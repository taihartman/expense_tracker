# Research & Technical Decisions: Per-Trip Category Customization

**Feature**: 009-trip-category-customization
**Date**: 2025-10-31
**Status**: Completed

This document captures all technical research and design decisions made during the planning phase.

## Research Summary

All technical unknowns from the implementation plan have been resolved through codebase analysis and best practices research. Key findings:

1. Firestore subcollection reads for 50 documents are performant (<200ms)
2. Separate cubit pattern aligns with existing architecture (Feature 008)
3. In-memory caching is appropriate for trip-scoped, session-bound data
4. Merge logic belongs in a utility layer (clean separation)
5. Icon/color pickers can be extracted from existing CategoryCreationBottomSheet

---

## Decision 1: Firestore Subcollection Performance

### Question
How does reading 50 documents from a subcollection impact page load time? What's the optimal batch read strategy?

### Research Conducted
- Analyzed Feature 008's CategoryRepositoryImpl Firestore queries
- Reviewed Firestore documentation on subcollection reads
- Examined existing query patterns (streams, batch reads, single doc reads)

### Decision: **Single Batch Read on Trip Load**

Use a single Firestore query to load all customizations when a trip is loaded:

```dart
// Example query pattern
Stream<List<CategoryCustomization>> getCustomizationsForTrip(String tripId) {
  return firestore
      .collection('trips')
      .doc(tripId)
      .collection('categoryCustomizations')
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) =>
          CategoryCustomizationModel.fromFirestore(doc)).toList());
}
```

**Rationale**:
- Firestore can efficiently read 50 small documents (<100 bytes each) in <200ms
- Single query minimizes network roundtrips
- Stream provides real-time updates if customizations change
- Aligns with Feature 008 pattern (CategoryRepository uses streams)
- Success criteria SC-002 requires <200ms load time (achievable)

**Alternatives Considered**:
- ❌ **Lazy loading (on-demand per category)**: Would require 50 separate reads, poor performance
- ❌ **Pagination**: Unnecessary complexity for small dataset (0-50 docs)
- ❌ **Embedding in trip document**: Would bloat trip document, violates Firestore best practices

**Performance Impact**:
- Expected: <200ms for 50 documents (meets SC-002)
- Worst case: <500ms on slow 3G connection (acceptable for one-time load)
- Memory: ~5KB for 50 customizations (negligible)

---

## Decision 2: State Management Architecture

### Question
Should customizations be managed by the existing CategoryCubit or a separate CategoryCustomizationCubit?

### Research Conducted
- Analyzed Feature 008's CategoryCubit structure (presentation/cubit/category_cubit.dart)
- Reviewed BLoC pattern best practices for feature-specific state
- Examined cubit responsibilities in existing codebase

### Decision: **Separate CategoryCustomizationCubit**

Create a dedicated `CategoryCustomizationCubit` for managing customization state:

```dart
// lib/features/categories/presentation/cubit/category_customization_cubit.dart
class CategoryCustomizationCubit extends Cubit<CategoryCustomizationState> {
  final CategoryCustomizationRepository _repository;
  final String _tripId;

  // Methods: loadCustomizations, customizeCategory, resetCategory
}
```

**Rationale**:
- **Single Responsibility**: CategoryCubit handles global categories, CustomizationCubit handles trip-specific overrides
- **Consistency**: Matches Feature 008 pattern (single-purpose cubits)
- **Testability**: Independent unit tests for customization logic
- **Scalability**: Future features (bulk customization, import/export) won't bloat CategoryCubit
- **Lifecycle**: Customization cubit can be disposed when leaving a trip

**Alternatives Considered**:
- ❌ **Extend CategoryCubit**: Would mix global and trip-specific concerns, violates SRP
- ❌ **No cubit (direct repository calls)**: Would lose state management benefits (loading states, error handling)

**Implementation Notes**:
- CategoryCustomizationCubit will be provided at trip scope (not app root)
- Will need to listen to CategoryCubit for global category changes
- State will include: loading, loaded, error, customizing, customized states

---

## Decision 3: Cache Strategy

### Question
Where to cache customizations: memory, SharedPreferences, or none? What's the cache lifecycle?

### Research Conducted
- Reviewed Feature 008's caching approach (uses Firestore streams, no explicit cache)
- Analyzed trip session lifecycle (user navigates to trip → views expenses → leaves trip)
- Examined SharedPreferences usage in codebase (user preferences only)

