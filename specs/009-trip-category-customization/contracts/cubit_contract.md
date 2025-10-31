# Cubit Contract: CategoryCustomizationCubit

**Feature**: 009-trip-category-customization
**Date**: 2025-10-31
**Type**: Presentation Layer State Management

This document defines the contract for the `CategoryCustomizationCubit` that manages category customization state and operations.

---

## Cubit Definition

```dart
// lib/features/categories/presentation/cubit/category_customization_cubit.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/models/category_customization.dart';
import '../../../../core/repositories/category_customization_repository.dart';
import '../../../../core/repositories/activity_log_repository.dart';
import 'category_customization_state.dart';

/// Cubit for managing category customization state and operations
///
/// Handles:
/// - Loading customizations for a trip
/// - Saving customizations (create/update)
/// - Resetting customizations to global defaults
/// - In-memory caching for performance
/// - Activity logging for customization changes
///
/// Lifecycle: Scoped to a single trip session
class CategoryCustomizationCubit extends Cubit<CategoryCustomizationState> {
  final CategoryCustomizationRepository _repository;
  final String _tripId;
  final ActivityLogRepository? _activityLogRepository;

  // Stream subscription for real-time updates
  StreamSubscription<List<CategoryCustomization>>? _customizationsSubscription;

  CategoryCustomizationCubit({
    required CategoryCustomizationRepository repository,
    required String tripId,
    ActivityLogRepository? activityLogRepository,
  })  : _repository = repository,
        _tripId = tripId,
        _activityLogRepository = activityLogRepository,
        super(const CategoryCustomizationInitial());

  /// Loads all customizations for the current trip
  ///
  /// Subscribes to real-time updates from repository.
  /// Customizations are cached in state for fast lookups.
  ///
  /// Emits:
  /// - CategoryCustomizationLoading (initial load)
  /// - CategoryCustomizationLoaded (data available)
  /// - CategoryCustomizationError (load failed)
  ///
  /// Side effects:
  /// - Cancels previous subscription if exists
  /// - Keeps subscription open until dispose()
  ///
  /// Example:
  /// ```dart
  /// context.read<CategoryCustomizationCubit>().loadCustomizations();
  /// ```
  void loadCustomizations();

  /// Gets a specific customization from cached state
  ///
  /// Returns null if no customization exists (category uses defaults).
  /// MUST be called after loadCustomizations() completes.
  ///
  /// Parameters:
  /// - [categoryId]: ID of category to get customization for
  ///
  /// Returns:
  /// - CategoryCustomization? - Cached customization or null
  ///
  /// Performance: <1ms (in-memory lookup)
  ///
  /// Example:
  /// ```dart
  /// final customization = context
  ///     .read<CategoryCustomizationCubit>()
  ///     .getCustomization('category-123');
  /// ```
  CategoryCustomization? getCustomization(String categoryId);

  /// Saves a customization (create or update)
  ///
  /// Validates customization before saving.
  /// Logs activity if activityLogRepository provided.
  ///
  /// Parameters:
  /// - [categoryId]: ID of category to customize
  /// - [customIcon]: Custom icon code (null = keep current/default)
  /// - [customColor]: Custom hex color (null = keep current/default)
  /// - [actorName]: Name of user performing action (for activity log)
  ///
  /// Emits:
  /// - CategoryCustomizationSaving (operation in progress)
  /// - CategoryCustomizationLoaded (success, state updated)
  /// - CategoryCustomizationError (save failed)
  ///
  /// Side effects:
  /// - Writes to Firestore
  /// - Logs activity (non-fatal)
  /// - Updates cached state
  ///
  /// Example:
  /// ```dart
  /// await context.read<CategoryCustomizationCubit>().saveCustomization(
  ///   categoryId: 'meals-id',
  ///   customIcon: 'fastfood',
  ///   customColor: '#FF5722',
  ///   actorName: 'Alice',
  /// );
  /// ```
  Future<void> saveCustomization({
    required String categoryId,
    String? customIcon,
    String? customColor,
    String? actorName,
  });

  /// Resets a customization to global defaults
  ///
  /// Deletes the customization document from Firestore.
  /// Logs activity if activityLogRepository provided.
  ///
  /// Parameters:
  /// - [categoryId]: ID of category to reset
  /// - [actorName]: Name of user performing action (for activity log)
  ///
  /// Emits:
  /// - CategoryCustomizationResetting (operation in progress)
  /// - CategoryCustomizationLoaded (success, customization removed from state)
  /// - CategoryCustomizationError (reset failed)
  ///
  /// Side effects:
  /// - Deletes from Firestore
  /// - Logs activity (non-fatal)
  /// - Updates cached state (removes customization)
  ///
  /// Example:
  /// ```dart
  /// await context.read<CategoryCustomizationCubit>().resetCustomization(
  ///   categoryId: 'meals-id',
  ///   actorName: 'Alice',
  /// );
  /// ```
  Future<void> resetCustomization({
    required String categoryId,
    String? actorName,
  });

  /// Checks if a category has any customization
  ///
  /// Convenience method for UI logic.
  ///
  /// Parameters:
  /// - [categoryId]: ID of category to check
  ///
  /// Returns:
  /// - bool - True if customized, false otherwise
  ///
  /// Performance: <1ms (in-memory lookup)
  ///
  /// Example:
  /// ```dart
  /// final isCustomized = context
  ///     .read<CategoryCustomizationCubit>()
  ///     .isCustomized('category-123');
  /// ```
  bool isCustomized(String categoryId);

  /// Disposes cubit and cancels stream subscription
  ///
  /// MUST be called when cubit is no longer needed (user leaves trip).
  ///
  /// Side effects:
  /// - Cancels Firestore stream subscription
  /// - Clears in-memory cache
  @override
  Future<void> close();
}
```

---

## State Definition

```dart
// lib/features/categories/presentation/cubit/category_customization_state.dart

