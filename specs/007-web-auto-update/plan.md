# Implementation Plan: Web App Update Detection and Auto-Refresh

**Branch**: `007-web-auto-update` | **Date**: 2025-01-30 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/007-web-auto-update/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

Implement automatic update detection for Flutter web app deployed to GitHub Pages to ensure users always run the latest version. When a new version is deployed, users returning to the app will see a non-blocking notification prompting them to reload. The system checks for updates on app launch and resume, compares semantic versions, and triggers a cache-bypassing reload when user accepts.

**Technical Approach**: Create a `VersionCheckService` that fetches `/version.json` from the server and compares with local version from `package_info_plus`. Integrate with Flutter's `WidgetsBindingObserver` to detect app resume events. Display update notification using Material Banner UI component. Implement debouncing (10 seconds) to prevent excessive network requests during rapid tab switching.

## Technical Context

**Language/Version**: Dart 3.9.0+, Flutter 3.19.0+ (web platform only)
**Primary Dependencies**: `http` ^1.1.0 (fetch version.json), `package_info_plus` ^8.1.2 (already present), `dart:html` (service worker APIs)
**Storage**: N/A (stateless service, transient in-memory state for debouncing)
**Testing**: `flutter test` with `mockito` for service mocking, widget tests for UI components
**Target Platform**: Flutter web (Chrome, Firefox, Safari, Edge with service worker support)
**Project Type**: Web (single Flutter web application)
**Performance Goals**: Version check <100ms startup overhead, <2 seconds network timeout, notification render <16ms (60fps)
**Constraints**: <200ms perceived latency for notification display, no blocking user interactions, graceful degradation on network failure
**Scale/Scope**: Single-file version.json (<1KB), 10-100 version checks per user per day, minimal memory footprint (<1KB state)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### Principle I: Test-Driven Development ✅
- **Compliance**: Tests will be written first for `VersionCheckService`, lifecycle observer, and notification UI
- **Approach**: Unit tests for version comparison logic, widget tests for banner component, integration test for full flow
- **TDD Cycle**: Red (failing version comparison test) → Green (implement semver parser) → Refactor (extract version parsing)

### Principle II: Code Quality & Maintainability ✅
- **Compliance**: All code follows Flutter/Dart style guide, flutter_lints enforced
- **Complexity**: Version comparison function O(1), lifecycle observer single responsibility, service <150 LOC
- **Coverage Target**: 80%+ for VersionCheckService (business logic), 60%+ overall with UI components
- **Documentation**: All public APIs documented, inline comments for semver parsing logic

### Principle III: User Experience Consistency ✅
- **Compliance**: Material Banner uses existing app theme, consistent with notification patterns
- **Interaction**: Dismissable banner, non-blocking, reappears on resume (consistent with ephemeral notifications)
- **Error Handling**: Silent failure on network errors, no user-facing error messages (graceful degradation)
- **Loading State**: Version check is non-blocking, no loading spinner needed
- **Accessibility**: Banner includes semantic labels, "Update Now" button meets 44x44px touch target

### Principle IV: Performance Standards ✅
- **Compliance**: Version check adds <100ms to startup (network fetch is async, non-blocking)
- **User Interaction**: Banner render <16ms, reload triggered within 100ms of button click
- **Network**: 2-second timeout for version.json fetch, debouncing prevents network spam
- **Memory**: Stateless service with single DateTime field (<1KB), no leaks

### Principle V: Data Integrity & Security ✅
- **Compliance**: No financial data involved, version comparison is deterministic
- **Validation**: Version string format validated (regex), malformed JSON handled gracefully
- **Error Recovery**: Network failures logged to console, app continues functioning
- **Audit Trail**: Not applicable (read-only version checking, no user data)

**GATE STATUS**: ✅ PASS - All principles satisfied, no violations to justify

## Project Structure

### Documentation (this feature)

```
specs/007-web-auto-update/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
│   └── version-api.yaml # OpenAPI spec for /version.json endpoint
├── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
└── checklists/
    └── requirements.md  # Spec validation checklist (already created)
```

### Source Code (repository root)

