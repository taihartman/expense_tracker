import 'package:flutter/widgets.dart';
import '../l10n/l10n_extensions.dart';

/// Supported currency codes for the expense tracker
///
/// MVP supports USD (United States Dollar) and VND (Vietnamese Dong)
enum CurrencyCode {
  /// United States Dollar (2 decimal places)
  usd('USD', 2),

  /// Vietnamese Dong (0 decimal places)
  vnd('VND', 0);

  /// Currency code as string (e.g., "USD", "VND")
  final String code;

  /// Number of decimal places for this currency
  final int decimalPlaces;

  const CurrencyCode(this.code, this.decimalPlaces);

  /// Parse currency code from string
  /// Returns null if not found
  static CurrencyCode? fromString(String code) {
    switch (code.toUpperCase()) {
      case 'USD':
        return CurrencyCode.usd;
      case 'VND':
        return CurrencyCode.vnd;
      default:
        return null;
    }
  }

  /// Get localized display name for this currency
  String displayName(BuildContext context) {
    switch (this) {
      case CurrencyCode.usd:
        return context.l10n.currencyUSD;
      case CurrencyCode.vnd:
        return context.l10n.currencyVND;
    }
  }

  /// Get currency symbol for display
  String get symbol {
    switch (this) {
      case CurrencyCode.usd:
        return '\$';
      case CurrencyCode.vnd:
        return '₫';
    }
  }

  @override
  String toString() => code;
}
