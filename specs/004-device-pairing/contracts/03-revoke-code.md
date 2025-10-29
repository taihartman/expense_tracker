# Contract: Revoke Device Link Code

**Operation**: Revoke (delete) an active or used device link code
**Endpoint**: `DevicePairingCubit.revokeCode()`
**Type**: Mutation (Delete)
**Priority**: P3 (Nice-to-Have)

---

## Input Contract

### Parameters

```dart
Future<void> revokeCode({
  required String tripId,
  required String codeId,
});
```

| Parameter | Type | Required | Constraints | Description |
|-----------|------|----------|-------------|-------------|
| `tripId` | String | ✅ | Non-empty, must exist in Firestore | Trip the code belongs to |
| `codeId` | String | ✅ | Non-empty, must be valid document ID | ID of code document to revoke |

### Preconditions

1. User must be authenticated (anonymous Firebase auth)
2. Trip with `tripId` must exist in Firestore
3. User must be a member of the trip (authorization check)
4. Code with `codeId` must exist in trip's deviceLinkCodes subcollection

---

## Output Contract

### Success Response

```dart
// Returns: void (operation successful)
// State: CodeRevoking → CodeRevoked(codeId: codeId)
```

**Side Effects**:
1. Deletes code document from Firestore: `DELETE /trips/{tripId}/deviceLinkCodes/{codeId}`
2. Removes code from local cache (if cached)
3. Emits `CodeRevoked` state

### Failure Response

```dart
// Throws exception
// State: CodeRevoking → CodeRevocationError(message: errorMessage)
```

---

## Error Responses

| Error | Condition | State Transition | User Message |
|-------|-----------|------------------|--------------|
| `CodeNotFound` | Code document doesn't exist | `CodeRevoking` → `CodeRevocationError` | "Code not found" |
| `PermissionDenied` | User not authorized | `CodeRevoking` → `CodeRevocationError` | "You don't have permission to revoke codes" |
| `NetworkError` | Firestore unavailable | `CodeRevoking` → `CodeRevocationError` | "Cannot revoke code offline. Check connection." |

---

## Business Logic

### Delete Operation

```dart
Future<void> revokeCode(String tripId, String codeId) async {
  emit(const CodeRevoking());

  try {
    // Verify code exists
    final codeDoc = await _firestore
      .collection('trips')
      .doc(tripId)
      .collection('deviceLinkCodes')
      .doc(codeId)
      .get();

    if (!codeDoc.exists) {
      throw CodeNotFoundException('Code not found');
    }

    // Delete code document
    await codeDoc.reference.delete();

    emit(CodeRevoked(codeId: codeId));
  } on FirebaseException catch (e) {
    if (e.code == 'permission-denied') {
      emit(CodeRevocationError('You don\'t have permission to revoke codes'));
    } else {
      emit(CodeRevocationError('Failed to revoke code: ${e.message}'));
    }
  } catch (e) {
    emit(CodeRevocationError('Cannot revoke code offline. Check connection.'));
  }
}
```

**Note**: Revoking a code that has already been used is allowed (for cleanup purposes).

---

## Firestore Operations

### Query Pattern (Verify Exists)

```dart
GET /trips/{tripId}/deviceLinkCodes/{codeId}
```

**Cost**: 1 read

### Delete Pattern

```dart
DELETE /trips/{tripId}/deviceLinkCodes/{codeId}
```

**Cost**: 1 delete (counts as 1 write)

**Total Operation Cost**: 1 read + 1 delete = **2 operations per revocation**

---

## Performance Requirements

| Metric | Target | Measurement |
|--------|--------|-------------|
| Response Time | <1 second | Time from cubit call to state emission |
| Firestore Latency | <300ms | Network round-trip for delete |
| UI Update | Immediate | Code removed from active codes list |

---

## Security Considerations

1. **Authorization**: Only trip members can revoke codes (enforced by Firestore rules)
2. **Audit Trail**: Consider logging revocations (future enhancement)
3. **No Undo**: Revocation is permanent (document deleted, not marked inactive)
4. **Safe to Revoke Used Codes**: No negative side effects (device already granted access)

### Firestore Security Rule

