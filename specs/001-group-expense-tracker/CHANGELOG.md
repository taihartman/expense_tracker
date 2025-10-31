# Feature Changelog: Group Expense Tracker for Trips

**Feature ID**: 001-group-expense-tracker

This changelog tracks all changes made during the development of this feature.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [Unreleased]

### In Progress
- Completing widget tests for expense forms
- Integration testing for expense recording flow
- Firebase Emulators configuration for local testing

---

## Development Log

## 2025-10-31 - ExpenseLoaded State Equality Fix

### Fixed
- **ExpenseLoaded state now properly detects when expense field values change**:
  - Root cause: `ExpenseLoaded` used Equatable with `props => [expenses]`, but `Expense.operator==` only compares by ID
  - When Firestore emitted updated expenses with changed fields (amount, description, etc.) but same IDs, Equatable considered states equal
  - Result: UI didn't rebuild, so changes weren't visually reflected in the expense list
  - Solution: Changed props to use `identityHashCode(expenses)` instead of direct list comparison
  - Now UI rebuilds whenever Firestore emits a new expense list instance, regardless of ID equality

### Changed
- **ExpenseState** (`lib/features/expenses/presentation/cubits/expense_state.dart`):
  - Line 30: Changed `props => [expenses, selectedExpense]` to `props => [identityHashCode(expenses), selectedExpense]`

### Impact
- ✅ **Real-time field updates now visible**: Edit expense amount/description on Device A → immediately appears on Device B
- ✅ **Works for all expense types**: Quick expenses (equal/weighted) and itemized/receipt splits
- ✅ **Maintains list position**: Expenses stay ordered by date, only content updates

## 2025-10-31 - Receipt Info Persistence Fix

### Fixed
- **Receipt info (expectedSubtotal, taxAmount) now persists to Firestore for itemized expenses**:
  - Root cause: Receipt info was stored only in UI state (`ItemizedExpenseCubit`), not in Firestore
  - When other devices loaded the expense, receipt info was missing
  - `initFromExpense()` was recalculating expectedSubtotal from items instead of loading saved value
  - Result: Receipt validation warnings appeared incorrectly, tax amounts were wrong on other devices

### Added
- **Expense Domain Model** (`lib/features/expenses/domain/models/expense.dart`):
  - Added `expectedSubtotal` field (Decimal?) - User-entered receipt subtotal for validation
  - Added `taxAmount` field (Decimal?) - User-entered tax amount for itemized splitting
  - Both fields optional for backward compatibility

- **Expense Serialization** (`lib/features/expenses/data/models/expense_model.dart`):
  - Added `expectedSubtotal` and `taxAmount` serialization to Firestore (stored as strings for precision)
  - Added deserialization with null-safe fallbacks
  - Backward compatible: Existing expenses without these fields work correctly

### Changed
- **ItemizedExpenseCubit** (`lib/features/expenses/presentation/cubits/itemized_expense_cubit.dart`):
  - `initFromExpense()`: Now loads receipt info from expense instead of recalculating
  - Fallback: If receipt info not available, calculates from items (backward compat)
  - `save()`: Now passes `expectedSubtotal` and `taxAmount` to Expense constructor
  - Logs show whether receipt info came from saved data or was calculated

### Impact
- ✅ **Receipt info syncs across devices**: Edit receipt on Device A → appears correctly on Device B
- ✅ **Validation warnings accurate**: Subtotal mismatches properly detected using saved receipt value
- ✅ **Tax amounts persist**: Tax splitting uses saved tax amount, not recalculated
- ✅ **Backward compatible**: Old expenses without receipt info work normally with fallback logic
- ✅ **Data integrity**: Receipt metadata preserved as user entered it

### Technical Details

