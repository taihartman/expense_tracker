# Quickstart Guide: Itemized Expense Splitter

**Feature**: Plates-Style Itemized Receipt Splitting
**Branch**: `002-itemized-splitter`
**Date**: 2025-10-28
**Audience**: Developers onboarding to this feature

## Overview

This guide helps you quickly understand, run, and contribute to the itemized expense splitter feature. You'll learn how to set up your environment, navigate the codebase, run tests, and make common changes.

---

## Prerequisites

### Required Software

1. **Flutter SDK**: 3.35.1+ (stable channel)
   ```bash
   flutter --version
   # Should show: Flutter 3.35.1 • channel stable
   ```

2. **Dart SDK**: 3.9.0+ (included with Flutter)
   ```bash
   dart --version
   # Should show: Dart SDK version: 3.9.0
   ```

3. **Firebase CLI** (optional, for Firestore emulator):
   ```bash
   npm install -g firebase-tools
   firebase --version
   ```

4. **Chrome** (for web development):
   - Required for `flutter run -d chrome`

### Repository Setup

```bash
# Clone repository
git clone https://github.com/yourusername/expense_tracker.git
cd expense_tracker

# Checkout feature branch
git checkout 002-itemized-splitter

# Install dependencies
flutter pub get

# Verify setup
flutter doctor
```

### Firebase Configuration

This app uses Firebase for persistence. You'll need a `firebase_options.dart` file:

```bash
# If firebase_options.dart doesn't exist, create from template
# (Ask your team lead for the Firebase project configuration)

# The file should be at:
# lib/firebase_options.dart
```

---

## Running the Application

### Development Mode (Local)

```bash
# Run on Chrome (web platform)
flutter run -d chrome

# The app will open in Chrome at:
# http://localhost:54321
```

### Navigate to Itemized Expense Flow

Once the app is running:

1. **Create or select a trip** (if none exist, create one first)
2. **Click "Add Expense" button** (usually a FAB or in app bar)
3. **Select "Itemized (Plates)" option** from split type picker
4. **You're now in the 4-step itemized flow**:
   - Step 1: Select participants and payer
   - Step 2: Add and assign line items
   - Step 3: Enter tax/tip/fees/discounts
   - Step 4: Review split and save

---

## Project Structure

### Key Directories

```
lib/features/expenses/
├── domain/               # Business logic (no UI dependencies)
│   ├── models/           # Domain entities
│   │   ├── expense.dart           # [EXTENDED] Main expense entity
│   │   ├── line_item.dart         # [NEW] Receipt line item
│   │   ├── item_assignment.dart   # [NEW] How items are split
│   │   ├── extras.dart            # [NEW] Tax/tip/fees container
│   │   ├── tax_extra.dart         # [NEW] Tax configuration
│   │   ├── tip_extra.dart         # [NEW] Tip configuration
│   │   ├── fee_extra.dart         # [NEW] Fee configuration
│   │   ├── discount_extra.dart    # [NEW] Discount configuration
│   │   ├── allocation_rule.dart   # [NEW] Allocation config
│   │   ├── rounding_config.dart   # [NEW] Rounding policy
│   │   └── participant_breakdown.dart # [NEW] Audit trail
│   ├── repositories/     # Data access interfaces
│   └── services/         # Business services
│       ├── itemized_calculator.dart  # [NEW] Calculation engine
│       └── rounding_service.dart     # [NEW] Rounding logic
├── data/                 # Firestore integration
│   ├── models/           # DTOs for serialization
│   │   ├── expense_model.dart        # [EXTENDED] Firestore mapper
│   │   ├── line_item_model.dart      # [NEW] DTO
│   │   └── extras_model.dart         # [NEW] DTO
│   └── repositories/     # Repository implementations
└── presentation/         # UI layer
    ├── cubits/           # State management (BLoC pattern)
    │   ├── itemized_expense_cubit.dart  # [NEW] Draft state
    │   └── itemized_expense_state.dart  # [NEW] State classes
    ├── pages/            # Full-screen pages
    │   └── itemized/     # [NEW] Itemized flow pages
    │       ├── itemized_expense_flow.dart  # Wizard coordinator
    │       ├── people_step_page.dart       # Step 1
    │       ├── items_step_page.dart        # Step 2
    │       ├── extras_step_page.dart       # Step 3
    │       └── review_step_page.dart       # Step 4
    └── widgets/          # Reusable UI components
        └── itemized/     # [NEW] Itemized-specific widgets
            ├── line_item_card.dart
            ├── person_breakdown_card.dart
            └── validation_banner.dart
```

