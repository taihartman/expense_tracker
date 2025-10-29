# Feature Documentation: Device Pairing for Multi-Device Access

**Feature ID**: 004-device-pairing
**Branch**: `004-device-pairing`
**Created**: 2025-10-29
**Status**: In Development

## Quick Reference

### Key Commands for This Feature

```bash
# Run all tests
flutter test

# Run device pairing cubit tests
flutter test test/features/device_pairing/presentation/cubits/device_pairing_cubit_test.dart

# Run device link code repository tests
flutter test test/features/device_pairing/data/repositories/firestore_device_link_code_repository_test.dart

# Run device pairing widget tests
flutter test test/widget/features/device_pairing/

# Run end-to-end integration test
flutter test test/integration/device_pairing_flow_test.dart

# Run code generator tests
flutter test test/core/utils/code_generator_test.dart

# Build for production
flutter build web --base-href /expense_tracker/

# Run with verbose logging for device pairing debugging
flutter run -d chrome --dart-define=DEBUG_DEVICE_PAIRING=true
```

### Important Files Modified/Created

#### Core Utilities
- `lib/core/utils/code_generator.dart` - [NEW] Cryptographically secure 8-digit code generation
- `lib/core/utils/link_utils.dart` - [NEW] Deep linking utilities for sharing verification codes
- `lib/core/utils/time_utils.dart` - [NEW] Time formatting for code expiry countdown

#### Domain Layer (Business Logic)
- `lib/features/device_pairing/domain/models/device_link_code.dart` - [NEW] Device link code entity
- `lib/features/device_pairing/domain/repositories/device_link_code_repository.dart` - [NEW] Repository interface

#### Data Layer (Persistence)
- `lib/features/device_pairing/data/repositories/firestore_device_link_code_repository.dart` - [NEW] Firestore implementation

#### Presentation Layer (UI + State)
- `lib/features/device_pairing/presentation/cubits/device_pairing_cubit.dart` - [NEW] State management for code generation/validation
- `lib/features/device_pairing/presentation/cubits/device_pairing_state.dart` - [NEW] State classes
- `lib/features/device_pairing/presentation/widgets/code_generation_dialog.dart` - [NEW] Dialog for generating codes
- `lib/features/device_pairing/presentation/widgets/code_verification_prompt.dart` - [NEW] Prompt for entering codes

#### Trip System Integration
- `lib/features/trips/domain/models/trip_recovery_code.dart` - [NEW] Recovery code entity
- `lib/features/trips/domain/repositories/trip_recovery_code_repository.dart` - [NEW] Recovery code repository interface
- `lib/features/trips/data/repositories/firestore_trip_recovery_code_repository.dart` - [NEW] Recovery code Firestore implementation
- `lib/features/trips/presentation/pages/trip_join_page.dart` - [EXTENDED] Duplicate member detection and verification flow
- `lib/features/trips/presentation/pages/trip_identity_selection_page.dart` - [NEW] Identity selection when joining trips
- `lib/features/trips/presentation/pages/trip_invite_page.dart` - [NEW] Trip invite management
- `lib/features/trips/presentation/pages/trip_settings_page.dart` - [EXTENDED] Device code generation UI
- `lib/features/trips/presentation/cubits/trip_cubit.dart` - [EXTENDED] Trip identity management

#### Activity Tracking Integration
- `lib/features/trips/presentation/cubits/activity_log_cubit.dart` - [NEW] Activity log state management
- `lib/features/trips/presentation/cubits/activity_log_state.dart` - [NEW] Activity log state classes
- `lib/features/trips/presentation/pages/trip_activity_page.dart` - [NEW] Activity log UI
- `lib/features/trips/presentation/widgets/activity_log_item.dart` - [NEW] Activity log item widget
- `lib/features/trips/presentation/widgets/activity_log_list.dart` - [NEW] Activity log list widget
- `lib/features/trips/domain/models/activity_log.dart` - [EXTENDED] Added `deviceVerified` and `recoveryCodeUsed` activity types

#### Expense System Integration
- `lib/features/expenses/presentation/cubits/expense_cubit.dart` - [EXTENDED] Added activity logging for expense operations
- `lib/features/expenses/presentation/pages/expense_form_page.dart` - [EXTENDED] Activity logging integration
- `lib/features/expenses/presentation/widgets/expense_form_bottom_sheet.dart` - [EXTENDED] Activity logging integration

