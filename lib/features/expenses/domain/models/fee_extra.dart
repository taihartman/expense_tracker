import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';
import 'percent_base.dart';

/// Fee configuration for itemized expenses
///
/// Supports additional charges like delivery fees, service charges, etc.
/// Can be percentage-based or absolute amount.
class FeeExtra extends Equatable {
  /// Unique identifier for this fee
  final String id;

  /// Fee name/description (e.g., "Delivery Fee", "Service Charge")
  final String name;

  /// Type of fee: 'percent' or 'amount'
  final String type;

  /// Fee value
  /// - For percent: percentage as decimal (e.g., 10.0 for 10%)
  /// - For amount: absolute amount in expense currency
  /// Must be > 0
  final Decimal value;

  /// Base for percentage calculation (required if type is 'percent', null if 'amount')
  final PercentBase? base;

  const FeeExtra({
    required this.id,
    required this.name,
    required this.type,
    required this.value,
    this.base,
  });

  /// Validate fee configuration
  ///
  /// Returns error message if invalid, null if valid
  String? validate() {
    // ID must not be empty
    if (id.trim().isEmpty) {
      return 'Fee ID cannot be empty';
    }

    // Name must not be empty
    if (name.trim().isEmpty) {
      return 'Fee name cannot be empty';
    }

    // Type must be 'percent' or 'amount'
    if (type != 'percent' && type != 'amount') {
      return 'Type must be "percent" or "amount"';
    }

    // Value must be positive
    if (value <= Decimal.zero) {
      return 'Fee value must be greater than 0';
    }

    // If percent type, base is required
    if (type == 'percent' && base == null) {
      return 'Percent-based fee requires a base';
    }

    // If amount type, base must be null
    if (type == 'amount' && base != null) {
      return 'Amount-based fee cannot have a base';
    }

    return null;
  }

  /// Create a copy with updated fields
  FeeExtra copyWith({
    String? id,
    String? name,
    String? type,
    Decimal? value,
    PercentBase? base,
  }) {
    return FeeExtra(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      value: value ?? this.value,
      base: base ?? this.base,
    );
  }

  @override
  List<Object?> get props => [id, name, type, value, base];

  @override
  String toString() {
    if (type == 'percent') {
      return 'FeeExtra($name: $value% on ${base?.displayName})';
    } else {
      return 'FeeExtra($name: \$$value absolute)';
    }
  }
}
