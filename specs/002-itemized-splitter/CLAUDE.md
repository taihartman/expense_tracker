# Feature Documentation: Plates-Style Itemized Expense Splitter

**Feature ID**: 002-itemized-splitter
**Branch**: `002-itemized-splitter`
**Created**: 2025-10-22
**Status**: Planning Complete - Ready for Implementation

## Quick Reference

### Key Commands for This Feature

```bash
# Run all tests
flutter test

# Run itemized expense calculator tests
flutter test test/unit/expenses/domain/services/itemized_calculator_test.dart

# Run itemized expense cubit tests
flutter test test/unit/expenses/presentation/cubits/itemized_expense_cubit_test.dart

# Run itemized UI widget tests
flutter test test/widget/expenses/itemized/

# Run end-to-end integration test
flutter test test/integration/itemized_expense_flow_test.dart

# Build for production
flutter build web --base-href /expense_tracker/

# Run with verbose logging for settlement debugging
flutter run -d chrome --dart-define=DEBUG_SETTLEMENTS=true
```

### Important Files Modified/Created

#### Domain Layer (Business Logic)
- `lib/features/expenses/domain/models/expense.dart` - [EXTEND] Add optional itemized fields
- `lib/features/expenses/domain/models/line_item.dart` - [NEW] Line item entity
- `lib/features/expenses/domain/models/item_assignment.dart` - [NEW] Item assignment (even/custom)
- `lib/features/expenses/domain/models/extras.dart` - [NEW] Tax/tip/fees/discounts container
- `lib/features/expenses/domain/models/tax_extra.dart` - [NEW] Tax configuration
- `lib/features/expenses/domain/models/tip_extra.dart` - [NEW] Tip configuration
- `lib/features/expenses/domain/models/fee_extra.dart` - [NEW] Fee configuration
- `lib/features/expenses/domain/models/discount_extra.dart` - [NEW] Discount configuration
- `lib/features/expenses/domain/models/allocation_rule.dart` - [NEW] Allocation rules
- `lib/features/expenses/domain/models/rounding_config.dart` - [NEW] Rounding policy
- `lib/features/expenses/domain/models/participant_breakdown.dart` - [NEW] Per-person audit trail
- `lib/features/expenses/domain/models/item_contribution.dart` - [NEW] Item contribution detail
- `lib/features/expenses/domain/services/itemized_calculator.dart` - [NEW] Core calculation engine
- `lib/features/expenses/domain/services/rounding_service.dart` - [NEW] Rounding + remainder distribution
- `lib/core/models/split_type.dart` - [EXTEND] Add 'itemized' enum value
- `lib/core/services/decimal_service.dart` - [NEW] Centralized rounding utilities
- `lib/core/models/iso_4217_precision.dart` - [NEW] Currency precision lookup

#### Data Layer (Persistence)
- `lib/features/expenses/data/models/expense_model.dart` - [EXTEND] Firestore serialization for itemized
- `lib/features/expenses/data/models/line_item_model.dart` - [NEW] Firestore DTO
- `lib/features/expenses/data/models/extras_model.dart` - [NEW] Firestore DTO
- `lib/features/expenses/data/models/allocation_rule_model.dart` - [NEW] Firestore DTO
- `lib/features/expenses/data/repositories/expense_repository_impl.dart` - [EXTEND] Handle itemized

#### Presentation Layer (UI + State)
- `lib/features/expenses/presentation/cubits/itemized_expense_cubit.dart` - [NEW] Draft state management
- `lib/features/expenses/presentation/cubits/itemized_expense_state.dart` - [NEW] State classes
- `lib/features/expenses/presentation/pages/add_expense_page.dart` - [EXTEND] Add "Itemized" option
- `lib/features/expenses/presentation/pages/itemized/itemized_expense_flow.dart` - [NEW] 4-step wizard
- `lib/features/expenses/presentation/pages/itemized/people_step_page.dart` - [NEW] Select participants
- `lib/features/expenses/presentation/pages/itemized/items_step_page.dart` - [NEW] Add/assign items
- `lib/features/expenses/presentation/pages/itemized/extras_step_page.dart` - [NEW] Tax/tip/fees
- `lib/features/expenses/presentation/pages/itemized/review_step_page.dart` - [NEW] Review + save
- `lib/features/expenses/presentation/widgets/itemized/line_item_card.dart` - [NEW] Item with assignment
- `lib/features/expenses/presentation/widgets/itemized/item_assignment_picker.dart` - [NEW] Even/custom picker
- `lib/features/expenses/presentation/widgets/itemized/extras_form.dart` - [NEW] Tax/tip inputs
- `lib/features/expenses/presentation/widgets/itemized/allocation_settings.dart` - [NEW] Advanced options
- `lib/features/expenses/presentation/widgets/itemized/review_summary_bar.dart` - [NEW] Grand total bar
- `lib/features/expenses/presentation/widgets/itemized/person_breakdown_card.dart` - [NEW] Per-person card
- `lib/features/expenses/presentation/widgets/itemized/breakdown_table_view.dart` - [NEW] Table mode
- `lib/features/expenses/presentation/widgets/itemized/validation_banner.dart` - [NEW] Error/warning display

