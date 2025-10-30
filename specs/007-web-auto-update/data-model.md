# Data Model: Web App Update Detection

**Feature**: 007-web-auto-update
**Phase**: 1 (Design)
**Date**: 2025-01-30

## Overview

This feature requires minimal data modeling as it deals with transient state and external API responses. No persistent storage is needed. All entities are ephemeral and exist only in memory during runtime.

## Entities

### 1. Version (Value Object)

**Purpose**: Represents a semantic version string for comparison

**Source**: `pub_semver` package (`Version` class)

**Format**: `major.minor.patch+build` (e.g., "1.0.1+2")

**Properties**:
```dart
class Version implements Comparable<Version> {
  final int major;        // Major version (breaking changes)
  final int minor;        // Minor version (new features)
  final int patch;        // Patch version (bug fixes)
  final List<dynamic> preRelease;  // Pre-release identifiers (e.g., "beta.1")
  final List<String> build;        // Build metadata (e.g., "2")

  // Factory constructor
  Version.parse(String version);

  // Comparison
  int compareTo(Version other);
  bool operator >(Version other);
  bool operator <(Version other);
  bool operator ==(Object other);

  // String representation
  String toString(); // Returns canonical format
}
```

**Usage**:
```dart
final local = Version.parse('1.0.1+2');
final server = Version.parse('1.0.2+3');

if (server > local) {
  // Update available
}
```

**Validation**:
- Must match pattern: `^\d+\.\d+\.\d+(\+\d+)?$`
- Major, minor, patch must be non-negative integers
- Build number (after `+`) is optional but recommended
- Pre-release tags (after `-`) are handled but not used in this feature

**Lifecycle**: Immutable value object, created on-demand for comparison

---

### 2. VersionResponse (DTO)

**Purpose**: Represents the JSON response from `/version.json` endpoint

**Source**: Parsed from HTTP response

**Schema**:
```dart
class VersionResponse {
  final String version;  // Semantic version string

  VersionResponse({required this.version});

  // JSON deserialization
  factory VersionResponse.fromJson(Map<String, dynamic> json) {
    return VersionResponse(
      version: json['version'] as String,
    );
  }

  // JSON serialization (for testing)
  Map<String, dynamic> toJson() => {'version': version};
}
```

**Example JSON**:
```json
{
  "version": "1.0.2+3"
}
```

**Validation**:
- `version` field is required (non-null)
- Must be a valid semantic version string
- Throw `FormatException` if invalid

**Lifecycle**: Created when HTTP response is received, discarded after version comparison

---

### 3. UpdateCheckState (Transient State)

**Purpose**: Tracks the current state of update checking to implement debouncing

**Source**: In-memory state in `VersionCheckService`

**Properties**:
```dart
class UpdateCheckState {
  final DateTime? lastCheckTime;      // When was the last check performed
  final bool isCheckingNow;           // Is a check currently in progress
  final bool updateAvailable;         // Was an update detected
  final Version? serverVersion;       // Server version if known

  UpdateCheckState({
    this.lastCheckTime,
    this.isCheckingNow = false,
    this.updateAvailable = false,
    this.serverVersion,
  });

  // Convenience methods
  bool shouldDebounce(Duration minimumInterval) {
    if (lastCheckTime == null) return false;
    return DateTime.now().difference(lastCheckTime!) < minimumInterval;
  }

  UpdateCheckState copyWith({
    DateTime? lastCheckTime,
    bool? isCheckingNow,
    bool? updateAvailable,
    Version? serverVersion,
  }) {
    return UpdateCheckState(
      lastCheckTime: lastCheckTime ?? this.lastCheckTime,
      isCheckingNow: isCheckingNow ?? this.isCheckingNow,
      updateAvailable: updateAvailable ?? this.updateAvailable,
      serverVersion: serverVersion ?? this.serverVersion,
    );
  }
}
```

**State Transitions**:
```
Initial (null lastCheckTime, not checking)
  ↓ checkForUpdate() called
Checking (isCheckingNow = true)
  ↓ HTTP request completes
Update Available (updateAvailable = true, serverVersion set) OR No Update (updateAvailable = false)
  ↓ User clicks "Update Now"
[App reloads, state cleared]
```

