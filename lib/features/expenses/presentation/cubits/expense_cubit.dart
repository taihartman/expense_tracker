import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/activity_logger_service.dart';
import '../../domain/models/expense.dart';
import '../../domain/repositories/expense_repository.dart';
import 'expense_state.dart';

/// Helper function to log with timestamps
void _log(String message) {
  debugPrint('[${DateTime.now().toIso8601String()}] [ExpenseCubit] $message');
}

/// Cubit for managing expense state
class ExpenseCubit extends Cubit<ExpenseState> {
  final ExpenseRepository _expenseRepository;
  final ActivityLoggerService? _activityLoggerService;
  String? _currentTripId;
  StreamSubscription<List<Expense>>? _expensesSubscription;

  ExpenseCubit({
    required ExpenseRepository expenseRepository,
    ActivityLoggerService? activityLoggerService,
  }) : _expenseRepository = expenseRepository,
       _activityLoggerService = activityLoggerService,
       super(const ExpenseInitial());

  /// Load all expenses for a trip
  /// Only recreates the stream subscription when switching to a different trip
  Future<void> loadExpenses(String tripId) async {
    try {
      _log('📥 loadExpenses() started for tripId: $tripId');
      final loadStart = DateTime.now();

      // Only recreate stream if switching to a different trip
      if (_currentTripId == tripId && _expensesSubscription != null) {
        _log(
          '⏭️ Already listening to trip $tripId, skipping stream recreation',
        );
        return;
      }

      _currentTripId = tripId;

      // Cancel existing subscription only when switching trips
      await _expensesSubscription?.cancel();
      _log('🔄 Switching trips - cancelled old subscription');

      emit(const ExpenseLoading());
      _log('✅ Emitted ExpenseLoading state');

      _log('🔍 Calling repository.getExpensesByTrip()...');
      final repoStart = DateTime.now();
      final expensesStream = _expenseRepository.getExpensesByTrip(tripId);
      _log(
        '✅ Got expenses stream (${DateTime.now().difference(repoStart).inMilliseconds}ms)',
      );

      _log('⏳ Waiting for first stream emission...');
      final streamStart = DateTime.now();

      // Use listen instead of await for to properly manage subscription
      _expensesSubscription = expensesStream.listen(
        (expenses) {
          _log(
            '📦 Received ${expenses.length} expenses from stream (${DateTime.now().difference(streamStart).inMilliseconds}ms)',
          );

          // Only emit if cubit is not closed
          if (!isClosed) {
            // Get currently selected expense if any
            Expense? selectedExpense;
            if (state is ExpenseLoaded) {
              selectedExpense = (state as ExpenseLoaded).selectedExpense;

              // Verify selected expense still exists in the list
              if (selectedExpense != null) {
                final stillExists = expenses.any(
                  (e) => e.id == selectedExpense!.id,
                );
                if (!stillExists) {
                  selectedExpense = null;
                }
              }
            }

            emit(
              ExpenseLoaded(
                expenses: expenses,
                selectedExpense: selectedExpense,
              ),
            );
            _log(
              '✅ Emitted ExpenseLoaded state (total time: ${DateTime.now().difference(loadStart).inMilliseconds}ms)',
            );
          } else {
            _log('⚠️ Cubit closed, skipping emit');
          }
        },
        onError: (error) {
          _log('❌ Stream error: $error');
          if (!isClosed) {
            emit(ExpenseError('Failed to load expenses: ${error.toString()}'));
          }
        },
      );
    } catch (e) {
      _log('❌ Error loading expenses: $e');
      if (!isClosed) {
        emit(ExpenseError('Failed to load expenses: ${e.toString()}'));
      }
    }
  }

  /// Create a new expense
  ///
  /// [actorName] is the name of the user performing this action (current user),
  /// not the payer of the expense. Used for activity logging.
  Future<void> createExpense(Expense expense, {String? actorName}) async {
    try {
      // Don't emit loading state - let Firestore stream handle updates smoothly
      final createdExpense = await _expenseRepository.createExpense(expense);

      emit(ExpenseCreated(createdExpense));

      // Log activity using centralized service
      if (_activityLoggerService != null &&
          actorName != null &&
          actorName.isNotEmpty) {
        _log('📝 Logging expense creation via ActivityLoggerService...');
        await _activityLoggerService.logExpenseAdded(createdExpense, actorName);
        _log('✅ Activity logged');
      }

      // No need to reload - Firestore stream will automatically update
    } catch (e) {
      emit(ExpenseError('Failed to create expense: ${e.toString()}'));
    }
  }

