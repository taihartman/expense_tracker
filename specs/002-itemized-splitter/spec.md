# Feature Specification: Plates-Style Itemized Expense Splitter

**Feature Branch**: `002-itemized-splitter`
**Created**: 2025-10-22
**Status**: Draft
**Input**: User request for itemized receipt splitting functionality similar to Plates app

## Overview

This feature extends the expense tracking system to support itemized receipt splitting, allowing users to assign individual line items from a single receipt to specific people, apply taxes/tips/fees with configurable allocation rules, and produce deterministic per-person breakdowns with full audit trails.

**Goal**: From one receipt (e.g., dinner), users can:
1. Add line items with quantities and prices
2. Assign each item to one or more people (even split or custom shares)
3. Enter tax/tip/fees as percentages or absolute values
4. Choose allocation and rounding methods
5. Review per-person totals with audit trail
6. Save a single canonical expense that the settlement engine consumes directly

## User Scenarios & Testing

### User Story 1 - Basic Itemized Split (Priority: P1)

A group of friends goes to dinner. The bill has multiple items, and they want to split it based on what each person ordered rather than splitting the total evenly.

**Why this priority**: This is the core value proposition - itemized splitting is fundamentally different from equal/weighted splits and delivers immediate value to users who share receipts.

**Independent Test**: Can be fully tested by creating an expense with 3-4 items assigned to different people, entering a tax percentage, and verifying that the per-person totals are correct. Delivers complete value without any other features.

**Acceptance Scenarios**:

1. **Given** a trip with 3 participants (Tai, Khiet, Bob), **When** I create an itemized expense with:
   - Pho Tai ($14) → assigned to Tai
   - Bun Cha ($13) → assigned to Khiet
   - Spring Rolls ($8) → assigned evenly to Tai and Bob
   - Tax 8.875%, Tip 18% on pre-tax total
   **Then** the system calculates correct per-person totals and saves them as `participantAmounts`

2. **Given** an itemized expense in progress, **When** I leave an item unassigned, **Then** the system prevents saving and highlights the unassigned item

3. **Given** a saved itemized expense, **When** the settlement calculator processes it, **Then** it correctly debits each participant by their `participantAmounts` value and credits the payer by the grand total

---

### User Story 2 - Custom Item Shares (Priority: P2)

Some items are shared unequally - for example, one person ate 2/3 of a shared appetizer while another ate 1/3.

**Why this priority**: Extends the basic splitting to handle real-world scenarios where sharing isn't always even, but builds on P1's foundation.

**Independent Test**: Can be tested by creating an expense with items using custom share assignments and verifying the math reflects the specified proportions.

**Acceptance Scenarios**:

1. **Given** an itemized expense, **When** I assign a $12 appetizer with custom shares (Tai: 66.67%, Bob: 33.33%), **Then** Tai's item subtotal includes $8.00 and Bob's includes $4.00

2. **Given** multiple items with custom shares, **When** I apply tax and tip, **Then** the extras are allocated proportionally to each person's item subtotal

---

### User Story 3 - Advanced Tax/Tip/Fee Allocation (Priority: P3)

Users need control over how taxes, tips, and fees are calculated and allocated (e.g., tax only on taxable items, tip based on post-tax total, service fees split evenly).

**Why this priority**: Handles complex real-world receipts (service charges, delivery fees, coupons) but requires the core splitting to be working first.

**Independent Test**: Can be tested with receipts that have specific tax rules (some items tax-exempt), multiple fees, and discounts, verifying allocation follows the configured rules.

**Acceptance Scenarios**:

1. **Given** an expense with taxable and non-taxable items, **When** I set tax to 8% on "taxable items only" base, **Then** only items marked taxable contribute to tax calculation

2. **Given** an expense with a $5 delivery fee, **When** I set allocation to "even across assigned people", **Then** each participant who has any items assigned gets an equal share of the fee ($5 / N)

