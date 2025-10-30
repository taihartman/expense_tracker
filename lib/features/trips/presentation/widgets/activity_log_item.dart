import 'package:flutter/material.dart';
import '../../domain/models/activity_log.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/time_utils.dart';
import '../../../../core/l10n/l10n_extensions.dart';

/// Widget that displays a single activity log entry
class ActivityLogItem extends StatefulWidget {
  final ActivityLog log;

  const ActivityLogItem({super.key, required this.log});

  @override
  State<ActivityLogItem> createState() => _ActivityLogItemState();
}

class _ActivityLogItemState extends State<ActivityLogItem> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final icon = _getIconForActivityType(widget.log.type);
    final color = _getColorForActivityType(context, widget.log.type);
    final hasExpandableContent = _hasExpandableContent();

    return Tooltip(
      message: formatAbsoluteTime(widget.log.timestamp),
      child: Card(
        margin: const EdgeInsets.only(bottom: AppTheme.spacing1),
        child: ListTile(
          onTap: hasExpandableContent
              ? () => setState(() => _isExpanded = !_isExpanded)
              : null,
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
                  text: widget.log.actorName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: ' ${_getActionText(widget.log.type)}'),
              ],
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.log.description.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  widget.log.description,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              // Show join method metadata for memberJoined activities
              if (widget.log.type == ActivityType.memberJoined &&
                  widget.log.metadata != null) ...[
                const SizedBox(height: 4),
                _buildJoinMethodInfo(context, widget.log.metadata!),
              ],
              // Show expandable expense edit details
              if (widget.log.type == ActivityType.expenseEdited &&
                  widget.log.metadata != null &&
                  _isExpanded) ...[
                const SizedBox(height: 8),
                _buildExpenseEditDetails(context, widget.log.metadata!),
              ],
              const SizedBox(height: 4),
              Text(
                formatRelativeTime(widget.log.timestamp),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          trailing: hasExpandableContent
              ? Icon(
                  _isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                )
              : null,
        ),
      ),
    );
  }

  bool _hasExpandableContent() {
    return widget.log.type == ActivityType.expenseEdited &&
        widget.log.metadata != null &&
        widget.log.metadata!['changes'] != null;
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
      case ActivityType.tripArchived:
        return Icons.archive;
      case ActivityType.tripUnarchived:
        return Icons.unarchive;

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
      case ActivityType.tripArchived:
        return Colors.grey;
      case ActivityType.tripUnarchived:
        return colorScheme.primary;

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
      case ActivityType.tripArchived:
        return 'archived the trip';
      case ActivityType.tripUnarchived:
        return 'unarchived the trip';

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

  Widget _buildJoinMethodInfo(
    BuildContext context,
    Map<String, dynamic> metadata,
  ) {
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
            invitedBy != null
                ? '$methodText • ${l10n.activityInvitedBy(invitedBy)}'
                : methodText,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }

  /// Builds detailed change information for expense edits
  Widget _buildExpenseEditDetails(
    BuildContext context,
    Map<String, dynamic> metadata,
  ) {
    final changes = metadata['changes'] as Map<String, dynamic>?;
    if (changes == null || changes.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Changes:',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          ...changes.entries.map(
            (entry) => _buildChangeRow(context, entry.key, entry.value),
          ),
        ],
      ),
    );
  }

  /// Builds a single change row (field name → before → after)
  Widget _buildChangeRow(BuildContext context, String field, dynamic value) {
    if (value is! Map<String, dynamic>) return const SizedBox.shrink();

    final textStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: Theme.of(context).colorScheme.onSurface,
    );

    // Handle different field types
    switch (field) {
      case 'amount':
        return _buildSimpleChange(
          context,
          'Amount',
          value['old'],
          value['new'],
          textStyle,
        );

      case 'currency':
        return _buildSimpleChange(
          context,
          'Currency',
          value['old'],
          value['new'],
          textStyle,
        );

      case 'description':
        return _buildSimpleChange(
          context,
          'Description',
          value['old'],
          value['new'],
          textStyle,
        );

      case 'category':
        return _buildSimpleChange(
          context,
          'Category',
          value['oldName'],
          value['newName'],
          textStyle,
        );

      case 'payer':
        return _buildSimpleChange(
          context,
          'Payer',
          value['oldName'],
          value['newName'],
          textStyle,
        );

      case 'date':
        return _buildSimpleChange(
          context,
          'Date',
          value['old'],
          value['new'],
          textStyle,
        );

      case 'splitType':
        return _buildSimpleChange(
          context,
          'Split type',
          value['old'],
          value['new'],
          textStyle,
        );

      case 'participants':
        return _buildParticipantChanges(context, value, textStyle);

      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildSimpleChange(
    BuildContext context,
    String label,
    String? oldValue,
    String? newValue,
    TextStyle? textStyle,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: textStyle?.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              '${oldValue ?? 'None'} → ${newValue ?? 'None'}',
              style: textStyle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantChanges(
    BuildContext context,
    Map<String, dynamic> participantData,
    TextStyle? textStyle,
  ) {
    final List<Widget> changeWidgets = [];

    // Added participants
    final added = participantData['added'] as List<dynamic>?;
    if (added != null && added.isNotEmpty) {
      final names = added.map((p) => p['name'] as String).join(', ');
      changeWidgets.add(
        _buildSimpleChange(context, 'Added', null, names, textStyle),
      );
    }

    // Removed participants
    final removed = participantData['removed'] as List<dynamic>?;
    if (removed != null && removed.isNotEmpty) {
      final names = removed.map((p) => p['name'] as String).join(', ');
      changeWidgets.add(
        _buildSimpleChange(context, 'Removed', names, null, textStyle),
      );
    }

    // Weight changes
    final weightsChanged = participantData['weightsChanged'] as List<dynamic>?;
    if (weightsChanged != null && weightsChanged.isNotEmpty) {
      for (final change in weightsChanged) {
        final name = change['name'] as String;
        final oldWeight = change['oldWeight'];
        final newWeight = change['newWeight'];
        changeWidgets.add(
          _buildSimpleChange(
            context,
            'Weight ($name)',
            oldWeight.toString(),
            newWeight.toString(),
            textStyle,
          ),
        );
      }
    }

    if (changeWidgets.isEmpty) return const SizedBox.shrink();

    return Column(children: changeWidgets);
  }
}
