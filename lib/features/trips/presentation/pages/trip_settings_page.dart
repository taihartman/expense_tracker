import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/models/participant.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../cubits/trip_cubit.dart';
import '../cubits/trip_state.dart';
import '../widgets/participant_form_bottom_sheet.dart';
import '../widgets/delete_participant_dialog.dart';
import '../widgets/recovery_code_dialog.dart';
import '../widgets/trip_verification_prompt.dart';
import '../../../../core/l10n/l10n_extensions.dart';
import '../../../device_pairing/presentation/cubits/device_pairing_cubit.dart';
import '../../../device_pairing/presentation/widgets/code_generation_dialog.dart';

/// Trip Settings Page
///
/// Allows users to:
/// - View and edit trip details
/// - Manage trip-specific participants (add/remove)
/// - View trip metadata
class TripSettingsPage extends StatelessWidget {
  final String tripId;

  const TripSettingsPage({super.key, required this.tripId});

  @override
  Widget build(BuildContext context) {
    // Check if user has verified their identity for this trip
    final tripCubit = context.read<TripCubit>();
    if (!tripCubit.isUserMemberOf(tripId)) {
      return Scaffold(
        appBar: AppBar(
          title: Text(context.l10n.tripSettingsTitle),
          elevation: 0,
        ),
        body: TripVerificationPrompt(tripId: tripId),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.tripSettingsTitle),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: context.l10n.tripBackToExpenses,
          onPressed: () {
            context.pop();
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: context.l10n.commonEdit,
            onPressed: () {
              context.push(AppRoutes.tripEdit(tripId));
            },
          ),
        ],
      ),
      body: BlocBuilder<TripCubit, TripState>(
        builder: (context, state) {
          if (state is TripLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is TripError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: AppTheme.spacing2),
                  Text(
                    context.l10n.tripSettingsLoadError,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppTheme.spacing1),
                  Text(
                    state.message,
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppTheme.spacing3),
                  ElevatedButton.icon(
                    onPressed: () {
                      context.read<TripCubit>().loadTrips();
                    },
                    icon: const Icon(Icons.refresh),
                    label: Text(context.l10n.commonRetry),
                  ),
                ],
              ),
            );
          }

          if (state is TripLoaded) {
            final trip = state.trips.firstWhere(
              (t) => t.id == tripId,
              orElse: () => throw Exception('Trip not found'),
            );

            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.spacing2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Trip Details Section
                  _buildSectionHeader(context, 'Trip Details'),
                  const SizedBox(height: AppTheme.spacing2),
                  _buildTripDetailsCard(context, trip),
                  const SizedBox(height: AppTheme.spacing4),

                  // Recovery Code Section
                  _buildSectionHeader(
                    context,
                    context.l10n.tripRecoverySectionTitle,
                  ),
                  const SizedBox(height: AppTheme.spacing2),
                  _buildRecoveryCodeCard(context, trip.id, trip.name),
                  const SizedBox(height: AppTheme.spacing2),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              context.push(AppRoutes.tripInvite(tripId)),
                          icon: const Icon(Icons.person_add_alt_1),
                          label: Text(context.l10n.tripInviteTitle),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.all(AppTheme.spacing2),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacing2),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              context.push(AppRoutes.tripActivity(tripId)),
                          icon: const Icon(Icons.history),
                          label: const Text('Activity'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.all(AppTheme.spacing2),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacing4),

                  // Participants Section
                  _buildSectionHeader(
                    context,
                    '${context.l10n.participantSectionTitle} (${trip.participants.length})',
                  ),
                  const SizedBox(height: AppTheme.spacing2),

                  if (trip.participants.isEmpty)
                    _buildEmptyState(context)
                  else
                    _buildParticipantsList(context, trip),

                  const SizedBox(height: AppTheme.spacing4),

                  // Archive Section
                  _buildSectionHeader(context, 'Archive'),
                  const SizedBox(height: AppTheme.spacing2),
                  _buildArchiveCard(context, trip),

                  const SizedBox(height: AppTheme.spacing4),

                  // Danger Zone Section
                  _buildSectionHeader(context, 'Danger Zone'),
                  const SizedBox(height: AppTheme.spacing2),
                  _buildDangerZoneCard(context, trip),
                ],
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: BlocBuilder<TripCubit, TripState>(
        builder: (context, state) {
          if (state is TripLoaded) {
            return FloatingActionButton.extended(
              onPressed: () => _showAddParticipantSheet(context),
              icon: const Icon(Icons.person_add),
              label: Text(context.l10n.participantAddButton),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        color: Theme.of(context).colorScheme.primary,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildTripDetailsCard(BuildContext context, trip) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing2),
        child: Column(
          children: [
            _buildDetailRow(
              context,
              icon: Icons.trip_origin,
              label: context.l10n.tripFieldNameLabel,
              value: trip.name,
            ),
            const Divider(height: AppTheme.spacing3),
            _buildDetailRow(
              context,
              icon: Icons.attach_money,
              label: context.l10n.tripFieldBaseCurrencyLabel,
              value: trip.baseCurrency.code,
            ),
            const Divider(height: AppTheme.spacing3),
            _buildDetailRow(
              context,
              icon: Icons.calendar_today,
              label: context.l10n.tripFieldCreatedLabel,
              value: _formatDate(trip.createdAt),
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

  Widget _buildEmptyState(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing4),
        child: Column(
          children: [
            Icon(
              Icons.person_outline,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: AppTheme.spacing2),
            Text(
              context.l10n.participantEmptyStateTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppTheme.spacing1),
            Text(
              context.l10n.participantEmptyStateDescription,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParticipantsList(BuildContext context, trip) {
    // Responsive layout: 2 columns on tablet+, 1 column on mobile
    final isMobile = AppTheme.isMobile(context);

    if (isMobile) {
      return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: trip.participants.length,
        separatorBuilder: (context, index) =>
            const SizedBox(height: AppTheme.spacing1),
        itemBuilder: (context, index) {
          return _buildParticipantCard(context, trip, trip.participants[index]);
        },
      );
    } else {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: AppTheme.spacing2,
          crossAxisSpacing: AppTheme.spacing2,
          childAspectRatio: 4,
        ),
        itemCount: trip.participants.length,
        itemBuilder: (context, index) {
          return _buildParticipantCard(context, trip, trip.participants[index]);
        },
      );
    }
  }

  Widget _buildParticipantCard(
    BuildContext context,
    trip,
    Participant participant,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    // Generate avatar color based on participant ID
    final colors = [
      colorScheme.primary,
      colorScheme.secondary,
      colorScheme.tertiary,
      Colors.orange,
      Colors.purple,
      Colors.teal,
    ];
    final colorIndex = participant.id.hashCode % colors.length;
    final avatarColor = colors[colorIndex];

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Color.fromRGBO(
            (avatarColor.r * 255.0).round() & 0xff,
            (avatarColor.g * 255.0).round() & 0xff,
            (avatarColor.b * 255.0).round() & 0xff,
            0.2,
          ),
          foregroundColor: avatarColor,
          child: Text(
            participant.name[0].toUpperCase(),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(participant.name),
        subtitle: Text(
          participant.id,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Generate Code button
            IconButton(
              icon: const Icon(Icons.qr_code),
              color: colorScheme.primary,
              tooltip: 'Generate Code',
              onPressed: () =>
                  _showGenerateCodeDialog(context, trip.id, participant.name),
            ),
            // Delete button
            IconButton(
              icon: const Icon(Icons.delete_outline),
              color: colorScheme.error,
              tooltip: context.l10n.participantRemoveTooltip,
              onPressed: () =>
                  _handleDeleteParticipant(context, trip, participant),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddParticipantSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) => BlocProvider.value(
        value: context.read<TripCubit>(),
        child: ParticipantFormBottomSheet(
          tripId: tripId,
          onParticipantAdded: (participant) {
            Navigator.of(sheetContext).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  context.l10n.participantAddedSuccess(participant.name),
                ),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        ),
      ),
    );
  }

  void _showGenerateCodeDialog(
    BuildContext context,
    String tripId,
    String memberName,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider<DevicePairingCubit>.value(
        value: context.read<DevicePairingCubit>(),
        child: CodeGenerationDialog(tripId: tripId, memberName: memberName),
      ),
    );
  }

  void _handleDeleteParticipant(
    BuildContext context,
    trip,
    Participant participant,
  ) {
    // TODO: Check if participant is used in expenses
    final expenseCount = 0; // Placeholder - will implement later

    showDialog(
      context: context,
      builder: (dialogContext) => DeleteParticipantDialog(
        participantName: participant.name,
        expenseCount: expenseCount,
        onConfirm: () async {
          Navigator.of(dialogContext).pop();

          try {
            // Get current user for activity logging
            final currentUser = context.read<TripCubit>().getCurrentUserForTrip(
              trip.id,
            );
            final actorName = currentUser?.name;

            await context.read<TripCubit>().removeParticipant(
              tripId: trip.id,
              participant: participant,
              actorName: actorName,
            );

            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('✓ ${participant.name} removed'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to remove participant: $e'),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
              );
            }
          }
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Build recovery code card with generate/view options
  Widget _buildRecoveryCodeCard(
    BuildContext context,
    String tripId,
    String tripName,
  ) {
    return FutureBuilder<bool>(
      future: context.read<TripCubit>().hasRecoveryCode(tripId),
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
                        'Emergency access for trip recovery',
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
                      onPressed: () =>
                          _showRecoveryCodeDialog(context, tripId, tripName),
                      icon: const Icon(Icons.visibility),
                      label: Text(context.l10n.tripRecoveryViewButton),
                    ),
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          _generateRecoveryCode(context, tripId, tripName),
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
  Future<void> _generateRecoveryCode(
    BuildContext context,
    String tripId,
    String tripName,
  ) async {
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
            child: const Text('Generate'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      final code = await context.read<TripCubit>().generateRecoveryCode(tripId);

      if (!context.mounted) return;

      // Show the generated code
      await _showGeneratedCodeDialog(context, code, tripId, tripName);

      // Refresh the UI
      if (context.mounted) {
        // Trigger rebuild by calling setState on parent
        (context as Element).markNeedsBuild();
      }
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to generate recovery code: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  /// Show generated recovery code dialog
  Future<void> _showGeneratedCodeDialog(
    BuildContext context,
    String code,
    String tripId,
    String tripName,
  ) async {
    await showDialog(
      context: context,
      builder: (dialogContext) => RecoveryCodeDialog(
        code: code,
        tripId: tripId,
        tripName: tripName,
        isFirstTime: false, // User is viewing existing code from settings
      ),
    );
  }

  /// Show existing recovery code
  Future<void> _showRecoveryCodeDialog(
    BuildContext context,
    String tripId,
    String tripName,
  ) async {
    final recoveryCode = await context.read<TripCubit>().getRecoveryCode(
      tripId,
    );

    if (!context.mounted || recoveryCode == null) return;

    await showDialog(
      context: context,
      builder: (dialogContext) => RecoveryCodeDialog(
        code: recoveryCode.code,
        tripId: tripId,
        tripName: tripName,
        isFirstTime: false,
        usageCount: recoveryCode.usedCount,
      ),
    );
  }

  /// Build archive card
  Widget _buildArchiveCard(BuildContext context, trip) {
    final isArchived = trip.isArchived;

    return Card(
      child: ListTile(
        leading: Icon(
          isArchived ? Icons.unarchive : Icons.archive,
          color: Theme.of(context).colorScheme.secondary,
        ),
        title: Text(
          isArchived
              ? context.l10n.tripUnarchiveButton
              : context.l10n.tripArchiveButton,
        ),
        subtitle: Text(
          isArchived
              ? 'Restore this trip to the active trip list'
              : 'Hide this trip from the main trip list',
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        onTap: () => isArchived
            ? _handleUnarchiveTrip(context, trip)
            : _handleArchiveTrip(context, trip),
      ),
    );
  }

  /// Build danger zone card with destructive actions
  Widget _buildDangerZoneCard(BuildContext context, trip) {
    return Card(
      color: Theme.of(
        context,
      ).colorScheme.errorContainer.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Leave this trip',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            const SizedBox(height: AppTheme.spacing1),
            Text(
              'You will lose access to this trip and need an invite to rejoin.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppTheme.spacing2),
            OutlinedButton.icon(
              onPressed: () => _handleLeaveTrip(context, trip),
              icon: const Icon(Icons.exit_to_app),
              label: Text(context.l10n.tripLeaveButton),
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
                side: BorderSide(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Handle archive trip action
  Future<void> _handleArchiveTrip(BuildContext context, trip) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.tripArchiveDialogTitle),
        content: Text(
          'This will hide "${trip.name}" from your active trip list. '
          'You can restore it later from the archived trips section.',
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
      final currentUser = context.read<TripCubit>().getCurrentUserForTrip(
        trip.id,
      );
      final actorName = currentUser?.name;

      await context.read<TripCubit>().archiveTrip(
        trip.id,
        actorName: actorName,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${context.l10n.tripArchiveSuccess}: "${trip.name}"'),
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
  Future<void> _handleUnarchiveTrip(BuildContext context, trip) async {
    try {
      // Get current user for activity logging
      final currentUser = context.read<TripCubit>().getCurrentUserForTrip(
        trip.id,
      );
      final actorName = currentUser?.name;

      await context.read<TripCubit>().unarchiveTrip(
        trip.id,
        actorName: actorName,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${context.l10n.tripUnarchiveSuccess}: "${trip.name}"',
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
  Future<void> _handleLeaveTrip(BuildContext context, trip) async {
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
      final tripName = trip.name;
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
