import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/l10n/l10n_extensions.dart';

/// Trip Details Card
///
/// Displays read-only trip information:
/// - Trip name
/// - Base currency
/// - Created date
class TripDetailsCard extends StatelessWidget {
  final String tripName;
  final String baseCurrencyCode;
  final DateTime createdAt;

  const TripDetailsCard({
    super.key,
    required this.tripName,
    required this.baseCurrencyCode,
    required this.createdAt,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing2),
        child: Column(
          children: [
            _buildDetailRow(
              context,
              icon: Icons.trip_origin,
              label: context.l10n.tripFieldNameLabel,
              value: tripName,
            ),
            const Divider(height: AppTheme.spacing3),
            _buildDetailRow(
              context,
              icon: Icons.attach_money,
              label: context.l10n.tripFieldBaseCurrencyLabel,
              value: baseCurrencyCode,
            ),
            const Divider(height: AppTheme.spacing3),
            _buildDetailRow(
              context,
              icon: Icons.calendar_today,
              label: context.l10n.tripFieldCreatedLabel,
              value: _formatDate(createdAt),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: AppTheme.spacing2),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(value, style: Theme.of(context).textTheme.bodyLarge),
            ],
          ),
        ),
      ],
    );
  }

  /// Format date using localized date formatter
  String _formatDate(DateTime date) {
    return DateFormat.yMd().format(date);
  }
}
