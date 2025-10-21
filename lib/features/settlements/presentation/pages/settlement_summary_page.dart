import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubits/settlement_cubit.dart';
import '../cubits/settlement_state.dart';
import '../widgets/all_people_summary_table.dart';
import '../widgets/minimal_transfers_view.dart';
import '../../../trips/presentation/cubits/trip_cubit.dart';
import '../../../trips/presentation/cubits/trip_state.dart';
import '../../../expenses/domain/repositories/expense_repository.dart';
import '../../../../core/models/participant.dart';
import '../../../../core/theme/app_theme.dart';

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
    // Capture repository here where providers are accessible
    final expenseRepository = context.read<ExpenseRepository>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settlement'),
        actions: [
          BlocBuilder<SettlementCubit, SettlementState>(
            builder: (context, state) {
              if (state is SettlementLoaded) {
                return IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Recompute Settlement',
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
                        ? 'Computing settlement...'
                        : 'Loading settlement...',
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
                    label: const Text('Retry'),
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
                                'Last updated: ${_formatTimestamp(state.summary.lastComputedAt)}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacing2),

                      // Summary table
                      AllPeopleSummaryTable(
                        personSummaries: state.summary.personSummaries,
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
                  'Settlement',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppTheme.spacing1),
                const Text('Loading settlement data...'),
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
