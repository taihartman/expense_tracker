import 'package:flutter/material.dart';
import '../../domain/models/activity_log.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/time_utils.dart';

/// Widget that displays a single activity log entry
class ActivityLogItem extends StatelessWidget {
  final ActivityLog log;

  const ActivityLogItem({super.key, required this.log});

  @override
  Widget build(BuildContext context) {
    final icon = _getIconForActivityType(log.type);
    final color = _getColorForActivityType(context, log.type);

    return Tooltip(
      message: formatAbsoluteTime(log.timestamp),
      child: Card(
        margin: const EdgeInsets.only(bottom: AppTheme.spacing1),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.1),
            foregroundColor: color,
            child: Icon(icon, size: 20),
          ),
          title: RichText(
            text: TextSpan(
              style: Theme.of(context).textTheme.bodyMedium,
              children: [
                TextSpan(
                  text: log.actorName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: ' ${_getActionText(log.type)}'),
              ],
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (log.description.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  log.description,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: 4),
              Text(
                formatRelativeTime(log.timestamp),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconForActivityType(ActivityType type) {
    switch (type) {
      case ActivityType.tripCreated:
        return Icons.add_circle;
      case ActivityType.memberJoined:
        return Icons.person_add;
      case ActivityType.expenseAdded:
        return Icons.receipt_long;
      case ActivityType.expenseEdited:
        return Icons.edit;
      case ActivityType.expenseDeleted:
        return Icons.delete;
    }
  }

  Color _getColorForActivityType(BuildContext context, ActivityType type) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (type) {
      case ActivityType.tripCreated:
      case ActivityType.memberJoined:
        return colorScheme.primary;
      case ActivityType.expenseAdded:
        return Colors.green;
      case ActivityType.expenseEdited:
        return Colors.orange;
      case ActivityType.expenseDeleted:
        return colorScheme.error;
    }
  }

  String _getActionText(ActivityType type) {
    switch (type) {
      case ActivityType.tripCreated:
        return 'created the trip';
      case ActivityType.memberJoined:
        return 'joined the trip';
      case ActivityType.expenseAdded:
        return 'added an expense';
      case ActivityType.expenseEdited:
        return 'edited an expense';
      case ActivityType.expenseDeleted:
        return 'deleted an expense';
    }
  }
}
