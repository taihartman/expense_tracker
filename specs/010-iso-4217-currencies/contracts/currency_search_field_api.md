# Contract: CurrencySearchField Widget API

**Feature**: ISO 4217 Multi-Currency Support
**Date**: 2025-01-30
**Version**: 1.0.0

## Overview

`CurrencySearchField` is a mobile-first Flutter widget that provides a searchable currency picker interface for selecting from 170+ ISO 4217 currencies. It replaces simple dropdown widgets with a modal search experience optimized for large lists.

---

## Widget API

### Constructor

```dart
class CurrencySearchField extends StatefulWidget {
  /// Creates a currency search field
  ///
  /// The [onChanged] callback is called when the user selects a currency.
  /// If [value] is null, the field displays as empty until a selection is made.
  const CurrencySearchField({
    Key? key,
    required this.onChanged,
    this.value,
    this.label,
    this.hint,
    this.enabled = true,
    this.validator,
    this.showOnlyActive = true,
    this.decoration,
  }) : super(key: key);

  /// Current selected currency (null if no selection)
  final CurrencyCode? value;

  /// Called when user selects a currency
  ///
  /// The callback receives null if the user clears the selection
  final ValueChanged<CurrencyCode?> onChanged;

  /// Label text displayed above the field
  ///
  /// Defaults to l10n.expenseFieldCurrencyLabel if not provided
  final String? label;

  /// Hint text shown when no currency is selected
  ///
  /// Defaults to "Select currency" if not provided
  final String? hint;

  /// Whether the field is enabled for interaction
  ///
  /// If false, tapping the field does nothing and it appears disabled
  final bool enabled;

  /// Validator function for form validation
  ///
  /// Called with current value when form.validate() is invoked
  /// Return null for valid, error string for invalid
  final FormFieldValidator<CurrencyCode>? validator;

  /// Whether to show only active currencies in the picker
  ///
  /// If true (default), only currencies with isActive=true are shown
  /// If false, all currencies including historical ones are shown
  final bool showOnlyActive;

  /// Custom input decoration
  ///
  /// If null, uses default Material TextField decoration
  final InputDecoration? decoration;

  @override
  State<CurrencySearchField> createState() => _CurrencySearchFieldState();
}
```

---

## Usage Examples

### Basic Usage

```dart
CurrencyCode? selectedCurrency = CurrencyCode.usd;

CurrencySearchField(
  value: selectedCurrency,
  onChanged: (currency) {
    setState(() {
      selectedCurrency = currency;
    });
  },
)
```

### With Form Validation

```dart
final _formKey = GlobalKey<FormState>();

Form(
  key: _formKey,
  child: CurrencySearchField(
    value: selectedCurrency,
    onChanged: (currency) {
      setState(() {
        selectedCurrency = currency;
      });
    },
    label: context.l10n.expenseFieldCurrencyLabel,
    validator: (value) {
      if (value == null) {
        return context.l10n.validationRequired;
      }
      return null;
    },
  ),
)
```

### With Custom Decoration

```dart
CurrencySearchField(
  value: selectedCurrency,
  onChanged: (currency) {
    setState(() {
      selectedCurrency = currency;
    });
  },
  decoration: InputDecoration(
    labelText: 'Trip Currency',
    prefixIcon: Icon(Icons.attach_money),
    suffixIcon: IconButton(
      icon: Icon(Icons.clear),
      onPressed: () => onChanged(null),
    ),
  ),
)
```

### Disabled State

```dart
CurrencySearchField(
  value: trip.baseCurrency,
  onChanged: (_) {},  // No-op callback
  enabled: false,  // Field appears disabled
)
```

---

## Picker Modal API

### _CurrencyPickerModal (Internal Widget)

**Presentation**:
- Mobile (<600px width): Full-screen modal bottom sheet
- Tablet/Desktop (≥600px): Centered dialog (600px wide)

**Components**:
1. **Search Bar** (top):
   - Text input for filtering currencies
   - Clear button to reset search
   - Hint: "Search by code or name"

2. **Currency List** (scrollable):
   - Virtualized list (ListView.builder)
   - Each item displays: `code - displayName` (e.g., "USD - United States Dollar")
   - Matched search terms highlighted
   - Tap to select

