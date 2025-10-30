# Implementation Plan: Receipt Split UX Improvements

**Branch**: `005-receipt-split-ux` | **Date**: 2025-10-30 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/005-receipt-split-ux/spec.md`

## Summary

Replace the current AppBar "+" button with a Material Design FAB Speed Dial that offers two distinct expense entry paths: "Quick Expense" (Equal/Weighted splits) and "Receipt Split (Who Ordered What)" (itemized wizard). Update all 60+ localization strings from "Itemized" terminology to "Receipt Split" for improved user-friendliness. Simplify the Quick Expense form by removing the itemized button, creating clear separation between simple and detailed expense entry methods.

**Technical Approach**: Pure UI refactoring in Flutter. Replace IconButton with FloatingActionButton + SpeedDial widget. Update app_en.arb localization keys (itemized* → receiptSplit*). Remove split type handling for itemized from expense form. No data model changes required - backward compatible with existing `splitType: itemized` expenses.

## Technical Context

**Language/Version**: Dart 3.9.0+ (Flutter SDK 3.19.0+)
**Primary Dependencies**:
- flutter/material.dart (Material Design 3 components)
- flutter_bloc 8.1.6 (state management)
- flutter_localizations (l10n system)
- intl 0.20.2 (localization)

**Storage**: Firestore (no schema changes - backward compatible)
**Testing**: flutter_test (widget tests), mockito (unit test mocks), build_runner (code generation)
**Target Platform**: Flutter Web (GitHub Pages deployment)
**Project Type**: Single Flutter web application
**Performance Goals**:
- FAB animation <300ms
- Speed dial expansion <200ms
- Quick Expense form opens <100ms
- Receipt Split wizard opens <100ms

**Constraints**:
- Material Design 3 compliance (FAB size 56x56dp, elevation 6dp)
- Backward compatibility with existing `splitType: itemized` expenses
- Zero data migration required
- Maintain existing wizard functionality (no behavior changes)

**Scale/Scope**:
- ~60 localization strings to update
- 3 primary files to modify (expense_list_page, expense_form_page, expense_form_bottom_sheet)
- ~10-15 files referencing localization strings
- No new dependencies required

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### I. Test-Driven Development (NON-NEGOTIABLE)
**Status**: ✅ PASS
- Widget tests required for FAB Speed Dial interaction
- Widget tests required for Quick Expense form (without itemized button)
- Integration tests for edit flow (ensure correct editor opens)
- All tests written before implementation

### II. Code Quality & Maintainability
**Status**: ✅ PASS
- Follow Flutter/Dart style guide (flutter_lints 5.0.0)
- Maximum cyclomatic complexity ≤ 10 (Speed Dial logic simple)
- Code coverage: 60% overall target (UI refactoring, widget tests primary)
- Documentation comments for FAB Speed Dial widget
- No commented-out code

### III. User Experience Consistency
**Status**: ✅ PASS
- FAB follows Material Design 3 specifications
- Speed Dial uses standard Material expansion animation
- Consistent touch targets (44x44px minimum)
- Error handling unchanged (existing form/wizard logic)
- Loading states unchanged
- Responsive design: FAB scales appropriately on small screens (<360dp)

### IV. Performance Standards
**Status**: ✅ PASS
- FAB/Speed Dial animations <300ms (Material Design standard)
- User interactions: FAB tap response <100ms
- No impact on page load time (simple UI component swap)
- No memory leaks (stateless FAB component)
- Bundle size impact: <5KB (localization string changes only)

### V. Data Integrity & Security
**Status**: ✅ PASS
- No changes to monetary calculations
- No changes to data validation
- No changes to persistence layer
- Backward compatibility: existing `splitType: itemized` expenses continue to work
- Audit trail unchanged (activity logging preserv ed)

**Overall Gate Status**: ✅ PASS - Ready for Phase 0

## Project Structure

### Documentation (this feature)

```
specs/005-receipt-split-ux/
├── spec.md              # Feature specification (/speckit.specify output)
├── plan.md              # This file (/speckit.plan output)
├── research.md          # Phase 0 output (Material Design patterns)
├── data-model.md        # Phase 1 output (N/A - no model changes)
├── quickstart.md        # Phase 1 output (implementation guide)
├── contracts/           # Phase 1 output (N/A - no API changes)
├── checklists/          # Quality checklists
│   └── requirements.md  # Specification quality checklist (✅ complete)
└── tasks.md             # Phase 2 output (/speckit.tasks command)
```

### Source Code (repository root)

```
lib/
├── features/
│   └── expenses/
│       └── presentation/
│           ├── pages/
│           │   ├── expense_list_page.dart           # [MODIFY] Replace AppBar button with FAB Speed Dial
│           │   ├── expense_form_page.dart            # [MODIFY] Remove itemized button from split type
│           │   └── itemized/
│           │       └── itemized_expense_wizard.dart  # [READ ONLY] Unchanged
│           └── widgets/
│               ├── expense_form_bottom_sheet.dart    # [MODIFY] Remove itemized handling
│               └── fab_speed_dial.dart               # [CREATE] New reusable Speed Dial widget
├── l10n/
│   └── app_en.arb                                     # [MODIFY] Update ~60 strings (itemized* → receiptSplit*)
└── core/
    ├── models/
    │   └── split_type.dart                            # [READ ONLY] Enum unchanged (backward compat)
    └── l10n/
        └── l10n_extensions.dart                       # [READ ONLY] Extension unchanged

