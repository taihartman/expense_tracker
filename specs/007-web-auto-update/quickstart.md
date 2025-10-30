# Quickstart Guide: Web App Update Detection

**Feature**: 007-web-auto-update
**Audience**: Developers, Testers, DevOps
**Last Updated**: 2025-01-30

## Overview

This guide helps you quickly test, deploy, and troubleshoot the web app update detection feature. Follow the appropriate section based on your role.

---

## For Developers

### Prerequisites

```bash
# Ensure you have Flutter web setup
flutter doctor
flutter config --enable-web

# Verify dependencies
flutter pub get

# Check current version
grep 'version:' pubspec.yaml
# Should see: version: 1.0.1+2
```

### Local Development Setup

#### 1. Run in Debug Mode

```bash
# Standard debug run (no version checking in debug mode)
flutter run -d chrome

# Debug with DevTools
flutter run -d chrome --dart-define=DEBUG_VERSION_CHECK=true
```

**Note**: Version checking is disabled in debug builds to avoid false positives during development.

#### 2. Build and Test Locally

```bash
# Build production web app
flutter build web --release

# Serve locally
cd build/web
python3 -m http.server 8000

# Open in browser
open http://localhost:8000
```

### Simulating Version Mismatch

#### Method 1: Manual version.json Edit (Recommended)

```bash
# 1. Build with current version
flutter build web

# 2. Note the current version
cat build/web/version.json
# {"version":"1.0.1+2"}

# 3. Start local server
python3 -m http.server 8000 -d build/web

# 4. In another terminal, edit version.json to simulate newer version
echo '{"version":"1.0.2+3"}' > build/web/version.json

# 5. In browser: Switch tabs and return to app
# Expected: Update notification appears
```

#### Method 2: Build Version Mismatch

```bash
# 1. Build with old version
# Edit pubspec.yaml: version: 1.0.0+1
flutter build web
python3 -m http.server 8001 -d build/web &

# 2. Build with new version
# Edit pubspec.yaml: version: 1.0.1+2
flutter build web
python3 -m http.server 8002 -d build/web &

# 3. Open app on port 8001 (old version)
# 4. Edit build/web/version.json on port 8001 to point to port 8002
# 5. Switch tabs and return
# Expected: Update notification appears
```

### Testing Different Scenarios

#### Scenario 1: Update on Resume (P1)

```bash
# Terminal 1: Start app
flutter build web && python3 -m http.server 8000 -d build/web

# Terminal 2: Simulate deployment
sleep 30  # Wait for app to load
echo '{"version":"1.0.2+3"}' > build/web/version.json

# Browser: Switch to different tab for 15 seconds, then return
# Expected: Notification appears within 2 seconds
```

#### Scenario 2: Update on Launch (P2)

```bash
# 1. Deploy "old" version
echo '{"version":"1.0.1+2"}' > build/web/version.json
python3 -m http.server 8000 -d build/web

# 2. Open in incognito window
# Expected: No notification (versions match)

# 3. Update version.json
echo '{"version":"1.0.2+3"}' > build/web/version.json

# 4. Open new incognito window
# Expected: Notification appears within 2 seconds of page load
```

#### Scenario 3: Offline Behavior (P3)

```bash
# 1. Start app normally
flutter build web && python3 -m http.server 8000 -d build/web

# 2. In browser DevTools:
#    - Open Network tab
#    - Set throttling to "Offline"

# 3. Switch tabs and return
# Expected: No error message, app works normally

# 4. Check browser console
# Expected: "Version check failed" log entry (not shown to user)
```

#### Scenario 4: Debouncing

```bash
# 1. Start app
flutter build web && python3 -m http.server 8000 -d build/web

# 2. Update version.json
echo '{"version":"1.0.2+3"}' > build/web/version.json

# 3. In browser: Rapidly switch tabs (5 times in 5 seconds)
# Expected: Only 1 HTTP request to version.json (visible in Network tab)

# 4. Wait 10 seconds, switch tabs again
# Expected: Another HTTP request (debounce expired)
```