### Relationship to Existing Features

```
Trip (existing)
  └─> Expense (extended)
       ├─> splitType: equal | weighted | itemized
       └─> [If itemized]
            ├─> items[] (LineItem)
            ├─> extras (Extras)
            ├─> allocation (AllocationRule)
            ├─> participantAmounts (Map)
            └─> participantBreakdown (Map)
```

---

## Understanding the Code

### Key Files to Read First

**1. Domain Models** (understand the data structure):

```bash
# Start here - the core expense entity
lib/features/expenses/domain/models/expense.dart

# Line items with assignment
lib/features/expenses/domain/models/line_item.dart

# Tax/tip/fees configuration
lib/features/expenses/domain/models/extras.dart

# Detailed breakdown for audit
lib/features/expenses/domain/models/participant_breakdown.dart
```

**2. Calculation Engine** (understand the logic):

```bash
# Core calculation service (pure Dart, no Flutter deps)
lib/features/expenses/domain/services/itemized_calculator.dart

# Rounding and remainder distribution
lib/features/expenses/domain/services/rounding_service.dart
```

**3. State Management** (understand the flow):

```bash
# Cubit manages draft state and triggers recalculation
lib/features/expenses/presentation/cubits/itemized_expense_cubit.dart

# State classes (Editing, Calculating, Ready, etc.)
lib/features/expenses/presentation/cubits/itemized_expense_state.dart
```

**4. UI Pages** (understand the user experience):

```bash
# Review screen with per-person cards
lib/features/expenses/presentation/pages/itemized/review_step_page.dart

# Items builder with assignment
lib/features/expenses/presentation/pages/itemized/items_step_page.dart
```

### How Data Flows

```
User Input (UI)
    ↓
ItemizedExpenseCubit (state management)
    ↓
ItemizedCalculator (pure calculation)
    ↓
RoundingService (rounding + remainder distribution)
    ↓
ParticipantBreakdown (detailed audit trail)
    ↓
Expense (domain entity with participantAmounts)
    ↓
ExpenseRepository (persistence)
    ↓
Firestore (cloud storage)
```

---

## Running Tests

### All Tests

```bash
# Run full test suite
flutter test

# Run with coverage report
flutter test --coverage

# View coverage in browser
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

### Specific Test Files

```bash
# Domain model tests
flutter test test/unit/expenses/domain/models/line_item_test.dart

# Calculation engine tests (golden fixtures)
flutter test test/unit/expenses/domain/services/itemized_calculator_test.dart

# Rounding service tests
flutter test test/unit/expenses/domain/services/rounding_service_test.dart

# Cubit state transition tests
flutter test test/unit/expenses/presentation/cubits/itemized_expense_cubit_test.dart

# Widget tests
flutter test test/widget/expenses/itemized/review_step_page_test.dart