3. **Given** an expense with a 20% discount on items, **When** I set discount to apply "before tax", **Then** the tax is calculated on the reduced item subtotals

---

### User Story 4 - Review Screen with Audit Trail (Priority: P1)

Before saving, users need to review the calculated split in detail, see per-person breakdowns, and verify the math is correct.

**Why this priority**: Critical for user confidence and trust - itemized splits are complex, and users need transparency. This is essential for P1 to be usable.

**Independent Test**: Can be tested by navigating through the review screen, toggling between card and table views, expanding audit trails, and verifying all numbers match the calculation engine's output.

**Acceptance Scenarios**:

1. **Given** a completed itemized expense, **When** I reach the review screen, **Then** I see a summary bar with Items Subtotal, Tax, Tip, Fees, Discounts, and Grand Total

2. **Given** the review screen, **When** I view a person's card, **Then** I see their item subtotal, allocated tax/tip/fees, rounding adjustment, and total, with an option to expand item-by-item breakdown

3. **Given** the review screen in table mode, **When** I view the table, **Then** the footer row sums equal the summary bar totals and the Grand Total

4. **Given** a rounding remainder exists, **When** I view the review screen, **Then** I see disclosure of the remainder amount and which person received it per the rounding policy

---

### User Story 5 - Currency and Rounding Support (Priority: P2)

Different currencies have different precision requirements (USD: 2 decimals, VND: 0 decimals), and rounding must be deterministic.

**Why this priority**: Essential for international use but can be implemented after core splitting works for one currency.

**Independent Test**: Can be tested with receipts in VND showing integer amounts and proper rounding, and USD receipts with cents.

**Acceptance Scenarios**:

1. **Given** an expense in VND, **When** I review the split, **Then** all amounts are shown as integers with no decimal places

2. **Given** an expense that produces rounding residuals, **When** rounding policy is "largest share", **Then** the person with the largest item subtotal receives the rounding adjustment

---

### User Story 6 - Edit Existing Itemized Expense (Priority: P3)

Users need to correct mistakes or update itemized expenses after creation.

**Why this priority**: Important for usability but can be implemented after the creation flow is solid.

**Independent Test**: Can be tested by editing an existing itemized expense, modifying items/tax/tip, and verifying the recalculated values are saved correctly.

**Acceptance Scenarios**:

1. **Given** a saved itemized expense, **When** I edit it, **Then** the UI pre-fills all items, extras, and allocation rules

2. **Given** I modify an item's price or assignment, **When** I save, **Then** the system recalculates all per-person totals and updates the expense

---

### Edge Cases

- What happens when tax is entered as an absolute amount but items subtotal is zero?
  → Treat as 0, display warning to user

- What happens when discounts exceed the item subtotal?
  → Clamp to zero, display warning to user

- What happens when tip percentage is extremely high (>100%)?
  → Allow but require confirmation before saving (validation banner)

- What happens when currency has zero minor units (e.g., VND)?
  → Use precision "1" for rounding, show integers in UI

- What happens when an item has quantity > 1 and is split with custom shares?
  → Calculate itemTotal = quantity × unitPrice, then apply custom shares to itemTotal

- What happens when all items are marked non-taxable but tax percentage is entered?
  → Tax total is 0 (no base to apply percentage to); show info message

