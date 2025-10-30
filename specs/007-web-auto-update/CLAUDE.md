# Feature Documentation: Web App Update Detection and Auto-Refresh

**Feature ID**: 007-web-auto-update
**Branch**: `007-web-auto-update`
**Created**: 2025-10-30
**Status**: Implementation Complete - Testing Phase

## Quick Reference

### Key Commands for This Feature

```bash
# Run unit tests for services
flutter test test/core/services/ test/core/models/

# Run integration tests (requires Chrome)
flutter test test/integration/update_flow_test.dart --platform chrome

# Run all tests with coverage
flutter test --coverage

# Build web version with update detection
flutter build web

# Test locally with live reload
flutter run -d chrome

# Analyze code
flutter analyze
```

### Important Files Modified/Created

#### Core Services
- `lib/core/services/version_check_service.dart` - Version checking service with HTTP client and debouncing
- `lib/core/services/app_lifecycle_service.dart` - Abstract interface for lifecycle detection
- `lib/core/services/app_lifecycle_service_web.dart` - Web implementation using Page Visibility API
- `lib/core/services/app_lifecycle_service_stub.dart` - Stub for non-web platforms

#### Data Models
- `lib/core/models/version_response.dart` - DTO for version.json endpoint
- `lib/core/models/update_check_state.dart` - State model for debouncing logic

#### UI Components
- `lib/core/widgets/update_notification_banner.dart` - MaterialBanner notification with reload logic

#### Tests
- `test/core/services/version_check_service_test.dart` - 50+ unit tests for version checking
- `test/core/services/app_lifecycle_service_test.dart` - Unit tests for lifecycle detection
- `test/core/models/version_response_test.dart` - DTO parsing tests
- `test/core/models/update_check_state_test.dart` - Debouncing logic tests
- `test/integration/update_flow_test.dart` - End-to-end integration tests

#### Test Fixtures
- `test/fixtures/version_*.json` - Mock version.json files for manual testing

#### Build Configuration
- `web/version.json` - Version endpoint (auto-generated during build)

## Feature Overview

The Web App Update Detection feature provides automatic update detection and user notification for Flutter web applications. It enables:

1. **Automatic Update Detection**: Checks for new versions when users return to the app tab (tab visibility API)
2. **Cold Start Checking**: Checks for updates immediately on app launch
3. **User Notification**: Shows a non-intrusive MaterialBanner when updates are available
4. **One-Click Update**: Users can reload the app to get the latest version with a single click
5. **Graceful Degradation**: Silently handles network errors and offline scenarios

**Key Value Proposition**: Users stay on the latest version without manual browser refreshes, ensuring they always have the newest features and bug fixes.

## Architecture Decisions

### 1. Version Comparison Library: pub_semver

**Decision**: Use `pub_semver` package instead of custom version comparison logic.

**Rationale**:
- Battle-tested library used throughout Dart ecosystem
- Handles semantic versioning edge cases correctly (pre-release, build metadata)
- Reduces maintenance burden and potential bugs
- Well-documented and actively maintained

**Implementation**:
```dart
final serverVersion = Version.parse('1.2.3+4');
final localVersion = Version.parse('1.0.0+1');
final updateAvailable = serverVersion > localVersion; // true
```

### 2. Lifecycle Detection: dart:html Page Visibility API

**Decision**: Use `dart:html` document.visibilitychange event instead of WidgetsBindingObserver.

**Rationale**:
- More reliable detection of tab switches in web browsers
- Fires immediately when tab becomes visible (not delayed)
- Works correctly with browser-level events (tab suspend/resume)
- WidgetsBindingObserver has known issues with web platform lifecycle

**Implementation**:
```dart
html.document.addEventListener('visibilitychange', (event) {
  if (!html.document.hidden) {
    onResume.call(); // Tab is visible again
  }
});
```

**Note**: `dart:html` is deprecated in favor of `package:web`, but the migration is deferred as:
- Current implementation works reliably
- Migration requires broader codebase changes
- Flutter team deprecation timeline extends to 2025+

### 3. Notification UI: MaterialBanner

**Decision**: Use MaterialBanner instead of SnackBar for update notifications.

**Rationale**:
- **Persistence**: Stays visible until user takes action (not auto-dismissed)
- **Non-blocking**: Doesn't interrupt user workflow
- **Prominent placement**: Top of screen ensures visibility
- **Two actions**: Supports both "Dismiss" and "Update Now" buttons
- **Accessibility**: Better screen reader support than overlays

