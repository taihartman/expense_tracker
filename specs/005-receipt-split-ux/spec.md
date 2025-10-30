# Feature Specification: Receipt Split UX Improvements

**Feature Branch**: `005-receipt-split-ux`
**Created**: 2025-10-30
**Status**: Draft
**Input**: User description: "Extract Receipt Split as a separate FAB entry point with improved terminology. Change 'Itemized' to 'Receipt Split (Who Ordered What)' across all 60+ localization strings. Replace AppBar '+' button with a Material Design FAB Speed Dial at bottom-right offering two options: 'Quick Expense' (Equal/Weighted only) and 'Receipt Split' (direct to wizard). Simplify expense form by removing itemized button from split type selection."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Add Simple Equal/Weighted Expense via Quick Entry (Priority: P1)

A user wants to quickly record a straightforward expense where everyone splits equally or by weights (e.g., "dinner for 3 people, split equally"). They don't need per-item detail.

**Why this priority**: This is the most common use case (70-80% of expenses). Quick entry must be frictionless and immediately discoverable.

**Independent Test**: User can tap FAB, select "Quick Expense", fill basic details (amount, payer, description), choose Equal or Weighted split, and save in under 30 seconds.

**Acceptance Scenarios**:

1. **Given** user is viewing the expense list, **When** user taps FAB at bottom-right, **Then** speed dial opens showing "Quick Expense" and "Receipt Split" options
2. **Given** speed dial is open, **When** user taps "Quick Expense", **Then** expense form bottom sheet appears with amount, payer, description, category, date, and split type (Equal/Weighted segmented button only)
3. **Given** expense form is open, **When** user fills amount, selects Equal split, chooses participants, and taps Save, **Then** expense is created and form closes
4. **Given** expense form is open, **When** user selects Weighted split, **Then** weight input fields appear for each participant
5. **Given** expense form shows Weighted split, **When** user enters weights and saves, **Then** expense is created with correct participant amounts

---

### User Story 2 - Add Detailed Receipt Split Directly (Priority: P1)

A user has a restaurant receipt with multiple items (e.g., "3 appetizers, 4 entrees, 2 desserts") and wants to track who ordered what. They need per-item assignment and tax/tip allocation.

**Why this priority**: This is the key differentiator of the app. Direct access prevents user frustration and data loss from having to abandon partially-filled forms.

**Independent Test**: User can tap FAB, select "Receipt Split", and be taken directly to the 4-step wizard without filling any intermediate form.

**Acceptance Scenarios**:

1. **Given** user is viewing the expense list, **When** user taps FAB and selects "Receipt Split (Who Ordered What)", **Then** Receipt Split wizard opens on Step 1 (People selection)
2. **Given** wizard Step 1 is open, **When** user selects participants, payer, currency, and taps Next, **Then** wizard advances to Step 2 (Items)
3. **Given** wizard Step 2 is open, **When** user adds 3 line items (name, quantity, price), assigns each to specific people, and taps Next, **Then** wizard advances to Step 3 (Extras)
4. **Given** wizard Step 3 is open, **When** user enters tax rate, tip percentage, and taps Next, **Then** wizard advances to Step 4 (Review)
5. **Given** wizard Step 4 shows breakdown, **When** user verifies per-person totals and taps Save, **Then** expense is created with all itemized details and wizard closes

---

### User Story 3 - Understand Terminology and Make Informed Choice (Priority: P2)

A new user wants to add their first expense but doesn't know whether to use "Quick Expense" or "Receipt Split". The terminology and hints should guide them.

**Why this priority**: First-time user experience determines adoption. Clear, friendly terminology prevents confusion and increases feature discovery.

**Independent Test**: User can read button labels and understand the difference without external help. Terminology uses natural language instead of accounting jargon.

**Acceptance Scenarios**:

1. **Given** user sees FAB speed dial for the first time, **When** user reads "Quick Expense" label, **Then** they understand it's for simple, fast entry
2. **Given** user sees FAB speed dial, **When** user reads "Receipt Split (Who Ordered What)" label, **Then** they understand it's for detailed item-by-item splitting
3. **Given** user is unsure which to use, **When** user taps Quick Expense, **Then** form shows only Equal/Weighted options (reinforcing "quick and simple")
4. **Given** user realizes they need itemized detail, **When** user closes Quick Expense form and taps Receipt Split instead, **Then** wizard opens directly without data loss concerns

