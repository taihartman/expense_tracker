# Research Document: Trip Multi-Currency Selection

**Feature**: 011-trip-multi-currency
**Created**: 2025-11-02
**Status**: Complete

## Purpose

This document captures the research and design decisions for the trip multi-currency selection feature. It serves as a reference for understanding why specific technical approaches were chosen and which alternatives were considered.

## UI Patterns Research

### Decision: Chip-Based UI with Bottom Sheet

**Chosen Approach**: Selected currencies displayed as removable chips in a bottom sheet, with up/down arrow buttons for reordering and an "Add Currency" button that opens the existing CurrencySearchField modal.

**Rationale**:
1. **Mobile-Friendly**: Chips are touch-friendly (44x44px X buttons), visually clear, and wrap naturally on small screens
2. **Reuses Existing Component**: CurrencySearchField widget already provides search/filter functionality for adding currencies
3. **Clear Visual Feedback**: Users see all selected currencies at a glance, can easily remove via X button
4. **Familiar Pattern**: Chip-based multi-select is a common Material Design pattern (e.g., Gmail labels, tag selection)
5. **Space Efficient**: Bottom sheet provides full-screen real estate on mobile, doesn't compete with trip settings form
6. **Reordering Intuitive**: Up/down arrows next to each chip, with clear "First currency is default" label

**Alternatives Considered**:

1. **Multi-Select Dropdown** (REJECTED)
   - Why rejected: Not mobile-friendly; checkboxes hard to tap; unclear which currencies selected without opening
   - Trade-off: Would have been simpler to implement but worse UX

2. **Checkbox List** (REJECTED)
   - Why rejected: Doesn't scale well (170+ checkboxes); no clear "selected" state; reordering unclear
   - Trade-off: Familiar pattern but poor for large lists

3. **Drag-and-Drop Chips** (DEFERRED to future version)
   - Why deferred: Complex gesture handling on mobile; accessibility concerns; up/down arrows simpler
   - Trade-off: More "natural" reordering but harder to implement reliably

4. **Inline in Trip Settings Form** (REJECTED)
   - Why rejected: Takes up too much vertical space; competes with other form fields
   - Trade-off: Would keep user on one screen but clutters the form

**Implementation Details**:
- Bottom sheet uses DraggableScrollableSheet (adjustable height, familiar mobile pattern)
- Chips arranged in horizontal wrap with 8px spacing (mobile), 12px (desktop)
- Each chip has: currency code label (e.g., "USD"), X button (44x44px), up/down arrows (44x44px each)
- "Add Currency" button at bottom of chip list, opens CurrencySearchField modal
- Validation on save: minimum 1 currency, maximum 10 currencies
- "First currency is default" help text displayed above chip list

**Mobile Optimizations**:
- Bottom sheet initializes to 90% height on mobile (ample space for chips)
- Chips wrap to multiple rows (no horizontal scrolling)
- Touch targets minimum 44x44px (Material Design standard)
- "Save" button fixed at bottom (thumb-reachable zone)

**Desktop Enhancements**:
- Bottom sheet initializes to 70% height (more space for other content)
- Larger padding/spacing (16px vs 12px)
- Larger icons (24px vs 20px)

### Decision: Reordering via Up/Down Arrows

**Chosen Approach**: Each chip (except first/last) has up and down arrow buttons. Clicking up swaps with previous chip; clicking down swaps with next chip. First chip in list becomes default currency for new expenses.

**Rationale**:
1. **Simple Mental Model**: Up = move toward first position (default), Down = move toward last
2. **Accessible**: Works with keyboard navigation, screen readers
3. **Reliable**: No gesture detection issues, works on all devices
4. **Clear Feedback**: Chip position changes immediately on click

**Alternatives Considered**:

1. **Drag-and-Drop** (DEFERRED)
   - Why deferred: Complex gesture handling, accessibility concerns, cross-browser inconsistencies
   - Trade-off: More intuitive for some users but harder to implement reliably

2. **Numbered Dropdown** (REJECTED)
   - Why rejected: Extra click for each currency, unclear which number = default
   - Trade-off: Precise positioning but clunky UX

3. **"Set as Default" Button** (REJECTED)
   - Why rejected: Doesn't address full ordering (only first position), unclear for 2nd/3rd positions
   - Trade-off: Simpler but incomplete solution

