import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubits/expense_cubit.dart';
import '../cubits/expense_state.dart';
import '../widgets/expense_card.dart';
import 'expense_form_page.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../../trips/presentation/cubits/trip_cubit.dart';
import '../../../trips/presentation/cubits/trip_state.dart';

/// Page displaying a list of expenses for the selected trip
class ExpenseListPage extends StatefulWidget {
  const ExpenseListPage({super.key});

  @override
  State<ExpenseListPage> createState() => _ExpenseListPageState();
}

class _ExpenseListPageState extends State<ExpenseListPage> {
  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  void _loadExpenses() {
    final tripCubit = context.read<TripCubit>();
    final selectedTrip = tripCubit.selectedTrip;

    if (selectedTrip != null) {
      context.read<ExpenseCubit>().loadExpenses(selectedTrip.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expenses'),
      ),
      body: BlocConsumer<ExpenseCubit, ExpenseState>(
        listener: (context, state) {
          if (state is ExpenseError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: theme.colorScheme.error,
              ),
            );
          } else if (state is ExpenseCreated) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Expense created successfully')),
            );
          }
        },
        builder: (context, state) {
          if (state is ExpenseLoading) {
            return const Center(child: LoadingIndicator());
          }

          if (state is ExpenseLoaded) {
            final expenses = state.expenses;

            if (expenses.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.receipt_long,
                      size: 64,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: AppTheme.spacing2),
                    Text(
                      'No expenses yet',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacing1),
                    Text(
                      'Tap the + button to add an expense',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing2),
              itemCount: expenses.length,
              itemBuilder: (context, index) {
                final expense = expenses[index];
                return ExpenseCard(
                  expense: expense,
                  onTap: () {
                    _navigateToExpenseForm(expense.tripId, expense: expense);
                  },
                );
              },
            );
          }

          // Initial state - show empty view
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 64,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: AppTheme.spacing2),
                Text(
                  'Select a trip to view expenses',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: BlocBuilder<TripCubit, TripState>(
        builder: (context, tripState) {
          // Only show FAB if a trip is selected
          final selectedTrip = context.read<TripCubit>().selectedTrip;

          if (selectedTrip == null) {
            return const SizedBox.shrink();
          }

          return FloatingActionButton(
            onPressed: () {
              _navigateToExpenseForm(selectedTrip.id);
            },
            child: const Icon(Icons.add),
          );
        },
      ),
    );
  }

  void _navigateToExpenseForm(String tripId, {expense}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ExpenseFormPage(
          tripId: tripId,
          expense: expense,
        ),
      ),
    );
  }
}
