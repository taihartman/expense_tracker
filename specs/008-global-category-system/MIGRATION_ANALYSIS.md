# Migration Analysis - Trip-Specific to Global Categories

**Feature ID**: 008-global-category-system
**Task**: T053 - Analyze existing expense category structure
**Date**: 2025-10-31

## Executive Summary

**Finding**: The expense model has ALWAYS used `categoryId` (nullable String). There is **NO** legacy string-based category field to migrate.

**Migration Requirement**: Move categories from trip subcollections (`/trips/{tripId}/categories/{categoryId}`) to global collection (`/categories/{categoryId}`) and update expense references.

**Impact**: Medium complexity - requires Firestore data migration script with deduplication logic.

---

## Current Data Structure

### Expense Model (Always had this structure)

```dart
class Expense {
  final String id;
  final String tripId;
  // ... other fields ...
  final String? categoryId;  // ← Always been here since day 1
}
```

**Evidence**: Git history shows `categoryId` field exists in earliest commit (86bc02c).

### Old Structure (Pre-Migration)

**Trip-Specific Categories**:
```
/trips/{tripId}/categories/{categoryId}
  ├── name: "Meals"
  ├── icon: "restaurant"
  ├── color: "#FF5722"
  └── usageCount: 15
```

**Firestore Rules** (from early commits):
```javascript
// Categories, fxRates, expenses: Inherit trip permissions
match /trips/{tripId} {
  match /{document=**} {
    allow read, write: if isAuthenticated();
  }
}
```

**Evidence**: Comment in firestore.rules indicates categories was a subcollection.

### New Structure (Post-Migration)

**Global Categories**:
```
/categories/{categoryId}
  ├── name: "Meals"
  ├── nameLowercase: "meals"  // NEW: for case-insensitive search
  ├── icon: "restaurant"
  ├── color: "#FF5722"
  ├── usageCount: 45           // NEW: aggregated across all trips
  ├── createdAt: Timestamp
  └── updatedAt: Timestamp
```

---

## Migration Scenarios

### Scenario 1: Expense with Valid Category Reference

**Before**:
```
/trips/trip1/categories/cat1
  └── name: "Meals"

/expenses/exp1
  ├── tripId: "trip1"
  └── categoryId: "cat1"  // Points to trip1's category
```

**After**:
```
/categories/global-cat-meals
  ├── name: "Meals"
  ├── nameLowercase: "meals"
  └── usageCount: 1

/expenses/exp1
  ├── tripId: "trip1"
  └── categoryId: "global-cat-meals"  // Updated to global category
```

**Migration Action**: Create global "Meals" category, update expense reference.

---

### Scenario 2: Multiple Trips with Same Category Name

**Before**:
```
/trips/trip1/categories/cat1
  └── name: "Meals"

/trips/trip2/categories/cat2
  └── name: "Meals"  // Same name, different ID

/expenses/exp1
  └── categoryId: "cat1"

/expenses/exp2
  └── categoryId: "cat2"
```

**After**:
```
/categories/global-cat-meals
  ├── name: "Meals"
  ├── nameLowercase: "meals"
  └── usageCount: 2  // Aggregated from both trips

/expenses/exp1
  └── categoryId: "global-cat-meals"

/expenses/exp2
  └── categoryId: "global-cat-meals"  // Both point to same global category
```

**Migration Action**: Deduplicate by name (case-insensitive), merge usageCount.

---

### Scenario 3: Expense with Null Category

**Before**:
```
/expenses/exp1
  └── categoryId: null  // No category assigned
```

**After**:
```
/expenses/exp1
  └── categoryId: null  // No change needed
```

**Migration Action**: None - null categories stay null.

---

### Scenario 4: Orphaned Expense (Category Deleted)

**Before**:
```
/expenses/exp1
  └── categoryId: "cat-deleted"  // References non-existent category
```

**After**:
```
/expenses/exp1
  └── categoryId: null  // Set to null (category doesn't exist)
```

**Migration Action**: Set categoryId to null for orphaned references.

---

## Data Discovery Queries

### Query 1: Find All Trip-Specific Categories

