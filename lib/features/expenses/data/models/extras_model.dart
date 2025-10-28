import 'package:decimal/decimal.dart';
import '../../domain/models/discount_extra.dart';
import '../../domain/models/extras.dart';
import '../../domain/models/fee_extra.dart';
import '../../domain/models/percent_base.dart';
import '../../domain/models/tax_extra.dart';
import '../../domain/models/tip_extra.dart';

/// Firestore model for Extras entity
///
/// Handles serialization/deserialization between domain entity and Firestore documents
class ExtrasModel {
  /// Convert Extras domain entity to Firestore JSON
  static Map<String, dynamic> toJson(Extras extras) {
    return {
      if (extras.tax != null) 'tax': _taxToJson(extras.tax!),
      if (extras.tip != null) 'tip': _tipToJson(extras.tip!),
      'fees': extras.fees.map(_feeToJson).toList(),
      'discounts': extras.discounts.map(_discountToJson).toList(),
    };
  }

  /// Convert Firestore JSON to Extras domain entity
  static Extras fromJson(Map<String, dynamic> data) {
    return Extras(
      tax: data['tax'] != null
          ? _taxFromJson(data['tax'] as Map<String, dynamic>)
          : null,
      tip: data['tip'] != null
          ? _tipFromJson(data['tip'] as Map<String, dynamic>)
          : null,
      fees:
          (data['fees'] as List?)
              ?.map((item) => _feeFromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      discounts:
          (data['discounts'] as List?)
              ?.map((item) => _discountFromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  /// Convert TaxExtra to JSON (inline serialization)
  static Map<String, dynamic> _taxToJson(TaxExtra tax) {
    return {
      'type': tax.type,
      'value': tax.value.toString(),
      if (tax.base != null) 'base': tax.base!.name,
    };
  }

  /// Convert JSON to TaxExtra (inline deserialization)
  static TaxExtra _taxFromJson(Map<String, dynamic> data) {
    return TaxExtra(
      type: data['type'] as String,
      value: Decimal.parse(data['value'] as String),
      base: data['base'] != null
          ? PercentBase.fromString(data['base'] as String)
          : null,
    );
  }

  /// Convert TipExtra to JSON (inline serialization)
  static Map<String, dynamic> _tipToJson(TipExtra tip) {
    return {
      'type': tip.type,
      'value': tip.value.toString(),
      if (tip.base != null) 'base': tip.base!.name,
    };
  }

  /// Convert JSON to TipExtra (inline deserialization)
  static TipExtra _tipFromJson(Map<String, dynamic> data) {
    return TipExtra(
      type: data['type'] as String,
      value: Decimal.parse(data['value'] as String),
      base: data['base'] != null
          ? PercentBase.fromString(data['base'] as String)
          : null,
    );
  }

  /// Convert FeeExtra to JSON (inline serialization)
  static Map<String, dynamic> _feeToJson(FeeExtra fee) {
    return {
      'id': fee.id,
      'name': fee.name,
      'type': fee.type,
      'value': fee.value.toString(),
      if (fee.base != null) 'base': fee.base!.name,
    };
  }

  /// Convert JSON to FeeExtra (inline deserialization)
  static FeeExtra _feeFromJson(Map<String, dynamic> data) {
    return FeeExtra(
      id: data['id'] as String,
      name: data['name'] as String,
      type: data['type'] as String,
      value: Decimal.parse(data['value'] as String),
      base: data['base'] != null
          ? PercentBase.fromString(data['base'] as String)
          : null,
    );
  }

  /// Convert DiscountExtra to JSON (inline serialization)
  static Map<String, dynamic> _discountToJson(DiscountExtra discount) {
    return {
      'id': discount.id,
      'name': discount.name,
      'type': discount.type,
      'value': discount.value.toString(),
      if (discount.base != null) 'base': discount.base!.name,
    };
  }

  /// Convert JSON to DiscountExtra (inline deserialization)
  static DiscountExtra _discountFromJson(Map<String, dynamic> data) {
    return DiscountExtra(
      id: data['id'] as String,
      name: data['name'] as String,
      type: data['type'] as String,
      value: Decimal.parse(data['value'] as String),
      base: data['base'] != null
          ? PercentBase.fromString(data['base'] as String)
          : null,
    );
  }
}
