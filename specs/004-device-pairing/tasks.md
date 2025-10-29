# Tasks: Device Pairing for Multi-Device Access

**Input**: Design documents from `/specs/004-device-pairing/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md

**Tests**: Test-Driven Development required per constitution - tests written BEFORE implementation

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`
- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions
- Flutter single-project structure
- Feature: `lib/features/device_pairing/`
- Tests: `test/features/device_pairing/`
- Integration: `test/integration/`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and basic structure

- [X] T001 Create feature directory structure: lib/features/device_pairing/{domain,data,presentation}/{models,repositories,cubits,widgets}
- [X] T002 Create test directory structure: test/features/device_pairing/{domain,data,presentation}/{models,repositories,cubits}
- [X] T003 [P] Create code generator utility in lib/core/utils/code_generator.dart
- [X] T004 [P] Add localization strings to lib/l10n/app_en.arb (17 device pairing strings)
- [X] T005 Regenerate localization files with flutter pub get

**Checkpoint**: Project structure ready for feature development

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core domain and data infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

### Tests for Foundation

- [X] T006 [P] Unit tests for DeviceLinkCode entity validation in test/features/device_pairing/domain/models/device_link_code_test.dart
- [X] T007 [P] Unit tests for CodeGenerator utility in test/core/utils/code_generator_test.dart

### Implementation for Foundation

- [X] T008 [P] Create DeviceLinkCode entity with validation in lib/features/device_pairing/domain/models/device_link_code.dart
- [X] T009 [P] Implement CodeGenerator.generate(), .normalize(), .isValid() in lib/core/utils/code_generator.dart
- [X] T010 Create DeviceLinkCodeRepository interface in lib/features/device_pairing/domain/repositories/device_link_code_repository.dart
- [X] T011 Create FirestoreDeviceLinkCodeRepository skeleton in lib/features/device_pairing/data/repositories/firestore_device_link_code_repository.dart
- [X] T012 Add Firestore security rules for /trips/{tripId}/deviceLinkCodes in firestore.rules
- [ ] T013 Deploy Firestore security rules with firebase deploy --only firestore:rules (manual step when ready to test)
- [X] T014 Create DevicePairingState classes in lib/features/device_pairing/presentation/cubits/device_pairing_state.dart
- [X] T015 Create DevicePairingCubit skeleton in lib/features/device_pairing/presentation/cubits/device_pairing_cubit.dart
- [X] T016 Add DevicePairingCubit to BLoC providers in lib/main.dart

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - Detect Duplicate Member & Request Verification (Priority: P1) 🎯 MVP Start

**Goal**: Detect when user tries to join with duplicate name (case-insensitive) and show verification prompt

**Independent Test**: Try to join trip with existing member name → See verification prompt with code entry field

### Tests for User Story 1

**NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [X] T017 [P] [US1] Unit test for TripCubit.hasDuplicateMember() case-insensitive matching in test/features/trips/presentation/cubits/trip_cubit_test.dart
- [X] T018 [P] [US1] Widget test for CodeVerificationPrompt display in test/features/device_pairing/presentation/widgets/code_verification_prompt_test.dart
- [X] T018a [P] [US1] Widget test for CodeVerificationPrompt cancel button functionality in test/features/device_pairing/presentation/widgets/code_verification_prompt_test.dart
- [X] T019 [P] [US1] Integration test for duplicate detection flow in test/integration/device_pairing_flow_test.dart

### Implementation for User Story 1

- [X] T020 [US1] Add hasDuplicateMember(tripId, name) method to TripCubit in lib/features/trips/presentation/cubits/trip_cubit.dart
- [X] T021 [US1] Create CodeVerificationPrompt widget (placeholder for validation) in lib/features/device_pairing/presentation/widgets/code_verification_prompt.dart
- [X] T022 [US1] Modify TripJoinPage to detect duplicates and show CodeVerificationPrompt in lib/features/trips/presentation/pages/trip_join_page.dart
- [X] T023 [US1] Add cancel button to CodeVerificationPrompt that returns to join form
- [X] T024 [US1] Test: Join with unique name bypasses verification, join with duplicate name shows prompt

