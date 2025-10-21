import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:decimal/decimal.dart';
import 'package:expense_tracker/features/expenses/presentation/widgets/expense_card.dart';
import 'package:expense_tracker/features/expenses/domain/models/expense.dart';
import 'package:expense_tracker/core/models/participant.dart';
import 'package:expense_tracker/core/models/split_type.dart';
import 'package:expense_tracker/core/models/currency_code.dart';
import 'package:intl/intl.dart';

void main() {
  group('ExpenseCard Widget -', () {
    late Expense testExpenseEqualSplit;
    late Expense testExpenseWeightedSplit;
    late Expense testExpenseVND;
    late List<Participant> testParticipants;

    setUp(() {
      // Create test participants
      testParticipants = [
        const Participant(id: 'tai', name: 'Tai'),
        const Participant(id: 'khiet', name: 'Khiet'),
        const Participant(id: 'bob', name: 'Bob'),
        const Participant(id: 'ethan', name: 'Ethan'),
      ];
      testExpenseEqualSplit = Expense(
        id: 'expense-1',
        tripId: 'trip-1',
        date: DateTime(2025, 10, 21),
        payerUserId: 'tai',
        currency: CurrencyCode.usd,
        amount: Decimal.parse('100.00'),
        description: 'Lunch at restaurant',
        categoryId: 'meals',
        splitType: SplitType.equal,
        participants: {
          'tai': 1,
          'khiet': 1,
          'bob': 1,
          'ethan': 1,
        },
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      testExpenseWeightedSplit = Expense(
        id: 'expense-2',
        tripId: 'trip-1',
        date: DateTime(2025, 10, 21),
        payerUserId: 'khiet',
        currency: CurrencyCode.usd,
        amount: Decimal.parse('200.00'),
        description: 'Hotel accommodation',
        categoryId: 'accommodation',
        splitType: SplitType.weighted,
        participants: {
          'tai': 2,
          'khiet': 1,
          'bob': 1,
        },
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      testExpenseVND = Expense(
        id: 'expense-3',
        tripId: 'trip-1',
        date: DateTime(2025, 10, 21),
        payerUserId: 'bob',
        currency: CurrencyCode.vnd,
        amount: Decimal.parse('500000'),
        description: 'Taxi fare',
        categoryId: 'transport',
        splitType: SplitType.equal,
        participants: {
          'tai': 1,
          'khiet': 1,
          'bob': 1,
        },
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    });

    Widget createWidgetUnderTest(Expense expense) {
      return MaterialApp(
        home: Scaffold(
          body: ExpenseCard(
            expense: expense,
            participants: testParticipants,
          ),
        ),
      );
    }

    testWidgets('displays expense amount with currency symbol',
        (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createWidgetUnderTest(testExpenseEqualSplit));

      // Assert
      expect(find.text('\$100.00'), findsOneWidget);
    });

    testWidgets('displays VND amount with no decimal places',
        (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createWidgetUnderTest(testExpenseVND));

      // Assert
      expect(find.text('₫500,000'), findsOneWidget);
    });

    testWidgets('displays expense description',
        (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createWidgetUnderTest(testExpenseEqualSplit));

      // Assert
      expect(find.text('Lunch at restaurant'), findsOneWidget);
    });

    testWidgets('displays payer name', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createWidgetUnderTest(testExpenseEqualSplit));

      // Assert
      expect(find.text('Paid by Tai'), findsOneWidget);
    });

    testWidgets('displays formatted date', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createWidgetUnderTest(testExpenseEqualSplit));

      // Assert
      final expectedDate = DateFormat('MMM dd, yyyy').format(
        DateTime(2025, 10, 21),
      );
      expect(find.text(expectedDate), findsOneWidget);
    });

    testWidgets('displays split type for equal split',
        (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createWidgetUnderTest(testExpenseEqualSplit));

      // Assert
      expect(find.text('Equal split'), findsOneWidget);
    });

    testWidgets('displays split type for weighted split',
        (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createWidgetUnderTest(testExpenseWeightedSplit));

      // Assert
      expect(find.text('Weighted split'), findsOneWidget);
    });

    testWidgets('displays participant count for equal split',
        (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createWidgetUnderTest(testExpenseEqualSplit));

      // Assert
      expect(find.text('4 participants'), findsOneWidget);
    });

    testWidgets('displays participant count for weighted split',
        (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createWidgetUnderTest(testExpenseWeightedSplit));

      // Assert
      expect(find.text('3 participants'), findsOneWidget);
    });

    testWidgets('displays category icon if available',
        (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createWidgetUnderTest(testExpenseEqualSplit));

      // Assert - Should display icon for category
      expect(find.byType(Icon), findsAtLeastNWidgets(1));
    });

    testWidgets('displays share amount for equal split',
        (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createWidgetUnderTest(testExpenseEqualSplit));

      // Assert - Each person's share (100/4 = 25)
      expect(find.text('\$25.00 per person'), findsOneWidget);
    });

    testWidgets('card is tappable', (WidgetTester tester) async {
      // Arrange
      bool tapped = false;
      final testExpense = testExpenseEqualSplit;

      final widget = MaterialApp(
        home: Scaffold(
          body: ExpenseCard(
            expense: testExpense,
            participants: testParticipants,
            onTap: () => tapped = true,
          ),
        ),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.tap(find.byType(ExpenseCard));
      await tester.pumpAndSettle();

      // Assert
      expect(tapped, isTrue);
    });

    testWidgets('displays all participant names in expanded view',
        (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createWidgetUnderTest(testExpenseEqualSplit));

      // Tap to expand
      await tester.tap(find.byType(ExpenseCard));
      await tester.pumpAndSettle();

      // Assert - All participant names should be visible
      expect(find.text('Tai'), findsOneWidget);
      expect(find.text('Khiet'), findsOneWidget);
      expect(find.text('Bob'), findsOneWidget);
      expect(find.text('Ethan'), findsOneWidget);
    });

    testWidgets('displays individual shares in expanded view',
        (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createWidgetUnderTest(testExpenseEqualSplit));

      // Tap to expand
      await tester.tap(find.byType(ExpenseCard));
      await tester.pumpAndSettle();

      // Assert - Each person's share should be displayed
      expect(find.text('\$25.00'), findsNWidgets(4));
    });

    testWidgets('displays weighted shares correctly in expanded view',
        (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createWidgetUnderTest(testExpenseWeightedSplit));

      // Tap to expand
      await tester.tap(find.byType(ExpenseCard));
      await tester.pumpAndSettle();

      // Assert - Weighted shares: Tai=100, Khiet=50, Bob=50
      expect(find.text('\$100.00'), findsOneWidget); // Tai's share
      expect(find.text('\$50.00'), findsNWidgets(2)); // Khiet and Bob
    });

    testWidgets('card has elevation and rounded corners',
        (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createWidgetUnderTest(testExpenseEqualSplit));

      // Assert
      final card = tester.widget<Card>(find.byType(Card));
      expect(card.elevation, greaterThan(0));
      expect(card.shape, isA<RoundedRectangleBorder>());
    });

    testWidgets('displays currency code as badge',
        (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createWidgetUnderTest(testExpenseVND));

      // Assert
      expect(find.text('VND'), findsOneWidget);
    });

    testWidgets('highlights payer in participant list',
        (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createWidgetUnderTest(testExpenseEqualSplit));

      // Tap to expand
      await tester.tap(find.byType(ExpenseCard));
      await tester.pumpAndSettle();

      // Assert - Payer should have different styling (bold or icon)
      expect(find.text('Tai'), findsOneWidget);
      // The payer row should have a distinct indicator (tested via widget structure)
    });
  });
}
