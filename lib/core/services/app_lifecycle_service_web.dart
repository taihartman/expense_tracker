import 'dart:html' as html;

import 'package:flutter/foundation.dart';

import 'app_lifecycle_service.dart';

/// Implementation of AppLifecycleService using dart:html Page Visibility API
class AppLifecycleServiceImpl implements AppLifecycleService {
  VoidCallback? _onResume;
  html.EventListener? _visibilityChangeListener;

  void _log(String message) {
    if (kDebugMode) {
      debugPrint('[AppLifecycle] $message');
    }
  }

  @override
  void startObserving({required VoidCallback onResume}) {
    _onResume = onResume;

    // Create event listener for visibility changes
    _visibilityChangeListener = (html.Event event) {
      final isHidden = html.document.hidden;
      _log('Visibility changed: hidden=$isHidden');

      // Call onResume when document becomes visible
      if (isHidden != null && !isHidden) {
        _log('App resumed (tab became visible)');
        _onResume?.call();
      }
    };

    // Register listener
    html.document.addEventListener('visibilitychange', _visibilityChangeListener);
    _log('Started observing app lifecycle');
  }

  @override
  void stopObserving() {
    if (_visibilityChangeListener != null) {
      html.document.removeEventListener(
        'visibilitychange',
        _visibilityChangeListener,
      );
      _visibilityChangeListener = null;
      _onResume = null;
      _log('Stopped observing app lifecycle');
    }
  }
}
