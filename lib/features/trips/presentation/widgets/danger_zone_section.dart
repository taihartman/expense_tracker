import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/l10n/l10n_extensions.dart';
import '../../../../core/router/app_routes.dart';
import '../cubits/trip_cubit.dart';

/// Danger Zone Section
///
/// Groups destructive trip actions with strong visual treatment:
/// - Archive/Unarchive trip
/// - Leave trip
///
/// Features:
/// - Red border (2px) for visual emphasis
/// - Red-tinted background (20% opacity)
/// - Clear warnings before destructive actions
class DangerZoneSection extends StatelessWidget {
  final String tripId;
  final String tripName;
  final bool isArchived;

  const DangerZoneSection({
    super.key,
    required this.tripId,
    required this.tripName,
    required this.isArchived,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.error,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).colorScheme.errorContainer.withValues(
          alpha: 0.2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Archive/Unarchive Section
            Row(
              children: [
                Icon(
                  isArchived ? Icons.unarchive : Icons.archive,
                  size: 20,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                const SizedBox(width: AppTheme.spacing2),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isArchived
                            ? context.l10n.tripSettingsUnarchiveTripTitle
                            : context.l10n.tripSettingsArchiveTripTitle,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isArchived
                            ? context.l10n.tripSettingsUnarchiveTripDescription
                            : context.l10n.tripSettingsArchiveTripDescription,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacing2),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => isArchived
                    ? _handleUnarchiveTrip(context)
                    : _handleArchiveTrip(context),
                icon: Icon(isArchived ? Icons.unarchive : Icons.archive),
                label: Text(
                  isArchived
                      ? context.l10n.tripUnarchiveButton
                      : context.l10n.tripArchiveButton,
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.secondary,
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
              ),
            ),

            const Divider(height: AppTheme.spacing4),

            // Leave Trip Section
            Row(
              children: [
                Icon(
                  Icons.exit_to_app,
                  size: 20,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(width: AppTheme.spacing2),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.tripSettingsLeaveTitle,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        context.l10n.tripSettingsLeaveWarning,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacing2),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _handleLeaveTrip(context),
                icon: const Icon(Icons.exit_to_app),
                label: Text(context.l10n.tripLeaveButton),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Handle archive trip action
  Future<void> _handleArchiveTrip(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.tripArchiveDialogTitle),
        content: Text(
          '${context.l10n.tripArchiveDialogMessage}\n\n'
          'Trip: "$tripName"',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(context.l10n.commonCancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.secondary,
            ),
            child: Text(context.l10n.tripArchiveButton),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      // Get current user for activity logging
      final currentUser = await context.read<TripCubit>().getCurrentUserForTrip(
        tripId,
      );
      final actorName = currentUser?.name;

      await context.read<TripCubit>().archiveTrip(
        tripId,
        actorName: actorName,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${context.l10n.tripArchiveSuccess}: "$tripName"'),
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Navigate to home page
        context.go(AppRoutes.home);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to archive trip: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// Handle unarchive trip action
  Future<void> _handleUnarchiveTrip(BuildContext context) async {
    try {
      // Get current user for activity logging
      final currentUser = await context.read<TripCubit>().getCurrentUserForTrip(
        tripId,
      );
      final actorName = currentUser?.name;

      await context.read<TripCubit>().unarchiveTrip(
        tripId,
        actorName: actorName,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${context.l10n.tripUnarchiveSuccess}: "$tripName"',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to unarchive trip: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// Handle leave trip action
  Future<void> _handleLeaveTrip(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.tripLeaveDialogTitle),
        content: Text(context.l10n.tripLeaveDialogMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(context.l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(context.l10n.tripLeaveDialogConfirm),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await context.read<TripCubit>().leaveTrip(tripId);

      if (!context.mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.tripLeftSuccess(tripName))),
      );

      // Navigate to home
      context.go(AppRoutes.home);
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to leave trip: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }
}