```
lib/
├── core/
│   ├── services/
│   │   ├── version_check_service.dart       # NEW: Fetches and compares versions
│   │   └── app_lifecycle_service.dart       # NEW: Observes app resume events
│   └── widgets/
│       └── update_notification_banner.dart  # NEW: Material Banner UI component
├── main.dart                                 # MODIFIED: Initialize lifecycle observer
└── app.dart                                  # MODIFIED: Wrap with update notification listener

test/
├── core/
│   ├── services/
│   │   ├── version_check_service_test.dart  # NEW: Unit tests for version comparison
│   │   └── app_lifecycle_service_test.dart  # NEW: Unit tests for lifecycle observer
│   └── widgets/
│       └── update_notification_banner_test.dart # NEW: Widget tests for banner
└── integration/
    └── update_flow_test.dart                # NEW: E2E test for update detection

pubspec.yaml                                  # MODIFIED: Add http dependency
```

**Structure Decision**: Flutter web application with clean architecture. Services live in `lib/core/services/` for reusability, widgets in `lib/core/widgets/` for shared UI components. Tests mirror source structure. This aligns with existing project conventions (e.g., `lib/core/router/`, `lib/features/`).

## Complexity Tracking

*No violations - this table is not needed.*

## Phase 0: Research & Technology Selection

### Research Topics

1. **Flutter Web Service Worker Lifecycle**
   - **Question**: How does `flutter_service_worker.js` handle cache invalidation and update detection?
   - **Research Goal**: Understand existing update mechanism, identify why it's insufficient, determine if unregister is necessary

2. **Semantic Version Parsing in Dart**
   - **Question**: Is there an existing Dart package for semantic version comparison, or should we implement custom parser?
   - **Research Goal**: Find best practice for parsing "major.minor.patch+build" format, handle edge cases (pre-release tags)

3. **WidgetsBindingObserver Best Practices**
   - **Question**: What's the recommended pattern for lifecycle observation in Flutter web? Any performance implications?
   - **Research Goal**: Understand `didChangeAppLifecycleState` behavior in web context, debouncing patterns

4. **Material Banner vs SnackBar**
   - **Question**: Which UI component is better for persistent, dismissable notifications in Flutter?
   - **Research Goal**: Compare Material Banner (persistent) vs SnackBar (auto-dismiss), alignment with Material Design guidelines

5. **dart:html Service Worker APIs**
   - **Question**: How to safely unregister service worker from Dart code? What are failure modes?
   - **Research Goal**: Find reliable pattern for service worker unregister, understand browser compatibility

### Research Deliverables

Output: `research.md` containing:
- Decision: Use custom semantic version parser (lightweight, no external dependency)
- Decision: Use WidgetsBindingObserver with manual debouncing (no built-in web lifecycle events)
- Decision: Use Material Banner (persistent, dismissable, fits requirement)
- Decision: Best-effort service worker unregister via `js` package (optional, non-blocking)
- Rationale: Each decision documented with alternatives considered
- Code examples: Sample implementation patterns for each component

## Phase 1: Design & Contracts

### Data Model

**File**: `data-model.md`

#### Version Entity
```dart
class Version {
  final int major;
  final int minor;
  final int patch;
  final int build;

  // Parse "1.0.1+2" format
  // Compare using numeric ordering
  // Handle invalid formats with exception
}
```

#### Update Check State (Transient)
```dart
class UpdateCheckState {
  final DateTime? lastCheckTime;
  final bool isCheckingNow;
  final bool updateAvailable;
  final Version? serverVersion;

  // Used for debouncing
  // Not persisted, lives in memory
}
```

### API Contracts

**File**: `contracts/version-api.yaml`

```yaml
openapi: 3.0.0
info:
  title: Version API
  version: 1.0.0
  description: Static endpoint for version checking

paths:
  /version.json:
    get:
      summary: Get deployed app version
      responses:
        '200':
          description: Version information
          content:
            application/json:
              schema:
                type: object
                required:
                  - version
                properties:
                  version:
                    type: string
                    pattern: ^\d+\.\d+\.\d+\+\d+$
                    example: "1.0.1+2"
        '404':
          description: Version file not found (gracefully handled)
```

### Service Contracts

#### VersionCheckService
```dart
abstract class VersionCheckService {
  /// Fetches server version from /version.json
  /// Compares with local version
  /// Returns true if server version is newer
  /// Throws no exceptions (returns false on error)
  Future<bool> isUpdateAvailable();

  /// Gets server version string if available
  /// Returns null on fetch failure
  Future<String?> getServerVersion();
}
```

