import 'package:decimal/decimal.dart';
import 'package:flutter/foundation.dart';
import '../../../../shared/services/firestore_service.dart';
import '../../domain/models/minimal_transfer.dart';
import '../../domain/repositories/settled_transfer_repository.dart';
import '../models/minimal_transfer_model.dart';

/// Helper function to log with timestamps
void _log(String message) {
  debugPrint(
    '[${DateTime.now().toIso8601String()}] [SettledTransferRepository] $message',
  );
}

/// Firestore implementation of SettledTransferRepository
///
/// Stores settled transfers in: settledTransfers/{tripId}/transfers/{transferId}
class SettledTransferRepositoryImpl implements SettledTransferRepository {
  final FirestoreService _firestoreService;

  SettledTransferRepositoryImpl({required FirestoreService firestoreService})
    : _firestoreService = firestoreService;

  @override
  Stream<List<MinimalTransfer>> getSettledTransfers(String tripId) {
    try {
      _log('👀 Watching settled transfers for trip: $tripId');

      return _firestoreService.firestore
          .collection('settledTransfers')
          .doc(tripId)
          .collection('transfers')
          .orderBy('settledAt', descending: true)
          .snapshots()
          .map((snapshot) {
            final transfers = snapshot.docs
                .map((doc) => MinimalTransferModel.fromFirestore(doc))
                .toList();

            _log('📦 Received ${transfers.length} settled transfers');
            return transfers;
          });
    } catch (e) {
      _log('❌ Error watching settled transfers: $e');
      throw Exception('Failed to watch settled transfers: $e');
    }
  }

  @override
  Future<void> markTransferAsSettled(
    String tripId,
    String fromUserId,
    String toUserId,
    String amountBase,
  ) async {
    try {
      _log(
        '✅ Marking transfer as settled: $fromUserId → $toUserId ($amountBase)',
      );

      // Create document reference with auto-generated ID
      final docRef = _firestoreService.firestore
          .collection('settledTransfers')
          .doc(tripId)
          .collection('transfers')
          .doc();

      // Create settled transfer record
      final settledTransfer = MinimalTransfer(
        id: docRef.id,
        tripId: tripId,
        fromUserId: fromUserId,
        toUserId: toUserId,
        amountBase: Decimal.parse(amountBase),
        computedAt: DateTime.now(), // When it was originally computed
        isSettled: true,
        settledAt: DateTime.now(), // When user marked it as settled
      );

      // Save to Firestore
      await docRef.set(MinimalTransferModel.toJson(settledTransfer));

      _log('✅ Transfer marked as settled successfully');
    } catch (e) {
      _log('❌ Error marking transfer as settled: $e');
      throw Exception('Failed to mark transfer as settled: $e');
    }
  }

  @override
  Future<void> unmarkTransferAsSettled(String tripId, String transferId) async {
    try {
      _log('↩️ Unmarking transfer $transferId as settled');

      await _firestoreService.firestore
          .collection('settledTransfers')
          .doc(tripId)
          .collection('transfers')
          .doc(transferId)
          .delete();

      _log('✅ Transfer unmarked successfully');
    } catch (e) {
      _log('❌ Error unmarking transfer: $e');
      throw Exception('Failed to unmark transfer: $e');
    }
  }

  @override
  Future<void> deleteSettledTransfersForTrip(String tripId) async {
    try {
      _log('🗑️ Deleting all settled transfers for trip: $tripId');

      // Get all settled transfers
      final snapshot = await _firestoreService.firestore
          .collection('settledTransfers')
          .doc(tripId)
          .collection('transfers')
          .get();

      // Delete in batch
      final batch = _firestoreService.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      // Also delete the trip document
      batch.delete(
        _firestoreService.firestore.collection('settledTransfers').doc(tripId),
      );

      await batch.commit();

      _log('✅ Deleted ${snapshot.docs.length} settled transfers');
    } catch (e) {
      _log('❌ Error deleting settled transfers: $e');
      throw Exception('Failed to delete settled transfers: $e');
    }
  }
}
