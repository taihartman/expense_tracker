# Tasks: Trip Invite System

**Input**: Design documents from `/specs/003-trip-invite-system/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/

**Tests**: ✅ INCLUDED - TDD is NON-NEGOTIABLE per project constitution

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`
- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions
- Flutter project: `lib/` for source code, `test/` for tests
- Feature-driven architecture: `lib/features/{feature}/domain|data|presentation`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and localization strings

- [ ] T001 [P] Add localization strings for trip invite system in lib/l10n/app_en.arb (tripJoinTitle, tripJoinCodeLabel, tripJoinNameLabel, tripJoinButton, tripJoinInvalidCode, tripJoinAlreadyMember, tripInviteTitle, tripInviteCodeLabel, tripInviteCopyButton, tripInviteShareButton, tripInviteCodeCopied, tripInviteShareMessage, activityLogTitle, activityLogEmpty)
- [ ] T002 [P] Add localization strings for activity log types in lib/l10n/app_en.arb (activityTripCreated, activityMemberJoined, activityExpenseAdded, activityExpenseEdited, activityExpenseDeleted)
- [ ] T003 [P] Add LocalStorageService methods for joined trip IDs in lib/core/services/local_storage_service.dart (addJoinedTrip, getJoinedTripIds, removeJoinedTrip)
- [ ] T004 Run flutter pub get to regenerate localization files

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core domain models and repositories that ALL user stories depend on

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [ ] T005 [P] Create ActivityType enum in lib/features/trips/domain/models/activity_log.dart (tripCreated, memberJoined, expenseAdded, expenseEdited, expenseDeleted)
- [ ] T006 [P] Create ActivityLog domain model in lib/features/trips/domain/models/activity_log.dart (id, tripId, actorName, type, description, timestamp, metadata)
- [ ] T007 [P] Create ActivityLogModel data model with JSON serialization in lib/features/trips/data/models/activity_log_model.dart (fromJson, toJson, fromFirestore, toFirestore)
- [ ] T008 Create ActivityLogRepository interface in lib/features/trips/domain/repositories/activity_log_repository.dart (addLog, getActivityLogs stream)
- [ ] T009 Implement ActivityLogRepositoryImpl in lib/features/trips/data/repositories/activity_log_repository_impl.dart (Firestore subcollection operations)
- [ ] T010 Update Firestore security rules in firestore.rules (add activityLog subcollection rules: allow read for members, allow create for members with server timestamp, deny update/delete)
- [ ] T011 Deploy Firestore security rules using firebase deploy --only firestore:rules

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 4 - Create Private Trip (Priority: P1) 🎯 FOUNDATION

**Goal**: Users can create trips that are private by default, with creator automatically added as first member

**Independent Test**: Create a trip and verify only creator can access it, and it doesn't appear in other users' trip lists

### Tests for User Story 4 (TDD - Write FIRST)

**NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [ ] T012 [P] [US4] Unit test for TripCubit.createTrip adds creator as participant in test/features/trips/presentation/cubits/trip_cubit_test.dart
- [ ] T013 [P] [US4] Unit test for TripCubit.createTrip logs trip_created activity in test/features/trips/presentation/cubits/trip_cubit_test.dart
- [ ] T014 [P] [US4] Unit test for TripCubit.createTrip caches joined trip ID in test/features/trips/presentation/cubits/trip_cubit_test.dart
- [ ] T015 [P] [US4] Unit test for TripCubit.loadTrips filters to joined trips only in test/features/trips/presentation/cubits/trip_cubit_test.dart
- [ ] T016 [P] [US4] Integration test for create trip flow in test/integration/trip_create_flow_test.dart

### Implementation for User Story 4

