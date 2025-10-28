import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/l10n/l10n_extensions.dart';

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
      title: Text(context.l10n.participantDeleteDialogTitle),
      content: Text(
        context.l10n.participantDeleteDialogMessage(participantName),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.l10n.commonCancel),
        ),
        TextButton(
          onPressed: onConfirm,
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.error,
          ),
          child: Text(context.l10n.participantRemoveButton),
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
      title: Text(context.l10n.participantDeleteDialogCannotRemoveTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.participantDeleteDialogCannotRemoveMessage(
              participantName,
              expenseCount,
            ),
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
                  context.l10n.participantDeleteDialogInstructionsHeader,
                  style: theme.textTheme.labelLarge,
                ),
                const SizedBox(height: AppTheme.spacing1),
                Text(
                  context.l10n.participantDeleteDialogInstructions,
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
          child: Text(context.l10n.commonGotIt),
        ),
      ],
    );
  }
}
