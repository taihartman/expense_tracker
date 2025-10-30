import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/models/trip.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/l10n/l10n_extensions.dart';
import '../../../../core/utils/link_utils.dart';
import '../cubits/trip_cubit.dart';

/// Page for displaying and sharing trip invite details
class TripInvitePage extends StatefulWidget {
  final Trip trip;

  const TripInvitePage({super.key, required this.trip});

  @override
  State<TripInvitePage> createState() => _TripInvitePageState();
}

class _TripInvitePageState extends State<TripInvitePage> {
  bool _isLoadingMessage = false;

  void _copyInviteCode(BuildContext context) {
    Clipboard.setData(ClipboardData(text: widget.trip.id));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.tripInviteCodeCopied),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _copyInviteLink(BuildContext context) async {
    setState(() {
      _isLoadingMessage = true;
    });

    try {
      // Load verified members from Firestore
      final verifiedMembers = await context
          .read<TripCubit>()
          .getVerifiedMembers(widget.trip.id);

      // Generate human-friendly message with link
      final message = generateShareMessage(
        trip: widget.trip,
        verifiedMembers: verifiedMembers,
      );

      // Copy to clipboard
      await Clipboard.setData(ClipboardData(text: message));

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.tripInviteMessageCopied),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to copy message'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMessage = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final inviteLink = generateShareableLink(widget.trip.id);

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.tripInviteTitle)),
      body: ListView(
        padding: const EdgeInsets.all(AppTheme.spacing3),
        children: [
          // Header
          Icon(
            Icons.group_add,
            size: 64,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: AppTheme.spacing2),
          Text(
            context.l10n.tripInviteTitle,
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spacing1),
          Text(
            context.l10n.tripInviteCodeDescription,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spacing3),

          // Invite Code Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacing2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.tripInviteCodeLabel,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: AppTheme.spacing1),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppTheme.spacing2),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SelectableText(
                      widget.trip.id,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacing2),

                  // Copy Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _copyInviteCode(context),
                      icon: const Icon(Icons.copy),
                      label: Text(context.l10n.tripInviteCopyButton),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppTheme.spacing2),

          // Share Link Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacing2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.tripInviteShareableLinkLabel,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: AppTheme.spacing1),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppTheme.spacing2),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SelectableText(
                      inviteLink,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacing2),

                  // Copy Link Button (copies personalized message)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isLoadingMessage
                          ? null
                          : () => _copyInviteLink(context),
                      icon: _isLoadingMessage
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.link),
                      label: Text(
                        _isLoadingMessage
                            ? 'Loading...'
                            : context.l10n.tripInviteCopyLinkButton,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppTheme.spacing3),

          // Instructions
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacing2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: AppTheme.spacing1),
                      Text(
                        context.l10n.tripInviteInstructionsTitle,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacing2),
                  _buildInstructionStep(
                    context,
                    '1',
                    context.l10n.tripInviteInstructionStep1,
                  ),
                  const SizedBox(height: AppTheme.spacing1),
                  _buildInstructionStep(
                    context,
                    '2',
                    context.l10n.tripInviteInstructionStep2,
                  ),
                  const SizedBox(height: AppTheme.spacing1),
                  _buildInstructionStep(
                    context,
                    '3',
                    context.l10n.tripInviteInstructionStep3,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionStep(
    BuildContext context,
    String number,
    String text,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppTheme.spacing1),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    );
  }
}
