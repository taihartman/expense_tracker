import 'package:flutter/material.dart';
import '../../../../core/constants/participants.dart';
import '../../../../core/models/split_type.dart';
import '../../../../core/theme/app_theme.dart';

/// Widget for selecting participants and their weights/shares
///
/// For Equal split: Shows checkboxes for participant selection
/// For Weighted split: Shows text fields for entering weights
class ParticipantSelector extends StatelessWidget {
  final SplitType splitType;
  final Map<String, num> selectedParticipants;
  final ValueChanged<Map<String, num>> onParticipantsChanged;

  const ParticipantSelector({
    required this.splitType,
    required this.selectedParticipants,
    required this.onParticipantsChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Participants',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: AppTheme.spacing1),
        if (splitType == SplitType.equal)
          ..._buildEqualSplitParticipants()
        else
          ..._buildWeightedSplitParticipants(),
      ],
    );
  }

  List<Widget> _buildEqualSplitParticipants() {
    return Participants.all.map((participant) {
      final isSelected = selectedParticipants.containsKey(participant.id);
      return CheckboxListTile(
        title: Text(participant.name),
        value: isSelected,
        onChanged: (value) {
          final updatedParticipants = Map<String, num>.from(selectedParticipants);
          if (value == true) {
            updatedParticipants[participant.id] = 1;
          } else {
            updatedParticipants.remove(participant.id);
          }
          onParticipantsChanged(updatedParticipants);
        },
      );
    }).toList();
  }

  List<Widget> _buildWeightedSplitParticipants() {
    return Participants.all.map((participant) {
      final weight = selectedParticipants[participant.id];
      return ListTile(
        title: Text(participant.name),
        trailing: SizedBox(
          width: 100,
          child: TextField(
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Weight',
              hintText: '0',
            ),
            controller: TextEditingController(
              text: weight?.toString() ?? '',
            )..selection = TextSelection.collapsed(
                offset: weight?.toString().length ?? 0,
              ),
            onChanged: (value) {
              final updatedParticipants = Map<String, num>.from(selectedParticipants);
              if (value.isEmpty) {
                updatedParticipants.remove(participant.id);
              } else {
                final numValue = num.tryParse(value);
                if (numValue != null && numValue > 0) {
                  updatedParticipants[participant.id] = numValue;
                }
              }
              onParticipantsChanged(updatedParticipants);
            },
          ),
        ),
      );
    }).toList();
  }
}
