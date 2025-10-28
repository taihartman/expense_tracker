import 'package:decimal/decimal.dart';
import '../../domain/models/assignment_mode.dart';
import '../../domain/models/item_assignment.dart';
import '../../domain/models/line_item.dart';

/// Firestore model for LineItem entity
///
/// Handles serialization/deserialization between domain entity and Firestore documents
class LineItemModel {
  /// Convert LineItem domain entity to Firestore JSON
  static Map<String, dynamic> toJson(LineItem lineItem) {
    return {
      'id': lineItem.id,
      'name': lineItem.name,
      'quantity': lineItem.quantity.toString(), // Store as string for precision
      'unitPrice': lineItem.unitPrice
          .toString(), // Store as string for precision
      'taxable': lineItem.taxable,
      'serviceChargeable': lineItem.serviceChargeable,
      'assignment': _assignmentToJson(lineItem.assignment),
    };
  }

  /// Convert Firestore JSON to LineItem domain entity
  static LineItem fromJson(Map<String, dynamic> data) {
    return LineItem(
      id: data['id'] as String,
      name: data['name'] as String,
      quantity: Decimal.parse(data['quantity'] as String),
      unitPrice: Decimal.parse(data['unitPrice'] as String),
      taxable: data['taxable'] as bool,
      serviceChargeable: data['serviceChargeable'] as bool,
      assignment: _assignmentFromJson(
        data['assignment'] as Map<String, dynamic>,
      ),
    );
  }

  /// Convert ItemAssignment to JSON (inline serialization)
  static Map<String, dynamic> _assignmentToJson(ItemAssignment assignment) {
    return {
      'mode': assignment.mode.name,
      'users': assignment.users,
      if (assignment.shares != null)
        'shares': assignment.shares!.map(
          (userId, share) => MapEntry(userId, share.toString()),
        ),
    };
  }

  /// Convert JSON to ItemAssignment (inline deserialization)
  static ItemAssignment _assignmentFromJson(Map<String, dynamic> data) {
    final mode =
        AssignmentMode.fromString(data['mode'] as String) ??
        AssignmentMode.even;
    final users = List<String>.from(data['users'] as List);

    Map<String, Decimal>? shares;
    if (data['shares'] != null) {
      final sharesData = data['shares'] as Map<String, dynamic>;
      shares = sharesData.map(
        (userId, value) => MapEntry(userId, Decimal.parse(value as String)),
      );
    }

    return ItemAssignment(mode: mode, users: users, shares: shares);
  }
}
