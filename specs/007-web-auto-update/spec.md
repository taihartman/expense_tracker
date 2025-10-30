# Feature Specification: Web App Update Detection and Auto-Refresh

**Feature Branch**: `007-web-auto-update`
**Created**: 2025-01-30
**Status**: Draft
**Input**: User description: "Web App Update Detection and Auto-Refresh for Flutter web deployment to ensure users always see the latest version"

## Problem Statement

Users of the Flutter web app deployed to GitHub Pages experience severe caching issues where they see outdated versions even after new deployments. The app uses Flutter's default service worker with aggressive caching for offline support, causing:

1. **Persistent Cache**: Regular browsers show old versions even after page refresh
2. **Incognito Works**: Incognito mode shows latest version (clean service worker state)
3. **No User Awareness**: Users don't know when updates are available
4. **Manual Workaround Required**: Only hard refresh (Ctrl+Shift+R) clears cache
5. **Unpredictable Update Timing**: Service worker update checks are browser-dependent (typically 24 hours)

This creates poor user experience where bug fixes and new features don't reach users reliably.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Receive Update on App Resume (Priority: P1)

As a user returning to the expense tracker app after being away, I want to automatically see a notification if a new version is available, so that I can quickly update to get the latest features and bug fixes.

**Why this priority**: This is the core value proposition - ensuring users get updates when they return to the app. Without this, the feature provides no value.

**Independent Test**: Can be fully tested by deploying a new version, switching away from the app tab for 30 seconds, then returning. System should show update notification immediately.

**Acceptance Scenarios**:

1. **Given** user has app open with version 1.0.1, **When** version 1.0.2 is deployed and user returns to the tab after being away, **Then** notification appears with "A new version is available" and "Update Now" button
2. **Given** user sees update notification, **When** user clicks "Update Now", **Then** page reloads and shows version 1.0.2
3. **Given** user dismisses notification, **When** user switches tabs and returns, **Then** notification reappears

---

### User Story 2 - Check for Updates on App Launch (Priority: P2)

As a user opening the app in a new tab or browser session, I want the app to immediately check if I'm running the latest version, so that I don't unknowingly use an outdated version.

**Why this priority**: Cold starts are common when users bookmark the app or share links. This ensures they get updates even without an existing session.

**Independent Test**: Can be fully tested by deploying a new version, then opening the app in a fresh incognito window. Update notification should appear within 2 seconds of page load.

**Acceptance Scenarios**:

1. **Given** version 1.0.2 is deployed, **When** user opens app in new tab with old cached version 1.0.1, **Then** notification appears within 2 seconds
2. **Given** user is already on latest version, **When** user opens app, **Then** no notification appears and app works normally
3. **Given** version check is in progress, **When** user starts interacting with app, **Then** app remains fully functional (non-blocking check)

---

### User Story 3 - Graceful Failure When Offline (Priority: P3)

As a user with intermittent internet connection, I want the app to continue working even if update checks fail, so that connectivity issues don't prevent me from using the app.

**Why this priority**: Error handling is critical but doesn't block core functionality. Users should never see errors from update checking failures.

**Independent Test**: Can be fully tested by opening the app, disconnecting network, switching tabs, and returning. App should work normally with no error messages.

**Acceptance Scenarios**:

1. **Given** user has no internet connection, **When** app tries to check for updates, **Then** check fails silently and app continues working
2. **Given** version.json returns 404 or malformed JSON, **When** app tries to check for updates, **Then** error is logged (console only) and no notification is shown
3. **Given** version check times out after 2 seconds, **When** user returns to the tab, **Then** app works normally and retries check on next resume

---

### Edge Cases