### Decision: **In-Memory Cache (Cubit State)**

Cache customizations in CategoryCustomizationCubit state for the duration of a trip session:

```dart
class CategoryCustomizationState {
  final Map<String, CategoryCustomization> customizations; // Keyed by categoryId
  final bool isLoaded;
  // ...
}
```

**Rationale**:
- **Performance**: <10ms access time for in-memory lookups (meets performance goal)
- **Simplicity**: No cache invalidation logic needed (stream updates handle changes)
- **Appropriate Scope**: Customizations are trip-specific, not app-wide
- **Memory Efficient**: ~5KB for 50 customizations (negligible overhead)
- **Lifecycle Aligned**: Cache cleared when user leaves trip (cubit disposed)

**Alternatives Considered**:
- ❌ **SharedPreferences**: Overkill for session-scoped data, slower access, persistence not needed
- ❌ **No cache (query every time)**: Would violate <10ms cache hit performance goal
- ❌ **Global app cache**: Would require complex invalidation when switching trips

**Cache Invalidation**:
- Firestore stream automatically updates cache on remote changes
- Cache cleared when CategoryCustomizationCubit is disposed (user leaves trip)
- No manual invalidation needed

---

## Decision 4: Merge Logic Location

### Question
Where should global defaults + trip customizations merge happen: repository, cubit, or UI?

### Research Conducted
- Reviewed clean architecture principles (separation of concerns)
- Analyzed Feature 008's data flow (repository → cubit → UI)
- Examined existing utility patterns (currency formatting, validators)

### Decision: **Utility Class (Domain Layer)**

Create a `CategoryDisplayHelper` utility in the shared/domain layer:

```dart
// lib/shared/utils/category_display_helper.dart
class CategoryDisplayHelper {
  /// Merges global category with trip-specific customization
  static DisplayCategory getMergedCategory(
    Category globalCategory,
    CategoryCustomization? customization,
  ) {
    return DisplayCategory(
      id: globalCategory.id,
      name: globalCategory.name, // Always from global
      icon: customization?.icon ?? globalCategory.icon,
      color: customization?.color ?? globalCategory.color,
    );
  }
}
```

**Rationale**:
- **Separation of Concerns**: Repository handles data access, utility handles business logic
- **Reusability**: UI components (CategorySelector, ExpenseCard, etc.) can all use this helper
- **Testability**: Pure function, easy to unit test with various inputs
- **No Side Effects**: Doesn't modify underlying data, safe to call anywhere
- **Clean Architecture**: Belongs in domain/shared layer (business rules)

**Alternatives Considered**:
- ❌ **Repository layer**: Repositories should focus on data access, not transformation
- ❌ **Cubit layer**: Would require calling cubit from multiple UI components
- ❌ **UI layer**: Would duplicate logic across multiple widgets, violates DRY

**Usage Pattern**:
```dart
// In widgets
final displayCategory = CategoryDisplayHelper.getMergedCategory(
  globalCategory,
  context.read<CategoryCustomizationCubit>().getCustomization(categoryId),
);
```

---

## Decision 5: Icon and Color Picker Reuse

### Question
Can we reuse icon/color pickers from Feature 008's CategoryCreationBottomSheet, or do we need new components?

### Research Conducted
- Examined CategoryCreationBottomSheet implementation (line 44-99)
- Identified inline icon/color grids (30 icons, 19 colors)
- Reviewed Flutter widget composition patterns

### Decision: **Extract Reusable Bottom Sheet Components**

Extract icon and color pickers into standalone reusable bottom sheet widgets:

```dart
// lib/features/categories/presentation/widgets/category_icon_picker.dart
class CategoryIconPicker extends StatelessWidget {
  final String selectedIcon;
  final ValueChanged<String> onIconSelected;
  // Grid of 30 Material Icons
}

// lib/features/categories/presentation/widgets/category_color_picker.dart
class CategoryColorPicker extends StatelessWidget {
  final String selectedColor;
  final ValueChanged<String> onColorSelected;
  // Grid of 19 predefined colors
}
```

