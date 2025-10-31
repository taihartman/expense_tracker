# Category API Contract

**Version**: 1.0.0
**Date**: 2025-10-31
**Purpose**: Define the interface for category operations (repository + cubit)

## Repository Interface

**Location**: `lib/features/categories/domain/repositories/category_repository.dart`

### Operations

#### 1. Get Top Categories by Usage

**Purpose**: Fetch the most popular categories for quick selection

```dart
Stream<List<Category>> getTopCategories({int limit = 5});
```

**Parameters**:
- `limit` (optional): Number of categories to return (default: 5)

**Returns**: Stream of categories ordered by `usageCount` descending

**Example**:
```dart
final topCategories = await repository.getTopCategories(limit: 5).first;
// Returns: [Meals (142 uses), Transport (98 uses), ...]
```

**Firestore Query**:
```
collection('categories')
  .orderBy('usageCount', descending: true)
  .limit(limit)
```

---

#### 2. Search Categories

**Purpose**: Find categories by partial name match (case-insensitive)

```dart
Stream<List<Category>> searchCategories(String query);
```

**Parameters**:
- `query`: Search term (case-insensitive)

**Returns**: Stream of matching categories ordered by relevance (exact match first, then by usage count)

**Example**:
```dart
final results = await repository.searchCategories('meal').first;
// Returns: [Meals, Meal Plans, Mealkit Delivery, ...]
```

**Firestore Query**:
```
collection('categories')
  .where('nameLowercase', isGreaterThanOrEqualTo: query.toLowerCase())
  .where('nameLowercase', isLessThan: query.toLowerCase() + '\uf8ff')
  .orderBy('nameLowercase')
  .orderBy('usageCount', descending: true)
```

**Edge Cases**:
- Empty query: Returns all categories (sorted by usage)
- No matches: Returns empty list
- Special characters: Sanitized automatically

---

#### 3. Get Category by ID

**Purpose**: Fetch a single category by its unique ID

```dart
Future<Category?> getCategoryById(String id);
```

**Parameters**:
- `id`: Category document ID

**Returns**: Category or null if not found

**Example**:
```dart
final category = await repository.getCategoryById('cat_xyz123');
// Returns: Category(name: 'Meals', icon: 'restaurant', ...)
```

---

#### 4. Create Category

**Purpose**: Add a new category to the global pool

```dart
Future<Category> createCategory({
  required String name,
  required String icon,
  required String color,
  required String userId,  // For rate limiting
});
```

**Parameters**:
- `name`: Category display name (1-50 chars, validated)
- `icon`: Material icon name (e.g., "restaurant")
- `color`: Hex color code (e.g., "#FF5722")
- `userId`: Current user ID for rate limiting and logging

**Returns**: Created category with auto-generated ID

**Validation**:
- Name length: 1-50 characters
- Name characters: Letters, numbers, spaces, `'`, `-`, `&` only
- Duplicate check: Case-insensitive name uniqueness
- Rate limit: Max 3 creations per user per 5 minutes

**Exceptions**:
- `ValidationException`: Invalid name format
- `DuplicateCategoryException`: Category name already exists (case-insensitive)
- `RateLimitException`: User exceeded creation limit

**Example**:
```dart
try {
  final category = await repository.createCategory(
    name: 'Pet Care',
    icon: 'pets',
    color: '#4CAF50',
    userId: currentUser.id,
  );
  // Success: category created
} on DuplicateCategoryException catch (e) {
  // Show error: "This category already exists"
} on RateLimitException catch (e) {
  // Show error: "Please wait before creating more categories"
}
```

**Side Effects**:
- Creates document in `categories` collection
- Logs entry in `categoryCreationLogs` for rate limiting
- (Optional) Updates `categoryIconUsage` statistics

---

#### 5. Increment Category Usage

**Purpose**: Update usage count when category is assigned to an expense

```dart
Future<void> incrementCategoryUsage(String categoryId);
```

**Parameters**:
- `categoryId`: Category to increment

