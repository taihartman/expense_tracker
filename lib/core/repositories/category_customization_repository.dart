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

  /// Checks if a specific user has customized a category
  ///
  /// Used to determine whether to show icon picker (first time) or skip it
  /// (user has already customized this category before).
  ///
  /// Parameters:
  /// - [tripId]: ID of the trip
  /// - [categoryId]: ID of the category to check
  /// - [userId]: ID of the user (Participant ID)
  ///
  /// Returns:
  /// - `Future<bool>` - True if user has customized this category, false otherwise
  ///
  /// Behavior:
  /// - Queries Firestore for customization document
  /// - Checks if userId matches current user
  /// - Returns false if document doesn't exist or userId doesn't match
  ///
  /// Performance:
  /// - Target: <200ms (reads from cache if available)
  Future<bool> hasUserCustomizedCategory(
    String tripId,
    String categoryId,
    String userId,
  );

  /// Records an icon preference vote for implicit crowd-sourced voting
  ///
  /// When a user customizes a category icon, this method records their
  /// preference. When 3+ users choose the same icon, the global category
  /// icon automatically updates to that icon.
  ///
  /// Parameters:
  /// - [categoryId]: ID of the category being customized
  /// - [iconName]: Icon name the user chose (e.g., "restaurant")
  ///
  /// Returns:
  /// - `Future<void>` - Completes when vote is recorded
  ///
  /// Behavior:
  /// - Uses Firestore transaction for atomic vote counting
  /// - Increments voteCount for the chosen icon
  /// - Recalculates mostPopular icon for this category
  /// - If threshold (3 votes) reached, updates global category icon
  /// - Non-blocking: failures don't affect customization save
  ///
  /// Errors:
  /// - Catches and logs errors (never throws to avoid blocking customization)
  /// - Retries transaction if write conflict occurs
  ///
  /// Performance:
  /// - Target: <300ms (best effort, non-blocking)
  /// - Transaction ensures consistency under concurrent votes
  Future<void> recordIconPreference(String categoryId, String iconName);
}
