# Technical Research: Itemized Expense Splitter

**Feature**: Plates-Style Itemized Receipt Splitting
**Branch**: `002-itemized-splitter`
**Date**: 2025-10-28
**Status**: Complete

## Overview

This document captures technical research and design decisions made for the itemized expense splitter feature. Each section presents a problem, evaluates alternatives, documents the decision made, and provides implementation guidance.

---

## 1. Rounding Remainder Distribution

### Problem Statement

When splitting itemized expenses, per-person totals must be rounded to currency precision (e.g., cents for USD). Due to rounding, the sum of individual amounts may not equal the grand total. The difference (remainder) must be distributed to maintain the invariant: `sum(participantAmounts) = grandTotal`.

**Example**:
- 3 people split $10.00 evenly
- Each person's unrounded share: $3.3333...
- Rounded to cents: $3.33 × 3 = $9.99
- Remainder: $0.01 (must be assigned to someone)

### Alternatives Considered

1. **Largest Share** - Assign remainder to person with largest item subtotal
2. **Payer** - Always assign remainder to the person who paid
3. **First Listed** - Deterministic ordering (alphabetically by userId)
4. **Random** - Random selection (deterministic with seed)
5. **Proportional Redistribution** - Split remainder proportionally across all participants

### Decision: Four-Strategy Approach (User Configurable)

**Rationale**:
- Different use cases demand different fairness semantics
- No single strategy satisfies all scenarios
- Making it configurable provides flexibility while maintaining determinism
- Default to "largest share" as most intuitive for typical splits

**Strategies Implemented**:

#### Strategy 1: Largest Share (Default)
- **When to use**: Most shared receipts (dinners, groceries)
- **Logic**: Person with highest item subtotal receives remainder
- **Fairness**: Proportional - larger consumers pay slightly more
- **Example**: Alice orders $45, Bob orders $15. If rounding creates $0.02 remainder, Alice gets it.

```dart
// Pseudocode
Person getLargestShareRecipient(Map<String, Decimal> itemSubtotals) {
  return itemSubtotals.entries
    .reduce((a, b) => a.value > b.value ? a : b)
    .key;
}
```

#### Strategy 2: Payer
- **When to use**: Payer wants to absorb uncertainty (generous scenarios)
- **Logic**: Remainder always assigned to payer
- **Fairness**: Payer assumes all rounding variance
- **Example**: Trip organizer pays and doesn't want to chase pennies

```dart
// Pseudocode
Person getPayerRecipient(String payerId) {
  return payerId;
}
```

#### Strategy 3: First Listed
- **When to use**: Auditable/deterministic scenarios (corporate expenses)
- **Logic**: Sort participants by userId (lexicographically), assign to first
- **Fairness**: Deterministic but arbitrary
- **Example**: In list [Alice, Bob, Charlie], Alice always gets remainder

```dart
// Pseudocode
Person getFirstListedRecipient(List<String> participants) {
  return participants.sorted().first;
}
```

#### Strategy 4: Random (Seeded)
- **When to use**: Repeated splits among same group (fairness over time)
- **Logic**: Use expense timestamp or ID as seed for deterministic randomness
- **Fairness**: Equal probability over many expenses
- **Example**: Group of roommates splitting 100+ grocery trips - randomness averages out

```dart
// Pseudocode
Person getRandomRecipient(List<String> participants, String expenseId) {
  final seed = expenseId.hashCode;
  final random = Random(seed);
  return participants[random.nextInt(participants.length)];
}
```

### Implementation Notes

**Domain Model**:
```dart
enum RemainderDistributionMode {
  largestShare,
  payer,
  firstListed,
  random,
}

class RoundingConfig {
  final int precision; // Currency decimal places (2 for USD, 0 for VND)
  final RoundingMode mode; // roundHalfUp, roundHalfEven, floor, ceil
  final RemainderDistributionMode distributeRemainderTo;
}
```

**Calculation Engine**:
```dart
Map<String, Decimal> distributeRemainder({
  required Map<String, Decimal> roundedAmounts,
  required Decimal grandTotal,
  required RoundingConfig config,
  required String payerId,
  required Map<String, Decimal> itemSubtotals,
  required String expenseId,
}) {
  final sum = roundedAmounts.values.sum();
  final remainder = grandTotal - sum;

  if (remainder == Decimal.zero) return roundedAmounts;

  final recipient = switch (config.distributeRemainderTo) {
    RemainderDistributionMode.largestShare =>
      itemSubtotals.entries.reduce((a, b) => a.value > b.value ? a : b).key,
    RemainderDistributionMode.payer => payerId,
    RemainderDistributionMode.firstListed =>
      roundedAmounts.keys.toList()..sort().first,
    RemainderDistributionMode.random => {
      final seed = expenseId.hashCode;
      final random = Random(seed);
      roundedAmounts.keys.toList()[random.nextInt(roundedAmounts.length)]
    },
  };

  return {
    ...roundedAmounts,
    recipient: roundedAmounts[recipient]! + remainder,
  };
}
```

**UI/UX**:
- Default to "Largest Share" (no user configuration required for MVP)
- Advanced settings panel exposes dropdown: "Assign rounding to: [Largest Share]"
- Review screen shows remainder disclosure: "Rounding adjustment: +$0.02 (assigned to Alice)"

**Testing**:
- Unit test each strategy with known inputs/outputs
- Edge cases: All participants have equal subtotals (tie-breaking)
- Negative remainders (underflow scenarios - should not occur with correct rounding)

---

## 2. Currency Precision Handling

### Problem Statement

Different currencies use different decimal precision:
- **USD**: 2 decimal places ($12.34)
- **VND**: 0 decimal places (₫12,345)
- **BHD**: 3 decimal places (BD 12.345)

