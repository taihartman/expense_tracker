import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';
import 'percent_base.dart';

/// Discount configuration for itemized expenses
///
/// Supports discounts like coupons, promos, etc.
/// Can be percentage-based or absolute amount.
class DiscountExtra extends Equatable {
  /// Unique identifier for this discount
  final String id;

  /// Discount name/description (e.g., "20% Off Coupon", "Early Bird Discount")
  final String name;

  /// Type of discount: 'percent' or 'amount'
  final String type;

  /// Discount value
  /// - For percent: percentage as decimal (e.g., 20.0 for 20%)
  /// - For amount: absolute amount in expense currency
  /// Must be > 0
  final Decimal value;

  /// Base for percentage calculation (required if type is 'percent', null if 'amount')
  final PercentBase? base;

  const DiscountExtra({
    required this.id,
    required this.name,
    required this.type,
    required this.value,
    this.base,
  });

  /// Validate discount configuration
  ///
  /// Returns error message if invalid, null if valid
  String? validate() {
    // ID must not be empty
    if (id.trim().isEmpty) {
      return 'Discount ID cannot be empty';
    }

    // Name must not be empty
    if (name.trim().isEmpty) {
      return 'Discount name cannot be empty';
    }

    // Type must be 'percent' or 'amount'
    if (type != 'percent' && type != 'amount') {
      return 'Type must be "percent" or "amount"';
    }

    // Value must be positive
    if (value <= Decimal.zero) {
      return 'Discount value must be greater than 0';
    }

    // If percent type, base is required
    if (type == 'percent' && base == null) {
      return 'Percent-based discount requires a base';
    }

    // If amount type, base must be null
    if (type == 'amount' && base != null) {
      return 'Amount-based discount cannot have a base';
    }

    return null;
  }

  /// Create a copy with updated fields
  DiscountExtra copyWith({
    String? id,
    String? name,
    String? type,
    Decimal? value,
    PercentBase? base,
  }) {
    return DiscountExtra(
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
      return 'DiscountExtra($name: $value% on ${base?.displayName})';
    } else {
      return 'DiscountExtra($name: \$$value absolute)';
    }
  }
}
