---
description: "Task list for Trip Multi-Currency Selection feature"
---

# Tasks: Trip Multi-Currency Selection

**Input**: Design documents from `/specs/011-trip-multi-currency/`
**Prerequisites**: plan.md, spec.md, data-model.md, contracts/, research.md, quickstart.md

**Tests**: Following project constitution (TDD NON-NEGOTIABLE), all tests MUST be written BEFORE implementation.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `- [ ] [ID] [P?] [Story?] Description`
- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2, US3, US4)
- Include exact file paths in descriptions

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and localization strings

- [x] T001 Add localization strings to lib/l10n/app_en.arb for multi-currency selector UI (multiCurrencySelectorTitle, multiCurrencySelectorHelpText, multiCurrencySelectorAddButton, multiCurrencySelectorMaxError, multiCurrencySelectorMinError, multiCurrencySelectorDuplicateError, multiCurrencySelectorMoveUp, multiCurrencySelectorMoveDown, multiCurrencySelectorRemove, multiCurrencySelectorChipLabel)
- [x] T002 Run flutter pub get to generate localization code
- [x] T003 Verify localization strings available via context.l10n

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core domain model, repository interface, and exceptions that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

### Domain Model Updates

- [x] T004 [P] Update Trip domain model in lib/features/trips/domain/models/trip.dart (add allowedCurrencies field, deprecate baseCurrency, add defaultCurrency getter, update validate() method, update copyWith(), update toString())
- [x] T005 [P] Create TripNotFoundException exception in lib/features/trips/domain/exceptions/trip_exceptions.dart
- [x] T006 [P] Create DataIntegrityException exception in lib/features/trips/domain/exceptions/trip_exceptions.dart

### Repository Interface Updates

- [x] T007 Update TripRepository interface in lib/features/trips/domain/repositories/trip_repository.dart (add getAllowedCurrencies() method signature, add updateAllowedCurrencies() method signature)

### Data Model Updates

- [x] T008 Update TripModel serialization in lib/features/trips/data/models/trip_model.dart (add allowedCurrencies field, update fromFirestore() to handle legacy trips, update toFirestore(), update toDomain() with migration logic, update fromDomain())

### Repository Implementation Updates

- [x] T009 Implement getAllowedCurrencies() in lib/features/trips/data/repositories/trip_repository_impl.dart (reuse getTripById, handle legacy trips via TripModel.toDomain(), throw TripNotFoundException if trip not found)
- [x] T010 Implement updateAllowedCurrencies() in lib/features/trips/data/repositories/trip_repository_impl.dart (validate 1-10 currencies, validate no duplicates, validate trip exists, update Firestore with new allowedCurrencies array)

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - Select Multiple Trip Currencies (Priority: P1) 🎯 MVP

**Goal**: Users can select 2-5 currencies for a trip via chip-based UI in bottom sheet, reducing cognitive load during expense entry

**Independent Test**: Create trip → navigate to trip settings → open currency selector → add 3 currencies (USD, EUR, GBP) → reorder using up/down arrows → save → verify trip has allowedCurrencies = [EUR, USD, GBP] in Firestore

### Tests for User Story 1 (TDD - Write FIRST)

**NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [ ] T011 [P] [US1] Unit test for Trip model validation in test/features/trips/domain/models/trip_test.dart (test allowedCurrencies validation: minimum 1 currency, maximum 10 currencies, no duplicates, valid currency codes)
- [ ] T012 [P] [US1] Unit test for TripModel serialization in test/features/trips/data/models/trip_model_test.dart (test fromFirestore with allowedCurrencies, test fromFirestore with legacy baseCurrency, test toFirestore, test toDomain migration logic)
- [ ] T013 [P] [US1] Unit test for TripRepository.getAllowedCurrencies() in test/features/trips/data/repositories/trip_repository_impl_test.dart (test returns allowedCurrencies when field exists, test returns [baseCurrency] for legacy trip, test throws TripNotFoundException when trip missing, test throws DataIntegrityException when both fields missing)
- [ ] T014 [P] [US1] Unit test for TripRepository.updateAllowedCurrencies() in test/features/trips/data/repositories/trip_repository_impl_test.dart (test updates Firestore with valid currencies, test throws ArgumentError when empty list, test throws ArgumentError when >10 currencies, test throws ArgumentError when duplicates, test throws TripNotFoundException when trip missing)
- [ ] T015 [P] [US1] Widget test for MultiCurrencySelector in test/features/trips/presentation/widgets/multi_currency_selector_test.dart (test renders chips for selected currencies, test calls onChanged when currency added, test calls onChanged when currency removed, test calls onChanged when currency moved up, test calls onChanged when currency moved down, test disables add button at max currencies, test disables remove button at min currencies, test prevents duplicate currency selection, test hides up arrow for first chip, test hides down arrow for last chip, test respects mobile vs desktop responsive sizing)

