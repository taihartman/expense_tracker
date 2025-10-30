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
  String? _loadError; // Track load errors for retry functionality

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
      // Fetch trip from Firestore by ID
      final tripCubit = context.read<TripCubit>();
      final trip = await tripCubit.getTripById(tripId);

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
        setState(() {
          _isLoading = false;
          _loadError = context.l10n.tripJoinNoParticipants;
        });
        return;
      }

      // Success - move to next step
      setState(() {
        _loadedTrip = trip;
        _currentStep = JoinStep.selectIdentity;
        _isLoading = false;
        _loadError = null; // Clear any previous errors
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _loadError = context.l10n.tripJoinLoadError;
      });
    }
  }

  /// Verify identity and join trip
  Future<void> _verifyAndJoin() async {
    if (_selectedParticipant == null || _loadedTrip == null) return;

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.tripJoinConfirmDialogTitle),
        content: Text(
          context.l10n.tripJoinConfirmDialogMessage(
            _loadedTrip!.name,
            _selectedParticipant!.name,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(context.l10n.tripJoinConfirmButton),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

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
          content: Text(context.l10n.tripJoinVerificationFailed),
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
        return const Center(child: CircularProgressIndicator());
    }
  }

  /// Step 1: Enter trip code
  Widget _buildEnterCodeStep() {
    final hasInviteCode =
        widget.inviteCode != null && widget.inviteCode!.isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacing2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Invite link banner (shown when code is pre-filled from URL)
          if (hasInviteCode) ...[
            Container(
              padding: const EdgeInsets.all(AppTheme.spacing2),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.card_giftcard, color: Colors.blue.shade700),
                  const SizedBox(width: AppTheme.spacing2),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.l10n.tripJoinInviteBannerTitle,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          context.l10n.tripJoinInviteBannerMessage,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.blue.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spacing3),
          ],

          // Instructions
          Text(
            context.l10n.tripJoinInstructionStep1,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: AppTheme.spacing3),

          // Trip code input
          CustomTextField(
            controller: _codeController,
            label: context.l10n.tripJoinCodeLabel,
            hint: context.l10n.tripJoinCodeHint,
            enabled: !_isLoading,
          ),

          // Error message with retry button
          if (_loadError != null) ...[
            const SizedBox(height: AppTheme.spacing2),
            Container(
              padding: const EdgeInsets.all(AppTheme.spacing2),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.red.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _loadError!,
                          style: TextStyle(color: Colors.red.shade900),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: Text(context.l10n.tripJoinRetryButton),
                    onPressed: _isLoading
                        ? null
                        : () {
                            setState(() {
                              _loadError = null;
                            });
                            _loadTrip();
                          },
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: AppTheme.spacing3),

          // Load button
          CustomButton(
            text: context.l10n.tripJoinLoadButton,
            onPressed: _isLoading ? null : _loadTrip,
          ),

          // Loading state
          if (_isLoading) ...[
            const SizedBox(height: AppTheme.spacing3),
            Container(
              padding: const EdgeInsets.all(AppTheme.spacing3),
              child: Column(
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: AppTheme.spacing2),
                  Text(
                    context.l10n.commonLoading,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Step 2: Select participant identity
  Widget _buildSelectIdentityStep() {
    if (_loadedTrip == null) {
      return Center(child: Text(context.l10n.tripJoinNoTripLoaded));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacing2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Trip preview card
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacing2),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.card_travel,
                      size: 32,
                      color: Colors.blue.shade700,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacing2),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.l10n.tripJoinTripLabel,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          _loadedTrip!.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.people,
                              size: 16,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${_loadedTrip!.participants.length} members',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Icon(
                              Icons.attach_money,
                              size: 16,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _loadedTrip!.baseCurrency.name.toUpperCase(),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppTheme.spacing3),

          // Instructions with help icon
          Row(
            children: [
              Expanded(
                child: Text(
                  context.l10n.tripJoinSelectIdentityPrompt,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.help_outline, size: 20),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(context.l10n.tripJoinSelectIdentityTitle),
                      content: Text(context.l10n.tripJoinInstructionStep2),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(context.l10n.commonGotIt),
                        ),
                      ],
                    ),
                  );
                },
                tooltip: 'Help',
              ),
            ],
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

          // Recovery code toggle with help icon
          Row(
            children: [
              Expanded(
                child: SwitchListTile(
                  title: Text(context.l10n.tripJoinUseRecoveryCode),
                  subtitle: Text(context.l10n.tripJoinRecoveryCodeSubtitle),
                  value: _useRecoveryCode,
                  onChanged: (value) {
                    setState(() {
                      _useRecoveryCode = value;
                    });
                  },
                ),
              ),
              IconButton(
                icon: const Icon(Icons.help_outline, size: 20),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(context.l10n.tripJoinUseRecoveryCode),
                      content: Text(context.l10n.tripJoinHelpRecoveryCode),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(context.l10n.commonGotIt),
                        ),
                      ],
                    ),
                  );
                },
                tooltip: 'Help',
              ),
            ],
          ),

          // Recovery code input (conditional)
          if (_useRecoveryCode) ...[
            const SizedBox(height: AppTheme.spacing2),
            CustomTextField(
              controller: _recoveryCodeController,
              label: context.l10n.tripJoinRecoveryCodeLabel,
              hint: context.l10n.tripJoinRecoveryCodeHint,
            ),
          ],

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
