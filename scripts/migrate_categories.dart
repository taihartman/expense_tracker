#!/usr/bin/env dart

/// Migration Script: Trip-Specific to Global Categories
///
/// Feature ID: 008-global-category-system
/// Task: T055 - Write migration script logic
///
/// Usage:
///   dart run scripts/migrate_categories.dart [--production] [--dry-run] [--rollback]
///
/// Flags:
///   --production: Run on production Firestore (default: uses emulator)
///   --dry-run: Simulate migration without writing to Firestore
///   --rollback: Rollback the migration (restore expense refs, delete global categories)
///
/// Prerequisites:
///   1. Firebase indexes deployed
///   2. Firestore backup created
///   3. Migration lock cleared in Firestore
///
/// See: specs/008-global-category-system/MIGRATION_STRATEGY.md
library;

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

// ============================================================================
// Data Classes
// ============================================================================

/// Snapshot of a trip-specific category
class TripCategorySnapshot {
  final String tripId;
  final String categoryId;
  final String name;
  final String icon;
  final String color;
  final int usageCount;

  TripCategorySnapshot({
    required this.tripId,
    required this.categoryId,
    required this.name,
    required this.icon,
    required this.color,
    required this.usageCount,
  });
}

/// Definition for a global category (after deduplication)
class GlobalCategoryDefinition {
  final String name;
  final String nameLowercase;
  final String icon; // Resolved via majority vote
  final String color; // Resolved via majority vote
  final int totalUsageCount; // Sum of all instances
  final List<String> sourceIds; // Original trip category IDs

  GlobalCategoryDefinition({
    required this.name,
    required this.nameLowercase,
    required this.icon,
    required this.color,
    required this.totalUsageCount,
    required this.sourceIds,
  });
}

/// Migration statistics
class MigrationStats {
  int totalExpenses = 0;
  int updatedExpenses = 0;
  int orphanedExpenses = 0;
  int nullCategoryExpenses = 0;

  @override
  String toString() {
    return '''
Migration Statistics:
  Total expenses: $totalExpenses
  Updated: $updatedExpenses
  Orphaned (set to null): $orphanedExpenses
  Already null: $nullCategoryExpenses
''';
  }
}

/// Migration logger with Firestore persistence
class MigrationLogger {
  final List<String> logs = [];

  void info(String message) => log('INFO', message);
  void warn(String message) => log('WARN', message);
  void error(String message) => log('ERROR', message);

  void log(String level, String message) {
    final timestamp = DateTime.now().toIso8601String();
    final entry = '$timestamp [$level] $message';
    logs.add(entry);
    print(entry);
  }

  Future<void> saveLogs(FirebaseFirestore db) async {
    try {
      await db.collection('_system').doc('migration_log').set({
        'timestamp': FieldValue.serverTimestamp(),
        'logs': logs,
        'totalEntries': logs.length,
      });
      info('Logs saved to Firestore: _system/migration_log');
    } catch (e) {
      error('Failed to save logs to Firestore: $e');
    }
  }
}

// ============================================================================
// Algorithm 1: Scan Trip Categories
// ============================================================================

Future<List<TripCategorySnapshot>> scanTripCategories(
  FirebaseFirestore db,
  MigrationLogger logger,
) async {
  logger.info('Scanning trip-specific categories...');
  final snapshots = <TripCategorySnapshot>[];

  // 1. Get all trips
  final tripsQuery = await db.collection('trips').get();
  logger.info('Found ${tripsQuery.size} trips to scan');

  // 2. For each trip, get its categories subcollection
  for (final tripDoc in tripsQuery.docs) {
    final tripId = tripDoc.id;

    try {
      final categoriesQuery = await db
          .collection('trips')
          .doc(tripId)
          .collection('categories')
          .get();

      if (categoriesQuery.size > 0) {
        logger.info('Trip $tripId: ${categoriesQuery.size} categories');
      }

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
    } catch (e) {
      logger.error('Failed to scan categories for trip $tripId: $e');
      rethrow;
    }
  }

  logger.info('Total categories scanned: ${snapshots.length}');
  return snapshots;
}

