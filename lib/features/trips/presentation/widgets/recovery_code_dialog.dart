import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/l10n/l10n_extensions.dart';
import '../../../../core/theme/app_theme.dart';

/// Reusable dialog for displaying recovery codes.
///
/// Used in two scenarios:
/// 1. After trip creation (first-time display with special messaging)
/// 2. In trip settings (viewing existing recovery code)
///
/// Features:
/// - Orange warning banner about code security
/// - Trip ID and name display with color-coded sections
/// - Visual distinction between public (Trip ID) and private (Recovery Code)
/// - Separate copy buttons for Trip ID and Recovery Code
/// - Copy-to-clipboard functionality with error handling
/// - Password manager storage hint
/// - Optional first-time messaging
class RecoveryCodeDialog extends StatelessWidget {
  /// The recovery code to display (format: XXXX-XXXX-XXXX)
  final String code;

  /// The trip ID to display
  final String tripId;

  /// Optional trip name to display
  final String? tripName;

  /// Whether this is the first time the user is seeing this code.
  /// If true, shows additional messaging about saving the code.
  final bool isFirstTime;

  /// Optional usage count to display (how many times code has been used).
  /// If provided, shows usage statistics below the code.
  final int? usageCount;

  const RecoveryCodeDialog({
    super.key,
    required this.code,
    required this.tripId,
    this.tripName,
    this.isFirstTime = false,
    this.usageCount,
  });

  /// Get formatted text for copying both trip ID and recovery code
  String _getFormattedTripInfo() {
    final buffer = StringBuffer();
    if (tripName != null) {
      buffer.writeln('Trip: $tripName');
    }
    buffer.writeln('Trip ID: $tripId');
    buffer.write('Recovery Code: $code');
    return buffer.toString();
  }

  /// Copy text to clipboard with error handling
  Future<void> _copyToClipboard(
    BuildContext context,
    String text,
    String successMessage,
  ) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(successMessage),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.tripRecoveryCopyFailed(e.toString())),
          backgroundColor: Theme.of(context).colorScheme.error,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// Copy full trip info with preview in snackbar
  Future<void> _copyAllInfo(BuildContext context) async {
    final text = _getFormattedTripInfo();

    try {
      await Clipboard.setData(ClipboardData(text: text));
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(context.l10n.tripRecoveryCopyAllSuccess),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  text,
                  style: const TextStyle(
                    fontSize: 11,
                    fontFamily: 'monospace',
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.tripRecoveryCopyFailed(e.toString())),
          backgroundColor: Theme.of(context).colorScheme.error,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// Build a section with color-coded styling
  Widget _buildSection({
    required BuildContext context,
    required String label,
    required String badge,
    required Color badgeColor,
    required IconData icon,
    required Widget child,
    Widget? action,
    Widget? description,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: badgeColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                badge,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: badgeColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.all(AppTheme.spacing2),
          decoration: BoxDecoration(
            color: badgeColor.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Expanded(child: child),
              if (action != null) action,
            ],
          ),
        ),
        if (description != null) ...[
          const SizedBox(height: 6),
          description,
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.l10n.tripRecoveryViewDialogTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Warning banner
            Container(
              padding: const EdgeInsets.all(AppTheme.spacing2),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber, color: Colors.orange),
                  const SizedBox(width: AppTheme.spacing2),
                  Expanded(
                    child: Text(
                      context.l10n.tripRecoveryWarningMessage,
                      style: const TextStyle(color: Colors.orange),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spacing3),

            // Password manager hint (for first-time view)
            if (isFirstTime) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.vpn_key, color: Colors.blue, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        context.l10n.tripRecoveryPasswordManagerHint,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontSize: 12,
                              color: Colors.blue.shade700,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.spacing3),
            ],

            // Trip name (if provided)
            if (tripName != null) ...[
              Text(
                context.l10n.tripRecoveryTripLabel,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 4),
              SelectableText(
                tripName!,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: AppTheme.spacing3),
            ],

            // Trip ID section (blue - safe to share)
            _buildSection(
              context: context,
              label: context.l10n.tripRecoveryTripIdLabel,
              badge: context.l10n.tripRecoveryTripIdSafeToShare,
              badgeColor: Colors.blue,
              icon: Icons.public,
              child: SelectableText(
                tripId,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontFamily: 'monospace',
                      fontSize: 13,
                    ),
              ),
              action: IconButton(
                icon: const Icon(Icons.copy, size: 16),
                onPressed: () => _copyToClipboard(
                  context,
                  tripId,
                  context.l10n.tripRecoveryTripIdCopied,
                ),
                tooltip: context.l10n.tripRecoveryTripIdCopied,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              description: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 14,
                    color: Colors.blue.shade700,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      context.l10n.tripRecoveryTripIdDescription,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.blue.shade700,
                            fontSize: 12,
                          ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spacing3),

            // Recovery code section (red - private)
            _buildSection(
              context: context,
              label: context.l10n.tripRecoveryCodeLabel,
              badge: context.l10n.tripRecoveryCodePrivate,
              badgeColor: Colors.red,
              icon: Icons.lock,
              child: Center(
                child: SelectableText(
                  code,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              description: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 14,
                    color: Colors.red.shade700,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      context.l10n.tripRecoveryCodeDescription,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.red.shade700,
                            fontSize: 12,
                          ),
                    ),
                  ),
                ],
              ),
            ),

            // First-time message or usage count
            if (isFirstTime) ...[
              const SizedBox(height: AppTheme.spacing2),
              Text(
                context.l10n.tripRecoveryFirstTimeMessage,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
              ),
            ] else if (usageCount != null) ...[
              const SizedBox(height: AppTheme.spacing2),
              Text(
                context.l10n.tripRecoveryUsedCount(usageCount!),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.l10n.commonClose),
        ),
        // Copy recovery code only
        OutlinedButton.icon(
          onPressed: () => _copyToClipboard(
            context,
            code,
            context.l10n.tripRecoveryCodeCopiedToClipboard,
          ),
          icon: const Icon(Icons.copy, size: 18),
          label: Text(context.l10n.tripRecoveryCopyCodeButton),
        ),
        // Copy full trip info (name, ID, and recovery code)
        ElevatedButton.icon(
          onPressed: () => _copyAllInfo(context),
          icon: const Icon(Icons.content_copy, size: 18),
          label: Text(context.l10n.tripRecoveryCopyAllButton),
        ),
      ],
    );
  }
}
