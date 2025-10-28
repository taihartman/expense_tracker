/// ISO 4217 currency precision lookup
///
/// Provides decimal places (minor units) for standard currencies
/// based on ISO 4217 specification
class Iso4217Precision {
  /// Map of currency code to decimal places
  static const Map<String, int> _precisionMap = {
    // Zero decimal currencies
    'BIF': 0, // Burundian Franc
    'CLP': 0, // Chilean Peso
    'DJF': 0, // Djiboutian Franc
    'GNF': 0, // Guinean Franc
    'ISK': 0, // Icelandic Króna
    'JPY': 0, // Japanese Yen
    'KMF': 0, // Comorian Franc
    'KRW': 0, // South Korean Won
    'PYG': 0, // Paraguayan Guaraní
    'RWF': 0, // Rwandan Franc
    'UGX': 0, // Ugandan Shilling
    'VND': 0, // Vietnamese Dong
    'VUV': 0, // Vanuatu Vatu
    'XAF': 0, // Central African CFA Franc
    'XOF': 0, // West African CFA Franc
    'XPF': 0, // CFP Franc

    // Three decimal currencies
    'BHD': 3, // Bahraini Dinar
    'IQD': 3, // Iraqi Dinar
    'JOD': 3, // Jordanian Dinar
    'KWD': 3, // Kuwaiti Dinar
    'LYD': 3, // Libyan Dinar
    'OMR': 3, // Omani Rial
    'TND': 3, // Tunisian Dinar

    // Standard two decimal currencies (most common)
    'USD': 2, // United States Dollar
    'EUR': 2, // Euro
    'GBP': 2, // British Pound
    'AUD': 2, // Australian Dollar
    'CAD': 2, // Canadian Dollar
    'CHF': 2, // Swiss Franc
    'CNY': 2, // Chinese Yuan
    'HKD': 2, // Hong Kong Dollar
    'INR': 2, // Indian Rupee
    'MXN': 2, // Mexican Peso
    'NZD': 2, // New Zealand Dollar
    'SEK': 2, // Swedish Krona
    'SGD': 2, // Singapore Dollar
    'THB': 2, // Thai Baht
  };

  /// Get decimal places for a currency code
  ///
  /// Returns the number of decimal places (minor units) for the given currency.
  /// Defaults to 2 if currency is not found in the map.
  ///
  /// Example:
  /// ```dart
  /// Iso4217Precision.getDecimalPlaces('USD') // 2
  /// Iso4217Precision.getDecimalPlaces('VND') // 0
  /// Iso4217Precision.getDecimalPlaces('BHD') // 3
  /// Iso4217Precision.getDecimalPlaces('XXX') // 2 (unknown, default)
  /// ```
  static int getDecimalPlaces(String currencyCode) {
    return _precisionMap[currencyCode.toUpperCase()] ?? 2;
  }

  /// Check if a currency uses zero decimal places
  static bool isZeroDecimalCurrency(String currencyCode) {
    return getDecimalPlaces(currencyCode) == 0;
  }

  /// Check if a currency uses three decimal places
  static bool isThreeDecimalCurrency(String currencyCode) {
    return getDecimalPlaces(currencyCode) == 3;
  }

  /// Get all supported currency codes
  static List<String> get supportedCurrencies =>
      _precisionMap.keys.toList()..sort();
}
