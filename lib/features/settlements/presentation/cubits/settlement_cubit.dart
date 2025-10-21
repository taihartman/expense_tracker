import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/models/minimal_transfer.dart';
import '../../domain/repositories/settlement_repository.dart';
import 'settlement_state.dart';

/// Helper function to log with timestamps
void _log(String message) {
  debugPrint('[${DateTime.now().toIso8601String()}] [SettlementCubit] $message');
}

/// Cubit for managing settlement state
///
/// Handles loading and computing settlements for a trip
class SettlementCubit extends Cubit<SettlementState> {
  final SettlementRepository _settlementRepository;
  StreamSubscription? _summarySubscription;
  StreamSubscription? _transfersSubscription;
  String? _currentTripId;

  SettlementCubit({
    required SettlementRepository settlementRepository,
  })  : _settlementRepository = settlementRepository,
        super(const SettlementInitial());

  /// Separate transfers into active and settled lists
  ({List<MinimalTransfer> active, List<MinimalTransfer> settled}) _separateTransfers(
      List<MinimalTransfer> allTransfers) {
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

  /// Load settlement for a trip
  ///
  /// Subscribes to real-time updates for both summary and transfers
  Future<void> loadSettlement(String tripId) async {
    try {
      _log('📥 Loading settlement for trip: $tripId');
      _currentTripId = tripId;

      // Cancel existing subscriptions
      await _summarySubscription?.cancel();
      await _transfersSubscription?.cancel();

      emit(const SettlementLoading());

      // Check if settlement exists
      final exists = await _settlementRepository.settlementExists(tripId);

      if (!exists) {
        _log('⚠️ Settlement does not exist, computing...');
        await computeSettlement(tripId);
        return;
      }

      // Subscribe to settlement summary stream
      _summarySubscription = _settlementRepository
          .watchSettlementSummary(tripId)
          .listen(
        (summary) async {
          if (summary == null) {
            _log('⚠️ Settlement summary became null, recomputing...');
            await computeSettlement(tripId);
            return;
          }

          _log('📦 Received settlement summary');

          // Get transfers
          final allTransfers = await _settlementRepository
              .getMinimalTransfers(tripId)
              .first;

          _log('📦 Received ${allTransfers.length} minimal transfers');

          // Separate active and settled transfers
          final separated = _separateTransfers(allTransfers);
          _log('📊 ${separated.active.length} active, ${separated.settled.length} settled');

          if (!isClosed) {
            emit(SettlementLoaded(
              summary: summary,
              activeTransfers: separated.active,
              settledTransfers: separated.settled,
            ));
          }
        },
        onError: (error) {
          _log('❌ Error loading settlement: $error');
          if (!isClosed) {
            emit(SettlementError('Failed to load settlement: ${error.toString()}'));
          }
        },
      );

      // Also subscribe to transfers for real-time updates
      _transfersSubscription = _settlementRepository
          .getMinimalTransfers(tripId)
          .listen(
        (allTransfers) {
          _log('📦 Transfers updated: ${allTransfers.length} transfers');
          if (state is SettlementLoaded && !isClosed) {
            final currentState = state as SettlementLoaded;
            final separated = _separateTransfers(allTransfers);
            _log('📊 ${separated.active.length} active, ${separated.settled.length} settled');
            emit(currentState.copyWith(
              activeTransfers: separated.active,
              settledTransfers: separated.settled,
            ));
          }
        },
        onError: (error) {
          _log('❌ Error loading transfers: $error');
        },
      );
    } catch (e) {
      _log('❌ Error in loadSettlement: $e');
      if (!isClosed) {
        emit(SettlementError('Failed to load settlement: ${e.toString()}'));
      }
    }
  }

  /// Compute settlement for a trip
  ///
  /// Calculates person summaries and minimal transfers from expenses
  /// This can be triggered manually or automatically when expenses change
  Future<void> computeSettlement(String tripId) async {
    try {
      _log('🔄 Computing settlement for trip: $tripId');
      emit(const SettlementComputing());

      final summary = await _settlementRepository.computeSettlement(tripId);
      _log('✅ Settlement computed successfully');

      // Get the computed transfers
      final allTransfers = await _settlementRepository
          .getMinimalTransfers(tripId)
          .first;

      // Separate active and settled transfers
      final separated = _separateTransfers(allTransfers);
      _log('📊 ${separated.active.length} active, ${separated.settled.length} settled');

      if (!isClosed) {
        emit(SettlementLoaded(
          summary: summary,
          activeTransfers: separated.active,
          settledTransfers: separated.settled,
        ));
      }

      // Now subscribe to real-time updates
      if (_currentTripId == tripId) {
        await loadSettlement(tripId);
      }
    } catch (e) {
      _log('❌ Error computing settlement: $e');
      if (!isClosed) {
        emit(SettlementError('Failed to compute settlement: ${e.toString()}'));
      }
    }
  }

  /// Refresh settlement data
  ///
  /// Re-computes the settlement from current expenses
  Future<void> refreshSettlement() async {
    if (_currentTripId != null) {
      await computeSettlement(_currentTripId!);
    }
  }

  /// Mark a specific transfer as settled
  ///
  /// Updates the transfer in Firestore, which will trigger real-time update
  Future<void> markTransferAsSettled(String transferId) async {
    if (_currentTripId == null) {
      _log('⚠️ Cannot mark transfer as settled: no current trip');
      return;
    }

    try {
      _log('✅ Marking transfer $transferId as settled');
      await _settlementRepository.markTransferAsSettled(_currentTripId!, transferId);
      _log('✅ Transfer marked as settled');
      // Real-time listener will automatically update the UI
    } catch (e) {
      _log('❌ Error marking transfer as settled: $e');
      if (!isClosed) {
        emit(SettlementError('Failed to mark transfer as settled: ${e.toString()}'));
      }
    }
  }

  /// Smart refresh: only recompute if expenses have changed
  ///
  /// Checks if expenses were modified after settlement was last computed
  /// If yes, recomputes settlement. Otherwise, just reloads existing data.
  /// Always reloads settlement data to ensure UI shows latest state (e.g., settled transfers).
  Future<void> smartRefresh(String tripId) async {
    try {
      _log('🔍 Smart refresh check for trip: $tripId');

      final shouldRecompute = await _settlementRepository.shouldRecompute(tripId);

      if (shouldRecompute) {
        _log('🔄 Expenses changed, recomputing settlement');
        await computeSettlement(tripId);
      } else {
        _log('✅ Settlement is up-to-date, reloading from Firestore');
        // Always reload to get latest data (e.g., settled transfers)
        await loadSettlement(tripId);
      }
    } catch (e) {
      _log('❌ Error in smart refresh: $e');
      if (!isClosed) {
        emit(SettlementError('Failed to refresh settlement: ${e.toString()}'));
      }
    }
  }

  /// Get current trip ID
  String? get currentTripId => _currentTripId;

  @override
  Future<void> close() {
    _log('🔴 Closing SettlementCubit - cancelling subscriptions');
    _summarySubscription?.cancel();
    _transfersSubscription?.cancel();
    return super.close();
  }
}
