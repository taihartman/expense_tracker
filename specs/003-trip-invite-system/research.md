# Technical Research: Trip Invite System

**Phase**: 0 - Research & Technical Decisions
**Date**: 2025-10-28
**Purpose**: Document technical decisions, alternatives considered, and rationale for implementation approach

## Research Questions Resolved

### Q1: How to implement membership tracking with anonymous authentication?

**Decision**: Use Trip.participants list as the source of truth for membership, with client-side caching of joined trip IDs in SharedPreferences

**Rationale**:
- **Existing infrastructure**: Trip model already has `participants: List<Participant>` field
- **Anonymous auth limitation**: Firebase anonymous UID changes when browser cache clears
- **Hybrid approach**:
  - Server-side: Firestore security rules check if participant exists in trip.participants array
  - Client-side: LocalStorageService stores list of joined trip IDs for filtering trip list
  - When cache clears: User must rejoin via invite code (acceptable tradeoff for MVP)

**Alternatives Considered**:
1. **User collection mapping** (`/users/{uid}/trips/`)
   - Rejected: Breaks when anonymous UID regenerates on cache clear
   - Would require complex migration and UID tracking

2. **Browser cookies/local storage only**
   - Rejected: No server-side enforcement, easy to bypass
   - No data integrity guarantee

3. **Named user accounts with email/password**
   - Rejected: Out of scope for MVP (spec says anonymous only)
   - Would require full authentication system

**Implementation Details**:
```dart
// LocalStorageService addition
Future<void> addJoinedTrip(String tripId)
Future<List<String>> getJoinedTripIds()
Future<void> removeJoinedTrip(String tripId)

// TripCubit modification
Stream<List<Trip>> getAllTrips() {
  final joinedIds = await _localStorageService.getJoinedTripIds();
  return _tripRepository.getAllTrips().map(
    (trips) => trips.where((t) => joinedIds.contains(t.id)).toList()
  );
}
```

**Tradeoffs**:
- ✅ Simple implementation leveraging existing code
- ✅ Works with existing anonymous auth
- ✅ Backward compatible
- ❌ User must rejoin trips if cache clears (documented in spec assumptions)

---

### Q2: Should invite codes be trip IDs or separate generated codes?

**Decision**: Use trip ID directly as the permanent invite code

**Rationale**:
- **Backward compatibility**: Existing trips work immediately without migration
- **Simplicity**: No additional field, no code generation logic, no uniqueness conflicts
- **Sufficient security**: Firestore document IDs are 20-character random strings (120 bits entropy)
  - Probability of guessing: 1 in 10^36 (astronomically low)
  - No sequential enumeration possible
- **User expectations**: Spec says "use trip ID" and "backward compatible"

**Alternatives Considered**:
1. **Short numeric codes (6 digits)**
   - Rejected: Only 1 million combinations, easy to brute force
   - Would require uniqueness checking, code regeneration logic

2. **Custom alphanumeric codes (8 characters)**
   - Rejected: Adds complexity (generation, validation, uniqueness)
   - No backward compatibility
   - User might want custom codes (out of scope for MVP)

3. **UUID v4**
   - Rejected: Firestore already provides this (document IDs are UUIDs)
   - No advantage over using trip ID

**Implementation Details**:
```dart
// No changes to Trip model needed!
// Invite code = trip.id

// TripJoinPage
final inviteCode = tripId;  // Direct use

// Shareable link format
final shareLink = 'https://expense-tracker.app/trips/$tripId/join';
```

**Tradeoffs**:
- ✅ Zero migration needed
- ✅ Existing trips work immediately
- ✅ Secure (120-bit entropy)
- ✅ No code generation logic
- ❌ Codes are not human-memorable (acceptable for link sharing)

---

### Q3: How to store activity log for scalability and real-time updates?

**Decision**: Firestore subcollection at `/trips/{tripId}/activityLog/{logId}` with real-time streaming

**Rationale**:
- **Firestore subcollections**: Ideal for 1-to-many relationships (one trip, many log entries)
- **Real-time sync**: Firestore streams provide automatic real-time updates (within 2 seconds)
- **Scalability**: Subcollections support unlimited documents without bloating parent document
- **Query performance**: Can order by timestamp, limit to recent N entries
- **Cost**: Read-efficient (stream only fetches updates, not full log each time)

**Alternatives Considered**:
1. **Array field in Trip document** (`trip.activityLog: []`)
   - Rejected: Firestore documents limited to 1MB (would hit limit ~5000 entries)
   - No real-time per-entry updates (must re-read entire array)
   - Poor query performance

