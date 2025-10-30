import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/l10n_extensions.dart';
import '../../../../core/models/participant.dart';
import '../../../device_pairing/presentation/cubits/device_pairing_cubit.dart';
import '../../../device_pairing/presentation/widgets/code_verification_prompt.dart';
import '../cubits/trip_cubit.dart';
import '../cubits/trip_state.dart';
import '../widgets/participant_identity_selector.dart';

/// Page shown when a user tries to access a trip they haven't officially joined.
///
/// This page allows users to:
/// 1. Select their identity from the trip's existing participants
/// 2. Verify their identity via device pairing code
/// 3. Gain access to the trip upon successful verification
///
/// This flow is used for backward compatibility when users accessed trips
/// before the invitation system was added, or when rejoining trips on a new device.
class TripIdentitySelectionPage extends StatefulWidget {
  final String tripId;
  final String? returnPath;

  const TripIdentitySelectionPage({
    required this.tripId,
    this.returnPath,
    super.key,
  });

  @override
  State<TripIdentitySelectionPage> createState() =>
      _TripIdentitySelectionPageState();
}

class _TripIdentitySelectionPageState extends State<TripIdentitySelectionPage> {
  Participant? _selectedParticipant;
  bool _isVerifying = false;
  bool _useRecoveryCode = false;
  final _recoveryCodeController = TextEditingController();

  @override
  void dispose() {
    _recoveryCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.identitySelectionTitle)),
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
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    state.message,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.pop(),
                    child: Text(context.l10n.commonBack),
                  ),
                ],
              ),
            );
          }

          // Find the trip
          final tripCubit = context.read<TripCubit>();
          final trip = tripCubit.trips
              .where((t) => t.id == widget.tripId)
              .firstOrNull;

          if (trip == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.search_off, size: 48),
                  const SizedBox(height: 16),
                  const Text('Trip not found'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.pop(),
                    child: Text(context.l10n.commonBack),
                  ),
                ],
              ),
            );
          }

          if (trip.participants.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.people_outline, size: 48),
                  const SizedBox(height: 16),
                  const Text('This trip has no participants yet'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.pop(),
                    child: Text(context.l10n.commonBack),
                  ),
                ],
              ),
            );
          }

          return _buildIdentitySelectionForm(
            context,
            trip.name,
            trip.participants,
          );
        },
      ),
    );
  }

  Widget _buildIdentitySelectionForm(
    BuildContext context,
    String tripName,
    List<Participant> participants,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Trip name
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const Icon(Icons.card_travel, size: 32),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Trip',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        Text(
                          tripName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Instructions
          Text(
            context.l10n.identitySelectionPrompt,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),

          const SizedBox(height: 16),

          // Participant selector
          ParticipantIdentitySelector(
            participants: participants,
            selectedParticipant: _selectedParticipant,
            onChanged: (participant) {
              setState(() {
                _selectedParticipant = participant;
              });
            },
          ),

          const SizedBox(height: 24),

          // Recovery code option
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Toggle for recovery code
                  CheckboxListTile(
                    value: _useRecoveryCode,
                    onChanged: (value) {
                      setState(() {
                        _useRecoveryCode = value ?? false;
                        if (!_useRecoveryCode) {
                          _recoveryCodeController.clear();
                        }
                      });
                    },
                    title: Text(context.l10n.tripJoinUseRecoveryCode),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),

                  // Recovery code input field (shown when toggled)
                  if (_useRecoveryCode) ...[
                    const SizedBox(height: 8),
                    TextField(
                      controller: _recoveryCodeController,
                      decoration: InputDecoration(
                        labelText: context.l10n.tripJoinRecoveryCodeLabel,
                        hintText: context.l10n.tripJoinRecoveryCodeHint,
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.shield),
                      ),
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Continue button
          ElevatedButton.icon(
            onPressed: _isVerifying || _selectedParticipant == null
                ? null
                : () => _handleContinue(context),
            icon: _isVerifying
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.verified_user),
            label: Text(
              _isVerifying
                  ? context.l10n.identitySelectionVerifying
                  : context.l10n.identitySelectionContinue,
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),

          if (_selectedParticipant == null) ...[
            const SizedBox(height: 8),
            Text(
              context.l10n.identitySelectionNoParticipant,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _handleContinue(BuildContext context) async {
    if (_selectedParticipant == null) return;

    // Capture values before async gap
    final devicePairingCubit = context.read<DevicePairingCubit>();
    final tripCubit = context.read<TripCubit>();
    final l10n = context.l10n;
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);

    setState(() {
      _isVerifying = true;
    });

    try {
      bool verified = false;

      // Check if using recovery code
      if (_useRecoveryCode && _recoveryCodeController.text.trim().isNotEmpty) {
        // Validate recovery code and join
        verified = await tripCubit.validateAndJoinWithRecoveryCode(
          tripId: widget.tripId,
          code: _recoveryCodeController.text.trim(),
          userName: _selectedParticipant!.name,
        );

        if (!verified && mounted) {
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text(l10n.tripJoinRecoveryCodeInvalid),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        // Show device pairing verification dialog
        final dialogResult = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => BlocProvider.value(
            value: devicePairingCubit,
            child: CodeVerificationPrompt(
              tripId: widget.tripId,
              memberName: _selectedParticipant!.name,
            ),
          ),
        );

        // Save membership to local storage
        if (dialogResult == true) {
          await tripCubit.joinTrip(
            tripId: widget.tripId,
            userName: _selectedParticipant!.name,
          );
          verified = true;
        }
      }

      if (!mounted) return;

      if (verified) {
        // Success! Navigate to destination
        final destination =
            widget.returnPath ?? '/trips/${widget.tripId}/expenses';

        // Get trip name
        final tripName =
            tripCubit.trips
                .where((t) => t.id == widget.tripId)
                .firstOrNull
                ?.name ??
            'trip';

        // Show success message briefly
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(l10n.identitySelectionSuccess(tripName)),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );

        // Navigate after a short delay to show the success message
        await Future.delayed(const Duration(milliseconds: 500));
        if (!mounted) return;

        router.go(destination);
      } else {
        // User cancelled verification or recovery code invalid
        setState(() {
          _isVerifying = false;
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isVerifying = false;
      });

      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Verification failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
