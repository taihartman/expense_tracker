# Localization Migration Status

## Summary
Migrating all hardcoded strings to use the new localization system (`context.l10n.stringKey`).

**ARB File**: `/Users/a515138832/expense_tracker/lib/l10n/app_en.arb` (250+ strings)
**Extension**: `/Users/a515138832/expense_tracker/lib/core/l10n/l10n_extensions.dart`

---

## ✅ COMPLETED FILES (12 files)

### 1. Enums & Constants (4 files)
- ✅ `/Users/a515138832/expense_tracker/lib/core/models/currency_code.dart`
  - Added `displayName(BuildContext context)` method
  - Maps USD → `context.l10n.currencyUSD`, VND → `context.l10n.currencyVND`

- ✅ `/Users/a515138832/expense_tracker/lib/core/models/split_type.dart`
  - Added `displayName(BuildContext context)` method
  - Removed hardcoded `final String displayName` field
  - Maps equal/weighted/itemized → `context.l10n.expenseSplitType*`

- ✅ `/Users/a515138832/expense_tracker/lib/core/constants/categories.dart`
  - Added `static String getLocalizedName(BuildContext context, String categoryName)`
  - Maps Meals/Transport/etc → `context.l10n.category*`

- ✅ `/Users/a515138832/expense_tracker/lib/features/categories/presentation/widgets/category_selector.dart`
  - Uses `DefaultCategories.getLocalizedName(context, categoryName)`
  - Section header: `context.l10n.expenseSectionCategory`

### 2. Trip Management Pages (4 files)
- ✅ `/Users/a515138832/expense_tracker/lib/features/trips/presentation/pages/trip_list_page.dart`
  - Title, empty state, base currency prefix

- ✅ `/Users/a515138832/expense_tracker/lib/features/trips/presentation/pages/trip_create_page.dart`
  - Title, field labels, validations, button text
  - Currency dropdown uses `currency.displayName(context)`

- ✅ `/Users/a515138832/expense_tracker/lib/features/trips/presentation/pages/trip_edit_page.dart`
  - Title, tooltips, field labels, validations, info message, button text
  - Currency dropdown uses `currency.displayName(context)`

- ✅ `/Users/a515138832/expense_tracker/lib/features/trips/presentation/pages/trip_settings_page.dart`
  - All strings migrated (title, tooltips, field labels, empty states, snackbars)

### 3. Trip/Participant Widgets (3 files)
- ✅ `/Users/a515138832/expense_tracker/lib/features/trips/presentation/widgets/trip_selector.dart`
  - Button labels, dialog title

- ✅ `/Users/a515138832/expense_tracker/lib/features/trips/presentation/widgets/participant_form_bottom_sheet.dart`
  - Title, field labels/hints/helpers, validations, button text, error messages

- ✅ `/Users/a515138832/expense_tracker/lib/features/trips/presentation/widgets/delete_participant_dialog.dart`
  - All dialog strings (titles, messages, instructions, button labels)

### 4. Expense Pages (1 file - partial)
- ✅ `/Users/a515138832/expense_tracker/lib/features/expenses/presentation/pages/expense_list_page.dart`
  - Title, tooltips, empty state, retry button

---

## 🔄 REMAINING FILES (Approx. 19 files)

### Priority 1: Expense Management (5 files)

