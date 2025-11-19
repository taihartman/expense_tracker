import 'package:decimal/decimal.dart';
import '../../../../core/models/currency_code.dart';
import '../../../../core/models/split_type.dart';
import '../../../../core/utils/decimal_helpers.dart';
import 'allocation_rule.dart';
import 'extras.dart';
import 'line_item.dart';
import 'participant_breakdown.dart';

/// Expense domain entity
///
/// Represents a single payment made by one participant
class Expense {
  /// Unique identifier (auto-generated)
  final String id;

  /// Trip this expense belongs to
  final String tripId;

  /// Date when expense occurred (date-only precision)
  final DateTime date;

  /// Participant ID who paid for this expense
  final String payerUserId;

  /// Currency of the expense amount
  final CurrencyCode currency;

  /// Amount paid (in specified currency)
  /// Must be > 0, max 12 digits + 2 decimals
  final Decimal amount;

  /// Optional user note (e.g., "Dinner at Pho 24")
  /// Max 200 characters
  final String? description;

  /// Optional category ID
  final String? categoryId;

  /// How the expense should be split
  final SplitType splitType;

  /// Map of participant IDs to their weights
  /// - For Equal split: all weights must be 1
  /// - For Weighted split: all weights must be > 0
  /// - For Itemized split: may be empty (items field contains the data)
  final Map<String, num> participants;

  /// When this expense was created (immutable)
  final DateTime createdAt;

  /// When this expense was last updated
  final DateTime updatedAt;

  // ===== Itemized Expense Fields (optional) =====

  /// Line items (only for splitType = itemized)
  final List<LineItem>? items;

  /// Tax, tip, fees, discounts (only for splitType = itemized)
  final Extras? extras;

  /// Allocation rules (only for splitType = itemized)
  final AllocationRule? allocation;

  /// Per-person amounts (only for splitType = itemized)
  /// Canonical source for settlement calculations
  /// Keys: user IDs, Values: amount strings (Decimal serialized)
  final Map<String, Decimal>? participantAmounts;

  /// Detailed per-person breakdown (only for splitType = itemized)
  /// Full audit trail with item contributions
  final Map<String, ParticipantBreakdown>? participantBreakdown;

  /// Expected subtotal from receipt (user-entered, for itemized expenses)
  /// Used for validation warnings when items don't match receipt
  final Decimal? expectedSubtotal;

  /// Tax amount from receipt (user-entered, absolute value, for itemized expenses)
  /// Used for receipt-based itemized splitting
  final Decimal? taxAmount;

  const Expense({
    required this.id,
    required this.tripId,
    required this.date,
    required this.payerUserId,
    required this.currency,
    required this.amount,
    this.description,
    this.categoryId,
    required this.splitType,
    required this.participants,
    required this.createdAt,
    required this.updatedAt,
    this.items,
    this.extras,
    this.allocation,
    this.participantAmounts,
    this.participantBreakdown,
    this.expectedSubtotal,
    this.taxAmount,
  });

  /// Calculate shares for each participant based on split type
  ///
  /// Returns a map of participant IDs to their share amounts (in Decimal)
  /// Uses proper rounding to ensure conservation of money
  Map<String, Decimal> calculateShares() {
    if (splitType == SplitType.equal) {
      return _calculateEqualShares();
    } else {
      return _calculateWeightedShares();
    }
  }

