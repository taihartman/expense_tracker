/// How an expense should be split among participants
enum SplitType {
  /// Divide evenly among all participants
  /// All participants have weight = 1
  equal('Equal'),

  /// Divide proportionally by custom weights
  /// Each participant has a custom weight > 0
  weighted('Weighted'),

  /// Itemized receipt splitting
  /// Line items assigned to people with calculated per-person amounts
  itemized('Itemized');

  /// Display name for UI
  final String displayName;

  const SplitType(this.displayName);

  /// Parse split type from string
  /// Returns null if not found
  static SplitType? fromString(String value) {
    switch (value.toLowerCase()) {
      case 'equal':
        return SplitType.equal;
      case 'weighted':
        return SplitType.weighted;
      case 'itemized':
        return SplitType.itemized;
      default:
        return null;
    }
  }

  @override
  String toString() => displayName;
}
