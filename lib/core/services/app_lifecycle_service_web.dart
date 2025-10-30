import 'dart:js_interop';

import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

import 'app_lifecycle_service.dart';

/// Implementation of AppLifecycleService using package:web Page Visibility API
class AppLifecycleServiceImpl implements AppLifecycleService {
  VoidCallback? _onResume;
  web.EventListener? _visibilityChangeListener;

  void _log(String message) {
    if (kDebugMode) {
      debugPrint('[AppLifecycle] $message');
    }
  }

  @override
  void startObserving({required VoidCallback onResume}) {
    _onResume = onResume;

    // Create event listener for visibility changes
    _visibilityChangeListener = (web.Event event) {
      final isHidden = web.document.hidden;
      _log('Visibility changed: hidden=$isHidden');

      // Call onResume when document becomes visible
      if (!isHidden) {
        _log('App resumed (tab became visible)');
        _onResume?.call();
      }
    }.toJS;

    // Register listener
    web.document.addEventListener(
      'visibilitychange',
      _visibilityChangeListener,
    );
    _log('Started observing app lifecycle');
  }

  @override
  void stopObserving() {
    if (_visibilityChangeListener != null) {
      web.document.removeEventListener(
        'visibilitychange',
        _visibilityChangeListener,
      );
      _visibilityChangeListener = null;
      _onResume = null;
      _log('Stopped observing app lifecycle');
    }
  }
}
