import 'package:flutter/material.dart';
import 'package:decimal/decimal.dart';
import '../../domain/models/category_spending.dart';
import '../../../../core/models/participant.dart';
import '../../../../core/models/currency_code.dart';
import '../../../../core/utils/formatters.dart' show Formatters;
import '../../../../core/theme/app_theme.dart';
import 'category_spending_pie_chart.dart';

/// Dashboard card showing per-person spending summary and category breakdown
///
/// Displays financial summary (paid/owed/net) and category spending pie chart
class PersonDashboardCard extends StatefulWidget {
  final PersonCategorySpending person;
  final Participant participant;
  final CurrencyCode baseCurrency;

  const PersonDashboardCard({
    super.key,
    required this.person,
    required this.participant,
    required this.baseCurrency,
  });

  @override
  State<PersonDashboardCard> createState() => _PersonDashboardCardState();
}

class _PersonDashboardCardState extends State<PersonDashboardCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final person = widget.person;
    final participant = widget.participant;

    // Determine net balance color
    final isPositive = person.netBase > Decimal.zero;
    final isNegative = person.netBase < Decimal.zero;
    final balanceColor = isPositive
        ? Colors.green.shade700
        : isNegative
        ? Colors.red.shade700
        : Theme.of(context).colorScheme.onSurface;

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with person info
          ListTile(
            leading: CircleAvatar(
              backgroundColor: _getAvatarColor(participant.id),
              child: Text(
                participant.name.substring(0, 1).toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              participant.name,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            trailing: IconButton(
              icon: Icon(_isExpanded ? Icons.expand_less : Icons.expand_more),
              onPressed: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
            ),
          ),

          // Financial Summary
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing2),
            child: Column(
              children: [
                _buildSummaryRow(
                  context,
                  'Total Paid',
                  person.totalPaidBase,
                  null,
                ),
                _buildSummaryRow(
                  context,
                  'Total Owed',
                  person.totalOwedBase,
                  null,
                ),
                const Divider(),
                _buildSummaryRow(
                  context,
                  'Net Balance',
                  person.netBase.abs(),
                  balanceColor,
                  prefix: isPositive
                      ? '↑ Will receive'
                      : isNegative
                      ? '↓ Needs to pay'
                      : '= Even',
                ),
              ],
            ),
          ),

          // Category Breakdown (Expandable)
          if (_isExpanded) ...[
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(AppTheme.spacing2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Category Breakdown',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacing2),
                  CategorySpendingPieChart(
                    categoryBreakdown: person.categoryBreakdown,
                    currency: widget.baseCurrency,
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: AppTheme.spacing1),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    BuildContext context,
    String label,
    Decimal amount,
    Color? amountColor, {
    String? prefix,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (prefix != null)
                Text(
                  prefix,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: amountColor,
                    fontSize: 10,
                  ),
                ),
              Text(
                Formatters.formatCurrency(amount, widget.baseCurrency),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: label == 'Net Balance'
                      ? FontWeight.bold
                      : FontWeight.normal,
                  color: amountColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
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

    // Use hash code for consistent coloring
    final hash = userId.hashCode.abs();
    return colors[hash % colors.length];
  }
}
