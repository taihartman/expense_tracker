import '../models/settlement_summary.dart';
import '../models/minimal_transfer.dart';
import '../../../expenses/domain/models/expense.dart';
import '../../../../core/models/currency_code.dart';

/// Repository interface for Settlement operations
///
/// Defines the contract for settlement data access
/// Implementation uses Firestore with Cloud Functions for settlement computation
abstract class SettlementRepository {
  /// Get settlement summary for a trip
  /// Returns null if no settlement exists for this trip
  Future<SettlementSummary?> getSettlementSummary(String tripId);

  /// Get settlement summary stream for a trip
  /// Returns real-time updates when settlement changes
  Stream<SettlementSummary?> watchSettlementSummary(String tripId);

  /// Get minimal transfers for a trip
  /// Returns list of optimized transfers to settle all debts
  Stream<List<MinimalTransfer>> getMinimalTransfers(String tripId);

  /// Manually trigger settlement computation
  /// Normally triggered automatically by Cloud Function on expense changes
  /// Returns the computed settlement summary
  ///
  /// T029: Added optional [currencyFilter] for per-currency settlements
  Future<SettlementSummary> computeSettlement(
    String tripId, {
    CurrencyCode? currencyFilter,
  });

  /// Compute settlement with provided expenses (performance optimization)
  /// Avoids re-fetching expenses when they're already available from a stream
  /// [tripId] - The ID of the trip
  /// [expenses] - The expenses to use for computation (from stream)
  ///
  /// T029: Added optional [currencyFilter] for per-currency settlements
  Future<SettlementSummary> computeSettlementWithExpenses(
    String tripId,
    List<Expense> expenses, {
    CurrencyCode? currencyFilter,
  });

  /// Check if settlement exists for a trip
  Future<bool> settlementExists(String tripId);

  /// Delete settlement data for a trip
  /// Used when trip is deleted or reset
  Future<void> deleteSettlement(String tripId);

  /// Mark a specific transfer as settled
  /// Updates the transfer's isSettled and settledAt fields
  Future<void> markTransferAsSettled(String tripId, String transferId);

  /// Check if settlement should be recomputed
  /// Compares settlement's lastComputedAt with trip's lastExpenseModifiedAt
  /// Returns true if expenses have been modified after settlement was computed
  Future<bool> shouldRecompute(String tripId);
}
