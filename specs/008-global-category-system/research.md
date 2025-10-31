# Research: Global Category Management System

**Date**: 2025-10-31
**Phase**: 0 (Pre-Implementation Research)
**Purpose**: Resolve technical unknowns and establish best practices before implementation

## Research Areas

### 1. Firestore Case-Insensitive Queries

**Question**: How to implement efficient case-insensitive search and duplicate detection in Firestore?

**Decision**: Use lowercase normalization with a dedicated field

**Rationale**:
- Firestore doesn't support native case-insensitive queries
- Adding a `nameLowercase` field enables efficient indexed queries
- Composite index on `nameLowercase` + `usageCount` enables sorted search results
- Client-side normalization before write ensures data consistency

**Implementation Approach**:
```dart
// Category model with normalized field
class Category {
  final String name;           // Display name: "Meals"
  final String nameLowercase;  // Search key: "meals"

  Category copyWith({String? name}) => Category(
    name: name ?? this.name,
    nameLowercase: (name ?? this.name).toLowerCase(),
  );
}

// Repository search query
Stream<List<Category>> searchCategories(String query) {
  final normalized = query.toLowerCase();
  return _firestore
    .collection('categories')
    .where('nameLowercase', isGreaterThanOrEqualTo: normalized)
    .where('nameLowercase', isLessThan: normalized + '\uf8ff')
    .orderBy('nameLowercase')
    .orderBy('usageCount', descending: true)
    .snapshots();
}
```

**Required Firestore Indexes**:
- Composite: `nameLowercase ASC` + `usageCount DESC`
- Single: `usageCount DESC` (for top categories)

**Alternatives Considered**:
- Client-side filtering: Would require fetching all categories (poor performance at scale)
- Cloud Functions: Added complexity and latency for simple normalization
- Algolia integration: Overkill for 100-500 categories, added cost and dependency

---

### 2. Rate Limiting Strategy

**Question**: How to implement client-side rate limiting (3 categories per 5 minutes) with Firestore?

**Decision**: Firestore subcollection with timestamp-based querying

**Rationale**:
- Firestore Security Rules can enforce server-side validation
- Client-side service provides immediate feedback before network round-trip
- Timestamp queries enable efficient "last 5 minutes" checks
- Automatic cleanup via Firestore TTL policies (optional optimization)

**Implementation Approach**:
```dart
// Rate limiter service
class RateLimiterService {
  Future<bool> canCreateCategory(String userId) async {
    final fiveMinutesAgo = DateTime.now().subtract(Duration(minutes: 5));

    final recentCreations = await _firestore
      .collection('categoryCreationLogs')
      .where('userId', isEqualTo: userId)
      .where('createdAt', isGreaterThan: fiveMinutesAgo)
      .get();

    return recentCreations.docs.length < 3;
  }

  Future<void> logCategoryCreation(String userId, String categoryId) async {
    await _firestore.collection('categoryCreationLogs').add({
      'userId': userId,
      'categoryId': categoryId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
```

**Firestore Security Rules**:
```javascript
// Enforce rate limiting server-side
match /categories/{categoryId} {
  allow create: if request.auth != null &&
    getUserRecentCreations(request.auth.uid) < 3;
}

function getUserRecentCreations(userId) {
  let fiveMinutesAgo = request.time - duration.value(5, 'm');
  return firestore.get(/databases/$(database)/documents/categoryCreationLogs)
    .where('userId', '==', userId)
    .where('createdAt', '>', fiveMinutesAgo)
    .size();
}
```

**Alternatives Considered**:
- Cloud Functions: Higher latency, more complex deployment
- Local storage only: No server-side enforcement (client can bypass)
- User document counter: Race conditions, doesn't auto-expire

---

### 3. Bottom Sheet UX Patterns

**Question**: What are mobile-first best practices for bottom sheet category browser?

**Decision**: Modal bottom sheet with DraggableScrollableSheet

**Rationale**:
- Native Flutter pattern: `showModalBottomSheet` is familiar to users
- DraggableScrollableSheet enables swipe-to-dismiss and partial/full height
- Search field at top (fixed), scrollable results below
- Supports both mobile (full-screen-like) and desktop (constrained width)

**Implementation Approach**:
```dart
void _showCategoryBrowser(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) => DraggableScrollableSheet(
      initialChildSize: 0.9,  // 90% of screen height
      minChildSize: 0.5,       // Can shrink to 50%
      maxChildSize: 0.95,      // Can expand to 95%
      builder: (context, scrollController) => CategoryBrowserBottomSheet(
        scrollController: scrollController,
      ),
    ),
  );
}
```

