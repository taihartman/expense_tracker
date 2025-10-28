import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';
import 'percent_base.dart';

/// Tax configuration for itemized expenses
///
/// Supports both percentage-based (e.g., 8.875% on taxable items)
/// and absolute amount (e.g., $5 fixed tax).
class TaxExtra extends Equatable {
  /// Type of tax: 'percent' or 'amount'
  final String type;

  /// Tax value
  /// - For percent: percentage as decimal (e.g., 8.875 for 8.875%)
  /// - For amount: absolute amount in expense currency
  /// Must be > 0
  final Decimal value;

  /// Base for percentage calculation (required if type is 'percent', null if 'amount')
  /// Examples: preTaxItemSubtotals, taxableItemSubtotalsOnly, postDiscountItemSubtotals
  final PercentBase? base;

  const TaxExtra._({required this.type, required this.value, this.base});

  /// Create a percentage-based tax
  ///
  /// Throws [ArgumentError] if value <= 0
  factory TaxExtra.percent({
    required Decimal value,
    required PercentBase base,
  }) {
    if (value <= Decimal.zero) {
      throw ArgumentError('Tax value must be greater than 0');
    }
    return TaxExtra._(type: 'percent', value: value, base: base);
  }

  /// Create an absolute amount tax
  ///
  /// Throws [ArgumentError] if value <= 0
  factory TaxExtra.amount({required Decimal value}) {
    if (value <= Decimal.zero) {
      throw ArgumentError('Tax value must be greater than 0');
    }
    return TaxExtra._(type: 'amount', value: value, base: null);
  }

  /// Raw constructor for deserialization
  ///
  /// Throws [ArgumentError] if validation fails
  factory TaxExtra({
    required String type,
    required Decimal value,
    PercentBase? base,
  }) {
    // Type must be 'percent' or 'amount'
    if (type != 'percent' && type != 'amount') {
      throw ArgumentError('Type must be "percent" or "amount"');
    }

    // Value must be positive
    if (value <= Decimal.zero) {
      throw ArgumentError('Tax value must be greater than 0');
    }

    // If percent type, base is required
    if (type == 'percent' && base == null) {
      throw ArgumentError('Percent-based tax requires a base');
    }

    // If amount type, base must be null
    if (type == 'amount' && base != null) {
      throw ArgumentError('Amount-based tax cannot have a base');
    }

    return TaxExtra._(type: type, value: value, base: base);
  }

  /// Validate tax configuration
  ///
  /// Returns error message if invalid, null if valid
  String? validate() {
    // Type must be 'percent' or 'amount'
    if (type != 'percent' && type != 'amount') {
      return 'Type must be "percent" or "amount"';
    }

    // Value must be positive
    if (value <= Decimal.zero) {
      return 'Tax value must be greater than 0';
    }

    // If percent type, base is required
    if (type == 'percent' && base == null) {
      return 'Percent-based tax requires a base';
    }

    // If amount type, base must be null
    if (type == 'amount' && base != null) {
      return 'Amount-based tax cannot have a base';
    }

    return null;
  }

  /// Create a copy with updated fields
  TaxExtra copyWith({String? type, Decimal? value, PercentBase? base}) {
    return TaxExtra._(
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
      return 'TaxExtra($value% on ${base?.displayName})';
    } else {
      return 'TaxExtra(\$$value absolute)';
    }
  }
}
