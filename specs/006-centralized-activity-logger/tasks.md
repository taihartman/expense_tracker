# Tasks: Centralized Activity Logger Service

**Input**: Design documents from `/specs/006-centralized-activity-logger/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`
- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and basic structure

- [ ] T001 Create directory structure for service in `lib/core/services/`
- [ ] T002 Create directory structure for tests in `test/core/services/`

**Checkpoint**: Directory structure ready

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**CRITICAL**: No user story work can begin until this phase is complete. ALL tests in this phase MUST be written FIRST and FAIL before implementation.

### Tests First (TDD - Write Before Implementation)

- [ ] T003 [P] Write test for ActivityLoggerService interface structure in `test/core/services/activity_logger_service_test.dart`
- [ ] T004 [P] Write test for fire-and-forget error handling (service never throws) in `test/core/services/activity_logger_service_test.dart`
- [ ] T005 [P] Write test for graceful degradation when trip data unavailable in `test/core/services/activity_logger_service_test.dart`
- [ ] T006 [P] Write test for handling null/empty actorName in `test/core/services/activity_logger_service_test.dart`

### Implementation (After Tests Fail)

- [ ] T007 Create ActivityLoggerService abstract interface in `lib/core/services/activity_logger_service.dart` with method signatures for all 7 logging methods (logExpenseAdded, logExpenseEdited, logExpenseDeleted, logTransferSettled, logTransferUnsettled, logMemberJoined, logTripCreated) and clearCache method
- [ ] T008 Create ActivityLoggerServiceImpl skeleton in `lib/core/services/activity_logger_service_impl.dart` with constructor accepting ActivityLogRepository and TripRepository
- [ ] T009 Implement private helper methods in ActivityLoggerServiceImpl: `_getTripContext()`, `_logActivity()`, `_logError()`, `_formatJoinMethod()`
- [ ] T010 Implement error handling pattern (try-catch with _logError) in all public methods
- [ ] T011 Add service to dependency injection in `lib/main.dart` (RepositoryProvider for ActivityLoggerService)

**Checkpoint**: Foundation ready - verify all foundational tests pass, user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - Developer Adds New Activity Type (Priority: P1) 🎯 MVP

**Goal**: Reduce developer effort by providing simple methods that encapsulate all activity logging complexity (change detection, metadata generation, error handling)

**Independent Test**: Developer can add expense edit logging with a single method call `activityLogger.logExpenseEdit(oldExpense, newExpense, actorName)` and verify the activity appears in the activity log with correct metadata including automatic change detection

### Tests for User Story 1 (TDD - Write Tests FIRST)

**NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [ ] T012 [P] [US1] Write test for logExpenseAdded with participant name resolution in `test/core/services/activity_logger_service_test.dart`
- [ ] T013 [P] [US1] Write test for logExpenseEdited with ExpenseChangeDetector integration in `test/core/services/activity_logger_service_test.dart`
- [ ] T014 [P] [US1] Write test for logExpenseEdited with no changes detected (identical old/new) in `test/core/services/activity_logger_service_test.dart`
- [ ] T015 [P] [US1] Write test for logExpenseDeleted with all required metadata in `test/core/services/activity_logger_service_test.dart`
- [ ] T016 [P] [US1] Write test for logTransferSettled with participant name lookup in `test/core/services/activity_logger_service_test.dart`
- [ ] T017 [P] [US1] Write test for logTransferUnsettled with participant name lookup in `test/core/services/activity_logger_service_test.dart`
- [ ] T018 [P] [US1] Write test for logMemberJoined with invite tracking in `test/core/services/activity_logger_service_test.dart`
- [ ] T019 [P] [US1] Write test for logTripCreated with trip metadata in `test/core/services/activity_logger_service_test.dart`
- [ ] T020 [P] [US1] Write test for clearCache invalidates cached trip data in `test/core/services/activity_logger_service_test.dart`

### Implementation for User Story 1 (After Tests Written and Failing)

- [ ] T021 [US1] Implement logExpenseAdded method in `lib/core/services/activity_logger_service_impl.dart` (fetch trip context, resolve payer name, create activity log with metadata)
- [ ] T022 [US1] Implement logExpenseEdited method in `lib/core/services/activity_logger_service_impl.dart` (use ExpenseChangeDetector.detectChanges, generate description with change count, create activity log with change metadata)
- [ ] T023 [US1] Implement logExpenseDeleted method in `lib/core/services/activity_logger_service_impl.dart` (create activity log with expense details in metadata)
- [ ] T024 [US1] Implement logTransferSettled method in `lib/core/services/activity_logger_service_impl.dart` (fetch trip context, resolve participant names, create activity log with transfer details)
- [ ] T025 [US1] Implement logTransferUnsettled method in `lib/core/services/activity_logger_service_impl.dart` (fetch trip context, resolve participant names, create activity log with transfer details)
- [ ] T026 [US1] Implement logMemberJoined method in `lib/core/services/activity_logger_service_impl.dart` (format join method, optionally lookup inviter name, create activity log with join metadata)
- [ ] T027 [US1] Implement logTripCreated method in `lib/core/services/activity_logger_service_impl.dart` (create activity log with trip name and base currency in metadata)
- [ ] T028 [US1] Implement clearCache method in `lib/core/services/activity_logger_service_impl.dart` (set _tripContextCache to null)
- [ ] T029 [US1] Verify all US1 tests pass (run `flutter test test/core/services/activity_logger_service_test.dart`)

