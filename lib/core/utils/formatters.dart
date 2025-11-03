import 'package:intl/intl.dart';
import 'package:decimal/decimal.dart';
import '../models/currency_code.dart';
import 'decimal_helpers.dart';

/// Currency formatters for USD (2 decimal places) and VND (0 decimal places)
class CurrencyFormatters {
  /// Format USD with 2 decimal places and $ symbol
  /// Example: formatUSD(Decimal.parse("123.45")) -> "$123.45"
  static String formatUSD(Decimal amount) {
    final formatter = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    return formatter.format(double.parse(DecimalHelpers.toFixed(amount, 2)));
  }

  /// Format VND with 0 decimal places and ₫ symbol
  /// Example: formatVND(Decimal.parse("500000")) -> "₫500,000"
  static String formatVND(Decimal amount) {
    final formatter = NumberFormat.currency(symbol: '₫', decimalDigits: 0);
    return formatter.format(double.parse(DecimalHelpers.toFixed(amount, 0)));
  }

  /// Format currency based on currency code
  /// Example: formatCurrency("USD", Decimal.parse("123.45")) -> "$123.45"
  static String formatCurrency(String currencyCode, Decimal amount) {
    // Parse currency code to enum
    final currency = CurrencyCode.fromString(currencyCode);
    if (currency == null) {
      return amount.toString();
    }

    // Use currency's metadata for formatting
    final formatter = NumberFormat.currency(
      symbol: currency.symbol,
      decimalDigits: currency.decimalPlaces,
    );

    return formatter.format(
      double.parse(DecimalHelpers.toFixed(amount, currency.decimalPlaces)),
    );
  }

  /// Get decimal places for currency
  static int getDecimalPlaces(String currencyCode) {
    final currency = CurrencyCode.fromString(currencyCode);
    return currency?.decimalPlaces ?? 2;
  }
}

/// Date formatters
class DateFormatters {
  /// Format date as YYYY-MM-DD (Firestore storage format)
  static String formatDateForStorage(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  /// Format date for display (e.g., "Oct 20, 2025")
  static String formatDateForDisplay(DateTime date) {
    return DateFormat('MMM d, y').format(date);
  }

  /// Format timestamp for display (e.g., "Oct 20, 2025 3:45 PM")
  static String formatTimestampForDisplay(DateTime timestamp) {
    return DateFormat('MMM d, y h:mm a').format(timestamp);
  }

  /// Parse date string from storage format
  static DateTime parseDateFromStorage(String dateString) {
    return DateFormat('yyyy-MM-dd').parse(dateString);
  }
}

/// Simplified formatters for common use
class Formatters {
  /// Format currency with appropriate symbol and decimals based on CurrencyCode enum
  static String formatCurrency(Decimal amount, CurrencyCode currencyCode) {
    return CurrencyFormatters.formatCurrency(currencyCode.code, amount);
  }
}