- What happens when multiple tabs are open and one updates? (Each tab independently checks and shows notification)
- How does system handle rapid focus events (tab switching)? (Debounce with 10-second minimum between checks)
- What if server version is older than local version (rollback)? (Don't show notification - version must be strictly newer)
- What if version format changes in future (e.g., "2.0.0-beta+3")? (Semantic version parser handles pre-release tags)
- What if user has very slow network? (2-second timeout prevents blocking, retry on next resume)
- What if service worker unregister fails? (Non-fatal, reload still works via window.location.reload)
- Does page reload clear localStorage? (No - window.location.reload() preserves localStorage by design; user data remains intact)

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST fetch deployed version from `/version.json` on the server when app resumes or launches
- **FR-002**: System MUST compare server version with currently running app version using semantic versioning (major.minor.patch+build)
- **FR-003**: System MUST check for updates when app first loads (cold start)
- **FR-004**: System MUST check for updates when user returns to the tab after being away (app resume/focus event)
- **FR-005**: System MUST NOT check for updates continuously while user is active (prevent network spam)
- **FR-006**: System MUST debounce rapid focus events with minimum 10 seconds between checks
- **FR-007**: System MUST show persistent, non-blocking notification when server version is newer than local version
- **FR-008**: Notification MUST include clear message "A new version is available" and prominent "Update Now" button
- **FR-009**: Notification MUST be dismissable but reappear on next resume until user updates
- **FR-010**: Clicking "Update Now" MUST trigger immediate page reload with cache bypass (`window.location.reload()`)
- **FR-011**: System SHOULD attempt to unregister service worker before reload (best effort, non-fatal if fails)
- **FR-012**: Network errors during version check MUST be silently ignored (no user-facing error message)
- **FR-013**: Version parsing errors MUST be logged to console but not shown to user
- **FR-014**: Failed version checks MUST NOT block app functionality
- **FR-015**: System MUST NOT show notification if server version is older than or equal to local version
- **FR-016**: Version check MUST complete within 2 seconds or timeout gracefully
- **FR-017**: Page reload MUST preserve localStorage data (trips, expenses, user preferences stored locally)

### Key Entities

- **Version**: Semantic version string in format "major.minor.patch+build" (e.g., "1.0.1+2")
  - Stored in: `version.json` (server), `pubspec.yaml` (source), `package_info_plus` (runtime)
  - Comparison: Numeric comparison of major, minor, patch, then build number

- **Update Check State**: Tracks whether update check is in progress and when last check occurred
  - Attributes: lastCheckTime (DateTime), isCheckingNow (boolean), updateAvailable (boolean), serverVersion (String?)
  - Used for: Debouncing and preventing duplicate checks

- **Service Worker Registration**: Browser's service worker instance that manages caching
  - Lifecycle: registered → activated → controlling
  - Unregister triggers: User clicks "Update Now"

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 95% of active users see update notification within 5 minutes of deployment being live
- **SC-002**: Users who click "Update Now" see the new version within 3 seconds (page reload time)
- **SC-003**: Version check adds less than 100ms to app startup time (measured from load event to interactive)
- **SC-004**: False positive rate less than 1% (users seeing incorrect "update available" notifications)
- **SC-005**: 80% of users who see notification click "Update Now" within 10 minutes (adoption rate)
- **SC-006**: Zero user-facing errors caused by version checking failures (graceful degradation)
- **SC-007**: App remains fully functional during version check (no UI blocking or freezing)
- **SC-008**: 100% of user data (trips, expenses, preferences) preserved after update reload (zero data loss)

## Assumptions

1. **Deployment Process**: `version.json` is correctly updated during build and deployment to GitHub Pages
2. **Network Access**: Users have internet connection most of the time (for online-first web app)
3. **Browser Support**: Users use modern browsers with service worker support (Chrome, Firefox, Safari, Edge)
4. **Version Format Stability**: Version format remains "major.minor.patch+build" for foreseeable future
5. **Single User Per Device**: No shared device scenarios where multiple users need different versions
6. **GitHub Pages Reliability**: GitHub Pages serves files reliably with < 1 second latency
7. **User Behavior**: Users will see notification if they keep app open for more than 5 minutes after deployment
8. **No Breaking Changes**: Version updates don't require data migration or break existing user state
9. **localStorage Persistence**: Browser's window.location.reload() preserves localStorage by design (confirmed by web standards)

## Out of Scope

- ❌ Automatic reload without user confirmation (too aggressive, might interrupt work)
- ❌ Periodic background checks while app is inactive (unnecessary battery/network usage)
- ❌ Update download progress indicator (web apps don't support partial downloads)
- ❌ Rollback mechanism or version history (not needed for forward-only updates)
- ❌ Debug panel for service worker inspection (per user preference: keep it simple)
- ❌ Custom cache-control headers (GitHub Pages limitation, requires CDN)
- ❌ Differential updates or patching (use full page reload strategy)
- ❌ Multi-tab synchronization of update state (each tab operates independently)
- ❌ Persistent "dismissed" state across sessions (notification reappears on every resume)
- ❌ Showing version numbers in notification (keep UI simple, version shown in footer)
- ❌ Analytics/telemetry for update adoption tracking (no tracking infrastructure in place)

## Technical Context

### Existing Infrastructure

- **Framework**: Flutter web with default `flutter_service_worker.js`
- **Deployment**: GitHub Pages with base-href `/expense_tracker/`
- **Version Source**: `version.json` auto-generated during Flutter build from `pubspec.yaml` (not checked into git, created in build/web/ directory)
- **Version Display**: Already shown in footer using `package_info_plus`
- **Service Worker Strategy**: Cache-first for assets, online-first for `index.html`
- **Local Storage**: Contains user's trip data, expense records, and preferences (MUST be preserved across reloads)
- **Available Packages**: `package_info_plus` (local version), need to add `http` (for fetching version.json)

### Platform Constraints

- **GitHub Pages**: Cannot customize HTTP cache-control headers
- **Service Worker**: Aggressive caching by design for offline support
- **Browser Behavior**: Service worker update checks happen automatically but timing is browser-dependent (typically 24 hours)
- **Update Detection**: Only reliable mechanism is periodic manual checks via JavaScript

## Dependencies

- `http` package (needs to be added) - for fetching `/version.json`
- `package_info_plus` (already present) - for reading local app version
- `dart:html` - for `window.location.reload()` and Page Visibility API
- Flutter web visibility events (`dart:html` visibilitychange) - for detecting tab focus/blur events

## Open Questions

None - all critical decisions have been made based on user preferences:
- ✅ Update style: Prompt user on resume (not auto-reload)
- ✅ Check frequency: Every app resume/load
- ✅ Debug tools: No debug panel (keep simple)
