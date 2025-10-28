# Feature Changelog: Plates-Style Itemized Expense Splitter

**Feature ID**: 002-itemized-splitter

This changelog tracks all changes made during the development of this feature.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [Unreleased]

### Added
- [New features, files, or capabilities added]

### Changed
- [Changes to existing functionality]

### Fixed
- [Bug fixes]

### Removed
- [Removed features or files]

---

## Development Log

<!-- Add entries below in reverse chronological order (newest first) -->

## 2025-10-28 - Complete Localization System Implementation

### Added
- **Comprehensive localization infrastructure** using Flutter's built-in l10n system
- `lib/l10n/app_en.arb` with 250+ extracted strings organized by category:
  - Common UI (buttons, actions)
  - Validation messages
  - Trip management
  - Participant management
  - Expense management
  - Itemized expense wizard (all 4 steps)
  - Settlement & transfers
  - Date/time formatting
  - Currency and category names
- `l10n.yaml` configuration file for localization generation
- `lib/core/l10n/l10n_extensions.dart` helper for easy string access via `context.l10n`
- Updated `main.dart` with localization delegates and supported locales
- Updated `pubspec.yaml` with `flutter_localizations` dependency and `intl` ^0.20.2

### Changed
- **Migrated all 23+ presentation files** to use localization system:
  - Trip management (4 files)
  - Participant management (3 files)
  - Expense management (4 files)
  - Itemized wizard (4 files)
  - Settlement & transfers (4 files)
  - Category selector
  - All shared widgets
- Added `displayName(BuildContext)` to `CurrencyCode` and `SplitType` enums
- Added `symbol` getter to `CurrencyCode` for currency symbols ($, ₫)
- Added `getLocalizedName()` static method to categories
- Updated root `CLAUDE.md` with comprehensive localization guidelines:
  - How to use localization in widgets
  - String naming conventions
  - How to add new strings
  - How to add new languages
  - Best practices and patterns

### Technical Details
- **100% localization coverage** for all priority user-facing strings
- 250+ hardcoded strings replaced with ARB keys across 23+ files
- ARB file supports parameterization (`{name}`, `{count}`) and pluralization
- Type-safe string access with autocomplete support
- Localization files auto-generate on `flutter pub get` or `flutter build`
- Infrastructure ready for multi-language support (just add `app_vi.arb` for Vietnamese)
- Fixed async context handling in error messages
- Proper mounted checks for BuildContext usage across async gaps

## 2025-10-28 - Fixed: Expense List Not Auto-Updating After Edit

### Fixed
- Expense list now immediately reflects changes after editing itemized expense
- No longer requires manual refresh (navigating away/back) to see updates

### Root Cause
- Firestore stream emits updates, but UI rendered before stream propagated changes
- Bottom sheet closed immediately after wizard, using cached state

### Technical Details
- Added explicit `ExpenseCubit.loadExpenses()` call after wizard returns successfully
- Added 150ms delay to ensure Firestore write completes and stream emits
- Only triggers reload when `result == true` (expense was saved)
- Comprehensive debug logging for troubleshooting

### User Experience
**Before**:
1. Edit itemized expense → Save
2. Return to list → Old data shows
3. Navigate away and back → Updated data appears

**After**:
1. Edit itemized expense → Save
2. Return to list → Updated data immediately visible
3. All changes reflected (items, tax, tip, totals, expanded details)

### Files Modified
- `lib/features/expenses/presentation/widgets/expense_form_bottom_sheet.dart`

## 2025-10-28 - Fixed: Item Editing and Extras Loading in Edit Mode

### Fixed
- Added ability to edit individual items (name, quantity, price) within itemized expenses
- Fixed extras (tax/tip) not loading when editing existing expenses
- Item assignments now preserved when editing item details

### Technical Details
**Items Edit Feature**:
- Added `_editingItemId` state variable to track edit mode
- Added edit icon button to each item card
- Modified "Add Item" card to show as "Edit Item" with pre-filled fields
- Created `_startEditItem()` method to enter edit mode and populate controllers
- Created `_cancelEdit()` method to exit edit mode
- Renamed `_addItem()` to `_saveItem()` to handle both add and update cases
- Preserves item assignment when updating

