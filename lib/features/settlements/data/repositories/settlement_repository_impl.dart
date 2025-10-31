import 'package:decimal/decimal.dart';
import 'package:flutter/foundation.dart';
import '../../../../shared/services/firestore_service.dart';
import '../../../expenses/domain/repositories/expense_repository.dart';
import '../../../trips/domain/repositories/trip_repository.dart';
import '../../domain/models/settlement_summary.dart';
import '../../domain/models/minimal_transfer.dart';
import '../../domain/models/person_summary.dart';
import '../../domain/repositories/settlement_repository.dart';
import '../../domain/services/settlement_calculator.dart';
import '../models/settlement_summary_model.dart';
import '../models/minimal_transfer_model.dart';

/// Helper function to log with timestamps (only in debug mode)
void _log(String message) {
  if (kDebugMode) {
    debugPrint(
      '[${DateTime.now().toIso8601String()}] [SettlementRepository] $message',
    );
  }
}

/// Firestore implementation of SettlementRepository
///
/// Uses local calculation for MVP (no Cloud Functions yet)
/// Settlement is computed on-demand from expenses
class SettlementRepositoryImpl implements SettlementRepository {
  final FirestoreService _firestoreService;
  final ExpenseRepository _expenseRepository;
  final TripRepository _tripRepository;
  final SettlementCalculator _calculator;

  SettlementRepositoryImpl({
    required FirestoreService firestoreService,
    required ExpenseRepository expenseRepository,
    required TripRepository tripRepository,
    SettlementCalculator? calculator,
  }) : _firestoreService = firestoreService,
       _expenseRepository = expenseRepository,
       _tripRepository = tripRepository,
       _calculator = calculator ?? SettlementCalculator();

  /// Apply adjustments to person summaries based on settled transfers
  ///
  /// When a transfer is settled:
  /// - Payer's netBase increases (they owe less, have paid their debt)
  /// - Receiver's netBase decreases (they're owed less, have been paid)
  ///
  /// This ensures the summary reflects the current state after payments.
  Map<String, PersonSummary> _applySettledTransferAdjustments(
    Map<String, PersonSummary> personSummaries,
    List<MinimalTransfer> settledTransfers,
  ) {
    // Create a mutable copy
    final adjusted = <String, PersonSummary>{};
    for (final entry in personSummaries.entries) {
      adjusted[entry.key] = entry.value;
    }

    // Apply each settled transfer's adjustment
    for (final transfer in settledTransfers.where((t) => t.isSettled)) {
      // Adjust payer (fromUserId): they've paid, so their net balance increases
      if (adjusted.containsKey(transfer.fromUserId)) {
        final payer = adjusted[transfer.fromUserId]!;
        adjusted[transfer.fromUserId] = PersonSummary(
          userId: payer.userId,
          totalPaidBase: payer.totalPaidBase,
          totalOwedBase: payer.totalOwedBase,
          netBase: payer.netBase + transfer.amountBase,
        );
      }

      // Adjust receiver (toUserId): they've been paid, so their net balance decreases
      if (adjusted.containsKey(transfer.toUserId)) {
        final receiver = adjusted[transfer.toUserId]!;
        adjusted[transfer.toUserId] = PersonSummary(
          userId: receiver.userId,
          totalPaidBase: receiver.totalPaidBase,
          totalOwedBase: receiver.totalOwedBase,
          netBase: receiver.netBase - transfer.amountBase,
        );
      }
    }

    return adjusted;
  }

  @override
  Future<SettlementSummary?> getSettlementSummary(String tripId) async {
    try {
      final doc = await _firestoreService.settlements.doc(tripId).get();

      if (!doc.exists) {
        return null;
      }

      return SettlementSummaryModel.fromFirestore(doc);
    } catch (e) {
      throw Exception('Failed to get settlement summary: $e');
    }
  }

  @override
  Stream<SettlementSummary?> watchSettlementSummary(String tripId) {
    try {
      return _firestoreService.settlements.doc(tripId).snapshots().map((doc) {
        if (!doc.exists) {
          return null;
        }
        return SettlementSummaryModel.fromFirestore(doc);
      });
    } catch (e) {
      throw Exception('Failed to watch settlement summary: $e');
    }
  }

