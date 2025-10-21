import 'package:flutter/material.dart';
import 'package:decimal/decimal.dart';
import '../../domain/models/person_summary.dart';
import '../../../../core/models/participant.dart';
import '../../../../core/models/currency_code.dart';
import '../../../../core/utils/formatters.dart' show Formatters;
import '../../../../core/theme/app_theme.dart';

/// Table showing summary for all people in a trip
///
/// Displays total paid, total owed, and net balance for each person
/// Color coded: green for positive (owed money), red for negative (owes money)
class AllPeopleSummaryTable extends StatelessWidget {
  final Map<String, PersonSummary> personSummaries;
  final CurrencyCode baseCurrency;
  final List<Participant> participants;

  const AllPeopleSummaryTable({
    super.key,
    required this.personSummaries,
    required this.baseCurrency,
    required this.participants,
  });

  @override
  Widget build(BuildContext context) {
    // Sort by net balance (highest to lowest)
    final sortedEntries = personSummaries.entries.toList()
      ..sort((a, b) => b.value.netBase.compareTo(a.value.netBase));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Everyone\'s Summary',
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
                columns: const [
                  DataColumn(label: Text('Person')),
                  DataColumn(label: Text('Paid'), numeric: true),
                  DataColumn(label: Text('Owed'), numeric: true),
                  DataColumn(label: Text('Balance'), numeric: true),
                ],
                rows: sortedEntries.map((entry) {
                  final userId = entry.key;
                  final summary = entry.value;
                  final userName = _getParticipantName(userId);

                  // Determine color based on net balance
                  final isPositive = summary.netBase > Decimal.zero;
                  final isNegative = summary.netBase < Decimal.zero;
                  final balanceColor = isPositive
                      ? Colors.green.shade700
                      : isNegative
                          ? Colors.red.shade700
                          : Theme.of(context).colorScheme.onSurface;

                  return DataRow(
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
                            summary.totalPaidBase,
                            baseCurrency,
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          Formatters.formatCurrency(
                            summary.totalOwedBase,
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
                                summary.netBase.abs(),
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
              children: [
                _buildLegendItem(
                  context,
                  Icons.arrow_upward,
                  'Gets money back',
                  Colors.green.shade700,
                ),
                _buildLegendItem(
                  context,
                  Icons.arrow_downward,
                  'Owes money',
                  Colors.red.shade700,
                ),
                _buildLegendItem(
                  context,
                  Icons.remove,
                  'Even',
                  Theme.of(context).colorScheme.onSurface,
                ),
              ],
            ),
          ],
        ),
      ),
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
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
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
