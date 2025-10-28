/// Mode for assigning a line item to people
///
/// Defines how an item's cost is split among assigned participants
enum AssignmentMode {
  /// Split evenly across all assigned users
  /// Example: $12 item assigned to 3 people → each pays $4
  even('Even Split'),

  /// Custom shares (normalized to sum to 1.0)
  /// Example: $12 item, person A: 0.66 (66%), person B: 0.34 (34%)
  /// → A pays $8, B pays $4
  custom('Custom Shares');

  /// Display name for UI
  final String displayName;

  const AssignmentMode(this.displayName);

  /// Parse from string
  static AssignmentMode? fromString(String value) {
    switch (value.toLowerCase()) {
      case 'even':
        return AssignmentMode.even;
      case 'custom':
        return AssignmentMode.custom;
      default:
        return null;
    }
  }

  /// Convert to string for serialization
  String toFirestore() {
    return toString().split('.').last;
  }
}
