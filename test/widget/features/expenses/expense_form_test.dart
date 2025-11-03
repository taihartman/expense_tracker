import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:expense_tracker/l10n/app_localizations.dart';
import 'package:expense_tracker/features/expenses/presentation/pages/expense_form_page.dart';
import 'package:expense_tracker/features/expenses/presentation/cubits/expense_cubit.dart';
import 'package:expense_tracker/features/expenses/domain/models/expense.dart';
import 'package:expense_tracker/features/trips/presentation/cubits/trip_cubit.dart';
import 'package:expense_tracker/features/trips/presentation/cubits/trip_state.dart';
import 'package:expense_tracker/features/trips/domain/models/trip.dart';
import 'package:expense_tracker/core/models/participant.dart';
import 'package:expense_tracker/core/models/currency_code.dart';
import 'package:expense_tracker/core/models/split_type.dart';
import 'package:decimal/decimal.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:expense_tracker/features/categories/presentation/cubit/category_cubit.dart';
import 'package:expense_tracker/features/categories/presentation/cubit/category_state.dart';
import 'package:expense_tracker/features/categories/presentation/cubit/category_customization_cubit.dart';
import 'package:expense_tracker/features/categories/presentation/cubit/category_customization_state.dart';
import 'expense_form_test.mocks.dart';

