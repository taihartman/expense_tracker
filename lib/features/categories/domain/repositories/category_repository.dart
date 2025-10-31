import '../models/category.dart';

/// Repository interface for global Category operations
///
/// Defines the contract for category data access in the global category system.
/// Categories are shared across all trips and users.
///
/// Implementation uses Firestore (see data/repositories/category_repository_impl.dart)
abstract class CategoryRepository {
  /// Get the top N most popular categories ordered by usage count
  ///
  /// Returns a stream of categories sorted by usageCount descending.
  /// Default limit is 5 for the chip selector, but can be customized.
  ///
  /// Used for:
  /// - Displaying top 5 categories in expense form chip selector
  /// - Populating category browser with popular categories first
  Stream<List<Category>> getTopCategories({int limit = 5});

  /// Search categories by name (case-insensitive, partial matching)
  ///
  /// Returns a stream of categories matching the search query.
  /// Results are ordered by relevance (exact match first, then by usage count).
  ///
  /// Empty query returns all categories sorted by usage count.
  ///
  /// Examples:
  /// - "meal" matches "Meals", "Meal Plan", "Mealkit"
  /// - "FOOD" matches "food", "Food & Drinks" (case-insensitive)
  Stream<List<Category>> searchCategories(String query);

  /// Get a specific category by its unique ID
  ///
  /// Returns null if category doesn't exist.
  ///
  /// Used for:
  /// - Displaying category details in expense cards
  /// - Resolving category references
  Future<Category?> getCategoryById(String categoryId);

  /// Create a new category in the global pool
  ///
  /// Parameters:
  /// - name: Category display name (1-50 chars, validated)
  /// - icon: Material icon name (defaults to "label")
  /// - color: Hex color code (e.g., "#FF5722")
  /// - userId: Current user ID for rate limiting and activity logging
  ///
  /// Returns: The created category with auto-generated ID and timestamps
  ///
  /// Throws:
  /// - Exception if validation fails (invalid name format)
  /// - Exception if duplicate name exists (case-insensitive)
  /// - Exception if user is rate-limited (3 creations per 5 minutes)
  ///
  /// Side effects:
  /// - Logs entry in categoryCreationLogs for rate limiting
  /// - May update categoryIconUsage statistics
  Future<Category> createCategory({
    required String name,
    String icon = 'label',
    required String color,
    required String userId,
  });

  /// Increment the usage count for a category
  ///
  /// Called when a category is assigned to an expense.
  /// Updates usageCount and updatedAt timestamp.
  ///
  /// This operation is typically batched with expense creation.
  Future<void> incrementCategoryUsage(String categoryId);

  /// Check if a category with the given name already exists (case-insensitive)
  ///
  /// Used to prevent duplicate category creation.
  ///
  /// Examples:
  /// - categoryExists("Meals") checks for "meals", "MEALS", "Meals"
  Future<bool> categoryExists(String name);

  /// Check if a user can create another category (rate limiting)
  ///
  /// Returns true if user can create a category (< 3 in last 5 minutes).
  /// Returns false if rate limit exceeded.
  ///
  /// Used to:
  /// - Disable "Create" button in UI when rate-limited
  /// - Show appropriate error message
  Future<bool> canUserCreateCategory(String userId);

  /// Seed the global category pool with default categories
  ///
  /// Called on system initialization if the global pool is empty.
  /// Creates 6 default categories: Meals, Transport, Accommodation, Activities, Shopping, Other
  ///
  /// This replaces the old trip-specific seeding.
  /// Only needs to run once for the entire system.
  Future<List<Category>> seedDefaultCategories();
}
