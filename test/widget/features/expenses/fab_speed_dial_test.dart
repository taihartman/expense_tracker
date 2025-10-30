import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/expenses/presentation/widgets/fab_speed_dial.dart';

void main() {
  group('ExpenseFabSpeedDial', () {
    testWidgets('T008: displays main FAB in closed state', (tester) async {
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

    testWidgets('T009: FAB expands to show 2 options when tapped',
        (tester) async {
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
      await tester.pumpAndSettle(); // Wait for animation

      // Verify mini FABs visible (main + 2 mini = 3 total)
      expect(find.byType(FloatingActionButton), findsNWidgets(3));
      expect(find.byIcon(Icons.flash_on), findsOneWidget); // Quick Expense
      expect(find.byIcon(Icons.receipt_long), findsOneWidget); // Receipt Split
    });

    testWidgets('T010: Quick Expense option calls onQuickExpenseTap callback',
        (tester) async {
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

      // Tap Quick Expense option (find the small FAB with flash icon)
      final quickExpenseFab = find.descendant(
        of: find.byType(FloatingActionButton),
        matching: find.byIcon(Icons.flash_on),
      );
      await tester.tap(quickExpenseFab);
      await tester.pumpAndSettle();

      expect(quickExpenseTapped, isTrue);
    });

    testWidgets('T011: Backdrop closes Speed Dial when tapped',
        (tester) async {
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

      // Verify mini FABs visible
      expect(find.byType(FloatingActionButton), findsNWidgets(3));

      // Tap backdrop (outside FABs) - tap at a safe location
      await tester.tapAt(const Offset(100, 100)); // Top-left corner
      await tester.pumpAndSettle();

      // Verify closed (only main FAB visible)
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });
  });
}