**Validation**:
- `lastCheckTime` must be in the past (not future)
- If `updateAvailable` is true, `serverVersion` must be non-null
- `isCheckingNow` and `updateAvailable` are mutually exclusive (can't be both true)

**Lifecycle**: Exists for lifetime of `VersionCheckService` instance, reset on app reload

---

## Relationships

```
┌─────────────────┐
│VersionCheckService│
│  (singleton)      │
└────────┬──────────┘
         │ owns
         ↓
┌─────────────────┐
│UpdateCheckState  │  (transient, in-memory)
│  - lastCheckTime │
│  - isCheckingNow │
│  - updateAvailable│
│  - serverVersion │
└────────┬──────────┘
         │ references
         ↓
    ┌────────┐
    │Version │  (immutable value object from pub_semver)
    └────────┘
         ↑
         │ parsed from
         │
┌────────────────┐
│VersionResponse │  (DTO, ephemeral)
│  - version str │
└────────────────┘
         ↑
         │ deserialized from
         │
┌────────────────┐
│/version.json   │  (HTTP endpoint)
│  {"version":.} │
└────────────────┘
```

**Key Interactions**:
1. `VersionCheckService` fetches `/version.json` → gets `VersionResponse`
2. `VersionResponse.version` string → parsed into `Version` object
3. `Version` comparison (server > local) → updates `UpdateCheckState.updateAvailable`
4. `UpdateCheckState` consulted for debouncing logic

---

## Data Flow

### Version Check Flow

```
1. User returns to tab
   ↓
2. VersionCheckService.checkForUpdate()
   ↓
3. Check UpdateCheckState.shouldDebounce()
   ├─ Yes → Skip check, return early
   └─ No → Continue
   ↓
4. Set UpdateCheckState.isCheckingNow = true
   ↓
5. HTTP GET /version.json (with 2-second timeout)
   ├─ Success → VersionResponse
   ├─ Timeout → Log error, return false
   └─ Network error → Log error, return false
   ↓
6. Parse VersionResponse → Version (server)
   ├─ Success → Continue
   └─ FormatException → Log error, return false
   ↓
7. Get local version from package_info_plus → Version (local)
   ↓
8. Compare: server > local?
   ├─ Yes → Set updateAvailable = true, serverVersion = server
   └─ No → Set updateAvailable = false
   ↓
9. Update UpdateCheckState:
   - lastCheckTime = DateTime.now()
   - isCheckingNow = false
   ↓
10. Return updateAvailable bool
```

---

## Storage & Persistence

**None Required**

This feature is intentionally stateless:
- No localStorage/sessionStorage
- No database
- No cookies

**Rationale**:
1. **Simplicity**: Avoids storage management complexity
2. **Freshness**: Every app resume checks for latest version
3. **Privacy**: No tracking or persistent identifiers
4. **Performance**: In-memory state is faster than disk I/O

**Implication**: If user dismisses notification, it will reappear on next tab resume. This is acceptable per spec (FR-009).

---

## Error Handling

### Version Parsing Errors

**Scenario**: Server returns invalid version string (e.g., "abc" or "1.0")

**Handling**:
```dart
try {
  final serverVersion = Version.parse(response.version);
} on FormatException catch (e) {
  _log('Invalid version format: ${response.version} - $e');
  return false; // Treat as "no update available"
}
```

### Network Errors

**Scenario**: Fetch times out, 404, CORS error, etc.

**Handling**:
```dart
try {
  final response = await http.get(uri).timeout(Duration(seconds: 2));
} on TimeoutException catch (e) {
  _log('Version check timeout: $e');
  return false; // Silent failure
} catch (e) {
  _log('Version check failed: $e');
  return false; // Silent failure
}
```

### Null Safety

All entities use null-safe Dart:
- `Version?` for optional server version
- `DateTime?` for optional last check time
- Non-null `version` field in VersionResponse (required)

---

## Testing Strategy

### Unit Tests

**VersionResponse**:
```dart
test('fromJson parses valid response', () {
  final json = {'version': '1.0.1+2'};
  final response = VersionResponse.fromJson(json);
  expect(response.version, '1.0.1+2');
});

test('fromJson throws on missing version', () {
  expect(() => VersionResponse.fromJson({}), throwsA(isA<TypeError>()));
});
```

**UpdateCheckState**:
```dart
test('shouldDebounce returns true within interval', () {
  final state = UpdateCheckState(
    lastCheckTime: DateTime.now().subtract(Duration(seconds: 5)),
  );
  expect(state.shouldDebounce(Duration(seconds: 10)), true);
});

test('shouldDebounce returns false after interval', () {
  final state = UpdateCheckState(
    lastCheckTime: DateTime.now().subtract(Duration(seconds: 15)),
  );
  expect(state.shouldDebounce(Duration(seconds: 10)), false);
});
```

**Version Comparison** (using pub_semver):
```dart
test('newer server version detected', () {
  final local = Version.parse('1.0.1+2');
  final server = Version.parse('1.0.2+3');
  expect(server > local, true);
});

test('equal versions not detected as update', () {
  final local = Version.parse('1.0.1+2');
  final server = Version.parse('1.0.1+2');
  expect(server > local, false);
});

test('older server version not detected as update', () {
  final local = Version.parse('1.0.2+3');
  final server = Version.parse('1.0.1+2');
  expect(server > local, false);
});
```

---

## API Contract Reference

See: [contracts/version-api.yaml](./contracts/version-api.yaml)

**Endpoint**: `GET /version.json`
**Response**: `{"version": "1.0.1+2"}`
**Status Codes**:
- 200: Success
- 404: File not found (handled gracefully)
- 5xx: Server error (handled gracefully)

---

## Dependencies

### External Packages

```yaml
dependencies:
  pub_semver: ^2.1.4        # Semantic version parsing and comparison
  package_info_plus: ^8.1.2 # Local app version (already present)
  http: ^1.1.0              # HTTP client for fetching version.json
```

### Standard Library

```dart
import 'dart:async';   // For TimeoutException
import 'dart:convert'; // For JSON parsing
import 'dart:html';    // For Page Visibility API (lifecycle)
```

---

## Future Considerations

### Potential Enhancements (Out of Scope)

1. **Version History**: Store last N versions seen for rollback detection
2. **Update Metadata**: Additional fields in version.json (release notes URL, breaking changes flag)
3. **Conditional Updates**: Skip updates for specific version ranges (emergency rollback)
4. **Analytics**: Track update adoption rates (requires analytics infrastructure)

These are explicitly out of scope for MVP but data model could be extended if needed.

---

## Summary

**Total Entities**: 3 (Version, VersionResponse, UpdateCheckState)
**Persistent Storage**: None (all transient)
**External Dependencies**: pub_semver, http, package_info_plus
**Complexity**: Low (simple value objects and DTOs)

The data model is intentionally minimal to keep the feature simple and maintainable. All complexity is in service logic, not data structure.
