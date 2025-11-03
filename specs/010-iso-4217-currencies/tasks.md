# Tasks: ISO 4217 Multi-Currency Support

**Input**: Design documents from `/specs/010-iso-4217-currencies/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md

**Tests**: Following TDD approach per Constitution Principle I - tests MUST be written and pass before implementation.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`
- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3, US4)
- Include exact file paths in descriptions

## Path Conventions
- **Flutter project**: `lib/`, `assets/`, `test/` at repository root
- Following clean architecture: `lib/core/`, `lib/shared/`, `lib/features/`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and currency data source setup

- [X] T001 Create `assets/currencies.json` with 170+ ISO 4217 currency data (code, numericCode, name, symbol, decimalPlaces, active)
- [X] T002 [P] Add `build_runner` dependency to `pubspec.yaml` if not already present
- [X] T003 [P] Add `json_annotation` dependency to `pubspec.yaml` for currency data serialization
- [X] T004 [P] Create `lib/generators/` directory for build_runner generator code
- [X] T005 [P] Configure `build.yaml` with currency code generator build rules

**Checkpoint**: Currency data source and build infrastructure ready

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Code generation system and core currency enum that ALL user stories depend on

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [X] T0*6 Implement `CurrencyCodeGenerator` class in `lib/generators/currency_code_generator.dart` that reads `assets/currencies.json` and generates Dart enum code
- [X] T0*7 Add JSON validation in generator (required fields, 3-letter codes, valid decimal places 0/2/3, no duplicates)
- [X] T0*8 Generate enum values with lowercase names (e.g., USD → CurrencyCode.usd)
- [X] T0*9 Generate `symbol` getter switch statement for all 170+ currencies in generated code
- [X] T0*10 Generate `displayName` getter switch statement for all 170+ currencies in generated code
- [X] T0*11 Generate `isActive` getter switch statement in generated code
- [X] T0*12 Generate `fromString()` static method with case-insensitive parsing and null return for invalid codes
- [X] T0*13 Generate `activeCurrencies` static getter returning list of active currencies only
- [X] T0*14 Add generated code header with timestamp, source file, and "DO NOT MODIFY" warning
- [X] T0*15 Run `dart run build_runner build --delete-conflicting-outputs` to generate `lib/core/models/currency_code.g.dart`
- [X] T0*16 Update `lib/core/models/currency_code.dart` to include `part 'currency_code.g.dart';` and remove hardcoded USD/VND enum values
- [X] T0*17 Verify generated enum compiles without errors (`flutter analyze`)
- [X] T0*18 Add generated `currency_code.g.dart` to git (not .gitignore)

**Checkpoint**: Foundation ready - currency enum with 170+ currencies available, user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - Select Local Currency for Trip (Priority: P1) 🎯 MVP

**Goal**: Users can select any ISO 4217 currency when creating or editing trips, with searchable picker UI

**Independent Test**: Create a new trip, open currency picker, search for "GBP", select "GBP - British Pound Sterling", save trip, verify trip shows GBP as currency

### Tests for User Story 1 (TDD)

**NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [X] T0*19 [P] [US1] Unit test for generated currency enum in `test/core/models/currency_code_test.dart` (verify all 170+ currencies exist, symbols correct, decimal places correct, fromString() works)
- [X] T0*20 [P] [US1] Widget test for CurrencySearchField in `test/shared/widgets/currency_search_field_test.dart` (render, open modal, search, select, close)
- [X] T0*21 [P] [US1] Integration test for trip creation with currency selection in `test/integration/trip_currency_selection_test.dart`

### Implementation for User Story 1

