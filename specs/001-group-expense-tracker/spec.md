# Feature Specification: Group Expense Tracker for Trips

**Feature Branch**: `001-group-expense-tracker`
**Created**: 2025-10-21
**Status**: Draft
**Input**: User description: "Group expense tracker for trips with multi-currency support and settlement calculations"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Record Trip Expenses (Priority: P1)

As a trip organizer, I need to quickly record expenses during a trip so that everyone knows who paid for what and how much they owe.

**Why this priority**: Core functionality - without expense recording, the entire application has no purpose. This is the foundational capability that enables all other features.

**Independent Test**: Can be fully tested by creating a trip, adding 5-10 expenses with different payers and amounts, and verifying all expenses are stored and displayed correctly. Delivers immediate value as a digital expense log.

**Acceptance Scenarios**:

1. **Given** I am viewing a trip, **When** I record an expense with payer, amount, currency, date, and description, **Then** the expense appears in the trip's expense list
2. **Given** I am recording an expense, **When** I specify which participants to split the cost among, **Then** the system calculates each participant's share
3. **Given** I am recording an expense, **When** I choose equal split, **Then** the cost is divided equally among selected participants
4. **Given** I am recording an expense, **When** I choose weighted split with custom weights, **Then** the cost is divided proportionally according to the weights
5. **Given** I have recorded an expense, **When** I view the expense details, **Then** I see payer, amount, currency, date, description, category, and participant shares

---

### User Story 2 - View Settlement Summary (Priority: P1)

As a trip participant, I need to see who owes whom and how much so that we can settle debts after the trip.

**Why this priority**: Primary value proposition - users need to know final settlement amounts. Without this, the app is just an expense log without the key benefit of calculating settlements.

**Independent Test**: Can be fully tested by entering sample expenses with different payers and viewing the settlement summary. Delivers the key value of "who owes whom" calculations.

**Acceptance Scenarios**:

1. **Given** multiple expenses have been recorded, **When** I view the settlement summary, **Then** I see each person's total paid, total owed, and net balance
2. **Given** I view the settlement summary, **When** debts have been netted, **Then** I see the minimal set of transfers needed to settle all debts
3. **Given** I view a settlement transfer, **When** copying to clipboard, **Then** I get formatted text of all transfers for easy sharing
4. **Given** multiple people have paid and owe, **When** the system calculates pairwise netting, **Then** opposite debts cancel out (e.g., if A owes B $10 and B owes A $6, result shows A owes B $4)

---

### User Story 3 - Multi-Currency Support (Priority: P2)

As a trip organizer traveling internationally, I need to record expenses in different currencies so that all spending is accurately tracked regardless of where purchases occur.

**Why this priority**: Essential for international trips but not needed for domestic travel. The app can function for single-currency trips without this feature.

**Independent Test**: Can be fully tested by creating a trip with base currency USD, recording expenses in both USD and VND, entering exchange rates, and verifying all amounts convert correctly to base currency in summaries.

**Acceptance Scenarios**:

1. **Given** I am recording an expense, **When** I select a currency different from the trip's base currency, **Then** the system prompts for or uses an existing exchange rate
2. **Given** I have set an exchange rate for a currency pair, **When** I record an expense in that currency, **Then** the system automatically converts to base currency for settlement calculations
3. **Given** I need to update exchange rates, **When** I enter a new rate for a currency pair and optional date, **Then** the system uses the appropriate rate based on expense dates
4. **Given** an expense is in the base currency, **When** calculating settlements, **Then** no conversion is applied (rate = 1.0)

---

### User Story 4 - Manage Multiple Trips (Priority: P2)

As a frequent traveler, I need to organize expenses by trip so that I can keep different trips' finances separate.

**Why this priority**: Important for users who travel frequently, but a single-trip version would still be valuable. This enables the app to scale beyond one-time use.

**Independent Test**: Can be fully tested by creating 2-3 trips with different names and participants, adding expenses to each, and verifying data isolation between trips.

**Acceptance Scenarios**:

1. **Given** I am using the application, **When** I create a new trip with a name and base currency, **Then** I can select and switch between trips
2. **Given** multiple trips exist, **When** I switch to a different trip, **Then** I see only that trip's expenses, participants, and settlement calculations
3. **Given** I am viewing the trip overview, **When** I look at the trip selector, **Then** I see the trip name and base currency clearly indicated

---

### User Story 5 - Categorize Expenses (Priority: P3)

As a trip organizer, I need to categorize expenses (meals, transport, accommodation, activities) so that I can see spending breakdowns by category.

**Why this priority**: Nice-to-have for analysis and insights, but not required for core settlement functionality. Adds value for expense tracking and budgeting.

**Independent Test**: Can be fully tested by adding expenses with different categories, viewing per-person dashboards with category pie charts, and verifying category totals are accurate.

**Acceptance Scenarios**:

1. **Given** I am recording an expense, **When** I select a category from the list, **Then** the expense is tagged with that category
2. **Given** expenses have categories, **When** I view a person's dashboard, **Then** I see a pie chart showing their spending breakdown by category
3. **Given** I need a custom category, **When** I add a new category to the trip, **Then** it becomes available for expense categorization

---

### User Story 6 - Individual Spending Dashboards (Priority: P3)

As a trip participant, I want to see my personal spending summary so that I understand my own financial contribution to the trip.

**Why this priority**: Enhances user experience with personalized views, but settlement summary provides the essential information needed. This adds convenience and insight.

**Independent Test**: Can be fully tested by recording expenses with different payers and viewing each person's mini dashboard showing their paid/owed/net amounts and category breakdown.

**Acceptance Scenarios**:

1. **Given** I am viewing the trip overview, **When** I look at the all-people summary table, **Then** I see each person's total paid, total owed, and net balance with color coding (green for positive, red for negative)
2. **Given** I am viewing personal dashboards, **When** I select a person, **Then** I see their mini card with financial summary and category spending chart
3. **Given** I view the summary table, **When** looking at net balances, **Then** positive balances are shown in green and negative in red for easy visual identification

---

### Edge Cases

- What happens when no participants are selected for an expense split? System should require at least one participant or default to all participants.
- What happens when an exchange rate is not available for a currency pair? System should prompt user to enter the rate or provide a default of 1.0 if same currency.
- What happens when a weighted split has zero total weight? System should show error and require at least one non-zero weight.
- What happens when trying to delete the last trip? System should prevent deletion or require creating a new trip first.
- What happens when an expense date is before the exchange rate date? System should use the most recent rate available or trip-level default rate.
- What happens when decimal precision varies between currencies (USD 2 decimals vs VND 0 decimals)? System should maintain full precision internally and format display appropriately per currency.
- What happens when minimal settlement calculation has multiple valid solutions? System should consistently produce one valid solution (greedy algorithm is deterministic).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST allow users to create trips with a name and base currency (USD or VND)
- **FR-002**: System MUST support a fixed list of participants for MVP (Tai, Khiet, Bob, Ethan, Ryan, Izzy)
- **FR-003**: System MUST allow recording expenses with date, payer, currency, amount, description, and category
- **FR-004**: System MUST support two split types: equal split (divide evenly) and weighted split (divide by custom weights)
- **FR-005**: System MUST allow selecting which participants share each expense
- **FR-006**: System MUST calculate each participant's share of an expense based on split type
- **FR-007**: System MUST maintain a table of exchange rates per trip with optional date, from currency, to currency, and rate
- **FR-008**: System MUST convert all expense amounts to the trip's base currency for settlement calculations
- **FR-009**: System MUST use appropriate exchange rate: exact date match if available, otherwise any date match, otherwise reciprocal if reverse exists, otherwise 1.0 for same currency
- **FR-010**: System MUST calculate pairwise debts (who owes whom) from all expense shares
- **FR-011**: System MUST net pairwise debts (A→B minus B→A) to reduce duplicate transfers
- **FR-012**: System MUST calculate minimal settlement transfers using greedy matching (fewest transfers to settle all debts)
- **FR-013**: System MUST display settlement summary showing each person's total paid, total owed, and net balance
- **FR-014**: System MUST display pairwise netted debts and minimal transfer list
- **FR-015**: System MUST provide copy-to-clipboard functionality for settlement transfers
- **FR-016**: System MUST support pre-seeded expense categories with ability to add new categories
- **FR-017**: System MUST isolate expense data per trip (multi-trip support)
- **FR-018**: System MUST display per-person mini dashboards with financial summary and category breakdown
- **FR-019**: System MUST use color coding for visual clarity (green for positive net, red for negative net)
- **FR-020**: System MUST maintain full decimal precision for monetary calculations and format display based on currency (USD 2 decimals, VND 0 decimals)