```javascript
// Firebase console or script
const trips = await db.collection('trips').get();

for (const trip of trips.docs) {
  const categories = await db
    .collection('trips')
    .doc(trip.id)
    .collection('categories')
    .get();

  console.log(`Trip ${trip.id}: ${categories.size} categories`);
}
```

**Expected Output**: List of all trips with their category counts.

---

### Query 2: Find Expenses with Categories

```javascript
const expenses = await db
  .collection('expenses')
  .where('categoryId', '!=', null)
  .get();

console.log(`${expenses.size} expenses have categories assigned`);
```

**Expected Output**: Count of expenses that reference categories.

---

### Query 3: Identify Duplicate Category Names

```javascript
const categoryNames = new Map(); // name.toLowerCase() → count

for (const trip of trips.docs) {
  const categories = await db
    .collection('trips')
    .doc(trip.id)
    .collection('categories')
    .get();

  for (const cat of categories.docs) {
    const nameLower = cat.data().name.toLowerCase();
    categoryNames.set(nameLower, (categoryNames.get(nameLower) || 0) + 1);
  }
}

// Find duplicates
for (const [name, count] of categoryNames) {
  if (count > 1) {
    console.log(`"${name}": appears in ${count} trips`);
  }
}
```

**Expected Output**: List of category names that appear in multiple trips.

---

## Migration Complexity Assessment

### Deduplication Logic

**Challenge**: Multiple trips may have categories with the same name but different:
- Icon (e.g., "Meals" with restaurant vs. fastfood icon)
- Color (e.g., "Meals" in red vs. orange)
- Usage count

**Resolution Strategy**:
1. **Group by name (case-insensitive)**
2. **Majority vote for icon**: Use most common icon across trips
3. **Majority vote for color**: Use most common color across trips
4. **Sum usage counts**: Aggregate from all trips
5. **Warn on conflicts**: Log when icon/color varies

**Example**:
```
Trip 1: "Meals" (restaurant, #FF5722, usageCount: 10)
Trip 2: "Meals" (fastfood, #FF5722, usageCount: 5)
Trip 3: "Meals" (restaurant, #E91E63, usageCount: 3)

Result: "Meals" (restaurant [2/3 majority], #FF5722 [2/3 majority], usageCount: 18)
```

### ID Mapping

**Challenge**: Expenses reference old trip-specific category IDs that will change.

**Resolution**:
1. **Create ID mapping table**:
   ```
   {
     "trip1-cat1": "global-cat-meals",
     "trip2-cat2": "global-cat-meals",
     "trip1-cat3": "global-cat-transport",
     ...
   }
   ```

2. **Batch update expenses**:
   ```javascript
   for (const [oldId, newId] of idMapping) {
     const expenses = await db
       .collection('expenses')
       .where('categoryId', '==', oldId)
       .get();

     const batch = db.batch();
     for (const exp of expenses.docs) {
       batch.update(exp.ref, { categoryId: newId });
     }
     await batch.commit();
   }
   ```

---

## Migration Risks

### Risk 1: Data Loss During Migration
**Severity**: HIGH
**Mitigation**:
- Create Firestore backup before migration
- Use batched writes (500 writes/batch max)
- Implement rollback mechanism
- Test on staging environment first

### Risk 2: Concurrent Updates During Migration
**Severity**: MEDIUM
**Mitigation**:
- Run migration during low-traffic window
- Implement migration lock (flag in Firestore)
- Use transactions where possible

### Risk 3: Orphaned Expense References
**Severity**: LOW
**Mitigation**:
- Set categoryId to null for orphaned references
- Log all orphaned expenses for manual review

### Risk 4: Icon/Color Conflicts
**Severity**: LOW
**Mitigation**:
- Use majority vote algorithm
- Log conflicts for manual review
- Allow users to customize after migration

---

## Estimated Migration Impact

### Production Data Estimates (Assumptions)

- **Trips**: ~50 trips (based on development/testing data)
- **Categories per trip**: ~5-10 average
- **Total trip-specific categories**: ~250-500
- **Unique category names** (after deduplication): ~20-30
- **Expenses with categories**: ~60-70% of total expenses

### Migration Time Estimate

