import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../cubits/expense_cubit.dart';
import '../cubits/expense_state.dart';
import '../widgets/expense_card.dart';
import '../widgets/expense_form_bottom_sheet.dart';
import '../../../../core/theme/app_theme.dart';

/// Page displaying list of expenses for a trip
class ExpenseListPage extends StatelessWidget {
  final String tripId;

  const ExpenseListPage({
    required this.tripId,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expenses'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Trip Settings',
            onPressed: () {
              context.go('/trips/$tripId/settings');
            },
          ),
          IconButton(
            icon: const Icon(Icons.account_balance_wallet),
            tooltip: 'View Settlement',
            onPressed: () {
              context.go('/trips/$tripId/settlement');
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Expense',
            onPressed: () {
              showExpenseFormBottomSheet(
                context: context,
                tripId: tripId,
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<ExpenseCubit, ExpenseState>(
        builder: (context, state) {
          if (state is ExpenseLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (state is ExpenseError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: AppTheme.spacing2),
                  Text(
                    state.message,
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppTheme.spacing2),
                  ElevatedButton(
                    onPressed: () {
                      context.read<ExpenseCubit>().loadExpenses(tripId);
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is ExpenseLoaded) {
            if (state.expenses.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 64,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    const SizedBox(height: AppTheme.spacing2),
                    Text(
                      'No expenses yet',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppTheme.spacing1),
                    Text(
                      'Tap + to add your first expense',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing1),
              itemCount: state.expenses.length,
              itemBuilder: (context, index) {
                final expense = state.expenses[index];
                return ExpenseCard(
                  expense: expense,
                  onTap: () {
                    // Show bottom sheet for editing
                    showExpenseFormBottomSheet(
                      context: context,
                      tripId: tripId,
                      expense: expense,
                    );
                  },
                );
              },
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}