test/
├── widget/
│   └── features/
│       └── expenses/
│           ├── fab_speed_dial_test.dart               # [CREATE] FAB Speed Dial widget tests
│           ├── expense_form_test.dart                 # [MODIFY] Update tests (remove itemized button expectations)
│           └── expense_list_page_test.dart            # [MODIFY] Update tests (FAB instead of AppBar button)
└── integration/
    └── expense_edit_flow_test.dart                    # [CREATE] Test edit flow routing
```

**Structure Decision**: This is a UI refactoring within the existing Flutter monorepo structure. Changes are isolated to the expenses feature presentation layer and localization. No new feature modules or architectural patterns required. Follows existing Flutter feature-based folder structure (features/expenses/presentation/).

## Complexity Tracking

*No constitutional violations - this section intentionally left blank.*

---

## Phase 0: Research & Technology Choices

### Research Tasks

1. **Material Design FAB Speed Dial Pattern**
   - **Question**: How to implement Material Design 3 Speed Dial in Flutter?
   - **Research scope**:
     - Official Material Design 3 FAB guidelines
     - Flutter Material library Speed Dial support (built-in vs. package)
     - Animation timing and expansion patterns
     - Accessibility considerations (semantic labels)
   - **Output**: `research.md` section with implementation approach

2. **Localization Key Migration Best Practices**
   - **Question**: How to safely rename 60+ localization keys without breaking existing code?
   - **Research scope**:
     - Flutter l10n key naming conventions
     - Find/replace strategies (grep, IDE refactoring)
     - Generated file handling (app_localizations.dart)
     - Testing strategies for localization changes
   - **Output**: `research.md` section with migration strategy

3. **Backward Compatibility for Enum Values**
   - **Question**: Should we rename `SplitType.itemized` enum value or keep it for backward compatibility?
   - **Research scope**:
     - Firestore deserialization impact
     - Code references vs. UI strings
     - Migration vs. terminology-only approach
   - **Output**: `research.md` section with decision and rationale

4. **FAB Positioning and Responsive Design**
   - **Question**: How to ensure FAB doesn't overlap content on different screen sizes?
   - **Research scope**:
     - Material Design padding specifications (16dp standard)
     - Flutter Scaffold FAB positioning options
     - Small screen adaptations (<360dp width)
     - Bottom sheet interaction (FAB visibility when sheet open)
   - **Output**: `research.md` section with responsive strategy

### Expected Outcomes

- **Decision Matrix**: Speed Dial implementation approach (built-in Material vs. custom vs. package)
- **Migration Plan**: Step-by-step guide for localization key updates
- **Backward Compatibility Strategy**: Keep enum as `itemized`, change only UI strings
- **Responsive Design Spec**: FAB positioning rules for all viewport sizes

---

## Phase 1: Design & Implementation Guide

### Data Model

**Status**: ✅ No changes required

This feature is a pure UI refactoring. Existing data model remains unchanged:
- `SplitType` enum: `equal`, `weighted`, `itemized` (enum value stays as `itemized` for backward compatibility)
- `Expense` model: No schema changes
- Firestore: No migration needed

**Backward Compatibility Note**: Existing expenses with `splitType: itemized` will continue to work. Edit flow detects this value and opens the Receipt Split wizard. Only UI terminology changes.

### API Contracts

**Status**: N/A - No API changes

This is a Flutter web frontend-only change. No backend, no REST APIs, no GraphQL. Firestore schema unchanged.

### Component Design

#### 1. FAB Speed Dial Widget (`lib/features/expenses/presentation/widgets/fab_speed_dial.dart`)

**Purpose**: Reusable Material Design Speed Dial component for expense entry options

**Interface**:
```dart
class ExpenseFabSpeedDial extends StatefulWidget {
  final String tripId;
  final VoidCallback onQuickExpenseTap;
  final VoidCallback onReceiptSplitTap;

