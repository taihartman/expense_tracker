# Contract: MultiCurrencySelector Widget

**Feature**: 011-trip-multi-currency
**Component**: Presentation Layer Widget
**Created**: 2025-11-02

## Purpose

The MultiCurrencySelector widget provides a chip-based UI for selecting and reordering multiple currencies for a trip. It is displayed in a bottom sheet (mobile-optimized) and allows users to add currencies via search, remove currencies via chip X buttons, and reorder currencies via up/down arrow buttons.

## Widget Specification

### File Location

`lib/features/trips/presentation/widgets/multi_currency_selector.dart`

### Constructor

```dart
class MultiCurrencySelector extends StatefulWidget {
  const MultiCurrencySelector({
    super.key,
    required this.selectedCurrencies,
    required this.onChanged,
    this.maxCurrencies = 10,
    this.minCurrencies = 1,
  });

  /// Currently selected currencies (ordered, first = default)
  final List<CurrencyCode> selectedCurrencies;

  /// Called when user adds, removes, or reorders currencies
  /// Callback receives updated list of currencies
  final ValueChanged<List<CurrencyCode>> onChanged;

  /// Maximum number of currencies allowed (default: 10)
  final int maxCurrencies;

  /// Minimum number of currencies required (default: 1)
  final int minCurrencies;

  @override
  State<MultiCurrencySelector> createState() => _MultiCurrencySelectorState();
}
```

### Input Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `selectedCurrencies` | `List<CurrencyCode>` | Yes | - | Initial list of selected currencies, ordered (first = default) |
| `onChanged` | `ValueChanged<List<CurrencyCode>>` | Yes | - | Callback when currencies change (add/remove/reorder) |
| `maxCurrencies` | `int` | No | 10 | Maximum allowed currencies (enforced in UI) |
| `minCurrencies` | `int` | No | 1 | Minimum required currencies (enforced in UI) |

### Output Behavior

**onChanged Callback**: Called when user:
- Adds a currency (via "Add Currency" button → CurrencySearchField modal)
- Removes a currency (via chip X button)
- Reorders currencies (via up/down arrow buttons)

Callback receives the updated `List<CurrencyCode>` with:
- New currency appended to end (when adding)
- Currency removed (when deleting)
- Currencies reordered (when moving up/down)

**Example**:
```dart
// Initial: [USD, EUR, GBP]
// User clicks "Move EUR up" arrow
// Callback receives: [EUR, USD, GBP]

// User clicks "Remove GBP" X button
// Callback receives: [EUR, USD]

// User adds CHF
// Callback receives: [EUR, USD, CHF]
```

## UI Specification

### Layout

The widget is typically displayed in a modal bottom sheet:

```dart
showModalBottomSheet(
  context: context,
  isScrollControlled: true,
  builder: (context) => DraggableScrollableSheet(
    initialChildSize: isMobile ? 0.9 : 0.7,
    builder: (context, scrollController) => MultiCurrencySelector(
      selectedCurrencies: trip.allowedCurrencies,
      onChanged: (currencies) {
        // Handle currency update
      },
    ),
  ),
);
```

### Visual Structure

```
┌─────────────────────────────────────────┐
│  Allowed Currencies                  [X]│  ← Header with close button
├─────────────────────────────────────────┤
│  First currency is the default for new  │  ← Help text
│  expenses. Use arrows to reorder.       │
├─────────────────────────────────────────┤
│  ┌──────────┐  ┌──────────┐            │  ← Chip list (wraps)
│  │ USD  ↓ ✕ │  │ EUR ↑↓ ✕│            │
│  └──────────┘  └──────────┘            │
│  ┌──────────┐                          │
│  │ GBP  ↑ ✕ │                          │
│  └──────────┘                          │
│                                         │
│  [ + Add Currency ]                    │  ← Add button
├─────────────────────────────────────────┤
│                           [ Save ]      │  ← Footer (optional)
└─────────────────────────────────────────┘
```

### Chip Specification

