import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';

/// Represents a single item contribution for a participant
///
/// Used in audit trail to show exactly which items contributed
/// to a person's total and by how much.
class ItemContribution extends Equatable {
  /// Line item ID
  final String itemId;

  /// Line item name
  final String itemName;

  /// Quantity of the item
  final Decimal quantity;

  /// Unit price of the item
  final Decimal unitPrice;

  /// Assigned share of this item (0.0 to 1.0)
  /// For even split of 2 people: 0.5
  /// For custom split: the user's specific share
  final Decimal assignedShare;

  const ItemContribution({
    required this.itemId,
    required this.itemName,
    required this.quantity,
    required this.unitPrice,
    required this.assignedShare,
  });

  /// Calculate this person's contribution amount
  /// (quantity * unitPrice * assignedShare)
  Decimal get contributionAmount => quantity * unitPrice * assignedShare;

  @override
  List<Object?> get props => [
        itemId,
        itemName,
        quantity,
        unitPrice,
        assignedShare,
      ];

  @override
  String toString() {
    return 'ItemContribution($itemName: ${assignedShare * Decimal.fromInt(100)}% = $contributionAmount)';
  }
}
