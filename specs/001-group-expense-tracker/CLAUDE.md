# Feature Documentation: Group Expense Tracker for Trips

**Feature ID**: 001-group-expense-tracker
**Branch**: `001-group-expense-tracker`
**Created**: 2025-10-21
**Status**: In Progress

## Quick Reference

### Key Commands for This Feature

```bash
# Run tests related to this feature
flutter test [test paths]

# Build with this feature
flutter build web

# Run specific widget tests
flutter test test/[feature]_test.dart
```

### Important Files Modified/Created

**Activity Tracking System** (Comprehensive audit trail for all user actions):
- `lib/features/trips/domain/models/activity_log.dart` - ActivityType enum and ActivityLog model (14 activity types)
- `lib/features/trips/domain/repositories/activity_log_repository.dart` - Repository interface for activity logs
- `lib/features/trips/data/repositories/activity_log_repository_impl.dart` - Firestore implementation
- `lib/features/trips/data/models/activity_log_model.dart` - Serialization/deserialization
- `lib/features/trips/presentation/pages/trip_activity_page.dart` - Activity log UI
- `lib/features/trips/presentation/widgets/activity_log_list.dart` - List widget for activities
- `lib/features/trips/presentation/widgets/activity_log_item.dart` - Individual activity display
- `lib/features/trips/presentation/cubits/activity_log_cubit.dart` - State management for activity logs
- `lib/core/services/local_storage_service.dart` - Added per-trip identity storage (saveUserIdentityForTrip, getUserIdentityForTrip)
- `lib/features/trips/presentation/cubits/trip_cubit.dart` - Added getCurrentUserForTrip() helper, stores identity on join
- `lib/features/expenses/presentation/cubits/expense_cubit.dart` - Updated to use actorName instead of payerName
- `lib/features/settlements/presentation/cubits/settlement_cubit.dart` - Added activity logging for settlements
- `lib/features/trips/data/models/activity_log_model.dart` - Serialization for all activity types

**Trip Management Enhancements**:
- `lib/features/trips/domain/models/trip.dart` - Added isArchived field for trip archiving
- `lib/features/trips/data/models/trip_model.dart` - Firestore serialization with backward compatibility
- `lib/features/trips/presentation/cubits/trip_cubit.dart` - Archive/unarchive methods, auto-focus on creation
- `lib/features/trips/presentation/cubits/trip_state.dart` - Separate archivedTrips list in TripLoaded state
- `lib/features/trips/presentation/pages/archived_trips_page.dart` - Dedicated archived trips management UI
- `lib/features/trips/presentation/pages/trip_settings_page.dart` - Archive section with archive/unarchive buttons
- `lib/features/trips/presentation/pages/trip_list_page.dart` - "View Archived Trips" button
- `lib/core/router/app_router.dart` - Added /trips/archived route

## Feature Overview

A comprehensive group expense tracker for trips with multi-currency support and intelligent settlement calculations. This feature enables trip organizers to:
- Record expenses with different payers and split types (equal/weighted)
- Handle multiple currencies (USD/VND) with exchange rate tracking
- Calculate optimal settlements using pairwise netting and minimal transfer algorithms
- View per-person dashboards with category breakdowns
- Manage multiple trips with isolated data

**Key Value Proposition**: Eliminates the complexity of splitting expenses on group trips by automatically calculating who owes whom and suggesting the minimum number of transfers needed to settle all debts.

## Architecture Decisions

### Data Models

- **Trip**: Represents a travel event
  - Location: TBD in implementation plan
  - Key properties: name, base currency (USD/VND), creation date, participants
  - Used by: All feature components

- **Expense**: Represents a single payment
  - Location: TBD in implementation plan
  - Key properties: date, payer, currency, amount, description, category, split type, participant shares
  - Used by: Expense recording, settlement calculations

- **Exchange Rate**: Currency conversion tracking
  - Location: TBD in implementation plan
  - Key properties: optional date, from currency, to currency, rate value, source
  - Used by: Multi-currency calculations

