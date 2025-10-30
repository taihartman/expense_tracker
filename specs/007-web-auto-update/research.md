# Research: Web Auto-Update Feature

**Feature**: 007-web-auto-update
**Phase**: Phase 0 - Research & Design
**Date**: 2025-10-30

This document contains comprehensive research findings on five critical technical topics for implementing automatic web application updates in Flutter web.

---

## Table of Contents

1. [Flutter Web Service Worker Lifecycle](#1-flutter-web-service-worker-lifecycle)
2. [Semantic Version Parsing in Dart](#2-semantic-version-parsing-in-dart)
3. [WidgetsBindingObserver for Web](#3-widgetsbindingobserver-for-web)
4. [Material Banner vs SnackBar](#4-material-banner-vs-snackbar)
5. [dart:html Service Worker APIs](#5-darthtml-service-worker-apis)

---

## 1. Flutter Web Service Worker Lifecycle

### Decision

**DO NOT unregister the service worker before reload.** Instead, rely on Flutter's built-in service worker management via `flutter_bootstrap.js` and trigger a simple `window.location.reload()` when a new version is detected.

### Rationale

**Critical Context (2025)**: Flutter announced that the default service worker implementation will be removed in the first stable release of 2025. The default `flutter_service_worker.js` will change to a "cleanup" service worker that will update the current implementation and remove itself from end users' browsers.

**Why This Matters**:
- Flutter is moving away from providing a default service worker because users need flexibility for custom cache-busting schemes, proxy server support, and custom update strategies
- The current service worker is fully managed by `flutter_bootstrap.js`, which handles versioning automatically
- Manual service worker manipulation could interfere with Flutter's cleanup process

**How flutter_service_worker.js Works**:
- As of Flutter 2.2+, when the service worker detects a change, users wait for updates to download but see them without requiring a second manual refresh
- The service worker version is managed via the `{{flutter_service_worker_version}}` template token (the old `serviceWorkerVersion` variable is deprecated)
- The service worker follows standard browser service worker lifecycle: install → waiting → active

**Why Default Mechanism is Insufficient**:
- Flutter's default behavior downloads updates silently but doesn't notify users
- Users may continue using stale versions for extended periods if they never close/reopen the tab
- No built-in mechanism to detect version changes and prompt users
- In long-running web apps (like our expense tracker), users might have tabs open for days/weeks

**Our Approach**:
1. Detect version changes by comparing `version.json` on tab focus
2. Show user-facing notification via MaterialBanner
3. Let user trigger reload when convenient
4. Allow standard `window.location.reload()` to handle cache updates
5. Avoid interfering with Flutter's service worker management

### Alternatives Considered

**Alternative 1: Manually unregister service worker before reload**
```dart
// NOT RECOMMENDED
await window.navigator.serviceWorker?.getRegistration()?.unregister();
window.location.reload();
```
**Why Not**:
- Could interfere with Flutter's cleanup service worker in 2025
- Adds complexity with minimal benefit
- Service worker will update naturally on reload

**Alternative 2: Use service worker's `skipWaiting()` and `clients.claim()`**
**Why Not**:
- Requires custom service worker implementation (Flutter is deprecating default)
- More complex to maintain
- Flutter's 2025 direction is away from default service workers

**Alternative 3: Force reload with cache bypass**
```dart
window.location.reload(forceReload: true); // Deprecated in modern browsers
```
**Why Not**:
- `forceReload` parameter is deprecated
- Not necessary with proper service worker lifecycle

### Code Example

```dart
// Simple, clean approach - let Flutter's service worker do its job
import 'dart:html' as html;

class VersionUpdateService {
  Future<void> reloadApp() async {
    // No service worker manipulation needed
    // Flutter's service worker will handle cache updates naturally
    html.window.location.reload();
  }
}
```

### Key Implementation Notes

1. **version.json Placement**: Place in `/web/version.json` so it's served at root and not cached aggressively
2. **Detection Timing**: Check on tab focus (when user returns to app)
3. **User Control**: Always let user choose when to reload (don't force)
4. **Graceful Degradation**: If service worker isn't registered, reload still works

### References

- [Flutter GitHub Issue #104509](https://github.com/flutter/flutter/issues/104509) - Need documentation for "Refresh. New Version available" prompt
- [Flutter Announce: Service Worker Removal](https://groups.google.com/g/flutter-announce/c/0Vv-j_TyrdI)
- [Medium: Flutter Web Service Worker Versioning](https://medium.com/@muhvarriel/how-flutter-web-improves-service-worker-versioning-for-efficient-app-updates-828f753830f4)

---

## 2. Semantic Version Parsing in Dart

### Decision

**Use the `pub_semver` package** (official Dart package) for semantic version parsing and comparison. This is the standard package used by Dart's package manager and provides robust semver 2.0.0-rc.1 support.

### Rationale

**Why pub_semver**:
- Official package maintained by the Dart team (now in `dart-lang/tools` repository)
- Battle-tested by Dart's package manager (pub)
- Handles all semver edge cases (pre-release, build metadata, version ranges)
- Zero additional dependencies
- Built-in comparison operators (`<`, `>`, `<=`, `>=`, `==`)
- Proper handling of `major.minor.patch+build` format

**Semantic Versioning Behavior**:
- Follows Semantic Versioning 2.0.0-rc.1 spec with pub-specific enhancements
- Build suffix ordering: `1.2.3+1` < `1.2.3+2` (unlike pure semver where build is ignored)
- Pre-release handling: `<2.0.0` excludes `2.0.0-alpha` (pub-specific behavior)
- Comparison priority: Major > Minor > Patch > Pre-release > Build

**Format Compatibility**:
Our `pubspec.yaml` uses format: `version: 1.0.0+1` (semantic version + build number)
- `pub_semver` handles this perfectly with `Version.parse('1.0.0+1')`
- Build number increments (e.g., `+1`, `+2`) are compared correctly

### Alternatives Considered

**Alternative 1: Custom implementation**
```dart
class SimpleVersion {
  final int major, minor, patch;
  // ... custom parsing and comparison logic
}
```
**Why Not**:
- Reinventing the wheel
- Won't handle edge cases (pre-release tags, build metadata)
- More code to maintain and test
- Risk of subtle bugs in comparison logic

**Alternative 2: Use `package_info_plus` only**
**Why Not**:
- `package_info_plus` retrieves version but doesn't provide comparison
- Still need `pub_semver` for version comparison logic

**Alternative 3: String comparison**
```dart
if (newVersion != currentVersion) // Bad!
```
**Why Not**:
- `"1.10.0" < "1.9.0"` as strings (incorrect!)
- Doesn't handle build numbers correctly
- Can't determine if update is major/minor/patch

### Code Example

```dart
import 'package:pub_semver/pub_semver.dart';

class VersionComparator {
  /// Returns true if [remote] is newer than [local]
  bool isUpdateAvailable(String remote, String local) {
    try {
      final remoteVersion = Version.parse(remote);
      final localVersion = Version.parse(local);

      // Simple comparison: is remote greater than local?
      return remoteVersion > localVersion;
    } catch (e) {
      // Handle parse errors gracefully
      return false;
    }
  }

  /// Get update type: 'major', 'minor', 'patch', or 'none'
  String getUpdateType(String remote, String local) {
    try {
      final remoteVersion = Version.parse(remote);
      final localVersion = Version.parse(local);

      if (remoteVersion.major > localVersion.major) return 'major';
      if (remoteVersion.minor > localVersion.minor) return 'minor';
      if (remoteVersion.patch > localVersion.patch) return 'patch';
      if (remoteVersion > localVersion) return 'build'; // Build number only

      return 'none';
    } catch (e) {
      return 'unknown';
    }
  }

  /// Example: Compare versions with all operators
  void exampleComparison() {
    final v1 = Version.parse('1.2.3+1');
    final v2 = Version.parse('1.2.3+2');
    final v3 = Version.parse('1.2.4');

    print(v2 > v1);  // true (build number increased)
    print(v3 > v2);  // true (patch version increased)
    print(v1 == v1); // true
    print(v1.compareTo(v2)); // -1 (v1 is less than v2)
  }
}
```

### Key Implementation Notes

1. **Add dependency to `pubspec.yaml`**:
```yaml
dependencies:
  pub_semver: ^2.1.4  # Check pub.dev for latest version
```

2. **Version format in version.json**:
```json
{
  "version": "1.0.0+1",
  "buildDate": "2025-10-30T10:00:00Z"
}
```

3. **Error handling**: Always wrap `Version.parse()` in try-catch (malformed versions throw `FormatException`)

4. **Build number importance**: Since our CI bumps build numbers, `1.0.0+1` vs `1.0.0+2` should trigger update notification

### Testing Strategy

```dart
import 'package:test/test.dart';
import 'package:pub_semver/pub_semver.dart';

void main() {
  group('Version Comparison', () {
    test('detects patch updates', () {
      final v1 = Version.parse('1.0.0');
      final v2 = Version.parse('1.0.1');
      expect(v2 > v1, isTrue);
    });

    test('detects build number updates', () {
      final v1 = Version.parse('1.0.0+1');
      final v2 = Version.parse('1.0.0+2');
      expect(v2 > v1, isTrue);
    });

    test('handles pre-release versions', () {
      final v1 = Version.parse('2.0.0-alpha');
      final v2 = Version.parse('2.0.0');
      expect(v2 > v1, isTrue);
    });
  });
}
```

### References

- [pub_semver on pub.dev](https://pub.dev/packages/pub_semver)
- [Dart Package Versioning Guide](https://dart.dev/tools/pub/versioning)
- [pub_semver GitHub Repository](https://github.com/dart-lang/tools/tree/main/pkgs/pub_semver)

---

## 3. WidgetsBindingObserver for Web

### Decision

**DO NOT use `WidgetsBindingObserver.didChangeAppLifecycleState` for Flutter web.** Instead, use `dart:html`'s `visibilitychange` event with manual event listeners to detect when the user returns to the tab.

### Rationale

**Why WidgetsBindingObserver Doesn't Work on Web**:
- `didChangeAppLifecycleState` is primarily designed for mobile platforms (iOS/Android)
- On Flutter web, the AppLifecycleState API is incomplete and unreliable
- GitHub Issue #77843 tracks this limitation (as of 2025, still not fully implemented)
- Web browsers use the Page Visibility API, which is different from mobile lifecycle

**How Browser Tab Visibility Works**:
- Browsers expose `document.visibilityState` (either `"visible"` or `"hidden"`)
- The `visibilitychange` event fires when user switches tabs, minimizes browser, etc.
- This is the web-standard way to detect tab focus/blur

**Why This Approach is Better**:
- Direct access to browser APIs via `dart:html`
- Reliable cross-browser support (Page Visibility API is widely supported)
- Low performance overhead (event-driven, not polling)
- Can easily clean up listeners in `dispose()`

**Performance Implications**:
- Event listeners are lightweight (fired only on visibility changes)
- No polling required (unlike checking visibility in a timer)
- Properly cleaned up in `dispose()` to prevent memory leaks
- No impact on app performance when tab is hidden

### Alternatives Considered

**Alternative 1: Use WidgetsBindingObserver**
```dart
class _MyState extends State<MyWidget> with WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // This doesn't work reliably on Flutter web!
  }
}
```
**Why Not**:
- Doesn't fire reliably on web (known limitation)
- Designed for mobile, not web
- May be implemented in future Flutter versions, but not reliable now

**Alternative 2: Polling with Timer**
```dart
Timer.periodic(Duration(seconds: 5), (timer) {
  if (document.visibilityState == 'visible') {
    // Check for updates
  }
});
```
**Why Not**:
- Wasteful (checks even when user isn't switching tabs)
- Delays detection (only checks every N seconds)
- More battery/resource intensive

**Alternative 3: Use `window.onFocus` / `window.onBlur`**
```dart
html.window.onFocus.listen((_) { /* ... */ });
```
**Why Not**:
- Less reliable than `visibilitychange` (doesn't handle all cases)
- `visibilitychange` is the modern standard
- Doesn't handle minimized windows correctly

### Code Example

```dart
import 'dart:html' as html;
import 'package:flutter/foundation.dart' show kIsWeb;

class VersionCheckService {
  late final html.EventListener _visibilityListener;

  void startListening() {
    if (!kIsWeb) return; // Only run on web

    // Create listener function (needed for cleanup)
    _visibilityListener = (html.Event event) {
      _handleVisibilityChange();
    };

    // Register listener
    html.document.addEventListener('visibilitychange', _visibilityListener);
  }

  void _handleVisibilityChange() {
    // Check if tab is now visible
    if (html.document.visibilityState == 'visible') {
      print('Tab is now visible - checking for updates...');
      _checkForUpdates();
    } else {
      print('Tab is now hidden');
    }
  }

  Future<void> _checkForUpdates() async {
    // Version check logic here
  }

  void stopListening() {
    if (!kIsWeb) return;

    // Clean up listener to prevent memory leaks
    html.document.removeEventListener('visibilitychange', _visibilityListener);
  }
}

// Usage in a StatefulWidget:
class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _versionCheckService = VersionCheckService();

  @override
  void initState() {
    super.initState();
    _versionCheckService.startListening();
  }

  @override
  void dispose() {
    _versionCheckService.stopListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(/* ... */);
  }
}
```

### Alternative Pattern: Using HtmlDocument.visibilityChangeEvent

```dart
import 'dart:html' as html;
import 'dart:async';

class AlternativeVersionCheckService {
  StreamSubscription<html.Event>? _subscription;

  void startListening() {
    if (!kIsWeb) return;

    // Use the EventStreamProvider approach
    _subscription = html.document.onVisibilityChange.listen((event) {
      if (html.document.visibilityState == 'visible') {
        _checkForUpdates();
      }
    });
  }

  Future<void> _checkForUpdates() async {
    // Version check logic
  }

  void stopListening() {
    _subscription?.cancel();
  }
}
```

### Key Implementation Notes

1. **Platform check**: Always wrap in `if (kIsWeb)` to prevent errors on mobile/desktop
2. **Cleanup**: MUST call `removeEventListener` or cancel subscription in `dispose()`
3. **Visibility state**: Check `document.visibilityState == 'visible'` before acting
4. **Timing**: Event fires immediately when tab becomes visible (no delay)
5. **Browser support**: Page Visibility API supported in all modern browsers (IE10+)

### Testing Strategy

```dart
// Testing with dart:html is tricky - mock the service instead
class MockVersionCheckService implements VersionCheckService {
  bool isListening = false;
  int checkCount = 0;

  @override
  void startListening() {
    isListening = true;
  }

  @override
  Future<void> checkForUpdates() async {
    checkCount++;
  }

  @override
  void stopListening() {
    isListening = false;
  }
}

void main() {
  testWidgets('Version service starts and stops with widget lifecycle', (tester) async {
    final service = MockVersionCheckService();

    await tester.pumpWidget(MyApp(versionService: service));
    expect(service.isListening, isTrue);

    await tester.pumpWidget(Container()); // Remove widget
    expect(service.isListening, isFalse);
  });
}
```

### References

- [Flutter Issue #77843: AppLifecycleState for web using Page Visibility API](https://github.com/flutter/flutter/issues/77843)
- [Stack Overflow: Detect AppLifeCycleState changes in Flutter web](https://stackoverflow.com/questions/68367780/flutter-web-how-to-detect-applifecyclestate-changes)
- [MDN: Page Visibility API](https://developer.mozilla.org/en-US/docs/Web/API/Page_Visibility_API)

---

## 4. Material Banner vs SnackBar

### Decision

**Use MaterialBanner** for displaying persistent update notifications. SnackBar is better suited for temporary, auto-dismissing messages.

### Rationale

**Why MaterialBanner is Better for Updates**:
- **Persistent**: Stays visible until user explicitly dismisses it
- **Non-modal**: Doesn't block interaction with the app
- **Prominent**: Displayed at top of screen (hard to miss)
- **Two actions**: Supports both "Reload Now" and "Dismiss" buttons
- **Clear intent**: Material Design guidelines recommend banners for important, non-urgent information

**Why NOT SnackBar**:
- **Auto-dismissing**: Disappears after timeout (user might miss it)
- **Bottom placement**: Can be obscured by keyboard or UI elements
- **Single action**: Typically shows one action button
- **Brief messages**: Designed for quick feedback, not persistent notifications
- **Easy to miss**: Can slide away before user notices

**Material Design Guidance**:
- Banners: Persistent notifications requiring acknowledgment
- SnackBars: Brief messages about app processes (e.g., "File saved")

**User Experience Benefits**:
- User controls when to reload (won't interrupt their work)
- Notification stays visible while they finish current task
- Clear call-to-action with two options (reload or dismiss)
- Professional appearance (not intrusive like a dialog)

### Alternatives Considered

**Alternative 1: SnackBar**
```dart
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text('New version available'),
    duration: Duration(seconds: 10),
    action: SnackBarAction(label: 'Reload', onPressed: () {}),
  ),
);
```
**Why Not**:
- Auto-dismisses (user might miss update notification)
- Only one action button (can't easily show both "Reload" and "Dismiss")
- Bottom placement (less prominent)

**Alternative 2: AlertDialog (modal)**
```dart
showDialog(
  context: context,
  builder: (context) => AlertDialog(
    title: Text('Update Available'),
    content: Text('A new version is available'),
    actions: [/* ... */],
  ),
);
```
**Why Not**:
- Modal (blocks app interaction - too disruptive)
- Requires immediate user decision
- Not appropriate for non-urgent updates

**Alternative 3: Custom overlay widget**
**Why Not**:
- Reinventing the wheel
- MaterialBanner is designed for this exact use case
- More code to maintain

### Code Example

```dart
import 'package:flutter/material.dart';

class UpdateNotificationService {
  /// Show a persistent update notification banner
  void showUpdateAvailable(
    BuildContext context, {
    required String currentVersion,
    required String newVersion,
    required VoidCallback onReload,
  }) {
    // Remove any existing banner first
    ScaffoldMessenger.of(context).removeCurrentMaterialBanner();

    // Show new banner
    ScaffoldMessenger.of(context).showMaterialBanner(
      MaterialBanner(
        backgroundColor: Colors.blue[50],
        leading: Icon(
          Icons.system_update,
          color: Colors.blue[700],
        ),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'New version available',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blue[900],
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Version $newVersion is ready (you have $currentVersion)',
              style: TextStyle(
                fontSize: 12,
                color: Colors.blue[700],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
            },
            child: Text('LATER'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
              onReload();
            },
            icon: Icon(Icons.refresh),
            label: Text('RELOAD NOW'),
          ),
        ],
      ),
    );
  }

  /// Hide the update banner
  void hideUpdateBanner(BuildContext context) {
    ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
  }
}
```

### Advanced Example: With Animation

```dart
class AnimatedUpdateBanner extends StatelessWidget {
  final String currentVersion;
  final String newVersion;
  final VoidCallback onReload;
  final VoidCallback onDismiss;

  const AnimatedUpdateBanner({
    required this.currentVersion,
    required this.newVersion,
    required this.onReload,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialBanner(
      backgroundColor: Colors.amber[50],
      leading: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: Duration(milliseconds: 800),
        builder: (context, value, child) {
          return Transform.rotate(
            angle: value * 2 * 3.14159, // Full rotation
            child: Icon(Icons.system_update, color: Colors.amber[700]),
          );
        },
      ),
      content: RichText(
        text: TextSpan(
          style: TextStyle(color: Colors.black87),
          children: [
            TextSpan(
              text: 'Version $newVersion',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(text: ' is available. Reload to update.'),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: onDismiss,
          child: Text('DISMISS'),
        ),
        ElevatedButton.icon(
          onPressed: onReload,
          icon: Icon(Icons.refresh),
          label: Text('RELOAD'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amber[700],
          ),
        ),
      ],
    );
  }
}
```

### Key Implementation Notes

1. **Prevent duplicates**: Call `removeCurrentMaterialBanner()` before showing new banner
2. **ScaffoldMessenger**: Use `ScaffoldMessenger.of(context)` (not `Scaffold.of(context)`)
3. **Two actions**: Always provide both "dismiss" and "action" buttons
4. **Styling**: Use appropriate colors (blue for info, amber for warnings)
5. **Content**: Keep text concise but informative
6. **Icon**: Use `Icons.system_update` or `Icons.refresh` for clarity

### Best Practices

```dart
// DO: Remove old banner before showing new one
ScaffoldMessenger.of(context)
  ..removeCurrentMaterialBanner()
  ..showMaterialBanner(banner);

// DO: Provide context in the message
content: Text('Version 1.2.0 is available (you have 1.1.0)')

// DON'T: Use vague messages
content: Text('Update available') // Too vague

// DO: Use appropriate action labels
actions: [
  TextButton(child: Text('LATER'), onPressed: dismiss),
  ElevatedButton(child: Text('RELOAD NOW'), onPressed: reload),
]

// DON'T: Use unclear labels
actions: [
  TextButton(child: Text('OK'), onPressed: dismiss), // Unclear intent
]
```

### Accessibility Considerations

```dart
MaterialBanner(
  content: Semantics(
    label: 'New app version $newVersion is available',
    child: Text('New version available: $newVersion'),
  ),
  actions: [
    TextButton(
      onPressed: onDismiss,
      child: Semantics(
        label: 'Dismiss update notification',
        child: Text('DISMISS'),
      ),
    ),
    ElevatedButton.icon(
      onPressed: onReload,
      icon: Icon(Icons.refresh),
      label: Semantics(
        label: 'Reload app to update to version $newVersion',
        child: Text('RELOAD'),
      ),
    ),
  ],
);
```

### References

- [MaterialBanner API Documentation](https://api.flutter.dev/flutter/material/MaterialBanner-class.html)
- [ScaffoldMessengerState.showMaterialBanner](https://api.flutter.dev/flutter/material/ScaffoldMessengerState/showMaterialBanner.html)
- [Material Design: Banners](https://m2.material.io/components/banners)
- [KindaCode: Working with MaterialBanner in Flutter](https://www.kindacode.com/article/working-with-materialbanner-in-flutter)

---

## 5. dart:html Service Worker APIs

### Decision

**DO NOT manually unregister the service worker.** Access service worker APIs via `dart:html` only for informational purposes (e.g., checking if a service worker is registered). Let Flutter's built-in service worker lifecycle handle registration/unregistration.

### Rationale

**Why Avoid Manual Unregistration**:
- Flutter is deprecating the default service worker in 2025
- Flutter will provide a "cleanup" service worker that auto-removes itself
- Manual unregistration could interfere with Flutter's cleanup process
- Simple `window.location.reload()` is sufficient for applying updates

**When to Use dart:html Service Worker APIs**:
- Checking if a service worker is currently registered (diagnostics)
- Detecting service worker state (active, waiting, installing)
- Debugging service worker issues
- Feature detection (does browser support service workers?)

**Browser Compatibility** (2025):
- Service Workers: Supported in all modern browsers (Chrome, Firefox, Safari, Edge)
- Not supported: IE11 and older browsers
- Progressive enhancement: App works without service workers (just won't cache offline)

**Safe Pattern**:
- Access via `window.navigator.serviceWorker` (returns `ServiceWorkerContainer?`)
- Always null-check (service workers may not be supported)
- Use `getRegistration()` to check current registration
- Don't call `unregister()` unless explicitly needed for debugging

### Alternatives Considered

**Alternative 1: Manually unregister before reload**
```dart
final registration = await html.window.navigator.serviceWorker?.getRegistration();
await registration?.unregister();
html.window.location.reload();
```
**Why Not**:
- Unnecessary complexity
- Could interfere with Flutter's 2025 cleanup process
- Simple reload is sufficient

**Alternative 2: Use `clients.claim()` and `skipWaiting()`**
```dart
// In custom service worker
self.addEventListener('install', (event) => {
  self.skipWaiting();
});
```
**Why Not**:
- Requires custom service worker (Flutter is deprecating default)
- More complex to maintain
- Our approach (notify user, let them reload) is simpler and safer

**Alternative 3: Use `service_worker` pub package**
**Why Not**:
- Adds dependency for minimal benefit
- `dart:html` provides everything we need
- Package is just JS bindings (not much value over dart:html)

### Code Example

```dart
import 'dart:html' as html;
import 'package:flutter/foundation.dart' show kIsWeb;

class ServiceWorkerInfo {
  /// Check if service workers are supported in current browser
  static bool isSupported() {
    if (!kIsWeb) return false;
    return html.window.navigator.serviceWorker != null;
  }

  /// Get information about current service worker registration (for debugging)
  static Future<Map<String, dynamic>> getInfo() async {
    if (!isSupported()) {
      return {'supported': false};
    }

    try {
      final registration = await html.window.navigator.serviceWorker?.getRegistration();

      if (registration == null) {
        return {
          'supported': true,
          'registered': false,
        };
      }

      return {
        'supported': true,
        'registered': true,
        'scope': registration.scope,
        'hasActive': registration.active != null,
        'hasWaiting': registration.waiting != null,
        'hasInstalling': registration.installing != null,
        'activeState': registration.active?.state,
      };
    } catch (e) {
      return {
        'supported': true,
        'error': e.toString(),
      };
    }
  }

  /// Log service worker info to console (for debugging)
  static Future<void> logInfo() async {
    final info = await getInfo();
    print('Service Worker Info:');
    info.forEach((key, value) {
      print('  $key: $value');
    });
  }

  /// CAUTION: Only use this for debugging/testing
  /// In production, let Flutter's service worker handle lifecycle
  static Future<bool> unregisterForDebug() async {
    if (!isSupported()) return false;

    try {
      final registration = await html.window.navigator.serviceWorker?.getRegistration();
      if (registration != null) {
        final success = await registration.unregister();
        print('Service worker unregistered: $success');
        return success;
      }
      return false;
    } catch (e) {
      print('Error unregistering service worker: $e');
      return false;
    }
  }
}
```

### Example: Service Worker State Monitoring

```dart
import 'dart:html' as html;
import 'dart:async';

class ServiceWorkerMonitor {
  StreamSubscription? _subscription;

  /// Monitor service worker updates (fires when new SW is waiting)
  void startMonitoring(void Function() onUpdateAvailable) {
    if (!ServiceWorkerInfo.isSupported()) return;

    html.window.navigator.serviceWorker?.getRegistration().then((registration) {
      if (registration == null) return;

      // Listen for updatefound event
      registration.onUpdateFound.listen((event) {
        final installingWorker = registration.installing;
        if (installingWorker == null) return;

        // Listen to installing worker's state changes
        installingWorker.addEventListener('statechange', (event) {
          if (installingWorker.state == 'installed' && registration.active != null) {
            // New service worker is installed and waiting
            print('New service worker installed and waiting');
            onUpdateAvailable();
          }
        });
      });
    });
  }

  void stopMonitoring() {
    _subscription?.cancel();
  }
}
```

### Key Implementation Notes

1. **Always null-check**: `window.navigator.serviceWorker` can be null
2. **Use for diagnostics**: Helpful for debugging update issues
3. **Don't unregister**: Let Flutter manage service worker lifecycle
4. **Feature detection**: Check support before accessing APIs
5. **Async operations**: All service worker operations return Futures

### Testing Service Worker Behavior

```dart
// Debug helper to test update flow
class ServiceWorkerDebugHelper {
  /// Force service worker to update (for testing)
  static Future<void> forceUpdate() async {
    if (!ServiceWorkerInfo.isSupported()) return;

    final registration = await html.window.navigator.serviceWorker?.getRegistration();
    if (registration != null) {
      await registration.update(); // Triggers update check
      print('Service worker update check triggered');
    }
  }

  /// Clear all caches (for testing)
  static Future<void> clearAllCaches() async {
    if (!kIsWeb) return;

    try {
      final cacheNames = await html.window.caches?.keys();
      if (cacheNames != null) {
        for (final name in cacheNames) {
          await html.window.caches?.delete(name);
          print('Deleted cache: $name');
        }
      }
    } catch (e) {
      print('Error clearing caches: $e');
    }
  }
}
```

### Browser Compatibility Check

```dart
class BrowserCapabilities {
  static Map<String, bool> check() {
    if (!kIsWeb) {
      return {
        'serviceWorker': false,
        'cacheStorage': false,
        'notifications': false,
      };
    }

    return {
      'serviceWorker': html.window.navigator.serviceWorker != null,
      'cacheStorage': html.window.caches != null,
      'notifications': html.Notification.supported,
      'pageVisibility': html.document.visibilityState != null,
    };
  }

  static void logCapabilities() {
    print('Browser Capabilities:');
    check().forEach((key, value) {
      print('  $key: $value');
    });
  }
}
```

### Safe Usage Pattern

```dart
// ✅ GOOD: Read-only access for information
Future<void> checkServiceWorkerStatus() async {
  if (!kIsWeb) return;

  final sw = html.window.navigator.serviceWorker;
  if (sw == null) {
    print('Service workers not supported');
    return;
  }

  final registration = await sw.getRegistration();
  if (registration == null) {
    print('No service worker registered');
  } else {
    print('Service worker active: ${registration.active != null}');
  }
}

// ❌ BAD: Manually manipulating service worker lifecycle
Future<void> forceUpdateServiceWorker() async {
  // Don't do this in production!
  final registration = await html.window.navigator.serviceWorker?.getRegistration();
  await registration?.unregister(); // Let Flutter handle this
  html.window.location.reload();
}

// ✅ GOOD: Simple reload (recommended approach)
void reloadApp() {
  html.window.location.reload();
}
```

### References

- [ServiceWorkerRegistration.unregister() - Flutter API](https://api.flutter.dev/flutter/dart-html/ServiceWorkerRegistration/unregister.html)
- [ServiceWorker class - dart:html](https://api.flutter.dev/flutter/dart-html/ServiceWorker-class.html)
- [Flutter Issue #156910: Deprecate and remove flutter_service_worker.js](https://github.com/flutter/flutter/issues/156910)
- [MDN: Service Worker API](https://developer.mozilla.org/en-US/docs/Web/API/Service_Worker_API)

---

## Summary of Decisions

| Topic | Decision | Package/API | Rationale |
|-------|----------|-------------|-----------|
| **Service Worker Lifecycle** | Don't unregister, use simple `window.location.reload()` | `dart:html` | Flutter's 2025 cleanup process handles it; unnecessary complexity |
| **Version Parsing** | Use `pub_semver` package | `pub_semver: ^2.1.4` | Official Dart package, battle-tested, handles all edge cases |
| **Tab Focus Detection** | Use `visibilitychange` event listener | `dart:html` | `WidgetsBindingObserver` doesn't work on web; browser API is reliable |
| **Update Notification** | Use `MaterialBanner` | Material library | Persistent, non-modal, supports two actions; better UX than SnackBar |
| **Service Worker Access** | Read-only diagnostics, don't manipulate | `dart:html` | Let Flutter manage lifecycle; only use for debugging info |

---

## Implementation Checklist

- [ ] Add `pub_semver` dependency to `pubspec.yaml`
- [ ] Create `version.json` in `/web/` directory
- [ ] Implement `VersionCheckService` with `visibilitychange` listener
- [ ] Implement `VersionComparator` using `pub_semver`
- [ ] Implement `UpdateNotificationService` with `MaterialBanner`
- [ ] Add service worker info methods for debugging (optional)
- [ ] Test version comparison logic with unit tests
- [ ] Test update notification UI in web browser
- [ ] Document manual testing procedure (simulate updates)
- [ ] Add logging for version check operations

---

## Next Steps

1. **Phase 1: Design** - Create detailed implementation plan based on these decisions
2. **Phase 2: Implementation** - Build components with code examples above
3. **Phase 3: Testing** - Test across browsers, simulate version updates
4. **Phase 4: Documentation** - Update CLAUDE.md with implementation details

---

## Additional Resources

### Flutter Web Deployment
- [Flutter Web Initialization](https://docs.flutter.dev/platform-integration/web/initialization)
- [Flutter Build Web Documentation](https://docs.flutter.dev/deployment/web)

### Service Worker Resources
- [MDN: Service Worker Lifecycle](https://developer.mozilla.org/en-US/docs/Web/API/Service_Worker_API/Using_Service_Workers#the_service_worker_life_cycle)
- [MDN: Page Visibility API](https://developer.mozilla.org/en-US/docs/Web/API/Page_Visibility_API)

### Flutter Material Design
- [Material Banner Guidelines](https://m2.material.io/components/banners)
- [SnackBar Guidelines](https://m2.material.io/components/snackbars)

### Version Management
- [Semantic Versioning 2.0.0](https://semver.org/)
- [Dart Package Versioning](https://dart.dev/tools/pub/versioning)

---

**Document Version**: 1.0.0
**Last Updated**: 2025-10-30
**Researched By**: Claude Code
**Status**: ✅ Complete - Ready for implementation planning
