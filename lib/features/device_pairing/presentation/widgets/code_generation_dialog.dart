import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubits/device_pairing_cubit.dart';
import '../cubits/device_pairing_state.dart';

/// Dialog for generating and displaying a device pairing code.
///
/// Shows a code generation dialog that:
/// - Automatically calls cubit to generate code
/// - Displays loading state during generation
/// - Shows the generated 8-digit code in large, readable format
/// - Provides copy to clipboard button
/// - Shows countdown timer for 15-minute expiry
/// - Handles error states
class CodeGenerationDialog extends StatefulWidget {
  final String tripId;
  final String memberName;

  const CodeGenerationDialog({
    super.key,
    required this.tripId,
    required this.memberName,
  });

  @override
  State<CodeGenerationDialog> createState() => _CodeGenerationDialogState();
}

class _CodeGenerationDialogState extends State<CodeGenerationDialog> {
  @override
  void initState() {
    super.initState();
    // Automatically generate code when dialog opens
    context.read<DevicePairingCubit>().generateCode(
          widget.tripId,
          widget.memberName,
        );
  }

  Future<void> _copyToClipboard(BuildContext context, String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  String _formatTimeRemaining(DateTime expiresAt) {
    final now = DateTime.now();
    final difference = expiresAt.difference(now);

    if (difference.isNegative) {
      return 'Expired';
    }

    final minutes = difference.inMinutes;
    final seconds = difference.inSeconds % 60;

    return 'Expires in $minutes minute${minutes != 1 ? 's' : ''} $seconds second${seconds != 1 ? 's' : ''}';
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DevicePairingCubit, DevicePairingState>(
      builder: (context, state) {
        return AlertDialog(
          title: const Text('Generate Code'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Explanation message
              Text(
                'Generate a verification code for ${widget.memberName} to pair their device.',
              ),
              const SizedBox(height: 24),

              // Loading state
              if (state is CodeGenerating) ...[
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: CircularProgressIndicator(),
                  ),
                ),
              ],

              // Success state - show code
              if (state is CodeGenerated) ...[
                // Code display
                Center(
                  child: SelectableText(
                    state.code.code,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 4,
                        ),
                  ),
                ),
                const SizedBox(height: 16),

                // Copy button
                ElevatedButton(
                  onPressed: () => _copyToClipboard(context, state.code.code),
                  child: const Text('Copy to Clipboard'),
                ),
                const SizedBox(height: 16),

                // Countdown timer
                Text(
                  _formatTimeRemaining(state.code.expiresAt),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],

              // Error state
              if (state is CodeGenerationError) ...[
                Text(
                  'Failed to generate code: ${state.message}',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}