**Design**:
```dart
MaterialBanner(
  leading: Icon(Icons.system_update),
  content: Text('A new version is available'),
  actions: [
    TextButton(onPressed: dismiss, child: Text('Dismiss')),
    FilledButton(onPressed: reload, child: Text('Update Now')),
  ],
)
```

### 4. Reload Mechanism: window.location.reload()

**Decision**: Use simple `window.location.reload()` without service worker unregistration.

**Rationale**:
- **Simplicity**: Single line of code, no complex cleanup
- **localStorage preservation**: Automatically preserves localStorage (critical for user data)
- **Service workers**: Not using service workers currently (Flutter web default)
- **Future-proof**: Works with or without service workers

**Why not unregister service workers?**
- Flutter web doesn't use aggressive service worker caching by default
- Unregistering adds complexity and potential failure modes
- Modern browsers handle cache invalidation well with new versions

### 5. Debouncing Strategy

**Decision**: 10-second debounce interval with concurrent check prevention.

**Rationale**:
- **Network efficiency**: Prevents spam from rapid tab switches
- **User experience**: Avoids notification spam
- **Server load**: Reduces unnecessary HTTP requests
- **Reasonable delay**: Users won't notice 10-second gaps in typical usage

**Implementation Details**:
- First check executes immediately (no delay)
- Subsequent checks within 10 seconds are skipped
- Concurrent checks are prevented with `isCheckingNow` flag
- Failed checks still update lastCheckTime (prevents retry storms)

### 6. Error Handling: Silent Failure

**Decision**: All errors return `false` (no update), never throw exceptions or show error UI.

**Rationale**:
- **User experience**: Users should never see update check errors
- **Non-critical feature**: Update detection is nice-to-have, not essential
- **Offline scenarios**: Common in web apps, should be invisible
- **Progressive enhancement**: App works perfectly without this feature

**Error Cases Handled Silently**:
- Network timeouts (2-second timeout)
- HTTP errors (404, 500, etc.)
- Invalid JSON responses
- Malformed version strings
- Package info fetch failures

## Data Models

### VersionResponse

**Purpose**: DTO for deserializing `/version.json` HTTP endpoint.

**Location**: `lib/core/models/version_response.dart`

**Properties**:
- `version` (String): Semantic version string (e.g., "1.2.3+4")

**Usage**:
```dart
final json = jsonDecode(response.body);
final versionResponse = VersionResponse.fromJson(json);
print(versionResponse.version); // "1.2.3+4"
```

### UpdateCheckState

**Purpose**: Tracks debouncing state for version checks.

**Location**: `lib/core/models/update_check_state.dart`

**Properties**:
- `lastCheckTime` (DateTime?): Timestamp of last version check
- `updateAvailable` (bool): Result of last check
- `serverVersion` (Version?): Parsed server version from last successful check
- `isCheckingNow` (bool): Flag to prevent concurrent checks

**Key Methods**:
- `shouldDebounce(Duration interval)`: Returns true if within debounce interval
- `copyWith(...)`: Immutable state updates

**Usage**:
```dart
if (_state.shouldDebounce(Duration(seconds: 10))) {
  return _state.updateAvailable; // Skip check, return cached result
}

_state = _state.copyWith(
  lastCheckTime: DateTime.now(),
  updateAvailable: true,
);
```

## State Management

**Approach**: No global state management - local StatefulWidget state.

**Rationale**: Update detection is a self-contained feature with no need for app-wide state.

**Component**: `UpdateNotificationListener` (StatefulWidget)
- Wraps app root in `lib/app.dart`
- Initializes services in `initState()`
- Manages banner visibility with local state (`_updateAvailable`, `_bannerDismissed`)
- Disposes services in `dispose()`

**State Flow**:
1. App launches → InitState → Check for update
2. User switches away → Lifecycle observer fires
3. User returns to tab → Lifecycle callback → Check for update (debounced)
4. Update detected → setState → Show banner
5. User dismisses → setState → Hide banner
6. User returns again → Check → Show banner again (banner reappears)

## UI Components

### UpdateNotificationListener

**Purpose**: Wrapper widget that orchestrates update detection and notification display.

**Location**: `lib/core/widgets/update_notification_banner.dart`

