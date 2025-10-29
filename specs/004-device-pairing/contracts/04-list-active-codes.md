# Contract: List Active Device Link Codes

**Operation**: Retrieve all active (unexpired, unused) codes for a trip
**Endpoint**: `DevicePairingCubit.loadActiveCodes()`
**Type**: Query (Read-only)
**Priority**: P3 (Nice-to-Have)

---

## Input Contract

### Parameters

```dart
Future<void> loadActiveCodes({
  required String tripId,
});
```

| Parameter | Type | Required | Constraints | Description |
|-----------|------|----------|-------------|-------------|
| `tripId` | String | ✅ | Non-empty, must exist in Firestore | Trip to load codes for |

### Preconditions

1. User must be authenticated (anonymous Firebase auth)
2. Trip with `tripId` must exist in Firestore
3. User must be a member of the trip (authorization check)

---

## Output Contract

### Success Response

```dart
// State: ActiveCodesLoading → ActiveCodesLoaded(codes: List<DeviceLinkCode>)
```

**Response Structure**:

```dart
class ActiveCodesLoaded extends DevicePairingState {
  final List<DeviceLinkCode> codes;

  const ActiveCodesLoaded({required this.codes});
}

// Example data
[
  DeviceLinkCode(
    id: "doc1",
    code: "1234-5678",
    memberName: "Alice",
    createdAt: DateTime(2025-10-29T10:00:00Z),
    expiresAt: DateTime(2025-10-29T10:15:00Z),
    used: false,
    usedAt: null
  ),
  DeviceLinkCode(
    id: "doc2",
    code: "5678-9012",
    memberName: "Bob",
    createdAt: DateTime(2025-10-29T10:05:00Z),
    expiresAt: DateTime(2025-10-29T10:20:00Z),
    used: false,
    usedAt: null
  )
]
```

**Sorting**: Codes are sorted by expiry time (ascending) - codes expiring soonest appear first.

**Filtering**: Only includes codes where:
- `used == false`
- `expiresAt > now()`

### Empty Response

```dart
// State: ActiveCodesLoading → ActiveCodesLoaded(codes: [])
```

**UI Display**: Show "No active codes" message

### Failure Response

```dart
// State: ActiveCodesLoading → ActiveCodesError(message: errorMessage)
```

---

## Error Responses

| Error | Condition | State Transition | User Message |
|-------|-----------|------------------|--------------|
| `TripNotFound` | Trip doesn't exist | `ActiveCodesLoading` → `ActiveCodesError` | "Trip not found" |
| `PermissionDenied` | User not authorized | `ActiveCodesLoading` → `ActiveCodesError` | "You don't have permission to view codes" |
| `NetworkError` | Firestore unavailable | `ActiveCodesLoading` → `ActiveCodesError` | "Cannot load codes offline. Check connection." |

---

## Business Logic

### Query Implementation

```dart
Future<void> loadActiveCodes(String tripId) async {
  emit(const ActiveCodesLoading());

  try {
    final now = Timestamp.now();

    final querySnapshot = await _firestore
      .collection('trips')
      .doc(tripId)
      .collection('deviceLinkCodes')
      .where('used', isEqualTo: false)
      .where('expiresAt', isGreaterThan: now)
      .orderBy('expiresAt', descending: false)  // Soonest first
      .get();

    final codes = querySnapshot.docs
      .map((doc) => DeviceLinkCode.fromFirestore(doc))
      .toList();

    emit(ActiveCodesLoaded(codes: codes));
  } on FirebaseException catch (e) {
    if (e.code == 'permission-denied') {
      emit(ActiveCodesError('You don\'t have permission to view codes'));
    } else {
      emit(ActiveCodesError('Failed to load codes: ${e.message}'));
    }
  } catch (e) {
    emit(ActiveCodesError('Cannot load codes offline. Check connection.'));
  }
}
```

### Client-Side Expiry Check (Optional Enhancement)

```dart
// Filter out any codes that expired during network latency
final activeCodes = codes.where((code) => !code.isExpired).toList();
```

**Reason**: Server timestamp may differ from client time (clock skew). Double-check on client for UX consistency.

