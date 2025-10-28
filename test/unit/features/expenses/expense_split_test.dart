import 'package:flutter_test/flutter_test.dart';
import 'package:decimal/decimal.dart';
import 'package:expense_tracker/features/expenses/domain/models/expense.dart';
import 'package:expense_tracker/core/models/split_type.dart';
import 'package:expense_tracker/core/models/currency_code.dart';

void main() {
  group('Expense Split Calculation -', () {
    group('Equal Split', () {
      test('divides amount evenly among participants', () {
        // Arrange
        final expense = Expense(
          id: 'test-1',
          tripId: 'trip-1',
          date: DateTime(2025, 10, 21),
          payerUserId: 'tai',
          currency: CurrencyCode.usd,
          amount: Decimal.parse('100.00'),
          splitType: SplitType.equal,
          participants: {'tai': 1, 'khiet': 1, 'bob': 1, 'ethan': 1},
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Act
        final shares = expense.calculateShares();

        // Assert
        expect(shares.length, equals(4));
        expect(shares['tai'], equals(Decimal.parse('25.00')));
        expect(shares['khiet'], equals(Decimal.parse('25.00')));
        expect(shares['bob'], equals(Decimal.parse('25.00')));
        expect(shares['ethan'], equals(Decimal.parse('25.00')));
      });

      test('handles odd amounts with proper rounding', () {
        // Arrange
        final expense = Expense(
          id: 'test-2',
          tripId: 'trip-1',
          date: DateTime(2025, 10, 21),
          payerUserId: 'tai',
          currency: CurrencyCode.usd,
          amount: Decimal.parse('100.00'),
          splitType: SplitType.equal,
          participants: {'tai': 1, 'khiet': 1, 'bob': 1}, // 3 people
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Act
        final shares = expense.calculateShares();

        // Assert
        expect(shares.length, equals(3));
        // Each person should get 33.33 (with rounding)
        final expectedShare = Decimal.parse('33.33');
        expect(shares['tai'], equals(expectedShare));
        expect(shares['khiet'], equals(expectedShare));
        expect(shares['bob'], equals(expectedShare));
      });

      test('handles single participant', () {
        // Arrange
        final expense = Expense(
          id: 'test-3',
          tripId: 'trip-1',
          date: DateTime(2025, 10, 21),
          payerUserId: 'tai',
          currency: CurrencyCode.usd,
          amount: Decimal.parse('100.00'),
          splitType: SplitType.equal,
          participants: {'tai': 1},
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Act
        final shares = expense.calculateShares();

        // Assert
        expect(shares.length, equals(1));
        expect(shares['tai'], equals(Decimal.parse('100.00')));
      });

      test('sum of shares equals original amount (conservation)', () {
        // Arrange
        final expense = Expense(
          id: 'test-4',
          tripId: 'trip-1',
          date: DateTime(2025, 10, 21),
          payerUserId: 'tai',
          currency: CurrencyCode.usd,
          amount: Decimal.parse('99.99'),
          splitType: SplitType.equal,
          participants: {'tai': 1, 'khiet': 1, 'bob': 1, 'ethan': 1, 'ryan': 1},
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Act
        final shares = expense.calculateShares();

        // Assert
        final sum = shares.values.fold(Decimal.zero, (a, b) => a + b);
        // Sum should be within 0.05 of original amount (allow for rounding)
        final difference = (sum - expense.amount).abs();
        expect(
          difference <= Decimal.parse('0.05'),
          isTrue,
          reason: 'Sum $sum should be close to ${expense.amount}',
        );
      });
    });

    group('Weighted Split', () {
      test('divides amount proportionally by weights', () {
        // Arrange
        final expense = Expense(
          id: 'test-5',
          tripId: 'trip-1',
          date: DateTime(2025, 10, 21),
          payerUserId: 'tai',
          currency: CurrencyCode.usd,
          amount: Decimal.parse('100.00'),
          splitType: SplitType.weighted,
          participants: {
            'tai': 2, // 50% (2/4)
            'khiet': 1, // 25% (1/4)
            'bob': 1, // 25% (1/4)
          },
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Act
        final shares = expense.calculateShares();

        // Assert
        expect(shares.length, equals(3));
        expect(shares['tai'], equals(Decimal.parse('50.00')));
        expect(shares['khiet'], equals(Decimal.parse('25.00')));
        expect(shares['bob'], equals(Decimal.parse('25.00')));
      });

      test('handles decimal weights', () {
        // Arrange
        final expense = Expense(
          id: 'test-6',
          tripId: 'trip-1',
          date: DateTime(2025, 10, 21),
          payerUserId: 'tai',
          currency: CurrencyCode.usd,
          amount: Decimal.parse('300.00'),
          splitType: SplitType.weighted,
          participants: {
            'tai': 1.5, // 50% (1.5/3.0)
            'khiet': 1.0, // 33.33% (1.0/3.0)
            'bob': 0.5, // 16.67% (0.5/3.0)
          },
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Act
        final shares = expense.calculateShares();

        // Assert
        expect(shares.length, equals(3));
        expect(shares['tai'], equals(Decimal.parse('150.00')));
        expect(shares['khiet'], equals(Decimal.parse('100.00')));
        expect(shares['bob'], equals(Decimal.parse('50.00')));
      });

      test('sum of weighted shares equals original amount', () {
        // Arrange
        final expense = Expense(
          id: 'test-7',
          tripId: 'trip-1',
          date: DateTime(2025, 10, 21),
          payerUserId: 'tai',
          currency: CurrencyCode.usd,
          amount: Decimal.parse('123.45'),
          splitType: SplitType.weighted,
          participants: {'tai': 3, 'khiet': 2, 'bob': 1},
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Act
        final shares = expense.calculateShares();

        // Assert
        final sum = shares.values.fold(Decimal.zero, (a, b) => a + b);
        // Sum should be within 0.05 of original amount
        final difference = (sum - expense.amount).abs();
        expect(
          difference <= Decimal.parse('0.05'),
          isTrue,
          reason: 'Sum $sum should be close to ${expense.amount}',
        );
      });
    });
  });
}
