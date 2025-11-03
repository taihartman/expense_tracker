import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/l10n/l10n_extensions.dart';
import '../cubits/trip_cubit.dart';
import 'recovery_code_dialog.dart';

/// Recovery Code Card
///
/// Displays recovery code management:
/// - Generate recovery code button (if no code exists)
/// - View recovery code button (if code exists)
class RecoveryCodeCard extends StatefulWidget {
  final String tripId;
  final String tripName;

  const RecoveryCodeCard({
    super.key,
    required this.tripId,
    required this.tripName,
  });

  @override
  State<RecoveryCodeCard> createState() => _RecoveryCodeCardState();
}

class _RecoveryCodeCardState extends State<RecoveryCodeCard> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: context.read<TripCubit>().hasRecoveryCode(widget.tripId),
      builder: (context, snapshot) {
        final hasCode = snapshot.data ?? false;
        final isLoading = snapshot.connectionState == ConnectionState.waiting;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacing2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.shield_outlined,
                      size: 20,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: AppTheme.spacing2),
                    Expanded(
                      child: Text(
                        context.l10n.tripSettingsRecoveryCodeDescription,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacing2),
                if (isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (hasCode)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _showRecoveryCodeDialog(context),
                      icon: const Icon(Icons.visibility),
                      label: Text(context.l10n.tripRecoveryViewButton),
                    ),
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _generateRecoveryCode(context),
                      icon: const Icon(Icons.add),
                      label: Text(context.l10n.tripRecoveryGenerateButton),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Generate recovery code for the trip
  Future<void> _generateRecoveryCode(BuildContext context) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.tripRecoveryGenerateDialogTitle),
        content: Text(context.l10n.tripRecoveryGenerateDialogMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(context.l10n.commonCancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(context.l10n.tripRecoveryGenerateButton),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      final code =
          await context.read<TripCubit>().generateRecoveryCode(widget.tripId);

      if (!context.mounted) return;

      // Show the generated code
      await _showGeneratedCodeDialog(context, code);

      // Refresh the UI
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.l10n.tripRecoveryCopyFailed(e.toString()),
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  /// Show generated recovery code dialog
  Future<void> _showGeneratedCodeDialog(
    BuildContext context,
    String code,
  ) async {
    await showDialog(
      context: context,
      builder: (dialogContext) => RecoveryCodeDialog(
        code: code,
        tripId: widget.tripId,
        tripName: widget.tripName,
        isFirstTime: false, // User is viewing existing code from settings
      ),
    );
  }

  /// Show existing recovery code
  Future<void> _showRecoveryCodeDialog(BuildContext context) async {
    final recoveryCode = await context.read<TripCubit>().getRecoveryCode(
      widget.tripId,
    );

    if (!context.mounted || recoveryCode == null) return;

    await showDialog(
      context: context,
      builder: (dialogContext) => RecoveryCodeDialog(
        code: recoveryCode.code,
        tripId: widget.tripId,
        tripName: widget.tripName,
        isFirstTime: false,
        usageCount: recoveryCode.usedCount,
      ),
    );
  }
}