- **Participant**: Fixed list for MVP
  - Names: Tai, Khiet, Bob, Ethan, Ryan, Izzy
  - Properties: identifier, name
  - Used by: Expense splitting, settlement calculations

- **Category**: Expense classification
  - Pre-seeded: Meals, Transport, Accommodation, Activities
  - Properties: name
  - Used by: Expense categorization, dashboard breakdowns

- **Settlement Summary** (Computed): Aggregated financial data
  - Properties: per-person paid/owed/net amounts in base currency
  - Used by: Settlement display

- **Pairwise Debt** (Computed): Netted debts between participants
  - Properties: debtor, creditor, amount
  - Used by: Settlement calculations

- **Minimal Transfer** (Computed): Optimal transfer plan
  - Properties: from participant, to participant, amount
  - Used by: Settlement recommendations

### Activity Tracking Architecture

**Purpose**: Comprehensive audit trail showing who did what and when in each trip.

**Identity Management**:
- Users select their identity from the trip's participant list when joining
- Identity stored per-trip in `LocalStorageService` using `saveUserIdentityForTrip(tripId, participantId)`
- Retrieved via `TripCubit.getCurrentUserForTrip(tripId)` for activity attribution
- No global user concept - identity is trip-scoped

**Data Storage**:
- Firestore subcollection: `/trips/{tripId}/activityLog/{logId}`
- Append-only (no updates/deletes per security rules)
- Server timestamp enforced
- Ordered by timestamp descending (newest first)
- Real-time updates via streams

**Activity Types** (14 total):
- **Trip Management**: tripCreated, tripUpdated, tripDeleted
- **Participants**: memberJoined, participantAdded, participantRemoved
- **Expenses**: expenseAdded, expenseEdited, expenseDeleted, expenseCategoryChanged, expenseSplitModified
- **Settlements**: transferMarkedSettled, transferMarkedUnsettled
- **Security**: deviceVerified, recoveryCodeUsed

**Integration Pattern**:
1. Inject `ActivityLogRepository?` in cubits (optional for testing)
2. Get current user: `TripCubit.getCurrentUserForTrip(tripId)` from UI layer
3. Pass `actorName` parameter to cubit methods
4. Log after successful operation (non-fatal, wrapped in try-catch)
5. Activity logs never break main operations

**Key Implementation Detail**:
Changed ExpenseCubit from using `payerName` to `actorName` - ensures activity logs show WHO performed the action (current user), not who paid for the expense.

### State Management

- **Approach**: BLoC/Cubit pattern (flutter_bloc)
- **State files**:
  - `lib/features/trips/presentation/cubits/trip_cubit.dart` - Trip management
  - `lib/features/expenses/presentation/cubits/expense_cubit.dart` - Expense CRUD
  - `lib/features/settlements/presentation/cubits/settlement_cubit.dart` - Settlement calculations
  - `lib/features/trips/presentation/cubits/activity_log_cubit.dart` - Activity log viewing
  - All cubits with state changes inject `ActivityLogRepository?` for audit trail

### UI Components

- **Main screens**:
  - `lib/screens/[feature]_screen.dart` - [Description]

- **Widgets**:
  - `lib/widgets/[widget].dart` - [Description]

## Dependencies Added

```yaml
# From pubspec.yaml
dependencies:
  [package_name]: [version]  # [Purpose]

dev_dependencies:
  [package_name]: [version]  # [Purpose]
```

## Implementation Notes

### Key Design Patterns

- **Settlement Algorithm**: Greedy matching for minimal transfer calculation
  - Pairwise debt netting (A→B minus B→A)
  - Minimal transfer optimization using creditor/debtor matching
  - Should reduce transfers by ~30% compared to pairwise approach

- **Trip Archiving System**: Soft-delete pattern for trip management
  - Archived trips remain fully functional (can view, add expenses, edit, etc.)
  - `isArchived` boolean field in Trip model (defaults to false)
  - Firestore backward compatible - existing trips without field treated as active
  - State separation: `TripLoaded` state contains both `trips` (active) and `archivedTrips` lists
  - UI filtering: Trip selector modal shows only active trips
  - Dedicated `/trips/archived` route for managing archived trips
  - Auto-focus: Newly created trips are automatically selected for immediate use
  - Identity preservation: User's trip identity persists when archiving/unarchiving