**Returns**: void (async operation)

**Example**:
```dart
// When user creates expense with category
await repository.incrementCategoryUsage(expense.categoryId);
```

**Firestore Operation**:
```dart
_firestore.collection('categories').doc(categoryId).update({
  'usageCount': FieldValue.increment(1),
  'updatedAt': FieldValue.serverTimestamp(),
});
```

**Note**: This operation is typically batched with expense creation for atomicity.

---

#### 6. Check Duplicate Name

**Purpose**: Verify if a category name already exists (case-insensitive)

```dart
Future<bool> categoryExists(String name);
```

**Parameters**:
- `name`: Category name to check

**Returns**: true if name exists (case-insensitive), false otherwise

**Example**:
```dart
final exists = await repository.categoryExists('meals');
if (exists) {
  // Show error: "This category already exists"
}
```

**Firestore Query**:
```
collection('categories')
  .where('nameLowercase', isEqualTo: name.toLowerCase())
  .limit(1)
```

---

#### 7. Check Rate Limit

**Purpose**: Determine if user can create another category

```dart
Future<bool> canUserCreateCategory(String userId);
```

**Parameters**:
- `userId`: User to check

**Returns**: true if user can create, false if rate limited

**Example**:
```dart
final canCreate = await repository.canUserCreateCategory(currentUser.id);
if (!canCreate) {
  // Disable create button, show tooltip
}
```

**Firestore Query**:
```
collection('categoryCreationLogs')
  .where('userId', isEqualTo: userId)
  .where('createdAt', isGreaterThan: fiveMinutesAgo)
  .get()
  .then((docs) => docs.length < 3)
```

---

## Cubit State Management

**Location**: `lib/features/categories/presentation/cubits/category_cubit.dart`

### States

```dart
abstract class CategoryState {}

class CategoryInitial extends CategoryState {}

class CategoryLoading extends CategoryState {}

class CategoryLoaded extends CategoryState {
  final List<Category> categories;
  CategoryLoaded(this.categories);
}

class CategorySearchResults extends CategoryState {
  final List<Category> results;
  final String query;
  CategorySearchResults(this.results, this.query);
}

class CategoryCreating extends CategoryState {}

class CategoryCreated extends CategoryState {
  final Category category;
  CategoryCreated(this.category);
}

class CategoryError extends CategoryState {
  final String message;
  CategoryError(this.message);
}

class CategoryRateLimited extends CategoryState {
  final DateTime retryAfter;  // When user can create again
  CategoryRateLimited(this.retryAfter);
}
```

### Methods

#### 1. Load Top Categories

```dart
Future<void> loadTopCategories({int limit = 5});
```

**Emits**:
- `CategoryLoading` → `CategoryLoaded(categories)`
- On error: `CategoryError(message)`

**Usage**:
```dart
context.read<CategoryCubit>().loadTopCategories(limit: 5);
```

---

#### 2. Search Categories

```dart
Future<void> searchCategories(String query);
```

**Emits**:
- `CategoryLoading` → `CategorySearchResults(results, query)`
- Empty query: `CategoryLoaded(allCategories)`
- On error: `CategoryError(message)`

**Usage**:
```dart
context.read<CategoryCubit>().searchCategories('meal');
```

---

#### 3. Create Category

```dart
Future<void> createCategory({
  required String name,
  required String icon,
  required String color,
  required String userId,
});
```

**Emits**:
- `CategoryCreating` → `CategoryCreated(category)`
- On validation error: `CategoryError(validationMessage)`
- On duplicate: `CategoryError('This category already exists')`
- On rate limit: `CategoryRateLimited(retryAfter)`

**Usage**:
```dart
await context.read<CategoryCubit>().createCategory(
  name: 'Pet Care',
  icon: 'pets',
  color: '#4CAF50',
  userId: currentUser.id,
);
```

---

#### 4. Check Rate Limit

```dart
Future<bool> checkRateLimit(String userId);
```