- [ ] T017 [US4] Modify TripCubit constructor to accept ActivityLogRepository in lib/features/trips/presentation/cubits/trip_cubit.dart
- [ ] T018 [US4] Add _getCurrentUserName helper method to TripCubit in lib/features/trips/presentation/cubits/trip_cubit.dart (checks LocalStorageService for saved name, prompts if not found)
- [ ] T019 [US4] Modify TripCubit.createTrip to add creator as first participant in lib/features/trips/presentation/cubits/trip_cubit.dart
- [ ] T020 [US4] Modify TripCubit.createTrip to log trip_created activity in lib/features/trips/presentation/cubits/trip_cubit.dart
- [ ] T021 [US4] Modify TripCubit.createTrip to cache joined trip ID locally in lib/features/trips/presentation/cubits/trip_cubit.dart
- [ ] T022 [US4] Modify TripCubit.loadTrips to filter trips to only joined trip IDs in lib/features/trips/presentation/cubits/trip_cubit.dart
- [ ] T023 [US4] Add getJoinedTripIds method to TripCubit in lib/features/trips/presentation/cubits/trip_cubit.dart
- [ ] T023b [US4] Modify TripCreatePage to add name input field in lib/features/trips/presentation/pages/trip_create_page.dart (1-50 characters validation, required field for trip creator name)
- [ ] T024 [US4] Update main.dart to pass ActivityLogRepository to TripCubit in lib/main.dart
- [ ] T025 [US4] Verify tests pass for User Story 4

**Checkpoint**: User Story 4 complete - trips are now private by default, creator is first member

---

## Phase 4: User Story 1 - Join Trip via Invite Code (Priority: P1) 🎯 MVP CORE

**Goal**: Users can join trips by entering an invite code and providing their name

**Independent Test**: Create a trip, get invite code, join it by entering code, verify added to members

### Tests for User Story 1 (TDD - Write FIRST)

**NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [ ] T026 [P] [US1] Unit test for TripCubit.joinTrip adds participant and logs activity in test/features/trips/presentation/cubits/trip_cubit_test.dart
- [ ] T027 [P] [US1] Unit test for TripCubit.joinTrip is idempotent (already member) in test/features/trips/presentation/cubits/trip_cubit_test.dart
- [ ] T028 [P] [US1] Unit test for TripCubit.joinTrip handles trip not found in test/features/trips/presentation/cubits/trip_cubit_test.dart
- [ ] T029 [P] [US1] Unit test for TripCubit.isUserMemberOf checks local cache in test/features/trips/presentation/cubits/trip_cubit_test.dart
- [ ] T030 [P] [US1] Widget test for TripJoinPage renders form in test/features/trips/presentation/pages/trip_join_page_test.dart
- [ ] T031 [P] [US1] Widget test for TripJoinPage shows error for invalid code in test/features/trips/presentation/pages/trip_join_page_test.dart
- [ ] T032 [P] [US1] Integration test for join trip via code flow in test/integration/trip_join_flow_test.dart

### Implementation for User Story 1

- [ ] T033 [US1] Add TripJoining, TripJoined, TripJoinError states to TripState in lib/features/trips/presentation/cubits/trip_state.dart
- [ ] T034 [US1] Add joinTrip method to TripCubit in lib/features/trips/presentation/cubits/trip_cubit.dart (validate trip exists, check if already member, add participant, log activity, cache locally, select trip)
- [ ] T035 [US1] Add isUserMemberOf method to TripCubit in lib/features/trips/presentation/cubits/trip_cubit.dart (check local cache)
- [ ] T036 [P] [US1] Create TripJoinPage UI in lib/features/trips/presentation/pages/trip_join_page.dart (code input field, name input field, join button, error display)
- [ ] T037 [P] [US1] Add validation to TripJoinPage in lib/features/trips/presentation/pages/trip_join_page.dart (code required, name required 1-50 chars)
- [ ] T038 [US1] Add BlocListener for TripCubit states in TripJoinPage in lib/features/trips/presentation/pages/trip_join_page.dart (navigate on TripJoined, show error on TripJoinError)
- [ ] T039 [US1] Add /trips/join route to app_router.dart in lib/core/router/app_router.dart
- [ ] T040 [US1] Add "Join Trip" floating action button to TripListPage in lib/features/trips/presentation/pages/trip_list_page.dart
- [ ] T041 [US1] Verify tests pass for User Story 1

