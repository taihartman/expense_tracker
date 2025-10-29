# Contract: Generate Device Link Code

**Operation**: Generate a temporary 8-digit verification code for a specific member name
**Endpoint**: `DevicePairingCubit.generateCode()`
**Type**: Mutation
**Priority**: P1 (Critical Path)

---

## Input Contract

### Parameters

```dart
Future<DeviceLinkCode> generateCode({
  required String tripId,
  required String memberName,
});
```

| Parameter | Type | Required | Constraints | Description |
|-----------|------|----------|-------------|-------------|
| `tripId` | String | ✅ | Non-empty, must exist in Firestore | Trip to generate code for |
| `memberName` | String | ✅ | 1-50 chars, must match existing trip member | Member this code is generated FOR |

### Preconditions

1. User must be authenticated (anonymous Firebase auth)
2. Trip with `tripId` must exist in Firestore
3. `memberName` must match an existing participant in the trip (case-insensitive)
4. User must be a member of the trip (optional - can be enforced or relaxed for MVP)

---

## Output Contract

### Success Response

```dart
DeviceLinkCode {
  id: "auto-generated-id",
  code: "1234-5678",
  tripId: "trip123",
  memberName: "Alice",
  createdAt: DateTime(2025-10-29T10:00:00Z),
  expiresAt: DateTime(2025-10-29T10:15:00Z),
  used: false,
  usedAt: null
}
```

**State Transition**: `CodeGenerating` → `CodeGenerated(DeviceLinkCode)`

**Side Effects**:
1. Creates document in `/trips/{tripId}/deviceLinkCodes/` collection
2. If code already exists for this member, invalidates previous code by marking it as used
3. Emits `CodeGenerated` state with the new code

### Error Responses

| Error | Condition | State Transition | User Message |
|-------|-----------|------------------|--------------|
| `TripNotFound` | Trip doesn't exist | `CodeGenerating` → `CodeGenerationError` | "Trip not found" |
| `MemberNotFound` | Member name doesn't exist in trip | `CodeGenerating` → `CodeGenerationError` | "Member name not found in trip" |
| `NetworkError` | Firestore unavailable | `CodeGenerating` → `CodeGenerationError` | "Cannot generate code offline. Check connection." |
| `PermissionDenied` | User not authorized | `CodeGenerating` → `CodeGenerationError` | "You don't have permission to generate codes" |
| `RateLimitExceeded` | Too many codes generated | `CodeGenerating` → `CodeGenerationError` | "Too many codes generated. Please wait." |

---

## Business Logic

### Code Generation Algorithm

```dart
String _generateCode() {
  final random = Random.secure();
  final code = random.nextInt(100000000);  // 0 to 99,999,999
  return code.toString().padLeft(8, '0');
}

String _formatCode(String code) {
  return '${code.substring(0, 4)}-${code.substring(4)}';
}
```

**Output**: 8-digit code with hyphen separator (e.g., "1234-5678")

### Invalidation of Previous Codes

```dart
// Before creating new code, invalidate existing codes for same member
await _firestore
  .collection('trips')
  .doc(tripId)
  .collection('deviceLinkCodes')
  .where('memberNameLower', isEqualTo: memberName.toLowerCase())
  .where('used', isEqualTo: false)
  .get()
  .then((snapshot) async {
    for (var doc in snapshot.docs) {
      await doc.reference.update({'used': true, 'usedAt': FieldValue.serverTimestamp()});
    }
  });
```

**Reason**: Only one active code per member at a time (security best practice)

### Expiry Calculation

```dart
final createdAt = DateTime.now();
final expiresAt = createdAt.add(Duration(minutes: 15));
```

**Value**: Exactly 15 minutes from creation (non-configurable for MVP)

---

## Firestore Operations

### Query Pattern

```dart
// Check for existing codes (to invalidate)
GET /trips/{tripId}/deviceLinkCodes
WHERE memberNameLower == memberName.toLowerCase()
WHERE used == false
```

