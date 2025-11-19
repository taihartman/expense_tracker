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
import '../../../../core/models/currency_code.dart';
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
  // T030: Track selected currency for filtering settlements
  CurrencyCode? _selectedCurrency;

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
    // Capture repository here where providers are accessible
    final expenseRepository = context.read<ExpenseRepository>();

    return FutureBuilder<bool>(
      future: tripCubit.isUserMemberOf(widget.tripId),
      builder: (context, snapshot) {
        // Show loading while checking membership
        if (!snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(title: Text(context.l10n.settlementTitle)),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        // Show verification prompt if not a member
        if (snapshot.data == false) {
          return Scaffold(
            appBar: AppBar(title: Text(context.l10n.settlementTitle)),
            body: TripVerificationPrompt(tripId: widget.tripId),
          );
        }

        // User is verified, show settlement summary
        return _buildSettlementSummary(context, expenseRepository);
      },
    );
  }

  Widget _buildSettlementSummary(BuildContext context, ExpenseRepository expenseRepository) {
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
                // T030: Get trip and its allowed currencies
                final trip = tripState is TripLoaded
                    ? tripState.trips.firstWhere(
                        (t) => t.id == widget.tripId,
                        orElse: () => tripState.selectedTrip!,
                      )
                    : null;

                final participants = trip?.participants ?? <Participant>[];
                final allowedCurrencies =
                    trip?.allowedCurrencies ?? [state.summary.baseCurrency];

                // T030: Initialize selected currency from state if not set
                _selectedCurrency ??= state.summary.baseCurrency;

                // T031: Check for empty settlements (no expenses in selected currency)
                final hasNoExpenses = state.activeTransfers.isEmpty &&
                    state.settledTransfers.isEmpty;

                return RefreshIndicator(
                  onRefresh: () async {
                    await context.read<SettlementCubit>().computeSettlement(
                      widget.tripId,
                    );
                  },
                  child: ListView(
                    padding: const EdgeInsets.all(AppTheme.spacing2),
                    children: [
                      // T031: Show empty state if no expenses in selected currency
                      if (hasNoExpenses) ...[
                        _buildEmptyState(
                          _selectedCurrency ?? state.summary.baseCurrency,
                        ),
                      ] else ...[
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

                      // Validation warnings banner (if any)
                      if (state.validationWarnings != null &&
                          state.validationWarnings!.isNotEmpty) ...[
                        Card(
                          color: Theme.of(context).colorScheme.errorContainer,
                          child: Padding(
                            padding: const EdgeInsets.all(AppTheme.spacing2),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.warning_amber_rounded,
                                      color: Theme.of(context).colorScheme.error,
                                      size: 20,
                                    ),
                                    const SizedBox(width: AppTheme.spacing1),
                                    Text(
                                      'Validation Warning',
                                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                        color: Theme.of(context).colorScheme.error,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppTheme.spacing1),
                                ...state.validationWarnings!.map((warning) =>
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      '• $warning',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Theme.of(context).colorScheme.onErrorContainer,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacing2),
                      ],

                      // T030: Currency switcher (only show if multiple currencies)
                      if (allowedCurrencies.length > 1) ...[
                        _buildCurrencySwitcher(
                          allowedCurrencies,
                          state.summary.baseCurrency,
                        ),
                        const SizedBox(height: AppTheme.spacing2),
                      ],

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
                        tripDefaultCurrency: trip?.defaultCurrency,
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
                        // Build dashboard cards (filtered by selected user if any)
                        ...() {
                          // Filter dashboards by selected user
                          final selectedUserId = state.selectedUserId;
                          final filteredSpending = selectedUserId != null &&
                                  state.personCategorySpending!
                                      .containsKey(selectedUserId)
                              ? {
                                  selectedUserId:
                                      state.personCategorySpending![selectedUserId]!,
                                }
                              : state.personCategorySpending!;

                          return filteredSpending.entries.map((entry) {
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
                                  activeTransfers: state.activeTransfers,
                                  person: personSpending,
                                  participant: participant,
                                  baseCurrency: state.summary.baseCurrency,
                                ),
                              );
                            } catch (e) {
                              // Skip if participant not found
                              return const SizedBox.shrink();
                            }
                          });
                        }(),
                      ],
                      ], // End of else block (T031)
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

  /// T030: Build currency switcher UI
  /// Shows SegmentedButton for allowed currencies
  Widget _buildCurrencySwitcher(
    List<CurrencyCode> allowedCurrencies,
    CurrencyCode currentCurrency,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Currency',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppTheme.spacing1),
            SegmentedButton<CurrencyCode>(
              segments: allowedCurrencies.map((currency) {
                return ButtonSegment<CurrencyCode>(
                  value: currency,
                  label: Text(currency.code.toUpperCase()),
                  icon: Text(currency.symbol),
                );
              }).toList(),
              selected: {_selectedCurrency ?? currentCurrency},
              onSelectionChanged: (Set<CurrencyCode> selected) {
                if (selected.isNotEmpty) {
                  final newCurrency = selected.first;
                  setState(() {
                    _selectedCurrency = newCurrency;
                  });
                  // T032: Load settlements filtered by selected currency
                  context.read<SettlementCubit>().loadSettlementForCurrency(
                        widget.tripId,
                        newCurrency,
                      );
                }
              },
              showSelectedIcon: false,
            ),
          ],
        ),
      ),
    );
  }

  /// T031: Build empty state UI when no expenses in selected currency
  Widget _buildEmptyState(CurrencyCode currency) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppTheme.spacing4,
          horizontal: AppTheme.spacing3,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: AppTheme.spacing2),
            Text(
              'No expenses in ${currency.code.toUpperCase()}',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacing1),
            Text(
              'Try switching to another currency to view settlements',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
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