// ============================================================================
// Algorithm 2: Deduplicate Categories
// ============================================================================

List<GlobalCategoryDefinition> deduplicateCategories(
  List<TripCategorySnapshot> snapshots,
  MigrationLogger logger,
) {
  logger.info('Deduplicating categories...');

  // 1. Group by name (case-insensitive)
  final groups = <String, List<TripCategorySnapshot>>{};

  for (final snapshot in snapshots) {
    final nameLower = snapshot.name.trim().toLowerCase();
    groups.putIfAbsent(nameLower, () => []).add(snapshot);
  }

  logger.info('Found ${groups.length} unique category names');

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
      (accumulator, i) => accumulator + i.usageCount,
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
        logger.warn(
          'Icon conflict for "$name": $uniqueIcons → using $icon',
        );
      }
      if (uniqueColors.length > 1) {
        logger.warn(
          'Color conflict for "$name": $uniqueColors → using $color',
        );
      }
    }
  }

  logger.info('Deduplicated to ${definitions.length} global categories');
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

// ============================================================================
// Algorithm 3: Create Global Categories
// ============================================================================

Future<Map<String, String>> createGlobalCategories(
  FirebaseFirestore db,
  List<GlobalCategoryDefinition> definitions,
  MigrationLogger logger,
  bool dryRun,
) async {
  logger.info('Creating global categories...');
  final mapping = <String, String>{};

  if (dryRun) {
    logger.info('[DRY RUN] Would create ${definitions.length} categories');
    // Generate mock IDs for dry run
    for (final def in definitions) {
      mapping[def.nameLowercase] = 'mock-${def.nameLowercase.hashCode}';
      logger.info('  [DRY RUN] "${def.name}" → ${mapping[def.nameLowercase]}');
    }
    return mapping;
  }

  // Process in batches of 500 (Firestore limit)
  final batches = _splitIntoBatches(definitions, 500);

  for (int i = 0; i < batches.length; i++) {
    final batch = db.batch();
    final batchDefinitions = batches[i];

    logger.info(
      'Creating batch ${i + 1}/${batches.length} (${batchDefinitions.length} categories)',
    );

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

      logger.info('  ✓ "${def.name}" → ${categoryRef.id}');
    }

    // Commit batch with retry logic
    await _retryWithBackoff(
      () => batch.commit(),
      logger: logger,
    );
    logger.info('  Batch ${i + 1} committed');
  }

  logger.info('Created ${definitions.length} global categories');
  return mapping;
}

// ============================================================================
// Algorithm 4: Build ID Mapping
// ============================================================================

Map<String, String> buildIdMapping(
  List<TripCategorySnapshot> snapshots,
  Map<String, String> globalCategoryIds,
  MigrationLogger logger,
) {
  logger.info('Building ID mapping...');
  final mapping = <String, String>{};

  for (final snapshot in snapshots) {
    final oldId = snapshot.categoryId; // Just the category ID
    final nameLower = snapshot.name.trim().toLowerCase();

    // Lookup global category ID
    final globalId = globalCategoryIds[nameLower];

    if (globalId == null) {
      logger.warn(
        'No global category found for "$nameLower" (old ID: $oldId)',
      );
      continue; // Skip - will be handled as orphaned reference
    }

    mapping[oldId] = globalId;
  }

  logger.info('Built mapping for ${mapping.length} category IDs');
  return mapping;
}

// ============================================================================
// Algorithm 5: Update Expense References
// ============================================================================

