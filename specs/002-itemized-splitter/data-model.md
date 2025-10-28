# Data Model: Itemized Expense Splitter

**Feature**: Plates-Style Itemized Receipt Splitting
**Branch**: `002-itemized-splitter`
**Date**: 2025-10-28
**Status**: Design Complete

## Overview

This document defines all domain entities, their fields, relationships, validation rules, and state transitions for the itemized expense splitter feature. All monetary values use `Decimal` type for precision. The data model extends the existing `Expense` entity with optional fields for backward compatibility.

---

## Core Entities

### 1. Expense (Extended)

**Purpose**: Represents a single payment made by one participant. Extended to support itemized splitting while maintaining backward compatibility with existing equal/weighted splits.

**Location**: `/lib/features/expenses/domain/models/expense.dart`

**Fields**:

| Field | Type | Required | Description | Constraints | Validation |
|-------|------|----------|-------------|-------------|------------|
| `id` | `String` | Yes | Unique identifier | UUID format | Auto-generated |
| `tripId` | `String` | Yes | Parent trip reference | UUID format | Must exist in trips collection |
| `date` | `DateTime` | Yes | Expense date | Date-only precision | Not in future |
| `payerUserId` | `String` | Yes | User who paid | Fixed participant ID | Must be valid user |
| `currency` | `CurrencyCode` | Yes | Currency code | ISO 4217 (USD, VND) | Enum validation |
| `amount` | `Decimal` | Yes | Grand total | > 0, max 12 digits + currency decimals | Must equal sum of participantAmounts if itemized |
| `description` | `String?` | No | User note | Max 200 characters | Length validation |
| `categoryId` | `String?` | No | Category reference | UUID format | Must exist if provided |
| `splitType` | `SplitType` | Yes | Split method | `equal`, `weighted`, `itemized` | Enum validation |
| `participants` | `Map<String, num>?` | No | User weights (legacy) | userId -> weight | Required for equal/weighted, null for itemized |
| `createdAt` | `DateTime` | Yes | Creation timestamp | UTC | Auto-generated |
| `updatedAt` | `DateTime` | Yes | Last update timestamp | UTC | Auto-updated |

**NEW Itemized Fields** (all optional, required only if `splitType = "itemized"`):

| Field | Type | Required | Description | Constraints |
|-------|------|----------|-------------|-------------|
| `items` | `List<LineItem>?` | Conditional | Line items from receipt | Min 1 item, max 300 items |
| `extras` | `Extras?` | Conditional | Tax/tip/fees/discounts | Must be valid if provided |
| `allocation` | `AllocationRule?` | Conditional | Allocation config | Auto-derived from currency |
| `participantAmounts` | `Map<String, Decimal>?` | Conditional | Per-person totals | userId -> amount, sum = amount |
| `participantBreakdown` | `Map<String, ParticipantBreakdown>?` | Conditional | Detailed audit trail | userId -> breakdown |

**Validation Rules**:

```dart
String? validate() {
  // Amount must be positive
  if (amount <= Decimal.zero) {
    return 'Amount must be greater than 0';
  }

  // Date cannot be in future
  if (date.isAfter(DateTime.now())) {
    return 'Date cannot be in the future';
  }

  // Itemized-specific validation
  if (splitType == SplitType.itemized) {
    if (items == null || items!.isEmpty) {
      return 'Itemized expenses must have at least one item';
    }

    if (participantAmounts == null || participantAmounts!.isEmpty) {
      return 'Itemized expenses must have participantAmounts';
    }

    // Verify sum equals total (within epsilon)
    final sum = participantAmounts!.values.fold(
      Decimal.zero,
      (a, b) => a + b,
    );
    final epsilon = Decimal.parse('1e-${currency.decimalPlaces}');
    if ((sum - amount).abs() > epsilon) {
      return 'Sum of participant amounts must equal grand total';
    }

    // All items must be assigned
    for (final item in items!) {
      if (item.assignment.assignedUserIds.isEmpty) {
        return 'All items must be assigned to at least one person';
      }
    }
  }

  // Legacy validation for equal/weighted
  if (splitType != SplitType.itemized) {
    if (participants == null || participants!.isEmpty) {
      return 'Equal/weighted splits require participants map';
    }
  }

  return null; // Valid
}
```

