import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import '../../domain/models/minimal_transfer.dart';
import '../../domain/models/transfer_breakdown.dart';
import '../../domain/services/transfer_breakdown_calculator.dart';
import '../../../expenses/domain/repositories/expense_repository.dart';
import '../../../../core/models/currency_code.dart';
import '../../../../core/models/participant.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/l10n/l10n_extensions.dart';

/// Bottom sheet showing detailed breakdown of a transfer
///
/// Displays all expenses that contributed to the debt between two people
class TransferBreakdownBottomSheet extends StatelessWidget {
  final MinimalTransfer transfer;
  final String tripId;
  final CurrencyCode baseCurrency;
  final List<Participant> participants;
  final ExpenseRepository repository;

  const TransferBreakdownBottomSheet({
    super.key,
    required this.transfer,
    required this.tripId,
    required this.baseCurrency,
    required this.participants,
    required this.repository,
  });

  String _getParticipantName(String userId) {
    try {
      return participants.firstWhere((p) => p.id == userId).name;
    } catch (e) {
      return userId;
    }
  }

  @override
  Widget build(BuildContext context) {
    final fromName = _getParticipantName(transfer.fromUserId);
    final toName = _getParticipantName(transfer.toUserId);
    final amount = Formatters.formatCurrency(transfer.amountBase, baseCurrency);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.spacing3,
                  0,
                  AppTheme.spacing3,
                  AppTheme.spacing2,
                ),
                child: Column(
                  children: [
                    Text(
                      context.l10n.transferBreakdownTitle,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacing1),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildPersonChip(context, fromName, isFrom: true),
                        const SizedBox(width: AppTheme.spacing1),
                        const Icon(Icons.arrow_forward, size: 20),
                        const SizedBox(width: AppTheme.spacing1),
                        _buildPersonChip(context, toName, isFrom: false),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacing1),
                    Text(
                      amount,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ),

              const Divider(),

              // Content
              Expanded(
                child: FutureBuilder<TransferBreakdown>(
                  future: _loadBreakdown(repository),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(AppTheme.spacing3),
                          child: Text(
                            context.l10n.transferBreakdownLoadError(
                              snapshot.error.toString(),
                            ),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }

                    final breakdown = snapshot.data;
                    if (breakdown == null) {
                      return Center(
                        child: Text(context.l10n.transferBreakdownNoData),
                      );
                    }

                    return _buildBreakdownContent(
                      context,
                      breakdown,
                      scrollController,
                      fromName,
                      toName,
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<TransferBreakdown> _loadBreakdown(
    ExpenseRepository expenseRepository,
  ) async {
    final expenses = await expenseRepository.getExpensesByTrip(tripId).first;

    final calculator = TransferBreakdownCalculator();
    return calculator.calculateBreakdown(
      fromUserId: transfer.fromUserId,
      toUserId: transfer.toUserId,
      transferAmount: transfer.amountBase,
      expenses: expenses,
    );
  }

  Widget _buildBreakdownContent(
    BuildContext context,
    TransferBreakdown breakdown,
    ScrollController scrollController,
    String fromName,
    String toName,
  ) {
    final relevantBreakdowns = breakdown.relevantBreakdowns;

    if (relevantBreakdowns.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacing3),
          child: Text(
            context.l10n.transferBreakdownNoExpenses,
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.all(AppTheme.spacing3),
      children: [
        // Summary
        Card(
          color: Theme.of(context).colorScheme.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacing2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.transferBreakdownSummaryTitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: AppTheme.spacing1),
                Text(
                  context.l10n.transferBreakdownSummaryDescription(
                    fromName,
                    toName,
                  ),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: AppTheme.spacing1),
                Text(
                  context.l10n.transferBreakdownExpenseCount(
                    relevantBreakdowns.length,
                  ),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: AppTheme.spacing2),

        // Expense list
        Text(
          context.l10n.transferBreakdownContributingExpenses,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppTheme.spacing1),

        ...relevantBreakdowns.map((expenseBreakdown) {
          return _buildExpenseCard(context, expenseBreakdown, fromName, toName);
        }),
      ],
    );
  }

  Widget _buildExpenseCard(
    BuildContext context,
    ExpenseBreakdown expenseBreakdown,
    String fromName,
    String toName,
  ) {
    final expense = expenseBreakdown.expense;
    final payerName = _getParticipantName(expense.payerUserId);
    final isPositive = expenseBreakdown.netContribution > Decimal.zero;

    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spacing2),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Expense header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        expense.description ??
                            context.l10n.transferBreakdownNoDescription,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        context.l10n.transferBreakdownExpenseMetadata(
                          payerName,
                          _formatDate(expense.date),
                        ),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  Formatters.formatCurrency(expense.amount, expense.currency),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppTheme.spacing2),
            const Divider(),
            const SizedBox(height: AppTheme.spacing1),

            // Breakdown details
            _buildPersonRow(
              context,
              fromName,
              context.l10n.transferBreakdownPaidLabel,
              expenseBreakdown.fromPaid,
              context.l10n.transferBreakdownOwesLabel,
              expenseBreakdown.fromOwes,
            ),
            const SizedBox(height: AppTheme.spacing1),
            _buildPersonRow(
              context,
              toName,
              context.l10n.transferBreakdownPaidLabel,
              expenseBreakdown.toPaid,
              context.l10n.transferBreakdownOwesLabel,
              expenseBreakdown.toOwes,
            ),

            const SizedBox(height: AppTheme.spacing2),

            // Net contribution
            Container(
              padding: const EdgeInsets.all(AppTheme.spacing1),
              decoration: BoxDecoration(
                color: isPositive ? Colors.red.shade50 : Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                    size: 16,
                    color: isPositive
                        ? Colors.red.shade700
                        : Colors.green.shade700,
                  ),
                  const SizedBox(width: AppTheme.spacing1),
                  Expanded(
                    child: Text(
                      expenseBreakdown.explanation,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isPositive
                            ? Colors.red.shade700
                            : Colors.green.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    Formatters.formatCurrency(
                      expenseBreakdown.netContribution.abs(),
                      baseCurrency,
                    ),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isPositive
                          ? Colors.red.shade700
                          : Colors.green.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonRow(
    BuildContext context,
    String name,
    String label1,
    Decimal value1,
    String label2,
    Decimal value2,
  ) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            name,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(
          child: Row(
            children: [
              Text('$label1: ', style: Theme.of(context).textTheme.bodySmall),
              Text(
                Formatters.formatCurrency(value1, baseCurrency),
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: AppTheme.spacing2),
              Text('$label2: ', style: Theme.of(context).textTheme.bodySmall),
              Text(
                Formatters.formatCurrency(value2, baseCurrency),
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPersonChip(
    BuildContext context,
    String name, {
    required bool isFrom,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isFrom ? Colors.red.shade50 : Colors.green.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        name,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: isFrom ? Colors.red.shade700 : Colors.green.shade700,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  /// Static method to show the bottom sheet
  static void show(
    BuildContext context, {
    required MinimalTransfer transfer,
    required String tripId,
    required CurrencyCode baseCurrency,
    required List<Participant> participants,
    required ExpenseRepository repository,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TransferBreakdownBottomSheet(
        transfer: transfer,
        tripId: tripId,
        baseCurrency: baseCurrency,
        participants: participants,
        repository: repository,
      ),
    );
  }
}