  /// Calculate equal shares (divide evenly)
  ///
  /// Uses remainder distribution to ensure conservation of money:
  /// If 50000 / 3 = 16666.666..., gives 16667 to first 2 people and 16666 to the last
  /// Total: 16667 + 16667 + 16666 = 50000 ✅
  Map<String, Decimal> _calculateEqualShares() {
    final participantCount = participants.length;
    if (participantCount == 0) {
      return {};
    }

    // For currencies with decimal places, use remainder distribution
    // to ensure sum of shares = original amount (conservation of money)
    // Strategy: Work in smallest currency unit (cents for USD), similar to VND logic
    if (currency.decimalPlaces > 0) {
      // Convert to smallest unit (e.g., USD $100.00 → 10000 cents)
      // .pow() returns Rational, convert to Decimal
      final scaleFactorRational = Decimal.fromInt(10).pow(currency.decimalPlaces);
      final scaleFactor = Decimal.parse(scaleFactorRational.toDouble().toString());

      // Multiply returns Rational, convert to Decimal then to BigInt
      final amountScaledRational = amount * scaleFactor;
      final amountScaled = Decimal.parse(amountScaledRational.toDouble().toString());
      final amountInSmallestUnit = amountScaled.toBigInt();

      // Calculate base share in smallest unit (floor division)
      final baseShareSmallestUnit = amountInSmallestUnit ~/ BigInt.from(participantCount);

      // Calculate remainder (how many extra smallest units to distribute)
      final totalForBase = baseShareSmallestUnit * BigInt.from(participantCount);
      final remainderSmallestUnit = amountInSmallestUnit - totalForBase;
      final remainder = remainderSmallestUnit.toInt();

      // Convert base share back to currency unit (e.g., 3333 cents → $33.33)
      final baseShareDecimal = DecimalHelpers.safeDivide(
        Decimal.fromBigInt(baseShareSmallestUnit),
        scaleFactor,
      );

      // Calculate precision (0.01 for USD with 2 decimals)
      final precision = Decimal.parse('0.${'0' * (currency.decimalPlaces - 1)}1');

      final shares = <String, Decimal>{};
      final userIds = participants.keys.toList();

      // First `remainder` people get baseShare + precision, rest get baseShare
      for (int i = 0; i < userIds.length; i++) {
        final share = i < remainder
            ? baseShareDecimal + precision
            : baseShareDecimal;
        shares[userIds[i]] = share;
      }

      return shares;
    }

    // For whole-number currencies (like VND), use remainder distribution
    // to ensure sum of shares = original amount (conservation of money)

    // Calculate base share (floor division)
    final baseShareBigInt = (amount / Decimal.fromInt(participantCount)).floor();
    final baseShare = Decimal.fromBigInt(baseShareBigInt);

    // Calculate remainder (how many extra units to distribute)
    final totalForBase = baseShare * Decimal.fromInt(participantCount);
    final remainderDecimal = amount - totalForBase;
    final remainder = remainderDecimal.toBigInt().toInt();

    final shares = <String, Decimal>{};
    final userIds = participants.keys.toList();

    // Distribute shares: first `remainder` people get baseShare + 1, rest get baseShare
    for (int i = 0; i < userIds.length; i++) {
      final share = i < remainder
          ? baseShare + Decimal.one
          : baseShare;
      shares[userIds[i]] = share;
    }

    return shares;
  }

  /// Calculate weighted shares (proportional to weights)
  ///
  /// Uses remainder distribution for whole-number currencies to ensure conservation of money
  Map<String, Decimal> _calculateWeightedShares() {
    if (participants.isEmpty) {
      return {};
    }

    // Calculate total weight
    final totalWeight = participants.values.fold<num>(
      0,
      (sum, weight) => sum + weight,
    );

    if (totalWeight == 0) {
      return {};
    }

    final totalWeightDecimal = Decimal.parse(totalWeight.toString());

    // For currencies with decimal places, use remainder distribution
    // to ensure sum of shares = original amount (conservation of money)
    if (currency.decimalPlaces > 0) {
      final shares = <String, Decimal>{};
      final userIds = participants.keys.toList();
      Decimal runningTotal = Decimal.zero;

      // Calculate shares with floor rounding for all except last participant
      for (int i = 0; i < userIds.length; i++) {
        final userId = userIds[i];
        final weight = Decimal.parse(participants[userId].toString());

        if (i == userIds.length - 1) {
          // Last participant gets the remainder to ensure conservation of money
          shares[userId] = amount - runningTotal;
        } else {
          // Calculate weighted share: (weight / totalWeight) * amount
          final weightRatio = DecimalHelpers.safeDivide(weight, totalWeightDecimal);
          final shareRational = weightRatio * amount;
          final share = Decimal.parse(shareRational.toDouble().toString());

          // Floor to currency precision (e.g., floor $33.336 to $33.33)
          // Convert to smallest unit, floor, convert back
          final scaleFactorRational = Decimal.fromInt(10).pow(currency.decimalPlaces);
          final scaleFactor = Decimal.parse(scaleFactorRational.toDouble().toString());
          final shareScaledRational = share * scaleFactor;
          final shareScaled = Decimal.parse(shareScaledRational.toDouble().toString());
          final shareSmallestUnit = shareScaled.toBigInt();
          final shareFloored = DecimalHelpers.safeDivide(
            Decimal.fromBigInt(shareSmallestUnit),
            scaleFactor,
          );

          shares[userId] = shareFloored;
          runningTotal += shareFloored;
        }
      }

      return shares;
    }

    // For whole-number currencies, use remainder distribution
    // Calculate shares with floor rounding, then distribute remainder

    final shares = <String, Decimal>{};
    final userIds = participants.keys.toList();
    Decimal runningTotal = Decimal.zero;

    // Calculate floored shares for all participants
    for (int i = 0; i < userIds.length; i++) {
      final userId = userIds[i];
      final weight = Decimal.parse(participants[userId].toString());

      if (i == userIds.length - 1) {
        // Last participant gets the remainder to ensure conservation of money
        shares[userId] = amount - runningTotal;
      } else {
        // Calculate weighted share and floor it
        final weightRatio = DecimalHelpers.safeDivide(weight, totalWeightDecimal);
        final shareRational = weightRatio * amount;
        // Convert Rational to Decimal, then floor to BigInt
        final shareDecimal = Decimal.parse(shareRational.toDouble().toString());
        final shareBigInt = shareDecimal.toBigInt();
        final shareFloored = Decimal.fromBigInt(shareBigInt);

        shares[userId] = shareFloored;
        runningTotal += shareFloored;
      }
    }

    return shares;
  }