- [X] T0*22 [P] [US1] Create `CurrencySearchField` widget in `lib/shared/widgets/currency_search_field.dart` with basic structure (StatefulWidget, constructor parameters)
- [X] T0*23 [P] [US1] Implement search state management in `_CurrencySearchFieldState` (search query, filtered list, TextEditingController)
- [X] T0*24 [US1] Implement modal bottom sheet presentation in `CurrencySearchField._showCurrencyPicker()` (mobile: full-screen bottom sheet, desktop: centered dialog)
- [X] T0*25 [US1] Implement search bar UI in modal with TextField, clear button, hint text "Search by code or name"
- [X] T0*26 [US1] Implement search filtering logic with case-insensitive matching on code AND displayName, 300ms debounce using Timer
- [X] T0*27 [US1] Implement virtualized currency list with ListView.builder showing filtered results, each item displaying "CODE - Display Name"
- [X] T0*28 [US1] Implement currency selection logic (onTap → close modal → fire onChanged callback)
- [X] T0*29 [US1] Implement empty state UI ("No currencies found" when search has no results)
- [X] T0*30 [US1] Implement accessibility features (keyboard navigation, screen reader labels, 44x44px touch targets, 56px list item height)
- [X] T0*31 [US1] Implement closed field display showing selected currency or hint text with dropdown icon
- [X] T0*32 [US1] Implement form validation support (validator callback, error display)
- [X] T0*33 [US1] Add localized strings to `lib/l10n/app_en.arb` (currencySearchFieldLabel, currencySearchFieldHint, currencySearchPlaceholder, currencySearchNoResults, currencySearchModalTitle)
- [X] T0*34 [US1] Replace DropdownButtonFormField with CurrencySearchField in `lib/features/trips/presentation/pages/trip_create_page.dart`
- [X] T0*35 [US1] Replace DropdownButtonFormField with CurrencySearchField in `lib/features/trips/presentation/pages/trip_edit_page.dart`
- [X] T0*36 [US1] Verify backward compatibility: load existing USD/VND trips and confirm they display correctly
- [X] T0*37 [US1] Run widget tests to verify CurrencySearchField renders and functions correctly
- [X] T0*38 [US1] Run integration test: create trip with GBP currency end-to-end

**Checkpoint**: At this point, User Story 1 should be fully functional - users can select any currency when creating/editing trips with searchable UI

---

## Phase 4: User Story 2 - Enter Expenses with Correct Currency Formatting (Priority: P1)

**Goal**: Expense amount fields automatically format with correct decimal precision (0, 2, or 3 decimals) and thousands separators based on selected currency

**Independent Test**: Create expense in USD (verify 2 decimals, 1,234.50), JPY (verify 0 decimals, 1,234), KWD (verify 3 decimals, 1,234.567)

### Tests for User Story 2 (TDD)

- [X] T0*39 [P] [US2] Unit test for 3-decimal currency formatting in `test/shared/utils/currency_input_formatter_test.dart` (test KWD, BHD, OMR with 3 decimals)
- [X] T0*40 [P] [US2] Widget test for CurrencyTextField with 3-decimal currencies in `test/shared/widgets/currency_text_field_test.dart`
- [X] T0*41 [P] [US2] Integration test for expense creation with various decimal place currencies

### Implementation for User Story 2

- [X] T0*42 [P] [US2] Update `CurrencyInputFormatter` regex in `lib/shared/utils/currency_input_formatter.dart` to support 0, 2, AND 3 decimal places (change from `\d{0,2}` to dynamic based on decimalPlaces)
- [X] T0*43 [P] [US2] Update `formatAmountForInput()` helper in `lib/shared/utils/currency_input_formatter.dart` to handle 3 decimal places
- [X] T0*44 [US2] Update `stripCurrencyFormatting()` helper to correctly handle 3 decimal places
- [X] T0*45 [US2] Update `CurrencyTextField` widget in `lib/shared/widgets/currency_text_field.dart` to read decimalPlaces from selected currency and pass to formatter
- [X] T0*46 [US2] Update `CurrencyFormatters.formatCurrency()` in `lib/core/utils/formatters.dart` to handle 3 decimal places, remove hardcoded switch for USD/VND
- [X] T0*47 [US2] Replace DropdownButtonFormField with CurrencySearchField in `lib/features/expenses/presentation/pages/expense_form_page.dart`
- [X] T0*48 [US2] Replace DropdownButtonFormField with CurrencySearchField in `lib/features/expenses/presentation/widgets/expense_form_bottom_sheet.dart`
- [X] T0*49 [US2] Test USD expense: enter "1234.5" → displays "1,234.50" (2 decimals)
- [X] T0*50 [US2] Test JPY expense: enter "1000000" → displays "1,000,000", prevents decimal entry (0 decimals)
- [X] T0*51 [US2] Test KWD expense: enter "1234.567" → displays "1,234.567" (3 decimals)
- [X] T0*52 [US2] Verify all expense views (list, details, settlements) display amounts with correct currency symbol and decimal precision

