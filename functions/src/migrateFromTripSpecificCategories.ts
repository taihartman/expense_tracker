/**
 * Migration: Transform trip-specific categories to global categories
 *
 * This migration handles the scenario where:
 * 1. Categories exist in /categories collection but still have tripId field
 * 2. Need to deduplicate and remove tripId to make truly global
 * 3. Expenses reference category NAMES instead of IDs (broken state)
 * 4. Need to fix expense references to use actual category IDs
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

interface Logger {
  info: (message: string) => void;
  warn: (message: string) => void;
  error: (message: string) => void;
}

interface TripSpecificCategory {
  id: string;
  tripId: string;
  name: string;
  icon: string;
  color: string;
  usageCount?: number;
}

interface GlobalCategoryDefinition {
  name: string;
  nameLowercase: string;
  icon: string;
  color: string;
  usageCount: number;
  sourceIds: string[]; // Old category IDs that map to this
  sourceTripIds: string[];
}

interface MigrationStats {
  oldCategories: number;
  newGlobalCategories: number;
  expensesFixed: number;
  expensesSetNull: number;
  nameMapping: Record<string, string>; // category name -> new global ID
}

class MigrationLogger implements Logger {
  private logs: Array<{timestamp: string; level: string; message: string}> = [];

  info(message: string) {
    const log = {
      timestamp: new Date().toISOString(),
      level: "INFO",
      message,
    };
    this.logs.push(log);
    console.log(`[INFO] ${message}`);
  }

  warn(message: string) {
    const log = {
      timestamp: new Date().toISOString(),
      level: "WARN",
      message,
    };
    this.logs.push(log);
    console.warn(`[WARN] ${message}`);
  }

  error(message: string) {
    const log = {
      timestamp: new Date().toISOString(),
      level: "ERROR",
      message,
    };
    this.logs.push(log);
    console.error(`[ERROR] ${message}`);
  }

  getLogs() {
    return this.logs;
  }
}

/**
 * Step 1: Scan existing /categories collection for trip-specific categories
 */
async function scanTripSpecificCategories(
  db: admin.firestore.Firestore,
  logger: Logger
): Promise<TripSpecificCategory[]> {
  logger.info("Scanning /categories collection for trip-specific categories...");

  const categoriesSnapshot = await db.collection("categories").get();
  const tripSpecificCategories: TripSpecificCategory[] = [];

  for (const doc of categoriesSnapshot.docs) {
    const data = doc.data();

    // Check if this is a trip-specific category (has tripId field)
    if (data.tripId) {
      tripSpecificCategories.push({
        id: doc.id,
        tripId: data.tripId,
        name: data.name,
        icon: data.icon,
        color: data.color,
        usageCount: data.usageCount || 0,
      });
    }
  }

  logger.info(`Found ${tripSpecificCategories.length} trip-specific categories`);
  return tripSpecificCategories;
}

/**
 * Step 2: Deduplicate and create global category definitions
 */
function createGlobalDefinitions(
  categories: TripSpecificCategory[],
  logger: Logger
): GlobalCategoryDefinition[] {
  logger.info("Deduplicating categories by name...");

  // Group by name (case-insensitive)
  const groups = new Map<string, TripSpecificCategory[]>();

  for (const cat of categories) {
    const nameLower = cat.name.toLowerCase();
    if (!groups.has(nameLower)) {
      groups.set(nameLower, []);
    }
    groups.get(nameLower)!.push(cat);
  }

  logger.info(`Found ${groups.size} unique category names`);

  // Create global definitions with majority vote for icon/color
  const definitions: GlobalCategoryDefinition[] = [];

  for (const [nameLower, instances] of groups) {
    // Use first instance for name (preserve casing)
    const name = instances[0].name;

    // Majority vote for icon
    const iconCounts = new Map<string, number>();
    for (const inst of instances) {
      iconCounts.set(inst.icon, (iconCounts.get(inst.icon) || 0) + 1);
    }
    const icon = Array.from(iconCounts.entries()).sort((a, b) => b[1] - a[1])[0][0];

    // Majority vote for color
    const colorCounts = new Map<string, number>();
    for (const inst of instances) {
      colorCounts.set(inst.color, (colorCounts.get(inst.color) || 0) + 1);
    }
    const color = Array.from(colorCounts.entries()).sort((a, b) => b[1] - a[1])[0][0];

    // Sum usage counts
    const usageCount = instances.reduce((sum, inst) => sum + (inst.usageCount || 0), 0);

    // Log conflicts
    if (iconCounts.size > 1) {
      logger.warn(
        `Icon conflict for "${name}": ${Array.from(iconCounts.keys()).join(", ")} → ${icon} (majority)`
      );
    }
    if (colorCounts.size > 1) {
      logger.warn(
        `Color conflict for "${name}": ${Array.from(colorCounts.keys()).join(", ")} → ${color} (majority)`
      );
    }

    definitions.push({
      name,
      nameLowercase: nameLower,
      icon,
      color,
      usageCount,
      sourceIds: instances.map((i) => i.id),
      sourceTripIds: instances.map((i) => i.tripId),
    });

    logger.info(`  "${name}": ${instances.length} instances → usageCount: ${usageCount}`);
  }

  return definitions;
}

