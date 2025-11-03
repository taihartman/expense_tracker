import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/models/participant.dart';
import '../../../../core/l10n/l10n_extensions.dart';
import '../cubits/trip_cubit.dart';
import '../../../device_pairing/presentation/cubits/device_pairing_cubit.dart';
import '../../../device_pairing/presentation/widgets/code_generation_dialog.dart';
import 'delete_participant_dialog.dart';

/// Trip Settings Participant Card
///
/// Displays participant information with actions:
/// - QR code generation for device pairing
/// - Delete participant
///
/// Touch targets are minimum 44x44px for accessibility.
class TripSettingsParticipantCard extends StatelessWidget {
  final String tripId;
  final Participant participant;
  final VoidCallback? onDeleted;

  const TripSettingsParticipantCard({
    super.key,
    required this.tripId,
    required this.participant,
    this.onDeleted,
  });

  @override
  Widget build(BuildContext context) {
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
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Generate Code button (44x44 touch target)
            IconButton(
              icon: const Icon(Icons.qr_code),
              color: colorScheme.primary,
              tooltip: context.l10n.tripSettingsGenerateQrCodeTooltip,
              onPressed: () => _showGenerateCodeDialog(context),
              // Ensures minimum 44x44 touch target
              constraints: const BoxConstraints(
                minWidth: 44,
                minHeight: 44,
              ),
            ),
            // Delete button (44x44 touch target)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              color: colorScheme.error,
              tooltip: context.l10n.tripSettingsDeleteParticipantTooltip,
              onPressed: () => _handleDeleteParticipant(context),
              // Ensures minimum 44x44 touch target
              constraints: const BoxConstraints(
                minWidth: 44,
                minHeight: 44,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showGenerateCodeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider<DevicePairingCubit>.value(
        value: context.read<DevicePairingCubit>(),
        child: CodeGenerationDialog(
          tripId: tripId,
          memberName: participant.name,
        ),
      ),
    );
  }

  void _handleDeleteParticipant(BuildContext context) {
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
            final currentUser = context
                .read<TripCubit>()
                .getCurrentUserForTrip(tripId);
            final actorName = currentUser?.name;

            await context.read<TripCubit>().removeParticipant(
              tripId: tripId,
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
              onDeleted?.call();
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
}