**Relationships**:
- `tripId` → `Trip` (many-to-one)
- `categoryId` → `Category` (many-to-one, optional)
- `payerUserId` → User (many-to-one)
- `items[]` → `LineItem` (one-to-many, composition)
- `extras` → `Extras` (one-to-one, composition)
- `allocation` → `AllocationRule` (one-to-one, composition)

---

### 2. LineItem

**Purpose**: Represents a single line on a receipt (e.g., "Steak $25.00 x2").

**Location**: `/lib/features/expenses/domain/models/line_item.dart`

**Fields**:

| Field | Type | Required | Description | Constraints | Default |
|-------|------|----------|-------------|-------------|---------|
| `id` | `String` | Yes | Unique item ID | UUID format | Auto-generated |
| `name` | `String` | Yes | Item name | 1-100 characters | None |
| `quantity` | `Decimal` | Yes | Quantity | > 0, max 4 decimals | 1 |
| `unitPrice` | `Decimal` | Yes | Price per unit | >= 0, currency precision | 0 |
| `taxable` | `bool` | Yes | Subject to tax | true/false | true |
| `serviceChargeable` | `bool` | Yes | Subject to service fees | true/false | true |
| `assignment` | `ItemAssignment` | Yes | Who pays for this item | Must have assignees | None |

**Computed Properties**:

```dart
/// Total price for this line item
Decimal get itemTotal => quantity * unitPrice;

/// List of user IDs assigned to this item
List<String> get assignedUserIds => assignment.assignedUserIds;

/// Check if item is fully assigned
bool get isAssigned => assignedUserIds.isNotEmpty;
```

**Validation**:

```dart
String? validate() {
  if (name.isEmpty || name.length > 100) {
    return 'Item name must be 1-100 characters';
  }

  if (quantity <= Decimal.zero) {
    return 'Quantity must be greater than 0';
  }

  if (unitPrice < Decimal.zero) {
    return 'Unit price cannot be negative';
  }

  if (!isAssigned) {
    return 'Item must be assigned to at least one person';
  }

  if (assignment.mode == AssignmentMode.custom) {
    if (assignment.customShares == null) {
      return 'Custom assignment requires shares';
    }

    // Verify shares sum to 1.0
    final sum = assignment.customShares!.values.fold(
      Decimal.zero,
      (a, b) => a + b,
    );
    if ((sum - Decimal.one).abs() > Decimal.parse('0.0001')) {
      return 'Custom shares must sum to 1.0';
    }
  }

  return null;
}
```

**Example**:

```dart
final steakItem = LineItem(
  id: 'item_001',
  name: 'Ribeye Steak',
  quantity: Decimal.fromInt(2),
  unitPrice: Decimal.parse('25.00'),
  taxable: true,
  serviceChargeable: true,
  assignment: ItemAssignment.even(['alice', 'bob']),
);
// itemTotal = 2 * $25.00 = $50.00
// Each person owes $25.00
```

---

### 3. ItemAssignment

**Purpose**: Defines how a line item is split among participants.

**Location**: `/lib/features/expenses/domain/models/item_assignment.dart`

**Fields**:

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `mode` | `AssignmentMode` | Yes | Assignment type (`even` or `custom`) |
| `assignedUserIds` | `List<String>` | Yes | Users assigned to this item (at least 1) |
| `customShares` | `Map<String, Decimal>?` | Conditional | userId -> share (0-1, sum=1.0), required if mode=custom |

**Enums**:

```dart
enum AssignmentMode {
  /// Split evenly across assignedUserIds
  even,

  /// Custom percentage shares per user
  custom,
}
```

**Constructors**:

