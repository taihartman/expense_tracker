import '../models/expense.dart';

/// Repository interface for Expense operations
///
/// Defines the contract for expense data access
/// Implementation uses Firestore (see data/repositories/expense_repository_impl.dart)
abstract class ExpenseRepository {
  /// Create a new expense
  /// Returns the created expense with generated ID
  Future<Expense> createExpense(Expense expense);

  /// Get an expense by ID
  /// Returns null if expense doesn't exist
  Future<Expense?> getExpenseById(String expenseId);

  /// Get all expenses for a trip
  /// Returns stream ordered by date descending (newest first)
  Stream<List<Expense>> getExpensesByTrip(String tripId);

  /// Update an existing expense
  /// Returns the updated expense
  Future<Expense> updateExpense(Expense expense);

  /// Delete an expense by ID
  Future<void> deleteExpense(String expenseId);

  /// Check if an expense exists
  Future<bool> expenseExists(String expenseId);

  /// Get expenses by category for a trip
  Stream<List<Expense>> getExpensesByCategory(String tripId, String categoryId);

  /// Get expenses by payer for a trip
  Stream<List<Expense>> getExpensesByPayer(String tripId, String payerUserId);
}