Future<MigrationStats> updateExpenseReferences(
  FirebaseFirestore db,
  Map<String, String> idMapping,
  MigrationLogger logger,
  bool dryRun,
) async {
  logger.info('Updating expense references...');
  final stats = MigrationStats();

  // 1. Get all expenses
  final expensesQuery = await db
      .collection('expenses')
      .orderBy(FieldPath.documentId)
      .get();

  stats.totalExpenses = expensesQuery.size;
  logger.info('Found ${stats.totalExpenses} total expenses');

  // 2. Group by categoryId for efficient processing
  final expensesByCategory = <String?, List<String>>{};

  for (final expenseDoc in expensesQuery.docs) {
    final categoryId = expenseDoc.data()['categoryId'] as String?;
    expensesByCategory
        .putIfAbsent(categoryId, () => [])
        .add(expenseDoc.id);
  }

  logger.info('Grouped into ${expensesByCategory.length} category buckets');

  if (dryRun) {
    logger.info('[DRY RUN] Would update expenses as follows:');
  }

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
    final newCategoryId = idMapping[oldCategoryId];

    if (newCategoryId == null) {
      // This expense has orphaned reference
      logger.warn(
        'Orphaned category reference: $oldCategoryId (${expenseIds.length} expenses)',
      );
      stats.orphanedExpenses += expenseIds.length;

      if (!dryRun) {
        // Set to null
        await _updateExpensesBatch(
          db,
          expenseIds,
          newCategoryId: null,
          logger: logger,
        );
      } else {
        logger.info('  [DRY RUN] Would set ${expenseIds.length} expenses to null');
      }

      continue;
    }

    // Update expenses with new category ID
    if (!dryRun) {
      await _updateExpensesBatch(
        db,
        expenseIds,
        newCategoryId: newCategoryId,
        logger: logger,
      );
    } else {
      logger.info(
        '  [DRY RUN] Would update ${expenseIds.length} expenses: $oldCategoryId → $newCategoryId',
      );
    }

    stats.updatedExpenses += expenseIds.length;
    logger.info(
      '  ✓ ${dryRun ? '[DRY RUN] ' : ''}Updated ${expenseIds.length} expenses: $oldCategoryId → $newCategoryId',
    );
  }

  return stats;
}

Future<void> _updateExpensesBatch(
  FirebaseFirestore db,
  List<String> expenseIds, {
  required String? newCategoryId,
  MigrationLogger? logger,
}) async {
  // Process in batches of 500
  final batches = _splitIntoBatches(expenseIds, 500);

  for (final batchIds in batches) {
    final batch = db.batch();

    for (final expenseId in batchIds) {
      final expenseRef = db.collection('expenses').doc(expenseId);
      batch.update(expenseRef, {'categoryId': newCategoryId});
    }

    // Commit with retry logic
    await _retryWithBackoff(
      () => batch.commit(),
      logger: logger,
    );
  }
}

// ============================================================================
// Helper Functions
// ============================================================================

List<List<T>> _splitIntoBatches<T>(List<T> items, int batchSize) {
  final batches = <List<T>>[];
  for (int i = 0; i < items.length; i += batchSize) {
    final end = (i + batchSize < items.length) ? i + batchSize : items.length;
    batches.add(items.sublist(i, end));
  }
  return batches;
}

/// Retry a function with exponential backoff
Future<T> _retryWithBackoff<T>(
  Future<T> Function() fn, {
  int maxAttempts = 3,
  Duration initialDelay = const Duration(seconds: 1),
  MigrationLogger? logger,
}) async {
  int attempt = 0;
  Duration delay = initialDelay;

  while (true) {
    attempt++;
    try {
      return await fn();
    } catch (e) {
      if (attempt >= maxAttempts) {
        logger?.error('Max retry attempts ($maxAttempts) exceeded');
        rethrow;
      }

      logger?.warn('Attempt $attempt failed: $e. Retrying in ${delay.inSeconds}s...');
      await Future.delayed(delay);
      delay *= 2; // Exponential backoff
    }
  }
}

// ============================================================================
// Rollback Functions
// ============================================================================

/// Save ID mapping to Firestore for potential rollback
Future<void> saveIdMappingForRollback(
  FirebaseFirestore db,
  Map<String, String> idMapping,
  MigrationLogger logger,
) async {
  logger.info('Saving ID mapping for rollback...');

  try {
    await db.collection('_system').doc('migration_id_mapping').set({
      'timestamp': FieldValue.serverTimestamp(),
      'mapping': idMapping,
      'totalMappings': idMapping.length,
    });
    logger.info('ID mapping saved (${idMapping.length} entries)');
  } catch (e) {
    logger.error('Failed to save ID mapping: $e');
    rethrow;
  }
}