---

### User Story 4 - Edit Existing Expenses (Priority: P3)

A user wants to edit an existing expense. The edit flow should respect the original split type (Quick vs Receipt Split).

**Why this priority**: Edit is less frequent than create, but must maintain consistency. Receipt Split expenses should open the wizard, Quick expenses should open the form.

**Independent Test**: User can tap any expense card, and system automatically opens the appropriate editor (form for Equal/Weighted, wizard for Receipt Split).

**Acceptance Scenarios**:

1. **Given** expense list contains an Equal split expense, **When** user taps the card, **Then** Quick Expense form opens with existing data pre-filled
2. **Given** expense list contains a Receipt Split expense, **When** user taps the card, **Then** Receipt Split wizard opens with existing items, tax, tip, and assignments pre-loaded
3. **Given** user edits a Quick Expense, **When** user changes amount and saves, **Then** expense is updated without navigating to wizard
4. **Given** user edits a Receipt Split expense, **When** user modifies an item assignment in wizard and saves, **Then** expense is updated with recalculated per-person totals

---

### Edge Cases

- **What happens when user taps outside FAB speed dial?** Speed dial should close without taking action (standard Material Design behavior)
- **What if user starts Quick Expense but realizes mid-way they need Receipt Split?** User can close form (loses draft) and tap FAB → Receipt Split. No conversion feature in MVP.
- **What if existing "itemized" expenses exist in storage?** They continue to work. Edit flow detects `splitType == itemized` and opens wizard. Only UI terminology changes.
- **What happens if FAB overlaps content?** FAB should respect Material Design padding (16dp from edges) and not overlap critical UI elements like settlement cards or expense list items.
- **What if user's device has small screen?** FAB speed dial should scale appropriately. On very small screens (<360dp width), consider using bottom navigation or menu instead.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST replace the existing AppBar "+" button with a Floating Action Button (FAB) positioned at bottom-right of expense list page
- **FR-002**: FAB MUST implement Material Design Speed Dial pattern, expanding to show two distinct options when tapped
- **FR-003**: Speed Dial option 1 MUST be labeled "Quick Expense" and open the existing expense form bottom sheet
- **FR-004**: Speed Dial option 2 MUST be labeled "Receipt Split (Who Ordered What)" and navigate directly to the itemized expense wizard
- **FR-005**: Quick Expense form MUST show only Equal and Weighted split types in the segmented button (no third "itemized" button)
- **FR-006**: Receipt Split wizard MUST remain functionally unchanged (4 steps: People, Items, Extras, Review)
- **FR-007**: System MUST update all localization strings containing "itemized" or "Itemized" to use "receiptSplit" or "Receipt Split" terminology (approximately 60+ strings in app_en.arb)
- **FR-008**: Terminology update MUST maintain string key naming convention (e.g., `itemizedWizardTitle` → `receiptSplitWizardTitle`)
- **FR-009**: Edit flow MUST detect expense split type and open appropriate editor (form for Equal/Weighted, wizard for Receipt Split)
- **FR-010**: System MUST preserve backward compatibility with existing expenses that have `splitType: itemized` in storage
- **FR-011**: FAB MUST follow Material Design 3 specifications (size, elevation, positioning, animations)
- **FR-012**: Speed Dial labels MUST use descriptive text that clearly differentiates the two expense entry methods
- **FR-013**: System MUST remove all references to "itemized" from expense_form_page.dart split type selection UI
- **FR-014**: System MUST remove the onSplitTypeChanged handler for itemized type in expense form (since it's now a separate entry point)
- **FR-015**: Quick Expense and Receipt Split entry points MUST be visually distinct with different icons (e.g., add icon for Quick, receipt icon for Receipt Split)

### Key Entities *(no new entities - UI refactoring only)*

- **Expense**: Existing entity with `splitType` enum (equal, weighted, itemized) - no schema changes required
- **Split Type Enum**: Existing enum may optionally rename `itemized` → `receiptSplit` (though not strictly required for backward compatibility)
- **Localization Keys**: Rename all `itemized*` keys to `receiptSplit*` in app_en.arb (structural change to localization, not data model)

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can identify and choose between Quick Expense and Receipt Split within 5 seconds of viewing the FAB for the first time (measured via user testing)
- **SC-002**: Receipt Split feature discovery increases by 40% (measured by comparing usage rate before/after terminology change)
- **SC-003**: Users creating simple expenses (Equal/Weighted) complete the flow in 25% less time due to removal of unnecessary itemized option (measured by timing Quick Expense flow)
- **SC-004**: Zero data loss incidents when switching between Quick Expense and Receipt Split entry points (measured by error logs and user reports)
- **SC-005**: 90% of users correctly understand the difference between Quick Expense and Receipt Split based on button labels alone (measured via user survey)
- **SC-006**: Edit flow works seamlessly for 100% of existing expenses regardless of whether they were created before or after terminology change (backward compatibility test)
- **SC-007**: FAB implementation passes Material Design 3 compliance checks (size, elevation, positioning, animation timing)

## Assumptions

1. **No data migration required**: Existing expenses with `splitType: itemized` will continue to function. Only UI terminology changes.
2. **Localization scope**: Only English (app_en.arb) strings will be updated in this feature. Future languages will use equivalent terminology.
3. **Speed Dial is appropriate for mobile**: Material Design Speed Dial pattern is well-understood by users and appropriate for 2 options. If >3 options are needed in future, pattern may need reevaluation.
4. **Users understand "receipt"**: The term "receipt" is universally understood in the context of expense splitting (bill, invoice, tab).
5. **Form vs Wizard separation is clear**: Having two distinct entry points (Quick Expense form vs Receipt Split wizard) creates a clear mental model without confusion.
6. **No conversion feature needed**: Users don't need to "upgrade" a Quick Expense to Receipt Split mid-flow. They can cancel and start over.
7. **FAB doesn't conflict with existing UI**: Bottom-right FAB positioning doesn't overlap important UI elements like settlement cards or navigation.

## Out of Scope

- Adding a third expense type (e.g., "Percentage Split" or "Custom")
- Implementing conversion from Quick Expense to Receipt Split (must cancel and restart)
- Adding receipt photo upload or OCR
- Changing the Receipt Split wizard flow (remains 4 steps as-is)
- Renaming the `splitType` enum value in code (can remain `itemized` internally for backward compatibility)
- Updating localization for languages other than English
- Adding tooltips or onboarding for first-time users
- Changing the Quick Expense form layout beyond removing itemized button
- Adding keyboard shortcuts for FAB actions
- Implementing undo/redo for expense creation

## Dependencies

- Existing `ItemizedExpenseWizard` component (remains unchanged)
- Existing `ExpenseFormBottomSheet` component (minor modification to remove itemized button)
- Existing localization system (`app_en.arb` + Flutter l10n generation)
- Material Design 3 components (FAB, Speed Dial pattern)
- Existing split type enum and logic (backward compatible)

## Risks & Mitigations

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| Users can't find Receipt Split feature | High - feature goes unused | Medium | Use clear icon (receipt) and descriptive label "Who Ordered What" |
| Terminology change breaks existing code references | High - app crashes | Low | Thorough find/replace with testing; maintain enum value as `itemized` |
| FAB overlaps important UI | Medium - poor UX | Medium | Test on multiple screen sizes; adjust padding if needed |
| Users confused by two entry points | Medium - friction | Low | Labels are self-explanatory; Speed Dial pattern is familiar |
| Backward compatibility issues | High - old expenses break | Low | No schema changes; only UI terminology changes |
| Localization generation fails | Medium - build breaks | Low | Run `flutter pub get` after ARB changes; verify generated files |

## Notes

- This is a pure UX improvement - no business logic changes
- All existing expenses continue to work without migration
- Receipt Split wizard functionality remains 100% unchanged
- Only changes: entry point (FAB vs form button) and terminology (Receipt Split vs Itemized)
- Material Design Speed Dial: https://m3.material.io/components/floating-action-button/guidelines#9d7a95fa-2c8e-4e9f-b927-b2e3f6e4b43e
