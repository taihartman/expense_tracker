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
  String get commonClose => 'Close';

  @override
  String get commonConfirm => 'Confirm';

  @override
  String get splashAppName => 'Expense Tracker';

  @override
  String get splashLoading => 'Loading...';

  @override
  String get splashLoadingAccessibility => 'Loading Expense Tracker';

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
  String get tripSelectTitle => 'My Trips';

  @override
  String get tripFieldNameLabel => 'Trip Name';

  @override
  String get tripFieldCreatorNameLabel => 'Your Name';

  @override
  String get tripFieldCreatorNameHelper =>
      'Your name will be added as the first member of this trip';

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
  String get tripLeaveButton => 'Leave Trip';

  @override
  String get tripCurrencyChangedInfo =>
      'Changing base currency only affects how settlements are displayed. Individual expense amounts remain unchanged.';

  @override
  String get tripEmptyStateTitle => 'No trips yet';

  @override
  String get tripEmptyStateDescription =>
      'Create a new trip or join an existing one';

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
  String get tripLeaveDialogTitle => 'Leave Trip?';

  @override
  String get tripLeaveDialogMessage =>
      'You will lose access to this trip and all its expenses. You\'ll need an invite link to rejoin.';

  @override
  String get tripLeaveDialogConfirm => 'Leave Trip';

  @override
  String tripLeftSuccess(String tripName) {
    return 'Left $tripName successfully';
  }

  @override
  String get tripArchiveButton => 'Archive Trip';

  @override
  String get tripUnarchiveButton => 'Unarchive Trip';

  @override
  String get tripArchiveDialogTitle => 'Archive Trip?';

  @override
  String get tripArchiveDialogMessage =>
      'This will hide the trip from your active trip list. You can restore it later from archived trips.';

  @override
  String get tripArchiveSuccess => 'Trip archived';

  @override
  String get tripUnarchiveSuccess => 'Trip unarchived';

  @override
  String get tripArchivedPageTitle => 'Archived Trips';

  @override
  String get tripViewArchivedButton => 'View Archived Trips';

  @override
  String get tripArchivedEmptyStateTitle => 'No Archived Trips';

  @override
  String get tripArchivedEmptyStateMessage =>
      'Trips you archive will appear here';

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
  String get expenseFabMainTooltip => 'Add expense options';

  @override
  String get expenseFabQuickExpenseTooltip => 'Quick Expense';

  @override
  String get expenseFabReceiptSplitTooltip =>
      'Receipt Split (Who Ordered What)';

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
  String get expenseSplitTypeReceiptSplit => 'Receipt Split (Who Ordered What)';

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
    return 'Error opening receipt split: $error';
  }

  @override
  String get receiptSplitWizardTitleNew => 'New Receipt Split';

  @override
  String get receiptSplitWizardTitleEdit => 'Edit Receipt Split';

  @override
  String get receiptSplitWizardSavedSuccess => 'Expense saved successfully!';

  @override
  String get receiptSplitWizardUpdatedSuccess =>
      'Expense updated successfully!';

  @override
  String get receiptSplitWizardSaving => 'Saving expense...';

  @override
  String get receiptSplitWizardStepReceiptInfo => 'Receipt';

  @override
  String get receiptSplitWizardStepPeople => 'People';

  @override
  String get receiptSplitWizardStepItems => 'Items';

  @override
  String get receiptSplitWizardStepExtras => 'Tip';

  @override
  String get receiptSplitWizardStepReview => 'Review';

  @override
  String get receiptSplitReceiptInfoTitle => 'Receipt Details';

  @override
  String get receiptSplitReceiptInfoDescription =>
      'Enter the subtotal and tax from your receipt';

  @override
  String get receiptSplitReceiptInfoSubtotalLabel =>
      'Subtotal (before tax & tip) *';

  @override
  String get receiptSplitReceiptInfoSubtotalHint => '0.00';

  @override
  String get receiptSplitReceiptInfoSubtotalHelper =>
      'Items you add should sum to this amount';

  @override
  String get receiptSplitReceiptInfoTaxLabel => 'Tax Amount';

  @override
  String get receiptSplitReceiptInfoTaxHint => '0.00';

  @override
  String get receiptSplitReceiptInfoTaxHelper => 'Leave blank if no tax';

  @override
  String get receiptSplitReceiptInfoContinueButton => 'Continue to Payer';

  @override
  String get receiptSplitPeopleTitle => 'Who paid for this expense? *';

  @override
  String get receiptSplitPeopleDescription => 'Select the person who paid';

  @override
  String get receiptSplitPeopleDescriptionError =>
      'Required - Select the person who paid';

  @override
  String get receiptSplitPeopleContinueButton => 'Continue to Items';

  @override
  String get receiptSplitItemsTitle => 'Add items from receipt';

  @override
  String get receiptSplitItemsDescription =>
      'Add each item and assign who ordered it';

  @override
  String get receiptSplitItemsEmptyTitle => 'No items yet';

  @override
  String get receiptSplitItemsEmptyDescription =>
      'Add items from the form below';

  @override
  String get receiptSplitItemsNotAssigned => 'Not assigned';

  @override
  String get receiptSplitItemsAssignTooltip => 'Assign';

  @override
  String get receiptSplitItemsEditTooltip => 'Edit';

  @override
  String get receiptSplitItemsRemoveTooltip => 'Remove';

  @override
  String get receiptSplitItemsAddCardTitle => 'Add New Item';

  @override
  String get receiptSplitItemsEditCardTitle => 'Edit Item';

  @override
  String get receiptSplitItemsFieldNameLabel => 'Item name';

  @override
  String get receiptSplitItemsFieldNameHint => 'e.g., Caesar Salad';

  @override
  String get receiptSplitItemsFieldQtyLabel => 'Qty';

  @override
  String get receiptSplitItemsFieldPriceLabel => 'Price';

  @override
  String get receiptSplitItemsFieldPriceHint => '0.00';

  @override
  String get receiptSplitItemsAddButton => 'Add Item';

  @override
  String get receiptSplitItemsUpdateButton => 'Update Item';

  @override
  String get receiptSplitItemsContinueButton => 'Continue to Tip';

  @override
  String get receiptSplitItemsExpectedSubtotal => 'Expected Subtotal';

  @override
  String get receiptSplitItemsCurrentTotal => 'Current Items Total';

  @override
  String get receiptSplitItemsDifference => 'Difference';

  @override
  String get receiptSplitItemsSubtotalMatch =>
      '✓ Items match expected subtotal';

  @override
  String get receiptSplitItemsSubtotalMismatch =>
      'Items don\'t match expected subtotal';

  @override
  String get receiptSplitItemsValidationHelper =>
      'Keep adding items until total matches subtotal';

  @override
  String receiptSplitItemsAssignDialogTitle(Object itemName) {
    return 'Assign: $itemName';
  }

  @override
  String get receiptSplitExtrasTitle => 'Add tip';

  @override
  String get receiptSplitExtrasDescription =>
      'Optional - leave blank if not applicable';

  @override
  String get receiptSplitExtrasTipCardTitle => 'Tip / Gratuity';

  @override
  String get receiptSplitExtrasTipAmountLabel => 'Tip Amount';

  @override
  String get receiptSplitExtrasTipAmountHint => '0.00';

  @override
  String get receiptSplitExtrasTipRateLabel => 'Or Tip Rate (%)';

  @override
  String get receiptSplitExtrasTipRateHint => 'e.g., 18';

  @override
  String get receiptSplitExtrasTipRateHelper => 'Calculated on items subtotal';

  @override
  String get receiptSplitExtrasInfoMessage =>
      'Tip will be split proportionally based on each person\'s item subtotal';

  @override
  String get receiptSplitExtrasContinueButton => 'Continue to Review';

  @override
  String get receiptSplitReviewTitle => 'Review & Save';

  @override
  String get receiptSplitReviewDescription =>
      'Check the breakdown before saving';

  @override
  String get receiptSplitReviewCannotSaveTitle => 'Cannot Save';

  @override
  String get receiptSplitReviewWarningTitle => 'Warning';

  @override
  String get receiptSplitReviewSubtotalWarningTitle => 'Subtotal Mismatch';

  @override
  String receiptSplitReviewSubtotalWarningMessage(
    String itemsTotal,
    String expectedSubtotal,
    String difference,
  ) {
    return 'Your items ($itemsTotal) don\'t match the expected subtotal ($expectedSubtotal). Difference: $difference';
  }

  @override
  String get receiptSplitReviewExpectedSubtotal => 'Expected Subtotal';

  @override
  String get receiptSplitReviewItemsTotal => 'Items Total';

  @override
  String get receiptSplitReviewTaxFromReceipt => 'Tax (from receipt)';

  @override
  String get receiptSplitReviewGrandTotal => 'Grand Total';

  @override
  String receiptSplitReviewPeopleSplitting(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count people splitting',
      one: '1 person splitting',
    );
    return '$_temp0';
  }

  @override
  String get receiptSplitReviewPerPersonBreakdown => 'Per Person Breakdown';

  @override
  String get receiptSplitReviewPaidBadge => 'PAID';

  @override
  String get receiptSplitReviewItemsSubtotal => 'Items Subtotal';

  @override
  String get receiptSplitReviewRounding => 'Rounding';

  @override
  String get receiptSplitReviewTotal => 'Total';

  @override
  String get receiptSplitReviewItemDetails => 'Item Details';

  @override
  String get receiptSplitReviewSaveButton => 'Save Expense';

  @override
  String get receiptSplitReviewUpdateButton => 'Update Expense';

  @override
  String get receiptSplitExpenseCannotEditNotItemized =>
      'Cannot edit: expense is not itemized';

  @override
  String get receiptSplitExpenseCannotEditNoItems =>
      'Cannot edit: expense has no items';

  @override
  String get receiptSplitExpenseCannotSaveNotReady =>
      'Cannot save: expense not ready';

  @override
  String get receiptSplitExpenseCannotSaveValidationErrors =>
      'Cannot save: validation errors exist';

  @override
  String get receiptSplitExpenseCannotSaveNoPayerSelected =>
      'Cannot save: payer not selected';

  @override
  String receiptSplitExpenseSaveError(Object error) {
    return 'Failed to save expense: $error';
  }

  @override
  String receiptSplitExpenseCalculationError(Object error) {
    return 'Calculation error: $error';
  }

  @override
  String get receiptSplitExpenseGeneratedDescriptionNoItems =>
      'Itemized expense';

  @override
  String receiptSplitExpenseGeneratedDescriptionMultiple(
    Object count,
    Object item1,
    Object item2,
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
  String get transferFilterAll => 'All';

  @override
  String get transferFilterOwes => 'Owes';

  @override
  String get transferFilterOwed => 'Owed';

  @override
  String transferFilterActive(String name) {
    return 'Filtering $name\'s transfers';
  }

  @override
  String get transferFilterClear => 'Clear filter';

  @override
  String get transferFilterHint => 'Tap any person above to filter transfers';

  @override
  String transferFilterNoResults(String name) {
    return 'No transfers for $name';
  }

  @override
  String get transferNameChipHint => 'Tip: Tap any name to filter transfers';

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
  String get currencySearchFieldLabel => 'Currency';

  @override
  String get currencySearchFieldHint => 'Select currency';

  @override
  String get currencySearchPlaceholder => 'Search by code or name';

  @override
  String get currencySearchNoResults => 'No currencies found';

  @override
  String get currencySearchNoResultsHint => 'Try a different search term';

  @override
  String get currencySearchModalTitle => 'Select Currency';

  @override
  String get currencySearchClearButton => 'Clear search';

  @override
  String get multiCurrencySelectorTitle => 'Allowed Currencies';

  @override
  String get multiCurrencySelectorHelpText =>
      'Select 1-10 currencies for this trip. The first currency will be the default for new expenses.';

  @override
  String get multiCurrencySelectorAddButton => 'Add Currency';

  @override
  String get multiCurrencySelectorMaxError => 'Maximum 10 currencies allowed';

  @override
  String get multiCurrencySelectorMinError => 'At least 1 currency is required';

  @override
  String get multiCurrencySelectorDuplicateError =>
      'This currency is already added';

  @override
  String get multiCurrencySelectorMoveUp => 'Move up';

  @override
  String get multiCurrencySelectorMoveDown => 'Move down';

  @override
  String get multiCurrencySelectorRemove => 'Remove currency';

  @override
  String multiCurrencySelectorChipLabel(String currencyCode) {
    return '$currencyCode';
  }

  @override
  String get categoryMeals => 'Meals';

  @override
  String get categoryTransport => 'Transport';

  @override
  String get categoryOther => 'Other';

  @override
  String get categoryAccommodation => 'Accommodation';

  @override
  String get categoryActivities => 'Activities';

  @override
  String get categoryShopping => 'Shopping';

  @override
  String get categoryBrowseAndCreate => 'Browse & Create';

  @override
  String get tripJoinTitle => 'Join Trip';

  @override
  String get tripJoinCodeLabel => 'Invite Code';

  @override
  String get tripJoinCodeHint => 'Enter the trip invite code';

  @override
  String get tripJoinNameLabel => 'Your Name';

  @override
  String get tripJoinNameHint => 'How should others see you?';

  @override
  String get tripJoinButton => 'Join Trip';

  @override
  String get tripJoinInvalidCode => 'Invalid or non-existent trip code';

  @override
  String get tripJoinAlreadyMember => 'You\'ve already joined this trip';

  @override
  String get tripJoinSuccess => 'Successfully joined trip!';

  @override
  String tripJoinError(String error) {
    return 'Failed to join trip: $error';
  }

  @override
  String get tripInviteTitle => 'Invite Friends';

  @override
  String get tripInviteCodeLabel => 'Invite Code';

  @override
  String get tripInviteCodeDescription =>
      'Share this code with friends to invite them to the trip';

  @override
  String get tripInviteCopyButton => 'Copy Code';

  @override
  String get tripInviteShareButton => 'Share Link';

  @override
  String get tripInviteCodeCopied => 'Invite code copied to clipboard';

  @override
  String tripInviteShareMessage(String code, String link) {
    return 'Join my trip on Expense Tracker! Use code: $code or click: $link';
  }

  @override
  String get tripInviteShareMessageButton => 'Share Message';

  @override
  String get tripInviteMessageCopied => 'Message copied to clipboard';

  @override
  String get tripInviteShareableLinkLabel => 'Shareable Link';

  @override
  String get tripInviteCopyLinkButton => 'Copy Link';

  @override
  String get tripInviteLinkCopied => 'Link copied to clipboard';

  @override
  String get tripInviteShowQrButton => 'Show QR Code';

  @override
  String get tripInviteQrDialogTitle => 'Scan to Join Trip';

  @override
  String get tripInviteQrDialogDescription =>
      'Scan this QR code with your phone camera or any QR scanner app to join the trip.';

  @override
  String get tripInviteCopyFallbackTitle => 'Copy Invite Message';

  @override
  String get tripInviteCopyFallbackMessage =>
      'Automatic copy failed. Please manually select and copy the text below:';

  @override
  String get tripInviteCopyError => 'Failed to copy message. Please try again.';

  @override
  String get tripInviteInstructionsTitle => 'How to invite friends';

  @override
  String get tripInviteInstructionStep1 =>
      'Share the message, code, or link with your friends';

  @override
  String get tripInviteInstructionStep2 =>
      'They click the link or enter the code on the Join Trip page';

  @override
  String get tripInviteInstructionStep3 =>
      'They select their identity and verify via device pairing or recovery code';

  @override
  String get activityLogTitle => 'Activity Log';

  @override
  String get activityLogEmpty =>
      'No activities yet. Start by adding expenses or inviting friends!';

  @override
  String get activityLogLoadMore => 'Load More';

  @override
  String get activityLogLoading => 'Loading activities...';

  @override
  String get activityJoinViaLink => 'via invite link';

  @override
  String get activityJoinViaQr => 'via QR code';

  @override
  String get activityJoinManual => 'by entering code';

  @override
  String get activityJoinRecovery => 'using recovery code';

  @override
  String activityInvitedBy(String name) {
    return 'invited by $name';
  }

  @override
  String activityTripCreated(String name) {
    return '$name created the trip';
  }

  @override
  String activityMemberJoined(String name) {
    return '$name joined the trip';
  }

  @override
  String activityExpenseAdded(String name, String title) {
    return '$name added expense: $title';
  }

  @override
  String activityExpenseEdited(String name, String title) {
    return '$name edited expense: $title';
  }

  @override
  String activityExpenseDeleted(String name, String title) {
    return '$name deleted expense: $title';
  }

  @override
  String get devicePairingCodePromptTitle => 'Verify Your Device';

  @override
  String devicePairingCodePromptMessage(String name) {
    return 'To access this trip as $name, please enter a verification code.';
  }

  @override
  String get devicePairingCodePromptHowToGet =>
      'You can get a code from:\n• Any trip member with verified access\n• Yourself from another device where you\'re already verified';

  @override
  String get devicePairingCodeFieldLabel => '8-Digit Code';

  @override
  String get devicePairingCodeFieldHint => '1234-5678';

  @override
  String get devicePairingValidateButton => 'Verify';

  @override
  String get devicePairingAskForCodeButton => 'Ask for Verification Code';

  @override
  String devicePairingAskForCodeMessage(String name) {
    return 'Hi! I\'m trying to join the trip as $name and need a verification code. Could you:\n\n1. Open Trip Settings\n2. Find my name ($name) in the participant list\n3. Tap the QR code icon next to my name\n4. Share the generated code with me\n\nThe code expires in 15 minutes. Thanks!';
  }

  @override
  String get devicePairingAskForCodeCopied =>
      'Message copied! Send it to a trip member to request a code.';

  @override
  String get devicePairingGenerateButton => 'Generate Code';

  @override
  String get devicePairingCopyButton => 'Copy Code';

  @override
  String get devicePairingCodeCopied => 'Code copied to clipboard';

  @override
  String get devicePairingErrorInvalid => 'Invalid or expired code';

  @override
  String get devicePairingErrorExpired =>
      'Code has expired. Request a new one from a member.';

  @override
  String get devicePairingErrorUsed => 'Code already used';

  @override
  String get devicePairingErrorNameMismatch =>
      'Code doesn\'t match your member name';

  @override
  String get devicePairingErrorRateLimit =>
      'Too many attempts. Please wait 60 seconds.';

  @override
  String get devicePairingErrorNetwork =>
      'Cannot verify code offline. Check connection.';

  @override
  String get devicePairingSuccessMessage => 'Device verified!';

  @override
  String devicePairingExpiresIn(String minutes, String seconds) {
    return 'Expires in $minutes:$seconds';
  }

  @override
  String get devicePairingShareInstructions =>
      'Share this code with the person trying to join on another device. It expires in 15 minutes.';

  @override
  String get identitySelectionTitle => 'Join Trip';

  @override
  String get identitySelectionPrompt =>
      'This trip already has members. Please select who you are:';

  @override
  String get identitySelectionContinue => 'Continue & Verify';

  @override
  String get identitySelectionNoParticipant => 'Please select your identity';

  @override
  String identitySelectionTripName(String tripName) {
    return 'Trip: $tripName';
  }

  @override
  String get identitySelectionVerifying => 'Verifying your identity...';

  @override
  String identitySelectionSuccess(String tripName) {
    return 'Identity verified! Welcome to $tripName';
  }

  @override
  String get tripJoinLoadButton => 'Continue';

  @override
  String get tripJoinSelectIdentityTitle => 'Select Your Identity';

  @override
  String get tripJoinSelectIdentityPrompt => 'Who are you in this trip?';

  @override
  String get tripJoinVerifyButton => 'Verify Identity';

  @override
  String get tripJoinTripNotFound => 'Trip not found. Please check the code.';

  @override
  String get tripJoinUseRecoveryCode => 'Use Recovery Code';

  @override
  String get tripJoinRecoveryCodeLabel => 'Recovery Code';

  @override
  String get tripJoinRecoveryCodeHint => 'Enter 12-digit recovery code';

  @override
  String get tripJoinRecoveryCodeInvalid =>
      'Invalid recovery code. Please check and try again.';

  @override
  String get tripJoinInstructionStep1 =>
      'Enter the trip invite code shared by a trip member';

  @override
  String get tripJoinInstructionStep2 =>
      'Select your identity. Members will see expenses under this name.';

  @override
  String get tripJoinQrScanTitle => 'Have a QR code?';

  @override
  String get tripJoinQrScanMessage =>
      'Simply point your phone camera at the QR code to join instantly. Your camera app will automatically recognize it and open the invite link.';

  @override
  String get tripJoinInviteBannerTitle =>
      'You\'ve been invited to join a trip!';

  @override
  String get tripJoinInviteBannerMessage =>
      'The invite code has been pre-filled for you. Tap \'Continue\' to proceed.';

  @override
  String get tripJoinNoParticipants => 'This trip has no participants yet.';

  @override
  String get tripJoinTripLabel => 'Trip';

  @override
  String get tripJoinNoTripLoaded => 'No trip loaded';

  @override
  String get tripJoinRecoveryCodeSubtitle =>
      'Bypass verification with recovery code';

  @override
  String get tripJoinLoadError =>
      'Could not verify trip code. Please check your internet connection and try again.';

  @override
  String tripJoinStepIndicator(int current, int total) {
    return 'Step $current of $total';
  }

  @override
  String get tripJoinGenericError => 'An error occurred. Please try again.';

  @override
  String get tripJoinVerificationFailed =>
      'Verification failed. Please try again.';

  @override
  String get tripJoinHelpDeviceVerification =>
      'Device verification ensures only authorized members can access the trip.';

  @override
  String get tripJoinHelpRecoveryCode =>
      'Recovery code is a 12-digit code provided when the trip was created.';

  @override
  String get tripJoinHelpWhereToFindCode =>
      'Ask a trip member to generate a code for you via Trip Settings.';

  @override
  String get tripJoinRetryButton => 'Retry';

  @override
  String get tripJoinConfirmDialogTitle => 'Confirm Your Identity';

  @override
  String tripJoinConfirmDialogMessage(String tripName, String participantName) {
    return 'Join $tripName as $participantName?';
  }

  @override
  String get tripJoinConfirmButton => 'Confirm & Join';

  @override
  String get tripVerificationPromptTitle => 'Select Your Identity';

  @override
  String get tripVerificationPromptMessage =>
      'To view and participate in this trip, please select who you are from the participant list.';

  @override
  String get tripVerificationPromptButton => 'Select My Identity';

  @override
  String get tripVerificationPromptBackButton => 'Go Back';

  @override
  String get tripRecoverySectionTitle => 'Recovery Code';

  @override
  String get tripRecoveryGenerateButton => 'Generate Recovery Code';

  @override
  String get tripRecoveryViewButton => 'View Recovery Code';

  @override
  String get tripRecoveryGenerateDialogTitle => 'Generate Recovery Code';

  @override
  String get tripRecoveryGenerateDialogMessage =>
      'This will generate a 12-digit recovery code for emergency access to this trip. Keep this code safe - it allows anyone to join this trip as any member.';

  @override
  String get tripRecoveryViewDialogTitle => 'Recovery Code';

  @override
  String get tripRecoveryWarningMessage =>
      'Keep this code safe! Anyone with this code can join this trip as any member.';

  @override
  String get tripRecoveryCopyButton => 'Copy Code';

  @override
  String get tripRecoveryCopiedMessage => 'Recovery code copied to clipboard';

  @override
  String tripRecoveryUsedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'times',
      one: 'time',
    );
    return 'Used $count $_temp0';
  }

  @override
  String get tripRecoveryTripLabel => 'Trip';

  @override
  String get tripRecoveryTripIdLabel => 'Trip ID';

  @override
  String get tripRecoveryTripIdDescription =>
      'Share this ID with others to invite them to join this trip.';

  @override
  String get tripRecoveryTripIdSafeToShare => 'SAFE TO SHARE';

  @override
  String get tripRecoveryCodeLabel => 'Recovery Code';

  @override
  String get tripRecoveryCodeDescription =>
      'Emergency access code. Use this to regain access if all trip members lose their devices.';

  @override
  String get tripRecoveryCodePrivate => 'PRIVATE';

  @override
  String get tripRecoveryFirstTimeMessage =>
      'Save this information now! You can view it later in Trip Settings.';

  @override
  String get tripRecoveryCodeCopiedToClipboard =>
      'Recovery code copied to clipboard';

  @override
  String get tripRecoveryCopyCodeButton => 'Copy Code';

  @override
  String get tripRecoveryCopyAllButton => 'Copy All';

  @override
  String get tripRecoveryCopyAllSuccess => 'Trip info copied to clipboard';

  @override
  String get tripRecoveryTripIdCopied => 'Trip ID copied to clipboard';

  @override
  String get tripRecoveryPasswordManagerHint =>
      'Tip: Save this code in a password manager like 1Password or LastPass for secure storage.';

  @override
  String tripRecoveryCopyFailed(String error) {
    return 'Failed to copy: $error';
  }

  @override
  String get categoryBrowserTitle => 'Select Category';

  @override
  String get categoryBrowserSearchHint => 'Search or create category...';

  @override
  String get categoryBrowserNoResults => 'No categories found';

  @override
  String get categoryBrowserLoading => 'Loading categories...';

  @override
  String categoryBrowserCreateNew(String name) {
    return 'Create \"$name\"';
  }

  @override
  String get categoryBrowserOtherChip => 'Other';

  @override
  String get categoryCreationDialogTitle => 'Create Category';

  @override
  String get categoryCreationFieldName => 'Category Name';

  @override
  String get categoryCreationFieldNameHint => 'e.g., Groceries, Gas, Dining';

  @override
  String get categoryCreationFieldIcon => 'Icon';

  @override
  String get categoryCreationFieldColor => 'Color';

  @override
  String get categoryCreationButtonCreate => 'Create';

  @override
  String get categoryCreationButtonCreateNew => 'Create New Category';

  @override
  String get categoryCreationButtonCancel => 'Cancel';

  @override
  String get categoryCreationSuccess => 'Category created successfully';

  @override
  String categoryCreatedWithName(String name) {
    return 'Category \"$name\" created!';
  }

  @override
  String get categoryIconPreferenceRecorded => 'Icon preference recorded';

  @override
  String get categoryValidationEmpty => 'Category name cannot be empty';

  @override
  String get categoryValidationTooLong =>
      'Category name must be 50 characters or less';

  @override
  String get categoryValidationInvalidChars =>
      'Category names can only contain letters, numbers, spaces, and basic punctuation';

  @override
  String get categoryValidationDuplicate => 'This category already exists';

  @override
  String get categoryRateLimitError =>
      'Please wait a moment before creating more categories';

  @override
  String get categoryRateLimitDisabled =>
      'Please wait before creating more categories';

  @override
  String get categoryIconPickerTitle => 'Select Icon';

  @override
  String get categoryIconPickerSearchHint => 'Search icons...';

  @override
  String get categoryIconPickerNoResults => 'No icons found';

  @override
  String get categoryColorPickerTitle => 'Select Color';

  @override
  String get categoryDefaultIconLabel => 'label';

  @override
  String get categorySimilarWarningTitle => 'Similar category exists';

  @override
  String categorySimilarWarningMessage(
    String existingName,
    String icon,
    int usageCount,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      usageCount,
      locale: localeName,
      other: '$usageCount times',
      one: '1 time',
    );
    return '$existingName ($icon, used $_temp0)';
  }

  @override
  String get categorySimilarWarningUseExisting => 'Use Existing';

  @override
  String get categorySimilarWarningCreateAnyway => 'Create Anyway';

  @override
  String get categoryCustomizationTitle => 'Customize Categories';

  @override
  String get categoryCustomizationDescription =>
      'Customize category icons and colors for this trip only';

  @override
  String get categoryCustomizationBadgeCustomized => 'Customized';

  @override
  String get categoryCustomizationBadgeDefault => 'Using global default';

  @override
  String get categoryCustomizationResetIcon => 'Reset Icon';

  @override
  String get categoryCustomizationResetColor => 'Reset Color';

  @override
  String get categoryCustomizationResetBoth => 'Reset to Default';

  @override
  String get categoryCustomizationNoCategories =>
      'No categories used in this trip yet';

  @override
  String get categoryCustomizationResetSuccess =>
      'Reset to default successfully';

  @override
  String get categoryCustomizationSaveSuccess =>
      'Category customized successfully';
}
