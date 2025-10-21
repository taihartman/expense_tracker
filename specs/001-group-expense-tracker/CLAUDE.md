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

- `lib/[path]/[file].dart` - [Description]
- `test/[path]/[file]_test.dart` - [Description]

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

### State Management

- **Approach**: [BLoC/Cubit/Provider/etc.]
- **State files**:
  - `lib/[path]/[feature]_cubit.dart`
  - `lib/[path]/[feature]_state.dart`

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

## Future Improvements

Per spec, the following are out of scope for MVP but potential future enhancements:

- User authentication and authorization
- Role-based permissions (trip owner vs participant)
- Real-time exchange rate API integration
- CSV/Excel import of bulk expenses
- Receipt photo uploads and OCR
- Expense edit history and audit trail
- Undo/redo functionality
- Native mobile apps (iOS/Android)
- Offline mode support
- Email/SMS notifications for settlements
- Payment tracking (marking settlements as paid)
- Recurring expenses or templates
- Budget limits and spending alerts
- Multi-language support
- Custom currency support beyond USD/VND
- Export to accounting software

## Migration Notes

### Breaking Changes

- [None / List any breaking changes]

### Migration Steps

```bash
# If users need to run migrations
flutter pub get
flutter clean && flutter pub get  # If dependencies changed
```
