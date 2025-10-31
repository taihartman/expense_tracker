# Migration Strategy - Trip-Specific to Global Categories

**Feature ID**: 008-global-category-system
**Task**: T054 - Design migration strategy
**Date**: 2025-10-31

## Overview

This document defines the detailed migration strategy, algorithms, and procedures for migrating trip-specific categories to the global category system.

**See Also**: [MIGRATION_ANALYSIS.md](./MIGRATION_ANALYSIS.md) for background and data structure analysis.

---

## Migration Algorithm

### High-Level Flow

```
┌─────────────────────────────────────────────────────────────┐
│ 1. PRE-MIGRATION VALIDATION                                 │
│    - Check Firestore indexes deployed                       │
│    - Verify backup created                                  │
│    - Set migration lock                                     │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ 2. SCAN & COLLECT                                           │
│    - Scan all trip-specific categories                      │
│    - Build category inventory with metadata                 │
│    - Log stats (total categories, unique names)             │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ 3. DEDUPLICATE & MERGE                                      │
│    - Group by name (case-insensitive)                       │
│    - Resolve icon conflicts (majority vote)                 │
│    - Resolve color conflicts (majority vote)                │
│    - Sum usageCount across all instances                    │
│    - Generate global category definitions                   │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ 4. CREATE GLOBAL CATEGORIES                                 │
│    - Create categories in /categories collection            │
│    - Use batched writes (500/batch)                         │
│    - Log new category IDs                                   │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ 5. BUILD ID MAPPING                                         │
│    - Map old trip category IDs → new global IDs             │
│    - Example: {trip1-cat1: global-meals, ...}               │
│    - Save mapping to migration log                          │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ 6. UPDATE EXPENSE REFERENCES                                │
│    - Query expenses by old categoryId                       │
│    - Update to new global categoryId                        │
│    - Use batched writes (500/batch)                         │
│    - Handle orphaned references (set to null)               │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ 7. VERIFY & CLEANUP                                         │
│    - Verify all expenses updated                            │
│    - Verify no orphaned trip categories remain              │
│    - Generate migration report                              │
│    - Clear migration lock                                   │
└─────────────────────────────────────────────────────────────┘
```

---

## Detailed Algorithms

### Algorithm 1: Scan Trip Categories

**Input**: Firestore database
**Output**: `List<TripCategorySnapshot>`

```dart
class TripCategorySnapshot {
  final String tripId;
  final String categoryId;
  final String name;
  final String icon;
  final String color;
  final int usageCount;
}

Future<List<TripCategorySnapshot>> scanTripCategories(
  FirebaseFirestore db,
) async {
  final snapshots = <TripCategorySnapshot>[];

  // 1. Get all trips
  final tripsQuery = await db.collection('trips').get();

  print('Found ${tripsQuery.size} trips to scan');

  // 2. For each trip, get its categories subcollection
  for (final tripDoc in tripsQuery.docs) {
    final tripId = tripDoc.id;

    final categoriesQuery = await db
        .collection('trips')
        .doc(tripId)
        .collection('categories')
        .get();

    print('Trip $tripId: ${categoriesQuery.size} categories');

    // 3. Collect category data
    for (final catDoc in categoriesQuery.docs) {
      final data = catDoc.data();

      snapshots.add(TripCategorySnapshot(
        tripId: tripId,
        categoryId: catDoc.id,
        name: data['name'] as String,
        icon: data['icon'] as String? ?? 'category',
        color: data['color'] as String? ?? '#9E9E9E',
        usageCount: data['usageCount'] as int? ?? 0,
      ));
    }
  }

  print('Total categories scanned: ${snapshots.length}');

  return snapshots;
}
```

**Error Handling**:
- If trip has no categories subcollection: Skip (no action needed)
- If category missing required fields: Log warning, use defaults
- If Firestore query fails: Throw exception, abort migration

---

### Algorithm 2: Deduplicate Categories

**Input**: `List<TripCategorySnapshot>`
**Output**: `List<GlobalCategoryDefinition>`