**Phase 1 - Analysis** (10-15 min):
- Scan all trips for categories
- Build deduplication mapping
- Generate conflict report

**Phase 2 - Create Global Categories** (5-10 min):
- Create ~20-30 global categories
- Batched writes (500/batch)

**Phase 3 - Update Expenses** (15-30 min):
- Update categoryId for all expenses
- Batched updates (500/batch)
- Assumes ~1000-2000 expenses

**Total**: ~30-55 minutes for production migration

---

## Migration Script Requirements (T054-T057)

### T054: Design Migration Strategy

**Deliverables**:
1. Detailed migration algorithm pseudocode
2. Deduplication rules (icon/color resolution)
3. Rollback procedure
4. Data validation checks

### T055: Write Migration Script Logic

**Language**: Dart (Flutter CLI tool)
**Why**: Reuse existing Firestore models and serialization

**Key Functions**:
```dart
Future<void> migrateCategories() async {
  // 1. Scan all trip categories
  final tripCategories = await scanTripCategories();

  // 2. Deduplicate and create global categories
  final globalCategories = await createGlobalCategories(tripCategories);

  // 3. Build ID mapping
  final idMapping = buildIdMapping(tripCategories, globalCategories);

  // 4. Update all expense references
  await updateExpenseReferences(idMapping);

  // 5. Verify migration
  await verifyMigration();
}
```

### T056: Add Rollback/Safety Mechanisms

**Backup Strategy**:
```bash
# Before migration
gcloud firestore export gs://backup-bucket/pre-migration-backup

# After migration (if needed)
gcloud firestore import gs://backup-bucket/pre-migration-backup
```

**Migration Lock**:
```dart
// Set migration in progress flag
await db.collection('_system').doc('migration').set({
  'status': 'in_progress',
  'startedAt': Timestamp.now(),
});

try {
  await migrateCategories();

  await db.collection('_system').doc('migration').set({
    'status': 'completed',
    'completedAt': Timestamp.now(),
  });
} catch (e) {
  await db.collection('_system').doc('migration').set({
    'status': 'failed',
    'error': e.toString(),
  });
  rethrow;
}
```

### T057: Test on Staging Data

**Test Scenarios**:
1. Empty database (no categories)
2. Single trip with categories
3. Multiple trips with duplicate category names
4. Expenses with null categories
5. Expenses with orphaned category references
6. Concurrent expense creation during migration

**Success Criteria**:
- All categories migrated to global collection
- No data loss
- All expense references updated correctly
- Orphaned references set to null
- Deduplication working as expected
- Performance acceptable (< 1 hour for 10k expenses)

---

## Next Steps

1. **Review this analysis** with stakeholders
2. **Approve migration strategy** (T054)
3. **Implement migration script** (T055)
4. **Add safety mechanisms** (T056)
5. **Test on staging** (T057)
6. **Execute on production** (T070)

---

## Appendices

### Appendix A: Category Data Schema Evolution

**Old Schema** (Trip-Specific):
```typescript
interface TripCategory {
  id: string;
  name: string;
  icon: string;
  color: string;
  usageCount: number;
}

// Location: /trips/{tripId}/categories/{categoryId}
```

**New Schema** (Global):
```typescript
interface GlobalCategory {
  id: string;
  name: string;
  nameLowercase: string;  // NEW
  icon: string;
  color: string;
  usageCount: number;
  createdAt: Timestamp;   // NEW
  updatedAt: Timestamp;   // NEW
}

// Location: /categories/{categoryId}
```

### Appendix B: Firestore Indexes Required

Already defined in `firestore.indexes.json`:
```json
{
  "collectionGroup": "categories",
  "queryScope": "COLLECTION",
  "fields": [
    { "fieldPath": "nameLowercase", "order": "ASCENDING" },
    { "fieldPath": "usageCount", "order": "DESCENDING" }
  ]
}
```

**Deploy before migration**:
```bash
firebase deploy --only firestore:indexes
```

---

**Document Status**: ✅ **COMPLETE**
**Next Task**: T054 - Design migration strategy
**Prepared By**: Claude (AI Assistant)
**Review Required**: Lead Engineer approval
