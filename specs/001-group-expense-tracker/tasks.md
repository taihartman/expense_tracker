# Tasks: Group Expense Tracker for Trips

**Input**: Design documents from `/specs/001-group-expense-tracker/`
**Prerequisites**: plan.md (tech stack), spec.md (user stories), research.md (decisions), data-model.md (entities), contracts/ (Firestore schema)

**Tests**: Test tasks included per constitutional requirement (Principle I: TDD mandatory)

**Organization**: Tasks grouped by user story to enable independent implementation and testing.

## Format: `[ID] [P?] [Story] Description`
- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2, US3, US4, US5, US6)
- Include exact file paths in descriptions

## Path Conventions
- **Flutter project**: `lib/` for source, `test/` for tests, `functions/` for Cloud Functions
- Following clean architecture: `lib/features/{feature}/domain|data|presentation`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and Firebase configuration

- [X] T001 Initialize Firebase project and configure FlutterFire (run `flutterfire configure`)
- [X] T002 [P] Add required dependencies to pubspec.yaml (flutter_bloc, cloud_firestore, firebase_auth, firebase_functions, decimal, fl_chart, intl, go_router)
- [X] T003 [P] Configure Firebase Firestore security rules in firestore.rules
- [X] T004 [P] Configure Firestore indexes in firestore.indexes.json per contracts/firestore-schema.md
- [X] T005 [P] Setup Material Design 3 theme with 8px grid in lib/core/theme/app_theme.dart
- [X] T006 [P] Create app router configuration in lib/core/router/app_router.dart with go_router
- [X] T007 [P] Initialize Firebase in lib/main.dart and setup app structure
- [X] T008 [P] Create Decimal helper utilities in lib/core/utils/decimal_helpers.dart
- [X] T009 [P] Define currency formatters (USD 2dp, VND 0dp) in lib/core/utils/formatters.dart
- [X] T010 [P] Create fixed participants list constant in lib/core/constants/participants.dart
- [X] T011 [P] Create default categories constant in lib/core/constants/categories.dart
- [ ] T012 [P] Setup Firebase Emulators configuration for local testing
- [X] T013 [P] Configure analysis_options.yaml with Flutter/Dart linting rules (zero tolerance)
- [X] T014 [P] Initialize Cloud Functions project in functions/ directory with TypeScript

**Checkpoint**: Project structure ready, Firebase configured, development environment operational

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core domain models and shared services that ALL user stories depend on

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [X] T015 Create Trip domain entity in lib/features/trips/domain/models/trip.dart with Decimal support
- [X] T016 [P] Create Participant value object in lib/core/models/participant.dart (id, name)
- [X] T017 [P] Create CurrencyCode enum in lib/core/models/currency_code.dart (USD, VND)
- [X] T018 [P] Create SplitType enum in lib/core/models/split_type.dart (Equal, Weighted)
- [X] T019 Create Trip Firestore model in lib/features/trips/data/models/trip_model.dart (toJson/fromJson)
- [X] T020 Define TripRepository interface in lib/features/trips/domain/repositories/trip_repository.dart
- [X] T021 Implement TripRepositoryImpl with Firestore in lib/features/trips/data/repositories/trip_repository_impl.dart
- [X] T022 [P] Create Firestore service wrapper in lib/shared/services/firestore_service.dart
- [X] T023 [P] Create base UI components (CustomButton, CustomTextField, LoadingIndicator) in lib/shared/widgets/
- [X] T024 Create error handling utilities in lib/core/utils/error_handler.dart

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - Record Trip Expenses (Priority: P1) 🎯 MVP

**Goal**: Users can create trips and record expenses with payer, amount, currency, split type, and participants

**Independent Test**: Create trip → Add 5 expenses with different payers → Verify all expenses stored and displayed

### Tests for User Story 1 (TDD - Write FIRST)

**IMPORTANT**: These tests must FAIL before implementation