```dart
class ItemAssignment {
  // Even split constructor
  ItemAssignment.even(List<String> users)
    : mode = AssignmentMode.even,
      assignedUserIds = users,
      customShares = null;

  // Custom shares constructor (percentages converted to decimals)
  ItemAssignment.custom(Map<String, double> percentages)
    : mode = AssignmentMode.custom,
      assignedUserIds = percentages.keys.toList(),
      customShares = _normalizePercentagesToShares(percentages);

  // Normalize percentages to shares that sum to 1.0
  static Map<String, Decimal> _normalizePercentagesToShares(
    Map<String, double> percentages,
  ) {
    final shares = percentages.map(
      (key, value) => MapEntry(
        key,
        Decimal.parse(value.toString()) / Decimal.fromInt(100),
      ),
    );

    final sum = shares.values.fold(Decimal.zero, (a, b) => a + b);

    // Normalize to ensure exact sum = 1.0
    return shares.map((key, value) => MapEntry(key, value / sum));
  }
}
```

**Example**:

```dart
// Even split: Alice and Bob each pay 50%
final evenAssignment = ItemAssignment.even(['alice', 'bob']);

// Custom split: Alice 66.67%, Bob 33.33%
final customAssignment = ItemAssignment.custom({
  'alice': 66.67,
  'bob': 33.33,
});
```

---

### 4. Extras

**Purpose**: Container for all additional charges and deductions (tax, tip, fees, discounts).

**Location**: `/lib/features/expenses/domain/models/extras.dart`

**Fields**:

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `tax` | `TaxExtra?` | No | Sales tax configuration |
| `tip` | `TipExtra?` | No | Gratuity configuration |
| `fees` | `List<FeeExtra>` | Yes | Additional fees (delivery, service, etc.) |
| `discounts` | `List<DiscountExtra>` | Yes | Coupons, promotions, etc. |

**Constructor**:

```dart
const Extras({
  this.tax,
  this.tip,
  this.fees = const [],
  this.discounts = const [],
});
```

**Example**:

```dart
final extras = Extras(
  tax: TaxExtra(
    percentValue: Decimal.parse('8.875'),
    base: PercentBase.preTaxItemSubtotals,
  ),
  tip: TipExtra(
    percentValue: Decimal.parse('20'),
    base: PercentBase.postTaxSubtotals,
  ),
  fees: [
    FeeExtra(
      name: 'Delivery Fee',
      absoluteValue: Decimal.fromInt(5),
      absoluteSplit: AbsoluteSplitMode.evenAcrossAllParticipants,
    ),
  ],
  discounts: [],
);
```

---

### 5. TaxExtra

**Purpose**: Represents sales tax on a receipt.

**Location**: `/lib/features/expenses/domain/models/tax_extra.dart`

**Fields**:

| Field | Type | Required | Description | Constraints |
|-------|------|----------|-------------|-------------|
| `percentValue` | `Decimal?` | Conditional | Tax percentage | 0-100, max 2 decimals |
| `absoluteValue` | `Decimal?` | Conditional | Absolute tax amount | >= 0 |
| `base` | `PercentBase?` | Conditional | What percentage applies to | Required if percentValue set |

**Validation**:

```dart
String? validate() {
  // Must have exactly one of percentValue or absoluteValue
  if ((percentValue == null && absoluteValue == null) ||
      (percentValue != null && absoluteValue != null)) {
    return 'Tax must be either percentage or absolute amount, not both';
  }

  if (percentValue != null) {
    if (percentValue! < Decimal.zero || percentValue! > Decimal.fromInt(100)) {
      return 'Tax percentage must be 0-100';
    }
    if (base == null) {
      return 'Tax base required for percentage tax';
    }
  }

  if (absoluteValue != null && absoluteValue! < Decimal.zero) {
    return 'Tax amount cannot be negative';
  }

  return null;
}
```

**Example**:

```dart
// Percentage tax
final percentTax = TaxExtra(
  percentValue: Decimal.parse('8.875'),
  base: PercentBase.preTaxItemSubtotals,
);

// Absolute tax
final absoluteTax = TaxExtra(
  absoluteValue: Decimal.parse('5.50'),
);
```

---

### 6. TipExtra

**Purpose**: Represents gratuity/tip.

**Location**: `/lib/features/expenses/domain/models/tip_extra.dart`

**Fields**: Same structure as `TaxExtra`

