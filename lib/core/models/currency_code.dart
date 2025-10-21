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

  @override
  String toString() => code;
}