**Checkpoint**: At this point, duplicate detection works and verification prompt is shown (validation not yet functional)

---

## Phase 4: User Story 2 - Generate Code for Requesting Member (Priority: P1) 🎯 MVP Core

**Goal**: Existing member can generate 8-digit code for specific member name

**Independent Test**: Navigate to trip settings → Tap member → Click "Generate Code" → See code displayed with copy button

### Tests for User Story 2

- [ ] T025 [P] [US2] Unit tests for FirestoreDeviceLinkCodeRepository.generateCode() in test/features/device_pairing/data/repositories/firestore_device_link_code_repository_test.dart
- [ ] T026 [P] [US2] Unit tests for DevicePairingCubit.generateCode() state transitions in test/features/device_pairing/presentation/cubits/device_pairing_cubit_test.dart
- [ ] T027 [P] [US2] Test that previous codes are invalidated when new code generated for same member
- [ ] T028 [P] [US2] Widget test for CodeGenerationDialog display and copy button in test/features/device_pairing/presentation/widgets/code_generation_dialog_test.dart
- [ ] T028a [P] [US2] Widget test for clipboard copy functionality in test/features/device_pairing/presentation/widgets/code_generation_dialog_test.dart

### Implementation for User Story 2

- [ ] T029 [P] [US2] Implement generateCode() in FirestoreDeviceLinkCodeRepository with code invalidation logic
- [ ] T030 [US2] Implement DevicePairingCubit.generateCode() with error handling
- [ ] T031 [P] [US2] Create CodeGenerationDialog widget with code display, copy button, countdown timer in lib/features/device_pairing/presentation/widgets/code_generation_dialog.dart
- [ ] T032 [US2] Add "Generate Code" button per member in TripSettingsPage members list in lib/features/trips/presentation/pages/trip_settings_page.dart
- [ ] T033 [US2] Wire up generate button to show CodeGenerationDialog
- [ ] T034 [US2] Implement clipboard copy functionality in CodeGenerationDialog
- [ ] T035 [US2] Test: Generated code is 8 digits, format XXXX-XXXX, copy works, countdown timer shows 15 min expiry (FR-016)

**Checkpoint**: At this point, members can generate codes that will expire in 15 minutes (validation not yet functional)

---

## Phase 5: User Story 3 - Verify Using Received Code (Priority: P1) 🎯 MVP Complete

**Goal**: User enters received code to complete device pairing and gain trip access

**Independent Test**: Enter valid code in verification prompt → Trip access granted, navigate to trip page

### Tests for User Story 3

- [ ] T036 [P] [US3] Unit tests for FirestoreDeviceLinkCodeRepository.validateCode() with all 6 validation rules in test/features/device_pairing/data/repositories/firestore_device_link_code_repository_test.dart
- [ ] T037 [P] [US3] Test Firestore transaction ensures one-time use (atomic marking as used)
- [ ] T038 [P] [US3] Unit tests for DevicePairingCubit.validateCode() with all error scenarios in test/features/device_pairing/presentation/cubits/device_pairing_cubit_test.dart
- [ ] T039 [P] [US3] Test case-insensitive member name matching in validation
- [ ] T040 [P] [US3] Test code normalization (hyphen optional)
- [ ] T040a [P] [US3] Unit test for _grantTripAccess() SharedPreferences caching in test/features/device_pairing/presentation/cubits/device_pairing_cubit_test.dart
- [ ] T041 [P] [US3] Integration test for full pairing flow: generate on Device A, validate on Device B in test/integration/device_pairing_flow_test.dart

### Implementation for User Story 3

