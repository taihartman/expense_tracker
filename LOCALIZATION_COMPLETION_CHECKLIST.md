# Localization Migration Completion Checklist

## Overview
This checklist tracks the remaining localization work needed to complete the migration.

## ✅ Completed Files (8 files)

### Priority 1: Core Expense Files ✅
- [x] expense_form_page.dart
- [x] expense_card.dart
- [x] expense_form_bottom_sheet.dart
- [x] participant_selector.dart

### Priority 2: Itemized Expense Wizard (Partial)
- [x] itemized_expense_wizard.dart
- [x] people_step_page.dart
- [~] items_step_page.dart (50% done - see below)

## 🟡 Partially Completed Files

### items_step_page.dart (50% complete)
**Status**: Headers migrated, need to complete:

Remaining strings to migrate:
```dart
Line 115: 'Not assigned' → context.l10n.itemizedItemsNotAssigned
Line 148: Tooltips for buttons
Line 194: Card title 'Add New Item' / 'Edit Item' → context.l10n.itemizedItemsAddCardTitle / itemizedItemsEditCardTitle
Line 201: 'Cancel' → context.l10n.commonCancel
Line 213: 'Item name' → context.l10n.itemizedItemsFieldNameLabel
Line 214: 'e.g., Caesar Salad' → context.l10n.itemizedItemsFieldNameHint
Line 226: 'Qty' → context.l10n.itemizedItemsFieldQtyLabel
Line 239: 'Price' → context.l10n.itemizedItemsFieldPriceLabel
Line 240: '0.00' → context.l10n.itemizedItemsFieldPriceHint
Line 252/260: Button labels 'Add Item' / 'Update Item' → context.l10n.itemizedItemsAddButton / itemizedItemsUpdateButton
Line 276: 'Back' → context.l10n.commonBack
Line 287: 'Continue to Extras' → context.l10n.itemizedItemsContinueButton
Line 301: 'Please fill in all fields' → context.l10n.validationPleaseFillAllFields
Line 355: 'Invalid input: $e' → context.l10n.validationInvalidInput(e.toString())
Line 384: 'Assign: ${item.name}' → context.l10n.itemizedItemsAssignDialogTitle(item.name)
Line 413: 'Cancel' → context.l10n.commonCancel
Line 424: 'Save' → context.l10n.commonSave
```

**Import needed**: Already added ✅

## ⏳ Remaining Files to Migrate

### Priority 2: Itemized Expense Wizard

#### extras_step_page.dart
Location: `lib/features/expenses/presentation/pages/itemized/steps/extras_step_page.dart`

**Steps**:
1. Add import: `import '../../../../../../core/l10n/l10n_extensions.dart';`
2. Replace strings:
   - Page title → `context.l10n.itemizedExtrasTitle`
   - Description → `context.l10n.itemizedExtrasDescription`
   - "Sales Tax" → `context.l10n.itemizedExtrasTaxCardTitle`
   - "Tax Rate (%)" → `context.l10n.itemizedExtrasTaxRateLabel`
   - Hint text → `context.l10n.itemizedExtrasTaxRateHint`
   - Helper text → `context.l10n.itemizedExtrasTaxRateHelper`
   - "Tip / Gratuity" → `context.l10n.itemizedExtrasTipCardTitle`
   - "Tip Rate (%)" → `context.l10n.itemizedExtrasTipRateLabel`
   - Tip hint → `context.l10n.itemizedExtrasTipRateHint`
   - Tip helper → `context.l10n.itemizedExtrasTipRateHelper`
   - Info message → `context.l10n.itemizedExtrasInfoMessage`
   - "Back" → `context.l10n.commonBack`
   - "Continue to Review" → `context.l10n.itemizedExtrasContinueButton`

#### review_step_page.dart
Location: `lib/features/expenses/presentation/pages/itemized/steps/review_step_page.dart`

**Steps**:
1. Add import: `import '../../../../../../core/l10n/l10n_extensions.dart';`
2. Replace strings:
   - Page title → `context.l10n.itemizedReviewTitle`
   - Description → `context.l10n.itemizedReviewDescription`
   - Warning/Error titles → `context.l10n.itemizedReviewCannotSaveTitle` / `itemizedReviewWarningTitle`
   - "Grand Total" → `context.l10n.itemizedReviewGrandTotal`
   - Participant count → `context.l10n.itemizedReviewPeopleSplitting(count)`
   - "Per Person Breakdown" → `context.l10n.itemizedReviewPerPersonBreakdown`
   - "PAID" badge → `context.l10n.itemizedReviewPaidBadge`
   - "Items Subtotal" → `context.l10n.itemizedReviewItemsSubtotal`
   - "Rounding" → `context.l10n.itemizedReviewRounding`
   - "Total" → `context.l10n.itemizedReviewTotal`
   - "Item Details" → `context.l10n.itemizedReviewItemDetails`
   - "Back" → `context.l10n.commonBack`
   - "Save Expense" / "Update Expense" → `context.l10n.itemizedReviewSaveButton` / `itemizedReviewUpdateButton`

#### itemized_expense_page.dart
**First check if file exists**:
```bash
ls -la /Users/a515138832/expense_tracker/lib/features/expenses/presentation/pages/itemized_expense_page.dart
```

If it exists, migrate following the same pattern.

### Priority 3: Settlement Files

#### settlement_summary_page.dart
Location: `lib/features/settlements/presentation/pages/settlement_summary_page.dart`