  const ExpenseFabSpeedDial({
    required this.tripId,
    required this.onQuickExpenseTap,
    required this.onReceiptSplitTap,
  });
}
```

**Behavior**:
- Closed state: Single FAB with "+" icon
- Open state: Expands to show 2 mini FABs:
  1. "Quick Expense" (add icon)
  2. "Receipt Split (Who Ordered What)" (receipt icon)
- Animation: Material Design standard (scale + fade)
- Backdrop: Semi-transparent overlay (dismisses on tap)

**Accessibility**:
- Semantic labels for screen readers
- Tooltip for closed FAB: "Add Expense"
- Tooltips for expanded options

#### 2. Expense List Page Modifications (`lib/features/expenses/presentation/pages/expense_list_page.dart`)

**Changes**:
- **Remove**: AppBar IconButton with "+" icon (lines 53-59)
- **Add**: `floatingActionButton` parameter to Scaffold
- **Add**: `ExpenseFabSpeedDial` widget with callbacks

**Updated Scaffold**:
```dart
Scaffold(
  appBar: AppBar(
    // Remove: IconButton(icon: Icon(Icons.add), ...)
    title: Text(context.l10n.tripExpensesTitle),
    actions: [
      // Keep: Settlement and Settings buttons
    ],
  ),
  body: ExpenseListContent(...),
  floatingActionButton: ExpenseFabSpeedDial(
    tripId: tripId,
    onQuickExpenseTap: () {
      showExpenseFormBottomSheet(
        context: context,
        tripId: tripId,
      );
    },
    onReceiptSplitTap: () {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ItemizedExpenseWizard(...),
        ),
      );
    },
  ),
)
```

#### 3. Expense Form Simplification (`lib/features/expenses/presentation/pages/expense_form_page.dart`)

**Changes in Split Type Section** (lines 595-639):
- **Keep**: SegmentedButton with Equal and Weighted options
- **Remove**: OutlinedButton for "Itemized (Add Line Items)"
- **Remove**: `if (value == SplitType.itemized)` handler in `onSplitTypeChanged`
- **Remove**: Hack code that hides itemized selection (lines 611-614)

**Simplified Split Type UI**:
```dart
// How to split? (Section 5)
SegmentedButton<SplitType>(
  segments: [
    ButtonSegment(
      value: SplitType.equal,
      label: Text(context.l10n.expenseSplitTypeEqual),
      icon: const Icon(Icons.people),
    ),
    ButtonSegment(
      value: SplitType.weighted,
      label: Text(context.l10n.expenseSplitTypeWeighted),
      icon: const Icon(Icons.balance),
    ),
  ],
  selected: {selectedSplitType},
  onSelectionChanged: (Set<SplitType> newSelection) {
    // Simple setState, no itemized handling
    onSplitTypeChanged(newSelection.first);
  },
),
// Remove: OutlinedButton for itemized
```

#### 4. Expense Form Bottom Sheet Cleanup (`lib/features/expenses/presentation/widgets/expense_form_bottom_sheet.dart`)

**Changes**:
- **Remove**: `_openItemizedWizardForEdit()` method call from `initState` (lines 81-96)
- **Keep**: Edit detection for itemized expenses (lines 87-97) - still opens wizard for existing itemized expenses
- **Simplify**: `onSplitTypeChanged` handler (remove lines 241-333 itemized navigation logic)

**Note**: Edit flow still works - tapping an existing Receipt Split expense card still opens wizard (handled in expense card tap handler)

### Localization Migration

**Scope**: Update app_en.arb (~60 strings)

**Naming Convention**:
- Old prefix: `itemized*`
- New prefix: `receiptSplit*`

**Key Examples**:
```json
// OLD
"itemizedWizardTitleNew": "New Itemized Expense"
"itemizedWizardStepItems": "Items"
"expenseSplitTypeItemized": "Itemized (Add Line Items)"

