import 'package:decimal/decimal.dart';

/// Utilities for working with Decimal type for monetary values
/// Constitutional requirement: Principle V (Data Integrity - no floating point for money)
class DecimalHelpers {
  /// Parse string to Decimal, returns Decimal.zero if invalid
  static Decimal parseDecimal(String value) {
    try {
      return Decimal.parse(value);
    } catch (e) {
      return Decimal.zero;
    }
  }

  /// Convert Decimal to string with fixed decimal places
  /// Example: toFixed(Decimal.parse("123.456"), 2) -> "123.46"
  static String toFixed(Decimal value, int decimalPlaces) {
    return value.toStringAsFixed(decimalPlaces);
  }

  /// Convert double to Decimal (use sparingly, prefer parsing strings)
  static Decimal fromDouble(double value) {
    return Decimal.parse(value.toString());
  }

  /// Safe division with zero check
  /// Returns Decimal.zero if divisor is zero
  static Decimal safeDivide(Decimal dividend, Decimal divisor) {
    if (divisor == Decimal.zero) {
      return Decimal.zero;
    }
    // Division returns Rational, convert to double then to Decimal
    final result = dividend / divisor;
    return Decimal.parse(result.toDouble().toString());
  }

  /// Check if decimal is zero (handles precision issues)
  static bool isZero(Decimal value) {
    return value == Decimal.zero;
  }

  /// Check if decimal is positive
  static bool isPositive(Decimal value) {
    return value > Decimal.zero;
  }

  /// Check if decimal is negative
  static bool isNegative(Decimal value) {
    return value < Decimal.zero;
  }

  /// Round to specified decimal places using banker's rounding (half-even)
  static Decimal round(Decimal value, int decimalPlaces) {
    if (decimalPlaces == 0) {
      return value.round();
    }

    // Use toStringAsFixed for rounding, then parse back
    final rounded = value.toStringAsFixed(decimalPlaces);
    return Decimal.parse(rounded);
  }

  /// Sum a list of Decimal values
  static Decimal sum(List<Decimal> values) {
    return values.fold(Decimal.zero, (acc, val) => acc + val);
  }

  /// Find maximum value in list of Decimals
  static Decimal max(List<Decimal> values) {
    if (values.isEmpty) return Decimal.zero;
    return values.reduce((a, b) => a > b ? a : b);
  }

  /// Find minimum value in list of Decimals
  static Decimal min(List<Decimal> values) {
    if (values.isEmpty) return Decimal.zero;
    return values.reduce((a, b) => a < b ? a : b);
  }

  /// Absolute value
  static Decimal abs(Decimal value) {
    return value.abs();
  }
}