import 'package:equatable/equatable.dart';
import '../../../../core/models/category_customization.dart';

/// Base state for category customization operations
abstract class CategoryCustomizationState extends Equatable {
  const CategoryCustomizationState();

  @override
  List<Object?> get props => [];
}

/// Initial state before any operations
class CategoryCustomizationInitial extends CategoryCustomizationState {
  const CategoryCustomizationInitial();
}

/// Loading customizations from repository
class CategoryCustomizationLoading extends CategoryCustomizationState {
  const CategoryCustomizationLoading();
}

/// Customizations loaded successfully
///
/// Contains cached customizations keyed by categoryId for fast lookups.
class CategoryCustomizationLoaded extends CategoryCustomizationState {
  /// Map of category ID to customization
  /// Missing keys = category uses global defaults
  final Map<String, CategoryCustomization> customizations;

  const CategoryCustomizationLoaded({
    required this.customizations,
  });

  /// Helper to get customization for a category
  CategoryCustomization? getCustomization(String categoryId) {
    return customizations[categoryId];
  }

  /// Helper to check if category is customized
  bool isCustomized(String categoryId) {
    return customizations.containsKey(categoryId);
  }

  /// Number of customizations
  int get count => customizations.length;

  @override
  List<Object?> get props => [customizations];
}

/// Saving a customization (create or update)
class CategoryCustomizationSaving extends CategoryCustomizationState {
  final String categoryId;

  const CategoryCustomizationSaving({required this.categoryId});

  @override
  List<Object?> get props => [categoryId];
}

/// Resetting a customization to defaults
class CategoryCustomizationResetting extends CategoryCustomizationState {
  final String categoryId;

  const CategoryCustomizationResetting({required this.categoryId});

  @override
  List<Object?> get props => [categoryId];
}

/// Error occurred during customization operations
class CategoryCustomizationError extends CategoryCustomizationState {
  final String message;
  final CategoryCustomizationErrorType type;

  /// Previous state before error (allows retry)
  final CategoryCustomizationState? previousState;

  const CategoryCustomizationError({
    required this.message,
    required this.type,
    this.previousState,
  });

  @override
  List<Object?> get props => [message, type, previousState];
}

/// Error types for customization operations
enum CategoryCustomizationErrorType {
  /// Failed to load customizations
  loadFailed,

  /// Failed to save customization
  saveFailed,

  /// Failed to reset customization
  resetFailed,

  /// Validation error
  validationFailed,
}
```

---

## State Transitions

### Loading Flow
```
Initial → Loading → Loaded (success)
                  → Error (failure)
```

### Saving Flow
```
Loaded → Saving → Loaded (success, updated cache)
               → Error (failure, preserve Loaded state)
```

### Resetting Flow
```
Loaded → Resetting → Loaded (success, removed from cache)
                  → Error (failure, preserve Loaded state)
```

### Error Recovery
```
Error (with previousState) → User retries → Resumes from previousState
```

---

## BLoC Listener Patterns

### Pattern 1: Load customizations on trip load

```dart
class TripDetailScreen extends StatefulWidget {
  final String tripId;
  // ...
}