#### Settlement Integration
- `lib/features/settlements/domain/services/settlement_calculator.dart` - [EXTEND] Consume participantAmounts

#### Tests (TDD)
- `test/unit/expenses/domain/models/line_item_test.dart` - [NEW] LineItem validation
- `test/unit/expenses/domain/models/extras_test.dart` - [NEW] Extras validation
- `test/unit/expenses/domain/services/itemized_calculator_test.dart` - [NEW] Golden fixtures
- `test/unit/expenses/domain/services/rounding_service_test.dart` - [NEW] Rounding policies
- `test/unit/expenses/presentation/cubits/itemized_expense_cubit_test.dart` - [NEW] State transitions
- `test/widget/expenses/itemized/line_item_card_test.dart` - [NEW] Widget test
- `test/widget/expenses/itemized/review_step_page_test.dart` - [NEW] Widget test
- `test/integration/itemized_expense_flow_test.dart` - [NEW] End-to-end test

## Feature Overview

This feature extends the expense tracking system to support **itemized receipt splitting** (similar to Plates app). Instead of splitting an entire expense amount equally or by custom weights, users can now:

1. **Add individual line items** from a receipt (e.g., "Pho Tai $14", "Spring Rolls $8")
2. **Assign each item** to one or more people (even split or custom shares like 2/3 - 1/3)
3. **Apply taxes, tips, fees, and discounts** with configurable allocation rules
4. **Choose rounding strategies** for handling fractional cents/currency units
5. **Review detailed per-person breakdowns** with full audit trail before saving
6. **Save as a single canonical expense** that integrates seamlessly with the existing settlement calculator

**Key Benefits**:
- **Fairness**: Each person pays only for what they ordered plus their fair share of taxes/tips
- **Transparency**: Full audit trail shows exactly how each person's total was calculated
- **Flexibility**: Handles complex real-world scenarios (split appetizers, tax-exempt items, service fees)
- **Currency-aware**: Supports VND (0 decimals) and USD (2 decimals) with proper rounding
- **Deterministic**: Same inputs always produce same outputs (critical for financial calculations)

## Architecture Decisions

### Design Philosophy

This feature follows **Clean Architecture** principles with strict separation of concerns:

1. **Domain Layer** (business logic)
   - Pure Dart entities with validation
   - Services for calculation and rounding (no Flutter dependencies)
   - Repository interfaces (contracts)

2. **Data Layer** (persistence)
   - Firestore models (DTOs)
   - Repository implementations
   - Serialization/deserialization logic

3. **Presentation Layer** (UI + state)
   - Cubits for state management (BLoC pattern)
   - Pages and widgets (Flutter)
   - No business logic in UI

### Data Models

#### Core Entities (Domain Layer)

**LineItem** - Represents a single line on a receipt
- Location: `lib/features/expenses/domain/models/line_item.dart`
- Key properties:
  - `id` (String): Unique identifier
  - `name` (String): Item description (e.g., "Pho Tai")
  - `quantity` (Decimal): How many (supports fractional, e.g., 0.5 bottles)
  - `unitPrice` (Decimal): Price per unit in expense currency
  - `taxable` (bool): Whether tax applies to this item
  - `serviceChargeable` (bool): Whether service fees apply
  - `assignment` (ItemAssignment): Who gets this item
- Computed properties:
  - `itemTotal`: `quantity * unitPrice`
- Used by: ItemizedCalculator, ItemsStepPage, ReviewStepPage

