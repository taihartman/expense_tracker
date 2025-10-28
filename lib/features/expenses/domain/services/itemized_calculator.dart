import 'package:decimal/decimal.dart';
import '../models/line_item.dart';
import '../models/extras.dart';
import '../models/allocation_rule.dart';
import '../models/participant_breakdown.dart';
import '../models/item_contribution.dart';
import '../models/assignment_mode.dart';
import '../models/percent_base.dart';
import '../models/absolute_split_mode.dart';
import 'rounding_service.dart';

/// Service for calculating itemized expense splits
///
/// Takes line items with per-item assignments and extras (tax, tip, fees, discounts)
/// and calculates exactly how much each participant owes with full audit trail.
class ItemizedCalculator {
  final RoundingService _roundingService = RoundingService();

  /// Calculate per-person breakdown for an itemized expense
  ///
  /// Returns a map of participant ID to their complete breakdown including:
  /// - Item subtotal with contribution details
  /// - Tax, tip, fees, discounts allocation
  /// - Grand total after rounding with remainder distribution
  ///
  /// Example:
  /// ```dart
  /// final calculator = ItemizedCalculator();
  /// final breakdown = calculator.calculate(
  ///   items: [pizza, salad],
  ///   extras: Extras(tax: ..., tip: ...),
  ///   allocation: AllocationRule(...),
  ///   currencyCode: 'USD',
  /// );
  /// // breakdown['alice'] contains full breakdown for Alice
  /// ```
  Map<String, ParticipantBreakdown> calculate({
    required List<LineItem> items,
    required Extras extras,
    required AllocationRule allocation,
    required String currencyCode,
  }) {
    // Step 1: Calculate item subtotals per person with contribution audit trail
    final participantData = _calculateItemSubtotals(items);

    // Step 2: Calculate tax amounts per person
    final taxAmounts = _calculateTax(
      participantData: participantData,
      extras: extras,
      allocation: allocation,
    );

    // Step 3: Calculate tip amounts per person
    final tipAmounts = _calculateTip(
      participantData: participantData,
      extras: extras,
      allocation: allocation,
    );

    // Step 4: Calculate fee amounts per person
    final feeResults = _calculateFees(
      participantData: participantData,
      extras: extras,
      allocation: allocation,
    );

    // Step 5: Calculate discount amounts per person
    final discountResults = _calculateDiscounts(
      participantData: participantData,
      extras: extras,
      allocation: allocation,
    );

    // Step 6: Sum up totals before rounding
    final unroundedTotals = <String, Decimal>{};
    for (final participantId in participantData.keys) {
      final itemSubtotal = participantData[participantId]!['subtotal'] as Decimal;
      final tax = taxAmounts[participantId] ?? Decimal.zero;
      final tip = tipAmounts[participantId] ?? Decimal.zero;
      final fees = feeResults['amounts']![participantId] ?? Decimal.zero;
      final discounts = discountResults['amounts']![participantId] ?? Decimal.zero;

      unroundedTotals[participantId] = itemSubtotal + tax + tip + fees - discounts;
    }

    // Step 7: Apply rounding with remainder distribution
    final roundedTotals = _roundingService.roundAmounts(
      amounts: unroundedTotals,
      config: allocation.rounding,
      currencyCode: currencyCode,
    );

    // Step 8: Build ParticipantBreakdown objects
    final breakdowns = <String, ParticipantBreakdown>{};
    for (final participantId in participantData.keys) {
      final contributions = participantData[participantId]!['contributions'] as List<ItemContribution>;
      final itemSubtotal = participantData[participantId]!['subtotal'] as Decimal;

      // Build extrasAllocated map
      final extrasAllocated = <String, Decimal>{};
      if (taxAmounts.containsKey(participantId)) {
        extrasAllocated['tax'] = taxAmounts[participantId]!;
      }
      if (tipAmounts.containsKey(participantId)) {
        extrasAllocated['tip'] = tipAmounts[participantId]!;
      }
      // Add individual fees
      final participantFees = feeResults['breakdowns']![participantId] ?? <String, Decimal>{};
      for (final entry in participantFees.entries) {
        extrasAllocated['fee_${entry.key}'] = entry.value;
      }
      // Add individual discounts
      final participantDiscounts = discountResults['breakdowns']![participantId] ?? <String, Decimal>{};
      for (final entry in participantDiscounts.entries) {
        extrasAllocated['discount_${entry.key}'] = entry.value;
      }

      // Calculate unrounded total
      final unroundedTotal = unroundedTotals[participantId]!;
      final roundedTotal = roundedTotals[participantId]!;
      final roundingAdjustment = roundedTotal - unroundedTotal;

      breakdowns[participantId] = ParticipantBreakdown(
        userId: participantId,
        itemsSubtotal: itemSubtotal,
        extrasAllocated: extrasAllocated,
        roundedAdjustment: roundingAdjustment,
        total: roundedTotal,
        items: contributions,
      );
    }

    return breakdowns;
  }