  /// Update an expense
  ///
  /// [actorName] is the name of the user performing this action (current user),
  /// not the payer of the expense. Used for activity logging.
  Future<void> updateExpense(Expense expense, {String? actorName}) async {
    try {
      // Fetch old expense for change detection (before updating)
      Expense? oldExpense;
      if (state is ExpenseLoaded) {
        final currentState = state as ExpenseLoaded;
        oldExpense = currentState.expenses.firstWhere(
          (e) => e.id == expense.id,
          orElse: () => throw Exception('Expense not found'),
        );
      }

      // Don't emit loading state - let Firestore stream handle updates smoothly
      await _expenseRepository.updateExpense(expense);

      // Don't emit ExpenseUpdated - let Firestore stream handle the update
      // This prevents the buildWhen filter from blocking UI updates on mobile

      // Log activity using centralized service
      if (_activityLoggerService != null &&
          actorName != null &&
          actorName.isNotEmpty &&
          oldExpense != null) {
        _log('📝 Logging expense edit via ActivityLoggerService...');
        await _activityLoggerService.logExpenseEdited(
          oldExpense,
          expense,
          actorName,
        );
        _log('✅ Activity logged');
      }

      // No need to reload - Firestore stream will automatically update
    } catch (e) {
      emit(ExpenseError('Failed to update expense: ${e.toString()}'));
    }
  }

  /// Delete an expense
  ///
  /// [actorName] is the name of the user performing this action (current user),
  /// not the payer of the expense. Used for activity logging.
  Future<void> deleteExpense(String expenseId, {String? actorName}) async {
    try {
      // Find the expense to get details before deleting (for activity log)
      Expense? expenseToDelete;
      if (state is ExpenseLoaded) {
        final currentState = state as ExpenseLoaded;
        expenseToDelete = currentState.expenses.firstWhere(
          (e) => e.id == expenseId,
          orElse: () => throw Exception('Expense not found'),
        );
      }

      await _expenseRepository.deleteExpense(expenseId);

      // Log activity using centralized service
      if (_activityLoggerService != null &&
          actorName != null &&
          actorName.isNotEmpty &&
          expenseToDelete != null) {
        _log('📝 Logging expense deletion via ActivityLoggerService...');
        await _activityLoggerService.logExpenseDeleted(
          expenseToDelete,
          actorName,
        );
        _log('✅ Activity logged');
      }

      // If deleted expense was selected, clear selection
      // Note: The stream will automatically update the expenses list,
      // and the listener in loadExpenses() will verify if selected expense still exists
      if (state is ExpenseLoaded) {
        final currentState = state as ExpenseLoaded;
        if (currentState.selectedExpense?.id == expenseId) {
          emit(currentState.copyWith(selectedExpense: null));
        }
      }

      // No need to reload - Firestore stream will automatically update
    } catch (e) {
      emit(ExpenseError('Failed to delete expense: ${e.toString()}'));
    }
  }

  /// Select an expense
  void selectExpense(Expense expense) {
    if (state is ExpenseLoaded) {
      final currentState = state as ExpenseLoaded;
      emit(currentState.copyWith(selectedExpense: expense));
    }
  }

  /// Get the currently selected expense
  Expense? get selectedExpense {
    if (state is ExpenseLoaded) {
      return (state as ExpenseLoaded).selectedExpense;
    }
    return null;
  }

  /// Get all expenses
  List<Expense> get expenses {
    if (state is ExpenseLoaded) {
      return (state as ExpenseLoaded).expenses;
    }
    return [];
  }

  @override
  Future<void> close() {
    _log('🔴 Closing ExpenseCubit - cancelling stream subscription');
    _expensesSubscription?.cancel();
    return super.close();
  }
}