**Checkpoint**: User Story 1 complete - users can join trips via manual code entry

---

## Phase 5: User Story 2 - Share Trip via Link (Priority: P1) 🎯 MVP ENHANCEMENT

**Goal**: Users can join trips with one click via shareable links (deep linking)

**Independent Test**: Generate shareable link, click it, verify it navigates to join page with code pre-filled

### Tests for User Story 2 (TDD - Write FIRST)

**NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [ ] T042 [P] [US2] Widget test for TripJoinPage pre-fills code when provided via deep link in test/features/trips/presentation/pages/trip_join_page_test.dart
- [ ] T043 [P] [US2] Integration test for deep link navigation in test/integration/trip_join_flow_test.dart (simulate clicking link, verify navigates to join page with code)
- [ ] T044 [P] [US2] Unit test for generateShareableLink helper in test/core/utils/link_utils_test.dart

### Implementation for User Story 2

- [ ] T045 [P] [US2] Modify TripJoinPage constructor to accept optional inviteCode parameter in lib/features/trips/presentation/pages/trip_join_page.dart
- [ ] T046 [US2] Modify TripJoinPage to pre-fill code field when inviteCode provided in lib/features/trips/presentation/pages/trip_join_page.dart
- [ ] T047 [US2] Add /trips/:tripId/join route to app_router.dart in lib/core/router/app_router.dart (extracts tripId from path, passes to TripJoinPage)
- [ ] T048 [P] [US2] Create generateShareableLink helper function in lib/core/utils/link_utils.dart (returns base URL + /trips/{tripId}/join)
- [ ] T049 [US2] Verify tests pass for User Story 2

**Checkpoint**: User Story 2 complete - users can join via shareable links

---

## Phase 6: User Story 5 - Access Trip Invite Details (Priority: P2)

**Goal**: Members can view invite code, copy it, and share it via native share dialog

**Independent Test**: Access trip invite page, verify code displayed, copy button works, share button works

### Tests for User Story 5 (TDD - Write FIRST)

**NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [ ] T050 [P] [US5] Widget test for TripInvitePage displays invite code in test/features/trips/presentation/pages/trip_invite_page_test.dart
- [ ] T051 [P] [US5] Widget test for TripInvitePage copy button copies to clipboard in test/features/trips/presentation/pages/trip_invite_page_test.dart
- [ ] T052 [P] [US5] Integration test for membership guard redirects non-members in test/integration/membership_guard_test.dart

### Implementation for User Story 5

- [ ] T053 [P] [US5] Create TripInvitePage UI in lib/features/trips/presentation/pages/trip_invite_page.dart (display invite code, copy button, share button, member list)
- [ ] T054 [US5] Add copy to clipboard functionality in TripInvitePage in lib/features/trips/presentation/pages/trip_invite_page.dart (using Clipboard API)
- [ ] T055 [US5] Add native share functionality in TripInvitePage in lib/features/trips/presentation/pages/trip_invite_page.dart (using Share API with shareable link)
- [ ] T056 [US5] Add /trips/:tripId/invite route with membership guard to app_router.dart in lib/core/router/app_router.dart (redirect non-members to join page)
- [ ] T057 [US5] Add "Invite Friends" button to TripSettingsPage in lib/features/trips/presentation/pages/trip_settings_page.dart (navigates to TripInvitePage)
- [ ] T058 [US5] Verify tests pass for User Story 5

**Checkpoint**: User Story 5 complete - members can easily share invites

---

## Phase 7: User Story 3 - View Trip Activity Log (Priority: P2)

**Goal**: Members can view chronological history of all trip actions with timestamps and actor names

**Independent Test**: Perform actions (join, add expense, edit expense), verify they appear in activity log

### Tests for User Story 3 (TDD - Write FIRST)

**NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [ ] T059 [P] [US3] Unit test for ActivityLogRepository.addLog creates Firestore document in test/features/trips/domain/repositories/activity_log_repository_test.dart
- [ ] T060 [P] [US3] Unit test for ActivityLogRepository.getActivityLogs streams logs ordered by timestamp in test/features/trips/domain/repositories/activity_log_repository_test.dart
- [ ] T061 [P] [US3] Unit test for ActivityLogCubit.loadActivityLogs emits loaded state in test/features/trips/presentation/cubits/activity_log_cubit_test.dart
- [ ] T062 [P] [US3] Unit test for ActivityLogCubit.loadActivityLogs emits error state on failure in test/features/trips/presentation/cubits/activity_log_cubit_test.dart
- [ ] T063 [P] [US3] Unit test for ExpenseCubit logs expense_added activity in test/features/expenses/presentation/cubits/expense_cubit_test.dart
- [ ] T064 [P] [US3] Unit test for ExpenseCubit logs expense_edited activity in test/features/expenses/presentation/cubits/expense_cubit_test.dart
- [ ] T065 [P] [US3] Unit test for ExpenseCubit logs expense_deleted activity in test/features/expenses/presentation/cubits/expense_cubit_test.dart
- [ ] T066 [P] [US3] Widget test for ActivityLogList displays log entries in test/features/trips/presentation/widgets/activity_log_list_test.dart
- [ ] T067 [P] [US3] Widget test for ActivityLogList shows empty state in test/features/trips/presentation/widgets/activity_log_list_test.dart
- [ ] T068 [P] [US3] Integration test for activity log real-time updates in test/integration/activity_log_updates_test.dart

### Implementation for User Story 3

- [ ] T069 [P] [US3] Create ActivityLogState classes in lib/features/trips/presentation/cubits/activity_log_state.dart (Initial, Loading, Loaded, Error)
- [ ] T070 [P] [US3] Create ActivityLogCubit in lib/features/trips/presentation/cubits/activity_log_cubit.dart (loadActivityLogs, stream subscription, limit to 50 entries)
- [ ] T071 [P] [US3] Create ActivityLogItem widget in lib/features/trips/presentation/widgets/activity_log_item.dart (displays single log entry with icon, actor, description, timestamp)
- [ ] T071b [P] [US3] Create relative timestamp formatting helper in lib/core/utils/time_utils.dart (formats DateTime to relative strings like "2 hours ago", "Yesterday", with localization support)
- [ ] T071c [US3] Add tooltip to ActivityLogItem for absolute timestamp in lib/features/trips/presentation/widgets/activity_log_item.dart (shows absolute timestamp on hover, e.g., "Oct 29, 2025 2:30 PM")
- [ ] T072 [US3] Create ActivityLogList widget in lib/features/trips/presentation/widgets/activity_log_list.dart (BlocBuilder for ActivityLogCubit, shows list or empty state)
- [ ] T072b [US3] Add Load More button and pagination logic to ActivityLogList in lib/features/trips/presentation/widgets/activity_log_list.dart (fetch older entries in batches of 50 when clicked, show loading state)
- [ ] T073 [US3] Add Activity Log tab to TripSettingsPage in lib/features/trips/presentation/pages/trip_settings_page.dart (TabBar with Settings and Activity tabs)
- [ ] T074 [US3] Add ActivityLogCubit to BLoC providers in main.dart in lib/main.dart
- [ ] T075 [US3] Modify ExpenseCubit constructor to accept ActivityLogRepository in lib/features/expenses/presentation/cubits/expense_cubit.dart
- [ ] T076 [US3] Modify ExpenseCubit.createExpense to log expense_added activity in lib/features/expenses/presentation/cubits/expense_cubit.dart
- [ ] T077 [US3] Modify ExpenseCubit.updateExpense to log expense_edited activity in lib/features/expenses/presentation/cubits/expense_cubit.dart
- [ ] T078 [US3] Modify ExpenseCubit.deleteExpense to log expense_deleted activity in lib/features/expenses/presentation/cubits/expense_cubit.dart
- [ ] T079 [US3] Update main.dart to pass ActivityLogRepository to ExpenseCubit in lib/main.dart
- [ ] T080 [US3] Verify tests pass for User Story 3

