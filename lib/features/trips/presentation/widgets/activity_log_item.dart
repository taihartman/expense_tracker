import 'package:flutter/material.dart';
import '../../domain/models/activity_log.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/time_utils.dart';
import '../../../../core/l10n/l10n_extensions.dart';

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
              // Show join method metadata for memberJoined activities
              if (log.type == ActivityType.memberJoined &&
                  log.metadata != null) ...[
                const SizedBox(height: 4),
                _buildJoinMethodInfo(context, log.metadata!),
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
      // Trip Management
      case ActivityType.tripCreated:
        return Icons.add_circle;
      case ActivityType.tripUpdated:
        return Icons.edit_note;
      case ActivityType.tripDeleted:
        return Icons.delete_forever;

      // Participant Activities
      case ActivityType.memberJoined:
        return Icons.person_add;
      case ActivityType.participantAdded:
        return Icons.group_add;
      case ActivityType.participantRemoved:
        return Icons.person_remove;

      // Expense Activities
      case ActivityType.expenseAdded:
        return Icons.receipt_long;
      case ActivityType.expenseEdited:
        return Icons.edit;
      case ActivityType.expenseDeleted:
        return Icons.delete;
      case ActivityType.expenseCategoryChanged:
        return Icons.category;
      case ActivityType.expenseSplitModified:
        return Icons.splitscreen;

      // Settlement Activities
      case ActivityType.transferMarkedSettled:
        return Icons.check_circle;
      case ActivityType.transferMarkedUnsettled:
        return Icons.cancel;

      // Device Pairing & Security
      case ActivityType.deviceVerified:
        return Icons.verified_user;
      case ActivityType.recoveryCodeUsed:
        return Icons.security;
    }
  }

  Color _getColorForActivityType(BuildContext context, ActivityType type) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (type) {
      // Trip Management - Primary color
      case ActivityType.tripCreated:
      case ActivityType.tripUpdated:
        return colorScheme.primary;
      case ActivityType.tripDeleted:
        return colorScheme.error;

      // Participant Activities - Primary color
      case ActivityType.memberJoined:
      case ActivityType.participantAdded:
        return colorScheme.primary;
      case ActivityType.participantRemoved:
        return Colors.orange;

      // Expense Activities - Green for add, Orange for edit, Red for delete
      case ActivityType.expenseAdded:
        return Colors.green;
      case ActivityType.expenseEdited:
      case ActivityType.expenseCategoryChanged:
      case ActivityType.expenseSplitModified:
        return Colors.orange;
      case ActivityType.expenseDeleted:
        return colorScheme.error;

      // Settlement Activities - Green for settled, Orange for unsettled
      case ActivityType.transferMarkedSettled:
        return Colors.green;
      case ActivityType.transferMarkedUnsettled:
        return Colors.orange;

      // Device Pairing & Security - Purple/blue for security
      case ActivityType.deviceVerified:
      case ActivityType.recoveryCodeUsed:
        return Colors.purple;
    }
  }

  String _getActionText(ActivityType type) {
    switch (type) {
      // Trip Management
      case ActivityType.tripCreated:
        return 'created the trip';
      case ActivityType.tripUpdated:
        return 'updated the trip';
      case ActivityType.tripDeleted:
        return 'deleted the trip';

      // Participant Activities
      case ActivityType.memberJoined:
        return 'joined the trip';
      case ActivityType.participantAdded:
        return 'added a participant';
      case ActivityType.participantRemoved:
        return 'removed a participant';

      // Expense Activities
      case ActivityType.expenseAdded:
        return 'added an expense';
      case ActivityType.expenseEdited:
        return 'edited an expense';
      case ActivityType.expenseDeleted:
        return 'deleted an expense';
      case ActivityType.expenseCategoryChanged:
        return 'changed expense category';
      case ActivityType.expenseSplitModified:
        return 'modified expense split';

      // Settlement Activities
      case ActivityType.transferMarkedSettled:
        return 'marked a transfer as settled';
      case ActivityType.transferMarkedUnsettled:
        return 'marked a transfer as unsettled';

      // Device Pairing & Security
      case ActivityType.deviceVerified:
        return 'verified a device';
      case ActivityType.recoveryCodeUsed:
        return 'used a recovery code';
    }
  }

  Widget _buildJoinMethodInfo(BuildContext context, Map<String, dynamic> metadata) {
    final joinMethod = metadata['joinMethod'] as String?;
    final invitedBy = metadata['invitedBy'] as String?;
    final l10n = context.l10n;

    // Build description parts
    String? methodText;
    IconData? methodIcon;

    switch (joinMethod) {
      case 'inviteLink':
        methodText = l10n.activityJoinViaLink;
        methodIcon = Icons.link;
        break;
      case 'qrCode':
        methodText = l10n.activityJoinViaQr;
        methodIcon = Icons.qr_code_scanner;
        break;
      case 'manualCode':
        methodText = l10n.activityJoinManual;
        methodIcon = Icons.keyboard;
        break;
      case 'recoveryCode':
        methodText = l10n.activityJoinRecovery;
        methodIcon = Icons.vpn_key;
        break;
    }

    // If no join method, don't show anything
    if (methodText == null) return const SizedBox.shrink();

    return Row(
      children: [
        Icon(
          methodIcon,
          size: 14,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            invitedBy != null ? '$methodText • ${l10n.activityInvitedBy(invitedBy)}' : methodText,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }
}