**The Problem:**
1. User enters receipt with `expectedSubtotal: 22000` and `taxAmount: 10000`
2. Values stored in `ItemizedExpenseEditing` state (in-memory only)
3. Expense saved to Firestore WITHOUT these fields (domain model didn't have them)
4. Other device loads expense → `initFromExpense()` calculates `expectedSubtotal: 20` from items → WRONG
5. Receipt validation shows incorrect warnings

**The Solution:**
1. Added fields to Expense domain model (optional, Decimal?)
2. Added Firestore serialization (strings for precision, null-safe)
3. Updated `initFromExpense()` to load from expense first, calculate as fallback
4. Updated `save()` to pass receipt info to Expense constructor
5. All receipt metadata now persists and syncs across devices

## 2025-10-31 - Real-Time Expense Edits Fix (Part 2) + List Refresh Fix

### Fixed
- **Itemized expense edits now reflect in real-time across devices**:
  - Root cause: Manual `loadExpenses()` call in `expense_form_bottom_sheet.dart` (line 169) was missed in PR #22
  - This call was interfering with Firestore stream emissions, creating race conditions
  - The 150ms delay was a failed attempt to work around the timing issue
  - Only affected itemized expense edits (regular expenses worked correctly)

- **List no longer "refreshes" (disappears/reappears) when adding or editing expenses**:
  - Root cause: Intermediate loading states (`ExpenseCreating`, `ExpenseUpdating`) caused BlocBuilder to show empty widget
  - List would disappear → Firestore stream updates → List reappears (visual flash)
  - Affected all expense operations (add/edit)

### Changed
- **Expense Form Bottom Sheet** (`lib/features/expenses/presentation/widgets/expense_form_bottom_sheet.dart`):
  - Removed manual `loadExpenses()` call from `_openItemizedWizardForEdit()` method
  - Removed 150ms delay workaround
  - Removed unused `expenseCubit` variable
  - Now trusts Firestore stream to handle all updates automatically

- **ExpenseCubit** (`lib/features/expenses/presentation/cubits/expense_cubit.dart`):
  - Removed `emit(ExpenseCreating())` from `createExpense()` method (line 121)
  - Removed `emit(ExpenseUpdating())` from `updateExpense()` method (line 147)
  - Kept success states (`ExpenseCreated`, `ExpenseUpdated`) for UI notifications
  - Firestore stream now handles all list updates without intermediate states

- **Expense List Page** (`lib/features/expenses/presentation/pages/expense_list_page.dart`):
  - Added `buildWhen` optimization to BlocBuilder - only rebuilds for `ExpenseLoading`, `ExpenseError`, `ExpenseLoaded`
  - Prevents rebuilds for transient states like `ExpenseCreated`, `ExpenseUpdated`
  - Added `key: ValueKey(expense.id)` to ExpenseCard items for efficient Flutter widget updates

### Impact
- ✅ **Itemized expense edits now sync in real-time** across all devices
- ✅ **List updates smoothly in-place** - no more disappearing/reappearing
- ✅ **Scroll position maintained** during add/edit/delete operations
- ✅ **No visual flash or flicker** when expense data changes
- ✅ **Better performance**: Fewer unnecessary widget rebuilds
- ✅ **Cleaner code**: Removed workarounds and unnecessary delays
- ✅ **Consistent behavior**: All expense types use same update mechanism

### Technical Details

**Real-Time Sync Issue:**
The issue occurred because:
1. User edits itemized expense → Firestore updates → stream should emit
2. Bottom sheet manually calls `loadExpenses()` after wizard closes
3. Even with trip-switching detection, the timing of this call interfered with stream emissions
4. Other devices' streams would miss updates due to race conditions

**List Refresh Issue:**
The "flash" happened because:
1. User adds/edits expense
2. Cubit emits `ExpenseCreating`/`ExpenseUpdating` (NOT `ExpenseLoaded`)
3. BlocBuilder sees state is not `ExpenseLoaded` → returns `SizedBox.shrink()` (empty)
4. List widget tree destroyed → **list disappears**
5. Firestore stream emits updated data
6. Cubit emits `ExpenseLoaded` → **list reappears**

**Solution:**
1. Remove intermediate loading states - trust stream for all updates
2. Add `buildWhen` filter - only rebuild for states that affect display
3. Add widget keys - help Flutter efficiently update changed items

Now the flow is:
1. User modifies expense → Firestore updates → stream emits automatically
2. List updates in-place without disappearing
3. Clean, predictable, smooth real-time sync

## 2025-10-30 - Real-Time Expense Updates Fix

### Fixed
- **Real-time expense updates now work correctly for edits and deletes**:
  - Root cause: `loadExpenses()` was being called during build phase in `app_router.dart`, causing Firestore stream subscription to cancel/recreate on every widget rebuild
  - This created a race condition where edits/deletes triggered stream updates → UI rebuild → stream cancelled → new stream read stale cache → old data displayed
  - Adds now worked because new data was already in Firestore cache when stream recreated

### Changed
- **ExpenseCubit stream subscription management** (`lib/features/expenses/presentation/cubits/expense_cubit.dart`):
  - Added trip-switching detection: `loadExpenses()` now only recreates stream when switching to a different trip
  - Returns early if already listening to the requested trip (avoids unnecessary stream churn)
  - Stream subscription now stable during expense CRUD operations

- **Router architecture** (`lib/core/router/app_router.dart`):
  - Removed `loadExpenses()` call from `BlocBuilder.builder()` (line 324)
  - Added `BlocListener<TripCubit>` wrapper to listen for trip selection changes
  - `loadExpenses()` now called from listener callback instead of build phase
  - Proper separation: listeners handle side effects, builders handle rendering

- **CRUD operations cleanup** (`lib/features/expenses/presentation/cubits/expense_cubit.dart`):
  - Removed manual `loadExpenses()` calls from `createExpense()`, `updateExpense()`, and `deleteExpense()`
  - Firestore stream automatically updates the expense list on changes
  - Cleaner code with fewer redundant operations

### Impact
- **Real-time sync now works correctly**: Edits and deletes made on Device A immediately reflect on Device B
- **Better performance**: Fewer stream subscriptions created (only on trip switching, not on every rebuild)
- **Cleaner architecture**: Follows Flutter/Bloc best practices (no side effects in build methods)
- **More reliable**: Eliminates race conditions between stream updates and cache reads

### Testing
- Analyzed modified files: No issues found
- Files pass `flutter analyze`
- Ready for manual testing across multiple devices

## 2025-10-30 - Automatic Version Tracking System

### Added
- **Comprehensive version tracking and display system**:
  - `lib/core/services/version_service.dart` - VersionService for runtime version access via package_info_plus
  - `lib/core/presentation/widgets/version_footer.dart` - Super small (8px) version display widget positioned at top left
  - Integrated version footer into home page using Stack wrapper in `lib/core/router/app_router.dart`
  - Initialized VersionService in `lib/main.dart` during app startup
- **Automated version bumping infrastructure**:
  - `.github/scripts/bump-version.sh` - Script to automatically increment patch version
  - `.github/scripts/bump-major-minor.sh` - Script to bump major/minor/patch versions manually
  - `.github/workflows/version-bump.yml` - GitHub Action for automatic patch version bump on every push to master
  - `.github/workflows/manual-version-bump.yml` - Manual workflow for major/minor version bumps via GitHub Actions UI
- **Dependency**: Added `package_info_plus: ^8.0.0` to pubspec.yaml for runtime version access
- **Documentation**: Updated CLAUDE.md with comprehensive version management section including commands and workflows

### Changed
- Version format displayed: `1.0.0+1` (semantic version with build number)
- Version display location: Top left of screen (visible on mobile web, not obscured by browser chrome)
- Version source: Single source of truth in `pubspec.yaml`, automatically read at runtime

### Impact
- Every push to master automatically increments patch version (1.0.0 → 1.0.1)
- Major/minor version bumps can be triggered manually via GitHub Actions for spec-kit features
- Users can see current app version at a glance
- No manual version management required - fully automated

## 2025-10-30 - Trip Join UX Enhancement

### Changed
- **Improved trip join flow terminology and clarity**:
  - Changed "Load Trip" button to "Continue" for better user understanding
  - "Load Trip" was technical jargon; "Continue" is familiar multi-step form language
  - Updated banner message: "Tap 'Continue' to proceed" (previously "Tap 'Load Trip' to continue")
  - Updated error message: "Could not verify trip code" (previously "Could not load trip")
- **Added step indicators** to clarify two-step join process:
  - Step 1 of 2: Verify Trip Code (enter code → Continue)
  - Step 2 of 2: Select Your Identity (choose participant → Verify Identity)
  - Consistent visual design with info icon and primary color theme
- Files modified:
  - `lib/l10n/app_en.arb` - Updated `tripJoinLoadButton`, `tripJoinInviteBannerMessage`, `tripJoinLoadError`; added `tripJoinStepIndicator`
  - `lib/features/trips/presentation/pages/trip_join_page.dart` - Added `_buildStepIndicator()` widget

### Impact
- Clearer user journey - users now understand it's a multi-step process
- Reduced confusion about what "Load Trip" means (technical vs user language)
- Standard multi-step form UX pattern improves familiarity

## 2025-10-29 - Automated Documentation Workflow

### Added
- **Automated documentation workflow system** to ensure Claude Code proactively documents changes:
  - `.claude-workflow-checklist.md` - Detailed checklist for when to use `/docs.log` and `/docs.update`
  - `.github/CLAUDE_CODE_INSTRUCTIONS.md` - Mandatory workflow instructions for AI
  - `.github/CLAUDE_WORKFLOW_EXAMPLE.md` - Concrete example showing correct vs incorrect workflow
- **Updated root CLAUDE.md** with prominent workflow instructions at the top
  - Added "IMPORTANT: Claude Code Workflow Instructions" section
  - Explicit triggers for `/docs.log` and `/docs.update`
  - Strong directive to not wait for user reminders

### Changed
- Documentation workflow is now AI-enforced, not user-initiated
- Claude Code will proactively use `/docs.log` after each significant change
- Claude Code will use `/docs.update` after architectural changes (models, cubits, routes, etc.)

### Impact
- Development sessions will have real-time changelog updates
- Feature CLAUDE.md files stay synchronized with code changes
- Reduces documentation debt and improves project maintainability

## 2025-10-29 - Archive Navigation and Auto-Selection Enhancement

### Fixed
- **Trip Settings navigation after archive**: Users are now redirected to the home page after successfully archiving a trip, preventing them from being stuck on the archived trip's settings page
- Added `context.go('/')` after archive success confirmation in `trip_settings_page.dart`

### Enhanced
- **Auto-selection after archiving current trip**: When archiving the currently selected trip, the system now automatically clears the selection and auto-selects the first available active trip
- Updated `TripCubit.archiveTrip()` to check if the archived trip is currently selected, clear selection, and trigger auto-selection logic
- Ensures users always land on a valid trip context after archiving, with seamless transition to another active trip

### Added
- **"View Archived Trips" button in trip selector modal**: Users can now access archived trips by tapping "My Trips" in the AppBar
- Button appears at the bottom of the trip selector modal (only when archived trips exist)
- Shows archived trip count badge: "Archived Trips (3)"
- Navigates to `/trips/archived` when tapped
- Modified `trip_selector.dart` to accept and display archived count

## 2025-10-29 - Trip Auto-Focus and Archive System

### Added
- **Auto-focus for newly created trips**: New trips are now automatically selected after creation for immediate use
- **Comprehensive trip archiving system**:
  - Archive/unarchive buttons in Trip Settings page
  - Dedicated Archived Trips page at `/trips/archived` route
  - "View Archived Trips" button in Trip List page (shows count)
  - Archived trips remain fully functional but hidden from main trip selector
- **Data model updates**:
  - Added `isArchived` field to Trip domain model (defaults to false)
  - Updated Trip Firestore model serialization with backward compatibility
  - Modified TripState to include separate `archivedTrips` list
- **State management**:
  - `TripCubit.archiveTrip(tripId)` - Archives a trip
  - `TripCubit.unarchiveTrip(tripId)` - Restores archived trip
  - Updated `loadTrips()` to filter and separate active/archived trips
- **Localization**: Added 10 new strings for archive functionality

### Changed
- Trip selector modal now filters to show only active (non-archived) trips
- `loadTrips()` now emits both active and archived trips in separate lists
- Auto-selection logic prioritizes active trips when no trip is selected

### Files Modified
- `lib/features/trips/domain/models/trip.dart` - Added isArchived field
- `lib/features/trips/data/models/trip_model.dart` - Updated serialization
- `lib/features/trips/presentation/cubits/trip_cubit.dart` - Archive methods and auto-focus
- `lib/features/trips/presentation/cubits/trip_state.dart` - Added archivedTrips list
- `lib/features/trips/presentation/pages/trip_settings_page.dart` - Archive UI
- `lib/features/trips/presentation/pages/trip_list_page.dart` - View archived button
- `lib/core/router/app_router.dart` - Added /trips/archived route
- `lib/l10n/app_en.arb` - Archive localization strings

### Files Created
- `lib/features/trips/presentation/pages/archived_trips_page.dart` - Archived trips management UI

## 2025-10-29 - Activity Tracking Documentation

### Added
- Comprehensive activity tracking guidelines in root `CLAUDE.md`
  - Complete section on "Activity Tracking & Audit Trail"
  - Step-by-step guide for adding activity logging to new features
  - Identity management patterns documentation
  - ActivityType enum expansion instructions
  - Repository injection best practices
  - Actor attribution guidelines (current user vs payer/creator)
  - Testing strategies for activity logging
  - Code examples for all common scenarios

### Changed
- Updated feature `CLAUDE.md` with activity tracking architecture details
  - Documented 14 activity types (trip, participant, expense, settlement, security)
  - Explained per-trip identity storage and retrieval
  - Documented Firestore subcollection structure
  - Added integration patterns and implementation details
  - Marked activity tracking as completed feature

### Documentation
This ensures all future feature development automatically includes proper activity tracking and audit trails.

## 2025-10-21 - Performance Optimization

### Changed
- Optimized app performance with offline-first architecture
- Implemented cache-first queries for Firestore data access
- Enhanced loading states and error handling

## 2025-10-21 - Settlement Calculation System

### Added
- Settlement calculator domain service (`lib/features/settlements/domain/services/settlement_calculator.dart`)
- Settlement domain models: PersonSummary, SettlementSummary, PairwiseDebt, MinimalTransfer
- Settlement data models with Firestore serialization
- Settlement repository with caching
- Settlement Cubit for state management
- Settlement UI pages and widgets:
  - Settlement Summary Page
  - All People Summary Table
  - Minimal Transfers View
- Pairwise debt netting algorithm
- Minimal transfer optimization using greedy matching

### Technical Details
- Implements full decimal precision for monetary calculations
- Settlement calculations complete within 2 seconds requirement
- Color coding for positive (green) and negative (red) net balances
- Copy-to-clipboard functionality for settlement plans

## 2025-10-21 - Trip Management Features

### Added
- Trip settings page (`lib/features/trips/presentation/pages/trip_settings_page.dart`)
- Participant management:
  - Participant form bottom sheet for adding/editing participants
  - Delete participant dialog with validation
  - Dynamic participant list per trip
- Trip selector widget with dropdown navigation
- Trip creation and list pages
- Trip Cubit for state management
- Trip domain and data models with Firestore integration

### Changed
- Enhanced Trip model to support dynamic participants (beyond fixed list)
- Updated trip selector to show current trip context

## 2025-10-21 - Expense Recording System

### Added
- Expense domain entity with split calculation (`lib/features/expenses/domain/models/expense.dart`)
- Category domain entity and repository
- Expense Firestore models and repository implementation
- Expense Cubit for state management
- Expense UI components:
  - Expense form page with split type selection
  - Expense list page
  - Expense card widget
  - Expense form bottom sheet
  - Participant selector with equal/weighted split support
  - Category selector widget
- Split calculation logic:
  - Equal split across selected participants
  - Weighted split with custom weights
  - Decimal precision throughout calculations
- Client-side validation for expense inputs
- Loading states and error handling

### Technical Details
- Supports multi-currency (USD/VND)
- Split types: Equal and Weighted
- Uses Decimal for precise monetary calculations
- Firestore integration with subcollection structure

## 2025-10-20 - Core Infrastructure Setup

### Added
- Firebase project initialization with FlutterFire
- Project dependencies:
  - flutter_bloc for state management
  - cloud_firestore for database
  - firebase_auth for authentication
  - firebase_functions for serverless functions
  - decimal for precise monetary calculations
  - fl_chart for data visualization
  - intl for internationalization
  - go_router for navigation
- Firestore security rules configuration
- Firestore indexes configuration
- Material Design 3 theme with 8px grid
- App router with go_router
- Firebase initialization in main.dart
- Core utilities:
  - Decimal helper utilities
  - Currency formatters (USD 2dp, VND 0dp)
  - Error handler utilities
- Core constants:
  - Fixed participants list (Tai, Khiet, Bob, Ethan, Ryan, Izzy)
  - Default categories (Meals, Transport, Accommodation, Activities)
- Base UI components (CustomButton, CustomTextField, LoadingIndicator)
- Firestore service wrapper
- Analysis options with zero-tolerance linting
- Cloud Functions project with TypeScript

### Technical Details
- Clean architecture: features/{feature}/domain|data|presentation
- Participant value object with id and name
- CurrencyCode enum (USD, VND)
- SplitType enum (Equal, Weighted)
- Repository pattern for data access

## 2025-10-20 - Testing Infrastructure

### Added
- Unit tests for expense split calculations (equal and weighted)
- Unit tests for expense validation rules
- Test structure following clean architecture

### Pending
- Widget tests for ExpenseForm and ExpenseCard
- Integration tests for expense recording flow

## 2025-10-20 - Spec-Kit Integration

### Added
- GitHub Spec-Kit for spec-driven development
- Slash commands: /speckit.specify, /speckit.plan, /speckit.tasks, /speckit.analyze, /speckit.clarify, /speckit.implement, /speckit.checklist
- Feature specification in specs/001-group-expense-tracker/spec.md
- Implementation plan in specs/001-group-expense-tracker/plan.md
- Task breakdown in specs/001-group-expense-tracker/tasks.md
- Data model documentation

## 2025-10-20 - Initial Setup

### Added
- Created feature specification
- Set up feature branch `001-group-expense-tracker`
- Initialized documentation structure
- Flutter web project initialization
- GitHub Actions CI/CD with auto-deploy to GitHub Pages
- Claude Code Action integration for GitHub