#### expense_form_page.dart (606 lines) - LARGE FILE
**Pattern to follow:**
```dart
// 1. Add import
import 'package:expense_tracker/core/l10n/l10n_extensions.dart';

// 2. Common replacements:
'Add Expense' → context.l10n.expenseAddTitle
'Edit Expense' → context.l10n.expenseEditTitle
'Amount' → context.l10n.expenseFieldAmountLabel
'Description (optional)' → context.l10n.expenseFieldDescriptionLabel
'Payer *' → context.l10n.expenseFieldPayerLabel
'Date' → context.l10n.expenseFieldDateLabel
'Currency' → context.l10n.expenseFieldCurrencyLabel
'AMOUNT & CURRENCY' → context.l10n.expenseSectionAmountCurrency
'WHAT WAS IT FOR?' → context.l10n.expenseSectionDescription
'WHO PAID & WHEN?' → context.l10n.expenseSectionPayerDate
'HOW TO SPLIT?' → context.l10n.expenseSectionSplit
'CATEGORY' → context.l10n.expenseSectionCategory
'WHO'S SPLITTING? *' → context.l10n.expenseSectionParticipantsRequired
'Please select a payer' → context.l10n.validationPleaseSelectPayer
'Please select at least one participant' → context.l10n.validationPleaseSelectParticipants
'Required' → context.l10n.validationRequired
'Invalid number' → context.l10n.validationInvalidNumber
'Must be > 0' → context.l10n.validationMustBeGreaterThanZero
'Add Expense' (button) → context.l10n.expenseSaveButton
'Save Changes' → context.l10n.expenseSaveChangesButton
'Delete Expense' → context.l10n.expenseDeleteButton

// 3. Split type display - use enum method:
SplitType.equal → splitType.displayName(context)
```

#### expense_card.dart (457 lines) - LARGE FILE
**Key strings:**
```dart
'Paid by $name' → context.l10n.expensePaidBy(name)
'$count participants' → context.l10n.expenseParticipantCount(count)
'Show details' → context.l10n.expenseShowDetails
'Show less' → context.l10n.expenseShowLess
'No itemized details available' → context.l10n.expenseCardNoItemizedDetails
'Line Items' → context.l10n.expenseCardLineItemsTitle
'Extras' → context.l10n.expenseCardExtrasTitle
'Tax' → context.l10n.expenseCardExtrasTaxLabel
'Tip' → context.l10n.expenseCardExtrasTipLabel
'Per-Person Breakdown' → context.l10n.expenseCardPerPersonBreakdown
```

#### expense_form_bottom_sheet.dart (432 lines) - LARGE FILE
**Key strings:**
```dart
'No participants configured' → context.l10n.expenseNoParticipantsTitle
'Please add participants to this trip first.' → context.l10n.expenseNoParticipantsDescription
'Go Back' → context.l10n.expenseGoBackButton
'Delete Expense?' → context.l10n.expenseDeleteDialogTitle
'This action cannot be undone.' → context.l10n.expenseDeleteDialogMessage
'Cancel' → context.l10n.commonCancel
'Delete' → context.l10n.commonDelete
```

#### participant_selector.dart (211 lines)
**Key strings:**
```dart
'Required - select at least one participant' → context.l10n.expenseParticipantSelectorRequired
'Weight' → context.l10n.expenseParticipantWeightLabel
'0' → context.l10n.expenseParticipantWeightHint
```

### Priority 2: Itemized Expense Wizard (6 files - ~1000+ lines total)

All files need import: `import 'package:expense_tracker/core/l10n/l10n_extensions.dart';`

#### itemized_expense_wizard.dart
**Strings:**
```dart
'New Itemized Expense' → context.l10n.itemizedWizardTitleNew
'Edit Itemized Expense' → context.l10n.itemizedWizardTitleEdit
'People' → context.l10n.itemizedWizardStepPeople
'Items' → context.l10n.itemizedWizardStepItems
'Extras' → context.l10n.itemizedWizardStepExtras
'Review' → context.l10n.itemizedWizardStepReview
'Expense saved successfully!' → context.l10n.itemizedWizardSavedSuccess
'Expense updated successfully!' → context.l10n.itemizedWizardUpdatedSuccess
'Saving expense...' → context.l10n.itemizedWizardSaving
```

#### people_step_page.dart
**Strings:**
```dart
'Who paid for this expense? *' → context.l10n.itemizedPeopleTitle
'Select the person who paid' → context.l10n.itemizedPeopleDescription
'Required - Select the person who paid' → context.l10n.itemizedPeopleDescriptionError
'Continue to Items' → context.l10n.itemizedPeopleContinueButton
```