```javascript
// In firestore.rules
match /trips/{tripId}/deviceLinkCodes/{codeId} {
  allow delete: if request.auth != null
    && exists(/databases/$(database)/documents/trips/$(tripId))
    && userIsMemberOf(tripId);  // Custom function to check membership
}
```

---

## Use Cases

### UC1: Member Accidentally Generated Wrong Code
**Scenario**: Member generated code for "Alice" but meant "Bob"
**Action**: Revoke the incorrect code and generate a new one for "Bob"
**Result**: Old code is deleted, new code created

### UC2: Security Concern
**Scenario**: Member suspects code was compromised (shared publicly)
**Action**: Immediately revoke the code
**Result**: Code cannot be used, even if not yet expired

### UC3: Cleanup Old Codes
**Scenario**: Trip has many expired/used codes cluttering the list
**Action**: Revoke all expired/used codes at once
**Result**: Clean active codes list

---

## Test Scenarios

### Unit Tests

```dart
test('revokeCode deletes code from Firestore', () async {
  final code = await setupValidCode(tripId: 'trip123', memberName: 'Alice');

  await cubit.revokeCode(tripId: 'trip123', codeId: code.id);

  expect(cubit.state, isA<CodeRevoked>());

  // Verify code no longer exists
  final codeDoc = await firestore
    .collection('trips')
    .doc('trip123')
    .collection('deviceLinkCodes')
    .doc(code.id)
    .get();

  expect(codeDoc.exists, false);
});

test('revokeCode throws CodeNotFound when code does not exist', () async {
  expect(
    () => cubit.revokeCode(tripId: 'trip123', codeId: 'nonexistent'),
    throwsA(isA<CodeNotFoundException>()),
  );
});

test('revokeCode can revoke already used codes', () async {
  final code = await setupUsedCode(tripId: 'trip123', memberName: 'Alice');

  await cubit.revokeCode(tripId: 'trip123', codeId: code.id);

  expect(cubit.state, isA<CodeRevoked>());
});
```

### Integration Tests

```dart
testWidgets('User can revoke code from active codes list', (tester) async {
  // Setup: Generate code
  final code = await generateCode(tripId: 'trip123', memberName: 'Alice');

  // Navigate to Trip Settings → Active Codes
  await tester.tap(find.text('Settings'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Active Device Codes'));
  await tester.pumpAndSettle();

  // Expect code in list
  expect(find.text(code.code), findsOneWidget);

  // Tap revoke button
  await tester.tap(find.byIcon(Icons.delete).first);
  await tester.pumpAndSettle();

  // Confirm revocation dialog
  await tester.tap(find.text('Revoke'));
  await tester.pumpAndSettle();

  // Expect code removed from list
  expect(find.text(code.code), findsNothing);
  expect(find.text('Code revoked'), findsOneWidget);
});
```

---

## UI Integration

### Button Placement

**Location**: Active Device Codes list in Trip Settings

**Visual Design**:
```
┌─────────────────────────────────────────┐
│ Active Device Codes                      │
├─────────────────────────────────────────┤
│  1234-5678                         [🗑️] │
│  For: Alice                              │
│  Expires in 14:32                        │
├─────────────────────────────────────────┤
│  5678-9012                         [🗑️] │
│  For: Bob                                │
│  Expires in 02:15                        │
└─────────────────────────────────────────┘
```

**Confirmation Dialog**:
```
Title: "Revoke Code?"
Message: "This code will no longer be valid. This action cannot be undone."
Actions: [Cancel] [Revoke]
```

---

## Dependencies

- `cloud_firestore` package
- `DeviceLinkCodeRepository` interface
- Trip membership verification

---

## Future Enhancements

1. **Batch Revocation**: Revoke multiple codes at once
2. **Auto-Revoke Expired**: Button to "Clean Up Expired Codes"
3. **Revocation Confirmation**: Require re-authentication for sensitive trips
4. **Audit Log**: Track who revoked which codes and when
5. **Undo Revocation**: Restore recently revoked codes (requires soft delete)

---

## See Also

- [Contract: Generate Code](./01-generate-code.md)
- [Contract: Validate Code](./02-validate-code.md)
- [Contract: List Active Codes](./04-list-active-codes.md)
- [Data Model](../data-model.md)
