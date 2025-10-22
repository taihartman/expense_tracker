import 'package:decimal/decimal.dart';
import '../../../../core/models/currency_code.dart';
import '../../../../core/models/split_type.dart';
import '../../../../core/utils/decimal_helpers.dart';

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
  final Map<String, num> participants;

  /// When this expense was created (immutable)
  final DateTime createdAt;

  /// When this expense was last updated
  final DateTime updatedAt;

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
  Map<String, Decimal> _calculateEqualShares() {
    final participantCount = participants.length;
    if (participantCount == 0) {
      return {};
    }

    // Divide amount by number of participants
    final shareAmount = DecimalHelpers.safeDivide(
      amount,
      Decimal.fromInt(participantCount),
    );

    // Round to currency decimal places
    final roundedShare = DecimalHelpers.round(
      shareAmount,
      currency.decimalPlaces,
    );

    return Map.fromEntries(
      participants.keys.map((userId) => MapEntry(userId, roundedShare)),
    );
  }

  /// Calculate weighted shares (proportional to weights)
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

    // Calculate share for each participant
    final shares = <String, Decimal>{};
    for (final entry in participants.entries) {
      final userId = entry.key;
      final weight = Decimal.parse(entry.value.toString());

      // Share = (weight / totalWeight) * amount
      final weightRatio = DecimalHelpers.safeDivide(weight, totalWeightDecimal);
      final shareRational = weightRatio * amount;
      // Convert Rational to Decimal via double to handle non-terminating decimals
      final share = Decimal.parse(shareRational.toDouble().toString());

      // Round to currency decimal places
      final roundedShare = DecimalHelpers.round(share, currency.decimalPlaces);

      shares[userId] = roundedShare;
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

    // Validate participants
    if (participants.isEmpty) {
      return 'At least one participant is required';
    }

    // Validate split type constraints
    if (splitType == SplitType.equal) {
      // All weights must be 1 for equal split
      final allWeightsOne = participants.values.every((w) => w == 1);
      if (!allWeightsOne) {
        return 'Equal split requires all participant weights to be 1';
      }
    } else if (splitType == SplitType.weighted) {
      // All weights must be > 0 for weighted split
      final allWeightsPositive = participants.values.every((w) => w > 0);
      if (!allWeightsPositive) {
        return 'Weighted split requires all participant weights to be greater than 0';
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