**ItemAssignment** - Defines how an item is split among people
- Location: `lib/features/expenses/domain/models/item_assignment.dart`
- Key properties:
  - `mode` (AssignmentMode enum): 'even' or 'custom'
  - `users` (List<String>): User IDs who share this item
  - `shares` (Map<String, Decimal>?): For custom mode, normalized shares that sum to 1.0
- Validation:
  - Even mode: shares must be null, at least 1 user
  - Custom mode: shares must be provided, sum to 1.0 (±0.0001 tolerance), match users list
- Used by: LineItem, ItemizedCalculator

**Extras** - Container for tax, tip, fees, and discounts
- Location: `lib/features/expenses/domain/models/extras.dart`
- Key properties:
  - `tax` (TaxExtra?): Tax configuration
  - `tip` (TipExtra?): Tip configuration
  - `fees` (List<FeeExtra>): Additional fees (e.g., delivery, service charge)
  - `discounts` (List<DiscountExtra>): Discounts or coupons
- Used by: Expense, ItemizedCalculator

**TaxExtra / TipExtra / FeeExtra / DiscountExtra** - Individual extra charges
- Locations: `lib/features/expenses/domain/models/[tax|tip|fee|discount]_extra.dart`
- Key properties:
  - `type` (ExtraType enum): 'percent' or 'amount'
  - `value` (Decimal): The percentage (e.g., 8.875) or absolute amount
  - `base` (PercentBase enum?): For percent type, what to apply percentage to
  - `appliesTo` (String?): For fees/discounts, what they apply to (e.g., "items", "postTax")
  - `name` (String): For fees/discounts, display name
- Used by: Extras, ItemizedCalculator

**AllocationRule** - Configures how extras are allocated and rounded
- Location: `lib/features/expenses/domain/models/allocation_rule.dart`
- Key properties:
  - `percentBase` (PercentBase enum): What percent-based extras use as base
  - `absoluteSplit` (AbsoluteSplitMode enum): How absolute-value extras are split
  - `rounding` (RoundingConfig): Rounding behavior
- Defaults:
  - `percentBase`: preTaxItemSubtotals
  - `absoluteSplit`: proportionalToItemsSubtotal
  - `rounding`: RoundingConfig with precision from currency
- Used by: Expense, ItemizedCalculator

**RoundingConfig** - Defines rounding behavior
- Location: `lib/features/expenses/domain/models/rounding_config.dart`
- Key properties:
  - `precision` (Decimal): Rounding increment (e.g., 0.01 for USD, 1 for VND)
  - `mode` (RoundingMode enum): roundHalfUp, roundHalfEven, floor, ceil
  - `distributeRemainderTo` (RemainderDistribution enum): largestShare, payer, firstListed, random
- Used by: AllocationRule, RoundingService

**ParticipantBreakdown** - Complete per-person audit trail
- Location: `lib/features/expenses/domain/models/participant_breakdown.dart`
- Key properties:
  - `userId` (String): Participant user ID
  - `itemsSubtotal` (Decimal): Sum of assigned item shares
  - `extrasAllocated` (Map<String, Decimal>): Tax, tip, fees, discounts allocated
  - `roundedAdjustment` (Decimal): Rounding remainder received (if any)
  - `total` (Decimal): Final amount this person owes
  - `items` (List<ItemContribution>): Item-by-item contributions
- Used by: Expense, ReviewStepPage (for audit display)

**Extended Expense Entity**
- Location: `lib/features/expenses/domain/models/expense.dart`
- New optional fields (backward compatible):
  - `items` (List<LineItem>?): Line items (only for splitType = 'itemized')
  - `extras` (Extras?): Tax/tip/fees (only for itemized)
  - `allocation` (AllocationRule?): Allocation rules (only for itemized)
  - `participantAmounts` (Map<String, Decimal>?): Canonical per-person totals (for settlements)
  - `participantBreakdown` (Map<String, ParticipantBreakdown>?): Full audit trail
- Validation:
  - If splitType = 'itemized', must have items, participantAmounts
  - Sum of participantAmounts must equal amount (within epsilon)
  - All assigned users must be in trip participants

### State Management

**Approach**: BLoC pattern with Cubits (from flutter_bloc package)