### Write Pattern

```dart
// Create new code document
POST /trips/{tripId}/deviceLinkCodes/
{
  code: "1234-5678",
  memberName: "Alice",
  memberNameLower: "alice",
  tripId: tripId,
  createdAt: FieldValue.serverTimestamp(),
  expiresAt: Timestamp.fromDate(now.add(Duration(minutes: 15))),
  used: false,
  usedAt: null
}
```

**Operation Cost**: 1 read (check existing) + N writes (invalidate existing, max 1) + 1 write (create new) = **2-3 operations**

---

## Performance Requirements

| Metric | Target | Measurement |
|--------|--------|-------------|
| Response Time | <2 seconds | Time from cubit call to state emission |
| Firestore Latency | <500ms | Network round-trip for write |
| Code Generation | <10ms | Cryptographic random generation time |
| Invalidation | <1 second | Time to mark previous codes as used |

---

## Security Considerations

1. **Random Generation**: Use `Random.secure()` to prevent predictability
2. **Collision Handling**: 100M possible codes make collisions extremely rare (no explicit handling needed)
3. **Previous Code Invalidation**: Prevents confusion and reduces attack surface
4. **Server Timestamps**: Use `FieldValue.serverTimestamp()` to prevent client-side manipulation
5. **Rate Limiting**: (Future) Limit code generation to 5 per minute per trip

---

## Test Scenarios

### Unit Tests

```dart
test('generateCode returns 8-digit code with hyphen', () async {
  final code = await cubit.generateCode(
    tripId: 'trip123',
    memberName: 'Alice',
  );

  expect(code.code, matches(r'^\d{4}-\d{4}$'));
  expect(code.tripId, 'trip123');
  expect(code.memberName, 'Alice');
  expect(code.used, false);
});

test('generateCode invalidates previous codes for same member', () async {
  // Generate first code
  final code1 = await cubit.generateCode(tripId: 'trip123', memberName: 'Alice');

  // Generate second code
  final code2 = await cubit.generateCode(tripId: 'trip123', memberName: 'Alice');

  // Verify first code is now marked as used
  final oldCode = await repository.getCodeById(code1.id);
  expect(oldCode.used, true);
  expect(code2.used, false);
});

test('generateCode throws TripNotFound when trip does not exist', () async {
  expect(
    () => cubit.generateCode(tripId: 'nonexistent', memberName: 'Alice'),
    throwsA(isA<TripNotFound>()),
  );
});
```

### Integration Tests

```dart
testWidgets('User can generate code from trip members list', (tester) async {
  // Navigate to trip settings
  await tester.tap(find.text('Settings'));
  await tester.pumpAndSettle();

  // Tap on member
  await tester.tap(find.text('Alice'));
  await tester.pumpAndSettle();

  // Tap generate code button
  await tester.tap(find.text('Generate Code'));
  await tester.pumpAndSettle();

  // Verify code is displayed
  expect(find.byType(CodeGenerationDialog), findsOneWidget);
  expect(find.textContaining(RegExp(r'\d{4}-\d{4}')), findsOneWidget);
});
```

---

## Dependencies

- `Random.secure()` from `dart:math`
- `cloud_firestore` package
- `DeviceLinkCodeRepository` interface
- `TripRepository` (to verify trip exists and user is member)

---

## Future Enhancements

1. **Rate Limiting**: Add Firestore write limit (5 codes per minute per trip)
2. **Audit Trail**: Log who generated each code (requires user ID field)
3. **Batch Generation**: Generate multiple codes at once for multiple members
4. **Custom Expiry**: Allow members to set custom expiry (5, 15, 30 minutes)
5. **Code Format Options**: Allow numeric-only codes for easier phone sharing

---

## See Also

- [Contract: Validate Code](./02-validate-code.md)
- [Contract: Revoke Code](./03-revoke-code.md)
- [Data Model](../data-model.md)