/// Rollback migration by reversing all changes
Future<void> rollbackMigration(
  FirebaseFirestore db,
  MigrationLogger logger,
) async {
  logger.info('=' * 60);
  logger.info('Starting migration rollback...');
  logger.info('=' * 60);

  try {
    // 1. Load ID mapping from Firestore
    logger.info('Loading ID mapping from Firestore...');
    final mappingDoc = await db
        .collection('_system')
        .doc('migration_id_mapping')
        .get();

    if (!mappingDoc.exists) {
      logger.error('No ID mapping found! Cannot rollback without mapping.');
      logger.error('You must restore from Firestore backup instead.');
      exit(1);
    }

    final data = mappingDoc.data()!;
    final Map<String, dynamic> rawMapping = data['mapping'] as Map<String, dynamic>;
    final idMapping = rawMapping.map((k, v) => MapEntry(k, v as String));

    logger.info('Loaded ${idMapping.length} ID mappings');

    // 2. Reverse the mapping (new ID → old ID)
    final reverseMapping = <String, String>{};
    for (final entry in idMapping.entries) {
      reverseMapping[entry.value] = entry.key;
    }

    logger.info('Created reverse mapping');

    // 3. Restore expense references to old category IDs
    logger.info('Restoring expense category references...');

    final expensesQuery = await db
        .collection('expenses')
        .orderBy(FieldPath.documentId)
        .get();

    logger.info('Found ${expensesQuery.size} expenses to check');

    final expensesByNewCategory = <String?, List<String>>{};

    for (final expenseDoc in expensesQuery.docs) {
      final categoryId = expenseDoc.data()['categoryId'] as String?;
      expensesByNewCategory
          .putIfAbsent(categoryId, () => [])
          .add(expenseDoc.id);
    }

    int restoredCount = 0;

    for (final entry in expensesByNewCategory.entries) {
      final newCategoryId = entry.key;
      final expenseIds = entry.value;

      if (newCategoryId == null) {
        continue; // Skip null categories
      }

      // Look up old category ID
      final oldCategoryId = reverseMapping[newCategoryId];

      if (oldCategoryId != null) {
        // Restore to old ID
        await _updateExpensesBatch(
          db,
          expenseIds,
          newCategoryId: oldCategoryId,
          logger: logger,
        );
        restoredCount += expenseIds.length;
        logger.info('  ✓ Restored ${expenseIds.length} expenses: $newCategoryId → $oldCategoryId');
      }
    }

    logger.info('Restored $restoredCount expense references');

    // 4. Delete global categories
    logger.info('Deleting global categories...');
    final globalCategories = await db.collection('categories').get();

    final batches = _splitIntoBatches(globalCategories.docs, 500);

    for (int i = 0; i < batches.length; i++) {
      final batch = db.batch();
      final batchDocs = batches[i];

      for (final doc in batchDocs) {
        batch.delete(doc.reference);
      }

      await _retryWithBackoff(
        () => batch.commit(),
        logger: logger,
      );

      logger.info('  Deleted batch ${i + 1}/${batches.length} (${batchDocs.length} categories)');
    }

    logger.info('Deleted ${globalCategories.size} global categories');

    // 5. Update migration status
    await db.collection('_system').doc('migration').set({
      'status': 'rolled_back',
      'rolledBackAt': FieldValue.serverTimestamp(),
      'restoredExpenses': restoredCount,
    });

    logger.info('=' * 60);
    logger.info('Rollback completed successfully!');
    logger.info('Restored $restoredCount expense references');
    logger.info('Deleted ${globalCategories.size} global categories');
    logger.info('=' * 60);

    // Save rollback logs
    await logger.saveLogs(db);
  } catch (e, stackTrace) {
    logger.error('Rollback failed: $e');
    logger.error('Stack trace: $stackTrace');

    try {
      await logger.saveLogs(db);
    } catch (logError) {
      logger.error('Failed to save rollback logs: $logError');
    }

    exit(1);
  }
}

// ============================================================================
// Validation Functions
// ============================================================================

