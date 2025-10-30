# Tasks: Receipt Split UX Improvements

**Input**: Design documents from `/specs/005-receipt-split-ux/`
**Prerequisites**: plan.md, quickstart.md, research.md, data-model.md

**Tests**: TDD approach - widget tests written FIRST before implementation (Constitution Principle I)

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`
- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3, US4)
- Include exact file paths in descriptions

## User Stories from Spec

- **US1** (P1): Add Simple Equal/Weighted Expense via Quick Entry
- **US2** (P1): Add Detailed Receipt Split Directly
- **US3** (P2): Understand Terminology and Make Informed Choice
- **US4** (P3): Edit Existing Expenses

---

## Phase 1: Setup (Localization Foundation)

**Purpose**: Update localization strings - foundational for all UI changes

- [X] T001 Backup current localization file: `cp lib/l10n/app_en.arb lib/l10n/app_en.arb.backup`
- [X] T002 Update all `itemized*` keys to `receiptSplit*` in lib/l10n/app_en.arb (~60 strings)
- [X] T003 Update string values to use "Receipt Split" terminology in lib/l10n/app_en.arb
- [X] T004 Regenerate localization files: `flutter pub get && dart format .`
- [X] T005 Update all code references from `.l10n.itemized*` to `.l10n.receiptSplit*` (find/replace across lib/ and test/)
- [X] T006 Verify localization build: `flutter analyze` (zero errors expected)
- [X] T007 Run existing tests to verify localization changes: `flutter test`

**Checkpoint**: Localization migration complete - all strings accessible, no broken references

---

## Phase 2: User Story 1 - Quick Expense Entry (Priority: P1) 🎯 MVP Core

**Goal**: Users can add simple Equal/Weighted expenses via FAB → Quick Expense path

**Independent Test**: Tap FAB → select "Quick Expense" → fill form → save in <30 seconds

### Tests for User Story 1

**NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [ ] T008 [P] [US1] Widget test: FAB Speed Dial displays main FAB in closed state in test/widget/features/expenses/fab_speed_dial_test.dart
- [ ] T009 [P] [US1] Widget test: FAB expands to show 2 options when tapped in test/widget/features/expenses/fab_speed_dial_test.dart
- [ ] T010 [P] [US1] Widget test: "Quick Expense" option calls onQuickExpenseTap callback in test/widget/features/expenses/fab_speed_dial_test.dart
- [ ] T011 [P] [US1] Widget test: Backdrop closes Speed Dial when tapped in test/widget/features/expenses/fab_speed_dial_test.dart
- [ ] T012 [P] [US1] Widget test: Expense form shows only Equal and Weighted split types in test/widget/features/expenses/expense_form_test.dart
- [ ] T013 [P] [US1] Widget test: Expense form does NOT show itemized/receipt split button in test/widget/features/expenses/expense_form_test.dart
- [ ] T014 [P] [US1] Widget test: Expense List Page displays FAB (not AppBar button) in test/widget/features/expenses/expense_list_page_test.dart
- [ ] T015 [P] [US1] Widget test: Tapping FAB Quick Expense opens bottom sheet in test/widget/features/expenses/expense_list_page_test.dart

### Implementation for User Story 1

- [ ] T016 [US1] Create ExpenseFabSpeedDial widget in lib/features/expenses/presentation/widgets/fab_speed_dial.dart (custom Speed Dial with FAB + 2 mini FABs, animation controller, backdrop)
- [ ] T017 [US1] Modify Expense List Page: Remove AppBar IconButton, add FAB Speed Dial in lib/features/expenses/presentation/pages/expense_list_page.dart
- [ ] T018 [US1] Add bottom padding (80dp) to expense ListView in lib/features/expenses/presentation/pages/expense_list_page.dart
- [ ] T019 [US1] Modify Expense Form Page: Remove itemized OutlinedButton from split type section in lib/features/expenses/presentation/pages/expense_form_page.dart (lines ~630-639)
- [ ] T020 [US1] Remove itemized selection hack (lines ~611-614) in lib/features/expenses/presentation/pages/expense_form_page.dart
- [ ] T021 [US1] Simplify onSplitTypeChanged handler: Remove itemized navigation logic in lib/features/expenses/presentation/widgets/expense_form_bottom_sheet.dart (lines ~241-333)
- [ ] T022 [US1] Run widget tests to verify US1: `flutter test test/widget/features/expenses/`

**Checkpoint**: User Story 1 complete - Quick Expense path fully functional, FAB visible, form simplified

---

## Phase 3: User Story 2 - Direct Receipt Split Entry (Priority: P1) 🎯 MVP Core

**Goal**: Users can add Receipt Split expenses directly from FAB (no intermediate form)

**Independent Test**: Tap FAB → select "Receipt Split (Who Ordered What)" → wizard opens on Step 1

### Tests for User Story 2

- [ ] T023 [P] [US2] Widget test: "Receipt Split" option visible with receipt icon in test/widget/features/expenses/fab_speed_dial_test.dart
- [ ] T024 [P] [US2] Widget test: Tapping "Receipt Split" calls onReceiptSplitTap callback in test/widget/features/expenses/fab_speed_dial_test.dart
- [ ] T025 [P] [US2] Widget test: Tapping FAB Receipt Split navigates to wizard in test/widget/features/expenses/expense_list_page_test.dart

### Implementation for User Story 2

- [ ] T026 [US2] Add onReceiptSplitTap callback to ExpenseFabSpeedDial (already in T016 implementation)
- [ ] T027 [US2] Wire Receipt Split FAB option to ItemizedExpenseWizard navigation in lib/features/expenses/presentation/pages/expense_list_page.dart
- [ ] T028 [US2] Verify wizard opens with correct initial state (tripId, participants, currency) in lib/features/expenses/presentation/pages/expense_list_page.dart
- [ ] T029 [US2] Run widget tests to verify US2: `flutter test test/widget/features/expenses/fab_speed_dial_test.dart`

**Checkpoint**: User Story 2 complete - Receipt Split wizard accessible directly from FAB

---

## Phase 4: User Story 3 - Clear Terminology (Priority: P2)

**Goal**: Users understand the difference between Quick Expense and Receipt Split from button labels

**Independent Test**: First-time user can read labels and choose correct option without help

### Tests for User Story 3

- [ ] T030 [P] [US3] Widget test: FAB tooltips display user-friendly text in test/widget/features/expenses/fab_speed_dial_test.dart
- [ ] T031 [P] [US3] Widget test: Speed Dial labels use "Quick Expense" and "Receipt Split (Who Ordered What)" in test/widget/features/expenses/fab_speed_dial_test.dart
- [ ] T032 [P] [US3] Visual regression test: FAB Speed Dial matches design spec (icons, labels, positioning) in test/widget/features/expenses/fab_speed_dial_test.dart

### Implementation for User Story 3

- [ ] T033 [US3] Add semantic labels and tooltips to FAB Speed Dial in lib/features/expenses/presentation/widgets/fab_speed_dial.dart
- [ ] T034 [US3] Verify icon choices: Icons.flash_on (Quick Expense), Icons.receipt_long (Receipt Split) in lib/features/expenses/presentation/widgets/fab_speed_dial.dart
- [ ] T035 [US3] Add localization keys for FAB labels in lib/l10n/app_en.arb (fabQuickExpenseLabel, fabReceiptSplitLabel, fabQuickExpenseTooltip, fabReceiptSplitTooltip)
- [ ] T036 [US3] Update FAB widget to use localized strings in lib/features/expenses/presentation/widgets/fab_speed_dial.dart
- [ ] T037 [US3] Run widget tests to verify US3: `flutter test test/widget/features/expenses/fab_speed_dial_test.dart`

**Checkpoint**: User Story 3 complete - Terminology clear and user-friendly

---

## Phase 5: User Story 4 - Edit Flow Compatibility (Priority: P3)

**Goal**: Editing existing expenses opens the correct editor (form for Equal/Weighted, wizard for Receipt Split)

**Independent Test**: Tap Equal expense card → form opens. Tap Receipt Split expense card → wizard opens.

### Tests for User Story 4

- [ ] T038 [P] [US4] Integration test: Equal split expense opens Quick Expense form in test/integration/expense_edit_flow_test.dart
- [ ] T039 [P] [US4] Integration test: Weighted split expense opens Quick Expense form in test/integration/expense_edit_flow_test.dart
- [ ] T040 [P] [US4] Integration test: Receipt Split expense (splitType: itemized) opens wizard in test/integration/expense_edit_flow_test.dart
- [ ] T041 [P] [US4] Integration test: Existing itemized expenses (pre-migration) still open wizard in test/integration/expense_edit_flow_test.dart

### Implementation for User Story 4

- [ ] T042 [US4] Verify expense card tap handler detects splitType correctly in lib/features/expenses/presentation/widgets/expense_card.dart
- [ ] T043 [US4] Ensure expense_form_bottom_sheet still handles itemized edit detection (lines ~81-96) in lib/features/expenses/presentation/widgets/expense_form_bottom_sheet.dart
- [ ] T044 [US4] Test backward compatibility: Create test expense with splitType: itemized, verify wizard opens
- [ ] T045 [US4] Run integration tests to verify US4: `flutter test test/integration/expense_edit_flow_test.dart`

**Checkpoint**: User Story 4 complete - Edit flow works for all expense types (backward compatible)

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Final touches and validation across all user stories

- [ ] T046 [P] Add documentation comments to ExpenseFabSpeedDial widget in lib/features/expenses/presentation/widgets/fab_speed_dial.dart
- [ ] T047 [P] Verify Material Design 3 compliance: FAB size (56x56dp), elevation (6dp), animations (<300ms)
- [ ] T048 [P] Test responsive design: FAB visible and functional on small screens (320dp, 360dp, 768dp widths)
- [ ] T049 [P] Performance profiling: Speed Dial animation with Flutter DevTools Timeline (<16ms frames)
- [ ] T050 [P] Test FAB doesn't overlap content: Scroll to bottom of expense list, verify FAB clearance
- [ ] T051 [P] Test FAB visibility when bottom sheet open at 50% and 90% height
- [ ] T052 Run all tests: `flutter test`
- [ ] T053 Run analyzer: `flutter analyze` (zero warnings)
- [ ] T054 Format code: `dart format .`
- [ ] T055 Build for production: `flutter build web --base-href /expense_tracker/`
- [ ] T056 Manual QA using quickstart.md checklist (FAB Speed Dial, Quick Expense, Receipt Split, Edit Flow, Responsive, Performance)
- [ ] T057 Update feature CLAUDE.md with implementation notes: `.specify/scripts/bash/update-feature-docs.sh update 005`
- [ ] T058 Log final changes to feature CHANGELOG.md: `/docs.log "Completed Receipt Split UX improvements with FAB Speed Dial and updated terminology"`

**Checkpoint**: All user stories validated, tests passing, ready for code review

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - start immediately
- **User Story 1 (Phase 2)**: Depends on Setup completion (Phase 1) - localization must be updated first
- **User Story 2 (Phase 3)**: Depends on User Story 1 completion (shares FAB widget)
- **User Story 3 (Phase 4)**: Depends on User Story 1 completion (enhances FAB widget)
- **User Story 4 (Phase 5)**: Depends on User Story 1 and 2 completion (edit flow routing)
- **Polish (Phase 6)**: Depends on all user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Depends on Phase 1 (localization) - Creates FAB Speed Dial widget, simplifies form
- **User Story 2 (P1)**: Depends on US1 - Adds Receipt Split navigation to existing FAB widget
- **User Story 3 (P2)**: Depends on US1 - Enhances FAB widget with tooltips and localized labels
- **User Story 4 (P3)**: Depends on US1 and US2 - Verifies edit flow routing works correctly

### Within Each User Story

- Tests MUST be written and FAIL before implementation (TDD principle)
- Widget creation (T016) before page integration (T017-T021)
- Core FAB widget (US1) before enhancements (US2, US3)
- All implementation before integration tests (US4)

### Parallel Opportunities

- **Phase 1**: T002-T003 can run in parallel (different sections of app_en.arb)
- **User Story 1 Tests**: T008-T015 can all be written in parallel (different test files)
- **User Story 2 Tests**: T023-T025 can be written in parallel
- **User Story 3 Tests**: T030-T032 can be written in parallel
- **User Story 4 Tests**: T038-T041 can be written in parallel
- **Polish Phase**: T046-T051 can run in parallel (different concerns)

---

## Parallel Example: User Story 1

```bash
# Launch all tests for User Story 1 together (write tests first):
Task: "Widget test: FAB Speed Dial displays main FAB in test/widget/features/expenses/fab_speed_dial_test.dart"
Task: "Widget test: FAB expands to show 2 options in test/widget/features/expenses/fab_speed_dial_test.dart"
Task: "Widget test: Quick Expense calls callback in test/widget/features/expenses/fab_speed_dial_test.dart"
Task: "Widget test: Expense form shows only Equal/Weighted in test/widget/features/expenses/expense_form_test.dart"
Task: "Widget test: Expense List displays FAB in test/widget/features/expenses/expense_list_page_test.dart"