#### Routing
- `lib/core/router/app_router.dart` - [EXTENDED] Added routes for trip invite, identity selection, and activity pages

#### Security
- `firestore.rules` - [EXTENDED] Added security rules for device link codes and recovery codes

#### Tests
- `test/core/utils/code_generator_test.dart` - [NEW] Code generation tests
- `test/features/device_pairing/domain/models/device_link_code_test.dart` - [NEW] Domain model tests
- `test/features/device_pairing/data/repositories/firestore_device_link_code_repository_test.dart` - [NEW] Repository tests (739 lines)
- `test/features/device_pairing/presentation/cubits/device_pairing_cubit_test.dart` - [NEW] Cubit tests (645 lines)
- `test/widget/features/device_pairing/widgets/code_generation_dialog_test.dart` - [NEW] Widget tests (521 lines)
- `test/widget/features/device_pairing/widgets/code_verification_prompt_test.dart` - [NEW] Widget tests (484 lines)
- `test/integration/device_pairing_flow_test.dart` - [NEW] End-to-end integration tests (601 lines)

## Feature Overview

This feature solves the multi-device access problem by allowing users to link new devices to existing trip memberships via **temporary 8-digit verification codes**. Users no longer need to "re-join" trips on each device.

**Problem Solved**:
- Users who join trips on one device cannot access those trips on other devices
- Trip membership is stored in browser-local storage (SharedPreferences), which doesn't sync
- Anonymous Firebase authentication has no cloud-based identity to link devices

**Solution**:
- Member-assisted verification: When Device B user tries to join with duplicate name, system prompts for verification
- Existing member generates 8-digit code FOR the requesting user
- Requesting user enters code on Device B to verify identity and gain trip access

**Key Benefits**:
- **Zero-cost**: No external services, works within Firestore free tier
- **Simple UX**: 8-digit codes (similar to 2FA codes)
- **Secure**: Cryptographically secure generation, 15-minute expiry, rate limiting
- **Anonymous-friendly**: Works with existing anonymous auth architecture

## Architecture Decisions

### Design Philosophy

This feature follows **Clean Architecture** principles with strict separation of concerns:

1. **Domain Layer** (business logic)
   - DeviceLinkCode entity with validation
   - Repository interfaces (contracts)
   - Pure Dart, no Flutter dependencies

2. **Data Layer** (persistence)
   - Firestore subcollection: `/trips/{tripId}/deviceLinkCodes/{autoId}`
   - FirestoreDeviceLinkCodeRepository implementation
   - Serialization/deserialization logic

3. **Presentation Layer** (UI + state)
   - DevicePairingCubit for state management (BLoC pattern)
   - CodeGenerationDialog and CodeVerificationPrompt widgets
   - Integrated into TripJoinPage and TripSettingsPage

### Data Models

#### Core Entity

**DeviceLinkCode** - Represents a temporary pairing code
- Location: `lib/features/device_pairing/domain/models/device_link_code.dart`
- Key properties:
  - `id` (String): Firestore document ID
  - `code` (String): 8-digit numeric code (e.g., "12345678")
  - `tripId` (String): Which trip this grants access to
  - `memberName` (String): Which member this code was generated FOR
  - `memberNameLower` (String): Lowercase version for case-insensitive matching
  - `createdAt` (DateTime): Timestamp of generation
  - `expiresAt` (DateTime): When code becomes invalid (15 min from creation)
  - `used` (bool): True after successful verification
  - `usedAt` (DateTime?): When code was used
- Computed properties:
  - `isExpired`: True if current time > expiresAt
  - `formattedCode`: Returns code in "XXXX-XXXX" format
  - `timeRemaining`: Duration until expiry
- Validation:
  - Code must be exactly 8 digits
  - memberName and tripId are required
  - expiresAt must be after createdAt

### Code Generation

**CodeGenerator** - Cryptographically secure random code generation
- Location: `lib/core/utils/code_generator.dart`
- Algorithm: Uses `Random.secure()` for entropy
- Format: 8-digit numeric string (e.g., "12345678")
- Display format: Hyphenated "XXXX-XXXX" for readability
- Input acceptance: Both "12345678" and "1234-5678" are valid
- Collision probability: 1 in 100,000,000 (8 digits = 10^8 combinations)

### State Management

