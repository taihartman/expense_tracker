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
import '../../../categories/presentation/cubit/category_cubit.dart';
import '../../../../core/models/participant.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/l10n/l10n_extensions.dart';
import 'itemized/itemized_expense_wizard.dart';
import '../../../../core/services/activity_logger_service.dart';

/// Page displaying list of expenses for a trip
class ExpenseListPage extends StatefulWidget {
  final String tripId;

  const ExpenseListPage({required this.tripId, super.key});

  @override
  State<ExpenseListPage> createState() => _ExpenseListPageState();
}

class _ExpenseListPageState extends State<ExpenseListPage> {
  @override
  void initState() {
    super.initState();
    // Load top categories for expense cards to display icons
    context.read<CategoryCubit>().loadTopCategories(limit: 10);
  }

  @override
  Widget build(BuildContext context) {
    // Check if user has verified their identity for this trip
    final tripCubit = context.read<TripCubit>();
    if (!tripCubit.isUserMemberOf(widget.tripId)) {
      return Scaffold(
        appBar: AppBar(title: Text(context.l10n.expenseListTitle)),
        body: TripVerificationPrompt(tripId: widget.tripId),
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
              context.push(AppRoutes.tripSettings(widget.tripId));
            },
          ),
          IconButton(
            icon: const Icon(Icons.account_balance_wallet),
            tooltip: context.l10n.settlementViewTooltip,
            onPressed: () {
              context.push(AppRoutes.settlement(widget.tripId));
            },
          ),
        ],
      ),
      floatingActionButton: SizedBox(
        height: 200,
        width: 56,
        child: ExpenseFabSpeedDial(
          tripId: widget.tripId,
          onQuickExpenseTap: () {
            showExpenseFormBottomSheet(context: context, tripId: widget.tripId);
          },
          onReceiptSplitTap: () async {
            // Get trip info and current user
            final tripCubit = context.read<TripCubit>();
            final tripState = tripCubit.state;

            if (tripState is! TripLoaded) return;

            // Find the current trip
            final trip = tripState.trips.firstWhere(
              (t) => t.id == widget.tripId,
              orElse: () => tripState.selectedTrip!,
            );

            // Get current user for this trip
            final currentUser = tripCubit.getCurrentUserForTrip(widget.tripId);

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
                    tripId: widget.tripId,
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
      body: BlocListener<ExpenseCubit, ExpenseState>(
        listener: (context, state) {
          // Pre-load categories when expenses are loaded
          if (state is ExpenseLoaded && state.expenses.isNotEmpty) {
            // Extract unique category IDs from all expenses
            final categoryIds = state.expenses
                .where((expense) => expense.categoryId != null)
                .map((expense) => expense.categoryId!)
                .toSet()
                .toList();

            // Batch load all categories for faster icon display
            if (categoryIds.isNotEmpty) {
              context.read<CategoryCubit>().loadCategoriesByIds(categoryIds);
            }
          }

          // Invalidate category cache when expense is created/updated with a category
          // This ensures usage counts are up-to-date in the UI
          if (state is ExpenseCreated && state.expense.categoryId != null) {
            context.read<CategoryCubit>().invalidateTopCategoriesCache();
          } else if (state is ExpenseUpdated &&
              state.expense.categoryId != null) {
            context.read<CategoryCubit>().invalidateTopCategoriesCache();
          }
        },
        child: BlocBuilder<ExpenseCubit, ExpenseState>(
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
                        context.read<ExpenseCubit>().loadExpenses(
                          widget.tripId,
                        );
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
                              (t) => t.id == widget.tripId,
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
                            tripId: widget.tripId,
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
      ),
    );
  }
}