  /// Validate expense data
  ///
  /// Returns error message if invalid, null if valid
  String? validate() {
    // Validate amount
    if (amount <= Decimal.zero) {
      return 'Expense amount must be greater than 0';
    }

    // Validate date (not in future)
    if (date.isAfter(DateTime.now())) {
      return 'Expense date cannot be in the future';
    }

    // Validate split type constraints
    if (splitType == SplitType.equal) {
      // All weights must be 1 for equal split
      if (participants.isEmpty) {
        return 'At least one participant is required';
      }
      final allWeightsOne = participants.values.every((w) => w == 1);
      if (!allWeightsOne) {
        return 'Equal split requires all participant weights to be 1';
      }
    } else if (splitType == SplitType.weighted) {
      // All weights must be > 0 for weighted split
      if (participants.isEmpty) {
        return 'At least one participant is required';
      }
      final allWeightsPositive = participants.values.every((w) => w > 0);
      if (!allWeightsPositive) {
        return 'Weighted split requires all participant weights to be greater than 0';
      }
    } else if (splitType == SplitType.itemized) {
      // Itemized split requires items and participantAmounts
      if (items == null || items!.isEmpty) {
        return 'Itemized split requires at least one item';
      }

      if (participantAmounts == null || participantAmounts!.isEmpty) {
        return 'Itemized split requires participant amounts';
      }

      // Validate all items
      for (int i = 0; i < items!.length; i++) {
        final itemError = items![i].validate();
        if (itemError != null) {
          return 'Item ${i + 1} error: $itemError';
        }
      }

      // Validate extras if present
      if (extras != null) {
        final extrasError = extras!.validate();
        if (extrasError != null) {
          return extrasError;
        }
      }

      // Validate allocation if present
      if (allocation != null) {
        final allocationError = allocation!.validate();
        if (allocationError != null) {
          return allocationError;
        }
      }

      // Validate sum of participantAmounts equals amount (within epsilon)
      final sum = participantAmounts!.values.fold(
        Decimal.zero,
        (a, b) => a + b,
      );
      final epsilon = Decimal.parse('0.01');
      if ((sum - amount).abs() > epsilon) {
        return 'Sum of participant amounts ($sum) must equal total amount ($amount)';
      }
    }

    // Validate description length
    if (description != null && description!.length > 200) {
      return 'Expense description cannot exceed 200 characters';
    }

    return null;
  }

  /// Create a copy of this expense with updated fields
  Expense copyWith({
    String? id,
    String? tripId,
    DateTime? date,
    String? payerUserId,
    CurrencyCode? currency,
    Decimal? amount,
    String? description,
    String? categoryId,
    SplitType? splitType,
    Map<String, num>? participants,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<LineItem>? items,
    Extras? extras,
    AllocationRule? allocation,
    Map<String, Decimal>? participantAmounts,
    Map<String, ParticipantBreakdown>? participantBreakdown,
    Decimal? expectedSubtotal,
    Decimal? taxAmount,
  }) {
    return Expense(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      date: date ?? this.date,
      payerUserId: payerUserId ?? this.payerUserId,
      currency: currency ?? this.currency,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      splitType: splitType ?? this.splitType,
      participants: participants ?? this.participants,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      items: items ?? this.items,
      extras: extras ?? this.extras,
      allocation: allocation ?? this.allocation,
      participantAmounts: participantAmounts ?? this.participantAmounts,
      participantBreakdown: participantBreakdown ?? this.participantBreakdown,
      expectedSubtotal: expectedSubtotal ?? this.expectedSubtotal,
      taxAmount: taxAmount ?? this.taxAmount,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Expense && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Expense(id: $id, tripId: $tripId, date: $date, '
        'payerUserId: $payerUserId, amount: $amount $currency, '
        'splitType: $splitType, participants: ${participants.length})';
  }
}
