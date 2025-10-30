import 'package:flutter/material.dart';
import '../../../../core/models/participant.dart';

/// A widget that displays a list of participants as radio buttons
/// for the user to select their identity.
///
/// Used in the trip identity selection flow where users need to
/// identify themselves from an existing trip's participant list.
class ParticipantIdentitySelector extends StatelessWidget {
  final List<Participant> participants;
  final Participant? selectedParticipant;
  final ValueChanged<Participant?> onChanged;

  const ParticipantIdentitySelector({
    required this.participants,
    required this.selectedParticipant,
    required this.onChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (participants.isEmpty) {
      return const Center(child: Text('No participants available'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: participants.map((participant) {
        final isSelected = selectedParticipant?.id == participant.id;

        return Card(
          margin: const EdgeInsets.only(bottom: 8.0),
          // ignore: deprecated_member_use
          child: RadioListTile<Participant>(
            value: participant,
            // ignore: deprecated_member_use
            groupValue: selectedParticipant,
            // ignore: deprecated_member_use
            onChanged: onChanged,
            title: Text(
              participant.name,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 16.0,
              ),
            ),
            subtitle: Text(
              'ID: ${participant.id}',
              style: TextStyle(fontSize: 12.0, color: Colors.grey[600]),
            ),
            activeColor: Theme.of(context).primaryColor,
            selected: isSelected,
          ),
        );
      }).toList(),
    );
  }
}