  /// Calculate item subtotals per person with contribution audit trail
  Map<String, Map<String, dynamic>> _calculateItemSubtotals(List<LineItem> items) {
    final participantData = <String, Map<String, dynamic>>{};

    for (final item in items) {
      final itemTotal = item.itemTotal;
      final assignment = item.assignment;

      // Calculate share for each assigned user
      // Note: We keep amounts unrounded here; rounding happens at the final step
      Map<String, Decimal> shares;
      if (assignment.mode == AssignmentMode.even) {
        // Even split - may produce infinite precision rational
        // Convert via double to handle infinite precision
        final shareRational = itemTotal / Decimal.fromInt(assignment.users.length);
        final shareDouble = shareRational.toDouble();
        final shareAmount = Decimal.parse(shareDouble.toStringAsFixed(10));
        shares = {
          for (final userId in assignment.users) userId: shareAmount,
        };
      } else {
        // Custom shares
        shares = {
          for (final entry in assignment.shares!.entries)
            entry.key: itemTotal * entry.value,
        };
      }

      // Record contributions
      for (final entry in shares.entries) {
        final userId = entry.key;
        final amount = entry.value;

        // Initialize participant data if needed
        if (!participantData.containsKey(userId)) {
          participantData[userId] = {
            'subtotal': Decimal.zero,
            'contributions': <ItemContribution>[],
          };
        }

        // Add to subtotal
        participantData[userId]!['subtotal'] =
            (participantData[userId]!['subtotal'] as Decimal) + amount;

        // Record contribution
        final Decimal assignedShare;
        if (assignment.mode == AssignmentMode.even) {
          // May produce infinite precision (e.g., 1/3) - convert via double
          final shareRational = Decimal.one / Decimal.fromInt(assignment.users.length);
          assignedShare = Decimal.parse(shareRational.toDouble().toStringAsFixed(10));
        } else {
          assignedShare = assignment.shares![userId]!;
        }

        final contribution = ItemContribution(
          itemId: item.id,
          itemName: item.name,
          quantity: item.quantity,
          unitPrice: item.unitPrice,
          assignedShare: assignedShare,
        );

        (participantData[userId]!['contributions'] as List<ItemContribution>).add(contribution);
      }
    }

    return participantData;
  }

  /// Calculate tax per person based on allocation rule
  Map<String, Decimal> _calculateTax({
    required Map<String, Map<String, dynamic>> participantData,
    required Extras extras,
    required AllocationRule allocation,
  }) {
    if (extras.tax == null) {
      return {};
    }

    final tax = extras.tax!;

    // Calculate total tax amount
    Decimal totalTaxAmount;
    if (tax.type == 'percent') {
      // Calculate base for percentage
      final base = _calculatePercentageBase(participantData, allocation.percentBase);
      totalTaxAmount = (base * tax.value / Decimal.fromInt(100)).toDecimal();
    } else {
      // Flat amount
      totalTaxAmount = tax.value;
    }

    // Distribute tax according to allocation rule
    return _distributeAbsoluteAmount(
      totalAmount: totalTaxAmount,
      participantData: participantData,
      splitMode: allocation.absoluteSplit,
    );
  }

  /// Calculate tip per person based on allocation rule
  Map<String, Decimal> _calculateTip({
    required Map<String, Map<String, dynamic>> participantData,
    required Extras extras,
    required AllocationRule allocation,
  }) {
    if (extras.tip == null) {
      return {};
    }

    final tip = extras.tip!;

    // Calculate total tip amount
    Decimal totalTipAmount;
    if (tip.type == 'percent') {
      // Calculate base for percentage
      final base = _calculatePercentageBase(participantData, allocation.percentBase);
      totalTipAmount = (base * tip.value / Decimal.fromInt(100)).toDecimal();
    } else {
      // Flat amount
      totalTipAmount = tip.value;
    }

    // Distribute tip according to allocation rule
    return _distributeAbsoluteAmount(
      totalAmount: totalTipAmount,
      participantData: participantData,
      splitMode: allocation.absoluteSplit,
    );
  }

