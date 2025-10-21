import '../../../../shared/services/firestore_service.dart';
import '../../../expenses/domain/repositories/expense_repository.dart';
import '../../../trips/domain/repositories/trip_repository.dart';
import '../../domain/models/settlement_summary.dart';
import '../../domain/models/minimal_transfer.dart';
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

      // Calculate person summaries
      final personSummaries = _calculator.calculatePersonSummaries(
        expenses: expenses,
        baseCurrency: trip.baseCurrency,
      );

      // Create settlement summary
      final settlementSummary = SettlementSummary(
        tripId: tripId,
        baseCurrency: trip.baseCurrency,
        personSummaries: personSummaries,
        lastComputedAt: DateTime.now(),
      );

      // Save to Firestore
      await _firestoreService.settlements
          .doc(tripId)
          .set(SettlementSummaryModel.toJson(settlementSummary));

      // Calculate and save minimal transfers
      final transfers = _calculator.calculateMinimalTransfers(
        tripId: tripId,
        personSummaries: personSummaries,
      );

      // Delete existing transfers
      final existingTransfers = await _firestoreService.settlements
          .doc(tripId)
          .collection('transfers')
          .get();

      final batch = _firestoreService.batch();

      // Delete old transfers
      for (final doc in existingTransfers.docs) {
        batch.delete(doc.reference);
      }

      // Add new transfers
      for (final transfer in transfers) {
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
}
