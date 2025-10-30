import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubits/settlement_cubit.dart';
import '../cubits/settlement_state.dart';
import '../widgets/all_people_summary_table.dart';
import '../widgets/minimal_transfers_view.dart';
import '../widgets/person_dashboard_card.dart';
import '../../../trips/presentation/cubits/trip_cubit.dart';
import '../../../trips/presentation/cubits/trip_state.dart';
import '../../../trips/presentation/widgets/trip_verification_prompt.dart';
import '../../../expenses/domain/repositories/expense_repository.dart';
import '../../../../core/models/participant.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/l10n/l10n_extensions.dart';

/// Page displaying settlement summary with transfers
///
/// Shows person summaries and minimal transfers calculated from expenses
class SettlementSummaryPage extends StatefulWidget {
  final String tripId;

  const SettlementSummaryPage({super.key, required this.tripId});

  @override
  State<SettlementSummaryPage> createState() => _SettlementSummaryPageState();
}

class _SettlementSummaryPageState extends State<SettlementSummaryPage> {
  @override
  void initState() {
    super.initState();
    // Smart refresh settlement when page initializes
    // This will only recompute if expenses have changed since last settlement
    Future.microtask(() {
      if (mounted) {
        context.read<SettlementCubit>().smartRefresh(widget.tripId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Check if user has verified their identity for this trip
    final tripCubit = context.read<TripCubit>();
    if (!tripCubit.isUserMemberOf(widget.tripId)) {
      return Scaffold(
        appBar: AppBar(title: Text(context.l10n.settlementTitle)),
        body: TripVerificationPrompt(tripId: widget.tripId),
      );
    }

    // Capture repository here where providers are accessible
    final expenseRepository = context.read<ExpenseRepository>();

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.settlementTitle),
        actions: [
          BlocBuilder<SettlementCubit, SettlementState>(
            builder: (context, state) {
              if (state is SettlementLoaded) {
                return IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: context.l10n.settlementRecomputeTooltip,
                  onPressed: () {
                    context.read<SettlementCubit>().computeSettlement(
                      widget.tripId,
                    );
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: BlocBuilder<SettlementCubit, SettlementState>(
        builder: (context, state) {
          if (state is SettlementLoading || state is SettlementComputing) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: AppTheme.spacing2),
                  Text(
                    state is SettlementComputing
                        ? context.l10n.settlementComputing
                        : context.l10n.settlementLoading,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            );
          }

          if (state is SettlementError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: AppTheme.spacing2),
                  Text('Error', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: AppTheme.spacing1),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacing3,
                    ),
                    child: Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacing3),
                  ElevatedButton.icon(
                    onPressed: () {
                      context.read<SettlementCubit>().loadSettlement(
                        widget.tripId,
                      );
                    },
                    icon: const Icon(Icons.refresh),
                    label: Text(context.l10n.commonRetry),
                  ),
                ],
              ),
            );
          }

          if (state is SettlementLoaded) {
            return BlocBuilder<TripCubit, TripState>(
              builder: (context, tripState) {
                // Get trip participants
                final participants = tripState is TripLoaded
                    ? tripState.trips
                          .firstWhere(
                            (t) => t.id == widget.tripId,
                            orElse: () => tripState.selectedTrip!,
                          )
                          .participants
                    : <Participant>[];

                return RefreshIndicator(
                  onRefresh: () async {
                    await context.read<SettlementCubit>().computeSettlement(
                      widget.tripId,
                    );
                  },
                  child: ListView(
                    padding: const EdgeInsets.all(AppTheme.spacing2),
                    children: [
                      // Last computed timestamp
                      Card(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                        child: Padding(
                          padding: const EdgeInsets.all(AppTheme.spacing2),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 20,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: AppTheme.spacing1),
                              Text(
                                context.l10n.settlementLastUpdated(
                                  _formatTimestamp(
                                    state.summary.lastComputedAt,
                                  ),
                                ),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacing2),

                      // Summary table
                      AllPeopleSummaryTable(
                        activeTransfers: state.activeTransfers,
                        baseCurrency: state.summary.baseCurrency,
                        participants: participants,
                      ),
                      const SizedBox(height: AppTheme.spacing3),

                      // Minimal transfers
                      MinimalTransfersView(
                        tripId: widget.tripId,
                        activeTransfers: state.activeTransfers,
                        settledTransfers: state.settledTransfers,
                        baseCurrency: state.summary.baseCurrency,
                        participants: participants,
                        expenseRepository: expenseRepository,
                      ),
                      const SizedBox(height: AppTheme.spacing3),

                      // Individual Dashboards (if category spending available)
                      if (state.personCategorySpending != null &&
                          state.personCategorySpending!.isNotEmpty) ...[
                        Text(
                          'Individual Dashboards',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: AppTheme.spacing2),
                        // Build dashboard cards
                        ...state.personCategorySpending!.entries.map((entry) {
                          final userId = entry.key;
                          final personSpending = entry.value;

                          // Find participant
                          try {
                            final participant = participants.firstWhere(
                              (p) => p.id == userId,
                            );

                            return Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppTheme.spacing2,
                              ),
                              child: PersonDashboardCard(
                                person: personSpending,
                                participant: participant,
                                baseCurrency: state.summary.baseCurrency,
                              ),
                            );
                          } catch (e) {
                            // Skip if participant not found
                            return const SizedBox.shrink();
                          }
                        }),
                      ],
                    ],
                  ),
                );
              },
            );
          }

          // Initial state
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.calculate_outlined,
                  size: 64,
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.5),
                ),
                const SizedBox(height: AppTheme.spacing2),
                Text(
                  context.l10n.settlementTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppTheme.spacing1),
                Text(context.l10n.settlementLoadingData),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 60) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
