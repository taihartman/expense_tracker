# Troubleshooting Guide

This document provides solutions to common issues encountered while developing the expense tracker app.

## Table of Contents
- [Mobile Layout Issues](#mobile-layout-issues)
- [State Management Issues](#state-management-issues)
- [Localization Issues](#localization-issues)
- [Currency Input Issues](#currency-input-issues)
- [Activity Logging Issues](#activity-logging-issues)
- [Build & Test Issues](#build--test-issues)
- [Firebase Issues](#firebase-issues)
- [Performance Issues](#performance-issues)

## Mobile Layout Issues

### Problem: Keyboard Hides Form Fields

**Symptoms**: When user taps a text field, the keyboard appears and hides the input field.

**Solution 1: Wrap form in SingleChildScrollView**
```dart
// ✅ CORRECT
SingleChildScrollView(
  child: Form(
    child: Column(
      children: [
        // Form fields...
      ],
    ),
  ),
)
```

**Solution 2: Add keyboard padding for modals**
```dart
showModalBottomSheet(
  context: context,
  isScrollControlled: true,  // IMPORTANT!
  builder: (context) => Container(
    padding: EdgeInsets.only(
      bottom: MediaQuery.of(context).viewInsets.bottom,  // Keyboard padding
    ),
    child: SingleChildScrollView(
      child: YourFormWidget(),
    ),
  ),
)
```

**Prevention**: Always use `SingleChildScrollView` for forms. See [MOBILE.md](MOBILE.md) for details.

---

### Problem: Vertical Space Conflict (Layout Overflow)

**Symptoms**: "RenderFlex overflowed by XXX pixels" error on mobile.

**Cause**: Fixed-height layouts competing for vertical space, or `Expanded` widgets in non-scrollable `Column`.

**Solution**: Replace fixed heights with flexible layouts
```dart
// ❌ BAD: Fixed heights
Column(
  children: [
    Container(height: 200, child: Header()),
    Container(height: 400, child: Content()),
    Container(height: 100, child: Footer()),
  ],
)

// ✅ GOOD: Flexible with scrolling
SingleChildScrollView(
  child: Column(
    children: [
      Header(),
      Content(),
      Footer(),
    ],
  ),
)
```

---

### Problem: Touch Targets Too Small

**Symptoms**: Users report difficulty tapping buttons on mobile.

**Cause**: Touch targets smaller than 44x44px minimum.

**Solution**: Ensure minimum size
```dart
// ❌ BAD: Too small
IconButton(
  icon: Icon(Icons.edit, size: 16),
  constraints: BoxConstraints(minWidth: 24, minHeight: 24),
)

// ✅ GOOD: Proper size
IconButton(
  icon: Icon(Icons.edit, size: isMobile ? 20 : 24),
  constraints: BoxConstraints(
    minWidth: isMobile ? 36 : 40,
    minHeight: isMobile ? 36 : 40,
  ),
)
```

---

### Problem: Horizontal Scrolling on Mobile

**Symptoms**: Users can scroll horizontally (should only be vertical).

**Cause**: Fixed widths exceed screen width, or Row without wrapping.

**Solution 1: Remove fixed widths**
```dart
// ❌ BAD: Fixed width
Container(
  width: 400,  // Exceeds mobile screen!
  child: ...
)

// ✅ GOOD: Responsive width
Container(
  width: double.infinity,
  child: ...
)
```

**Solution 2: Use Wrap instead of Row**
```dart
// ❌ BAD: Row overflows
Row(
  children: [
    Chip(), Chip(), Chip(), Chip(), Chip(),
  ],
)

// ✅ GOOD: Wrap allows multi-line
Wrap(
  spacing: 8,
  children: [
    Chip(), Chip(), Chip(), Chip(), Chip(),
  ],
)
```

---

## State Management Issues

### Problem: Cubit Not Emitting State Changes

**Symptoms**: UI not updating when cubit method is called.

**Cause 1: Modifying existing object instead of creating new one**
```dart
// ❌ BAD: Modifying existing list
void addExpense(Expense expense) {
  state.expenses.add(expense);  // State doesn't change reference
  emit(state);  // BLoC won't detect change!
}

// ✅ GOOD: Create new list
void addExpense(Expense expense) {
  final updatedExpenses = [...state.expenses, expense];
  emit(ExpenseLoadedState(updatedExpenses));
}
```

**Cause 2: Not awaiting async operation**
```dart
// ❌ BAD: Not awaiting
void loadExpenses() {
  _repository.getExpenses();  // Missing await!
  emit(ExpenseLoadedState([]));  // Emits before data arrives
}

// ✅ GOOD: Await async operation
Future<void> loadExpenses() async {
  final expenses = await _repository.getExpenses();
  emit(ExpenseLoadedState(expenses));
}
```

---

### Problem: Activity Logging Not Working

**Symptoms**: No activities showing in Activity Log page.

**Cause 1: Actor name not provided**

**Check**: Is `actorName` being passed to cubit method?
```dart
// ❌ BAD: No actor name
context.read<ExpenseCubit>().createExpense(expense);

// ✅ GOOD: Get actor from current user
final currentUser = context.read<TripCubit>().getCurrentUserForTrip(tripId);
context.read<ExpenseCubit>().createExpense(
  expense,
  actorName: currentUser?.name,
);
```

**Cause 2: User hasn't joined trip**

**Check**: Has user selected their identity for this trip?
```dart
final currentUser = context.read<TripCubit>().getCurrentUserForTrip(tripId);
if (currentUser == null) {
  // User needs to join trip first!
  // Show error or redirect to join trip page
}
```

**Cause 3: ActivityLogRepository not injected**

**Check**: Is `ActivityLogRepository` provided to cubit?
```dart
// In main.dart or wherever cubit is created
BlocProvider(
  create: (context) => ExpenseCubit(
    expenseRepository: context.read<ExpenseRepository>(),
    activityLogRepository: context.read<ActivityLogRepository>(),  // Don't forget!
  ),
)
```

---

### Problem: Currency Amounts Not Updating

**Symptoms**: Changing currency in dropdown doesn't update the input field formatting.

**Cause**: `CurrencyTextField` not rebuilding when currency changes.

**Solution**: Ensure `currencyCode` parameter updates
```dart
// ✅ CORRECT
CurrencyTextField(
  controller: _amountController,
  currencyCode: _selectedCurrency,  // This should be a state variable
  label: context.l10n.expenseFieldAmountLabel,
)

// In dropdown onChanged:
onChanged: (value) {
  setState(() {
    _selectedCurrency = value!;  // Triggers rebuild
  });
}
```

---

## Localization Issues

### Problem: "Undefined name 'context.l10n'"

**Symptoms**: Compilation error when using `context.l10n`.

**Solution**: Import the extension
```dart
import 'package:expense_tracker/core/l10n/l10n_extensions.dart';
```

---

### Problem: "The getter 'myNewString' isn't defined"

**Symptoms**: Added string to `app_en.arb` but can't access it.

**Solution**: Regenerate localization files
```bash
flutter pub get
# or
flutter gen-l10n
```

---

### Problem: Strings Not Updating After Editing ARB

**Symptoms**: Changed text in `app_en.arb` but UI still shows old text.

**Solution 1: Hot restart (not hot reload)**
- Stop the app
- Run `flutter pub get`
- Restart the app (not just hot reload)

**Solution 2: Clean and rebuild**
```bash
flutter clean
flutter pub get
flutter run
```

---

### Problem: FormatException in ARB File

**Symptoms**: "Illegal argument in locale string" error.

**Cause**: Invalid JSON syntax in ARB file.

**Common mistakes**:
- Trailing commas in JSON (not allowed)
- Missing quotes around keys
- Comment keys like `"_COMMENT_": "..."` (breaks generation)
- Incorrect placeholder syntax

**Solution**: Validate JSON syntax
```json
{
  "myString": "Hello",  // ❌ NO trailing comma on last item
  "myOtherString": "World"
}
```

---

## Currency Input Issues

### Problem: Formatting Not Working (No Commas)

**Symptoms**: User enters `1000.50` but it doesn't format to `1,000.50`.

**Solution**: Ensure you're using `CurrencyTextField` (not plain `TextField`)
```dart
// ❌ BAD: Plain TextField
TextField(
  controller: _amountController,
)

// ✅ GOOD: CurrencyTextField
CurrencyTextField(
  controller: _amountController,
  currencyCode: CurrencyCode.usd,
  label: context.l10n.expenseFieldAmountLabel,
)
```

---

### Problem: Decimal Places Showing for VND

**Symptoms**: VND input allows decimal places (should be whole numbers only).

**Solution**: Ensure currency is `CurrencyCode.vnd`
```dart
CurrencyTextField(
  controller: _amountController,
  currencyCode: CurrencyCode.vnd,  // NOT CurrencyCode.usd!
  label: context.l10n.expenseFieldAmountLabel,
)
```

---

### Problem: Can't Parse Amount (FormatException)

**Symptoms**: `Decimal.parse()` throws FormatException.

**Cause**: Trying to parse formatted string (with commas).

**Solution**: Use `stripCurrencyFormatting()` first
```dart
// ❌ BAD: Parse formatted string
final amount = Decimal.parse(_amountController.text);  // Throws on "1,000.50"

// ✅ GOOD: Strip formatting first
final cleanValue = stripCurrencyFormatting(_amountController.text);
final amount = Decimal.parse(cleanValue);  // Works!
```

---

### Problem: Value Not Pre-filling When Editing

**Symptoms**: Editing an expense shows empty amount field.

**Cause**: Not formatting the initial value.

**Solution**: Use `formatAmountForInput()` for initial value
```dart
_amountController = TextEditingController(
  text: expense != null
      ? formatAmountForInput(expense.amount, expense.currency)  // Format!
      : '',
);
```

---

### Problem: Validation Not Showing

**Symptoms**: Empty amount field doesn't show error.

**Cause**: Form not wrapped in `Form` widget, or not calling `validate()`.

**Solution**: Wrap in Form and call validate
```dart
final _formKey = GlobalKey<FormState>();

Form(
  key: _formKey,
  child: Column(
    children: [
      CurrencyTextField(...),
      ElevatedButton(
        onPressed: () {
          if (_formKey.currentState!.validate()) {
            // Save expense
          }
        },
      ),
    ],
  ),
)
```

---

## Activity Logging Issues

### Problem: ActivityType.X Not Found

**Symptoms**: Compilation error after adding new ActivityType.

**Cause**: Mock files not regenerated.

**Solution**: Run build_runner
```bash
dart run build_runner build --delete-conflicting-outputs
```

---

### Problem: Activity Shows "null" for Actor

**Symptoms**: Activity log shows "null performed action".

**Cause**: Actor name not passed correctly.

**Solution**: Always get actor from current user
```dart
// ✅ CORRECT
final currentUser = context.read<TripCubit>().getCurrentUserForTrip(tripId);
if (currentUser != null) {
  context.read<ExpenseCubit>().createExpense(
    expense,
    actorName: currentUser.name,
  );
}
```

---

## Build & Test Issues

### Problem: "Missing Stub" Error in Tests

**Symptoms**: `MissingStubError: 'method'` when running tests.

**Solution**: Add `when(...).thenAnswer(...)` stub
```dart
// Add stub for the method being called
when(mockRepository.getExpenses(any)).thenAnswer(
  (_) => Stream.value([]),
);
```

---

### Problem: ".mocks.dart File Not Found"

**Symptoms**: Import error for `*.mocks.dart` file.

**Solution**: Generate mocks
```bash
dart run build_runner build --delete-conflicting-outputs
```

---

### Problem: Test Times Out

**Symptoms**: Test hangs and times out after 30 seconds.

**Cause**: Waiting for async operation that never completes.

**Solution**: Add timeout and check stubs
```dart
test('should do something', () async {
  // Ensure all async operations have stubs
  when(mockRepository.createExpense(any)).thenAnswer((_) async => expense);

  await cubit.createExpense(expense);

  // Give time for async operations
  await Future.delayed(const Duration(milliseconds: 100));

  verify(mockRepository.createExpense(any)).called(1);
}, timeout: Timeout(Duration(seconds: 5)));  // Custom timeout
```

---

### Problem: "Bad State: No Element" When Capturing

**Symptoms**: Error when trying to capture arguments in test.

**Cause**: Method wasn't called, so nothing to capture.

**Solution**: Verify call first, then capture
```dart
// ✅ CORRECT
verify(mockRepository.createExpense(captureAny)).called(1);
final captured = verify(mockRepository.createExpense(captureAny))
    .captured.single as Expense;

// ❌ BAD: Capture before verifying
final captured = verify(mockRepository.createExpense(captureAny))
    .captured.single;  // Might be empty!
```

---

## Firebase Issues

### Problem: Firestore Permission Denied

**Symptoms**: `PERMISSION_DENIED` error when accessing Firestore.

**Cause**: Security rules preventing access, or user not authenticated.

**Solution 1**: Check Firebase security rules
**Solution 2**: Ensure user is authenticated
**Solution 3**: Check document path is correct

---

### Problem: Data Not Updating in Real-Time

**Symptoms**: Changes in Firestore don't reflect in UI immediately.

**Cause**: Using `get()` instead of `snapshots()`.

**Solution**: Use streams for real-time updates
```dart
// ❌ BAD: One-time read
Future<List<Expense>> getExpenses() {
  return _firestore.collection('expenses').get().then(...);
}

// ✅ GOOD: Real-time stream
Stream<List<Expense>> getExpenses() {
  return _firestore.collection('expenses').snapshots().map(...);
}
```

---

## Performance Issues

### Problem: App Slow on Mobile

**Symptoms**: UI lags or stutters on mobile devices.

**Common causes**:
1. Building expensive widgets in build method
2. Not using `const` constructors
3. Large lists without `ListView.builder`
4. Unoptimized images

**Solutions**:
1. Move expensive computations to cubit/repository
2. Use `const` for static widgets
3. Always use `ListView.builder` for lists
4. Optimize image sizes for mobile

---

### Problem: Too Many Rebuilds

**Symptoms**: UI flickering, or poor performance.

**Cause**: State changes triggering unnecessary rebuilds.

**Solution**: Use `BlocBuilder` with `buildWhen`
```dart
BlocBuilder<ExpenseCubit, ExpenseState>(
  buildWhen: (previous, current) {
    // Only rebuild when expenses actually change
    return previous.expenses != current.expenses;
  },
  builder: (context, state) {
    return ExpenseList(expenses: state.expenses);
  },
)
```

---

## Getting More Help

If your issue isn't listed here:

1. **Check the skills**: `.claude/skills/` for detailed workflows
2. **Check documentation**:
   - [CLAUDE.md](CLAUDE.md) - Quick reference
   - [PROJECT_KNOWLEDGE.md](PROJECT_KNOWLEDGE.md) - Architecture
   - [MOBILE.md](MOBILE.md) - Mobile design
   - [DEVELOPMENT.md](DEVELOPMENT.md) - Development workflows
3. **Search codebase**: Look for similar implementations
4. **Check tests**: Test files often show expected usage
5. **Review error messages**: Flutter error messages are usually helpful

## Contributing to This Guide

Found a solution to a common problem? Add it here:
1. Identify the problem category
2. Describe symptoms clearly
3. Explain the cause
4. Provide concrete solution with code examples
5. Show both ❌ bad and ✅ good examples when possible