# Integration test (end-to-end)
flutter test test/integration/itemized_expense_flow_test.dart
```

### Test Coverage Goals

- **Domain logic**: 80%+ coverage (calculation, validation, rounding)
- **State management**: 70%+ coverage (Cubit state transitions)
- **Widgets**: 60%+ coverage (UI components)
- **Integration**: 1-2 complete flows (happy path + error cases)

---

## Common Development Tasks

### Task 1: Add a New Allocation Base

**Example**: Add support for "postTipSubtotals" base (for calculating fees after tip).

**Steps**:

1. **Add enum value**:
   ```dart
   // lib/features/expenses/domain/models/percent_base.dart
   enum PercentBase {
     preTaxItemSubtotals,
     taxableItemSubtotalsOnly,
     postDiscountItemSubtotals,
     postTaxSubtotals,
     postFeesSubtotals,
     postTipSubtotals, // NEW
   }
   ```

2. **Update calculation engine**:
   ```dart
   // lib/features/expenses/domain/services/itemized_calculator.dart
   Decimal _calculatePercentBase({
     required PercentBase baseType,
     // ... existing params
     required Map<String, Decimal> tipAllocations, // NEW param
   }) {
     return switch (baseType) {
       // ... existing cases
       PercentBase.postTipSubtotals => {
         itemSubtotals.values.sum() +
         taxAllocations.values.sum() +
         tipAllocations.values.sum()
       },
     };
   }
   ```

3. **Add test case**:
   ```dart
   // test/unit/expenses/domain/services/itemized_calculator_test.dart
   test('calculates fee on postTipSubtotals base', () {
     final result = calculator.calculate(
       items: [/* ... */],
       extras: Extras(
         tip: TipExtra(/* ... */),
         fees: [
           FeeExtra(
             name: 'Processing Fee',
             percentValue: Decimal.parse('2'),
             percentBase: PercentBase.postTipSubtotals,
           ),
         ],
       ),
       allocation: allocation,
     );

     // Assert fee is calculated on items + tax + tip
     expect(result.breakdowns['alice']!.feesAllocated, Decimal.parse('X'));
   });
   ```

4. **Update UI dropdown**:
   ```dart
   // lib/features/expenses/presentation/widgets/itemized/allocation_settings.dart
   DropdownButton<PercentBase>(
     items: [
       // ... existing items
       DropdownMenuItem(
         value: PercentBase.postTipSubtotals,
         child: Text('After Tip'),
       ),
     ],
   )
   ```

---

### Task 2: Add a New Rounding Strategy

**Example**: Add "alternating" strategy (assigns remainder to different person each time).

**Steps**:

1. **Add enum value**:
   ```dart
   // lib/features/expenses/domain/models/rounding_config.dart
   enum RemainderDistributionMode {
     largestShare,
     payer,
     firstListed,
     random,
     alternating, // NEW
   }
   ```

2. **Implement strategy**:
   ```dart
   // lib/features/expenses/domain/services/rounding_service.dart
   String _getRecipientForRemainder({
     required RemainderDistributionMode mode,
     required Map<String, Decimal> itemSubtotals,
     required String payerId,
     required String expenseId,
     required List<Expense> recentExpenses, // NEW param for alternating
   }) {
     return switch (mode) {
       // ... existing cases
       RemainderDistributionMode.alternating => {
         // Get last recipient from recent expenses
         final lastRecipient = _getLastRemainderRecipient(recentExpenses);
         final participants = itemSubtotals.keys.toList()..sort();
         final lastIndex = participants.indexOf(lastRecipient);
         final nextIndex = (lastIndex + 1) % participants.length;
         participants[nextIndex]
       },
     };
   }
   ```

3. **Add test**:
   ```dart
   test('distributes remainder in alternating fashion', () {
     // Test that consecutive expenses assign remainder to different people
   });
   ```

---

### Task 3: Add a Field to LineItem

**Example**: Add "notes" field for item-specific notes.

**Steps**:

1. **Update domain model**:
   ```dart
   // lib/features/expenses/domain/models/line_item.dart
   class LineItem {
     final String id;
     final String name;
     final Decimal quantity;
     final Decimal unitPrice;
     final bool taxable;
     final bool serviceChargeable;
     final ItemAssignment assignment;
     final String? notes; // NEW

     const LineItem({
       // ... existing params
       this.notes,
     });
   }
   ```

2. **Update Firestore DTO**:
   ```dart
   // lib/features/expenses/data/models/line_item_model.dart
   static Map<String, dynamic> toFirestore(LineItem item) {
     return {
       // ... existing fields
       if (item.notes != null) 'notes': item.notes,
     };
   }

   static LineItem fromFirestore(Map<String, dynamic> data) {
     return LineItem(
       // ... existing fields
       notes: data['notes'] as String?,
     );
   }
   ```

3. **Update JSON schema**:
   ```json
   // specs/002-itemized-splitter/contracts/line_item_dto.json
   {
     "properties": {
       // ... existing properties
       "notes": {
         "type": "string",
         "description": "Optional item-specific note",
         "maxLength": 200
       }
     }
   }
   ```

4. **Update UI**:
   ```dart
   // lib/features/expenses/presentation/pages/itemized/items_step_page.dart
   TextField(
     decoration: InputDecoration(labelText: 'Notes (optional)'),
     maxLength: 200,
     onChanged: (value) => context.read<ItemizedExpenseCubit>()
       .updateItemNotes(itemId, value),
   )
   ```

5. **Add test**:
   ```dart
   test('preserves item notes through save/load cycle', () {
     // Create expense with item.notes = "Extra spicy"
     // Save to Firestore
     // Load back
     // Assert notes field is preserved
   });
   ```

---

### Task 4: Modify Calculation Logic

**Example**: Change how tax is allocated to use custom weights instead of proportional.

**Steps**:

1. **Identify calculation code**:
   ```dart
   // lib/features/expenses/domain/services/itemized_calculator.dart
   Map<String, Decimal> _calculateTax(...) {
     // Current: allocate proportionally
     return _allocateProportionally(totalTax, itemSubtotals);
   }
   ```

2. **Modify logic**:
   ```dart
   Map<String, Decimal> _calculateTax({
     required TaxExtra tax,
     required Map<String, Decimal> itemSubtotals,
     required Map<String, Decimal>? customTaxWeights, // NEW param
   }) {
     if (customTaxWeights != null) {
       return _allocateByWeights(totalTax, customTaxWeights);
     }
     return _allocateProportionally(totalTax, itemSubtotals);
   }
   ```

3. **Update tests**:
   ```dart
   test('allocates tax using custom weights', () {
     final result = calculator.calculate(
       // ... params with customTaxWeights
     );
     expect(result.breakdowns['alice']!.taxAllocated, expectedAmount);
   });
   ```

4. **Update golden fixtures**:
   ```bash
   # Regenerate expected outputs
   flutter test test/unit/expenses/domain/services/itemized_calculator_test.dart --update-goldens
   ```

5. **Update data model docs**:
   ```markdown
   // specs/002-itemized-splitter/data-model.md
   ## TaxExtra
   - customWeights: Map<String, Decimal>? (optional weights for allocation)
   ```

---

## Debugging Tips

### Enable Verbose Logging

```dart
// lib/features/expenses/domain/services/itemized_calculator.dart
import 'package:logging/logging.dart';

