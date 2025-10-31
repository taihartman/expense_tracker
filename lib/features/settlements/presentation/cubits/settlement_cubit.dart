import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rxdart/rxdart.dart';
import '../../../../core/services/activity_logger_service.dart';
import '../../domain/models/minimal_transfer.dart';
import '../../domain/models/category_spending.dart';
import '../../domain/models/settlement_summary.dart';
import '../../domain/repositories/settlement_repository.dart';
import '../../domain/repositories/settled_transfer_repository.dart';
import '../../domain/services/settlement_calculator.dart';
import 'settlement_state.dart';
import '../../../expenses/domain/repositories/expense_repository.dart';
import '../../../categories/domain/repositories/category_repository.dart';
import '../../../categories/domain/models/category.dart' as cat;
import '../../../trips/domain/repositories/trip_repository.dart';
import '../../../trips/domain/models/trip.dart';

/// Helper function to log with timestamps (only in debug mode)
void _log(String message) {
  if (kDebugMode) {
    debugPrint(
      '[${DateTime.now().toIso8601String()}] [SettlementCubit] $message',
    );
  }
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

  // Cache for performance optimization
  Trip? _cachedTrip;
  List<cat.Category>? _cachedCategories;
  DateTime? _cachedLastComputedAt;

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

  /// Fast in-memory check if settlement needs recomputation
  ///
  /// Returns true if:
  /// - First load (no cached timestamps)
  /// - Expenses modified after last settlement computation
  bool _shouldRecomputeInMemory() {
    // First load - must compute
    if (_cachedLastComputedAt == null) {
      _log('⚡ First load - must compute settlement');
      return true;
    }

    // No expense modifications tracked - assume need to recompute
    if (_cachedTrip?.lastExpenseModifiedAt == null) {
      _log('⚡ No expense modification timestamp - recomputing');
      return true;
    }

    // Check if expenses modified after last computation
    final expensesChanged = _cachedTrip!.lastExpenseModifiedAt!.isAfter(
      _cachedLastComputedAt!,
    );

    if (expensesChanged) {
      _log(
        '⚡ Expenses modified (${_cachedTrip!.lastExpenseModifiedAt}) after last computation ($_cachedLastComputedAt)',
      );
    } else {
      _log(
        '⚡ No expense changes detected (last modified: ${_cachedTrip!.lastExpenseModifiedAt}, last computed: $_cachedLastComputedAt)',
      );
    }

    return expensesChanged;
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

      // Parallelize initial data fetching for faster load
      await Future.wait([
        _tripRepository.getTripById(tripId).then((t) => _cachedTrip = t),
        _expenseRepository.getExpensesByTrip(tripId).first,
        _settledTransferRepository.getSettledTransfers(tripId).first,
        _categoryRepository
            .searchCategories('')
            .first
            .then((c) {
              _cachedCategories = c;
              _log('📂 Cached ${c.length} categories for category spending');
            })
            .catchError((e) {
              _log(
                '⚠️ Failed to load categories: $e (continuing without category spending)',
              );
              _cachedCategories = [];
            }),
      ]);

      if (_cachedTrip == null) {
        throw Exception('Trip not found: $tripId');
      }

      _log(
        '📍 Trip: ${_cachedTrip!.name}, Base Currency: ${_cachedTrip!.baseCurrency.code}',
      );
      _log(
        '⚡ Parallel fetch complete - trip, expenses, settled transfers, and ${_cachedCategories?.length ?? 0} categories loaded',
      );

      // Now subscribe to streams for real-time updates
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
                // Fast in-memory check if we need to recompute
                final shouldRecompute = _shouldRecomputeInMemory();

                SettlementSummary summary;
                List<MinimalTransfer> calculatedTransfers;

                if (shouldRecompute) {
                  _log(
                    '🔄 Recomputing settlement (expenses changed or first load)',
                  );
                  _log('⚡ Using expenses from stream - no re-fetch!');
                  summary = await _settlementRepository.computeSettlementWithExpenses(
                    tripId,
                    data.expenses,
                  );

                  // Cache timestamps for future comparisons
                  _cachedLastComputedAt = summary.lastComputedAt;

                  // Get calculated transfers
                  calculatedTransfers = await _settlementRepository
                      .getMinimalTransfers(tripId)
                      .first;

                  _log(
                    '✅ Settlement recomputed: ${summary.personSummaries.length} people',
                  );
                } else {
                  _log('⚡ Using cached settlement (no changes detected)');
                  final cachedSummary = await _settlementRepository
                      .getSettlementSummary(tripId);

                  if (cachedSummary == null) {
                    // No cache exists, must compute
                    _log('⚠️ No cached settlement found, computing...');
                    _log('⚡ Using expenses from stream - no re-fetch!');
                    summary = await _settlementRepository.computeSettlementWithExpenses(
                      tripId,
                      data.expenses,
                    );
                    _cachedLastComputedAt = summary.lastComputedAt;
                  } else {
                    summary = cachedSummary;
                  }

                  // Always fetch fresh transfers (they change when marked as settled)
                  calculatedTransfers = await _settlementRepository
                      .getMinimalTransfers(tripId)
                      .first;

                  _log(
                    '✅ Using cached settlement: ${summary.personSummaries.length} people',
                  );
                }

                // Separate active from settled
                final separated = _separateTransfers(
                  calculatedTransfers,
                  data.settled,
                );
                _log(
                  '📊 ${separated.active.length} active, ${separated.settled.length} settled',
                );

                // Calculate category spending using single-pass optimization
                // This reuses the expense iteration that already happened in person summary calc
                Map<String, PersonCategorySpending>? categorySpending;
                try {
                  // Use cached categories if available
                  if (_cachedCategories != null && _cachedTrip != null) {
                    // Use optimized single-pass calculation
                    // Note: Person summaries already calculated in repository,
                    // but we need category spending which is UI-only
                    final result = _settlementCalculator
                        .calculateSettlementData(
                          expenses: data.expenses,
                          baseCurrency: _cachedTrip!.baseCurrency,
                          categories: _cachedCategories,
                        );
                    categorySpending = result.categorySpending;
                    _log(
                      '✅ Category spending calculated (single-pass): ${categorySpending?.length ?? 0} people',
                    );
                  }
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

  /// Set user filter for transfers
  ///
  /// Filters transfers to show only those involving the specified user.
  /// [userId] - The ID of the user to filter by
  /// [filterMode] - Whether to show all transfers, only what they owe, or only what they're owed
  void setUserFilter(String userId, TransferFilterMode filterMode) {
    final currentState = state;
    if (currentState is SettlementLoaded) {
      _log('🔍 Setting user filter: $userId, mode: $filterMode');
      emit(
        currentState.copyWith(selectedUserId: userId, filterMode: filterMode),
      );
    }
  }

  /// Clear the user filter
  void clearUserFilter() {
    final currentState = state;
    if (currentState is SettlementLoaded) {
      _log('🔍 Clearing user filter');
      emit(currentState.copyWith(clearFilter: true));
    }
  }

  /// Update filter mode without changing selected user
  void setFilterMode(TransferFilterMode filterMode) {
    final currentState = state;
    if (currentState is SettlementLoaded &&
        currentState.selectedUserId != null) {
      _log('🔍 Updating filter mode: $filterMode');
      emit(currentState.copyWith(filterMode: filterMode));
    }
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
