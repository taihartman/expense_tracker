import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubits/device_pairing_cubit.dart';
import '../cubits/device_pairing_state.dart';
import '../../../../core/utils/code_generator.dart';

/// Dialog prompting user to verify their device with a code.
///
/// Shown when a duplicate member name is detected during trip join.
/// Allows the user to enter an 8-digit verification code to prove
/// they are the legitimate device for that member.
class CodeVerificationPrompt extends StatefulWidget {
  final String tripId;
  final String memberName;

  const CodeVerificationPrompt({
    super.key,
    required this.tripId,
    required this.memberName,
  });

  @override
  State<CodeVerificationPrompt> createState() =>
      _CodeVerificationPromptState();
}

class _CodeVerificationPromptState extends State<CodeVerificationPrompt> {
  final _codeController = TextEditingController();
  String? _errorMessage;
  bool _isCodeValidFlag = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  bool _isCodeValid() {
    final code = _codeController.text.trim();
    return CodeGenerator.isValid(code);
  }

  void _updateCodeValidity() {
    final isValid = _isCodeValid();
    if (isValid != _isCodeValidFlag) {
      setState(() {
        _isCodeValidFlag = isValid;
      });
    }
  }

  void _handleSubmit(BuildContext context) {
    if (_isCodeValid()) {
      context.read<DevicePairingCubit>().validateCode(
            widget.tripId,
            _codeController.text.trim(),
            widget.memberName,
          );
    }
  }

  void _handleCancel(BuildContext context) {
    Navigator.of(context).pop(false);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DevicePairingCubit, DevicePairingState>(
      listener: (context, state) {
        if (state is CodeValidated) {
          // Success - dismiss dialog with true result
          Navigator.of(context).pop(true);
        } else if (state is CodeValidationError) {
          // Update error message
          setState(() {
            _errorMessage = state.message;
          });
        }
      },
      builder: (context, state) {
        final isValidating = state is CodeValidating;

        return AlertDialog(
          title: const Text('Device Verification Required'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Explanation message
              Text(
                'A member named "${widget.memberName}" already exists in this trip. '
                'To verify you are the legitimate device for this member, '
                'please enter the verification code from your other device.',
              ),
              const SizedBox(height: 16),

              // Code input field
              TextField(
                controller: _codeController,
                decoration: InputDecoration(
                  labelText: 'Verification Code',
                  hintText: '1234-5678',
                  errorText: _errorMessage,
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9\-]')),
                  LengthLimitingTextInputFormatter(9), // "XXXX-XXXX"
                ],
                onChanged: (value) {
                  // Clear error when user types
                  if (_errorMessage != null) {
                    setState(() {
                      _errorMessage = null;
                    });
                  }
                  // Update button enabled state
                  _updateCodeValidity();
                },
              ),
              const SizedBox(height: 8),

              // Loading indicator
              if (isValidating)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
            ],
          ),
          actions: [
            // Cancel button
            TextButton(
              onPressed: isValidating ? null : () => _handleCancel(context),
              child: const Text('Cancel'),
            ),

            // Submit button
            TextButton(
              onPressed: (isValidating || !_isCodeValidFlag)
                  ? null
                  : () => _handleSubmit(context),
              child: const Text('Submit Code'),
            ),
          ],
        );
      },
    );
  }
}
