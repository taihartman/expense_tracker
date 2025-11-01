# Feature Specification: ISO 4217 Multi-Currency Support

**Feature Branch**: `010-iso-4217-currencies`
**Created**: 2025-01-30
**Status**: Draft
**Input**: User description: "Add support for all ISO 4217 world currencies (170+ currencies) to replace the current 2-currency system. Users should be able to select any world currency when creating trips and expenses, with proper currency symbols, decimal place handling (0-3 decimals), and searchable currency selection UI. Current implementation uses hardcoded enum with USD and VND only - expand to full ISO 4217 standard using code generation approach to maintain type safety while supporting all currencies. Include proper formatting for thousand separators, currency-specific decimal places (JPY=0, USD=2, KWD=3), and localized display names."

## User Scenarios & Testing

### User Story 1 - Select Local Currency for Trip (Priority: P1)

A user creating a new trip for travel in a country using a currency not currently supported (e.g., British Pounds, Japanese Yen, Thai Baht) needs to select their destination currency as the trip's base currency. Currently, they are forced to choose between USD or VND, which creates confusion and makes expense tracking inaccurate for their use case.

**Why this priority**: This is the core value proposition. Without the ability to select the correct currency, users traveling to most countries cannot use the app effectively. This directly impacts user acquisition and retention.

**Independent Test**: Can be fully tested by creating a new trip and verifying that any ISO 4217 currency can be selected from the currency picker, and that the selected currency is saved and displayed correctly on the trip details page.

**Acceptance Scenarios**:

1. **Given** a user is creating a new trip, **When** they click the currency selection field, **Then** they see a searchable list of 170+ world currencies with currency codes and names
2. **Given** a user has selected "GBP - British Pound Sterling" as trip currency, **When** they save the trip, **Then** the trip details page shows "GBP" or "£" as the currency
3. **Given** a user searches for "euro" in the currency picker, **When** the search filters results, **Then** they see "EUR - Euro" in the filtered results
4. **Given** a user selects "JPY - Japanese Yen", **When** they view expense entry fields, **Then** amount fields do not show decimal places (JPY has 0 decimal places)

---

### User Story 2 - Enter Expenses with Correct Currency Formatting (Priority: P1)

A user adding an expense in their selected currency needs the system to automatically format amounts with the correct decimal precision and thousands separators. For example, entering "1000000" in Japanese Yen should display as "1,000,000" (no decimals), while entering "1234.5" in US Dollars should display as "1,234.50" (2 decimals).

**Why this priority**: Proper currency formatting is essential for user trust and data accuracy. Incorrect decimal handling can lead to errors of 100x or more (e.g., entering 100 JPY but system treating it as 100.00 JPY).

**Independent Test**: Can be tested by creating expenses in currencies with different decimal place requirements (0, 2, and 3 decimals) and verifying the input field formats and validates amounts correctly for each currency type.

**Acceptance Scenarios**:

1. **Given** a user is entering an expense in USD (2 decimals), **When** they type "1234.5", **Then** the field displays "1,234.50"
2. **Given** a user is entering an expense in JPY (0 decimals), **When** they type "1000000", **Then** the field displays "1,000,000" and prevents decimal entry
3. **Given** a user is entering an expense in KWD (3 decimals), **When** they type "1234.567", **Then** the field displays "1,234.567"
4. **Given** a user views a list of expenses in different currencies, **When** amounts are displayed, **Then** each amount shows the correct currency symbol and decimal precision

---

### User Story 3 - Efficiently Find Currency from Large List (Priority: P2)

A user needs to find their desired currency from a list of 170+ options without scrolling through an overwhelming dropdown. They should be able to search by currency code (e.g., "EUR"), currency name (e.g., "Euro"), or country name (e.g., "France").

**Why this priority**: While essential for usability, the search functionality is a UX enhancement that can be delivered after basic currency selection works. A simple alphabetical list would be functional but not optimal.

**Independent Test**: Can be tested independently by implementing the currency search component and verifying that searching for various terms (codes, names, partial matches) returns relevant currency options within 5 seconds.

**Acceptance Scenarios**:

1. **Given** a user opens the currency picker, **When** they type "EUR" in the search field, **Then** "EUR - Euro" appears at the top of results within 1 second
2. **Given** a user opens the currency picker, **When** they type "pound", **Then** results include "GBP - British Pound Sterling" and "EGP - Egyptian Pound"
3. **Given** a user opens the currency picker with search active, **When** they clear the search, **Then** the full alphabetical list of all currencies is restored
4. **Given** a user types a search term with no matches (e.g., "xyz"), **When** the search completes, **Then** a "No currencies found" message is displayed

---

### User Story 4 - Maintain Compatibility with Existing Data (Priority: P1)

Users with existing trips and expenses using USD or VND need their data to continue working without any migration, errors, or data loss after the currency system is expanded.

**Why this priority**: Data integrity is critical. Breaking existing user data would be catastrophic for user trust and could result in loss of historical expense records.

