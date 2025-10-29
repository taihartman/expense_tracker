# Quickstart: Device Pairing Implementation

**Feature**: Device Pairing for Multi-Device Access
**Branch**: `004-device-pairing`
**Date**: 2025-10-29

## Purpose

This guide provides a step-by-step implementation path for developers. Follow these steps in order to implement device pairing with TDD approach.

---

## Prerequisites

- Flutter SDK 3.19.0+
- Firebase project configured
- Existing features: Trip management, Trip invite system
- BLoC pattern familiarity

---

## Implementation Roadmap

### Phase 1: Domain Layer (1-2 hours)

**Goal**: Define core entities and repository interfaces

#### 1.1 Create DeviceLinkCode Entity

**File**: `lib/features/device_pairing/domain/models/device_link_code.dart`

**Test First**:
```bash
# Create test file
touch test/features/device_pairing/domain/models/device_link_code_test.dart

# Write tests for:
# - Entity creation
# - Validation rules
# - isExpired getter
# - isValid getter
# - copyWith method
```

**Implementation**:
```dart
class DeviceLinkCode {
  final String id;
  final String code;
  final String tripId;
  final String memberName;
  final DateTime createdAt;
  final DateTime expiresAt;
  final bool used;
  final DateTime? usedAt;

  // Constructor, methods, validation
}
```

**Acceptance**: All unit tests pass, entity validated correctly.

---

#### 1.2 Create Repository Interface

**File**: `lib/features/device_pairing/domain/repositories/device_link_code_repository.dart`

**Interface**:
```dart
abstract class DeviceLinkCodeRepository {
  Future<DeviceLinkCode> generateCode(String tripId, String memberName);
  Future<bool> validateCode(String tripId, String code, String memberName);
  Future<void> revokeCode(String tripId, String codeId);
  Future<List<DeviceLinkCode>> getActiveCodes(String tripId);
  Stream<List<DeviceLinkCode>> watchActiveCodes(String tripId);
}
```

**Acceptance**: Interface defined, ready for implementation.

---

### Phase 2: Data Layer (2-3 hours)

**Goal**: Implement Firestore repository with real database operations

#### 2.1 Create Firestore Repository

**File**: `lib/features/device_pairing/data/repositories/firestore_device_link_code_repository.dart`

**Test First**:
```bash
touch test/features/device_pairing/data/repositories/firestore_device_link_code_repository_test.dart

# Use mockito to mock Firestore
# Test all repository methods
```

**Implementation Highlights**:
- Use `Random.secure()` for code generation
- Store `memberNameLower` for case-insensitive queries
- Use Firestore transactions for `validateCode` (atomic one-time use)
- Invalidate previous codes when generating new one for same member

**Acceptance**: All repository tests pass, Firestore operations work correctly.

---

#### 2.2 Add Firestore Security Rules

**File**: `firestore.rules`

**Rules to Add**:
```javascript
match /trips/{tripId}/deviceLinkCodes/{codeId} {
  allow read: if request.auth != null
    && exists(/databases/$(database)/documents/trips/$(tripId));

  allow create: if request.auth != null
    && request.resource.data.used == false
    && request.resource.data.expiresAt > request.time;

  allow update: if request.auth != null
    && request.resource.data.diff(resource.data).affectedKeys().hasOnly(['used', 'usedAt']);

  allow delete: if request.auth != null;
}
```

**Deploy**:
```bash
firebase deploy --only firestore:rules
```

**Acceptance**: Security rules deployed, tested via Firebase Console.

---

### Phase 3: Presentation Layer - Cubit (2-3 hours)

**Goal**: Implement business logic and state management

#### 3.1 Create State Classes

**File**: `lib/features/device_pairing/presentation/cubits/device_pairing_state.dart`

**States**:
```dart
sealed class DevicePairingState {}
class DevicePairingInitial extends DevicePairingState {}

// Code generation states
class CodeGenerating extends DevicePairingState {}
class CodeGenerated extends DevicePairingState {
  final DeviceLinkCode code;
}
class CodeGenerationError extends DevicePairingState {
  final String message;
}

// Code validation states
class CodeValidating extends DevicePairingState {}
class CodeValidated extends DevicePairingState {
  final String tripId;
}
class CodeValidationError extends DevicePairingState {
  final String message;
}

// Active codes states
class ActiveCodesLoading extends DevicePairingState {}
class ActiveCodesLoaded extends DevicePairingState {
  final List<DeviceLinkCode> codes;
}
class ActiveCodesError extends DevicePairingState {
  final String message;
}
```

---

#### 3.2 Create DevicePairingCubit

**File**: `lib/features/device_pairing/presentation/cubits/device_pairing_cubit.dart`

**Test First**:
```bash
touch test/features/device_pairing/presentation/cubits/device_pairing_cubit_test.dart

# Test all operations:
# - generateCode()
# - validateCode()
# - revokeCode()
# - loadActiveCodes()
# - Rate limiting logic
```

**Key Methods**:
```dart
class DevicePairingCubit extends Cubit<DevicePairingState> {
  Future<void> generateCode(String tripId, String memberName);
  Future<void> validateCode(String tripId, String code, String memberName);
  Future<void> revokeCode(String tripId, String codeId);
  Future<void> loadActiveCodes(String tripId);
}
```

