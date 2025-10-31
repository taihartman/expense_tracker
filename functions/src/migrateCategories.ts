/**
 * Firebase Cloud Function: Migrate Trip-Specific Categories to Global
 *
 * Feature ID: 008-global-category-system
 * Task: T055 - Migration script implementation (Cloud Functions version)
 *
 * Usage:
 *   POST https://[region]-[project-id].cloudfunctions.net/migrateCategories
 *   Body: { "dryRun": true/false, "action": "migrate"/"rollback" }
 *
 * See: specs/008-global-category-system/MIGRATION_STRATEGY.md
 */

import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

// ============================================================================
// Types
// ============================================================================

interface TripCategorySnapshot {
  tripId: string;
  categoryId: string;
  name: string;
  icon: string;
  color: string;
  usageCount: number;
}

interface GlobalCategoryDefinition {
  name: string;
  nameLowercase: string;
  icon: string;
  color: string;
  totalUsageCount: number;
  sourceIds: string[];
}

interface MigrationStats {
  totalExpenses: number;
  updatedExpenses: number;
  orphanedExpenses: number;
  nullCategoryExpenses: number;
}

interface MigrationLog {
  timestamp: string;
  level: 'INFO' | 'WARN' | 'ERROR';
  message: string;
}

// ============================================================================
// Logger
// ============================================================================

class MigrationLogger {
  logs: MigrationLog[] = [];

  info(message: string) {
    this.log('INFO', message);
  }

  warn(message: string) {
    this.log('WARN', message);
  }

  error(message: string) {
    this.log('ERROR', message);
  }

  private log(level: 'INFO' | 'WARN' | 'ERROR', message: string) {
    const entry: MigrationLog = {
      timestamp: new Date().toISOString(),
      level,
      message,
    };
    this.logs.push(entry);
    console.log(`[${entry.timestamp}] [${level}] ${message}`);
  }

  async saveLogs(db: admin.firestore.Firestore) {
    try {
      await db.collection('_system').doc('migration_log').set({
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        logs: this.logs,
        totalEntries: this.logs.length,
      });
      this.info('Logs saved to Firestore: _system/migration_log');
    } catch (e) {
      this.error(`Failed to save logs: ${e}`);
    }
  }
}

// ============================================================================
// Algorithm 1: Scan Trip Categories
// ============================================================================

async function scanTripCategories(
  db: admin.firestore.Firestore,
  logger: MigrationLogger
): Promise<TripCategorySnapshot[]> {
  logger.info('Scanning trip-specific categories...');
  const snapshots: TripCategorySnapshot[] = [];

  const tripsSnapshot = await db.collection('trips').get();
  logger.info(`Found ${tripsSnapshot.size} trips to scan`);

  for (const tripDoc of tripsSnapshot.docs) {
    const tripId = tripDoc.id;

    try {
      const categoriesSnapshot = await db
        .collection('trips')
        .doc(tripId)
        .collection('categories')
        .get();

      if (categoriesSnapshot.size > 0) {
        logger.info(`Trip ${tripId}: ${categoriesSnapshot.size} categories`);
      }

      for (const catDoc of categoriesSnapshot.docs) {
        const data = catDoc.data();
        snapshots.push({
          tripId,
          categoryId: catDoc.id,
          name: data.name as string,
          icon: (data.icon as string) || 'category',
          color: (data.color as string) || '#9E9E9E',
          usageCount: (data.usageCount as number) || 0,
        });
      }
    } catch (e) {
      logger.error(`Failed to scan categories for trip ${tripId}: ${e}`);
      throw e;
    }
  }

  logger.info(`Total categories scanned: ${snapshots.length}`);
  return snapshots;
}

// ============================================================================
// Algorithm 2: Deduplicate Categories
// ============================================================================

function majorityVote(values: string[], defaultValue: string): string {
  if (values.length === 0) return defaultValue;

  const counts = new Map<string, number>();
  for (const value of values) {
    counts.set(value, (counts.get(value) || 0) + 1);
  }

  let winner = defaultValue;
  let maxCount = 0;

  for (const [value, count] of counts.entries()) {
    if (count > maxCount) {
      maxCount = count;
      winner = value;
    }
  }

  return winner;
}

