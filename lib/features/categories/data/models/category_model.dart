import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/category.dart';

/// Firestore model for Category entity
///
/// Handles serialization/deserialization between domain entity and Firestore documents
class CategoryModel {
  /// Convert Category domain entity to Firestore JSON
  static Map<String, dynamic> toJson(Category category) {
    return {
      'tripId': category.tripId,
      'name': category.name,
      'icon': category.icon,
      'color': category.color,
    };
  }

  /// Convert Firestore document to Category domain entity
  static Category fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Category(
      id: doc.id,
      tripId: data['tripId'] as String,
      name: data['name'] as String,
      icon: data['icon'] as String?,
      color: data['color'] as String?,
    );
  }

  /// Convert Firestore document snapshot to Category domain entity
  static Category fromSnapshot(DocumentSnapshot snapshot) {
    return fromFirestore(snapshot);
  }
}
