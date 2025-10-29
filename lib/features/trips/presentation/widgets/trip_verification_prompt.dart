import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/l10n/l10n_extensions.dart';

/// Widget displayed when user tries to access trip content without verifying identity.
///
/// Shows an explanation and a button to navigate to identity selection page.
/// This replaces route-level blocking with a softer, more contextual approach.
class TripVerificationPrompt extends StatelessWidget {
  final String tripId;

  const TripVerificationPrompt({
    required this.tripId,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Lock icon
            Icon(
              Icons.person_outline,
              size: 80,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.6),
            ),
            const SizedBox(height: 32),

            // Title
            Text(
              context.l10n.tripVerificationPromptTitle,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // Message
            Text(
              context.l10n.tripVerificationPromptMessage,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.7),
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Primary button - Select Identity
            FilledButton.icon(
              onPressed: () {
                // Navigate to identity selection with current path as return path
                final currentPath = GoRouterState.of(context).uri.toString();
                final returnPath = Uri.encodeComponent(currentPath);
                context.go('/trips/$tripId/identify?returnTo=$returnPath');
              },
              icon: const Icon(Icons.check_circle_outline),
              label: Text(context.l10n.tripVerificationPromptButton),
              style: FilledButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
            const SizedBox(height: 12),

            // Secondary button - Go Back
            TextButton.icon(
              onPressed: () {
                context.go('/');
              },
              icon: const Icon(Icons.arrow_back),
              label: Text(context.l10n.tripVerificationPromptBackButton),
            ),
          ],
        ),
      ),
    );
  }
}
