# Implementation Plan: Device Pairing for Multi-Device Access

**Branch**: `004-device-pairing` | **Date**: 2025-10-29 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/004-device-pairing/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

Add member-assisted device pairing via temporary 8-digit codes to solve multi-device access problem. When users try to join a trip with a duplicate name (case-insensitive), the system detects this and prompts them to request a verification code from an existing member. Existing members generate codes FOR specific member names from the trip members list. Codes expire after 15 minutes, are one-time use, and include global rate limiting (5 attempts/minute per trip) via Firestore security rules. This provides zero-cost multi-device access within the existing anonymous auth architecture.

## Technical Context

**Language/Version**: Dart 3.9.0+ / Flutter SDK 3.19.0+
**Primary Dependencies**: Firebase Core, Cloud Firestore, flutter_bloc (^8.1.6), shared_preferences (^2.3.4), flutter_localizations
**Storage**: Firestore (cloud database with real-time streams), SharedPreferences (local browser storage for membership caching)
**Testing**: flutter_test, mockito (for unit tests), integration_test (for flow testing)
**Target Platform**: Web (primary), iOS/Android (future)
**Project Type**: Flutter web application (single responsive SPA)
**Performance Goals**: <2s code generation, <1s code validation, <3min full pairing flow, zero external service costs
**Constraints**: Within Firestore free tier (<50K reads, <20K writes/day), 15-minute code expiry, anonymous auth only, no backend server
**Scale/Scope**: 1000 concurrent users, <50K Firestore operations/day, 8-digit codes (100M combinations), 5 attempts/min rate limiting

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Requirement | Feature Alignment | Status |
|-----------|-------------|-------------------|--------|
| **Test-Driven Development** | Write tests before implementation | Will write unit tests for code generation/validation logic, integration tests for full pairing flow before implementing | ✅ PASS |
| **Code Quality** | 80% test coverage for business logic | Code generation, validation, duplicate detection, rate limiting logic will have comprehensive unit tests | ✅ PASS |
| **UX Consistency** | 8px grid, 44x44px touch targets, Material Design | UI will follow existing expense tracker patterns, use standard Material widgets, 8px spacing | ✅ PASS |
| **Performance Standards** | <2s page load, <1s interactions | Code generation <2s, validation <1s per SC-001 and SC-003 | ✅ PASS |
| **Data Integrity** | Decimal for money, atomic transactions | Uses Firestore atomic operations for one-time use enforcement, timestamp-based expiry validation | ✅ PASS |

**Overall Status**: ✅ **PASSED** - All constitution principles satisfied. No violations or trade-offs required.

**Notes**:
- Feature uses existing patterns (BLoC, Firestore streams, SharedPreferences)
- No new architectural complexity introduced
- Security via Firestore rules (no custom backend needed)
- Zero external dependencies aligns with cost-consciousness

## Project Structure

### Documentation (this feature)

```
specs/004-device-pairing/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
├── checklists/          # Quality validation checklists
│   └── requirements.md
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

```
lib/features/device_pairing/
├── domain/
│   ├── models/
│   │   └── device_link_code.dart           # DeviceLinkCode entity
│   └── repositories/
│       └── device_link_code_repository.dart # Abstract repository interface
├── data/
│   └── repositories/
│       └── firestore_device_link_code_repository.dart # Firestore implementation
└── presentation/
    ├── cubits/
    │   ├── device_pairing_cubit.dart        # Business logic for code generation/validation
    │   └── device_pairing_state.dart        # State classes
    └── widgets/
        ├── code_verification_prompt.dart    # Shown when duplicate name detected
        └── code_generation_dialog.dart      # Shown when member generates code

lib/features/trips/presentation/
├── pages/
│   ├── trip_join_page.dart                  # MODIFIED: Add duplicate detection
│   └── trip_settings_page.dart              # MODIFIED: Add code management UI
└── cubits/
    └── trip_cubit.dart                      # MODIFIED: Add duplicate name check method

lib/core/
├── router/
│   └── app_router.dart                      # MODIFIED: Add device pairing routes (if needed)
└── utils/
    └── code_generator.dart                  # Utility for secure 8-digit code generation