### Debugging

#### Enable Verbose Logging

```dart
// In lib/core/services/version_check_service.dart
class VersionCheckServiceImpl extends VersionCheckService {
  static const bool _verbose = true; // Set to true for debugging

  void _log(String message) {
    if (_verbose || kDebugMode) {
      print('[VersionCheck] $message');
    }
  }
}
```

#### Check Service Worker State

```javascript
// In browser console
navigator.serviceWorker.getRegistration().then(reg => {
  console.log('Service Worker:', reg);
  console.log('Active:', reg.active);
  console.log('Waiting:', reg.waiting);
});
```

#### Monitor Version Checks

```javascript
// In browser console
// Add network listener for version.json requests
performance.getEntriesByType('resource')
  .filter(r => r.name.includes('version.json'))
  .forEach(r => console.log('Version check:', r.name, r.duration + 'ms'));
```

### Common Issues

#### Issue: Notification doesn't appear

**Diagnosis**:
1. Check browser console for errors
2. Verify version.json is accessible: `curl http://localhost:8000/version.json`
3. Confirm versions are different: local < server
4. Check debouncing: wait 10+ seconds before testing again

**Solution**:
```bash
# Clear browser cache
# Chrome: Cmd+Shift+Delete → Clear browsing data → Cached images and files

# Hard reload
# Chrome: Cmd+Shift+R (Mac) or Ctrl+Shift+R (Windows/Linux)
```

#### Issue: Notification appears incorrectly (false positive)

**Diagnosis**:
1. Check version comparison logic
2. Verify version.json hasn't been manually edited incorrectly
3. Confirm pubspec.yaml version matches built version

**Solution**:
```bash
# Rebuild with clean state
flutter clean
flutter pub get
flutter build web

# Verify versions match
grep 'version:' pubspec.yaml
cat build/web/version.json
```

#### Issue: Update button doesn't reload

**Diagnosis**:
1. Check browser console for JavaScript errors
2. Verify reload logic is implemented correctly
3. Test in different browsers

**Solution**:
```dart
// Verify reload implementation in update_notification_banner.dart
void _handleUpdateNow() {
  // Option 1: Simple reload
  html.window.location.reload();

  // Option 2: Force reload (bypass cache)
  html.window.location.href = html.window.location.href;
}
```

---

## For Testers

### Manual Test Checklist

#### Pre-Deployment Testing

- [ ] **P1 - Update on Resume**
  - [ ] Deploy new version to staging
  - [ ] Open app with old version cached
  - [ ] Switch to different tab for 30+ seconds
  - [ ] Return to app
  - [ ] ✓ Notification appears with "A new version is available"
  - [ ] ✓ "Update Now" button is clickable
  - [ ] Click "Update Now"
  - [ ] ✓ Page reloads with new version

- [ ] **P2 - Update on Launch**
  - [ ] Deploy new version to staging
  - [ ] Open app in incognito/private window
  - [ ] ✓ Notification appears within 2 seconds
  - [ ] Click "Update Now"
  - [ ] ✓ Page reloads successfully

- [ ] **P3 - Offline Graceful Failure**
  - [ ] Open app normally
  - [ ] Disconnect internet (airplane mode or DevTools offline)
  - [ ] Switch tabs and return
  - [ ] ✓ No error message shown to user
  - [ ] ✓ App remains fully functional
  - [ ] Reconnect internet
  - [ ] Switch tabs and return
  - [ ] ✓ Version check resumes (notification appears if update available)

#### Notification Behavior

- [ ] **Dismissal & Reappearance**
  - [ ] Notification appears (update available)
  - [ ] Click dismiss/close button (X)
  - [ ] ✓ Notification disappears
  - [ ] Switch tabs and return
  - [ ] ✓ Notification reappears

