# Data Model: Global Category Management System

**Date**: 2025-10-31
**Phase**: 1 (Design)
**Purpose**: Define data structures, relationships, and validation rules

## Entity Definitions

### GlobalCategory

**Purpose**: Represents a category in the shared global pool, usable across all trips and users.

**Storage**: Firestore collection `/categories`

**Domain Model** (`lib/features/categories/domain/models/category.dart`):
```dart
class Category {
  final String id;                // Firestore document ID
  final String name;              // Display name (1-50 chars, original casing)
  final String nameLowercase;     // Normalized for search (auto-generated)
  final String icon;              // Material icon name (e.g., "restaurant")
  final String color;             // Hex color code (e.g., "#FF5722")
  final int usageCount;           // Incremented on each expense assignment
  final DateTime createdAt;       // Timestamp of creation
  final DateTime updatedAt;       // Timestamp of last modification

  Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.usageCount = 0,
    required this.createdAt,
    required this.updatedAt,
  }) : nameLowercase = name.toLowerCase();

  // Validation
  String? validate() {
    return CategoryValidator.validateCategoryName(name);
  }

  // Usage increment (immutable pattern)
  Category incrementUsage() => copyWith(
    usageCount: usageCount + 1,
    updatedAt: DateTime.now(),
  );
}
```

**Firestore Document Structure**:
```json
{
  "name": "Meals",
  "nameLowercase": "meals",
  "icon": "restaurant",
  "color": "#FF5722",
  "usageCount": 142,
  "createdAt": "2025-10-31T10:00:00Z",
  "updatedAt": "2025-10-31T15:30:00Z"
}
```

**Indexes**:
- Composite: `nameLowercase ASC` + `usageCount DESC` (for search with popularity)
- Single: `usageCount DESC` (for top categories)
- Single: `createdAt DESC` (optional: recently created)

**Validation Rules**:
- `name`: 1-50 characters, letters (Unicode), numbers, spaces, `'`, `-`, `&` only
- `nameLowercase`: Auto-generated lowercase version of `name`
- `icon`: Valid Material icon name (string, non-empty)
- `color`: Hex format `#[0-9A-F]{6}` (case-insensitive)
- `usageCount`: Non-negative integer (≥ 0)

**Relationships**:
- One-to-many with Expense: A category can be assigned to many expenses
- No foreign key: Expenses reference category via `categoryId` field

---

### CategoryIconUsage (Optional Enhancement)

**Purpose**: Track icon selection frequency for smart defaults when creating categories with existing names.

**Storage**: Firestore collection `/categoryIconUsage`

**Domain Model**:
```dart
class CategoryIconUsage {
  final String id;                // Composite key: "${categoryNameLowercase}_$icon"
  final String categoryName;      // Original case category name
  final String categoryNameLowercase;  // Normalized for grouping
  final String icon;              // Material icon name
  final int usageCount;           // Number of times this icon was selected

  CategoryIconUsage({
    required this.id,
    required this.categoryName,
    required this.icon,
    this.usageCount = 1,
  }) : categoryNameLowercase = categoryName.toLowerCase();
}
```

**Firestore Document Structure**:
```json
{
  "categoryName": "Meals",
  "categoryNameLowercase": "meals",
  "icon": "restaurant",
  "usageCount": 87
}
```

**Usage**:
- When user creates "Meals", query `categoryNameLowercase == "meals"` and suggest icon with highest `usageCount`
- Increment counter when user confirms category creation with that icon

**Index**:
- Composite: `categoryNameLowercase ASC` + `usageCount DESC`

---

### UserCategoryCreationLog

**Purpose**: Track category creation events for rate limiting (3 per 5 minutes per user).

**Storage**: Firestore collection `/categoryCreationLogs`

**Domain Model**:
```dart
class UserCategoryCreationLog {
  final String id;                // Firestore auto-generated
  final String userId;            // User who created the category
  final String categoryId;        // Category that was created
  final DateTime createdAt;       // Server timestamp

  UserCategoryCreationLog({
    required this.id,
    required this.userId,
    required this.categoryId,
    required this.createdAt,
  });
}
```

