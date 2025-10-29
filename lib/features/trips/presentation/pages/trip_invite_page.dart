import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../domain/models/trip.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/l10n/l10n_extensions.dart';
import '../../../../core/utils/link_utils.dart';

/// Page for displaying and sharing trip invite details
class TripInvitePage extends StatelessWidget {
  final Trip trip;

  const TripInvitePage({super.key, required this.trip});

  void _copyInviteCode(BuildContext context) {
    Clipboard.setData(ClipboardData(text: trip.id));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.tripInviteCodeCopied),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _copyInviteLink(BuildContext context) {
    final link = generateShareableLink(trip.id);
    Clipboard.setData(ClipboardData(text: link));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Link copied to clipboard'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final inviteLink = generateShareableLink(trip.id);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.tripInviteTitle),
      ),
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
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SelectableText(
                      trip.id,
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
                    'Shareable Link',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: AppTheme.spacing1),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppTheme.spacing2),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
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

                  // Copy Link Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _copyInviteLink(context),
                      icon: const Icon(Icons.link),
                      label: const Text('Copy Link'),
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
                        'How to invite friends',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacing2),
                  _buildInstructionStep(
                    context,
                    '1',
                    'Share the invite code or link with your friends',
                  ),
                  const SizedBox(height: AppTheme.spacing1),
                  _buildInstructionStep(
                    context,
                    '2',
                    'They enter the code on the Join Trip page',
                  ),
                  const SizedBox(height: AppTheme.spacing1),
                  _buildInstructionStep(
                    context,
                    '3',
                    'They provide their name and join the trip',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionStep(BuildContext context, String number, String text) {
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
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}