---

## Firestore Operations

### Query Pattern

```dart
GET /trips/{tripId}/deviceLinkCodes
WHERE used == false
WHERE expiresAt > now()
ORDER BY expiresAt ASC
```

**Index Required**:
```
Collection: deviceLinkCodes (collection group)
Fields: tripId (Ascending), used (Ascending), expiresAt (Ascending)
```

**Cost**: 1 read per active code (e.g., 5 active codes = 5 reads)

**Optimization**: Query returns only active codes, not all codes (efficient).

---

## Performance Requirements

| Metric | Target | Measurement |
|--------|--------|-------------|
| Response Time | <2 seconds | Time from cubit call to state emission |
| Firestore Latency | <500ms | Network round-trip for query |
| Max Codes Displayed | 50 | Pagination not needed (trips typically have <10 active codes) |
| Real-Time Updates | Optional | Can use `.snapshots()` for live updates |

---

## Data Display Format

### List Item Layout

```
┌─────────────────────────────────────────────────┐
│ CODE: 1234-5678                           [Copy] │
│ For: Alice                                       │
│ Expires in: 14:32                          [🗑️]  │
└─────────────────────────────────────────────────┘
```

**Fields Displayed**:
- Code (large, bold)
- Member name it was generated for
- Time until expiry (countdown timer)
- Copy button (to copy code to clipboard)
- Revoke button (delete icon)

### Countdown Timer

```dart
String formatTimeUntilExpiry(DateTime expiresAt) {
  final duration = expiresAt.difference(DateTime.now());

  if (duration.isNegative) {
    return 'Expired';
  }

  final minutes = duration.inMinutes;
  final seconds = duration.inSeconds % 60;

  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}

// Example outputs:
// "14:32" (14 minutes, 32 seconds)
// "02:05" (2 minutes, 5 seconds)
// "00:30" (30 seconds)
```

**Update Frequency**: Refresh countdown every second using `StreamBuilder` or `Timer.periodic`.

---

## Real-Time Updates (Optional Enhancement)

### Using Firestore Snapshots

```dart
Stream<List<DeviceLinkCode>> watchActiveCodes(String tripId) {
  final now = Timestamp.now();

  return _firestore
    .collection('trips')
    .doc(tripId)
    .collection('deviceLinkCodes')
    .where('used', isEqualTo: false)
    .where('expiresAt', isGreaterThan: now)
    .orderBy('expiresAt', descending: false)
    .snapshots()
    .map((snapshot) => snapshot.docs
      .map((doc) => DeviceLinkCode.fromFirestore(doc))
      .toList());
}
```

**Benefit**: List automatically updates when:
- New code is generated
- Code is revoked
- Code is used
- Code expires (requires periodic re-query)

**Cost**: 1 read per update event (may increase Firestore usage)

**Decision for MVP**: Use one-time load (`get()`) instead of real-time (`snapshots()`) to minimize costs. Can add real-time in future if requested.

---

## Use Cases

### UC1: View Active Codes Before Generating New One
**Scenario**: Member wants to check if code already exists for "Alice" before generating
**Action**: Navigate to Active Codes, search for "Alice"
**Result**: See existing code or confirm none exists

### UC2: Share Code from Active Codes List
**Scenario**: Member forgot to share code after generating it
**Action**: Open Active Codes, find code for "Alice", tap Copy
**Result**: Code copied to clipboard, can be shared via text/call

### UC3: Cleanup Old Codes
**Scenario**: Trip has 10 active codes but only 2 are still needed
**Action**: View Active Codes list, revoke unnecessary codes
**Result**: Clean list with only needed codes

### UC4: Monitor Code Expiry
**Scenario**: Member generated code 10 minutes ago, wants to check if still valid
**Action**: Open Active Codes, see countdown timer
**Result**: "Expires in 04:32" - code still valid, can share with Device B user

---

## Test Scenarios

### Unit Tests

