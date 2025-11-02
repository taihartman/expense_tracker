# Feature Specification: Trip Multi-Currency Selection

**Feature Branch**: `011-trip-multi-currency`
**Created**: 2025-11-02
**Status**: Draft
**Input**: User description: "In the trip settings we should allow the user to select multiple currencies that they want to use in the trip. once selected these should be the currencies presented to the user when creating and editing all types of expenses."

## Clarifications

### Session 2025-11-02

- Q: What UI mechanism should be used for reordering currencies if drag-and-drop is out of scope? → A: Up/down arrow buttons next to each currency in the list
- Q: When should the migration from baseCurrency to allowedCurrencies execute? → A: Firebase Cloud Functions
- Q: When a user changes the primary currency (by reordering), do existing settlement calculations need to be recalculated immediately? → A: No recalculation needed - settlements will be shown per currency (separate settlement screen for each allowed currency), with unified conversion view coming in a future feature
- Q: What UI pattern should be used for selecting multiple currencies in trip settings? → A: Chip-based UI (selected currencies shown as chips with X to remove, plus "Add Currency" button with search). Entire currency selection feature contained in a bottom sheet

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Select Multiple Trip Currencies (Priority: P1)

A trip organizer is planning a European vacation visiting multiple countries (France, Switzerland, UK). They want to pre-select EUR, CHF, and GBP as their trip currencies so that when they or other participants add expenses, they only see these three relevant currencies instead of all 170+ options.

**Why this priority**: Core value proposition - reduces cognitive load during expense entry by filtering to only relevant currencies for the trip.

**Independent Test**: Can be fully tested by creating a trip, selecting 2-3 currencies in trip settings, and verifying only those currencies appear in the expense form currency dropdown. Delivers immediate value by simplifying expense creation.

**Acceptance Scenarios**:

1. **Given** I am creating a new trip, **When** I reach the currency selection step, **Then** I see a bottom sheet with chip-based interface showing selected currencies and an "Add Currency" button with search functionality
2. **Given** I have selected USD and EUR as trip currencies, **When** I save the trip, **Then** both currencies are stored and displayed in trip settings
3. **Given** I am editing an existing trip, **When** I navigate to currency settings, **Then** I can add or remove currencies from the allowed list
4. **Given** I try to remove all currencies from a trip, **When** I attempt to save, **Then** I see a validation error requiring at least one currency
5. **Given** I have a trip with 3 currencies selected, **When** I view trip details, **Then** I see all selected currencies clearly displayed

---

### User Story 2 - Filtered Expense Currency Selection (Priority: P1)

When a trip participant creates or edits an expense, they see only the currencies that were pre-selected for the trip, making it faster and easier to choose the correct currency without scrolling through 170+ options.

**Why this priority**: Direct user impact - every expense creation becomes faster and less error-prone. This is the primary benefit users will experience from the feature.

**Independent Test**: Create a trip with 2 specific currencies (e.g., USD and JPY), then create an expense and verify the currency dropdown shows only those 2 currencies. Can be tested independently even if trip creation UI is simplified.

**Acceptance Scenarios**:

1. **Given** a trip has USD, EUR, and GBP as allowed currencies, **When** I create a new expense, **Then** the currency dropdown shows only USD, EUR, and GBP
2. **Given** a trip has only JPY as the allowed currency, **When** I create an expense, **Then** JPY is pre-selected and I cannot change it
3. **Given** I am editing an existing expense with a currency not in the current allowed list, **When** I view the expense form, **Then** I can still see and keep the original currency (backward compatibility)
4. **Given** a trip has 5 allowed currencies, **When** I create an itemized expense, **Then** line item currencies are also filtered to the allowed list
5. **Given** a trip has allowed currencies defined, **When** I use the quick-add expense feature, **Then** it defaults to the first allowed currency

---

### User Story 3 - Per-Currency Settlement Views (Priority: P2)

When a trip has multiple allowed currencies, the system shows separate settlement screens for each currency. Users can view who owes whom in USD on one screen, EUR on another screen, etc. This avoids currency conversion complexity while still providing clear settlement information per currency.

**Why this priority**: Settlements are calculated independently per currency, avoiding the need for exchange rates. Can be implemented after core multi-currency selection works. Future enhancement will add unified conversion view.

**Independent Test**: Create a trip with USD and EUR as allowed currencies. Add expenses in both currencies. Verify settlements page shows separate settlement calculations for USD expenses and EUR expenses (no conversion between currencies).

**Acceptance Scenarios**:

1. **Given** a trip has USD and EUR as allowed currencies with expenses in both, **When** I view settlements, **Then** I see separate settlement screens for USD and EUR
2. **Given** a trip has expenses in USD only (even though EUR is also allowed), **When** I view settlements, **Then** I see USD settlement screen and EUR shows no settlements needed
3. **Given** a trip created before this feature (single baseCurrency), **When** viewed after migration, **Then** settlements work as before with the single currency

---

### User Story 4 - Migrate Existing Trips (Priority: P2)

Existing trips with a single baseCurrency field need to be automatically migrated to the new multi-currency system without any user action or data loss.

**Why this priority**: Must work for backward compatibility but doesn't provide new user value. Can be implemented and tested after the core multi-currency selection works.

**Independent Test**: Create a trip using the old single-currency system, run migration, then verify the trip has one allowed currency matching the old baseCurrency. All expense functionality should work unchanged.

**Acceptance Scenarios**:

