import 'package:flutter_test/flutter_test.dart';
import 'package:decimal/decimal.dart';
import 'package:expense_tracker/features/expenses/domain/models/expense.dart';
import 'package:expense_tracker/core/models/split_type.dart';
import 'package:expense_tracker/core/models/currency_code.dart';

void main() {
  group('Expense Validation -', () {
    test('valid expense passes validation', () {
      // Arrange
      final expense = Expense(
        id: 'test-1',
        tripId: 'trip-1',
        date: DateTime(2025, 10, 21),
        payerUserId: 'tai',
        currency: CurrencyCode.usd,
        amount: Decimal.parse('100.00'),
        splitType: SplitType.equal,
        participants: {'tai': 1, 'khiet': 1},
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Act
      final error = expense.validate();

      // Assert
      expect(error, isNull);
    });

    test('rejects zero amount', () {
      // Arrange
      final expense = Expense(
        id: 'test-2',
        tripId: 'trip-1',
        date: DateTime(2025, 10, 21),
        payerUserId: 'tai',
        currency: CurrencyCode.usd,
        amount: Decimal.zero,
        splitType: SplitType.equal,
        participants: {'tai': 1},
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Act
      final error = expense.validate();

      // Assert
      expect(error, isNotNull);
      expect(error, contains('amount'));
      expect(error, contains('greater than 0'));
    });

    test('rejects negative amount', () {
      // Arrange
      final expense = Expense(
        id: 'test-3',
        tripId: 'trip-1',
        date: DateTime(2025, 10, 21),
        payerUserId: 'tai',
        currency: CurrencyCode.usd,
        amount: Decimal.parse('-50.00'),
        splitType: SplitType.equal,
        participants: {'tai': 1},
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Act
      final error = expense.validate();

      // Assert
      expect(error, isNotNull);
      expect(error, contains('amount'));
    });

    test('rejects future date', () {
      // Arrange
      final futureDate = DateTime.now().add(const Duration(days: 1));
      final expense = Expense(
        id: 'test-4',
        tripId: 'trip-1',
        date: futureDate,
        payerUserId: 'tai',
        currency: CurrencyCode.usd,
        amount: Decimal.parse('100.00'),
        splitType: SplitType.equal,
        participants: {'tai': 1},
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Act
      final error = expense.validate();

      // Assert
      expect(error, isNotNull);
      expect(error, contains('date'));
      expect(error, contains('future'));
    });

    test('rejects empty participants', () {
      // Arrange
      final expense = Expense(
        id: 'test-5',
        tripId: 'trip-1',
        date: DateTime(2025, 10, 21),
        payerUserId: 'tai',
        currency: CurrencyCode.usd,
        amount: Decimal.parse('100.00'),
        splitType: SplitType.equal,
        participants: {},
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Act
      final error = expense.validate();

      // Assert
      expect(error, isNotNull);
      expect(error, contains('participant'));
    });

    test('rejects equal split with non-1 weights', () {
      // Arrange
      final expense = Expense(
        id: 'test-6',
        tripId: 'trip-1',
        date: DateTime(2025, 10, 21),
        payerUserId: 'tai',
        currency: CurrencyCode.usd,
        amount: Decimal.parse('100.00'),
        splitType: SplitType.equal,
        participants: {'tai': 2, 'khiet': 1}, // Invalid: not all weights = 1
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Act
      final error = expense.validate();

      // Assert
      expect(error, isNotNull);
      expect(error!.toLowerCase(), contains('equal'));
      expect(error.toLowerCase(), contains('weight'));
    });

    test('rejects weighted split with zero or negative weights', () {
      // Arrange
      final expense = Expense(
        id: 'test-7',
        tripId: 'trip-1',
        date: DateTime(2025, 10, 21),
        payerUserId: 'tai',
        currency: CurrencyCode.usd,
        amount: Decimal.parse('100.00'),
        splitType: SplitType.weighted,
        participants: {'tai': 2, 'khiet': 0}, // Invalid: zero weight
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Act
      final error = expense.validate();

      // Assert
      expect(error, isNotNull);
      expect(error, contains('weight'));
      expect(error, contains('greater than 0'));
    });

    test('accepts description up to 200 characters', () {
      // Arrange
      final validDescription = 'A' * 200;
      final expense = Expense(
        id: 'test-8',
        tripId: 'trip-1',
        date: DateTime(2025, 10, 21),
        payerUserId: 'tai',
        currency: CurrencyCode.usd,
        amount: Decimal.parse('100.00'),
        description: validDescription,
        splitType: SplitType.equal,
        participants: {'tai': 1},
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Act
      final error = expense.validate();

      // Assert
      expect(error, isNull);
    });

    test('rejects description over 200 characters', () {
      // Arrange
      final longDescription = 'A' * 201;
      final expense = Expense(
        id: 'test-9',
        tripId: 'trip-1',
        date: DateTime(2025, 10, 21),
        payerUserId: 'tai',
        currency: CurrencyCode.usd,
        amount: Decimal.parse('100.00'),
        description: longDescription,
        splitType: SplitType.equal,
        participants: {'tai': 1},
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Act
      final error = expense.validate();

      // Assert
      expect(error, isNotNull);
      expect(error, contains('description'));
      expect(error, contains('200'));
    });
  });
}
