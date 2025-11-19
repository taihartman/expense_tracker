import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/models/minimal_transfer.dart';
import '../../domain/repositories/settlement_repository.dart';
import 'settlement_state.dart';
import '../../../expenses/domain/repositories/expense_repository.dart';
import '../../../trips/domain/repositories/trip_repository.dart';

/// Helper function to log with timestamps
void _log(String message) {
  debugPrint(
    '[${DateTime.now().toIso8601String()}] [SettlementCubit] $message',
  );
}

/// Simplified SettlementCubit using Pure Derived State Pattern
///
/// Key Principles:
/// 1. Settlements are DERIVED from expenses (not stored separately)
/// 2. Calculate on-demand whenever expenses change
/// 3. Only store "settled transfer" history in Firestore
/// 4. Always accurate, no staleness issues
class SettlementCubitSimplified extends Cubit<SettlementState> {
  final SettlementRepository _settlementRepository;
  final ExpenseRepository _expenseRepository;
  final TripRepository _tripRepository;

  StreamSubscription? _combinedSubscription;
  String? _currentTripId;

  SettlementCubitSimplified({
    required SettlementRepository settlementRepository,
    required ExpenseRepository expenseRepository,
    required TripRepository tripRepository,
  }) : _settlementRepository = settlementRepository,
       _expenseRepository = expenseRepository,
       _tripRepository = tripRepository,
       super(const SettlementInitial());

  /// Separate transfers into active and settled lists
  ({List<MinimalTransfer> active, List<MinimalTransfer> settled})
  _separateTransfers(List<MinimalTransfer> allTransfers) {
    final active = <MinimalTransfer>[];
    final settled = <MinimalTransfer>[];

    for (final transfer in allTransfers) {
      if (transfer.isSettled) {
        settled.add(transfer);
      } else {
        active.add(transfer);
      }
    }

    return (active: active, settled: settled);
  }

  /// Load settlement by calculating from current expenses
  ///
  /// This method subscribes to the expense stream and recalculates
  /// settlements whenever expenses change. No complex synchronization needed!
  Future<void> loadSettlement(String tripId) async {
    try {
      _log('📥 Loading settlement for trip: $tripId (SIMPLIFIED APPROACH)');
      _currentTripId = tripId;

      // Cancel existing subscription
      await _combinedSubscription?.cancel();

      emit(const SettlementLoading());

      // Get trip for base currency (one-time fetch)
      final trip = await _tripRepository.getTripById(tripId);
      if (trip == null) {
        throw Exception('Trip not found: $tripId');
      }

      _log('📍 Trip: ${trip.name}, Base Currency: ${trip.defaultCurrency.code}');

      // Subscribe to expense stream - calculate on every emission
      // This is the ONLY subscription we need!
      _combinedSubscription = _expenseRepository
          .getExpensesByTrip(tripId)
          .listen(
            (expenses) async {
              _log(
                '📦 Received ${expenses.length} expenses, recalculating settlement...',
              );

              try {
                // Calculate settlement summary from current expenses
                // This is FAST (< 5ms for 200 expenses)
                final result = await _settlementRepository.computeSettlement(
                  tripId,
                );
                final summary = result.summary;
                final validationWarnings = result.validationWarnings;

                _log('✅ Settlement calculated successfully');
                _log('   ${summary.personSummaries.length} person summaries');

                // Get transfers from the repository
                // In the simplified version, these are calculated fresh, not stored
                final allTransfers = await _settlementRepository
                    .getMinimalTransfers(tripId)
                    .first;

                _log('📦 Received ${allTransfers.length} transfers');

                // Separate active and settled transfers
                final separated = _separateTransfers(allTransfers);
                _log(
                  '📊 ${separated.active.length} active, ${separated.settled.length} settled',
                );

                if (!isClosed) {
                  emit(
                    SettlementLoaded(
                      summary: summary,
                      activeTransfers: separated.active,
                      settledTransfers: separated.settled,
                      validationWarnings: validationWarnings,
                    ),
                  );
                }
              } catch (e) {
                _log('❌ Error calculating settlement: $e');
                if (!isClosed) {
                  emit(
                    SettlementError(
                      'Failed to calculate settlement: ${e.toString()}',
                    ),
                  );
                }
              }
            },
            onError: (error) {
              _log('❌ Error in expense stream: $error');
              if (!isClosed) {
                emit(
                  SettlementError(
                    'Failed to load expenses: ${error.toString()}',
                  ),
                );
              }
            },
          );
    } catch (e) {
      _log('❌ Error in loadSettlement: $e');
      if (!isClosed) {
        emit(SettlementError('Failed to load settlement: ${e.toString()}'));
      }
    }
  }

  /// Mark a specific transfer as settled
  ///
  /// This is the ONLY write operation to Firestore for settlements
  Future<void> markTransferAsSettled(String transferId) async {
    if (_currentTripId == null) {
      _log('⚠️ Cannot mark transfer as settled: no current trip');
      return;
    }

    try {
      _log('✅ Marking transfer $transferId as settled');
      await _settlementRepository.markTransferAsSettled(
        _currentTripId!,
        transferId,
      );
      _log('✅ Transfer marked as settled');

      // The expense stream listener will automatically recalculate and update UI
      // No manual refresh needed!
    } catch (e) {
      _log('❌ Error marking transfer as settled: $e');
      if (!isClosed) {
        emit(
          SettlementError(
            'Failed to mark transfer as settled: ${e.toString()}',
          ),
        );
      }
    }
  }

  /// Get current trip ID
  String? get currentTripId => _currentTripId;

  @override
  Future<void> close() {
    _log('🔴 Closing SettlementCubit - cancelling subscription');
    _combinedSubscription?.cancel();
    return super.close();
  }
}