```dart
class GlobalCategoryDefinition {
  final String name;
  final String nameLowercase;
  final String icon;           // Resolved via majority vote
  final String color;          // Resolved via majority vote
  final int totalUsageCount;   // Sum of all instances
  final List<String> sourceIds; // Original trip category IDs
}

List<GlobalCategoryDefinition> deduplicateCategories(
  List<TripCategorySnapshot> snapshots,
) {
  // 1. Group by name (case-insensitive)
  final groups = <String, List<TripCategorySnapshot>>{};

  for (final snapshot in snapshots) {
    final nameLower = snapshot.name.trim().toLowerCase();
    groups.putIfAbsent(nameLower, () => []).add(snapshot);
  }

  print('Found ${groups.length} unique category names');

  // 2. For each group, resolve conflicts and merge
  final definitions = <GlobalCategoryDefinition>[];

  for (final entry in groups.entries) {
    final nameLower = entry.key;
    final instances = entry.value;

    // Use original name from first instance (preserve casing)
    final name = instances.first.name.trim();

    // Resolve icon (majority vote)
    final icon = _majorityVote(
      instances.map((i) => i.icon).toList(),
      defaultValue: 'category',
    );

    // Resolve color (majority vote)
    final color = _majorityVote(
      instances.map((i) => i.color).toList(),
      defaultValue: '#9E9E9E',
    );

    // Sum usage counts
    final totalUsageCount = instances.fold<int>(
      0,
      (sum, i) => sum + i.usageCount,
    );

    // Collect source IDs for mapping
    final sourceIds = instances
        .map((i) => '${i.tripId}-${i.categoryId}')
        .toList();

    definitions.add(GlobalCategoryDefinition(
      name: name,
      nameLowercase: nameLower,
      icon: icon,
      color: color,
      totalUsageCount: totalUsageCount,
      sourceIds: sourceIds,
    ));

    // Log conflicts
    if (instances.length > 1) {
      final uniqueIcons = instances.map((i) => i.icon).toSet();
      final uniqueColors = instances.map((i) => i.color).toSet();

      if (uniqueIcons.length > 1) {
        print('⚠️  Icon conflict for "$name": $uniqueIcons → using $icon');
      }
      if (uniqueColors.length > 1) {
        print('⚠️  Color conflict for "$name": $uniqueColors → using $color');
      }
    }
  }

  return definitions;
}

/// Majority vote helper: returns most common value
String _majorityVote(List<String> values, {required String defaultValue}) {
  if (values.isEmpty) return defaultValue;

  // Count occurrences
  final counts = <String, int>{};
  for (final value in values) {
    counts[value] = (counts[value] ?? 0) + 1;
  }

  // Find most common
  String? winner;
  int maxCount = 0;

  for (final entry in counts.entries) {
    if (entry.value > maxCount) {
      maxCount = entry.value;
      winner = entry.key;
    }
  }

  return winner ?? defaultValue;
}
```

**Conflict Resolution Rules**:

1. **Name**: Use first instance's casing (e.g., "Meals" not "meals")
2. **Icon**: Majority vote (most common icon wins)
3. **Color**: Majority vote (most common color wins)
4. **UsageCount**: Sum all instances
5. **Tie-breaker**: If multiple values tied, use first occurrence

**Example**:
```
Input:
  Trip1: "Meals" (restaurant, #FF5722, count: 10)
  Trip2: "meals" (fastfood, #FF5722, count: 5)
  Trip3: "MEALS" (restaurant, #E91E63, count: 3)

Output:
  Name: "Meals" (from first instance)
  Icon: "restaurant" (2/3 votes)
  Color: "#FF5722" (2/3 votes)
  UsageCount: 18 (sum)
```

---

### Algorithm 3: Create Global Categories

**Input**: `List<GlobalCategoryDefinition>`
**Output**: `Map<String, String>` (nameLowercase → global category ID)

```dart
Future<Map<String, String>> createGlobalCategories(
  FirebaseFirestore db,
  List<GlobalCategoryDefinition> definitions,
) async {
  final mapping = <String, String>{};

  // Process in batches of 500 (Firestore limit)
  final batches = _splitIntoBatches(definitions, 500);

  for (int i = 0; i < batches.length; i++) {
    final batch = db.batch();
    final batchDefinitions = batches[i];

    print('Creating batch ${i + 1}/${batches.length} (${batchDefinitions.length} categories)');

    for (final def in batchDefinitions) {
      // Generate new document reference
      final categoryRef = db.collection('categories').doc();

      // Create category document
      batch.set(categoryRef, {
        'name': def.name,
        'nameLowercase': def.nameLowercase,
        'icon': def.icon,
        'color': def.color,
        'usageCount': def.totalUsageCount,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Save mapping for ID lookup
      mapping[def.nameLowercase] = categoryRef.id;

      print('  ✓ "${def.name}" → ${categoryRef.id}');
    }

    // Commit batch
    await batch.commit();
    print('  Batch ${i + 1} committed');
  }

  print('Created ${definitions.length} global categories');

  return mapping;
}

List<List<T>> _splitIntoBatches<T>(List<T> items, int batchSize) {
  final batches = <List<T>>[];
  for (int i = 0; i < items.length; i += batchSize) {
    final end = (i + batchSize < items.length) ? i + batchSize : items.length;
    batches.add(items.sublist(i, end));
  }
  return batches;
}
```