**Firestore Document Structure**:
```json
{
  "userId": "user_abc123",
  "categoryId": "category_xyz789",
  "createdAt": "2025-10-31T15:25:00Z"
}
```

**Indexes**:
- Composite: `userId ASC` + `createdAt DESC` (for rate limit queries)

**TTL Policy** (Optional):
- Firestore TTL: Auto-delete documents older than 7 days
- Reduces storage costs, no impact on rate limiting (5-minute window)

**Rate Limit Query**:
```dart
// Check if user can create another category
final fiveMinutesAgo = DateTime.now().subtract(Duration(minutes: 5));
final recentLogs = await firestore
  .collection('categoryCreationLogs')
  .where('userId', isEqualTo: currentUserId)
  .where('createdAt', isGreaterThan: fiveMinutesAgo)
  .get();

final canCreate = recentLogs.docs.length < 3;
```

---

### TripCategoryCache (Optional Optimization)

**Purpose**: Cache top 5 popular categories per trip for instant load without querying global pool.

**Storage**: Firestore document `/tripCategoryCache/{tripId}`

**Note**: This is an **optional optimization**. Initial implementation can query global categories directly. Add if performance testing shows slow load times.

**Domain Model**:
```dart
class TripCategoryCache {
  final String tripId;            // Trip this cache belongs to
  final List<String> categoryIds; // Top 5 category IDs (ordered by popularity)
  final DateTime lastUpdated;     // Cache freshness timestamp

  TripCategoryCache({
    required this.tripId,
    required this.categoryIds,
    required this.lastUpdated,
  });
}
```

**Firestore Document Structure**:
```json
{
  "tripId": "trip_123",
  "categoryIds": ["cat_1", "cat_2", "cat_3", "cat_4", "cat_5"],
  "lastUpdated": "2025-10-31T12:00:00Z"
}
```

**Cache Invalidation**:
- Update when global category rankings change (Cloud Function trigger)
- TTL: 1 hour (stale cache acceptable, top 5 rarely changes)

---

## State Transitions

### Category Lifecycle

```
[New] --create--> [Active] --increment usage--> [Active]
                              |
                              +--(no delete permitted)
```

**States**:
- **New**: Category being created (validation in progress)
- **Active**: Category available in global pool (can be selected, usage tracked)
- **No Delete**: Categories cannot be deleted to preserve expense references

**State Changes**:
- `create`: User creates new category → saves to Firestore → becomes Active
- `incrementUsage`: Expense assigned with category → `usageCount++` → stays Active

---

### User Rate Limit State

```
[No Limit] --create category (1x)--> [1/3 Used]
           --create category (2x)--> [2/3 Used]
           --create category (3x)--> [Rate Limited]
           --wait 5 minutes-------> [No Limit]
```

**States**:
- **No Limit**: User can create categories freely
- **1/3 Used**, **2/3 Used**: User has created 1 or 2 categories in last 5 minutes
- **Rate Limited**: User has created 3 categories in last 5 minutes (create disabled)

**State Changes**:
- `create category`: Logs entry → increments count → transitions toward Rate Limited
- `wait 5 minutes`: Oldest log expires → count decreases → transitions toward No Limit

---

## Validation Rules Summary

| Field | Constraint | Error Message |
|-------|-----------|---------------|
| `name` (length) | 1-50 characters | "Category name must be between 1 and 50 characters" |
| `name` (chars) | Letters, numbers, spaces, `'`, `-`, `&` | "Category names can only contain letters, numbers, spaces, and basic punctuation" |
| `name` (duplicate) | Case-insensitive unique | "This category already exists" |
| `icon` | Non-empty string | "Icon is required" |
| `color` | Hex format `#[0-9A-Fa-f]{6}` | "Invalid color format" |
| `usageCount` | ≥ 0 | "Usage count cannot be negative" |
| Rate limit | ≤ 3 creations per 5 min | "Please wait a moment before creating more categories" |

