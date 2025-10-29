# Phase 0: Research - Device Pairing Technical Unknowns

**Feature**: Device Pairing for Multi-Device Access
**Branch**: `004-device-pairing`
**Date**: 2025-10-29

## Purpose

This document resolves technical unknowns identified during planning. Each question is answered with concrete implementation details, code examples, and references to ensure the feature can be implemented without blocking issues.

---

## Research Questions

### Q1: How to implement global rate limiting (5 attempts/min) in Firestore security rules?

**Status**: ✅ RESOLVED

**Answer**: Firestore security rules support rate limiting using the `request.time` variable and aggregation queries. However, true "sliding window" rate limiting is complex in security rules. The recommended approach is:

**Option A - Simple Time-Based Windows (Recommended)**:
Store validation attempts in a subcollection and count attempts in the last 60 seconds:

```javascript
// Firestore Security Rules (firestore.rules)
match /trips/{tripId}/validationAttempts/{attemptId} {
  allow write: if request.auth != null
    && get(/databases/$(database)/documents/trips/$(tripId)).data.exists()
    && countRecentAttempts(tripId) < 5;
}

function countRecentAttempts(tripId) {
  let recentAttempts = firestore.get(/databases/$(database)/documents/trips/$(tripId)/validationAttempts)
    .where('timestamp', '>', request.time - duration.value(60, 's'));
  return recentAttempts.size();
}
```

**Option B - Client-Side Tracking with Server Validation (Simpler)**:
- Client tracks attempts locally and enforces UI-level rate limiting
- Server validates using Firestore transaction to check attempt count
- Security rules prevent excessive writes

**Decision**: Use **Option B** for MVP (simpler, sufficient for non-hostile users). Option A can be added later if abuse detected.

**Implementation Notes**:
- Store attempts in `/trips/{tripId}/validationAttempts/{autoId}` subcollection
- Each attempt document: `{timestamp: DateTime, success: bool}`
- Cubit checks attempt count in last 60 seconds before allowing validation
- Clean up old attempts (>1 hour) using TTL or periodic cleanup

---

### Q2: How to enforce one-time use of codes atomically in Firestore?

**Status**: ✅ RESOLVED

**Answer**: Use Firestore transactions to ensure atomic read-modify-write operations. This prevents race conditions where two devices try to use the same code simultaneously.

**Implementation Pattern**:

```dart
Future<bool> validateAndUseCode(String tripId, String code, String memberName) async {
  final docRef = _firestore
      .collection('trips')
      .doc(tripId)
      .collection('deviceLinkCodes')
      .where('code', isEqualTo: code)
      .limit(1);

  return await _firestore.runTransaction((transaction) async {
    // Read code document
    final querySnapshot = await docRef.get();
    if (querySnapshot.docs.isEmpty) {
      throw Exception('Invalid code');
    }

    final codeDoc = querySnapshot.docs.first;
    final data = codeDoc.data();

    // Validate conditions
    if (data['used'] == true) {
      throw Exception('Code already used');
    }
    if (DateTime.parse(data['expiresAt']).isBefore(DateTime.now())) {
      throw Exception('Code expired');
    }
    if (data['memberName'].toLowerCase() != memberName.toLowerCase()) {
      throw Exception('Code does not match member name');
    }

    // Mark as used (atomic)
    transaction.update(codeDoc.reference, {
      'used': true,
      'usedAt': FieldValue.serverTimestamp(),
    });

    return true;
  });
}
```

**Key Points**:
- Firestore transactions automatically retry on conflicts
- Use `FieldValue.serverTimestamp()` for accurate server-side timestamps
- Transaction block ensures no other device can use code during validation
- Max transaction size: 500 documents (we only need 1, well within limits)

---

### Q3: How to auto-delete expired codes from Firestore?

**Status**: ✅ RESOLVED

**Answer**: Firestore does not have built-in TTL (Time-To-Live) for automatic document deletion. Three options:

**Option A - Firebase Extensions TTL (Recommended)**:
- Use the official "Delete Collections" extension
- Configure to delete documents where `expiresAt < now()`
- Runs automatically every hour
- Free tier: Up to 1000 deletes/day

**Option B - Cloud Functions (More Complex)**:
```javascript
// Cloud Function triggered daily
exports.cleanupExpiredCodes = functions.pubsub
  .schedule('every 24 hours')
  .onRun(async (context) => {
    const now = admin.firestore.Timestamp.now();
    const expiredQuery = admin.firestore()
      .collectionGroup('deviceLinkCodes')
      .where('expiresAt', '<', now)
      .limit(500);

    const snapshot = await expiredQuery.get();
    const batch = admin.firestore().batch();
    snapshot.docs.forEach(doc => batch.delete(doc.ref));
    await batch.commit();
  });
```