### Performance Considerations

- Full decimal precision for monetary calculations (no intermediate rounding)
- Settlement calculations should complete within 2 seconds of expense recording
- Exchange rate lookup strategy: exact date match → any date match → reciprocal → 1.0

### Known Limitations

- MVP: Fixed participant list (no dynamic user management)
- MVP: Manual exchange rate entry only (no API fetching)
- MVP: Limited to USD and VND currencies
- Storage mechanism TBD (will be determined in implementation plan)

## Testing Strategy

### Test Coverage

- Unit tests: `test/[feature]/`
- Widget tests: `test/widgets/[feature]/`
- Integration tests: `test/integration/[feature]/`

### Manual Testing Checklist

- [ ] Create trip with base currency USD and VND
- [ ] Record 5-10 expenses with different payers and amounts
- [ ] Test equal split with 2-6 participants
- [ ] Test weighted split with various weight distributions
- [ ] Record expenses in multiple currencies (USD + VND)
- [ ] Enter exchange rates and verify conversions
- [ ] Verify pairwise netting (A owes B 10000, B owes A 20000 → net 10000 to A)
- [ ] Verify minimal settlement reduces transfer count by ~30%
- [ ] Test category assignment and dashboard displays
- [ ] Test copy-to-clipboard for settlement plan
- [ ] Verify color coding (green for positive, red for negative net balances)
- [ ] Test data isolation between multiple trips
- [ ] Test edge cases from spec (no participants, missing exchange rates, etc.)

## Related Documentation

- Main spec: `specs/001-group-expense-tracker/spec.md`
- Implementation plan: `specs/001-group-expense-tracker/plan.md`
- Tasks: `specs/001-group-expense-tracker/tasks.md`

## Implemented Features

**✅ Activity Tracking & Audit Trail** (Completed):
- Comprehensive activity logging for all state-changing operations
- Per-trip identity management with automatic storage
- Real-time activity feed with 14 activity types
- Proper actor attribution (current user, not payer/creator)
- Color-coded UI with icons and relative timestamps
- Firestore integration with append-only security

**✅ Trip Management Enhancements** (Completed):
- **Auto-focus on creation**: Newly created trips are automatically selected
- **Trip archiving system**:
  - Archive/unarchive trips from Trip Settings page
  - Archived trips remain fully functional but hidden from main selector
  - Dedicated Archived Trips page (`/trips/archived`)
  - "View Archived Trips" button in Trip List (with count badge)
  - Backward-compatible Firestore implementation
  - Separate state management for active vs archived trips

## Future Improvements

Per spec, the following are out of scope for MVP but potential future enhancements:

- User authentication and authorization
- Role-based permissions (trip owner vs participant)
- Real-time exchange rate API integration
- CSV/Excel import of bulk expenses
- Receipt photo uploads and OCR
- ~~Expense edit history and audit trail~~ ✅ **Implemented via Activity Tracking**
- Undo/redo functionality
- Native mobile apps (iOS/Android)
- Offline mode support
- Email/SMS notifications for settlements
- ~~Payment tracking (marking settlements as paid)~~ ✅ **Implemented via transferMarkedSettled activity type**
- Recurring expenses or templates
- Budget limits and spending alerts
- Multi-language support (partial: activity log text is English-only)
- Custom currency support beyond USD/VND
- Export to accounting software
- **Activity Log Enhancements**:
  - Filtering/search within activity log
  - Export activity history to CSV
  - Activity log pagination for large trips
  - Rich metadata display (show old/new values for updates)

## Migration Notes

### Breaking Changes

- [None / List any breaking changes]

### Migration Steps

```bash
# If users need to run migrations
flutter pub get
flutter clean && flutter pub get  # If dependencies changed
```
