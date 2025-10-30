import 'package:flutter/foundation.dart';

import 'app_lifecycle_service.dart';

/// Stub implementation of AppLifecycleService for non-web platforms
///
/// This is a no-op implementation for testing and non-web platforms
class AppLifecycleServiceImpl implements AppLifecycleService {
  void _log(String message) {
    if (kDebugMode) {
      debugPrint('[AppLifecycle] $message');
    }
  }

  @override
  void startObserving({required VoidCallback onResume}) {
    _log('Stub implementation - startObserving called (no-op)');
  }

  @override
  void stopObserving() {
    _log('Stub implementation - stopObserving called (no-op)');
  }
}