  @override
  Stream<List<MinimalTransfer>> getMinimalTransfers(String tripId) {
    try {
      return _firestoreService.settlements
          .doc(tripId)
          .collection('transfers')
          .orderBy('amountBase', descending: true)
          .snapshots()
          .map((snapshot) {
            return snapshot.docs
                .map((doc) => MinimalTransferModel.fromFirestore(doc))
                .toList();
          });
    } catch (e) {
      throw Exception('Failed to get minimal transfers: $e');
    }
  }

  @override
  Future<SettlementSummary> computeSettlement(String tripId) async {
    try {
      _log('🔄 computeSettlement() called for trip: $tripId');

      // Get trip to determine base currency
      final trip = await _tripRepository.getTripById(tripId);
      if (trip == null) {
        throw Exception('Trip not found: $tripId');
      }
      _log('📍 Trip: ${trip.name}, Base Currency: ${trip.baseCurrency.code}');

      // Get all expenses for the trip (await first value from stream)
      final expenses = await _expenseRepository.getExpensesByTrip(tripId).first;

      _log('📦 Retrieved ${expenses.length} expenses from Firestore');

      // Calculate person summaries from expenses (raw calculation)
      _log('\n=== CALCULATING PERSON SUMMARIES ===');
      var personSummaries = _calculator.calculatePersonSummaries(
        expenses: expenses,
        baseCurrency: trip.baseCurrency,
      );

      // Get existing transfers and build list of settled transfers
      _log('\n=== CHECKING FOR SETTLED TRANSFERS ===');
      final existingTransfers = await _firestoreService.settlements
          .doc(tripId)
          .collection('transfers')
          .get();

      _log('📦 Found ${existingTransfers.docs.length} existing transfers');

      // Build list of settled transfers to apply as adjustments
      final settledTransfersToApply = <MinimalTransfer>[];
      final settledMap = <String, ({bool isSettled, DateTime? settledAt})>{};

      for (final doc in existingTransfers.docs) {
        final existingTransfer = MinimalTransferModel.fromFirestore(doc);
        if (existingTransfer.isSettled) {
          settledTransfersToApply.add(existingTransfer);
          final key =
              '${existingTransfer.fromUserId}-${existingTransfer.toUserId}';
          settledMap[key] = (
            isSettled: existingTransfer.isSettled,
            settledAt: existingTransfer.settledAt,
          );
          _log(
            '✅ Settled transfer found: ${existingTransfer.fromUserId} -> ${existingTransfer.toUserId} (${existingTransfer.amountBase})',
          );
        }
      }

      // Apply adjustments to person summaries based on settled transfers BEFORE calculating new transfers
      _log('\n=== APPLYING SETTLED TRANSFER ADJUSTMENTS ===');
      if (settledTransfersToApply.isNotEmpty) {
        _log(
          'Applying ${settledTransfersToApply.length} settled transfer adjustments',
        );
        for (final t in settledTransfersToApply) {
          _log('  ${t.fromUserId} -> ${t.toUserId}: ${t.amountBase}');
        }
        personSummaries = _applySettledTransferAdjustments(
          personSummaries,
          settledTransfersToApply,
        );
      } else {
        _log('No settled transfers to adjust');
      }

      _log('\n📊 Person Summaries AFTER adjustments:');
      personSummaries.forEach((userId, summary) {
        _log('  $userId: Net = ${summary.netBase}');
      });

      // Calculate pairwise netted transfers directly from expenses
      _log('\n=== CALCULATING PAIRWISE NETTED TRANSFERS ===');
      final rawTransfers = _calculator.calculatePairwiseNetTransfers(
        tripId: tripId,
        expenses: expenses,
      );

      // Apply settled transfer reductions
      // For pairwise transfers, we subtract any settled amounts from the raw debts
      _log('\n=== APPLYING SETTLED TRANSFER REDUCTIONS ===');
      final transfersWithSettledStatus = <MinimalTransfer>[];

      // Build a map of settled amounts by pair
      final settledAmounts = <String, ({Decimal amount, DateTime settledAt})>{};
      for (final settled in settledTransfersToApply) {
        final key = '${settled.fromUserId}-${settled.toUserId}';
        settledAmounts[key] = (
          amount: settled.amountBase,
          settledAt: settled.settledAt!,
        );
        _log(
          '  Settled: ${settled.fromUserId} -> ${settled.toUserId}: ${settled.amountBase}',
        );
      }

      for (final transfer in rawTransfers) {
        final key = '${transfer.fromUserId}-${transfer.toUserId}';
        final settledInfo = settledAmounts[key];

        if (settledInfo != null) {
          // Subtract settled amount from raw debt
          final remainingAmount = transfer.amountBase - settledInfo.amount;
          _log(
            '  ${transfer.fromUserId} -> ${transfer.toUserId}: ${transfer.amountBase} - ${settledInfo.amount} = $remainingAmount',
          );

          if (remainingAmount > Decimal.parse('0.01')) {
            // Still have remaining debt
            transfersWithSettledStatus.add(
              MinimalTransfer(
                id: '',
                tripId: transfer.tripId,
                fromUserId: transfer.fromUserId,
                toUserId: transfer.toUserId,
                amountBase: remainingAmount,
                computedAt: transfer.computedAt,
                isSettled: false, // Remaining debt is not settled
                settledAt: null,
              ),
            );
          }
          // If remainingAmount <= 0, the debt is fully settled, don't add a transfer
        } else {
          // No settled amount, use full raw amount
          transfersWithSettledStatus.add(
            MinimalTransfer(
              id: '',
              tripId: transfer.tripId,
              fromUserId: transfer.fromUserId,
              toUserId: transfer.toUserId,
              amountBase: transfer.amountBase,
              computedAt: transfer.computedAt,
              isSettled: false,
              settledAt: null,
            ),
          );
        }
      }

      // Create settlement summary with adjusted summaries
      final settlementSummary = SettlementSummary(
        tripId: tripId,
        baseCurrency: trip.baseCurrency,
        personSummaries: personSummaries,
        lastComputedAt: DateTime.now(),
      );

      _log('\n💾 Saving settlement summary to Firestore...');

      // Save settlement summary to Firestore (with adjusted summaries)
      await _firestoreService.settlements
          .doc(tripId)
          .set(SettlementSummaryModel.toJson(settlementSummary));

      // Optimize transfer storage: merge/update instead of delete+recreate
      final batch = _firestoreService.batch();

      // Build map of existing transfers by key for quick lookup
      final existingByKey =
          <String, ({String docId, MinimalTransfer transfer})>{};
      for (final doc in existingTransfers.docs) {
        final transfer = MinimalTransferModel.fromFirestore(doc);
        final key = '${transfer.fromUserId}-${transfer.toUserId}';
        existingByKey[key] = (docId: doc.id, transfer: transfer);
      }

      // Track which existing transfers to keep
      final processedKeys = <String>{};

      // Update or create transfers
      for (final transfer in transfersWithSettledStatus) {
        final key = '${transfer.fromUserId}-${transfer.toUserId}';
        processedKeys.add(key);

        final existing = existingByKey[key];
        if (existing != null) {
          // Transfer exists - update if changed
          if (existing.transfer.amountBase != transfer.amountBase ||
              existing.transfer.isSettled != transfer.isSettled) {
            final docRef = _firestoreService.settlements
                .doc(tripId)
                .collection('transfers')
                .doc(existing.docId);

            final updatedTransfer = MinimalTransfer(
              id: existing.docId,
              tripId: transfer.tripId,
              fromUserId: transfer.fromUserId,
              toUserId: transfer.toUserId,
              amountBase: transfer.amountBase,
              computedAt: transfer.computedAt,
              isSettled: transfer.isSettled,
              settledAt: transfer.settledAt,
            );

            batch.set(docRef, MinimalTransferModel.toJson(updatedTransfer));
            _log('  Updated transfer: $key');
          } else {
            _log('  Unchanged transfer: $key');
          }
        } else {
          // New transfer - create
          final docRef = _firestoreService.settlements
              .doc(tripId)
              .collection('transfers')
              .doc();

          final newTransfer = MinimalTransfer(
            id: docRef.id,
            tripId: transfer.tripId,
            fromUserId: transfer.fromUserId,
            toUserId: transfer.toUserId,
            amountBase: transfer.amountBase,
            computedAt: transfer.computedAt,
            isSettled: transfer.isSettled,
            settledAt: transfer.settledAt,
          );

          batch.set(docRef, MinimalTransferModel.toJson(newTransfer));
          _log('  Created new transfer: $key');
        }
      }

      // Delete transfers that no longer exist
      for (final entry in existingByKey.entries) {
        if (!processedKeys.contains(entry.key)) {
          final docRef = _firestoreService.settlements
              .doc(tripId)
              .collection('transfers')
              .doc(entry.value.docId);
          batch.delete(docRef);
          _log('  Deleted obsolete transfer: ${entry.key}');
        }
      }

      await batch.commit();

      _log('✅ Settlement computed and saved successfully');
      _log('   ${transfersWithSettledStatus.length} transfers created');
      _log('   ${personSummaries.length} person summaries saved\n');

      return settlementSummary;
    } catch (e) {
      _log('❌ Error in computeSettlement: $e');
      throw Exception('Failed to compute settlement: $e');
    }
  }

