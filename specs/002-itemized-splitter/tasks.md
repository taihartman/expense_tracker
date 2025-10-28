---
description: "Implementation tasks for Plates-style itemized expense splitter"
---

# Tasks: Itemized Expense Splitter

**Feature**: Plates-Style Itemized Receipt Splitting
**Branch**: `002-itemized-splitter`
**Input**: Design documents from `/specs/002-itemized-splitter/`
**Prerequisites**: spec.md, plan.md, data-model.md, research.md, contracts/, quickstart.md

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story. Tests MUST be written BEFORE implementation (TDD).

## Format: `- [ ] [T###] [P] [US#] Description`
- **[P]**: Can run in parallel (different files, no dependencies)
- **[US#]**: User story label (US1-US6) - REQUIRED for story phases only
- Include exact file paths in descriptions

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and structure for itemized expense feature

- [ ] T001 [P] Install decimal package dependency in pubspec.yaml (decimal ^2.3.3)
- [ ] T002 [P] Create directory structure /lib/features/expenses/domain/models/itemized/
- [ ] T003 [P] Create directory structure /lib/features/expenses/data/models/itemized/
- [ ] T004 [P] Create directory structure /lib/features/expenses/presentation/pages/itemized/
- [ ] T005 [P] Create directory structure /lib/features/expenses/presentation/widgets/itemized/
- [ ] T006 [P] Create test directory structure /test/unit/expenses/domain/services/
- [ ] T007 [P] Create test directory structure /test/widget/expenses/itemized/
- [ ] T008 [P] Create test directory structure /test/integration/

**Checkpoint**: Directory structure ready for implementation

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [ ] T009 Create ISO 4217 precision lookup service in /lib/core/models/iso_4217_precision.dart
- [ ] T010 [P] Create PercentBase enum in /lib/features/expenses/domain/models/percent_base.dart
- [ ] T011 [P] Create AbsoluteSplitMode enum in /lib/features/expenses/domain/models/absolute_split_mode.dart
- [ ] T012 [P] Create AssignmentMode enum in /lib/features/expenses/domain/models/assignment_mode.dart
- [ ] T013 [P] Create RoundingMode enum in /lib/features/expenses/domain/models/rounding_mode.dart
- [ ] T014 [P] Create RemainderDistributionMode enum in /lib/features/expenses/domain/models/remainder_distribution_mode.dart
- [ ] T015 Extend SplitType enum to include 'itemized' in /lib/core/models/split_type.dart
- [ ] T016 Create DecimalService for currency-aware rounding in /lib/core/services/decimal_service.dart
- [ ] T017 Write tests for ISO 4217 precision lookup in /test/unit/core/models/iso_4217_precision_test.dart
- [ ] T018 Write tests for DecimalService in /test/unit/core/services/decimal_service_test.dart

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - Basic Itemized Split (Priority: P1) 🎯 MVP

**Goal**: Enable users to create itemized expenses with line items, assign items to people (even split), apply basic tax/tip, and produce per-person totals with settlement integration.

**Independent Test**: Create expense with 3-4 items assigned to different people, enter tax percentage, verify per-person totals are correct and settlement calculator consumes them properly.

### Domain Models for US1 (Write Tests FIRST)

- [ ] T019 [P] [US1] Write unit tests for RoundingConfig model in /test/unit/expenses/domain/models/rounding_config_test.dart
- [ ] T020 [P] [US1] Write unit tests for ItemAssignment model in /test/unit/expenses/domain/models/item_assignment_test.dart
- [ ] T021 [P] [US1] Write unit tests for LineItem model in /test/unit/expenses/domain/models/line_item_test.dart
- [ ] T022 [P] [US1] Write unit tests for TaxExtra model in /test/unit/expenses/domain/models/tax_extra_test.dart
- [ ] T023 [P] [US1] Write unit tests for TipExtra model in /test/unit/expenses/domain/models/tip_extra_test.dart
- [ ] T024 [P] [US1] Write unit tests for Extras model in /test/unit/expenses/domain/models/extras_test.dart
- [ ] T025 [P] [US1] Write unit tests for AllocationRule model in /test/unit/expenses/domain/models/allocation_rule_test.dart
- [ ] T026 [P] [US1] Write unit tests for ItemContribution model in /test/unit/expenses/domain/models/item_contribution_test.dart
- [ ] T027 [P] [US1] Write unit tests for ParticipantBreakdown model in /test/unit/expenses/domain/models/participant_breakdown_test.dart
- [ ] T028 [US1] Write unit tests for extended Expense model with itemized fields in /test/unit/expenses/domain/models/expense_test.dart

**VERIFY: All tests above FAIL before proceeding to implementation**

### Domain Models Implementation for US1

- [ ] T029 [P] [US1] Create RoundingConfig model in /lib/features/expenses/domain/models/rounding_config.dart
- [ ] T030 [P] [US1] Create ItemAssignment model in /lib/features/expenses/domain/models/item_assignment.dart
- [ ] T031 [P] [US1] Create LineItem model in /lib/features/expenses/domain/models/line_item.dart
- [ ] T032 [P] [US1] Create TaxExtra model in /lib/features/expenses/domain/models/tax_extra.dart
- [ ] T033 [P] [US1] Create TipExtra model in /lib/features/expenses/domain/models/tip_extra.dart
- [ ] T034 [P] [US1] Create Extras model in /lib/features/expenses/domain/models/extras.dart
- [ ] T035 [P] [US1] Create AllocationRule model in /lib/features/expenses/domain/models/allocation_rule.dart
- [ ] T036 [P] [US1] Create ItemContribution model in /lib/features/expenses/domain/models/item_contribution.dart
- [ ] T037 [P] [US1] Create ParticipantBreakdown model in /lib/features/expenses/domain/models/participant_breakdown.dart
- [ ] T038 [US1] Extend Expense model with optional itemized fields in /lib/features/expenses/domain/models/expense.dart

**VERIFY: All domain model tests now PASS**

### Services for US1 (Write Tests FIRST)

- [ ] T039 [US1] Write unit tests with golden fixtures for ItemizedCalculator in /test/unit/expenses/domain/services/itemized_calculator_test.dart (minimum 10 test scenarios covering basic itemized splits, tax allocation, tip allocation)
- [ ] T040 [US1] Write unit tests for RoundingService in /test/unit/expenses/domain/services/rounding_service_test.dart (test all 4 remainder distribution strategies)

**VERIFY: Service tests FAIL before implementation**

### Services Implementation for US1

- [ ] T041 [US1] Create ItemizedCalculator service in /lib/features/expenses/domain/services/itemized_calculator.dart (calculate per-person item subtotals, apply tax, apply tip, produce ParticipantBreakdown)
- [ ] T042 [US1] Create RoundingService in /lib/features/expenses/domain/services/rounding_service.dart (round to currency precision, distribute remainder using configured strategy)

**VERIFY: Service tests now PASS**

### Data Layer for US1 (Write Tests FIRST)

- [ ] T043 [P] [US1] Write tests for LineItem Firestore serialization in /test/unit/expenses/data/models/line_item_model_test.dart
- [ ] T044 [P] [US1] Write tests for Extras Firestore serialization in /test/unit/expenses/data/models/extras_model_test.dart
- [ ] T045 [P] [US1] Write tests for AllocationRule Firestore serialization in /test/unit/expenses/data/models/allocation_rule_model_test.dart
- [ ] T046 [US1] Write tests for Expense extended serialization in /test/unit/expenses/data/models/expense_model_test.dart (verify backward compatibility with old expenses)

**VERIFY: Data layer tests FAIL before implementation**

### Data Layer Implementation for US1

- [ ] T047 [P] [US1] Create LineItemModel Firestore DTO in /lib/features/expenses/data/models/line_item_model.dart (toFirestore, fromFirestore)
- [ ] T048 [P] [US1] Create ExtrasModel Firestore DTO in /lib/features/expenses/data/models/extras_model.dart (toFirestore, fromFirestore)
- [ ] T049 [P] [US1] Create AllocationRuleModel Firestore DTO in /lib/features/expenses/data/models/allocation_rule_model.dart (toFirestore, fromFirestore)
- [ ] T050 [US1] Extend ExpenseModel to serialize itemized fields in /lib/features/expenses/data/models/expense_model.dart (conditional serialization, backward compatible)

**VERIFY: Data layer tests now PASS**

### State Management for US1 (Write Tests FIRST)

- [ ] T051 [US1] Write BLoC tests for ItemizedExpenseCubit in /test/unit/expenses/presentation/cubits/itemized_expense_cubit_test.dart (test state transitions: Initial -> Editing -> Calculating -> Ready, validation errors)

**VERIFY: Cubit tests FAIL before implementation**

### State Management Implementation for US1

- [ ] T052 [US1] Create ItemizedExpenseState classes in /lib/features/expenses/presentation/cubits/itemized_expense_state.dart (Initial, Editing, Calculating, Ready, Saving, Saved, Error)
- [ ] T053 [US1] Create ItemizedExpenseCubit in /lib/features/expenses/presentation/cubits/itemized_expense_cubit.dart (manage draft state, trigger recalculation, validate, save)

**VERIFY: Cubit tests now PASS**

### UI Implementation for US1 (Write Widget Tests FIRST)

- [ ] T054 [P] [US1] Write widget tests for PeopleStepPage in /test/widget/expenses/itemized/people_step_page_test.dart
- [ ] T055 [P] [US1] Write widget tests for ItemsStepPage in /test/widget/expenses/itemized/items_step_page_test.dart
- [ ] T056 [P] [US1] Write widget tests for ExtrasStepPage in /test/widget/expenses/itemized/extras_step_page_test.dart
- [ ] T057 [P] [US1] Write widget tests for ReviewStepPage in /test/widget/expenses/itemized/review_step_page_test.dart
- [ ] T058 [P] [US1] Write widget tests for LineItemCard in /test/widget/expenses/itemized/line_item_card_test.dart
- [ ] T059 [P] [US1] Write widget tests for PersonBreakdownCard in /test/widget/expenses/itemized/person_breakdown_card_test.dart

**VERIFY: Widget tests FAIL before implementation**

### UI Components for US1

- [ ] T060 [P] [US1] Create LineItemCard widget in /lib/features/expenses/presentation/widgets/itemized/line_item_card.dart (display item name, quantity, price, assignment)
- [ ] T061 [P] [US1] Create ItemAssignmentPicker widget in /lib/features/expenses/presentation/widgets/itemized/item_assignment_picker.dart (even split only for US1)
- [ ] T062 [P] [US1] Create ExtrasForm widget in /lib/features/expenses/presentation/widgets/itemized/extras_form.dart (tax and tip percentage inputs)
- [ ] T063 [P] [US1] Create ReviewSummaryBar widget in /lib/features/expenses/presentation/widgets/itemized/review_summary_bar.dart (show items subtotal, tax, tip, grand total)
- [ ] T064 [P] [US1] Create PersonBreakdownCard widget in /lib/features/expenses/presentation/widgets/itemized/person_breakdown_card.dart (display per-person total with expandable item list)
- [ ] T065 [P] [US1] Create ValidationBanner widget in /lib/features/expenses/presentation/widgets/itemized/validation_banner.dart (show unassigned items, negative totals errors)

### UI Pages for US1

- [ ] T066 [US1] Create ItemizedExpenseFlow wizard coordinator in /lib/features/expenses/presentation/pages/itemized/itemized_expense_flow.dart (4-step navigation, provide ItemizedExpenseCubit)
- [ ] T067 [US1] Create PeopleStepPage in /lib/features/expenses/presentation/pages/itemized/people_step_page.dart (select participants, select payer)
- [ ] T068 [US1] Create ItemsStepPage in /lib/features/expenses/presentation/pages/itemized/items_step_page.dart (add items, assign items to people with even split)
- [ ] T069 [US1] Create ExtrasStepPage in /lib/features/expenses/presentation/pages/itemized/extras_step_page.dart (tax and tip percentage inputs only)
- [ ] T070 [US1] Create ReviewStepPage in /lib/features/expenses/presentation/pages/itemized/review_step_page.dart (summary bar, person breakdown cards, validation, save button)

**VERIFY: Widget tests now PASS**

### Settlement Integration for US1 (Write Tests FIRST)

- [ ] T071 [US1] Write tests for SettlementCalculator itemized expense handling in /test/unit/settlements/settlement_calculator_test.dart (verify it consumes participantAmounts correctly)

**VERIFY: Settlement tests FAIL before implementation**

### Settlement Integration Implementation for US1

- [ ] T072 [US1] Extend SettlementCalculator to consume participantAmounts when splitType is itemized in /lib/features/settlements/domain/services/settlement_calculator.dart (credit payer by amount, debit each participant by participantAmounts[userId])

**VERIFY: Settlement tests now PASS**

### Integration Testing for US1

- [ ] T073 [US1] Write end-to-end integration test in /test/integration/itemized_expense_flow_test.dart (create expense with 3 items, assign to different people, enter tax/tip, verify totals, save, verify settlement)

**VERIFY: Integration test PASSES**

### Entry Point Integration for US1

- [ ] T074 [US1] Add "Itemized (Plates)" option to expense creation flow in /lib/features/expenses/presentation/pages/expense_form_page.dart (split type selector)
- [ ] T075 [US1] Update ExpenseCard to show itemized badge in /lib/features/expenses/presentation/widgets/expense_card.dart (when splitType = itemized)

**Checkpoint**: User Story 1 complete - basic itemized split with even assignment, tax/tip, and settlement integration fully functional

---

## Phase 4: User Story 2 - Custom Item Shares (Priority: P2)

**Goal**: Allow users to assign items with custom percentage shares (e.g., Alice 66.67%, Bob 33.33%) instead of only even splits.

**Independent Test**: Create expense with items using custom share assignments, verify math reflects specified proportions.

### Domain Models for US2 (Write Tests FIRST)

- [ ] T076 [US2] Write tests for ItemAssignment custom shares in /test/unit/expenses/domain/models/item_assignment_test.dart (test percentage normalization, sum validation)

**VERIFY: Custom shares tests FAIL before implementation**

### Domain Models Implementation for US2

- [ ] T077 [US2] Extend ItemAssignment model to support custom shares in /lib/features/expenses/domain/models/item_assignment.dart (add custom constructor, normalize percentages to sum=1.0)

**VERIFY: Custom shares tests now PASS**

### Services for US2 (already supports custom shares via ItemAssignment)

No additional service changes needed - ItemizedCalculator already handles custom shares

### UI Implementation for US2 (Write Widget Tests FIRST)

- [ ] T078 [US2] Write widget tests for CustomSharesInput in /test/widget/expenses/itemized/custom_shares_input_test.dart (test percentage inputs, validation, normalization)

**VERIFY: Widget tests FAIL before implementation**

### UI Components for US2

- [ ] T079 [US2] Create CustomSharesInput widget in /lib/features/expenses/presentation/widgets/itemized/custom_shares_input.dart (percentage input fields per participant, real-time validation showing total = 100%)
- [ ] T080 [US2] Extend ItemAssignmentPicker to support "Custom" mode in /lib/features/expenses/presentation/widgets/itemized/item_assignment_picker.dart (toggle between "Even" and "Custom", show CustomSharesInput when custom)

**VERIFY: Widget tests now PASS**

### Integration Testing for US2

- [ ] T081 [US2] Write integration test for custom shares in /test/integration/itemized_custom_shares_test.dart (create expense with custom share items, verify calculated amounts)

**VERIFY: Integration test PASSES**

**Checkpoint**: User Story 2 complete - custom percentage shares working independently

---

## Phase 5: User Story 3 - Advanced Tax/Tip/Fee Allocation (Priority: P3)

**Goal**: Give users control over allocation bases (tax on taxable items only, tip on post-tax total, fees split evenly or proportionally) and support discounts.

**Independent Test**: Create receipts with specific tax rules, multiple fees, discounts, verify allocation follows configured rules.

### Domain Models for US3 (Write Tests FIRST)

- [ ] T082 [P] [US3] Write tests for FeeExtra model in /test/unit/expenses/domain/models/fee_extra_test.dart (test percent and absolute modes, validate bases)
- [ ] T083 [P] [US3] Write tests for DiscountExtra model in /test/unit/expenses/domain/models/discount_extra_test.dart (test percent and absolute modes, applyBeforeTax flag)

**VERIFY: Fee/discount tests FAIL before implementation**

### Domain Models Implementation for US3

- [ ] T084 [P] [US3] Create FeeExtra model in /lib/features/expenses/domain/models/fee_extra.dart (support percent/absolute, percentBase, absoluteSplit)
- [ ] T085 [P] [US3] Create DiscountExtra model in /lib/features/expenses/domain/models/discount_extra.dart (support percent/absolute, percentBase, absoluteSplit, applyBeforeTax)
- [ ] T086 [US3] Extend Extras model to include fees and discounts in /lib/features/expenses/domain/models/extras.dart (add fees list, discounts list)

**VERIFY: Fee/discount tests now PASS**

### Services for US3 (Write Tests FIRST)

- [ ] T087 [US3] Extend ItemizedCalculator tests in /test/unit/expenses/domain/services/itemized_calculator_test.dart (add test scenarios for taxableItemSubtotalsOnly, postDiscountItemSubtotals, fees, discounts, various allocation bases)

**VERIFY: Extended calculator tests FAIL before implementation**

### Services Implementation for US3

- [ ] T088 [US3] Extend ItemizedCalculator to handle taxableItemSubtotalsOnly base in /lib/features/expenses/domain/services/itemized_calculator.dart (filter to taxable items when calculating tax base)
- [ ] T089 [US3] Extend ItemizedCalculator to apply discounts in /lib/features/expenses/domain/services/itemized_calculator.dart (apply before or after tax based on applyBeforeTax flag, clamp to prevent negative subtotals)
- [ ] T090 [US3] Extend ItemizedCalculator to calculate fees in /lib/features/expenses/domain/services/itemized_calculator.dart (support percent/absolute, allocate based on mode)
- [ ] T091 [US3] Update ParticipantBreakdown to include feesAllocated and discountsAllocated in /lib/features/expenses/domain/models/participant_breakdown.dart

**VERIFY: Extended calculator tests now PASS**

### Data Layer for US3 (Write Tests FIRST)

- [ ] T092 [US3] Write tests for Extras extended serialization in /test/unit/expenses/data/models/extras_model_test.dart (test fees and discounts serialization)

**VERIFY: Data layer tests FAIL before implementation**

### Data Layer Implementation for US3

- [ ] T093 [US3] Extend ExtrasModel to serialize fees and discounts in /lib/features/expenses/data/models/extras_model.dart (toFirestore/fromFirestore for fees and discounts arrays)

**VERIFY: Data layer tests now PASS**

### UI Implementation for US3 (Write Widget Tests FIRST)

- [ ] T094 [P] [US3] Write widget tests for AllocationSettings in /test/widget/expenses/itemized/allocation_settings_test.dart
- [ ] T095 [P] [US3] Write widget tests for FeeInput in /test/widget/expenses/itemized/fee_input_test.dart
- [ ] T096 [P] [US3] Write widget tests for DiscountInput in /test/widget/expenses/itemized/discount_input_test.dart

**VERIFY: Widget tests FAIL before implementation**

### UI Components for US3

- [ ] T097 [US3] Create AllocationSettings widget in /lib/features/expenses/presentation/widgets/itemized/allocation_settings.dart (dropdowns for tax base, tip base, advanced options)
- [ ] T098 [US3] Create FeeInput widget in /lib/features/expenses/presentation/widgets/itemized/fee_input.dart (name, percent/absolute toggle, base selection, split mode)
- [ ] T099 [US3] Create DiscountInput widget in /lib/features/expenses/presentation/widgets/itemized/discount_input.dart (name, percent/absolute toggle, base selection, applyBeforeTax checkbox)
- [ ] T100 [US3] Extend ExtrasStepPage to support fees and discounts in /lib/features/expenses/presentation/pages/itemized/extras_step_page.dart (add fee list, add discount list, advanced settings expandable panel)
- [ ] T101 [US3] Extend LineItemCard to show taxable/serviceChargeable toggles in /lib/features/expenses/presentation/widgets/itemized/line_item_card.dart (checkboxes for taxable and serviceChargeable flags)

**VERIFY: Widget tests now PASS**

### Integration Testing for US3

- [ ] T102 [US3] Write integration test for advanced allocation in /test/integration/itemized_advanced_allocation_test.dart (create expense with taxable/non-taxable items, fees, discounts, verify allocation)

**VERIFY: Integration test PASSES**

**Checkpoint**: User Story 3 complete - advanced tax/tip/fee allocation and discounts working independently

---

## Phase 6: User Story 4 - Review Screen with Audit Trail (Priority: P1)

**Goal**: Provide detailed review screen with summary bar, per-person cards/table toggle, expandable item-by-item audit trail, and validation before save.

**Independent Test**: Navigate review screen, toggle views, expand audit trails, verify all numbers match calculation engine output.

**Note**: Most review screen UI already implemented in US1 (T070), this phase adds audit trail details and table view

### UI Implementation for US4 (Write Widget Tests FIRST)

- [ ] T103 [P] [US4] Write widget tests for BreakdownTableView in /test/widget/expenses/itemized/breakdown_table_view_test.dart
- [ ] T104 [P] [US4] Write widget tests for AuditTrailExpansion in /test/widget/expenses/itemized/audit_trail_expansion_test.dart

**VERIFY: Widget tests FAIL before implementation**

### UI Components for US4

- [ ] T105 [US4] Create BreakdownTableView widget in /lib/features/expenses/presentation/widgets/itemized/breakdown_table_view.dart (table with columns: Person, Items, Tax, Tip, Fees, Discounts, Total; footer row with sums)
- [ ] T106 [US4] Extend PersonBreakdownCard to show expandable audit trail in /lib/features/expenses/presentation/widgets/itemized/person_breakdown_card.dart (expandable section showing itemContributions list, tax/tip/fees breakdown, rounding adjustment)
- [ ] T107 [US4] Extend ReviewStepPage to support card/table toggle in /lib/features/expenses/presentation/pages/itemized/review_step_page.dart (toggle button, switch between PersonBreakdownCard list and BreakdownTableView)
- [ ] T108 [US4] Extend ValidationBanner to show rounding remainder disclosure in /lib/features/expenses/presentation/widgets/itemized/validation_banner.dart (info banner: "Rounding adjustment: +$0.02 assigned to Alice")

**VERIFY: Widget tests now PASS**

### Integration Testing for US4

- [ ] T109 [US4] Write integration test for review screen interactions in /test/integration/itemized_review_screen_test.dart (toggle card/table view, expand audit trails, verify no data loss on view change)

**VERIFY: Integration test PASSES**

**Checkpoint**: User Story 4 complete - review screen with full audit trail and table view working independently

---

## Phase 7: User Story 5 - Currency and Rounding Support (Priority: P2)

**Goal**: Support multi-currency with proper precision (VND: 0 decimals, USD: 2 decimals), deterministic rounding with configurable remainder distribution.

**Independent Test**: Create receipts in VND showing integer amounts, USD showing cents, verify rounding is deterministic and remainder is assigned per policy.

**Note**: Rounding infrastructure already implemented in Phase 2 (T016) and used in US1, this phase adds UI controls and VND testing

### Services for US5 (Write Tests FIRST)

- [ ] T110 [US5] Write tests for VND rounding in /test/unit/expenses/domain/services/itemized_calculator_test.dart (test VND expenses round to integers, no decimal places)
- [ ] T111 [US5] Write tests for all rounding modes in /test/unit/expenses/domain/services/rounding_service_test.dart (roundHalfUp, roundHalfEven, floor, ceil)

**VERIFY: Rounding tests FAIL (if any gaps exist) or PASS (if already covered)**

### Services Implementation for US5

No implementation needed - rounding already works via DecimalService and RoundingService from Phase 2

**VERIFY: All rounding tests PASS**

### UI Implementation for US5 (Write Widget Tests FIRST)

- [ ] T112 [US5] Write widget tests for RoundingSettings in /test/widget/expenses/itemized/rounding_settings_test.dart

**VERIFY: Widget tests FAIL before implementation**

### UI Components for US5

- [ ] T113 [US5] Create RoundingSettings widget in /lib/features/expenses/presentation/widgets/itemized/rounding_settings.dart (dropdown for rounding mode, dropdown for remainder distribution, shown in advanced settings)
- [ ] T114 [US5] Extend AllocationSettings to include RoundingSettings in /lib/features/expenses/presentation/widgets/itemized/allocation_settings.dart (expandable "Rounding Options" panel)
- [ ] T115 [US5] Update all currency displays to use currency precision in /lib/features/expenses/presentation/pages/itemized/review_step_page.dart (CurrencyFormatter.format with currencyCode, VND shows integers, USD shows 2 decimals)

**VERIFY: Widget tests now PASS**

### Integration Testing for US5

- [ ] T116 [US5] Write integration test for VND expense in /test/integration/itemized_vnd_currency_test.dart (create VND expense, verify integer amounts throughout)
- [ ] T117 [US5] Write integration test for rounding policies in /test/integration/itemized_rounding_policies_test.dart (create same expense with different remainder distribution modes, verify different outcomes)

**VERIFY: Integration tests PASS**

**Checkpoint**: User Story 5 complete - multi-currency support and configurable rounding working independently

---

## Phase 8: User Story 6 - Edit Existing Itemized Expense (Priority: P3)

**Goal**: Allow users to edit existing itemized expenses, pre-filling all fields, recalculating on changes, and saving updates.

**Independent Test**: Edit an existing itemized expense, modify items/tax/tip, verify recalculated values are saved correctly.

### State Management for US6 (Write Tests FIRST)

- [ ] T118 [US6] Write tests for ItemizedExpenseCubit edit mode in /test/unit/expenses/presentation/cubits/itemized_expense_cubit_test.dart (test loadExisting action, pre-fill state, recalculate on edits)

**VERIFY: Edit mode tests FAIL before implementation**

### State Management Implementation for US6

- [ ] T119 [US6] Extend ItemizedExpenseCubit to support edit mode in /lib/features/expenses/presentation/cubits/itemized_expense_cubit.dart (add loadExisting method, populate state from existing expense, update save logic to handle both create and update)

**VERIFY: Edit mode tests now PASS**

### UI Implementation for US6

- [ ] T120 [US6] Extend ItemizedExpenseFlow to accept optional expenseId in /lib/features/expenses/presentation/pages/itemized/itemized_expense_flow.dart (if expenseId provided, load existing expense into cubit)
- [ ] T121 [US6] Update expense list to enable edit action in /lib/features/expenses/presentation/pages/expense_list_page.dart (tap itemized expense to edit, navigate to ItemizedExpenseFlow with expenseId)
- [ ] T122 [US6] Update ReviewStepPage save button text in /lib/features/expenses/presentation/pages/itemized/review_step_page.dart (show "Update Expense" when editing, "Save Expense" when creating)

### Integration Testing for US6

- [ ] T123 [US6] Write integration test for edit flow in /test/integration/itemized_edit_expense_test.dart (create expense, save, re-open for edit, modify item price, verify updated total)

**VERIFY: Integration test PASSES**

**Checkpoint**: User Story 6 complete - editing existing itemized expenses working independently

---

## Phase 9: Polish & Cross-Cutting Concerns

**Purpose**: Final improvements affecting multiple user stories, performance optimization, documentation

- [ ] T124 [P] Add loading states to ItemizedExpenseCubit transitions in /lib/features/expenses/presentation/cubits/itemized_expense_cubit.dart (show progress indicators during calculation and save)
- [ ] T125 [P] Add error recovery for Firestore save failures in /lib/features/expenses/presentation/cubits/itemized_expense_cubit.dart (retry logic, clear error messaging)
- [ ] T126 [P] Optimize review screen performance with memoization in /lib/features/expenses/presentation/cubits/itemized_expense_cubit.dart (cache calculation results, input hash checking)
- [ ] T127 [P] Add input debouncing for live recalculation in /lib/features/expenses/presentation/pages/itemized/extras_step_page.dart (300ms debounce on tip/tax input)
- [ ] T128 [P] Use ListView.builder for item breakdowns in /lib/features/expenses/presentation/widgets/itemized/person_breakdown_card.dart (virtualize large item lists)
- [ ] T129 [P] Add performance benchmarks in /test/performance/itemized_calculator_benchmark.dart (test 50 items, 6 people, verify <100ms calculation time)
- [ ] T130 [P] Update quickstart.md with actual file paths and examples from implementation in /specs/002-itemized-splitter/quickstart.md
- [ ] T131 [P] Generate API documentation with dartdoc in /docs/api/ (run `dart doc .`)
- [ ] T132 [P] Run flutter analyze and fix all warnings in project root
- [ ] T133 [P] Run flutter format on all Dart files in project root
- [ ] T134 [P] Verify all tests pass with flutter test --coverage (target 80% domain, 60% overall)
- [ ] T135 [P] Profile review screen with DevTools in /lib/features/expenses/presentation/pages/itemized/review_step_page.dart (verify 60fps scrolling, <200ms initial render)
- [ ] T136 Run quickstart.md validation: create trip, create itemized expense, verify settlement

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup (Phase 1) - BLOCKS all user stories
- **User Stories (Phase 3-8)**: All depend on Foundational (Phase 2) completion
  - US1 (P1): Can start after Phase 2 - foundational MVP story
  - US2 (P2): Can start after Phase 2 - independent of US1 but builds on models
  - US3 (P3): Can start after Phase 2 - extends US1 models
  - US4 (P1): Can start after Phase 2 - US1 already includes basic review page
  - US5 (P2): Can start after Phase 2 - rounding already in foundation
  - US6 (P3): Depends on US1-US5 being testable - implements edit functionality
- **Polish (Phase 9)**: Depends on US1-US6 being complete

### User Story Dependencies

```
Foundational (Phase 2)
    ↓
    ├─→ US1 (Phase 3) ─┐
    ├─→ US2 (Phase 4) ─┤
    ├─→ US3 (Phase 5) ─┼─→ US6 (Phase 8)
    ├─→ US4 (Phase 6) ─┤
    └─→ US5 (Phase 7) ─┘
              ↓
        Polish (Phase 9)
```

**Key Insights**:
- US1 is foundational but others can start in parallel after Phase 2
- US2 extends US1 models but can be developed independently
- US3 extends US1 calculator but doesn't block other stories
- US4 enhances US1 UI but basic review already in US1
- US5 uses foundation from Phase 2, minimal dependencies
- US6 requires US1-US5 to exist but can be last priority

### Within Each User Story (TDD Order)

1. **Write Tests FIRST** - All tests must FAIL before implementation
2. **Domain Models** - Entity tests, then implementations
3. **Services** - Service tests (with golden fixtures for calculator), then implementations
4. **Data Layer** - Serialization tests, then implementations
5. **State Management** - Cubit tests, then implementations
6. **UI Components** - Widget tests, then implementations
7. **Integration** - End-to-end tests to verify story completeness

### Parallel Opportunities

**Within Phase 1 (Setup)**:
- All tasks T001-T008 can run in parallel

**Within Phase 2 (Foundational)**:
- T010-T014 (enums) can run in parallel
- T017-T018 (tests) can run in parallel after T009, T016 complete

**Within User Story Phases**:
- All test tasks marked [P] can run in parallel (writing tests for different files)
- All model implementation tasks marked [P] can run in parallel (after their tests are written)
- Widget tests can run in parallel
- Widget implementations can run in parallel (after their tests)

**Across User Stories** (after Phase 2 complete):
- US1, US2, US3, US4, US5 can be worked on in parallel by different developers
- US6 should wait until US1 is functional

**Within Phase 9 (Polish)**:
- All tasks T124-T136 marked [P] can run in parallel

---

## Parallel Execution Examples

### Example 1: Phase 2 Foundational Enums

```bash
# Launch all enum creation tasks together:
Task T010: "Create PercentBase enum in /lib/features/expenses/domain/models/percent_base.dart"
Task T011: "Create AbsoluteSplitMode enum in /lib/features/expenses/domain/models/absolute_split_mode.dart"
Task T012: "Create AssignmentMode enum in /lib/features/expenses/domain/models/assignment_mode.dart"
Task T013: "Create RoundingMode enum in /lib/features/expenses/domain/models/rounding_mode.dart"
Task T014: "Create RemainderDistributionMode enum in /lib/features/expenses/domain/models/remainder_distribution_mode.dart"
```

### Example 2: User Story 1 Domain Model Tests

```bash
# Write all domain model tests in parallel (they test different files):
Task T019: "Write unit tests for RoundingConfig model in /test/unit/expenses/domain/models/rounding_config_test.dart"
Task T020: "Write unit tests for ItemAssignment model in /test/unit/expenses/domain/models/item_assignment_test.dart"
Task T021: "Write unit tests for LineItem model in /test/unit/expenses/domain/models/line_item_test.dart"
Task T022: "Write unit tests for TaxExtra model in /test/unit/expenses/domain/models/tax_extra_test.dart"
Task T023: "Write unit tests for TipExtra model in /test/unit/expenses/domain/models/tip_extra_test.dart"
Task T024: "Write unit tests for Extras model in /test/unit/expenses/domain/models/extras_test.dart"
Task T025: "Write unit tests for AllocationRule model in /test/unit/expenses/domain/models/allocation_rule_test.dart"
Task T026: "Write unit tests for ItemContribution model in /test/unit/expenses/domain/models/item_contribution_test.dart"
Task T027: "Write unit tests for ParticipantBreakdown model in /test/unit/expenses/domain/models/participant_breakdown_test.dart"
```

### Example 3: Multiple User Stories in Parallel (after Phase 2)

```bash
# Developer A works on US1 (basic itemized split)
# Developer B works on US2 (custom shares)
# Developer C works on US3 (advanced allocation)
# All can proceed simultaneously after Phase 2 is complete
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (T001-T008)
2. Complete Phase 2: Foundational (T009-T018) - **CRITICAL BLOCKER**
3. Complete Phase 3: User Story 1 (T019-T075)
4. **STOP and VALIDATE**: Test US1 independently
   - Create itemized expense with even splits
   - Apply tax and tip
   - Verify per-person totals
   - Verify settlement integration
   - Save and reload expense
5. Deploy/demo if ready (MVP = basic itemized splitting with settlement)

### Incremental Delivery (Recommended)

1. **Foundation** (Phases 1-2) → Infrastructure ready
2. **MVP** (Phase 3: US1) → Test independently → Deploy/Demo
   - Users can now create itemized expenses with even splits
3. **Enhancement 1** (Phase 4: US2) → Test independently → Deploy/Demo
   - Users can now use custom percentage shares
4. **Enhancement 2** (Phase 5: US3) → Test independently → Deploy/Demo
   - Users can now use advanced tax/tip/fee allocation
5. **Enhancement 3** (Phase 6: US4) → Test independently → Deploy/Demo
   - Users can now view detailed audit trails and table view
6. **Enhancement 4** (Phase 7: US5) → Test independently → Deploy/Demo
   - Users can now use VND currency and configure rounding
7. **Enhancement 5** (Phase 8: US6) → Test independently → Deploy/Demo
   - Users can now edit existing itemized expenses
8. **Polish** (Phase 9) → Final quality improvements

### Parallel Team Strategy

With multiple developers after Phase 2 completion:

- **Developer A**: US1 (T019-T075) - Highest priority, foundational
- **Developer B**: US2 (T076-T081) - Can start immediately, independent
- **Developer C**: US3 (T082-T102) - Can start immediately, extends models
- **Developer D**: US4 (T103-T109) - Enhances US1 UI
- **Developer E**: US5 (T110-T117) - Currency/rounding controls

Each story completes and integrates independently without blocking others.

---

## Test-Driven Development (TDD) Checklist

**CRITICAL**: This project follows TDD. Tests MUST be written BEFORE implementation.

### For Each User Story Phase:

1. ✅ **Write ALL tests first** (marked with "Write tests" in task descriptions)
2. ✅ **Verify ALL tests FAIL** (red phase - proves tests are valid)
3. ✅ **Implement code to make tests pass** (green phase)
4. ✅ **Verify ALL tests PASS** (green confirmation)
5. ✅ **Refactor if needed** (while keeping tests green)
6. ✅ **Run integration test** (verify story works end-to-end)

### Test Coverage Goals

- **Domain Logic**: 80%+ (calculation engine, validation, rounding)
- **State Management**: 70%+ (Cubit state transitions)
- **Widgets**: 60%+ (UI components)
- **Integration**: 100% of critical user flows (1 test per story minimum)

**Command**: `flutter test --coverage` to verify coverage after each phase

---

## Notes

- **[P]** markers indicate tasks that can run in parallel (different files, no dependencies)
- **[US#]** labels map tasks to specific user stories for traceability
- Each user story should be independently completable and testable
- Tests MUST fail before implementing (TDD requirement)
- Commit after each task or logical group of related tasks
- Stop at checkpoints to validate story independence
- Golden fixtures for calculator tests should cover all allocation bases and edge cases
- Settlement integration is critical - must verify participantAmounts are consumed correctly
- Backward compatibility is essential - old expenses must still load correctly
- Performance targets: <100ms calculation, 60fps scrolling, <200ms review screen render

---

**Total Tasks**: 136
**Estimated Effort**: 30-40 hours
**Complexity**: Medium-High (financial calculations, multi-step UI, state management)
**Risk Areas**: Decimal precision, rounding remainders, Firestore backward compatibility, review screen performance with large receipts

**Status**: Ready for implementation
**Last Updated**: 2025-10-28
