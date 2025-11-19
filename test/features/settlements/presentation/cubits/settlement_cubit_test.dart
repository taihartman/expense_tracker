import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:expense_tracker/features/settlements/presentation/cubits/settlement_cubit.dart';
import 'package:expense_tracker/features/settlements/presentation/cubits/settlement_state.dart';
import 'package:expense_tracker/features/settlements/domain/repositories/settlement_repository.dart';
import 'package:expense_tracker/features/settlements/domain/repositories/settled_transfer_repository.dart';
import 'package:expense_tracker/features/expenses/domain/repositories/expense_repository.dart';
import 'package:expense_tracker/features/trips/domain/repositories/trip_repository.dart';
import 'package:expense_tracker/features/categories/domain/repositories/category_repository.dart';
import 'package:expense_tracker/core/services/local_storage_service.dart';
import 'package:expense_tracker/core/models/currency_code.dart';
import 'package:expense_tracker/features/expenses/domain/models/expense.dart';
import 'package:expense_tracker/features/settlements/domain/models/settlement_summary.dart';
import 'package:expense_tracker/features/settlements/domain/models/settlement_computation_result.dart';
import 'package:expense_tracker/features/trips/domain/models/trip.dart';
import 'package:expense_tracker/core/models/participant.dart';
import 'package:expense_tracker/core/models/split_type.dart';
import 'package:decimal/decimal.dart';

import 'settlement_cubit_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<SettlementRepository>(),
  MockSpec<ExpenseRepository>(),
  MockSpec<TripRepository>(),
  MockSpec<SettledTransferRepository>(),
  MockSpec<CategoryRepository>(),
  MockSpec<LocalStorageService>(),
])