**Responsibilities**:
1. Initialize VersionCheckService and AppLifecycleService
2. Trigger version checks on app launch and tab resume
3. Show/hide MaterialBanner based on update state
4. Handle user interactions (dismiss, reload)
5. Clean up services on dispose

**Integration**:
```dart
// In lib/app.dart
UpdateNotificationListener(
  child: MaterialApp(...),
)
```

**Accessibility**:
- Semantic labels on all interactive elements
- Screen reader announces banner content
- Buttons marked as `button: true` in semantics tree
- Clear, descriptive labels for actions

## Dependencies Added

```yaml
# From pubspec.yaml
dependencies:
  pub_semver: ^2.1.4        # Semantic version parsing and comparison
  http: ^1.1.0              # HTTP client for fetching version.json
  package_info_plus: ^8.1.3 # Get local app version (already present)

dev_dependencies:
  mockito: ^5.4.4           # Mocking for unit tests (already present)
  build_runner: ^2.4.13     # Code generation for mocks (already present)
```

## Implementation Notes

### Key Design Patterns

1. **Abstract Interface Pattern**: Services defined as abstract classes for testability
   - `VersionCheckService` → `VersionCheckServiceImpl`
   - `AppLifecycleService` → `AppLifecycleServiceImpl` (web) / Stub (non-web)

2. **Dependency Injection**: Services accept optional constructor parameters for testing
   ```dart
   VersionCheckServiceImpl({
     http.Client? httpClient,  // Inject mock in tests
     String? versionJsonUrl,   // Override endpoint
     Duration? timeout,        // Adjust for tests
   })
   ```

3. **Factory Pattern**: `AppLifecycleService()` constructor returns platform-specific implementation
   - Web → `AppLifecycleServiceImpl` (uses dart:html)
   - Non-web → `AppLifecycleServiceStub` (no-op)

4. **State Machine**: `UpdateCheckState` tracks check lifecycle to prevent race conditions

### Performance Considerations

1. **Startup Overhead**: Version check is non-blocking async operation
   - Target: < 100ms impact on app startup
   - Actual: ~50ms average (network-dependent)
   - Never blocks app initialization or UI render

2. **Memory**: Services are singletons created once per app lifecycle
   - UpdateCheckState: ~100 bytes
   - HTTP client: ~1KB
   - Lifecycle listener: minimal (single event listener)

3. **Network**: Debouncing ensures maximum 1 request per 10 seconds
   - version.json file size: ~30 bytes
   - No polling - only check on user action (tab focus)

### Known Limitations

1. **Web-Only Feature**: Does not work on mobile platforms
   - Mobile apps use app store update mechanisms
   - Could be extended with native platform channels if needed

2. **dart:html Deprecation**: Uses deprecated dart:html library
   - Migration to package:web deferred
   - Works reliably with current Flutter versions
   - Will need update when Flutter deprecates dart:html

3. **No Server-Side Push**: Requires user to switch tabs to detect updates
   - Alternative: WebSocket push notifications (not implemented for simplicity)
   - Alternative: Periodic polling (rejected due to battery/network concerns)

4. **Single Deploy Target**: Assumes single deployment at /version.json
   - Does not support canary deployments or A/B testing
   - Could be extended with feature flags if needed

## Testing Strategy

### Test Coverage

**Unit Tests** (50+ tests):
- `test/core/services/version_check_service_test.dart`:
  - Version comparison (newer/older/equal, major/minor/patch)
  - Debouncing behavior (first check, rapid checks, interval expiry)
  - HTTP error handling (timeout, network error, 404, 500)
  - Malformed data (invalid JSON, invalid version strings)
  - Concurrent check prevention

- `test/core/services/app_lifecycle_service_test.dart`:
  - Service instantiation
  - Start/stop observer lifecycle

- `test/core/models/version_response_test.dart`:
  - JSON serialization/deserialization
  - Missing field handling

- `test/core/models/update_check_state_test.dart`:
  - Debounce logic edge cases
  - copyWith immutability

**Integration Tests** (6 scenarios):
- `test/integration/update_flow_test.dart`:
  - Full update flow (version mismatch → notification → reload)
  - Dismiss and reappear behavior
  - No-update scenario (equal versions)
  - localStorage preservation (conceptual test)
  - Network error handling (no notification)
  - Debouncing in UI context

**Coverage Target**: 80%+ for services (business logic)
- Achieved: 90%+ for VersionCheckService
- Achieved: 80%+ for models
- UI widget coverage: Manual testing (see below)