### Implementation for User Story 1

**Models (already done in Phase 2)**:
- ✅ Trip domain model updated (T004)
- ✅ TripModel serialization updated (T008)
- ✅ Repository interface updated (T007)
- ✅ Repository implementation updated (T009, T010)

**UI Widget**:
- [ ] T016 [US1] Create MultiCurrencySelector widget in lib/features/trips/presentation/widgets/multi_currency_selector.dart (chip-based UI, add currency via CurrencySearchField modal, remove via X button, reorder via up/down arrows, validate max 10 currencies, validate min 1 currency, prevent duplicates, onChanged callback, responsive design mobile/desktop)

**Cubit Updates** (optional - may use existing TripCubit):
- [ ] T017 [US1] Add updateTripCurrencies() method to TripCubit in lib/features/trips/presentation/cubits/trip_cubit.dart (call repository.updateAllowedCurrencies, emit loading/success/error states, inject ActivityLogRepository for logging)
- [ ] T018 [P] [US1] Unit test for TripCubit.updateTripCurrencies() in test/features/trips/presentation/cubits/trip_cubit_test.dart (test emits success state on valid update, test emits error state on validation failure, test logs activity)

**UI Integration**:
- [ ] T019 [US1] Add currency selector to trip settings page in lib/features/trips/presentation/pages/trip_settings_page.dart (add "Allowed Currencies" section, display current currencies as chips, add "Edit Currencies" button that opens MultiCurrencySelector bottom sheet, save changes via TripCubit)

**Activity Logging**:
- [ ] T020 [US1] Add activity log entry when currencies updated in TripCubit.updateTripCurrencies() (format: "Sarah added EUR and GBP to allowed currencies", handle via ActivityLogRepository)

**Checkpoint**: At this point, User Story 1 should be fully functional - users can select/edit trip currencies via settings page

---

## Phase 4: User Story 2 - Filtered Expense Currency Selection (Priority: P1)

**Goal**: When creating/editing expenses, users see only trip's allowed currencies in dropdown (filtered from 170+ to 2-5), making expense entry faster and less error-prone

**Independent Test**: Create trip with 2 currencies (USD, JPY) → create expense → tap currency dropdown → verify dropdown shows ONLY USD and JPY (not all 170+ currencies)

### Tests for User Story 2 (TDD - Write FIRST)

**NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [ ] T021 [P] [US2] Widget test for expense form currency dropdown in test/features/expenses/presentation/pages/expense_form_page_test.dart (test currency dropdown shows only trip's allowed currencies, test pre-selects first allowed currency as default, test preserves existing expense currency even if not in allowed list for backward compatibility)
- [ ] T022 [P] [US2] Integration test for expense creation with filtered currencies in test/features/expenses/integration/expense_creation_test.dart (test end-to-end: create trip with 3 currencies → navigate to create expense → verify dropdown has only 3 currencies → select currency → create expense → verify expense saved with correct currency)

### Implementation for User Story 2

**Expense Form Updates**:
- [ ] T023 [US2] Update expense form currency dropdown in lib/features/expenses/presentation/pages/expense_form_page.dart (filter CurrencyCode.values to only show trip.allowedCurrencies, pre-select trip.defaultCurrency for new expenses, allow existing expense currency even if not in allowed list)
- [ ] T024 [US2] Update itemized expense form currency dropdown in lib/features/expenses/presentation/pages/itemized_expense_form_page.dart (filter line item currency dropdown to trip.allowedCurrencies)
- [ ] T025 [US2] Update quick-add expense feature to use trip.defaultCurrency in lib/features/expenses/presentation/widgets/quick_add_expense_widget.dart (if exists)

**Validation**:
- [ ] T026 [US2] Add client-side validation in expense forms (warn if selecting currency not in trip.allowedCurrencies for new expenses, allow it for editing existing expenses)

**Checkpoint**: At this point, User Stories 1 AND 2 should both work - trip currency selection flows into expense creation

---

## Phase 5: User Story 3 - Per-Currency Settlement Views (Priority: P2)

**Goal**: Settlements page shows separate settlement calculations for each allowed currency (no cross-currency conversion), providing clear per-currency settlement information

**Independent Test**: Create trip with USD and EUR → add expenses in both currencies → navigate to settlements → verify separate settlement screens for USD and EUR (each showing settlements for that currency only)

### Tests for User Story 3 (TDD - Write FIRST)

**NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [ ] T027 [P] [US3] Unit test for per-currency settlement calculations in test/features/settlements/domain/services/settlement_service_test.dart (test settlement calculation filters expenses by currency, test settlement calculation works independently per currency, test handles trip with multiple currencies)
- [ ] T028 [P] [US3] Widget test for currency-switcher UI in test/features/settlements/presentation/pages/settlements_page_test.dart (test renders tabs/dropdown for each allowed currency, test switches between currencies, test shows settlements for selected currency only, test shows empty state for currency with no expenses)

### Implementation for User Story 3

**Settlement Calculations** (no changes to algorithm needed):
- [ ] T029 [US3] Update SettlementService to accept currency filter parameter in lib/features/settlements/domain/services/settlement_service.dart (add optional currencyFilter parameter to calculateSettlements method, filter expenses by currency before running algorithm)

**Settlement UI Updates**:
- [ ] T030 [US3] Update settlements page to show currency switcher in lib/features/settlements/presentation/pages/settlements_page.dart (add tabs for 2-3 currencies or dropdown for 4+ currencies, use MediaQuery for mobile vs desktop UI, filter settlements by selected currency)
- [ ] T031 [US3] Add empty state for currencies with no expenses in lib/features/settlements/presentation/pages/settlements_page.dart (show "No {currency} expenses yet" when currency has zero expenses)

**SettlementCubit Updates**:
- [ ] T032 [US3] Update SettlementCubit to load settlements per currency in lib/features/settlements/presentation/cubits/settlement_cubit.dart (load settlements for each allowed currency, expose settlements grouped by currency)
- [ ] T033 [P] [US3] Unit test for SettlementCubit per-currency loading in test/features/settlements/presentation/cubits/settlement_cubit_test.dart (test loads settlements grouped by currency, test handles empty currency gracefully)

**Checkpoint**: All P1 and P2 user stories (1, 2, 3) should now be independently functional

---

## Phase 6: User Story 4 - Migrate Existing Trips (Priority: P2)

**Goal**: All existing trips with baseCurrency field are automatically migrated to allowedCurrencies = [baseCurrency] via server-side Firebase Cloud Functions, ensuring backward compatibility without user intervention

**Independent Test**: Create legacy trip with baseCurrency = "USD" (no allowedCurrencies field) → run migration function → verify trip has allowedCurrencies = ["USD"] in Firestore → verify app loads trip correctly with allowedCurrencies

### Tests for User Story 4 (TDD - Write FIRST)

**NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [ ] T034 [P] [US4] Unit test for Cloud Function migration logic in functions/test/migrations/migrate-trip-currencies.test.ts (test migrates trip with baseCurrency to allowedCurrencies, test skips trip already migrated, test handles trip missing baseCurrency, test is idempotent - safe to re-run, test generates correct migration summary)

### Implementation for User Story 4

**Firebase Cloud Functions Setup**:
- [ ] T035 [US4] Initialize Firebase Functions project in functions/ directory (run firebase init functions, select TypeScript, install dependencies)
- [ ] T036 [US4] Configure Firebase Functions package.json in functions/package.json (add dependencies: firebase-admin ^12.0.0, firebase-functions ^5.0.0, add devDependencies for testing: @firebase/rules-unit-testing, chai, mocha, ts-node)
- [ ] T037 [US4] Configure TypeScript for Cloud Functions in functions/tsconfig.json (set target es2018, module commonjs, strict mode)

**Migration Function**:
- [ ] T038 [US4] Implement migration Cloud Function in functions/src/migrations/migrate-trip-currencies.ts (query trips without allowedCurrencies field, validate baseCurrency exists, update with allowedCurrencies = [baseCurrency], log results, return MigrationSummary with totalTrips/successful/failed/results)
- [ ] T039 [US4] Export migration function in functions/src/index.ts (export migrateTripCurrencies function)

**Authentication**:
- [ ] T040 [US4] Add bearer token authentication to migration function in functions/src/migrations/migrate-trip-currencies.ts (check Authorization header against functions.config().migration.secret, return 403 if unauthorized)

**Deployment**:
- [ ] T041 [US4] Build and deploy migration function to Firebase (cd functions && npm install && npm run build && firebase deploy --only functions:migrateTripCurrencies)
- [ ] T042 [US4] Set migration secret in Firebase config (firebase functions:config:set migration.secret="your-secret-key")
- [ ] T043 [US4] Execute migration function in production (curl POST to function URL with bearer token, monitor Cloud Functions logs, verify migration summary)
- [ ] T044 [US4] Verify migration results in Firestore (check all trips have allowedCurrencies field, verify counts match migration summary)

**Documentation**:
- [ ] T045 [P] [US4] Update quickstart.md with migration testing instructions in specs/011-trip-multi-currency/quickstart.md (add section on running migration locally with emulator, add verification steps)

**Checkpoint**: All user stories (1, 2, 3, 4) should now be complete - new multi-currency selection works, legacy trips migrated

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Quality improvements, documentation, and final validation

- [ ] T046 [P] Run flutter analyze and fix any linting warnings
- [ ] T047 [P] Run flutter format . to format all Dart code
- [ ] T048 Run flutter test --coverage to verify code coverage meets 80% for business logic
- [ ] T049 [P] Update feature CLAUDE.md documentation in specs/011-trip-multi-currency/CLAUDE.md (architecture overview, key components, testing strategy)
- [ ] T050 [P] Update feature CHANGELOG.md in specs/011-trip-multi-currency/CHANGELOG.md (log all major changes during implementation)
- [ ] T051 Test complete user journey on mobile viewport (375x667px): create trip with 3 currencies → create expenses in each currency → view per-currency settlements → verify UX is smooth
- [ ] T052 [P] Add golden tests for MultiCurrencySelector widget in test/features/trips/presentation/widgets/multi_currency_selector_golden_test.dart (capture visual regression test snapshots)
- [ ] T053 Performance benchmark: measure currency dropdown filter time (<100ms target per SC-005)
- [ ] T054 Performance benchmark: measure trip update propagation (<500ms target per SC-006)
- [ ] T055 Verify all acceptance scenarios from spec.md user stories pass
- [ ] T056 [P] Run quickstart.md validation steps to verify feature works end-to-end
- [ ] T056a Manually measure currency selection time with stopwatch (create trip → open currency selector → add 3 currencies → reorder → save) to validate SC-001 target of <30 seconds
- [ ] T056b Run accessibility audit with screen reader (VoiceOver on iOS/macOS or TalkBack on Android) to verify semantic labels on currency chips, up/down arrow buttons, and "Add Currency" button

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3-6)**: All depend on Foundational phase completion
  - User Story 1 (P1) and User Story 2 (P1) can proceed in parallel after foundational
  - User Story 3 (P2) depends on User Story 1 and 2 being complete (needs trip currencies and expenses)
  - User Story 4 (P2) can proceed in parallel with User Story 3
