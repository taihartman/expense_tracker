import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @commonDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// No description provided for @commonContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get commonContinue;

  /// No description provided for @commonBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get commonBack;

  /// No description provided for @commonRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get commonRetry;

  /// No description provided for @commonAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get commonAdd;

  /// No description provided for @commonEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get commonEdit;

  /// No description provided for @commonRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get commonRemove;

  /// No description provided for @commonUpdate.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get commonUpdate;

  /// No description provided for @commonGotIt.
  ///
  /// In en, this message translates to:
  /// **'Got It'**
  String get commonGotIt;

  /// No description provided for @commonRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get commonRequired;

  /// No description provided for @commonLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get commonLoading;

  /// No description provided for @commonError.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get commonError;

  /// No description provided for @validationRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get validationRequired;

  /// No description provided for @validationInvalidNumber.
  ///
  /// In en, this message translates to:
  /// **'Invalid number'**
  String get validationInvalidNumber;

  /// No description provided for @validationMustBeGreaterThanZero.
  ///
  /// In en, this message translates to:
  /// **'Must be > 0'**
  String get validationMustBeGreaterThanZero;

  /// No description provided for @validationPleaseEnterTripName.
  ///
  /// In en, this message translates to:
  /// **'Please enter a trip name'**
  String get validationPleaseEnterTripName;

  /// No description provided for @validationTripNameTooLong.
  ///
  /// In en, this message translates to:
  /// **'Trip name must be 100 characters or less'**
  String get validationTripNameTooLong;

  /// No description provided for @validationNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get validationNameRequired;

  /// No description provided for @validationNameTooLong.
  ///
  /// In en, this message translates to:
  /// **'Name must be 50 characters or less'**
  String get validationNameTooLong;

  /// No description provided for @validationPleaseSelectPayer.
  ///
  /// In en, this message translates to:
  /// **'Please select a payer'**
  String get validationPleaseSelectPayer;

  /// No description provided for @validationPleaseSelectParticipants.
  ///
  /// In en, this message translates to:
  /// **'Please select at least one participant'**
  String get validationPleaseSelectParticipants;

  /// No description provided for @validationPleaseFillAllFields.
  ///
  /// In en, this message translates to:
  /// **'Please fill in all fields'**
  String get validationPleaseFillAllFields;

  /// No description provided for @validationInvalidInput.
  ///
  /// In en, this message translates to:
  /// **'Invalid input: {error}'**
  String validationInvalidInput(String error);

  /// No description provided for @validationInvalidPrice.
  ///
  /// In en, this message translates to:
  /// **'Invalid price: {error}'**
  String validationInvalidPrice(String error);

  /// No description provided for @validationAtLeastOneItemRequired.
  ///
  /// In en, this message translates to:
  /// **'At least one item is required'**
  String get validationAtLeastOneItemRequired;

  /// No description provided for @validationItemsNotAssigned.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item not assigned to anyone} other{{count} items not assigned to anyone}}'**
  String validationItemsNotAssigned(int count);

  /// No description provided for @validationTaxTooHigh.
  ///
  /// In en, this message translates to:
  /// **'Tax percentage is unusually high ({value}%)'**
  String validationTaxTooHigh(String value);

  /// No description provided for @validationTipTooHigh.
  ///
  /// In en, this message translates to:
  /// **'Tip percentage is unusually high ({value}%)'**
  String validationTipTooHigh(String value);

  /// No description provided for @validationParticipantAlreadyExists.
  ///
  /// In en, this message translates to:
  /// **'A participant named {name} already exists'**
  String validationParticipantAlreadyExists(String name);

  /// No description provided for @tripCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Trip'**
  String get tripCreateTitle;

  /// No description provided for @tripEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Trip'**
  String get tripEditTitle;

  /// No description provided for @tripSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Trip Settings'**
  String get tripSettingsTitle;

  /// No description provided for @tripListTitle.
  ///
  /// In en, this message translates to:
  /// **'My Trips'**
  String get tripListTitle;

  /// No description provided for @tripSelectTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Trip'**
  String get tripSelectTitle;

  /// No description provided for @tripFieldNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Trip Name'**
  String get tripFieldNameLabel;

  /// No description provided for @tripFieldBaseCurrencyLabel.
  ///
  /// In en, this message translates to:
  /// **'Base Currency'**
  String get tripFieldBaseCurrencyLabel;

  /// No description provided for @tripFieldBaseCurrencyHelper.
  ///
  /// In en, this message translates to:
  /// **'All settlements will be calculated in this currency'**
  String get tripFieldBaseCurrencyHelper;

  /// No description provided for @tripFieldBaseCurrencyEditHelper.
  ///
  /// In en, this message translates to:
  /// **'Used for settlement displays. Expense amounts are not converted.'**
  String get tripFieldBaseCurrencyEditHelper;

  /// No description provided for @tripFieldCreatedLabel.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get tripFieldCreatedLabel;

  /// No description provided for @tripCreateButton.
  ///
  /// In en, this message translates to:
  /// **'Create Trip'**
  String get tripCreateButton;

  /// No description provided for @tripSaveChangesButton.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get tripSaveChangesButton;

  /// No description provided for @tripBackToExpenses.
  ///
  /// In en, this message translates to:
  /// **'Back to Expenses'**
  String get tripBackToExpenses;

  /// No description provided for @tripBackToSettings.
  ///
  /// In en, this message translates to:
  /// **'Back to Settings'**
  String get tripBackToSettings;

  /// No description provided for @tripCurrencyChangedInfo.
  ///
  /// In en, this message translates to:
  /// **'Changing base currency only affects how settlements are displayed. Individual expense amounts remain unchanged.'**
  String get tripCurrencyChangedInfo;

  /// No description provided for @tripEmptyStateTitle.
  ///
  /// In en, this message translates to:
  /// **'No trips yet'**
  String get tripEmptyStateTitle;

  /// No description provided for @tripLoadError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load trips: {error}'**
  String tripLoadError(String error);

  /// No description provided for @tripCreateError.
  ///
  /// In en, this message translates to:
  /// **'Failed to create trip: {error}'**
  String tripCreateError(String error);

  /// No description provided for @tripUpdateError.
  ///
  /// In en, this message translates to:
  /// **'Failed to update trip: {error}'**
  String tripUpdateError(String error);

  /// No description provided for @tripDeleteError.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete trip: {error}'**
  String tripDeleteError(String error);

  /// No description provided for @tripSettingsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load trip settings'**
  String get tripSettingsLoadError;

  /// No description provided for @tripBaseCurrencyPrefix.
  ///
  /// In en, this message translates to:
  /// **'Base: '**
  String get tripBaseCurrencyPrefix;

  /// No description provided for @participantSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Participants'**
  String get participantSectionTitle;

  /// No description provided for @participantAddButton.
  ///
  /// In en, this message translates to:
  /// **'Add Participant'**
  String get participantAddButton;

  /// No description provided for @participantAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Participant'**
  String get participantAddTitle;

  /// No description provided for @participantRemoveButton.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get participantRemoveButton;

  /// No description provided for @participantRemoveTooltip.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get participantRemoveTooltip;

  /// No description provided for @participantFieldNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name *'**
  String get participantFieldNameLabel;

  /// No description provided for @participantFieldNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter name (e.g., \"Sarah\")'**
  String get participantFieldNameHint;

  /// No description provided for @participantFieldIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Participant ID'**
  String get participantFieldIdLabel;

  /// No description provided for @participantFieldIdHint.
  ///
  /// In en, this message translates to:
  /// **'Auto-generated from name'**
  String get participantFieldIdHint;

  /// No description provided for @participantFieldIdHelper.
  ///
  /// In en, this message translates to:
  /// **'Auto-generated from name. Used internally for tracking.'**
  String get participantFieldIdHelper;

  /// No description provided for @participantEmptyStateTitle.
  ///
  /// In en, this message translates to:
  /// **'No participants added yet'**
  String get participantEmptyStateTitle;

  /// No description provided for @participantEmptyStateDescription.
  ///
  /// In en, this message translates to:
  /// **'Tap the + button below to add your first participant'**
  String get participantEmptyStateDescription;

  /// No description provided for @participantAddedSuccess.
  ///
  /// In en, this message translates to:
  /// **'{name} added successfully'**
  String participantAddedSuccess(String name);

  /// No description provided for @participantAddError.
  ///
  /// In en, this message translates to:
  /// **'Failed to add participant: {error}'**
  String participantAddError(String error);

  /// No description provided for @participantDeleteDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove Participant?'**
  String get participantDeleteDialogTitle;

  /// No description provided for @participantDeleteDialogMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove {name} from this trip?\n\nThis action cannot be undone.'**
  String participantDeleteDialogMessage(String name);

  /// No description provided for @participantDeleteDialogCannotRemoveTitle.
  ///
  /// In en, this message translates to:
  /// **'Cannot Remove Participant'**
  String get participantDeleteDialogCannotRemoveTitle;

  /// No description provided for @participantDeleteDialogCannotRemoveMessage.
  ///
  /// In en, this message translates to:
  /// **'{name} is used in {count, plural, =1{1 expense} other{{count} expenses}} and cannot be removed.'**
  String participantDeleteDialogCannotRemoveMessage(String name, int count);

  /// No description provided for @participantDeleteDialogInstructionsHeader.
  ///
  /// In en, this message translates to:
  /// **'To remove this participant:'**
  String get participantDeleteDialogInstructionsHeader;

  /// No description provided for @participantDeleteDialogInstructions.
  ///
  /// In en, this message translates to:
  /// **'1. Delete or reassign their expenses\n2. Try removing them again'**
  String get participantDeleteDialogInstructions;

  /// No description provided for @expenseListTitle.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get expenseListTitle;

  /// No description provided for @expenseAddButton.
  ///
  /// In en, this message translates to:
  /// **'Add Expense'**
  String get expenseAddButton;

  /// No description provided for @expenseAddTooltip.
  ///
  /// In en, this message translates to:
  /// **'Add Expense'**
  String get expenseAddTooltip;

  /// No description provided for @expenseAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Expense'**
  String get expenseAddTitle;

  /// No description provided for @expenseEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Expense'**
  String get expenseEditTitle;

  /// No description provided for @expenseSaveButton.
  ///
  /// In en, this message translates to:
  /// **'Add Expense'**
  String get expenseSaveButton;

  /// No description provided for @expenseSaveChangesButton.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get expenseSaveChangesButton;

  /// No description provided for @expenseUpdateButton.
  ///
  /// In en, this message translates to:
  /// **'Update Expense'**
  String get expenseUpdateButton;

  /// No description provided for @expenseDeleteButton.
  ///
  /// In en, this message translates to:
  /// **'Delete Expense'**
  String get expenseDeleteButton;

  /// No description provided for @expenseEmptyStateTitle.
  ///
  /// In en, this message translates to:
  /// **'No expenses yet'**
  String get expenseEmptyStateTitle;

  /// No description provided for @expenseEmptyStateDescription.
  ///
  /// In en, this message translates to:
  /// **'Tap + to add your first expense'**
  String get expenseEmptyStateDescription;

  /// No description provided for @expenseNoParticipantsTitle.
  ///
  /// In en, this message translates to:
  /// **'No participants configured'**
  String get expenseNoParticipantsTitle;

  /// No description provided for @expenseNoParticipantsDescription.
  ///
  /// In en, this message translates to:
  /// **'Please add participants to this trip first.'**
  String get expenseNoParticipantsDescription;

  /// No description provided for @expenseGoBackButton.
  ///
  /// In en, this message translates to:
  /// **'Go Back'**
  String get expenseGoBackButton;

  /// No description provided for @expenseSectionAmountCurrency.
  ///
  /// In en, this message translates to:
  /// **'AMOUNT & CURRENCY'**
  String get expenseSectionAmountCurrency;

  /// No description provided for @expenseSectionDescription.
  ///
  /// In en, this message translates to:
  /// **'WHAT WAS IT FOR?'**
  String get expenseSectionDescription;

  /// No description provided for @expenseSectionPayerDate.
  ///
  /// In en, this message translates to:
  /// **'WHO PAID & WHEN?'**
  String get expenseSectionPayerDate;

  /// No description provided for @expenseSectionSplit.
  ///
  /// In en, this message translates to:
  /// **'HOW TO SPLIT?'**
  String get expenseSectionSplit;

  /// No description provided for @expenseSectionCategory.
  ///
  /// In en, this message translates to:
  /// **'CATEGORY'**
  String get expenseSectionCategory;

  /// No description provided for @expenseSectionParticipants.
  ///
  /// In en, this message translates to:
  /// **'WHO\'S SPLITTING?'**
  String get expenseSectionParticipants;

  /// No description provided for @expenseSectionParticipantsRequired.
  ///
  /// In en, this message translates to:
  /// **'WHO\'S SPLITTING? *'**
  String get expenseSectionParticipantsRequired;

  /// No description provided for @expenseFieldAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get expenseFieldAmountLabel;

  /// No description provided for @expenseFieldDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get expenseFieldDescriptionLabel;

  /// No description provided for @expenseFieldPayerLabel.
  ///
  /// In en, this message translates to:
  /// **'Payer *'**
  String get expenseFieldPayerLabel;

  /// No description provided for @expenseFieldPayerRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get expenseFieldPayerRequired;

  /// No description provided for @expenseFieldDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get expenseFieldDateLabel;

  /// No description provided for @expenseFieldCurrencyLabel.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get expenseFieldCurrencyLabel;

  /// No description provided for @expenseSplitTypeEqual.
  ///
  /// In en, this message translates to:
  /// **'Equal'**
  String get expenseSplitTypeEqual;

  /// No description provided for @expenseSplitTypeWeighted.
  ///
  /// In en, this message translates to:
  /// **'Weighted'**
  String get expenseSplitTypeWeighted;

  /// No description provided for @expenseSplitTypeItemized.
  ///
  /// In en, this message translates to:
  /// **'Itemized (Add Line Items)'**
  String get expenseSplitTypeItemized;

  /// No description provided for @expenseParticipantSelectorRequired.
  ///
  /// In en, this message translates to:
  /// **'Required - select at least one participant'**
  String get expenseParticipantSelectorRequired;

  /// No description provided for @expenseParticipantWeightLabel.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get expenseParticipantWeightLabel;

  /// No description provided for @expenseParticipantWeightHint.
  ///
  /// In en, this message translates to:
  /// **'0'**
  String get expenseParticipantWeightHint;

  /// No description provided for @expensePaidBy.
  ///
  /// In en, this message translates to:
  /// **'Paid by {name}'**
  String expensePaidBy(String name);

  /// No description provided for @expenseParticipantCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 participant} other{{count} participants}}'**
  String expenseParticipantCount(int count);

  /// No description provided for @expenseShowDetails.
  ///
  /// In en, this message translates to:
  /// **'Show details'**
  String get expenseShowDetails;

  /// No description provided for @expenseShowLess.
  ///
  /// In en, this message translates to:
  /// **'Show less'**
  String get expenseShowLess;

  /// No description provided for @expenseDeleteDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Expense?'**
  String get expenseDeleteDialogTitle;

  /// No description provided for @expenseDeleteDialogMessage.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone.'**
  String get expenseDeleteDialogMessage;

  /// No description provided for @expenseLoadError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load expenses: {error}'**
  String expenseLoadError(String error);

  /// No description provided for @expenseCreateError.
  ///
  /// In en, this message translates to:
  /// **'Failed to create expense: {error}'**
  String expenseCreateError(String error);

  /// No description provided for @expenseUpdateError.
  ///
  /// In en, this message translates to:
  /// **'Failed to update expense: {error}'**
  String expenseUpdateError(String error);

  /// No description provided for @expenseDeleteError.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete expense: {error}'**
  String expenseDeleteError(String error);

  /// No description provided for @expenseItemizedOpenError.
  ///
  /// In en, this message translates to:
  /// **'Error opening itemized expense: {error}'**
  String expenseItemizedOpenError(String error);

  /// No description provided for @itemizedWizardTitleNew.
  ///
  /// In en, this message translates to:
  /// **'New Itemized Expense'**
  String get itemizedWizardTitleNew;

  /// No description provided for @itemizedWizardTitleEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit Itemized Expense'**
  String get itemizedWizardTitleEdit;

  /// No description provided for @itemizedWizardSavedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Expense saved successfully!'**
  String get itemizedWizardSavedSuccess;

  /// No description provided for @itemizedWizardUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Expense updated successfully!'**
  String get itemizedWizardUpdatedSuccess;

  /// No description provided for @itemizedWizardSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving expense...'**
  String get itemizedWizardSaving;

  /// No description provided for @itemizedWizardStepPeople.
  ///
  /// In en, this message translates to:
  /// **'People'**
  String get itemizedWizardStepPeople;

  /// No description provided for @itemizedWizardStepItems.
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get itemizedWizardStepItems;

  /// No description provided for @itemizedWizardStepExtras.
  ///
  /// In en, this message translates to:
  /// **'Extras'**
  String get itemizedWizardStepExtras;

  /// No description provided for @itemizedWizardStepReview.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get itemizedWizardStepReview;

  /// No description provided for @itemizedPeopleTitle.
  ///
  /// In en, this message translates to:
  /// **'Who paid for this expense? *'**
  String get itemizedPeopleTitle;

  /// No description provided for @itemizedPeopleDescription.
  ///
  /// In en, this message translates to:
  /// **'Select the person who paid'**
  String get itemizedPeopleDescription;

  /// No description provided for @itemizedPeopleDescriptionError.
  ///
  /// In en, this message translates to:
  /// **'Required - Select the person who paid'**
  String get itemizedPeopleDescriptionError;

  /// No description provided for @itemizedPeopleContinueButton.
  ///
  /// In en, this message translates to:
  /// **'Continue to Items'**
  String get itemizedPeopleContinueButton;

  /// No description provided for @itemizedItemsTitle.
  ///
  /// In en, this message translates to:
  /// **'Add items from receipt'**
  String get itemizedItemsTitle;

  /// No description provided for @itemizedItemsDescription.
  ///
  /// In en, this message translates to:
  /// **'Add each item and assign who ordered it'**
  String get itemizedItemsDescription;

  /// No description provided for @itemizedItemsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No items yet'**
  String get itemizedItemsEmptyTitle;

  /// No description provided for @itemizedItemsEmptyDescription.
  ///
  /// In en, this message translates to:
  /// **'Add items from the form below'**
  String get itemizedItemsEmptyDescription;

  /// No description provided for @itemizedItemsNotAssigned.
  ///
  /// In en, this message translates to:
  /// **'Not assigned'**
  String get itemizedItemsNotAssigned;

  /// No description provided for @itemizedItemsAssignTooltip.
  ///
  /// In en, this message translates to:
  /// **'Assign'**
  String get itemizedItemsAssignTooltip;

  /// No description provided for @itemizedItemsEditTooltip.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get itemizedItemsEditTooltip;

  /// No description provided for @itemizedItemsRemoveTooltip.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get itemizedItemsRemoveTooltip;

  /// No description provided for @itemizedItemsAddCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Add New Item'**
  String get itemizedItemsAddCardTitle;

  /// No description provided for @itemizedItemsEditCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Item'**
  String get itemizedItemsEditCardTitle;

  /// No description provided for @itemizedItemsFieldNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Item name'**
  String get itemizedItemsFieldNameLabel;

  /// No description provided for @itemizedItemsFieldNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Caesar Salad'**
  String get itemizedItemsFieldNameHint;

  /// No description provided for @itemizedItemsFieldQtyLabel.
  ///
  /// In en, this message translates to:
  /// **'Qty'**
  String get itemizedItemsFieldQtyLabel;

  /// No description provided for @itemizedItemsFieldPriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get itemizedItemsFieldPriceLabel;

  /// No description provided for @itemizedItemsFieldPriceHint.
  ///
  /// In en, this message translates to:
  /// **'0.00'**
  String get itemizedItemsFieldPriceHint;

  /// No description provided for @itemizedItemsAddButton.
  ///
  /// In en, this message translates to:
  /// **'Add Item'**
  String get itemizedItemsAddButton;

  /// No description provided for @itemizedItemsUpdateButton.
  ///
  /// In en, this message translates to:
  /// **'Update Item'**
  String get itemizedItemsUpdateButton;

  /// No description provided for @itemizedItemsContinueButton.
  ///
  /// In en, this message translates to:
  /// **'Continue to Extras'**
  String get itemizedItemsContinueButton;

  /// No description provided for @itemizedItemsAssignDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Assign: {itemName}'**
  String itemizedItemsAssignDialogTitle(String itemName);

  /// No description provided for @itemizedExtrasTitle.
  ///
  /// In en, this message translates to:
  /// **'Add tax & tip'**
  String get itemizedExtrasTitle;

  /// No description provided for @itemizedExtrasDescription.
  ///
  /// In en, this message translates to:
  /// **'Optional - leave blank if not applicable'**
  String get itemizedExtrasDescription;

  /// No description provided for @itemizedExtrasTaxCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Sales Tax'**
  String get itemizedExtrasTaxCardTitle;

  /// No description provided for @itemizedExtrasTaxRateLabel.
  ///
  /// In en, this message translates to:
  /// **'Tax Rate (%)'**
  String get itemizedExtrasTaxRateLabel;

  /// No description provided for @itemizedExtrasTaxRateHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., 8.875'**
  String get itemizedExtrasTaxRateHint;

  /// No description provided for @itemizedExtrasTaxRateHelper.
  ///
  /// In en, this message translates to:
  /// **'Applies to all taxable items'**
  String get itemizedExtrasTaxRateHelper;

  /// No description provided for @itemizedExtrasTipCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Tip / Gratuity'**
  String get itemizedExtrasTipCardTitle;

  /// No description provided for @itemizedExtrasTipRateLabel.
  ///
  /// In en, this message translates to:
  /// **'Tip Rate (%)'**
  String get itemizedExtrasTipRateLabel;

  /// No description provided for @itemizedExtrasTipRateHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., 18'**
  String get itemizedExtrasTipRateHint;

  /// No description provided for @itemizedExtrasTipRateHelper.
  ///
  /// In en, this message translates to:
  /// **'Calculated on pre-tax subtotal'**
  String get itemizedExtrasTipRateHelper;

  /// No description provided for @itemizedExtrasInfoMessage.
  ///
  /// In en, this message translates to:
  /// **'Tax and tip will be split proportionally based on each person\'s item subtotal'**
  String get itemizedExtrasInfoMessage;

  /// No description provided for @itemizedExtrasContinueButton.
  ///
  /// In en, this message translates to:
  /// **'Continue to Review'**
  String get itemizedExtrasContinueButton;

  /// No description provided for @itemizedReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Review & Save'**
  String get itemizedReviewTitle;

  /// No description provided for @itemizedReviewDescription.
  ///
  /// In en, this message translates to:
  /// **'Check the breakdown before saving'**
  String get itemizedReviewDescription;

  /// No description provided for @itemizedReviewCannotSaveTitle.
  ///
  /// In en, this message translates to:
  /// **'Cannot Save'**
  String get itemizedReviewCannotSaveTitle;

  /// No description provided for @itemizedReviewWarningTitle.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get itemizedReviewWarningTitle;

  /// No description provided for @itemizedReviewGrandTotal.
  ///
  /// In en, this message translates to:
  /// **'Grand Total'**
  String get itemizedReviewGrandTotal;

  /// No description provided for @itemizedReviewPeopleSplitting.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 person splitting} other{{count} people splitting}}'**
  String itemizedReviewPeopleSplitting(int count);

  /// No description provided for @itemizedReviewPerPersonBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Per Person Breakdown'**
  String get itemizedReviewPerPersonBreakdown;

  /// No description provided for @itemizedReviewPaidBadge.
  ///
  /// In en, this message translates to:
  /// **'PAID'**
  String get itemizedReviewPaidBadge;

  /// No description provided for @itemizedReviewItemsSubtotal.
  ///
  /// In en, this message translates to:
  /// **'Items Subtotal'**
  String get itemizedReviewItemsSubtotal;

  /// No description provided for @itemizedReviewRounding.
  ///
  /// In en, this message translates to:
  /// **'Rounding'**
  String get itemizedReviewRounding;

  /// No description provided for @itemizedReviewTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get itemizedReviewTotal;

  /// No description provided for @itemizedReviewItemDetails.
  ///
  /// In en, this message translates to:
  /// **'Item Details'**
  String get itemizedReviewItemDetails;

  /// No description provided for @itemizedReviewSaveButton.
  ///
  /// In en, this message translates to:
  /// **'Save Expense'**
  String get itemizedReviewSaveButton;

  /// No description provided for @itemizedReviewUpdateButton.
  ///
  /// In en, this message translates to:
  /// **'Update Expense'**
  String get itemizedReviewUpdateButton;

  /// No description provided for @itemizedExpenseCannotEditNotItemized.
  ///
  /// In en, this message translates to:
  /// **'Cannot edit: expense is not itemized'**
  String get itemizedExpenseCannotEditNotItemized;

  /// No description provided for @itemizedExpenseCannotEditNoItems.
  ///
  /// In en, this message translates to:
  /// **'Cannot edit: expense has no items'**
  String get itemizedExpenseCannotEditNoItems;

  /// No description provided for @itemizedExpenseCannotSaveNotReady.
  ///
  /// In en, this message translates to:
  /// **'Cannot save: expense not ready'**
  String get itemizedExpenseCannotSaveNotReady;

  /// No description provided for @itemizedExpenseCannotSaveValidationErrors.
  ///
  /// In en, this message translates to:
  /// **'Cannot save: validation errors exist'**
  String get itemizedExpenseCannotSaveValidationErrors;

  /// No description provided for @itemizedExpenseCannotSaveNoPayerSelected.
  ///
  /// In en, this message translates to:
  /// **'Cannot save: payer not selected'**
  String get itemizedExpenseCannotSaveNoPayerSelected;

  /// No description provided for @itemizedExpenseSaveError.
  ///
  /// In en, this message translates to:
  /// **'Failed to save expense: {error}'**
  String itemizedExpenseSaveError(String error);

  /// No description provided for @itemizedExpenseCalculationError.
  ///
  /// In en, this message translates to:
  /// **'Calculation error: {error}'**
  String itemizedExpenseCalculationError(String error);

  /// No description provided for @itemizedExpenseGeneratedDescriptionNoItems.
  ///
  /// In en, this message translates to:
  /// **'Itemized expense'**
  String get itemizedExpenseGeneratedDescriptionNoItems;

  /// No description provided for @itemizedExpenseGeneratedDescriptionMultiple.
  ///
  /// In en, this message translates to:
  /// **'{item1}, {item2}, and {count} more'**
  String itemizedExpenseGeneratedDescriptionMultiple(
    String item1,
    String item2,
    int count,
  );

  /// No description provided for @expenseCardNoItemizedDetails.
  ///
  /// In en, this message translates to:
  /// **'No itemized details available'**
  String get expenseCardNoItemizedDetails;

  /// No description provided for @expenseCardLineItemsTitle.
  ///
  /// In en, this message translates to:
  /// **'Line Items'**
  String get expenseCardLineItemsTitle;

  /// No description provided for @expenseCardExtrasTitle.
  ///
  /// In en, this message translates to:
  /// **'Extras'**
  String get expenseCardExtrasTitle;

  /// No description provided for @expenseCardExtrasTaxLabel.
  ///
  /// In en, this message translates to:
  /// **'Tax'**
  String get expenseCardExtrasTaxLabel;

  /// No description provided for @expenseCardExtrasTipLabel.
  ///
  /// In en, this message translates to:
  /// **'Tip'**
  String get expenseCardExtrasTipLabel;

  /// No description provided for @expenseCardPerPersonBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Per-Person Breakdown'**
  String get expenseCardPerPersonBreakdown;

  /// No description provided for @settlementTitle.
  ///
  /// In en, this message translates to:
  /// **'Settlement'**
  String get settlementTitle;

  /// No description provided for @settlementViewTooltip.
  ///
  /// In en, this message translates to:
  /// **'View Settlement'**
  String get settlementViewTooltip;

  /// No description provided for @settlementRecomputeTooltip.
  ///
  /// In en, this message translates to:
  /// **'Recompute Settlement'**
  String get settlementRecomputeTooltip;

  /// No description provided for @settlementComputing.
  ///
  /// In en, this message translates to:
  /// **'Computing settlement...'**
  String get settlementComputing;

  /// No description provided for @settlementLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading settlement...'**
  String get settlementLoading;

  /// No description provided for @settlementLoadingData.
  ///
  /// In en, this message translates to:
  /// **'Loading settlement data...'**
  String get settlementLoadingData;

  /// No description provided for @settlementLastUpdated.
  ///
  /// In en, this message translates to:
  /// **'Last updated: {timestamp}'**
  String settlementLastUpdated(String timestamp);

  /// No description provided for @settlementCalculateError.
  ///
  /// In en, this message translates to:
  /// **'Failed to calculate settlement: {error}'**
  String settlementCalculateError(String error);

  /// No description provided for @settlementLoadError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load settlement: {error}'**
  String settlementLoadError(String error);

  /// No description provided for @settlementMarkSettledError.
  ///
  /// In en, this message translates to:
  /// **'Failed to mark transfer as settled: {error}'**
  String settlementMarkSettledError(String error);

  /// No description provided for @settlementTripNotFoundError.
  ///
  /// In en, this message translates to:
  /// **'Trip not found: {tripId}'**
  String settlementTripNotFoundError(String tripId);

  /// No description provided for @transfersAllSettledTitle.
  ///
  /// In en, this message translates to:
  /// **'All Settled!'**
  String get transfersAllSettledTitle;

  /// No description provided for @transfersAllSettledDescription.
  ///
  /// In en, this message translates to:
  /// **'Everyone is even, no transfers needed.'**
  String get transfersAllSettledDescription;

  /// No description provided for @transfersCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Settlement Transfers'**
  String get transfersCardTitle;

  /// No description provided for @transfersCountTotal.
  ///
  /// In en, this message translates to:
  /// **'{count} total'**
  String transfersCountTotal(int count);

  /// No description provided for @transfersHintTapToSettle.
  ///
  /// In en, this message translates to:
  /// **'Tap a transfer to mark as settled'**
  String get transfersHintTapToSettle;

  /// No description provided for @transfersPendingTitle.
  ///
  /// In en, this message translates to:
  /// **'Pending Transfers'**
  String get transfersPendingTitle;

  /// No description provided for @transfersSettledTitle.
  ///
  /// In en, this message translates to:
  /// **'Settled Transfers'**
  String get transfersSettledTitle;

  /// No description provided for @transferCopiedFormat.
  ///
  /// In en, this message translates to:
  /// **'{fromName} pays {toName} {amount}'**
  String transferCopiedFormat(String fromName, String toName, String amount);

  /// No description provided for @transferCopiedMessage.
  ///
  /// In en, this message translates to:
  /// **'Copied: {text}'**
  String transferCopiedMessage(String text);

  /// No description provided for @transferMarkSettledDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Mark as Settled'**
  String get transferMarkSettledDialogTitle;

  /// No description provided for @transferMarkSettledDialogMessage.
  ///
  /// In en, this message translates to:
  /// **'Mark this transfer as settled?\n\n{fromName} → {toName}: {amount}'**
  String transferMarkSettledDialogMessage(
    String fromName,
    String toName,
    String amount,
  );

  /// No description provided for @transferBreakdownTitle.
  ///
  /// In en, this message translates to:
  /// **'Transfer Breakdown'**
  String get transferBreakdownTitle;

  /// No description provided for @transferBreakdownViewTooltip.
  ///
  /// In en, this message translates to:
  /// **'View Breakdown'**
  String get transferBreakdownViewTooltip;

  /// No description provided for @transferBreakdownNoData.
  ///
  /// In en, this message translates to:
  /// **'No data available'**
  String get transferBreakdownNoData;

  /// No description provided for @transferBreakdownLoadError.
  ///
  /// In en, this message translates to:
  /// **'Error loading breakdown: {error}'**
  String transferBreakdownLoadError(String error);

  /// No description provided for @transferBreakdownNoExpenses.
  ///
  /// In en, this message translates to:
  /// **'No expenses found that contribute to this transfer.'**
  String get transferBreakdownNoExpenses;

  /// No description provided for @transferBreakdownSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get transferBreakdownSummaryTitle;

  /// No description provided for @transferBreakdownSummaryDescription.
  ///
  /// In en, this message translates to:
  /// **'This shows all expenses that created debts between {fromName} and {toName}. The amounts shown are the exact debts from each expense, after pairwise netting.'**
  String transferBreakdownSummaryDescription(String fromName, String toName);

  /// No description provided for @transferBreakdownExpenseCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 expense between these two people} other{{count} expenses between these two people}}'**
  String transferBreakdownExpenseCount(int count);

  /// No description provided for @transferBreakdownContributingExpenses.
  ///
  /// In en, this message translates to:
  /// **'Contributing Expenses'**
  String get transferBreakdownContributingExpenses;

  /// No description provided for @transferBreakdownNoDescription.
  ///
  /// In en, this message translates to:
  /// **'No description'**
  String get transferBreakdownNoDescription;

  /// No description provided for @transferBreakdownExpenseMetadata.
  ///
  /// In en, this message translates to:
  /// **'Paid by {payerName} • {date}'**
  String transferBreakdownExpenseMetadata(String payerName, String date);

  /// No description provided for @transferBreakdownPaidLabel.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get transferBreakdownPaidLabel;

  /// No description provided for @transferBreakdownOwesLabel.
  ///
  /// In en, this message translates to:
  /// **'Owes'**
  String get transferBreakdownOwesLabel;

  /// No description provided for @transferBreakdownPaidPrefix.
  ///
  /// In en, this message translates to:
  /// **'Paid: '**
  String get transferBreakdownPaidPrefix;

  /// No description provided for @transferBreakdownOwesPrefix.
  ///
  /// In en, this message translates to:
  /// **'Owes: '**
  String get transferBreakdownOwesPrefix;

  /// No description provided for @summaryTableTitle.
  ///
  /// In en, this message translates to:
  /// **'Everyone\'s Summary'**
  String get summaryTableTitle;

  /// No description provided for @summaryTableColumnPerson.
  ///
  /// In en, this message translates to:
  /// **'Person'**
  String get summaryTableColumnPerson;

  /// No description provided for @summaryTableColumnToReceive.
  ///
  /// In en, this message translates to:
  /// **'To Receive'**
  String get summaryTableColumnToReceive;

  /// No description provided for @summaryTableColumnToPay.
  ///
  /// In en, this message translates to:
  /// **'To Pay'**
  String get summaryTableColumnToPay;

  /// No description provided for @summaryTableColumnNet.
  ///
  /// In en, this message translates to:
  /// **'Net'**
  String get summaryTableColumnNet;

  /// No description provided for @summaryTableLegendWillReceive.
  ///
  /// In en, this message translates to:
  /// **'Will receive money'**
  String get summaryTableLegendWillReceive;

  /// No description provided for @summaryTableLegendNeedsToPay.
  ///
  /// In en, this message translates to:
  /// **'Needs to pay'**
  String get summaryTableLegendNeedsToPay;

  /// No description provided for @summaryTableLegendEven.
  ///
  /// In en, this message translates to:
  /// **'Even'**
  String get summaryTableLegendEven;

  /// No description provided for @dateToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get dateToday;

  /// No description provided for @dateYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get dateYesterday;

  /// No description provided for @dateDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{days}d ago'**
  String dateDaysAgo(int days);

  /// No description provided for @currencyUSD.
  ///
  /// In en, this message translates to:
  /// **'US Dollar'**
  String get currencyUSD;

  /// No description provided for @currencyVND.
  ///
  /// In en, this message translates to:
  /// **'Vietnamese Dong'**
  String get currencyVND;

  /// No description provided for @categoryMeals.
  ///
  /// In en, this message translates to:
  /// **'Meals'**
  String get categoryMeals;

  /// No description provided for @categoryTransport.
  ///
  /// In en, this message translates to:
  /// **'Transport'**
  String get categoryTransport;

  /// No description provided for @categoryAccommodation.
  ///
  /// In en, this message translates to:
  /// **'Accommodation'**
  String get categoryAccommodation;

  /// No description provided for @categoryActivities.
  ///
  /// In en, this message translates to:
  /// **'Activities'**
  String get categoryActivities;

  /// No description provided for @categoryShopping.
  ///
  /// In en, this message translates to:
  /// **'Shopping'**
  String get categoryShopping;

  /// No description provided for @categoryOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get categoryOther;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
