import 'package:equatable/equatable.dart';
import '../../domain/models/expense.dart';

/// Base state for ExpenseCubit
abstract class ExpenseState extends Equatable {
  const ExpenseState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class ExpenseInitial extends ExpenseState {
  const ExpenseInitial();
}

/// Loading state
class ExpenseLoading extends ExpenseState {
  const ExpenseLoading();
}

/// Loaded state with list of expenses
class ExpenseLoaded extends ExpenseState {
  final List<Expense> expenses;
  final Expense? selectedExpense;

  const ExpenseLoaded({required this.expenses, this.selectedExpense});

  @override
  List<Object?> get props => [identityHashCode(expenses), selectedExpense];

  ExpenseLoaded copyWith({List<Expense>? expenses, Expense? selectedExpense}) {
    return ExpenseLoaded(
      expenses: expenses ?? this.expenses,
      selectedExpense: selectedExpense ?? this.selectedExpense,
    );
  }
}

/// Creating expense state
class ExpenseCreating extends ExpenseState {
  const ExpenseCreating();
}

/// Expense created successfully
class ExpenseCreated extends ExpenseState {
  final Expense expense;

  const ExpenseCreated(this.expense);

  @override
  List<Object?> get props => [expense];
}

/// Updating expense state
class ExpenseUpdating extends ExpenseState {
  const ExpenseUpdating();
}

/// Expense updated successfully
class ExpenseUpdated extends ExpenseState {
  final Expense expense;

  const ExpenseUpdated(this.expense);

  @override
  List<Object?> get props => [expense];
}

/// Error state
class ExpenseError extends ExpenseState {
  final String message;

  const ExpenseError(this.message);

  @override
  List<Object?> get props => [message];
}
