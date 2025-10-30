import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

import '../services/app_lifecycle_service.dart';
import '../services/version_check_service.dart';

/// Widget that listens for app updates and shows a Material Banner notification
class UpdateNotificationListener extends StatefulWidget {
  final Widget child;
  final VersionCheckService? versionCheckService;
  final AppLifecycleService? lifecycleService;

  const UpdateNotificationListener({
    required this.child,
    this.versionCheckService,
    this.lifecycleService,
    super.key,
  });

  @override
  State<UpdateNotificationListener> createState() =>
      _UpdateNotificationListenerState();
}

class _UpdateNotificationListenerState extends State<UpdateNotificationListener>
    with SingleTickerProviderStateMixin {
  late final VersionCheckService _versionCheckService;
  late final AppLifecycleService _lifecycleService;
  late final AnimationController _iconAnimationController;
  late final Animation<double> _iconAnimation;

  bool _updateAvailable = false;
  bool _bannerDismissed = false;

  void _log(String message) {
    if (kDebugMode) {
      debugPrint('[UpdateNotification] $message');
    }
  }

  @override
  void initState() {
    super.initState();

    // Initialize animation controller for icon pulse effect
    _iconAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Create a pulsing scale animation for the update icon
    _iconAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _iconAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _versionCheckService =
        widget.versionCheckService ?? VersionCheckServiceImpl();
    _lifecycleService = widget.lifecycleService ?? AppLifecycleService();

    // Check for updates on app launch (cold start)
    _checkForUpdate();

    // Start observing app lifecycle for resume events
    _lifecycleService.startObserving(onResume: _checkForUpdate);
  }

  Future<void> _checkForUpdate() async {
    _log('Checking for updates...');

    final updateAvailable = await _versionCheckService.isUpdateAvailable();

    if (mounted && updateAvailable != _updateAvailable) {
      setState(() {
        _updateAvailable = updateAvailable;
        _bannerDismissed = false; // Reset dismissed state on new check
      });

      if (updateAvailable) {
        _log('Update available - showing banner');
        _showBanner();
        // Start icon pulse animation when banner appears
        unawaited(_iconAnimationController.repeat(reverse: true));
      }
    }
  }

  void _showBanner() {
    if (_bannerDismissed) {
      _log('Banner previously dismissed - not showing');
      return;
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Use 8px grid spacing for consistent layout
    const spacing = 8.0;

    ScaffoldMessenger.of(context).showMaterialBanner(
      MaterialBanner(
        backgroundColor: colorScheme.primaryContainer,
        elevation: 4.0, // Subtle elevation for prominence
        padding: const EdgeInsets.all(spacing * 2), // 16px padding
        leading: Semantics(
          label: 'Update available icon',
          child: ScaleTransition(
            scale: _iconAnimation,
            child: Icon(
              Icons.system_update,
              color: colorScheme.onPrimaryContainer,
              size: 32.0, // Slightly larger for better visibility
            ),
          ),
        ),
        content: Semantics(
          label: 'A new version of the app is available',
          child: Text(
            'A new version is available',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        actions: [
          Semantics(
            label: 'Dismiss update notification',
            button: true,
            child: TextButton(
              onPressed: _dismissBanner,
              style: TextButton.styleFrom(
                foregroundColor: colorScheme.onPrimaryContainer,
                padding: const EdgeInsets.symmetric(
                  horizontal: spacing * 2,
                  vertical: spacing,
                ),
              ),
              child: const Text('Dismiss'),
            ),
          ),
          const SizedBox(width: spacing), // Space between buttons
          Semantics(
            label: 'Update app now and reload',
            button: true,
            child: FilledButton(
              onPressed: _reloadApp,
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: spacing * 2,
                  vertical: spacing,
                ),
              ),
              child: const Text('Update Now'),
            ),
          ),
        ],
      ),
    );
  }

  void _dismissBanner() {
    _log('Banner dismissed by user');
    // Stop icon animation when banner is dismissed
    _iconAnimationController.stop();
    _iconAnimationController.reset();

    setState(() {
      _bannerDismissed = true;
    });
    ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
  }

  void _reloadApp() {
    _log('Reloading app to apply update...');

    // Use window.location.reload() to trigger a full app reload
    // This will fetch the new version and preserve localStorage
    web.window.location.reload();
  }

  @override
  void dispose() {
    _iconAnimationController.dispose();
    _lifecycleService.stopObserving();
    _versionCheckService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
