import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:expense_tracker/main.dart';
import 'package:expense_tracker/core/services/local_storage_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Record Expense Flow -', () {
    testWidgets(
        'User can create a trip and add an expense with equal split',
        (WidgetTester tester) async {
      // Arrange - Initialize LocalStorageService and launch app
      final localStorageService = await LocalStorageService.init();
      await tester.pumpWidget(ExpenseTrackerApp(
        localStorageService: localStorageService,
      ));
      await tester.pumpAndSettle();

      // Step 1: Create a new trip
      // Tap "Create Trip" button
      expect(find.text('Create Trip'), findsOneWidget);
      await tester.tap(find.text('Create Trip'));
      await tester.pumpAndSettle();

      // Fill in trip name
      expect(find.byType(TextField), findsWidgets);
      await tester.enterText(
        find.byType(TextField).first,
        'Vietnam 2025',
      );

      // Select base currency (USD)
      await tester.tap(find.text('USD'));
      await tester.pumpAndSettle();

      // Submit trip creation
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      // Verify trip created
      expect(find.text('Vietnam 2025'), findsOneWidget);

      // Step 2: Navigate to add expense
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Step 3: Fill in expense details
      // Enter amount
      await tester.enterText(
        find.widgetWithText(TextField, 'Amount'),
        '100.00',
      );

      // Enter description
      await tester.enterText(
        find.widgetWithText(TextField, 'Description'),
        'Dinner',
      );

      // Select payer (Tai)
      await tester.tap(find.text('Payer'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tai'));
      await tester.pumpAndSettle();

      // Select split type (Equal)
      await tester.tap(find.text('Equal Split'));
      await tester.pumpAndSettle();

      // Select participants (checkboxes for Equal split)
      await tester.tap(find.byWidgetPredicate(
        (widget) =>
            widget is Checkbox &&
            widget.value == false,
      ));
      await tester.pumpAndSettle();

      // Submit expense
      await tester.tap(find.text('Save Expense'));
      await tester.pumpAndSettle();

      // Verify expense appears in list
      expect(find.text('Dinner'), findsOneWidget);
      expect(find.text('\$100.00'), findsOneWidget);
    });

    testWidgets('User can add expense with weighted split',
        (WidgetTester tester) async {
      // Arrange - Initialize LocalStorageService and launch app with existing trip
      final localStorageService = await LocalStorageService.init();
      await tester.pumpWidget(ExpenseTrackerApp(
        localStorageService: localStorageService,
      ));
      await tester.pumpAndSettle();

      // Assume trip already exists, navigate to add expense
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Fill in expense details
      await tester.enterText(
        find.widgetWithText(TextField, 'Amount'),
        '200.00',
      );

      await tester.enterText(
        find.widgetWithText(TextField, 'Description'),
        'Hotel',
      );

      // Select payer
      await tester.tap(find.text('Payer'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Khiet'));
      await tester.pumpAndSettle();

      // Select weighted split
      await tester.tap(find.text('Weighted Split'));
      await tester.pumpAndSettle();

      // Enter weights for participants
      final weightFields = find.byWidgetPredicate(
        (widget) => widget is TextField,
      );

      await tester.enterText(weightFields.at(0), '2'); // Tai weight = 2
      await tester.enterText(weightFields.at(1), '1'); // Khiet weight = 1
      await tester.pumpAndSettle();

      // Submit expense
      await tester.tap(find.text('Save Expense'));
      await tester.pumpAndSettle();

      // Verify expense appears
      expect(find.text('Hotel'), findsOneWidget);
      expect(find.text('\$200.00'), findsOneWidget);
    });

    testWidgets('User can view expense list', (WidgetTester tester) async {
      // Arrange - Initialize LocalStorageService and launch app
      final localStorageService = await LocalStorageService.init();
      await tester.pumpWidget(ExpenseTrackerApp(
        localStorageService: localStorageService,
      ));
      await tester.pumpAndSettle();

      // Navigate to expense list
      await tester.tap(find.text('Expenses'));
      await tester.pumpAndSettle();

      // Verify expense list is visible
      expect(find.byType(ListView), findsOneWidget);

      // Verify expenses are displayed (if any exist)
      // This would show previously created expenses from other tests
    });

    testWidgets('User can switch between trips',
        (WidgetTester tester) async {
      // Arrange - Initialize LocalStorageService and launch app
      final localStorageService = await LocalStorageService.init();
      await tester.pumpWidget(ExpenseTrackerApp(
        localStorageService: localStorageService,
      ));
      await tester.pumpAndSettle();

      // Open trip selector
      await tester.tap(find.text('Vietnam 2025'));
      await tester.pumpAndSettle();

      // Verify trip list appears
      expect(find.byType(ListTile), findsWidgets);

      // Select different trip (if multiple exist)
      // This test assumes multiple trips exist from other test runs
    });
  });
}