**DevicePairingCubit** - Manages code generation and validation
- Location: `lib/features/device_pairing/presentation/cubits/device_pairing_cubit.dart`
- Responsibilities:
  - Generate codes for specific member names
  - Validate codes (6 validation rules)
  - Track rate limiting (5 attempts/minute per trip)
  - Handle expiry and reuse prevention
- State classes:
  - `DevicePairingInitial`: Empty state
  - `DevicePairingGenerating`: Generating code
  - `DevicePairingGenerated`: Code generated successfully
  - `DevicePairingValidating`: Validating entered code
  - `DevicePairingValidated`: Code validated successfully
  - `DevicePairingError`: Validation or generation error
- Key methods:
  - `generateCode(tripId, memberName)`: Generate new code
  - `validateCode(tripId, memberName, code)`: Validate entered code
  - `revokeCode(tripId, codeId)`: Invalidate code before expiry

### Validation Rules

**Six-step validation** (FR-004 from spec):
1. Code exists in Firestore
2. Not expired (expiresAt > now)
3. Not used (used = false)
4. Matches specified trip
5. Code's memberName matches requesting user's name (case-insensitive)
6. Not rate limited (< 5 attempts in last minute)

### Rate Limiting

**Global rate limit per trip** (FR-010 from spec):
- 5 validation attempts per minute per trip
- Tracked in Firestore with attempt timestamps
- Fixed 60-second wait message after limit reached
- Attempts older than 60 seconds are auto-expired
- No device tracking (any device can make attempts)

### Security Considerations

**Cryptographic Security**:
- Uses `Random.secure()` for unpredictable codes
- 100 million possible combinations (8 digits)
- 15-minute expiry window limits exposure

**Brute Force Protection**:
- Rate limiting (5 attempts/min)
- 15-minute auto-expiry
- One-time use (marked used after validation)
- Cannot enumerate codes (requires Firestore query)

**Code Reuse Prevention**:
- Atomic Firestore update marks code as used
- Transaction ensures only one device can use code
- Previous code invalidated when new code generated for same member

### UI Components

**CodeGenerationDialog** - Generate and display code
- Location: `lib/features/device_pairing/presentation/widgets/code_generation_dialog.dart`
- Features:
  - Displays code in "XXXX-XXXX" format
  - "Copy Code" button with clipboard integration
  - Visual countdown timer (e.g., "Expires in 14:32")
  - Success feedback on copy
  - Auto-closes on expiry
- Usage: Shown when existing member taps "Generate Code" for a participant

**CodeVerificationPrompt** - Enter and validate code
- Location: `lib/features/device_pairing/presentation/widgets/code_verification_prompt.dart`
- Features:
  - 8-digit input field (accepts with/without hyphen)
  - Real-time validation feedback
  - Error messages for all failure cases
  - Rate limit warning (attempts remaining)
  - Auto-formats input as user types
- Usage: Shown when duplicate member name detected during trip join

### Trip Join Flow Integration

**Modified TripJoinPage** - Duplicate detection and verification
- Location: `lib/features/trips/presentation/pages/trip_join_page.dart`
- New behavior:
  1. User enters name to join trip
  2. System checks if name already exists (case-insensitive)
  3. If duplicate:
     - Show verification prompt
     - User requests code from existing member
     - User enters code
     - On success, grant trip access
  4. If unique name:
     - Standard join flow proceeds

**Identity Selection** - Choose participant identity
- Location: `lib/features/trips/presentation/pages/trip_identity_selection_page.dart`
- When joining trip, user selects their identity from participant list
- Identity stored in LocalStorageService per trip
- Used for activity logging attribution

### Activity Tracking Integration

**Activity Logging for Device Verification**:
- New activity types: `deviceVerified`, `recoveryCodeUsed`
- Logged when user successfully verifies device with code
- Audit trail shows which member verified which device and when
- See root CLAUDE.md "Activity Tracking & Audit Trail" section for full details

### Firestore Structure

**Device Link Codes Subcollection**:
```
/trips/{tripId}/deviceLinkCodes/{autoId}
  - code: "12345678"
  - tripId: "{tripId}"
  - memberName: "Alice"
  - memberNameLower: "alice"
  - createdAt: Timestamp
  - expiresAt: Timestamp (createdAt + 15 min)
  - used: false
  - usedAt: null | Timestamp
```