- [X] T025 [P] [US1] Unit test for Expense.calculateShares() equal split in test/unit/features/expenses/expense_split_test.dart
- [X] T026 [P] [US1] Unit test for Expense.calculateShares() weighted split in test/unit/features/expenses/expense_split_test.dart
- [X] T027 [P] [US1] Unit test for expense validation rules in test/unit/features/expenses/expense_validation_test.dart
- [ ] T028 [P] [US1] Widget test for ExpenseForm in test/widget/features/expenses/expense_form_test.dart
- [ ] T029 [P] [US1] Widget test for ExpenseCard in test/widget/features/expenses/expense_card_test.dart
- [ ] T030 [US1] Integration test for create trip → add expense flow in test/integration/flows/record_expense_flow_test.dart

### Implementation for User Story 1

- [X] T031 [P] [US1] Create Expense domain entity in lib/features/expenses/domain/models/expense.dart with calculateShares() method
- [X] T032 [P] [US1] Create Category domain entity in lib/features/categories/domain/models/category.dart
- [X] T033 [P] [US1] Create Expense Firestore model in lib/features/expenses/data/models/expense_model.dart
- [X] T034 [P] [US1] Create Category Firestore model in lib/features/categories/data/models/category_model.dart
- [X] T035 [US1] Define ExpenseRepository interface in lib/features/expenses/domain/repositories/expense_repository.dart
- [X] T036 [US1] Implement ExpenseRepositoryImpl in lib/features/expenses/data/repositories/expense_repository_impl.dart
- [X] T037 [P] [US1] Define CategoryRepository interface in lib/features/categories/domain/repositories/category_repository.dart
- [X] T038 [P] [US1] Implement CategoryRepositoryImpl in lib/features/categories/data/repositories/category_repository_impl.dart
- [X] T039 [US1] Create TripCubit for trip selection state in lib/features/trips/presentation/cubits/trip_cubit.dart
- [X] T040 [US1] Create ExpenseCubit for expense management in lib/features/expenses/presentation/cubits/expense_cubit.dart
- [X] T041 [P] [US1] Create TripSelectorWidget in lib/features/trips/presentation/widgets/trip_selector.dart
- [X] T042 [P] [US1] Create ExpenseFormPage with split type selection in lib/features/expenses/presentation/pages/expense_form_page.dart
- [X] T043 [P] [US1] Create ExpenseListPage in lib/features/expenses/presentation/pages/expense_list_page.dart
- [X] T044 [P] [US1] Create ExpenseCard widget in lib/features/expenses/presentation/widgets/expense_card.dart
- [X] T045 [US1] Create ParticipantSelector widget (checkboxes for Equal, weight inputs for Weighted) in lib/features/expenses/presentation/widgets/participant_selector.dart
- [X] T046 [US1] Implement expense input validation (client-side) in expense form
- [X] T047 [US1] Add loading states and error handling to ExpenseCubit
- [X] T048 [US1] Seed default categories on trip creation
- [X] T049 [US1] Run all US1 tests and verify they PASS

**Checkpoint**: Users can create trips, record expenses with various split types, and view expense list ✅

---

## Phase 4: User Story 2 - View Settlement Summary (Priority: P1) 🎯 MVP

**Goal**: Users can view calculated settlement showing who owes whom with pairwise netting and minimal transfers

**Independent Test**: Enter sample expenses with different payers → View settlement summary → Verify net balances and minimal transfers correct

### Tests for User Story 2 (TDD - Write FIRST)

- [ ] T050 [P] [US2] Unit test for pairwise debt calculation algorithm in test/unit/features/settlements/pairwise_debt_test.dart
- [ ] T051 [P] [US2] Unit test for debt netting algorithm in test/unit/features/settlements/debt_netting_test.dart
- [ ] T052 [P] [US2] Unit test for minimal settlement greedy algorithm in test/unit/features/settlements/minimal_settlement_test.dart
- [ ] T053 [P] [US2] Unit test for settlement validation (sum of nets = 0) in test/unit/features/settlements/settlement_validation_test.dart
- [ ] T054 [P] [US2] Widget test for SettlementSummaryTable in test/widget/features/settlements/settlement_summary_table_test.dart
- [ ] T055 [P] [US2] Widget test for TransferListWidget in test/widget/features/settlements/transfer_list_test.dart
- [ ] T056 [US2] Integration test for expense entry → settlement calculation flow in test/integration/flows/settlement_calculation_flow_test.dart

### Implementation for User Story 2

