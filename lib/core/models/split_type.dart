import 'package:flutter/widgets.dart';
import '../l10n/l10n_extensions.dart';

/// How an expense should be split among participants
enum SplitType {
  /// Divide evenly among all participants
  /// All participants have weight = 1
  equal,

  /// Divide proportionally by custom weights
  /// Each participant has a custom weight > 0
  weighted,

  /// Itemized receipt splitting
  /// Line items assigned to people with calculated per-person amounts
  itemized;

  /// Get localized display name for this split type
  String displayName(BuildContext context) {
    switch (this) {
      case SplitType.equal:
        return context.l10n.expenseSplitTypeEqual;
      case SplitType.weighted:
        return context.l10n.expenseSplitTypeWeighted;
      case SplitType.itemized:
        return context.l10n.expenseSplitTypeItemized;
    }
  }

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
  String toString() => name;
}
