import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/code_generator.dart';
import '../../../../core/l10n/l10n_extensions.dart';
import '../../utils/verification_code_input_formatter.dart';
import '../cubits/device_pairing_cubit.dart';
import '../cubits/device_pairing_state.dart';

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
  State<CodeVerificationPrompt> createState() => _CodeVerificationPromptState();
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

  Future<void> _copyAskForCodeMessage(BuildContext context) async {
    try {
      final message = context.l10n.devicePairingAskForCodeMessage(
        widget.memberName,
      );
      await Clipboard.setData(ClipboardData(text: message));

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.devicePairingAskForCodeCopied),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to copy message to clipboard'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
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
          title: Text(context.l10n.devicePairingCodePromptTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Explanation message
              Text(
                context.l10n.devicePairingCodePromptMessage(widget.memberName),
              ),
              const SizedBox(height: 12),

              // How to get code info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 20,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        context.l10n.devicePairingCodePromptHowToGet,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Code input field
              TextField(
                controller: _codeController,
                decoration: InputDecoration(
                  labelText: context.l10n.devicePairingCodeFieldLabel,
                  hintText: context.l10n.devicePairingCodeFieldHint,
                  errorText: _errorMessage,
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [VerificationCodeInputFormatter()],
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
              const SizedBox(height: 12),

              // Ask for Code button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: isValidating
                      ? null
                      : () => _copyAskForCodeMessage(context),
                  icon: const Icon(Icons.content_copy, size: 18),
                  label: Text(context.l10n.devicePairingAskForCodeButton),
                ),
              ),
              const SizedBox(height: 8),

              // Loading indicator
              if (isValidating)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Center(child: CircularProgressIndicator()),
                ),
            ],
          ),
          actions: [
            // Cancel button
            TextButton(
              onPressed: isValidating ? null : () => _handleCancel(context),
              child: Text(context.l10n.commonCancel),
            ),

            // Submit button
            TextButton(
              onPressed: (isValidating || !_isCodeValidFlag)
                  ? null
                  : () => _handleSubmit(context),
              child: Text(context.l10n.devicePairingValidateButton),
            ),
          ],
        );
      },
    );
  }
}