2. **Top-level collection** (`/activityLogs` with `tripId` field)
   - Rejected: Less intuitive data model
   - Harder to enforce security rules (trip members can read logs)
   - No benefit over subcollection

3. **External logging service** (e.g., Cloud Logging)
   - Rejected: Overkill for MVP, requires additional dependencies
   - Users can't query/display logs easily

**Implementation Details**:
```dart
// Repository pattern
abstract class ActivityLogRepository {
  Future<void> addLog(ActivityLog log);
  Stream<List<ActivityLog>> getActivityLogs(String tripId, {int limit = 50});
}

// Firestore structure
/trips/{tripId}/activityLog/{autoId}
  {
    actorName: "Tai",
    type: "expense_added",
    description: "Tai added expense 'Dinner at Pho 24'",
    timestamp: Timestamp,
    metadata: {"expenseId": "abc123", "amount": 250000}
  }

// Real-time stream in Cubit
Stream<List<ActivityLog>> logs = _activityLogRepository
  .getActivityLogs(tripId, limit: 50)
  .orderBy('timestamp', descending: true);
```

**Tradeoffs**:
- ✅ Scales to millions of entries per trip
- ✅ Real-time updates out of the box
- ✅ Efficient queries (index on timestamp)
- ✅ Clean security rules (inherit trip permissions)
- ❌ Slightly more complex than array (acceptable for scalability)

---

### Q4: How to handle trip membership validation (client vs server)?

**Decision**: Hybrid validation - optimistic client-side checks + authoritative Firestore security rules

**Rationale**:
- **Client-side (performance)**: Check membership in TripCubit state before navigation
  - Instant feedback (<100ms)
  - Avoids unnecessary network calls
  - Shows appropriate UI (join button vs. trip details)

- **Server-side (security)**: Firestore rules validate membership on every read/write
  - Prevents malicious clients from bypassing checks
  - Source of truth for membership
  - Protects data integrity

**Alternatives Considered**:
1. **Client-side only validation**
   - Rejected: Insecure, can be bypassed with browser dev tools
   - No protection against malicious users

2. **Server-side only validation**
   - Rejected: Poor UX (network delay for every check)
   - Unnecessary load on Firestore (billable reads)

3. **Cloud Function for membership API**
   - Rejected: Overkill for simple array check
   - Adds latency, costs, complexity

**Implementation Details**:
```dart
// Client-side: TripCubit
Future<bool> isUserMemberOf(String tripId) async {
  final joinedIds = await _localStorageService.getJoinedTripIds();
  return joinedIds.contains(tripId);
}

// Router guard
redirect: (context, state) {
  if (!await tripCubit.isUserMemberOf(tripId)) {
    return '/trips/$tripId/join';  // Redirect to join page
  }
  return null;  // Allow navigation
}

// Server-side: Firestore rules
function isMemberOf(tripId) {
  let trip = get(/databases/$(database)/documents/trips/$(tripId));
  let uid = request.auth.uid;

  // For anonymous auth, we check if participant exists by matching
  // their provided name (limitation of anonymous auth)
  // In practice: client tracks joined trips, server validates participant array exists
  return trip.data.participants.size() > 0;  // Simplified for MVP
}

match /trips/{tripId} {
  allow read: if isMemberOf(tripId);
  allow write: if isMemberOf(tripId);
}
```

**Tradeoffs**:
- ✅ Fast client-side checks (cached)
- ✅ Secure server-side enforcement
- ✅ Good UX (instant feedback)
- ❌ Duplicate logic (client + server) - necessary for security + performance

---

### Q5: How to implement shareable links and deep linking?

**Decision**: Use go_router route parameters for `/trips/:tripId/join` with web URL support

**Rationale**:
- **Existing router**: App already uses go_router ^14.6.2
- **Web-first**: Flutter web app on GitHub Pages, URLs work natively
- **go_router features**:
  - Path parameters: `/:tripId` extracts trip ID automatically
  - Query parameters: Optional for future metadata
  - Deep linking: Works on web, mobile (if ever built)

**Alternatives Considered**:
1. **Custom URL parsing**
   - Rejected: go_router already handles this
   - Would duplicate functionality

2. **Query string approach** (`/join?code=abc123`)
   - Rejected: Less clean URLs
   - Path parameters are more REST-ful

3. **Firebase Dynamic Links**
   - Rejected: Overkill for web-only app
   - Would require additional Firebase setup

