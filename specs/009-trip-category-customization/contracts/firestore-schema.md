# Firestore Schema Contracts

**Feature**: Per-Trip Category Visual Customization + Icon System Improvements
**Version**: 1.0.0
**Date**: 2025-10-31

## Collections

### /categoryIconPreferences/{categoryId}

**Purpose**: Store voting data for category icon preferences

**Document ID**: Same as category ID (1-to-1 relationship)

**Fields**:
```typescript
{
  categoryId: string;          // Reference to /categories/{id}
  preferences: {               // Map of icon names to vote counts
    [iconName: string]: number;
  };
  mostPopular: string;         // Icon name with highest vote count
  lastUpdatedAt: Timestamp;    // Server timestamp of last vote
}
```

**Example**:
```json
{
  "categoryId": "abc123",
  "preferences": {
    "restaurant": 5,
    "fastfood": 3,
    "local_cafe": 1
  },
  "mostPopular": "restaurant",
  "lastUpdatedAt": "2025-10-31T12:30:45Z"
}
```

**Indexes**: None required (single-document reads)

**Security Rules**:
```javascript
match /categoryIconPreferences/{categoryId} {
  allow read: if request.auth != null;
  allow create, update: if request.auth != null 
                      && request.resource.data.categoryId == categoryId;
  allow delete: if false;  // No deletion allowed
}
```

**Write Operations**:
- **recordVote**: Transaction-based increment of preference count
- **updateMostPopular**: Automatic recalculation on vote
- **updateGlobalIcon**: Updates /categories/{id} when threshold reached

---

### /categories/{categoryId} (Enhanced)

**Changes**: Icon field can be updated by voting system

**Vote-Related Behavior**:
- When vote threshold reached (3 votes), `icon` field updates to `mostPopular` from preferences
- `updatedAt` timestamp refreshed on icon change
- No other fields affected by voting

**Example Update**:
```javascript
// Before voting
{ "icon": "tree", "updatedAt": "2025-10-30T10:00:00Z" }

// After 3 users vote for "ski"
{ "icon": "ski", "updatedAt": "2025-10-31T14:20:00Z" }
```

---

## Transaction Patterns

### Vote Recording Transaction

**Purpose**: Atomically record vote and update icon if threshold reached

**Steps**:
1. Read `/categoryIconPreferences/{categoryId}`
2. Increment `preferences[iconName]`
3. Recalculate `mostPopular`
4. Update `lastUpdatedAt`
5. IF `preferences[mostPopular] >= 3` THEN update `/categories/{categoryId}.icon`

**Code Example**:
```dart
await firestore.runTransaction((transaction) async {
  final prefDoc = firestore.collection('categoryIconPreferences').doc(categoryId);
  final snapshot = await transaction.get(prefDoc);

  final prefs = snapshot.data()?['preferences'] ?? {};
  prefs[iconName] = (prefs[iconName] ?? 0) + 1;

  final mostPopular = prefs.entries.reduce((a, b) => a.value > b.value ? a : b).key;

  transaction.set(prefDoc, {
    'categoryId': categoryId,
    'preferences': prefs,
    'mostPopular': mostPopular,
    'lastUpdatedAt': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));

  if (prefs[mostPopular] >= 3) {
    transaction.update(
      firestore.collection('categories').doc(categoryId),
      {'icon': mostPopular, 'updatedAt': FieldValue.serverTimestamp()},
    );
  }
});
```

**Conflict Resolution**: Last write wins (Firestore default)

---

## API Methods

### CategoryCustomizationRepository

#### recordIconPreference()

**Signature**:
```dart
Future<void> recordIconPreference({
  required String categoryId,
  required String iconName,
}) async
```

**Preconditions**:
- `categoryId` must exist in `/categories`
- `iconName` must be valid CategoryIcon enum value

**Behavior**:
- Increment vote count atomically
- Update global icon if threshold reached
- Non-blocking: errors logged but don't fail customization

**Returns**: `void` (fire-and-forget operation)

**Exceptions**: Swallowed (voting failures don't block customization)

---

### CategoryRepository

#### findSimilarCategories()

**Signature**:
```dart
Future<List<Category>> findSimilarCategories({
  required String name,
  double similarityThreshold = 0.80,
}) async
```

**Preconditions**:
- `name` must be non-empty

**Behavior**:
- Load all categories (cached)
- Calculate Jaro-Winkler similarity
- Return top 3 matches above threshold
- Sorted by similarity descending

**Returns**: `List<Category>` (max 3 items)

**Exceptions**: Returns empty list on error

---

## Migration Guide

### Adding categoryIconPreferences Collection

**Step 1**: Deploy security rules
```bash
# Update firestore.rules
firebase deploy --only firestore:rules
```

**Step 2**: No data seeding required
- Collection auto-populates as users vote
- First vote creates document with initial preference count

**Step 3**: Monitor
```bash
# Check vote counts
gcloud firestore documents list --collection-ids=categoryIconPreferences
```

**Rollback**: Delete collection if needed (no impact on categories)

---

**Contract Version**: 1.0.0
**Last Updated**: 2025-10-31
**Status**: Ready for implementation