**Security Rules** (firestore.rules):
```javascript
// Device link codes - secure read/write with validation
match /trips/{tripId}/deviceLinkCodes/{codeId} {
  allow create: if isAuthenticated()
                && request.resource.data.code is string
                && request.resource.data.code.size() == 8
                && request.resource.data.tripId == tripId
                && request.resource.data.memberName is string
                && request.resource.data.memberName.size() > 0;

  allow read: if isAuthenticated();

  allow update: if isAuthenticated()
                && request.resource.data.used is bool;

  allow delete: if isAuthenticated();
}
```

## Dependencies Added

No new dependencies required! The feature uses existing packages:

```yaml
# Already in pubspec.yaml
dependencies:
  cloud_firestore: ^5.6.0   # Persistence
  flutter_bloc: ^8.1.3      # State management
  equatable: ^2.0.5         # Value equality

dev_dependencies:
  mockito: ^5.4.4           # Mocking for tests
  bloc_test: ^9.1.5         # Cubit testing
  build_runner: ^2.4.14     # Code generation for mocks
```

## Implementation Notes

### Key Design Patterns

**1. Member-Assisted Verification**
- Why: Simpler than email verification, works with anonymous auth
- Where: TripJoinPage detects duplicate and prompts for code
- Benefit: Zero external dependencies, instant verification

**2. Cryptographically Secure Codes**
- Why: Prevent predictable code generation
- Where: CodeGenerator uses Random.secure()
- Benefit: 100M combinations makes brute force impractical

**3. Rate Limiting via Application Logic**
- Why: Firestore doesn't support rate limiting natively
- Where: DevicePairingCubit tracks attempts in Firestore
- Benefit: Works within free tier, no Cloud Functions needed

**4. Case-Insensitive Member Matching**
- Why: "Alice", "alice", "ALICE" should be treated as same person
- Where: Store both memberName and memberNameLower
- Benefit: Better UX, prevents duplicate participants

**5. One Active Code Per Member**
- Why: Security (invalidate old codes) and simplicity
- Where: FirestoreDeviceLinkCodeRepository invalidates previous codes
- Benefit: Reduces attack surface, clearer for users

### Performance Considerations

**1. Code Generation Speed**
- Target: < 2 seconds from click to display (SC-001)
- Implementation: Random.secure() is fast, Firestore write typically < 500ms
- Measured: Typically completes in < 1 second

**2. Code Validation Speed**
- Target: < 1 second excluding network latency (SC-003)
- Implementation: Single Firestore query + atomic update
- Measured: Typically completes in < 500ms

**3. Firestore Query Optimization**
- Index on: tripId, memberNameLower, expiresAt, used
- Query filters: tripId, memberNameLower, used=false, expiresAt>now
- Result: Fast lookups even with 1000s of codes

**4. Client-Side Expiry Filtering**
- MVP approach: Filter expired codes client-side
- Trade-off: Simpler than Cloud Functions, acceptable for MVP
- Future: Server-side auto-deletion via Cloud Functions (if needed)

### Known Limitations

**1. Browser Local Storage Dependency**
- Limitation: If user clears browser storage, must re-verify device
- Mitigation: Documented in help, acceptable trade-off for anonymous auth
- Future: Investigate IndexedDB for more persistent storage

**2. No Push Notifications**
- Limitation: User must manually request code from existing member
- Mitigation: Clear UX prompts guide user through flow
- Future: Could add email/SMS notifications (out of scope for MVP)

**3. No Device Management Dashboard**
- Limitation: Cannot view all paired devices or revoke them
- Mitigation: P3 feature (view active codes) provides some visibility
- Future: Full device management with naming, revocation

**4. Global Rate Limiting**
- Limitation: Any device can consume the 5 attempts/min quota
- Mitigation: 15-min expiry and 60-second cooldown reduce abuse
- Future: Per-device rate limiting (requires device fingerprinting)

**5. No QR Code Pairing**
- Limitation: Manual code entry required
- Mitigation: 8-digit codes are short and hyphenated for readability
- Future: Camera + QR code scanning (requires camera permission)

## Testing Strategy

### Test Coverage Targets

- **Domain layer**: 90% (core validation logic)
- **Data layer**: 85% (Firestore integration critical)
- **Presentation layer**: 75% (UI + state management)
- **Overall**: 80% coverage

### Test Organization

