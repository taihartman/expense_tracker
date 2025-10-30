# Currency Input Skill

## Description
This skill provides a systematic workflow for implementing currency input fields in the expense tracker app. The app uses a unified currency input system with automatic formatting, thousand separators, and currency-specific decimal places.

## When to Use
- Adding forms with monetary amount inputs
- Creating expense forms
- Building budget or limit fields
- Editing existing expense amounts
- When you see plain TextField/TextFormField for currency amounts (anti-pattern)

## Core Philosophy
**ALWAYS use `CurrencyTextField` for monetary amounts.** Never use plain `TextField` or `TextFormField`. This ensures consistent formatting, validation, and user experience across the app.

## Key Files
- `lib/shared/widgets/currency_text_field.dart` - Reusable currency input widget
- `lib/shared/utils/currency_input_formatter.dart` - Currency-aware input formatter
- `lib/core/models/currency_code.dart` - Currency enum with metadata

## What CurrencyTextField Provides

- ✅ Automatic thousand separators (1,000,000)
- ✅ Currency-aware decimal places (USD = 2, VND = 0)
- ✅ Built-in validation (required, valid number, > 0)
- ✅ Localized error messages
- ✅ Consistent styling across app
- ✅ Auto-parsing to Decimal type

## Workflow

### Step 1: Import Dependencies

```dart
import 'package:expense_tracker/shared/widgets/currency_text_field.dart';
import 'package:expense_tracker/shared/utils/currency_input_formatter.dart';
import 'package:expense_tracker/core/models/currency_code.dart';
```

### Step 2: Create Controller in State

```dart
class _ExpenseFormPageState extends State<ExpenseFormPage> {
  late final TextEditingController _amountController;
  CurrencyCode _selectedCurrency = CurrencyCode.usd;

  @override
  void initState() {
    super.initState();

    // Initialize controller
    _amountController = TextEditingController();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }
}
```

### Step 3: Use CurrencyTextField in Build

Basic usage:

```dart
CurrencyTextField(
  controller: _amountController,
  currencyCode: _selectedCurrency,
  label: context.l10n.expenseFieldAmountLabel,
)
```

Advanced usage with all options:

```dart
CurrencyTextField(
  controller: _amountController,
  currencyCode: _selectedCurrency,
  label: context.l10n.expenseFieldAmountLabel,
  hint: 'Enter amount',          // Optional hint text
  isRequired: true,               // Default: true
  allowZero: false,               // Default: false
  prefixIcon: Icons.attach_money, // Optional icon
  onAmountChanged: (amount) {     // Optional callback
    // Called with parsed Decimal value (or null if invalid)
    print('Amount: $amount');
    setState(() {
      _calculatedTotal = _calculateTotal();
    });
  },
)
```

### Step 4: Pre-fill Values When Editing

When editing an existing expense, use `formatAmountForInput` helper:

```dart
import 'package:expense_tracker/shared/utils/currency_input_formatter.dart';

class _ExpenseFormPageState extends State<ExpenseFormPage> {
  late final TextEditingController _amountController;
  CurrencyCode _selectedCurrency = CurrencyCode.usd;

  @override
  void initState() {
    super.initState();

    // Pre-fill when editing
    _amountController = TextEditingController(
      text: widget.expense != null
          ? formatAmountForInput(
              widget.expense!.amount,
              widget.expense!.currency,
            )
          : '',
    );

    // Set currency from expense
    if (widget.expense != null) {
      _selectedCurrency = widget.expense!.currency;
    }
  }
}
```

**Why use `formatAmountForInput`?**
- Ensures value displays with thousand separators (e.g., "1,000.50" instead of "1000.5")
- Respects currency-specific decimal places
- Provides consistent user experience

### Step 5: Parse User Input When Saving

Use `stripCurrencyFormatting` before parsing:

```dart
void _saveExpense() {
  // Parse the amount
  final cleanValue = stripCurrencyFormatting(_amountController.text);
  final amount = Decimal.parse(cleanValue);

  // Create/update expense with parsed amount
  final expense = Expense(
    amount: amount,
    currency: _selectedCurrency,
    // ... other fields
  );

  // Save via repository or cubit
  context.read<ExpenseCubit>().createExpense(expense);
}
```

**Why use `stripCurrencyFormatting`?**
- Removes thousand separators (1,000.50 → 1000.50)
- Makes string parseable by `Decimal.parse()`
- Handles edge cases consistently

### Step 6: Add Currency Selector (if needed)

Usually paired with currency input field:

