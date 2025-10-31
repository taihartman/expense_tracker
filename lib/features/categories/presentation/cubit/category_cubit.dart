import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/validators/category_validator.dart';
import '../../../../core/services/auth_service.dart';
import '../../data/services/rate_limiter_service.dart';
import '../../domain/repositories/category_repository.dart';
import 'category_state.dart';

/// Cubit for managing global category operations
///
/// Handles:
/// - Loading top N popular categories for chip selector
/// - Searching categories with autocomplete
/// - Creating new categories with validation and rate limiting
/// - Incrementing category usage when assigned to expenses
/// - Checking rate limit status for UI feedback
class CategoryCubit extends Cubit<CategoryState> {
  final CategoryRepository _categoryRepository;
  final RateLimiterService _rateLimiterService;
  final AuthService _authService;

  // Stream subscriptions for cleanup
  StreamSubscription? _topCategoriesSubscription;
  StreamSubscription? _searchSubscription;

  // Cache tracking for top categories (24-hour TTL)
  DateTime? _lastTopCategoriesRefresh;
  static const _cacheDuration = Duration(hours: 24);

  CategoryCubit({
    required CategoryRepository categoryRepository,
    required RateLimiterService rateLimiterService,
    required AuthService authService,
  }) : _categoryRepository = categoryRepository,
       _rateLimiterService = rateLimiterService,
       _authService = authService,
       super(const CategoryInitial());

  /// Load top N popular categories (default: 5 for chip selector)
  ///
  /// Emits:
  /// - CategoryLoadingTop while loading
  /// - CategoryTopLoaded on success
  /// - CategoryError on failure
  ///
  /// Used for:
  /// - Expense form chip selector (top 5)
  /// - Category browser initial view (top 10+)
  void loadTopCategories({int limit = 5}) {
    debugPrint(
      '🔄 [CategoryCubit] loadTopCategories called with limit: $limit',
    );
    debugPrint('📍 [CategoryCubit] Stack trace:\n${StackTrace.current}');
    emit(const CategoryLoadingTop());

    _topCategoriesSubscription?.cancel();
    _topCategoriesSubscription = _categoryRepository
        .getTopCategories(limit: limit)
        .listen(
          (categories) {
            emit(CategoryTopLoaded(categories: categories));
            // Track refresh time for cache invalidation
            _lastTopCategoriesRefresh = DateTime.now();
          },
          onError: (error) {
            emit(
              CategoryError(
                message: 'Failed to load categories: $error',
                type: CategoryErrorType.loadFailed,
              ),
            );
          },
        );
  }

  /// Load top categories only if cache is stale (24+ hours old)
  ///
  /// This reduces Firebase reads by using a 24-hour TTL cache.
  /// If categories were loaded within the last 24 hours, does nothing.
  /// Otherwise, triggers a fresh query from Firebase.
  ///
  /// Use this instead of loadTopCategories() when restoring state
  /// (e.g., after closing "Browse & Create" bottom sheet).
  void loadTopCategoriesIfStale({int limit = 5}) {
    final now = DateTime.now();
    final isStale =
        _lastTopCategoriesRefresh == null ||
        now.difference(_lastTopCategoriesRefresh!) > _cacheDuration;

    if (isStale) {
      loadTopCategories(limit: limit);
    }
    // Otherwise, do nothing - use existing CategoryTopLoaded state
  }

  /// Invalidate top categories cache, forcing next load to be fresh
  ///
  /// Call this after:
  /// - Creating a new expense (to show updated usage counts)
  /// - Creating a new category
  /// - Any operation that might affect category popularity
  ///
  /// Next call to loadTopCategoriesIfStale() will fetch from Firebase.
  void invalidateTopCategoriesCache() {
    _lastTopCategoriesRefresh = null;
  }

  /// Search categories by name (case-insensitive, partial matching)
  ///
  /// Emits:
  /// - CategorySearching while searching
  /// - CategorySearchResults on success
  /// - CategoryError on failure
  ///
  /// Empty query returns all categories sorted by popularity.
  ///
  /// Examples:
  /// - "meal" matches "Meals", "Meal Plan", "Mealkit"
  /// - "FOOD" matches "food", "Food & Drinks"
  void searchCategories(String query) {
    _searchSubscription?.cancel();
    _searchSubscription = _categoryRepository
        .searchCategories(query)
        .listen(
          (results) {
            emit(CategorySearchResults(query: query, results: results));
          },
          onError: (error) {
            emit(
              CategoryError(
                message: 'Failed to search categories: $error',
                type: CategoryErrorType.searchFailed,
              ),
            );
          },
        );
  }

