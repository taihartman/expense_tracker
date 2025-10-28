import 'package:equatable/equatable.dart';
import 'discount_extra.dart';
import 'fee_extra.dart';
import 'tax_extra.dart';
import 'tip_extra.dart';

/// Container for all extra charges and discounts
///
/// Includes tax, tip, fees, and discounts that apply to an itemized expense.
/// All fields are optional.
class Extras extends Equatable {
  /// Tax configuration (optional)
  final TaxExtra? tax;

  /// Tip configuration (optional)
  final TipExtra? tip;

  /// List of additional fees (optional, defaults to empty list)
  final List<FeeExtra> fees;

  /// List of discounts (optional, defaults to empty list)
  final List<DiscountExtra> discounts;

  const Extras({
    this.tax,
    this.tip,
    this.fees = const [],
    this.discounts = const [],
  });

  /// Validate all extras
  ///
  /// Returns error message if any extra is invalid, null if all valid
  String? validate() {
    // Validate tax
    if (tax != null) {
      final taxError = tax!.validate();
      if (taxError != null) {
        return 'Tax error: $taxError';
      }
    }

    // Validate tip
    if (tip != null) {
      final tipError = tip!.validate();
      if (tipError != null) {
        return 'Tip error: $tipError';
      }
    }

    // Validate fees
    for (int i = 0; i < fees.length; i++) {
      final feeError = fees[i].validate();
      if (feeError != null) {
        return 'Fee ${i + 1} error: $feeError';
      }
    }

    // Validate discounts
    for (int i = 0; i < discounts.length; i++) {
      final discountError = discounts[i].validate();
      if (discountError != null) {
        return 'Discount ${i + 1} error: $discountError';
      }
    }

    return null;
  }

  /// Create a copy with updated fields
  Extras copyWith({
    TaxExtra? tax,
    TipExtra? tip,
    List<FeeExtra>? fees,
    List<DiscountExtra>? discounts,
  }) {
    return Extras(
      tax: tax ?? this.tax,
      tip: tip ?? this.tip,
      fees: fees ?? this.fees,
      discounts: discounts ?? this.discounts,
    );
  }

  @override
  List<Object?> get props => [tax, tip, fees, discounts];

  @override
  String toString() {
    return 'Extras(tax: $tax, tip: $tip, fees: ${fees.length}, discounts: ${discounts.length})';
  }
}