/**
 * Step 3: Delete old trip-specific categories and create new global ones
 */
async function replaceCategories(
  db: admin.firestore.Firestore,
  oldCategories: TripSpecificCategory[],
  definitions: GlobalCategoryDefinition[],
  logger: Logger,
  dryRun: boolean
): Promise<Map<string, string>> {
  logger.info("Replacing trip-specific categories with global categories...");

  const nameToIdMapping = new Map<string, string>();

  if (!dryRun) {
    // Delete old categories in batches
    logger.info(`Deleting ${oldCategories.length} old trip-specific categories...`);
    const deleteBatches = splitIntoBatches(oldCategories, 500);

    for (let i = 0; i < deleteBatches.length; i++) {
      const batch = db.batch();
      for (const cat of deleteBatches[i]) {
        batch.delete(db.collection("categories").doc(cat.id));
      }
      await retryWithBackoff(() => batch.commit());
      logger.info(`  Deleted batch ${i + 1}/${deleteBatches.length}`);
    }

    // Create new global categories in batches
    logger.info(`Creating ${definitions.length} global categories...`);
    const createBatches = splitIntoBatches(definitions, 500);

    for (let i = 0; i < createBatches.length; i++) {
      const batch = db.batch();
      for (const def of createBatches[i]) {
        const categoryRef = db.collection("categories").doc();

        batch.set(categoryRef, {
          name: def.name,
          nameLowercase: def.nameLowercase,
          icon: def.icon,
          color: def.color,
          usageCount: def.usageCount,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        // Store mapping: category name -> new global ID
        nameToIdMapping.set(def.nameLowercase, categoryRef.id);
      }
      await retryWithBackoff(() => batch.commit());
      logger.info(`  Created batch ${i + 1}/${createBatches.length}`);
    }
  } else {
    // Dry run - generate mock IDs
    logger.info("[DRY RUN] Would delete 24 old categories and create 6 global categories");
    for (const def of definitions) {
      const mockId = `mock-${def.nameLowercase}`;
      nameToIdMapping.set(def.nameLowercase, mockId);
      logger.info(`  [DRY RUN] "${def.name}" → ${mockId}`);
    }
  }

  return nameToIdMapping;
}

/**
 * Step 4: Fix expense references (NAME strings → category IDs)
 */
async function fixExpenseReferences(
  db: admin.firestore.Firestore,
  nameMapping: Map<string, string>,
  logger: Logger,
  dryRun: boolean
): Promise<{fixed: number; setNull: number}> {
  logger.info("Fixing expense category references...");

  const expensesSnapshot = await db.collection("expenses").get();
  logger.info(`Found ${expensesSnapshot.size} expenses`);

  // Group expenses by their current categoryId (which is a NAME string)
  const expensesByName = new Map<string, string[]>();
  let nullCount = 0;

  for (const doc of expensesSnapshot.docs) {
    const categoryId = doc.data().categoryId;

    if (categoryId === null || categoryId === undefined) {
      nullCount++;
      continue;
    }

    if (!expensesByName.has(categoryId)) {
      expensesByName.set(categoryId, []);
    }
    expensesByName.get(categoryId)!.push(doc.id);
  }

  logger.info(`${nullCount} expenses already have null category (no change needed)`);
  logger.info(`${expensesByName.size} unique category name references found`);

  let fixedCount = 0;
  let setNullCount = 0;

  for (const [categoryName, expenseIds] of expensesByName) {
    const nameLower = categoryName.toLowerCase();
    const newCategoryId = nameMapping.get(nameLower);

    if (!newCategoryId) {
      // No matching global category - set to null
      logger.warn(
        `No global category for "${categoryName}" - setting ${expenseIds.length} expenses to null`
      );
      setNullCount += expenseIds.length;

      if (!dryRun) {
        await updateExpensesBatch(db, expenseIds, null, logger);
      }
    } else {
      // Update to correct global category ID
      logger.info(
        `Fixing ${expenseIds.length} expenses: "${categoryName}" → ${newCategoryId}`
      );
      fixedCount += expenseIds.length;

      if (!dryRun) {
        await updateExpensesBatch(db, expenseIds, newCategoryId, logger);
      }
    }
  }

  logger.info(`Fixed ${fixedCount} expense references`);
  logger.info(`Set ${setNullCount} orphaned expenses to null`);

  return {fixed: fixedCount, setNull: setNullCount};
}

/**
 * Helper: Update expenses in batches
 */
async function updateExpensesBatch(
  db: admin.firestore.Firestore,
  expenseIds: string[],
  newCategoryId: string | null,
  logger: Logger
) {
  const batches = splitIntoBatches(expenseIds, 500);

  for (const batchIds of batches) {
    const batch = db.batch();

    for (const expenseId of batchIds) {
      const expenseRef = db.collection("expenses").doc(expenseId);
      batch.update(expenseRef, {categoryId: newCategoryId});
    }

    await retryWithBackoff(() => batch.commit());
  }
}

/**
 * Helper: Split array into batches
 */
function splitIntoBatches<T>(items: T[], batchSize: number): T[][] {
  const batches: T[][] = [];
  for (let i = 0; i < items.length; i += batchSize) {
    batches.push(items.slice(i, i + batchSize));
  }
  return batches;
}

/**
 * Helper: Retry with exponential backoff
 */
async function retryWithBackoff<T>(
  fn: () => Promise<T>,
  maxAttempts = 3,
  initialDelay = 1000
): Promise<T> {
  let attempt = 0;
  let delay = initialDelay;

  while (true) {
    attempt++;
    try {
      return await fn();
    } catch (error) {
      if (attempt >= maxAttempts) {
        throw error;
      }
      console.warn(`Attempt ${attempt} failed, retrying in ${delay}ms...`);
      await new Promise((resolve) => setTimeout(resolve, delay));
      delay *= 2;
    }
  }
}

/**
 * Main migration orchestrator
 */
async function runMigration(
  db: admin.firestore.Firestore,
  logger: MigrationLogger,
  dryRun: boolean
): Promise<MigrationStats> {
  logger.info("============================================================");
  logger.info("Migration: Trip-Specific to Global Categories");
  if (dryRun) {
    logger.info("[DRY RUN MODE] No changes will be written to Firestore");
  }
  logger.info("============================================================");

  // Step 1: Scan existing categories
  const oldCategories = await scanTripSpecificCategories(db, logger);

  if (oldCategories.length === 0) {
    logger.info("No trip-specific categories found. Migration not needed.");
    return {
      oldCategories: 0,
      newGlobalCategories: 0,
      expensesFixed: 0,
      expensesSetNull: 0,
      nameMapping: {},
    };
  }

  // Step 2: Create global definitions
  const definitions = createGlobalDefinitions(oldCategories, logger);

  // Step 3: Replace categories
  const nameMapping = await replaceCategories(db, oldCategories, definitions, logger, dryRun);

  // Step 4: Fix expense references
  const {fixed, setNull} = await fixExpenseReferences(db, nameMapping, logger, dryRun);

  // Save logs
  if (!dryRun) {
    await db.collection("_system").doc("migration_log_transform").set({
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      logs: logger.getLogs(),
    });
  }

  logger.info("============================================================");
  logger.info("Migration completed successfully!");
  logger.info(`Old categories: ${oldCategories.length}`);
  logger.info(`New global categories: ${definitions.length}`);
  logger.info(`Expenses fixed: ${fixed}`);
  logger.info(`Expenses set to null: ${setNull}`);
  logger.info("============================================================");

  const nameMappingObj: Record<string, string> = {};
  nameMapping.forEach((id, name) => {
    nameMappingObj[name] = id;
  });

  return {
    oldCategories: oldCategories.length,
    newGlobalCategories: definitions.length,
    expensesFixed: fixed,
    expensesSetNull: setNull,
    nameMapping: nameMappingObj,
  };
}

/**
 * Cloud Function HTTP endpoint
 */
export const migrateFromTripSpecificFunction = functions.https.onRequest(
  async (req, res) => {
    try {
      const dryRun = req.body.dryRun === true;
      const db = admin.firestore();
      const logger = new MigrationLogger();

      const stats = await runMigration(db, logger, dryRun);

      res.json({
        success: true,
        dryRun,
        stats,
        logs: logger.getLogs(),
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        error: String(error),
      });
    }
  }
);
