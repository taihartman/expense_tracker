import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../cubits/trip_cubit.dart';
import '../cubits/trip_state.dart';
import '../widgets/participant_identity_selector.dart';
import '../../domain/models/trip.dart';
import '../../../../core/models/participant.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../../../core/l10n/l10n_extensions.dart';
import '../../../device_pairing/presentation/widgets/code_verification_prompt.dart';
import '../../../device_pairing/presentation/cubits/device_pairing_cubit.dart';

/// Steps in the trip join flow
enum JoinStep {
  /// Step 1: Enter trip code and optionally recovery code
  enterCode,
  /// Step 2: Select participant identity and verify
  selectIdentity,
  /// Step 3: Verifying identity (loading state)
  verifying,
}

/// Page for joining an existing trip via invite code
///
/// This page implements a secure two-step join flow:
/// 1. Enter trip ID → Load trip
/// 2. Select identity from participants → Verify via device pairing
///
/// Alternatively, users can toggle "Use Recovery Code" to bypass verification.
class TripJoinPage extends StatefulWidget {
  /// Optional invite code pre-filled from deep link
  final String? inviteCode;

  const TripJoinPage({super.key, this.inviteCode});

  @override
  State<TripJoinPage> createState() => _TripJoinPageState();
}

class _TripJoinPageState extends State<TripJoinPage> {
  // Controllers
  final _codeController = TextEditingController();
  final _recoveryCodeController = TextEditingController();

  // State
  JoinStep _currentStep = JoinStep.enterCode;
  Trip? _loadedTrip;
  Participant? _selectedParticipant;
  bool _useRecoveryCode = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill invite code if provided via deep link
    if (widget.inviteCode != null && widget.inviteCode!.isNotEmpty) {
      _codeController.text = widget.inviteCode!;
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _recoveryCodeController.dispose();
    super.dispose();
  }