- [ ] **Multiple Tabs**
  - [ ] Open app in 2 tabs with old version
  - [ ] Deploy new version
  - [ ] Switch to Tab 1
  - [ ] ✓ Notification appears in Tab 1
  - [ ] Switch to Tab 2
  - [ ] ✓ Notification appears in Tab 2 (independent check)

#### Edge Cases

- [ ] **Rapid Tab Switching (Debouncing)**
  - [ ] Open app
  - [ ] Switch tabs 5 times rapidly (within 5 seconds)
  - [ ] ✓ Only 1 version check occurs (visible in Network tab)
  - [ ] Wait 10+ seconds
  - [ ] Switch tabs again
  - [ ] ✓ Another version check occurs

- [ ] **Same Version (No Update)**
  - [ ] Open app when server version = local version
  - [ ] Switch tabs and return
  - [ ] ✓ No notification appears
  - [ ] ✓ App works normally

- [ ] **Older Server Version (Rollback)**
  - [ ] Configure server with older version (if possible)
  - [ ] Switch tabs and return
  - [ ] ✓ No notification appears (don't suggest downgrade)

### Automated Test Execution

```bash
# Run all tests
flutter test

# Run specific test suites
flutter test test/core/services/version_check_service_test.dart
flutter test test/core/widgets/update_notification_banner_test.dart
flutter test test/integration/update_flow_test.dart

# Run with coverage
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

### Test Environments

| Environment | URL | Purpose |
|-------------|-----|---------|
| Local Dev | http://localhost:8000 | Development testing |
| Staging | https://username.github.io/expense_tracker-staging/ | Pre-production validation |
| Production | https://username.github.io/expense_tracker/ | Live deployment |

### Performance Testing

```bash
# Measure startup overhead
# 1. Build production app
flutter build web --release

# 2. Use Lighthouse in Chrome DevTools
# - Open DevTools (F12)
# - Go to Lighthouse tab
# - Run audit
# - Check "Time to Interactive" metric
# - Should be < 100ms overhead from version checking

# 3. Check network timing
# - Open Network tab in DevTools
# - Filter by "version.json"
# - Verify request completes within 2 seconds
```

---

## For DevOps

### Deployment Checklist

#### Pre-Deployment

- [ ] Bump version in `pubspec.yaml`
  ```bash
  # Use version bump script
  .github/scripts/bump-version.sh

  # Or manually edit pubspec.yaml
  # version: 1.0.2+3  # Increment patch or build number
  ```

- [ ] Verify version.json generation
  ```bash
  flutter build web --release
  cat build/web/version.json
  # Should match pubspec.yaml version
  ```

- [ ] Test locally before deploying
  ```bash
  python3 -m http.server 8000 -d build/web
  # Verify app loads and version.json is accessible
  ```

#### Deployment

- [ ] Deploy to GitHub Pages
  ```bash
  # Automatic via GitHub Actions (on push to master)
  git push origin master

  # Or manual deployment
  flutter build web --base-href /expense_tracker/
  # Upload build/web/* to GitHub Pages
  ```

- [ ] Verify deployment
  ```bash
  # Check version.json is accessible
  curl https://username.github.io/expense_tracker/version.json

  # Should return: {"version":"1.0.2+3"}
  ```

#### Post-Deployment

- [ ] Monitor user updates
  - [ ] Check error logs for version check failures
  - [ ] Verify users are receiving notifications (sample manual check)
  - [ ] Confirm no 404 errors on version.json

- [ ] Rollback procedure (if needed)
  ```bash
  # Revert to previous version
  git revert HEAD
  git push origin master

  # Users with newer version will NOT downgrade (by design)
  # New users will get old version until you fix and re-deploy
  ```

### Monitoring

```bash
# Check GitHub Pages deployment status
curl -I https://username.github.io/expense_tracker/version.json

# Should return:
# HTTP/2 200
# content-type: application/json
# cache-control: max-age=600
```

### Troubleshooting Deployment

#### version.json not found (404)

**Cause**: Flutter build didn't generate version.json

**Solution**:
```bash
# Verify pubspec.yaml has version field
grep 'version:' pubspec.yaml

# Clean and rebuild
flutter clean
flutter pub get
flutter build web --release

# Check build output
ls -la build/web/version.json
```

#### version.json has wrong version

**Cause**: Stale build artifacts

**Solution**:
```bash
# Force clean build
flutter clean
rm -rf build/
flutter build web --release

# Verify version matches
grep 'version:' pubspec.yaml
cat build/web/version.json
```

#### Users not seeing updates

**Cause**: Multiple possibilities

**Diagnosis**:
1. Check GitHub Pages deployment completed
2. Verify version.json is accessible publicly
3. Confirm version is actually newer (major.minor.patch+build)
4. Check browser console for errors (ask user)
5. Verify users waited 10+ seconds between tab switches (debouncing)

**Solution**: See "Common Issues" in Developer section above

---

## Integration Points

### Code Locations

```
lib/
├── main.dart                                  # App initialization
├── core/
│   ├── services/
│   │   ├── version_check_service.dart        # Version checking logic
│   │   └── app_lifecycle_service.dart        # Tab focus detection
│   └── widgets/
│       └── update_notification_banner.dart   # Notification UI

test/
├── core/
│   ├── services/
│   │   └── version_check_service_test.dart   # Unit tests
│   └── widgets/
│       └── update_notification_banner_test.dart # Widget tests
└── integration/
    └── update_flow_test.dart                  # E2E tests
```

### main.dart Integration

```dart
import 'package:expense_tracker/core/services/app_lifecycle_service.dart';
import 'package:expense_tracker/core/services/version_check_service.dart';

void main() {
  // Initialize services
  final versionCheckService = VersionCheckServiceImpl();
  final lifecycleService = AppLifecycleServiceImpl(
    onResume: () => versionCheckService.checkForUpdate(),
  );

  runApp(
    MultiProvider(
      providers: [
        Provider<VersionCheckService>.value(value: versionCheckService),
        Provider<AppLifecycleService>.value(value: lifecycleService),
      ],
      child: MyApp(),
    ),
  );

  // Start observing lifecycle events
  lifecycleService.startObserving();

  // Initial version check on app start
  versionCheckService.checkForUpdate();
}
```

### app.dart Integration

```dart
import 'package:expense_tracker/core/widgets/update_notification_banner.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: UpdateNotificationListener( // Wrap root widget
        child: Scaffold(
          // Your app content
        ),
      ),
    );
  }
}
```

---

## FAQ

**Q: How often does the app check for updates?**
A: On app launch (cold start) and every time you return to the tab after being away. Minimum 10 seconds between checks (debouncing).

**Q: Will I be forced to update immediately?**
A: No. You see a notification and can choose when to update by clicking "Update Now". You can also dismiss it and continue working.

**Q: What happens if I have multiple tabs open?**
A: Each tab checks independently. Updating one tab doesn't automatically update others. When you switch to another tab, it will also show the notification.

**Q: Does this work offline?**
A: The app works offline, but version checking requires internet. If offline, the check fails silently and retries on next resume.

**Q: Can I disable update notifications?**
A: Not currently. This is a critical feature to ensure all users have the latest bug fixes and security updates.

**Q: What if the server has an older version (rollback)?**
A: The notification will not appear. We only notify for newer versions, never downgrades.

**Q: How long does the update take?**
A: Clicking "Update Now" reloads the page, which typically takes 1-3 seconds depending on network speed.

**Q: Will my data be lost when I update?**
A: No. Your trip and expense data is persisted and will be available after the reload.

---

## Support

- **Documentation**: See [spec.md](./spec.md), [plan.md](./plan.md), [data-model.md](./data-model.md)
- **Issues**: Report bugs via GitHub Issues with label `feature:007-web-auto-update`
- **Testing**: Run test suite with `flutter test` for immediate feedback