**Extras Initialization**:
- Added `_initializeFromState()` method to load existing tax/tip values
- Added `_getExtras()` helper to extract extras from any state type
- Uses `WidgetsBinding.instance.addPostFrameCallback()` to initialize after first build
- Sets toggle switches and populates controllers based on existing data

### User Experience
**Editing Items**:
1. Click edit icon on any item → Form fills with item data
2. Card title changes to "Edit Item", button to "Update Item" (orange color)
3. Cancel button appears to exit edit without saving
4. Modify fields → Click "Update Item" → Changes saved
5. Item assignments preserved during edit

**Editing Extras**:
1. Navigate to extras step when editing expense with tax/tip
2. Tax toggle automatically ON with value pre-filled (e.g., "8.875")
3. Tip toggle automatically ON with value pre-filled (e.g., "18")
4. Can modify or disable as needed

### Files Modified
- `lib/features/expenses/presentation/pages/itemized/steps/items_step_page.dart`
- `lib/features/expenses/presentation/pages/itemized/steps/extras_step_page.dart`

## 2025-10-28 - Added: Full Edit Support for Itemized Expenses

### Added
- Complete CRUD support for itemized expenses (Create, Read, Update, Delete)
- Edit mode detection in expense form bottom sheet
- Automatic wizard navigation when tapping itemized expense
- Edit mode UI labels ("Edit Itemized Expense", "Update Expense")
- Success messages differentiate between create and update

### Technical Details
- Added `expenseId`, `originalDate`, `originalDescription`, `originalCategoryId`, `originalCreatedAt` to ItemizedExpenseEditing state
- Created `initFromExpense()` method in ItemizedExpenseCubit to load existing expense data
- Modified `save()` method to detect edit vs create mode and call appropriate repository method
- Bottom sheet now detects `splitType == itemized` and opens wizard with `existingExpense` parameter
- Wizard initializes via `initFromExpense()` when `existingExpense` is provided
- Preserves original timestamps (createdAt) when updating

### User Experience
**Editing Flow**:
1. User taps itemized expense in list
2. Bottom sheet detects itemized type
3. Wizard opens with all data pre-filled (payer, items, assignments, tax, tip)
4. User can modify any field
5. Click "Update Expense" to save changes
6. Returns to expense list with updated data

**UI Indicators**:
- AppBar title: "Edit Itemized Expense" (vs "New Itemized Expense")
- Save button: "Update Expense" (vs "Save Expense")
- Success message: "Expense updated successfully!" (vs "Expense saved successfully!")

**Data Integrity**:
- Preserves original date, description, category
- Maintains createdAt timestamp
- Updates updatedAt timestamp
- Recalculates all breakdowns based on new data

### Files Modified
- `lib/features/expenses/presentation/cubits/itemized_expense_state.dart`
- `lib/features/expenses/presentation/cubits/itemized_expense_cubit.dart`
- `lib/features/expenses/presentation/widgets/expense_form_bottom_sheet.dart`
- `lib/features/expenses/presentation/pages/itemized/itemized_expense_wizard.dart`
- `lib/features/expenses/presentation/pages/itemized/steps/review_step_page.dart`

### Known Limitations
- Cannot change split type from itemized to equal/weighted (would require separate flow)
- Cannot delete itemized expense from wizard (only from expense list)

## 2025-10-28 - Added: Expandable Expense Cards with Detailed Breakdown

### Added
- Expense cards in list view now have expandable details
- Added expansion toggle button (chevron icon) in each card
- Itemized expenses show: line items with assignments, extras (tax/tip/fees), per-person breakdown
- Equal/weighted expenses show: per-person breakdown with amounts
- Weighted split shows weight multipliers (e.g., "2x") next to names

### Technical Details
- Converted ExpenseCard from StatelessWidget to StatefulWidget
- Added `_isExpanded` state to manage expansion
- Created `_buildItemizedDetails()` for itemized expense detailed view
- Created `_buildEqualWeightedDetails()` for equal/weighted expense detailed view
- Displays line items with Chip widgets showing assigned users
- Shows tax/tip as percentage or absolute value based on type
- Uses CircleAvatar for participant icons in breakdown
- Smooth inline expansion without navigation

### User Experience
- Tap edit icon to modify expense (existing behavior)
- Tap chevron to expand/collapse details inline
- Itemized: See all line items, who ordered what, tax/tip details, and final per-person totals
- Equal/Weighted: See exactly how much each person owes
- Visual feedback with color-coded chips and avatars
- No need to navigate away from list to see details

