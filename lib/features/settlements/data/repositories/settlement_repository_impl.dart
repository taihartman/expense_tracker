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
  })  : _firestoreService = firestoreService,
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
      return _firestoreService.settlements
          .doc(tripId)
          .snapshots()
          .map((doc) {
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
      // Get trip to determine base currency
      final trip = await _tripRepository.getTripById(tripId);
      if (trip == null) {
        throw Exception('Trip not found: $tripId');
      }

      // Get all expenses for the trip (await first value from stream)
      final expenses = await _expenseRepository
          .getExpensesByTrip(tripId)
          .first;

      // Calculate person summaries from expenses (raw calculation)
      var personSummaries = _calculator.calculatePersonSummaries(
        expenses: expenses,
        baseCurrency: trip.baseCurrency,
      );

      // Calculate minimal transfers from raw summaries
      final transfers = _calculator.calculateMinimalTransfers(
        tripId: tripId,
        personSummaries: personSummaries,
      );

      // Get existing transfers and build map of settled transfers
      final existingTransfers = await _firestoreService.settlements
          .doc(tripId)
          .collection('transfers')
          .get();

      // Build map of settled transfers: "fromUserId-toUserId" -> (isSettled, settledAt, amount)
      final settledMap = <String, ({bool isSettled, DateTime? settledAt, })>{};
      for (final doc in existingTransfers.docs) {
        final existingTransfer = MinimalTransferModel.fromFirestore(doc);
        if (existingTransfer.isSettled) {
          final key = '${existingTransfer.fromUserId}-${existingTransfer.toUserId}';
          settledMap[key] = (
            isSettled: existingTransfer.isSettled,
            settledAt: existingTransfer.settledAt,
          );
        }
      }

      // Build list of transfers with settled status preserved
      final transfersWithSettledStatus = <MinimalTransfer>[];
      for (final transfer in transfers) {
        final key = '${transfer.fromUserId}-${transfer.toUserId}';
        final wasSettled = settledMap[key];

        transfersWithSettledStatus.add(MinimalTransfer(
          id: '', // Will be set when saving
          tripId: transfer.tripId,
          fromUserId: transfer.fromUserId,
          toUserId: transfer.toUserId,
          amountBase: transfer.amountBase,
          computedAt: transfer.computedAt,
          isSettled: wasSettled?.isSettled ?? false,
          settledAt: wasSettled?.settledAt,
        ));
      }

      // Apply adjustments to person summaries based on settled transfers
      personSummaries = _applySettledTransferAdjustments(
        personSummaries,
        transfersWithSettledStatus,
      );

      // Create settlement summary with adjusted summaries
      final settlementSummary = SettlementSummary(
        tripId: tripId,
        baseCurrency: trip.baseCurrency,
        personSummaries: personSummaries,
        lastComputedAt: DateTime.now(),
      );

      // Save settlement summary to Firestore (with adjusted summaries)
      await _firestoreService.settlements
          .doc(tripId)
          .set(SettlementSummaryModel.toJson(settlementSummary));

      // Now save the transfers
      final batch = _firestoreService.batch();

      // Delete old transfers
      for (final doc in existingTransfers.docs) {
        batch.delete(doc.reference);
      }

      // Add new transfers with preserved settled status
      for (final transfer in transfersWithSettledStatus) {
        final docRef = _firestoreService.settlements
            .doc(tripId)
            .collection('transfers')
            .doc();

        final transferWithId = MinimalTransfer(
          id: docRef.id,
          tripId: transfer.tripId,
          fromUserId: transfer.fromUserId,
          toUserId: transfer.toUserId,
          amountBase: transfer.amountBase,
          computedAt: transfer.computedAt,
          isSettled: transfer.isSettled,
          settledAt: transfer.settledAt,
        );

        batch.set(docRef, MinimalTransferModel.toJson(transferWithId));
      }

      await batch.commit();

      return settlementSummary;
    } catch (e) {
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
          .update({
        'isSettled': true,
        'settledAt': _firestoreService.now,
      });

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
      final settlementDoc = await _firestoreService.settlements.doc(tripId).get();

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