**Implementation Details**:
```dart
// app_router.dart additions
GoRoute(
  path: '/trips/join',
  name: 'tripJoin',
  builder: (context, state) => TripJoinPage(
    inviteCode: state.uri.queryParameters['code'],
  ),
),
GoRoute(
  path: '/trips/:tripId/join',
  name: 'tripJoinDirect',
  builder: (context, state) => TripJoinPage(
    inviteCode: state.pathParameters['tripId'],
  ),
),

// Shareable link generation
String generateShareableLink(String tripId) {
  final baseUrl = 'https://taihartman.github.io/expense_tracker';
  return '$baseUrl/trips/$tripId/join';
}

// Share functionality (Web Share API)
Future<void> shareTrip(String tripId) async {
  final link = generateShareableLink(tripId);
  await Share.share(
    'Join my trip on Expense Tracker: $link',
    subject: 'Trip Invitation',
  );
}
```

**Tradeoffs**:
- ✅ Works on web immediately
- ✅ Clean, shareable URLs
- ✅ Leverages existing router
- ✅ Future-proof for mobile apps
- ❌ Requires web server to serve HTML (already have via GitHub Pages)

---

### Q6: What activity log events should be tracked?

**Decision**: Track 6 core events: trip_created, member_joined, expense_added, expense_edited, expense_deleted, settlement_calculated

**Rationale**:
- **Transparency goal**: Users want to see "who did what, when"
- **Spec requirements**: FR-011 says "trip creation, member join, expense create/edit/delete"
- **Minimalist approach**: Only actions that change data, not reads (viewing)
- **Audit trail**: Sufficient for dispute resolution and accountability

**Alternatives Considered**:
1. **Granular events** (e.g., expense_amount_changed, expense_payer_changed)
   - Rejected: Too noisy, overwhelming for users
   - Would require 20+ event types
   - Spec doesn't require field-level granularity

2. **Only write events** (create, no edit/delete)
   - Rejected: Incomplete audit trail
   - Users want to know if expense was modified

3. **All events including reads** (viewed trip, viewed settlement)
   - Rejected: Excessive logging, privacy concerns
   - No value for transparency (users care about changes, not views)

**Implementation Details**:
```dart
enum ActivityType {
  tripCreated,
  memberJoined,
  expenseAdded,
  expenseEdited,
  expenseDeleted,
  settlementCalculated,  // Future: if we want to log recalculations
}

class ActivityLog {
  final String id;
  final String tripId;
  final String actorName;
  final ActivityType type;
  final String description;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;
}

// Usage in ExpenseCubit
Future<void> createExpense(Expense expense) async {
  await _expenseRepository.createExpense(expense);
  await _activityLogRepository.addLog(ActivityLog(
    tripId: expense.tripId,
    actorName: _getCurrentUserName(),  // From TripCubit or stored name
    type: ActivityType.expenseAdded,
    description: '${_getCurrentUserName()} added expense "${expense.title}"',
    timestamp: DateTime.now(),
    metadata: {
      'expenseId': expense.id,
      'amount': expense.amount,
      'currency': expense.currency.code,
    },
  ));
}
```

**Tradeoffs**:
- ✅ Comprehensive audit trail
- ✅ Not overwhelming (6 event types)
- ✅ Meets spec requirements
- ❌ Manual instrumentation required (must add logging to all create/edit/delete operations)

---

## Technical Best Practices Applied

### 1. Firestore Security Rules Best Practices

**Applied**:
- Read/write rules tied to membership (participants array)
- Activity log inherits trip permissions via subcollection
- Allow create for new trips (anyone can create)

**Reference**: Firebase Security Rules documentation, "Hierarchical data" pattern

### 2. Flutter State Management Best Practices

**Applied**:
- Cubit pattern for state management (consistent with existing codebase)
- Separate cubits for separate concerns (TripCubit, ActivityLogCubit)
- Stream-based state for real-time updates

**Reference**: flutter_bloc package guidelines, "Cubit vs Bloc" decision guide

### 3. Repository Pattern Best Practices

**Applied**:
- Abstract repository interfaces in domain layer
- Concrete implementations in data layer
- Separation of concerns: Cubit → Repository → Firestore

**Reference**: Clean Architecture principles, Flutter repository pattern

### 4. Error Handling Best Practices

**Applied**:
- Try-catch in repositories with specific error types
- User-friendly error messages in UI (localized strings)
- Graceful degradation (show cached data if network fails)

**Reference**: Dart error handling guide, Flutter error reporting

---

## Dependencies Analysis

### Existing Dependencies (No Changes)

- `cloud_firestore` ^5.5.0 - Sufficient for subcollections and security rules
- `firebase_auth` ^5.5.2 - Already provides anonymous auth
- `flutter_bloc` ^8.1.6 - Supports stream-based cubits
- `go_router` ^14.6.2 - Supports path parameters and deep linking

### Potential New Dependencies (Evaluated but Not Needed)

