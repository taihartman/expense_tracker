/// Mode for splitting absolute-value extras (fees, discounts, tips)
///
/// Defines how absolute-value extras should be distributed among participants
enum AbsoluteSplitMode {
  /// Proportional to each person's item subtotals
  /// Example: $10 fee, person A has $30 items (60%), person B has $20 items (40%)
  /// → A pays $6 fee, B pays $4 fee
  proportionalToItemsSubtotal('Proportional to Items'),

  /// Even across all assigned people
  /// Example: $10 fee, 3 people → each pays $3.33
  evenAcrossAssignedPeople('Split Evenly');

  /// Display name for UI
  final String displayName;

  const AbsoluteSplitMode(this.displayName);

  /// Parse from string
  static AbsoluteSplitMode? fromString(String value) {
    switch (value.toLowerCase()) {
      case 'proportionaltoitemssubtotal':
      case 'proportional_to_items_subtotal':
      case 'proportional':
        return AbsoluteSplitMode.proportionalToItemsSubtotal;
      case 'evenacrossassignedpeople':
      case 'even_across_assigned_people':
      case 'even':
        return AbsoluteSplitMode.evenAcrossAssignedPeople;
      default:
        return null;
    }
  }

  /// Convert to string for serialization
  String toFirestore() {
    return toString().split('.').last;
  }
}