```dart
DropdownButtonFormField<CurrencyCode>(
  value: _selectedCurrency,
  decoration: InputDecoration(
    labelText: context.l10n.expenseFieldCurrencyLabel,
  ),
  items: CurrencyCode.values.map((currency) {
    return DropdownMenuItem(
      value: currency,
      child: Text('${currency.symbol} ${currency.displayName(context)}'),
    );
  }).toList(),
  onChanged: (value) {
    setState(() => _selectedCurrency = value!);
  },
)
```

**Note**: When currency changes, `CurrencyTextField` automatically updates its formatter to match the new currency's decimal places.

## Currency-Specific Behavior

### USD (2 decimal places)
- User can enter: `1000.50`
- Displays: `1,000.50`
- Maximum 2 decimals enforced
- Can enter cents

### VND (0 decimal places)
- User can enter: `1000000`
- Displays: `1,000,000`
- No decimal point allowed
- Whole numbers only

## Validation

`CurrencyTextField` provides built-in validation:

### Required Field Validation
```dart
CurrencyTextField(
  controller: _amountController,
  currencyCode: CurrencyCode.usd,
  label: 'Amount',
  isRequired: true,  // Shows error if empty
)
```

Error shown: `context.l10n.validationRequired` → "This field is required"

### Invalid Number Validation
- Automatically validates if input is a valid number
- Error shown: `context.l10n.validationInvalidNumber` → "Please enter a valid number"

### Greater Than Zero Validation
```dart
CurrencyTextField(
  controller: _amountController,
  currencyCode: CurrencyCode.usd,
  label: 'Amount',
  allowZero: false,  // Requires amount > 0
)
```

Error shown: `context.l10n.validationMustBeGreaterThanZero` → "Amount must be greater than zero"

### Optional Field
```dart
CurrencyTextField(
  controller: _amountController,
  currencyCode: CurrencyCode.usd,
  label: 'Budget (optional)',
  isRequired: false,  // No error if empty
)
```

## Complete Example

```dart
class ExpenseFormPage extends StatefulWidget {
  final Expense? expense;

  const ExpenseFormPage({this.expense, super.key});

  @override
  State<ExpenseFormPage> createState() => _ExpenseFormPageState();
}

class _ExpenseFormPageState extends State<ExpenseFormPage> {
  late final TextEditingController _amountController;
  late final TextEditingController _descriptionController;
  CurrencyCode _selectedCurrency = CurrencyCode.usd;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();

    // Pre-fill when editing
    _amountController = TextEditingController(
      text: widget.expense != null
          ? formatAmountForInput(
              widget.expense!.amount,
              widget.expense!.currency,
            )
          : '',
    );

    _descriptionController = TextEditingController(
      text: widget.expense?.description ?? '',
    );

    if (widget.expense != null) {
      _selectedCurrency = widget.expense!.currency;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.expense == null
              ? context.l10n.expenseCreateTitle
              : context.l10n.expenseEditTitle,
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView( // Mobile-first: always use ScrollView
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Currency input field
              CurrencyTextField(
                controller: _amountController,
                currencyCode: _selectedCurrency,
                label: context.l10n.expenseFieldAmountLabel,
                prefixIcon: Icons.attach_money,
              ),
              const SizedBox(height: 16),

              // Currency selector
              DropdownButtonFormField<CurrencyCode>(
                value: _selectedCurrency,
                decoration: InputDecoration(
                  labelText: context.l10n.expenseFieldCurrencyLabel,
                  prefixIcon: const Icon(Icons.currency_exchange),
                ),
                items: CurrencyCode.values.map((currency) {
                  return DropdownMenuItem(
                    value: currency,
                    child: Text(
                      '${currency.symbol} ${currency.displayName(context)}',
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedCurrency = value!);
                },
              ),
              const SizedBox(height: 16),

              // Description field
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: context.l10n.expenseFieldDescriptionLabel,
                  prefixIcon: const Icon(Icons.description),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return context.l10n.validationRequired;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Save button
              ElevatedButton(
                onPressed: _saveExpense,
                child: Text(context.l10n.commonSave),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveExpense() {
    if (_formKey.currentState!.validate()) {
      // Parse the amount
      final cleanValue = stripCurrencyFormatting(_amountController.text);
      final amount = Decimal.parse(cleanValue);

      // Create/update expense
      final expense = Expense(
        id: widget.expense?.id ?? '',
        amount: amount,
        currency: _selectedCurrency,
        description: _descriptionController.text,
        date: DateTime.now(),
        // ... other fields
      );

      if (widget.expense == null) {
        context.read<ExpenseCubit>().createExpense(expense);
      } else {
        context.read<ExpenseCubit>().updateExpense(expense);
      }

      Navigator.pop(context);
    }
  }
}
```