3. **Close Action**:
   - Close button in app bar (mobile) or dialog header (desktop)
   - Dismiss by tapping outside modal (desktop only)
   - Back button (mobile)

**Search Behavior**:
- Case-insensitive
- Matches currency code OR display name
- Debounced 300ms to avoid excessive filtering
- Examples:
  - "eur" → matches "EUR - Euro"
  - "dollar" → matches "USD - United States Dollar", "AUD - Australian Dollar", etc.
  - "¥" → matches "JPY - Japanese Yen", "CNY - Chinese Yuan"

**Empty State**:
- No search results: "No currencies found. Try a different search."
- Empty list (all inactive): "No active currencies available."

---

## Behavior Specification

### Interaction Flow

```
[User taps CurrencySearchField]
       ↓
[Modal opens (bottom sheet on mobile, dialog on desktop)]
       ↓
[Full currency list displayed (170+ items, virtualized)]
       ↓
[User types in search bar] → [List filters in real-time (300ms debounce)]
       ↓
[User taps currency from list]
       ↓
[Modal closes]
       ↓
[onChanged callback fires with selected CurrencyCode]
       ↓
[Field displays selected currency: "USD - United States Dollar"]
```

### State Management

**Internal State**:
- Search query (String)
- Filtered currency list (List<CurrencyCode>)
- Loading state (bool) - for async operations if needed

**Parent State** (via callbacks):
- Selected currency (CurrencyCode?)

---

## Visual Design

### Field Display (Closed State)

**Layout**:
```
┌─────────────────────────────────────┐
│ Currency                            │  ← Label
│ ┌─────────────────────────────────┐ │
│ │ USD - United States Dollar    ▼ │ │  ← Selected value + dropdown icon
│ └─────────────────────────────────┘ │
└─────────────────────────────────────┘
```

**Empty State**:
```
┌─────────────────────────────────────┐
│ Currency                            │
│ ┌─────────────────────────────────┐ │
│ │ Select currency               ▼ │ │  ← Hint text
│ └─────────────────────────────────┘ │
└─────────────────────────────────────┘
```

**Disabled State**:
```
┌─────────────────────────────────────┐
│ Currency                            │
│ ┌─────────────────────────────────┐ │
│ │ USD - United States Dollar      │ │  ← No dropdown icon, grayed out
│ └─────────────────────────────────┘ │
└─────────────────────────────────────┘
```

### Modal Display (Mobile)

**Layout** (375px width):
```
┌───────────────────────────┐
│ ✕   Select Currency       │  ← App bar with close button
├───────────────────────────┤
│ ┌───────────────────────┐ │
│ │ 🔍 Search...        ✕ │ │  ← Search bar with clear button
│ └───────────────────────┘ │
├───────────────────────────┤
│ AED - UAE Dirham          │  ← Scrollable list
│ AUD - Australian Dollar   │
│ BHD - Bahraini Dinar      │
│ BRL - Brazilian Real      │
│ CAD - Canadian Dollar     │
│ CHF - Swiss Franc         │
│ CNY - Chinese Yuan        │
│ EUR - Euro                │
│ GBP - British Pound       │
│ ... (scrollable)          │
└───────────────────────────┘
```

### Modal Display (Desktop)

**Layout** (600px dialog):
```
        ┌─────────────────────────────┐
        │ Select Currency          ✕  │  ← Dialog header
        ├─────────────────────────────┤
        │ ┌─────────────────────────┐ │
        │ │ 🔍 Search...          ✕ │ │
        │ └─────────────────────────┘ │
        ├─────────────────────────────┤
        │ AED - UAE Dirham            │
        │ AUD - Australian Dollar     │
        │ ... (scrollable, 400px max) │
        └─────────────────────────────┘
```

---

## Accessibility

### Requirements

1. **Keyboard Navigation**:
   - Field: Focusable, opens modal on Enter/Space
   - Search bar: Auto-focused when modal opens
   - Currency list: Arrow keys navigate, Enter selects
   - Close: Escape key closes modal

2. **Screen Reader Support**:
   - Field: Announces label and current value
   - Search bar: Announces "Search currencies"
   - List items: Announces "Currency code - Currency name"
   - Selection: Announces "Selected [currency]"

