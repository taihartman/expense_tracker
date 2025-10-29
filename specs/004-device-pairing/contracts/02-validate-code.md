# Contract: Validate Device Link Code

**Operation**: Validate a verification code and grant trip access to requesting device
**Endpoint**: `DevicePairingCubit.validateCode()`
**Type**: Mutation (with side effects: marks code as used, grants trip access)
**Priority**: P1 (Critical Path)

---

## Input Contract

### Parameters

```dart
Future<bool> validateCode({
  required String tripId,
  required String code,
  required String memberName,
});
```

| Parameter | Type | Required | Constraints | Description |
|-----------|------|----------|-------------|-------------|
| `tripId` | String | ✅ | Non-empty, must exist in Firestore | Trip to validate code for |
| `code` | String | ✅ | 8-9 chars (8 digits + optional hyphen) | Code entered by user |
| `memberName` | String | ✅ | 1-50 chars | Name of member requesting verification |

### Input Normalization

```dart
String _normalizeCode(String input) {
  return input.replaceAll('-', '').replaceAll(' ', '');
}

// Accepts both:
// - "1234-5678" (hyphenated)
// - "12345678" (plain)
```

### Preconditions

1. User must be authenticated (anonymous Firebase auth)
2. Trip with `tripId` must exist in Firestore
3. User must not exceed rate limit (5 attempts in last 60 seconds)
4. Code must be 8 digits (after removing hyphen)

---

## Output Contract

### Success Response

```dart
// Returns: true (validation successful)
// State: CodeValidating → CodeValidated(tripId: tripId)
```

**Side Effects on Success**:
1. Marks code as used in Firestore: `{used: true, usedAt: serverTimestamp()}`
2. Adds trip ID to local storage (SharedPreferences): `memberTrips.add(tripId)`
3. Records validation attempt: `validationAttempts.add({timestamp: now, success: true})`
4. Navigates user to trip page or home page with trip selected

### Failure Response

```dart
// Returns: false (validation failed)
// State: CodeValidating → CodeValidationError(message: errorMessage)
```

**Side Effects on Failure**:
1. Records validation attempt: `validationAttempts.add({timestamp: now, success: false})`
2. Does NOT mark code as used
3. Increments attempt counter (for rate limiting)

---

## Validation Rules

The code must pass **ALL** of the following checks:

| Rule | Check | Error Message | HTTP Status Equivalent |
|------|-------|---------------|------------------------|
| 1. Code exists | Code found in Firestore | "Invalid or expired code" | 404 Not Found |
| 2. Not expired | `expiresAt > now()` | "Code has expired. Request a new one from a member." | 410 Gone |
| 3. Not used | `used == false` | "Code already used" | 409 Conflict |
| 4. Trip matches | `code.tripId == requestedTripId` | "Code is for a different trip" | 400 Bad Request |
| 5. Member name matches | `code.memberNameLower == memberName.toLowerCase()` | "Code doesn't match your member name" | 403 Forbidden |
| 6. Not rate limited | <5 attempts in last 60s | "Too many attempts. Please wait 60 seconds." | 429 Too Many Requests |

**Validation Order**: Check rate limit first → Query Firestore → Validate remaining rules

---

## Business Logic

### Rate Limiting Check

```dart
Future<bool> _isRateLimited(String tripId) async {
  final cutoff = DateTime.now().subtract(Duration(seconds: 60));
  final attempts = await _firestore
    .collection('trips')
    .doc(tripId)
    .collection('validationAttempts')
    .where('timestamp', isGreaterThan: Timestamp.fromDate(cutoff))
    .get();

  return attempts.docs.length >= 5;
}
```

**Action on Rate Limit**: Return early with error, do NOT query Firestore for code

### Code Query

```dart
final codeQuery = await _firestore
  .collection('trips')
  .doc(tripId)
  .collection('deviceLinkCodes')
  .where('code', isEqualTo: _formatCode(code))  // Add hyphen back
  .limit(1)
  .get();

if (codeQuery.docs.isEmpty) {
  throw InvalidCodeException('Invalid or expired code');
}

final codeDoc = codeQuery.docs.first;
final codeData = DeviceLinkCode.fromFirestore(codeDoc);
```

### Atomic One-Time Use Enforcement

