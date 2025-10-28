/// Rounding mode for monetary values
///
/// Defines how fractional cents/currency units are rounded
enum RoundingMode {
  /// Round half up (>= 0.5 rounds up, < 0.5 rounds down)
  /// Example: 1.235 → 1.24, 1.234 → 1.23
  /// Most common for financial applications
  roundHalfUp('Round Half Up'),

  /// Round half to even (banker's rounding)
  /// If exactly 0.5, round to nearest even number
  /// Example: 1.235 → 1.24 (4 is even), 1.245 → 1.24 (4 is even)
  /// Reduces accumulated rounding bias
  roundHalfEven('Round Half to Even'),

  /// Always round down (toward zero)
  /// Example: 1.239 → 1.23, 1.999 → 1.99
  floor('Round Down'),

  /// Always round up (away from zero)
  /// Example: 1.231 → 1.24, 1.001 → 1.01
  ceil('Round Up');

  /// Display name for UI
  final String displayName;

  const RoundingMode(this.displayName);

  /// Parse from string
  static RoundingMode? fromString(String value) {
    switch (value.toLowerCase()) {
      case 'roundhalfup':
      case 'round_half_up':
      case 'halfup':
        return RoundingMode.roundHalfUp;
      case 'roundhalfeven':
      case 'round_half_even':
      case 'halfeven':
      case 'banker':
        return RoundingMode.roundHalfEven;
      case 'floor':
      case 'down':
        return RoundingMode.floor;
      case 'ceil':
      case 'ceiling':
      case 'up':
        return RoundingMode.ceil;
      default:
        return null;
    }
  }

  /// Convert to string for serialization
  String toFirestore() {
    return toString().split('.').last;
  }
}
