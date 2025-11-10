import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qr_flutter/qr_flutter.dart';
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
  bool _isLoadingMessage = true;
  String? _shareMessage;

  @override
  void initState() {
    super.initState();
    // Pre-compute share message to avoid async gap during clipboard operation
    _loadShareMessage();
  }

  Future<void> _loadShareMessage() async {
    try {
      final tripCubit = context.read<TripCubit>();

      // Load verified members asynchronously (before user interaction)
      final verifiedMembers = await tripCubit.getVerifiedMembers(
        widget.trip.id,
      );

      // Get current user to track who shared this link
      final currentUser = await tripCubit.getCurrentUserForTrip(widget.trip.id);

      // Generate complete share message
      final message = generateShareMessage(
        trip: widget.trip,
        verifiedMembers: verifiedMembers,
        sharedByParticipantId: currentUser?.id,
      );

      if (mounted) {
        setState(() {
          _shareMessage = message;
          _isLoadingMessage = false;
        });
      }

      developer.log('✅ Share message pre-loaded', name: 'TripInvitePage');
    } catch (e) {
      developer.log(
        '⚠️ Failed to load share message: $e',
        name: 'TripInvitePage',
        error: e,
      );

      if (mounted) {
        setState(() {
          _isLoadingMessage = false;
        });
      }
    }
  }

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

  Future<void> _showQrCodeDialog(BuildContext context) async {
    // Get current user to track who shared this QR code
    final currentUser = await context.read<TripCubit>().getCurrentUserForTrip(
      widget.trip.id,
    );
    final inviteLink = generateQrCodeLink(
      widget.trip.id,
      sharedBy: currentUser?.id,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.tripInviteQrDialogTitle),
        content: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                context.l10n.tripInviteQrDialogDescription,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppTheme.spacing3),
              Container(
                padding: const EdgeInsets.all(AppTheme.spacing2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: QrImageView(
                  data: inviteLink,
                  version: QrVersions.auto,
                  size: 280,
                  backgroundColor: Colors.white,
                  errorCorrectionLevel: QrErrorCorrectLevel.M,
                ),
              ),
              const SizedBox(height: AppTheme.spacing2),
              Text(
                widget.trip.name,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(context.l10n.commonClose),
          ),
        ],
      ),
    );
  }

  void _copyInviteLink(BuildContext context) {
    // If message hasn't loaded yet, show fallback dialog
    if (_shareMessage == null) {
      developer.log(
        '⚠️ Share message not ready, showing fallback',
        name: 'TripInvitePage',
      );
      _showManualCopyDialog(context);
      return;
    }

    try {
      // COMPLETELY SYNCHRONOUS clipboard call - no async/await!
      // This preserves the user gesture context on mobile browsers
      Clipboard.setData(ClipboardData(text: _shareMessage!));

      developer.log('✅ Clipboard copy successful', name: 'TripInvitePage');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.tripInviteMessageCopied),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      developer.log(
        '❌ Clipboard copy failed: $e',
        name: 'TripInvitePage',
        error: e,
      );

      // Show fallback dialog with selectable text
      _showManualCopyDialog(context);
    }
  }

  void _showManualCopyDialog(BuildContext context) {
    // Use pre-computed message, or fallback to just the trip code
    final message = _shareMessage ?? widget.trip.id;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.tripInviteCopyFallbackTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.tripInviteCopyFallbackMessage,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppTheme.spacing2),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppTheme.spacing2),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
              child: SelectableText(
                message,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(context.l10n.commonClose),
          ),
        ],
      ),
    );
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
                  const SizedBox(height: AppTheme.spacing2),

                  // Show QR Code Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _showQrCodeDialog(context),
                      icon: const Icon(Icons.qr_code),
                      label: Text(context.l10n.tripInviteShowQrButton),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppTheme.spacing2),

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