```dart
return await _firestore.runTransaction((transaction) async {
  // Re-read code inside transaction to check current state
  final freshDoc = await transaction.get(codeDoc.reference);
  final freshData = DeviceLinkCode.fromFirestore(freshDoc);

  // Validate rules
  if (freshData.used) {
    throw CodeAlreadyUsedException('Code already used');
  }
  if (freshData.isExpired) {
    throw CodeExpiredException('Code has expired');
  }
  if (freshData.memberNameLower != memberName.toLowerCase()) {
    throw MemberNameMismatchException('Code doesn\'t match your member name');
  }

  // Mark as used (atomic)
  transaction.update(codeDoc.reference, {
    'used': true,
    'usedAt': FieldValue.serverTimestamp(),
  });

  return true;
});
```

**Why Transaction?** Prevents race condition where two devices try to use the same code simultaneously.

### Grant Trip Access

```dart
Future<void> _grantTripAccess(String tripId) async {
  final prefs = await SharedPreferences.getInstance();
  final existingTrips = prefs.getStringList('memberTrips') ?? [];

  if (!existingTrips.contains(tripId)) {
    existingTrips.add(tripId);
    await prefs.setStringList('memberTrips', existingTrips);
  }
}
```

**Effect**: User can now see trip in trip list and access trip pages.

---

## Firestore Operations

### Query Pattern (Rate Limit Check)

```dart
GET /trips/{tripId}/validationAttempts
WHERE timestamp > (now - 60 seconds)
```

**Cost**: 1 read (0 if rate limit not hit)

### Query Pattern (Code Lookup)

```dart
GET /trips/{tripId}/deviceLinkCodes
WHERE code == "1234-5678"
LIMIT 1
```

**Cost**: 1 read

### Transaction Pattern (Mark as Used)

```dart
TRANSACTION {
  READ /trips/{tripId}/deviceLinkCodes/{codeId}
  VALIDATE (used == false, not expired, name matches)
  UPDATE /trips/{tripId}/deviceLinkCodes/{codeId} { used: true, usedAt: serverTimestamp() }
}
```

**Cost**: 1 read + 1 write (inside transaction) = **2 reads + 1 write total**

### Write Pattern (Record Attempt)

```dart
POST /trips/{tripId}/validationAttempts/
{
  timestamp: FieldValue.serverTimestamp(),
  success: true/false
}
```

**Cost**: 1 write

**Total Operation Cost**: 2-3 reads + 2 writes = **4-5 operations per validation**

---

## Performance Requirements

| Metric | Target | Measurement |
|--------|--------|-------------|
| Response Time | <1 second | Time from cubit call to state emission |
| Firestore Latency | <300ms | Network round-trip for transaction |
| Transaction Retry | Max 5 attempts | Firestore automatic retry on conflicts |
| Rate Limit Check | <100ms | In-memory or local query |

---

## Error Handling

### Error Priority (Check in Order)

1. **Rate Limit** → Check first (prevents unnecessary Firestore reads)
2. **Invalid Code** → Code not found in Firestore
3. **Expired** → Check timestamp
4. **Already Used** → Check used flag
5. **Name Mismatch** → Check memberNameLower
6. **Network Error** → Catch Firestore exceptions

### User-Facing Error Messages

```dart
Map<Type, String> errorMessages = {
  RateLimitException: 'Too many attempts. Please wait 60 seconds.',
  InvalidCodeException: 'Invalid or expired code',
  CodeExpiredException: 'Code has expired. Request a new one from a member.',
  CodeAlreadyUsedException: 'Code already used',
  MemberNameMismatchException: 'Code doesn\'t match your member name',
  NetworkException: 'Cannot verify code offline. Check connection.',
};
```

**UX Note**: Do NOT reveal which specific check failed for invalid codes (security best practice). Use generic "Invalid or expired code" for NotFound errors.

---

## Security Considerations