**Steps**:
1. Add import: `import '../../../../core/l10n/l10n_extensions.dart';`
2. Replace strings:
   - Page title → `context.l10n.settlementTitle`
   - Tooltips → `context.l10n.settlementViewTooltip`, `context.l10n.settlementRecomputeTooltip`
   - "Computing settlement..." → `context.l10n.settlementComputing`
   - "Loading settlement..." → `context.l10n.settlementLoading`
   - Last updated → `context.l10n.settlementLastUpdated(timestamp)`
   - Error messages → Use appropriate `settlement*Error` keys

#### minimal_transfers_view.dart
Location: `lib/features/settlements/presentation/widgets/minimal_transfers_view.dart`

**Steps**:
1. Add import: `import '../../../../core/l10n/l10n_extensions.dart';`
2. Replace strings:
   - "All Settled!" → `context.l10n.transfersAllSettledTitle`
   - Description → `context.l10n.transfersAllSettledDescription`
   - "Settlement Transfers" → `context.l10n.transfersCardTitle`
   - Count display → `context.l10n.transfersCountTotal(count)`
   - Hint text → `context.l10n.transfersHintTapToSettle`
   - "Pending Transfers" → `context.l10n.transfersPendingTitle`
   - "Settled Transfers" → `context.l10n.transfersSettledTitle`
   - Dialog title/message → `context.l10n.transferMarkSettledDialogTitle`, `context.l10n.transferMarkSettledDialogMessage(...)`
   - Copied messages → `context.l10n.transferCopiedMessage(...)`

#### transfer_breakdown_bottom_sheet.dart
Location: `lib/features/settlements/presentation/widgets/transfer_breakdown_bottom_sheet.dart`

**Steps**:
1. Add import: `import '../../../../core/l10n/l10n_extensions.dart';`
2. Replace strings:
   - "Transfer Breakdown" → `context.l10n.transferBreakdownTitle`
   - Tooltip → `context.l10n.transferBreakdownViewTooltip`
   - "No data available" → `context.l10n.transferBreakdownNoData`
   - Error loading → `context.l10n.transferBreakdownLoadError(error)`
   - "No expenses found..." → `context.l10n.transferBreakdownNoExpenses`
   - "Summary" → `context.l10n.transferBreakdownSummaryTitle`
   - Summary description → `context.l10n.transferBreakdownSummaryDescription(fromName, toName)`
   - Expense count → `context.l10n.transferBreakdownExpenseCount(count)`
   - "Contributing Expenses" → `context.l10n.transferBreakdownContributingExpenses`
   - "No description" → `context.l10n.transferBreakdownNoDescription`
   - Expense metadata → `context.l10n.transferBreakdownExpenseMetadata(payerName, date)`
   - "Paid" / "Owes" labels → `context.l10n.transferBreakdownPaidLabel`, etc.

#### all_people_summary_table.dart
Location: `lib/features/settlements/presentation/widgets/all_people_summary_table.dart`

**Steps**:
1. Add import: `import '../../../../core/l10n/l10n_extensions.dart';`
2. Replace strings:
   - "Everyone's Summary" → `context.l10n.summaryTableTitle`
   - "Person" → `context.l10n.summaryTableColumnPerson`
   - "To Receive" → `context.l10n.summaryTableColumnToReceive`
   - "To Pay" → `context.l10n.summaryTableColumnToPay`
   - "Net" → `context.l10n.summaryTableColumnNet`
   - Legend items → `context.l10n.summaryTableLegend*`

### Priority 4: Category Selector

#### category_selector.dart
Location: `lib/features/expenses/presentation/widgets/category_selector.dart`

**Steps**:
1. Add import: `import '../../../../core/l10n/l10n_extensions.dart';`
2. Replace strings:
   - Section header → `context.l10n.expenseSectionCategory`
   - Category names → Use `DefaultCategories.getLocalizedName(context, categoryId)`

## Migration Pattern Reference

### Basic String Replacement
```dart
// Before:
const Text('Hello World')

// After:
Text(context.l10n.helloWorld)
```

### Parameterized Strings
```dart
// Before:
Text('Paid by $name')

// After:
Text(context.l10n.expensePaidBy(name))
```

### Pluralization
```dart
// Before:
Text('$count participants')

// After:
Text(context.l10n.expenseParticipantCount(count))
```

### Enum Display Names
```dart
// Before:
splitType.displayName

// After:
splitType.displayName(context)
```

### Validation Messages with Builder
```dart
// When validator needs context:
validator: (value) {
  if (value == null || value.isEmpty) {
    return context.l10n.validationRequired;
  }
  return null;
}

// May need Builder widget if not in build method context
Builder(
  builder: (context) => TextField(
    decoration: InputDecoration(
      labelText: context.l10n.fieldLabel,
    ),
  ),
)
```

## Quick Migration Script Template

For each file:
1. Add import at top
2. Use Find & Replace for common patterns:
   - `'Cancel'` → `context.l10n.commonCancel`
   - `'Save'` → `context.l10n.commonSave`
   - `'Delete'` → `context.l10n.commonDelete`
   - `'Back'` → `context.l10n.commonBack`
   - `'Continue'` → `context.l10n.commonContinue`
3. Remove `const` from widgets that now use context
4. Wrap validators/decorations in Builder if needed

## Testing After Migration

After completing migrations:
1. Run `flutter analyze` - Should pass
2. Run `flutter test` - All tests should pass
3. Hot restart app and verify:
   - All UI text displays correctly
   - No missing translation errors
   - Context is available everywhere needed

## Notes

- All ARB keys are defined in `/Users/a515138832/expense_tracker/lib/l10n/app_en.arb`
- Extension helper is at `/Users/a515138832/expense_tracker/lib/core/l10n/l10n_extensions.dart`
- Total ARB entries: 250+ strings covering all UI text
- Language support: English (en) - ready for future language additions