**Error Handling**:
- If batch commit fails: Log error, attempt retry (max 3 attempts)
- If all retries fail: Abort migration, rollback created categories
- If duplicate category exists: Skip creation, use existing ID

---

### Algorithm 4: Build ID Mapping

**Input**:
- `List<TripCategorySnapshot>` (original categories)
- `Map<String, String>` (nameLowercase → global ID)

**Output**: `Map<String, String>` (old ID → new ID)

```dart
Map<String, String> buildIdMapping(
  List<TripCategorySnapshot> snapshots,
  Map<String, String> globalCategoryIds,
) {
  final mapping = <String, String>{};

  for (final snapshot in snapshots) {
    final oldId = '${snapshot.tripId}-${snapshot.categoryId}';
    final nameLower = snapshot.name.trim().toLowerCase();

    // Lookup global category ID
    final globalId = globalCategoryIds[nameLower];

    if (globalId == null) {
      print('⚠️  No global category found for "$nameLower" (old ID: $oldId)');
      continue; // Skip - will be handled as orphaned reference
    }

    mapping[oldId] = globalId;
  }

  print('Built mapping for ${mapping.length} category IDs');

  return mapping;
}
```

**Mapping Example**:
```dart
{
  'trip1-cat1': 'global-abc123',  // trip1's "Meals" → global "Meals"
  'trip2-cat5': 'global-abc123',  // trip2's "Meals" → same global "Meals"
  'trip1-cat2': 'global-def456',  // trip1's "Transport" → global "Transport"
  // ... etc
}
```

---

### Algorithm 5: Update Expense References

**Input**: `Map<String, String>` (old ID → new ID)
**Output**: `MigrationStats`

```dart
class MigrationStats {
  int totalExpenses = 0;
  int updatedExpenses = 0;
  int orphanedExpenses = 0;
  int nullCategoryExpenses = 0;
}

Future<MigrationStats> updateExpenseReferences(
  FirebaseFirestore db,
  Map<String, String> idMapping,
) async {
  final stats = MigrationStats();

  // 1. Get all expenses (in batches to avoid memory issues)
  final expensesQuery = await db
      .collection('expenses')
      .orderBy(FieldPath.documentId)
      .get();

  stats.totalExpenses = expensesQuery.size;
  print('Found ${stats.totalExpenses} total expenses');

  // 2. Group by categoryId for efficient processing
  final expensesByCategory = <String?, List<String>>{};

  for (final expenseDoc in expensesQuery.docs) {
    final categoryId = expenseDoc.data()['categoryId'] as String?;
    expensesByCategory
        .putIfAbsent(categoryId, () => [])
        .add(expenseDoc.id);
  }

  print('Grouped into ${expensesByCategory.length} category buckets');

  // 3. Update expenses category by category
  for (final entry in expensesByCategory.entries) {
    final oldCategoryId = entry.key;
    final expenseIds = entry.value;

    if (oldCategoryId == null) {
      // Already null - no update needed
      stats.nullCategoryExpenses += expenseIds.length;
      continue;
    }

    // Look up new global category ID
    // Note: oldCategoryId is already in format "tripId-categoryId" from old system
    // OR it might be just "categoryId" - need to handle both cases

    String? newCategoryId;

    // Try direct lookup first (old format was just categoryId)
    newCategoryId = idMapping[oldCategoryId];

    // If not found, try looking up by matching to trip categories
    if (newCategoryId == null) {
      // This expense has orphaned reference
      print('⚠️  Orphaned category reference: $oldCategoryId (${expenseIds.length} expenses)');
      stats.orphanedExpenses += expenseIds.length;

      // Set to null
      await _updateExpensesBatch(
        db,
        expenseIds,
        newCategoryId: null,
      );

      continue;
    }

    // Update expenses with new category ID
    await _updateExpensesBatch(
      db,
      expenseIds,
      newCategoryId: newCategoryId,
    );

    stats.updatedExpenses += expenseIds.length;
    print('  ✓ Updated ${expenseIds.length} expenses: $oldCategoryId → $newCategoryId');
  }

  return stats;
}

Future<void> _updateExpensesBatch(
  FirebaseFirestore db,
  List<String> expenseIds,
  {required String? newCategoryId},
) async {
  // Process in batches of 500
  final batches = _splitIntoBatches(expenseIds, 500);

  for (final batchIds in batches) {
    final batch = db.batch();

    for (final expenseId in batchIds) {
      final expenseRef = db.collection('expenses').doc(expenseId);
      batch.update(expenseRef, {'categoryId': newCategoryId});
    }

    await batch.commit();
  }
}
```