**ItemizedExpenseCubit** - Manages draft expense state during creation/editing
- Location: `lib/features/expenses/presentation/cubits/itemized_expense_cubit.dart`
- Responsibilities:
  - Maintain draft expense (trip, payer, currency, items, extras, allocation)
  - Trigger recalculation when data changes
  - Validate state (unassigned items, negative totals, extreme percentages)
  - Provide derived data (per-person breakdowns, grand total, validation errors)
  - Save expense via repository
- State classes (in `itemized_expense_state.dart`):
  - `ItemizedExpenseInitial`: Empty state before starting
  - `ItemizedExpenseEditing`: User is modifying data
  - `ItemizedExpenseCalculating`: Calculation in progress
  - `ItemizedExpenseReady`: Calculation complete, ready to save
  - `ItemizedExpenseSaving`: Saving to Firestore
  - `ItemizedExpenseSaved`: Save successful
  - `ItemizedExpenseError`: Validation or save error
- Actions (methods):
  - `init(tripId, participants, payer, currency)`: Start new itemized expense
  - `addItem(lineItem)`: Add line item
  - `updateItem(id, lineItem)`: Update existing item
  - `removeItem(id)`: Remove item
  - `assignItem(id, assignment)`: Change item assignment
  - `setTax(taxExtra)`: Set/update tax
  - `setTip(tipExtra)`: Set/update tip
  - `addFee(feeExtra)`: Add fee
  - `removeFee(index)`: Remove fee
  - `addDiscount(discountExtra)`: Add discount
  - `removeDiscount(index)`: Remove discount
  - `setAllocation(allocationRule)`: Update allocation rules
  - `recalculate()`: Trigger calculation (async)
  - `save()`: Persist expense to Firestore

**Integration with Existing ExpenseCubit**:
- ExpenseCubit remains unchanged for equal/weighted splits
- ItemizedExpenseCubit is a separate cubit, provided in ItemizedExpenseFlow widget tree
- Both use the same ExpenseRepository for persistence

### Calculation Engine

**ItemizedCalculator** - Core calculation service (pure Dart, no Flutter dependencies)
- Location: `lib/features/expenses/domain/services/itemized_calculator.dart`
- Algorithm (from research.md):
  1. **Calculate item subtotals per user** (even or custom shares)
  2. **Apply discounts** (proportional or per-person) → adjust subtotals
  3. **Calculate tax** (percent on chosen base or absolute) → allocate to users
  4. **Calculate fees** (percent or absolute) → allocate to users
  5. **Calculate tip** (percent on chosen base or absolute) → allocate to users
  6. **Sum per-user totals** (subtotal + tax + fees + tip - discounts)
  7. **Round each user's total** to currency precision
  8. **Distribute rounding remainder** per policy (largestShare, payer, etc.)
  9. **Validate**: sum of participantAmounts = amount (within epsilon)
  10. **Return**: participantAmounts, participantBreakdown, amount
- Input: items, extras, allocation, currency, participants, payer
- Output: `CalculationResult` with participantAmounts, participantBreakdown, amount, validation errors
- Performance: <100ms for 50 items, 6 participants (target from plan.md)
- Testing: 15+ golden fixtures covering edge cases

**RoundingService** - Handles rounding and remainder distribution
- Location: `lib/features/expenses/domain/services/rounding_service.dart`
- Methods:
  - `round(amount, precision, mode)`: Round single amount to precision
  - `distributeRemainder(amounts, remainder, policy, payer, currency)`: Assign remainder to one person
- Policies implemented (from research.md):
  - **largestShare**: Person with largest amount gets remainder
  - **payer**: Payer gets remainder (generous payer scenario)
  - **firstListed**: First person in list gets remainder (deterministic)
  - **random**: Random person (seeded for determinism in tests)
- Used by: ItemizedCalculator

### UI Components

**4-Step Wizard Flow**:

1. **PeopleStepPage** (`people_step_page.dart`)
   - Select participants (checkboxes, 1-6 people)
   - Select payer (radio buttons)
   - Select currency (USD or VND)
   - Next → ItemsStepPage

2. **ItemsStepPage** (`items_step_page.dart`)
   - Add line items (name, quantity, unit price, taxable, serviceChargeable)
   - Assign each item (Even or Custom button → ItemAssignmentPicker)
   - Show items subtotal
   - Back / Next → ExtrasStepPage
   - Widgets: LineItemCard, ItemAssignmentPicker

