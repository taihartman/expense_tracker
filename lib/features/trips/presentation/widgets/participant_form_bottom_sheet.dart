import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/models/participant.dart';
import '../../../../core/theme/app_theme.dart';
import '../cubits/trip_cubit.dart';
import '../cubits/trip_state.dart';
import '../../../../core/l10n/l10n_extensions.dart';

/// Bottom sheet for adding a new participant to a trip
///
/// Features:
/// - Auto-generates participant ID from name
/// - Validates for duplicate names
/// - Material 3 design with drag handle
class ParticipantFormBottomSheet extends StatefulWidget {
  final String tripId;
  final void Function(Participant participant) onParticipantAdded;

  const ParticipantFormBottomSheet({
    super.key,
    required this.tripId,
    required this.onParticipantAdded,
  });

  @override
  State<ParticipantFormBottomSheet> createState() =>
      _ParticipantFormBottomSheetState();
}

class _ParticipantFormBottomSheetState
    extends State<ParticipantFormBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String _generatedId = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_updateGeneratedId);
  }

  @override
  void dispose() {
    _nameController.removeListener(_updateGeneratedId);
    _nameController.dispose();
    super.dispose();
  }

  void _updateGeneratedId() {
    setState(() {
      final name = _nameController.text;
      final cleaned = name.toLowerCase().trim().replaceAll(
        RegExp(r'[^a-z0-9]'),
        '',
      );

      if (cleaned.isEmpty) {
        _generatedId = 'participant_...';
      } else {
        _generatedId = cleaned.substring(
          0,
          cleaned.length > 20 ? 20 : cleaned.length,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        left: AppTheme.spacing2,
        right: AppTheme.spacing2,
        top: AppTheme.spacing1,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppTheme.spacing3,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title
            Text(
              context.l10n.participantAddTitle,
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: AppTheme.spacing3),

            // Name field
            TextFormField(
              controller: _nameController,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: context.l10n.participantFieldNameLabel,
                hintText: context.l10n.participantFieldNameHint,
                border: const OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return context.l10n.validationNameRequired;
                }
                if (value.trim().length > 50) {
                  return context.l10n.validationNameTooLong;
                }

                // Check for duplicate names
                final state = context.read<TripCubit>().state;
                if (state is TripLoaded) {
                  final trip = state.trips.firstWhere(
                    (t) => t.id == widget.tripId,
                  );
                  final isDuplicate = trip.participants.any(
                    (p) => p.name.toLowerCase() == value.trim().toLowerCase(),
                  );
                  if (isDuplicate) {
                    return context.l10n.validationParticipantAlreadyExists(
                      value.trim(),
                    );
                  }
                }

                return null;
              },
            ),
            const SizedBox(height: AppTheme.spacing2),

            // Auto-generated ID field (read-only)
            TextFormField(
              enabled: false,
              decoration: InputDecoration(
                labelText: context.l10n.participantFieldIdLabel,
                hintText: context.l10n.participantFieldIdHint,
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest,
                helperText: context.l10n.participantFieldIdHelper,
                helperMaxLines: 2,
              ),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontFamily: 'monospace',
              ),
              controller: TextEditingController(text: _generatedId),
            ),
            const SizedBox(height: AppTheme.spacing3),

            // Submit button
            FilledButton(
              onPressed: _isLoading ? null : _handleSubmit,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(context.l10n.participantAddButton),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final state = context.read<TripCubit>().state;
      if (state is! TripLoaded) {
        throw Exception('Trip not loaded');
      }

      final trip = state.trips.firstWhere((t) => t.id == widget.tripId);

      // Create new participant
      final newParticipant = Participant.fromName(_nameController.text.trim());

      // Check for duplicate IDs (unlikely but possible)
      final isDuplicateId = trip.participants.any(
        (p) => p.id == newParticipant.id,
      );
      if (isDuplicateId) {
        // Add timestamp suffix to make it unique
        final uniqueParticipant = Participant(
          id: '${newParticipant.id}_${DateTime.now().millisecondsSinceEpoch}',
          name: newParticipant.name,
          createdAt: newParticipant.createdAt,
        );

        await _addParticipantToTrip(trip, uniqueParticipant);
        widget.onParticipantAdded(uniqueParticipant);
      } else {
        await _addParticipantToTrip(trip, newParticipant);
        widget.onParticipantAdded(newParticipant);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.participantAddError(e.toString())),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _addParticipantToTrip(trip, Participant participant) async {
    // Get current user for activity logging
    final currentUser = context.read<TripCubit>().getCurrentUserForTrip(trip.id);
    final actorName = currentUser?.name;

    await context.read<TripCubit>().addParticipant(
      tripId: trip.id,
      participant: participant,
      actorName: actorName,
    );
  }
}