1. **Rate Limiting**: Global per trip (5 attempts/min) prevents brute force
2. **Atomic Operations**: Firestore transaction prevents race conditions
3. **Server Timestamps**: Cannot be manipulated by client
4. **Error Message Obscurity**: Generic errors for invalid codes (don't leak information)
5. **No Code Enumeration**: Cannot list all codes via API
6. **Case-Insensitive Name Matching**: Prevents bypassing via case changes

### Brute Force Analysis

- **Code Space**: 100,000,000 combinations (10^8)
- **Rate Limit**: 5 attempts per minute = 7200 attempts per day
- **Success Probability**: 7200 / 100M = 0.0072% per day
- **With 15-min Expiry**: Only 75 attempts possible per code (0.000075% success rate)

**Conclusion**: Brute force attacks are infeasible.

---

## Test Scenarios

### Unit Tests

```dart
test('validateCode succeeds with valid code', () async {
  final code = await setupValidCode(tripId: 'trip123', memberName: 'Alice');

  final result = await cubit.validateCode(
    tripId: 'trip123',
    code: code.code,
    memberName: 'Alice',
  );

  expect(result, true);
  expect(cubit.state, isA<CodeValidated>());
});

test('validateCode fails with expired code', () async {
  final code = await setupExpiredCode(tripId: 'trip123', memberName: 'Alice');

  expect(
    () => cubit.validateCode(tripId: 'trip123', code: code.code, memberName: 'Alice'),
    throwsA(isA<CodeExpiredException>()),
  );
});

test('validateCode marks code as used atomically', () async {
  final code = await setupValidCode(tripId: 'trip123', memberName: 'Alice');

  // Validate code
  await cubit.validateCode(tripId: 'trip123', code: code.code, memberName: 'Alice');

  // Verify code is now marked as used
  final updatedCode = await repository.getCodeById(code.id);
  expect(updatedCode.used, true);
  expect(updatedCode.usedAt, isNotNull);
});

test('validateCode enforces rate limiting', () async {
  // Make 5 failed attempts
  for (int i = 0; i < 5; i++) {
    try {
      await cubit.validateCode(tripId: 'trip123', code: 'invalid', memberName: 'Alice');
    } catch (_) {}
  }

  // 6th attempt should be rate limited
  expect(
    () => cubit.validateCode(tripId: 'trip123', code: 'another', memberName: 'Alice'),
    throwsA(isA<RateLimitException>()),
  );
});

test('validateCode accepts code without hyphen', () async {
  final code = await setupValidCode(tripId: 'trip123', memberName: 'Alice');

  final result = await cubit.validateCode(
    tripId: 'trip123',
    code: code.code.replaceAll('-', ''),  // Remove hyphen
    memberName: 'Alice',
  );

  expect(result, true);
});

test('validateCode fails when member name does not match', () async {
  final code = await setupValidCode(tripId: 'trip123', memberName: 'Alice');

  expect(
    () => cubit.validateCode(tripId: 'trip123', code: code.code, memberName: 'Bob'),
    throwsA(isA<MemberNameMismatchException>()),
  );
});
```

### Integration Tests

```dart
testWidgets('User can validate code and access trip', (tester) async {
  // Setup: Generate code on Device A
  final code = await generateCodeOnDeviceA(tripId: 'trip123', memberName: 'Alice');

  // Device B: Try to join with duplicate name
  await tester.enterText(find.byKey(Key('tripIdField')), 'trip123');
  await tester.enterText(find.byKey(Key('nameField')), 'Alice');
  await tester.tap(find.text('Join Trip'));
  await tester.pumpAndSettle();

  // Expect verification prompt
  expect(find.byType(CodeVerificationPrompt), findsOneWidget);

  // Enter code
  await tester.enterText(find.byKey(Key('codeField')), code);
  await tester.tap(find.text('Verify'));
  await tester.pumpAndSettle();

  // Expect success and navigation to trip
  expect(find.text('Device verified!'), findsOneWidget);
  expect(find.byType(TripPage), findsOneWidget);
});
```

---

## Dependencies

- `cloud_firestore` package (transactions)
- `shared_preferences` package (local storage)
- `DeviceLinkCodeRepository` interface
- `TripRepository` (to add user to cached trip list)

---

## Future Enhancements

1. **Biometric Confirmation**: Require fingerprint/FaceID before validation
2. **Device Fingerprinting**: Log device type/browser for audit trail
3. **Push Notifications**: Notify Device A when Device B successfully validates
4. **Auto-Revoke on Use**: Option to auto-revoke code after first use (already implemented)
5. **Validation History**: Show user their recent validation attempts in settings

---

## See Also

- [Contract: Generate Code](./01-generate-code.md)
- [Contract: Revoke Code](./03-revoke-code.md)
- [Data Model](../data-model.md)
- [Research: Rate Limiting](../research.md#q1-how-to-implement-global-rate-limiting)
- [Research: Atomic Operations](../research.md#q2-how-to-enforce-one-time-use-atomically)
