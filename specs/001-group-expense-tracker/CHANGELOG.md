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

## 2025-10-30 - Automatic Version Tracking System

### Added
- **Comprehensive version tracking and display system**:
  - `lib/core/services/version_service.dart` - VersionService for runtime version access via package_info_plus
  - `lib/core/presentation/widgets/version_footer.dart` - Super small (8px) version display widget positioned at bottom center
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
- Version display location: Bottom center of screen (non-intrusive, super small text)
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