3. **ExtrasStepPage** (`extras_step_page.dart`)
   - Tax: percent or amount, select base (preTaxItemSubtotals, taxableOnly, postDiscount)
   - Tip: percent or amount, select base (preTax, postTax, postFees), presets (10%, 15%, 18%, 20%)
   - Fees: add multiple (name, percent/amount, appliesTo)
   - Discounts: add multiple (name, percent/amount, appliesTo)
   - Advanced: allocation settings (absoluteSplit, rounding policy)
   - Back / Next → ReviewStepPage
   - Widgets: ExtrasForm, AllocationSettings

4. **ReviewStepPage** (`review_step_page.dart`)
   - Summary bar: Items Subtotal, Tax, Tip, Fees, Discounts, Grand Total
   - Validation banner: unassigned items (error), negative totals (error), extreme % (warning)
   - Per-person cards (default): name, avatar, payer badge, breakdown (items, tax, tip, fees, discounts, rounding, total), audit expander (item-by-item contributions)
   - Table mode toggle: horizontal scroll table with per-person columns, footer sum row
   - Items snapshot (collapsible): all items with assignments
   - Footer: Back / Save Expense (disabled on blocking validation)
   - Widgets: ReviewSummaryBar, PersonBreakdownCard, BreakdownTableView, ValidationBanner

**Entry Point**:
- AddExpensePage gets new "Itemized (Plates)" button alongside "Equal" and "Weighted"
- Opens ItemizedExpenseFlow as full-screen modal or new route

**Design System**:
- 8px grid spacing
- Existing theme colors and typography
- 44x44px minimum touch targets (accessibility)
- Responsive: card view for mobile, table toggle for desktop

### Settlement Integration

**Existing SettlementCalculator** modified to:
- Check if expense has `splitType = 'itemized'`
- If yes, use `participantAmounts` directly instead of calling `expense.calculateShares()`
- Credit payer by `amount` (grand total)
- Debit each participant by `participantAmounts[userId]`
- Minimal transfer algorithm unchanged

**Example**:
```dart
// In settlement_calculator.dart
for (final expense in expenses) {
  if (expense.splitType == SplitType.itemized && expense.participantAmounts != null) {
    // Itemized expense: use pre-calculated amounts
    expense.participantAmounts!.forEach((userId, amountStr) {
      final share = Decimal.parse(amountStr);
      ledger[userId] -= share;
    });
    ledger[expense.payerUserId] += expense.amount;
  } else {
    // Equal/weighted: use existing logic
    final shares = expense.calculateShares();
    shares.forEach((userId, share) {
      ledger[userId] -= share;
    });
    ledger[expense.payerUserId] += expense.amount;
  }
}
```

## Dependencies Added

No new dependencies required! The feature uses existing packages:

```yaml
# Already in pubspec.yaml
dependencies:
  decimal: ^2.3.3           # Precise monetary arithmetic
  flutter_bloc: ^8.1.3      # State management
  equatable: ^2.0.5         # Value equality
  cloud_firestore: ^5.6.0   # Persistence
  intl: ^0.18.0             # Currency formatting

dev_dependencies:
  mockito: ^5.4.4           # Mocking for tests
  bloc_test: ^9.1.5         # Cubit testing
```

**Rationale**: All required functionality (Decimal math, state management, Firestore) already exists. No need to add new dependencies.

## Implementation Notes

### Key Design Patterns

**1. Clean Architecture** (Domain-Data-Presentation separation)
- Why: Testability, maintainability, separation of concerns
- Where: Entire feature follows this pattern
- Benefit: Domain logic (ItemizedCalculator) is pure Dart, testable without Flutter

**2. Repository Pattern** (ExpenseRepository interface)
- Why: Abstraction over Firestore, testable with mocks
- Where: ExpenseRepositoryImpl handles serialization/deserialization
- Benefit: Can swap Firestore for other backends without changing domain/presentation

**3. BLoC Pattern / Cubit** (State management)
- Why: Reactive, testable, separates business logic from UI
- Where: ItemizedExpenseCubit manages draft expense state
- Benefit: UI rebuilds automatically on state changes, easy to test state transitions

**4. Value Objects** (Immutable entities)
- Why: Data integrity, easier to reason about
- Where: All domain models (LineItem, Extras, AllocationRule, etc.)
- Benefit: No accidental mutations, copyWith for updates