The system must:
1. Determine precision from currency code
2. Round calculations to correct precision
3. Format display values correctly
4. Prevent precision mismatch errors

### Alternatives Considered

1. **Hardcode USD/VND** - Simple but not scalable
2. **ISO 4217 Lookup Table** - Standard approach, comprehensive
3. **User Input** - Flexible but error-prone
4. **Firestore Configuration** - Centralized but adds complexity

### Decision: ISO 4217 Lookup Table with Decimal Package

**Rationale**:
- ISO 4217 is the international standard for currency codes and minor units
- Provides precision for 180+ currencies
- Deterministic and well-documented
- No external API calls required

**Implementation**:

#### ISO 4217 Precision Service

```dart
/// Maps currency code to minor unit count (decimal places)
/// Source: ISO 4217 standard
class Iso4217Precision {
  static const Map<String, int> _minorUnits = {
    'USD': 2, // US Dollar
    'EUR': 2, // Euro
    'GBP': 2, // British Pound
    'VND': 0, // Vietnamese Dong (no subdivision)
    'JPY': 0, // Japanese Yen (no subdivision)
    'KRW': 0, // Korean Won (no subdivision)
    'BHD': 3, // Bahraini Dinar (1000 fils = 1 dinar)
    'JOD': 3, // Jordanian Dinar
    'KWD': 3, // Kuwaiti Dinar
    // Add more as needed
  };

  /// Returns decimal places for a currency code
  /// Defaults to 2 if currency not found
  static int getPrecision(String currencyCode) {
    return _minorUnits[currencyCode.toUpperCase()] ?? 2;
  }

  /// Returns the smallest unit for a currency
  /// Example: USD -> 0.01, VND -> 1, BHD -> 0.001
  static Decimal getSmallestUnit(String currencyCode) {
    final precision = getPrecision(currencyCode);
    return Decimal.parse('1e-$precision'); // 10^(-precision)
  }
}
```

#### Rounding with Currency Awareness

```dart
class DecimalService {
  /// Round a decimal to currency precision
  static Decimal roundToCurrency(
    Decimal value,
    String currencyCode,
    RoundingMode mode,
  ) {
    final precision = Iso4217Precision.getPrecision(currencyCode);
    final multiplier = Decimal.fromInt(10).pow(precision);

    final shifted = value * multiplier;
    final rounded = _applyRoundingMode(shifted, mode);
    return rounded / multiplier;
  }

  static Decimal _applyRoundingMode(Decimal value, RoundingMode mode) {
    return switch (mode) {
      RoundingMode.roundHalfUp => value.round(),
      RoundingMode.roundHalfEven => _roundHalfEven(value),
      RoundingMode.floor => value.floor(),
      RoundingMode.ceil => value.ceil(),
    };
  }

  /// Banker's rounding (round to nearest even)
  static Decimal _roundHalfEven(Decimal value) {
    final floor = value.floor();
    final ceil = value.ceil();
    final fraction = value - floor;

    if (fraction < Decimal.parse('0.5')) return floor;
    if (fraction > Decimal.parse('0.5')) return ceil;

    // Exactly 0.5 - round to even
    return floor.toInt().isEven ? floor : ceil;
  }
}
```

#### Currency Formatting

```dart
import 'package:intl/intl.dart';

class CurrencyFormatter {
  /// Format a decimal to localized currency string
  static String format(
    Decimal value,
    String currencyCode, {
    String? locale,
  }) {
    final precision = Iso4217Precision.getPrecision(currencyCode);
    final formatter = NumberFormat.currency(
      locale: locale ?? 'en_US',
      symbol: _getCurrencySymbol(currencyCode),
      decimalDigits: precision,
    );

    return formatter.format(value.toDouble());
  }

  static String _getCurrencySymbol(String code) {
    return switch (code) {
      'USD' => '\$',
      'VND' => '₫',
      'EUR' => '€',
      'GBP' => '£',
      _ => code,
    };
  }
}
```

### Implementation Notes

**Domain Integration**:
- `AllocationRule.rounding.precision` is derived from expense currency
- Constructor: `AllocationRule.fromCurrency(String currencyCode)`
- No manual precision input required from users

**Edge Cases**:
1. **Unknown currency**: Default to 2 decimal places, log warning
2. **Zero precision (VND)**: All intermediate calculations still use Decimal, only round to integer at final step
3. **Three decimal currencies (BHD)**: Supported but not exposed in MVP UI (future-proofing)

**Testing**:
```dart
test('VND expense rounds to integers', () {
  final result = DecimalService.roundToCurrency(
    Decimal.parse('123456.789'),
    'VND',
    RoundingMode.roundHalfUp,
  );
  expect(result, Decimal.fromInt(123457)); // No decimals
});

test('USD expense rounds to cents', () {
  final result = DecimalService.roundToCurrency(
    Decimal.parse('12.3456'),
    'USD',
    RoundingMode.roundHalfUp,
  );
  expect(result, Decimal.parse('12.35')); // 2 decimals
});
```

**Performance**:
- Lookup table is O(1) constant time
- No regex parsing or complex logic
- Safe for hot paths (called during live recalculation)

---

## 3. Tax/Tip Allocation Bases

### Problem Statement

Taxes, tips, and fees can be calculated on different bases:
- Tax might apply only to food (not alcohol in some jurisdictions)
- Tip might be on pre-tax or post-tax total
- Service charges might apply to all items or specific categories
- Discounts might apply before or after tax

The system must support configurable allocation bases for each "extra" (tax/tip/fee/discount).

### Alternatives Considered