- [X] T057 [P] [US2] Create SettlementSummary domain entity in lib/features/settlements/domain/models/settlement_summary.dart
- [X] T058 [P] [US2] Create PersonSummary value object in lib/features/settlements/domain/models/person_summary.dart
- [X] T059 [P] [US2] Create PairwiseDebt entity in lib/features/settlements/domain/models/pairwise_debt.dart
- [X] T060 [P] [US2] Create MinimalTransfer entity in lib/features/settlements/domain/models/minimal_transfer.dart
- [X] T061 [US2] Create Firestore models for computed settlement collections in lib/features/settlements/data/models/
- [X] T062 [US2] Implement settlement calculation service in lib/features/settlements/domain/services/settlement_calculator.dart (pairwise, netting, minimal algorithms)
- [ ] T063 [US2] Create Cloud Function: onExpenseWrite trigger in functions/src/compute-settlement.ts
- [ ] T064 [P] [US2] Create Cloud Function: getSettlement callable in functions/src/get-settlement.ts
- [ ] T065 [US2] Implement currency conversion logic with FX rate fallback in settlement calculator
- [X] T066 [US2] Define SettlementRepository interface in lib/features/settlements/domain/repositories/settlement_repository.dart
- [X] T067 [US2] Implement SettlementRepositoryImpl in lib/features/settlements/data/repositories/settlement_repository_impl.dart
- [X] T068 [US2] Create SettlementCubit in lib/features/settlements/presentation/cubits/settlement_cubit.dart
- [X] T069 [P] [US2] Create SettlementSummaryPage in lib/features/settlements/presentation/pages/settlement_summary_page.dart
- [X] T070 [P] [US2] Create AllPeopleSummaryTable widget with color coding (green/red) in lib/features/settlements/presentation/widgets/all_people_summary_table.dart
- [ ] T071 [P] [US2] Create PairwiseNettedView in lib/features/settlements/presentation/widgets/pairwise_netted_view.dart
- [X] T072 [P] [US2] Create MinimalTransfersView in lib/features/settlements/presentation/widgets/minimal_transfers_view.dart
- [X] T073 [US2] Implement copy-to-clipboard for settlement transfers
- [ ] T074 [US2] Deploy Cloud Functions to Firebase
- [ ] T075 [US2] Add settlement calculation performance benchmark test (100 expenses < 2s requirement) in test/performance/settlement_benchmark_test.dart
- [ ] T076 [US2] Run all US2 tests and verify they PASS

**Checkpoint**: Users can view complete settlement calculations with optimal transfer plans ✅

---

## Phase 5: User Story 3 - Multi-Currency Support (Priority: P2)

**Goal**: Users can record expenses in USD or VND and set exchange rates for accurate base currency conversion

**Independent Test**: Create trip with base USD → Add expenses in both USD and VND → Enter exchange rates → Verify settlements convert correctly

### Tests for User Story 3 (TDD - Write FIRST)

- [ ] T077 [P] [US3] Unit test for FX rate matching logic (exact date, any date, reciprocal, same currency) in test/unit/features/exchange_rates/fx_rate_matcher_test.dart
- [ ] T078 [P] [US3] Unit test for currency conversion with Decimal precision in test/unit/features/exchange_rates/currency_conversion_test.dart
- [ ] T079 [P] [US3] Widget test for FxRateForm in test/widget/features/exchange_rates/fx_rate_form_test.dart
- [ ] T080 [P] [US3] Widget test for FxRateTable in test/widget/features/exchange_rates/fx_rate_table_test.dart
- [ ] T081 [US3] Integration test for multi-currency expense workflow in test/integration/flows/multi_currency_flow_test.dart

### Implementation for User Story 3