- **Polish (Phase 7)**: Depends on all desired user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2) - No dependencies on other stories
- **User Story 2 (P1)**: Depends on User Story 1 (needs trip.allowedCurrencies to filter dropdown)
- **User Story 3 (P2)**: Depends on User Story 1 and 2 (needs trip currencies and expenses created)
- **User Story 4 (P2)**: Can start after Foundational (Phase 2) - Independent from other stories (server-side migration)

### Within Each User Story

- **TDD Cycle**: Tests MUST be written and FAIL before implementation
- Models before services
- Services before UI
- Core implementation before integration
- Story complete before moving to next priority

### Parallel Opportunities

- **Phase 1**: All Setup tasks can run in parallel (T001-T003)
- **Phase 2**: Domain model updates (T004-T006) can run in parallel, then repository updates (T007-T010)
- **Phase 3**: All US1 tests (T011-T015) can be written in parallel
- **Phase 4**: All US2 tests (T021-T022) can be written in parallel
- **Phase 5**: All US3 tests (T027-T028) can be written in parallel
- **Phase 6**: US4 test (T034) standalone, Firebase setup tasks (T035-T037) can run in parallel
- **Phase 7**: Most polish tasks marked [P] can run in parallel (T046-T047, T049-T050, T052)
- **Cross-Story**: User Story 4 (migration) can be developed in parallel with User Story 3 (settlements)