#### items_step_page.dart
**Strings:**
```dart
'Add items from receipt' → context.l10n.itemizedItemsTitle
'Add each item and assign who ordered it' → context.l10n.itemizedItemsDescription
'No items yet' → context.l10n.itemizedItemsEmptyTitle
'Add items from the form below' → context.l10n.itemizedItemsEmptyDescription
'Not assigned' → context.l10n.itemizedItemsNotAssigned
'Assign' → context.l10n.itemizedItemsAssignTooltip
'Edit' → context.l10n.itemizedItemsEditTooltip
'Remove' → context.l10n.itemizedItemsRemoveTooltip
'Add New Item' → context.l10n.itemizedItemsAddCardTitle
'Edit Item' → context.l10n.itemizedItemsEditCardTitle
'Item name' → context.l10n.itemizedItemsFieldNameLabel
'e.g., Caesar Salad' → context.l10n.itemizedItemsFieldNameHint
'Qty' → context.l10n.itemizedItemsFieldQtyLabel
'Price' → context.l10n.itemizedItemsFieldPriceLabel
'0.00' → context.l10n.itemizedItemsFieldPriceHint
'Add Item' → context.l10n.itemizedItemsAddButton
'Update Item' → context.l10n.itemizedItemsUpdateButton
'Continue to Extras' → context.l10n.itemizedItemsContinueButton
'Assign: $itemName' → context.l10n.itemizedItemsAssignDialogTitle(itemName)
```

#### extras_step_page.dart
**Strings:**
```dart
'Add tax & tip' → context.l10n.itemizedExtrasTitle
'Optional - leave blank if not applicable' → context.l10n.itemizedExtrasDescription
'Sales Tax' → context.l10n.itemizedExtrasTaxCardTitle
'Tax Rate (%)' → context.l10n.itemizedExtrasTaxRateLabel
'e.g., 8.875' → context.l10n.itemizedExtrasTaxRateHint
'Applies to all taxable items' → context.l10n.itemizedExtrasTaxRateHelper
'Tip / Gratuity' → context.l10n.itemizedExtrasTipCardTitle
'Tip Rate (%)' → context.l10n.itemizedExtrasTipRateLabel
'e.g., 18' → context.l10n.itemizedExtrasTipRateHint
'Calculated on pre-tax subtotal' → context.l10n.itemizedExtrasTipRateHelper
'Tax and tip will be split proportionally...' → context.l10n.itemizedExtrasInfoMessage
'Continue to Review' → context.l10n.itemizedExtrasContinueButton
```

#### review_step_page.dart
**Strings:**
```dart
'Review & Save' → context.l10n.itemizedReviewTitle
'Check the breakdown before saving' → context.l10n.itemizedReviewDescription
'Cannot Save' → context.l10n.itemizedReviewCannotSaveTitle
'Warning' → context.l10n.itemizedReviewWarningTitle
'Grand Total' → context.l10n.itemizedReviewGrandTotal
'$count people splitting' → context.l10n.itemizedReviewPeopleSplitting(count)
'Per Person Breakdown' → context.l10n.itemizedReviewPerPersonBreakdown
'PAID' → context.l10n.itemizedReviewPaidBadge
'Items Subtotal' → context.l10n.itemizedReviewItemsSubtotal
'Rounding' → context.l10n.itemizedReviewRounding
'Total' → context.l10n.itemizedReviewTotal
'Item Details' → context.l10n.itemizedReviewItemDetails
'Save Expense' → context.l10n.itemizedReviewSaveButton
'Update Expense' → context.l10n.itemizedReviewUpdateButton
```

#### itemized_expense_page.dart (if exists)
Check for any standalone strings and map to ARB entries.

### Priority 3: Settlement (4 files)

#### settlement_summary_page.dart
**Strings:**
```dart
'Settlement' → context.l10n.settlementTitle
'View Settlement' → context.l10n.settlementViewTooltip
'Recompute Settlement' → context.l10n.settlementRecomputeTooltip
'Computing settlement...' → context.l10n.settlementComputing
'Loading settlement...' → context.l10n.settlementLoading
'Loading settlement data...' → context.l10n.settlementLoadingData
'Last updated: $timestamp' → context.l10n.settlementLastUpdated(timestamp)
```