---

## Migration Data Mapping

### Before Migration (Trip-Specific)

**Old Structure**: `trips/{tripId}/categories/{categoryId}`

```json
{
  "tripId": "trip_123",
  "name": "Meals",
  "icon": "restaurant",
  "color": "#FF5722"
}
```

### After Migration (Global)

**New Structure**: `categories/{categoryId}`

```json
{
  "name": "Meals",
  "nameLowercase": "meals",
  "icon": "restaurant",
  "color": "#FF5722",
  "usageCount": 15,  // Sum of all trip-specific usages
  "migratedFrom": ["trip_123_cat_1", "trip_456_cat_2"],  // Audit trail
  "createdAt": "2025-10-31T00:00:00Z",
  "updatedAt": "2025-10-31T00:00:00Z"
}
```

### Expense Reference Update

**Before**: `expenses/{expenseId}.categoryId = "trip_123_cat_1"`
**After**: `expenses/{expenseId}.categoryId = "global_cat_xyz"`

**Mapping**: Migration script builds `oldCategoryId -> newCategoryId` map and batch updates all expenses.

---

## Data Integrity Constraints

1. **No Orphaned References**: Migration ensures all expense `categoryId` values reference valid global categories
2. **No Duplicate Names**: Case-insensitive uniqueness enforced at creation time
3. **No Negative Usage**: Firestore Security Rules prevent negative `usageCount`
4. **No Empty Names**: Validation prevents empty category names at client and server
5. **Immutable Rate Logs**: Once created, UserCategoryCreationLog entries cannot be modified (append-only)

---

## Performance Considerations

**Query Optimizations**:
- Top 5 categories: Single query with `limit(5)` on `usageCount DESC` index
- Search: Prefix matching on `nameLowercase` with composite index
- Rate limit check: Indexed query on `userId` + `createdAt` (typically returns 0-3 docs)

**Cache Strategy**:
- Local cache (Hive): Top 20 categories for offline access
- Firestore cache: Default Firestore SDK caching (persistence enabled)
- No in-memory cache: Stream-based updates keep UI fresh

**Write Optimization**:
- Usage increment: Batched with expense creation (single round-trip)
- Rate limit log: Async write (doesn't block category creation UI)

---

## Security Rules

```javascript
// Firestore Security Rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Global categories
    match /categories/{categoryId} {
      // Anyone can read categories
      allow read: if true;

      // Authenticated users can create if:
      // - Valid name (1-50 chars, valid characters)
      // - Not rate limited (< 3 creations in 5 min)
      // - No duplicate name (case-insensitive)
      allow create: if request.auth != null &&
        isValidCategoryName(request.resource.data.name) &&
        !isRateLimited(request.auth.uid) &&
        !isDuplicateName(request.resource.data.nameLowercase);

      // No updates or deletes allowed
      allow update, delete: if false;
    }

    // Rate limit logs
    match /categoryCreationLogs/{logId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null &&
        request.resource.data.userId == request.auth.uid;
      allow update, delete: if false;
    }

    // Helper functions
    function isValidCategoryName(name) {
      return name.size() >= 1 &&
             name.size() <= 50 &&
             name.matches('^[\\p{L}\\p{N}\\s\'\\-&]+$');
    }

    function isRateLimited(userId) {
      let fiveMinutesAgo = request.time - duration.value(5, 'm');
      let recentLogs = firestore.get(/databases/$(database)/documents/categoryCreationLogs)
        .data.where('userId', '==', userId)
        .where('createdAt', '>', fiveMinutesAgo);
      return recentLogs.size() >= 3;
    }

    function isDuplicateName(nameLower) {
      let existing = firestore.get(/databases/$(database)/documents/categories)
        .data.where('nameLowercase', '==', nameLower);
      return existing.size() > 0;
    }
  }
}
```

---

## Next Phase

**Phase 2**: Generate task breakdown with dependencies (run `/speckit.tasks`)