**Implementation Notes**:
- Add rate limiting check before validation (5 attempts/min)
- Normalize code input (remove hyphens) in `validateCode`
- Grant trip access (save to SharedPreferences) after successful validation

**Acceptance**: All cubit tests pass, state transitions correct.

---

### Phase 4: Presentation Layer - UI (3-4 hours)

**Goal**: Create user-facing widgets and integrate with existing pages

#### 4.1 Create Code Verification Prompt

**File**: `lib/features/device_pairing/presentation/widgets/code_verification_prompt.dart`

**Widget**: Dialog shown when duplicate name detected during trip join

**Features**:
- Text field for code input (accepts with/without hyphen)
- Validation button
- Error messages display
- Loading indicator during validation

**Usage**:
```dart
showDialog(
  context: context,
  builder: (context) => CodeVerificationPrompt(
    tripId: tripId,
    memberName: memberName,
  ),
);
```

**Acceptance**: Widget displays correctly, code input works, errors shown.

---

#### 4.2 Create Code Generation Dialog

**File**: `lib/features/device_pairing/presentation/widgets/code_generation_dialog.dart`

**Widget**: Dialog shown after code is generated

**Features**:
- Display code in large, readable format
- Copy to clipboard button
- Countdown timer showing expiry
- Instructions for sharing code

**Usage**:
```dart
showDialog(
  context: context,
  builder: (context) => CodeGenerationDialog(
    code: generatedCode,
  ),
);
```

**Acceptance**: Code displayed, copy works, countdown updates every second.

---

#### 4.3 Modify TripJoinPage for Duplicate Detection

**File**: `lib/features/trips/presentation/pages/trip_join_page.dart`

**Changes**:
1. Add duplicate name check before joining:
```dart
final isDuplicate = await tripCubit.hasDuplicateMember(tripId, name);
if (isDuplicate) {
  showDialog(
    context: context,
    builder: (context) => CodeVerificationPrompt(
      tripId: tripId,
      memberName: name,
    ),
  );
  return;
}
```

2. Ensure case-insensitive matching:
```dart
bool hasDuplicateMember(String tripId, String name) {
  final trip = getTrip(tripId);
  return trip.participants.any(
    (p) => p.name.toLowerCase() == name.toLowerCase()
  );
}
```

**Acceptance**: Duplicate detection works, verification prompt shown.

---

#### 4.4 Add Code Management to TripSettingsPage

**File**: `lib/features/trips/presentation/pages/trip_settings_page.dart`

**Changes**:
1. Add "Active Device Codes" section
2. Add "Generate Code" button per member
3. Link to Active Codes page (future P3 feature)

**UI Structure**:
```
Trip Settings
├── General
├── Members
│   ├── Alice          [Generate Code]
│   ├── Bob            [Generate Code]
│   └── Charlie        [Generate Code]
└── Active Device Codes      [View All →]
```

**Acceptance**: Generate code buttons appear, tapping shows generation dialog.

---

### Phase 5: Integration & Testing (2-3 hours)

**Goal**: End-to-end testing and bug fixes

#### 5.1 Create Integration Test

**File**: `test/integration/device_pairing_flow_test.dart`

**Test Scenario**:
```dart
testWidgets('Full device pairing flow', (tester) async {
  // Device A: Generate code for Alice
  // Device B: Try to join with name Alice
  // System: Show verification prompt
  // Device B: Enter code
  // System: Grant access, navigate to trip
});
```

**Acceptance**: Full flow works without errors.

---

#### 5.2 Manual Testing Checklist

- [ ] Generate code from trip members list
- [ ] Copy code to clipboard
- [ ] Code expires after 15 minutes
- [ ] Cannot use code twice
- [ ] Cannot use expired code
- [ ] Duplicate name detection works (case-insensitive)
- [ ] Code works with/without hyphen
- [ ] Rate limiting kicks in after 5 attempts
- [ ] Network errors handled gracefully
- [ ] Validation success navigates to trip page

---

### Phase 6: Firestore Indexes (15 minutes)

**Goal**: Ensure queries perform optimally

#### 6.1 Create Required Indexes

Run these queries in Firebase Console to auto-generate indexes:

```dart
// Query 1: Find active codes for member
firestore.collection('trips')
  .doc(tripId)
  .collection('deviceLinkCodes')
  .where('memberNameLower', isEqualTo: 'alice')
  .where('used', isEqualTo: false)
  .where('expiresAt', isGreaterThan: now)
  .get();

// Query 2: List all active codes
firestore.collection('trips')
  .doc(tripId)
  .collection('deviceLinkCodes')
  .where('used', isEqualTo: false)
  .where('expiresAt', isGreaterThan: now)
  .orderBy('expiresAt')
  .get();
```

