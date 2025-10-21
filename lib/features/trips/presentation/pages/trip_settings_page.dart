import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/models/participant.dart';
import '../../../../core/theme/app_theme.dart';
import '../cubits/trip_cubit.dart';
import '../cubits/trip_state.dart';
import '../widgets/participant_form_bottom_sheet.dart';
import '../widgets/delete_participant_dialog.dart';

/// Trip Settings Page
///
/// Allows users to:
/// - View and edit trip details
/// - Manage trip-specific participants (add/remove)
/// - View trip metadata
class TripSettingsPage extends StatelessWidget {
  final String tripId;

  const TripSettingsPage({
    super.key,
    required this.tripId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip Settings'),
        elevation: 0,
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
                    'Failed to load trip settings',
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
                    label: const Text('Retry'),
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

                  // Participants Section
                  _buildSectionHeader(
                    context,
                    'Participants (${trip.participants.length})',
                  ),
                  const SizedBox(height: AppTheme.spacing2),

                  if (trip.participants.isEmpty)
                    _buildEmptyState(context)
                  else
                    _buildParticipantsList(context, trip),
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
              label: const Text('Add Participant'),
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
              label: 'Trip Name',
              value: trip.name,
            ),
            const Divider(height: AppTheme.spacing3),
            _buildDetailRow(
              context,
              icon: Icons.attach_money,
              label: 'Base Currency',
              value: trip.baseCurrency.code,
            ),
            const Divider(height: AppTheme.spacing3),
            _buildDetailRow(
              context,
              icon: Icons.calendar_today,
              label: 'Created',
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
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.primary,
        ),
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
              Text(
                value,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
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
              'No participants added yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppTheme.spacing1),
            Text(
              'Tap the + button below to add your first participant',
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
        separatorBuilder: (context, index) => const SizedBox(height: AppTheme.spacing1),
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

  Widget _buildParticipantCard(BuildContext context, trip, Participant participant) {
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
            avatarColor.red,
            avatarColor.green,
            avatarColor.blue,
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
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          color: colorScheme.error,
          tooltip: 'Remove ${participant.name}',
          onPressed: () => _handleDeleteParticipant(context, trip, participant),
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
      builder: (sheetContext) => ParticipantFormBottomSheet(
        tripId: tripId,
        onParticipantAdded: (participant) {
          Navigator.of(sheetContext).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✓ ${participant.name} added successfully'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
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

          // Remove participant from trip
          final updatedParticipants = List<Participant>.from(trip.participants)
            ..remove(participant);

          final updatedTrip = trip.copyWith(
            participants: updatedParticipants,
            updatedAt: DateTime.now(),
          );

          try {
            await context.read<TripCubit>().updateTrip(updatedTrip);

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
}
