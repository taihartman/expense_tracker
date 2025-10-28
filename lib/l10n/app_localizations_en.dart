// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonSave => 'Save';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonContinue => 'Continue';

  @override
  String get commonBack => 'Back';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonAdd => 'Add';

  @override
  String get commonEdit => 'Edit';

  @override
  String get commonRemove => 'Remove';

  @override
  String get commonUpdate => 'Update';

  @override
  String get commonGotIt => 'Got It';

  @override
  String get commonRequired => 'Required';

  @override
  String get commonLoading => 'Loading...';

  @override
  String get commonError => 'Error';

  @override
  String get validationRequired => 'Required';

  @override
  String get validationInvalidNumber => 'Invalid number';

  @override
  String get validationMustBeGreaterThanZero => 'Must be > 0';

  @override
  String get validationPleaseEnterTripName => 'Please enter a trip name';

  @override
  String get validationTripNameTooLong =>
      'Trip name must be 100 characters or less';

  @override
  String get validationNameRequired => 'Name is required';

  @override
  String get validationNameTooLong => 'Name must be 50 characters or less';

  @override
  String get validationPleaseSelectPayer => 'Please select a payer';

  @override
  String get validationPleaseSelectParticipants =>
      'Please select at least one participant';

  @override
  String get validationPleaseFillAllFields => 'Please fill in all fields';

  @override
  String validationInvalidInput(String error) {
    return 'Invalid input: $error';
  }

  @override
  String validationInvalidPrice(String error) {
    return 'Invalid price: $error';
  }

  @override
  String get validationAtLeastOneItemRequired =>
      'At least one item is required';

  @override
  String validationItemsNotAssigned(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items not assigned to anyone',
      one: '1 item not assigned to anyone',
    );
    return '$_temp0';
  }

  @override
  String validationTaxTooHigh(String value) {
    return 'Tax percentage is unusually high ($value%)';
  }

  @override
  String validationTipTooHigh(String value) {
    return 'Tip percentage is unusually high ($value%)';
  }

  @override
  String validationParticipantAlreadyExists(String name) {
    return 'A participant named $name already exists';
  }

  @override
  String get tripCreateTitle => 'Create Trip';

  @override
  String get tripEditTitle => 'Edit Trip';

  @override
  String get tripSettingsTitle => 'Trip Settings';

  @override
  String get tripListTitle => 'My Trips';

  @override
  String get tripSelectTitle => 'Select Trip';

  @override
  String get tripFieldNameLabel => 'Trip Name';

  @override
  String get tripFieldBaseCurrencyLabel => 'Base Currency';

  @override
  String get tripFieldBaseCurrencyHelper =>
      'All settlements will be calculated in this currency';

  @override
  String get tripFieldBaseCurrencyEditHelper =>
      'Used for settlement displays. Expense amounts are not converted.';

  @override
  String get tripFieldCreatedLabel => 'Created';

  @override
  String get tripCreateButton => 'Create Trip';

  @override
  String get tripSaveChangesButton => 'Save Changes';

  @override
  String get tripBackToExpenses => 'Back to Expenses';

  @override
  String get tripBackToSettings => 'Back to Settings';

  @override
  String get tripCurrencyChangedInfo =>
      'Changing base currency only affects how settlements are displayed. Individual expense amounts remain unchanged.';

  @override
  String get tripEmptyStateTitle => 'No trips yet';

  @override
  String tripLoadError(String error) {
    return 'Failed to load trips: $error';
  }

  @override
  String tripCreateError(String error) {
    return 'Failed to create trip: $error';
  }

  @override
  String tripUpdateError(String error) {
    return 'Failed to update trip: $error';
  }

  @override
  String tripDeleteError(String error) {
    return 'Failed to delete trip: $error';
  }

  @override
  String get tripSettingsLoadError => 'Failed to load trip settings';

  @override
  String get tripBaseCurrencyPrefix => 'Base: ';

  @override
  String get participantSectionTitle => 'Participants';

  @override
  String get participantAddButton => 'Add Participant';

  @override
  String get participantAddTitle => 'Add Participant';

  @override
  String get participantRemoveButton => 'Remove';

  @override
  String get participantRemoveTooltip => 'Remove';

  @override
  String get participantFieldNameLabel => 'Name *';

  @override
  String get participantFieldNameHint => 'Enter name (e.g., \"Sarah\")';

  @override
  String get participantFieldIdLabel => 'Participant ID';

  @override
  String get participantFieldIdHint => 'Auto-generated from name';

  @override
  String get participantFieldIdHelper =>
      'Auto-generated from name. Used internally for tracking.';

  @override
  String get participantEmptyStateTitle => 'No participants added yet';

  @override
  String get participantEmptyStateDescription =>
      'Tap the + button below to add your first participant';

  @override
  String participantAddedSuccess(String name) {
    return '$name added successfully';
  }

  @override
  String participantAddError(String error) {
    return 'Failed to add participant: $error';
  }

  @override
  String get participantDeleteDialogTitle => 'Remove Participant?';

  @override
  String participantDeleteDialogMessage(String name) {
    return 'Are you sure you want to remove $name from this trip?\n\nThis action cannot be undone.';
  }

  @override
  String get participantDeleteDialogCannotRemoveTitle =>
      'Cannot Remove Participant';

  @override
  String participantDeleteDialogCannotRemoveMessage(String name, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count expenses',
      one: '1 expense',
    );
    return '$name is used in $_temp0 and cannot be removed.';
  }

  @override
  String get participantDeleteDialogInstructionsHeader =>
      'To remove this participant:';

  @override
  String get participantDeleteDialogInstructions =>
      '1. Delete or reassign their expenses\n2. Try removing them again';

  @override
  String get expenseListTitle => 'Expenses';

  @override
  String get expenseAddButton => 'Add Expense';

  @override
  String get expenseAddTooltip => 'Add Expense';

  @override
  String get expenseAddTitle => 'Add Expense';

  @override
  String get expenseEditTitle => 'Edit Expense';

  @override
  String get expenseSaveButton => 'Add Expense';

  @override
  String get expenseSaveChangesButton => 'Save Changes';

  @override
  String get expenseUpdateButton => 'Update Expense';

  @override
  String get expenseDeleteButton => 'Delete Expense';

  @override
  String get expenseEmptyStateTitle => 'No expenses yet';

  @override
  String get expenseEmptyStateDescription => 'Tap + to add your first expense';

  @override
  String get expenseNoParticipantsTitle => 'No participants configured';

  @override
  String get expenseNoParticipantsDescription =>
      'Please add participants to this trip first.';

  @override
  String get expenseGoBackButton => 'Go Back';

  @override
  String get expenseSectionAmountCurrency => 'AMOUNT & CURRENCY';

  @override
  String get expenseSectionDescription => 'WHAT WAS IT FOR?';

  @override
  String get expenseSectionPayerDate => 'WHO PAID & WHEN?';

  @override
  String get expenseSectionSplit => 'HOW TO SPLIT?';

  @override
  String get expenseSectionCategory => 'CATEGORY';

  @override
  String get expenseSectionParticipants => 'WHO\'S SPLITTING?';

  @override
  String get expenseSectionParticipantsRequired => 'WHO\'S SPLITTING? *';

  @override
  String get expenseFieldAmountLabel => 'Amount';

  @override
  String get expenseFieldDescriptionLabel => 'Description (optional)';

  @override
  String get expenseFieldPayerLabel => 'Payer *';

  @override
  String get expenseFieldPayerRequired => 'Required';

  @override
  String get expenseFieldDateLabel => 'Date';

  @override
  String get expenseFieldCurrencyLabel => 'Currency';

  @override
  String get expenseSplitTypeEqual => 'Equal';

  @override
  String get expenseSplitTypeWeighted => 'Weighted';

  @override
  String get expenseSplitTypeItemized => 'Itemized (Add Line Items)';

  @override
  String get expenseParticipantSelectorRequired =>
      'Required - select at least one participant';

  @override
  String get expenseParticipantWeightLabel => 'Weight';

  @override
  String get expenseParticipantWeightHint => '0';

  @override
  String expensePaidBy(String name) {
    return 'Paid by $name';
  }

  @override
  String expenseParticipantCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count participants',
      one: '1 participant',
    );
    return '$_temp0';
  }

  @override
  String get expenseShowDetails => 'Show details';

  @override
  String get expenseShowLess => 'Show less';

  @override
  String get expenseDeleteDialogTitle => 'Delete Expense?';

  @override
  String get expenseDeleteDialogMessage => 'This action cannot be undone.';

  @override
  String expenseLoadError(String error) {
    return 'Failed to load expenses: $error';
  }

  @override
  String expenseCreateError(String error) {
    return 'Failed to create expense: $error';
  }

  @override
  String expenseUpdateError(String error) {
    return 'Failed to update expense: $error';
  }

  @override
  String expenseDeleteError(String error) {
    return 'Failed to delete expense: $error';
  }

  @override
  String expenseItemizedOpenError(String error) {
    return 'Error opening itemized expense: $error';
  }

  @override
  String get itemizedWizardTitleNew => 'New Itemized Expense';

  @override
  String get itemizedWizardTitleEdit => 'Edit Itemized Expense';

  @override
  String get itemizedWizardSavedSuccess => 'Expense saved successfully!';

  @override
  String get itemizedWizardUpdatedSuccess => 'Expense updated successfully!';

  @override
  String get itemizedWizardSaving => 'Saving expense...';

  @override
  String get itemizedWizardStepPeople => 'People';

  @override
  String get itemizedWizardStepItems => 'Items';

  @override
  String get itemizedWizardStepExtras => 'Extras';

  @override
  String get itemizedWizardStepReview => 'Review';

  @override
  String get itemizedPeopleTitle => 'Who paid for this expense? *';

  @override
  String get itemizedPeopleDescription => 'Select the person who paid';

  @override
  String get itemizedPeopleDescriptionError =>
      'Required - Select the person who paid';

  @override
  String get itemizedPeopleContinueButton => 'Continue to Items';

  @override
  String get itemizedItemsTitle => 'Add items from receipt';

  @override
  String get itemizedItemsDescription =>
      'Add each item and assign who ordered it';

  @override
  String get itemizedItemsEmptyTitle => 'No items yet';

  @override
  String get itemizedItemsEmptyDescription => 'Add items from the form below';

  @override
  String get itemizedItemsNotAssigned => 'Not assigned';

  @override
  String get itemizedItemsAssignTooltip => 'Assign';

  @override
  String get itemizedItemsEditTooltip => 'Edit';

  @override
  String get itemizedItemsRemoveTooltip => 'Remove';

  @override
  String get itemizedItemsAddCardTitle => 'Add New Item';

  @override
  String get itemizedItemsEditCardTitle => 'Edit Item';

  @override
  String get itemizedItemsFieldNameLabel => 'Item name';

  @override
  String get itemizedItemsFieldNameHint => 'e.g., Caesar Salad';

  @override
  String get itemizedItemsFieldQtyLabel => 'Qty';

  @override
  String get itemizedItemsFieldPriceLabel => 'Price';

  @override
  String get itemizedItemsFieldPriceHint => '0.00';

  @override
  String get itemizedItemsAddButton => 'Add Item';

  @override
  String get itemizedItemsUpdateButton => 'Update Item';

  @override
  String get itemizedItemsContinueButton => 'Continue to Extras';

  @override
  String itemizedItemsAssignDialogTitle(String itemName) {
    return 'Assign: $itemName';
  }

  @override
  String get itemizedExtrasTitle => 'Add tax & tip';

  @override
  String get itemizedExtrasDescription =>
      'Optional - leave blank if not applicable';

  @override
  String get itemizedExtrasTaxCardTitle => 'Sales Tax';

  @override
  String get itemizedExtrasTaxRateLabel => 'Tax Rate (%)';

  @override
  String get itemizedExtrasTaxRateHint => 'e.g., 8.875';

  @override
  String get itemizedExtrasTaxRateHelper => 'Applies to all taxable items';

  @override
  String get itemizedExtrasTipCardTitle => 'Tip / Gratuity';

  @override
  String get itemizedExtrasTipRateLabel => 'Tip Rate (%)';

  @override
  String get itemizedExtrasTipRateHint => 'e.g., 18';

  @override
  String get itemizedExtrasTipRateHelper => 'Calculated on pre-tax subtotal';

  @override
  String get itemizedExtrasInfoMessage =>
      'Tax and tip will be split proportionally based on each person\'s item subtotal';

  @override
  String get itemizedExtrasContinueButton => 'Continue to Review';

  @override
  String get itemizedReviewTitle => 'Review & Save';

  @override
  String get itemizedReviewDescription => 'Check the breakdown before saving';

  @override
  String get itemizedReviewCannotSaveTitle => 'Cannot Save';

  @override
  String get itemizedReviewWarningTitle => 'Warning';

  @override
  String get itemizedReviewGrandTotal => 'Grand Total';

  @override
  String itemizedReviewPeopleSplitting(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count people splitting',
      one: '1 person splitting',
    );
    return '$_temp0';
  }

  @override
  String get itemizedReviewPerPersonBreakdown => 'Per Person Breakdown';

  @override
  String get itemizedReviewPaidBadge => 'PAID';

  @override
  String get itemizedReviewItemsSubtotal => 'Items Subtotal';

  @override
  String get itemizedReviewRounding => 'Rounding';

  @override
  String get itemizedReviewTotal => 'Total';

  @override
  String get itemizedReviewItemDetails => 'Item Details';

  @override
  String get itemizedReviewSaveButton => 'Save Expense';

  @override
  String get itemizedReviewUpdateButton => 'Update Expense';

  @override
  String get itemizedExpenseCannotEditNotItemized =>
      'Cannot edit: expense is not itemized';

  @override
  String get itemizedExpenseCannotEditNoItems =>
      'Cannot edit: expense has no items';

  @override
  String get itemizedExpenseCannotSaveNotReady =>
      'Cannot save: expense not ready';

  @override
  String get itemizedExpenseCannotSaveValidationErrors =>
      'Cannot save: validation errors exist';

  @override
  String get itemizedExpenseCannotSaveNoPayerSelected =>
      'Cannot save: payer not selected';

  @override
  String itemizedExpenseSaveError(String error) {
    return 'Failed to save expense: $error';
  }

  @override
  String itemizedExpenseCalculationError(String error) {
    return 'Calculation error: $error';
  }

  @override
  String get itemizedExpenseGeneratedDescriptionNoItems => 'Itemized expense';

  @override
  String itemizedExpenseGeneratedDescriptionMultiple(
    String item1,
    String item2,
    int count,
  ) {
    return '$item1, $item2, and $count more';
  }

  @override
  String get expenseCardNoItemizedDetails => 'No itemized details available';

  @override
  String get expenseCardLineItemsTitle => 'Line Items';

  @override
  String get expenseCardExtrasTitle => 'Extras';

  @override
  String get expenseCardExtrasTaxLabel => 'Tax';

  @override
  String get expenseCardExtrasTipLabel => 'Tip';

  @override
  String get expenseCardPerPersonBreakdown => 'Per-Person Breakdown';

  @override
  String get settlementTitle => 'Settlement';

  @override
  String get settlementViewTooltip => 'View Settlement';

  @override
  String get settlementRecomputeTooltip => 'Recompute Settlement';

  @override
  String get settlementComputing => 'Computing settlement...';

  @override
  String get settlementLoading => 'Loading settlement...';

  @override
  String get settlementLoadingData => 'Loading settlement data...';

  @override
  String settlementLastUpdated(String timestamp) {
    return 'Last updated: $timestamp';
  }

  @override
  String settlementCalculateError(String error) {
    return 'Failed to calculate settlement: $error';
  }

  @override
  String settlementLoadError(String error) {
    return 'Failed to load settlement: $error';
  }

  @override
  String settlementMarkSettledError(String error) {
    return 'Failed to mark transfer as settled: $error';
  }

  @override
  String settlementTripNotFoundError(String tripId) {
    return 'Trip not found: $tripId';
  }

  @override
  String get transfersAllSettledTitle => 'All Settled!';

  @override
  String get transfersAllSettledDescription =>
      'Everyone is even, no transfers needed.';

  @override
  String get transfersCardTitle => 'Settlement Transfers';

  @override
  String transfersCountTotal(int count) {
    return '$count total';
  }

  @override
  String get transfersHintTapToSettle => 'Tap a transfer to mark as settled';

  @override
  String get transfersPendingTitle => 'Pending Transfers';

  @override
  String get transfersSettledTitle => 'Settled Transfers';

  @override
  String transferCopiedFormat(String fromName, String toName, String amount) {
    return '$fromName pays $toName $amount';
  }

  @override
  String transferCopiedMessage(String text) {
    return 'Copied: $text';
  }

  @override
  String get transferMarkSettledDialogTitle => 'Mark as Settled';

  @override
  String transferMarkSettledDialogMessage(
    String fromName,
    String toName,
    String amount,
  ) {
    return 'Mark this transfer as settled?\n\n$fromName → $toName: $amount';
  }

  @override
  String get transferBreakdownTitle => 'Transfer Breakdown';

  @override
  String get transferBreakdownViewTooltip => 'View Breakdown';

  @override
  String get transferBreakdownNoData => 'No data available';

  @override
  String transferBreakdownLoadError(String error) {
    return 'Error loading breakdown: $error';
  }

  @override
  String get transferBreakdownNoExpenses =>
      'No expenses found that contribute to this transfer.';

  @override
  String get transferBreakdownSummaryTitle => 'Summary';

  @override
  String transferBreakdownSummaryDescription(String fromName, String toName) {
    return 'This shows all expenses that created debts between $fromName and $toName. The amounts shown are the exact debts from each expense, after pairwise netting.';
  }

  @override
  String transferBreakdownExpenseCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count expenses between these two people',
      one: '1 expense between these two people',
    );
    return '$_temp0';
  }

  @override
  String get transferBreakdownContributingExpenses => 'Contributing Expenses';

  @override
  String get transferBreakdownNoDescription => 'No description';

  @override
  String transferBreakdownExpenseMetadata(String payerName, String date) {
    return 'Paid by $payerName • $date';
  }

  @override
  String get transferBreakdownPaidLabel => 'Paid';

  @override
  String get transferBreakdownOwesLabel => 'Owes';

  @override
  String get transferBreakdownPaidPrefix => 'Paid: ';

  @override
  String get transferBreakdownOwesPrefix => 'Owes: ';

  @override
  String get summaryTableTitle => 'Everyone\'s Summary';

  @override
  String get summaryTableColumnPerson => 'Person';

  @override
  String get summaryTableColumnToReceive => 'To Receive';

  @override
  String get summaryTableColumnToPay => 'To Pay';

  @override
  String get summaryTableColumnNet => 'Net';

  @override
  String get summaryTableLegendWillReceive => 'Will receive money';

  @override
  String get summaryTableLegendNeedsToPay => 'Needs to pay';

  @override
  String get summaryTableLegendEven => 'Even';

  @override
  String get dateToday => 'Today';

  @override
  String get dateYesterday => 'Yesterday';

  @override
  String dateDaysAgo(int days) {
    return '${days}d ago';
  }

  @override
  String get currencyUSD => 'US Dollar';

  @override
  String get currencyVND => 'Vietnamese Dong';

  @override
  String get categoryMeals => 'Meals';

  @override
  String get categoryTransport => 'Transport';

  @override
  String get categoryAccommodation => 'Accommodation';

  @override
  String get categoryActivities => 'Activities';

  @override
  String get categoryShopping => 'Shopping';

  @override
  String get categoryOther => 'Other';
}
