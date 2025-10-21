import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/models/expense.dart';
import '../../domain/repositories/expense_repository.dart';
import 'expense_state.dart';

/// Cubit for managing expense state
class ExpenseCubit extends Cubit<ExpenseState> {
  final ExpenseRepository _expenseRepository;
  String? _currentTripId;

  ExpenseCubit({required ExpenseRepository expenseRepository})
      : _expenseRepository = expenseRepository,
        super(const ExpenseInitial());

  /// Load all expenses for a trip
  Future<void> loadExpenses(String tripId) async {
    try {
      _currentTripId = tripId;
      emit(const ExpenseLoading());

      final expensesStream = _expenseRepository.getExpensesByTrip(tripId);

      await for (final expenses in expensesStream) {
        // Get currently selected expense if any
        Expense? selectedExpense;
        if (state is ExpenseLoaded) {
          selectedExpense = (state as ExpenseLoaded).selectedExpense;

          // Verify selected expense still exists in the list
          if (selectedExpense != null) {
            final stillExists =
                expenses.any((e) => e.id == selectedExpense!.id);
            if (!stillExists) {
              selectedExpense = null;
            }
          }
        }

        emit(ExpenseLoaded(
          expenses: expenses,
          selectedExpense: selectedExpense,
        ));
      }
    } catch (e) {
      emit(ExpenseError('Failed to load expenses: ${e.toString()}'));
    }
  }

  /// Create a new expense
  Future<void> createExpense(Expense expense) async {
    try {
      emit(const ExpenseCreating());

      final createdExpense = await _expenseRepository.createExpense(expense);

      emit(ExpenseCreated(createdExpense));

      // Reload expenses to update the list
      if (_currentTripId != null) {
        await loadExpenses(_currentTripId!);
      }
    } catch (e) {
      emit(ExpenseError('Failed to create expense: ${e.toString()}'));
    }
  }

  /// Update an expense
  Future<void> updateExpense(Expense expense) async {
    try {
      emit(const ExpenseUpdating());

      await _expenseRepository.updateExpense(expense);

      emit(ExpenseUpdated(expense));

      // Reload expenses to update the list
      if (_currentTripId != null) {
        await loadExpenses(_currentTripId!);
      }
    } catch (e) {
      emit(ExpenseError('Failed to update expense: ${e.toString()}'));
    }
  }

  /// Delete an expense
  Future<void> deleteExpense(String expenseId) async {
    try {
      await _expenseRepository.deleteExpense(expenseId);

      // If deleted expense was selected, clear selection
      if (state is ExpenseLoaded) {
        final currentState = state as ExpenseLoaded;
        if (currentState.selectedExpense?.id == expenseId) {
          emit(currentState.copyWith(selectedExpense: null));
        }
      }

      // Reload expenses to update the list
      if (_currentTripId != null) {
        await loadExpenses(_currentTripId!);
      }
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
}