#### minimal_transfers_view.dart
**Strings:**
```dart
'All Settled!' → context.l10n.transfersAllSettledTitle
'Everyone is even, no transfers needed.' → context.l10n.transfersAllSettledDescription
'Settlement Transfers' → context.l10n.transfersCardTitle
'$count total' → context.l10n.transfersCountTotal(count)
'Tap a transfer to mark as settled' → context.l10n.transfersHintTapToSettle
'Pending Transfers' → context.l10n.transfersPendingTitle
'Settled Transfers' → context.l10n.transfersSettledTitle
'$fromName pays $toName $amount' → context.l10n.transferCopiedFormat(fromName, toName, amount)
'Copied: $text' → context.l10n.transferCopiedMessage(text)
'Mark as Settled' → context.l10n.transferMarkSettledDialogTitle
'Mark this transfer as settled?\n\n$fromName → $toName: $amount' → context.l10n.transferMarkSettledDialogMessage(fromName, toName, amount)
```

#### transfer_breakdown_bottom_sheet.dart
**Strings:**
```dart
'Transfer Breakdown' → context.l10n.transferBreakdownTitle
'View Breakdown' → context.l10n.transferBreakdownViewTooltip
'No data available' → context.l10n.transferBreakdownNoData
'Error loading breakdown: $error' → context.l10n.transferBreakdownLoadError(error)
'No expenses found...' → context.l10n.transferBreakdownNoExpenses
'Summary' → context.l10n.transferBreakdownSummaryTitle
'This shows all expenses that created debts...' → context.l10n.transferBreakdownSummaryDescription(fromName, toName)
'$count expense between these two people' → context.l10n.transferBreakdownExpenseCount(count)
'Contributing Expenses' → context.l10n.transferBreakdownContributingExpenses
'No description' → context.l10n.transferBreakdownNoDescription
'Paid by $payerName • $date' → context.l10n.transferBreakdownExpenseMetadata(payerName, date)
'Paid' → context.l10n.transferBreakdownPaidLabel
'Owes' → context.l10n.transferBreakdownOwesLabel
'Paid: ' → context.l10n.transferBreakdownPaidPrefix
'Owes: ' → context.l10n.transferBreakdownOwesPrefix
```

#### all_people_summary_table.dart
**Strings:**
```dart
'Everyone's Summary' → context.l10n.summaryTableTitle
'Person' → context.l10n.summaryTableColumnPerson
'To Receive' → context.l10n.summaryTableColumnToReceive
'To Pay' → context.l10n.summaryTableColumnToPay
'Net' → context.l10n.summaryTableColumnNet
'Will receive money' → context.l10n.summaryTableLegendWillReceive
'Needs to pay' → context.l10n.summaryTableLegendNeedsToPay
'Even' → context.l10n.summaryTableLegendEven
```

### Priority 4: Cubits Error Messages (4 files)

**Note:** Cubits don't have BuildContext. Error messages are emitted as strings in state.
Two approaches:
1. **Keep as-is** (error strings can remain technical/English for debugging)
2. **Emit error keys** and translate in UI layer

**Recommended:** Keep internal error messages as-is. Only translate user-facing errors that are displayed directly.

Files:
- `/Users/a515138832/expense_tracker/lib/features/trips/presentation/cubits/trip_cubit.dart`
- `/Users/a515138832/expense_tracker/lib/features/expenses/presentation/cubits/expense_cubit.dart`
- `/Users/a515138832/expense_tracker/lib/features/expenses/presentation/cubits/itemized_expense_cubit.dart`
- `/Users/a515138832/expense_tracker/lib/features/settlements/presentation/cubits/settlement_cubit.dart`

**If migrating errors:**
```dart
// Instead of:
emit(TripError('Failed to load trips: $e'));

// Emit error key or code:
emit(TripError('tripLoadError', details: e.toString()));

// Then in UI:
if (state is TripError) {
  Text(context.l10n.tripLoadError(state.details))
}
```

