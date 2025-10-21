import '../../../../core/constants/categories.dart';
import '../../../../shared/services/firestore_service.dart';
import '../../domain/models/category.dart';
import '../../domain/repositories/category_repository.dart';
import '../models/category_model.dart';

/// Firestore implementation of CategoryRepository
class CategoryRepositoryImpl implements CategoryRepository {
  final FirestoreService _firestoreService;

  CategoryRepositoryImpl({required FirestoreService firestoreService})
      : _firestoreService = firestoreService;

  @override
  Future<Category> createCategory(Category category) async {
    try {
      // Validate category data
      final error = category.validate();
      if (error != null) {
        throw ArgumentError(error);
      }

      // Create document reference with auto-generated ID
      final docRef = _firestoreService.categories.doc();

      // Create category with generated ID
      final newCategory = category.copyWith(id: docRef.id);

      // Save to Firestore
      await docRef.set(CategoryModel.toJson(newCategory));

      return newCategory;
    } catch (e) {
      throw Exception('Failed to create category: $e');
    }
  }

  @override
  Future<Category?> getCategoryById(String categoryId) async {
    try {
      final doc = await _firestoreService.categories.doc(categoryId).get();

      if (!doc.exists) {
        return null;
      }

      return CategoryModel.fromFirestore(doc);
    } catch (e) {
      throw Exception('Failed to get category: $e');
    }
  }

  @override
  Stream<List<Category>> getCategoriesByTrip(String tripId) {
    try {
      return _firestoreService.categories
          .where('tripId', isEqualTo: tripId)
          .orderBy('name')
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => CategoryModel.fromFirestore(doc))
            .toList();
      });
    } catch (e) {
      throw Exception('Failed to get categories stream: $e');
    }
  }

  @override
  Future<Category> updateCategory(Category category) async {
    try {
      // Validate category data
      final error = category.validate();
      if (error != null) {
        throw ArgumentError(error);
      }

      // Check if category exists
      final exists = await categoryExists(category.id);
      if (!exists) {
        throw Exception('Category not found: ${category.id}');
      }

      // Save to Firestore
      await _firestoreService.categories
          .doc(category.id)
          .update(CategoryModel.toJson(category));

      return category;
    } catch (e) {
      throw Exception('Failed to update category: $e');
    }
  }

  @override
  Future<void> deleteCategory(String categoryId) async {
    try {
      await _firestoreService.categories.doc(categoryId).delete();
    } catch (e) {
      throw Exception('Failed to delete category: $e');
    }
  }

  @override
  Future<bool> categoryExists(String categoryId) async {
    try {
      final doc = await _firestoreService.categories.doc(categoryId).get();
      return doc.exists;
    } catch (e) {
      throw Exception('Failed to check if category exists: $e');
    }
  }

  @override
  Future<List<Category>> seedDefaultCategories(String tripId) async {
    try {
      final batch = _firestoreService.batch();
      final createdCategories = <Category>[];

      for (final defaultCategory in DefaultCategories.all) {
        final docRef = _firestoreService.categories.doc();
        final category = Category(
          id: docRef.id,
          tripId: tripId,
          name: defaultCategory['name']!,
          icon: defaultCategory['icon'],
          color: defaultCategory['color'],
        );

        batch.set(docRef, CategoryModel.toJson(category));
        createdCategories.add(category);
      }

      await batch.commit();
      return createdCategories;
    } catch (e) {
      throw Exception('Failed to seed default categories: $e');
    }
  }
}