Each chip displays:
- **Currency code** (e.g., "USD") - 14px (mobile) / 16px (desktop)
- **Up arrow button** (↑) - 44x44px touch target, 20px icon (mobile) / 24px (desktop)
  - Visible for all chips except first (can't move up)
  - Swaps with previous chip when clicked
- **Down arrow button** (↓) - 44x44px touch target, 20px icon (mobile) / 24px (desktop)
  - Visible for all chips except last (can't move down)
  - Swaps with next chip when clicked
- **Remove button** (✕) - 44x44px touch target, 20px icon (mobile) / 24px (desktop)
  - Removes currency from list when clicked
  - Disabled if removing would violate minCurrencies constraint

**Chip layout** (horizontal):
```
┌────────────────────┐
│ USD  ↑ ↓ ✕        │
└────────────────────┘
 └─┬─┘ └┬┘ └┬┘ └─┬─┘
   │    │   │    │
   │    │   │    Remove button (44x44px)
   │    │   Down button (44x44px, hidden if last)
   │    Up button (44x44px, hidden if first)
   Currency code label
```

### "Add Currency" Button

- Full-width on mobile, centered on desktop
- Minimum 44px height (touch target)
- Opens CurrencySearchField modal when clicked
- Disabled if `selectedCurrencies.length >= maxCurrencies`
- Shows tooltip: "Maximum 10 currencies" when disabled

### Validation & Error States

**Maximum currencies exceeded**:
- "Add Currency" button disabled
- Optional error message: "Maximum 10 currencies selected"

**Minimum currencies violated** (attempt to remove last currency):
- Remove button disabled for last remaining chip
- Optional tooltip: "Trip must have at least one currency"

**Duplicate currency** (added via CurrencySearchField):
- Show snackbar: "USD already selected"
- Do not add to list

## Behavior Specification

### Adding a Currency

1. User clicks "Add Currency" button
2. CurrencySearchField modal opens (reuses existing widget from feature 010)
3. User searches/selects a currency
4. Modal closes with selected currency
5. Widget checks if currency already in list:
   - If duplicate: show snackbar error, do NOT call onChanged
   - If max limit reached: show snackbar error, do NOT call onChanged
   - If valid: append to `selectedCurrencies` list, call `onChanged(updatedList)`

### Removing a Currency

1. User clicks X button on a chip
2. Widget checks if removing would violate minCurrencies:
   - If last currency: do nothing (button disabled)
   - If valid: remove from `selectedCurrencies` list, call `onChanged(updatedList)`

### Reordering Currencies

**Move Up** (↑ button):
1. User clicks up arrow on chip at index `i`
2. Swap `selectedCurrencies[i]` with `selectedCurrencies[i-1]`
3. Call `onChanged(updatedList)`
4. UI animates chip movement (optional)

**Move Down** (↓ button):
1. User clicks down arrow on chip at index `i`
2. Swap `selectedCurrencies[i]` with `selectedCurrencies[i+1]`
3. Call `onChanged(updatedList)`
4. UI animates chip movement (optional)

## Responsive Design

### Mobile (<600px)

- Bottom sheet: 90% viewport height
- Chip spacing: 8px horizontal, 8px vertical
- Font size: 14px
- Icon size: 20px
- Touch targets: 44x44px minimum
- Padding: 12px

### Desktop (≥600px)

- Bottom sheet: 70% viewport height
- Chip spacing: 12px horizontal, 12px vertical
- Font size: 16px
- Icon size: 24px
- Touch targets: 48x48px (larger for mouse precision)
- Padding: 16px

## Accessibility

### Screen Reader Support

- Chips: Semantic label "USD currency, position 1 of 3, move up, move down, remove"
- Up arrow button: "Move USD up"
- Down arrow button: "Move USD down"
- Remove button: "Remove USD"
- Add button: "Add currency"

### Keyboard Navigation

- Tab order: Header close → chips (left-to-right, top-to-bottom) → add button → save button
- Each chip's buttons are sub-tab-stops (tab to chip, arrow keys to navigate buttons)
- Enter/Space: activate button
- Escape: close bottom sheet

### Color Contrast

- Chip background: Material Design primary container (AA contrast)
- Chip text: High contrast (AAA)
- Disabled buttons: Reduced opacity but still readable

## Testing Contract

### Unit Tests

**File**: `test/features/trips/presentation/widgets/multi_currency_selector_test.dart`

```dart
group('MultiCurrencySelector', () {
  testWidgets('renders chips for selected currencies', (tester) async { ... });
  
  testWidgets('calls onChanged when currency added', (tester) async { ... });
  
  testWidgets('calls onChanged when currency removed', (tester) async { ... });
  
  testWidgets('calls onChanged when currency moved up', (tester) async { ... });
  
  testWidgets('calls onChanged when currency moved down', (tester) async { ... });
  
  testWidgets('disables add button at max currencies', (tester) async { ... });
  
  testWidgets('disables remove button at min currencies', (tester) async { ... });
  
  testWidgets('prevents duplicate currency selection', (tester) async { ... });
  
  testWidgets('hides up arrow for first chip', (tester) async { ... });
  
  testWidgets('hides down arrow for last chip', (tester) async { ... });
  
  testWidgets('respects mobile vs desktop responsive sizing', (tester) async { ... });
});
```

### Widget Tests

- Verify chip rendering (count, order, labels)
- Verify button visibility (first/last chip constraints)
- Verify button interactions (tap up/down/remove/add)
- Verify onChanged callback receives correct data
- Verify validation (max/min currencies, duplicates)
- Verify responsive design (mobile vs desktop sizes)

### Integration Tests

- Full flow: open bottom sheet → add 3 currencies → reorder → remove 1 → save
- Verify changes persist to Firestore
- Verify changes reflected in expense form currency dropdown

## Dependencies

### Internal

- `CurrencySearchField` widget (from feature 010) - for adding currencies
- `CurrencyCode` enum (from feature 010) - for currency data
- Localization: `context.l10n.*` for all user-facing strings

### External

- Flutter Material widgets: Chip, IconButton, ModalBottomSheet, etc.
- flutter_bloc: For potential integration with TripCubit (optional)

## Localization Strings

**Required ARB entries** (to be added to `lib/l10n/app_en.arb`):

```json
{
  "multiCurrencySelectorTitle": "Allowed Currencies",
  "multiCurrencySelectorHelpText": "First currency is the default for new expenses. Use arrows to reorder.",
  "multiCurrencySelectorAddButton": "Add Currency",
  "multiCurrencySelectorMaxError": "Maximum {max} currencies allowed",
  "multiCurrencySelectorMinError": "Trip must have at least {min} currency",
  "multiCurrencySelectorDuplicateError": "{currency} is already selected",
  "multiCurrencySelectorMoveUp": "Move {currency} up",
  "multiCurrencySelectorMoveDown": "Move {currency} down",
  "multiCurrencySelectorRemove": "Remove {currency}",
  "multiCurrencySelectorChipLabel": "{currency} currency, position {position} of {total}"
}
```

## Performance Considerations

- **Chip rendering**: Use ListView.builder if >10 currencies (unlikely given maxCurrencies=10)
- **Reordering animation**: Optional, use AnimatedList for smooth transitions
- **State management**: Local state (StatefulWidget) sufficient, no need for Cubit

## Implementation Notes

### State Management

Use local state (StatefulWidget) to track:
- Current currency list (mutable copy of input)
- Validation errors (max/min/duplicate)
- Bottom sheet visibility (if managing internally)

Only call `onChanged` when user confirms changes (either via "Save" button or auto-save on each change).

### Error Handling

- **Duplicate currency**: Show snackbar, do NOT add
- **Max currencies**: Disable add button, show tooltip
- **Min currencies**: Disable remove button for last chip
- **Invalid currency code**: Should not occur (CurrencySearchField only allows valid codes)

---

**Contract Version**: 1.0 | **Created**: 2025-11-02 | **Status**: Draft
