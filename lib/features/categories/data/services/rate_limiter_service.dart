import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../shared/services/firestore_service.dart';

/// Service for rate limiting user actions
///
/// Prevents spam by tracking user actions in a time window.
/// Currently used for category creation (3 per 5 minutes per user).
///
/// Future use cases:
/// - Trip creation rate limiting
/// - Expense creation rate limiting
/// - Invitation rate limiting
class RateLimiterService {
  final FirestoreService _firestoreService;

  RateLimiterService({required FirestoreService firestoreService})
    : _firestoreService = firestoreService;

  /// Check if a user can create a category
  ///
  /// Returns true if user can create (< 3 creations in last 5 minutes).
  /// Returns false if rate limit exceeded.
  ///
  /// Used to:
  /// - Disable "Create" button in UI when rate-limited
  /// - Show appropriate error message
  /// - Validate before attempting creation
  Future<bool> canUserCreateCategory(String userId) async {
    try {
      // Check if user has created 3+ categories in the last 5 minutes
      final fiveMinutesAgo = DateTime.now().subtract(
        const Duration(minutes: 5),
      );

      final querySnapshot = await _firestoreService.firestore
          .collection('categoryCreationLogs')
          .where('userId', isEqualTo: userId)
          .where('createdAt', isGreaterThan: Timestamp.fromDate(fiveMinutesAgo))
          .get();

      // Return true if user can create (< 3 recent creations)
      return querySnapshot.docs.length < 3;
    } catch (e) {
      throw Exception('Failed to check rate limit: $e');
    }
  }

  /// Log a category creation event for rate limiting
  ///
  /// Called after successfully creating a category.
  /// Creates an entry in categoryCreationLogs collection.
  ///
  /// Parameters:
  /// - userId: The ID of the user who created the category
  /// - categoryId: The ID of the created category
  /// - categoryName: The name of the created category (for debugging)
  Future<void> logCategoryCreation({
    required String userId,
    required String categoryId,
    required String categoryName,
  }) async {
    try {
      await _firestoreService.firestore.collection('categoryCreationLogs').add({
        'userId': userId,
        'categoryId': categoryId,
        'categoryName': categoryName,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to log category creation: $e');
    }
  }

  /// Get the number of recent category creations by a user
  ///
  /// Useful for showing the user how many creations they have left.
  ///
  /// Example: "You have created 2 categories recently. You can create 1 more."
  Future<int> getRecentCreationCount(String userId) async {
    try {
      final fiveMinutesAgo = DateTime.now().subtract(
        const Duration(minutes: 5),
      );

      final querySnapshot = await _firestoreService.firestore
          .collection('categoryCreationLogs')
          .where('userId', isEqualTo: userId)
          .where('createdAt', isGreaterThan: Timestamp.fromDate(fiveMinutesAgo))
          .get();

      return querySnapshot.docs.length;
    } catch (e) {
      throw Exception('Failed to get recent creation count: $e');
    }
  }

  /// Get the time remaining until the user can create another category
  ///
  /// Returns null if user can create now.
  /// Returns Duration if user is rate-limited.
  ///
  /// Used to show: "Please wait 2 minutes before creating more categories"
  Future<Duration?> getTimeUntilNextCreation(String userId) async {
    try {
      final fiveMinutesAgo = DateTime.now().subtract(
        const Duration(minutes: 5),
      );

      final querySnapshot = await _firestoreService.firestore
          .collection('categoryCreationLogs')
          .where('userId', isEqualTo: userId)
          .where('createdAt', isGreaterThan: Timestamp.fromDate(fiveMinutesAgo))
          .orderBy('createdAt', descending: false) // Oldest first
          .limit(1)
          .get();

      // If less than 3 recent creations, user can create now
      if (querySnapshot.docs.length < 3) {
        return null;
      }

      // Get the oldest creation timestamp
      final oldestDoc = querySnapshot.docs.first;
      final oldestCreation = (oldestDoc.data()['createdAt'] as Timestamp)
          .toDate();

      // Calculate when it will be 5 minutes since oldest creation
      final fiveMinutesAfterOldest = oldestCreation.add(
        const Duration(minutes: 5),
      );

      // Calculate remaining time
      final remaining = fiveMinutesAfterOldest.difference(DateTime.now());

      // Return remaining time if positive, otherwise null (can create now)
      return remaining.isNegative ? null : remaining;
    } catch (e) {
      throw Exception('Failed to get time until next creation: $e');
    }
  }
}