**Or Manually**: Add to `firestore.indexes.json`:
```json
{
  "indexes": [
    {
      "collectionGroup": "deviceLinkCodes",
      "queryScope": "COLLECTION_GROUP",
      "fields": [
        { "fieldPath": "tripId", "order": "ASCENDING" },
        { "fieldPath": "memberNameLower", "order": "ASCENDING" },
        { "fieldPath": "used", "order": "ASCENDING" },
        { "fieldPath": "expiresAt", "order": "DESCENDING" }
      ]
    }
  ]
}
```

**Deploy**:
```bash
firebase deploy --only firestore:indexes
```

**Acceptance**: No "index required" errors in logs.

---

## Code Utilities

### Code Generator Utility

**File**: `lib/core/utils/code_generator.dart`

```dart
import 'dart:math';

class CodeGenerator {
  static final _random = Random.secure();

  static String generate() {
    final code = _random.nextInt(100000000);
    final codeString = code.toString().padLeft(8, '0');
    return '${codeString.substring(0, 4)}-${codeString.substring(4)}';
  }

  static String normalize(String code) {
    return code.replaceAll('-', '').replaceAll(' ', '');
  }

  static bool isValid(String code) {
    final normalized = normalize(code);
    return RegExp(r'^\d{8}$').hasMatch(normalized);
  }
}
```

---

## Localization Strings

Add to `lib/l10n/app_en.arb`:

```json
{
  "devicePairingCodePromptTitle": "Verify Device",
  "devicePairingCodePromptMessage": "A member named '{name}' already exists. Enter the verification code they provided to access this trip.",
  "devicePairingCodeFieldLabel": "8-Digit Code",
  "devicePairingCodeFieldHint": "1234-5678",
  "devicePairingValidateButton": "Verify",
  "devicePairingGenerateButton": "Generate Code",
  "devicePairingCopyButton": "Copy Code",
  "devicePairingCodeCopied": "Code copied to clipboard",

  "devicePairingErrorInvalid": "Invalid or expired code",
  "devicePairingErrorExpired": "Code has expired. Request a new one from a member.",
  "devicePairingErrorUsed": "Code already used",
  "devicePairingErrorNameMismatch": "Code doesn't match your member name",
  "devicePairingErrorRateLimit": "Too many attempts. Please wait 60 seconds.",
  "devicePairingErrorNetwork": "Cannot verify code offline. Check connection.",

  "devicePairingSuccessMessage": "Device verified!",
  "devicePairingExpiresIn": "Expires in {minutes}:{seconds}",
  "devicePairingShareInstructions": "Share this code with the person trying to join on another device. It expires in 15 minutes."
}
```

Regenerate localization:
```bash
flutter pub get
```

---

## BLoC Provider Setup

Add to `main.dart`:

```dart
MultiBlocProvider(
  providers: [
    // Existing providers...
    BlocProvider(
      create: (context) => DevicePairingCubit(
        deviceLinkCodeRepository: FirestoreDeviceLinkCodeRepository(
          firestore: FirebaseFirestore.instance,
        ),
      ),
    ),
  ],
  child: MaterialApp.router(
    routerConfig: AppRouter.router,
  ),
)
```

---

## Testing Commands

```bash
# Run all tests
flutter test

# Run device pairing tests only
flutter test test/features/device_pairing/

# Run integration tests
flutter test test/integration/device_pairing_flow_test.dart

# Run with coverage
flutter test --coverage

# Run analyzer
flutter analyze
```

---

## Debugging Tips

### Check Firestore Documents

```dart
// In Firebase Console → Firestore
/trips/{tripId}/deviceLinkCodes/
// Verify:
// - code field is 9 chars (8 digits + 1 hyphen)
// - expiresAt is 15 minutes after createdAt
// - memberNameLower is lowercase version of memberName
```

### Common Issues

**Issue**: "Index required" error
**Fix**: Deploy Firestore indexes (see Phase 6)

**Issue**: Code validation always fails
**Fix**: Check server time vs client time (clock skew)

**Issue**: Duplicate detection not working
**Fix**: Ensure case-insensitive comparison (`.toLowerCase()`)

**Issue**: Transaction fails
**Fix**: Verify Firestore security rules allow updates

---

## Performance Benchmarks

| Operation | Target | Typical |
|-----------|--------|---------|
| Generate code | <2s | ~800ms |
| Validate code | <1s | ~500ms |
| Load active codes | <2s | ~400ms |
| Firestore write | <500ms | ~200ms |
| Firestore transaction | <500ms | ~300ms |

---

## Deployment Checklist

- [ ] All unit tests pass
- [ ] Integration test passes
- [ ] Firestore rules deployed
- [ ] Firestore indexes deployed
- [ ] Localization strings added
- [ ] Code reviewed
- [ ] Manual testing completed
- [ ] Performance benchmarks met
- [ ] Documentation updated

---

## Future Phase: P3 Features (Optional)

If time permits, implement:

1. **Active Codes Page**: Full-page list of active codes with revoke buttons
2. **Code Revocation**: Delete active codes before expiry
3. **Real-Time Updates**: Use Firestore streams for live code list
4. **Expiry Alerts**: Show warning when code about to expire

---

## See Also

- [Feature Spec](./spec.md)
- [Data Model](./data-model.md)
- [Contracts](./contracts/)
- [Research](./research.md)
- [Root CLAUDE.md](/CLAUDE.md)