| Field | Type | Required | Description | Constraints |
|-------|------|----------|-------------|-------------|
| `percentValue` | `Decimal?` | Conditional | Tip percentage | 0-100, max 2 decimals |
| `absoluteValue` | `Decimal?` | Conditional | Absolute tip amount | >= 0 |
| `base` | `PercentBase?` | Conditional | What percentage applies to | Required if percentValue set |

**Validation**: Identical to `TaxExtra`

---

### 7. FeeExtra

**Purpose**: Represents additional fees (delivery, service charge, etc.).

**Location**: `/lib/features/expenses/domain/models/fee_extra.dart`

**Fields**:

| Field | Type | Required | Description | Constraints |
|-------|------|----------|-------------|-------------|
| `name` | `String` | Yes | Fee description | 1-50 characters |
| `percentValue` | `Decimal?` | Conditional | Fee as percentage | 0-100 |
| `absoluteValue` | `Decimal?` | Conditional | Fee as amount | >= 0 |
| `percentBase` | `PercentBase?` | Conditional | Base for percentage | Required if percentValue set |
| `absoluteSplit` | `AbsoluteSplitMode?` | Conditional | How to split absolute fee | Required if absoluteValue set |

**Validation**:

```dart
String? validate() {
  if (name.isEmpty || name.length > 50) {
    return 'Fee name must be 1-50 characters';
  }

  if ((percentValue == null && absoluteValue == null) ||
      (percentValue != null && absoluteValue != null)) {
    return 'Fee must be either percentage or absolute, not both';
  }

  if (percentValue != null) {
    if (percentValue! < Decimal.zero || percentValue! > Decimal.fromInt(100)) {
      return 'Fee percentage must be 0-100';
    }
    if (percentBase == null) {
      return 'Percent base required for percentage fee';
    }
  }

  if (absoluteValue != null) {
    if (absoluteValue! < Decimal.zero) {
      return 'Fee amount cannot be negative';
    }
    if (absoluteSplit == null) {
      return 'Absolute split mode required for absolute fee';
    }
  }

  return null;
}
```

**Example**:

```dart
// Percentage service fee
final serviceFee = FeeExtra(
  name: 'Service Fee',
  percentValue: Decimal.parse('10'),
  percentBase: PercentBase.preTaxItemSubtotals,
);

// Absolute delivery fee
final deliveryFee = FeeExtra(
  name: 'Delivery Fee',
  absoluteValue: Decimal.fromInt(5),
  absoluteSplit: AbsoluteSplitMode.evenAcrossAllParticipants,
);
```

---

### 8. DiscountExtra

**Purpose**: Represents coupons, promotions, or discounts.

**Location**: `/lib/features/expenses/domain/models/discount_extra.dart`

**Fields**:

| Field | Type | Required | Description | Constraints |
|-------|------|----------|-------------|-------------|
| `name` | `String` | Yes | Discount description | 1-50 characters |
| `percentValue` | `Decimal?` | Conditional | Discount as percentage | 0-100 |
| `absoluteValue` | `Decimal?` | Conditional | Discount as amount | >= 0 |
| `percentBase` | `PercentBase?` | Conditional | Base for percentage | Required if percentValue set |
| `absoluteSplit` | `AbsoluteSplitMode?` | Conditional | How to split absolute discount | Required if absoluteValue set |
| `applyBeforeTax` | `bool` | Yes | Order of operations | true/false, default true |

**Validation**: Similar to `FeeExtra` with additional name validation

**Example**:

```dart
final happyHour = DiscountExtra(
  name: '20% Off Happy Hour',
  percentValue: Decimal.parse('20'),
  percentBase: PercentBase.preTaxItemSubtotals,
  applyBeforeTax: true, // Apply discount before tax calculation
);

final coupon = DiscountExtra(
  name: '$10 Coupon',
  absoluteValue: Decimal.fromInt(10),
  absoluteSplit: AbsoluteSplitMode.proportionalToItemSubtotals,
  applyBeforeTax: true,
);
```

---

### 9. AllocationRule

**Purpose**: Configuration for how extras are allocated and rounded.