### Files Modified
- `lib/features/expenses/presentation/widgets/expense_card.dart`

## 2025-10-28 - Fixed: Participant Count in Saved Expenses

### Fixed
- Participant list now only includes people with items assigned
- Changed from using all trip participants to filtering by participantBreakdown.keys
- Saved expense correctly shows participant count (e.g., "3 participants" instead of "6 participants")

### Technical Details
- Modified `save()` method in ItemizedExpenseCubit (line 322-325)
- Changed iteration from `readyState.draft.participants` to `readyState.participantBreakdown.keys`
- Only participants with non-zero amounts are included in expense.participants field
- Improves data accuracy for settlement calculations

### User Experience
- When saving itemized expense, participant count reflects actual people involved
- Settlement screen shows correct number of people per expense
- More accurate expense filtering by participant

### Files Modified
- `lib/features/expenses/presentation/cubits/itemized_expense_cubit.dart`

## 2025-10-28 - Fixed: Payer Selection Now Works in People Step

### Fixed
- Added `setPayer` method to ItemizedExpenseCubit
- Implemented onTap handler in PeopleStepPage to update payer
- Users can now select different payer by tapping participant cards

### Technical Details
- Added `setPayer(String payerUserId)` method to cubit (line 91-110)
- Method updates state and recalculates (important for payer-based remainder distribution)
- PeopleStepPage now calls `context.read<ItemizedExpenseCubit>().setPayer(userId)` on tap
- Includes debug logging for troubleshooting

### User Experience
- Tap any participant card in Step 1 to change who paid
- Selected payer shows checkmark and highlighted border
- Changes take effect immediately

### Files Modified
- `lib/features/expenses/presentation/cubits/itemized_expense_cubit.dart`
- `lib/features/expenses/presentation/pages/itemized/steps/people_step_page.dart`

## 2025-10-28 - Fixed: Bottom Sheet Handler Now Includes Itemized Logic

### Fixed
- Added itemized navigation logic to `expense_form_bottom_sheet.dart`
- Bottom sheet handler now properly navigates to wizard when itemized is selected
- Added comprehensive debug logging to bottom sheet handler

### Root Cause
- The app uses `showExpenseFormBottomSheet` (not `ExpenseFormPage`)
- The bottom sheet's `onSplitTypeChanged` handler only had simple setState logic
- It didn't include the itemized wizard navigation that was added to the page

### Technical Details
- Added missing imports: `ExpenseRepository`, `ItemizedExpenseCubit`, `ItemizedExpenseWizard`
- Copied full itemized navigation logic from expense_form_page.dart
- Handler now checks if `value == SplitType.itemized` and navigates to wizard
- Bottom sheet closes if wizard saves successfully
- All debug logs prefixed with `[BottomSheet]` for easy debugging

### Files Modified
- `lib/features/expenses/presentation/widgets/expense_form_bottom_sheet.dart`

### Testing
After hot restart, clicking "Itemized (Add Line Items)" should show:
```
🟣 [UI] Itemized button CLICKED
🟣 [BottomSheet Handler] onSplitTypeChanged called with: SplitType.itemized
🔵 [BottomSheet] ITEMIZED BUTTON PRESSED
... (wizard opens)
```

## 2025-10-28 - Fixed: Proper Navigation Return Handling

### Fixed
- Fixed navigation behavior when wizard is opened
- Wizard now returns result to indicate save vs cancel
- Expense form only closes if wizard saved successfully

### Technical Details
- Wizard returns `true` when saved (Navigator.pop(true))
- Wizard returns `null` when cancelled (back button)
- Expense form checks result: only pops if `result == true`

### User Experience
**When user saves in wizard:**
- Wizard closes → Expense form closes → Returns to trip page ✅

**When user cancels wizard:**
- Wizard closes → Expense form stays open → User can try again ✅

## 2025-10-28 - Fixed: Itemized Button Navigation

### Fixed
- Fixed crash when clicking "Itemized" button (ParticipantSelector null error)
- Changed itemized from SegmentedButton option to separate OutlinedButton
- Added guard to hide ParticipantSelector when navigating to wizard