- [ ] T042 [US3] Implement validateCode() in FirestoreDeviceLinkCodeRepository with Firestore transaction
- [ ] T043 [US3] Add 6 validation rules: code exists, not expired, not used, trip matches, name matches (case-insensitive), not rate limited (placeholder)
- [ ] T044 [US3] Implement DevicePairingCubit.validateCode() with error handling
- [ ] T045 [US3] Implement _grantTripAccess() to save tripId to SharedPreferences
- [ ] T046 [US3] Wire CodeVerificationPrompt to call cubit.validateCode() on submit
- [ ] T047 [US3] Add error message display to CodeVerificationPrompt for all validation failures
- [ ] T048 [US3] Implement navigation to trip page after successful validation
- [ ] T049 [US3] Test all error scenarios: invalid code, expired, already used, name mismatch, offline

**Checkpoint**: At this point, FULL MVP is functional - users can pair devices end-to-end (rate limiting placeholder)

---

## Phase 6: User Story 4 - Security - Rate Limiting (Priority: P2)

**Goal**: Prevent brute force attacks with 5 attempts/minute rate limiting

**Independent Test**: Make 6 validation attempts in quick succession → 6th attempt shows "Too many attempts" error

### Tests for User Story 4

- [ ] T050 [P] [US4] Unit test for rate limiting check logic in test/features/device_pairing/presentation/cubits/device_pairing_cubit_test.dart
- [ ] T051 [P] [US4] Test that attempt counter resets after 60 seconds
- [ ] T052 [P] [US4] Integration test for rate limiting enforcement in test/integration/device_pairing_flow_test.dart

### Implementation for User Story 4

- [ ] T053 [P] [US4] Create validationAttempts subcollection structure in Firestore
- [ ] T054 [US4] Implement _isRateLimited() check in DevicePairingCubit
- [ ] T055 [US4] Implement _recordAttempt() to track validation attempts
- [ ] T056 [US4] Add rate limit check to validateCode() before Firestore query
- [ ] T057 [US4] Add rate limit error message to localization (FR-011: "Too many attempts. Please wait 60 seconds before trying again")
- [ ] T058 [US4] Test: 5 failed attempts pass, 6th fails with error, after 60s can try again

**Checkpoint**: At this point, brute force attacks are prevented (production-ready security)

---

## Phase 7: User Story 5 - View Active Codes (Priority: P3)

**Goal**: Trip members can view all active codes and revoke them

**Independent Test**: Navigate to Active Codes page → See list of unexpired codes with expiry countdown and revoke buttons

### Tests for User Story 5

- [ ] T059 [P] [US5] Unit tests for FirestoreDeviceLinkCodeRepository.getActiveCodes() filtering in test/features/device_pairing/data/repositories/firestore_device_link_code_repository_test.dart
- [ ] T060 [P] [US5] Unit tests for FirestoreDeviceLinkCodeRepository.revokeCode() in test/features/device_pairing/data/repositories/firestore_device_link_code_repository_test.dart
- [ ] T061 [P] [US5] Unit tests for DevicePairingCubit.loadActiveCodes() and .revokeCode() in test/features/device_pairing/presentation/cubits/device_pairing_cubit_test.dart
- [ ] T062 [P] [US5] Widget test for ActiveCodesPage display in test/features/device_pairing/presentation/pages/active_codes_page_test.dart

### Implementation for User Story 5

- [ ] T063 [P] [US5] Implement getActiveCodes() in FirestoreDeviceLinkCodeRepository with filtering and sorting
- [ ] T064 [P] [US5] Implement revokeCode() in FirestoreDeviceLinkCodeRepository
- [ ] T065 [US5] Implement DevicePairingCubit.loadActiveCodes() and .revokeCode()
- [ ] T066 [US5] Create ActiveCodesPage with ListView of codes in lib/features/device_pairing/presentation/pages/active_codes_page.dart
- [ ] T067 [US5] Create ActiveCodeListTile widget with expiry countdown in lib/features/device_pairing/presentation/widgets/active_code_list_tile.dart
- [ ] T068 [US5] Add revoke button with confirmation dialog to each list item
- [ ] T069 [US5] Add "Active Device Codes" link in TripSettingsPage
- [ ] T070 [US5] Test: Active codes load, countdown updates, revoke works, empty state shows "No active codes"