---

## Migration Checklist

For each file:

1. ✅ Add import: `import 'package:expense_tracker/core/l10n/l10n_extensions.dart';`
2. ✅ Search for all hardcoded string literals (`'...'` or `"..."`)
3. ✅ Replace with `context.l10n.stringKey`
4. ✅ For strings with parameters, use ARB placeholders: `context.l10n.stringKey(param)`
5. ✅ For enum display names, use `enum.displayName(context)`
6. ✅ For category names, use `DefaultCategories.getLocalizedName(context, name)`
7. ✅ Remove any `const` keywords from widgets that now use `context.l10n`
8. ✅ Test compilation: `flutter analyze`
9. ✅ Test build: `flutter build web`

---

## ARB Reference Quick Guide

### Common Actions
- `commonCancel` - "Cancel"
- `commonSave` - "Save"
- `commonDelete` - "Delete"
- `commonContinue` - "Continue"
- `commonBack` - "Back"
- `commonRetry` - "Retry"
- `commonAdd` - "Add"
- `commonEdit` - "Edit"
- `commonRemove` - "Remove"
- `commonUpdate` - "Update"
- `commonGotIt` - "Got It"

### Validation
- `validationRequired` - "Required"
- `validationInvalidNumber` - "Invalid number"
- `validationMustBeGreaterThanZero` - "Must be > 0"
- `validationPleaseSelectPayer` - "Please select a payer"
- `validationPleaseSelectParticipants` - "Please select at least one participant"
- `validationNameRequired` - "Name is required"
- `validationNameTooLong` - "Name must be 50 characters or less"

### Trips
- Titles: `tripCreateTitle`, `tripEditTitle`, `tripSettingsTitle`, `tripListTitle`
- Fields: `tripFieldNameLabel`, `tripFieldBaseCurrencyLabel`, `tripFieldCreatedLabel`
- Buttons: `tripCreateButton`, `tripSaveChangesButton`

### Expenses
- Titles: `expenseListTitle`, `expenseAddTitle`, `expenseEditTitle`
- Fields: `expenseFieldAmountLabel`, `expenseFieldDescriptionLabel`, `expenseFieldPayerLabel`, `expenseFieldDateLabel`
- Sections: `expenseSectionAmountCurrency`, `expenseSectionDescription`, `expenseSectionSplit`
- Split types: `expenseSplitTypeEqual`, `expenseSplitTypeWeighted`, `expenseSplitTypeItemized`

### Itemized
- All prefixed with `itemized*`
- Wizard: `itemizedWizardTitle*`, `itemizedWizardStep*`
- Steps: `itemizedPeople*`, `itemizedItems*`, `itemizedExtras*`, `itemizedReview*`

### Settlement
- All prefixed with `settlement*` or `transfer*`
- Summary table: `summaryTable*`

---

## Testing After Migration

```bash
# 1. Analyze code
flutter analyze

# 2. Format code
flutter format .

# 3. Build web
flutter build web

# 4. Run app
flutter run -d chrome

# 5. Test each feature:
#    - Create/edit trip
#    - Add/edit expense
#    - Add itemized expense
#    - View settlement
#    - All dialogs and validations
```

---

## Notes

- **Don't migrate:** Debug logs, internal IDs, technical error messages
- **Currency display:** Use `currency.displayName(context)` method
- **Split type display:** Use `splitType.displayName(context)` method
- **Category display:** Use `DefaultCategories.getLocalizedName(context, name)`
- **Remove `const`:** Widgets using `context.l10n` cannot be const
- **Pluralization:** ARB handles plurals automatically (e.g., `expenseParticipantCount`)
- **Date formatting:** Keep using existing date formatters, but labels should be localized

---

## Files Migrated Summary

**Total files to migrate:** ~31 files
**Completed:** 12 files (39%)
**Remaining:** 19 files (61%)

**Time estimate for remaining files:** 3-4 hours for manual migration
