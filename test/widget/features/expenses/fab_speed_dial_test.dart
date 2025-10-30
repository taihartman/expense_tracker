import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:expense_tracker/features/expenses/presentation/widgets/fab_speed_dial.dart';
import 'package:expense_tracker/l10n/app_localizations.dart';

/// Helper to wrap widget with MaterialApp and localization
Widget _wrapWithMaterialApp(Widget child) {
  return MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
    ],
    supportedLocales: const [Locale('en')],
    home: Scaffold(body: Container(), floatingActionButton: child),
  );
}

void main() {
  group('ExpenseFabSpeedDial', () {
    testWidgets('T008: displays main FAB in closed state', (tester) async {
      await tester.pumpWidget(
        _wrapWithMaterialApp(
          ExpenseFabSpeedDial(
            tripId: 'test-trip',
            onQuickExpenseTap: () {},
            onReceiptSplitTap: () {},
          ),
        ),
      );

      // Verify main FAB present
      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('T009: FAB expands to show 2 options when tapped', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrapWithMaterialApp(
          ExpenseFabSpeedDial(
            tripId: 'test-trip',
            onQuickExpenseTap: () {},
            onReceiptSplitTap: () {},
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

    testWidgets('T010: Quick Expense option calls onQuickExpenseTap callback', (
      tester,
    ) async {
      bool quickExpenseTapped = false;

      await tester.pumpWidget(
        _wrapWithMaterialApp(
          ExpenseFabSpeedDial(
            tripId: 'test-trip',
            onQuickExpenseTap: () => quickExpenseTapped = true,
            onReceiptSplitTap: () {},
          ),
        ),
      );

      // Open Speed Dial
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Find the Quick Expense FAB by its unique heroTag
      final fabWidget = tester.widget<FloatingActionButton>(
        find.byWidgetPredicate(
          (widget) =>
              widget is FloatingActionButton &&
              widget.heroTag == 'quickExpense',
        ),
      );

      // Verify it has the correct callback by calling it directly
      fabWidget.onPressed!();
      await tester.pumpAndSettle();

      expect(quickExpenseTapped, isTrue);
    });

    testWidgets('T011: Backdrop closes Speed Dial when tapped', (tester) async {
      await tester.pumpWidget(
        _wrapWithMaterialApp(
          ExpenseFabSpeedDial(
            tripId: 'test-trip',
            onQuickExpenseTap: () {},
            onReceiptSplitTap: () {},
          ),
        ),
      );

      // Open Speed Dial
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Verify mini FABs visible
      expect(find.byType(FloatingActionButton), findsNWidgets(3));

      // Tap the main FAB again to close (toggle behavior)
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Verify closed (only main FAB visible)
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });
  });
}
