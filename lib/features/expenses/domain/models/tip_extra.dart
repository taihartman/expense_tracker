import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';
import 'percent_base.dart';

/// Tip configuration for itemized expenses
///
/// Supports both percentage-based (e.g., 18% on pre-tax total)
/// and absolute amount (e.g., $10 fixed tip).
/// Unlike tax, tip value can be zero (no tip).
class TipExtra extends Equatable {
  /// Type of tip: 'percent' or 'amount'
  final String type;

  /// Tip value
  /// - For percent: percentage as decimal (e.g., 18.0 for 18%)
  /// - For amount: absolute amount in expense currency
  /// Must be >= 0 (zero allowed for no tip)
  final Decimal value;

  /// Base for percentage calculation (required if type is 'percent', null if 'amount')
  /// Examples: preTaxItemSubtotals, postTaxSubtotals, postFeesSubtotals
  final PercentBase? base;

  const TipExtra._({
    required this.type,
    required this.value,
    this.base,
  });

  /// Create a percentage-based tip
  ///
  /// Throws [ArgumentError] if value < 0
  factory TipExtra.percent({
    required Decimal value,
    required PercentBase base,
  }) {
    if (value < Decimal.zero) {
      throw ArgumentError('Tip value cannot be negative');
    }
    return TipExtra._(
      type: 'percent',
      value: value,
      base: base,
    );
  }

  /// Create an absolute amount tip
  ///
  /// Throws [ArgumentError] if value < 0
  factory TipExtra.amount({
    required Decimal value,
  }) {
    if (value < Decimal.zero) {
      throw ArgumentError('Tip value cannot be negative');
    }
    return TipExtra._(
      type: 'amount',
      value: value,
      base: null,
    );
  }

  /// Raw constructor for deserialization
  ///
  /// Throws [ArgumentError] if validation fails
  factory TipExtra({
    required String type,
    required Decimal value,
    PercentBase? base,
  }) {
    // Type must be 'percent' or 'amount'
    if (type != 'percent' && type != 'amount') {
      throw ArgumentError('Type must be "percent" or "amount"');
    }

    // Value must be non-negative (zero allowed)
    if (value < Decimal.zero) {
      throw ArgumentError('Tip value cannot be negative');
    }

    // If percent type, base is required
    if (type == 'percent' && base == null) {
      throw ArgumentError('Percent-based tip requires a base');
    }

    // If amount type, base must be null
    if (type == 'amount' && base != null) {
      throw ArgumentError('Amount-based tip cannot have a base');
    }

    return TipExtra._(
      type: type,
      value: value,
      base: base,
    );
  }

  /// Validate tip configuration
  ///
  /// Returns error message if invalid, null if valid
  String? validate() {
    // Type must be 'percent' or 'amount'
    if (type != 'percent' && type != 'amount') {
      return 'Type must be "percent" or "amount"';
    }

    // Value must be non-negative (zero allowed)
    if (value < Decimal.zero) {
      return 'Tip value cannot be negative';
    }

    // If percent type, base is required
    if (type == 'percent' && base == null) {
      return 'Percent-based tip requires a base';
    }

    // If amount type, base must be null
    if (type == 'amount' && base != null) {
      return 'Amount-based tip cannot have a base';
    }

    return null;
  }

  /// Create a copy with updated fields
  TipExtra copyWith({
    String? type,
    Decimal? value,
    PercentBase? base,
  }) {
    return TipExtra._(
      type: type ?? this.type,
      value: value ?? this.value,
      base: base ?? this.base,
    );
  }

  @override
  List<Object?> get props => [type, value, base];

  @override
  String toString() {
    if (type == 'percent') {
      return 'TipExtra($value% on ${base?.displayName})';
    } else {
      return 'TipExtra(\$$value absolute)';
    }
  }
}
