# Quickstart: Receipt Split UX Implementation

**Feature**: 005-receipt-split-ux
**Target**: Developers implementing this feature
**Prerequisites**: Read [spec.md](./spec.md), [plan.md](./plan.md), and [research.md](./research.md)

## Overview

This guide provides step-by-step instructions for implementing the Receipt Split UX improvements. Follow the TDD cycle: write tests first, then implement, then refactor.

---

## Phase 1: Localization Updates (Foundation)

**Why First**: All other components depend on updated localization strings.

### Step 1.1: Backup Current Localization

```bash
cp lib/l10n/app_en.arb lib/l10n/app_en.arb.backup
```

### Step 1.2: Update ARB Keys and Values

**File**: `lib/l10n/app_en.arb`

**Find and Replace** (use IDE or sed):
```bash
# Replace all key names
sed -i '' 's/"itemized/"receiptSplit/g' lib/l10n/app_en.arb
```

**Manual Updates** (key string values):
- `"receiptSplitWizardTitleNew"`: `"New Receipt Split"`
- `"receiptSplitWizardTitleEdit"`: `"Edit Receipt Split"`
- `"expenseSplitTypeReceiptSplit"`: `"Receipt Split (Who Ordered What)"`
- Update all wizard step, items, extras, review strings to use "Receipt Split" terminology

### Step 1.3: Regenerate L10n Files

```bash
flutter pub get  # Triggers code generation
dart format .    # Format generated files
```

### Step 1.4: Update Code References

**Find All References**:
```bash
grep -r "\.l10n\.itemized" lib/ test/
```

**Replace in All Files**:
```bash
find lib test -name "*.dart" -exec sed -i '' 's/\.l10n\.itemized/.l10n.receiptSplit/g' {} +
```

**Verify**:
```bash
flutter analyze  # Should show zero errors related to l10n
```

### Step 1.5: Test Localization

```bash
flutter test  # Existing tests should still pass with new strings
```

---

## Phase 2: FAB Speed Dial Widget (Core Component)

**Why Second**: Reusable component needed by Expense List Page.

### Step 2.1: Write Widget Tests First (TDD)

**File**: `test/widget/features/expenses/fab_speed_dial_test.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/expenses/presentation/widgets/fab_speed_dial.dart';

void main() {
  group('ExpenseFabSpeedDial', () {
    testWidgets('displays main FAB in closed state', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Container(),
            floatingActionButton: ExpenseFabSpeedDial(
              tripId: 'test-trip',
              onQuickExpenseTap: () {},
              onReceiptSplitTap: () {},
            ),
          ),
        ),
      );

      // Verify main FAB present
      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('expands to show options when tapped', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Container(),
            floatingActionButton: ExpenseFabSpeedDial(
              tripId: 'test-trip',
              onQuickExpenseTap: () {},
              onReceiptSplitTap: () {},
            ),
          ),
        ),
      );

      // Tap main FAB
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();  // Wait for animation

      // Verify mini FABs visible
      expect(find.byType(FloatingActionButton), findsNWidgets(3));  // Main + 2 mini
      expect(find.byIcon(Icons.flash_on), findsOneWidget);          // Quick Expense
      expect(find.byIcon(Icons.receipt_long), findsOneWidget);      // Receipt Split
    });

    testWidgets('calls onQuickExpenseTap when Quick Expense tapped', (tester) async {
      bool quickExpenseTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Container(),
            floatingActionButton: ExpenseFabSpeedDial(
              tripId: 'test-trip',
              onQuickExpenseTap: () => quickExpenseTapped = true,
              onReceiptSplitTap: () {},
            ),
          ),
        ),
      );

      // Open Speed Dial
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Tap Quick Expense option
      await tester.tap(find.byIcon(Icons.flash_on));
      await tester.pumpAndSettle();

      expect(quickExpenseTapped, isTrue);
    });

    testWidgets('calls onReceiptSplitTap when Receipt Split tapped', (tester) async {
      bool receiptSplitTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Container(),
            floatingActionButton: ExpenseFabSpeedDial(
              tripId: 'test-trip',
              onQuickExpenseTap: () {},
              onReceiptSplitTap: () => receiptSplitTapped = true,
            ),
          ),
        ),
      );

      // Open Speed Dial
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Tap Receipt Split option
      await tester.tap(find.byIcon(Icons.receipt_long));
      await tester.pumpAndSettle();

      expect(receiptSplitTapped, isTrue);
    });

    testWidgets('closes when backdrop tapped', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Container(),
            floatingActionButton: ExpenseFabSpeedDial(
              tripId: 'test-trip',
              onQuickExpenseTap: () {},
              onReceiptSplitTap: () {},
            ),
          ),
        ),
      );

      // Open Speed Dial
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Tap backdrop (outside FABs)
      await tester.tapAt(Offset(100, 100));  // Top-left corner
      await tester.pumpAndSettle();

      // Verify closed (only main FAB visible)
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });
  });
}
```

