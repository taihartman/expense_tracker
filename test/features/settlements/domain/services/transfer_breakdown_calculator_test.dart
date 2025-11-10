import 'package:flutter_test/flutter_test.dart';
import 'package:decimal/decimal.dart';
import 'package:expense_tracker/features/settlements/domain/services/transfer_breakdown_calculator.dart';
import 'package:expense_tracker/features/expenses/domain/models/expense.dart';
import 'package:expense_tracker/core/models/currency_code.dart';
import 'package:expense_tracker/core/models/split_type.dart';

/// Unit tests for TransferBreakdownCalculator
///
/// Tests that transfer breakdowns correctly calculate how much each
/// expense contributes to a debt between two people.
void main() {
  group('TransferBreakdownCalculator -', () {
    late TransferBreakdownCalculator calculator;

    setUp(() {
      calculator = TransferBreakdownCalculator();
    });

    group('Itemized expense handling -', () {
      test('uses participantAmounts for itemized expenses', () {
        // Arrange - Itemized expense (like "Receipt Split")
        // Simulates the Vietnamese meal from the bug report:
        // - Total: ₫240,000
        // - Ethan paid
        // - Izzy consumed: ₫86,666
        // - Ryan consumed: ₫86,667
        // - Ethan consumed: ₫66,667
        final expense = Expense(
          id: 'exp-1',
          tripId: 'trip-1',
          date: DateTime.now(),
          payerUserId: 'ethan',
          currency: CurrencyCode.vnd,
          amount: Decimal.parse('240000'),
          description: 'Beef noodle, Chicken noodle, and 2 more',
          splitType: SplitType.itemized,
          participants: {
            'ethan': 1,
            'izzy': 1,
            'ryan': 1,
          },
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          // Pre-calculated amounts from itemized split
          participantAmounts: {
            'ethan': Decimal.parse('66667'),
            'izzy': Decimal.parse('86666'),
            'ryan': Decimal.parse('86667'),
          },
        );

        // Act - Calculate breakdown for Izzy → Ethan transfer
        final breakdown = calculator.calculateBreakdown(
          fromUserId: 'izzy',
          toUserId: 'ethan',
          transferAmount: Decimal.parse('86666'),
          expenses: [expense],
        );

        // Assert - Should use participantAmounts, not calculateShares()
        expect(breakdown.expenseBreakdowns.length, 1);

        final expenseBreakdown = breakdown.expenseBreakdowns.first;

        // Izzy paid ₫0, owes ₫86,666
        expect(expenseBreakdown.fromPaid, Decimal.zero);
        expect(expenseBreakdown.fromOwes, Decimal.parse('86666'));

        // Ethan paid ₫240,000, owes ₫66,667
        expect(expenseBreakdown.toPaid, Decimal.parse('240000'));
        expect(expenseBreakdown.toOwes, Decimal.parse('66667'));

        // Net contribution: Izzy owes Ethan ₫86,666 (positive)
        expect(expenseBreakdown.netContribution, Decimal.parse('86666'));
      });

      test('correctly handles itemized expense with different payer', () {
        // Arrange - Ryan paid this time
        final expense = Expense(
          id: 'exp-2',
          tripId: 'trip-1',
          date: DateTime.now(),
          payerUserId: 'ryan',
          currency: CurrencyCode.vnd,
          amount: Decimal.parse('100000'),
          description: 'Lẩu tip',
          splitType: SplitType.itemized,
          participants: {
            'ethan': 1,
            'izzy': 1,
            'ryan': 1,
          },
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          participantAmounts: {
            'ethan': Decimal.parse('33333'),
            'izzy': Decimal.parse('33333'),
            'ryan': Decimal.parse('33334'),
          },
        );

        // Act - Calculate breakdown for Izzy → Ethan transfer
        final breakdown = calculator.calculateBreakdown(
          fromUserId: 'izzy',
          toUserId: 'ethan',
          transferAmount: Decimal.zero, // No direct debt between them
          expenses: [expense],
        );

        // Assert - No direct debt between Izzy and Ethan (Ryan paid)
        expect(breakdown.expenseBreakdowns.length, 1);

        final expenseBreakdown = breakdown.expenseBreakdowns.first;

        // Neither Izzy nor Ethan paid (Ryan did)
        expect(expenseBreakdown.fromPaid, Decimal.zero);
        expect(expenseBreakdown.toPaid, Decimal.zero);

        // Both owe Ryan (not each other)
        expect(expenseBreakdown.fromOwes, Decimal.parse('33333'));
        expect(expenseBreakdown.toOwes, Decimal.parse('33333'));

        // Net contribution: zero (no direct debt between Izzy and Ethan)
        expect(expenseBreakdown.netContribution, Decimal.zero);
      });

      test('handles multiple itemized expenses correctly', () {
        // Arrange - Two itemized expenses
        final expenses = [
          Expense(
            id: 'exp-1',
            tripId: 'trip-1',
            date: DateTime.now(),
            payerUserId: 'ethan',
            currency: CurrencyCode.vnd,
            amount: Decimal.parse('240000'),
            splitType: SplitType.itemized,
            participants: {'ethan': 1, 'izzy': 1, 'ryan': 1},
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            participantAmounts: {
              'ethan': Decimal.parse('66667'),
              'izzy': Decimal.parse('86666'),
              'ryan': Decimal.parse('86667'),
            },
          ),
          Expense(
            id: 'exp-2',
            tripId: 'trip-1',
            date: DateTime.now(),
            payerUserId: 'ethan',
            currency: CurrencyCode.vnd,
            amount: Decimal.parse('100000'),
            splitType: SplitType.itemized,
            participants: {'ethan': 1, 'izzy': 1, 'ryan': 1},
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            participantAmounts: {
              'ethan': Decimal.parse('33333'),
              'izzy': Decimal.parse('33333'),
              'ryan': Decimal.parse('33334'),
            },
          ),
        ];

        // Act - Calculate breakdown for Izzy → Ethan transfer
        final breakdown = calculator.calculateBreakdown(
          fromUserId: 'izzy',
          toUserId: 'ethan',
          transferAmount: Decimal.parse('119999'), // 86666 + 33333
          expenses: expenses,
        );

        // Assert - Should have 2 expense breakdowns
        expect(breakdown.expenseBreakdowns.length, 2);

        // First expense: Izzy owes ₫86,666
        expect(breakdown.expenseBreakdowns[0].netContribution, Decimal.parse('86666'));

        // Second expense: Izzy owes ₫33,333
        expect(breakdown.expenseBreakdowns[1].netContribution, Decimal.parse('33333'));

        // Total: ₫119,999
        final total = breakdown.relevantBreakdowns
            .map((b) => b.netContribution)
            .fold(Decimal.zero, (sum, amount) => sum + amount);
        expect(total, Decimal.parse('119999'));
      });
    });

    group('Equal split handling -', () {
      test('correctly calculates breakdown for equal split expenses', () {
        // Arrange - Simple equal split
        final expense = Expense(
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
        );

        // Act
        final breakdown = calculator.calculateBreakdown(
          fromUserId: 'bob',
          toUserId: 'alice',
          transferAmount: Decimal.parse('50'),
          expenses: [expense],
        );

        // Assert
        expect(breakdown.expenseBreakdowns.length, 1);

        final expenseBreakdown = breakdown.expenseBreakdowns.first;

        // Bob paid ₫0, owes ₫50
        expect(expenseBreakdown.fromPaid, Decimal.zero);
        expect(expenseBreakdown.fromOwes, Decimal.parse('50'));

        // Alice paid ₫100, owes ₫50
        expect(expenseBreakdown.toPaid, Decimal.parse('100'));
        expect(expenseBreakdown.toOwes, Decimal.parse('50'));

        // Net: Bob owes Alice ₫50
        expect(expenseBreakdown.netContribution, Decimal.parse('50'));
      });
    });

    group('Weighted split handling -', () {
      test('correctly calculates breakdown for weighted split expenses', () {
        // Arrange - Weighted split (Alice weight=2, Bob weight=1)
        final expense = Expense(
          id: 'exp-1',
          tripId: 'trip-1',
          date: DateTime.now(),
          payerUserId: 'alice',
          currency: CurrencyCode.usd,
          amount: Decimal.parse('90'),
          splitType: SplitType.weighted,
          participants: {'alice': 2, 'bob': 1},
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Act
        final breakdown = calculator.calculateBreakdown(
          fromUserId: 'bob',
          toUserId: 'alice',
          transferAmount: Decimal.parse('30'),
          expenses: [expense],
        );

        // Assert
        expect(breakdown.expenseBreakdowns.length, 1);

        final expenseBreakdown = breakdown.expenseBreakdowns.first;

        // Bob should owe 1/3 of ₫90 = ₫30
        expect(expenseBreakdown.fromOwes, Decimal.parse('30'));

        // Alice should owe 2/3 of ₫90 = ₫60
        expect(expenseBreakdown.toOwes, Decimal.parse('60'));

        // Net: Bob owes Alice ₫30
        expect(expenseBreakdown.netContribution, Decimal.parse('30'));
      });
    });

    group('Reverse debt handling -', () {
      test('handles negative contribution when FROM paid and TO participated', () {
        // Arrange - Bob paid, Alice participated
        final expense = Expense(
          id: 'exp-1',
          tripId: 'trip-1',
          date: DateTime.now(),
          payerUserId: 'bob',
          currency: CurrencyCode.usd,
          amount: Decimal.parse('100'),
          splitType: SplitType.equal,
          participants: {'alice': 1, 'bob': 1},
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Act - Calculate breakdown for Bob → Alice
        // (Bob paid, so Alice owes Bob, which is opposite direction)
        final breakdown = calculator.calculateBreakdown(
          fromUserId: 'bob',
          toUserId: 'alice',
          transferAmount: Decimal.zero, // No debt this direction
          expenses: [expense],
        );

        // Assert
        final expenseBreakdown = breakdown.expenseBreakdowns.first;

        // Bob paid ₫100, owes ₫50
        expect(expenseBreakdown.fromPaid, Decimal.parse('100'));
        expect(expenseBreakdown.fromOwes, Decimal.parse('50'));

        // Alice paid ₫0, owes ₫50
        expect(expenseBreakdown.toPaid, Decimal.zero);
        expect(expenseBreakdown.toOwes, Decimal.parse('50'));

        // Negative contribution: Alice owes Bob (opposite direction)
        expect(expenseBreakdown.netContribution, Decimal.parse('-50'));
      });
    });

    group('Relevant breakdowns filtering -', () {
      test('filters out zero-contribution expenses', () {
        // Arrange - Mix of expenses
        final expenses = [
          // Ethan paid, both participated - Izzy owes
          Expense(
            id: 'exp-1',
            tripId: 'trip-1',
            date: DateTime.now(),
            payerUserId: 'ethan',
            currency: CurrencyCode.vnd,
            amount: Decimal.parse('100'),
            splitType: SplitType.equal,
            participants: {'ethan': 1, 'izzy': 1},
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          // Ryan paid, neither Ethan nor Izzy involved - zero contribution
          Expense(
            id: 'exp-2',
            tripId: 'trip-1',
            date: DateTime.now(),
            payerUserId: 'ryan',
            currency: CurrencyCode.vnd,
            amount: Decimal.parse('50'),
            splitType: SplitType.equal,
            participants: {'ryan': 1, 'charlie': 1},
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ];

        // Act
        final breakdown = calculator.calculateBreakdown(
          fromUserId: 'izzy',
          toUserId: 'ethan',
          transferAmount: Decimal.parse('50'),
          expenses: expenses,
        );

        // Assert - Only relevant breakdown should be included
        expect(breakdown.expenseBreakdowns.length, 2);
        expect(breakdown.relevantBreakdowns.length, 1);

        // Only exp-1 should contribute
        expect(breakdown.relevantBreakdowns.first.expense.id, 'exp-1');
      });
    });
  });
}
