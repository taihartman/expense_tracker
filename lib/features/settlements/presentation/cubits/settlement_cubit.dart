import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
          final transfers = await _settlementRepository
              .getMinimalTransfers(tripId)
              .first;

          _log('📦 Received ${transfers.length} minimal transfers');

          if (!isClosed) {
            emit(SettlementLoaded(
              summary: summary,
              transfers: transfers,
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
        (transfers) {
          _log('📦 Transfers updated: ${transfers.length} transfers');
          if (state is SettlementLoaded && !isClosed) {
            final currentState = state as SettlementLoaded;
            emit(currentState.copyWith(transfers: transfers));
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
      final transfers = await _settlementRepository
          .getMinimalTransfers(tripId)
          .first;

      if (!isClosed) {
        emit(SettlementLoaded(
          summary: summary,
          transfers: transfers,
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