  /// Create a new category in the global pool
  ///
  /// Performs validation:
  /// 1. Authentication check
  /// 2. Name validation (1-50 chars, allowed characters)
  /// 3. Duplicate check (case-insensitive)
  /// 4. Rate limiting (3 per 5 minutes per user)
  ///
  /// Emits:
  /// - CategoryCreating while creating
  /// - CategoryCreated on success
  /// - CategoryError on validation/duplicate/rate limit failure
  ///
  /// Parameters:
  /// - name: Category display name (required)
  /// - icon: Material icon name (defaults to 'label')
  /// - color: Hex color code (required)
  ///
  /// Note: userId is obtained internally from AuthService for rate limiting.
  Future<void> createCategory({
    required String name,
    String icon = 'label',
    required String color,
  }) async {
    try {
      // 1. Get authenticated user ID for rate limiting
      final userId = _authService.getAuthUidForRateLimiting();
      if (userId == null) {
        emit(
          CategoryError(
            message: 'You must be logged in to create categories',
            type: CategoryErrorType.generic,
          ),
        );
        return;
      }

      // 2. Validate category name
      final validationError = CategoryValidator.validateCategoryName(name);
      if (validationError != null) {
        emit(
          CategoryError(
            message: validationError,
            type: CategoryErrorType.validation,
          ),
        );
        return;
      }

      // 3. Check for similar categories (prevents vote splitting)
      final similarCategories = await _categoryRepository.findSimilarCategories(
        name,
        threshold: 0.8,
        limit: 1,
      );
      if (similarCategories.isNotEmpty) {
        final similar = similarCategories.first;
        emit(
          CategoryError(
            message:
                'Category "${similar.category.name}" already exists. Please use the existing category instead.',
            type: CategoryErrorType.duplicate,
          ),
        );
        return;
      }

      // 4. Check rate limiting
      final canCreate = await _rateLimiterService.canUserCreateCategory(userId);
      if (!canCreate) {
        final timeUntilNext = await _rateLimiterService
            .getTimeUntilNextCreation(userId);
        final minutesRemaining = timeUntilNext?.inMinutes ?? 0;

        emit(
          CategoryError(
            message:
                'You\'ve created too many categories recently. Please wait $minutesRemaining minutes.',
            type: CategoryErrorType.rateLimit,
          ),
        );
        return;
      }

      // 5. Create category
      emit(CategoryCreating(name: name));

      final category = await _categoryRepository.createCategory(
        name: name,
        icon: icon,
        color: color,
        userId: userId,
      );

      emit(CategoryCreated(category: category));

      // Invalidate cache so newly created category appears in selector
      invalidateTopCategoriesCache();
    } catch (e) {
      emit(
        CategoryError(
          message: 'Failed to create category: $e',
          type: CategoryErrorType.createFailed,
        ),
      );
    }
  }

  /// Increment category usage count
  ///
  /// Called when a category is assigned to an expense.
  /// Updates the popularity ranking for future searches.
  ///
  /// Emits:
  /// - CategoryUsageIncremented on success
  /// - CategoryError on failure
  ///
  /// This operation fails silently in UI to not disrupt expense creation.
  Future<void> incrementCategoryUsage(String categoryId) async {
    try {
      await _categoryRepository.incrementCategoryUsage(categoryId);
      emit(CategoryUsageIncremented(categoryId: categoryId));
    } catch (e) {
      // Silent failure - don't disrupt expense creation
      emit(
        CategoryError(
          message: 'Failed to update category usage: $e',
          type: CategoryErrorType.generic,
        ),
      );
    }
  }

  /// Check if user can create a category (rate limit check)
  ///
  /// Returns rate limit status for UI feedback:
  /// - canCreate: true if user can create now
  /// - recentCreationCount: number of recent creations (0-3)
  /// - timeUntilNext: time until next creation allowed (if rate-limited)
  ///
  /// Emits:
  /// - CategoryRateLimitChecked with status
  /// - CategoryError on failure
  ///
  /// Used for:
  /// - Disabling "Create" button when rate-limited
  /// - Showing "X/3 categories created" counter
  /// - Displaying countdown timer when rate-limited
  ///
  /// Note: userId is obtained internally from AuthService for rate limiting.
  Future<void> checkRateLimit() async {
    try {
      final userId = _authService.getAuthUidForRateLimiting();
      if (userId == null) {
        emit(
          CategoryError(
            message: 'You must be logged in to check rate limits',
            type: CategoryErrorType.generic,
          ),
        );
        return;
      }

      final canCreate = await _rateLimiterService.canUserCreateCategory(userId);
      final recentCount = await _rateLimiterService.getRecentCreationCount(
        userId,
      );
      final timeUntilNext = await _rateLimiterService.getTimeUntilNextCreation(
        userId,
      );

      emit(
        CategoryRateLimitChecked(
          canCreate: canCreate,
          recentCreationCount: recentCount,
          timeUntilNext: timeUntilNext,
        ),
      );
    } catch (e) {
      emit(
        CategoryError(
          message: 'Failed to check rate limit: $e',
          type: CategoryErrorType.generic,
        ),
      );
    }
  }

  @override
  Future<void> close() {
    _topCategoriesSubscription?.cancel();
    _searchSubscription?.cancel();
    return super.close();
  }
}
