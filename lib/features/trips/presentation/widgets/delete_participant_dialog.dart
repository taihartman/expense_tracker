import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

/// Dialog for confirming participant deletion
///
/// Shows different UI based on whether the participant has expenses:
/// - No expenses: Simple confirmation dialog
/// - Has expenses: Warning dialog that blocks deletion
class DeleteParticipantDialog extends StatelessWidget {
  final String participantName;
  final int expenseCount;
  final VoidCallback onConfirm;

  const DeleteParticipantDialog({
    super.key,
    required this.participantName,
    required this.expenseCount,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    if (expenseCount > 0) {
      return _buildWarningDialog(context);
    } else {
      return _buildConfirmationDialog(context);
    }
  }

  Widget _buildConfirmationDialog(BuildContext context) {
    return AlertDialog(
      title: const Text('Remove Participant?'),
      content: Text(
        'Are you sure you want to remove $participantName from this trip?\n\nThis action cannot be undone.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: onConfirm,
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.error,
          ),
          child: const Text('Remove'),
        ),
      ],
    );
  }

  Widget _buildWarningDialog(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      icon: Icon(
        Icons.warning_amber_rounded,
        color: colorScheme.error,
        size: 48,
      ),
      title: const Text('Cannot Remove Participant'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$participantName is used in $expenseCount ${expenseCount == 1 ? 'expense' : 'expenses'} and cannot be removed.',
          ),
          const SizedBox(height: AppTheme.spacing2),
          Container(
            padding: const EdgeInsets.all(AppTheme.spacing2),
            decoration: BoxDecoration(
              color: Color.fromRGBO(
                colorScheme.errorContainer.red,
                colorScheme.errorContainer.green,
                colorScheme.errorContainer.blue,
                0.3,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'To remove this participant:',
                  style: theme.textTheme.labelLarge,
                ),
                const SizedBox(height: AppTheme.spacing1),
                Text(
                  '1. Delete or reassign their expenses\n2. Try removing them again',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Got It'),
        ),
      ],
    );
  }
}