Future<bool> validatePreMigration(
  FirebaseFirestore db,
  MigrationLogger logger,
) async {
  logger.info('Running pre-migration validation...');

  // 1. Check Firestore indexes exist
  logger.warn('MANUAL CHECK: Verify indexes deployed (firebase firestore:indexes)');

  // 2. Check migration lock
  final migrationDoc = await db.collection('_system').doc('migration').get();

  if (migrationDoc.exists) {
    final status = migrationDoc.data()?['status'];
    if (status == 'in_progress') {
      logger.error('Migration already in progress!');
      return false;
    }
  }

  // 3. Check backup exists
  logger.warn('MANUAL CHECK: Verify Firestore backup created');

  // 4. Verify collections exist
  final tripsCount = (await db.collection('trips').limit(1).get()).size;
  if (tripsCount == 0) {
    logger.warn('No trips found - migration may not be needed');
  }

  logger.info('Pre-migration validation passed');
  return true;
}

Future<bool> validatePostMigration(
  FirebaseFirestore db,
  MigrationStats stats,
  MigrationLogger logger,
  bool dryRun,
) async {
  logger.info('Running post-migration validation...');

  if (dryRun) {
    logger.info('[DRY RUN] Skipping post-migration validation');
    logger.info(stats.toString());
    return true;
  }

  // 1. Verify global categories created
  final globalCategoriesCount = (await db.collection('categories').get()).size;

  if (globalCategoriesCount == 0) {
    logger.error('No global categories created!');
    return false;
  }

  logger.info('✓ Created $globalCategoriesCount global categories');

  // 2. Verify no trip categories remain (warning only)
  final trips = await db.collection('trips').get();

  for (final trip in trips.docs) {
    final categories = await db
        .collection('trips')
        .doc(trip.id)
        .collection('categories')
        .limit(1)
        .get();

    if (categories.size > 0) {
      logger.warn('Trip ${trip.id} still has trip-specific categories');
    }
  }

  // 3. Print stats
  logger.info(stats.toString());

  // 4. Verify math
  final expected = stats.updatedExpenses +
      stats.orphanedExpenses +
      stats.nullCategoryExpenses;

  if (expected != stats.totalExpenses) {
    logger.error('Math error: Updated count doesn\'t match total!');
    return false;
  }

  logger.info('Post-migration validation passed');
  return true;
}

// ============================================================================
// Main Migration Orchestrator
// ============================================================================