**Location**: `/lib/features/expenses/domain/models/allocation_rule.dart`

**Fields**:

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `rounding` | `RoundingConfig` | Yes | Rounding policy |

**Constructor**:

```dart
class AllocationRule {
  final RoundingConfig rounding;

  const AllocationRule({required this.rounding});

  // Factory: Create from currency code (auto-derives precision)
  factory AllocationRule.fromCurrency(String currencyCode) {
    return AllocationRule(
      rounding: RoundingConfig.fromCurrency(currencyCode),
    );
  }
}
```

**Example**:

```dart
// Auto-derived for USD (2 decimal places)
final usdRule = AllocationRule.fromCurrency('USD');

// Auto-derived for VND (0 decimal places)
final vndRule = AllocationRule.fromCurrency('VND');
```

---

### 10. RoundingConfig

**Purpose**: Defines rounding precision, mode, and remainder distribution.

**Location**: `/lib/features/expenses/domain/models/rounding_config.dart`

**Fields**:

| Field | Type | Required | Description | Constraints |
|-------|------|----------|-------------|-------------|
| `precision` | `int` | Yes | Decimal places to round to | 0-4, derived from currency |
| `mode` | `RoundingMode` | Yes | Rounding algorithm | Enum value |
| `distributeRemainderTo` | `RemainderDistributionMode` | Yes | How to distribute remainder | Enum value |

**Enums**:

```dart
enum RoundingMode {
  /// Round 0.5 up (standard)
  roundHalfUp,

  /// Round 0.5 to nearest even (banker's rounding)
  roundHalfEven,

  /// Always round down
  floor,

  /// Always round up
  ceil,
}

enum RemainderDistributionMode {
  /// Assign to person with largest item subtotal
  largestShare,

  /// Assign to payer
  payer,

  /// Assign to first person (alphabetically by userId)
  firstListed,

  /// Assign randomly (seeded by expense ID for determinism)
  random,
}
```

**Constructor**:

```dart
class RoundingConfig {
  final int precision;
  final RoundingMode mode;
  final RemainderDistributionMode distributeRemainderTo;

  const RoundingConfig({
    required this.precision,
    this.mode = RoundingMode.roundHalfUp,
    this.distributeRemainderTo = RemainderDistributionMode.largestShare,
  });

  // Factory: Create from currency code
  factory RoundingConfig.fromCurrency(String currencyCode) {
    return RoundingConfig(
      precision: Iso4217Precision.getPrecision(currencyCode),
    );
  }
}
```

**Example**:

```dart
// Default USD rounding (2 decimals, round half up, largest share)
final usdRounding = RoundingConfig.fromCurrency('USD');
// precision: 2, mode: roundHalfUp, distributeRemainderTo: largestShare

// Custom configuration
final customRounding = RoundingConfig(
  precision: 2,
  mode: RoundingMode.roundHalfEven,
  distributeRemainderTo: RemainderDistributionMode.payer,
);
```

---

### 11. ParticipantBreakdown

**Purpose**: Detailed audit trail showing how a participant's total was calculated.

**Location**: `/lib/features/expenses/domain/models/participant_breakdown.dart`

**Fields**:

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `userId` | `String` | Yes | Participant user ID |
| `itemSubtotal` | `Decimal` | Yes | Sum of assigned item shares |
| `taxAllocated` | `Decimal` | Yes | Allocated tax amount |
| `tipAllocated` | `Decimal` | Yes | Allocated tip amount |
| `feesAllocated` | `Decimal` | Yes | Allocated fees total |
| `discountsAllocated` | `Decimal` | Yes | Allocated discounts total (negative) |
| `roundingAdjustment` | `Decimal` | Yes | Rounding remainder adjustment |
| `total` | `Decimal` | Yes | Final amount owed |
| `itemContributions` | `List<ItemContribution>` | Yes | Per-item breakdown |

**Computed Property**:

```dart
/// Verify breakdown integrity
bool isValid() {
  final computed = itemSubtotal +
                   taxAllocated +
                   tipAllocated +
                   feesAllocated +
                   discountsAllocated +
                   roundingAdjustment;

  return (computed - total).abs() < Decimal.parse('0.001');
}
```