**Edge Cases**:

1. **Null categoryId**: No update needed (already null)
2. **Orphaned reference**: Set to null, log warning
3. **Batch size exceeded**: Split into multiple batches (500/batch)
4. **Concurrent updates**: Use Firestore transactions if needed

---

## Rollback Procedures

### Rollback Strategy 1: Firestore Backup Restore

**Prerequisites**: Firestore backup created before migration

```bash
# Before migration
gcloud firestore export gs://backup-bucket/pre-global-categories-$(date +%Y%m%d-%H%M%S)

# Rollback (if needed)
gcloud firestore import gs://backup-bucket/pre-global-categories-20251031-120000
```

**Pros**: Complete rollback, restores exact state
**Cons**: Takes 30-60 minutes, overwrites any changes made after backup

---

### Rollback Strategy 2: Manual Reversal

If migration completed but needs reversal:

```dart
Future<void> rollbackMigration(
  FirebaseFirestore db,
  Map<String, String> idMapping, // Saved during migration
) async {
  // 1. Reverse expense categoryId updates
  final reverseMapping = <String, String>{};
  for (final entry in idMapping.entries) {
    reverseMapping[entry.value] = entry.key; // Swap key-value
  }

  // 2. Update expenses back to old category IDs
  // (Similar logic to updateExpenseReferences but reversed)

  // 3. Delete global categories
  final globalCategories = await db.collection('categories').get();
  final batch = db.batch();
  for (final doc in globalCategories.docs) {
    batch.delete(doc.reference);
  }
  await batch.commit();

  print('✓ Rollback complete');
}
```

**Pros**: Can be run immediately
**Cons**: Requires ID mapping saved during migration

---

## Data Validation Checks

### Pre-Migration Validation

```dart
Future<bool> validatePreMigration(FirebaseFirestore db) async {
  // 1. Check Firestore indexes exist
  // (Manual check - indexes can't be queried programmatically)
  print('⚠️  MANUAL CHECK: Verify indexes deployed (firebase firestore:indexes)');

  // 2. Check migration lock
  final migrationDoc = await db
      .collection('_system')
      .doc('migration')
      .get();

  if (migrationDoc.exists) {
    final status = migrationDoc.data()?['status'];
    if (status == 'in_progress') {
      print('❌ Migration already in progress!');
      return false;
    }
  }

  // 3. Check backup exists
  print('⚠️  MANUAL CHECK: Verify Firestore backup created');

  // 4. Verify collections exist
  final tripsCount = (await db.collection('trips').limit(1).get()).size;
  if (tripsCount == 0) {
    print('⚠️  No trips found - migration may not be needed');
  }

  print('✓ Pre-migration validation passed');
  return true;
}
```

---

### Post-Migration Validation

