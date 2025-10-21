import '../models/minimal_transfer.dart';

/// Repository for managing settled transfer history
///
/// This stores ONLY the transfers that users have marked as "settled/paid".
/// These are immutable historical records of user actions.
///
/// Unlike the main SettlementRepository which calculates settlements on-demand,
/// this repository persists state because "settled" is a USER ACTION, not derived data.
abstract class SettledTransferRepository {
  /// Get all settled transfers for a trip (as a stream for real-time updates)
  Stream<List<MinimalTransfer>> getSettledTransfers(String tripId);

  /// Mark a transfer as settled
  ///
  /// Records that the payer has paid the receiver the specified amount.
  /// This is an immutable record - once settled, it's permanent history.
  Future<void> markTransferAsSettled(
    String tripId,
    String fromUserId,
    String toUserId,
    String amountBase,
  );

  /// Un-settle a transfer (if user made a mistake)
  Future<void> unmarkTransferAsSettled(String tripId, String transferId);

  /// Delete all settled transfers for a trip (cleanup)
  Future<void> deleteSettledTransfersForTrip(String tripId);
}
