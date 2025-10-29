# Data Model: Trip Invite System

**Phase**: 1 - Design & Contracts
**Date**: 2025-10-28
**Purpose**: Define entities, relationships, validation rules, and state transitions for trip invite system

## Entity Definitions

### 1. ActivityLog (NEW Entity)

**Purpose**: Represents a single action taken in a trip for transparency and audit trail

**Fields**:

| Field | Type | Required | Validation | Description |
|-------|------|----------|------------|-------------|
| `id` | String | Yes | Non-empty, auto-generated | Unique identifier (Firestore document ID) |
| `tripId` | String | Yes | Non-empty, valid trip ID | Reference to parent trip |
| `actorName` | String | Yes | 1-50 chars, non-empty | Name of person who performed action |
| `type` | ActivityType (enum) | Yes | Valid enum value | Category of action performed |
| `description` | String | Yes | 1-200 chars | Human-readable description |
| `timestamp` | DateTime | Yes | Not in future | When action occurred |
| `metadata` | Map<String, dynamic>? | No | Valid JSON | Optional action-specific details |

**Validation Rules**:
```dart
class ActivityLog {
  // Constructor validation
  ActivityLog({
    required this.id,
    required this.tripId,
    required this.actorName,
    required this.type,
    required this.description,
    required this.timestamp,
    this.metadata,
  }) : assert(id.isNotEmpty),
       assert(tripId.isNotEmpty),
       assert(actorName.length >= 1 && actorName.length <= 50),
       assert(description.length >= 1 && description.length <= 200),
       assert(!timestamp.isAfter(DateTime.now()));
}
```

**Example**:
```json
{
  "id": "log123abc",
  "tripId": "trip456def",
  "actorName": "Tai",
  "type": "expense_added",
  "description": "Tai added expense 'Dinner at Pho 24'",
  "timestamp": "2025-10-28T14:30:00Z",
  "metadata": {
    "expenseId": "exp789xyz",
    "amount": 250000,
    "currency": "VND"
  }
}
```

---

### 2. ActivityType (NEW Enum)

**Purpose**: Categorize types of actions logged in activity log

**Values**:

| Value | Description | Triggered By |
|-------|-------------|--------------|
| `tripCreated` | Trip was created | `TripCubit.createTrip()` |
| `memberJoined` | User joined trip | `TripCubit.joinTrip()` |
| `expenseAdded` | Expense created | `ExpenseCubit.createExpense()` |
| `expenseEdited` | Expense modified | `ExpenseCubit.updateExpense()` |
| `expenseDeleted` | Expense removed | `ExpenseCubit.deleteExpense()` |
| `settlementCalculated` | (Future) Settlement recalculated | `SettlementCubit.calculate()` |

**Implementation**:
```dart
enum ActivityType {
  tripCreated('trip_created', 'Trip Created'),
  memberJoined('member_joined', 'Member Joined'),
  expenseAdded('expense_added', 'Expense Added'),
  expenseEdited('expense_edited', 'Expense Edited'),
  expenseDeleted('expense_deleted', 'Expense Deleted'),
  settlementCalculated('settlement_calculated', 'Settlement Calculated');

  const ActivityType(this.code, this.displayName);
  final String code;
  final String displayName;
}
```

---

### 3. Trip (EXISTING Entity - No Schema Changes)

**Reused Fields for Membership**:

| Field | Current Usage | New Usage for Invites |
|-------|---------------|----------------------|
| `id` | Unique identifier | **Invite code** (permanent, shareable) |
| `participants` | Per-trip participant list | **Membership list** (who can access trip) |

**No Breaking Changes**: All existing Trip functionality preserved.

**Membership Semantics**:
- Empty `participants` list → Trip not yet claimed (pre-feature legacy trips)
- Non-empty `participants` → Members who can access trip
- User in `participants` → Can view, edit, add expenses, view activity log
- User NOT in `participants` → Cannot access trip (redirected to join page)

---

### 4. Participant (EXISTING Entity - Reused)

**Purpose**: Represents a person in a trip (already used for expenses, now also for membership)

**Fields** (Unchanged):
- `id`: String (generated from name, e.g., "tai", "khiet")
- `name`: String (display name, e.g., "Tai", "Khiet")
- `createdAt`: DateTime (when added to trip)

**New Usage**: When user joins trip, create `Participant.fromName(providedName)` and add to `Trip.participants`

---

## Entity Relationships

### ER Diagram

```
┌─────────────────────────┐
│        Trip             │
│─────────────────────────│
│ id (PK, invite code)    │──────┐
│ name                    │      │
│ baseCurrency            │      │
│ participants: []        │◄─────┼─── Membership list
│ createdAt               │      │
│ updatedAt               │      │
└─────────────────────────┘      │
         │                       │
         │ 1:N                   │
         ▼                       │
┌─────────────────────────┐      │
│    ActivityLog          │      │
│─────────────────────────│      │
│ id (PK)                 │      │
│ tripId (FK) ────────────┼──────┘
│ actorName               │
│ type                    │
│ description             │
│ timestamp               │
│ metadata                │
└─────────────────────────┘
         │
         │ references
         ▼
┌─────────────────────────┐
│    Participant          │
│─────────────────────────│
│ id (PK)                 │
│ name ◄──────────────────┼─── actorName matches participant.name
│ createdAt               │
└─────────────────────────┘
```

