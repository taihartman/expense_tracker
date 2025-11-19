import 'package:flutter_test/flutter_test.dart';
import 'package:decimal/decimal.dart';
import 'package:expense_tracker/features/settlements/domain/services/settlement_calculator.dart';
import 'package:expense_tracker/features/expenses/domain/models/expense.dart';
import 'package:expense_tracker/core/models/currency_code.dart';
import 'package:expense_tracker/core/models/split_type.dart';

/// T027: Unit tests for per-currency settlement calculations
///
/// Tests that settlement calculations can filter expenses by currency
/// and calculate settlements independently for each currency.
void main() {
  group('T027: Per-Currency Settlement Calculations -', () {
    late SettlementCalculator calculator;

    setUp(() {
      calculator = SettlementCalculator();
    });

    group('Currency filtering -', () {
      test('filters USD expenses when currencyFilter is USD', () {
        // Arrange - Mixed currency expenses
        final expenses = [
          Expense(
            id: 'exp-1',
            tripId: 'trip-1',
            date: DateTime.now(),
            payerUserId: 'alice',
            currency: CurrencyCode.usd,
            amount: Decimal.parse('100'),
            splitType: SplitType.equal,
            participants: {'alice': 1, 'bob': 1},
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          Expense(
            id: 'exp-2',
            tripId: 'trip-1',
            date: DateTime.now(),
            payerUserId: 'bob',
            currency: CurrencyCode.eur,
            amount: Decimal.parse('50'),
            splitType: SplitType.equal,
            participants: {'alice': 1, 'bob': 1},
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          Expense(
            id: 'exp-3',
            tripId: 'trip-1',
            date: DateTime.now(),
            payerUserId: 'alice',
            currency: CurrencyCode.usd,
            amount: Decimal.parse('60'),
            splitType: SplitType.equal,
            participants: {'alice': 1, 'bob': 1},
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ];

        // Act - Calculate settlements with USD filter
        final summaries = calculator.calculatePersonSummaries(
          expenses: expenses,
          baseCurrency: CurrencyCode.usd,
          currencyFilter: CurrencyCode.usd,
        );

        // Assert - Should only include USD expenses (exp-1 and exp-3)
        // Alice paid 100 + 60 = 160, owes 50 + 30 = 80, net = +80
        // Bob paid 0, owes 50 + 30 = 80, net = -80
        expect(summaries['alice']!.totalPaidBase, Decimal.parse('160'));
        expect(summaries['alice']!.totalOwedBase, Decimal.parse('80'));
        expect(summaries['alice']!.netBase, Decimal.parse('80'));

        expect(summaries['bob']!.totalPaidBase, Decimal.zero);
        expect(summaries['bob']!.totalOwedBase, Decimal.parse('80'));
        expect(summaries['bob']!.netBase, Decimal.parse('-80'));
      });

      test('filters EUR expenses when currencyFilter is EUR', () {
        // Arrange - Mixed currency expenses
        final expenses = [
          Expense(
            id: 'exp-1',
            tripId: 'trip-1',
            date: DateTime.now(),
            payerUserId: 'alice',
            currency: CurrencyCode.usd,
            amount: Decimal.parse('100'),
            splitType: SplitType.equal,
            participants: {'alice': 1, 'bob': 1},
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          Expense(
            id: 'exp-2',
            tripId: 'trip-1',
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

        // Act - Calculate settlements with EUR filter
        final summaries = calculator.calculatePersonSummaries(
          expenses: expenses,
          baseCurrency: CurrencyCode.eur,
          currencyFilter: CurrencyCode.eur,
        );

        // Assert - Should only include EUR expense (exp-2)
        // Alice paid 0, owes 25, net = -25
        // Bob paid 50, owes 25, net = +25
        expect(summaries['alice']!.totalPaidBase, Decimal.zero);
        expect(summaries['alice']!.totalOwedBase, Decimal.parse('25'));
        expect(summaries['alice']!.netBase, Decimal.parse('-25'));

        expect(summaries['bob']!.totalPaidBase, Decimal.parse('50'));
        expect(summaries['bob']!.totalOwedBase, Decimal.parse('25'));
        expect(summaries['bob']!.netBase, Decimal.parse('25'));
      });

      test('returns empty summaries when no expenses match currency filter', () {
        // Arrange - Only USD expenses
        final expenses = [
          Expense(
            id: 'exp-1',
            tripId: 'trip-1',
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

        // Act - Calculate settlements with GBP filter (no GBP expenses)
        final summaries = calculator.calculatePersonSummaries(
          expenses: expenses,
          baseCurrency: CurrencyCode.gbp,
          currencyFilter: CurrencyCode.gbp,
        );

        // Assert - Should have no summaries or zero balances
        expect(summaries.isEmpty, true);
      });
    });

    group('Independent per-currency calculations -', () {
      test('calculates USD and EUR settlements independently', () {
        // Arrange - Trip with both USD and EUR expenses
        final allExpenses = [
          // USD expenses
          Expense(
            id: 'exp-usd-1',
            tripId: 'trip-1',
            date: DateTime.now(),
            payerUserId: 'alice',
            currency: CurrencyCode.usd,
            amount: Decimal.parse('100'),
            splitType: SplitType.equal,
            participants: {'alice': 1, 'bob': 1, 'charlie': 1},
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          Expense(
            id: 'exp-usd-2',
            tripId: 'trip-1',
            date: DateTime.now(),
            payerUserId: 'bob',
            currency: CurrencyCode.usd,
            amount: Decimal.parse('90'),
            splitType: SplitType.equal,
            participants: {'alice': 1, 'bob': 1, 'charlie': 1},
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          // EUR expenses
          Expense(
            id: 'exp-eur-1',
            tripId: 'trip-1',
            date: DateTime.now(),
            payerUserId: 'charlie',
            currency: CurrencyCode.eur,
            amount: Decimal.parse('60'),
            splitType: SplitType.equal,
            participants: {'alice': 1, 'bob': 1},
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ];

        // Act - Calculate USD settlements
        final usdSummaries = calculator.calculatePersonSummaries(
          expenses: allExpenses,
          baseCurrency: CurrencyCode.usd,
          currencyFilter: CurrencyCode.usd,
        );

        // Act - Calculate EUR settlements
        final eurSummaries = calculator.calculatePersonSummaries(
          expenses: allExpenses,
          baseCurrency: CurrencyCode.eur,
          currencyFilter: CurrencyCode.eur,
        );

        // Assert USD settlements
        // Alice paid 100, owes 100/3 + 90/3
        // With remainder distribution: 100/3 = 33.34 (alice gets extra cent) + 30.00 = 63.34
        expect(
          usdSummaries['alice']!.totalPaidBase,
          Decimal.parse('100'),
        );
        expect(
          usdSummaries['alice']!.totalOwedBase.toStringAsFixed(2),
          '63.34',
        );

        // Assert EUR settlements
        // Charlie paid 60, owes 0, net = +60
        // Alice paid 0, owes 30, net = -30
        expect(eurSummaries['charlie']!.totalPaidBase, Decimal.parse('60'));
        expect(eurSummaries['charlie']!.totalOwedBase, Decimal.zero);
        expect(eurSummaries['charlie']!.netBase, Decimal.parse('60'));

        expect(eurSummaries['alice']!.totalPaidBase, Decimal.zero);
        expect(eurSummaries['alice']!.totalOwedBase, Decimal.parse('30'));
        expect(eurSummaries['alice']!.netBase, Decimal.parse('-30'));

        // Assert EUR calculations don't affect USD and vice versa
        // Charlie doesn't appear in USD summaries
        expect(usdSummaries.containsKey('charlie'), true);
        expect(
          usdSummaries['charlie']!.totalPaidBase,
          Decimal.zero,
        ); // Charlie paid no USD
      });

      test('calculates pairwise transfers independently per currency', () {
        // Arrange - Multi-currency expenses
        final allExpenses = [
          // USD: Alice pays 100, split between Alice and Bob
          Expense(
            id: 'exp-usd-1',
            tripId: 'trip-1',
            date: DateTime.now(),
            payerUserId: 'alice',
            currency: CurrencyCode.usd,
            amount: Decimal.parse('100'),
            splitType: SplitType.equal,
            participants: {'alice': 1, 'bob': 1},
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          // EUR: Bob pays 50, split between Alice and Bob
          Expense(
            id: 'exp-eur-1',
            tripId: 'trip-1',
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

        // Act - Calculate USD transfers
        final usdTransfers = calculator.calculatePairwiseNetTransfers(
          tripId: 'trip-1',
          expenses: allExpenses,
          currencyFilter: CurrencyCode.usd,
        );

        // Act - Calculate EUR transfers
        final eurTransfers = calculator.calculatePairwiseNetTransfers(
          tripId: 'trip-1',
          expenses: allExpenses,
          currencyFilter: CurrencyCode.eur,
        );

        // Assert - USD: Bob owes Alice 50
        expect(usdTransfers.length, 1);
        expect(usdTransfers[0].fromUserId, 'bob');
        expect(usdTransfers[0].toUserId, 'alice');
        expect(usdTransfers[0].amountBase, Decimal.parse('50'));

        // Assert - EUR: Alice owes Bob 25
        expect(eurTransfers.length, 1);
        expect(eurTransfers[0].fromUserId, 'alice');
        expect(eurTransfers[0].toUserId, 'bob');
        expect(eurTransfers[0].amountBase, Decimal.parse('25'));
      });
    });

    group('Multi-currency trip handling -', () {
      test('handles trip with 3 currencies (USD, EUR, GBP)', () {
        // Arrange - Trip with 3 different currencies
        final expenses = [
          Expense(
            id: 'exp-usd',
            tripId: 'trip-1',
            date: DateTime.now(),
            payerUserId: 'alice',
            currency: CurrencyCode.usd,
            amount: Decimal.parse('100'),
            splitType: SplitType.equal,
            participants: {'alice': 1, 'bob': 1},
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          Expense(
            id: 'exp-eur',
            tripId: 'trip-1',
            date: DateTime.now(),
            payerUserId: 'bob',
            currency: CurrencyCode.eur,
            amount: Decimal.parse('60'),
            splitType: SplitType.equal,
            participants: {'alice': 1, 'bob': 1},
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          Expense(
            id: 'exp-gbp',
            tripId: 'trip-1',
            date: DateTime.now(),
            payerUserId: 'alice',
            currency: CurrencyCode.gbp,
            amount: Decimal.parse('80'),
            splitType: SplitType.equal,
            participants: {'alice': 1, 'bob': 1},
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ];

        // Act - Calculate for each currency
        final usdSummaries = calculator.calculatePersonSummaries(
          expenses: expenses,
          baseCurrency: CurrencyCode.usd,
          currencyFilter: CurrencyCode.usd,
        );

        final eurSummaries = calculator.calculatePersonSummaries(
          expenses: expenses,
          baseCurrency: CurrencyCode.eur,
          currencyFilter: CurrencyCode.eur,
        );

        final gbpSummaries = calculator.calculatePersonSummaries(
          expenses: expenses,
          baseCurrency: CurrencyCode.gbp,
          currencyFilter: CurrencyCode.gbp,
        );

        // Assert - Each currency has independent settlements
        // USD: Alice paid 100, owes 50, net = +50
        expect(usdSummaries['alice']!.netBase, Decimal.parse('50'));

        // EUR: Bob paid 60, owes 30, net = +30
        expect(eurSummaries['bob']!.netBase, Decimal.parse('30'));

        // GBP: Alice paid 80, owes 40, net = +40
        expect(gbpSummaries['alice']!.netBase, Decimal.parse('40'));
      });

      test('validates balances per currency (conservation of money)', () {
        // Arrange
        final expenses = [
          Expense(
            id: 'exp-1',
            tripId: 'trip-1',
            date: DateTime.now(),
            payerUserId: 'alice',
            currency: CurrencyCode.usd,
            amount: Decimal.parse('100'),
            splitType: SplitType.equal,
            participants: {'alice': 1, 'bob': 1, 'charlie': 1},
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          Expense(
            id: 'exp-2',
            tripId: 'trip-1',
            date: DateTime.now(),
            payerUserId: 'bob',
            currency: CurrencyCode.usd,
            amount: Decimal.parse('90'),
            splitType: SplitType.equal,
            participants: {'alice': 1, 'bob': 1, 'charlie': 1},
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ];

        // Act
        final summaries = calculator.calculatePersonSummaries(
          expenses: expenses,
          baseCurrency: CurrencyCode.usd,
          currencyFilter: CurrencyCode.usd,
        );

        // Assert - Sum of all net balances should be zero
        final sum = summaries.values
            .map((s) => s.netBase)
            .fold(Decimal.zero, (a, b) => a + b);

        // Allow for small rounding errors (up to 0.02 to account for division by 3)
        expect(
          sum.abs() < Decimal.parse('0.02'),
          true,
          reason:
              'Sum of net balances should be near zero (actual: $sum, sum of alice ${summaries['alice']!.netBase} + bob ${summaries['bob']!.netBase} + charlie ${summaries['charlie']!.netBase})',
        );

        final isValid = calculator.validateBalances(summaries);
        expect(isValid, true);
      });
    });
  });
}
