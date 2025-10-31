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

  /// No description provided for @commonClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// No description provided for @splashAppName.
  ///
  /// In en, this message translates to:
  /// **'Expense Tracker'**
  String get splashAppName;

  /// No description provided for @splashLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get splashLoading;

  /// No description provided for @splashLoadingAccessibility.
  ///
  /// In en, this message translates to:
  /// **'Loading Expense Tracker'**
  String get splashLoadingAccessibility;

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
  /// **'My Trips'**
  String get tripSelectTitle;

  /// No description provided for @tripFieldNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Trip Name'**
  String get tripFieldNameLabel;

  /// No description provided for @tripFieldCreatorNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Your Name'**
  String get tripFieldCreatorNameLabel;

  /// No description provided for @tripFieldCreatorNameHelper.
  ///
  /// In en, this message translates to:
  /// **'Your name will be added as the first member of this trip'**
  String get tripFieldCreatorNameHelper;

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

  /// No description provided for @tripLeaveButton.
  ///
  /// In en, this message translates to:
  /// **'Leave Trip'**
  String get tripLeaveButton;

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

  /// No description provided for @tripEmptyStateDescription.
  ///
  /// In en, this message translates to:
  /// **'Create a new trip or join an existing one'**
  String get tripEmptyStateDescription;

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

  /// No description provided for @tripLeaveDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave Trip?'**
  String get tripLeaveDialogTitle;

  /// No description provided for @tripLeaveDialogMessage.
  ///
  /// In en, this message translates to:
  /// **'You will lose access to this trip and all its expenses. You\'ll need an invite link to rejoin.'**
  String get tripLeaveDialogMessage;

  /// No description provided for @tripLeaveDialogConfirm.
  ///
  /// In en, this message translates to:
  /// **'Leave Trip'**
  String get tripLeaveDialogConfirm;

  /// No description provided for @tripLeftSuccess.
  ///
  /// In en, this message translates to:
  /// **'Left {tripName} successfully'**
  String tripLeftSuccess(String tripName);

  /// No description provided for @tripArchiveButton.
  ///
  /// In en, this message translates to:
  /// **'Archive Trip'**
  String get tripArchiveButton;

  /// No description provided for @tripUnarchiveButton.
  ///
  /// In en, this message translates to:
  /// **'Unarchive Trip'**
  String get tripUnarchiveButton;

  /// No description provided for @tripArchiveDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Archive Trip?'**
  String get tripArchiveDialogTitle;

  /// No description provided for @tripArchiveDialogMessage.
  ///
  /// In en, this message translates to:
  /// **'This will hide the trip from your active trip list. You can restore it later from archived trips.'**
  String get tripArchiveDialogMessage;

  /// No description provided for @tripArchiveSuccess.
  ///
  /// In en, this message translates to:
  /// **'Trip archived'**
  String get tripArchiveSuccess;

  /// No description provided for @tripUnarchiveSuccess.
  ///
  /// In en, this message translates to:
  /// **'Trip unarchived'**
  String get tripUnarchiveSuccess;

  /// No description provided for @tripArchivedPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Archived Trips'**
  String get tripArchivedPageTitle;

  /// No description provided for @tripViewArchivedButton.
  ///
  /// In en, this message translates to:
  /// **'View Archived Trips'**
  String get tripViewArchivedButton;

  /// No description provided for @tripArchivedEmptyStateTitle.
  ///
  /// In en, this message translates to:
  /// **'No Archived Trips'**
  String get tripArchivedEmptyStateTitle;

  /// No description provided for @tripArchivedEmptyStateMessage.
  ///
  /// In en, this message translates to:
  /// **'Trips you archive will appear here'**
  String get tripArchivedEmptyStateMessage;

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

  /// No description provided for @expenseFabMainTooltip.
  ///
  /// In en, this message translates to:
  /// **'Add expense options'**
  String get expenseFabMainTooltip;

  /// No description provided for @expenseFabQuickExpenseTooltip.
  ///
  /// In en, this message translates to:
  /// **'Quick Expense'**
  String get expenseFabQuickExpenseTooltip;

  /// No description provided for @expenseFabReceiptSplitTooltip.
  ///
  /// In en, this message translates to:
  /// **'Receipt Split (Who Ordered What)'**
  String get expenseFabReceiptSplitTooltip;

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

  /// No description provided for @expenseSplitTypeReceiptSplit.
  ///
  /// In en, this message translates to:
  /// **'Receipt Split (Who Ordered What)'**
  String get expenseSplitTypeReceiptSplit;

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
  /// **'Error opening receipt split: {error}'**
  String expenseItemizedOpenError(String error);

  /// No description provided for @receiptSplitWizardTitleNew.
  ///
  /// In en, this message translates to:
  /// **'New Receipt Split'**
  String get receiptSplitWizardTitleNew;

  /// No description provided for @receiptSplitWizardTitleEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit Receipt Split'**
  String get receiptSplitWizardTitleEdit;

  /// No description provided for @receiptSplitWizardSavedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Expense saved successfully!'**
  String get receiptSplitWizardSavedSuccess;

  /// No description provided for @receiptSplitWizardUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Expense updated successfully!'**
  String get receiptSplitWizardUpdatedSuccess;

  /// No description provided for @receiptSplitWizardSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving expense...'**
  String get receiptSplitWizardSaving;

  /// No description provided for @receiptSplitWizardStepReceiptInfo.
  ///
  /// In en, this message translates to:
  /// **'Receipt'**
  String get receiptSplitWizardStepReceiptInfo;

  /// No description provided for @receiptSplitWizardStepPeople.
  ///
  /// In en, this message translates to:
  /// **'People'**
  String get receiptSplitWizardStepPeople;

  /// No description provided for @receiptSplitWizardStepItems.
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get receiptSplitWizardStepItems;

  /// No description provided for @receiptSplitWizardStepExtras.
  ///
  /// In en, this message translates to:
  /// **'Tip'**
  String get receiptSplitWizardStepExtras;

  /// No description provided for @receiptSplitWizardStepReview.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get receiptSplitWizardStepReview;

  /// No description provided for @receiptSplitReceiptInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Receipt Details'**
  String get receiptSplitReceiptInfoTitle;

  /// No description provided for @receiptSplitReceiptInfoDescription.
  ///
  /// In en, this message translates to:
  /// **'Enter the subtotal and tax from your receipt'**
  String get receiptSplitReceiptInfoDescription;

  /// No description provided for @receiptSplitReceiptInfoSubtotalLabel.
  ///
  /// In en, this message translates to:
  /// **'Subtotal (before tax & tip) *'**
  String get receiptSplitReceiptInfoSubtotalLabel;

  /// No description provided for @receiptSplitReceiptInfoSubtotalHint.
  ///
  /// In en, this message translates to:
  /// **'0.00'**
  String get receiptSplitReceiptInfoSubtotalHint;

  /// No description provided for @receiptSplitReceiptInfoSubtotalHelper.
  ///
  /// In en, this message translates to:
  /// **'Items you add should sum to this amount'**
  String get receiptSplitReceiptInfoSubtotalHelper;

  /// No description provided for @receiptSplitReceiptInfoTaxLabel.
  ///
  /// In en, this message translates to:
  /// **'Tax Amount'**
  String get receiptSplitReceiptInfoTaxLabel;

  /// No description provided for @receiptSplitReceiptInfoTaxHint.
  ///
  /// In en, this message translates to:
  /// **'0.00'**
  String get receiptSplitReceiptInfoTaxHint;

  /// No description provided for @receiptSplitReceiptInfoTaxHelper.
  ///
  /// In en, this message translates to:
  /// **'Leave blank if no tax'**
  String get receiptSplitReceiptInfoTaxHelper;

  /// No description provided for @receiptSplitReceiptInfoContinueButton.
  ///
  /// In en, this message translates to:
  /// **'Continue to Payer'**
  String get receiptSplitReceiptInfoContinueButton;

  /// No description provided for @receiptSplitPeopleTitle.
  ///
  /// In en, this message translates to:
  /// **'Who paid for this expense? *'**
  String get receiptSplitPeopleTitle;

  /// No description provided for @receiptSplitPeopleDescription.
  ///
  /// In en, this message translates to:
  /// **'Select the person who paid'**
  String get receiptSplitPeopleDescription;

  /// No description provided for @receiptSplitPeopleDescriptionError.
  ///
  /// In en, this message translates to:
  /// **'Required - Select the person who paid'**
  String get receiptSplitPeopleDescriptionError;

  /// No description provided for @receiptSplitPeopleContinueButton.
  ///
  /// In en, this message translates to:
  /// **'Continue to Items'**
  String get receiptSplitPeopleContinueButton;

  /// No description provided for @receiptSplitItemsTitle.
  ///
  /// In en, this message translates to:
  /// **'Add items from receipt'**
  String get receiptSplitItemsTitle;

  /// No description provided for @receiptSplitItemsDescription.
  ///
  /// In en, this message translates to:
  /// **'Add each item and assign who ordered it'**
  String get receiptSplitItemsDescription;

  /// No description provided for @receiptSplitItemsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No items yet'**
  String get receiptSplitItemsEmptyTitle;

  /// No description provided for @receiptSplitItemsEmptyDescription.
  ///
  /// In en, this message translates to:
  /// **'Add items from the form below'**
  String get receiptSplitItemsEmptyDescription;

  /// No description provided for @receiptSplitItemsNotAssigned.
  ///
  /// In en, this message translates to:
  /// **'Not assigned'**
  String get receiptSplitItemsNotAssigned;

  /// No description provided for @receiptSplitItemsAssignTooltip.
  ///
  /// In en, this message translates to:
  /// **'Assign'**
  String get receiptSplitItemsAssignTooltip;

  /// No description provided for @receiptSplitItemsEditTooltip.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get receiptSplitItemsEditTooltip;

  /// No description provided for @receiptSplitItemsRemoveTooltip.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get receiptSplitItemsRemoveTooltip;

  /// No description provided for @receiptSplitItemsAddCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Add New Item'**
  String get receiptSplitItemsAddCardTitle;

  /// No description provided for @receiptSplitItemsEditCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Item'**
  String get receiptSplitItemsEditCardTitle;

  /// No description provided for @receiptSplitItemsFieldNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Item name'**
  String get receiptSplitItemsFieldNameLabel;

  /// No description provided for @receiptSplitItemsFieldNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Caesar Salad'**
  String get receiptSplitItemsFieldNameHint;

  /// No description provided for @receiptSplitItemsFieldQtyLabel.
  ///
  /// In en, this message translates to:
  /// **'Qty'**
  String get receiptSplitItemsFieldQtyLabel;

  /// No description provided for @receiptSplitItemsFieldPriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get receiptSplitItemsFieldPriceLabel;

  /// No description provided for @receiptSplitItemsFieldPriceHint.
  ///
  /// In en, this message translates to:
  /// **'0.00'**
  String get receiptSplitItemsFieldPriceHint;

  /// No description provided for @receiptSplitItemsAddButton.
  ///
  /// In en, this message translates to:
  /// **'Add Item'**
  String get receiptSplitItemsAddButton;

  /// No description provided for @receiptSplitItemsUpdateButton.
  ///
  /// In en, this message translates to:
  /// **'Update Item'**
  String get receiptSplitItemsUpdateButton;

  /// No description provided for @receiptSplitItemsContinueButton.
  ///
  /// In en, this message translates to:
  /// **'Continue to Tip'**
  String get receiptSplitItemsContinueButton;

  /// No description provided for @receiptSplitItemsExpectedSubtotal.
  ///
  /// In en, this message translates to:
  /// **'Expected Subtotal'**
  String get receiptSplitItemsExpectedSubtotal;

  /// No description provided for @receiptSplitItemsCurrentTotal.
  ///
  /// In en, this message translates to:
  /// **'Current Items Total'**
  String get receiptSplitItemsCurrentTotal;

  /// No description provided for @receiptSplitItemsDifference.
  ///
  /// In en, this message translates to:
  /// **'Difference'**
  String get receiptSplitItemsDifference;

  /// No description provided for @receiptSplitItemsSubtotalMatch.
  ///
  /// In en, this message translates to:
  /// **'✓ Items match expected subtotal'**
  String get receiptSplitItemsSubtotalMatch;

  /// No description provided for @receiptSplitItemsSubtotalMismatch.
  ///
  /// In en, this message translates to:
  /// **'Items don\'t match expected subtotal'**
  String get receiptSplitItemsSubtotalMismatch;

  /// No description provided for @receiptSplitItemsValidationHelper.
  ///
  /// In en, this message translates to:
  /// **'Keep adding items until total matches subtotal'**
  String get receiptSplitItemsValidationHelper;

  /// No description provided for @receiptSplitItemsAssignDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Assign: {itemName}'**
  String receiptSplitItemsAssignDialogTitle(Object itemName);

  /// No description provided for @receiptSplitExtrasTitle.
  ///
  /// In en, this message translates to:
  /// **'Add tip'**
  String get receiptSplitExtrasTitle;

  /// No description provided for @receiptSplitExtrasDescription.
  ///
  /// In en, this message translates to:
  /// **'Optional - leave blank if not applicable'**
  String get receiptSplitExtrasDescription;

  /// No description provided for @receiptSplitExtrasTipCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Tip / Gratuity'**
  String get receiptSplitExtrasTipCardTitle;

  /// No description provided for @receiptSplitExtrasTipAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Tip Amount'**
  String get receiptSplitExtrasTipAmountLabel;

  /// No description provided for @receiptSplitExtrasTipAmountHint.
  ///
  /// In en, this message translates to:
  /// **'0.00'**
  String get receiptSplitExtrasTipAmountHint;

  /// No description provided for @receiptSplitExtrasTipRateLabel.
  ///
  /// In en, this message translates to:
  /// **'Or Tip Rate (%)'**
  String get receiptSplitExtrasTipRateLabel;

  /// No description provided for @receiptSplitExtrasTipRateHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., 18'**
  String get receiptSplitExtrasTipRateHint;

  /// No description provided for @receiptSplitExtrasTipRateHelper.
  ///
  /// In en, this message translates to:
  /// **'Calculated on items subtotal'**
  String get receiptSplitExtrasTipRateHelper;

  /// No description provided for @receiptSplitExtrasInfoMessage.
  ///
  /// In en, this message translates to:
  /// **'Tip will be split proportionally based on each person\'s item subtotal'**
  String get receiptSplitExtrasInfoMessage;

  /// No description provided for @receiptSplitExtrasContinueButton.
  ///
  /// In en, this message translates to:
  /// **'Continue to Review'**
  String get receiptSplitExtrasContinueButton;

  /// No description provided for @receiptSplitReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Review & Save'**
  String get receiptSplitReviewTitle;

  /// No description provided for @receiptSplitReviewDescription.
  ///
  /// In en, this message translates to:
  /// **'Check the breakdown before saving'**
  String get receiptSplitReviewDescription;

  /// No description provided for @receiptSplitReviewCannotSaveTitle.
  ///
  /// In en, this message translates to:
  /// **'Cannot Save'**
  String get receiptSplitReviewCannotSaveTitle;

  /// No description provided for @receiptSplitReviewWarningTitle.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get receiptSplitReviewWarningTitle;

  /// No description provided for @receiptSplitReviewSubtotalWarningTitle.
  ///
  /// In en, this message translates to:
  /// **'Subtotal Mismatch'**
  String get receiptSplitReviewSubtotalWarningTitle;

  /// No description provided for @receiptSplitReviewSubtotalWarningMessage.
  ///
  /// In en, this message translates to:
  /// **'Your items ({itemsTotal}) don\'t match the expected subtotal ({expectedSubtotal}). Difference: {difference}'**
  String receiptSplitReviewSubtotalWarningMessage(
    String itemsTotal,
    String expectedSubtotal,
    String difference,
  );

  /// No description provided for @receiptSplitReviewExpectedSubtotal.
  ///
  /// In en, this message translates to:
  /// **'Expected Subtotal'**
  String get receiptSplitReviewExpectedSubtotal;

  /// No description provided for @receiptSplitReviewItemsTotal.
  ///
  /// In en, this message translates to:
  /// **'Items Total'**
  String get receiptSplitReviewItemsTotal;

  /// No description provided for @receiptSplitReviewTaxFromReceipt.
  ///
  /// In en, this message translates to:
  /// **'Tax (from receipt)'**
  String get receiptSplitReviewTaxFromReceipt;

  /// No description provided for @receiptSplitReviewGrandTotal.
  ///
  /// In en, this message translates to:
  /// **'Grand Total'**
  String get receiptSplitReviewGrandTotal;

  /// No description provided for @receiptSplitReviewPeopleSplitting.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 person splitting} other{{count} people splitting}}'**
  String receiptSplitReviewPeopleSplitting(num count);

  /// No description provided for @receiptSplitReviewPerPersonBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Per Person Breakdown'**
  String get receiptSplitReviewPerPersonBreakdown;

  /// No description provided for @receiptSplitReviewPaidBadge.
  ///
  /// In en, this message translates to:
  /// **'PAID'**
  String get receiptSplitReviewPaidBadge;

  /// No description provided for @receiptSplitReviewItemsSubtotal.
  ///
  /// In en, this message translates to:
  /// **'Items Subtotal'**
  String get receiptSplitReviewItemsSubtotal;

  /// No description provided for @receiptSplitReviewRounding.
  ///
  /// In en, this message translates to:
  /// **'Rounding'**
  String get receiptSplitReviewRounding;

  /// No description provided for @receiptSplitReviewTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get receiptSplitReviewTotal;

  /// No description provided for @receiptSplitReviewItemDetails.
  ///
  /// In en, this message translates to:
  /// **'Item Details'**
  String get receiptSplitReviewItemDetails;

  /// No description provided for @receiptSplitReviewSaveButton.
  ///
  /// In en, this message translates to:
  /// **'Save Expense'**
  String get receiptSplitReviewSaveButton;

  /// No description provided for @receiptSplitReviewUpdateButton.
  ///
  /// In en, this message translates to:
  /// **'Update Expense'**
  String get receiptSplitReviewUpdateButton;

  /// No description provided for @receiptSplitExpenseCannotEditNotItemized.
  ///
  /// In en, this message translates to:
  /// **'Cannot edit: expense is not itemized'**
  String get receiptSplitExpenseCannotEditNotItemized;

  /// No description provided for @receiptSplitExpenseCannotEditNoItems.
  ///
  /// In en, this message translates to:
  /// **'Cannot edit: expense has no items'**
  String get receiptSplitExpenseCannotEditNoItems;

  /// No description provided for @receiptSplitExpenseCannotSaveNotReady.
  ///
  /// In en, this message translates to:
  /// **'Cannot save: expense not ready'**
  String get receiptSplitExpenseCannotSaveNotReady;

  /// No description provided for @receiptSplitExpenseCannotSaveValidationErrors.
  ///
  /// In en, this message translates to:
  /// **'Cannot save: validation errors exist'**
  String get receiptSplitExpenseCannotSaveValidationErrors;

  /// No description provided for @receiptSplitExpenseCannotSaveNoPayerSelected.
  ///
  /// In en, this message translates to:
  /// **'Cannot save: payer not selected'**
  String get receiptSplitExpenseCannotSaveNoPayerSelected;

  /// No description provided for @receiptSplitExpenseSaveError.
  ///
  /// In en, this message translates to:
  /// **'Failed to save expense: {error}'**
  String receiptSplitExpenseSaveError(Object error);

  /// No description provided for @receiptSplitExpenseCalculationError.
  ///
  /// In en, this message translates to:
  /// **'Calculation error: {error}'**
  String receiptSplitExpenseCalculationError(Object error);

  /// No description provided for @receiptSplitExpenseGeneratedDescriptionNoItems.
  ///
  /// In en, this message translates to:
  /// **'Itemized expense'**
  String get receiptSplitExpenseGeneratedDescriptionNoItems;

  /// No description provided for @receiptSplitExpenseGeneratedDescriptionMultiple.
  ///
  /// In en, this message translates to:
  /// **'{item1}, {item2}, and {count} more'**
  String receiptSplitExpenseGeneratedDescriptionMultiple(
    Object count,
    Object item1,
    Object item2,
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

  /// No description provided for @transferFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get transferFilterAll;

  /// No description provided for @transferFilterOwes.
  ///
  /// In en, this message translates to:
  /// **'Owes'**
  String get transferFilterOwes;

  /// No description provided for @transferFilterOwed.
  ///
  /// In en, this message translates to:
  /// **'Owed'**
  String get transferFilterOwed;

  /// No description provided for @transferFilterActive.
  ///
  /// In en, this message translates to:
  /// **'Filtering {name}\'s transfers'**
  String transferFilterActive(String name);

  /// No description provided for @transferFilterClear.
  ///
  /// In en, this message translates to:
  /// **'Clear filter'**
  String get transferFilterClear;

  /// No description provided for @transferFilterHint.
  ///
  /// In en, this message translates to:
  /// **'Tap any person above to filter transfers'**
  String get transferFilterHint;

  /// No description provided for @transferFilterNoResults.
  ///
  /// In en, this message translates to:
  /// **'No transfers for {name}'**
  String transferFilterNoResults(String name);

  /// No description provided for @transferNameChipHint.
  ///
  /// In en, this message translates to:
  /// **'Tip: Tap any name to filter transfers'**
  String get transferNameChipHint;

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

  /// No description provided for @tripJoinTitle.
  ///
  /// In en, this message translates to:
  /// **'Join Trip'**
  String get tripJoinTitle;

  /// No description provided for @tripJoinCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Invite Code'**
  String get tripJoinCodeLabel;

  /// No description provided for @tripJoinCodeHint.
  ///
  /// In en, this message translates to:
  /// **'Enter the trip invite code'**
  String get tripJoinCodeHint;

  /// No description provided for @tripJoinNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Your Name'**
  String get tripJoinNameLabel;

  /// No description provided for @tripJoinNameHint.
  ///
  /// In en, this message translates to:
  /// **'How should others see you?'**
  String get tripJoinNameHint;

  /// No description provided for @tripJoinButton.
  ///
  /// In en, this message translates to:
  /// **'Join Trip'**
  String get tripJoinButton;

  /// No description provided for @tripJoinInvalidCode.
  ///
  /// In en, this message translates to:
  /// **'Invalid or non-existent trip code'**
  String get tripJoinInvalidCode;

  /// No description provided for @tripJoinAlreadyMember.
  ///
  /// In en, this message translates to:
  /// **'You\'ve already joined this trip'**
  String get tripJoinAlreadyMember;

  /// No description provided for @tripJoinSuccess.
  ///
  /// In en, this message translates to:
  /// **'Successfully joined trip!'**
  String get tripJoinSuccess;

  /// No description provided for @tripJoinError.
  ///
  /// In en, this message translates to:
  /// **'Failed to join trip: {error}'**
  String tripJoinError(String error);

  /// No description provided for @tripInviteTitle.
  ///
  /// In en, this message translates to:
  /// **'Invite Friends'**
  String get tripInviteTitle;

  /// No description provided for @tripInviteCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Invite Code'**
  String get tripInviteCodeLabel;

  /// No description provided for @tripInviteCodeDescription.
  ///
  /// In en, this message translates to:
  /// **'Share this code with friends to invite them to the trip'**
  String get tripInviteCodeDescription;

  /// No description provided for @tripInviteCopyButton.
  ///
  /// In en, this message translates to:
  /// **'Copy Code'**
  String get tripInviteCopyButton;

  /// No description provided for @tripInviteShareButton.
  ///
  /// In en, this message translates to:
  /// **'Share Link'**
  String get tripInviteShareButton;

  /// No description provided for @tripInviteCodeCopied.
  ///
  /// In en, this message translates to:
  /// **'Invite code copied to clipboard'**
  String get tripInviteCodeCopied;

  /// No description provided for @tripInviteShareMessage.
  ///
  /// In en, this message translates to:
  /// **'Join my trip on Expense Tracker! Use code: {code} or click: {link}'**
  String tripInviteShareMessage(String code, String link);

  /// No description provided for @tripInviteShareMessageButton.
  ///
  /// In en, this message translates to:
  /// **'Share Message'**
  String get tripInviteShareMessageButton;

  /// No description provided for @tripInviteMessageCopied.
  ///
  /// In en, this message translates to:
  /// **'Message copied to clipboard'**
  String get tripInviteMessageCopied;

  /// No description provided for @tripInviteShareableLinkLabel.
  ///
  /// In en, this message translates to:
  /// **'Shareable Link'**
  String get tripInviteShareableLinkLabel;

  /// No description provided for @tripInviteCopyLinkButton.
  ///
  /// In en, this message translates to:
  /// **'Copy Link'**
  String get tripInviteCopyLinkButton;

  /// No description provided for @tripInviteLinkCopied.
  ///
  /// In en, this message translates to:
  /// **'Link copied to clipboard'**
  String get tripInviteLinkCopied;

  /// No description provided for @tripInviteShowQrButton.
  ///
  /// In en, this message translates to:
  /// **'Show QR Code'**
  String get tripInviteShowQrButton;

  /// No description provided for @tripInviteQrDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan to Join Trip'**
  String get tripInviteQrDialogTitle;

  /// No description provided for @tripInviteQrDialogDescription.
  ///
  /// In en, this message translates to:
  /// **'Scan this QR code with your phone camera or any QR scanner app to join the trip.'**
  String get tripInviteQrDialogDescription;

  /// No description provided for @tripInviteCopyFallbackTitle.
  ///
  /// In en, this message translates to:
  /// **'Copy Invite Message'**
  String get tripInviteCopyFallbackTitle;

  /// No description provided for @tripInviteCopyFallbackMessage.
  ///
  /// In en, this message translates to:
  /// **'Automatic copy failed. Please manually select and copy the text below:'**
  String get tripInviteCopyFallbackMessage;

  /// No description provided for @tripInviteCopyError.
  ///
  /// In en, this message translates to:
  /// **'Failed to copy message. Please try again.'**
  String get tripInviteCopyError;

  /// No description provided for @tripInviteInstructionsTitle.
  ///
  /// In en, this message translates to:
  /// **'How to invite friends'**
  String get tripInviteInstructionsTitle;

  /// No description provided for @tripInviteInstructionStep1.
  ///
  /// In en, this message translates to:
  /// **'Share the message, code, or link with your friends'**
  String get tripInviteInstructionStep1;

  /// No description provided for @tripInviteInstructionStep2.
  ///
  /// In en, this message translates to:
  /// **'They click the link or enter the code on the Join Trip page'**
  String get tripInviteInstructionStep2;

  /// No description provided for @tripInviteInstructionStep3.
  ///
  /// In en, this message translates to:
  /// **'They select their identity and verify via device pairing or recovery code'**
  String get tripInviteInstructionStep3;

  /// No description provided for @activityLogTitle.
  ///
  /// In en, this message translates to:
  /// **'Activity Log'**
  String get activityLogTitle;

  /// No description provided for @activityLogEmpty.
  ///
  /// In en, this message translates to:
  /// **'No activities yet. Start by adding expenses or inviting friends!'**
  String get activityLogEmpty;

  /// No description provided for @activityLogLoadMore.
  ///
  /// In en, this message translates to:
  /// **'Load More'**
  String get activityLogLoadMore;

  /// No description provided for @activityLogLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading activities...'**
  String get activityLogLoading;

  /// No description provided for @activityJoinViaLink.
  ///
  /// In en, this message translates to:
  /// **'via invite link'**
  String get activityJoinViaLink;

  /// No description provided for @activityJoinViaQr.
  ///
  /// In en, this message translates to:
  /// **'via QR code'**
  String get activityJoinViaQr;

  /// No description provided for @activityJoinManual.
  ///
  /// In en, this message translates to:
  /// **'by entering code'**
  String get activityJoinManual;

  /// No description provided for @activityJoinRecovery.
  ///
  /// In en, this message translates to:
  /// **'using recovery code'**
  String get activityJoinRecovery;

  /// No description provided for @activityInvitedBy.
  ///
  /// In en, this message translates to:
  /// **'invited by {name}'**
  String activityInvitedBy(String name);

  /// No description provided for @activityTripCreated.
  ///
  /// In en, this message translates to:
  /// **'{name} created the trip'**
  String activityTripCreated(String name);

  /// No description provided for @activityMemberJoined.
  ///
  /// In en, this message translates to:
  /// **'{name} joined the trip'**
  String activityMemberJoined(String name);

  /// No description provided for @activityExpenseAdded.
  ///
  /// In en, this message translates to:
  /// **'{name} added expense: {title}'**
  String activityExpenseAdded(String name, String title);

  /// No description provided for @activityExpenseEdited.
  ///
  /// In en, this message translates to:
  /// **'{name} edited expense: {title}'**
  String activityExpenseEdited(String name, String title);

  /// No description provided for @activityExpenseDeleted.
  ///
  /// In en, this message translates to:
  /// **'{name} deleted expense: {title}'**
  String activityExpenseDeleted(String name, String title);

  /// No description provided for @devicePairingCodePromptTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify Your Device'**
  String get devicePairingCodePromptTitle;

  /// No description provided for @devicePairingCodePromptMessage.
  ///
  /// In en, this message translates to:
  /// **'To access this trip as {name}, please enter a verification code.'**
  String devicePairingCodePromptMessage(String name);

  /// No description provided for @devicePairingCodePromptHowToGet.
  ///
  /// In en, this message translates to:
  /// **'You can get a code from:\n• Any trip member with verified access\n• Yourself from another device where you\'re already verified'**
  String get devicePairingCodePromptHowToGet;

  /// No description provided for @devicePairingCodeFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'8-Digit Code'**
  String get devicePairingCodeFieldLabel;

  /// No description provided for @devicePairingCodeFieldHint.
  ///
  /// In en, this message translates to:
  /// **'1234-5678'**
  String get devicePairingCodeFieldHint;

  /// No description provided for @devicePairingValidateButton.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get devicePairingValidateButton;

  /// No description provided for @devicePairingAskForCodeButton.
  ///
  /// In en, this message translates to:
  /// **'Ask for Verification Code'**
  String get devicePairingAskForCodeButton;

  /// No description provided for @devicePairingAskForCodeMessage.
  ///
  /// In en, this message translates to:
  /// **'Hi! I\'m trying to join the trip as {name} and need a verification code. Could you:\n\n1. Open Trip Settings\n2. Find my name ({name}) in the participant list\n3. Tap the QR code icon next to my name\n4. Share the generated code with me\n\nThe code expires in 15 minutes. Thanks!'**
  String devicePairingAskForCodeMessage(String name);

  /// No description provided for @devicePairingAskForCodeCopied.
  ///
  /// In en, this message translates to:
  /// **'Message copied! Send it to a trip member to request a code.'**
  String get devicePairingAskForCodeCopied;

  /// No description provided for @devicePairingGenerateButton.
  ///
  /// In en, this message translates to:
  /// **'Generate Code'**
  String get devicePairingGenerateButton;

  /// No description provided for @devicePairingCopyButton.
  ///
  /// In en, this message translates to:
  /// **'Copy Code'**
  String get devicePairingCopyButton;

  /// No description provided for @devicePairingCodeCopied.
  ///
  /// In en, this message translates to:
  /// **'Code copied to clipboard'**
  String get devicePairingCodeCopied;

  /// No description provided for @devicePairingErrorInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid or expired code'**
  String get devicePairingErrorInvalid;

  /// No description provided for @devicePairingErrorExpired.
  ///
  /// In en, this message translates to:
  /// **'Code has expired. Request a new one from a member.'**
  String get devicePairingErrorExpired;

  /// No description provided for @devicePairingErrorUsed.
  ///
  /// In en, this message translates to:
  /// **'Code already used'**
  String get devicePairingErrorUsed;

  /// No description provided for @devicePairingErrorNameMismatch.
  ///
  /// In en, this message translates to:
  /// **'Code doesn\'t match your member name'**
  String get devicePairingErrorNameMismatch;

  /// No description provided for @devicePairingErrorRateLimit.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please wait 60 seconds.'**
  String get devicePairingErrorRateLimit;

  /// No description provided for @devicePairingErrorNetwork.
  ///
  /// In en, this message translates to:
  /// **'Cannot verify code offline. Check connection.'**
  String get devicePairingErrorNetwork;

  /// No description provided for @devicePairingSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'Device verified!'**
  String get devicePairingSuccessMessage;

  /// No description provided for @devicePairingExpiresIn.
  ///
  /// In en, this message translates to:
  /// **'Expires in {minutes}:{seconds}'**
  String devicePairingExpiresIn(String minutes, String seconds);

  /// No description provided for @devicePairingShareInstructions.
  ///
  /// In en, this message translates to:
  /// **'Share this code with the person trying to join on another device. It expires in 15 minutes.'**
  String get devicePairingShareInstructions;

  /// No description provided for @identitySelectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Join Trip'**
  String get identitySelectionTitle;

  /// No description provided for @identitySelectionPrompt.
  ///
  /// In en, this message translates to:
  /// **'This trip already has members. Please select who you are:'**
  String get identitySelectionPrompt;

  /// No description provided for @identitySelectionContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue & Verify'**
  String get identitySelectionContinue;

  /// No description provided for @identitySelectionNoParticipant.
  ///
  /// In en, this message translates to:
  /// **'Please select your identity'**
  String get identitySelectionNoParticipant;

  /// No description provided for @identitySelectionTripName.
  ///
  /// In en, this message translates to:
  /// **'Trip: {tripName}'**
  String identitySelectionTripName(String tripName);

  /// No description provided for @identitySelectionVerifying.
  ///
  /// In en, this message translates to:
  /// **'Verifying your identity...'**
  String get identitySelectionVerifying;

  /// No description provided for @identitySelectionSuccess.
  ///
  /// In en, this message translates to:
  /// **'Identity verified! Welcome to {tripName}'**
  String identitySelectionSuccess(String tripName);

  /// No description provided for @tripJoinLoadButton.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get tripJoinLoadButton;

  /// No description provided for @tripJoinSelectIdentityTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Your Identity'**
  String get tripJoinSelectIdentityTitle;

  /// No description provided for @tripJoinSelectIdentityPrompt.
  ///
  /// In en, this message translates to:
  /// **'Who are you in this trip?'**
  String get tripJoinSelectIdentityPrompt;

  /// No description provided for @tripJoinVerifyButton.
  ///
  /// In en, this message translates to:
  /// **'Verify Identity'**
  String get tripJoinVerifyButton;

  /// No description provided for @tripJoinTripNotFound.
  ///
  /// In en, this message translates to:
  /// **'Trip not found. Please check the code.'**
  String get tripJoinTripNotFound;

  /// No description provided for @tripJoinUseRecoveryCode.
  ///
  /// In en, this message translates to:
  /// **'Use Recovery Code'**
  String get tripJoinUseRecoveryCode;

  /// No description provided for @tripJoinRecoveryCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Recovery Code'**
  String get tripJoinRecoveryCodeLabel;

  /// No description provided for @tripJoinRecoveryCodeHint.
  ///
  /// In en, this message translates to:
  /// **'Enter 12-digit recovery code'**
  String get tripJoinRecoveryCodeHint;

  /// No description provided for @tripJoinRecoveryCodeInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid recovery code. Please check and try again.'**
  String get tripJoinRecoveryCodeInvalid;

  /// No description provided for @tripJoinInstructionStep1.
  ///
  /// In en, this message translates to:
  /// **'Enter the trip invite code shared by a trip member'**
  String get tripJoinInstructionStep1;

  /// No description provided for @tripJoinInstructionStep2.
  ///
  /// In en, this message translates to:
  /// **'Select your identity. Members will see expenses under this name.'**
  String get tripJoinInstructionStep2;

  /// No description provided for @tripJoinQrScanTitle.
  ///
  /// In en, this message translates to:
  /// **'Have a QR code?'**
  String get tripJoinQrScanTitle;

  /// No description provided for @tripJoinQrScanMessage.
  ///
  /// In en, this message translates to:
  /// **'Simply point your phone camera at the QR code to join instantly. Your camera app will automatically recognize it and open the invite link.'**
  String get tripJoinQrScanMessage;

  /// No description provided for @tripJoinInviteBannerTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'ve been invited to join a trip!'**
  String get tripJoinInviteBannerTitle;

  /// No description provided for @tripJoinInviteBannerMessage.
  ///
  /// In en, this message translates to:
  /// **'The invite code has been pre-filled for you. Tap \'Continue\' to proceed.'**
  String get tripJoinInviteBannerMessage;

  /// No description provided for @tripJoinNoParticipants.
  ///
  /// In en, this message translates to:
  /// **'This trip has no participants yet.'**
  String get tripJoinNoParticipants;

  /// No description provided for @tripJoinTripLabel.
  ///
  /// In en, this message translates to:
  /// **'Trip'**
  String get tripJoinTripLabel;

  /// No description provided for @tripJoinNoTripLoaded.
  ///
  /// In en, this message translates to:
  /// **'No trip loaded'**
  String get tripJoinNoTripLoaded;

  /// No description provided for @tripJoinRecoveryCodeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Bypass verification with recovery code'**
  String get tripJoinRecoveryCodeSubtitle;

  /// No description provided for @tripJoinLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not verify trip code. Please check your internet connection and try again.'**
  String get tripJoinLoadError;

  /// No description provided for @tripJoinStepIndicator.
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}'**
  String tripJoinStepIndicator(int current, int total);

  /// No description provided for @tripJoinGenericError.
  ///
  /// In en, this message translates to:
  /// **'An error occurred. Please try again.'**
  String get tripJoinGenericError;

  /// No description provided for @tripJoinVerificationFailed.
  ///
  /// In en, this message translates to:
  /// **'Verification failed. Please try again.'**
  String get tripJoinVerificationFailed;

  /// No description provided for @tripJoinHelpDeviceVerification.
  ///
  /// In en, this message translates to:
  /// **'Device verification ensures only authorized members can access the trip.'**
  String get tripJoinHelpDeviceVerification;

  /// No description provided for @tripJoinHelpRecoveryCode.
  ///
  /// In en, this message translates to:
  /// **'Recovery code is a 12-digit code provided when the trip was created.'**
  String get tripJoinHelpRecoveryCode;

  /// No description provided for @tripJoinHelpWhereToFindCode.
  ///
  /// In en, this message translates to:
  /// **'Ask a trip member to generate a code for you via Trip Settings.'**
  String get tripJoinHelpWhereToFindCode;

  /// No description provided for @tripJoinRetryButton.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get tripJoinRetryButton;

  /// No description provided for @tripJoinConfirmDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm Your Identity'**
  String get tripJoinConfirmDialogTitle;

  /// No description provided for @tripJoinConfirmDialogMessage.
  ///
  /// In en, this message translates to:
  /// **'Join {tripName} as {participantName}?'**
  String tripJoinConfirmDialogMessage(String tripName, String participantName);

  /// No description provided for @tripJoinConfirmButton.
  ///
  /// In en, this message translates to:
  /// **'Confirm & Join'**
  String get tripJoinConfirmButton;

  /// No description provided for @tripVerificationPromptTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Your Identity'**
  String get tripVerificationPromptTitle;

  /// No description provided for @tripVerificationPromptMessage.
  ///
  /// In en, this message translates to:
  /// **'To view and participate in this trip, please select who you are from the participant list.'**
  String get tripVerificationPromptMessage;

  /// No description provided for @tripVerificationPromptButton.
  ///
  /// In en, this message translates to:
  /// **'Select My Identity'**
  String get tripVerificationPromptButton;

  /// No description provided for @tripVerificationPromptBackButton.
  ///
  /// In en, this message translates to:
  /// **'Go Back'**
  String get tripVerificationPromptBackButton;

  /// No description provided for @tripRecoverySectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Recovery Code'**
  String get tripRecoverySectionTitle;

  /// No description provided for @tripRecoveryGenerateButton.
  ///
  /// In en, this message translates to:
  /// **'Generate Recovery Code'**
  String get tripRecoveryGenerateButton;

  /// No description provided for @tripRecoveryViewButton.
  ///
  /// In en, this message translates to:
  /// **'View Recovery Code'**
  String get tripRecoveryViewButton;

  /// No description provided for @tripRecoveryGenerateDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Generate Recovery Code'**
  String get tripRecoveryGenerateDialogTitle;

  /// No description provided for @tripRecoveryGenerateDialogMessage.
  ///
  /// In en, this message translates to:
  /// **'This will generate a 12-digit recovery code for emergency access to this trip. Keep this code safe - it allows anyone to join this trip as any member.'**
  String get tripRecoveryGenerateDialogMessage;

  /// No description provided for @tripRecoveryViewDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Recovery Code'**
  String get tripRecoveryViewDialogTitle;

  /// No description provided for @tripRecoveryWarningMessage.
  ///
  /// In en, this message translates to:
  /// **'Keep this code safe! Anyone with this code can join this trip as any member.'**
  String get tripRecoveryWarningMessage;

  /// No description provided for @tripRecoveryCopyButton.
  ///
  /// In en, this message translates to:
  /// **'Copy Code'**
  String get tripRecoveryCopyButton;

  /// No description provided for @tripRecoveryCopiedMessage.
  ///
  /// In en, this message translates to:
  /// **'Recovery code copied to clipboard'**
  String get tripRecoveryCopiedMessage;

  /// No description provided for @tripRecoveryUsedCount.
  ///
  /// In en, this message translates to:
  /// **'Used {count} {count, plural, =1{time} other{times}}'**
  String tripRecoveryUsedCount(int count);

  /// No description provided for @tripRecoveryTripLabel.
  ///
  /// In en, this message translates to:
  /// **'Trip'**
  String get tripRecoveryTripLabel;

  /// No description provided for @tripRecoveryTripIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Trip ID'**
  String get tripRecoveryTripIdLabel;

  /// No description provided for @tripRecoveryTripIdDescription.
  ///
  /// In en, this message translates to:
  /// **'Share this ID with others to invite them to join this trip.'**
  String get tripRecoveryTripIdDescription;

  /// No description provided for @tripRecoveryTripIdSafeToShare.
  ///
  /// In en, this message translates to:
  /// **'SAFE TO SHARE'**
  String get tripRecoveryTripIdSafeToShare;

  /// No description provided for @tripRecoveryCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Recovery Code'**
  String get tripRecoveryCodeLabel;

  /// No description provided for @tripRecoveryCodeDescription.
  ///
  /// In en, this message translates to:
  /// **'Emergency access code. Use this to regain access if all trip members lose their devices.'**
  String get tripRecoveryCodeDescription;

  /// No description provided for @tripRecoveryCodePrivate.
  ///
  /// In en, this message translates to:
  /// **'PRIVATE'**
  String get tripRecoveryCodePrivate;

  /// No description provided for @tripRecoveryFirstTimeMessage.
  ///
  /// In en, this message translates to:
  /// **'Save this information now! You can view it later in Trip Settings.'**
  String get tripRecoveryFirstTimeMessage;

  /// No description provided for @tripRecoveryCodeCopiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Recovery code copied to clipboard'**
  String get tripRecoveryCodeCopiedToClipboard;

  /// No description provided for @tripRecoveryCopyCodeButton.
  ///
  /// In en, this message translates to:
  /// **'Copy Code'**
  String get tripRecoveryCopyCodeButton;

  /// No description provided for @tripRecoveryCopyAllButton.
  ///
  /// In en, this message translates to:
  /// **'Copy All'**
  String get tripRecoveryCopyAllButton;

  /// No description provided for @tripRecoveryCopyAllSuccess.
  ///
  /// In en, this message translates to:
  /// **'Trip info copied to clipboard'**
  String get tripRecoveryCopyAllSuccess;

  /// No description provided for @tripRecoveryTripIdCopied.
  ///
  /// In en, this message translates to:
  /// **'Trip ID copied to clipboard'**
  String get tripRecoveryTripIdCopied;

  /// No description provided for @tripRecoveryPasswordManagerHint.
  ///
  /// In en, this message translates to:
  /// **'Tip: Save this code in a password manager like 1Password or LastPass for secure storage.'**
  String get tripRecoveryPasswordManagerHint;

  /// No description provided for @tripRecoveryCopyFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to copy: {error}'**
  String tripRecoveryCopyFailed(String error);

  /// No description provided for @categoryBrowserTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Category'**
  String get categoryBrowserTitle;

  /// No description provided for @categoryBrowserSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search categories...'**
  String get categoryBrowserSearchHint;

  /// No description provided for @categoryBrowserNoResults.
  ///
  /// In en, this message translates to:
  /// **'No categories found'**
  String get categoryBrowserNoResults;

  /// No description provided for @categoryBrowserLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading categories...'**
  String get categoryBrowserLoading;

  /// No description provided for @categoryBrowserCreateNew.
  ///
  /// In en, this message translates to:
  /// **'Create \"{name}\"'**
  String categoryBrowserCreateNew(String name);

  /// No description provided for @categoryBrowserOtherChip.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get categoryBrowserOtherChip;

  /// No description provided for @categoryCreationDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Category'**
  String get categoryCreationDialogTitle;

  /// No description provided for @categoryCreationFieldName.
  ///
  /// In en, this message translates to:
  /// **'Category Name'**
  String get categoryCreationFieldName;

  /// No description provided for @categoryCreationFieldNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Groceries, Gas, Dining'**
  String get categoryCreationFieldNameHint;

  /// No description provided for @categoryCreationFieldIcon.
  ///
  /// In en, this message translates to:
  /// **'Icon'**
  String get categoryCreationFieldIcon;

  /// No description provided for @categoryCreationFieldColor.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get categoryCreationFieldColor;

  /// No description provided for @categoryCreationButtonCreate.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get categoryCreationButtonCreate;

  /// No description provided for @categoryCreationButtonCreateNew.
  ///
  /// In en, this message translates to:
  /// **'Create New Category'**
  String get categoryCreationButtonCreateNew;

  /// No description provided for @categoryCreationButtonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get categoryCreationButtonCancel;

  /// No description provided for @categoryCreationSuccess.
  ///
  /// In en, this message translates to:
  /// **'Category created successfully'**
  String get categoryCreationSuccess;

  /// No description provided for @categoryValidationEmpty.
  ///
  /// In en, this message translates to:
  /// **'Category name cannot be empty'**
  String get categoryValidationEmpty;

  /// No description provided for @categoryValidationTooLong.
  ///
  /// In en, this message translates to:
  /// **'Category name must be 50 characters or less'**
  String get categoryValidationTooLong;

  /// No description provided for @categoryValidationInvalidChars.
  ///
  /// In en, this message translates to:
  /// **'Category names can only contain letters, numbers, spaces, and basic punctuation'**
  String get categoryValidationInvalidChars;

  /// No description provided for @categoryValidationDuplicate.
  ///
  /// In en, this message translates to:
  /// **'This category already exists'**
  String get categoryValidationDuplicate;

  /// No description provided for @categoryRateLimitError.
  ///
  /// In en, this message translates to:
  /// **'Please wait a moment before creating more categories'**
  String get categoryRateLimitError;

  /// No description provided for @categoryRateLimitDisabled.
  ///
  /// In en, this message translates to:
  /// **'Please wait before creating more categories'**
  String get categoryRateLimitDisabled;

  /// No description provided for @categoryIconPickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Icon'**
  String get categoryIconPickerTitle;

  /// No description provided for @categoryIconPickerSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search icons...'**
  String get categoryIconPickerSearchHint;

  /// No description provided for @categoryIconPickerNoResults.
  ///
  /// In en, this message translates to:
  /// **'No icons found'**
  String get categoryIconPickerNoResults;

  /// No description provided for @categoryColorPickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Color'**
  String get categoryColorPickerTitle;

  /// No description provided for @categoryDefaultIconLabel.
  ///
  /// In en, this message translates to:
  /// **'label'**
  String get categoryDefaultIconLabel;
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
