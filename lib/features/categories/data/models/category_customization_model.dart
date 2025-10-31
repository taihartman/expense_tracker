import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/models/category_customization.dart';

/// Firestore serialization model for CategoryCustomization
///
/// Handles conversion between Firestore documents and domain entities.
/// Document ID is the category ID for efficient lookup.
class CategoryCustomizationModel extends CategoryCustomization {
  const CategoryCustomizationModel({
    required super.categoryId,
    required super.tripId,
    super.customIcon,
    super.customColor,
    required super.updatedAt,
  });

  /// Creates CategoryCustomization from Firestore document
  ///
  /// Document structure:
  /// ```
  /// /trips/{tripId}/categoryCustomizations/{categoryId} {
  ///   tripId: string,
  ///   customIcon?: string,
  ///   customColor?: string,
  ///   updatedAt: timestamp
  /// }
  /// ```
  factory CategoryCustomizationModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return CategoryCustomizationModel(
      categoryId: doc.id, // Document ID is the category ID
      tripId: data['tripId'] as String,
      customIcon: data['customIcon'] as String?,
      customColor: data['customColor'] as String?,
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  /// Converts CategoryCustomization to Firestore document data
  ///
  /// Note: categoryId is NOT included in the document data because it's
  /// used as the document ID itself.
  Map<String, dynamic> toFirestore() {
    return {
      'tripId': tripId,
      if (customIcon != null) 'customIcon': customIcon,
      if (customColor != null) 'customColor': customColor,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Creates model from domain entity
  factory CategoryCustomizationModel.fromDomain(
    CategoryCustomization customization,
  ) {
    return CategoryCustomizationModel(
      categoryId: customization.categoryId,
      tripId: customization.tripId,
      customIcon: customization.customIcon,
      customColor: customization.customColor,
      updatedAt: customization.updatedAt,
    );
  }
}