**Example**:

```dart
final aliceBreakdown = ParticipantBreakdown(
  userId: 'alice',
  itemSubtotal: Decimal.parse('66.67'),
  taxAllocated: Decimal.parse('5.92'),
  tipAllocated: Decimal.parse('14.52'),
  feesAllocated: Decimal.zero,
  discountsAllocated: Decimal.zero,
  roundingAdjustment: Decimal.parse('0.01'),
  total: Decimal.parse('87.12'),
  itemContributions: [
    ItemContribution(itemId: 'item1', itemName: 'Steak', amount: Decimal.parse('50.00')),
    ItemContribution(itemId: 'item2', itemName: 'Wine', amount: Decimal.parse('16.67')),
  ],
);
```

---

### 12. ItemContribution

**Purpose**: Shows how much a participant owes for a specific line item.

**Location**: `/lib/features/expenses/domain/models/item_contribution.dart`

**Fields**:

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `itemId` | `String` | Yes | Reference to LineItem.id |
| `itemName` | `String` | Yes | Item name (for display) |
| `amount` | `Decimal` | Yes | Share amount for this item |

**Example**:

```dart
final contribution = ItemContribution(
  itemId: 'item_001',
  itemName: 'Ribeye Steak',
  amount: Decimal.parse('25.00'), // Alice's share of $50 item
);
```

---

## Supporting Enums

### PercentBase

**Purpose**: Defines what a percentage-based extra (tax/tip/fee) is calculated on.

**Location**: `/lib/features/expenses/domain/models/percent_base.dart`

```dart
enum PercentBase {
  /// Sum of all item prices (no extras)
  preTaxItemSubtotals,

  /// Sum of only items marked as taxable
  taxableItemSubtotalsOnly,

  /// Item subtotals after discounts applied
  postDiscountItemSubtotals,

  /// Items + Tax
  postTaxSubtotals,

  /// Items + Tax + Fees
  postFeesSubtotals,
}
```

**Usage**:

```dart
// Tax on all items
final tax = TaxExtra(
  percentValue: Decimal.parse('8.875'),
  base: PercentBase.preTaxItemSubtotals,
);

// Tip on subtotal + tax (common in US)
final tip = TipExtra(
  percentValue: Decimal.parse('20'),
  base: PercentBase.postTaxSubtotals,
);
```

---

### AbsoluteSplitMode

**Purpose**: Defines how absolute-value extras (fees/discounts) are split among participants.

**Location**: `/lib/features/expenses/domain/models/absolute_split_mode.dart`

```dart
enum AbsoluteSplitMode {
  /// Divide evenly among all participants
  /// Example: $6 fee, 3 people -> $2 each
  evenAcrossAllParticipants,

  /// Allocate proportionally to item subtotals
  /// Example: Alice has $40 items, Bob $20 of $60 total
  ///          $6 fee -> Alice $4, Bob $2
  proportionalToItemSubtotals,
}
```

**Usage**:

```dart
// Delivery fee split evenly
final deliveryFee = FeeExtra(
  name: 'Delivery',
  absoluteValue: Decimal.fromInt(5),
  absoluteSplit: AbsoluteSplitMode.evenAcrossAllParticipants,
);

// Service charge allocated proportionally
final serviceFee = FeeExtra(
  name: 'Service Charge',
  absoluteValue: Decimal.fromInt(10),
  absoluteSplit: AbsoluteSplitMode.proportionalToItemSubtotals,
);
```

---

## State Transitions (ItemizedExpenseCubit)

### States

