import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/models/category_customization.dart';
import '../../../../core/repositories/category_customization_repository.dart';
import '../../../../shared/services/firestore_service.dart';
import '../models/category_customization_model.dart';

/// Implementation of CategoryCustomizationRepository using Firestore.
///
/// Manages per-trip category visual customizations (icon and color overrides)
/// stored in `/trips/{tripId}/categoryCustomizations/{categoryId}` subcollection.
class CategoryCustomizationRepositoryImpl
    implements CategoryCustomizationRepository {
  final FirestoreService _firestoreService;

  CategoryCustomizationRepositoryImpl({
    required FirestoreService firestoreService,
  }) : _firestoreService = firestoreService;

  /// Returns a stream of all category customizations for a specific trip.
  ///
  /// The stream emits updates in real-time when customizations are added,
  /// modified, or deleted.
  @override
  Stream<List<CategoryCustomization>> getCustomizationsForTrip(String tripId) {
    return _firestoreService.trips
        .doc(tripId)
        .collection('categoryCustomizations')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => CategoryCustomizationModel.fromFirestore(doc))
          .toList();
    });
  }

  /// Retrieves a single category customization for a trip.
  ///
  /// Returns null if no customization exists for the given category.
  @override
  Future<CategoryCustomization?> getCustomization(
    String tripId,
    String categoryId,
  ) async {
    final doc = await _firestoreService.trips
        .doc(tripId)
        .collection('categoryCustomizations')
        .doc(categoryId)
        .get();

    if (!doc.exists) {
      return null;
    }

    return CategoryCustomizationModel.fromFirestore(doc);
  }

  /// Saves or updates a category customization.
  ///
  /// Creates a new customization if it doesn't exist, or updates an existing one.
  @override
  Future<void> saveCustomization(CategoryCustomization customization) async {
    final model = CategoryCustomizationModel(
      categoryId: customization.categoryId,
      tripId: customization.tripId,
      customIcon: customization.customIcon,
      customColor: customization.customColor,
      updatedAt: customization.updatedAt,
    );

    await _firestoreService.trips
        .doc(customization.tripId)
        .collection('categoryCustomizations')
        .doc(customization.categoryId)
        .set(model.toFirestore(), SetOptions(merge: true));
  }

  /// Deletes a category customization, reverting to global defaults.
  @override
  Future<void> deleteCustomization(String tripId, String categoryId) async {
    await _firestoreService.trips
        .doc(tripId)
        .collection('categoryCustomizations')
        .doc(categoryId)
        .delete();
  }
}