  /// Calculate fees per person with breakdown
  Map<String, Map<String, dynamic>> _calculateFees({
    required Map<String, Map<String, dynamic>> participantData,
    required Extras extras,
    required AllocationRule allocation,
  }) {
    final feeAmounts = <String, Decimal>{};
    final feeBreakdowns = <String, Map<String, Decimal>>{};

    // Initialize
    for (final participantId in participantData.keys) {
      feeAmounts[participantId] = Decimal.zero;
      feeBreakdowns[participantId] = {};
    }

    // Process each fee
    for (final fee in extras.fees) {
      // Calculate total fee amount
      Decimal totalFeeAmount;
      if (fee.type == 'percent') {
        final base = _calculatePercentageBase(participantData, fee.base!);
        totalFeeAmount = (base * fee.value / Decimal.fromInt(100)).toDecimal();
      } else {
        totalFeeAmount = fee.value;
      }

      // Distribute fee
      final distribution = _distributeAbsoluteAmount(
        totalAmount: totalFeeAmount,
        participantData: participantData,
        splitMode: allocation.absoluteSplit,
      );

      // Add to totals and breakdowns
      for (final entry in distribution.entries) {
        feeAmounts[entry.key] = feeAmounts[entry.key]! + entry.value;
        feeBreakdowns[entry.key]![fee.name] = entry.value;
      }
    }

    return {
      'amounts': feeAmounts,
      'breakdowns': feeBreakdowns,
    };
  }

  /// Calculate discounts per person with breakdown
  Map<String, Map<String, dynamic>> _calculateDiscounts({
    required Map<String, Map<String, dynamic>> participantData,
    required Extras extras,
    required AllocationRule allocation,
  }) {
    final discountAmounts = <String, Decimal>{};
    final discountBreakdowns = <String, Map<String, Decimal>>{};

    // Initialize
    for (final participantId in participantData.keys) {
      discountAmounts[participantId] = Decimal.zero;
      discountBreakdowns[participantId] = {};
    }

    // Process each discount
    for (final discount in extras.discounts) {
      // Calculate total discount amount
      Decimal totalDiscountAmount;
      if (discount.type == 'percent') {
        final base = _calculatePercentageBase(participantData, discount.base!);
        totalDiscountAmount = (base * discount.value / Decimal.fromInt(100)).toDecimal();
      } else {
        totalDiscountAmount = discount.value;
      }

      // Distribute discount
      final distribution = _distributeAbsoluteAmount(
        totalAmount: totalDiscountAmount,
        participantData: participantData,
        splitMode: allocation.absoluteSplit,
      );

      // Add to totals and breakdowns
      for (final entry in distribution.entries) {
        discountAmounts[entry.key] = discountAmounts[entry.key]! + entry.value;
        discountBreakdowns[entry.key]![discount.name] = entry.value;
      }
    }

    return {
      'amounts': discountAmounts,
      'breakdowns': discountBreakdowns,
    };
  }

  /// Calculate percentage base according to PercentBase configuration
  Decimal _calculatePercentageBase(
    Map<String, Map<String, dynamic>> participantData,
    PercentBase base,
  ) {
    // For now, we only support preTaxItemSubtotals
    // Future versions can support other bases
    var total = Decimal.zero;
    for (final data in participantData.values) {
      total = total + (data['subtotal'] as Decimal);
    }
    return total;
  }

  /// Distribute an absolute amount according to split mode
  Map<String, Decimal> _distributeAbsoluteAmount({
    required Decimal totalAmount,
    required Map<String, Map<String, dynamic>> participantData,
    required AbsoluteSplitMode splitMode,
  }) {
    if (splitMode == AbsoluteSplitMode.evenAcrossAssignedPeople) {
      // Split evenly among all participants
      final perPersonRational = totalAmount / Decimal.fromInt(participantData.length);
      final perPerson = perPersonRational.toDecimal();
      return {
        for (final participantId in participantData.keys)
          participantId: perPerson,
      };
    } else {
      // Proportional to items subtotal
      final totalSubtotal = participantData.values.fold<Decimal>(
        Decimal.zero,
        (sum, data) => sum + (data['subtotal'] as Decimal),
      );

      if (totalSubtotal == Decimal.zero) {
        // If no items, split evenly
        final perPersonRational = totalAmount / Decimal.fromInt(participantData.length);
        final perPerson = perPersonRational.toDecimal();
        return {
          for (final participantId in participantData.keys)
            participantId: perPerson,
        };
      }

      // Calculate proportional share
      // May produce infinite precision rational - convert via double
      return {
        for (final entry in participantData.entries)
          entry.key: Decimal.parse(
            (totalAmount * (entry.value['subtotal'] as Decimal) / totalSubtotal)
                .toDouble()
                .toStringAsFixed(10),
          ),
      };
    }
  }
}