- [ ] T082 [P] [US3] Create ExchangeRate domain entity in lib/features/exchange_rates/domain/models/exchange_rate.dart
- [ ] T083 [P] [US3] Create RateSource enum in lib/core/models/rate_source.dart (Manual)
- [ ] T084 [P] [US3] Create ExchangeRate Firestore model in lib/features/exchange_rates/data/models/exchange_rate_model.dart
- [ ] T085 [US3] Implement FX rate matching service in lib/features/exchange_rates/domain/services/fx_rate_matcher.dart
- [ ] T086 [US3] Implement currency converter service in lib/features/exchange_rates/domain/services/currency_converter.dart
- [ ] T087 [US3] Define ExchangeRateRepository interface in lib/features/exchange_rates/domain/repositories/exchange_rate_repository.dart
- [ ] T088 [US3] Implement ExchangeRateRepositoryImpl in lib/features/exchange_rates/data/repositories/exchange_rate_repository_impl.dart
- [ ] T089 [US3] Create ExchangeRateCubit in lib/features/exchange_rates/presentation/cubits/exchange_rate_cubit.dart
- [ ] T090 [P] [US3] Create FxRateManagementPage in lib/features/exchange_rates/presentation/pages/fx_rate_management_page.dart
- [ ] T091 [P] [US3] Create FxRateForm widget in lib/features/exchange_rates/presentation/widgets/fx_rate_form.dart
- [ ] T092 [P] [US3] Create FxRateTable widget in lib/features/exchange_rates/presentation/widgets/fx_rate_table.dart
- [ ] T093 [US3] Update ExpenseForm to show currency selector (USD/VND)
- [ ] T094 [US3] Add FX rate prompt when recording expense in non-base currency
- [ ] T095 [US3] Update settlement calculator to use currency converter
- [ ] T096 [US3] Update Cloud Function to handle multi-currency conversion
- [ ] T097 [US3] Run all US3 tests and verify they PASS

**Checkpoint**: Users can manage multiple currencies with manual exchange rates ✅

---

## Phase 6: User Story 4 - Manage Multiple Trips (Priority: P2)

**Goal**: Users can create multiple trips, switch between them, and keep data isolated per trip

**Independent Test**: Create 3 trips with different names → Add expenses to each → Switch trips → Verify data isolation

### Tests for User Story 4 (TDD - Write FIRST)

- [ ] T098 [P] [US4] Unit test for trip switching logic in test/unit/features/trips/trip_switching_test.dart
- [ ] T099 [P] [US4] Unit test for trip data isolation in test/unit/features/trips/trip_isolation_test.dart
- [ ] T100 [P] [US4] Widget test for TripCard in test/widget/features/trips/trip_card_test.dart
- [ ] T101 [P] [US4] Widget test for TripCreateForm in test/widget/features/trips/trip_create_form_test.dart
- [ ] T102 [US4] Integration test for multi-trip workflow in test/integration/flows/multi_trip_flow_test.dart

### Implementation for User Story 4

- [ ] T103 [US4] Update TripCubit to handle multiple trips and trip selection state
- [ ] T104 [P] [US4] Create TripListPage in lib/features/trips/presentation/pages/trip_list_page.dart
- [ ] T105 [P] [US4] Create TripCard widget in lib/features/trips/presentation/widgets/trip_card.dart
- [ ] T106 [P] [US4] Create TripCreatePage in lib/features/trips/presentation/pages/trip_create_page.dart
- [ ] T107 [P] [US4] Create TripCreateForm widget with base currency selector in lib/features/trips/presentation/widgets/trip_create_form.dart
- [ ] T108 [US4] Update TripSelector to show current trip name and base currency pill
- [ ] T109 [US4] Update all Cubits to filter data by selected tripId
- [ ] T110 [US4] Update router to include trip selection in navigation state
- [ ] T111 [US4] Add trip switching confirmation if user has unsaved changes
- [ ] T112 [US4] Run all US4 tests and verify they PASS

**Checkpoint**: Users can manage and switch between multiple trips with isolated data ✅

---

## Phase 7: User Story 5 - Categorize Expenses (Priority: P3)

**Goal**: Users can assign categories to expenses and view spending breakdowns by category with pie charts

**Independent Test**: Add expenses with different categories → View person dashboard → Verify category pie chart shows correct breakdown

### Tests for User Story 5 (TDD - Write FIRST)

