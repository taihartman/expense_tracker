import 'package:decimal/decimal.dart';
import '../../domain/models/item_contribution.dart';
import '../../domain/models/participant_breakdown.dart';

/// Firestore model for ParticipantBreakdown entity
///
/// Handles serialization/deserialization between domain entity and Firestore documents
class ParticipantBreakdownModel {
  /// Convert ParticipantBreakdown domain entity to Firestore JSON
  static Map<String, dynamic> toJson(ParticipantBreakdown breakdown) {
    return {
      'userId': breakdown.userId,
      'itemsSubtotal': breakdown.itemsSubtotal
          .toString(), // Store as string for precision
      'extrasAllocated': breakdown.extrasAllocated.map(
        (key, value) => MapEntry(key, value.toString()),
      ),
      'roundedAdjustment': breakdown.roundedAdjustment
          .toString(), // Store as string for precision
      'total': breakdown.total.toString(), // Store as string for precision
      'items': breakdown.items.map(_itemContributionToJson).toList(),
    };
  }

  /// Convert Firestore JSON to ParticipantBreakdown domain entity
  static ParticipantBreakdown fromJson(Map<String, dynamic> data) {
    return ParticipantBreakdown(
      userId: data['userId'] as String,
      itemsSubtotal: Decimal.parse(data['itemsSubtotal'] as String),
      extrasAllocated: (data['extrasAllocated'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, Decimal.parse(value as String)),
      ),
      roundedAdjustment: Decimal.parse(data['roundedAdjustment'] as String),
      total: Decimal.parse(data['total'] as String),
      items: (data['items'] as List)
          .map(
            (item) => _itemContributionFromJson(item as Map<String, dynamic>),
          )
          .toList(),
    );
  }

  /// Convert ItemContribution to JSON (inline serialization)
  static Map<String, dynamic> _itemContributionToJson(
    ItemContribution contribution,
  ) {
    return {
      'itemId': contribution.itemId,
      'itemName': contribution.itemName,
      'quantity': contribution.quantity.toString(),
      'unitPrice': contribution.unitPrice.toString(),
      'assignedShare': contribution.assignedShare.toString(),
    };
  }

  /// Convert JSON to ItemContribution (inline deserialization)
  static ItemContribution _itemContributionFromJson(Map<String, dynamic> data) {
    return ItemContribution(
      itemId: data['itemId'] as String,
      itemName: data['itemName'] as String,
      quantity: Decimal.parse(data['quantity'] as String),
      unitPrice: Decimal.parse(data['unitPrice'] as String),
      assignedShare: Decimal.parse(data['assignedShare'] as String),
    );
  }
}