# Then implement in sequence (due to file dependencies):
1. T016: Create ExpenseFabSpeedDial widget
2. T017-T018: Modify Expense List Page (uses widget from T016)
3. T019-T021: Modify Expense Form (independent of FAB)
4. T022: Run all widget tests
```

---

## Implementation Strategy

### MVP First (User Stories 1 & 2)

1. Complete Phase 1: Setup (localization foundation) ✅
2. Complete Phase 2: User Story 1 (Quick Expense via FAB) ✅
3. Complete Phase 3: User Story 2 (Receipt Split via FAB) ✅
4. **STOP and VALIDATE**: Test both expense entry paths independently
5. Deploy/demo if ready

### Incremental Delivery

1. Localization foundation → All strings ready ✅
2. Add US1 (Quick Expense FAB) → Test independently → **MVP Core!**
3. Add US2 (Receipt Split FAB) → Test independently → **MVP Complete!**
4. Add US3 (Terminology polish) → Test independently → Enhanced UX
5. Add US4 (Edit flow) → Test independently → Full backward compatibility
6. Polish → Final validation → Production ready

### Sequential Implementation (Recommended)

Since US2-US4 depend on US1 (FAB widget), follow this order:

1. Phase 1 (Setup) - Foundation
2. Phase 2 (US1) - Core FAB widget + Quick Expense
3. Phase 3 (US2) - Receipt Split navigation
4. Phase 4 (US3) - Terminology enhancements
5. Phase 5 (US4) - Edit flow validation
6. Phase 6 (Polish) - Final touches

---

## Validation Checkpoints

After each phase, verify:

**After Phase 1 (Setup)**:
- ✅ `flutter analyze` passes (zero errors)
- ✅ All existing tests pass with new localization strings
- ✅ `context.l10n.receiptSplit*` accessible in code

**After Phase 2 (US1)**:
- ✅ FAB visible at bottom-right of expense list
- ✅ Tapping FAB expands Speed Dial (<300ms animation)
- ✅ "Quick Expense" option visible
- ✅ Tapping Quick Expense opens bottom sheet
- ✅ Expense form shows only Equal and Weighted (no itemized button)
- ✅ Creating expense with Equal split works
- ✅ Creating expense with Weighted split works

**After Phase 3 (US2)**:
- ✅ "Receipt Split (Who Ordered What)" option visible in Speed Dial
- ✅ Tapping Receipt Split opens wizard directly
- ✅ Wizard Step 1 loads with correct trip data
- ✅ Can complete full wizard flow and save Receipt Split expense

**After Phase 4 (US3)**:
- ✅ FAB tooltip: "Add expense options"
- ✅ Quick Expense tooltip clear and helpful
- ✅ Receipt Split tooltip clear and helpful
- ✅ Icons intuitive (flash icon, receipt icon)

**After Phase 5 (US4)**:
- ✅ Tapping Equal expense card opens form
- ✅ Tapping Weighted expense card opens form
- ✅ Tapping Receipt Split expense card opens wizard
- ✅ Existing itemized expenses (old data) still open wizard

**After Phase 6 (Polish)**:
- ✅ All tests passing
- ✅ Zero analyzer warnings
- ✅ Code formatted
- ✅ Production build succeeds
- ✅ Manual QA checklist complete

---

## Notes

- [P] tasks = different files, no dependencies - can run in parallel
- [Story] label maps task to specific user story for traceability
- Constitution Principle I (TDD): Tests written FIRST, must FAIL before implementation
- Each user story should be independently completable and testable
- Verify tests fail before implementing (red → green → refactor)
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- FAB Speed Dial is custom implementation (no external dependencies)
- Backward compatibility maintained: `SplitType.itemized` enum unchanged
- Zero data migration required

---

## Success Metrics (from Spec)

After implementation, verify:

- ✅ SC-001: Users identify Quick vs Receipt Split within 5 seconds (user testing)
- ✅ SC-002: Receipt Split feature discovery increases 40% (usage metrics)
- ✅ SC-003: Quick Expense flow 25% faster (timing measurements)
- ✅ SC-004: Zero data loss incidents (error logs)
- ✅ SC-005: 90% understand difference from labels alone (user survey)
- ✅ SC-006: Edit flow works for 100% of existing expenses (backward compat tests)
- ✅ SC-007: FAB passes Material Design 3 compliance (visual inspection)
