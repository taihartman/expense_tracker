import 'package:flutter/material.dart';
import '../../../../core/constants/participants.dart';
import '../../../../core/models/participant.dart';
import '../../../../core/models/split_type.dart';
import '../../../../core/theme/app_theme.dart';

/// Widget for selecting participants and their weights/shares
///
/// For Equal split: Shows checkboxes for participant selection
/// For Weighted split: Shows text fields for entering weights
class ParticipantSelector extends StatefulWidget {
  final SplitType splitType;
  final Map<String, num> selectedParticipants;
  final ValueChanged<Map<String, num>> onParticipantsChanged;

  /// Available participants for this trip
  /// If null, uses the global default list for backward compatibility
  final List<Participant>? availableParticipants;

  const ParticipantSelector({
    required this.splitType,
    required this.selectedParticipants,
    required this.onParticipantsChanged,
    this.availableParticipants,
    super.key,
  });

  @override
  State<ParticipantSelector> createState() => _ParticipantSelectorState();
}

class _ParticipantSelectorState extends State<ParticipantSelector> {
  // Controllers for weighted split - properly managed lifecycle
  final Map<String, TextEditingController> _weightControllers = {};

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  @override
  void didUpdateWidget(ParticipantSelector oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Recreate controllers if split type changed to weighted
    if (oldWidget.splitType != widget.splitType && widget.splitType == SplitType.weighted) {
      _disposeControllers();
      _initializeControllers();
    }

    // Update controller values if selected participants changed
    if (oldWidget.selectedParticipants != widget.selectedParticipants) {
      _updateControllerValues();
    }
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  List<Participant> get _participants =>
      widget.availableParticipants ?? Participants.all;

  void _initializeControllers() {
    if (widget.splitType == SplitType.weighted) {
      for (final participant in _participants) {
        final weight = widget.selectedParticipants[participant.id];
        _weightControllers[participant.id] = TextEditingController(
          text: weight?.toString() ?? '',
        );
      }
    }
  }

  void _updateControllerValues() {
    if (widget.splitType == SplitType.weighted) {
      for (final participant in _participants) {
        final controller = _weightControllers[participant.id];
        final weight = widget.selectedParticipants[participant.id];
        final newText = weight?.toString() ?? '';

        // Only update if different to avoid cursor jumps
        if (controller != null && controller.text != newText) {
          controller.text = newText;
        }
      }
    }
  }

  void _disposeControllers() {
    for (final controller in _weightControllers.values) {
      controller.dispose();
    }
    _weightControllers.clear();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "WHO'S SPLITTING?",
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppTheme.spacing1),
        if (widget.splitType == SplitType.equal)
          ..._buildEqualSplitParticipants(theme)
        else
          ..._buildWeightedSplitParticipants(theme),
      ],
    );
  }

  List<Widget> _buildEqualSplitParticipants(ThemeData theme) {
    // Use Wrap for better responsive layout
    return [
      Wrap(
        spacing: AppTheme.spacing1,
        runSpacing: 4,
        children: _participants.map((participant) {
          final isSelected = widget.selectedParticipants.containsKey(participant.id);
          return FilterChip(
            label: Text(participant.name),
            selected: isSelected,
            onSelected: (value) {
              final updatedParticipants = Map<String, num>.from(widget.selectedParticipants);
              if (value) {
                updatedParticipants[participant.id] = 1;
              } else {
                updatedParticipants.remove(participant.id);
              }
              widget.onParticipantsChanged(updatedParticipants);
            },
            selectedColor: theme.colorScheme.primaryContainer,
            checkmarkColor: theme.colorScheme.onPrimaryContainer,
          );
        }).toList(),
      ),
    ];
  }

  List<Widget> _buildWeightedSplitParticipants(ThemeData theme) {
    return _participants.map((participant) {
      final controller = _weightControllers[participant.id]!;
      final isSelected = widget.selectedParticipants.containsKey(participant.id);

      return Padding(
        padding: const EdgeInsets.only(bottom: AppTheme.spacing1),
        child: Row(
          children: [
            Expanded(
              child: Text(
                participant.name,
                style: theme.textTheme.bodyLarge,
              ),
            ),
            SizedBox(
              width: 100,
              child: TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Weight',
                  hintText: '0',
                  border: const OutlineInputBorder(),
                  filled: isSelected,
                  fillColor: isSelected
                    ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
                    : null,
                ),
                onChanged: (value) {
                  final updatedParticipants = Map<String, num>.from(widget.selectedParticipants);
                  if (value.isEmpty) {
                    updatedParticipants.remove(participant.id);
                  } else {
                    final numValue = num.tryParse(value);
                    if (numValue != null && numValue > 0) {
                      updatedParticipants[participant.id] = numValue;
                    }
                  }
                  widget.onParticipantsChanged(updatedParticipants);
                },
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
}