**Checkpoint**: At this point, User Stories 1 AND 2 should both work independently - currency selection works AND amount formatting respects currency-specific decimal places

---

## Phase 5: User Story 3 - Efficiently Find Currency from Large List (Priority: P2)

**Goal**: Currency picker search returns relevant results quickly (<1 second) for 170+ item list on mobile

**Independent Test**: Open currency picker, type "eur" → EUR appears within 1 second, type "pound" → GBP and EGP both appear, type "xyz" → "No currencies found" message

### Tests for User Story 3 (TDD)

- [ ] T053 [P] [US3] Performance test for currency search in `test/shared/widgets/currency_search_field_performance_test.dart` (verify <50ms filter time)
- [ ] T054 [P] [US3] Widget test for search edge cases (no results, special characters, very long search term)

### Implementation for User Story 3

- [ ] T055 [P] [US3] Add search performance logging to measure actual filter time in CurrencySearchField
- [ ] T056 [US3] Optimize search algorithm if needed (consider caching, early returns, optimized string matching)
- [ ] T057 [US3] Add search result highlighting (optional enhancement: highlight matched characters in results)
- [ ] T058 [US3] Test search performance on mobile viewport (375x667px) with DevTools
- [ ] T059 [US3] Test virtualized list scrolling FPS on mobile (should maintain 60 FPS)
- [X] T0*60 [US3] Verify memory usage stays under 10MB for modal + list

**Checkpoint**: All search performance targets met - users can find currencies quickly even on mobile devices

---

## Phase 6: User Story 4 - Maintain Compatibility with Existing Data (Priority: P1)

**Goal**: Existing trips and expenses with USD or VND continue to work without migration, errors, or data loss

**Independent Test**: Load trip created with USD before currency expansion → verify displays correctly with $ symbol and 2 decimals, settlements show correct formatting

### Tests for User Story 4 (TDD)

- [X] T0*61 [P] [US4] Backward compatibility test for USD trips in `test/integration/backward_compatibility_test.dart`
- [X] T0*62 [P] [US4] Backward compatibility test for VND expenses
- [X] T0*63 [P] [US4] Backward compatibility test for USD settlements

### Implementation for User Story 4

- [X] T0*64 [P] [US4] Verify `fromString('USD')` returns `CurrencyCode.usd` (not null)
- [X] T0*65 [P] [US4] Verify `fromString('VND')` returns `CurrencyCode.vnd` (not null)
- [X] T0*66 [US4] Verify USD symbol is still "$" and decimalPlaces is 2
- [X] T0*67 [US4] Verify VND symbol is still "₫" and decimalPlaces is 0
- [X] T0*68 [US4] Load sample USD trip from Firestore → verify displays correctly (no migration needed)
- [X] T0*69 [US4] Load sample VND expense from Firestore → verify displays correctly
- [X] T0*70 [US4] Calculate settlement for USD trip → verify amounts show correct formatting
- [X] T0*71 [US4] Run full test suite to ensure no regressions in existing functionality

**Checkpoint**: All existing data works correctly - 100% backward compatibility achieved

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Final improvements, documentation, and production readiness