// NEW
"receiptSplitWizardTitleNew": "New Receipt Split"
"receiptSplitWizardStepItems": "Items"
"expenseSplitTypeReceiptSplit": "Receipt Split (Who Ordered What)"
```

**Migration Process**:
1. Find all `itemized*` keys in app_en.arb
2. Rename to `receiptSplit*` (maintain camelCase)
3. Update string values to use "Receipt Split" terminology
4. Find all `context.l10n.itemized*` references in Dart code
5. Replace with `context.l10n.receiptSplit*`
6. Run `flutter pub get` to regenerate l10n files
7. Run `flutter analyze` to catch missing references
8. Run widget tests to verify strings render correctly

**Files Requiring Updates** (~10-15 files):
- `lib/features/expenses/presentation/pages/itemized/itemized_expense_wizard.dart`
- `lib/features/expenses/presentation/pages/itemized/steps/*.dart` (4 step files)
- `lib/features/expenses/presentation/widgets/expense_card.dart`
- `lib/features/expenses/presentation/pages/expense_form_page.dart`
- All test files referencing itemized strings

### Testing Strategy

#### Widget Tests

1. **FAB Speed Dial Tests** (`test/widget/features/expenses/fab_speed_dial_test.dart`):
   - FAB displays in closed state
   - Tapping FAB expands Speed Dial
   - "Quick Expense" option visible when expanded
   - "Receipt Split" option visible when expanded
   - Tapping "Quick Expense" calls `onQuickExpenseTap` callback
   - Tapping "Receipt Split" calls `onReceiptSplitTap` callback
   - Tapping backdrop closes Speed Dial

2. **Expense Form Tests** (update `test/widget/features/expenses/expense_form_test.dart`):
   - Split type shows only Equal and Weighted options
   - No "Itemized" button present
   - Selecting Equal shows participant chips
   - Selecting Weighted shows weight input fields
   - Saving expense with Equal split creates correct expense

3. **Expense List Page Tests** (update `test/widget/features/expenses/expense_list_page_test.dart`):
   - AppBar does NOT have "+" button
   - FAB is present at bottom-right
   - Tapping FAB opens Speed Dial
   - Quick Expense option opens bottom sheet
   - Receipt Split option navigates to wizard

#### Integration Tests

4. **Edit Flow Tests** (`test/integration/expense_edit_flow_test.dart`):
   - Tapping Equal split expense opens Quick Expense form
   - Tapping Weighted split expense opens Quick Expense form
   - Tapping Receipt Split expense opens wizard
   - Existing `itemized` expenses open wizard (backward compat)

#### Localization Tests

5. **L10n Tests** (manual verification):
   - Run `flutter pub get` successfully generates l10n files
   - All `receiptSplit*` strings accessible via `context.l10n`
   - No broken string references (flutter analyze passes)
   - Visual verification: strings display correctly in UI

### Performance Validation

**Benchmarks**:
- FAB Speed Dial animation: <300ms (measured with Timeline)
- Quick Expense bottom sheet open: <100ms
- Receipt Split wizard navigation: <100ms

**Tools**:
- Flutter DevTools Timeline for animation profiling
- `flutter run --profile` for realistic performance testing

---

## Phase 2: Task Generation

**Deferred to `/speckit.tasks` command**

This phase generates dependency-ordered tasks from the design above. Tasks will include:
1. Create FAB Speed Dial widget with tests
2. Update localization strings (app_en.arb)
3. Modify Expense List Page (replace AppBar button)
4. Simplify Expense Form (remove itemized button)
5. Update all code references to new l10n keys
6. Update widget tests
7. Create integration tests for edit flow
8. Manual QA on multiple screen sizes

---

## Dependencies & Constraints

### External Dependencies

**No new dependencies required**. Using existing Flutter Material library:
- `FloatingActionButton` (built-in)
- `AnimatedContainer` or `AnimatedScale` for Speed Dial animation
- Existing `flutter_localizations` system

### Internal Dependencies

- Existing `ItemizedExpenseWizard` (unchanged)
- Existing `ExpenseFormBottomSheet` (minor cleanup)
- Existing `ExpenseCubit` (unchanged)
- Existing localization system (`app_en.arb` + generated files)

### Constraints

1. **Backward Compatibility**: Must not break existing expenses with `splitType: itemized`
2. **Material Design Compliance**: FAB must follow M3 specifications
3. **Zero Data Migration**: No Firestore updates required
4. **Localization Only**: English strings only (other languages future work)
5. **No Wizard Changes**: Receipt Split wizard functionality unchanged

---

## Risk Mitigation

| Risk | Mitigation Strategy |
|------|---------------------|
| Localization key rename breaks code | Thorough find/replace + flutter analyze + comprehensive tests |
| FAB overlaps bottom sheet | Test with bottom sheet open; adjust FAB position if needed |
| Users don't find Speed Dial | Use clear icons (receipt icon) and descriptive labels |
| Animation performance issues | Profile with DevTools; simplify animation if needed |
| Backward compat breaks old expenses | Keep `SplitType.itemized` enum; extensive edit flow tests |

---

## Success Metrics

- ✅ All widget tests pass
- ✅ All integration tests pass
- ✅ `flutter analyze` shows zero warnings
- ✅ FAB Speed Dial animation <300ms
- ✅ No console errors on expense creation/edit
- ✅ Existing itemized expenses open wizard correctly
- ✅ Quick Expense flow completes without itemized option

---

## Next Steps

1. Run `/speckit.tasks` to generate dependency-ordered implementation tasks
2. Implement tasks following TDD cycle (tests first)
3. Manual QA on Chrome, iOS Safari, Android Chrome
4. Code review focusing on constitution compliance
5. Merge to master → auto-deploy to GitHub Pages