  /// Load trip by ID from loaded trips list
  Future<void> _loadTrip() async {
    final tripId = _codeController.text.trim();

    if (tripId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.validationRequired),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Get trip from already loaded trips
      final tripCubit = context.read<TripCubit>();
      final trip = tripCubit.trips.where((t) => t.id == tripId).firstOrNull;

      if (!mounted) return;

      if (trip == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.tripJoinTripNotFound),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      if (trip.participants.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This trip has no participants yet.'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Success - move to next step
      setState(() {
        _loadedTrip = trip;
        _currentStep = JoinStep.selectIdentity;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading trip: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Join trip with recovery code (bypasses verification)
  Future<void> _joinWithRecoveryCode() async {
    final tripId = _codeController.text.trim();
    final recoveryCode = _recoveryCodeController.text.trim();

    if (tripId.isEmpty || recoveryCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.validationRequired),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Load trip first to get participant list
    setState(() {
      _isLoading = true;
    });

    try {
      final tripCubit = context.read<TripCubit>();
      final trip = tripCubit.trips.where((t) => t.id == tripId).firstOrNull;

      if (!mounted) return;

      if (trip == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.tripJoinTripNotFound),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      if (trip.participants.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This trip has no participants yet.'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Show participant selector to choose which identity to use
      setState(() {
        _loadedTrip = trip;
        _currentStep = JoinStep.selectIdentity;
        _isLoading = false;
        // Keep recovery code for later validation
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Verify identity and join trip
  Future<void> _verifyAndJoin() async {
    if (_selectedParticipant == null || _loadedTrip == null) return;

    // Capture values before async gap
    final devicePairingCubit = context.read<DevicePairingCubit>();
    final tripCubit = context.read<TripCubit>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    setState(() {
      _currentStep = JoinStep.verifying;
    });

    try {
      // Check if using recovery code
      if (_useRecoveryCode && _recoveryCodeController.text.trim().isNotEmpty) {
        // Validate recovery code and join
        final success = await tripCubit.validateAndJoinWithRecoveryCode(
          tripId: _loadedTrip!.id,
          code: _recoveryCodeController.text.trim(),
          userName: _selectedParticipant!.name,
        );

        if (!mounted) return;

        if (!success) {
          // Recovery code validation failed - return to identity selection
          setState(() {
            _currentStep = JoinStep.selectIdentity;
          });
        }
        // Note: Navigation on success handled by BlocListener below
      } else {
        // Show device pairing verification dialog
        final verified = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => BlocProvider.value(
            value: devicePairingCubit,
            child: CodeVerificationPrompt(
              tripId: _loadedTrip!.id,
              memberName: _selectedParticipant!.name,
            ),
          ),
        );

        if (!mounted) return;

        if (verified == true) {
          // Verification successful - join trip
          await tripCubit.joinTrip(
            tripId: _loadedTrip!.id,
            userName: _selectedParticipant!.name,
          );

          // Note: Navigation handled by BlocListener below
        } else {
          // User cancelled verification - return to identity selection
          setState(() {
            _currentStep = JoinStep.selectIdentity;
          });
        }
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _currentStep = JoinStep.selectIdentity;
      });

      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Verification failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.tripJoinTitle)),
      body: BlocListener<TripCubit, TripState>(
        listener: (context, state) {
          if (state is TripJoined) {
            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(context.l10n.tripJoinSuccess),
                backgroundColor: Colors.green,
              ),
            );
            // Navigate back to trip list
            context.go('/');
          } else if (state is TripError) {
            // Show error message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );

            // If in verifying step, return to identity selection
            if (_currentStep == JoinStep.verifying) {
              setState(() {
                _currentStep = JoinStep.selectIdentity;
              });
            }
          }
        },
        child: _buildCurrentStep(),
      ),
    );
  }

  /// Build UI for current step
  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case JoinStep.enterCode:
        return _buildEnterCodeStep();
      case JoinStep.selectIdentity:
        return _buildSelectIdentityStep();
      case JoinStep.verifying:
        return const Center(
          child: CircularProgressIndicator(),
        );
    }
  }

  /// Step 1: Enter trip code
  Widget _buildEnterCodeStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacing2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Instructions
          const Text(
            'Enter the trip code to join an existing trip.',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: AppTheme.spacing3),

          // Trip code input
          CustomTextField(
            controller: _codeController,
            label: context.l10n.tripJoinCodeLabel,
            hint: context.l10n.tripJoinCodeHint,
            enabled: !_isLoading,
          ),
          const SizedBox(height: AppTheme.spacing2),

          // Recovery code toggle
          SwitchListTile(
            title: Text(context.l10n.tripJoinUseRecoveryCode),
            subtitle: const Text('Bypass verification with recovery code'),
            value: _useRecoveryCode,
            onChanged: _isLoading
                ? null
                : (value) {
                    setState(() {
                      _useRecoveryCode = value;
                    });
                  },
          ),

          // Recovery code input (conditional)
          if (_useRecoveryCode) ...[
            const SizedBox(height: AppTheme.spacing2),
            CustomTextField(
              controller: _recoveryCodeController,
              label: context.l10n.tripJoinRecoveryCodeLabel,
              hint: context.l10n.tripJoinRecoveryCodeHint,
              enabled: !_isLoading,
            ),
          ],

          const SizedBox(height: AppTheme.spacing3),

          // Load/Join button
          CustomButton(
            text: _useRecoveryCode
                ? context.l10n.tripJoinButton
                : context.l10n.tripJoinLoadButton,
            onPressed: _isLoading
                ? null
                : (_useRecoveryCode ? _joinWithRecoveryCode : _loadTrip),
          ),
        ],
      ),
    );
  }

  /// Step 2: Select participant identity
  Widget _buildSelectIdentityStep() {
    if (_loadedTrip == null) {
      return const Center(child: Text('No trip loaded'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacing2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Trip name card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacing2),
              child: Row(
                children: [
                  const Icon(Icons.card_travel, size: 32),
                  const SizedBox(width: AppTheme.spacing2),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Trip',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        Text(
                          _loadedTrip!.name,
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

          const SizedBox(height: AppTheme.spacing3),

          // Instructions
          Text(
            context.l10n.tripJoinSelectIdentityPrompt,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: AppTheme.spacing2),

          // Participant selector
          ParticipantIdentitySelector(
            participants: _loadedTrip!.participants,
            selectedParticipant: _selectedParticipant,
            onChanged: (participant) {
              setState(() {
                _selectedParticipant = participant;
              });
            },
          ),

          const SizedBox(height: AppTheme.spacing3),

          // Verify button
          CustomButton(
            text: context.l10n.tripJoinVerifyButton,
            onPressed: _selectedParticipant == null ? null : _verifyAndJoin,
          ),

          if (_selectedParticipant == null) ...[
            const SizedBox(height: AppTheme.spacing1),
            Text(
              context.l10n.identitySelectionNoParticipant,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],

          const SizedBox(height: AppTheme.spacing2),

          // Back button
          TextButton(
            onPressed: () {
              setState(() {
                _currentStep = JoinStep.enterCode;
                _loadedTrip = null;
                _selectedParticipant = null;
              });
            },
            child: Text(context.l10n.commonBack),
          ),
        ],
      ),
    );
  }
}