- [X] T0*72 [P] Update unit tests across 27 files to use varied currencies (not just USD/VND) in `test/core/`, `test/shared/`, `test/features/`
- [X] T0*73 [P] Add comprehensive test coverage for 3-decimal currencies (BHD, KWD, OMR, TND, JOD) across all tests
- [X] T0*74 [P] Update generator tests in `test/generators/currency_code_generator_test.dart` (verify JSON validation, enum generation, error handling)
- [X] T0*75 [P] Add documentation comments to CurrencySearchField public API
- [X] T0*76 [P] Add documentation comments to currency generator code
- [X] T0*77 [P] Update CLAUDE.md currency section with new 170+ currency support and code generation approach
- [X] T0*78 [P] Create feature documentation using `/docs.create` command
- [X] T0*79 Run `flutter analyze` to verify no lint warnings
- [X] T0*80 Run `flutter format .` to format all code
- [X] T0*81 Run full test suite: `flutter test` to verify all tests pass
- [X] T0*82 Test on mobile viewport (375x667px) in Chrome DevTools - verify all UI works correctly
- [X] T0*83 Test on desktop viewport (1920x1080) - verify responsive behavior
- [X] T0*84 Manual smoke test: Create trip → select EUR → create expense in EUR → verify formatting → calculate settlements
- [X] T0*85 Manual edge case test: Select 3-decimal currency (KWD) → create expense → verify 3 decimals work
- [X] T0*86 Performance benchmark: Measure currency picker search time (should be <50ms)
- [X] T0*87 Bundle size check: Verify generated code adds <100KB and currencies.json adds <50KB
- [X] T0*88 Run quickstart.md validation: Follow maintenance guide to add a test currency, verify process works
- [X] T0*89 Use `/docs.log` to document all changes made during implementation
- [X] T0*90 Use `/docs.complete` to mark feature as complete and roll up to root CHANGELOG.md

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion (T001-T005) - BLOCKS all user stories
- **User Story 1 (Phase 3)**: Depends on Foundational completion (T006-T018) - Can proceed independently
- **User Story 2 (Phase 4)**: Depends on Foundational completion (T006-T018) - Can proceed independently, but makes sense after US1 for UX continuity
- **User Story 3 (Phase 5)**: Depends on User Story 1 completion (T022-T038) - Enhances the search widget created in US1
- **User Story 4 (Phase 6)**: Depends on Foundational completion (T006-T018) - Can proceed independently
- **Polish (Phase 7)**: Depends on all desired user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2) - No dependencies on other stories ✅ INDEPENDENT
- **User Story 2 (P1)**: Can start after Foundational (Phase 2) - Technically independent but reuses CurrencySearchField from US1 for better UX
- **User Story 3 (P2)**: Depends on User Story 1 (enhances search performance of the picker created in US1)
- **User Story 4 (P1)**: Can start after Foundational (Phase 2) - No dependencies on other stories ✅ INDEPENDENT

### Within Each User Story

- Tests MUST be written and FAIL before implementation (TDD per Constitution Principle I)
- Models/generators before widgets
- Widgets before pages
- Unit tests before integration tests
- Core implementation before edge cases
- Story complete and validated before moving to next priority

### Parallel Opportunities

- **Phase 1**: T002, T003, T004, T005 can all run in parallel
- **Phase 2**: Many tasks can run in parallel (T007-T014 generator implementation)
- **User Story 1 Tests**: T019, T020, T021 can run in parallel (different test files)
- **User Story 1 Implementation**: T022, T023 can run in parallel (different concerns in same widget)
- **User Story 2 Tests**: T039, T040, T041 can run in parallel
- **User Story 2 Implementation**: T042, T043, T044 can run in parallel (different helper functions)
- **User Story 3 Tests**: T053, T054 can run in parallel
- **User Story 3 Implementation**: T055, T056 can run in parallel if optimizations are independent
- **User Story 4 Tests**: T061, T062, T063 can run in parallel
- **User Story 4 Implementation**: T064, T065, T066, T067 can run in parallel (independent verification tasks)
- **Phase 7 Polish**: Most tasks (T072-T079) can run in parallel (different files/concerns)
- **Different user stories can be worked on in parallel by different team members** (after Foundational phase)

---

## Parallel Example: User Story 1

