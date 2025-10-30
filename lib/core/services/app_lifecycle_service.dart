import 'package:flutter/foundation.dart';

import 'app_lifecycle_service_stub.dart'
    if (dart.library.html) 'app_lifecycle_service_web.dart';

/// Service for observing app lifecycle events (tab visibility changes)
///
/// Uses the Page Visibility API (visibilitychange event) to detect
/// when user returns to the app tab.
///
/// Example usage:
/// ```dart
/// final lifecycleService = AppLifecycleService();
///
/// lifecycleService.startObserving(
///   onResume: () {
///     print('App resumed - user switched back to tab');
///     // Trigger version check or refresh data
///   },
/// );
///
/// // Later, when no longer needed:
/// lifecycleService.stopObserving();
/// ```
///
/// In a StatefulWidget:
/// ```dart
/// class MyWidget extends StatefulWidget {
///   @override
///   State<MyWidget> createState() => _MyWidgetState();
/// }
///
/// class _MyWidgetState extends State<MyWidget> {
///   late final AppLifecycleService _lifecycle;
///
///   @override
///   void initState() {
///     super.initState();
///     _lifecycle = AppLifecycleService();
///     _lifecycle.startObserving(onResume: _handleResume);
///   }
///
///   void _handleResume() {
///     if (mounted) {
///       // Handle app resume - check for updates, refresh data, etc.
///     }
///   }
///
///   @override
///   void dispose() {
///     _lifecycle.stopObserving();
///     super.dispose();
///   }
///
///   @override
///   Widget build(BuildContext context) => Container();
/// }
/// ```
abstract class AppLifecycleService {
  /// Factory constructor that returns the appropriate implementation
  ///
  /// Returns AppLifecycleServiceImpl on web, stub implementation elsewhere
  factory AppLifecycleService() => AppLifecycleServiceImpl();

  /// Starts observing app lifecycle events
  ///
  /// Calls [onResume] callback when app returns to foreground (tab becomes visible)
  ///
  /// On web, uses Page Visibility API to detect tab visibility changes.
  void startObserving({required VoidCallback onResume});

  /// Stops observing lifecycle events and cleans up resources
  ///
  /// Safe to call multiple times - subsequent calls are no-ops.
  void stopObserving();
}