### Relationship Rules

1. **Trip → ActivityLog** (1:N)
   - One trip has many activity log entries
   - Activity log entries belong to exactly one trip
   - Stored as Firestore subcollection: `/trips/{tripId}/activityLog/{logId}`
   - Cascade behavior: Deleting trip does NOT automatically delete activity logs (Firestore limitation; acceptable)

2. **Trip → Participant** (1:N embedded)
   - One trip has many participants
   - Participants are embedded in trip document (not separate collection)
   - Maximum: ~100 participants (Firestore 1MB document limit)

3. **ActivityLog → Participant** (N:1 loose reference)
   - Activity log references participant by name (not ID)
   - No foreign key constraint (actorName is just a string)
   - Rationale: Participant names are immutable per trip, sufficient for audit trail

---

## Validation Rules

### ActivityLog Validation

**Business Rules**:
1. `tripId` must reference existing trip
2. `actorName` should match a participant in the trip (soft constraint, not enforced)
3. `timestamp` cannot be in the future
4. `description` must be human-readable (auto-generated from template)
5. `metadata` is optional and action-specific

**Enforcement**:
- Client-side: Validate in `ActivityLog` constructor (Dart asserts)
- Server-side: Firestore rules validate `tripId` exists

### Trip Membership Validation

**Business Rules**:
1. User can only access trips they are a member of
2. User can join a trip by providing their name
3. User cannot join the same trip twice (duplicate names allowed, but same user = idempotent)
4. Trip creator is automatically added as first member

**Enforcement**:
- Client-side: `TripCubit` filters trips to only joined trips
- Server-side: Firestore rules check `participants` array
- Join operation: Idempotent (check if already member before adding)

---

## State Transitions

### Trip Membership State Machine

```
[New User]
    │
    ├─► CREATE TRIP ──► [Trip Creator] ──► Auto-added to participants
    │
    └─► RECEIVE INVITE CODE
            │
            ▼
        ENTER CODE
            │
            ├─► Valid Code ──► PROVIDE NAME ──► [Trip Member]
            │                        │
            │                        └─► Add to participants list
            │                            Create "member_joined" log
            │
            └─► Invalid Code ──► [Error: Trip not found]
```

**State Definitions**:
1. **New User**: No trips joined yet (empty joined trips list)
2. **Trip Creator**: User who created trip (first participant)
3. **Trip Member**: User in trip's participants list
4. **Non-Member**: User not in participants list (cannot access trip data)

**Transitions**:
- `createTrip()`: New User → Trip Creator
- `joinTrip()`: New User → Trip Member
- (No transition for leaving trip in MVP)

### Activity Log Lifecycle

```
[Action Occurs]
    │
    ├─► Trip Created ──────► Create log entry (type: trip_created)
    ├─► Member Joined ─────► Create log entry (type: member_joined)
    ├─► Expense Added ─────► Create log entry (type: expense_added)
    ├─► Expense Edited ────► Create log entry (type: expense_edited)
    └─► Expense Deleted ───► Create log entry (type: expense_deleted)
            │
            ▼
    [Log Entry Persisted]
            │
            └─► Immutable (no edits/deletes allowed)
```

**Log Entry States**:
1. **Created**: Log entry written to Firestore
2. **Persisted**: Immutable, permanent record
3. (No "deleted" state - logs are append-only)

---

## Query Patterns

### 1. Get Activity Logs for Trip (Most Common)

**Query**:
```dart
Stream<List<ActivityLog>> getActivityLogs(String tripId, {int limit = 50}) {
  return _firestore
      .collection('trips')
      .doc(tripId)
      .collection('activityLog')
      .orderBy('timestamp', descending: true)
      .limit(limit)
      .snapshots()
      .map((snapshot) => snapshot.docs.map(ActivityLogModel.fromFirestore).toList());
}
```

**Indexes Required**:
- `timestamp` (descending) - Auto-created by Firestore on first query

**Performance**: O(log N) with index, <100ms for 50 entries

---

### 2. Check if User is Member of Trip

**Client-Side Query** (cached):
```dart
Future<bool> isUserMemberOf(String tripId) async {
  final joinedIds = await _localStorageService.getJoinedTripIds();
  return joinedIds.contains(tripId);
}
```

**Server-Side Validation** (Firestore rule):
```javascript
function isMemberOf(tripId) {
  let trip = get(/databases/$(database)/documents/trips/$(tripId));
  // For MVP: Check if participants array is not empty
  // (Client tracks membership, server validates trip exists)
  return trip != null && trip.data.participants.size() > 0;
}
```

**Performance**: Client-side: <10ms (memory), Server-side: <50ms (cache hit)

---

### 3. Get All Joined Trips for User