**Checkpoint**: User Story 3 complete - full activity log transparency

---

## Phase 8: Membership Guards & Navigation

**Purpose**: Apply membership guards to existing routes to enforce privacy

- [ ] T081 [P] Add membershipGuard helper function in lib/core/router/app_router.dart (checks TripCubit.isUserMemberOf, redirects to join page if not member)
- [ ] T082 [P] Apply membership guard to /trips/:tripId/expenses route in lib/core/router/app_router.dart
- [ ] T083 [P] Apply membership guard to /trips/:tripId/expenses/create route in lib/core/router/app_router.dart
- [ ] T084 [P] Apply membership guard to /trips/:tripId/expenses/:expenseId/edit route in lib/core/router/app_router.dart
- [ ] T085 [P] Apply membership guard to /trips/:tripId/settings route in lib/core/router/app_router.dart
- [ ] T086 [P] Apply membership guard to /trips/:tripId/settlement route in lib/core/router/app_router.dart
- [ ] T087 [P] Apply membership guard to /trips/:tripId/edit route in lib/core/router/app_router.dart
- [ ] T088 [P] Integration test for membership guard redirects in test/integration/membership_guard_test.dart (non-member tries to access member-only route, verify redirected to join page)

---

## Phase 9: Polish & Cross-Cutting Concerns

**Purpose**: Final polish, documentation, and validation

- [ ] T089 [P] Add loading states (shimmer/CircularProgressIndicator) to TripJoinPage in lib/features/trips/presentation/pages/trip_join_page.dart
- [ ] T090 [P] Add loading states to ActivityLogList in lib/features/trips/presentation/widgets/activity_log_list.dart
- [ ] T091 [P] Add empty state for users with no joined trips in TripListPage in lib/features/trips/presentation/pages/trip_list_page.dart (prompt to create or join trip)
- [ ] T092 [P] Format all new Dart files using flutter format
- [ ] T093 Run flutter analyze and fix any warnings
- [ ] T094 Run flutter test --coverage and verify 80%+ coverage for new code
- [ ] T095 Create feature documentation using /docs.create command
- [ ] T096 Manual testing: Create trip, join via code, join via link, view activity log, share invite
- [ ] T097 Manual testing: Clear browser cache, verify must rejoin trips (expected behavior)
- [ ] T098 Manual testing: Test on Chrome, Safari, Firefox for web compatibility
- [ ] T099 Build for production using flutter build web --base-href /expense_tracker/
- [ ] T100 Log completion to feature CHANGELOG.md using /docs.log command

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phases 3-7)**: All depend on Foundational phase completion
  - **Phase 3 (US4)**: Must complete first - creates private trip foundation
  - **Phase 4 (US1)**: Depends on Phase 3 (need trips to join)
  - **Phase 5 (US2)**: Extends Phase 4 (same join flow, adds deep linking)
  - **Phase 6 (US5)**: Can run after Phase 5 (sharing features)
  - **Phase 7 (US3)**: Can run in parallel with Phase 6 (independent observational feature)
- **Membership Guards (Phase 8)**: Depends on Phase 4 completion (requires joinTrip functionality)
- **Polish (Phase 9)**: Depends on all user stories being complete

### User Story Dependencies

- **User Story 4 (P1 - Create Private Trip)**: Foundation - no dependencies on other stories
- **User Story 1 (P1 - Join via Code)**: Depends on US4 (need trips to join)
- **User Story 2 (P1 - Share via Link)**: Depends on US1 (extends join flow)
- **User Story 5 (P2 - Invite Details)**: Depends on US2 (sharing features)
- **User Story 3 (P2 - Activity Log)**: Independent - can start after Foundational

### Within Each User Story (TDD Order)

1. **Tests FIRST** (all marked [P] can run in parallel)
2. **Models** (marked [P] can run in parallel)
3. **Services/Cubits** (depends on models)
4. **UI/Pages** (depends on cubits)
5. **Integration** (depends on all above)
6. **Verify tests pass**

### Parallel Opportunities