**Option C - Client-Side Cleanup (Simplest for MVP)**:
- When loading codes, filter out expired ones client-side
- Periodically delete expired codes when user accesses Trip Settings
- Leave old codes in Firestore (they're harmless, just take storage)

**Decision**: Use **Option C** for MVP (no server setup required). Can add Option A later if storage becomes concern.

**Storage Impact**: 1000 codes × 200 bytes = 200KB (negligible)

---

### Q4: How to generate cryptographically secure 8-digit codes in Dart?

**Status**: ✅ RESOLVED

**Answer**: Use Dart's `Random.secure()` constructor from `dart:math`.

**Implementation**:

```dart
import 'dart:math';

class CodeGenerator {
  static final _random = Random.secure();

  /// Generate an 8-digit code with format "XXXX-XXXX"
  static String generateCode() {
    // Generate random number between 0 and 99,999,999
    final code = _random.nextInt(100000000);

    // Pad with leading zeros to ensure 8 digits
    final codeString = code.toString().padLeft(8, '0');

    // Format as XXXX-XXXX
    return '${codeString.substring(0, 4)}-${codeString.substring(4)}';
  }

  /// Remove hyphen from code for validation
  static String normalizeCode(String code) {
    return code.replaceAll('-', '');
  }
}
```

**Security Analysis**:
- 100 million possible codes (10^8)
- With 5 attempts/min rate limiting: 7200 attempts/day max
- Brute force probability: 7200/100M = 0.0072% per day
- With 15-minute expiry: Only 75 attempts per code (0.000075% success rate)

**Key Points**:
- `Random.secure()` uses platform-specific CSPRNG (Cryptographically Secure PRNG)
- On web: Uses `window.crypto.getRandomValues()`
- On mobile: Uses `/dev/urandom` (iOS) or `SecureRandom` (Android)
- No external dependencies needed

---

### Q5: How to implement case-insensitive name matching in Firestore queries?

**Status**: ✅ RESOLVED

**Answer**: Firestore queries are case-sensitive by default. Must implement case-insensitive matching at application level.

**Approach A - Lowercase Normalization (Recommended)**:
Store a `memberNameLower` field alongside `memberName`:

```dart
// When creating trip participant
final participant = {
  'name': 'Alice',
  'nameLower': 'alice',  // Store normalized version
};

// When checking for duplicates
final existingMembers = await _firestore
  .collection('trips')
  .doc(tripId)
  .collection('participants')
  .where('nameLower', isEqualTo: inputName.toLowerCase())
  .get();

return existingMembers.docs.isNotEmpty;  // Duplicate found
```

**Approach B - Client-Side Filtering (Alternative)**:
Load all participants and filter in memory:

```dart
final allParticipants = await getParticipants(tripId);
final duplicate = allParticipants.firstWhere(
  (p) => p.name.toLowerCase() == inputName.toLowerCase(),
  orElse: () => null,
);
```

**Decision**: Use **Approach A** for new `deviceLinkCodes` collection. Use **Approach B** for existing `Trip.participants` list (don't modify existing schema). This works because:
- Trips have ≤50 participants (small data set)
- Client-side filtering is fast for small lists
- No migration needed for existing data

**Implementation for Device Codes**:
```dart
// Store code with normalized member name
final codeDoc = {
  'code': generatedCode,
  'memberName': 'Alice',          // Original casing
  'memberNameLower': 'alice',     // For querying
  'tripId': tripId,
  'createdAt': FieldValue.serverTimestamp(),
  'expiresAt': DateTime.now().add(Duration(minutes: 15)),
  'used': false,
};

// Query by normalized name
final codeQuery = await _firestore
  .collection('trips')
  .doc(tripId)
  .collection('deviceLinkCodes')
  .where('memberNameLower', isEqualTo: memberName.toLowerCase())
  .where('used', isEqualTo: false)
  .where('expiresAt', isGreaterThan: DateTime.now())
  .limit(1)
  .get();
```

---

## Summary of Decisions

| Question | Decision | Rationale |
|----------|----------|-----------|
| Rate limiting implementation | Client-side tracking with server validation | Simpler for MVP, sufficient for non-hostile users |
| One-time use enforcement | Firestore transactions | Atomic, prevents race conditions |
| Expired code cleanup | Client-side filtering (MVP) | No server setup, negligible storage impact |
| Secure code generation | `Random.secure()` with 8 digits | Built-in, cryptographically secure, 100M combinations |
| Case-insensitive matching | Normalized field for codes, client filter for participants | No schema migration, works with existing data |

---

## Open Questions Remaining

**None** - All technical unknowns have been resolved with concrete implementation paths.

---

## References

- [Firestore Transactions](https://firebase.google.com/docs/firestore/manage-data/transactions)
- [Firestore Security Rules](https://firebase.google.com/docs/firestore/security/rules-structure)
- [Dart Random.secure()](https://api.dart.dev/stable/dart-math/Random/Random.secure.html)
- [Firebase TTL Extension](https://extensions.dev/extensions/firebase/firestore-delete-collections)

---

## Next Steps

Proceed to **Phase 1**: Generate data-model.md and contracts/ with the implementation details from this research.