@GenerateMocks([ExpenseCubit, TripCubit, CategoryCubit, CategoryCustomizationCubit])
void main() {
  group('ExpenseForm Widget -', () {
    late MockExpenseCubit mockExpenseCubit;
    late MockTripCubit mockTripCubit;
    late MockCategoryCubit mockCategoryCubit;
    late MockCategoryCustomizationCubit mockCategoryCustomizationCubit;
    late List<Participant> testParticipants;
    late Trip testTrip;

    setUp(() {
      mockExpenseCubit = MockExpenseCubit();
      mockTripCubit = MockTripCubit();
      mockCategoryCubit = MockCategoryCubit();
      mockCategoryCustomizationCubit = MockCategoryCustomizationCubit();

      // Create test participants
      testParticipants = const [
        Participant(id: 'tai', name: 'Tai'),
        Participant(id: 'khiet', name: 'Khiet'),
        Participant(id: 'bob', name: 'Bob'),
        Participant(id: 'ethan', name: 'Ethan'),
      ];

      // Create test trip with participants
      testTrip = Trip(
        id: 'test-trip-1',
        name: 'Test Trip',
        allowedCurrencies: const [CurrencyCode.usd],
        participants: testParticipants,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Setup mock trip cubit to return loaded state with test trip
      when(
        mockTripCubit.state,
      ).thenReturn(TripLoaded(trips: [testTrip], selectedTrip: testTrip));
      when(mockTripCubit.stream).thenAnswer(
        (_) =>
            Stream.value(TripLoaded(trips: [testTrip], selectedTrip: testTrip)),
      );

      // Setup mock category cubit
      when(mockCategoryCubit.state)
          .thenReturn(const CategoryTopLoaded(categories: []));
      when(mockCategoryCubit.stream).thenAnswer(
        (_) => Stream.value(const CategoryTopLoaded(categories: [])),
      );

      // Setup mock category customization cubit
      when(mockCategoryCustomizationCubit.state)
          .thenReturn(const CategoryCustomizationLoaded(customizations: {}));
      when(mockCategoryCustomizationCubit.stream).thenAnswer(
        (_) => Stream.value(
          const CategoryCustomizationLoaded(customizations: {}),
        ),
      );
    });

    Widget createWidgetUnderTest() {
      return MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en')],
        home: MultiBlocProvider(
          providers: [
            BlocProvider<ExpenseCubit>.value(value: mockExpenseCubit),
            BlocProvider<TripCubit>.value(value: mockTripCubit),
            BlocProvider<CategoryCubit>.value(value: mockCategoryCubit),
            BlocProvider<CategoryCustomizationCubit>.value(
              value: mockCategoryCustomizationCubit,
            ),
          ],
          child: const ExpenseFormPage(tripId: 'test-trip-1'),
        ),
      );
    }

    testWidgets('displays all required form fields', (
      WidgetTester tester,
    ) async {
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

    testWidgets('shows currency selector with USD and VND options', (
      WidgetTester tester,
    ) async {
      // Arrange
      await tester.pumpWidget(createWidgetUnderTest());

      // Act - Tap currency dropdown
      await tester.tap(find.text('Currency'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('USD'), findsWidgets);
      expect(find.text('VND'), findsOneWidget);
    });

    testWidgets('shows payer selector with all participants', (
      WidgetTester tester,
    ) async {
      // Arrange
      await tester.pumpWidget(createWidgetUnderTest());

      // Act - Tap payer dropdown
      await tester.tap(find.text('Payer'));
      await tester.pumpAndSettle();

      // Assert - All participants should be available
      for (final participant in testParticipants) {
        expect(find.text(participant.name), findsWidgets);
      }
    });

    testWidgets('shows split type selector with Equal and Weighted options', (
      WidgetTester tester,
    ) async {
      // Arrange
      await tester.pumpWidget(createWidgetUnderTest());

      // Act - Tap split type dropdown
      await tester.tap(find.text('Split Type'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Equal'), findsWidgets);
      expect(find.text('Weighted'), findsOneWidget);
    });

    testWidgets('shows checkboxes for Equal split type', (
      WidgetTester tester,
    ) async {
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

    testWidgets('shows weight input fields for Weighted split type', (
      WidgetTester tester,
    ) async {
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

    testWidgets('validates amount field is required', (
      WidgetTester tester,
    ) async {
      // Arrange
      await tester.pumpWidget(createWidgetUnderTest());

      // Act - Try to submit without entering amount
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Assert - Should show validation error
      expect(find.text('Amount is required'), findsOneWidget);
    });

    testWidgets('validates amount must be positive', (
      WidgetTester tester,
    ) async {
      // Arrange
      await tester.pumpWidget(createWidgetUnderTest());

      // Act - Enter negative amount
      await tester.enterText(find.widgetWithText(TextField, 'Amount'), '-10');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Assert - Should show validation error
      expect(find.text('Amount must be positive'), findsOneWidget);
    });

    testWidgets('validates at least one participant must be selected', (
      WidgetTester tester,
    ) async {
      // Arrange
      await tester.pumpWidget(createWidgetUnderTest());

      // Act - Fill in amount but don't select participants
      await tester.enterText(find.widgetWithText(TextField, 'Amount'), '100');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Assert - Should show validation error
      expect(
        find.text('At least one participant must be selected'),
        findsOneWidget,
      );
    });

    testWidgets('submits form with valid equal split data', (
      WidgetTester tester,
    ) async {
      // Arrange
      await tester.pumpWidget(createWidgetUnderTest());

      // Act - Fill in all required fields for equal split
      await tester.enterText(
        find.widgetWithText(TextField, 'Amount'),
        '100.00',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Description'),
        'Test Expense',
      );

      // Select payer
      await tester.tap(find.text('Payer'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(testParticipants.first.name).last);
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

    testWidgets('submits form with valid weighted split data', (
      WidgetTester tester,
    ) async {
      // Arrange
      await tester.pumpWidget(createWidgetUnderTest());

      // Act - Fill in all required fields for weighted split
      await tester.enterText(
        find.widgetWithText(TextField, 'Amount'),
        '100.00',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Description'),
        'Test Weighted Expense',
      );

      // Select payer
      await tester.tap(find.text('Payer'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(testParticipants.first.name).last);
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

    testWidgets('displays date picker when date field is tapped', (
      WidgetTester tester,
    ) async {
      // Arrange
      await tester.pumpWidget(createWidgetUnderTest());

      // Act - Tap date field
      await tester.tap(find.text('Date'));
      await tester.pumpAndSettle();

      // Assert - Date picker should be displayed
      expect(find.byType(DatePickerDialog), findsOneWidget);
    });

    testWidgets('updates form state when split type changes', (
      WidgetTester tester,
    ) async {
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

  /// T021: Tests for filtered currency dropdown (multi-currency support)
  group('T021: Multi-Currency Filtering -', () {
    late MockExpenseCubit mockExpenseCubit;
    late MockTripCubit mockTripCubit;
    late MockCategoryCubit mockCategoryCubit;
    late MockCategoryCustomizationCubit mockCategoryCustomizationCubit;
    late List<Participant> testParticipants;

    setUp(() {
      mockExpenseCubit = MockExpenseCubit();
      mockTripCubit = MockTripCubit();
      mockCategoryCubit = MockCategoryCubit();
      mockCategoryCustomizationCubit = MockCategoryCustomizationCubit();

      testParticipants = const [
        Participant(id: 'alice', name: 'Alice'),
        Participant(id: 'bob', name: 'Bob'),
      ];
    });

    Widget createWidgetWithTrip(Trip trip) {
      when(mockTripCubit.state)
          .thenReturn(TripLoaded(trips: [trip], selectedTrip: trip));
      when(mockTripCubit.stream).thenAnswer(
        (_) => Stream.value(TripLoaded(trips: [trip], selectedTrip: trip)),
      );

      // Setup mock category cubit
      when(mockCategoryCubit.state)
          .thenReturn(const CategoryTopLoaded(categories: []));
      when(mockCategoryCubit.stream).thenAnswer(
        (_) => Stream.value(const CategoryTopLoaded(categories: [])),
      );

      // Setup mock category customization cubit
      when(mockCategoryCustomizationCubit.state)
          .thenReturn(const CategoryCustomizationLoaded(customizations: {}));
      when(mockCategoryCustomizationCubit.stream).thenAnswer(
        (_) => Stream.value(
          const CategoryCustomizationLoaded(customizations: {}),
        ),
      );

      return MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: MultiBlocProvider(
          providers: [
            BlocProvider<ExpenseCubit>.value(value: mockExpenseCubit),
            BlocProvider<TripCubit>.value(value: mockTripCubit),
            BlocProvider<CategoryCubit>.value(value: mockCategoryCubit),
            BlocProvider<CategoryCustomizationCubit>.value(
              value: mockCategoryCustomizationCubit,
            ),
          ],
          child: ExpenseFormPage(tripId: trip.id),
        ),
      );
    }

    testWidgets(
        'currency dropdown shows only trips allowed currencies (USD, EUR, GBP)',
        (WidgetTester tester) async {
      // Arrange - Trip with 3 allowed currencies
      final trip = Trip(
        id: 'test-trip',
        name: 'Europe Trip',
        allowedCurrencies: const [
          CurrencyCode.usd,
          CurrencyCode.eur,
          CurrencyCode.gbp,
        ],
        participants: testParticipants,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Act
      await tester.pumpWidget(createWidgetWithTrip(trip));
      await tester.tap(find.text('Currency'));
      await tester.pumpAndSettle();

      // Assert - Should show ONLY allowed currencies
      expect(find.text('usd'), findsWidgets); // Currency code shown
      expect(find.text('eur'), findsOneWidget);
      expect(find.text('gbp'), findsOneWidget);

      // Should NOT show other currencies (like JPY, VND, CAD)
      expect(find.text('jpy'), findsNothing);
      expect(find.text('vnd'), findsNothing);
      expect(find.text('cad'), findsNothing);
    });

    testWidgets('pre-selects first allowed currency as default for new expense',
        (WidgetTester tester) async {
      // Arrange - Trip with EUR as first currency
      final trip = Trip(
        id: 'test-trip',
        name: 'Europe Trip',
        allowedCurrencies: const [
          CurrencyCode.eur, // First = default
          CurrencyCode.usd,
          CurrencyCode.gbp,
        ],
        participants: testParticipants,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Act - Create new expense (no existing expense)
      await tester.pumpWidget(createWidgetWithTrip(trip));
      await tester.pumpAndSettle();

      // Assert - Currency dropdown should default to EUR (first currency)
      final currencyDropdown =
          tester.widget<DropdownButtonFormField<CurrencyCode>>(
        find.byType(DropdownButtonFormField<CurrencyCode>),
      );
      expect(currencyDropdown.initialValue, CurrencyCode.eur);
    });

    testWidgets('pre-selects USD when USD is first allowed currency',
        (WidgetTester tester) async {
      // Arrange - Trip with USD as first currency
      final trip = Trip(
        id: 'test-trip',
        name: 'US Trip',
        allowedCurrencies: const [
          CurrencyCode.usd, // First = default
          CurrencyCode.cad,
        ],
        participants: testParticipants,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Act
      await tester.pumpWidget(createWidgetWithTrip(trip));
      await tester.pumpAndSettle();

      // Assert - Currency dropdown should default to USD
      final currencyDropdown =
          tester.widget<DropdownButtonFormField<CurrencyCode>>(
        find.byType(DropdownButtonFormField<CurrencyCode>),
      );
      expect(currencyDropdown.initialValue, CurrencyCode.usd);
    });

    testWidgets('preserves existing expense currency even if not in allowed list',
        (WidgetTester tester) async {
      // Arrange - Trip allows USD, EUR, GBP
      final trip = Trip(
        id: 'test-trip',
        name: 'Europe Trip',
        allowedCurrencies: const [
          CurrencyCode.usd,
          CurrencyCode.eur,
          CurrencyCode.gbp,
        ],
        participants: testParticipants,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Existing expense with JPY (NOT in allowed list - backward compatibility)
      final existingExpense = Expense(
        id: 'exp-123',
        tripId: 'test-trip',
        date: DateTime.now(),
        payerUserId: 'alice',
        currency: CurrencyCode.jpy, // NOT in allowedCurrencies
        amount: Decimal.parse('1000'),
        splitType: SplitType.equal,
        participants: {'alice': 1, 'bob': 1},
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      when(mockTripCubit.state)
          .thenReturn(TripLoaded(trips: [trip], selectedTrip: trip));
      when(mockTripCubit.stream).thenAnswer(
        (_) => Stream.value(TripLoaded(trips: [trip], selectedTrip: trip)),
      );

      // Act - Edit existing expense
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: MultiBlocProvider(
            providers: [
              BlocProvider<ExpenseCubit>.value(value: mockExpenseCubit),
              BlocProvider<TripCubit>.value(value: mockTripCubit),
            ],
            child: ExpenseFormPage(
              tripId: trip.id,
              expense: existingExpense, // Editing existing expense
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert - Should preserve JPY currency
      final currencyDropdown =
          tester.widget<DropdownButtonFormField<CurrencyCode>>(
        find.byType(DropdownButtonFormField<CurrencyCode>),
      );
      expect(currencyDropdown.initialValue, CurrencyCode.jpy);

      // Open dropdown to verify JPY is included
      await tester.tap(find.text('Currency'));
      await tester.pumpAndSettle();
      expect(find.text('jpy'), findsOneWidget);
    });

    testWidgets('currency dropdown works with single allowed currency',
        (WidgetTester tester) async {
      // Arrange - Trip with only USD
      final trip = Trip(
        id: 'test-trip',
        name: 'US Trip',
        allowedCurrencies: const [CurrencyCode.usd], // Only one currency
        participants: testParticipants,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Act
      await tester.pumpWidget(createWidgetWithTrip(trip));
      await tester.tap(find.text('Currency'));
      await tester.pumpAndSettle();

      // Assert - Should show only USD
      expect(find.text('usd'), findsWidgets);
      expect(find.text('eur'), findsNothing);
      expect(find.text('gbp'), findsNothing);
    });

    // TODO: Re-enable this test - currently causes rendering issues with 10 currencies
    // testWidgets('currency dropdown works with maximum (10) allowed currencies',
    //     (WidgetTester tester) async {
    //   // Arrange - Trip with 10 allowed currencies
    //   final trip = Trip(
    //     id: 'test-trip',
    //     name: 'Multi-Currency Trip',
    //     allowedCurrencies: const [
    //       CurrencyCode.usd,
    //       CurrencyCode.eur,
    //       CurrencyCode.gbp,
    //       CurrencyCode.jpy,
    //       CurrencyCode.cad,
    //       CurrencyCode.aud,
    //       CurrencyCode.chf,
    //       CurrencyCode.cny,
    //       CurrencyCode.sek,
    //       CurrencyCode.nzd,
    //     ],
    //     participants: testParticipants,
    //     createdAt: DateTime.now(),
    //     updatedAt: DateTime.now(),
    //   );
    //
    //   // Act
    //   await tester.pumpWidget(createWidgetWithTrip(trip));
    //   await tester.pump();
    //
    //   // Assert - Verify dropdown exists and is initialized with first currency
    //   final currencyDropdown =
    //       tester.widget<DropdownButtonFormField<CurrencyCode>>(
    //     find.byType(DropdownButtonFormField<CurrencyCode>),
    //   );
    //
    //   // Should have USD (first currency) as initial value
    //   expect(currencyDropdown.initialValue, CurrencyCode.usd);
    // });
  });
}