**Checkpoint**: All user stories complete and independently functional

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories

- [ ] T071 [P] Create Firestore indexes for deviceLinkCodes queries: composite index on (used, expiresAt) for active codes filtering, single-field index on memberNameLower for case-insensitive queries (manual or auto-generated)
- [ ] T072 Deploy Firestore indexes with firebase deploy --only firestore:indexes
- [ ] T073 [P] Add expired code cleanup utility (client-side filtering per FR-017)
- [ ] T074 [P] Performance testing: Verify <2s code generation (SC-001), <1s code validation (SC-003), and 80% test coverage for business logic (Constitution requirement)
- [ ] T075 [P] Run flutter analyze and fix any linter warnings
- [ ] T076 [P] Run flutter format . to format all code
- [ ] T077 Code review: Verify all localization strings used (no hardcoded text)
- [ ] T078 Manual testing with quickstart.md checklist
- [ ] T079 [P] Update feature CLAUDE.md documentation with `/docs.update`
- [ ] T080 Create feature CHANGELOG.md entry with `/docs.log`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3-7)**: All depend on Foundational phase completion
  - US1 (Duplicate Detection): Can start after Foundational - No dependencies on other stories
  - US2 (Generate Code): Can start after Foundational - No dependencies on other stories
  - US3 (Validate Code): Depends on US2 (needs generateCode working) - Can test independently with pre-generated codes
  - US4 (Rate Limiting): Depends on US3 (enhances validation) - Can test independently with validation attempts
  - US5 (View Active Codes): Depends on US2 (needs codes to list) - Can test independently with pre-generated codes
- **Polish (Phase 8)**: Depends on all desired user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2) - Independently testable
- **User Story 2 (P1)**: Can start after Foundational (Phase 2) - Independently testable
- **User Story 3 (P1)**: Logical dependency on US2 for full flow, but can test with manually created codes - Independently testable
- **User Story 4 (P2)**: Enhances US3, can be tested independently by making multiple attempts - Independently testable
- **User Story 5 (P3)**: Uses US2 codes, can be tested independently with pre-generated codes - Independently testable

### Within Each User Story

- Tests MUST be written and FAIL before implementation
- Models/utilities before services/repositories
- Services/repositories before cubits
- Cubits before UI widgets
- Core implementation before integration
- Story complete before moving to next priority

### Parallel Opportunities

**Setup Phase**:
- T003 (CodeGenerator utility) and T004 (localization) can run in parallel

**Foundational Phase**:
- T006 and T007 (tests) can run in parallel
- T008 and T009 (entities/utils) can run in parallel after tests written
- T012 (security rules) can run in parallel with code tasks

**User Story Tests** (per story):
- All test files for a story can be written in parallel

**User Story Implementation** (per story):
- Models/utilities can run in parallel
- Widgets can run in parallel after cubit is done

**Cross-Story Parallelization**:
- Once Foundational completes, US1 and US2 can be developed in parallel by different developers
- US3, US4, US5 can be worked on in parallel if team capacity allows (though US3 benefits from US2 being done)

**Polish Phase**:
- T071, T073, T074, T075, T076, T079, T080 all marked [P] - can run in parallel

---

## Parallel Example: User Story 2 (Generate Code)

```bash
# Launch all tests for User Story 2 together:
Task: T025 "Unit tests for generateCode() repository method"
Task: T026 "Unit tests for generateCode() cubit state transitions"
Task: T027 "Test code invalidation logic"
Task: T028 "Widget test for CodeGenerationDialog"

# After tests written and failing, launch implementation in parallel:
Task: T029 "Implement generateCode() in repository"
Task: T031 "Create CodeGenerationDialog widget"
# (T030 depends on T029 completing, so runs after)
```

---

## Parallel Example: Polish Phase