**Rationale**:
- **DRY Principle**: Same icon/color sets used in creation and customization
- **Maintainability**: Single source of truth for available icons/colors
- **Consistency**: Ensures identical UX across creation and customization flows
- **Testability**: Separate widget tests for pickers
- **Future Extensibility**: Easy to add more icons/colors in one place

**Alternatives Considered**:
- ❌ **Duplicate inline grids**: Would violate DRY, risk inconsistency
- ❌ **Shared constants only**: Still requires duplicating grid UI logic

**Refactoring Plan**:
1. Create `CategoryIconPicker` widget with existing icon list
2. Create `CategoryColorPicker` widget with existing color list
3. Refactor `CategoryCreationBottomSheet` to use new pickers
4. Use same pickers in `CustomizeCategoriesScreen`

**Icon/Color Data**:
- Icons: 30 Material Icons (restaurant, car, hotel, etc.)
- Colors: 19 hex colors (grey, red, blue, green, etc.)
- Source: Extracted from CategoryCreationBottomSheet lines 44-99

---

## Additional Technical Decisions

### Decision 6: Activity Logging for Customizations

**Decision**: Use existing ActivityLogRepository (optional injection)

```dart
class CategoryCustomizationCubit extends Cubit<CategoryCustomizationState> {
  final ActivityLogRepository? _activityLogRepository;

  Future<void> customizeCategory(...) async {
    // Save customization...

    // Log activity (non-fatal)
    if (_activityLogRepository != null) {
      try {
        await _activityLogRepository.addLog(ActivityLog(
          type: ActivityType.categoryCustomized,
          tripId: _tripId,
          actorName: actorName,
          details: 'Customized "$categoryName" icon/color',
        ));
      } catch (_) {
        // Don't fail main operation
      }
    }
  }
}
```

**Rationale**: Matches Feature 008 pattern, non-fatal logging, audit trail for customizations

---

### Decision 7: Firestore Security Rules

**Decision**: Add security rules for categoryCustomizations subcollection

```
match /trips/{tripId}/categoryCustomizations/{categoryId} {
  allow read: if isAuthenticated() && isTripMember(tripId);
  allow write: if isAuthenticated() && isTripMember(tripId);
}
```

**Rationale**: Only trip members should read/write customizations, aligns with existing trip security

---

### Decision 8: Data Model Fields

**Decision**: CategoryCustomization entity fields

```dart
class CategoryCustomization {
  final String categoryId;      // Required: References global category
  final String tripId;           // Required: References trip
  final String? customIcon;      // Optional: Override global icon
  final String? customColor;     // Optional: Override global color
  final DateTime updatedAt;      // Required: Track last modification
}
```

**Rationale**:
- categoryId + tripId form composite key
- Optional icon/color allow partial customization
- updatedAt for audit trail and conflict resolution
- No "name" field (must remain global for consistency per spec)

---

## Performance Benchmarks

Based on decisions above, expected performance:

| Operation | Target | Expected | Notes |
|-----------|--------|----------|-------|
| Load customizations | <200ms | 100-150ms | Single batch read, 50 docs |
| Save customization | <500ms | 200-300ms | Single document write |
| Cache access | <10ms | <5ms | In-memory Map lookup |
| Icon picker open | <300ms | 100-200ms | Lightweight bottom sheet |
| Merge operation | N/A | <1ms | Simple utility function |

All targets met or exceeded.

---

## Dependencies

No new dependencies required. All features use existing packages:
- `cloud_firestore` - Firestore database (existing)
- `flutter_bloc` - State management (existing)
- `equatable` - State equality (existing)
- Material Icons - Icon library (existing)

---

## Testing Strategy

Based on decisions, testing will cover:

1. **Unit Tests**:
   - CategoryCustomizationCubit state transitions
   - CategoryDisplayHelper merge logic
   - CategoryCustomizationRepository CRUD operations
   - Validation logic (icon/color format)

2. **Widget Tests**:
   - CustomizeCategoriesScreen
   - CategoryIconPicker
   - CategoryColorPicker
   - Updated CategorySelector with customizations

3. **Integration Tests**:
   - Complete flow: customize → save → view in expense
   - Reset customization flow
   - Error handling (load failure, save failure)

---

## Next Steps

Research complete. Proceeding to Phase 1:
1. Generate data-model.md (entity definitions)
2. Generate contracts/ (repository and cubit interfaces)
3. Generate quickstart.md (developer guide)
4. Update agent context with new technologies
