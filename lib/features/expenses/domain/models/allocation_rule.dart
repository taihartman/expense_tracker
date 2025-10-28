import 'package:equatable/equatable.dart';
import 'absolute_split_mode.dart';
import 'percent_base.dart';
import 'rounding_config.dart';

/// Configuration for how extras are allocated and rounded
///
/// Defines:
/// - What base percentage-based extras use
/// - How absolute-value extras are split
/// - Rounding behavior and remainder distribution
class AllocationRule extends Equatable {
  /// Base for percentage-based extras (tax, tip, fees)
  /// Determines what subtotal percentages are applied to
  final PercentBase percentBase;

  /// How to split absolute-value extras (fees, discounts, tips)
  /// Either proportional to items or even across people
  final AbsoluteSplitMode absoluteSplit;

  /// Rounding configuration
  final RoundingConfig rounding;

  const AllocationRule({
    required this.percentBase,
    required this.absoluteSplit,
    required this.rounding,
  });

  /// Validate allocation rule
  ///
  /// Returns error message if invalid, null if valid
  String? validate() {
    // Validate rounding config
    final roundingError = rounding.validate();
    if (roundingError != null) {
      return 'Rounding error: $roundingError';
    }

    return null;
  }

  /// Create a copy with updated fields
  AllocationRule copyWith({
    PercentBase? percentBase,
    AbsoluteSplitMode? absoluteSplit,
    RoundingConfig? rounding,
  }) {
    return AllocationRule(
      percentBase: percentBase ?? this.percentBase,
      absoluteSplit: absoluteSplit ?? this.absoluteSplit,
      rounding: rounding ?? this.rounding,
    );
  }

  @override
  List<Object?> get props => [percentBase, absoluteSplit, rounding];

  @override
  String toString() {
    return 'AllocationRule(percentBase: $percentBase, absoluteSplit: $absoluteSplit, rounding: $rounding)';
  }
}