### Migration: ExpenseCubit (Pilot Feature)

- [ ] T030 [US1] Add ActivityLoggerService injection to ExpenseCubit in `lib/features/expenses/presentation/cubits/expense_cubit.dart` (keep old repositories for now)
- [ ] T031 [US1] Update ExpenseCubit provider in `lib/main.dart` to inject ActivityLoggerService
- [ ] T032 [US1] Replace manual logging in ExpenseCubit.addExpense() with activityLogger.logExpenseAdded() in `lib/features/expenses/presentation/cubits/expense_cubit.dart`
- [ ] T033 [US1] Replace manual logging in ExpenseCubit.updateExpense() with activityLogger.logExpenseEdited() in `lib/features/expenses/presentation/cubits/expense_cubit.dart`
- [ ] T034 [US1] Replace manual logging in ExpenseCubit.deleteExpense() with activityLogger.logExpenseDeleted() in `lib/features/expenses/presentation/cubits/expense_cubit.dart`
- [ ] T035 [US1] Update ExpenseCubit tests in `test/features/expenses/presentation/cubits/expense_cubit_test.dart` to use MockActivityLoggerService and verify service calls
- [ ] T036 [US1] Run all ExpenseCubit tests to verify migration (`flutter test test/features/expenses/`)
- [ ] T037 [US1] Manual test: Add/edit/delete expense and verify activity logs appear correctly in UI

**Checkpoint**: At this point, User Story 1 should be fully functional and testable independently. Developer can add activity logging with a single method call instead of 40+ lines of boilerplate.

---

## Phase 4: User Story 2 - Consistent Activity Metadata Across Features (Priority: P2)

**Goal**: Ensure all activities follow the same metadata structure and naming conventions for consistent analysis and reporting

**Independent Test**: Trigger activities from different features (expenses, settlements, trips) and verify all logs follow the same metadata structure with consistent field names (e.g., always "fromId"/"fromName", "toId"/"toName", "amount", "currency")

### Tests for User Story 2 (TDD - Write Tests FIRST)

**NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [ ] T038 [P] [US2] Write test for metadata structure consistency across all activity types in `test/core/services/activity_logger_service_metadata_test.dart`
- [ ] T039 [P] [US2] Write test for participant metadata always includes both ID and name in `test/core/services/activity_logger_service_metadata_test.dart`
- [ ] T040 [P] [US2] Write test for change records use consistent "oldValue"/"newValue" naming in `test/core/services/activity_logger_service_metadata_test.dart`
- [ ] T041 [P] [US2] Write test for monetary amounts always include amount + currency pair in `test/core/services/activity_logger_service_metadata_test.dart`

### Implementation for User Story 2

- [ ] T042 [US2] Review and standardize metadata structure in logExpenseAdded (ensure consistent field naming) in `lib/core/services/activity_logger_service_impl.dart`
- [ ] T043 [US2] Review and standardize metadata structure in logExpenseEdited (ensure ExpenseChangeDetector uses consistent naming) in `lib/core/services/activity_logger_service_impl.dart`
- [ ] T044 [US2] Review and standardize metadata structure in logExpenseDeleted (ensure consistent field naming) in `lib/core/services/activity_logger_service_impl.dart`
- [ ] T045 [US2] Review and standardize metadata structure in logTransferSettled/Unsettled (ensure fromId/fromName, toId/toName consistency) in `lib/core/services/activity_logger_service_impl.dart`
- [ ] T046 [US2] Review and standardize metadata structure in logMemberJoined (ensure consistent field naming) in `lib/core/services/activity_logger_service_impl.dart`
- [ ] T047 [US2] Review and standardize metadata structure in logTripCreated (ensure consistent field naming) in `lib/core/services/activity_logger_service_impl.dart`
- [ ] T048 [US2] Document metadata standards in `specs/006-centralized-activity-logger/contracts/metadata_standards.md` (field naming conventions, required vs optional fields, data types)
- [ ] T049 [US2] Verify all US2 tests pass (run `flutter test test/core/services/activity_logger_service_metadata_test.dart`)

**Checkpoint**: At this point, User Stories 1 AND 2 should both work independently. All activities follow the same metadata structure with consistent field names.

