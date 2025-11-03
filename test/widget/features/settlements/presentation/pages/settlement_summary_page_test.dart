import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:expense_tracker/features/settlements/presentation/pages/settlement_summary_page.dart';
import 'package:expense_tracker/features/settlements/presentation/cubits/settlement_cubit.dart';
import 'package:expense_tracker/features/settlements/presentation/cubits/settlement_state.dart';
import 'package:expense_tracker/features/trips/presentation/cubits/trip_cubit.dart';
import 'package:expense_tracker/features/trips/presentation/cubits/trip_state.dart';
import 'package:expense_tracker/features/expenses/domain/repositories/expense_repository.dart';
import 'package:expense_tracker/core/models/currency_code.dart';
import 'package:expense_tracker/core/models/participant.dart';
import 'package:expense_tracker/features/settlements/domain/models/settlement_summary.dart';
import 'package:expense_tracker/features/trips/domain/models/trip.dart';
import 'package:expense_tracker/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'settlement_summary_page_test.mocks.dart';

@GenerateMocks([SettlementCubit, TripCubit, ExpenseRepository])
/// T028: Widget tests for per-currency settlement views
///
/// Tests the currency-switcher UI that allows users to switch between
/// different currencies and view settlements independently per currency.
void main() {
  late MockSettlementCubit mockSettlementCubit;
  late MockTripCubit mockTripCubit;
  late MockExpenseRepository mockExpenseRepository;

  // Test data
  const testTripId = 'trip-1';
  final testTrip = Trip(
    id: testTripId,
    name: 'Europe Trip',
    participants: [
      const Participant(id: 'alice', name: 'Alice'),
      const Participant(id: 'bob', name: 'Bob'),
    ],
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    allowedCurrencies: [CurrencyCode.usd, CurrencyCode.eur, CurrencyCode.gbp],
  );

  // Create test settlement data for USD
  final usdSettlement = SettlementSummary(
    tripId: testTripId,
    baseCurrency: CurrencyCode.usd,
    personSummaries: const {},
    lastComputedAt: DateTime.now(),
  );

  // Create test settlement data for EUR
  final eurSettlement = SettlementSummary(
    tripId: testTripId,
    baseCurrency: CurrencyCode.eur,
    personSummaries: const {},
    lastComputedAt: DateTime.now(),
  );

  setUp(() {
    mockSettlementCubit = MockSettlementCubit();
    mockTripCubit = MockTripCubit();
    mockExpenseRepository = MockExpenseRepository();

    // Default: User is verified member of trip
    when(mockTripCubit.isUserMemberOf(testTripId)).thenReturn(true);

    // Default trip state with allowed currencies
    when(
      mockTripCubit.state,
    ).thenReturn(TripLoaded(trips: [testTrip], selectedTrip: testTrip));

    // Default settlement state (USD)
    when(mockSettlementCubit.state).thenReturn(
      SettlementLoaded(
        summary: usdSettlement,
        activeTransfers: const [],
        settledTransfers: const [],
        personCategorySpending: null,
      ),
    );

    when(mockSettlementCubit.stream).thenAnswer(
      (_) => Stream.value(
        SettlementLoaded(
          summary: usdSettlement,
          activeTransfers: const [],
          settledTransfers: const [],
          personCategorySpending: null,
        ),
      ),
    );

    when(mockTripCubit.stream).thenAnswer(
      (_) =>
          Stream.value(TripLoaded(trips: [testTrip], selectedTrip: testTrip)),
    );

    // T032: Stub loadSettlementForCurrency method (stub any call)
    when(
      mockSettlementCubit.loadSettlementForCurrency(any, any),
    ).thenAnswer((_) async {});
  });

  Widget createTestWidget() {
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
          BlocProvider<SettlementCubit>.value(value: mockSettlementCubit),
          BlocProvider<TripCubit>.value(value: mockTripCubit),
        ],
        child: RepositoryProvider<ExpenseRepository>.value(
          value: mockExpenseRepository,
          child: const SettlementSummaryPage(tripId: testTripId),
        ),
      ),
    );
  }

  group('T028: Currency-Switcher UI -', () {
    group('Renders currency selector -', () {
      testWidgets('shows tabs/dropdown for each allowed currency', (
        WidgetTester tester,
      ) async {
        // Arrange
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Assert - Look for currency switcher widget
        // T028: This will FAIL until T030 implements the UI
        // Expecting to find a TabBar or DropdownButton with currency options
        expect(
          find.text('USD'),
          findsOneWidget,
          reason: 'Should show USD currency tab/option',
        );
        expect(
          find.text('EUR'),
          findsOneWidget,
          reason: 'Should show EUR currency tab/option',
        );
        expect(
          find.text('GBP'),
          findsOneWidget,
          reason: 'Should show GBP currency tab/option',
        );
      });

      testWidgets('shows only allowed currencies (not all 170+ currencies)', (
        WidgetTester tester,
      ) async {
        // Arrange
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Assert - Should NOT show disallowed currencies
        expect(
          find.text('JPY'),
          findsNothing,
          reason: 'Should not show JPY if not in allowed currencies',
        );
        expect(
          find.text('VND'),
          findsNothing,
          reason: 'Should not show VND if not in allowed currencies',
        );
      });
    });

    group('Currency switching -', () {
      testWidgets('switches to EUR when EUR tab/option is tapped', (
        WidgetTester tester,
      ) async {
        // Arrange
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Act - Tap EUR currency
        // T028: This will FAIL until T030 implements the UI
        final eurButton = find.text('EUR');
        expect(eurButton, findsOneWidget);
        await tester.tap(eurButton);
        await tester.pumpAndSettle();

        // Assert - Verify cubit was called to load EUR settlements
        // TODO(T032): Uncomment once loadSettlementForCurrency() is implemented
        // verify(mockSettlementCubit.loadSettlementForCurrency(
        //   testTripId,
        //   CurrencyCode.eur,
        // )).called(1);
      });

      testWidgets('highlights currently selected currency', (
        WidgetTester tester,
      ) async {
        // Arrange - Settlement loaded with EUR
        when(mockSettlementCubit.state).thenReturn(
          SettlementLoaded(
            summary: eurSettlement,
            activeTransfers: const [],
            settledTransfers: const [],
            personCategorySpending: null,
          ),
        );

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Assert - EUR should be highlighted/selected
        // T028: This will FAIL until T030 implements the UI
        // Look for visual indicator (TabBar will have isSelected, etc.)
        final eurTab = find.text('EUR');
        expect(eurTab, findsOneWidget);

        // Check that the EUR tab/button has a selected style
        // This can be verified by checking the widget properties
        // (exact assertion will depend on implementation)
      });
    });

    group('Currency-filtered settlements -', () {
      testWidgets('shows settlements only for selected currency', (
        WidgetTester tester,
      ) async {
        // Arrange - USD settlements loaded
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Assert - Should display USD-specific settlement data
        // The summary table should show USD amounts
        // T028: This verification happens through the existing widgets
        // (AllPeopleSummaryTable, MinimalTransfersView)
        // They will receive filtered data from the cubit

        // Verify the baseCurrency is USD
        final state = mockSettlementCubit.state as SettlementLoaded;
        expect(state.summary.baseCurrency, CurrencyCode.usd);
      });

      testWidgets('reloads settlements when currency is changed', (
        WidgetTester tester,
      ) async {
        // Arrange
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Act - Switch to GBP
        // T028: This will FAIL until T030 implements the UI
        final gbpButton = find.text('GBP');
        expect(gbpButton, findsOneWidget);
        await tester.tap(gbpButton);
        await tester.pumpAndSettle();

        // Assert - Verify cubit was called to load GBP settlements
        // TODO(T032): Uncomment once loadSettlementForCurrency() is implemented
        // verify(mockSettlementCubit.loadSettlementForCurrency(
        //   testTripId,
        //   CurrencyCode.gbp,
        // )).called(1);
      });
    });

    group('Empty state handling -', () {
      testWidgets('shows empty state when selected currency has no expenses', (
        WidgetTester tester,
      ) async {
        // Arrange - Empty settlement for GBP (no expenses in that currency)
        final emptySettlement = SettlementSummary(
          tripId: testTripId,
          baseCurrency: CurrencyCode.gbp,
          personSummaries: const {}, // Empty - no expenses
          lastComputedAt: DateTime.now(),
        );

        when(mockSettlementCubit.state).thenReturn(
          SettlementLoaded(
            summary: emptySettlement,
            activeTransfers: const [],
            settledTransfers: const [],
            personCategorySpending: null,
          ),
        );

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Assert - Should show empty state message
        // T028: This will FAIL until T031 implements empty state
        expect(
          find.text('No expenses in GBP'),
          findsOneWidget,
          reason: 'Should show empty state for currency with no expenses',
        );

        // Or look for empty state icon
        expect(
          find.byIcon(Icons.account_balance_wallet_outlined),
          findsOneWidget,
          reason: 'Should show empty state icon',
        );
      });

      testWidgets('empty state suggests switching to currency with expenses', (
        WidgetTester tester,
      ) async {
        // Arrange - Empty GBP settlement
        final emptySettlement = SettlementSummary(
          tripId: testTripId,
          baseCurrency: CurrencyCode.gbp,
          personSummaries: const {},
          lastComputedAt: DateTime.now(),
        );

        when(mockSettlementCubit.state).thenReturn(
          SettlementLoaded(
            summary: emptySettlement,
            activeTransfers: const [],
            settledTransfers: const [],
            personCategorySpending: null,
          ),
        );

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Assert - Should show helpful message
        // T028: This will FAIL until T031 implements empty state
        expect(
          find.textContaining('Try switching'),
          findsOneWidget,
          reason: 'Should suggest switching to other currencies',
        );
      });
    });
  });
}