- [ ] T113 [P] [US5] Unit test for category spending aggregation in test/unit/features/categories/category_aggregation_test.dart
- [ ] T114 [P] [US5] Unit test for category validation in test/unit/features/categories/category_validation_test.dart
- [ ] T115 [P] [US5] Widget test for CategorySelector in test/widget/features/categories/category_selector_test.dart
- [ ] T116 [P] [US5] Widget test for CategoryForm in test/widget/features/categories/category_form_test.dart
- [ ] T117 [P] [US5] Widget test for CategoryPieChart in test/widget/features/settlements/category_pie_chart_test.dart
- [ ] T118 [US5] Integration test for categorized expense workflow in test/integration/flows/categorized_expense_flow_test.dart

### Implementation for User Story 5

- [ ] T119 [US5] Update CategoryCubit in lib/features/categories/presentation/cubits/category_cubit.dart for CRUD operations
- [ ] T120 [P] [US5] Create CategoryManagementPage in lib/features/categories/presentation/pages/category_management_page.dart
- [ ] T121 [P] [US5] Create CategoryForm widget with icon and color pickers in lib/features/categories/presentation/widgets/category_form.dart
- [ ] T122 [P] [US5] Create CategorySelector widget for expense form in lib/features/categories/presentation/widgets/category_selector.dart
- [ ] T123 [US5] Update ExpenseForm to include category selection dropdown
- [ ] T124 [US5] Create category spending aggregation service in lib/features/settlements/domain/services/category_aggregator.dart
- [ ] T125 [P] [US5] Create CategoryPieChart widget using fl_chart in lib/features/settlements/presentation/widgets/category_pie_chart.dart
- [ ] T126 [US5] Update SettlementSummaryPage to include category breakdowns
- [ ] T127 [US5] Add category filter to ExpenseListPage
- [ ] T128 [US5] Run all US5 tests and verify they PASS

**Checkpoint**: Users can categorize expenses and view spending analysis by category ✅

---

## Phase 8: User Story 6 - Individual Spending Dashboards (Priority: P3)

**Goal**: Users can view personalized spending summaries with color-coded net balances and category charts

**Independent Test**: Record expenses with various payers → View each person's dashboard → Verify personal summaries and color coding correct

### Tests for User Story 6 (TDD - Write FIRST)

- [ ] T129 [P] [US6] Unit test for person summary calculation in test/unit/features/settlements/person_summary_test.dart
- [ ] T130 [P] [US6] Widget test for PersonMiniCard in test/widget/features/settlements/person_mini_card_test.dart
- [ ] T131 [P] [US6] Widget test for PersonDashboard in test/widget/features/settlements/person_dashboard_test.dart
- [ ] T132 [US6] Golden test for dashboard color coding (green/red nets) in test/golden/settlement_color_coding_golden_test.dart

### Implementation for User Story 6

- [ ] T133 [P] [US6] Create PersonMiniCard widget with summary (paid/owed/net) in lib/features/settlements/presentation/widgets/person_mini_card.dart
- [ ] T134 [P] [US6] Create PersonDashboard widget with category pie chart in lib/features/settlements/presentation/widgets/person_dashboard.dart
- [ ] T135 [US6] Update AllPeopleSummaryTable to include color coding (green for positive net, red for negative)
- [ ] T136 [US6] Create PersonDashboardPage for detailed individual view in lib/features/settlements/presentation/pages/person_dashboard_page.dart
- [ ] T137 [US6] Add person selection to router for dashboard navigation
- [ ] T138 [US6] Implement color theming for positive/negative net balances in theme
- [ ] T139 [US6] Run all US6 tests and verify they PASS
- [ ] T140 [US6] Generate golden file baselines for visual regression tests

**Checkpoint**: Users have rich, personalized spending dashboards with visual analytics ✅

---

## Phase 9: Polish & Cross-Cutting Concerns

**Purpose**: Final quality improvements, optimization, and production readiness