```dart
test('loadActiveCodes returns only unexpired, unused codes', () async {
  // Setup: Create multiple codes
  await setupCode(tripId: 'trip123', memberName: 'Alice', used: false, expiresAt: now.add(Duration(minutes: 10)));
  await setupCode(tripId: 'trip123', memberName: 'Bob', used: true, expiresAt: now.add(Duration(minutes: 10)));
  await setupCode(tripId: 'trip123', memberName: 'Charlie', used: false, expiresAt: now.subtract(Duration(minutes: 1)));

  await cubit.loadActiveCodes(tripId: 'trip123');

  final state = cubit.state as ActiveCodesLoaded;
  expect(state.codes.length, 1);  // Only Alice's code (unused + not expired)
  expect(state.codes.first.memberName, 'Alice');
});

test('loadActiveCodes returns empty list when no active codes', () async {
  await cubit.loadActiveCodes(tripId: 'trip123');

  final state = cubit.state as ActiveCodesLoaded;
  expect(state.codes, isEmpty);
});

test('loadActiveCodes sorts codes by expiry time', () async {
  await setupCode(tripId: 'trip123', memberName: 'Alice', expiresAt: now.add(Duration(minutes: 15)));
  await setupCode(tripId: 'trip123', memberName: 'Bob', expiresAt: now.add(Duration(minutes: 5)));
  await setupCode(tripId: 'trip123', memberName: 'Charlie', expiresAt: now.add(Duration(minutes: 10)));

  await cubit.loadActiveCodes(tripId: 'trip123');

  final state = cubit.state as ActiveCodesLoaded;
  expect(state.codes[0].memberName, 'Bob');      // Expires soonest
  expect(state.codes[1].memberName, 'Charlie');
  expect(state.codes[2].memberName, 'Alice');    // Expires latest
});
```

### Integration Tests

```dart
testWidgets('User can view active codes in trip settings', (tester) async {
  // Setup: Generate code
  await generateCode(tripId: 'trip123', memberName: 'Alice');

  // Navigate to Trip Settings → Active Codes
  await tester.tap(find.text('Settings'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Active Device Codes'));
  await tester.pumpAndSettle();

  // Expect code displayed
  expect(find.text('1234-5678'), findsOneWidget);
  expect(find.text('For: Alice'), findsOneWidget);
  expect(find.textContaining('Expires in'), findsOneWidget);
});

testWidgets('User sees "No active codes" when list is empty', (tester) async {
  // Navigate to Active Codes with no codes
  await tester.tap(find.text('Settings'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Active Device Codes'));
  await tester.pumpAndSettle();

  expect(find.text('No active codes'), findsOneWidget);
});
```

---

## UI Components

### Page Structure

```dart
class ActiveCodesPage extends StatelessWidget {
  final String tripId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Active Device Codes')),
      body: BlocBuilder<DevicePairingCubit, DevicePairingState>(
        builder: (context, state) {
          if (state is ActiveCodesLoading) {
            return Center(child: CircularProgressIndicator());
          }

          if (state is ActiveCodesError) {
            return Center(child: Text(state.message));
          }

          if (state is ActiveCodesLoaded) {
            if (state.codes.isEmpty) {
              return Center(child: Text('No active codes'));
            }

            return ListView.builder(
              itemCount: state.codes.length,
              itemBuilder: (context, index) {
                return ActiveCodeListTile(code: state.codes[index]);
              },
            );
          }

          return SizedBox.shrink();
        },
      ),
    );
  }
}
```

---

## Dependencies

- `cloud_firestore` package
- `DeviceLinkCodeRepository` interface
- Countdown timer utility

---

## Future Enhancements

1. **Search/Filter**: Filter codes by member name
2. **Pagination**: Load codes in batches (if >50 codes)
3. **Export**: Export all active codes as text file
4. **Bulk Actions**: Select multiple codes and revoke at once
5. **Expiry Alerts**: Show warning when codes about to expire (<5 min)
6. **Real-Time Updates**: Use Firestore snapshots for live list updates

---

## See Also

- [Contract: Generate Code](./01-generate-code.md)
- [Contract: Validate Code](./02-validate-code.md)
- [Contract: Revoke Code](./03-revoke-code.md)
- [Data Model](../data-model.md)