function deduplicateCategories(
  snapshots: TripCategorySnapshot[],
  logger: MigrationLogger
): GlobalCategoryDefinition[] {
  logger.info('Deduplicating categories...');

  const groups = new Map<string, TripCategorySnapshot[]>();

  for (const snapshot of snapshots) {
    const nameLower = snapshot.name.trim().toLowerCase();
    if (!groups.has(nameLower)) {
      groups.set(nameLower, []);
    }
    groups.get(nameLower)!.push(snapshot);
  }

  logger.info(`Found ${groups.size} unique category names`);

  const definitions: GlobalCategoryDefinition[] = [];

  for (const [nameLower, instances] of groups.entries()) {
    const name = instances[0].name.trim();
    const icon = majorityVote(
      instances.map((i) => i.icon),
      'category'
    );
    const color = majorityVote(
      instances.map((i) => i.color),
      '#9E9E9E'
    );
    const totalUsageCount = instances.reduce((sum, i) => sum + i.usageCount, 0);
    const sourceIds = instances.map((i) => `${i.tripId}-${i.categoryId}`);

    definitions.push({
      name,
      nameLowercase: nameLower,
      icon,
      color,
      totalUsageCount,
      sourceIds,
    });

    if (instances.length > 1) {
      const uniqueIcons = new Set(instances.map((i) => i.icon));
      const uniqueColors = new Set(instances.map((i) => i.color));

      if (uniqueIcons.size > 1) {
        logger.warn(
          `Icon conflict for "${name}": ${Array.from(uniqueIcons).join(', ')} → using ${icon}`
        );
      }
      if (uniqueColors.size > 1) {
        logger.warn(
          `Color conflict for "${name}": ${Array.from(uniqueColors).join(', ')} → using ${color}`
        );
      }
    }
  }

  logger.info(`Deduplicated to ${definitions.length} global categories`);
  return definitions;
}

// ============================================================================
// Algorithm 3: Create Global Categories
// ============================================================================

function splitIntoBatches<T>(items: T[], batchSize: number): T[][] {
  const batches: T[][] = [];
  for (let i = 0; i < items.length; i += batchSize) {
    batches.push(items.slice(i, i + batchSize));
  }
  return batches;
}

