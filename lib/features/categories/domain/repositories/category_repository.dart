import '../models/category.dart';

/// Repository interface for Category operations
///
/// Defines the contract for category data access
/// Implementation uses Firestore (see data/repositories/category_repository_impl.dart)
abstract class CategoryRepository {
  /// Create a new category
  /// Returns the created category with generated ID
  Future<Category> createCategory(Category category);

  /// Get a category by ID
  /// Returns null if category doesn't exist
  Future<Category?> getCategoryById(String categoryId);

  /// Get all categories for a trip
  /// Returns stream ordered by name
  Stream<List<Category>> getCategoriesByTrip(String tripId);

  /// Update an existing category
  /// Returns the updated category
  Future<Category> updateCategory(Category category);

  /// Delete a category by ID
  Future<void> deleteCategory(String categoryId);

  /// Check if a category exists
  Future<bool> categoryExists(String categoryId);

  /// Seed default categories for a new trip
  Future<List<Category>> seedDefaultCategories(String tripId);
}
