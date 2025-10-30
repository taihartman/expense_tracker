import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rxdart/rxdart.dart';
import '../../../../core/services/activity_logger_service.dart';
import '../../domain/models/minimal_transfer.dart';
import '../../domain/models/category_spending.dart';
import '../../domain/repositories/settlement_repository.dart';
import '../../domain/repositories/settled_transfer_repository.dart';
import '../../domain/services/settlement_calculator.dart';
import 'settlement_state.dart';
import '../../../expenses/domain/repositories/expense_repository.dart';
import '../../../categories/domain/repositories/category_repository.dart';
import '../../../trips/domain/repositories/trip_repository.dart';

/// Helper function to log with timestamps
void _log(String message) {
  debugPrint(
    '[${DateTime.now().toIso8601String()}] [SettlementCubit] $message',
  );
}

/// Settlement Cubit using Pure Derived State Pattern
///
/// Key Principles:
/// 1. Settlements are DERIVED from expenses (not stored separately)
/// 2. Calculate on-demand whenever expenses change
/// 3. Only store "settled transfer" history in Firestore
/// 4. Always accurate, no staleness issues
///
/// This is a SIMPLIFIED version that replaces the complex 368-line implementation
/// with a clean 150-line approach that's easier to maintain and debug.
class SettlementCubit extends Cubit<SettlementState> {
  final SettlementRepository _settlementRepository;
  final ExpenseRepository _expenseRepository;
  final TripRepository _tripRepository;
  final SettledTransferRepository _settledTransferRepository;
  final CategoryRepository _categoryRepository;
  final SettlementCalculator _settlementCalculator;
  final ActivityLoggerService? _activityLoggerService;

  StreamSubscription? _combinedSubscription;
  String? _currentTripId;

  SettlementCubit({
    required SettlementRepository settlementRepository,
    required ExpenseRepository expenseRepository,
    required TripRepository tripRepository,
    required SettledTransferRepository settledTransferRepository,
    required CategoryRepository categoryRepository,
    SettlementCalculator? settlementCalculator,
    ActivityLoggerService? activityLoggerService,
  }) : _settlementRepository = settlementRepository,
       _expenseRepository = expenseRepository,
       _tripRepository = tripRepository,
       _settledTransferRepository = settledTransferRepository,
       _categoryRepository = categoryRepository,
       _settlementCalculator = settlementCalculator ?? SettlementCalculator(),
       _activityLoggerService = activityLoggerService,
       super(const SettlementInitial());

  /// Separate transfers into active and settled lists
  ({List<MinimalTransfer> active, List<MinimalTransfer> settled})
  _separateTransfers(
    List<MinimalTransfer> calculatedTransfers,
    List<MinimalTransfer> settledTransfers,
  ) {
    final active = <MinimalTransfer>[];

    for (final transfer in calculatedTransfers) {
      // Check if this transfer matches any settled transfer
      final isSettled = settledTransfers.any(
        (settled) =>
            settled.fromUserId == transfer.fromUserId &&
            settled.toUserId == transfer.toUserId,
      );

      if (!isSettled) {
        active.add(transfer);
      }
    }

    return (active: active, settled: settledTransfers);
  }