**Mobile UX Details**:
- Search field: Fixed at top, auto-focus on open
- Results list: Scrollable with `scrollController` from DraggableScrollableSheet
- Loading: Shimmer for initial load (<200ms target)
- Empty state: "No results" with "Create" CTA
- Tap outside or swipe down: Dismiss without selection

**Alternatives Considered**:
- Full-screen dialog: Loses context, feels heavier
- Dropdown menu: Doesn't support search or scrolling well on mobile
- Separate page: Requires navigation, breaks expense creation flow

---

### 4. Icon Picker Implementation

**Question**: How to implement Material icon picker with search?

**Decision**: Grid layout with search filtering using flutter icon data

**Rationale**:
- Material Icons data available via `Icons` class reflection
- Grid layout optimal for visual icon scanning
- Search by icon name (e.g., "restaurant", "car") common pattern
- Lightweight: No additional dependencies

**Implementation Approach**:
```dart
// Icon picker widget
class IconPicker extends StatefulWidget {
  final IconData? selectedIcon;
  final ValueChanged<IconData> onIconSelected;

  // Icon data from flutter/material
  static final List<IconData> materialIcons = [
    Icons.restaurant,
    Icons.directions_car,
    Icons.hotel,
    // ... ~1000 Material icons
  ];

  // Search filter
  List<IconData> _filterIcons(String query) {
    if (query.isEmpty) return materialIcons;
    return materialIcons.where((icon) {
      final iconName = icon.toString();
      return iconName.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }
}
```

**UI Layout**:
- Search field: Top, real-time filtering
- Grid: 6 columns on mobile (44x44px touch targets), 8 on desktop
- Selected state: Highlighted border
- Categories: Optional grouping (optional enhancement)

**Storage**:
- Store as string: `icon.codePoint.toString()` or icon name
- Retrieve: `IconData(int.parse(stored), fontFamily: 'MaterialIcons')`

**Alternatives Considered**:
- Icon library package: Adds dependency, unnecessary for Material icons
- Image-based icons: Larger bundle size, no customization
- Curated subset only: Limits user creativity, harder to maintain

---

### 5. Caching Strategy for Categories

**Question**: How to cache top 20 categories locally for offline access?

**Decision**: Hive for local storage with Stream-based updates

**Rationale**:
- Hive is fast, lightweight, and already used in Flutter apps
- Stream from Firestore updates cache automatically
- Cache persists across app restarts
- LRU-style eviction keeps only top 20

**Implementation Approach**:
```dart
class CategoryCacheService {
  final Box<Category> _cacheBox;

  // Listen to Firestore and update cache
  Stream<List<Category>> getTopCategories() {
    return _firestore
      .collection('categories')
      .orderBy('usageCount', descending: true)
      .limit(20)
      .snapshots()
      .map((snapshot) {
        final categories = snapshot.docs.map((doc) =>
          Category.fromFirestore(doc)
        ).toList();

        // Update cache
        _cacheBox.clear();
        for (final category in categories) {
          _cacheBox.put(category.id, category);
        }

        return categories;
      });
  }

  // Get cached categories (offline)
  List<Category> getCachedCategories() {
    return _cacheBox.values.toList()
      ..sort((a, b) => b.usageCount.compareTo(a.usageCount));
  }
}
```

**Cache Invalidation**:
- Auto-update: Stream from Firestore keeps cache fresh
- Manual refresh: Pull-to-refresh on category browser
- TTL: Optional 1-hour expiry for stale data

**Alternatives Considered**:
- SharedPreferences: Limited storage, slower for large objects
- In-memory only: Lost on app restart
- Service worker cache: Web-specific, not universal

---

### 6. Migration Script Pattern

**Question**: How to safely migrate trip-specific categories to global pool?

**Decision**: Batched Firestore writes with progress tracking

**Rationale**:
- Firestore batch limit: 500 operations per batch
- Multiple batches for >500 categories
- Rollback strategy: Store original tripId for reference
- Idempotent: Can re-run if interrupted

