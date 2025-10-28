import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';
import 'remainder_distribution_mode.dart';
import 'rounding_mode.dart';

/// Configuration for rounding monetary values
///
/// Defines how fractional currency units (cents, pennies) are handled
/// when splitting expenses and how remainders are distributed.
class RoundingConfig extends Equatable {
  /// Rounding precision (e.g., 0.01 for USD, 1 for VND)
  /// Must be positive (e.g., 0.01, 0.05, 1.00)
  final Decimal precision;

  /// Rounding mode to apply
  final RoundingMode mode;

  /// How to distribute rounding remainders
  final RemainderDistributionMode distributeRemainderTo;

  RoundingConfig({
    required this.precision,
    required this.mode,
    required this.distributeRemainderTo,
  }) {
    if (precision <= Decimal.zero) {
      throw ArgumentError('Precision must be positive');
    }
  }

  /// Validate configuration
  ///
  /// Returns error message if invalid, null if valid
  String? validate() {
    if (precision <= Decimal.zero) {
      return 'Precision must be positive';
    }
    return null;
  }

  /// Create a copy with updated fields
  RoundingConfig copyWith({
    Decimal? precision,
    RoundingMode? mode,
    RemainderDistributionMode? distributeRemainderTo,
  }) {
    return RoundingConfig(
      precision: precision ?? this.precision,
      mode: mode ?? this.mode,
      distributeRemainderTo:
          distributeRemainderTo ?? this.distributeRemainderTo,
    );
  }

  @override
  List<Object?> get props => [precision, mode, distributeRemainderTo];

  @override
  String toString() {
    return 'RoundingConfig(precision: $precision, mode: $mode, distributeRemainderTo: $distributeRemainderTo)';
  }
}