**5. Builder Pattern** (Multi-step wizard)
- Why: Complex object construction with validation at each step
- Where: ItemizedExpenseFlow with 4 step pages
- Benefit: User can't save incomplete/invalid expense

### Performance Considerations

**1. Calculation Memoization**
- Problem: Recalculating on every item change can be expensive (50+ items)
- Solution: ItemizedExpenseCubit debounces recalculation (300ms), caches last result
- Benefit: Smooth UI updates without lag

**2. ListView.builder for Items**
- Problem: Large item lists (100+) can cause scroll jank
- Solution: Use ListView.builder (lazy rendering) instead of Column
- Benefit: Only visible items are rendered, 60fps maintained

**3. Const Widgets**
- Problem: Unnecessary rebuilds waste CPU
- Solution: Mark static widgets as const (e.g., icons, labels)
- Benefit: Reduced rebuild overhead

**4. Decimal Math Optimization**
- Problem: Decimal operations slower than double
- Solution: Minimize Decimal conversions, use int for quantities where possible
- Benefit: Faster calculations while maintaining precision

**5. Firestore Batch Write**
- Problem: Multiple writes can fail partially
- Solution: Use batch write for expense + trip.lastExpenseModifiedAt update
- Benefit: Atomic operation, all-or-nothing

### Known Limitations

**1. Fixed Participant List**
- Limitation: MVP supports only 6 fixed participants (Tai, Khiet, Bob, Ethan, Ryan, Izzy)
- Future: Add dynamic participant management
- Workaround: Users can leave participants unassigned in itemized expenses

**2. Two Currencies Only**
- Limitation: Only USD and VND supported in MVP
- Future: Add more currencies with ISO 4217 lookup table (already designed in research.md)
- Workaround: Users must convert to USD/VND manually

**3. No Multi-Receipt Merging**
- Limitation: Each receipt must be entered as separate expense
- Future: Allow combining multiple receipts into one expense
- Workaround: Enter sequentially

**4. No Receipt OCR**
- Limitation: Manual entry of line items
- Future: Camera + OCR to parse receipts automatically
- Workaround: Manual entry (target <3 minutes for 5 items per success criteria)

**5. No Drafts/Autosave**
- Limitation: User must complete in one session
- Future: Save drafts to local storage, resume later
- Workaround: Complete expense entry before closing app

## Testing Strategy

### Test Coverage Targets

- **Domain layer**: 80% minimum (TDD enforced)
- **Data layer**: 70% (serialization critical)
- **Presentation layer**: 60% (UI complexity)
- **Overall**: 70% coverage

### Test Organization (from tasks.md)

**Unit Tests** (`test/unit/`):
- **Domain models**: LineItem, Extras, AllocationRule validation
- **Services**: ItemizedCalculator (15+ golden fixtures), RoundingService (4 policies)
- **Cubits**: ItemizedExpenseCubit state transitions (bloc_test)

**Widget Tests** (`test/widget/`):
- LineItemCard, ItemAssignmentPicker
- ExtrasForm, AllocationSettings
- ReviewStepPage (card and table modes)
- PersonBreakdownCard, ValidationBanner

**Integration Tests** (`test/integration/`):
- End-to-end itemized expense flow
- Settlement calculation with itemized expenses
- Mixed expenses (itemized + equal + weighted)

### Manual Testing Checklist

**User Story 1 - Basic Itemized Split**:
- [ ] Create itemized expense with 3 items, 3 people, tax 8.875%, tip 18%
- [ ] Verify per-person totals match manual calculation
- [ ] Verify unassigned item prevents save
- [ ] Verify settlement summary includes correct debits/credits

**User Story 2 - Custom Shares**:
- [ ] Assign item with custom shares (2/3 - 1/3)
- [ ] Verify math reflects specified proportions
- [ ] Verify UI shows percentages correctly

**User Story 3 - Advanced Allocation**:
- [ ] Create expense with tax-exempt item, verify tax only on taxable items
- [ ] Add $5 delivery fee split evenly, verify each person gets $5/N
- [ ] Add 20% discount before tax, verify tax on reduced total

**User Story 4 - Review Screen**:
- [ ] Toggle between card and table view, verify data preserved
- [ ] Expand audit trail, verify item-by-item contributions shown
- [ ] Verify footer sum equals grand total

**User Story 5 - Currency/Rounding**:
- [ ] Create VND expense, verify 0 decimals displayed
- [ ] Create USD expense with remainder, verify policy applied (largestShare)
- [ ] Verify sum of rounded amounts equals grand total

