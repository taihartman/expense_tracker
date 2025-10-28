import 'package:decimal/decimal.dart';
import '../models/iso_4217_precision.dart';
import '../../features/expenses/domain/models/rounding_mode.dart';

/// Service for currency-aware decimal operations and rounding
///
/// Provides utilities for precise monetary calculations with proper
/// rounding based on currency precision (ISO 4217)
class DecimalService {
  /// Round a decimal value to currency precision
  ///
  /// [value]: The decimal value to round
  /// [currencyCode]: Currency code (e.g., 'USD', 'VND')
  /// [mode]: Rounding mode to use
  ///
  /// Returns the rounded decimal value
  ///
  /// Example:
  /// ```dart
  /// DecimalService.round(Decimal.parse('1.235'), 'USD', RoundingMode.roundHalfUp)
  /// // Returns Decimal.parse('1.24')
  ///
  /// DecimalService.round(Decimal.parse('1000.7'), 'VND', RoundingMode.roundHalfUp)
  /// // Returns Decimal.parse('1001')
  /// ```
  static Decimal round(
    Decimal value,
    String currencyCode,
    RoundingMode mode,
  ) {
    final decimalPlaces = Iso4217Precision.getDecimalPlaces(currencyCode);
    return roundToPlaces(value, decimalPlaces, mode);
  }

  /// Round a decimal value to specific number of decimal places
  ///
  /// [value]: The decimal value to round
  /// [decimalPlaces]: Number of decimal places (0-4)
  /// [mode]: Rounding mode to use
  ///
  /// Returns the rounded decimal value
  static Decimal roundToPlaces(
    Decimal value,
    int decimalPlaces,
    RoundingMode mode,
  ) {
    // Use toStringAsFixed for rounding which is built into Decimal
    // For custom rounding modes, we need manual implementation

    if (mode == RoundingMode.roundHalfUp) {
      // Decimal's toStringAsFixed uses half-up rounding by default
      return Decimal.parse(value.toStringAsFixed(decimalPlaces));
    }

    // For other modes, calculate multiplier and do manual rounding
    final multiplier = Decimal.parse('1${'0' * decimalPlaces}');

    // Multiply to shift decimal point
    final shifted = value * multiplier;

    // Apply rounding mode - shifted is a Rational, convert to Decimal
    final shiftedDecimal = shifted.toDecimal();
    final Decimal rounded;
    switch (mode) {
      case RoundingMode.roundHalfUp:
        // Already handled above
        rounded = Decimal.parse(shifted.toStringAsFixed(0));
        break;
      case RoundingMode.roundHalfEven:
        rounded = _roundHalfEven(shiftedDecimal);
        break;
      case RoundingMode.floor:
        rounded = shiftedDecimal.floor();
        break;
      case RoundingMode.ceil:
        rounded = shiftedDecimal.ceil();
        break;
    }

    // Divide back
    final result = rounded / multiplier;
    return result.toDecimal();
  }

  /// Round half to even (banker's rounding)
  ///
  /// If fraction is exactly 0.5, round to nearest even number
  /// This reduces accumulated rounding bias over many operations
  static Decimal _roundHalfEven(Decimal value) {
    final floor = value.floor();
    final fraction = value - floor;

    if (fraction > Decimal.parse('0.5')) {
      // Greater than 0.5: round up
      return floor + Decimal.one;
    } else if (fraction < Decimal.parse('0.5')) {
      // Less than 0.5: round down
      return floor;
    } else {
      // Exactly 0.5: round to nearest even
      final floorBigInt = floor.toBigInt();
      if (floorBigInt % BigInt.two == BigInt.zero) {
        // Already even: round down
        return floor;
      } else {
        // Odd: round up to make it even
        return floor + Decimal.one;
      }
    }
  }

  /// Get currency precision (decimal places)
  static int getCurrencyPrecision(String currencyCode) {
    return Iso4217Precision.getDecimalPlaces(currencyCode);
  }

  /// Check if two decimal values are equal within currency precision
  ///
  /// Useful for comparing monetary amounts that may have floating point errors
  ///
  /// Example:
  /// ```dart
  /// DecimalService.areEqualWithinPrecision(
  ///   Decimal.parse('10.00'),
  ///   Decimal.parse('10.001'),
  ///   'USD', // 2 decimal places
  /// ) // Returns true (both round to $10.00)
  /// ```
  static bool areEqualWithinPrecision(
    Decimal a,
    Decimal b,
    String currencyCode,
  ) {
    final precision = Iso4217Precision.getDecimalPlaces(currencyCode);
    final epsilon = Decimal.parse('1${'0' * precision}').pow(-1).toDecimal();

    final diff = (a - b).abs().toDecimal();
    return diff < epsilon;
  }

  /// Format decimal for display with currency precision
  ///
  /// Returns a string with proper decimal places for the currency
  ///
  /// Example:
  /// ```dart
  /// DecimalService.formatForCurrency(Decimal.parse('10.5'), 'USD')
  /// // Returns '10.50'
  ///
  /// DecimalService.formatForCurrency(Decimal.parse('10000.7'), 'VND')
  /// // Returns '10001'
  /// ```
  static String formatForCurrency(Decimal value, String currencyCode) {
    final decimalPlaces = Iso4217Precision.getDecimalPlaces(currencyCode);
    return value.toStringAsFixed(decimalPlaces);
  }
}
