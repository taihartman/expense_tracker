/**
 * Import function triggers from their respective submodules:
 *
 * import {onCall} from "firebase-functions/v2/https";
 * import {onDocumentWritten} from "firebase-functions/v2/firestore";
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

import {onRequest} from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import * as admin from "firebase-admin";

// Initialize Firebase Admin
admin.initializeApp();

/**
 * Generate a 12-digit recovery code in format XXXX-XXXX-XXXX
 * @return {string} Generated recovery code
 */
function generateRecoveryCode(): string {
  const code = Math.floor(Math.random() * 1000000000000); // 0 to 999,999,999,999
  const codeString = code.toString().padStart(12, "0");
  return `${codeString.substring(0, 4)}-${codeString.substring(4, 8)}-${codeString.substring(8)}`;
}

/**
 * One-time backfill function to generate recovery codes for all legacy trips
 *
 * Usage:
 * 1. Deploy function: firebase deploy --only functions:backfillRecoveryCodes
 * 2. Call function: curl https://YOUR_REGION-YOUR_PROJECT.cloudfunctions.net/backfillRecoveryCodes
 * 3. Or via Firebase Console: Functions -> backfillRecoveryCodes -> Testing tab
 *
 * This function:
 * - Iterates through all trips in the database
 * - Checks if each trip already has a recovery code
 * - Generates and saves a recovery code for trips without one
 * - Returns a summary of the operation
 */
// Export migration functions
export {migrateCategoriesFunction as migrateCategories} from "./migrateCategories";
export {migrateFromTripSpecificFunction as migrateFromTripSpecific} from "./migrateFromTripSpecificCategories";
// Export diagnostic function
export {diagnosticCategories} from "./diagnostics";

export const backfillRecoveryCodes = onRequest(async (request, response) => {
  logger.info("🚀 Starting recovery code backfill...");

  try {
    const db = admin.firestore();
    const tripsRef = db.collection("trips");

    // Get all trips
    const tripsSnapshot = await tripsRef.get();
    const totalTrips = tripsSnapshot.docs.length;

    logger.info(`📦 Found ${totalTrips} trips to check`);

    if (totalTrips === 0) {
      response.json({
        success: true,
        message: "No trips found",
        generated: 0,
        skipped: 0,
      });
      return;
    }

    let generatedCount = 0;
    let skippedCount = 0;
    const results: Array<{tripId: string; tripName: string; status: string; code?: string}> = [];

    // Process each trip
    for (const tripDoc of tripsSnapshot.docs) {
      const tripId = tripDoc.id;
      const tripData = tripDoc.data();
      const tripName = tripData.name || "Unknown";

      logger.info(`🔍 Processing trip: ${tripName} (ID: ${tripId})`);

      try {
        // Check if recovery code already exists
        const recoveryCodeRef = db
          .collection("trips")
          .doc(tripId)
          .collection("recovery")
          .doc("code");

        const recoveryCodeDoc = await recoveryCodeRef.get();

        if (recoveryCodeDoc.exists) {
          skippedCount++;
          logger.info(`  ⏭️ Trip already has recovery code, skipping`);
          results.push({
            tripId,
            tripName,
            status: "skipped",
          });
          continue;
        }

        // Generate new recovery code
        const code = generateRecoveryCode();
        logger.info(`  🔑 Generated recovery code: ${code}`);

        // Save recovery code to Firestore
        await recoveryCodeRef.set({
          code: code,
          tripId: tripId,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          usedCount: 0,
          lastUsedAt: null,
        });

        generatedCount++;
        logger.info(`  ✅ Recovery code generated and saved`);

        results.push({
          tripId,
          tripName,
          status: "generated",
          code: code,
        });
      } catch (error) {
        logger.error(`❌ Failed to process trip ${tripId}:`, error);
        results.push({
          tripId,
          tripName,
          status: "error",
        });
      }
    }

    logger.info(`🎉 Backfill complete: ${generatedCount} generated, ${skippedCount} skipped`);

    response.json({
      success: true,
      message: "Recovery code backfill completed",
      generated: generatedCount,
      skipped: skippedCount,
      total: totalTrips,
      results: results,
    });
  } catch (error) {
    logger.error("❌ Fatal error in backfill:", error);
    response.status(500).json({
      success: false,
      message: "Backfill failed",
      error: String(error),
    });
  }
});
