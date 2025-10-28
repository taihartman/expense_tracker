import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';
import 'item_assignment.dart';

/// Represents a single line item on a receipt
///
/// Each line item has a name, quantity, unit price, and assignment to participants.
/// Tax and service charge flags determine which extras apply to this item.
class LineItem extends Equatable {
  /// Unique identifier
  final String id;

  /// Item name/description (e.g., "Pho Tai", "Spring Rolls")
  /// Must not be empty
  final String name;

  /// Quantity (supports fractional, e.g., 0.5 bottles)
  /// Must be > 0
  final Decimal quantity;

  /// Price per unit in expense currency
  /// Must be >= 0 (zero allowed for free items)
  final Decimal unitPrice;

  /// Whether tax applies to this item
  final bool taxable;

  /// Whether service charges apply to this item
  final bool serviceChargeable;

  /// How this item is assigned to participants
  final ItemAssignment assignment;

  const LineItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.taxable,
    required this.serviceChargeable,
    required this.assignment,
  });

  /// Calculate total price for this item (quantity * unitPrice)
  Decimal get itemTotal => quantity * unitPrice;

  /// Validate line item
  ///
  /// Returns error message if invalid, null if valid
  String? validate() {
    // Name must not be empty
    if (name.trim().isEmpty) {
      return 'Item name cannot be empty';
    }

    // Quantity must be positive
    if (quantity <= Decimal.zero) {
      return 'Quantity must be greater than 0';
    }

    // Unit price must be non-negative
    if (unitPrice < Decimal.zero) {
      return 'Unit price cannot be negative';
    }

    // Validate assignment
    final assignmentError = assignment.validate();
    if (assignmentError != null) {
      return 'Assignment error: $assignmentError';
    }

    return null;
  }

  /// Create a copy with updated fields
  LineItem copyWith({
    String? id,
    String? name,
    Decimal? quantity,
    Decimal? unitPrice,
    bool? taxable,
    bool? serviceChargeable,
    ItemAssignment? assignment,
  }) {
    return LineItem(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      taxable: taxable ?? this.taxable,
      serviceChargeable: serviceChargeable ?? this.serviceChargeable,
      assignment: assignment ?? this.assignment,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    quantity,
    unitPrice,
    taxable,
    serviceChargeable,
    assignment,
  ];

  @override
  String toString() {
    return 'LineItem(id: $id, name: $name, quantity: $quantity, unitPrice: $unitPrice, total: $itemTotal)';
  }
}
