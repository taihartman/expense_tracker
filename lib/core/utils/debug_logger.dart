import 'dart:async';
import 'package:flutter/foundation.dart';
import '../config/app_config.dart';

/// Global debug logger for mobile debugging.
///
/// Collects logs in memory and provides them via a stream for display
/// in the debug panel. Only active when `AppConfig.enableDebugPanel` is true.
///
/// Usage:
/// ```dart
/// DebugLogger.log('🔀 Redirect to /splash');
/// DebugLogger.log('📍 Deep link captured: /trips/join?code=xxx');
/// ```
class DebugLogger {
  static final List<String> _logs = [];
  static final _controller = StreamController<List<String>>.broadcast();

  /// Stream of all logs (emits whenever a new log is added)
  static Stream<List<String>> get logsStream => _controller.stream;

  /// Get current logs (immutable copy)
  static List<String> get logs => List.unmodifiable(_logs);

  /// Log a message (only if debug panel is enabled)
  static void log(String message) {
    // If debug panel is disabled, do nothing (no overhead)
    if (!AppConfig.enableDebugPanel) return;

    final timestamp = DateTime.now().toIso8601String().substring(11, 23);
    final logEntry = '[$timestamp] $message';

    _logs.add(logEntry);

    // Keep only last 100 logs to prevent memory issues
    if (_logs.length > 100) {
      _logs.removeAt(0);
    }

    _controller.add(_logs);

    // Also print to console for desktop debugging
    debugPrint(logEntry);
  }

  /// Clear all logs
  static void clear() {
    if (!AppConfig.enableDebugPanel) return;

    _logs.clear();
    _controller.add(_logs);
    debugPrint('[DEBUG] Logs cleared');
  }

  /// Dispose resources (call when app is closing)
  static void dispose() {
    if (!AppConfig.enableDebugPanel) return;

    _controller.close();
  }
}
