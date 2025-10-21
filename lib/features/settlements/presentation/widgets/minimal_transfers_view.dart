import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/models/minimal_transfer.dart';
import '../../../../core/constants/participants.dart';
import '../../../../core/models/currency_code.dart';
import '../../../../core/utils/formatters.dart' show Formatters;
import '../../../../core/theme/app_theme.dart';
import '../cubits/settlement_cubit.dart';

/// View showing minimal transfers to settle all debts
///
/// Displays optimized list of transfers with copy-to-clipboard functionality
/// and settlement marking
class MinimalTransfersView extends StatelessWidget {
  final List<MinimalTransfer> activeTransfers;
  final List<MinimalTransfer> settledTransfers;
  final CurrencyCode baseCurrency;

  const MinimalTransfersView({
    super.key,
    required this.activeTransfers,
    required this.settledTransfers,
    required this.baseCurrency,
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
                'All Settled!',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppTheme.spacing1),
              Text(
                'Everyone is even, no transfers needed.',
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
                  'Settlement Transfers',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text(
                  '${activeTransfers.length + settledTransfers.length} total',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacing1),
            Text(
              'Tap a transfer to mark as settled',
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
                    'Pending Transfers',
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
                  transfer: transfer,
                  baseCurrency: baseCurrency,
                  index: index + 1,
                  isSettled: false,
                );
              }),
            ],

            // Settled Transfers Section
            if (settledTransfers.isNotEmpty) ...[
              if (activeTransfers.isNotEmpty) const SizedBox(height: AppTheme.spacing3),
              Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 20,
                    color: Colors.green.shade600,
                  ),
                  const SizedBox(width: AppTheme.spacing1),
                  Text(
                    'Settled Transfers',
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
                  transfer: transfer,
                  baseCurrency: baseCurrency,
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
  final MinimalTransfer transfer;
  final CurrencyCode baseCurrency;
  final int? index; // Null for settled transfers
  final bool isSettled;

  const _TransferCard({
    required this.transfer,
    required this.baseCurrency,
    required this.index,
    required this.isSettled,
  });

  @override
  State<_TransferCard> createState() => _TransferCardState();
}

class _TransferCardState extends State<_TransferCard> {
  void _copyToClipboard(BuildContext context) {
    final fromName = Participants.getNameById(widget.transfer.fromUserId);
    final toName = Participants.getNameById(widget.transfer.toUserId);
    final amount = Formatters.formatCurrency(
      widget.transfer.amountBase,
      widget.baseCurrency,
    );

    final text = '$fromName pays $toName $amount';

    Clipboard.setData(ClipboardData(text: text));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied: $text'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _showSettleDialog(BuildContext context) async {
    final fromName = Participants.getNameById(widget.transfer.fromUserId);
    final toName = Participants.getNameById(widget.transfer.toUserId);
    final amount = Formatters.formatCurrency(
      widget.transfer.amountBase,
      widget.baseCurrency,
    );

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark as Settled'),
        content: Text(
          'Mark this transfer as settled?\n\n$fromName → $toName: $amount',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Mark as Settled'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await context.read<SettlementCubit>().markTransferAsSettled(widget.transfer.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fromName = Participants.getNameById(widget.transfer.fromUserId);
    final toName = Participants.getNameById(widget.transfer.toUserId);
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
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                  decoration: widget.isSettled
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                          ),
                          if (widget.isSettled && widget.transfer.settledAt != null) ...[
                            const SizedBox(width: AppTheme.spacing1),
                            Text(
                              '• ${_formatDate(widget.transfer.settledAt!)}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.green.shade600,
                                  ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                // Copy button (always available on long press)
                if (!widget.isSettled)
                  const Icon(
                    Icons.touch_app,
                    size: 20,
                    color: Colors.grey,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.month}/${date.day}';
    }
  }

  Widget _buildPersonChip(BuildContext context, String name, {required bool isFrom}) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: isFrom
            ? Colors.red.shade50
            : Colors.green.shade50,
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