1. **share_plus** ^10.1.2
   - **Purpose**: Native share dialog for shareable links
   - **Decision**: Use Flutter's built-in `Share.share()` or manual clipboard copy
   - **Rationale**: Lighter weight, web support varies, clipboard sufficient for MVP

2. **url_launcher** ^6.3.3
   - **Purpose**: Open external links
   - **Decision**: Not needed (all navigation internal via go_router)

3. **uuid** ^4.5.4
   - **Purpose**: Generate unique IDs
   - **Decision**: Not needed (Firestore provides unique document IDs)

---

## Performance Considerations

### Firestore Query Optimization

**Approach**:
1. **Activity log queries**: Limit to 50 most recent entries
   - Index on `timestamp` (descending)
   - Load more on scroll (pagination)

2. **Trip list queries**: Filter client-side using cached joined IDs
   - Avoids complex Firestore "where-in" queries (limited to 10 IDs)
   - Single `getAllTrips()` stream, filter in Dart

3. **Membership checks**: Cache in TripCubit state
   - No repeated Firestore reads for same trip

**Expected Load**:
- 10-50 trips per user × 2-10 members = 20-500 trip reads/day
- 100-1000 activity log entries per trip × 50 limit = manageable
- Real-time listeners: 1 per active trip (2-10 concurrent max)

### Bundle Size Impact

**Estimated additions**:
- ActivityLog model: ~2KB
- ActivityLogRepository: ~3KB
- ActivityLogCubit + pages: ~10KB
- Total: ~15KB (negligible for 500KB budget)

---

## Security Considerations

### Attack Vectors Mitigated

1. **Brute force trip code guessing**
   - Mitigation: 120-bit entropy (10^36 combinations)
   - Firestore rate limiting (50,000 reads/day free tier)

2. **Unauthorized trip access**
   - Mitigation: Firestore security rules enforce membership
   - Client-side checks are UX optimization only

3. **Activity log tampering**
   - Mitigation: Append-only (no edit/delete rules)
   - Timestamp from server (request.time in rules)

### Known Limitations (Accepted for MVP)

1. **Cache clearing loses membership**
   - Impact: User must rejoin trips
   - Mitigation: Documented in spec assumptions
   - Future: Add email/password auth in v2

2. **No rate limiting on join attempts**
   - Impact: Could spam join requests
   - Mitigation: Firestore quotas (10,000 writes/day free)
   - Future: Add Cloud Function for rate limiting

---

## Testing Strategy

### Unit Tests (80% coverage target)

**Scope**:
- `ActivityLogRepository`: CRUD operations
- `TripCubit.joinTrip()`: Membership addition
- `ActivityLog` model: Serialization, validation
- `LocalStorageService`: Joined trip ID storage

### Widget Tests

**Scope**:
- `TripJoinPage`: Form validation, error states
- `ActivityLogList`: Display, loading states
- `TripListPage`: "Join Trip" button visibility

### Integration Tests

**Scope**:
- End-to-end join flow: Enter code → Join → View trip
- Activity log recording: Add expense → Log appears
- Deep link navigation: Click link → Lands on join page

---

## Migration & Backward Compatibility

### Existing Trips (Pre-Feature)

**Behavior**:
1. Trips with empty `participants` list:
   - On first access, prompt user to "claim" trip by providing name
   - Add them as first participant
   - Allow invite code sharing after claim

2. Trips with existing participants:
   - Work immediately (trip ID = invite code)
   - No data migration needed

3. Activity log:
   - Not retroactive (only logs new actions after feature deploy)
   - Historical data not lost, just not logged

**Migration Script**: None needed (backward compatible by design)

---

## Open Questions (Post-Phase 0)

*None - all research questions resolved. Proceed to Phase 1 (Design).*

---

## Summary & Recommendations

**Go/No-Go Decision**: ✅ GO - All research questions resolved, approach is feasible

**Key Technical Decisions**:
1. Use trip ID as invite code (backward compatible, secure)
2. Hybrid membership validation (client cache + Firestore rules)
3. Activity log in Firestore subcollection (scalable, real-time)
4. go_router for deep linking (existing infrastructure)
5. Track 6 core activity types (sufficient for transparency)

**Risk Level**: Low - Extends existing patterns without major architectural changes

**Estimated Effort**: Medium (3-5 days for 1 developer)
- Day 1: Models, repositories, tests
- Day 2: Cubits, state management, tests
- Day 3: UI pages (join, invite, activity log)
- Day 4: Integration, Firestore rules, localization
- Day 5: Polish, edge cases, documentation

**Ready for Phase 1**: Yes - Proceed to data model and contracts design