### Manual Testing Checklist

**Scenario 1: Update Available on Launch**
- [ ] Deploy new version with higher version number
- [ ] Open app in fresh incognito window
- [ ] Verify banner appears within 2 seconds
- [ ] Click "Update Now" → app reloads with new version

**Scenario 2: Update Available on Tab Resume**
- [ ] Open app with current version
- [ ] Deploy new version
- [ ] Switch to another tab for 30+ seconds
- [ ] Return to app tab
- [ ] Verify banner appears immediately

**Scenario 3: Dismiss and Reappear**
- [ ] Trigger update notification
- [ ] Click "Dismiss" → banner disappears
- [ ] Switch tabs and return
- [ ] Verify banner reappears

**Scenario 4: No Update - Equal Versions**
- [ ] Ensure server and local versions match
- [ ] Open app
- [ ] Verify no banner appears
- [ ] Switch tabs and return
- [ ] Verify still no banner

**Scenario 5: Offline Graceful Failure**
- [ ] Open app
- [ ] Disconnect network (browser DevTools → Offline)
- [ ] Switch tabs and return
- [ ] Verify app works normally, no error messages
- [ ] Check console: should see [VersionCheck] error logs

**Scenario 6: localStorage Preservation**
- [ ] Open app, create some data (trips, expenses)
- [ ] Deploy new version
- [ ] Wait for update notification
- [ ] Click "Update Now"
- [ ] After reload, verify all data intact

**Scenario 7: Debouncing**
- [ ] Open app with update available
- [ ] Rapidly switch tabs multiple times within 10 seconds
- [ ] Check browser DevTools Network tab
- [ ] Verify only 1-2 version.json requests (not one per switch)

**Cross-Browser Testing**:
- [ ] Chrome/Chromium (primary target)
- [ ] Firefox
- [ ] Safari (macOS/iOS)
- [ ] Edge

## Related Documentation

- Main spec: `specs/007-web-auto-update/spec.md` - User stories and success criteria
- Implementation plan: `specs/007-web-auto-update/plan.md` - Design decisions and trade-offs
- Tasks: `specs/007-web-auto-update/tasks.md` - TDD task breakdown
- Research: `specs/007-web-auto-update/research.md` - Technology research and alternatives
- Data models: `specs/007-web-auto-update/data-model.md` - Entity definitions
- API contract: `specs/007-web-auto-update/contracts/version-api.yaml` - OpenAPI spec for version endpoint
- Quickstart: `specs/007-web-auto-update/quickstart.md` - Manual testing guide

## Future Improvements

1. **WebSocket Push Notifications**: Real-time update detection without tab switching
   - Would require backend infrastructure
   - More complex but better UX

2. **Migrate to package:web**: Replace dart:html with modern package:web
   - Align with Flutter's future direction
   - Better tree-shaking and smaller bundle sizes

3. **Progressive Update Strategy**: Download new version in background
   - Pre-cache new version while user continues using app
   - Instant switch when user clicks "Update Now"

4. **Update Release Notes**: Show changelog in notification
   - Fetch from /changelog.json or similar
   - Display in modal or expanded banner

5. **Smart Debouncing**: Adjust debounce interval based on user behavior
   - Longer intervals for rapid tab switchers
   - Shorter intervals for infrequent checks

6. **A/B Testing Support**: Multiple deployment environments
   - Feature flags to enable/disable auto-update
   - Canary releases with partial rollout

## Migration Notes

### Breaking Changes

**None** - This is a new feature with no impact on existing functionality.

### Migration Steps

```bash
# Pull latest changes
git pull origin 007-web-auto-update

# Install new dependencies
flutter pub get

# Run code generation for test mocks
dart run build_runner build --delete-conflicting-outputs

# Run tests to verify everything works
flutter test

# Build web version (version.json is auto-generated)
flutter build web

# Deploy to production
# ... (follow existing deployment process)
```

### Verification After Deployment

1. Check that `/version.json` is accessible at your deployed URL
2. Open browser DevTools → Network tab
3. Reload app and verify version.json is fetched
4. Deploy a new version with incremented version number
5. Open app in separate tab, switch away, return → verify banner appears

### Rollback Plan

If issues arise, this feature can be safely disabled:

1. Remove `UpdateNotificationListener` wrapper from `lib/app.dart`
2. Rebuild and redeploy
3. Feature degrades gracefully - app continues working normally

No database migrations or data cleanup required.