#### AppLifecycleService
```dart
abstract class AppLifecycleService {
  /// Starts observing app lifecycle events
  /// Calls onResume callback when app returns to foreground
  /// Debounces rapid events (10-second minimum)
  void startObserving({required VoidCallback onResume});

  /// Stops observing lifecycle events
  void stopObserving();
}
```

### Quickstart Guide

**File**: `quickstart.md`

```markdown
# Update Detection Quickstart

## For Developers

### Local Testing

1. **Simulate version mismatch**:
   - Edit `pubspec.yaml` version to 1.0.0+1
   - Run `flutter build web`
   - Serve with `python -m http.server -d build/web 8000`
   - Edit `build/web/version.json` to 1.0.1+2
   - Reload page → notification should appear

2. **Test debouncing**:
   - Switch tabs rapidly (< 10 seconds between switches)
   - Verify only one version check happens
   - Check console logs for debounce messages

3. **Test offline behavior**:
   - Open DevTools Network tab → set to Offline
   - Switch tabs → no error shown, app works normally
   - Check console for "version check failed" log

### Integration Points

**main.dart**:
```dart
void main() {
  runApp(
    AppLifecycleProvider( // Wrap with lifecycle observer
      child: MyApp(),
    ),
  );
}
```

**app.dart** (root widget):
```dart
@override
Widget build(BuildContext context) {
  return UpdateNotificationListener( // Wrap scaffold
    child: MaterialApp(...),
  );
}
```

## For Testers

### Manual Test Cases

1. **P1 - Update on Resume**:
   - Deploy new version to staging
   - Open app with old version
   - Switch to different tab for 30+ seconds
   - Return to app → notification appears

2. **P2 - Update on Launch**:
   - Deploy new version
   - Open app in incognito window
   - Notification appears within 2 seconds

3. **P3 - Offline Graceful Failure**:
   - Disconnect network
   - Switch tabs and return
   - No error message, app works normally

### Automated Tests

Run: `flutter test test/integration/update_flow_test.dart`

Expected: All 3 user stories (P1, P2, P3) pass with green checkmarks
```

## Next Steps

After this planning phase:

1. **Phase 0 Complete**: Review `research.md` for technology decisions
2. **Phase 1 Complete**: Review `data-model.md`, `contracts/`, `quickstart.md`
3. **Run** `/speckit.tasks`: Generate dependency-ordered implementation tasks
4. **Run** `/speckit.analyze`: Validate consistency between spec, plan, and tasks
5. **Run** `/speckit.checklist`: Generate quality assurance checklist
6. **Run** `/speckit.implement`: Execute task-by-task implementation with TDD

## Re-evaluated Constitution Check (Post-Design)

### Principle I: Test-Driven Development ✅
- **Design Impact**: Clear service boundaries enable isolated unit testing
- **Test Strategy**: 5 test files identified, each with specific responsibilities
- **TDD Readiness**: All contracts defined, ready for test-first implementation

### Principle II: Code Quality & Maintainability ✅
- **Design Impact**: Clean architecture with single-responsibility services
- **Complexity**: Version parser is pure function (<50 LOC), services <150 LOC each
- **Maintainability**: No cross-cutting concerns, easy to mock for testing

### Principle III: User Experience Consistency ✅
- **Design Impact**: Material Banner aligns with existing Flutter Material Design usage
- **Interaction Pattern**: Dismissable notification consistent with app patterns
- **Error Handling**: Silent failure preserves UX, no user-facing errors

### Principle IV: Performance Standards ✅
- **Design Impact**: Async/await pattern ensures non-blocking version checks
- **Performance**: Debouncing prevents network spam, 2-second timeout prevents hangs
- **Measurement**: Integration test will measure startup overhead (<100ms target)

### Principle V: Data Integrity & Security ✅
- **Design Impact**: Read-only operation, no data integrity concerns
- **Security**: HTTPS enforced by GitHub Pages, no sensitive data transmitted
- **Error Recovery**: All error paths handled gracefully, app never breaks

**FINAL GATE STATUS**: ✅ PASS - Design maintains compliance with all constitutional principles
