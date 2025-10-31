import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/categories.dart';
import '../../../../core/validators/category_validator.dart';
import '../../../../shared/services/firestore_service.dart';
import '../../domain/models/category.dart';
import '../../domain/repositories/category_repository.dart';
import '../models/category_model.dart';
import '../services/rate_limiter_service.dart';

/// Firestore implementation of CategoryRepository for global category system
///
/// Categories are stored in a top-level collection shared across all trips.
/// This implementation handles:
/// - Global category queries (top categories, search)
/// - Category creation with validation and rate limiting
/// - Usage tracking for popularity ranking
class CategoryRepositoryImpl implements CategoryRepository {
  final FirestoreService _firestoreService;
  final RateLimiterService _rateLimiterService;

  CategoryRepositoryImpl({
    required FirestoreService firestoreService,
    required RateLimiterService rateLimiterService,
  }) : _firestoreService = firestoreService,
       _rateLimiterService = rateLimiterService;

  @override
  Stream<List<Category>> getTopCategories({int limit = 5}) {
    try {
      return _firestoreService.categories
          .orderBy('usageCount', descending: true)
          .limit(limit)
          .snapshots()
          .map((snapshot) {
            return snapshot.docs
                .map((doc) => CategoryModel.fromFirestore(doc))
                .toList();
          });
    } catch (e) {
      throw Exception('Failed to get top categories: $e');
    }
  }

  @override
  Stream<List<Category>> searchCategories(String query) {
    try {
      // Empty query returns all categories sorted by usage
      if (query.trim().isEmpty) {
        return _firestoreService.categories
            .orderBy('usageCount', descending: true)
            .snapshots()
            .map((snapshot) {
              return snapshot.docs
                  .map((doc) => CategoryModel.fromFirestore(doc))
                  .toList();
            });
      }

      // Sanitize query for case-insensitive search
      final sanitizedQuery = CategoryValidator.sanitize(query);

      // Firestore range query for prefix matching
      // e.g., "meal" matches "meals", "mealkit"
      return _firestoreService.categories
          .where('nameLowercase', isGreaterThanOrEqualTo: sanitizedQuery)
          .where('nameLowercase', isLessThan: '$sanitizedQuery\uf8ff')
          .orderBy('nameLowercase')
          .orderBy('usageCount', descending: true)
          .snapshots()
          .map((snapshot) {
            return snapshot.docs
                .map((doc) => CategoryModel.fromFirestore(doc))
                .toList();
          });
    } catch (e) {
      throw Exception('Failed to search categories: $e');
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
  Future<Category> createCategory({
    required String name,
    String icon = 'label',
    required String color,
    required String userId,
  }) async {
    try {
      // 1. Validate category name
      final validationError = CategoryValidator.validateCategoryName(name);
      if (validationError != null) {
        throw ArgumentError(validationError);
      }

      // 2. Check for duplicates (case-insensitive)
      final exists = await categoryExists(name);
      if (exists) {
        throw Exception(
          'Category "$name" already exists (case-insensitive match)',
        );
      }

      // 3. Check rate limiting
      final canCreate = await _rateLimiterService.canUserCreateCategory(userId);
      if (!canCreate) {
        throw Exception(
          'Rate limit exceeded. Please wait before creating more categories.',
        );
      }

      // 4. Create category document
      final docRef = _firestoreService.categories.doc();
      final now = DateTime.now();

      final category = Category(
        id: docRef.id,
        name: name.trim(),
        nameLowercase: CategoryValidator.sanitize(name),
        icon: icon,
        color: color,
        usageCount: 0,
        createdAt: now,
        updatedAt: now,
      );

      // 5. Create category in Firestore
      await docRef.set(CategoryModel.toJson(category));

      // 6. Log creation for rate limiting
      await _rateLimiterService.logCategoryCreation(
        userId: userId,
        categoryId: docRef.id,
        categoryName: name.trim(),
      );

      return category;
    } catch (e) {
      if (e is ArgumentError ||
          e.toString().contains('already exists') ||
          e.toString().contains('Rate limit')) {
        rethrow;
      }
      throw Exception('Failed to create category: $e');
    }
  }

  @override
  Future<void> incrementCategoryUsage(String categoryId) async {
    try {
      await _firestoreService.categories.doc(categoryId).update({
        'usageCount': FieldValue.increment(1),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Failed to increment category usage: $e');
    }
  }

  @override
  Future<bool> categoryExists(String name) async {
    try {
      final sanitizedName = CategoryValidator.sanitize(name);

      final querySnapshot = await _firestoreService.categories
          .where('nameLowercase', isEqualTo: sanitizedName)
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      throw Exception('Failed to check if category exists: $e');
    }
  }

  @override
  Future<bool> canUserCreateCategory(String userId) async {
    try {
      return await _rateLimiterService.canUserCreateCategory(userId);
    } catch (e) {
      throw Exception('Failed to check rate limit: $e');
    }
  }

  @override
  Future<List<Category>> seedDefaultCategories() async {
    try {
      final batch = _firestoreService.batch();
      final createdCategories = <Category>[];
      final now = DateTime.now();

      for (final defaultCategory in DefaultCategories.all) {
        // Check if category already exists (case-insensitive)
        final exists = await categoryExists(defaultCategory['name']!);
        if (exists) {
          // Skip if already seeded
          continue;
        }

        final docRef = _firestoreService.categories.doc();
        final category = Category(
          id: docRef.id,
          name: defaultCategory['name']!,
          nameLowercase: defaultCategory['name']!.toLowerCase(),
          icon: defaultCategory['icon']!,
          color: defaultCategory['color']!,
          usageCount: 0,
          createdAt: now,
          updatedAt: now,
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