Future<void> migrateCategories({
  required FirebaseFirestore db,
  required MigrationLogger logger,
  required bool dryRun,
}) async {
  logger.info('=' * 60);
  logger.info('Starting category migration...');
  if (dryRun) {
    logger.info('[DRY RUN MODE] No changes will be written to Firestore');
  }
  logger.info('=' * 60);

  try {
    // 1. Pre-migration validation
    final validationPassed = await validatePreMigration(db, logger);
    if (!validationPassed) {
      logger.error('Pre-migration validation failed. Aborting.');
      exit(1);
    }

    // 2. Set migration lock
    if (!dryRun) {
      await db.collection('_system').doc('migration').set({
        'status': 'in_progress',
        'startedAt': FieldValue.serverTimestamp(),
      });
      logger.info('Migration lock set');
    }

    // 3. Scan trip categories
    final snapshots = await scanTripCategories(db, logger);

    if (snapshots.isEmpty) {
      logger.info('No trip-specific categories found. Migration not needed.');
      if (!dryRun) {
        await db.collection('_system').doc('migration').set({
          'status': 'completed',
          'completedAt': FieldValue.serverTimestamp(),
          'reason': 'No categories to migrate',
        });
      }
      return;
    }

    // 4. Deduplicate categories
    final definitions = deduplicateCategories(snapshots, logger);

    // 5. Create global categories
    final globalCategoryIds = await createGlobalCategories(
      db,
      definitions,
      logger,
      dryRun,
    );

    // 6. Build ID mapping
    final idMapping = buildIdMapping(snapshots, globalCategoryIds, logger);

    // 6.5. Save ID mapping for rollback support
    if (!dryRun) {
      await saveIdMappingForRollback(db, idMapping, logger);
    }

    // 7. Update expense references
    final stats = await updateExpenseReferences(
      db,
      idMapping,
      logger,
      dryRun,
    );

    // 8. Post-migration validation
    final postValidationPassed = await validatePostMigration(
      db,
      stats,
      logger,
      dryRun,
    );

    if (!postValidationPassed) {
      logger.error('Post-migration validation failed!');
      if (!dryRun) {
        await db.collection('_system').doc('migration').set({
          'status': 'failed',
          'error': 'Post-migration validation failed',
          'completedAt': FieldValue.serverTimestamp(),
        });
      }
      exit(1);
    }

    // 9. Clear migration lock
    if (!dryRun) {
      await db.collection('_system').doc('migration').set({
        'status': 'completed',
        'completedAt': FieldValue.serverTimestamp(),
        'stats': {
          'totalExpenses': stats.totalExpenses,
          'updatedExpenses': stats.updatedExpenses,
          'orphanedExpenses': stats.orphanedExpenses,
          'nullCategoryExpenses': stats.nullCategoryExpenses,
        },
      });
      logger.info('Migration lock cleared');
    }

    // 10. Save logs to Firestore
    if (!dryRun) {
      await logger.saveLogs(db);
    }

    logger.info('=' * 60);
    logger.info('Migration completed successfully!');
    logger.info('=' * 60);
  } catch (e, stackTrace) {
    logger.error('Migration failed with error: $e');
    logger.error('Stack trace: $stackTrace');

    if (!dryRun) {
      try {
        await db.collection('_system').doc('migration').set({
          'status': 'failed',
          'error': e.toString(),
          'completedAt': FieldValue.serverTimestamp(),
        });
        await logger.saveLogs(db);
      } catch (logError) {
        logger.error('Failed to save error logs: $logError');
      }
    }

    exit(1);
  }
}

// ============================================================================
// Command-Line Entry Point
// ============================================================================

Future<void> main(List<String> args) async {
  // Parse command-line arguments
  final isProduction = args.contains('--production');
  final isDryRun = args.contains('--dry-run');
  final isRollback = args.contains('--rollback');

  print('');
  print('Category Migration Script');
  print('Feature: 008-global-category-system');
  print('');
  print('Configuration:');
  print('  Environment: ${isProduction ? 'PRODUCTION' : 'EMULATOR'}');
  print('  Mode: ${isRollback ? 'ROLLBACK' : (isDryRun ? 'DRY RUN (no writes)' : 'LIVE')}');
  print('');

  // Confirm production runs
  if (isProduction && !isDryRun) {
    if (isRollback) {
      print('⚠️  WARNING: You are about to ROLLBACK migration on PRODUCTION!');
      print('⚠️  This will restore old category references and delete global categories.');
    } else {
      print('⚠️  WARNING: You are about to run migration on PRODUCTION!');
      print('⚠️  This will modify live data.');
    }
    print('');
    stdout.write('Type "CONFIRM" to continue: ');
    final confirmation = stdin.readLineSync();

    if (confirmation != 'CONFIRM') {
      print('Operation aborted.');
      exit(0);
    }
    print('');
  }

  // Initialize Firebase
  await Firebase.initializeApp();

  final db = FirebaseFirestore.instance;

  // Configure Firestore for emulator if not production
  if (!isProduction) {
    db.settings = const Settings(
      host: 'localhost:8080',
      sslEnabled: false,
      persistenceEnabled: false,
    );
    print('Connected to Firestore Emulator (localhost:8080)');
  } else {
    print('Connected to Production Firestore');
  }

  print('');

  // Create logger
  final logger = MigrationLogger();

  // Run migration or rollback
  if (isRollback) {
    if (isDryRun) {
      print('⚠️  WARNING: --rollback ignores --dry-run flag');
      print('Rollback always performs live operations.');
      print('');
    }
    await rollbackMigration(db, logger);
  } else {
    await migrateCategories(
      db: db,
      logger: logger,
      dryRun: isDryRun,
    );
  }
}
