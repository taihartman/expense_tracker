import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:decimal/decimal.dart';
import '../../domain/models/minimal_transfer.dart';
import '../../../../core/models/participant.dart';
import '../../../../core/models/currency_code.dart';
import '../../../../core/utils/formatters.dart' show Formatters;
import '../../../../core/theme/app_theme.dart';
import '../../../../core/l10n/l10n_extensions.dart';
import '../cubits/settlement_cubit.dart';
import '../cubits/settlement_state.dart';

/// Summary data for a person based on settlement transfers
class _PersonTransferSummary {
  final String userId;
  final Decimal totalToReceive; // Sum of transfers where user receives
  final Decimal totalToPay; // Sum of transfers where user pays
  final Decimal netBalance; // totalToReceive - totalToPay

  _PersonTransferSummary({
    required this.userId,
    required this.totalToReceive,
    required this.totalToPay,
  }) : netBalance = totalToReceive - totalToPay;
}

/// Table showing summary for all people in a trip
///
/// Displays amounts to receive, amounts to pay, and net balance based on settlement transfers
/// Color coded: green for positive (will receive money), red for negative (needs to pay)
class AllPeopleSummaryTable extends StatelessWidget {
  final List<MinimalTransfer> activeTransfers;
  final CurrencyCode baseCurrency;
  final List<Participant> participants;

  const AllPeopleSummaryTable({
    super.key,
    required this.activeTransfers,
    required this.baseCurrency,
    required this.participants,
  });

  /// Calculate transfer summaries from active transfers
  Map<String, _PersonTransferSummary> _calculateTransferSummaries() {
    final summaries = <String, _PersonTransferSummary>{};

    // Initialize summaries for all participants
    for (final participant in participants) {
      summaries[participant.id] = _PersonTransferSummary(
        userId: participant.id,
        totalToReceive: Decimal.zero,
        totalToPay: Decimal.zero,
      );
    }

    // Calculate totals from transfers
    for (final transfer in activeTransfers) {
      // Person receiving money
      final receiver = summaries[transfer.toUserId];
      if (receiver != null) {
        summaries[transfer.toUserId] = _PersonTransferSummary(
          userId: transfer.toUserId,
          totalToReceive: receiver.totalToReceive + transfer.amountBase,
          totalToPay: receiver.totalToPay,
        );
      }

      // Person paying money
      final payer = summaries[transfer.fromUserId];
      if (payer != null) {
        summaries[transfer.fromUserId] = _PersonTransferSummary(
          userId: transfer.fromUserId,
          totalToReceive: payer.totalToReceive,
          totalToPay: payer.totalToPay + transfer.amountBase,
        );
      }
    }

    return summaries;
  }

  @override
  Widget build(BuildContext context) {
    // Calculate summaries from transfers
    final transferSummaries = _calculateTransferSummaries();

    // Sort by net balance (highest to lowest)
    final sortedEntries = transferSummaries.entries.toList()
      ..sort((a, b) => b.value.netBalance.compareTo(a.value.netBalance));

    return BlocBuilder<SettlementCubit, SettlementState>(
      builder: (context, state) {
        final selectedUserId = state is SettlementLoaded
            ? state.selectedUserId
            : null;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacing2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.summaryTableTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppTheme.spacing2),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columnSpacing: AppTheme.spacing2,
                    headingRowColor: WidgetStateProperty.all(
                      Theme.of(context).colorScheme.surfaceContainerHighest,
                    ),
                    columns: [
                      DataColumn(
                        label: Text(context.l10n.summaryTableColumnPerson),
                      ),
                      DataColumn(
                        label: Text(context.l10n.summaryTableColumnToReceive),
                        numeric: true,
                      ),
                      DataColumn(
                        label: Text(context.l10n.summaryTableColumnToPay),
                        numeric: true,
                      ),
                      DataColumn(
                        label: Text(context.l10n.summaryTableColumnNet),
                        numeric: true,
                      ),
                    ],
                    rows: sortedEntries.map((entry) {
                      final userId = entry.key;
                      final summary = entry.value;
                      final userName = _getParticipantName(userId);

                      // Determine color based on net balance
                      final isPositive = summary.netBalance > Decimal.zero;
                      final isNegative = summary.netBalance < Decimal.zero;
                      final balanceColor = isPositive
                          ? Colors.green.shade700
                          : isNegative
                          ? Colors.red.shade700
                          : Theme.of(context).colorScheme.onSurface;

                      final isSelected = selectedUserId == userId;

                      return DataRow(
                        selected: isSelected,
                        onSelectChanged: (_) {
                          // Toggle filter: if already selected, clear it; otherwise set it
                          if (isSelected) {
                            context.read<SettlementCubit>().clearUserFilter();
                          } else {
                            context.read<SettlementCubit>().setUserFilter(
                              userId,
                              TransferFilterMode.all,
                            );
                          }
                        },
                        color: isSelected
                            ? WidgetStateProperty.all(
                                Theme.of(context).colorScheme.primaryContainer
                                    .withValues(alpha: 0.3),
                              )
                            : null,
                        cells: [
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: _getAvatarColor(userId),
                                  child: Text(
                                    userName.substring(0, 1).toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AppTheme.spacing1),
                                Text(userName),
                              ],
                            ),
                          ),
                          DataCell(
                            Text(
                              Formatters.formatCurrency(
                                summary.totalToReceive,
                                baseCurrency,
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              Formatters.formatCurrency(
                                summary.totalToPay,
                                baseCurrency,
                              ),
                            ),
                          ),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isPositive
                                      ? Icons.arrow_upward
                                      : isNegative
                                      ? Icons.arrow_downward
                                      : Icons.remove,
                                  size: 16,
                                  color: balanceColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  Formatters.formatCurrency(
                                    summary.netBalance.abs(),
                                    baseCurrency,
                                  ),
                                  style: TextStyle(
                                    color: balanceColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: AppTheme.spacing2),
                // Legend
                Wrap(
                  spacing: AppTheme.spacing2,
                  runSpacing: AppTheme.spacing1,
                  children: [
                    _buildLegendItem(
                      context,
                      Icons.arrow_upward,
                      context.l10n.summaryTableLegendWillReceive,
                      Colors.green.shade700,
                    ),
                    _buildLegendItem(
                      context,
                      Icons.arrow_downward,
                      context.l10n.summaryTableLegendNeedsToPay,
                      Colors.red.shade700,
                    ),
                    _buildLegendItem(
                      context,
                      Icons.remove,
                      context.l10n.summaryTableLegendEven,
                      Theme.of(context).colorScheme.onSurface,
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacing1),
                // Tap hint
                Text(
                  context.l10n.transferFilterHint,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLegendItem(
    BuildContext context,
    IconData icon,
    String label,
    Color color,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  String _getParticipantName(String userId) {
    try {
      return participants.firstWhere((p) => p.id == userId).name;
    } catch (e) {
      // Fallback to ID if participant not found
      return userId;
    }
  }

  Color _getAvatarColor(String userId) {
    // Consistent colors for each user
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
    ];

    // Find index in participants list for consistent coloring
    final index = participants.indexWhere((p) => p.id == userId);
    return colors[index >= 0 ? index % colors.length : 0];
  }
}
