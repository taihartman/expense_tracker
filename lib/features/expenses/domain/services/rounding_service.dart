import 'dart:math';
import 'package:decimal/decimal.dart';
import '../../../../core/services/decimal_service.dart';
import '../models/rounding_config.dart';
import '../models/remainder_distribution_mode.dart';

/// Service for rounding amounts with remainder distribution
///
/// Handles precise rounding to currency precision while ensuring
/// the total is preserved by distributing rounding remainders
/// according to configured strategies.
class RoundingService {
  /// Round amounts to currency precision and distribute remainder
  ///
  /// [amounts]: Map of participant ID to their unrounded amount
  /// [config]: Rounding configuration (precision, mode, distribution strategy)
  /// [currencyCode]: Currency code for precision lookup
  /// [payerId]: Required if distribution mode is 'payer'
  /// [randomSeed]: Optional seed for reproducible random distribution
  ///
  /// Returns map of participant ID to rounded amount that sums to original total
  ///
  /// Example:
  /// ```dart
  /// final amounts = {
  ///   'alice': Decimal.parse('3.333333'),
  ///   'bob': Decimal.parse('3.333333'),
  ///   'charlie': Decimal.parse('3.333333'),
  /// };
  ///
  /// final config = RoundingConfig(
  ///   precision: Decimal.parse('0.01'),
  ///   mode: RoundingMode.roundHalfUp,
  ///   distributeRemainderTo: RemainderDistributionMode.largestShare,
  /// );
  ///
  /// final rounded = service.roundAmounts(
  ///   amounts: amounts,
  ///   config: config,
  ///   currencyCode: 'USD',
  /// );
  /// // Result: {'alice': 3.34, 'bob': 3.33, 'charlie': 3.33}
  /// // Total preserved: 10.00
  /// ```
  Map<String, Decimal> roundAmounts({
    required Map<String, Decimal> amounts,
    required RoundingConfig config,
    required String currencyCode,
    String? payerId,
    int? randomSeed,
  }) {
    // Validate payer requirement
    if (config.distributeRemainderTo == RemainderDistributionMode.payer) {
      if (payerId == null) {
        throw ArgumentError(
          'payerId is required when distribution mode is "payer"',
        );
      }
      if (!amounts.containsKey(payerId)) {
        throw ArgumentError(
          'payerId "$payerId" not found in amounts map',
        );
      }
    }

    // If only one participant or all amounts are zero, just round normally
    if (amounts.length == 1 || amounts.values.every((a) => a == Decimal.zero)) {
      return amounts.map(
        (key, value) => MapEntry(
          key,
          DecimalService.round(value, currencyCode, config.mode),
        ),
      );
    }

    // Step 1: Calculate original total
    var originalTotal = Decimal.zero;
    for (final amount in amounts.values) {
      originalTotal = originalTotal + amount;
    }

    // Step 2: Round each amount individually
    final roundedAmounts = <String, Decimal>{};
    for (final entry in amounts.entries) {
      roundedAmounts[entry.key] = DecimalService.round(
        entry.value,
        currencyCode,
        config.mode,
      );
    }

    // Step 3: Calculate rounded total and remainder
    var roundedTotal = Decimal.zero;
    for (final amount in roundedAmounts.values) {
      roundedTotal = roundedTotal + amount;
    }

    final remainder = originalTotal - roundedTotal;

    // Step 4: If remainder is zero or negligible, return rounded amounts
    final epsilonRational = config.precision * Decimal.fromInt(1) / Decimal.fromInt(10);
    final epsilon = epsilonRational.toDecimal();
    if (remainder.abs() < epsilon) {
      return roundedAmounts;
    }

    // Step 5: Determine how many precision units to distribute
    final unitsRational = remainder / config.precision;
    final unitsDecimal = unitsRational.toDecimal();
    final unitsToDistribute = unitsDecimal.round();

    if (unitsToDistribute == Decimal.zero) {
      return roundedAmounts;
    }

    // Step 6: Select participant(s) to receive remainder
    final recipientId = _selectRemainderRecipient(
      amounts: amounts,
      config: config,
      payerId: payerId,
      randomSeed: randomSeed,
    );

    // Step 7: Distribute remainder
    final adjustedAmounts = Map<String, Decimal>.from(roundedAmounts);
    final adjustment = unitsToDistribute * config.precision;
    adjustedAmounts[recipientId] = adjustedAmounts[recipientId]! + adjustment;

    return adjustedAmounts;
  }

  /// Calculate remainder after rounding amounts
  ///
  /// Returns the difference between original total and rounded total
  /// expressed in units of precision
  Decimal calculateRemainder({
    required Map<String, Decimal> amounts,
    required Decimal precision,
  }) {
    var originalTotal = Decimal.zero;
    for (final amount in amounts.values) {
      originalTotal = originalTotal + amount;
    }

    var roundedTotal = Decimal.zero;
    for (final amount in amounts.values) {
      // Round to precision
      final multiplierRational = Decimal.one / precision;
      final multiplier = multiplierRational.toDecimal();
      final shifted = amount * multiplier;
      final rounded = Decimal.parse(shifted.toStringAsFixed(0));
      final resultRational = rounded / multiplier;
      final result = resultRational.toDecimal();
      roundedTotal = roundedTotal + result;
    }

    final remainder = originalTotal - roundedTotal;

    // Express remainder in units of precision
    final unitsRational = remainder / precision;
    final units = unitsRational.toDecimal();

    // Round to nearest precision unit
    final roundedUnits = Decimal.parse(units.toStringAsFixed(0));
    return roundedUnits * precision;
  }

  /// Select which participant receives the rounding remainder
  String _selectRemainderRecipient({
    required Map<String, Decimal> amounts,
    required RoundingConfig config,
    String? payerId,
    int? randomSeed,
  }) {
    switch (config.distributeRemainderTo) {
      case RemainderDistributionMode.largestShare:
        // Find participant with largest absolute amount
        return amounts.entries
            .reduce((a, b) => a.value.abs() > b.value.abs() ? a : b)
            .key;

      case RemainderDistributionMode.payer:
        // Validated earlier, payerId must exist
        return payerId!;

      case RemainderDistributionMode.firstListed:
        // First key in insertion order (LinkedHashMap preserves order)
        return amounts.keys.first;

      case RemainderDistributionMode.random:
        // Random selection (reproducible with seed)
        final random = randomSeed != null ? Random(randomSeed) : Random();
        final keys = amounts.keys.toList();
        return keys[random.nextInt(keys.length)];
    }
  }
}
