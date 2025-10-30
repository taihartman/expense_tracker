# Data Model: Receipt Split UX Improvements

**Feature**: 005-receipt-split-ux
**Status**: N/A - No data model changes

## Overview

This feature is a pure UI refactoring with **no data model changes required**.

## Existing Models (Unchanged)

### SplitType Enum

**Location**: `lib/core/models/split_type.dart`

**Values**:
- `equal` - Split equally among participants
- `weighted` - Split by custom weights
- `itemized` - Split by line items (unchanged internally, UI shows "Receipt Split")

**Backward Compatibility Note**: The enum value remains `itemized` to maintain compatibility with existing Firestore documents. Only UI terminology changes to "Receipt Split".

### Expense Model

**Location**: `lib/features/expenses/domain/models/expense.dart`

**Relevant Fields**:
- `splitType: SplitType` - Unchanged
- All other fields unchanged

**Firestore Schema**: No migration needed. Existing documents with `"splitType": "itemized"` continue to deserialize correctly.

## UI-Only Changes

This feature updates:
1. **Localization strings** (`app_en.arb`): ~60 strings renamed from `itemized*` to `receiptSplit*`
2. **UI components**: FAB Speed Dial, Expense Form, Expense List Page
3. **Navigation flow**: Direct entry to wizard vs. nested button

**No database changes, no API changes, no data migrations.**

## Testing Implications

Tests verify:
- Existing `splitType: itemized` expenses still load correctly
- Edit flow detects `itemized` and opens wizard
- New expenses save with `splitType: itemized` (enum value unchanged)
- UI displays "Receipt Split" terminology (localization)

---

**Next**: See [quickstart.md](./quickstart.md) for implementation guide.
