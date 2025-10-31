import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/category.dart';

/// Firestore model for Category entity
///
/// Handles serialization/deserialization between domain entity and Firestore documents.
/// Categories are stored in a global top-level collection shared across all trips.
class CategoryModel {
  /// Convert Category domain entity to Firestore JSON
  ///
  /// Used when creating or updating category documents in Firestore.
  /// The ID field is stored as the document ID, not in the data.
  static Map<String, dynamic> toJson(Category category) {
    return {
      'name': category.name,
      'nameLowercase': category.nameLowercase,
      'icon': category.icon,
      'color': category.color,
      'usageCount': category.usageCount,
      'createdAt': Timestamp.fromDate(category.createdAt),
      'updatedAt': Timestamp.fromDate(category.updatedAt),
    };
  }

  /// Convert Firestore document to Category domain entity
  ///
  /// Handles both newly created documents and existing ones.
  /// Provides sensible defaults for missing fields to support migration.
  static Category fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Category(
      id: doc.id,
      name: data['name'] as String,
      nameLowercase:
          data['nameLowercase'] as String? ??
          (data['name'] as String).toLowerCase(),
      icon: data['icon'] as String? ?? 'label', // Default icon
      color: data['color'] as String,
      usageCount:
          data['usageCount'] as int? ??
          0, // Default to 0 for migrated categories
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert Firestore document snapshot to Category domain entity
  ///
  /// Alias for fromFirestore for backward compatibility
  static Category fromSnapshot(DocumentSnapshot snapshot) {
    return fromFirestore(snapshot);
  }

  /// Create a new category with auto-generated timestamps
  ///
  /// Helper method for creating new categories with proper initialization
  static Category createNew({
    required String id,
    required String name,
    String icon = 'label',
    required String color,
  }) {
    final now = DateTime.now();
    return Category(
      id: id,
      name: name,
      nameLowercase: name.toLowerCase(),
      icon: icon,
      color: color,
      usageCount: 0,
      createdAt: now,
      updatedAt: now,
    );
  }
}