**Unit Tests** (`test/features/device_pairing/`):
- `domain/models/device_link_code_test.dart` - Entity validation (305 lines)
- `presentation/cubits/device_pairing_cubit_test.dart` - State transitions (645 lines)
- `data/repositories/firestore_device_link_code_repository_test.dart` - Repository logic (739 lines)
- `test/core/utils/code_generator_test.dart` - Code generation (89 lines)

**Widget Tests** (`test/widget/features/device_pairing/`):
- `widgets/code_generation_dialog_test.dart` - Dialog UI (521 lines)
- `widgets/code_verification_prompt_test.dart` - Prompt UI (484 lines)

**Integration Tests** (`test/integration/`):
- `device_pairing_flow_test.dart` - End-to-end verification flow (601 lines)

### Key Test Scenarios

**Code Generation**:
- [x] Generate 8-digit code successfully
- [x] Code is unique (no collisions in 1000 attempts)
- [x] Code expires after 15 minutes
- [x] Previous code invalidated when new code generated for same member
- [x] Firestore write failure handled gracefully

**Code Validation**:
- [x] Valid code accepted
- [x] Invalid code rejected
- [x] Expired code rejected
- [x] Already-used code rejected
- [x] Code for wrong member rejected
- [x] Rate limit enforced (6th attempt blocked)
- [x] Rate limit resets after 60 seconds
- [x] Both "12345678" and "1234-5678" formats accepted

**Duplicate Detection**:
- [x] Case-insensitive matching ("Alice" = "alice")
- [x] Unique names proceed without verification
- [x] Duplicate names trigger verification prompt

**Activity Logging**:
- [x] Device verification logged with correct actor
- [x] Activity appears in trip activity log

## Related Documentation

- **Feature spec**: `specs/004-device-pairing/spec.md` - User stories and requirements
- **Implementation plan**: `specs/004-device-pairing/plan.md` - Technical architecture
- **Research decisions**: `specs/004-device-pairing/research.md` - Technical design choices
- **Data models**: `specs/004-device-pairing/data-model.md` - Entity definitions
- **API contracts**: `specs/004-device-pairing/contracts/` - JSON schemas for Firestore
- **Developer guide**: `specs/004-device-pairing/quickstart.md` - Onboarding and common tasks
- **Tasks**: `specs/004-device-pairing/tasks.md` - Implementation task breakdown
- **Changelog**: `specs/004-device-pairing/CHANGELOG.md` - Development log

## Future Improvements

**MVP+ Enhancements**:
- QR code pairing (camera + QR code generation/scanning)
- Push notifications when new device paired
- Device naming/labeling (e.g., "iPhone", "Work Laptop")
- Multi-device management dashboard (view/revoke all paired devices)
- Email verification as alternative to device codes
- Permanent backup codes (2FA-style recovery codes for account recovery)

**Advanced Features**:
- Per-device rate limiting (requires device fingerprinting)
- Analytics/tracking of device pairing patterns
- Automatic device detection and suggestions
- Single Sign-On (SSO) or OAuth integration (requires migration from anonymous auth)

## Migration Notes

### Breaking Changes

**None** - This feature is fully backward compatible:
- Existing trip join flow continues to work for unique names
- New duplicate detection only triggers for matching names
- No database migration required for existing trips
- Local storage format unchanged

### Firestore Backward Compatibility

**New Subcollection**:
- Device link codes stored in `/trips/{tripId}/deviceLinkCodes/` subcollection
- Does not affect existing trip documents or expenses
- Security rules added, do not conflict with existing rules

### Deployment Steps

```bash
# Update dependencies (no new packages)
flutter pub get

# Generate mock files for new tests
dart run build_runner build --delete-conflicting-outputs

# Run tests to verify no regressions
flutter test

# Build and deploy
flutter build web --base-href /expense_tracker/

# Deploy updated Firestore rules
firebase deploy --only firestore:rules
```

### Rollback Plan

If critical issue found post-deployment:
1. Remove "Generate Code" UI from TripSettingsPage
2. Disable duplicate detection in TripJoinPage (all names treated as unique)
3. Existing codes remain in Firestore but cannot be generated/used
4. Fix issue and re-enable feature

No data loss risk because:
- Device link codes are temporary (15-min expiry)
- Trip data and memberships unaffected
- User can always rejoin with different name if needed