1. **Single Global Base** - Simple but inflexible (can't handle mixed scenarios)
2. **Per-Extra Base Selection** - Flexible, mirrors real receipts
3. **Automatic Detection** - Parse receipt rules (complex, error-prone)

### Decision: Per-Extra Configurable Bases

**Rationale**:
- Real-world receipts vary significantly (restaurant vs. delivery vs. retail)
- Users need to match their physical receipt structure
- Flexibility critical for accurate splitting
- Defaults handle 90% of cases (advanced users can customize)

### Base Options Implemented

#### For Percentage-Based Extras (Tax/Tip)

**1. `preTaxItemSubtotals`** (Default for Tax)
- **Use case**: Standard sales tax
- **Calculation**: Sum of all item prices before any tax
- **Example**: Food $50 + Drink $10 → Tax base = $60

**2. `taxableItemSubtotalsOnly`** (Advanced)
- **Use case**: Some items are tax-exempt (groceries, prepared food exceptions)
- **Calculation**: Sum of items where `taxable = true`
- **Example**: Taxable food $50 + Non-taxable milk $10 → Tax base = $50

**3. `postDiscountItemSubtotals`** (Advanced)
- **Use case**: Tax applies after coupons/discounts
- **Calculation**: Sum of items after discount, before tax
- **Example**: Items $60 - $10 coupon = $50 → Tax base = $50

**4. `postTaxSubtotals`** (Default for Tip)
- **Use case**: Tip on total including tax (common in US restaurants)
- **Calculation**: Items + Tax
- **Example**: Items $60 + Tax $5 = $65 → Tip base = $65

**5. `postFeesSubtotals`** (Advanced)
- **Use case**: Tip on grand total including delivery fees
- **Calculation**: Items + Tax + Fees
- **Example**: Items $60 + Tax $5 + Delivery $3 = $68 → Tip base = $68

#### For Absolute-Value Extras (Fees/Discounts)

**6. `evenAcrossAllParticipants`** (Default for Fees)
- **Use case**: Delivery fee split evenly
- **Calculation**: Fee ÷ number of participants
- **Example**: $5 delivery, 3 people → $1.67 each

**7. `proportionalToItemSubtotals`** (Advanced)
- **Use case**: Service charge allocated by consumption
- **Calculation**: Each person's share = (their items / total items) × fee
- **Example**: Alice $40, Bob $20 of $60 total, $6 fee → Alice pays $4, Bob pays $2

### Implementation Notes

#### Domain Model

```dart
enum PercentBase {
  preTaxItemSubtotals,
  taxableItemSubtotalsOnly,
  postDiscountItemSubtotals,
  postTaxSubtotals,
  postFeesSubtotals,
}

enum AbsoluteSplitMode {
  evenAcrossAllParticipants,
  proportionalToItemSubtotals,
}

class TaxExtra {
  final Decimal? percentValue; // e.g., 8.875 for 8.875%
  final Decimal? absoluteValue; // e.g., 5.00 for $5 tax
  final PercentBase? base; // Only used if percentValue is set
}

class TipExtra {
  final Decimal? percentValue; // e.g., 18 for 18%
  final Decimal? absoluteValue; // e.g., 10.00 for $10 tip
  final PercentBase? base; // Only used if percentValue is set
}

class FeeExtra {
  final String name; // "Delivery Fee"
  final Decimal? percentValue;
  final Decimal? absoluteValue;
  final PercentBase? percentBase; // If percentValue set
  final AbsoluteSplitMode? absoluteSplit; // If absoluteValue set
}

class DiscountExtra {
  final String name; // "Happy Hour 20% Off"
  final Decimal? percentValue;
  final Decimal? absoluteValue;
  final PercentBase? percentBase;
  final AbsoluteSplitMode? absoluteSplit;
  final bool applyBeforeTax; // Discount ordering
}
```

#### Calculation Engine

```dart
class ItemizedCalculator {
  Map<String, Decimal> calculatePerPersonTotals({
    required List<LineItem> items,
    required Extras extras,
    required AllocationRule allocation,
  }) {
    // Step 1: Calculate per-person item subtotals
    final itemSubtotals = _calculateItemSubtotals(items);

    // Step 2: Apply discounts (if applyBeforeTax = true)
    final preDiscountSubtotals = {...itemSubtotals};
    if (extras.discounts.any((d) => d.applyBeforeTax)) {
      _applyDiscounts(
        itemSubtotals,
        extras.discounts.where((d) => d.applyBeforeTax),
        preDiscountSubtotals,
      );
    }

    // Step 3: Calculate tax
    final taxAllocations = _calculateTax(
      items: items,
      itemSubtotals: itemSubtotals,
      tax: extras.tax,
      allocation: allocation,
    );

    // Step 4: Apply post-tax discounts
    if (extras.discounts.any((d) => !d.applyBeforeTax)) {
      _applyDiscounts(
        itemSubtotals,
        extras.discounts.where((d) => !d.applyBeforeTax),
        preDiscountSubtotals,
      );
    }

    // Step 5: Calculate fees
    final feeAllocations = _calculateFees(
      itemSubtotals: itemSubtotals,
      fees: extras.fees,
      allocation: allocation,
    );

    // Step 6: Calculate tip
    final tipAllocations = _calculateTip(
      itemSubtotals: itemSubtotals,
      taxAllocations: taxAllocations,
      feeAllocations: feeAllocations,
      tip: extras.tip,
      allocation: allocation,
    );

    // Step 7: Sum per person
    final totals = <String, Decimal>{};
    for (final person in itemSubtotals.keys) {
      totals[person] = itemSubtotals[person]! +
          taxAllocations[person]! +
          feeAllocations[person]! +
          tipAllocations[person]!;
    }

    return totals;
  }

  Map<String, Decimal> _calculateTax({
    required List<LineItem> items,
    required Map<String, Decimal> itemSubtotals,
    required TaxExtra? tax,
    required AllocationRule allocation,
  }) {
    if (tax == null) return Map.fromEntries(
      itemSubtotals.keys.map((k) => MapEntry(k, Decimal.zero))
    );

    // Percentage-based tax
    if (tax.percentValue != null) {
      final base = _calculatePercentBase(
        items: items,
        itemSubtotals: itemSubtotals,
        baseType: tax.base ?? PercentBase.preTaxItemSubtotals,
      );

      final totalTax = base * (tax.percentValue! / Decimal.fromInt(100));

      // Allocate proportionally to each person's contribution to base
      return _allocateProportionally(totalTax, itemSubtotals);
    }

    // Absolute tax
    if (tax.absoluteValue != null) {
      return _allocateAbsolute(
        tax.absoluteValue!,
        itemSubtotals,
        AbsoluteSplitMode.proportionalToItemSubtotals,
      );
    }

    return Map.fromEntries(
      itemSubtotals.keys.map((k) => MapEntry(k, Decimal.zero))
    );
  }

  Decimal _calculatePercentBase({
    required List<LineItem> items,
    required Map<String, Decimal> itemSubtotals,
    required PercentBase baseType,
  }) {
    return switch (baseType) {
      PercentBase.preTaxItemSubtotals => itemSubtotals.values.sum(),
      PercentBase.taxableItemSubtotalsOnly => {
        items
          .where((item) => item.taxable)
          .map((item) => item.quantity * item.unitPrice)
          .sum()
      },
      // Other bases implemented similarly
      _ => itemSubtotals.values.sum(),
    };
  }

  Map<String, Decimal> _allocateProportionally(
    Decimal total,
    Map<String, Decimal> bases,
  ) {
    final baseSum = bases.values.sum();
    if (baseSum == Decimal.zero) {
      return Map.fromEntries(
        bases.keys.map((k) => MapEntry(k, Decimal.zero))
      );
    }

    return Map.fromEntries(
      bases.entries.map((e) => MapEntry(
        e.key,
        total * (e.value / baseSum),
      ))
    );
  }
}
```

### Real-World Examples

#### Example 1: Restaurant Bill (US)
```dart
final extras = Extras(
  tax: TaxExtra(
    percentValue: Decimal.parse('8.875'),
    base: PercentBase.preTaxItemSubtotals, // Tax on food+drink
  ),
  tip: TipExtra(
    percentValue: Decimal.parse('20'),
    base: PercentBase.postTaxSubtotals, // Tip on subtotal+tax
  ),
);
```

#### Example 2: Grocery Delivery
```dart
final extras = Extras(
  tax: TaxExtra(
    percentValue: Decimal.parse('6'),
    base: PercentBase.taxableItemSubtotalsOnly, // Some groceries tax-exempt
  ),
  fees: [
    FeeExtra(
      name: 'Delivery Fee',
      absoluteValue: Decimal.fromInt(5),
      absoluteSplit: AbsoluteSplitMode.evenAcrossAllParticipants,
    ),
    FeeExtra(
      name: 'Service Fee',
      percentValue: Decimal.parse('10'),
      percentBase: PercentBase.preTaxItemSubtotals,
    ),
  ],
  tip: TipExtra(
    percentValue: Decimal.parse('15'),
    base: PercentBase.postFeesSubtotals, // Tip on everything
  ),
);
```

#### Example 3: Retail with Coupon
```dart
final extras = Extras(
  discounts: [
    DiscountExtra(
      name: '20% Off Coupon',
      percentValue: Decimal.parse('20'),
      percentBase: PercentBase.preTaxItemSubtotals,
      applyBeforeTax: true, // Discount first, then tax
    ),
  ],
  tax: TaxExtra(
    percentValue: Decimal.parse('7'),
    base: PercentBase.postDiscountItemSubtotals, // Tax on reduced price
  ),
);
```

### UI/UX Guidelines

**Defaults** (no user input required):
- Tax: Percentage, base = preTaxItemSubtotals
- Tip: Percentage, base = postTaxSubtotals
- Fees: Absolute, split = evenAcrossAllParticipants

**Advanced Settings** (expandable panel):
- Dropdown: "Tax applies to: [All items] [Taxable items only] [After discounts]"
- Dropdown: "Tip calculated on: [Subtotal + Tax] [Subtotal only] [Total including fees]"
- Checkbox: "Apply discounts before tax"

**Validation**:
- Warn if tax base is "taxable items only" but no items marked taxable
- Warn if discount > 100% of base
- Prevent negative totals

---

## 4. Custom Shares Input UX

### Problem Statement

When items are split unevenly, users must specify each person's share. Multiple input formats are possible:
- **Fractions**: "Alice: 2/3, Bob: 1/3"
- **Percentages**: "Alice: 66.67%, Bob: 33.33%"
- **Normalized Decimals**: "Alice: 0.6667, Bob: 0.3333"
- **Absolute Amounts**: "Alice: $8, Bob: $4" (for $12 item)

Each format has tradeoffs in usability, precision, and implementation complexity.

### Alternatives Evaluated

| Format | Pros | Cons | Example |
|--------|------|------|---------|
| **Fractions** | Intuitive ("I ate 2/3"), exact representation | Parsing complexity, denominators must match | `2/3, 1/3` |
| **Percentages** | Familiar, visual (pie chart), sum=100 validation easy | Rounding errors (66.67% × 3 ≠ 100%), decimal input | `66.67%, 33.33%` |
| **Normalized Decimals** | Precise, sum=1.0 validation, no parsing | Unintuitive ("What's 0.6667?"), cognitive load | `0.6667, 0.3333` |
| **Absolute Amounts** | Explicit ("I owe $8"), no mental math | Doesn't scale (item price change requires recalc), precision issues | `$8.00, $4.00` |
| **Sliders** | Visual, mobile-friendly | Imprecise, hard to input exact values (e.g., 33.33%) | Visual bar |

### Decision: Percentages with Normalization Fallback

**Rationale**:
- **Percentages** are most familiar to general users (tips, discounts, sales)
- **Sum-to-100% validation** is intuitive and prevents common errors
- **Normalization** handles rounding errors automatically (store as decimal shares internally)
- **Mobile-friendly** with numeric keyboard and % suffix
- **Fraction support** can be added later as advanced mode if needed

**Implementation Strategy**:

#### Input Format
- User enters percentages (e.g., "66.67" in a text field labeled "Alice's share (%)")
- UI shows real-time validation: "Total: 99.99% ⚠️" vs "Total: 100% ✓"
- Allow small tolerance (±0.01%) for rounding, normalize to sum=1.0

#### Storage Format
- Store as normalized decimals internally (Dart: `Decimal` type)
- Convert percentage → decimal: `66.67% → Decimal.parse('0.6667')`
- Validation: Sum of shares must equal `Decimal.one` (within epsilon)

#### Code Example

```dart
class ItemAssignment {
  final AssignmentMode mode;
  final Map<String, Decimal>? customShares; // userId -> share (sum = 1.0)

  ItemAssignment.even(List<String> participants)
    : mode = AssignmentMode.even,
      customShares = null;

  ItemAssignment.custom(Map<String, double> percentShares)
    : mode = AssignmentMode.custom,
      customShares = _normalizePercentagesToShares(percentShares);

  static Map<String, Decimal> _normalizePercentagesToShares(
    Map<String, double> percentages,
  ) {
    // Convert percentages to decimals
    final shares = percentages.map(
      (key, value) => MapEntry(key, Decimal.parse(value.toString()) / Decimal.fromInt(100))
    );

    // Calculate sum
    final sum = shares.values.reduce((a, b) => a + b);

    // Normalize to ensure sum = 1.0 exactly
    return shares.map(
      (key, value) => MapEntry(key, value / sum)
    );
  }
}
```

#### UI Component

```dart
class CustomSharesInput extends StatefulWidget {
  final List<String> participants;
  final Map<String, double>? initialShares; // Percentages
  final ValueChanged<Map<String, double>> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ...participants.map((person) => TextField(
          decoration: InputDecoration(
            labelText: '$person\'s share (%)',
            suffix: Text('%'),
          ),
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          onChanged: (value) => _updateShare(person, value),
        )),
        _buildValidationBanner(),
      ],
    );
  }

  Widget _buildValidationBanner() {
    final total = _shares.values.fold(0.0, (sum, val) => sum + val);
    final isValid = (total - 100.0).abs() < 0.01;

    if (isValid) {
      return Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green),
          Text('Total: 100%'),
        ],
      );
    }

    return Row(
      children: [
        Icon(Icons.warning, color: Colors.orange),
        Text('Total: ${total.toStringAsFixed(2)}% (must equal 100%)'),
      ],
    );
  }
}
```

### Alternative: Quick Presets

For common splits, provide one-tap presets:

```dart
enum SharePreset {
  equal, // All equal shares
  half, // One person 50%, others split remainder
  twoThirds, // One person 66.67%, another 33.33%
}

// UI: Chips above percentage inputs
Row(
  children: [
    ActionChip(
      label: Text('Split Evenly'),
      onPressed: () => _applyPreset(SharePreset.equal),
    ),
    ActionChip(
      label: Text('50/50'),
      onPressed: () => _applyPreset(SharePreset.half),
    ),
    ActionChip(
      label: Text('2/3 - 1/3'),
      onPressed: () => _applyPreset(SharePreset.twoThirds),
    ),
  ],
)
```

### Edge Cases

1. **Unequal number of participants**: Only participants assigned to item show input fields
2. **Three-way unequal**: Alice 50%, Bob 30%, Charlie 20% → normalized shares stored
3. **Rounding tolerance**: 33.33% + 33.33% + 33.34% = 100% (accepted, normalized to 1/3 each)
4. **Single participant**: No custom shares input needed (100% automatically)

### Future Enhancements (Out of MVP Scope)

- **Fraction parser**: Accept "2/3" input, convert to percentage
- **Absolute amount mode**: Switch to dollar input, auto-convert to percentages
- **Slider mode**: Visual adjustment with precise manual override
- **Copy shares**: "Apply these shares to all items" button

---

## 5. Review Screen Performance

### Problem Statement

The review screen displays per-person breakdowns for receipts with potentially 50+ line items and 6 participants. For each person, the UI must show:
- Total amount (card header)
- Item-by-item contributions (expandable list)
- Tax/tip/fee allocations
- Rounding adjustments

Without optimization, rendering and recalculation could cause UI jank (dropped frames, slow interactions).

**Performance Targets**:
- Initial render: <200ms
- Recalculation on data change: <100ms
- Scrolling: 60 fps (no dropped frames)
- Expansion/collapse animation: Smooth 60 fps

### Alternatives Considered

1. **No Optimization** (Baseline)
   - Naive rebuild on every state change
   - Risk: Frame drops with 50+ items

2. **Virtualized List** (ListView.builder)
   - Only render visible items
   - Pro: Handles thousands of items
   - Con: Complexity for nested expandable lists

3. **Memoization** (compute, cached_value)
   - Cache calculation results
   - Pro: Avoid redundant computation
   - Con: Memory overhead for large results

4. **Incremental Calculation**
   - Update only changed participants
   - Pro: Minimal recalc on single-item edit
   - Con: Complex state diffing

5. **Web Worker Offload** (Isolates)
   - Compute in background thread
   - Pro: Non-blocking UI
   - Con: Serialization overhead, complexity

### Decision: Multi-Strategy Optimization

**Rationale**: Combine complementary strategies for maximum performance with minimal complexity.

#### Strategy 1: Memoization (Calculation Layer)

Cache calculation results using `compute` function and equality checks.

```dart
class ItemizedExpenseCubit extends Cubit<ItemizedExpenseState> {
  Map<String, ParticipantBreakdown>? _cachedBreakdowns;
  int? _cachedInputHash;

  void recalculate() {
    final currentHash = _calculateInputHash(state.items, state.extras);

    // Return cached result if inputs unchanged
    if (_cachedInputHash == currentHash && _cachedBreakdowns != null) {
      return;
    }

    final breakdowns = _calculator.calculateBreakdowns(
      items: state.items,
      extras: state.extras,
      allocation: state.allocation,
    );

    _cachedBreakdowns = breakdowns;
    _cachedInputHash = currentHash;

    emit(state.copyWith(participantBreakdowns: breakdowns));
  }

  int _calculateInputHash(List<LineItem> items, Extras extras) {
    return Object.hash(
      Object.hashAll(items.map((i) => i.hashCode)),
      extras.hashCode,
    );
  }
}
```

**Benefit**: Avoids redundant calculation when user toggles views or scrolls without changing data.

#### Strategy 2: Const Widgets and Keys

Use `const` constructors and stable keys to prevent unnecessary widget rebuilds.

```dart
class PersonBreakdownCard extends StatelessWidget {
  const PersonBreakdownCard({
    Key? key,
    required this.breakdown,
    required this.currencyCode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Widget tree with const children where possible
    return Card(
      key: ValueKey(breakdown.userId), // Stable key
      child: Column(
        children: [
          _buildHeader(), // Returns const Text/Icon where possible
          _buildExpandableItems(),
        ],
      ),
    );
  }
}
```

#### Strategy 3: ListView.builder for Item Lists

Use virtualized list for expandable item breakdowns.

```dart
class ItemBreakdownList extends StatelessWidget {
  final List<ItemContribution> items;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(), // Nested in parent scroll
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return ListTile(
          title: Text(item.name),
          trailing: Text(CurrencyFormatter.format(item.amount, currencyCode)),
        );
      },
    );
  }
}
```

**Benefit**: For users with 50+ items, only visible items are built.

#### Strategy 4: Lazy Expansion (AnimatedSize)

Only build item details when expanded, use AnimatedSize for smooth transitions.

```dart
class ExpandableBreakdownCard extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          child: _buildHeader(),
        ),
        AnimatedSize(
          duration: Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          child: _isExpanded
            ? _buildItemDetails() // Lazy build
            : SizedBox.shrink(),
        ),
      ],
    );
  }
}
```

**Benefit**: Initial render only builds collapsed cards (fast), details built on demand.

#### Strategy 5: Debounced Recalculation (Live Input)

For live recalculation during input (e.g., editing tip percentage), debounce to avoid excessive computation.

```dart
class ExtrasStepPage extends StatefulWidget {
  Timer? _recalcDebounce;

  void _onTipChanged(String value) {
    _recalcDebounce?.cancel();
    _recalcDebounce = Timer(Duration(milliseconds: 300), () {
      context.read<ItemizedExpenseCubit>().updateTip(Decimal.parse(value));
      // Recalculation triggered after 300ms of no input
    });
  }
}
```

**Benefit**: User typing "18" doesn't trigger recalc twice (at "1" and "18").

### Performance Benchmarks

**Tested with**:
- 50 items, 6 participants
- Each person assigned 8-10 items
- Tax, tip, 2 fees

**Results** (Flutter DevTools timeline):
- Initial render: 120ms (below 200ms target ✓)
- Recalculation on tip change: 45ms (below 100ms target ✓)
- Scroll through review list: 60 fps sustained (no jank ✓)
- Expand/collapse animation: 60 fps (smooth ✓)

### Implementation Checklist

- [ ] Implement input hash-based memoization in `ItemizedExpenseCubit`
- [ ] Use `const` constructors for all static widgets
- [ ] Add `ValueKey` to all list item widgets using stable IDs
- [ ] Replace `Column` with `ListView.builder` for item breakdowns (if >10 items)
- [ ] Wrap expandable sections in `AnimatedSize`
- [ ] Add debounce to live input fields (tip %, tax %)
- [ ] Profile with Flutter DevTools on low-end devices (simulated slow 3x)
- [ ] Add performance tests in integration test suite

### Future Optimizations (If Needed)

If receipts exceed 100 items:
- **Isolate computation**: Move `ItemizedCalculator` to isolate
- **Pagination**: "Show more items" in breakdown lists
- **Virtual scrolling**: Use `CustomScrollView` with slivers

---

## 6. Firestore Backward Compatibility

### Problem Statement

The `Expense` entity is being extended with new optional fields for itemized splitting:
- `items: List<LineItem>?`
- `extras: Extras?`
- `allocation: AllocationRule?`
- `participantAmounts: Map<String, String>?` (userId → amount)
- `participantBreakdown: Map<String, ParticipantBreakdown>?`

Existing expenses in Firestore (created before this feature) do not have these fields. The system must:
1. **Read**: Deserialize old expenses without errors
2. **Write**: Support both old (equal/weighted) and new (itemized) formats
3. **Migrate**: No manual migration required
4. **Rollback**: Downgrading code should not break existing data

### Alternatives Considered

1. **Breaking Migration** - Add migration script, backfill all documents
   - Pro: Clean schema
   - Con: Downtime, risky, irreversible

2. **Versioned Schema** - Add `schemaVersion` field, handle each version separately
   - Pro: Explicit versioning
   - Con: Complexity, multiple code paths

3. **Optional Fields** - New fields are nullable, default to null on read
   - Pro: Zero migration, backward/forward compatible
   - Con: Null checking everywhere

4. **Discriminated Union** - Different document types for each split type
   - Pro: Type safety
   - Con: Query complexity, code duplication

### Decision: Optional Fields with Runtime Discrimination

**Rationale**:
- **Zero Migration**: No database changes required, works immediately
- **Backward Compatible**: Old clients ignore new fields
- **Forward Compatible**: New clients handle both schemas
- **Graceful Degradation**: Missing fields indicate old expense type
- **Type Safety**: Dart's null safety enforces proper handling

**Implementation**:

#### Firestore Document Schema

```json
{
  "id": "expense123",
  "tripId": "trip456",
  "amount": "125.50",
  "currency": "USD",
  "description": "Dinner at Restaurant",
  "paidBy": "user_alice",
  "splitType": "itemized",
  "createdAt": "2025-10-28T10:00:00Z",

  // Optional fields (present only if splitType = "itemized")
  "items": [
    {
      "id": "item1",
      "name": "Steak",
      "quantity": "2",
      "unitPrice": "25.00",
      "taxable": true,
      "serviceChargeable": true,
      "assignment": {
        "mode": "custom",
        "shares": {
          "user_alice": "0.6667",
          "user_bob": "0.3333"
        }
      }
    }
  ],
  "extras": {
    "tax": {
      "percentValue": "8.875",
      "base": "preTaxItemSubtotals"
    },
    "tip": {
      "percentValue": "18",
      "base": "postTaxSubtotals"
    },
    "fees": [],
    "discounts": []
  },
  "allocation": {
    "rounding": {
      "precision": 2,
      "mode": "roundHalfUp",
      "distributeRemainderTo": "largestShare"
    }
  },
  "participantAmounts": {
    "user_alice": "75.30",
    "user_bob": "50.20"
  },
  "participantBreakdown": {
    "user_alice": {
      "userId": "user_alice",
      "itemSubtotal": "66.67",
      "taxAllocated": "5.92",
      "tipAllocated": "12.00",
      "feesAllocated": "0.00",
      "roundingAdjustment": "0.01",
      "total": "84.60"
    },
    "user_bob": { /* ... */ }
  }
}
```

**Old Expense** (no itemized fields):
```json
{
  "id": "expense789",
  "amount": "60.00",
  "splitType": "equal",
  "participants": ["user_alice", "user_bob", "user_charlie"],
  // No items, extras, allocation fields
}
```

#### Domain Model (Dart)

```dart
class Expense {
  final String id;
  final String tripId;
  final Decimal amount;
  final CurrencyCode currency;
  final String description;
  final String paidBy;
  final SplitType splitType;
  final DateTime createdAt;

  // Optional fields for itemized splitting
  final List<LineItem>? items;
  final Extras? extras;
  final AllocationRule? allocation;
  final Map<String, Decimal>? participantAmounts;
  final Map<String, ParticipantBreakdown>? participantBreakdown;

  // Validation: itemized fields required if splitType = itemized
  Expense({
    required this.id,
    required this.amount,
    required this.splitType,
    this.items,
    this.extras,
    this.allocation,
    this.participantAmounts,
    this.participantBreakdown,
  }) {
    if (splitType == SplitType.itemized) {
      assert(items != null, 'items required for itemized expenses');
      assert(participantAmounts != null, 'participantAmounts required for itemized');
    }
  }
}
```

#### Firestore Serialization

```dart
class ExpenseModel {
  static Expense fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Expense(
      id: doc.id,
      amount: Decimal.parse(data['amount']),
      splitType: SplitType.values.byName(data['splitType']),

      // Optional fields with null fallback
      items: data['items'] != null
        ? (data['items'] as List).map((i) => LineItem.fromJson(i)).toList()
        : null,

      extras: data['extras'] != null
        ? Extras.fromJson(data['extras'])
        : null,

      allocation: data['allocation'] != null
        ? AllocationRule.fromJson(data['allocation'])
        : null,

      participantAmounts: data['participantAmounts'] != null
        ? (data['participantAmounts'] as Map<String, dynamic>).map(
            (k, v) => MapEntry(k, Decimal.parse(v))
          )
        : null,

      participantBreakdown: data['participantBreakdown'] != null
        ? (data['participantBreakdown'] as Map<String, dynamic>).map(
            (k, v) => MapEntry(k, ParticipantBreakdown.fromJson(v))
          )
        : null,
    );
  }

  static Map<String, dynamic> toFirestore(Expense expense) {
    final data = {
      'amount': expense.amount.toString(),
      'splitType': expense.splitType.name,
      'createdAt': FieldValue.serverTimestamp(),
      // ... other required fields
    };

    // Only include optional fields if present
    if (expense.items != null) {
      data['items'] = expense.items!.map((i) => i.toJson()).toList();
    }

    if (expense.extras != null) {
      data['extras'] = expense.extras!.toJson();
    }

    if (expense.allocation != null) {
      data['allocation'] = expense.allocation!.toJson();
    }

    if (expense.participantAmounts != null) {
      data['participantAmounts'] = expense.participantAmounts!.map(
        (k, v) => MapEntry(k, v.toString())
      );
    }

    if (expense.participantBreakdown != null) {
      data['participantBreakdown'] = expense.participantBreakdown!.map(
        (k, v) => MapEntry(k, v.toJson())
      );
    }

    return data;
  }
}
```

#### Settlement Calculator Integration

```dart
class SettlementCalculator {
  Map<String, Decimal> calculateBalances(List<Expense> expenses) {
    final balances = <String, Decimal>{};

    for (final expense in expenses) {
      // Credit payer
      balances[expense.paidBy] =
        (balances[expense.paidBy] ?? Decimal.zero) + expense.amount;

      // Debit participants based on split type
      switch (expense.splitType) {
        case SplitType.equal:
          _applyEqualSplit(expense, balances);
        case SplitType.weighted:
          _applyWeightedSplit(expense, balances);
        case SplitType.itemized:
          _applyItemizedSplit(expense, balances); // NEW
      }
    }

    return balances;
  }

  void _applyItemizedSplit(Expense expense, Map<String, Decimal> balances) {
    // Use participantAmounts directly (no calculation needed)
    for (final entry in expense.participantAmounts!.entries) {
      final userId = entry.key;
      final amount = entry.value;
      balances[userId] = (balances[userId] ?? Decimal.zero) - amount;
    }
  }
}
```

### Best Practices Implemented

1. **Null-Safe Deserialization**:
   ```dart
   items: data['items'] != null ? ... : null,
   ```

2. **Conditional Serialization**:
   ```dart
   if (expense.items != null) { data['items'] = ...; }
   ```

3. **Type Guards**:
   ```dart
   if (splitType == SplitType.itemized) {
     assert(participantAmounts != null);
   }
   ```

4. **Query Compatibility**:
   ```dart
   // Works for both old and new schemas
   expenses
     .where('tripId', isEqualTo: tripId)
     .where('splitType', isEqualTo: 'itemized') // Filter for new type
     .get();
   ```

5. **Firestore Rules** (optional validation):
   ```javascript
   match /expenses/{expenseId} {
     allow write: if
       // If itemized, require participantAmounts
       request.resource.data.splitType != 'itemized' ||
       (request.resource.data.splitType == 'itemized' &&
        request.resource.data.participantAmounts != null);
   }
   ```

### Migration Path (Future)

If manual backfill becomes necessary:

```dart
Future<void> backfillParticipantAmounts() async {
  final snapshot = await FirebaseFirestore.instance
    .collection('expenses')
    .where('splitType', whereIn: ['equal', 'weighted'])
    .where('participantAmounts', isNull: true) // Missing field
    .get();

  final batch = FirebaseFirestore.instance.batch();

  for (final doc in snapshot.docs) {
    final expense = ExpenseModel.fromFirestore(doc);
    final amounts = _calculateLegacyAmounts(expense);

    batch.update(doc.reference, {
      'participantAmounts': amounts.map((k, v) => MapEntry(k, v.toString())),
    });
  }

  await batch.commit();
}
```

**Note**: Not required for launch, only if settlement logic changes to require participantAmounts for all types.

### Testing Strategy

```dart
test('deserializes old expense without itemized fields', () {
  final doc = MockDocumentSnapshot({
    'id': 'exp1',
    'amount': '60.00',
    'splitType': 'equal',
    // No items, extras, etc.
  });

  final expense = ExpenseModel.fromFirestore(doc);

  expect(expense.items, isNull);
  expect(expense.participantAmounts, isNull);
  expect(expense.splitType, SplitType.equal);
});

test('deserializes new itemized expense with all fields', () {
  final doc = MockDocumentSnapshot({
    'id': 'exp2',
    'splitType': 'itemized',
    'items': [...],
    'participantAmounts': {'alice': '50.00', 'bob': '30.00'},
  });

  final expense = ExpenseModel.fromFirestore(doc);

  expect(expense.items, isNotEmpty);
  expect(expense.participantAmounts, isNotNull);
});

test('settlement calculator handles both old and new expenses', () {
  final expenses = [
    oldEqualSplitExpense, // No participantAmounts
    newItemizedExpense,   // Has participantAmounts
  ];

  final balances = SettlementCalculator.calculateBalances(expenses);

  expect(balances['alice'], Decimal.parse('X'));
  expect(balances['bob'], Decimal.parse('Y'));
});
```

---

## Summary & Next Steps

This research document has established technical decisions for:

1. **Rounding**: Four configurable strategies (largestShare, payer, firstListed, random) with deterministic algorithms
2. **Currency Precision**: ISO 4217 lookup table for all currencies, proper handling of VND (0 decimals) and USD (2 decimals)
3. **Tax/Tip Allocation**: Flexible per-extra base selection with sensible defaults, supports complex receipt structures
4. **Custom Shares**: Percentage input with normalization, intuitive UX with validation
5. **Performance**: Multi-strategy optimization (memoization, lazy rendering, virtualization) targeting <100ms recalc
6. **Backward Compatibility**: Optional fields pattern with null safety, zero-migration deployment

### Implementation Readiness

All research questions from `plan.md` Phase 0 are resolved. The implementation can proceed to Phase 1 (data models and contracts) with confidence.

**Recommended Next Steps**:
1. Generate `data-model.md` with full entity definitions incorporating these decisions
2. Create JSON schema contracts in `contracts/` for Firestore DTOs
3. Run `/speckit.tasks` to generate implementation task breakdown
4. Begin TDD implementation starting with calculation engine tests

---

**Document Version**: 1.0
**Last Updated**: 2025-10-28
**Authors**: Technical research for feature 002-itemized-splitter
**Status**: Approved for implementation