  @override
  Future<bool> settlementExists(String tripId) async {
    try {
      final doc = await _firestoreService.settlements.doc(tripId).get();

      return doc.exists;
    } catch (e) {
      throw Exception('Failed to check if settlement exists: $e');
    }
  }

  @override
  Future<void> deleteSettlement(String tripId) async {
    try {
      // Delete transfers subcollection
      final transfers = await _firestoreService.settlements
          .doc(tripId)
          .collection('transfers')
          .get();

      final batch = _firestoreService.batch();

      for (final doc in transfers.docs) {
        batch.delete(doc.reference);
      }

      // Delete settlement document
      batch.delete(_firestoreService.settlements.doc(tripId));

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to delete settlement: $e');
    }
  }

  @override
  Future<void> markTransferAsSettled(String tripId, String transferId) async {
    try {
      // First, mark the transfer as settled in Firestore
      await _firestoreService.settlements
          .doc(tripId)
          .collection('transfers')
          .doc(transferId)
          .update({'isSettled': true, 'settledAt': _firestoreService.now});

      // Fetch the transfer to get its details (needed for summary adjustment)
      final transferDoc = await _firestoreService.settlements
          .doc(tripId)
          .collection('transfers')
          .doc(transferId)
          .get();

      if (!transferDoc.exists) {
        throw Exception('Transfer not found after marking as settled');
      }

      final transfer = MinimalTransferModel.fromFirestore(transferDoc);

      // Fetch current settlement summary
      final settlementDoc = await _firestoreService.settlements
          .doc(tripId)
          .get();

      if (!settlementDoc.exists) {
        throw Exception('Settlement not found');
      }

      final summary = SettlementSummaryModel.fromFirestore(settlementDoc);

      // Apply adjustment for this single settled transfer
      final adjustedSummaries = _applySettledTransferAdjustments(
        summary.personSummaries,
        [transfer],
      );

      // Update settlement with adjusted summaries
      await _firestoreService.settlements.doc(tripId).update({
        'personSummaries': adjustedSummaries.map(
          (userId, personSummary) => MapEntry(userId, personSummary.toMap()),
        ),
      });
    } catch (e) {
      throw Exception('Failed to mark transfer as settled: $e');
    }
  }

  @override
  Future<bool> shouldRecompute(String tripId) async {
    try {
      // Get settlement summary to check lastComputedAt
      final settlement = await getSettlementSummary(tripId);
      if (settlement == null) {
        // No settlement exists, should compute
        return true;
      }

      // Get trip to check lastExpenseModifiedAt
      final trip = await _tripRepository.getTripById(tripId);
      if (trip == null) {
        throw Exception('Trip not found: $tripId');
      }

      // If no expenses have been modified, no need to recompute
      if (trip.lastExpenseModifiedAt == null) {
        return false;
      }

      // Recompute if expenses were modified after settlement was computed
      return trip.lastExpenseModifiedAt!.isAfter(settlement.lastComputedAt);
    } catch (e) {
      throw Exception('Failed to check if should recompute: $e');
    }
  }
}