- **Phase 1 (Setup)**: All 4 tasks marked [P] can run in parallel
- **Phase 2 (Foundational)**: T005-T007 (models) can run in parallel
- **Within Each User Story**: All test tasks marked [P] can run in parallel
- **Phases 6 & 7**: Can run in parallel (US5 and US3 are independent)
- **Phase 8 (Guards)**: T082-T087 (route modifications) can run in parallel

---

## Parallel Example: User Story 1

```bash
# Launch all tests for User Story 1 together:
Task: "Unit test for TripCubit.joinTrip adds participant and logs activity"
Task: "Unit test for TripCubit.joinTrip is idempotent (already member)"
Task: "Unit test for TripCubit.joinTrip handles trip not found"
Task: "Unit test for TripCubit.isUserMemberOf checks local cache"
Task: "Widget test for TripJoinPage renders form"
Task: "Widget test for TripJoinPage shows error for invalid code"
Task: "Integration test for join trip via code flow"

# After tests pass, launch parallel implementation tasks:
Task: "Create TripJoinPage UI" (different file from Cubit)
Task: "Add validation to TripJoinPage" (same file, do sequentially)
```

---

## Implementation Strategy

### MVP First (User Stories 4 + 1 Only)

1. Complete Phase 1: Setup (localization, local storage)
2. Complete Phase 2: Foundational (ActivityLog model, repository)
3. Complete Phase 3: User Story 4 (Create Private Trip)
4. Complete Phase 4: User Story 1 (Join via Code)
5. **STOP and VALIDATE**: Test US4 + US1 independently
6. Deploy/demo if ready

**Deliverable**: Users can create private trips and join them via invite codes

---

### Incremental Delivery

1. **MVP (Phases 1-4)**: Create + Join trips → Deploy/Demo 🚀
2. **Phase 5**: Add shareable links → Deploy/Demo 🚀
3. **Phase 6**: Add invite details page → Deploy/Demo 🚀
4. **Phase 7**: Add activity log → Deploy/Demo 🚀
5. **Phase 8-9**: Guards + Polish → Final Deploy/Demo 🚀

Each increment adds value without breaking previous functionality.

---

### Parallel Team Strategy

With multiple developers:

1. **Together**: Complete Phase 1 (Setup) + Phase 2 (Foundational)
2. **Phase 3 (US4)**: Single developer (foundation for all)
3. **After Phase 3**:
   - Developer A: Phase 4 (US1) → Phase 5 (US2)
   - Developer B: Phase 7 (US3 - independent)
   - Developer C: Phase 6 (US5)
4. **Together**: Phase 8 (Guards) + Phase 9 (Polish)

---

## Notes

- ✅ **TDD Required**: Tests MUST be written first per constitution
- **[P] tasks**: Different files, no dependencies, can run in parallel
- **[Story] label**: Maps task to specific user story for traceability
- Each user story should be independently completable and testable
- Verify tests FAIL before implementing
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- Constitution compliance: 80% test coverage for business logic

---

## Total Task Count

- **Setup (Phase 1)**: 4 tasks
- **Foundational (Phase 2)**: 7 tasks
- **User Story 4 (Phase 3)**: 15 tasks (5 tests + 10 implementation) ← Added T023b
- **User Story 1 (Phase 4)**: 16 tasks (7 tests + 9 implementation)
- **User Story 2 (Phase 5)**: 8 tasks (3 tests + 5 implementation)
- **User Story 5 (Phase 6)**: 9 tasks (3 tests + 6 implementation)
- **User Story 3 (Phase 7)**: 24 tasks (10 tests + 14 implementation) ← Added T071b, T071c, T072b
- **Membership Guards (Phase 8)**: 8 tasks
- **Polish (Phase 9)**: 12 tasks

**Total**: 104 tasks (was 100, added 4 for requirement completeness)

**MVP (Phases 1-4)**: 42 tasks (was 41, added T023b)
**Full Feature**: 104 tasks

**Estimated Effort**: 3-5 developer days (MVP), 7-10 days (full feature)