### Key Entities

- **Trip**: Represents a travel event with name, base currency, creation date, and associated expenses/participants
- **Expense**: Represents a single payment with date, payer, currency, amount, description, category, split type, and participant shares
- **Exchange Rate**: Represents currency conversion with optional date, from currency, to currency, rate value, and source (manual)
- **Participant**: Represents a person in the trip with identifier and name
- **Category**: Represents expense classification with name
- **Settlement Summary**: Computed aggregation showing per-person paid/owed/net amounts in base currency
- **Pairwise Debt**: Computed representation of netted debts between two participants
- **Minimal Transfer**: Computed optimal transfer from one participant to another to settle debts

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can record a new expense in under 30 seconds including participant selection
- **SC-002**: Users can view complete settlement summary (who owes whom) immediately after recording expenses
- **SC-003**: System correctly calculates equal splits for all participant counts (2-6 people)
- **SC-004**: System correctly calculates weighted splits with various weight distributions
- **SC-005**: Minimal settlement algorithm reduces the number of transfers by at least 30% compared to pairwise debts for trips with 10+ expenses
- **SC-006**: Currency conversion calculations are accurate to full decimal precision with no rounding errors in intermediate steps
- **SC-007**: Pairwise netting correctly cancels opposite debts (verified by test case: A owes B 10,000 and B owes A 20,000 results in A receiving net 10,000 from B)
- **SC-008**: Users can successfully enter 5-10 expenses across multiple currencies and see correct base currency conversions
- **SC-009**: Settlement summary displays update within 2 seconds of recording a new expense
- **SC-010**: Users can copy settlement plan to clipboard in a readable format for sharing
- **SC-011**: 95% of users successfully complete their first expense entry without errors or confusion
- **SC-012**: Visual color coding (green/red) makes net balances immediately distinguishable at a glance

## Assumptions

- Users have basic familiarity with expense splitting concepts (payer, participants, shares)
- Exchange rates are entered manually by users; no automatic fetching from external APIs
- All participants are known at trip creation time (no dynamic invitations or user authentication for MVP)
- Users trust each other and have shared access to the same trip data (no access control or permissions)
- Monetary precision requirements are satisfied by standard decimal arithmetic (no cryptocurrency-level precision needed)
- Users access the application through a web browser (no mobile app installation required for MVP)
- Users have stable internet connection for real-time updates to shared data
- Trip data persists across sessions and devices
- Settlement calculations are performed server-side to ensure consistency across all users viewing the same trip
- Users manually trigger or system automatically computes settlements (no need for manual refresh)

## Out of Scope (MVP)

- User authentication and authorization (anonymous access only)
- Role-based permissions (trip owner vs participant)
- Real-time exchange rate fetching from external APIs
- CSV/Excel import of bulk expenses
- Receipt photo uploads and OCR
- Expense edit history and audit trail
- Undo/redo functionality for expenses
- Native mobile apps (iOS/Android)
- Offline mode support
- Email/SMS notifications for settlements
- Payment tracking (marking settlements as paid)
- Recurring expenses or templates
- Budget limits and spending alerts
- Multi-language support
- Custom currency support beyond USD/VND
- Export to accounting software