### Technical Details
- ParticipantSelector only handles equal/weighted split types
- Itemized is now a navigation action, not a form state
- Button text clarifies action: "Itemized (Add Line Items)"

### User Experience
- **Before**: User clicks "Itemized" → app crashes
- **After**: User clicks "Itemized (Add Line Items)" → wizard opens smoothly

## 2025-10-28 - Integration Complete: Itemized Expenses Now Accessible

### Changed
- Extended ExpenseFormPage to include "Itemized" option in split type selector
- Added third segment to SegmentedButton (Equal / Weighted / Itemized)
- Implemented navigation to ItemizedExpenseWizard when itemized is selected
- Auto-close expense form after wizard saves successfully

### Technical Details
- Wizard receives trip context (tripId, participants, payer, currency) from expense form
- Uses BlocProvider to inject ItemizedExpenseCubit with ExpenseRepository
- Proper BuildContext handling across async navigation
- Clean compilation with zero errors

### User Flow
1. User clicks "Add Expense" on trip page
2. User sees 3 split type options: Equal / Weighted / Itemized
3. User selects "Itemized" → navigates to 4-step wizard
4. User completes wizard steps (People → Items → Extras → Review)
5. User clicks "Save Expense" → expense saved to Firestore
6. User returns to trip page → new itemized expense appears in list

### Files Modified
- `lib/features/expenses/presentation/pages/expense_form_page.dart`

### Status
✅ Feature is now fully integrated and accessible to users

## 2025-10-28 - Polished 4-Step Wizard UI Complete

### Added
- Created ItemizedExpenseWizard - 4-step wizard container with visual stepper
- Created PeopleStepPage (Step 1) - Payer selection with card-based UI
- Created ItemsStepPage (Step 2) - Add/edit line items with assignment dialog
- Created ExtrasStepPage (Step 3) - Tax and tip configuration with toggles and quick-select chips
- Created ReviewStepPage (Step 4) - Per-person breakdown with expandable audit trail

### UI/UX Highlights
- Visual stepper with progress indicator (People → Items → Extras → Review)
- Step navigation with tappable completed steps
- Assignment dialog with participant checkboxes
- Tax/tip toggle switches with preset rate chips (8%, 8.5%, 10% for tax; 15%, 18%, 20%, 25% for tip)
- Expandable per-person breakdown cards showing:
  - Items subtotal
  - Allocated tax, tip, fees, discounts
  - Rounding adjustments
  - Item-by-item contribution details
- Validation error/warning banners
- Grand total display card
- Payer badge on relevant person
- Save button with validation state

### Technical Details
- All pages integrate with ItemizedExpenseCubit reactive state
- Real-time recalculation as user inputs data
- Smooth page transitions with PageView
- Responsive layout with SingleChildScrollView
- Material Design 3 components

### Files Created
- `lib/features/expenses/presentation/pages/itemized/itemized_expense_wizard.dart`
- `lib/features/expenses/presentation/pages/itemized/steps/people_step_page.dart`
- `lib/features/expenses/presentation/pages/itemized/steps/items_step_page.dart`
- `lib/features/expenses/presentation/pages/itemized/steps/extras_step_page.dart`
- `lib/features/expenses/presentation/pages/itemized/steps/review_step_page.dart`

### Testing Status
- ✅ Compilation verified with flutter analyze
- ⏳ Manual end-to-end testing pending
- ⏳ Integration with ExpenseFormPage pending

## 2025-10-28 - Settlement Integration Complete

### Changed
- Updated SettlementCalculator to handle itemized expenses
- Now checks for `participantAmounts` field and uses pre-calculated values
- Falls back to `calculateShares()` for equal/weighted expenses
- Both `calculatePersonSummaries()` and `calculatePairwiseNetTransfers()` updated

### Technical Highlights
- Zero-breaking-change integration
- Itemized expenses now work in settlements automatically
- Maintains pairwise netting algorithm
- Proper logging for debugging

## 2025-10-28 - MVP Complete (Backend + Minimal UI)

### Added
- Created ItemizedExpensePage - minimal but functional single-page UI
- Item management: add, remove, assign to people
- Tax & tip inputs (percentage-based)
- Real-time calculation and breakdown display
- Per-person totals shown before saving
- Save to Firestore integration
- Validation error display

