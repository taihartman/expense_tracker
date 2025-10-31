import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../cubits/expense_cubit.dart';
import '../cubits/expense_state.dart';
import '../cubits/itemized_expense_cubit.dart';
import '../widgets/expense_card.dart';
import '../widgets/expense_form_bottom_sheet.dart';
import '../widgets/fab_speed_dial.dart';
import '../../domain/repositories/expense_repository.dart';
import '../../../trips/presentation/cubits/trip_cubit.dart';
import '../../../trips/presentation/cubits/trip_state.dart';
import '../../../trips/presentation/widgets/trip_verification_prompt.dart';
import '../../../../core/models/participant.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/l10n/l10n_extensions.dart';
import 'itemized/itemized_expense_wizard.dart';
import '../../../../core/services/activity_logger_service.dart';

/// Page displaying list of expenses for a trip
class ExpenseListPage extends StatelessWidget {
  final String tripId;

  const ExpenseListPage({required this.tripId, super.key});

  @override
  Widget build(BuildContext context) {
    // Check if user has verified their identity for this trip
    final tripCubit = context.read<TripCubit>();
    if (!tripCubit.isUserMemberOf(tripId)) {
      return Scaffold(
        appBar: AppBar(title: Text(context.l10n.expenseListTitle)),
        body: TripVerificationPrompt(tripId: tripId),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.expenseListTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: context.l10n.tripSettingsTitle,
            onPressed: () {
              context.push(AppRoutes.tripSettings(tripId));
            },
          ),
          IconButton(
            icon: const Icon(Icons.account_balance_wallet),
            tooltip: context.l10n.settlementViewTooltip,
            onPressed: () {
              context.push(AppRoutes.settlement(tripId));
            },
          ),
        ],
      ),
      floatingActionButton: SizedBox(
        height: 200,
        width: 56,
        child: ExpenseFabSpeedDial(
          tripId: tripId,
          onQuickExpenseTap: () {
            showExpenseFormBottomSheet(context: context, tripId: tripId);
          },
          onReceiptSplitTap: () async {
            // Get trip info and current user
            final tripCubit = context.read<TripCubit>();
            final tripState = tripCubit.state;

            if (tripState is! TripLoaded) return;

            // Find the current trip
            final trip = tripState.trips.firstWhere(
              (t) => t.id == tripId,
              orElse: () => tripState.selectedTrip!,
            );

            // Get current user for this trip
            final currentUser = tripCubit.getCurrentUserForTrip(tripId);

            // Navigate to Receipt Split wizard
            final expenseRepository = context.read<ExpenseRepository>();
            final activityLoggerService = context.read<ActivityLoggerService>();
            await Navigator.of(context).push<bool>(
              MaterialPageRoute(
                builder: (context) => BlocProvider(
                  create: (context) => ItemizedExpenseCubit(
                    expenseRepository: expenseRepository,
                    activityLoggerService: activityLoggerService,
                  ),
                  child: ItemizedExpenseWizard(
                    tripId: tripId,
                    participants: trip.participants.map((p) => p.id).toList(),
                    participantNames: {
                      for (var p in trip.participants) p.id: p.name,
                    },
                    initialPayerUserId:
                        currentUser?.id ?? trip.participants.first.id,
                    currency: trip.baseCurrency,
                  ),
                ),
              ),
            );
          },
        ),
      ),
      body: BlocBuilder<ExpenseCubit, ExpenseState>(
        buildWhen: (previous, current) {
          // Only rebuild for states that affect the list display
          // Prevents rebuilds for transient states like ExpenseCreated, ExpenseUpdated
          return current is ExpenseLoading ||
              current is ExpenseError ||
              current is ExpenseLoaded;
        },
        builder: (context, state) {
          if (state is ExpenseLoading) {
            return const Center(child: CircularProgressIndicator());
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
                    child: Text(context.l10n.commonRetry),
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
                      context.l10n.expenseEmptyStateTitle,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppTheme.spacing1),
                    Text(
                      context.l10n.expenseEmptyStateDescription,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              );
            }

            return BlocBuilder<TripCubit, TripState>(
              builder: (context, tripState) {
                // Get trip participants
                final List<Participant> participants = tripState is TripLoaded
                    ? tripState.trips
                          .firstWhere(
                            (t) => t.id == tripId,
                            orElse: () => tripState.selectedTrip!,
                          )
                          .participants
                    : <Participant>[];

                return ListView.builder(
                  padding: const EdgeInsets.only(
                    top: AppTheme.spacing1,
                    bottom: 80, // 80dp clearance for FAB Speed Dial
                  ),
                  itemCount: state.expenses.length,
                  itemBuilder: (context, index) {
                    final expense = state.expenses[index];
                    return ExpenseCard(
                      key: ValueKey(expense.id),
                      expense: expense,
                      participants: participants,
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
              },
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}