---

## Phase 5: User Story 3 - Performance Optimization Through Caching (Priority: P3)

**Goal**: Maintain app responsiveness even when logging many activities by caching trip data to avoid redundant fetches

**Independent Test**: Perform 50+ operations in quick succession and verify response time remains under 500ms, and cached trip data is reused instead of fetched repeatedly

### Tests for User Story 3 (TDD - Write Tests FIRST)

**NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [ ] T050 [P] [US3] Write test for cache hit behavior (second call to same trip doesn't fetch) in `test/core/services/activity_logger_service_cache_test.dart`
- [ ] T051 [P] [US3] Write test for cache miss behavior (first call or different trip fetches) in `test/core/services/activity_logger_service_cache_test.dart`
- [ ] T052 [P] [US3] Write test for cache expiration (5-minute TTL) in `test/core/services/activity_logger_service_cache_test.dart`
- [ ] T053 [P] [US3] Write test for cache invalidation when switching trips in `test/core/services/activity_logger_service_cache_test.dart`
- [ ] T054 [P] [US3] Write performance benchmark test (50+ activities in 1 minute with <500ms per operation) in `test/core/services/activity_logger_service_performance_test.dart`

### Implementation for User Story 3

- [ ] T055 [US3] Create _TripContextCache internal class in `lib/core/services/activity_logger_service_impl.dart` (fields: tripId, participants, tripName, cachedAt)
- [ ] T056 [US3] Implement _TripContextCache.isExpired() method in `lib/core/services/activity_logger_service_impl.dart` (check if age >= cacheExpirationMinutes)
- [ ] T057 [US3] Update _getTripContext() to check cache before fetching in `lib/core/services/activity_logger_service_impl.dart` (check tripId match and not expired)
- [ ] T058 [US3] Update _getTripContext() to populate cache on fetch in `lib/core/services/activity_logger_service_impl.dart` (store tripId, participants, tripName, cachedAt)
- [ ] T059 [US3] Add cacheExpirationMinutes parameter to ActivityLoggerServiceImpl constructor with default 5 minutes in `lib/core/services/activity_logger_service_impl.dart`
- [ ] T060 [US3] Verify all US3 tests pass (run `flutter test test/core/services/activity_logger_service_cache_test.dart` and `flutter test test/core/services/activity_logger_service_performance_test.dart`)
- [ ] T061 [US3] Manual performance test: Log 50 expenses rapidly and measure response time (should be <500ms after first)

**Checkpoint**: All user stories should now be independently functional. Performance meets <500ms requirement for 50+ activities in 1 minute.

---

## Phase 6: Migration & Polish (Cross-Cutting Concerns)

**Purpose**: Complete migration of remaining features and finalize documentation

### Migration: SettlementCubit

- [ ] T062 Add ActivityLoggerService injection to SettlementCubit in `lib/features/settlements/presentation/cubits/settlement_cubit.dart`
- [ ] T063 Update SettlementCubit provider in `lib/main.dart` to inject ActivityLoggerService
- [ ] T064 Replace manual logging in SettlementCubit.markTransferAsSettled() with activityLogger.logTransferSettled() in `lib/features/settlements/presentation/cubits/settlement_cubit.dart`
- [ ] T065 Replace manual logging in SettlementCubit.markTransferAsUnsettled() with activityLogger.logTransferUnsettled() in `lib/features/settlements/presentation/cubits/settlement_cubit.dart`
- [ ] T066 Update SettlementCubit tests to use MockActivityLoggerService in `test/features/settlements/presentation/cubits/settlement_cubit_test.dart`
- [ ] T067 Run all SettlementCubit tests (`flutter test test/features/settlements/`)

### Migration: TripCubit

- [ ] T068 Add ActivityLoggerService injection to TripCubit in `lib/features/trips/presentation/cubits/trip_cubit.dart`
- [ ] T069 Update TripCubit provider in `lib/main.dart` to inject ActivityLoggerService
- [ ] T070 Replace manual logging in TripCubit.createTrip() with activityLogger.logTripCreated() in `lib/features/trips/presentation/cubits/trip_cubit.dart`
- [ ] T071 Replace manual logging in TripCubit.joinTrip() with activityLogger.logMemberJoined() in `lib/features/trips/presentation/cubits/trip_cubit.dart`
- [ ] T072 Update TripCubit tests to use MockActivityLoggerService in `test/features/trips/presentation/cubits/trip_cubit_test.dart`
- [ ] T073 Run all TripCubit tests (`flutter test test/features/trips/`)

### Cleanup

- [ ] T074 Remove ActivityLogRepository and TripRepository injections from ExpenseCubit in `lib/features/expenses/presentation/cubits/expense_cubit.dart`
- [ ] T075 Remove ActivityLogRepository injection from SettlementCubit in `lib/features/settlements/presentation/cubits/settlement_cubit.dart`
- [ ] T076 Remove ActivityLogRepository injection from TripCubit (if only used for logging) in `lib/features/trips/presentation/cubits/trip_cubit.dart`
- [ ] T077 Update all cubit providers in `lib/main.dart` to remove old repository injections (keep only ActivityLoggerService)
- [ ] T078 Remove old manual logging code from all cubits (delete try-catch blocks with _activityLogRepository?.addLog)
- [ ] T079 Run flutter analyze to check for unused imports and dead code (`flutter analyze`)

### Documentation

- [ ] T080 [P] Update feature CLAUDE.md with service usage patterns in `specs/006-centralized-activity-logger/CLAUDE.md`
- [ ] T081 [P] Update feature CHANGELOG.md with all changes using `/docs.log` for each migration step
- [ ] T082 Run `/docs.update` to finalize feature CLAUDE.md with architecture decisions
- [ ] T083 Verify quickstart.md examples are accurate in `specs/006-centralized-activity-logger/quickstart.md`

### Final Validation

- [ ] T084 Run full test suite (`flutter test`)
- [ ] T085 Run test coverage report (`flutter test --coverage`)
- [ ] T086 Verify 80%+ code coverage for ActivityLoggerService business logic
- [ ] T087 Manual regression test: Create trip → Add expenses → Edit expenses → Delete expenses → Mark settlements → Verify all activity logs appear correctly
- [ ] T088 Run `/docs.complete` to mark feature complete and roll up to root CHANGELOG.md

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3, 4, 5)**: All depend on Foundational phase completion
  - User stories can then proceed in parallel (if staffed)
  - Or sequentially in priority order (P1 → P2 → P3)
