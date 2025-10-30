import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../config/app_config.dart';
import '../utils/debug_logger.dart';
import 'debug_panel.dart';

/// Wraps the app with a debug overlay that shows routing state and logs.
///
/// Only renders debug panel if `AppConfig.enableDebugPanel` is true.
/// Zero overhead when disabled - just returns the child widget.
///
/// Usage:
/// ```dart
/// MaterialApp.router(
///   routerConfig: AppRouter.router,
///   builder: (context, child) {
///     return DebugOverlay(child: child ?? const SizedBox.shrink());
///   },
/// );
/// ```
class DebugOverlay extends StatefulWidget {
  final Widget child;

  const DebugOverlay({
    super.key,
    required this.child,
  });

  @override
  State<DebugOverlay> createState() => _DebugOverlayState();
}

class _DebugOverlayState extends State<DebugOverlay> {
  List<String> _logs = [];

  @override
  void initState() {
    super.initState();

    // Only set up stream listener if debug panel is enabled
    if (AppConfig.enableDebugPanel) {
      // Initialize with current logs
      _logs = DebugLogger.logs;

      // Listen to log updates
      DebugLogger.logsStream.listen((logs) {
        if (mounted) {
          setState(() {
            _logs = logs;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // If debug panel disabled, just return child (zero overhead)
    if (!AppConfig.enableDebugPanel) {
      return widget.child;
    }

    // Get routing state from GoRouter
    Map<String, dynamic>? routingState;
    try {
      final routerState = GoRouterState.of(context);
      routingState = {
        'uri': routerState.uri.toString(),
        'matchedLocation': routerState.matchedLocation,
        'path': routerState.path ?? 'null',
        'queryParams': routerState.uri.queryParameters.isEmpty
            ? 'none'
            : routerState.uri.queryParameters.toString(),
      };
    } catch (e) {
      // If GoRouterState is not available (shouldn't happen), just show null
      routingState = null;
    }

    // Render app with debug panel overlay
    return Stack(
      children: [
        widget.child,
        DebugPanel(
          logs: _logs,
          routingState: routingState,
        ),
      ],
    );
  }
}