**Run Tests** (should fail - widget doesn't exist yet):
```bash
flutter test test/widget/features/expenses/fab_speed_dial_test.dart
```

### Step 2.2: Implement FAB Speed Dial Widget

**File**: `lib/features/expenses/presentation/widgets/fab_speed_dial.dart`

```dart
import 'package:flutter/material.dart';

/// A Material Design Speed Dial FAB for expense entry options.
///
/// Displays a main FAB that expands to show two options:
/// - Quick Expense (equal/weighted splits)
/// - Receipt Split (itemized wizard)
class ExpenseFabSpeedDial extends StatefulWidget {
  final String tripId;
  final VoidCallback onQuickExpenseTap;
  final VoidCallback onReceiptSplitTap;

  const ExpenseFabSpeedDial({
    Key? key,
    required this.tripId,
    required this.onQuickExpenseTap,
    required this.onReceiptSplitTap,
  }) : super(key: key);

  @override
  State<ExpenseFabSpeedDial> createState() => _ExpenseFabSpeedDialState();
}

class _ExpenseFabSpeedDialState extends State<ExpenseFabSpeedDial>
    with SingleTickerProviderStateMixin {
  bool _isOpen = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      _scaleAnimation,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  void _close() {
    if (_isOpen) {
      setState(() {
        _isOpen = false;
        _animationController.reverse();
      });
    }
  }

  void _handleQuickExpenseTap() {
    _close();
    widget.onQuickExpenseTap();
  }

  void _handleReceiptSplitTap() {
    _close();
    widget.onReceiptSplitTap();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        // Backdrop (dismisses Speed Dial when tapped)
        if (_isOpen)
          Positioned.fill(
            child: GestureDetector(
              onTap: _close,
              child: Container(
                color: Colors.black.withOpacity(0.3),
              ),
            ),
          ),

        // Mini FAB 2: Receipt Split (144dp above main)
        if (_isOpen)
          Positioned(
            right: 0,
            bottom: 144,
            child: FadeTransition(
              opacity: _opacityAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: FloatingActionButton.small(
                  heroTag: 'receiptSplit',
                  onPressed: _handleReceiptSplitTap,
                  tooltip: 'Receipt Split (Who Ordered What)',
                  child: const Icon(Icons.receipt_long),
                ),
              ),
            ),
          ),

        // Mini FAB 1: Quick Expense (72dp above main)
        if (_isOpen)
          Positioned(
            right: 0,
            bottom: 72,
            child: FadeTransition(
              opacity: _opacityAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: FloatingActionButton.small(
                  heroTag: 'quickExpense',
                  onPressed: _handleQuickExpenseTap,
                  tooltip: 'Quick Expense',
                  child: const Icon(Icons.flash_on),
                ),
              ),
            ),
          ),

        // Main FAB
        FloatingActionButton(
          onPressed: _toggle,
          tooltip: 'Add expense options',
          child: AnimatedRotation(
            turns: _isOpen ? 0.125 : 0.0,  // 45° rotation when open
            duration: const Duration(milliseconds: 200),
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }
}
```

**Run Tests** (should pass now):
```bash
flutter test test/widget/features/expenses/fab_speed_dial_test.dart
```

---

## Phase 3: Update Expense List Page (Integration)

### Step 3.1: Update Widget Tests

**File**: `test/widget/features/expenses/expense_list_page_test.dart`

Add tests:
```dart
testWidgets('displays FAB instead of AppBar button', (tester) async {
  // ... setup ...

  // Verify AppBar does NOT have IconButton with add icon
  final appBar = tester.widget<AppBar>(find.byType(AppBar));
  expect(appBar.actions, isNot(contains(isA<IconButton>())));

  // Verify FAB present
  expect(find.byType(ExpenseFabSpeedDial), findsOneWidget);
});

testWidgets('tapping FAB Quick Expense opens bottom sheet', (tester) async {
  // ... setup ...

  // Tap FAB
  await tester.tap(find.byType(FloatingActionButton));
  await tester.pumpAndSettle();

  // Tap Quick Expense
  await tester.tap(find.byIcon(Icons.flash_on));
  await tester.pumpAndSettle();

  // Verify bottom sheet opened
  expect(find.byType(ExpenseFormBottomSheet), findsOneWidget);
});
```

### Step 3.2: Modify Expense List Page

**File**: `lib/features/expenses/presentation/pages/expense_list_page.dart`

**Remove** AppBar IconButton (lines ~53-59):
```dart
// DELETE THIS:
IconButton(
  icon: const Icon(Icons.add),
  tooltip: context.l10n.expenseAddTooltip,
  onPressed: () {
    showExpenseFormBottomSheet(context: context, tripId: tripId);
  },
),
```

**Add** FAB to Scaffold:
```dart
import 'package:expense_tracker/features/expenses/presentation/widgets/fab_speed_dial.dart';
import 'package:expense_tracker/features/expenses/presentation/pages/itemized/itemized_expense_wizard.dart';

// ... in build method ...

return Scaffold(
  appBar: AppBar(
    title: Text(context.l10n.tripExpensesTitle),
    actions: [
      // Keep existing: Settlement, Settings buttons
      IconButton(
        icon: const Icon(Icons.account_balance_wallet),
        onPressed: () => context.go('/trips/$tripId/settlements'),
      ),
      IconButton(
        icon: const Icon(Icons.settings),
        onPressed: () => context.go('/trips/$tripId/settings'),
      ),
    ],
  ),
  body: _buildBody(context, tripId),
  floatingActionButton: ExpenseFabSpeedDial(
    tripId: tripId,
    onQuickExpenseTap: () {
      showExpenseFormBottomSheet(
        context: context,
        tripId: tripId,
      );
    },
    onReceiptSplitTap: () {
      // Get participants and navigate to wizard
      final tripState = context.read<TripCubit>().state;
      if (tripState is TripLoaded) {
        final trip = tripState.trips.firstWhere((t) => t.id == tripId);
        final participantNames = {
          for (var p in trip.participants) p.id: p.name
        };

        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => BlocProvider(
              create: (context) => ItemizedExpenseCubit(
                expenseRepository: context.read<ExpenseRepository>(),
                activityLogRepository: context.read<ActivityLogRepository>(),
              ),
              child: ItemizedExpenseWizard(
                tripId: tripId,
                participants: trip.participants.map((p) => p.id).toList(),
                participantNames: participantNames,
                initialPayerUserId: null,  // User will select in wizard
                currency: trip.baseCurrency,
              ),
            ),
          ),
        );
      }
    },
  ),
  floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
);
```

**Add Bottom Padding** to expense list:
```dart
ListView.builder(
  padding: const EdgeInsets.only(
    left: 16,
    right: 16,
    top: 16,
    bottom: 80,  // Space for FAB
  ),
  // ... rest of ListView ...
)
```

**Run Tests**:
```bash
flutter test test/widget/features/expenses/expense_list_page_test.dart
```

---

## Phase 4: Simplify Expense Form (Cleanup)

### Step 4.1: Update Widget Tests

**File**: `test/widget/features/expenses/expense_form_test.dart`

Update tests:
```dart
testWidgets('split type shows only Equal and Weighted', (tester) async {
  // ... setup ...

  // Verify segmented button has 2 segments
  final segmentedButton = tester.widget<SegmentedButton<SplitType>>(
    find.byType(SegmentedButton<SplitType>),
  );
  expect(segmentedButton.segments.length, 2);

  // Verify no "Itemized" button
  expect(find.text(context.l10n.expenseSplitTypeReceiptSplit), findsNothing);
});
```

### Step 4.2: Modify Expense Form Page

**File**: `lib/features/expenses/presentation/pages/expense_form_page.dart`

**Remove** itemized button (lines ~595-639):
```dart
// KEEP THIS (Segmented Button):
SegmentedButton<SplitType>(
  segments: [
    ButtonSegment(
      value: SplitType.equal,
      label: Text(context.l10n.expenseSplitTypeEqual),
      icon: const Icon(Icons.people),
    ),
    ButtonSegment(
      value: SplitType.weighted,
      label: Text(context.l10n.expenseSplitTypeWeighted),
      icon: const Icon(Icons.balance),
    ),
  ],
  selected: {selectedSplitType},
  onSelectionChanged: (Set<SplitType> newSelection) {
    onSplitTypeChanged(newSelection.first);
  },
),

// DELETE THIS (Itemized button):
const SizedBox(height: AppTheme.spacing1),
SizedBox(
  width: double.infinity,
  child: OutlinedButton.icon(
    onPressed: () {
      debugPrint('🟣 [UI] Itemized button CLICKED');
      onSplitTypeChanged(SplitType.itemized);
    },
    icon: const Icon(Icons.receipt_long),
    label: Text(context.l10n.expenseSplitTypeReceiptSplit),
    style: OutlinedButton.styleFrom(
      padding: const EdgeInsets.symmetric(vertical: 12),
    ),
  ),
),
```

### Step 4.3: Modify Expense Form Bottom Sheet

**File**: `lib/features/expenses/presentation/widgets/expense_form_bottom_sheet.dart`

**Remove** itemized navigation logic (lines ~241-333):
```dart
// In onSplitTypeChanged handler:

void onSplitTypeChanged(SplitType value) {
  // DELETE THE ENTIRE `if (value == SplitType.itemized)` BLOCK

  // KEEP ONLY THIS:
  setState(() {
    _selectedSplitType = value;
    if (value == SplitType.equal) {
      // Reset to equal weights
      _participants = {for (var id in _participants.keys) id: 1};
    }
  });
}
```

**Run Tests**:
```bash
flutter test test/widget/features/expenses/expense_form_test.dart
```

---

## Phase 5: Integration Testing (Edit Flow)

### Step 5.1: Create Integration Test

**File**: `test/integration/expense_edit_flow_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/core/models/split_type.dart';
// ... other imports ...

void main() {
  group('Expense Edit Flow', () {
    testWidgets('Equal split expense opens Quick Expense form', (tester) async {
      // Create equal split expense
      final expense = Expense(
        id: 'test-1',
        tripId: 'trip-1',
        splitType: SplitType.equal,
        // ... other fields ...
      );

      // Tap expense card
      await tester.tap(find.text(expense.description));
      await tester.pumpAndSettle();

      // Verify Quick Expense form opened (bottom sheet)
      expect(find.byType(ExpenseFormBottomSheet), findsOneWidget);
      expect(find.byType(ItemizedExpenseWizard), findsNothing);
    });

    testWidgets('Receipt Split expense opens wizard', (tester) async {
      // Create itemized expense
      final expense = Expense(
        id: 'test-2',
        tripId: 'trip-1',
        splitType: SplitType.itemized,
        // ... other fields ...
      );

      // Tap expense card
      await tester.tap(find.text(expense.description));
      await tester.pumpAndSettle();

      // Verify wizard opened
      expect(find.byType(ItemizedExpenseWizard), findsOneWidget);
      expect(find.byType(ExpenseFormBottomSheet), findsNothing);
    });
  });
}
```

**Run Test**:
```bash
flutter test test/integration/expense_edit_flow_test.dart
```

---

## Phase 6: Manual QA

### Checklist

**FAB Speed Dial**:
- [ ] FAB appears at bottom-right on expense list
- [ ] Tapping FAB expands Speed Dial with animation (<300ms)
- [ ] "Quick Expense" option visible with flash icon
- [ ] "Receipt Split (Who Ordered What)" option visible with receipt icon
- [ ] Tapping backdrop closes Speed Dial
- [ ] Tapping Quick Expense opens bottom sheet
- [ ] Tapping Receipt Split opens wizard

**Quick Expense Form**:
- [ ] Form shows only Equal and Weighted split types
- [ ] No "Itemized" or "Receipt Split" button visible
- [ ] Equal split works correctly
- [ ] Weighted split works correctly
- [ ] Saving creates expense successfully

**Receipt Split Wizard**:
- [ ] Wizard opens directly from FAB (no intermediate form)
- [ ] All 4 steps work correctly
- [ ] Strings use "Receipt Split" terminology (not "Itemized")
- [ ] Saving creates expense with `splitType: itemized`

**Edit Flow**:
- [ ] Tapping Equal split expense opens Quick Expense form
- [ ] Tapping Weighted split expense opens Quick Expense form
- [ ] Tapping Receipt Split expense opens wizard
- [ ] Existing itemized expenses (pre-migration) still open wizard

**Responsive Design**:
- [ ] FAB visible on small screens (320dp width)
- [ ] FAB doesn't overlap expense cards
- [ ] FAB visible when bottom sheet open at 50% height
- [ ] Speed Dial expansion works on all screen sizes

**Performance**:
- [ ] Speed Dial animation smooth (<16ms frames)
- [ ] No lag when tapping FAB
- [ ] No memory leaks (check DevTools)

---

## Deployment

### Pre-Merge Checklist

```bash
# 1. All tests pass
flutter test

# 2. No analyzer warnings
flutter analyze

# 3. Code formatted
dart format .

# 4. Build succeeds
flutter build web --base-href /expense_tracker/

# 5. Visual QA on local server
flutter run -d chrome
```

### Git Workflow

```bash
# 1. Commit changes
git add .
git commit -m "feat(ux): Extract Receipt Split as FAB Speed Dial entry point

- Replace AppBar '+' button with Material Design FAB Speed Dial
- Update 60+ localization strings: 'Itemized' → 'Receipt Split (Who Ordered What)'
- Simplify Quick Expense form (remove itemized button)
- Add custom ExpenseFabSpeedDial widget with tests
- Maintain backward compatibility with existing itemized expenses

🤖 Generated with Claude Code (https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"

# 2. Push to remote
git push origin 005-receipt-split-ux

# 3. Create PR
gh pr create --title "Feature 005: Receipt Split UX Improvements" \
  --body "See specs/005-receipt-split-ux/spec.md for full specification"
```

---

## Troubleshooting

### Issue: Localization strings not found

**Symptom**: `context.l10n.receiptSplitWizardTitle` undefined

**Solution**:
```bash
flutter pub get  # Regenerate l10n files
flutter clean    # Clear build cache
flutter pub get  # Regenerate again
```

### Issue: FAB overlaps content

**Solution**: Add bottom padding to scrollable content:
```dart
ListView(
  padding: EdgeInsets.only(bottom: 80),  // Space for FAB
  // ...
)
```

### Issue: Speed Dial animation stutters

**Solution**: Wrap in RepaintBoundary:
```dart
RepaintBoundary(
  child: ExpenseFabSpeedDial(...),
)
```

### Issue: Tests fail after localization update

**Solution**: Update test mocks and expectations:
```dart
// Update MockAppLocalizations to return receiptSplit* strings
when(mockL10n.receiptSplitWizardTitle).thenReturn('New Receipt Split');
```

---

## Success Criteria Verification

After implementation, verify:

- ✅ Users can identify Quick Expense vs Receipt Split within 5 seconds
- ✅ Receipt Split feature more discoverable (FAB vs buried button)
- ✅ Quick Expense flow ~25% faster (no itemized option to skip)
- ✅ Zero data loss between entry points
- ✅ Terminology clear and user-friendly
- ✅ Edit flow works for all expense types (backward compatible)
- ✅ FAB follows Material Design 3 specs

---

## Next Steps

1. **Run** `/speckit.tasks` to generate dependency-ordered tasks
2. **Implement** tasks following this guide
3. **Manual QA** using checklist above
4. **Code Review** focusing on TDD compliance
5. **Merge** and auto-deploy to GitHub Pages
