/**
 * Diagnostic script to analyze current category state in production
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

export const diagnosticCategories = functions.https.onRequest(async (req, res) => {
  try {
    const db = admin.firestore();

    // 1. Check global categories collection
    const globalCategoriesSnapshot = await db.collection("categories").get();
    const globalCategories = globalCategoriesSnapshot.docs.map((doc) => ({
      id: doc.id,
      ...doc.data(),
    }));

    // 2. Check for any trip-specific categories (subcollections)
    const tripsSnapshot = await db.collection("trips").get();
    const tripCategories: any[] = [];

    for (const tripDoc of tripsSnapshot.docs) {
      const categoriesSnapshot = await db
        .collection("trips")
        .doc(tripDoc.id)
        .collection("categories")
        .get();

      for (const catDoc of categoriesSnapshot.docs) {
        tripCategories.push({
          tripId: tripDoc.id,
          categoryId: catDoc.id,
          ...catDoc.data(),
        });
      }
    }

    // 3. Check expenses and their category references
    const expensesSnapshot = await db.collection("expenses").get();
    const expenseAnalysis = {
      total: expensesSnapshot.size,
      withCategory: 0,
      withNull: 0,
      categoryReferences: new Map<string, number>(),
    };

    for (const expenseDoc of expensesSnapshot.docs) {
      const categoryId = expenseDoc.data().categoryId;

      if (categoryId === null || categoryId === undefined) {
        expenseAnalysis.withNull++;
      } else {
        expenseAnalysis.withCategory++;
        const count = expenseAnalysis.categoryReferences.get(categoryId) || 0;
        expenseAnalysis.categoryReferences.set(categoryId, count + 1);
      }
    }

    // 4. Check if referenced categories exist
    const orphanedReferences: string[] = [];
    for (const [categoryId] of expenseAnalysis.categoryReferences) {
      const exists = globalCategories.some((cat) => cat.id === categoryId);
      if (!exists) {
        orphanedReferences.push(categoryId);
      }
    }

    // Convert Map to object for JSON response
    const categoryReferencesObj: Record<string, number> = {};
    expenseAnalysis.categoryReferences.forEach((count, id) => {
      categoryReferencesObj[id] = count;
    });

    res.json({
      success: true,
      timestamp: new Date().toISOString(),
      data: {
        globalCategories: {
          count: globalCategories.length,
          categories: globalCategories,
        },
        tripSpecificCategories: {
          count: tripCategories.length,
          categories: tripCategories,
        },
        expenses: {
          total: expenseAnalysis.total,
          withCategory: expenseAnalysis.withCategory,
          withNull: expenseAnalysis.withNull,
          uniqueCategoryReferences: expenseAnalysis.categoryReferences.size,
          categoryReferences: categoryReferencesObj,
        },
        orphanedReferences: {
          count: orphanedReferences.length,
          categoryIds: orphanedReferences,
        },
        analysis: {
          allCategoriesAreGlobal: tripCategories.length === 0 && globalCategories.length > 0,
          noOrphanedReferences: orphanedReferences.length === 0,
          systemHealthy:
            tripCategories.length === 0 &&
            globalCategories.length > 0 &&
            orphanedReferences.length === 0,
        },
      },
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: String(error),
    });
  }
});