class _TripDetailScreenState extends State<TripDetailScreen> {
  @override
  void initState() {
    super.initState();
    // Load customizations when screen loads
    context.read<CategoryCustomizationCubit>().loadCustomizations();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CategoryCustomizationCubit, CategoryCustomizationState>(
      listener: (context, state) {
        if (state is CategoryCustomizationError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      child: BlocBuilder<CategoryCustomizationCubit, CategoryCustomizationState>(
        builder: (context, state) {
          if (state is CategoryCustomizationLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is CategoryCustomizationLoaded) {
            return TripContent(customizations: state.customizations);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
```

### Pattern 2: Save customization with feedback

```dart
Future<void> _onSaveCustomization() async {
  final cubit = context.read<CategoryCustomizationCubit>();
  final currentUser = context.read<TripCubit>().getCurrentUserForTrip(widget.tripId);

  await cubit.saveCustomization(
    categoryId: _selectedCategoryId,
    customIcon: _selectedIcon,
    customColor: _selectedColor,
    actorName: currentUser?.name,
  );

  // Show success message (listener will handle errors)
  if (cubit.state is CategoryCustomizationLoaded) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Customization saved')),
    );
    Navigator.of(context).pop();
  }
}
```

### Pattern 3: Display customized category

```dart
Widget buildCategoryChip(Category category) {
  return BlocBuilder<CategoryCustomizationCubit, CategoryCustomizationState>(
    builder: (context, state) {
      final customization = state is CategoryCustomizationLoaded
          ? state.getCustomization(category.id)
          : null;

      final displayIcon = customization?.customIcon ?? category.icon;
      final displayColor = customization?.customColor ?? category.color;
      final isCustomized = customization != null;

      return Chip(
        avatar: Icon(getIconData(displayIcon)),
        label: Text(category.name),
        backgroundColor: parseColor(displayColor),
        // Show indicator if customized
        deleteIcon: isCustomized ? const Icon(Icons.edit, size: 16) : null,
      );
    },
  );
}
```

---

## Performance Contract

### Operation Targets

| Operation | Target | Notes |
|-----------|--------|-------|
| loadCustomizations | <200ms | Initial Firestore read |
| getCustomization | <1ms | In-memory Map lookup |
| saveCustomization | <500ms | Firestore write + activity log |
| resetCustomization | <500ms | Firestore delete + activity log |
| isCustomized | <1ms | In-memory Map lookup |

### Memory Contract

| Metric | Target |
|--------|--------|
| Cubit instance size | <10KB |
| Cached customizations (50) | <5KB |
| Total memory footprint | <20KB per trip |

---

## Testing Contract

### Required Unit Tests

1. **Initial State**:
   - Cubit starts in CategoryCustomizationInitial state
   - tripId stored correctly

2. **Load Customizations**:
   - Emits Loading → Loaded (empty)
   - Emits Loading → Loaded (with customizations)
   - Emits Loading → Error (load failed)
   - Stream updates emit new Loaded state

3. **Get Customization**:
   - Returns null for non-existent customization
   - Returns correct customization when exists
   - Throws if called before loadCustomizations

4. **Save Customization**:
   - Emits Saving → Loaded (new customization added to cache)
   - Emits Saving → Loaded (existing customization updated in cache)
   - Emits Saving → Error (save failed)
   - Logs activity when activityLogRepository provided
   - Does not fail if activity logging fails

5. **Reset Customization**:
   - Emits Resetting → Loaded (customization removed from cache)
   - Emits Resetting → Error (reset failed)
   - Logs activity when activityLogRepository provided

6. **Is Customized**:
   - Returns true for customized category
   - Returns false for non-customized category

7. **Dispose**:
   - Cancels stream subscription
   - Does not emit states after close()

### Mock Requirements

```dart
@GenerateMocks([
  CategoryCustomizationRepository,
  ActivityLogRepository,
])
void main() {
  late MockCategoryCustomizationRepository mockRepository;
  late MockActivityLogRepository mockActivityLogRepository;
  late CategoryCustomizationCubit cubit;

  setUp(() {
    mockRepository = MockCategoryCustomizationRepository();
    mockActivityLogRepository = MockActivityLogRepository();
    cubit = CategoryCustomizationCubit(
      repository: mockRepository,
      tripId: 'test-trip-id',
      activityLogRepository: mockActivityLogRepository,
    );
  });

  tearDown(() {
    cubit.close();
  });

  // Tests...
}
```

---

## Dependency Injection

### Provider Setup

```dart
// At trip scope (not app root)
MultiBlocProvider(
  providers: [
    BlocProvider(
      create: (context) => CategoryCustomizationCubit(
        repository: context.read<CategoryCustomizationRepository>(),
        tripId: tripId,
        activityLogRepository: context.read<ActivityLogRepository>(),
      )..loadCustomizations(), // Auto-load on create
    ),
  ],
  child: TripDetailScreen(tripId: tripId),
)
```

---

## Error Handling

### User-Facing Error Messages

| Error Type | User Message | Recovery Action |
|------------|-------------|-----------------|
| loadFailed | "Failed to load customizations. Using global defaults." | Retry button |
| saveFailed | "Failed to save customization. Please try again." | Retry button |
| resetFailed | "Failed to reset customization. Please try again." | Retry button |
| validationFailed | "Invalid icon or color selected." | Fix selection |

### Error State Preservation

When operations fail, the cubit MUST:
1. Emit CategoryCustomizationError with previousState
2. Preserve the previousState (typically Loaded) for recovery
3. Allow user to retry operation from current state

---

## API Stability

**Version**: 1.0.0
**Stability**: Stable
**Breaking Changes**: None planned

Future additions (non-breaking):
- Batch save operations
- Undo/redo support
- Customization presets