1. **Given** an existing trip with baseCurrency = "USD", **When** migration runs, **Then** trip has allowedCurrencies = ["USD"] and primaryCurrency = "USD"
2. **Given** a trip with 10 existing USD expenses and baseCurrency = "USD", **When** after migration I create a new expense, **Then** I can only select USD (matching legacy behavior)
3. **Given** 50 existing trips in the database, **When** migration completes, **Then** all trips have at least one allowed currency and no data is lost

---

### Edge Cases

- **What happens when** a user tries to select more than 10 currencies? **System enforces** a maximum limit of 10 currencies per trip to prevent abuse and maintain UI usability
- **What happens when** an expense exists with currency "VND" but VND is removed from allowed currencies? **System preserves** the VND currency on that expense for data integrity but doesn't show VND in new expense dropdowns
- **What happens when** a user deletes the primary currency from the allowed list? **System prevents** deletion of the last currency and shows validation error
- **What happens when** two currencies have the same code (data corruption)? **System deduplicates** during migration and save operations
- **What happens when** a user accesses a trip before Cloud Functions migration completes? **System treats** trip as having baseCurrency as the single allowed currency until migration completes server-side

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST allow users to select multiple currencies when creating a trip
- **FR-002**: System MUST allow users to add or remove currencies from a trip's allowed currency list
- **FR-003**: System MUST require at least one currency to be selected for every trip
- **FR-004**: System MUST enforce a maximum of 10 currencies per trip
- **FR-005**: System MUST calculate settlements independently for each allowed currency (no cross-currency conversion)
- **FR-006**: System MUST filter expense form currency dropdowns to show only the trip's allowed currencies
- **FR-007**: System MUST preserve original currency on existing expenses even if removed from allowed list
- **FR-008**: System MUST automatically migrate existing trips from single baseCurrency to allowedCurrencies list using Firebase Cloud Functions
- **FR-009**: System MUST pre-select the first allowed currency as default when creating a new expense
- **FR-010**: System MUST display all selected currencies in trip settings and trip details views
- **FR-011**: System MUST validate currency selection changes before saving
- **FR-012**: Users MUST be able to reorder allowed currencies using up/down arrow buttons; the first currency in the list becomes the default currency for new expenses (per FR-009)
- **FR-013**: System MUST persist allowed currencies to Firestore as an array of currency codes
- **FR-014**: System MUST handle legacy trips with baseCurrency field gracefully during transition period
- **FR-015**: System MUST provide clear visual feedback when currencies are added or removed (chip add/remove animations with 200ms transitions, success toast on save)
- **FR-016**: System MUST present currency selection interface in a bottom sheet with chip-based UI showing selected currencies, up/down arrow buttons for reordering, and "Add Currency" button with search

### Key Entities

- **Trip**: Extended to include multiple allowed currencies
  - `allowedCurrencies`: List of CurrencyCode values (1-10 currencies)
  - First currency in list serves as default for new expenses
  - Legacy field `baseCurrency` retained during migration period for backward compatibility

- **Expense**: Existing entity, no changes required
  - `currency`: Single CurrencyCode value (unchanged)
  - Validation updated to check currency is in trip's allowed list (for new expenses)

- **Migration Record**: Tracks Cloud Functions migration status
  - Migration version identifier
  - Completion timestamp
  - Affected trip count
  - Execution log for debugging

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can select 2-5 currencies for a trip and complete the selection process in under 30 seconds
- **SC-002**: Expense creation shows only trip-allowed currencies, reducing dropdown options from 170+ to user's selected 2-5 currencies
- **SC-003**: 100% of existing trips are migrated automatically without data loss or user intervention required
- **SC-004**: Settlement calculations work independently for each currency without cross-currency conversion, maintaining calculation accuracy per currency
- **SC-005**: Users creating expenses see filtered currency list immediately with no performance degradation (dropdown loads in under 100ms)
- **SC-006**: Trip currency editing allows adding/removing currencies with changes reflected across all expense forms within 500ms

## Assumptions *(optional)*

- Users typically travel to 1-5 countries per trip, so 10 currency limit is generous
- Most trips will use 1-3 currencies (matches common travel patterns: domestic + 1-2 foreign)
- Currency selection during trip creation is acceptable friction (one-time setup cost)
- Existing CurrencySearchField widget from feature 010 can be adapted for multi-select
- Settlement calculations will be per-currency without conversion (unified conversion view is future enhancement)
- Firestore supports arrays of strings (currency codes) efficiently
- Migration will run via Firebase Cloud Functions to handle all existing trips server-side
- Users prefer filtered lists over search when list size is small (2-10 items vs 170+)

## Out of Scope *(optional)*

- Unified settlement view with cross-currency conversion (future feature - this version shows separate settlements per currency)
- Real-time currency exchange rates (future feature)
- Suggesting currencies based on trip location/name (future enhancement)
- Per-user default currency preferences
- Currency analytics (which currencies used most frequently)
- Bulk currency selection (e.g., "All European currencies")
- Currency reordering via drag-and-drop (first version uses up/down arrow buttons)

## Dependencies *(optional)*

- **Feature 010 (ISO 4217 Multi-Currency Support)**: Provides CurrencyCode enum with 170+ currencies
- **CurrencySearchField Widget**: Used within bottom sheet for adding currencies to chip-based selection UI
- **Trip Model**: Requires schema update to support multiple currencies
- **TripModel Serialization**: Requires update to serialize/deserialize currency lists
- **Firebase Cloud Functions**: Required to execute server-side migration of existing trips from baseCurrency → allowedCurrencies
- **Settlement Calculations**: Need to calculate independently per currency (no conversion logic required)

## Open Questions *(optional)*

None - all design decisions have been made based on brainstorming session with user.
