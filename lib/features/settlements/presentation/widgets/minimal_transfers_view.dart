import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../domain/models/minimal_transfer.dart';
import '../../../../core/constants/participants.dart';
import '../../../../core/models/currency_code.dart';
import '../../../../core/utils/formatters.dart' show Formatters;
import '../../../../core/theme/app_theme.dart';

/// View showing minimal transfers to settle all debts
///
/// Displays optimized list of transfers with copy-to-clipboard functionality
class MinimalTransfersView extends StatelessWidget {
  final List<MinimalTransfer> transfers;
  final CurrencyCode baseCurrency;

  const MinimalTransfersView({
    super.key,
    required this.transfers,
    required this.baseCurrency,
  });

  @override
  Widget build(BuildContext context) {
    if (transfers.isEmpty) {
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Minimal Transfers',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text(
                  '${transfers.length} transfer${transfers.length == 1 ? '' : 's'}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacing1),
            Text(
              'Optimized to minimize number of transactions',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: AppTheme.spacing2),
            const Divider(),
            const SizedBox(height: AppTheme.spacing1),
            ...transfers.asMap().entries.map((entry) {
              final index = entry.key;
              final transfer = entry.value;
              return _TransferCard(
                transfer: transfer,
                baseCurrency: baseCurrency,
                index: index + 1,
              );
            }),
          ],
        ),
      ),
    );
  }
}

/// Individual transfer card with copy functionality
class _TransferCard extends StatefulWidget {
  final MinimalTransfer transfer;
  final CurrencyCode baseCurrency;
  final int index;

  const _TransferCard({
    required this.transfer,
    required this.baseCurrency,
    required this.index,
  });

  @override
  State<_TransferCard> createState() => _TransferCardState();
}

class _TransferCardState extends State<_TransferCard> {
  bool _copied = false;

  void _copyToClipboard(BuildContext context) {
    final fromName = Participants.getNameById(widget.transfer.fromUserId);
    final toName = Participants.getNameById(widget.transfer.toUserId);
    final amount = Formatters.formatCurrency(
      widget.transfer.amountBase,
      widget.baseCurrency,
    );

    final text = '$fromName pays $toName $amount';

    Clipboard.setData(ClipboardData(text: text));

    setState(() {
      _copied = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied: $text'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );

    // Reset copied state after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _copied = false;
        });
      }
    });
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
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      margin: const EdgeInsets.only(bottom: AppTheme.spacing2),
      child: InkWell(
        onTap: () => _copyToClipboard(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacing2),
          child: Row(
            children: [
              // Step number
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
                    Text(
                      amount,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ),
              // Copy button
              Icon(
                _copied ? Icons.check : Icons.content_copy,
                color: _copied
                    ? Colors.green
                    : Theme.of(context).colorScheme.onSurfaceVariant,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
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