- **Migration & Polish (Phase 6)**: Depends on User Story 1 (P1) completion (pilot successful)

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2) - No dependencies on other stories
- **User Story 2 (P2)**: Can start after Foundational (Phase 2) - No dependencies on other stories, but benefits from US1 implementation
- **User Story 3 (P3)**: Depends on US1 completion (needs implemented service to test caching)

### Within Each User Story

- Tests (TDD) MUST be written and FAIL before implementation
- All tests for a story can be written in parallel (marked [P])
- Implementation tasks run after tests are written
- Story validation/checkpoint happens after all tasks complete

### Parallel Opportunities

- All Setup tasks can run in parallel (T001-T002)
- All Foundational test tasks can run in parallel (T003-T006)
- All US1 test tasks can run in parallel (T012-T020)
- All US2 test tasks can run in parallel (T038-T041)
- All US3 test tasks can run in parallel (T050-T054)
- Documentation tasks can run in parallel (T080-T081)

---

## Parallel Example: User Story 1 Tests

```bash
# Launch all tests for User Story 1 together (TDD):
Task T012: "Write test for logExpenseAdded..."
Task T013: "Write test for logExpenseEdited..."
Task T014: "Write test for logExpenseEdited with no changes..."
Task T015: "Write test for logExpenseDeleted..."
Task T016: "Write test for logTransferSettled..."
Task T017: "Write test for logTransferUnsettled..."
Task T018: "Write test for logMemberJoined..."
Task T019: "Write test for logTripCreated..."
Task T020: "Write test for clearCache..."
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL - blocks all stories)
3. Complete Phase 3: User Story 1 (core service + ExpenseCubit migration)
4. **STOP and VALIDATE**: Test User Story 1 independently
5. Deploy/demo if ready (basic service working)

### Incremental Delivery

1. Complete Setup + Foundational → Foundation ready
2. Add User Story 1 → Test independently → Service works for basic logging (MVP!)
3. Add User Story 2 → Test independently → Metadata consistency ensured
4. Add User Story 3 → Test independently → Performance optimized with caching
5. Complete Phase 6 → Migrate all features → Full rollout

### Parallel Team Strategy

With multiple developers:

1. Team completes Setup + Foundational together
2. Once Foundational is done:
   - Developer A: User Story 1 (tests + implementation)
   - Developer B: User Story 2 (tests + metadata standards)
   - Developer C: User Story 3 (tests + caching - waits for US1 implementation)
3. All join for Phase 6 migration and polish

---

## Notes

- **TDD is NON-NEGOTIABLE**: Write ALL tests FIRST (they must fail initially)
- **Coverage requirement**: 80%+ for service business logic, 60%+ overall
- [P] tasks = different files, no dependencies, can run in parallel
- [Story] label maps task to specific user story for traceability
- Each user story should be independently completable and testable
- Verify tests fail before implementing (red → green → refactor)
- Commit after each logical group of tasks
- Stop at any checkpoint to validate story independently
- Use `/docs.log` after each significant milestone
- Use `/docs.update` when adding new components or changing architecture
- Use `/docs.complete` when feature is fully implemented and tested
