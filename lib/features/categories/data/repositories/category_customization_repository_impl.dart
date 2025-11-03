import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/models/category_customization.dart';
import '../../../../core/repositories/category_customization_repository.dart';
import '../../../../shared/services/firestore_service.dart';
import '../models/category_customization_model.dart';
import '../models/category_icon_preference_model.dart';

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
    final model = CategoryCustomizationModel.fromDomain(customization);

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

  /// Checks if a specific user has customized a category
  @override
  Future<bool> hasUserCustomizedCategory(
    String tripId,
    String categoryId,
    String userId,
  ) async {
    final doc = await _firestoreService.trips
        .doc(tripId)
        .collection('categoryCustomizations')
        .doc(categoryId)
        .get();

    if (!doc.exists) return false;

    final data = doc.data();
    if (data == null) return false;

    // Check if userId matches (handles legacy docs without userId field)
    return data['userId'] == userId;
  }

  /// Records an icon preference vote for crowd-sourced icon improvement
  ///
  /// This method implements the voting system where users implicitly vote
  /// for better icons by customizing categories. When 3+ users choose the
  /// same icon, the global category icon automatically updates.
  ///
  /// Uses Firestore increment for atomic vote counting.
  ///
  /// Errors are caught and logged but never thrown to avoid blocking the
  /// main customization flow.
  @override
  Future<void> recordIconPreference(String categoryId, String iconName) async {
    try {
      // 1. Atomically increment vote count for this preference
      final preferenceDocId =
          CategoryIconPreferenceModel.generateDocumentId(categoryId, iconName);
      final preferenceRef =
          _firestoreService.categoryIconPreferences.doc(preferenceDocId);

      // Use set with merge to create if doesn't exist, update if it does
      await preferenceRef.set(
        {
          'categoryId': categoryId,
          'iconName': iconName,
          'voteCount': FieldValue.increment(1),
          'lastVoteAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      // 2. Query all preferences for this category to find most popular
      final allPreferencesSnapshot = await _firestoreService
          .categoryIconPreferences
          .where('categoryId', isEqualTo: categoryId)
          .get();

      if (allPreferencesSnapshot.docs.isEmpty) return;

      // Build list of preferences and find most popular
      final allPreferences = allPreferencesSnapshot.docs
          .map((doc) => CategoryIconPreferenceModel.fromQueryDocumentSnapshot(doc))
          .toList();

      // Sort by vote count (descending), then by lastVoteAt (most recent)
      allPreferences.sort((a, b) {
        final voteComparison = b.voteCount.compareTo(a.voteCount);
        if (voteComparison != 0) return voteComparison;
        return b.lastVoteAt.compareTo(a.lastVoteAt);
      });

      final mostPopular = allPreferences.first;

      // 3. Update mostPopular flags
      final batch = _firestoreService.batch();
      for (final pref in allPreferences) {
        final docId = CategoryIconPreferenceModel.generateDocumentId(
          pref.categoryId,
          pref.iconName,
        );
        final prefRef = _firestoreService.categoryIconPreferences.doc(docId);

        if (pref.iconName == mostPopular.iconName) {
          // Set mostPopular flag
          batch.update(prefRef, {'mostPopular': true});

          // 4. If threshold reached, update global category icon
          if (mostPopular.hasReachedThreshold()) {
            final categoryRef = _firestoreService.categories.doc(categoryId);
            batch.update(categoryRef, {
              'icon': mostPopular.iconName,
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }
        } else {
          // Clear mostPopular flag
          batch.update(prefRef, {'mostPopular': false});
        }
      }

      await batch.commit();
    } catch (e) {
      // Log error but don't throw - voting failures should never block customization
      // Silent failure - in production use proper logging service
      // debugPrint('Failed to record icon preference for $categoryId → $iconName: $e');
    }
  }
}
