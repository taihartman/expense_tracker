import '../models/settlement_summary.dart';
import '../models/minimal_transfer.dart';

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
  Future<SettlementSummary> computeSettlement(String tripId);

  /// Check if settlement exists for a trip
  Future<bool> settlementExists(String tripId);

  /// Delete settlement data for a trip
  /// Used when trip is deleted or reset
  Future<void> deleteSettlement(String tripId);
}