**Query**:
```dart
Stream<List<Trip>> getJoinedTrips() async* {
  final joinedIds = await _localStorageService.getJoinedTripIds();
  await for (final allTrips in _tripRepository.getAllTrips()) {
    yield allTrips.where((trip) => joinedIds.contains(trip.id)).toList();
  }
}
```

**Performance**: O(N) filter in Dart, <50ms for 50 trips

---

## Constraints & Limits

### Firestore Limits

| Resource | Limit | Impact |
|----------|-------|--------|
| Document size | 1 MB | Trip document can hold ~100 participants (acceptable) |
| Subcollection size | Unlimited | Activity log can grow indefinitely |
| Writes per second | 1 per document | Activity log writes are low-frequency (acceptable) |
| Real-time listeners | 1M concurrent | Activity log streams are per-trip (no issue) |

### Business Constraints

| Constraint | Value | Rationale |
|------------|-------|-----------|
| Max participants per trip | 100 | Firestore 1MB limit, 10KB per participant = 100 participants |
| Max activity log entries per trip | Unlimited | Subcollection, paginated loading |
| Activity log page size | 50 entries | Balance between performance and completeness |
| Actor name length | 1-50 chars | UI space, readability |
| Description length | 1-200 chars | Single-line display |

---

## Data Integrity Guarantees

### Atomicity

**Trip Join Operation** (pseudo-transaction):
```dart
// In TripCubit.joinTrip()
try {
  // 1. Validate trip exists
  final trip = await _tripRepository.getTripById(tripId);
  if (trip == null) throw TripNotFoundException();

  // 2. Check if already member (idempotent)
  if (trip.participants.any((p) => p.name == userName)) {
    // Already member, return success
    return;
  }

  // 3. Add participant to trip (atomic write)
  final updatedTrip = trip.copyWith(
    participants: [...trip.participants, Participant.fromName(userName)],
  );
  await _tripRepository.updateTrip(updatedTrip);

  // 4. Create activity log entry (separate write, acceptable)
  await _activityLogRepository.addLog(ActivityLog(
    tripId: tripId,
    actorName: userName,
    type: ActivityType.memberJoined,
    description: '$userName joined the trip',
    timestamp: DateTime.now(),
  ));

  // 5. Cache joined trip ID locally
  await _localStorageService.addJoinedTrip(tripId);
} catch (e) {
  // Rollback not needed (participant addition is atomic)
  rethrow;
}
```

**Trade-off**: Activity log write is separate (not in transaction). Acceptable because:
- If log fails, participant still added (user can join)
- Log entry can be retried or manually added later
- Firestore doesn't support multi-document transactions across collections

### Audit Trail Immutability

**Enforcement**:
- Firestore rules: No update or delete allowed on activity log entries
```javascript
match /trips/{tripId}/activityLog/{logId} {
  allow read: if isMemberOf(tripId);
  allow create: if isMemberOf(tripId);
  allow update, delete: if false;  // Immutable
}
```

### Referential Integrity

**No Cascading Deletes**: Firestore doesn't support cascades
- Deleting trip does NOT auto-delete activity logs
- Acceptable: If trip deleted, logs orphaned but inaccessible (no UI to view)
- Future: Add Cloud Function for cleanup if needed

---

## Migration Considerations

### Existing Trips (Pre-Feature)

**Scenario 1**: Trip with empty `participants` list
- **Behavior**: First user to access prompts "Claim this trip by providing your name"
- **Action**: Add user as first participant, create `trip_created` log entry (retroactive)

**Scenario 2**: Trip with existing participants
- **Behavior**: Works immediately (trip ID = invite code)
- **Action**: None (backward compatible)

**Scenario 3**: Activity log not present
- **Behavior**: Show empty state "No activity yet"
- **Action**: Start logging from feature deployment forward

**No Data Migration Required**: Feature is additive, not destructive

---

## Testing Considerations

### Unit Test Coverage

**Models**:
- `ActivityLog`: Validation, serialization, equality
- `ActivityType`: Enum values, display names

**Repositories**:
- `ActivityLogRepository`: CRUD operations, stream subscriptions
- `TripRepository.joinTrip()`: Membership addition, idempotency

### Integration Test Scenarios

1. **Join Trip Flow**:
   - Enter valid code → Provide name → Added to participants → Log entry created

2. **Activity Log Real-Time**:
   - User A adds expense → User B sees log update within 2 seconds

3. **Membership Filtering**:
   - User joins trip → Trip appears in their trip list
   - User clears cache → Trip disappears, must rejoin

4. **Backward Compatibility**:
   - Existing trip (pre-feature) → User can access via trip ID → Prompted to claim

---

## Summary

**New Entities**: 1 (ActivityLog)
**Modified Entities**: 0 (Trip reused as-is)
**New Enums**: 1 (ActivityType)
**New Relationships**: 1 (Trip ↔ ActivityLog subcollection)

**Complexity Assessment**: Low
- Extends existing architecture cleanly
- No schema migrations needed
- Leverages Firestore subcollections (standard pattern)
- Minimal new code (1 model, 1 repository, 1 cubit)

**Ready for Contracts Phase**: Yes - Proceed to Firestore schema and Cubit contracts
