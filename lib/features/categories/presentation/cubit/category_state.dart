import 'package:equatable/equatable.dart';
import '../../domain/models/category.dart';

/// Base state for CategoryCubit
///
/// Handles category browsing, searching, and creation in the global category system.
abstract class CategoryState extends Equatable {
  const CategoryState();

  @override
  List<Object?> get props => [];
}

/// Initial state before any category operation
class CategoryInitial extends CategoryState {
  const CategoryInitial();
}

/// Loading top categories (for the chip selector)
class CategoryLoadingTop extends CategoryState {
  const CategoryLoadingTop();
}

/// Top categories loaded successfully
class CategoryTopLoaded extends CategoryState {
  final List<Category> categories;

  const CategoryTopLoaded({required this.categories});

  @override
  List<Object?> get props => [categories];
}

/// Searching categories (user is typing in search field)
class CategorySearching extends CategoryState {
  final String query;
  final List<Category> results;

  const CategorySearching({required this.query, required this.results});

  @override
  List<Object?> get props => [query, results];
}

/// Search completed with results
class CategorySearchResults extends CategoryState {
  final String query;
  final List<Category> results;

  const CategorySearchResults({required this.query, required this.results});

  @override
  List<Object?> get props => [query, results];
}

/// Creating a new category (loading state)
class CategoryCreating extends CategoryState {
  final String name;

  const CategoryCreating({required this.name});

  @override
  List<Object?> get props => [name];
}

/// Category created successfully
class CategoryCreated extends CategoryState {
  final Category category;

  const CategoryCreated({required this.category});

  @override
  List<Object?> get props => [category];
}

/// Category usage incremented successfully
///
/// Emitted after an expense is assigned to a category.
/// Used to update local category list popularity.
class CategoryUsageIncremented extends CategoryState {
  final String categoryId;

  const CategoryUsageIncremented({required this.categoryId});

  @override
  List<Object?> get props => [categoryId];
}

/// Rate limit check completed
class CategoryRateLimitChecked extends CategoryState {
  final bool canCreate;
  final int recentCreationCount;
  final Duration? timeUntilNext;

  const CategoryRateLimitChecked({
    required this.canCreate,
    required this.recentCreationCount,
    this.timeUntilNext,
  });

  @override
  List<Object?> get props => [canCreate, recentCreationCount, timeUntilNext];
}

/// Category operation failed with error
class CategoryError extends CategoryState {
  final String message;
  final CategoryErrorType type;

  const CategoryError({required this.message, required this.type});

  @override
  List<Object?> get props => [message, type];
}

/// Types of category errors for specific handling in UI
enum CategoryErrorType {
  /// Generic error (network, Firestore, etc.)
  generic,

  /// Category name validation failed
  validation,

  /// Duplicate category name (case-insensitive)
  duplicate,

  /// Rate limit exceeded (3 per 5 minutes)
  rateLimit,

  /// Failed to load categories
  loadFailed,

  /// Failed to search categories
  searchFailed,

  /// Failed to create category
  createFailed,
}