```dart
sealed class ItemizedExpenseState {}

/// Initial state - no data yet
class ItemizedExpenseInitial extends ItemizedExpenseState {}

/// Editing in progress
class ItemizedExpenseEditing extends ItemizedExpenseState {
  final List<LineItem> items;
  final Extras extras;
  final AllocationRule allocation;
  final Map<String, ParticipantBreakdown> breakdowns;
  final List<ValidationError> validationErrors;

  bool get isValid => validationErrors.isEmpty;
}

/// Calculating breakdowns (async operation)
class ItemizedExpenseCalculating extends ItemizedExpenseState {}

/// Ready to save (all validation passed)
class ItemizedExpenseReady extends ItemizedExpenseState {
  final Expense expense; // Complete expense ready for save
}

/// Saving to Firestore
class ItemizedExpenseSaving extends ItemizedExpenseState {}

/// Successfully saved
class ItemizedExpenseSaved extends ItemizedExpenseState {
  final String expenseId;
}

/// Error occurred
class ItemizedExpenseError extends ItemizedExpenseState {
  final String message;
}
```

### State Machine

```
[Initial]
    |
    v
[Editing] <---+
    |         |
    | recalculate()
    v         |
[Calculating]-+
    |
    | (valid)
    v
[Ready]
    |
    | save()
    v
[Saving]
    |
    +---(success)----> [Saved]
    |
    +---(error)------> [Error]
```

### Transitions

| From State | Action | To State | Conditions |
|------------|--------|----------|------------|
| Initial | init() | Editing | Load trip participants |
| Editing | addItem() | Editing | Item added to draft |
| Editing | updateItem() | Editing | Item modified |
| Editing | removeItem() | Editing | Item removed |
| Editing | setTax() | Editing | Tax updated |
| Editing | setTip() | Editing | Tip updated |
| Editing | addFee() | Editing | Fee added |
| Editing | recalculate() | Calculating | Trigger recalc |
| Calculating | - | Editing | Breakdowns computed, validation errors found |
| Calculating | - | Ready | Breakdowns computed, no errors |
| Ready | save() | Saving | User confirms save |
| Saving | - | Saved | Firestore write success |
| Saving | - | Error | Firestore write failure |
| Error | retry() | Saving | User retries save |
| Saved | - | (exit flow) | Navigate back |

---

## Relationships Diagram

```
Trip (existing)
  |
  | 1:N
  v
Expense
  ├─ splitType (enum)
  ├─ items (0..300)
  │    └─> LineItem
  │         └─> ItemAssignment
  │              ├─ mode (enum)
  │              └─ customShares (Map)
  ├─ extras (optional)
  │    └─> Extras
  │         ├─> TaxExtra
  │         ├─> TipExtra
  │         ├─> List<FeeExtra>
  │         └─> List<DiscountExtra>
  ├─ allocation (optional)
  │    └─> AllocationRule
  │         └─> RoundingConfig
  ├─ participantAmounts (Map)
  └─ participantBreakdown (Map)
       └─> ParticipantBreakdown
            └─> List<ItemContribution>
```

---

## Validation Rules Summary

### Expense-Level Validation

1. `amount > 0`
2. `date <= now()`
3. If `splitType == itemized`:
   - `items` not empty
   - `participantAmounts` not empty
   - `sum(participantAmounts.values) == amount` (within epsilon)
   - All items assigned
4. If `splitType != itemized`:
   - `participants` map required

### LineItem Validation

1. `name` length 1-100
2. `quantity > 0`
3. `unitPrice >= 0`
4. At least one assigned user
5. If custom shares: sum == 1.0

### Extras Validation

1. Each extra must be either percent OR absolute (not both, not neither)
2. Percentages: 0-100
3. Absolute values: >= 0
4. Percent-based extras require `base`
5. Absolute extras require split mode

### Rounding Validation

1. `precision` 0-4
2. `mode` valid enum
3. `distributeRemainderTo` valid enum

---

## Data Integrity Invariants

### Conservation of Money

```dart
// Invariant 1: Sum of participant amounts equals grand total
assert(
  participantAmounts.values.sum() == expense.amount,
  'Sum of shares must equal total',
);

// Invariant 2: Each breakdown total matches participantAmount
for (final entry in participantBreakdown.entries) {
  final userId = entry.key;
  final breakdown = entry.value;

  assert(
    breakdown.total == participantAmounts[userId],
    'Breakdown total must match participant amount',
  );
}

// Invariant 3: Breakdown components sum to total
for (final breakdown in participantBreakdown.values) {
  final computed = breakdown.itemSubtotal +
                   breakdown.taxAllocated +
                   breakdown.tipAllocated +
                   breakdown.feesAllocated +
                   breakdown.discountsAllocated +
                   breakdown.roundingAdjustment;

  assert(
    (computed - breakdown.total).abs() < epsilon,
    'Breakdown components must sum to total',
  );
}
```

