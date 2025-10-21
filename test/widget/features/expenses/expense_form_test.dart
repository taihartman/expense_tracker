import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:expense_tracker/features/expenses/presentation/pages/expense_form_page.dart';
import 'package:expense_tracker/features/expenses/presentation/cubits/expense_cubit.dart';
import 'package:expense_tracker/core/constants/participants.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'expense_form_test.mocks.dart';

@GenerateMocks([ExpenseCubit])
void main() {
  group('ExpenseForm Widget -', () {
    late MockExpenseCubit mockExpenseCubit;

    setUp(() {
      mockExpenseCubit = MockExpenseCubit();
    });

    Widget createWidgetUnderTest() {
      return MaterialApp(
        home: BlocProvider<ExpenseCubit>.value(
          value: mockExpenseCubit,
          child: const ExpenseFormPage(tripId: 'test-trip-1'),
        ),
      );
    }

    testWidgets('displays all required form fields', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createWidgetUnderTest());

      // Assert - Check for essential form fields
      expect(find.text('Amount'), findsOneWidget);
      expect(find.text('Description'), findsOneWidget);
      expect(find.text('Currency'), findsOneWidget);
      expect(find.text('Payer'), findsOneWidget);
      expect(find.text('Split Type'), findsOneWidget);
      expect(find.text('Date'), findsOneWidget);
    });

    testWidgets('shows currency selector with USD and VND options',
        (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createWidgetUnderTest());

      // Act - Tap currency dropdown
      await tester.tap(find.text('Currency'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('USD'), findsWidgets);
      expect(find.text('VND'), findsOneWidget);
    });

    testWidgets('shows payer selector with all participants',
        (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createWidgetUnderTest());

      // Act - Tap payer dropdown
      await tester.tap(find.text('Payer'));
      await tester.pumpAndSettle();

      // Assert - All participants should be available
      for (final participant in kFixedParticipants) {
        expect(find.text(participant.name), findsWidgets);
      }
    });

    testWidgets('shows split type selector with Equal and Weighted options',
        (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createWidgetUnderTest());

      // Act - Tap split type dropdown
      await tester.tap(find.text('Split Type'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Equal'), findsWidgets);
      expect(find.text('Weighted'), findsOneWidget);
    });

    testWidgets('shows checkboxes for Equal split type',
        (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createWidgetUnderTest());

      // Act - Select Equal split type
      await tester.tap(find.text('Split Type'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Equal').last);
      await tester.pumpAndSettle();

      // Assert - Should show checkboxes for participants
      expect(find.byType(Checkbox), findsAtLeastNWidgets(1));
    });

    testWidgets('shows weight input fields for Weighted split type',
        (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createWidgetUnderTest());

      // Act - Select Weighted split type
      await tester.tap(find.text('Split Type'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Weighted'));
      await tester.pumpAndSettle();

      // Assert - Should show weight input fields
      expect(find.text('Weight'), findsAtLeastNWidgets(1));
    });

    testWidgets('validates amount field is required',
        (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createWidgetUnderTest());

      // Act - Try to submit without entering amount
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Assert - Should show validation error
      expect(find.text('Amount is required'), findsOneWidget);
    });

    testWidgets('validates amount must be positive',
        (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createWidgetUnderTest());

      // Act - Enter negative amount
      await tester.enterText(
          find.widgetWithText(TextField, 'Amount'), '-10');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Assert - Should show validation error
      expect(find.text('Amount must be positive'), findsOneWidget);
    });

    testWidgets('validates at least one participant must be selected',
        (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createWidgetUnderTest());

      // Act - Fill in amount but don't select participants
      await tester.enterText(
          find.widgetWithText(TextField, 'Amount'), '100');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Assert - Should show validation error
      expect(
          find.text('At least one participant must be selected'), findsOneWidget);
    });

    testWidgets('submits form with valid equal split data',
        (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createWidgetUnderTest());

      // Act - Fill in all required fields for equal split
      await tester.enterText(
          find.widgetWithText(TextField, 'Amount'), '100.00');
      await tester.enterText(
          find.widgetWithText(TextField, 'Description'), 'Test Expense');

      // Select payer
      await tester.tap(find.text('Payer'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(kFixedParticipants.first.name).last);
      await tester.pumpAndSettle();

      // Select currency
      await tester.tap(find.text('Currency'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('USD').last);
      await tester.pumpAndSettle();

      // Select split type (Equal)
      await tester.tap(find.text('Split Type'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Equal').last);
      await tester.pumpAndSettle();

      // Select at least one participant
      await tester.tap(find.byType(Checkbox).first);
      await tester.pumpAndSettle();

      // Submit form
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Assert - Verify cubit method was called
      verify(mockExpenseCubit.createExpense(any)).called(1);
    });

    testWidgets('submits form with valid weighted split data',
        (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createWidgetUnderTest());

      // Act - Fill in all required fields for weighted split
      await tester.enterText(
          find.widgetWithText(TextField, 'Amount'), '100.00');
      await tester.enterText(
          find.widgetWithText(TextField, 'Description'), 'Test Weighted Expense');

      // Select payer
      await tester.tap(find.text('Payer'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(kFixedParticipants.first.name).last);
      await tester.pumpAndSettle();

      // Select currency
      await tester.tap(find.text('Currency'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('USD').last);
      await tester.pumpAndSettle();

      // Select split type (Weighted)
      await tester.tap(find.text('Split Type'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Weighted'));
      await tester.pumpAndSettle();

      // Enter weights for participants
      final weightFields = find.widgetWithText(TextField, 'Weight');
      await tester.enterText(weightFields.first, '2');
      await tester.pumpAndSettle();

      // Submit form
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Assert - Verify cubit method was called
      verify(mockExpenseCubit.createExpense(any)).called(1);
    });

    testWidgets('displays date picker when date field is tapped',
        (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createWidgetUnderTest());

      // Act - Tap date field
      await tester.tap(find.text('Date'));
      await tester.pumpAndSettle();

      // Assert - Date picker should be displayed
      expect(find.byType(DatePickerDialog), findsOneWidget);
    });

    testWidgets('updates form state when split type changes',
        (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createWidgetUnderTest());

      // Act - Change split type from Equal to Weighted
      await tester.tap(find.text('Split Type'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Equal').last);
      await tester.pumpAndSettle();

      expect(find.byType(Checkbox), findsAtLeastNWidgets(1));

      // Change to Weighted
      await tester.tap(find.text('Split Type'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Weighted'));
      await tester.pumpAndSettle();

      // Assert - Should now show weight fields instead of checkboxes
      expect(find.text('Weight'), findsAtLeastNWidgets(1));
    });
  });
}