final _log = Logger('ItemizedCalculator');

Map<String, Decimal> calculate(...) {
  _log.fine('Calculating with ${items.length} items');
  _log.fine('Item subtotals: $itemSubtotals');
  _log.fine('Tax: ${extras.tax}');

  // ... calculation logic

  _log.fine('Final breakdowns: $breakdowns');
  return breakdowns;
}
```

Enable in `main.dart`:
```dart
void main() {
  Logger.root.level = Level.FINE;
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.message}');
  });

  runApp(MyApp());
}
```

### Use Flutter DevTools

```bash
# Run app in debug mode
flutter run -d chrome

# Open DevTools
# Press "p" in terminal or navigate to http://localhost:xxxxx/#/debugger
```

**Key DevTools Features**:
- **Widget Inspector**: View widget tree, find UI issues
- **Timeline**: Profile performance, find jank
- **Memory**: Track memory leaks
- **Network**: Monitor Firestore calls
- **Logging**: View all print/log statements

### Debug Calculation Issues

If per-person totals don't sum correctly:

1. **Add breakpoint in calculator**:
   ```dart
   // lib/features/expenses/domain/services/itemized_calculator.dart
   final breakdowns = <String, ParticipantBreakdown>{};
   for (final userId in participants) {
     // SET BREAKPOINT HERE
     final breakdown = _calculatePersonBreakdown(userId, ...);
     breakdowns[userId] = breakdown;
   }
   ```

2. **Inspect intermediate values**:
   - Check `itemSubtotals[userId]`
   - Check `taxAllocations[userId]`
   - Check `roundedAmounts[userId]`
   - Check `remainder` value

3. **Verify invariants**:
   ```dart
   // Add assertions during development
   assert(
     participantAmounts.values.sum() == grandTotal,
     'Sum check failed: ${participantAmounts.values.sum()} != $grandTotal',
   );
   ```

### Debug Firestore Serialization

If expense doesn't save/load correctly:

1. **Check Firestore console**:
   - Firebase Console → Firestore Database
   - Navigate to `expenses/{expenseId}`
   - Verify all fields are present and have correct types

2. **Add logging to DTO**:
   ```dart
   // lib/features/expenses/data/models/expense_model.dart
   static Map<String, dynamic> toFirestore(Expense expense) {
     final data = {
       'amount': expense.amount.toString(),
       // ... other fields
     };
     print('Serializing expense: $data');
     return data;
   }
   ```

3. **Test serialization round-trip**:
   ```dart
   test('expense survives Firestore round-trip', () {
     final original = Expense(/* ... */);
     final json = ExpenseModel.toFirestore(original);
     final restored = ExpenseModel.fromFirestore(
       MockDocumentSnapshot(json),
     );
     expect(restored, equals(original));
   });
   ```

---

## Performance Profiling

### Profile Calculation Speed

```dart
// test/performance/itemized_calculator_benchmark.dart
import 'package:test/test.dart';

