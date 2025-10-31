import '../models/category_customization.dart';

/// Repository interface for category customization operations
///
/// Implementations must handle:
/// - CRUD operations for trip-specific category customizations
/// - Stream-based real-time updates
/// - Efficient batch reads
/// - Graceful error handling
///
/// See contracts/repository_contract.md for detailed specifications.
abstract class CategoryCustomizationRepository {
  /// Loads all customizations for a specific trip
  ///
  /// Returns a stream that emits the complete list of customizations
  /// whenever any customization changes (add, update, delete).
  ///
  /// Parameters:
  /// - [tripId]: ID of the trip to load customizations for
  ///
  /// Returns:
  /// - `Stream<List<CategoryCustomization>>` - Real-time customizations list
  ///
  /// Behavior:
  /// - Empty list if no customizations exist
  /// - Updates automatically on remote changes
  /// - Stream never completes (closes on dispose)
  ///
  /// Errors:
  /// - Throws Exception if Firestore read fails
  /// - Emits error in stream if connection lost (can recover)
  ///
  /// Performance:
  /// - Target: <200ms for initial load
  /// - Supports up to 50 customizations per trip
  Stream<List<CategoryCustomization>> getCustomizationsForTrip(String tripId);

  /// Gets a specific customization for a category within a trip
  ///
  /// Returns null if no customization exists (category uses global defaults).
  ///
  /// Parameters:
  /// - [tripId]: ID of the trip
  /// - [categoryId]: ID of the category to get customization for
  ///
  /// Returns:
  /// - `Future<CategoryCustomization?>` - Customization or null
  ///
  /// Behavior:
  /// - Returns null if document doesn't exist (not an error)
  /// - Single read operation (not a stream)
  ///
  /// Errors:
  /// - Throws Exception if Firestore read fails
  ///
  /// Performance:
  /// - Target: <100ms
  /// - Should hit in-memory cache if possible
  Future<CategoryCustomization?> getCustomization(
    String tripId,
    String categoryId,
  );

  /// Saves a customization (create or update)
  ///
  /// If customization exists, updates it. Otherwise creates new.
  ///
  /// Parameters:
  /// - [customization]: The customization to save
  ///
  /// Returns:
  /// - `Future<void>` - Completes when save succeeds
  ///
  /// Behavior:
  /// - Sets updatedAt to current timestamp
  /// - Validates icon and color before saving
  /// - Overwrites existing customization if present
  ///
  /// Errors:
  /// - Throws Exception if validation fails
  /// - Throws Exception if Firestore write fails
  /// - Throws Exception if user lacks permissions
  ///
  /// Performance:
  /// - Target: <500ms
  Future<void> saveCustomization(CategoryCustomization customization);

  /// Deletes a customization (resets category to global defaults)
  ///
  /// Parameters:
  /// - [tripId]: ID of the trip
  /// - [categoryId]: ID of the category to reset
  ///
  /// Returns:
  /// - `Future<void>` - Completes when delete succeeds
  ///
  /// Behavior:
  /// - Deletes Firestore document
  /// - Does nothing if customization doesn't exist (not an error)
  ///
  /// Errors:
  /// - Throws Exception if Firestore delete fails
  /// - Throws Exception if user lacks permissions
  ///
  /// Performance:
  /// - Target: <500ms
  Future<void> deleteCustomization(String tripId, String categoryId);
}