### Assignment Completeness

```dart
// Invariant 4: All items must be assigned
for (final item in items) {
  assert(
    item.assignedUserIds.isNotEmpty,
    'Item ${item.id} must be assigned',
  );
}

// Invariant 5: Custom shares must sum to 1.0
for (final item in items) {
  if (item.assignment.mode == AssignmentMode.custom) {
    final sum = item.assignment.customShares!.values.sum();
    assert(
      (sum - Decimal.one).abs() < Decimal.parse('0.0001'),
      'Custom shares must sum to 1.0',
    );
  }
}
```

---

## Performance Considerations

### Memory

- **LineItem**: ~200 bytes each
- **ParticipantBreakdown**: ~500 bytes each
- **Max 300 items, 6 participants**: ~60KB + 3KB = ~63KB per expense
- Well within Flutter memory limits

### Computation

- **Calculation complexity**: O(I × P) where I = items, P = participants
- **Worst case**: 300 items × 6 participants = 1,800 operations
- **Estimated time**: <50ms on modern devices (Decimal arithmetic overhead)

### Storage (Firestore)

- **Document size**: Max ~100KB for 300-item receipt with full breakdown
- **Firestore limit**: 1MB per document (safe margin)
- **Indexes**: No new indexes required (existing `tripId` + `createdAt` sufficient)

---

## Migration Notes

### Backward Compatibility

- All new fields are **optional** (nullable in Dart)
- Existing expenses (`splitType: equal/weighted`) have `items == null`
- No manual migration required
- Old clients ignore new fields (forward compatible)
- New clients handle old expenses gracefully (backward compatible)

### Forward Evolution

If future features require schema changes:

1. Add new optional fields to `Expense`
2. Update `ExpenseModel.fromFirestore()` with null checks
3. Update `ExpenseModel.toFirestore()` with conditional serialization
4. Add validation in domain layer
5. No database migration needed

---

## File References

| Entity | Domain Model | Firestore DTO | Location |
|--------|--------------|---------------|----------|
| Expense | `/lib/features/expenses/domain/models/expense.dart` | `/lib/features/expenses/data/models/expense_model.dart` | Existing (extend) |
| LineItem | `/lib/features/expenses/domain/models/line_item.dart` | `/lib/features/expenses/data/models/line_item_model.dart` | New |
| ItemAssignment | `/lib/features/expenses/domain/models/item_assignment.dart` | (embedded in LineItem) | New |
| Extras | `/lib/features/expenses/domain/models/extras.dart` | `/lib/features/expenses/data/models/extras_model.dart` | New |
| TaxExtra | `/lib/features/expenses/domain/models/tax_extra.dart` | (embedded in Extras) | New |
| TipExtra | `/lib/features/expenses/domain/models/tip_extra.dart` | (embedded in Extras) | New |
| FeeExtra | `/lib/features/expenses/domain/models/fee_extra.dart` | (embedded in Extras) | New |
| DiscountExtra | `/lib/features/expenses/domain/models/discount_extra.dart` | (embedded in Extras) | New |
| AllocationRule | `/lib/features/expenses/domain/models/allocation_rule.dart` | `/lib/features/expenses/data/models/allocation_rule_model.dart` | New |
| RoundingConfig | `/lib/features/expenses/domain/models/rounding_config.dart` | (embedded in AllocationRule) | New |
| ParticipantBreakdown | `/lib/features/expenses/domain/models/participant_breakdown.dart` | (embedded in Expense) | New |
| ItemContribution | `/lib/features/expenses/domain/models/item_contribution.dart` | (embedded in Breakdown) | New |

---

**Status**: Design Complete, Ready for Implementation
**Last Updated**: 2025-10-28
**Next Step**: Generate JSON schema contracts in `contracts/` directory