3. **Touch Targets**:
   - Minimum 44x44px for all tappable elements
   - List items: 56px height (Material Design standard)

4. **Color Contrast**:
   - Text: 4.5:1 contrast ratio minimum
   - Disabled state: 3:1 contrast ratio

---

## Performance

### Optimization Strategies

1. **Virtualized List**:
   - Use `ListView.builder` to render only visible items
   - Typical viewport: ~10-12 items visible at once
   - Total items: 170+ currencies
   - Memory usage: Constant (~10 items in memory vs. 170)

2. **Search Debouncing**:
   - 300ms debounce on search input
   - Prevents excessive filtering while user types
   - Uses `Timer` to cancel pending filters

3. **Lazy Loading** (future optimization):
   - Load currency list on first modal open (not widget construction)
   - Cache filtered results

### Performance Targets

| Metric | Target | Measurement |
|--------|--------|-------------|
| Modal open time | <100ms | Time from tap to modal visible |
| Search filter time | <50ms | Time from keypress to filtered results |
| List scroll FPS | 60 FPS | Frame rate during scroll |
| Memory usage | <10MB | Memory for modal + list |

---

## Testing Strategy

### Widget Tests

**Test File**: `test/shared/widgets/currency_search_field_test.dart`

**Test Cases**:

1. **Rendering**:
   - Displays label correctly
   - Displays selected currency
   - Displays hint when no selection
   - Displays disabled state correctly

2. **Interaction**:
   - Opens modal on tap
   - Closes modal on currency selection
   - Closes modal on close button
   - Does not open modal when disabled

3. **Search**:
   - Filters by currency code (case-insensitive)
   - Filters by currency name (case-insensitive)
   - Shows "no results" when search has no matches
   - Clears search when clear button tapped

4. **Form Validation**:
   - Calls validator on form.validate()
   - Displays validation error message
   - Prevents submission when invalid

5. **Callbacks**:
   - onChanged fires with selected currency
   - onChanged fires with null when cleared

### Integration Tests

**Test Cases**:

1. Select currency in trip creation flow (end-to-end)
2. Select currency in expense creation flow (end-to-end)
3. Search and select currency with 170+ items loaded
4. Verify backward compatibility (USD/VND still selectable)

---

## Migration Guide

### Replacing DropdownButtonFormField

**Before**:
```dart
DropdownButtonFormField<CurrencyCode>(
  value: selectedCurrency,
  items: CurrencyCode.values.map((currency) {
    return DropdownMenuItem(
      value: currency,
      child: Text('${currency.symbol} ${currency.displayName(context)}'),
    );
  }).toList(),
  onChanged: (value) {
    setState(() => selectedCurrency = value);
  },
  decoration: InputDecoration(
    labelText: context.l10n.expenseFieldCurrencyLabel,
  ),
)
```

**After**:
```dart
CurrencySearchField(
  value: selectedCurrency,
  onChanged: (value) {
    setState(() => selectedCurrency = value);
  },
  label: context.l10n.expenseFieldCurrencyLabel,
)
```

**Benefits**:
- Simpler API (no manual item construction)
- Better mobile UX (searchable vs. scrollable dropdown)
- Handles 170+ currencies efficiently
- Built-in search and filtering

---

## Localization

### Required Strings

Add to `lib/l10n/app_en.arb`:

```json
{
  "currencySearchFieldLabel": "Currency",
  "currencySearchFieldHint": "Select currency",
  "currencySearchPlaceholder": "Search by code or name",
  "currencySearchNoResults": "No currencies found. Try a different search.",
  "currencySearchModalTitle": "Select Currency",
  "currencySearchClearButton": "Clear search"
}
```

---

## Error Handling

### Edge Cases

| Scenario | Behavior |
|----------|----------|
| No currencies available (all inactive) | Show empty state message, disable search |
| Search returns no results | Show "No currencies found" message |
| User clears selection (null) | Display hint text, fire onChanged(null) |
| Invalid initial value (not in enum) | Treat as null, display hint |
| Modal dismissed without selection | No change to value, no callback fired |

---

**Status**: API contract complete. Ready for implementation.