## Adding New Currencies

To add support for a new currency:

### 1. Add to CurrencyCode enum

File: `lib/core/models/currency_code.dart`

```dart
enum CurrencyCode {
  usd('USD', 2),  // 2 decimal places
  vnd('VND', 0),  // 0 decimal places
  eur('EUR', 2),  // New currency - 2 decimal places
}
```

### 2. Add display name to localization

File: `lib/l10n/app_en.arb`

```json
{
  "currencyEUR": "Euro"
}
```

### 3. Add symbol and display name

File: `lib/core/models/currency_code.dart`

```dart
String get symbol {
  switch (this) {
    case CurrencyCode.usd:
      return '\$';
    case CurrencyCode.vnd:
      return '₫';
    case CurrencyCode.eur:
      return '€';
  }
}

String displayName(BuildContext context) {
  switch (this) {
    case CurrencyCode.usd:
      return context.l10n.currencyUSD;
    case CurrencyCode.vnd:
      return context.l10n.currencyVND;
    case CurrencyCode.eur:
      return context.l10n.currencyEUR;
  }
}
```

The `CurrencyTextField` and `CurrencyInputFormatter` will automatically handle the new currency's decimal places.

## Best Practices

**✅ DO:**
- Always use `CurrencyTextField` for monetary amounts
- Use `formatAmountForInput()` when pre-filling edit forms
- Pass the correct `CurrencyCode` enum (not a string)
- Use `stripCurrencyFormatting()` before parsing manually
- Use `SingleChildScrollView` for forms (mobile-first)
- Pair with currency selector dropdown when needed

**❌ DON'T:**
- Never use plain `TextField` or `TextFormField` for currency amounts
- Don't use `FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))` directly
- Don't hardcode decimal places - let the currency code determine it
- Don't parse `_controller.text` directly - use `stripCurrencyFormatting()` first
- Don't forget to dispose controllers in `dispose()`
- Don't forget to import the currency formatting helper functions

## Helper Functions

### formatAmountForInput
```dart
String formatAmountForInput(Decimal amount, CurrencyCode currency)
```

**Purpose**: Format a Decimal amount for display in a text field

**Example**:
```dart
// Input: Decimal.parse('1000.5'), CurrencyCode.usd
// Output: "1,000.50"

// Input: Decimal.parse('1000000'), CurrencyCode.vnd
// Output: "1,000,000"
```

### stripCurrencyFormatting
```dart
String stripCurrencyFormatting(String formattedValue)
```

**Purpose**: Remove formatting before parsing

**Example**:
```dart
// Input: "1,000.50"
// Output: "1000.50"

// Input: "1,000,000"
// Output: "1000000"
```

## Troubleshooting

**Problem**: Formatting not working, commas not showing
- **Solution**: Ensure you're using `CurrencyTextField`, not plain `TextField`
- **Solution**: Check that you're passing the correct `CurrencyCode` enum

**Problem**: Decimal places showing for VND (should be 0)
- **Solution**: Ensure currency is `CurrencyCode.vnd`, not `CurrencyCode.usd`

**Problem**: Can't parse the amount, getting FormatException
- **Solution**: Use `stripCurrencyFormatting()` before `Decimal.parse()`

**Problem**: Value not pre-filling when editing
- **Solution**: Use `formatAmountForInput()` in controller initialization

**Problem**: Validation not showing
- **Solution**: Wrap form in `Form` widget with `GlobalKey<FormState>`
- **Solution**: Check that you're calling `_formKey.currentState!.validate()`

## Decision Checklist

Before implementing currency input:

- [ ] Am I using `CurrencyTextField` (not plain TextField)?
- [ ] Have I created a `TextEditingController`?
- [ ] Have I disposed the controller in `dispose()`?
- [ ] Am I passing the correct `CurrencyCode` enum?
- [ ] If editing, am I using `formatAmountForInput()` to pre-fill?
- [ ] Am I using `stripCurrencyFormatting()` before parsing?
- [ ] Have I wrapped the form in `SingleChildScrollView`?
- [ ] Have I added a currency selector if needed?
- [ ] Have I tested with both USD and VND?
- [ ] Have I imported the helper functions?

## Additional Resources

For more information, see:
- Root CLAUDE.md → Currency Input System section
- `lib/shared/widgets/currency_text_field.dart` - Widget implementation
- `lib/shared/utils/currency_input_formatter.dart` - Formatter implementation
- `lib/core/models/currency_code.dart` - Currency enum definition
- Existing forms using CurrencyTextField (search codebase)