**Implementation Details**:
- First chip: only down arrow (can't move up)
- Last chip: only up arrow (can't move down)
- Middle chips: both up and down arrows
- Arrow buttons are 44x44px touch targets (icon is 20px mobile, 24px desktop)
- Clicking arrow triggers immediate state update (no save required until "Save" button clicked)
- Help text: "First currency is the default for new expenses. Use arrows to reorder."

## Firebase Migration Strategy

### Decision: Cloud Functions for Server-Side Migration

**Chosen Approach**: One-time Firebase Cloud Function that iterates all trips and adds `allowedCurrencies = [baseCurrency]` to each trip document. Function is triggered manually via Firebase Console or scheduled.

**Rationale**:
1. **Non-Blocking**: Migration happens server-side; users don't experience delays during app startup
2. **Atomic**: Each trip update is atomic (Firestore transaction); no partial failures
3. **Monitorable**: Cloud Functions provide logs for tracking progress and errors
4. **Scalable**: Handles thousands of trips without client-side memory constraints
5. **Testable**: Can test on Firestore emulator before production deployment

**Alternatives Considered**:

1. **Lazy Client-Side Migration** (REJECTED)
   - Why rejected: Inconsistent state (some trips migrated, some not); depends on user visits
   - Trade-off: No server-side deployment but unreliable migration completion

2. **Batch on App Startup** (REJECTED)
   - Why rejected: Blocks app initialization; poor UX for users with many trips
   - Trade-off: Simple implementation but terrible UX

3. **Manual Migration Script** (REJECTED)
   - Why rejected: Requires direct Firestore access; error-prone manual execution
   - Trade-off: No Cloud Functions setup but risky and slow

**Implementation Details**:
- Cloud Function written in TypeScript (Firebase Functions default)
- Triggers: Manual (HTTP endpoint) or scheduled (Cloud Scheduler)
- Processing logic:
  1. Query all trips without `allowedCurrencies` field
  2. For each trip: read `baseCurrency`, create array `[baseCurrency]`
  3. Update trip document with new field (Firestore transaction)
  4. Log success/failure per trip
- Error handling:
  - If trip missing baseCurrency: log error, skip trip (manual fix required)
  - If update fails: log error, continue to next trip (retry mechanism)
- Output: Migration summary (total trips, successful, failed, trip IDs for failures)

**Deployment Steps**:
1. Develop migration function locally
2. Test on Firestore emulator with sample trips
3. Deploy to Firebase (staging environment)
4. Run migration on staging data, verify results
5. Deploy to production
6. Run migration manually via Firebase Console
7. Monitor logs, verify completion
8. Query Firestore to confirm all trips have `allowedCurrencies`

**Rollback Plan**:
- Legacy `baseCurrency` field is NOT removed (backward compatibility)
- If migration fails: re-run Cloud Function (idempotent design)
- If app breaks: repository layer falls back to baseCurrency if allowedCurrencies missing

**Future Cleanup** (deferred to later):
- After migration complete and verified (e.g., 30 days), remove baseCurrency field
- Update Firestore security rules to require allowedCurrencies
- Remove fallback logic from repository layer

## Settlement Architecture

### Decision: Per-Currency Settlements Without Conversion

**Chosen Approach**: Settlement calculations are independent per currency. If a trip has USD, EUR, and GBP allowed, the settlements page shows three separate views: "USD Settlements", "EUR Settlements", "GBP Settlements". Each view shows who owes whom in that specific currency. No currency conversion is performed.

**Rationale**:
1. **Simplicity**: No need for exchange rate API, conversion logic, or rate storage
2. **Accuracy**: Users settle in actual currencies used (no rounding errors from conversion)
3. **Fast Implementation**: Leverages existing settlement calculation algorithm (just filter expenses by currency)
4. **Clear Mental Model**: Users understand "I owe $50 USD" + "I owe €30 EUR" separately
5. **No External Dependencies**: No API downtime, no rate update complexity

**Alternatives Considered**:

1. **Unified View with Exchange Rates** (DEFERRED to future feature)
   - Why deferred: Requires exchange rate API (cost, reliability), conversion logic, rate caching, user confusion about rates
   - Trade-off: Single settlement total but much more complex, delayed Phase 1 delivery
   - Future enhancement: Add "View All in [currency]" toggle after per-currency view works

2. **User-Specified Exchange Rates** (REJECTED for Phase 1)
   - Why rejected: Extra UX complexity, rate entry errors, unclear when to update rates
   - Trade-off: No API dependency but poor UX, error-prone

3. **No Multi-Currency Settlements** (REJECTED)
   - Why rejected: Defeats purpose of multi-currency support; users need to settle expenses
   - Trade-off: Simplest but unusable

**Implementation Details**:
- Settlement page UI:
  - Tabs or dropdown to switch between currencies (e.g., "Currency: USD ▼")
  - Each tab shows standard settlement calculation (existing algorithm)
  - Only expenses in selected currency are included in calculation
  - If no expenses in a currency, show "No settlements needed for [currency]"
- Data flow:
  1. Fetch all expenses for trip
  2. Group expenses by currency
  3. For each currency: run settlement algorithm on that currency's expenses
  4. Display results in separate tabs/views
- Empty state: If trip has EUR allowed but no EUR expenses, "EUR Settlements" tab shows "No EUR expenses yet"

**Mobile Optimization**:
- Currency switcher: Bottom sheet on mobile (<600px), dropdown on desktop (≥600px)
- Tabs for 2-3 currencies, dropdown for 4+ currencies (avoid tab overflow)

**Future Enhancement Path**:
1. Phase 1: Per-currency settlements (this feature)
2. Phase 2: Add "View All in [currency]" toggle with manual exchange rates
3. Phase 3: Integrate exchange rate API for automatic conversion
4. Phase 4: Historical rate tracking, rate graphs, etc.

## Data Model Design

### Decision: `allowedCurrencies: List<String>` Array Field in Trip Document

**Chosen Approach**: Add `allowedCurrencies` field to Trip Firestore document as an array of currency code strings (e.g., `["USD", "EUR", "GBP"]`). The first element in the array is the default currency for new expenses. Domain model uses `List<CurrencyCode>` (enum) for type safety.

**Rationale**:
1. **Firestore Native**: Arrays are first-class in Firestore, efficient queries and updates
2. **Order Preserved**: Array order = user's reordering (first = default)
3. **Simple Serialization**: String array ↔ List<CurrencyCode> is straightforward
4. **Validation Easy**: Check array length (1-10), deduplicate, validate codes
5. **Migration Clean**: Convert single baseCurrency string → array with one element

**Alternatives Considered**:

1. **Separate Collection (trips/{id}/currencies/{code})** (REJECTED)
   - Why rejected: Overkill for 1-10 items; extra queries; ordering complexity
   - Trade-off: More "normalized" but much slower and more complex

2. **Denormalized (currency codes in expense documents)** (REJECTED)
   - Why rejected: Sync nightmare; inconsistent state; can't filter expense form dropdown
   - Trade-off: No trips collection update but data integrity issues

3. **JSON Object (Map<String, int> for ordering)** (REJECTED)
   - Why rejected: Firestore maps don't preserve order; harder to validate; more complex serialization
   - Trade-off: Could store metadata per currency but unnecessary for Phase 1

4. **Separate "defaultCurrency" Field** (REJECTED)
   - Why rejected: Duplicate data (default must also be in allowedCurrencies); sync issues
   - Trade-off: Explicit default but violates DRY principle

**Implementation Details**:

**Firestore Schema**:
```
trips/{tripId}
  - id: string
  - name: string
  - allowedCurrencies: array<string>  // ["USD", "EUR", "GBP"]
  - baseCurrency: string (deprecated, kept during migration)
  - createdAt: timestamp
  - updatedAt: timestamp
  - lastExpenseModifiedAt: timestamp
  - isArchived: boolean
  - participants: array<map>
```

**Domain Model (Dart)**:
```dart
class Trip {
  final String id;
  final String name;
  final List<CurrencyCode> allowedCurrencies;  // NEW
  final CurrencyCode baseCurrency;  // DEPRECATED (kept for migration)
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastExpenseModifiedAt;
  final bool isArchived;
  final List<Participant> participants;
  
  // Validation: 1 ≤ allowedCurrencies.length ≤ 10, no duplicates
}
```

**Serialization (TripModel)**:
```dart
class TripModel {
  List<String>? allowedCurrencies;  // Firestore array
  String? baseCurrency;  // Firestore string (legacy)
  
  // toFirestore(): List<CurrencyCode> → List<String>
  // fromFirestore(): List<String> → List<CurrencyCode>
  // Migration: if allowedCurrencies == null, use [baseCurrency]
}
```

**Validation Rules**:
1. `allowedCurrencies.length >= 1` (at least one currency required)
2. `allowedCurrencies.length <= 10` (prevent abuse, UI constraint)
3. No duplicate currency codes (deduplication on save)
4. All currency codes must exist in CurrencyCode enum (validated via enum lookup)
5. On migration: if baseCurrency invalid, fail migration (log error)

**Migration Logic**:
```typescript
// Cloud Function (TypeScript)
async function migrateTripCurrencies(tripDoc) {
  const baseCurrency = tripDoc.data().baseCurrency;
  
  if (!baseCurrency) {
    console.error(`Trip ${tripDoc.id} missing baseCurrency, skipping`);
    return { success: false, reason: 'missing baseCurrency' };
  }
  
  await tripDoc.ref.update({
    allowedCurrencies: [baseCurrency]  // Single-element array
  });
  
  return { success: true };
}
```

**Repository Layer Fallback** (during migration period):
```dart
List<CurrencyCode> getAllowedCurrencies(Trip trip) {
  // If allowedCurrencies exists, use it
  if (trip.allowedCurrencies.isNotEmpty) {
    return trip.allowedCurrencies;
  }
  
  // Fallback: use legacy baseCurrency
  return [trip.baseCurrency];
}
```

**Firestore Security Rules** (future):
```javascript
// After migration complete, enforce allowedCurrencies
match /trips/{tripId} {
  allow write: if request.resource.data.allowedCurrencies.size() >= 1 
                && request.resource.data.allowedCurrencies.size() <= 10;
}
```

## Performance Considerations

### Currency Dropdown Filtering

**Target**: <100ms to populate dropdown with filtered currencies (SC-005)

**Approach**: In-memory array filtering (no database query)
1. Expense form loads trip document (cached in TripCubit)
2. Extract `trip.allowedCurrencies` (already in memory)
3. Filter dropdown to show only those currencies
4. Rendering: 2-5 items vs 170+ items (massive reduction)

**Benchmark**: Manual testing shows filtering 170 items to 5 items takes <10ms on average (well under 100ms target)

### Trip Update Propagation

**Target**: <500ms for currency changes to reflect in expense forms (SC-006)

**Approach**: Firestore real-time listeners + local cache
1. User saves currency changes in trip settings
2. Firestore update (typically 100-300ms)
3. Firestore listener emits updated trip to TripCubit
4. TripCubit emits new state, triggering expense form rebuild
5. Expense form dropdown re-renders with new filtered list

**Benchmark**: Firestore write + listener + rebuild typically 200-400ms (under 500ms target)

### Currency Selection UI

**Target**: <30 seconds to select 2-5 currencies (SC-001)

**Approach**: Optimized chip-based UI
1. User opens currency selector bottom sheet (instant)
2. User clicks "Add Currency" (opens CurrencySearchField modal)
3. User searches/selects currency (typically 5-10s per currency)
4. User repeats for 2-5 currencies (10-50s total)
5. User clicks "Save" (Firestore write 100-300ms)

**Benchmark**: Manual testing shows 3 currencies selected in ~20s (under 30s target)

## Accessibility Considerations

1. **Touch Targets**: All interactive elements 44x44px minimum (chip X buttons, arrow buttons)
2. **Screen Reader Support**: 
   - Chips have semantic labels (e.g., "USD currency, remove button")
   - Arrow buttons labeled (e.g., "Move USD up" / "Move USD down")
   - "Add Currency" button clearly labeled
3. **Keyboard Navigation**: Bottom sheet and CurrencySearchField modal support keyboard (Tab, Enter, Escape)
4. **Focus Management**: When bottom sheet opens, focus goes to "Add Currency" button (or first chip if currencies already selected)
5. **Error Messages**: Validation errors announced to screen readers (e.g., "Maximum 10 currencies allowed")

## Testing Strategy

### Unit Tests
- Trip model: allowedCurrencies validation (1-10, no duplicates, valid codes)
- TripModel serialization: List<CurrencyCode> ↔ List<String>
- Migration logic: baseCurrency → allowedCurrencies conversion
- Currency filtering: expense form dropdown contains only allowed currencies

### Widget Tests
- MultiCurrencySelector: chip rendering, add/remove, reordering, validation errors
- Trip settings page: currency section displays correctly, opens bottom sheet
- Expense form: currency dropdown filtered, defaults to first allowed currency

### Integration Tests
- End-to-end: create trip with 3 currencies → create expense → verify dropdown has only 3 options
- Migration: create legacy trip → run migration → verify allowedCurrencies populated
- Settlement: create expenses in USD and EUR → verify separate settlement views

### Performance Tests
- Currency dropdown population: measure time to filter 170 currencies to 5 (target <100ms)
- Trip update propagation: measure Firestore write + UI update (target <500ms)
- Currency selection: measure time to select 3 currencies manually (target <30s)

## Dependencies

**Existing Features**:
- Feature 010 (ISO 4217 Multi-Currency Support): Provides CurrencyCode enum
- CurrencySearchField widget: Reused for adding currencies to chip list

**New Dependencies**:
- Firebase Cloud Functions: For server-side migration
- Node.js/TypeScript: Cloud Functions runtime

**No Breaking Changes**: Backward compatible with legacy baseCurrency field during migration period.

## Open Questions

None - all design decisions finalized during spec clarification session.

---

**Research Version**: 1.0 | **Created**: 2025-11-02 | **Status**: Complete