```bash
# Launch all tests for User Story 1 together:
Task: "Unit test for generated currency enum in test/core/models/currency_code_test.dart"
Task: "Widget test for CurrencySearchField in test/shared/widgets/currency_search_field_test.dart"
Task: "Integration test for trip creation with currency selection in test/integration/trip_currency_selection_test.dart"

# Launch parallel implementation tasks:
Task: "Create CurrencySearchField widget in lib/shared/widgets/currency_search_field.dart"
Task: "Implement search state management in _CurrencySearchFieldState"
```

## Parallel Example: User Story 2

```bash
# Launch all formatter updates together:
Task: "Update CurrencyInputFormatter regex in lib/shared/utils/currency_input_formatter.dart"
Task: "Update formatAmountForInput() helper in lib/shared/utils/currency_input_formatter.dart"
Task: "Update stripCurrencyFormatting() helper"
```

---

## Implementation Strategy

### MVP First (User Story 1 + User Story 4)

1. Complete Phase 1: Setup (T001-T005)
2. Complete Phase 2: Foundational (T006-T018) - CRITICAL - blocks all stories
3. Complete Phase 3: User Story 1 (T019-T038) - Currency selection with search
4. Complete Phase 6: User Story 4 (T061-T071) - Verify backward compatibility
5. **STOP and VALIDATE**: Test independently - can users select currencies and does existing data still work?
6. Deploy/demo if ready - MVP delivers value to users traveling to countries beyond US and Vietnam

### Incremental Delivery

1. Complete Setup + Foundational → Foundation ready (generated enum with 170+ currencies)
2. Add User Story 1 → Test independently → Deploy/Demo (MVP! Users can now select any currency)
3. Add User Story 2 → Test independently → Deploy/Demo (Expenses now format correctly per currency)
4. Add User Story 3 → Test independently → Deploy/Demo (Search performance optimized)
5. Add User Story 4 validation → Deploy/Demo (Confidence in backward compatibility)
6. Polish → Final production-ready release
7. Each story adds value without breaking previous stories

### Parallel Team Strategy

With multiple developers:

1. Team completes Setup + Foundational together
2. Once Foundational is done (T006-T018 complete):
   - Developer A: User Story 1 (T019-T038)
   - Developer B: User Story 2 (T039-T052) - may need to wait for CurrencySearchField widget from US1
   - Developer C: User Story 4 (T061-T071) - can start immediately after foundational
   - Developer D: User Story 3 (T053-T060) - starts after US1 complete
3. Stories complete and integrate independently
4. Team completes Polish phase together

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Each user story should be independently completable and testable
- Verify tests fail before implementing (TDD per Constitution)
- Run `flutter analyze` and `flutter test` frequently
- Use `/docs.log` after each significant task or group of tasks
- Commit generated `currency_code.g.dart` to git (not ignored)
- Stop at any checkpoint to validate story independently
- Mobile-first: Test on 375x667px viewport before considering complete
- Avoid: vague tasks, same file conflicts, skipping tests, breaking backward compatibility

---

## Task Count Summary

- **Total Tasks**: 90
- **Phase 1 (Setup)**: 5 tasks
- **Phase 2 (Foundational)**: 13 tasks (BLOCKING)
- **Phase 3 (User Story 1 - P1)**: 20 tasks (3 tests + 17 implementation)
- **Phase 4 (User Story 2 - P1)**: 14 tasks (3 tests + 11 implementation)
- **Phase 5 (User Story 3 - P2)**: 6 tasks (2 tests + 4 implementation)
- **Phase 6 (User Story 4 - P1)**: 8 tasks (3 tests + 5 implementation)
- **Phase 7 (Polish)**: 19 tasks

**Parallel Opportunities**: 40+ tasks marked [P] can run in parallel within their phases

**MVP Scope**: Phase 1 + 2 + 3 + 6 = 46 tasks (Setup + Foundational + US1 + US4)

**Estimated Timeline**:
- Setup + Foundational: 1 day
- User Story 1: 1 day
- User Story 2: 0.5 days
- User Story 3: 0.5 days
- User Story 4: 0.5 days
- Polish: 0.5 days
- **Total**: 3-4 days

---

**Generated**: 2025-01-30
**Ready for**: Implementation via `/speckit.implement` or manual execution