test/features/device_pairing/
├── domain/models/
│   └── device_link_code_test.dart           # Unit tests for entity
├── data/repositories/
│   └── firestore_device_link_code_repository_test.dart  # Repository tests
├── presentation/cubits/
│   └── device_pairing_cubit_test.dart       # Cubit logic tests
└── integration/
    └── device_pairing_flow_test.dart        # End-to-end pairing flow test
```

**Structure Decision**: Flutter single-project structure with feature-based organization. The `device_pairing` feature follows the existing clean architecture pattern (domain → data → presentation) with clear separation of concerns. Integration points are modifications to existing `trip_join_page.dart` (duplicate detection trigger) and `trip_settings_page.dart` (code generation UI for members).

## Complexity Tracking

*Fill ONLY if Constitution Check has violations that must be justified*

**N/A** - No constitution violations. Feature aligns with all core principles and introduces no unnecessary complexity.

---

## Phase 0: Research Outcomes

**Document**: [research.md](./research.md)

### Technical Unknowns Resolved

All critical technical questions have been researched and resolved:

1. **Rate Limiting Implementation**: Application logic (client-side checks + Firestore tracking) via `/trips/{tripId}/validationAttempts/{timestamp}` subcollection. Implementation: record timestamp on each attempt, query last 60 seconds of attempts, block if ≥5 found. Simple, sufficient for MVP, no Firestore security rules needed
2. **Atomic One-Time Use**: Firestore transactions prevent race conditions
3. **Expired Code Cleanup**: Client-side filtering for MVP (no server infrastructure needed)
4. **Secure Code Generation**: `Random.secure()` provides 100M combinations with 8 digits
5. **Case-Insensitive Matching**: Store `memberNameLower` field for queries, client-side filter for existing participants

**Key Decisions**:
- No external dependencies required (all Firebase/Dart built-ins)
- Zero additional infrastructure costs
- Simple implementation paths for all complex operations
- **Rate Limiting**: Application logic with Firestore-backed tracking via `/trips/{tripId}/validationAttempts/{timestamp}` subcollection (not Firestore security rules)

**Risks Mitigated**:
- Brute force attacks: 8-digit codes + rate limiting + 15-min expiry = 0.000075% success rate
- Race conditions: Firestore transactions ensure atomicity
- Clock skew: Server timestamps prevent client manipulation

---

## Phase 1: Design Artifacts

### Phase 1.1: Data Model

**Document**: [data-model.md](./data-model.md)

**Key Entities**:
- `DeviceLinkCode`: 8 fields, validated, immutable after creation
- Firestore subcollection: `/trips/{tripId}/deviceLinkCodes/{autoId}`

**Schema Highlights**:
- Stores both `memberName` (original casing) and `memberNameLower` (for queries)
- Server timestamps for `createdAt`, `expiresAt`, `usedAt`
- Boolean `used` flag for one-time use enforcement
- 15-minute expiry calculated on creation

**Firestore Security Rules**:
- Anyone can read codes (brute force protected by rate limiting)
- Only trip members can create codes
- Updates restricted to marking as used (one-way state change)
- Only trip members can delete (revoke) codes

**Storage Estimates**:
- ~200 bytes per code
- Expected usage: 2000 codes/week = 400 KB/week (negligible)
- Operations: ~4-5 per validation (well within free tier)

### Phase 1.2: API Contracts

**Documents**: [contracts/](./contracts/)

Four primary operations defined:

1. **[Generate Code](./contracts/01-generate-code.md)**
   - Input: tripId, memberName
   - Output: DeviceLinkCode entity
   - Side effects: Invalidates previous codes for same member
   - Performance: <2s target

2. **[Validate Code](./contracts/02-validate-code.md)**
   - Input: tripId, code, memberName
   - Output: boolean (success/failure)
   - Side effects: Marks code as used, grants trip access
   - Performance: <1s target
   - Validation: 6 rules (exists, not expired, not used, trip matches, name matches, not rate limited)

3. **[Revoke Code](./contracts/03-revoke-code.md)** (P3)
   - Input: tripId, codeId
   - Output: void
   - Side effects: Deletes code document
   - Use case: Member-initiated cleanup

4. **[List Active Codes](./contracts/04-list-active-codes.md)** (P3)
   - Input: tripId
   - Output: List<DeviceLinkCode>
   - Filtering: Only unused, unexpired codes
   - Sorting: By expiry time (soonest first)

**Test Coverage Requirements**:
- Unit tests: All validation rules, edge cases, error handling
- Integration tests: Full pairing flow from Device A to Device B
- Contract tests: Repository interface matches implementation

### Phase 1.3: Implementation Guide

**Document**: [quickstart.md](./quickstart.md)

**Implementation Phases**:
1. Domain Layer (1-2 hours): Entities + repository interface
2. Data Layer (2-3 hours): Firestore repository + security rules
3. Presentation Layer - Cubit (2-3 hours): State management + business logic
4. Presentation Layer - UI (3-4 hours): Widgets + page modifications
5. Integration & Testing (2-3 hours): End-to-end tests + manual testing
6. Firestore Indexes (15 minutes): Deploy required indexes

**Total Estimated Time**: 11-16 hours

**Key Dependencies**:
- `dart:math` (Random.secure)
- `cloud_firestore` (database operations)
- `shared_preferences` (local trip access caching)
- `flutter_bloc` (state management)
- Existing features: Trip management, TripCubit

**Localization**: 12 new strings to add to `app_en.arb`

### Phase 1.4: Agent Context Update

**Technologies Introduced**:
- Firestore subcollections pattern (`/trips/{tripId}/deviceLinkCodes/`)
- Firestore transactions for atomic operations
- Cryptographically secure random number generation (`Random.secure()`)
- Rate limiting via application logic (not Firestore rules)
- Case-insensitive string matching with normalized fields

**Patterns to Follow**:
- Clean architecture (domain → data → presentation)
- BLoC pattern for state management
- Test-Driven Development (write tests first)
- Repository pattern for data access
- Immutable entities with `copyWith` methods

**Integration Points**:
- `TripCubit`: Add `hasDuplicateMember()` method for name checking
- `TripJoinPage`: Add duplicate detection before joining
- `TripSettingsPage`: Add "Generate Code" buttons per member
- `SharedPreferences`: Reuse existing trip membership caching

**Known Limitations**:
- Rate limiting is per-trip (global), not per-device/user
- Expired codes remain in Firestore until manually cleaned up (acceptable for MVP)
- No push notifications when code is used
- No device fingerprinting or audit trail (future enhancement)

---

## Implementation Order

### Critical Path (P1 - Must Have)

Implement in this order to maintain testability:

1. **Domain Layer**: `DeviceLinkCode` entity + validation
2. **Repository Interface**: `DeviceLinkCodeRepository` abstract class
3. **Firestore Repository**: Implementation with transactions
4. **Security Rules**: Deploy to Firestore
5. **State Management**: `DevicePairingCubit` + states
6. **UI - Verification Prompt**: Widget for entering code (Device B)
7. **UI - Generation Dialog**: Widget for displaying code (Device A)
8. **Trip Join Integration**: Add duplicate detection to `TripJoinPage`
9. **Trip Settings Integration**: Add "Generate Code" buttons to members list
10. **Integration Test**: Full flow from Device A → Device B
11. **Firestore Indexes**: Deploy required indexes

### Optional Path (P2 - Nice to Have)

12. **Rate Limiting UI**: Show attempt counter and countdown timer
13. **Error Recovery**: Retry logic for network failures

### Future Path (P3 - Can Defer)

14. **Active Codes Page**: Full-page list of active codes
15. **Code Revocation**: Delete codes before expiry
16. **Real-Time Updates**: Firestore streams for live updates

---

## Testing Strategy

### Unit Tests (Target: 80% coverage)

- **Domain**: Entity validation, business logic methods
- **Data**: Repository methods (mocked Firestore)
- **Presentation**: Cubit state transitions, error handling

**Files**:
- `test/features/device_pairing/domain/models/device_link_code_test.dart`
- `test/features/device_pairing/data/repositories/firestore_device_link_code_repository_test.dart`
- `test/features/device_pairing/presentation/cubits/device_pairing_cubit_test.dart`

### Integration Tests

- **Happy Path**: Generate code → validate code → access granted
- **Error Cases**: Expired code, used code, wrong name, rate limited
- **Duplicate Detection**: Join with duplicate name triggers verification

**Files**:
- `test/integration/device_pairing_flow_test.dart`

### Manual Testing

**Checklist**:
- [ ] Generate code from trip settings
- [ ] Copy code to clipboard works
- [ ] Code expires after 15 minutes
- [ ] Cannot use code twice
- [ ] Duplicate name detection (case-insensitive)
- [ ] Rate limiting after 5 attempts
- [ ] Network error handling
- [ ] Navigation after successful validation

---

## Deployment Requirements

### Firestore Configuration

**Security Rules**:
```bash
firebase deploy --only firestore:rules
```

**Indexes** (auto-created or manual):
```bash
firebase deploy --only firestore:indexes
```

**Estimated Operations** (1000 users, 2 devices each):
- Reads: ~4000/day (2 per validation × 2000 validations)
- Writes: ~2000/day (1 per generation + 1 per validation)
- **Total**: 6000 ops/day (well within free tier: 50K reads, 20K writes)

### App Configuration

**BLoC Provider** (add to `main.dart`):
```dart
BlocProvider(
  create: (context) => DevicePairingCubit(
    deviceLinkCodeRepository: FirestoreDeviceLinkCodeRepository(
      firestore: FirebaseFirestore.instance,
    ),
  ),
)
```

**Localization** (add to `lib/l10n/app_en.arb`):
- 12 new strings for device pairing UI
- Run `flutter pub get` to regenerate

### No External Dependencies

This feature requires **zero new packages** - all dependencies already exist:
- ✅ `cloud_firestore` (existing)
- ✅ `firebase_core` (existing)
- ✅ `flutter_bloc` (existing)
- ✅ `shared_preferences` (existing)
- ✅ `dart:math` (built-in)

---

## Success Metrics

| Metric | Target | Measurement Method |
|--------|--------|-------------------|
| Code generation time | <2s | Log timestamps in cubit |
| Code validation time | <1s | Log timestamps in cubit |
| Full pairing flow | <3min | Integration test timer |
| Brute force prevention | 100% | Rate limiting test |
| One-time use enforcement | 100% | Transaction test |
| User success rate | 95% | Track validation outcomes |
| Zero external costs | ✅ | Monitor Firestore usage |

---

## Known Limitations & Future Work

### MVP Limitations (Acceptable)

1. **No Device Management**: Users cannot view/revoke paired devices
2. **No Push Notifications**: Device A doesn't know when Device B validates
3. **Global Rate Limiting**: Rate limit applies to entire trip, not per device
4. **Manual Cleanup**: Expired codes remain in Firestore (cleaned up client-side)
5. **No Audit Trail**: No record of who generated which codes

### Future Enhancements (Post-MVP)

1. **Device Fingerprinting**: Log device type/browser for security
2. **Push Notifications**: Alert Device A when Device B successfully pairs
3. **Audit Trail**: Track code generation/usage history
4. **Biometric Confirmation**: Require fingerprint before validation
5. **QR Code Option**: Generate QR code instead of 8-digit code
6. **Custom Expiry**: Allow members to set expiry time (5/15/30 min)

---

## Conclusion

This implementation plan provides a complete roadmap for device pairing with:

- ✅ **Zero external costs** (Firestore free tier sufficient)
- ✅ **Simple implementation** (11-16 hours estimated)
- ✅ **Strong security** (rate limiting + 8-digit codes + 15-min expiry)
- ✅ **No new dependencies** (uses existing packages)
- ✅ **Testable design** (TDD approach with 80% coverage target)
- ✅ **User-friendly UX** (member-assisted verification, clear error messages)

**Recommendation**: Proceed with implementation following the critical path (P1 features). Defer P3 features to future iterations if time-constrained.

**Next Step**: Run `/speckit.tasks` to generate detailed task breakdown for implementation.