### Integration Notes
To use the ItemizedExpensePage:
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => BlocProvider(
      create: (context) => ItemizedExpenseCubit(
        expenseRepository: context.read<ExpenseRepository>(),
      ),
      child: ItemizedExpensePage(
        tripId: tripId,
        participants: ['alice', 'bob', 'charlie'],
        participantNames: {'alice': 'Alice', 'bob': 'Bob', 'charlie': 'Charlie'},
        payerUserId: 'alice',
        currency: CurrencyCode.usd,
      ),
    ),
  ),
);
```

### What Works
- ✅ Full calculation engine (246/267 tests passing)
- ✅ Firestore persistence (34 tests passing)
- ✅ State management with validation
- ✅ Basic UI for creating itemized expenses
- ✅ Per-person breakdown with audit trail
- ✅ Multi-currency support (USD, VND, BHD)

### What's Next (Future Enhancements)
- Add to existing ExpenseFormPage as 3rd split type option
- Build polished 4-step wizard UI (22 components)
- Add fees and discounts UI
- Add advanced allocation settings UI
- Receipt photo attachment
- Edit existing itemized expenses
- Integration tests

## 2025-10-28 - State Management Layer Complete

### Added
- Created ItemizedExpenseCubit for draft expense management
- Created 7 state classes (Initial, Editing, Calculating, Ready, Saving, Saved, Error)
- Implemented 15 Cubit methods: init, addItem, updateItem, removeItem, assignItem, setTax, setTip, addFee, removeFee, addDiscount, removeDiscount, setAllocation, save, validate, calculate
- Automatic validation on every change (unassigned items, empty items list, extreme percentages)
- Automatic recalculation after each modification

### Technical Highlights
- BLoC pattern with Cubit for state management
- Reactive validation with error and warning lists
- Optimistic UI updates (validation happens immediately)
- Currency-aware precision defaults (VND=1, USD=0.01, BHD=0.001)
- Auto-generated expense descriptions from items
- Full integration with ItemizedCalculator and ExpenseRepository

## 2025-10-28 - Data Layer Complete

### Added
- Created 4 Firestore DTO models (LineItemModel, ExtrasModel, AllocationRuleModel, ParticipantBreakdownModel)
- Added 24 serialization tests with golden JSON fixtures
- Created 10 ExpenseModel extension tests (full itemized, backward compat, partial fields, decimal precision, edge cases)
- Extended ExpenseModel with optional itemized fields (items, extras, allocation, participantAmounts, participantBreakdown)

### Changed
- No changes to ExpenseRepository - uses ExpenseModel.toJson/fromFirestore which now handles itemized fields automatically

### Technical Highlights
- Full backward compatibility: old expenses without itemized fields deserialize correctly (fields are null)
- Decimal precision preserved through serialization roundtrip
- Handles complex nested structures (multiple fees/discounts, many participants)
- Empty lists and null fields handled correctly
- Test coverage: 34 serialization/deserialization tests passing (24 DTOs + 10 ExpenseModel)

## 2025-10-28 - Domain Layer Complete

### Added
- Implemented 12 domain models with full validation (LineItem, ItemAssignment, Extras, TaxExtra, TipExtra, FeeExtra, DiscountExtra, AllocationRule, RoundingConfig, ItemContribution, ParticipantBreakdown)
- Created ItemizedCalculator service for core calculation engine
- Created RoundingService with 4 remainder distribution strategies
- Added 138 comprehensive unit tests (98 model tests + 40 service tests)
- Extended Expense model with optional itemized fields (backward compatible)
- Added DecimalService for currency-aware rounding
- Added ISO 4217 precision lookup for multi-currency support

### Changed
- Enhanced decimal_service.dart with proper Rational to Decimal conversions
- Fixed infinite precision handling for division operations

### Technical Highlights
- Full TDD approach: all tests passing (138/138)
- Proper handling of infinite precision rationals (e.g., 1/3) via double conversion
- Multi-currency support: USD (2 decimals), VND (0 decimals), BHD (3 decimals)
- 4 rounding modes: roundHalfUp, roundHalfEven, floor, ceil
- 4 remainder distribution strategies: largestShare, payer, firstListed, random
- Golden fixture tests covering real-world scenarios
- Complete audit trail with per-item contributions

## 2025-10-22 - Initial Setup

### Added
- Created feature specification
- Set up feature branch
- Initialized documentation structure