- [ ] T141 [P] Add comprehensive error handling with user-friendly messages across all forms
- [ ] T142 [P] Add loading indicators (>300ms operations) across all async operations
- [ ] T143 [P] Implement offline persistence with Firestore cache
- [ ] T144 [P] Add accessibility labels and semantic widgets for screen readers
- [ ] T145 [P] Ensure all touch targets meet 44x44px minimum (accessibility)
- [ ] T146 [P] Add responsive breakpoints for mobile (375px), tablet (768px), desktop (1920px)
- [ ] T147 [P] Optimize bundle size (tree shaking, code splitting) - target <500KB gzipped
- [ ] T148 [P] Add comprehensive logging for all Firestore operations and Cloud Functions
- [ ] T149 [P] Create user help text for complex features (weighted splits, exchange rates)
- [ ] T150 [P] Add confirmation dialogs for destructive actions
- [ ] T151 Verify all tests pass with >80% business logic coverage, >60% overall coverage
- [ ] T152 Run `flutter analyze` and ensure zero warnings
- [ ] T153 Run performance profiling and verify <2s initial load on 3G
- [ ] T154 Verify settlement calculation benchmark (<2s for 100+ expenses)
- [ ] T155 Deploy Firestore security rules and indexes to production
- [ ] T156 Build production bundle and verify size meets <500KB target
- [ ] T157 Deploy to Firebase Hosting staging environment
- [ ] T158 Conduct end-to-end smoke testing on staging
- [ ] T159 Deploy to production Firebase Hosting
- [ ] T160 Update README.md with setup instructions and feature documentation

**Checkpoint**: Application is production-ready with full quality compliance ✅

---

## Dependencies & Execution Strategy

### User Story Dependencies

```
Foundation (Phase 2) → MUST complete before any user stories

User Story 1 (P1) → Independent (can start after Foundation)
User Story 2 (P1) → Depends on US1 (needs expenses to calculate settlements)
User Story 3 (P2) → Depends on US1, US2 (extends existing expense/settlement)
User Story 4 (P2) → Independent of US2, US3 (just UI/state management)
User Story 5 (P3) → Depends on US1 (needs expenses to categorize)
User Story 6 (P3) → Depends on US2, US5 (needs settlements and categories for dashboards)

Polish (Phase 9) → After all user stories complete
```

### Recommended MVP Scope

**MVP = Phase 1 (Setup) + Phase 2 (Foundation) + Phase 3 (US1) + Phase 4 (US2)**

This delivers core value: Record expenses + View settlements

Additional stories can be delivered incrementally.

### Parallel Execution Examples

**Phase 1 (Setup)**: Can run T002-T014 in parallel (independent setup tasks)

**Phase 2 (Foundation)**: Can run T016-T018, T019-T021, T022-T024 in parallel groups

**Phase 3 (US1)**:
- Tests T025-T029 can run in parallel (different test files)
- Domain models T031-T034 can run in parallel
- Repositories T035-T038 can run in parallel
- Widgets T041-T044 can run in parallel

**Phase 4 (US2)**:
- Tests T050-T055 can run in parallel
- Domain entities T057-T060 can run in parallel
- Widgets T069-T072 can run in parallel

**Phase 5-8**: Similar parallelization within each story

**Phase 9 (Polish)**: Most tasks T141-T150 can run in parallel

### Constitutional Compliance Checkpoints

After each phase, verify:
- ✅ All tests pass (TDD cycle followed)
- ✅ Code coverage ≥ 80% business logic, ≥ 60% overall
- ✅ `flutter analyze` returns zero warnings
- ✅ All functions have cyclomatic complexity ≤ 10
- ✅ Public APIs have documentation comments
- ✅ Performance benchmarks meet targets

---

## Summary

**Total Tasks**: 160
- Setup (Phase 1): 14 tasks
- Foundation (Phase 2): 10 tasks
- US1 (P1): 25 tasks (including 6 test tasks)
- US2 (P1): 27 tasks (including 7 test tasks)
- US3 (P2): 21 tasks (including 5 test tasks)
- US4 (P2): 15 tasks (including 5 test tasks)
- US5 (P3): 16 tasks (including 6 test tasks)
- US6 (P3): 12 tasks (including 4 test tasks)
- Polish (Phase 9): 20 tasks

**Parallel Opportunities**: ~60% of tasks marked [P] can run in parallel within their phase

**Independent Test Criteria**: Each user story phase includes specific test criteria for independent verification

**Estimated Effort**: MVP (US1+US2) = ~70 tasks, Full feature set = 160 tasks

**Next Step**: Start with Phase 1 (Setup), then proceed through phases in order. Each user story can be delivered as an independent increment after its phase completes.
