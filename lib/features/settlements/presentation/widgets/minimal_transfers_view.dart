import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/models/minimal_transfer.dart';
import '../../../../core/models/participant.dart';
import '../../../../core/models/currency_code.dart';
import '../../../../core/utils/formatters.dart' show Formatters;
import '../../../../core/theme/app_theme.dart';
import '../cubits/settlement_cubit.dart';
import 'transfer_breakdown_bottom_sheet.dart';
import '../../../expenses/domain/repositories/expense_repository.dart';
import '../../../../core/l10n/l10n_extensions.dart';

/// View showing minimal transfers to settle all debts
///
/// Displays optimized list of transfers with copy-to-clipboard functionality
/// and settlement marking
class MinimalTransfersView extends StatelessWidget {
  final String tripId;
  final List<MinimalTransfer> activeTransfers;
  final List<MinimalTransfer> settledTransfers;
  final CurrencyCode baseCurrency;
  final List<Participant> participants;
  final ExpenseRepository expenseRepository;

  const MinimalTransfersView({
    super.key,
    required this.tripId,
    required this.activeTransfers,
    required this.settledTransfers,
    required this.baseCurrency,
    required this.participants,
    required this.expenseRepository,
  });

  @override
  Widget build(BuildContext context) {
    // If no transfers at all (both active and settled), show all settled message
    if (activeTransfers.isEmpty && settledTransfers.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacing3),
          child: Column(
            children: [
              Icon(
                Icons.check_circle_outline,
                size: 64,
                color: Colors.green.shade400,
              ),
              const SizedBox(height: AppTheme.spacing2),
              Text(
                context.l10n.transfersAllSettledTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppTheme.spacing1),
              Text(
                context.l10n.transfersAllSettledDescription,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  context.l10n.transfersCardTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text(
                  context.l10n.transfersCountTotal(
                    activeTransfers.length + settledTransfers.length,
                  ),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacing1),
            Text(
              context.l10n.transfersHintTapToSettle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppTheme.spacing2),
            const Divider(),
            const SizedBox(height: AppTheme.spacing1),

            // Active Transfers Section
            if (activeTransfers.isNotEmpty) ...[
              Row(
                children: [
                  Icon(
                    Icons.pending_actions,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: AppTheme.spacing1),
                  Text(
                    context.l10n.transfersPendingTitle,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacing1),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${activeTransfers.length}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacing2),
              ...activeTransfers.asMap().entries.map((entry) {
                final index = entry.key;
                final transfer = entry.value;
                return _TransferCard(
                  tripId: tripId,
                  transfer: transfer,
                  baseCurrency: baseCurrency,
                  participants: participants,
                  expenseRepository: expenseRepository,
                  index: index + 1,
                  isSettled: false,
                );
              }),
            ],

            // Settled Transfers Section
            if (settledTransfers.isNotEmpty) ...[
              if (activeTransfers.isNotEmpty)
                const SizedBox(height: AppTheme.spacing3),
              Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 20,
                    color: Colors.green.shade600,
                  ),
                  const SizedBox(width: AppTheme.spacing1),
                  Text(
                    context.l10n.transfersSettledTitle,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacing1),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${settledTransfers.length}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacing2),
              ...settledTransfers.map((transfer) {
                return _TransferCard(
                  tripId: tripId,
                  transfer: transfer,
                  baseCurrency: baseCurrency,
                  participants: participants,
                  expenseRepository: expenseRepository,
                  index: null, // No step number for settled transfers
                  isSettled: true,
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}

/// Individual transfer card with copy and settlement functionality
class _TransferCard extends StatefulWidget {
  final String tripId;
  final MinimalTransfer transfer;
  final CurrencyCode baseCurrency;
  final List<Participant> participants;
  final ExpenseRepository expenseRepository;
  final int? index; // Null for settled transfers
  final bool isSettled;

  const _TransferCard({
    required this.tripId,
    required this.transfer,
    required this.baseCurrency,
    required this.participants,
    required this.expenseRepository,
    required this.index,
    required this.isSettled,
  });

  @override
  State<_TransferCard> createState() => _TransferCardState();
}

class _TransferCardState extends State<_TransferCard> {
  String _getParticipantName(String userId) {
    try {
      return widget.participants.firstWhere((p) => p.id == userId).name;
    } catch (e) {
      return userId; // Fallback to ID if not found
    }
  }

  void _copyToClipboard(BuildContext context) {
    final fromName = _getParticipantName(widget.transfer.fromUserId);
    final toName = _getParticipantName(widget.transfer.toUserId);
    final amount = Formatters.formatCurrency(
      widget.transfer.amountBase,
      widget.baseCurrency,
    );

    final text = context.l10n.transferCopiedFormat(fromName, toName, amount);

    Clipboard.setData(ClipboardData(text: text));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.transferCopiedMessage(text)),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _showSettleDialog(BuildContext context) async {
    final fromName = _getParticipantName(widget.transfer.fromUserId);
    final toName = _getParticipantName(widget.transfer.toUserId);
    final amount = Formatters.formatCurrency(
      widget.transfer.amountBase,
      widget.baseCurrency,
    );

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(dialogContext.l10n.transferMarkSettledDialogTitle),
        content: Text(
          dialogContext.l10n.transferMarkSettledDialogMessage(
            fromName,
            toName,
            amount,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(dialogContext.l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(dialogContext.l10n.transferMarkSettledDialogTitle),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await context.read<SettlementCubit>().markTransferAsSettled(
        widget.transfer.id,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final fromName = _getParticipantName(widget.transfer.fromUserId);
    final toName = _getParticipantName(widget.transfer.toUserId);
    final amount = Formatters.formatCurrency(
      widget.transfer.amountBase,
      widget.baseCurrency,
    );

    return Card(
      elevation: 0,
      color: widget.isSettled
          ? Theme.of(context).colorScheme.surfaceContainerLowest
          : Theme.of(context).colorScheme.surfaceContainerHighest,
      margin: const EdgeInsets.only(bottom: AppTheme.spacing2),
      child: InkWell(
        onTap: widget.isSettled ? null : () => _showSettleDialog(context),
        onLongPress: () => _copyToClipboard(context),
        borderRadius: BorderRadius.circular(12),
        child: Opacity(
          opacity: widget.isSettled ? 0.6 : 1.0,
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacing2),
            child: Row(
              children: [
                // Step number or checkmark
                if (widget.index != null)
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: Text(
                      '${widget.index}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  )
                else
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.green.shade100,
                    child: Icon(
                      Icons.check,
                      size: 20,
                      color: Colors.green.shade700,
                    ),
                  ),
                const SizedBox(width: AppTheme.spacing2),
                // Transfer details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _buildPersonChip(context, fromName, isFrom: true),
                          const SizedBox(width: AppTheme.spacing1),
                          const Icon(Icons.arrow_forward, size: 20),
                          const SizedBox(width: AppTheme.spacing1),
                          _buildPersonChip(context, toName, isFrom: false),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            amount,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                  decoration: widget.isSettled
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                          ),
                          if (widget.isSettled &&
                              widget.transfer.settledAt != null) ...[
                            const SizedBox(width: AppTheme.spacing1),
                            Text(
                              '• ${_formatDate(widget.transfer.settledAt!)}',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: Colors.green.shade600),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                // Action buttons
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Breakdown button (only for active transfers)
                    if (!widget.isSettled)
                      IconButton(
                        icon: Icon(
                          Icons.info_outline,
                          size: 20,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        tooltip: context.l10n.transferBreakdownViewTooltip,
                        onPressed: () => _showBreakdown(context),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    if (!widget.isSettled)
                      const SizedBox(width: AppTheme.spacing1),
                    // Touch indicator
                    if (!widget.isSettled)
                      const Icon(Icons.touch_app, size: 20, color: Colors.grey),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showBreakdown(BuildContext context) {
    TransferBreakdownBottomSheet.show(
      context,
      transfer: widget.transfer,
      tripId: widget.tripId,
      baseCurrency: widget.baseCurrency,
      participants: widget.participants,
      repository: widget.expenseRepository,
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    final context = this.context;

    if (difference.inDays == 0) {
      return context.l10n.dateToday;
    } else if (difference.inDays == 1) {
      return context.l10n.dateYesterday;
    } else if (difference.inDays < 7) {
      return context.l10n.dateDaysAgo(difference.inDays);
    } else {
      return '${date.month}/${date.day}';
    }
  }

  Widget _buildPersonChip(
    BuildContext context,
    String name, {
    required bool isFrom,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isFrom ? Colors.red.shade50 : Colors.green.shade50,
        borderRadius: BorderRadius.circular(4),
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
}