---

## Parallel Example: User Story 1

```bash
# Write all tests for User Story 1 together (TDD - FAIL first):
Task T011: "Unit test for Trip model validation"
Task T012: "Unit test for TripModel serialization"
Task T013: "Unit test for TripRepository.getAllowedCurrencies()"
Task T014: "Unit test for TripRepository.updateAllowedCurrencies()"
Task T015: "Widget test for MultiCurrencySelector"

# After tests written and failing, implement in sequence:
Task T016: "Create MultiCurrencySelector widget"
Task T017: "Add updateTripCurrencies() to TripCubit"
Task T018: "Unit test for TripCubit.updateTripCurrencies()"
Task T019: "Add currency selector to trip settings page"
Task T020: "Add activity logging"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (localization strings)
2. Complete Phase 2: Foundational (domain model, repository, exceptions)
3. Complete Phase 3: User Story 1 (select multiple trip currencies)
4. **STOP and VALIDATE**: Test User Story 1 independently
5. Deploy/demo if ready

**MVP Deliverable**: Users can select 2-5 currencies for a trip, reducing cognitive load by filtering 170+ currencies to a manageable set

### Incremental Delivery

1. Complete Setup + Foundational → Foundation ready
2. Add User Story 1 (P1) → Test independently → Deploy/Demo (MVP!)
3. Add User Story 2 (P1) → Test independently → Deploy/Demo (expense filtering working)
4. Add User Story 3 (P2) → Test independently → Deploy/Demo (per-currency settlements working)
5. Add User Story 4 (P2) → Run migration → Deploy/Demo (legacy trips migrated)
6. Each story adds value without breaking previous stories

### Parallel Team Strategy

With multiple developers:

1. Team completes Setup + Foundational together
2. Once Foundational is done:
   - Developer A: User Story 1 (trip currency selection)
   - Developer B: User Story 4 (migration Cloud Function - independent)
3. After User Story 1 complete:
   - Developer A: User Story 2 (expense filtering - depends on US1)
   - Developer B: User Story 3 (settlements - depends on US1)
4. Stories integrate independently without conflicts

---

## Notes

- **TDD NON-NEGOTIABLE**: Per project constitution, ALL tests must be written BEFORE implementation
- **[P] tasks**: Different files, no dependencies, can run in parallel
- **[Story] label**: Maps task to specific user story (US1, US2, US3, US4) for traceability
- **Each user story independently testable**: Can stop at any checkpoint to validate story works standalone
- **Mobile-first**: All UI tasks should be tested on 375x667px viewport FIRST
- **Commit frequently**: After each task or logical group of related tasks
- **Code quality**: Run flutter analyze and flutter format before each commit
- **Performance**: Measure against success criteria (SC-005: <100ms dropdown, SC-006: <500ms update)

---

**Task Breakdown Version**: 1.0 | **Created**: 2025-11-02 | **Status**: Ready for Implementation