void main() {
  test('benchmark large receipt (300 items, 6 people)', () {
    final items = List.generate(300, (i) => createTestItem(i));
    final calculator = ItemizedCalculator();

    final stopwatch = Stopwatch()..start();

    for (var i = 0; i < 100; i++) {
      calculator.calculate(items: items, extras: extras, allocation: allocation);
    }

    stopwatch.stop();
    final avgMs = stopwatch.elapsedMilliseconds / 100;

    print('Average calculation time: ${avgMs}ms');
    expect(avgMs, lessThan(100), reason: 'Should calculate in <100ms');
  });
}
```

Run:
```bash
flutter test test/performance/itemized_calculator_benchmark.dart
```

### Profile UI Rendering

1. **Run in profile mode**:
   ```bash
   flutter run --profile -d chrome
   ```

2. **Open DevTools → Performance tab**

3. **Navigate to review screen with large receipt**

4. **Trigger rebuild** (scroll, expand cards)

5. **Check timeline** for:
   - Frame render time (should be <16ms for 60fps)
   - Expensive widgets (look for long build times)
   - Layout/paint jank

---

## Code Style & Conventions

### Naming Conventions

- **Classes**: `PascalCase` (e.g., `LineItem`, `ItemizedCalculator`)
- **Files**: `snake_case.dart` (e.g., `line_item.dart`, `itemized_calculator.dart`)
- **Variables**: `camelCase` (e.g., `itemSubtotal`, `participantAmounts`)
- **Constants**: `lowerCamelCase` (e.g., `maxItems = 300`)
- **Enums**: `camelCase` values (e.g., `AssignmentMode.even`, not `AssignmentMode.EVEN`)

### Documentation

All public classes/methods must have dartdoc comments:

```dart
/// Calculates per-person breakdowns for an itemized expense.
///
/// Takes a list of [items] with assignments, applies [extras] (tax/tip/fees),
/// and produces a map of userId to [ParticipantBreakdown] with full audit trail.
///
/// Throws [ValidationException] if any item is unassigned or totals don't balance.
///
/// Example:
/// ```dart
/// final breakdowns = calculator.calculate(
///   items: [item1, item2],
///   extras: Extras(tax: tax, tip: tip),
///   allocation: AllocationRule.fromCurrency('USD'),
/// );
/// ```
Map<String, ParticipantBreakdown> calculate({
  required List<LineItem> items,
  required Extras extras,
  required AllocationRule allocation,
}) {
  // Implementation
}
```

### Testing Best Practices

1. **Use descriptive test names**:
   ```dart
   test('allocates remainder to payer when mode is RemainderDistributionMode.payer', () {
     // Test body
   });
   ```

2. **Arrange-Act-Assert pattern**:
   ```dart
   test('calculates tax on taxable items only', () {
     // Arrange
     final items = [taxableItem, nonTaxableItem];
     final extras = Extras(tax: TaxExtra(/* ... */));

     // Act
     final result = calculator.calculate(items: items, extras: extras, ...);

     // Assert
     expect(result.breakdowns['alice']!.taxAllocated, expectedTax);
   });
   ```

3. **Use golden fixtures for calculation tests**:
   ```dart
   test('matches golden output for complex receipt', () {
     final result = calculator.calculate(/* ... */);
     expect(result, matchesGoldenFile('golden/complex_receipt.json'));
   });
   ```

---

## Getting Help

### Documentation

- **Feature Spec**: `specs/002-itemized-splitter/spec.md`
- **Implementation Plan**: `specs/002-itemized-splitter/plan.md`
- **Data Model**: `specs/002-itemized-splitter/data-model.md`
- **Technical Research**: `specs/002-itemized-splitter/research.md`
- **JSON Schemas**: `specs/002-itemized-splitter/contracts/*.json`

### Ask Questions

- **GitHub Issues**: Tag with `feature:002-itemized-splitter`
- **Pull Request Comments**: For code-specific questions
- **Team Chat**: For quick clarifications

### Common Issues

**Issue**: "participantAmounts sum doesn't equal amount"
- **Solution**: Check rounding precision matches currency. Enable verbose logging in `RoundingService` to see remainder distribution.

**Issue**: "All items must be assigned" error
- **Solution**: Verify all `LineItem.assignment.assignedUserIds` lists are non-empty. Check validation logic in `ItemizedExpenseCubit`.

**Issue**: "Negative total for participant"
- **Solution**: Discounts may exceed item subtotals. Check discount clamping logic in `ItemizedCalculator._applyDiscounts()`.

**Issue**: "Test fails with 'expected X but got Y'"
- **Solution**: If using Decimal arithmetic, ensure you're comparing with epsilon tolerance:
  ```dart
  expect((actual - expected).abs() < Decimal.parse('0.01'), isTrue);
  ```

---

## Next Steps

### For New Developers

1. **Read the spec**: `specs/002-itemized-splitter/spec.md` (understand requirements)
2. **Read data-model.md**: Understand all entities and their relationships
3. **Run the app**: Follow "Running the Application" section
4. **Create a test expense**: Walk through the 4-step flow manually
5. **Read calculator code**: `lib/features/expenses/domain/services/itemized_calculator.dart`
6. **Run tests**: `flutter test` and observe outputs
7. **Make a small change**: Try Task 3 (add a field) to practice the workflow

### For Contributors

Check the task list for available work:
```bash
# If tasks.md exists
cat specs/002-itemized-splitter/tasks.md

# Or run:
/speckit.tasks
```

Look for tasks marked:
- `[TODO]` - Not started
- `[INPROGRESS]` - Someone is working on it
- `[DONE]` - Completed

Pick a task, create a branch, and submit a PR!

---

## Useful Commands Reference

```bash
# Development
flutter run -d chrome               # Run app in dev mode
flutter run --release -d chrome     # Run optimized build
flutter pub get                     # Install dependencies
flutter pub upgrade                 # Upgrade dependencies

# Testing
flutter test                        # Run all tests
flutter test --coverage             # Run with coverage
flutter test path/to/test.dart      # Run specific test
flutter test --update-goldens       # Regenerate golden files

# Code Quality
flutter analyze                     # Run linter
flutter format .                    # Format all Dart files
flutter format --set-exit-if-changed .  # Check formatting (CI)

# Build
flutter build web                   # Build for production
flutter build web --release         # Optimized production build
flutter clean                       # Clean build artifacts

# Firebase
firebase emulators:start            # Start local Firestore emulator
firebase deploy                     # Deploy to production

# Git
git status                          # Check changes
git diff                            # View changes
git add .                           # Stage all changes
git commit -m "message"             # Commit
git push origin 002-itemized-splitter  # Push to branch
```

---

**Document Version**: 1.0
**Last Updated**: 2025-10-28
**Maintained By**: Feature 002 Team
**Questions**: Open an issue with tag `feature:002-itemized-splitter`