- What happens when the payer is not one of the people assigned items?
  → Allow (payer might be paying for others who aren't ordering); payer appears in breakdown with $0 items if not assigned anything

- What happens when rounding residual cannot be evenly distributed?
  → Use configured policy (largestShare, payer, firstListed, random) to assign to one person

## Requirements

### Functional Requirements

#### Data Model

- **FR-001**: System MUST extend the Expense entity to include optional fields: `items[]`, `extras`, `allocation`, `participantAmounts`, `participantBreakdown`
- **FR-002**: System MUST support `splitType = "itemized"` in addition to existing "equal" and "weighted"
- **FR-003**: Each `LineItem` MUST include: id, name, quantity, unitPrice, taxable flag, serviceChargeable flag, and assignment (mode + users/shares)
- **FR-004**: `Extras` MUST support: tax (percent/amount), tip (percent/amount), fees (array with name/type/value/appliesTo), discounts (array with name/type/value/appliesTo)
- **FR-005**: `AllocationRule` MUST specify: percentBase, absoluteSplit, and rounding (precision/mode/distributeRemainderTo)
- **FR-006**: System MUST store a single canonical `amount` (grand total) and `participantAmounts` object mapping userId → amount string

#### Calculation Engine

- **FR-007**: System MUST calculate item subtotals per user based on assignment mode (even across selected users, or custom shares that sum to 1.0)
- **FR-008**: System MUST apply discounts based on configured base (preTaxItemSubtotals, postTaxSubtotals, etc.)
- **FR-009**: System MUST calculate tax as percentage of chosen base (preTaxItemSubtotals, taxableItemSubtotalsOnly, postDiscountItemSubtotals) or as absolute amount
- **FR-010**: System MUST allocate fees based on type (percent/amount) and appliesTo base
- **FR-011**: System MUST calculate tip as percentage of chosen base (pre-tax, post-tax, post-fees) or as absolute amount
- **FR-012**: System MUST round each participant's total to currency precision using configured mode (roundHalfUp, roundHalfEven, floor, ceil)
- **FR-013**: System MUST distribute rounding remainders according to policy (largestShare, payer, firstListed, random)
- **FR-014**: System MUST ensure sum of participantAmounts equals amount (grand total) within epsilon determined by currency precision
- **FR-015**: System MUST use Decimal arithmetic throughout (no floating point)

#### UI/UX Flow

- **FR-016**: System MUST provide an "Itemized (Plates)" entry point in the Add Expense flow
- **FR-017**: System MUST present a 4-step flow: People & Payer → Items Builder → Tax/Tip/Fees/Discounts → Review Split
- **FR-018**: Items Builder MUST allow adding line items with name, quantity, unit price, taxable toggle, serviceChargeable toggle
- **FR-019**: Items Builder MUST allow assigning items to people with "Even" or "Custom" modes
- **FR-020**: Tax/Tip/Fees screen MUST support percent or amount input with base selection
- **FR-021**: Review Screen MUST display: summary bar, per-person cards/table, validation banners, items snapshot
- **FR-022**: Review Screen MUST prevent saving when unassigned items exist or negative totals occur
- **FR-023**: Review Screen MUST allow toggling between card and table views
- **FR-024**: Review Screen MUST show audit trail (item-by-item contributions) in expandable sections
- **FR-025**: System MUST format currency amounts according to currency's minor unit count (VND: 0 decimals, USD: 2 decimals)

#### Settlement Integration

- **FR-026**: SettlementCalculator MUST consume `participantAmounts` when `splitType = "itemized"`
- **FR-027**: SettlementCalculator MUST credit payer by `amount` and debit each participant by `participantAmounts[userId]`
- **FR-028**: Existing equal/weighted split logic MUST remain unchanged

#### Validation

- **FR-029**: System MUST block save when any item is unassigned
- **FR-030**: System MUST block save when any participant total is negative
- **FR-031**: System MUST warn (require confirmation) when tax/tip percentages exceed configurable threshold (e.g., 100%)
- **FR-032**: System MUST clamp discounts to prevent negative item subtotals

#### State Management

- **FR-033**: System MUST implement `ItemizedExpenseCubit` to manage draft state (people, items, extras, allocation)
- **FR-034**: Cubit MUST derive per-user breakdown and grand total from draft state
- **FR-035**: Cubit MUST validate state (unassigned items, negative totals) and expose validation errors
- **FR-036**: Cubit MUST provide actions: addItem, updateItem, assignItem, setTax, setTip, addFee, addDiscount, setAllocation, recalc, save

#### Persistence

- **FR-037**: System MUST serialize itemized expenses to Firestore with all new fields
- **FR-038**: System MUST maintain backward compatibility (existing expenses without itemized fields remain valid)
- **FR-039**: System MUST update Trip.lastExpenseModifiedAt in same batch write as expense
- **FR-040**: System MUST deserialize itemized fields from Firestore when loading expenses

### Key Entities

- **LineItem**: Represents a single line on a receipt (name, quantity, unit price, flags for taxable/serviceChargeable, assignment to people)
- **Extras**: Container for tax, tip, fees, and discounts (each with type: percent/amount, value, and optional appliesTo base)
- **AllocationRule**: Configuration for how percentage-based extras are allocated (base selection), how absolute extras are split (proportional vs even), and rounding behavior (precision, mode, remainder distribution)
- **Expense** (extended): Existing entity with new optional fields for itemized splitting, preserves existing equal/weighted behavior
- **participantAmounts**: Map of userId → amount string, the canonical source for settlement calculations
- **participantBreakdown**: Detailed audit trail per user (item subtotal, allocated extras, rounding adjustment, total)

## Success Criteria

### Measurable Outcomes

- **SC-001**: Users can create an itemized expense with 5 items and 3 people in under 3 minutes
- **SC-002**: Calculation engine produces deterministic results (same inputs → same outputs) for all test fixtures
- **SC-003**: Settlement calculations using itemized expenses produce minimal transfers identical to manual calculation
- **SC-004**: Review screen displays all per-person totals that sum to grand total within 1 cent (or 1 currency unit for zero-decimal currencies)
- **SC-005**: 95% of test cases with rounding remainders distribute correctly per policy
- **SC-006**: Users can toggle between card and table view on review screen without loss of data or scroll position
- **SC-007**: System prevents saving 100% of invalid expenses (unassigned items, negative totals)
- **SC-008**: VND expenses display with 0 decimal places, USD with 2 decimal places, across all screens

## Technical Constraints

- **TC-001**: All calculations MUST use Decimal arithmetic (no floating point)
- **TC-002**: Currency precision MUST be derived from ISO 4217 minor unit count (default 2)
- **TC-003**: No new Firestore collections or indexes required
- **TC-004**: Itemized expenses MUST integrate with existing BLoC/Cubit state management
- **TC-005**: Existing equal/weighted expense flows MUST remain unchanged (additive change only)

## Out of Scope

- Dynamic participant management (still limited to fixed list: Tai, Khiet, Bob, Ethan, Ryan, Izzy)
- Receipt OCR or photo parsing
- Real-time collaboration or sync during editing
- Multi-receipt merging
- Currency conversion within a single receipt (all items must use expense currency)
- Complex tax rules (e.g., different tax rates per item category)
- Automatic tip calculation based on service quality
- Integration with external payment systems

## Dependencies

- Existing Expense entity and ExpenseRepository
- Existing SettlementCalculator
- Existing Trip entity (for participant list and base currency)
- Flutter Decimal package or equivalent for precise arithmetic
- Existing BLoC/Cubit infrastructure

## Open Questions

1. Should we support fractional quantities (e.g., 0.5 bottles of wine) or integers only?
   - **Recommendation**: Support decimal quantities for flexibility

2. What is the maximum number of items per receipt?
   - **Recommendation**: Cap at 300 items to prevent extreme payloads and UI performance issues

3. Should we allow saving drafts or must expenses be completed in one session?
   - **Recommendation**: Initially require completion in one session (simpler), consider drafts in future

4. Should we support multiple currencies within a single itemized receipt?
   - **Recommendation**: No, all items must use the expense currency (out of scope for now)

5. How should we handle receipts with split payments (multiple payers)?
   - **Recommendation**: Out of scope - itemized expenses have one payer, but we could allow transferring ownership later

6. Should the review screen be editable or read-only (with "Edit" buttons to return to previous steps)?
   - **Recommendation**: Read-only with "Edit Items" / "Edit Tax/Tip/Fees" buttons to return to specific steps

## Revision History

- **2025-10-22**: Initial specification created from user-provided detailed requirements