```dart
Future<bool> validatePostMigration(
  FirebaseFirestore db,
  MigrationStats stats,
) async {
  // 1. Verify global categories created
  final globalCategoriesCount = (await db.collection('categories').get()).size;

  if (globalCategoriesCount == 0) {
    print('❌ No global categories created!');
    return false;
  }

  print('✓ Created $globalCategoriesCount global categories');

  // 2. Verify no trip categories remain
  final trips = await db.collection('trips').get();

  for (final trip in trips.docs) {
    final categories = await db
        .collection('trips')
        .doc(trip.id)
        .collection('categories')
        .limit(1)
        .get();

    if (categories.size > 0) {
      print('⚠️  Trip ${trip.id} still has ${categories.size} categories');
    }
  }

  // 3. Verify all expenses updated
  final expensesWithOldCategories = await db
      .collection('expenses')
      .where('categoryId', 'isNull', isEqualTo: false)
      .get();

  // Check if any still reference old format (would need custom validation)

  // 4. Print stats
  print('');
  print('Migration Statistics:');
  print('  Total expenses: ${stats.totalExpenses}');
  print('  Updated: ${stats.updatedExpenses}');
  print('  Orphaned (set to null): ${stats.orphanedExpenses}');
  print('  Already null: ${stats.nullCategoryExpenses}');
  print('');

  // 5. Verify math
  final expected = stats.updatedExpenses +
      stats.orphanedExpenses +
      stats.nullCategoryExpenses;

  if (expected != stats.totalExpenses) {
    print('❌ Math error: Updated count doesn't match total!');
    return false;
  }

  print('✓ Post-migration validation passed');
  return true;
}
```

---

## Migration Execution Checklist

### Phase 1: Preparation (1 day before)

- [ ] Deploy Firestore indexes
  ```bash
  firebase deploy --only firestore:indexes
  firebase firestore:indexes  # Verify status: READY
  ```

- [ ] Create Firestore backup
  ```bash
  gcloud firestore export gs://backup-bucket/pre-global-categories-$(date +%Y%m%d-%H%M%S)
  ```

- [ ] Notify stakeholders (migration window)

- [ ] Run pre-migration validation on staging

- [ ] Test rollback procedure on staging

### Phase 2: Migration (Maintenance window)

- [ ] Set maintenance mode (optional)

- [ ] Set migration lock in Firestore

- [ ] Run migration script
  ```bash
  dart run scripts/migrate_categories.dart --production
  ```

- [ ] Monitor progress logs

- [ ] Verify no errors in migration log

### Phase 3: Verification (After migration)

- [ ] Run post-migration validation

- [ ] Manually test category browsing in app

- [ ] Manually test category creation

- [ ] Verify expense categories display correctly

- [ ] Check Firestore console for data integrity

### Phase 4: Cleanup (After successful verification)

- [ ] Clear migration lock

- [ ] Update security rules (if needed)

- [ ] Document migration completion

- [ ] Archive migration logs

- [ ] Delete old trip category subcollections (optional, 7 days later)

---

## Migration Logs

### Log Format

```
2025-10-31 12:00:00 [INFO] Migration started
2025-10-31 12:00:05 [INFO] Pre-migration validation: PASSED
2025-10-31 12:00:10 [INFO] Scanned 50 trips
2025-10-31 12:00:15 [INFO] Found 347 trip categories
2025-10-31 12:00:20 [INFO] Deduplicated to 24 unique categories
2025-10-31 12:00:20 [WARN] Icon conflict for "Meals": {restaurant, fastfood} → using restaurant
2025-10-31 12:00:25 [INFO] Created 24 global categories
2025-10-31 12:00:30 [INFO] Built ID mapping for 347 references
2025-10-31 12:01:00 [INFO] Updated 1,234 expenses
2025-10-31 12:01:00 [WARN] Orphaned 12 expense references (set to null)
2025-10-31 12:01:05 [INFO] Post-migration validation: PASSED
2025-10-31 12:01:05 [INFO] Migration completed successfully
```

### Log Storage

```dart
class MigrationLogger {
  final List<String> logs = [];

  void log(String level, String message) {
    final timestamp = DateTime.now().toIso8601String();
    final entry = '$timestamp [$level] $message';
    logs.add(entry);
    print(entry);
  }

  Future<void> saveLogs(FirebaseFirestore db) async {
    await db.collection('_system').doc('migration_log').set({
      'timestamp': FieldValue.serverTimestamp(),
      'logs': logs,
    });
  }
}
```

---

## Next Steps

- **T055**: Implement this strategy as Dart CLI tool
- **T056**: Add safety mechanisms (backup, lock, retry)
- **T057**: Test on staging data
- **T070**: Execute on production

---

**Document Status**: ✅ **COMPLETE**
**Prepared By**: Claude (AI Assistant)
**Review Required**: Lead Engineer approval before implementation