  /// Load settlement by calculating from current expenses
  ///
  /// Subscribes to both expense stream and settled transfer stream,
  /// recalculating whenever either changes.
  Future<void> loadSettlement(String tripId) async {
    try {
      _log('📥 Loading settlement for trip: $tripId');
      _currentTripId = tripId;

      await _combinedSubscription?.cancel();
      emit(const SettlementLoading());

      // Get trip for base currency
      final trip = await _tripRepository.getTripById(tripId);
      if (trip == null) {
        throw Exception('Trip not found: $tripId');
      }

      _log('📍 Trip: ${trip.name}, Base Currency: ${trip.baseCurrency.code}');

      // Combine expense stream with settled transfer stream
      // Recalculate whenever EITHER changes
      _combinedSubscription =
          CombineLatestStream.combine2(
            _expenseRepository.getExpensesByTrip(tripId),
            _settledTransferRepository.getSettledTransfers(tripId),
            (expenses, settledTransfers) =>
                (expenses: expenses, settled: settledTransfers),
          ).listen(
            (data) async {
              _log(
                '📦 Received ${data.expenses.length} expenses, ${data.settled.length} settled transfers',
              );

              try {
                // Calculate settlement from current expenses
                final summary = await _settlementRepository.computeSettlement(
                  tripId,
                );

                _log(
                  '✅ Settlement calculated: ${summary.personSummaries.length} people',
                );

                // Get calculated transfers
                final calculatedTransfers = await _settlementRepository
                    .getMinimalTransfers(tripId)
                    .first;

                // Separate active from settled
                final separated = _separateTransfers(
                  calculatedTransfers,
                  data.settled,
                );
                _log(
                  '📊 ${separated.active.length} active, ${separated.settled.length} settled',
                );

                // Calculate category spending breakdown
                Map<String, PersonCategorySpending>? categorySpending;
                try {
                  final categories = await _categoryRepository
                      .getCategoriesByTrip(tripId)
                      .first;
                  categorySpending = _settlementCalculator
                      .calculatePersonCategorySpending(
                        expenses: data.expenses,
                        categories: categories,
                        baseCurrency: trip.baseCurrency,
                      );
                  _log(
                    '✅ Category spending calculated for ${categorySpending.length} people',
                  );
                } catch (e) {
                  _log('⚠️ Failed to calculate category spending: $e');
                  // Continue without category spending if it fails
                }

                if (!isClosed) {
                  emit(
                    SettlementLoaded(
                      summary: summary,
                      activeTransfers: separated.active,
                      settledTransfers: separated.settled,
                      personCategorySpending: categorySpending,
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
              _log('❌ Error in combined stream: $error');
              if (!isClosed) {
                emit(
                  SettlementError('Failed to load data: ${error.toString()}'),
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
  /// Mark a transfer as settled
  ///
  /// [actorName] is the name of the user performing this action (current user).
  /// Used for activity logging.
  Future<void> markTransferAsSettled(
    String transferId, {
    String? actorName,
  }) async {
    if (_currentTripId == null) {
      _log('⚠️ Cannot mark transfer as settled: no current trip');
      return;
    }

    try {
      final currentState = state;
      if (currentState is! SettlementLoaded) {
        _log('⚠️ Cannot mark transfer as settled: settlement not loaded');
        return;
      }

      // Find the transfer to settle
      final transfer = currentState.activeTransfers.firstWhere(
        (t) => t.id == transferId,
        orElse: () => throw Exception('Transfer not found'),
      );

      _log(
        '✅ Marking transfer as settled: ${transfer.fromUserId} → ${transfer.toUserId} (${transfer.amountBase})',
      );

      await _settledTransferRepository.markTransferAsSettled(
        _currentTripId!,
        transfer.fromUserId,
        transfer.toUserId,
        transfer.amountBase.toString(),
      );

      _log('✅ Transfer marked as settled');

      // Log activity using centralized service
      if (_activityLoggerService != null &&
          actorName != null &&
          actorName.isNotEmpty) {
        _log('📝 Logging transfer settled via ActivityLoggerService...');
        await _activityLoggerService.logTransferSettled(transfer, actorName);
        _log('✅ Activity logged');
      }

      // The combined stream will automatically recalculate and update UI
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

  /// Compute/refresh settlement (for manual refresh button)
  Future<void> computeSettlement(String tripId) async {
    _log('🔄 Manual refresh requested');
    // Just reload - the stream will recalculate automatically
    await loadSettlement(tripId);
  }

  /// Refresh settlement (alias for computeSettlement)
  Future<void> refreshSettlement() async {
    if (_currentTripId != null) {
      await computeSettlement(_currentTripId!);
    }
  }

  /// Smart refresh (simplified - just reload)
  Future<void> smartRefresh(String tripId) async {
    await loadSettlement(tripId);
  }

  /// Get current trip ID
  String? get currentTripId => _currentTripId;

  @override
  Future<void> close() {
    _log('🔴 Closing SettlementCubit');
    _combinedSubscription?.cancel();
    return super.close();
  }
}