**Returns**: true if user can create, false otherwise

**Side Effect**: Emits `CategoryRateLimited` if limit exceeded

**Usage**:
```dart
final canCreate = await context.read<CategoryCubit>().checkRateLimit(currentUser.id);
```

---

## Error Handling

### Exception Types

```dart
// Custom exceptions
class DuplicateCategoryException implements Exception {
  final String message = 'This category already exists';
}

class RateLimitException implements Exception {
  final String message = 'Please wait a moment before creating more categories';
  final DateTime retryAfter;
  RateLimitException(this.retryAfter);
}

class ValidationException implements Exception {
  final String message;
  ValidationException(this.message);
}
```

### UI Error Display

**Error Messages**:
- Validation: "Category names can only contain letters, numbers, spaces, and basic punctuation"
- Duplicate: "This category already exists" (with option to select existing)
- Rate limit: "Please wait before creating more categories" (show disabled button)
- Network: "Unable to load categories. Please check your connection."

**Error Recovery**:
- Validation: User can edit and retry immediately
- Duplicate: Show existing category, offer to select it
- Rate limit: Disable create button, show countdown timer (optional)
- Network: Show retry button

---

## Caching Contract

**Cache Service**: Optional local storage for offline access

### Operations

#### Get Cached Categories

```dart
List<Category> getCachedCategories();
```

**Returns**: Top 20 categories from local cache (Hive)

**Usage**: Fallback when offline or Firestore slow

---

#### Update Cache

```dart
Future<void> updateCache(List<Category> categories);
```

**Parameters**: Updated list of top categories

**Usage**: Called automatically by stream listener

---

## Performance Targets

| Operation | Target | Measured By |
|-----------|--------|-------------|
| Load top 5 categories | <200ms | Time to first render |
| Search query | <500ms | Input to results display |
| Create category | <1 second | Button tap to success state |
| Rate limit check | <100ms | Sync operation, no UI block |
| Cache load (offline) | <50ms | Local storage read |

---

## Security Contract

All operations require:
- **Authentication**: User must be signed in (Firebase Auth)
- **Validation**: Client and server-side validation
- **Rate Limiting**: Enforced at both client (UX) and server (Security Rules)

**Firestore Security Rules** enforce:
- Read: Public (anyone can view categories)
- Create: Authenticated + validation + rate limit + no duplicates
- Update/Delete: Forbidden (categories immutable)

---

## Migration Contract

**One-time operation**: Run before deploying feature

### Migration Script Interface

```dart
Future<MigrationResult> migrateTripCategoriesToGlobal();
```

**Returns**:
```dart
class MigrationResult {
  final int categoriesMigrated;
  final int expensesUpdated;
  final Map<String, String> categoryIdMapping;  // old -> new
  final List<String> errors;
}
```

**Safety**:
- Dry-run mode: Preview changes without committing
- Idempotent: Can re-run if interrupted
- Atomic: Uses Firestore batched writes
- Rollback: Stores `migratedFrom` field for audit trail

---

## Testing Contract

### Unit Tests

Required test coverage:
- Repository methods (all operations)
- Cubit state transitions (all states)
- Validation logic (all rules)
- Rate limiter service (all scenarios)

### Widget Tests

Required test coverage:
- CategorySelector (chip selection, "Other" button)
- CategoryBrowserBottomSheet (search, scroll, select)
- CategoryCreationDialog (form, validation, submit)
- IconPicker (grid, search, selection)
- ColorPicker (palette, selection)

### Integration Tests

Required test coverage:
- Complete flow: browse → search → create → select
- Rate limiting: create 3 → get blocked → wait → retry
- Duplicate detection: create → duplicate error → select existing

---

## Versioning

**Current Version**: 1.0.0

**Future Enhancements** (not in scope):
- Batch category operations
- Category analytics dashboard
- Category synonyms/aliases
- Personalized category recommendations

---

**Next Step**: Run `/speckit.tasks` to generate implementation task breakdown