**Implementation Approach**:
```dart
// Migration script (run once via Cloud Functions or local script)
Future<void> migrateTripCategoriesToGlobal() async {
  // Step 1: Query all trip-specific categories
  final tripCategories = await _firestore
    .collectionGroup('categories')  // Assumes subcollection pattern
    .get();

  // Step 2: Group by name (case-insensitive) to find duplicates
  final Map<String, List<Category>> grouped = {};
  for (final doc in tripCategories.docs) {
    final category = Category.fromFirestore(doc);
    final key = category.name.toLowerCase();
    grouped.putIfAbsent(key, () => []).add(category);
  }

  // Step 3: Create global categories (merge duplicates)
  final globalCategoryMap = <String, String>{}; // old ID -> new ID

  for (final entry in grouped.entries) {
    final categories = entry.value;
    final mergedCategory = _mergeDuplicates(categories);

    // Create global category
    final docRef = await _firestore.collection('categories').add({
      ...mergedCategory.toFirestore(),
      'migratedFrom': categories.map((c) => c.id).toList(),
    });

    // Map old IDs to new ID
    for (final oldCategory in categories) {
      globalCategoryMap[oldCategory.id] = docRef.id;
    }
  }

  // Step 4: Update expense categoryId references (batched)
  final expenses = await _firestore.collectionGroup('expenses').get();
  final batches = <WriteBatch>[];
  var currentBatch = _firestore.batch();
  var operationCount = 0;

  for (final expenseDoc in expenses.docs) {
    final oldCategoryId = expenseDoc.data()['categoryId'];
    if (oldCategoryId != null && globalCategoryMap.containsKey(oldCategoryId)) {
      currentBatch.update(expenseDoc.reference, {
        'categoryId': globalCategoryMap[oldCategoryId],
      });
      operationCount++;

      // Start new batch every 500 operations
      if (operationCount >= 500) {
        batches.add(currentBatch);
        currentBatch = _firestore.batch();
        operationCount = 0;
      }
    }
  }

  if (operationCount > 0) batches.add(currentBatch);

  // Step 5: Commit all batches
  for (final batch in batches) {
    await batch.commit();
  }

  print('Migration complete: ${globalCategoryMap.length} categories migrated');
}

Category _mergeDuplicates(List<Category> categories) {
  // Pick most common icon/color, sum usage counts
  final iconCounts = <String, int>{};
  final colorCounts = <String, int>{};
  var totalUsage = 0;

  for (final category in categories) {
    iconCounts[category.icon] = (iconCounts[category.icon] ?? 0) + 1;
    colorCounts[category.color] = (colorCounts[category.color] ?? 0) + 1;
    totalUsage += category.usageCount;
  }

  final mostCommonIcon = iconCounts.entries.reduce((a, b) =>
    a.value > b.value ? a : b
  ).key;
  final mostCommonColor = colorCounts.entries.reduce((a, b) =>
    a.value > b.value ? a : b
  ).key;

  return Category(
    name: categories.first.name,  // Use original casing from first
    icon: mostCommonIcon,
    color: mostCommonColor,
    usageCount: totalUsage,
  );
}
```

**Safety Measures**:
- Dry-run mode: Preview changes without committing
- Backup: Export existing data before migration
- Verification: Count total expenses before/after
- Rollback: Store `migratedFrom` field to reverse if needed

**Alternatives Considered**:
- Direct Firestore updates: No batching, risk of partial completion
- Cloud Functions: More complex deployment, similar logic
- Manual SQL-style migration: Firestore is NoSQL, doesn't fit pattern

---

### 7. Character Validation Pattern

**Question**: How to validate category names for allowed characters?

**Decision**: RegExp-based validator with clear error messages

**Rationale**:
- RegExp efficient for character class matching
- Single validation rule covers all constraints
- Clear error messages for UX
- Reusable across client and server (Security Rules)

**Implementation Approach**:
```dart
class CategoryValidator {
  // Allow: letters (Unicode), numbers, spaces, apostrophes, hyphens, ampersands
  static final RegExp _validChars = RegExp(r"^[\p{L}\p{N}\s'\-&]+$", unicode: true);

  static String? validateCategoryName(String name) {
    if (name.isEmpty) {
      return 'Category name cannot be empty';
    }
    if (name.length > 50) {
      return 'Category name must be 50 characters or less';
    }
    if (!_validChars.hasMatch(name)) {
      return 'Category names can only contain letters, numbers, spaces, and basic punctuation';
    }
    return null; // Valid
  }
}
```

**Firestore Security Rules**:
```javascript
function isValidCategoryName(name) {
  return name.size() >= 1 &&
         name.size() <= 50 &&
         name.matches('^[\\p{L}\\p{N}\\s\'\\-&]+$');
}
```

**Alternatives Considered**:
- Whitelist approach: Hard to maintain, doesn't cover Unicode
- Blacklist approach: Easy to miss edge cases
- No validation: Opens door to spam and display issues

---

## Summary

All technical unknowns resolved. Key decisions:
1. **Case-insensitive search**: Lowercase normalized field + Firestore indexes
2. **Rate limiting**: Firestore subcollection + Security Rules enforcement
3. **Bottom sheet**: DraggableScrollableSheet with fixed search, scrollable results
4. **Icon picker**: Grid layout with Material Icons reflection
5. **Caching**: Hive for top 20 categories with Stream updates
6. **Migration**: Batched writes with duplicate merging and expense reference updates
7. **Validation**: RegExp for character class matching with clear errors

**Next Phase**: Data model design and API contracts (Phase 1)