**Independent Test**: Can be tested by loading trips and expenses created before the currency expansion and verifying they display correctly with proper currency formatting and symbols.

**Acceptance Scenarios**:

1. **Given** a trip was created with USD before the expansion, **When** the user views the trip, **Then** it still shows USD as the currency and all expenses display correctly
2. **Given** an expense was created with VND before the expansion, **When** the user views the expense, **Then** it displays with the VND symbol (₫) and 0 decimal places
3. **Given** settlements were calculated for a USD trip before the expansion, **When** the user views settlements, **Then** all amounts show correct USD formatting with 2 decimals

---

### Edge Cases

- What happens when a user selects a currency with 3 decimal places (BHD, KWD, OMR, TND, JOD) and the system previously only handled 0 or 2 decimals?
- How does the system handle obsolete or historical currencies that are in ISO 4217 but no longer in active circulation?
- What happens if currency metadata (symbols, decimal places) is missing or incorrect for a specific currency code?
- How does the currency picker perform when rendering 170+ items on mobile devices with limited processing power?
- What happens when a user's search query matches both currency codes and currency names (e.g., "IN" matches both "INR - Indian Rupee" and currencies with "IN" in the name)?

## Requirements

### Functional Requirements

- **FR-001**: System MUST support selection of all active ISO 4217 currency codes (minimum 170 currencies)
- **FR-002**: System MUST display the correct currency symbol for each currency (e.g., $, €, £, ¥, ₫)
- **FR-003**: System MUST handle varying decimal place requirements: 0 decimals (JPY, KRW, VND), 2 decimals (USD, EUR, GBP), and 3 decimals (BHD, KWD, OMR, TND, JOD)
- **FR-004**: System MUST format currency amounts with thousands separators (e.g., 1,000,000.00)
- **FR-005**: System MUST provide a searchable currency selection interface that allows filtering by currency code or currency name
- **FR-006**: System MUST display localized currency names (e.g., "United States Dollar" for USD)
- **FR-007**: System MUST maintain backward compatibility with existing trips and expenses created with USD or VND
- **FR-008**: System MUST prevent users from entering more decimal places than allowed for the selected currency (e.g., prevent "100.50" for JPY)
- **FR-009**: System MUST store currency information in a format that allows for future updates to currency metadata without requiring data migration
- **FR-010**: Currency selection MUST be available when creating trips, creating expenses, and editing expenses

### Key Entities

- **Currency**: Represents a world currency conforming to ISO 4217 standard
  - Currency Code: 3-letter alphabetic code (e.g., USD, EUR, JPY)
  - Display Name: Full name of currency (e.g., "United States Dollar")
  - Symbol: Currency symbol for display (e.g., $, €, ¥)
  - Decimal Places: Number of minor units (0, 2, or 3)
  - Active Status: Whether currency is currently in active circulation

## Success Criteria

### Measurable Outcomes

- **SC-001**: Users can select any of the 170+ active ISO 4217 currencies when creating or editing trips
- **SC-002**: Currency amounts display with correct decimal precision (0, 2, or 3 decimals) based on the currency's ISO 4217 specification
- **SC-003**: Users can find their desired currency via search functionality in under 5 seconds
- **SC-004**: 100% of existing trips and expenses continue to function correctly without data migration or errors
- **SC-005**: Currency amounts display with thousands separators and proper decimal formatting in all views (trip list, expense list, expense details, settlements)
- **SC-006**: System correctly handles input validation for currencies with 0 decimal places (prevents decimal entry) and 3 decimal places (allows up to 3 digits after decimal)

## Assumptions

1. **Exchange Rate Conversion**: Currency conversion between different currencies is out of scope for this feature. Each expense is stored and displayed in its original currency. Multi-currency settlements will require future enhancement.

2. **Currency Display Names**: English display names are sufficient for initial release. Multi-language support for currency names is a future enhancement.

3. **Currency Data Updates**: Currency metadata (symbols, decimal places, active status) is relatively static and does not require real-time updates. Changes to ISO 4217 standard are infrequent.

4. **Supported Decimal Places**: The system will support 0, 2, and 3 decimal places, covering all active currencies. Historical currencies with 4+ decimal places are out of scope.

5. **Currency Symbols**: For currencies without widely-recognized Unicode symbols, the 3-letter currency code will be displayed as a fallback (e.g., "AED" for UAE Dirham if symbol is unavailable).

6. **Data Storage**: Currency codes will continue to be stored as strings (e.g., "USD", "EUR") in the database, maintaining backward compatibility with existing data.

7. **Mobile Performance**: The currency picker will be optimized for mobile devices, using virtualization or pagination if needed to handle 170+ items efficiently.

## Dependencies

1. **Existing Trip Management**: This feature extends the existing trip creation and editing functionality to support expanded currency selection.

2. **Existing Expense Management**: This feature extends expense creation and editing to support all currencies with proper formatting.

3. **ISO 4217 Standard**: This feature relies on the ISO 4217 currency standard for currency codes, names, and decimal place specifications. Updates to this standard may require corresponding updates to the currency data.