**User Story 6 - Edit Expense**:
- [ ] Edit existing itemized expense, verify data pre-filled
- [ ] Modify item price, verify recalculation
- [ ] Save, verify updated expense in list

### Golden Test Fixtures (from research.md)

1. **Even split, percent tax & tip (USD)**: 2 users, 3 items, tax 8.875%, tip 18%, precision 0.01
2. **Custom shares, absolute tip (USD)**: $10 tip, remainder to payer
3. **VND no decimals**: precision 1, integer formatting, consistent remainder
4. **Discount before tax**: 20% discount reduces tax base
5. **Unassigned item**: Save blocked, banner shows item
6. **Extreme percentage warning**: Tip 100%, confirm-on-save

## Related Documentation

- **Feature spec**: `specs/002-itemized-splitter/spec.md` - User stories and requirements
- **Implementation plan**: `specs/002-itemized-splitter/plan.md` - Technical architecture
- **Research decisions**: `specs/002-itemized-splitter/research.md` - Technical design choices
- **Data models**: `specs/002-itemized-splitter/data-model.md` - Entity definitions
- **API contracts**: `specs/002-itemized-splitter/contracts/` - JSON schemas for Firestore
- **Developer guide**: `specs/002-itemized-splitter/quickstart.md` - Onboarding and common tasks
- **Tasks**: `specs/002-itemized-splitter/tasks.md` - Implementation task breakdown (136 tasks)
- **Changelog**: `specs/002-itemized-splitter/CHANGELOG.md` - Development log

## Future Improvements

**MVP+ Enhancements**:
- Dynamic participant management (add/remove people beyond fixed 6)
- More currencies (EUR, GBP, JPY, etc.) via ISO 4217
- Receipt OCR (camera + ML to parse line items automatically)
- Drafts/autosave (resume incomplete expense later)
- Multi-receipt merging (combine multiple receipts into one expense)
- Duplicate expense (copy structure, clear prices for next meal)
- Export itemized breakdowns (PDF, CSV for expense reports)
- Currency conversion within receipt (handle mixed-currency items)

**Advanced Features**:
- Different tax rates per item category (e.g., food vs alcohol)
- Complex service charges (progressive tiers, excludes certain items)
- Group payment (multiple payers split payment, not just one payer)
- Itemized expense templates (save common restaurant orders)
- Receipt photo attachment (for records, not parsing)

## Migration Notes

### Breaking Changes

**None** - This feature is fully backward compatible:
- Existing equal/weighted expenses continue to work unchanged
- New optional fields on Expense entity default to null
- Settlement calculator handles both old and new expense types
- No database migration required

### Migration Steps

```bash
# Update dependencies (no new packages)
flutter pub get

# Run tests to verify no regressions
flutter test

# Build and deploy
flutter build web --base-href /expense_tracker/
```

### Firestore Backward Compatibility

**Strategy** (from research.md):
- All itemized fields are optional (`items`, `extras`, `allocation`, `participantAmounts`, `participantBreakdown`)
- Existing expenses without these fields deserialize correctly (fields are null)
- Runtime discrimination: `if (splitType == SplitType.itemized && participantAmounts != null)`
- No re-indexing or backfilling required

**Example deserialization**:
```dart
// Old expense (before this feature)
{
  "id": "exp_123",
  "splitType": "equal",
  "amount": "100.00",
  "participants": {"tai": 1, "khiet": 1}
}
// Deserializes as: Expense with items=null, participantAmounts=null (works fine)

// New expense (after this feature)
{
  "id": "exp_456",
  "splitType": "itemized",
  "amount": "100.00",
  "items": [...],
  "participantAmounts": {"tai": "55.00", "khiet": "45.00"}
}
// Deserializes as: Expense with items, participantAmounts populated
```

### Rollback Plan

If critical issue found post-deployment:
1. Hide "Itemized" button in AddExpensePage (prevents new itemized expenses)
2. Existing itemized expenses continue to work (read-only)
3. Settlement calculator still handles them correctly
4. Fix issue and re-enable button

No data loss or corruption risk because:
- Itemized expenses are just an extension (not a separate system)
- Settlement logic has fallback to `calculateShares()` if `participantAmounts` missing
- All data persisted in standard Firestore documents
