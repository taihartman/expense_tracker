import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../domain/models/person_summary.dart';
import '../../domain/models/minimal_transfer.dart';
import '../../../../core/constants/participants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/models/currency_code.dart';

/// Page displaying settlement summary with transfers
class SettlementSummaryPage extends StatelessWidget {
  final Map<String, PersonSummary> personSummaries;
  final List<MinimalTransfer> minimalTransfers;
  final CurrencyCode baseCurrency;

  const SettlementSummaryPage({
    required this.personSummaries,
    required this.minimalTransfers,
    required this.baseCurrency,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settlement'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppTheme.spacing2),
        children: [
          // Summary table
          _buildSummarySection(context),
          const SizedBox(height: AppTheme.spacing3),

          // Minimal transfers
          _buildTransfersSection(context),
        ],
      ),
    );
  }

  Widget _buildSummarySection(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Summary',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: AppTheme.spacing2),
            Table(
              columnWidths: const {
                0: FlexColumnWidth(2),
                1: FlexColumnWidth(1),
                2: FlexColumnWidth(1),
                3: FlexColumnWidth(1),
              },
              children: [
                // Header
                TableRow(
                  children: [
                    _tableHeader('Person'),
                    _tableHeader('Paid'),
                    _tableHeader('Owed'),
                    _tableHeader('Net'),
                  ],
                ),
                // Data rows
                ...personSummaries.values.map((summary) {
                  return TableRow(
                    children: [
                      _tableCell(
                        context,
                        Participants.getNameById(summary.userId),
                      ),
                      _tableCell(
                        context,
                        Formatters.formatCurrency(summary.totalPaidBase, baseCurrency),
                      ),
                      _tableCell(
                        context,
                        Formatters.formatCurrency(summary.totalOwedBase, baseCurrency),
                      ),
                      _tableCell(
                        context,
                        Formatters.formatCurrency(summary.netBase.abs(), baseCurrency),
                        color: AppTheme.getBalanceColor(summary.netBase.toDouble()),
                      ),
                    ],
                  );
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransfersSection(BuildContext context) {
    final theme = Theme.of(context);

    if (minimalTransfers.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacing3),
          child: Center(
            child: Text(
              'All settled up! \ud83c\udf89',
              style: theme.textTheme.titleMedium,
            ),
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
                  'Transfers (${minimalTransfers.length})',
                  style: theme.textTheme.titleLarge,
                ),
                TextButton.icon(
                  onPressed: () => _copyAllTransfers(context),
                  icon: const Icon(Icons.copy, size: 18),
                  label: const Text('Copy All'),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacing2),
            ...minimalTransfers.map((transfer) {
              return _buildTransferCard(context, transfer);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTransferCard(BuildContext context, MinimalTransfer transfer) {
    final theme = Theme.of(context);
    final fromName = Participants.getNameById(transfer.fromUserId);
    final toName = Participants.getNameById(transfer.toUserId);
    final amount = Formatters.formatCurrency(transfer.amountBase, baseCurrency);

    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spacing1),
      color: theme.colorScheme.surfaceContainerHighest,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Icon(
            Icons.arrow_forward,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
        title: Text(
          '$fromName → $toName',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(amount),
        trailing: IconButton(
          icon: const Icon(Icons.copy, size: 20),
          onPressed: () => _copyTransfer(context, fromName, toName, amount),
        ),
      ),
    );
  }

  Widget _tableHeader(String text) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _tableCell(BuildContext context, String text, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        text,
        style: color != null ? TextStyle(color: color, fontWeight: FontWeight.w500) : null,
      ),
    );
  }

  void _copyTransfer(BuildContext context, String from, String to, String amount) {
    final text = '$from pays $to $amount';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Transfer copied to clipboard')),
    );
  }

  void _copyAllTransfers(BuildContext context) {
    final text = minimalTransfers.map((t) {
      final from = Participants.getNameById(t.fromUserId);
      final to = Participants.getNameById(t.toUserId);
      final amount = Formatters.formatCurrency(t.amountBase, baseCurrency);
      return '$from pays $to $amount';
    }).join('\n');

    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${minimalTransfers.length} transfers copied to clipboard')),
    );
  }
}