```bash
# Launch all polish tasks together:
Task: T071 "Create Firestore indexes"
Task: T073 "Add expired code cleanup"
Task: T074 "Performance testing"
Task: T075 "Run flutter analyze"
Task: T076 "Run flutter format"
Task: T079 "Update CLAUDE.md"
Task: T080 "Create CHANGELOG entry"
```

---

## Implementation Strategy

### MVP First (User Stories 1, 2, 3 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL - blocks all stories)
3. Complete Phase 3: User Story 1 (Duplicate Detection)
4. Complete Phase 4: User Story 2 (Generate Code)
5. Complete Phase 5: User Story 3 (Validate Code)
6. **STOP and VALIDATE**: Test full pairing flow independently
7. Deploy/demo if ready - **FUNCTIONAL MVP**

**Estimated Time**: 11-13 hours for P1 stories

### Incremental Delivery (Add Security)

8. Complete Phase 6: User Story 4 (Rate Limiting)
9. **STOP and VALIDATE**: Test brute force protection
10. Deploy/demo - **PRODUCTION-READY**

**Estimated Time**: +2 hours

### Full Feature (Add Management UI)

11. Complete Phase 7: User Story 5 (View Active Codes)
12. Complete Phase 8: Polish
13. **FINAL VALIDATION**: Run all integration tests
14. Deploy - **COMPLETE FEATURE**

**Estimated Time**: +3 hours

### Parallel Team Strategy

With multiple developers:

1. Team completes Setup + Foundational together (Phases 1-2)
2. Once Foundational is done:
   - Developer A: User Story 1 (Duplicate Detection)
   - Developer B: User Story 2 (Generate Code)
   - Developer C: User Story 3 (Validate Code) - starts after US2 tasks T029-T031 complete
3. Stories complete and integrate independently
4. Team reconvenes for User Story 4 (Rate Limiting) together
5. Developer D: User Story 5 (View Active Codes) while others do polish

---

## Test-Driven Development Checklist

Per Constitution requirement, tests MUST be written before implementation:

**For Each User Story**:
1. ✅ Write all unit tests for that story (they FAIL)
2. ✅ Write all widget tests for that story (they FAIL)
3. ✅ Write integration test for that story (it FAILS)
4. ✅ Run tests and confirm all FAIL appropriately
5. ✅ Implement code to make tests PASS
6. ✅ Run tests again and confirm all PASS
7. ✅ Refactor if needed while keeping tests green
8. ✅ Move to next story

**Target Coverage**: 80% for business logic (code generation, validation, duplicate detection, rate limiting)

---

## Notes

- [P] tasks = different files, no dependencies within their phase
- [Story] label maps task to specific user story for traceability
- Each user story should be independently completable and testable
- Verify tests fail before implementing
- Commit after each task or logical group of parallel tasks
- Stop at any checkpoint to validate story independently
- US1+US2+US3 form the MVP (11-13 hours estimated)
- US4 adds production security (2 hours)
- US5 adds management UI (3 hours)
- Total: 16-18 hours for complete feature

---

## Task Summary

**Total Tasks**: 83 (updated from 80 - added 3 test tasks for TDD compliance)
- Setup: 5 tasks
- Foundational: 11 tasks
- User Story 1 (P1): 9 tasks (4 tests + 5 implementation)
- User Story 2 (P1): 12 tasks (5 tests + 7 implementation)
- User Story 3 (P1): 15 tasks (7 tests + 8 implementation)
- User Story 4 (P2): 9 tasks (3 tests + 6 implementation)
- User Story 5 (P3): 12 tasks (4 tests + 8 implementation)
- Polish: 10 tasks

**Parallel Opportunities**: 38 tasks marked [P] can run in parallel within their phases

**Independent Test Criteria**:
- US1: Try to join with duplicate name → See verification prompt ✅
- US2: Generate code from settings → See code with copy button ✅
- US3: Enter valid code → Gain trip access ✅
- US4: Make 6 attempts → 6th blocked ✅
- US5: View active codes page → See list with revoke buttons ✅

**Suggested MVP Scope**: Phases 1-5 (User Stories 1, 2, 3) = Full device pairing functionality