async function createGlobalCategories(
  db: admin.firestore.Firestore,
  definitions: GlobalCategoryDefinition[],
  logger: MigrationLogger,
  dryRun: boolean
): Promise<Map<string, string>> {
  logger.info('Creating global categories...');
  const mapping = new Map<string, string>();

  if (dryRun) {
    logger.info(`[DRY RUN] Would create ${definitions.length} categories`);
    for (const def of definitions) {
      const mockId = `mock-${def.nameLowercase.replace(/\s/g, '-')}`;
      mapping.set(def.nameLowercase, mockId);
      logger.info(`  [DRY RUN] "${def.name}" → ${mockId}`);
    }
    return mapping;
  }

  const batches = splitIntoBatches(definitions, 500);

  for (let i = 0; i < batches.length; i++) {
    const batch = db.batch();
    const batchDefs = batches[i];

    logger.info(
      `Creating batch ${i + 1}/${batches.length} (${batchDefs.length} categories)`
    );

    for (const def of batchDefs) {
      const categoryRef = db.collection('categories').doc();

      batch.set(categoryRef, {
        name: def.name,
        nameLowercase: def.nameLowercase,
        icon: def.icon,
        color: def.color,
        usageCount: def.totalUsageCount,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      mapping.set(def.nameLowercase, categoryRef.id);
      logger.info(`  ✓ "${def.name}" → ${categoryRef.id}`);
    }

    await batch.commit();
    logger.info(`  Batch ${i + 1} committed`);
  }

  logger.info(`Created ${definitions.length} global categories`);
  return mapping;
}

// ============================================================================
// Algorithm 4: Build ID Mapping
// ============================================================================

function buildIdMapping(
  snapshots: TripCategorySnapshot[],
  globalCategoryIds: Map<string, string>,
  logger: MigrationLogger
): Map<string, string> {
  logger.info('Building ID mapping...');
  const mapping = new Map<string, string>();

  for (const snapshot of snapshots) {
    const oldId = snapshot.categoryId;
    const nameLower = snapshot.name.trim().toLowerCase();

    const globalId = globalCategoryIds.get(nameLower);

    if (!globalId) {
      logger.warn(
        `No global category found for "${nameLower}" (old ID: ${oldId})`
      );
      continue;
    }

    mapping.set(oldId, globalId);
  }

  logger.info(`Built mapping for ${mapping.size} category IDs`);
  return mapping;
}

// ============================================================================
// Algorithm 5: Update Expense References
// ============================================================================

async function updateExpenseReferences(
  db: admin.firestore.Firestore,
  idMapping: Map<string, string>,
  logger: MigrationLogger,
  dryRun: boolean
): Promise<MigrationStats> {
  logger.info('Updating expense references...');
  const stats: MigrationStats = {
    totalExpenses: 0,
    updatedExpenses: 0,
    orphanedExpenses: 0,
    nullCategoryExpenses: 0,
  };

  const expensesSnapshot = await db
    .collection('expenses')
    .orderBy(admin.firestore.FieldPath.documentId())
    .get();

  stats.totalExpenses = expensesSnapshot.size;
  logger.info(`Found ${stats.totalExpenses} total expenses`);

  const expensesByCategory = new Map<string | null, string[]>();

  for (const expenseDoc of expensesSnapshot.docs) {
    const categoryId = expenseDoc.data().categoryId as string | null;
    if (!expensesByCategory.has(categoryId)) {
      expensesByCategory.set(categoryId, []);
    }
    expensesByCategory.get(categoryId)!.push(expenseDoc.id);
  }

  logger.info(`Grouped into ${expensesByCategory.size} category buckets`);

  for (const [oldCategoryId, expenseIds] of expensesByCategory.entries()) {
    if (oldCategoryId === null) {
      stats.nullCategoryExpenses += expenseIds.length;
      continue;
    }

    const newCategoryId = idMapping.get(oldCategoryId);

    if (!newCategoryId) {
      logger.warn(
        `Orphaned category reference: ${oldCategoryId} (${expenseIds.length} expenses)`
      );
      stats.orphanedExpenses += expenseIds.length;

      if (!dryRun) {
        await updateExpensesBatch(db, expenseIds, null);
      } else {
        logger.info(
          `  [DRY RUN] Would set ${expenseIds.length} expenses to null`
        );
      }
      continue;
    }

    if (!dryRun) {
      await updateExpensesBatch(db, expenseIds, newCategoryId);
    } else {
      logger.info(
        `  [DRY RUN] Would update ${expenseIds.length} expenses: ${oldCategoryId} → ${newCategoryId}`
      );
    }

    stats.updatedExpenses += expenseIds.length;
    logger.info(
      `  ✓ Updated ${expenseIds.length} expenses: ${oldCategoryId} → ${newCategoryId}`
    );
  }

  return stats;
}

async function updateExpensesBatch(
  db: admin.firestore.Firestore,
  expenseIds: string[],
  newCategoryId: string | null
): Promise<void> {
  const batches = splitIntoBatches(expenseIds, 500);

  for (const batchIds of batches) {
    const batch = db.batch();

    for (const expenseId of batchIds) {
      const expenseRef = db.collection('expenses').doc(expenseId);
      batch.update(expenseRef, { categoryId: newCategoryId });
    }

    await batch.commit();
  }
}

// ============================================================================
// Rollback Functions
// ============================================================================

async function saveIdMappingForRollback(
  db: admin.firestore.Firestore,
  idMapping: Map<string, string>,
  logger: MigrationLogger
): Promise<void> {
  logger.info('Saving ID mapping for rollback...');

  try {
    const mappingObj: Record<string, string> = {};
    for (const [key, value] of idMapping.entries()) {
      mappingObj[key] = value;
    }

    await db.collection('_system').doc('migration_id_mapping').set({
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      mapping: mappingObj,
      totalMappings: idMapping.size,
    });
    logger.info(`ID mapping saved (${idMapping.size} entries)`);
  } catch (e) {
    logger.error(`Failed to save ID mapping: ${e}`);
    throw e;
  }
}

async function rollbackMigration(
  db: admin.firestore.Firestore,
  logger: MigrationLogger
): Promise<void> {
  logger.info('='.repeat(60));
  logger.info('Starting migration rollback...');
  logger.info('='.repeat(60));

  try {
    // 1. Load ID mapping
    const mappingDoc = await db
      .collection('_system')
      .doc('migration_id_mapping')
      .get();

    if (!mappingDoc.exists) {
      throw new Error(
        'No ID mapping found! Cannot rollback without mapping. Restore from Firestore backup instead.'
      );
    }

    const rawMapping = mappingDoc.data()!.mapping as Record<string, string>;
    const idMapping = new Map(Object.entries(rawMapping));

    logger.info(`Loaded ${idMapping.size} ID mappings`);

    // 2. Reverse mapping
    const reverseMapping = new Map<string, string>();
    for (const [oldId, newId] of idMapping.entries()) {
      reverseMapping.set(newId, oldId);
    }

    logger.info('Created reverse mapping');

    // 3. Restore expense references
    logger.info('Restoring expense category references...');

    const expensesSnapshot = await db
      .collection('expenses')
      .orderBy(admin.firestore.FieldPath.documentId())
      .get();

    logger.info(`Found ${expensesSnapshot.size} expenses to check`);

    const expensesByNewCategory = new Map<string | null, string[]>();

    for (const expenseDoc of expensesSnapshot.docs) {
      const categoryId = expenseDoc.data().categoryId as string | null;
      if (!expensesByNewCategory.has(categoryId)) {
        expensesByNewCategory.set(categoryId, []);
      }
      expensesByNewCategory.get(categoryId)!.push(expenseDoc.id);
    }

    let restoredCount = 0;

    for (const [newCategoryId, expenseIds] of expensesByNewCategory.entries()) {
      if (newCategoryId === null) continue;

      const oldCategoryId = reverseMapping.get(newCategoryId);

      if (oldCategoryId) {
        await updateExpensesBatch(db, expenseIds, oldCategoryId);
        restoredCount += expenseIds.length;
        logger.info(
          `  ✓ Restored ${expenseIds.length} expenses: ${newCategoryId} → ${oldCategoryId}`
        );
      }
    }

    logger.info(`Restored ${restoredCount} expense references`);

    // 4. Delete global categories
    logger.info('Deleting global categories...');
    const globalCategoriesSnapshot = await db.collection('categories').get();

    const batches = splitIntoBatches(
      globalCategoriesSnapshot.docs,
      500
    );

    for (let i = 0; i < batches.length; i++) {
      const batch = db.batch();
      const batchDocs = batches[i];

      for (const doc of batchDocs) {
        batch.delete(doc.ref);
      }

      await batch.commit();

      logger.info(
        `  Deleted batch ${i + 1}/${batches.length} (${batchDocs.length} categories)`
      );
    }

    logger.info(`Deleted ${globalCategoriesSnapshot.size} global categories`);

    // 5. Update migration status
    await db.collection('_system').doc('migration').set({
      status: 'rolled_back',
      rolledBackAt: admin.firestore.FieldValue.serverTimestamp(),
      restoredExpenses: restoredCount,
    });

    logger.info('='.repeat(60));
    logger.info('Rollback completed successfully!');
    logger.info(`Restored ${restoredCount} expense references`);
    logger.info(`Deleted ${globalCategoriesSnapshot.size} global categories`);
    logger.info('='.repeat(60));

    await logger.saveLogs(db);
  } catch (e) {
    logger.error(`Rollback failed: ${e}`);
    await logger.saveLogs(db);
    throw e;
  }
}

// ============================================================================
// Main Migration Orchestrator
// ============================================================================

async function migrateCategories(
  db: admin.firestore.Firestore,
  logger: MigrationLogger,
  dryRun: boolean
): Promise<{ stats: MigrationStats; logs: MigrationLog[] }> {
  logger.info('='.repeat(60));
  logger.info('Starting category migration...');
  if (dryRun) {
    logger.info('[DRY RUN MODE] No changes will be written to Firestore');
  }
  logger.info('='.repeat(60));

  try {
    // 1. Set migration lock
    if (!dryRun) {
      await db.collection('_system').doc('migration').set({
        status: 'in_progress',
        startedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      logger.info('Migration lock set');
    }

    // 2. Scan trip categories
    const snapshots = await scanTripCategories(db, logger);

    if (snapshots.length === 0) {
      logger.info('No trip-specific categories found. Migration not needed.');
      if (!dryRun) {
        await db.collection('_system').doc('migration').set({
          status: 'completed',
          completedAt: admin.firestore.FieldValue.serverTimestamp(),
          reason: 'No categories to migrate',
        });
      }
      return { stats: {
        totalExpenses: 0,
        updatedExpenses: 0,
        orphanedExpenses: 0,
        nullCategoryExpenses: 0,
      }, logs: logger.logs };
    }

    // 3. Deduplicate
    const definitions = deduplicateCategories(snapshots, logger);

    // 4. Create global categories
    const globalCategoryIds = await createGlobalCategories(
      db,
      definitions,
      logger,
      dryRun
    );

    // 5. Build ID mapping
    const idMapping = buildIdMapping(snapshots, globalCategoryIds, logger);

    // 6. Save ID mapping
    if (!dryRun) {
      await saveIdMappingForRollback(db, idMapping, logger);
    }

    // 7. Update expenses
    const stats = await updateExpenseReferences(db, idMapping, logger, dryRun);

    // 8. Clear migration lock
    if (!dryRun) {
      await db.collection('_system').doc('migration').set({
        status: 'completed',
        completedAt: admin.firestore.FieldValue.serverTimestamp(),
        stats,
      });
      logger.info('Migration lock cleared');
    }

    // 9. Save logs
    if (!dryRun) {
      await logger.saveLogs(db);
    }

    logger.info('='.repeat(60));
    logger.info('Migration completed successfully!');
    logger.info('='.repeat(60));

    return { stats, logs: logger.logs };
  } catch (e) {
    logger.error(`Migration failed: ${e}`);

    if (!dryRun) {
      try {
        await db.collection('_system').doc('migration').set({
          status: 'failed',
          error: String(e),
          completedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        await logger.saveLogs(db);
      } catch (logError) {
        logger.error(`Failed to save error logs: ${logError}`);
      }
    }

    throw e;
  }
}

// ============================================================================
// Cloud Function HTTP Handler
// ============================================================================

export const migrateCategoriesFunction = functions.https.onRequest(
  async (req, res) => {
    // CORS headers
    res.set('Access-Control-Allow-Origin', '*');

    if (req.method === 'OPTIONS') {
      res.set('Access-Control-Allow-Methods', 'POST');
      res.set('Access-Control-Allow-Headers', 'Content-Type');
      res.status(204).send('');
      return;
    }

    if (req.method !== 'POST') {
      res.status(405).send('Method Not Allowed');
      return;
    }

    const dryRun = req.body.dryRun === true;
    const action = req.body.action || 'migrate';

    const db = admin.firestore();
    const logger = new MigrationLogger();

    try {
      if (action === 'rollback') {
        await rollbackMigration(db, logger);
        res.status(200).json({
          success: true,
          action: 'rollback',
          logs: logger.logs,
        });
      } else {
        const result = await migrateCategories(db, logger, dryRun);
        res.status(200).json({
          success: true,
          action: 'migrate',
          dryRun,
          stats: result.stats,
          logs: result.logs,
        });
      }
    } catch (error) {
      logger.error(`Function failed: ${error}`);
      res.status(500).json({
        success: false,
        error: String(error),
        logs: logger.logs,
      });
    }
  }
);