/// T033: Unit tests for SettlementCubit per-currency loading
///
/// Tests that the cubit can load settlements filtered by currency
/// and properly manages currency filter state.
void main() {
  group('T033: SettlementCubit Per-Currency Loading -', () {
    late MockSettlementRepository mockSettlementRepository;
    late MockExpenseRepository mockExpenseRepository;
    late MockTripRepository mockTripRepository;
    late MockSettledTransferRepository mockSettledTransferRepository;
    late MockCategoryRepository mockCategoryRepository;
    late MockLocalStorageService mockLocalStorageService;

    // Test data
    const testTripId = 'trip-1';
    final testTrip = Trip(
      id: testTripId,
      name: 'Europe Trip',
      participants: const [
        Participant(id: 'alice', name: 'Alice'),
        Participant(id: 'bob', name: 'Bob'),
      ],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      allowedCurrencies: const [CurrencyCode.usd, CurrencyCode.eur, CurrencyCode.gbp],
    );

    final usdExpenses = [
      Expense(
        id: 'exp-usd-1',
        tripId: testTripId,
        date: DateTime.now(),
        payerUserId: 'alice',
        currency: CurrencyCode.usd,
        amount: Decimal.parse('100'),
        splitType: SplitType.equal,
        participants: {'alice': 1, 'bob': 1},
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];

    final eurExpenses = [
      Expense(
        id: 'exp-eur-1',
        tripId: testTripId,
        date: DateTime.now(),
        payerUserId: 'bob',
        currency: CurrencyCode.eur,
        amount: Decimal.parse('50'),
        splitType: SplitType.equal,
        participants: {'alice': 1, 'bob': 1},
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];

    final allExpenses = [...usdExpenses, ...eurExpenses];

    final usdSettlement = SettlementSummary(
      tripId: testTripId,
      baseCurrency: CurrencyCode.usd,
      personSummaries: const {},
      lastComputedAt: DateTime.now(),
    );

    final eurSettlement = SettlementSummary(
      tripId: testTripId,
      baseCurrency: CurrencyCode.eur,
      personSummaries: const {},
      lastComputedAt: DateTime.now(),
    );

    setUp(() {
      mockSettlementRepository = MockSettlementRepository();
      mockExpenseRepository = MockExpenseRepository();
      mockTripRepository = MockTripRepository();
      mockSettledTransferRepository = MockSettledTransferRepository();
      mockCategoryRepository = MockCategoryRepository();
      mockLocalStorageService = MockLocalStorageService();

      // Default mocks
      when(mockTripRepository.getTripById(testTripId))
          .thenAnswer((_) async => testTrip);

      when(mockExpenseRepository.getExpensesByTrip(testTripId))
          .thenAnswer((_) => Stream.value(allExpenses));

      when(mockSettledTransferRepository.getSettledTransfers(testTripId))
          .thenAnswer((_) => Stream.value([]));

      when(mockSettlementRepository.getMinimalTransfers(testTripId))
          .thenAnswer((_) => Stream.value([]));

      when(mockCategoryRepository.searchCategories(''))
          .thenAnswer((_) => Stream.value([]));

      when(
        mockLocalStorageService.getSettlementFilter(testTripId),
      ).thenReturn((userId: null, filterMode: 'all'));
    });

    SettlementCubit createCubit() {
      return SettlementCubit(
        settlementRepository: mockSettlementRepository,
        expenseRepository: mockExpenseRepository,
        tripRepository: mockTripRepository,
        settledTransferRepository: mockSettledTransferRepository,
        categoryRepository: mockCategoryRepository,
        localStorageService: mockLocalStorageService,
      );
    }

    group('Load settlement for specific currency -', () {
      blocTest<SettlementCubit, SettlementState>(
        'loadSettlementForCurrency() loads USD settlements',
        build: createCubit,
        setUp: () {
          when(
            mockSettlementRepository.computeSettlementWithExpenses(
              testTripId,
              allExpenses,
              currencyFilter: CurrencyCode.usd,
            ),
          ).thenAnswer((_) async => SettlementComputationResult(summary: usdSettlement));
        },
        act: (cubit) async {
          await cubit.loadSettlement(testTripId);
          await cubit.loadSettlementForCurrency(testTripId, CurrencyCode.usd);
        },
        verify: (_) {
          // Verify USD settlements were loaded with filter
          verify(
            mockSettlementRepository.computeSettlementWithExpenses(
              testTripId,
              any,
              currencyFilter: CurrencyCode.usd,
            ),
          ).called(greaterThan(0));
        },
      );

      blocTest<SettlementCubit, SettlementState>(
        'loadSettlementForCurrency() loads EUR settlements',
        build: createCubit,
        setUp: () {
          when(
            mockSettlementRepository.computeSettlementWithExpenses(
              testTripId,
              allExpenses,
              currencyFilter: CurrencyCode.eur,
            ),
          ).thenAnswer((_) async => SettlementComputationResult(summary: eurSettlement));
        },
        act: (cubit) async {
          await cubit.loadSettlement(testTripId);
          await cubit.loadSettlementForCurrency(testTripId, CurrencyCode.eur);
        },
        verify: (_) {
          // Verify EUR settlements were loaded with filter
          verify(
            mockSettlementRepository.computeSettlementWithExpenses(
              testTripId,
              any,
              currencyFilter: CurrencyCode.eur,
            ),
          ).called(greaterThan(0));
        },
      );

      blocTest<SettlementCubit, SettlementState>(
        'emits SettlementLoaded with correct base currency',
        build: createCubit,
        setUp: () {
          when(
            mockSettlementRepository.computeSettlementWithExpenses(
              testTripId,
              allExpenses,
              currencyFilter: CurrencyCode.eur,
            ),
          ).thenAnswer((_) async => SettlementComputationResult(summary: eurSettlement));
        },
        act: (cubit) async {
          // Load EUR-filtered settlements directly
          await cubit.loadSettlementForCurrency(testTripId, CurrencyCode.eur);
        },
        expect: () => [
          isA<SettlementLoading>(),
          isA<SettlementLoaded>().having(
            (s) => s.summary.baseCurrency,
            'base currency',
            CurrencyCode.eur,
          ),
        ],
      );

      blocTest<SettlementCubit, SettlementState>(
        'loadSettlementForCurrency(null) loads all expenses (no filter)',
        build: createCubit,
        setUp: () {
          when(
            mockSettlementRepository.computeSettlementWithExpenses(
              testTripId,
              allExpenses,
            ),
          ).thenAnswer((_) async => SettlementComputationResult(summary: usdSettlement));
        },
        act: (cubit) async {
          await cubit.loadSettlement(testTripId);
          await cubit.loadSettlementForCurrency(testTripId, null);
        },
        verify: (_) {
          // Verify computeSettlement was called without filter
          verify(
            mockSettlementRepository.computeSettlementWithExpenses(
              testTripId,
              any,
            ),
          ).called(greaterThan(0));
        },
      );
    });
  });
}
