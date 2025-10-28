/// Mode for distributing rounding remainders
///
/// After rounding each person's total, there may be a small remainder
/// (e.g., $0.01) to ensure sum of rounded amounts equals grand total.
/// This enum defines who receives that remainder.
enum RemainderDistributionMode {
  /// Person with largest share gets remainder
  /// Most fair: person paying most gets the extra penny
  /// Example: 3 people, remainder $0.01 → person with $15.50 gets it (becomes $15.51)
  largestShare('Largest Share'),

  /// Payer gets remainder
  /// Generous payer scenario: payer covers the rounding difference
  /// Example: Payer already paid $50, gets +$0.01 → pays $50.01
  payer('Payer'),

  /// First listed participant gets remainder
  /// Deterministic and simple
  /// Example: Participants [Alice, Bob, Charlie] → Alice gets remainder
  firstListed('First Listed'),

  /// Random participant gets remainder
  /// Fair over many expenses, non-deterministic
  /// Example: Random selection from assigned participants
  random('Random');

  /// Display name for UI
  final String displayName;

  const RemainderDistributionMode(this.displayName);

  /// Parse from string
  static RemainderDistributionMode? fromString(String value) {
    switch (value.toLowerCase()) {
      case 'largestshare':
      case 'largest_share':
      case 'largest':
        return RemainderDistributionMode.largestShare;
      case 'payer':
        return RemainderDistributionMode.payer;
      case 'firstlisted':
      case 'first_listed':
      case 'first':
        return RemainderDistributionMode.firstListed;
      case 'random':
        return RemainderDistributionMode.random;
      default:
        return null;
    }
  }

  /// Convert to string for serialization
  String toFirestore() {
    return toString().split('.').last;
  }
}
