import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/trips/domain/models/trip.dart';
import 'package:expense_tracker/core/models/currency_code.dart';
import 'package:expense_tracker/core/models/participant.dart';

void main() {
  group('Trip Model', () {
    final now = DateTime(2025, 11, 2, 12, 0, 0);

    group('creation', () {
      test('creates trip with allowedCurrencies', () {
        final trip = Trip(
          id: 'trip1',
          name: 'Vietnam 2025',
          allowedCurrencies: [CurrencyCode.usd, CurrencyCode.vnd],
          createdAt: now,
          updatedAt: now,
        );

        expect(trip.id, 'trip1');
        expect(trip.name, 'Vietnam 2025');
        expect(trip.allowedCurrencies, [CurrencyCode.usd, CurrencyCode.vnd]);
        expect(trip.defaultCurrency, CurrencyCode.usd); // First in list
        expect(trip.isArchived, false); // Default value
        expect(trip.participants, isEmpty);
      });

      test('creates trip with baseCurrency (legacy)', () {
        // ignore: deprecated_member_use_from_same_package
        final trip = Trip(
          id: 'trip1',
          name: 'Vietnam 2025',
          baseCurrency: CurrencyCode.usd,
          createdAt: now,
          updatedAt: now,
        );

        expect(trip.baseCurrency, CurrencyCode.usd);
        expect(trip.allowedCurrencies, isEmpty);
        expect(trip.defaultCurrency, CurrencyCode.usd); // Fallback to baseCurrency
      });

      test('creates trip with participants', () {
        final participants = [
          const Participant(id: 'user1', name: 'Alice'),
          const Participant(id: 'user2', name: 'Bob'),
        ];

        final trip = Trip(
          id: 'trip1',
          name: 'Vietnam 2025',
          allowedCurrencies: [CurrencyCode.usd],
          participants: participants,
          createdAt: now,
          updatedAt: now,
        );

        expect(trip.participants.length, 2);
        expect(trip.participants[0].name, 'Alice');
      });
    });

    group('validation', () {
      group('name validation', () {
        test('rejects empty name', () {
          final trip = Trip(
            id: 'trip1',
            name: '',
            allowedCurrencies: [CurrencyCode.usd],
            createdAt: now,
            updatedAt: now,
          );

          final error = trip.validate();
          expect(error, 'Trip name cannot be empty');
        });

        test('rejects name with only whitespace', () {
          final trip = Trip(
            id: 'trip1',
            name: '   ',
            allowedCurrencies: [CurrencyCode.usd],
            createdAt: now,
            updatedAt: now,
          );

          final error = trip.validate();
          expect(error, 'Trip name cannot be empty');
        });

        test('rejects name exceeding 100 characters', () {
          final longName = 'A' * 101;
          final trip = Trip(
            id: 'trip1',
            name: longName,
            allowedCurrencies: [CurrencyCode.usd],
            createdAt: now,
            updatedAt: now,
          );

          final error = trip.validate();
          expect(error, 'Trip name cannot exceed 100 characters');
        });

        test('accepts name with exactly 100 characters', () {
          final maxName = 'A' * 100;
          final trip = Trip(
            id: 'trip1',
            name: maxName,
            allowedCurrencies: [CurrencyCode.usd],
            createdAt: now,
            updatedAt: now,
          );

          final error = trip.validate();
          expect(error, isNull);
        });

        test('accepts valid name', () {
          final trip = Trip(
            id: 'trip1',
            name: 'Vietnam 2025',
            allowedCurrencies: [CurrencyCode.usd],
            createdAt: now,
            updatedAt: now,
          );

          final error = trip.validate();
          expect(error, isNull);
        });
      });

      group('allowedCurrencies validation', () {
        test('rejects trip with no currencies (neither allowedCurrencies nor baseCurrency)', () {
          final trip = Trip(
            id: 'trip1',
            name: 'Vietnam 2025',
            allowedCurrencies: [],
            baseCurrency: null,
            createdAt: now,
            updatedAt: now,
          );

          final error = trip.validate();
          expect(error, 'At least one currency is required');
        });

        test('accepts trip with 1 currency (minimum valid)', () {
          final trip = Trip(
            id: 'trip1',
            name: 'Vietnam 2025',
            allowedCurrencies: [CurrencyCode.usd],
            createdAt: now,
            updatedAt: now,
          );

          final error = trip.validate();
          expect(error, isNull);
        });

        test('accepts trip with 10 currencies (maximum valid)', () {
          final trip = Trip(
            id: 'trip1',
            name: 'Multi-Currency Trip',
            allowedCurrencies: [
              CurrencyCode.usd,
              CurrencyCode.eur,
              CurrencyCode.gbp,
              CurrencyCode.jpy,
              CurrencyCode.aud,
              CurrencyCode.cad,
              CurrencyCode.chf,
              CurrencyCode.cny,
              CurrencyCode.sek,
              CurrencyCode.nzd,
            ],
            createdAt: now,
            updatedAt: now,
          );

          final error = trip.validate();
          expect(error, isNull);
          expect(trip.allowedCurrencies.length, 10);
        });

        test('rejects trip with 11 currencies (exceeds maximum)', () {
          final trip = Trip(
            id: 'trip1',
            name: 'Too Many Currencies',
            allowedCurrencies: [
              CurrencyCode.usd,
              CurrencyCode.eur,
              CurrencyCode.gbp,
              CurrencyCode.jpy,
              CurrencyCode.aud,
              CurrencyCode.cad,
              CurrencyCode.chf,
              CurrencyCode.cny,
              CurrencyCode.sek,
              CurrencyCode.nzd,
              CurrencyCode.vnd, // 11th currency
            ],
            createdAt: now,
            updatedAt: now,
          );

          final error = trip.validate();
          expect(error, 'Maximum 10 currencies allowed');
        });

        test('rejects trip with duplicate currencies', () {
          final trip = Trip(
            id: 'trip1',
            name: 'Duplicate Currencies',
            allowedCurrencies: [
              CurrencyCode.usd,
              CurrencyCode.eur,
              CurrencyCode.usd, // Duplicate
            ],
            createdAt: now,
            updatedAt: now,
          );

          final error = trip.validate();
          expect(error, 'Duplicate currencies are not allowed');
        });

        test('accepts trip with baseCurrency only (legacy backward compatibility)', () {
          // ignore: deprecated_member_use_from_same_package
          final trip = Trip(
            id: 'trip1',
            name: 'Legacy Trip',
            baseCurrency: CurrencyCode.usd,
            allowedCurrencies: [],
            createdAt: now,
            updatedAt: now,
          );

          final error = trip.validate();
          expect(error, isNull);
        });
      });
    });

    group('defaultCurrency getter', () {
      test('returns first currency from allowedCurrencies when non-empty', () {
        final trip = Trip(
          id: 'trip1',
          name: 'Vietnam 2025',
          allowedCurrencies: [CurrencyCode.vnd, CurrencyCode.usd],
          createdAt: now,
          updatedAt: now,
        );

        expect(trip.defaultCurrency, CurrencyCode.vnd);
      });

      test('falls back to baseCurrency when allowedCurrencies is empty', () {
        // ignore: deprecated_member_use_from_same_package
        final trip = Trip(
          id: 'trip1',
          name: 'Legacy Trip',
          baseCurrency: CurrencyCode.eur,
          allowedCurrencies: [],
          createdAt: now,
          updatedAt: now,
        );

        expect(trip.defaultCurrency, CurrencyCode.eur);
      });

      test('falls back to USD when both allowedCurrencies and baseCurrency are empty', () {
        final trip = Trip(
          id: 'trip1',
          name: 'Emergency Fallback',
          allowedCurrencies: [],
          baseCurrency: null,
          createdAt: now,
          updatedAt: now,
        );

        expect(trip.defaultCurrency, CurrencyCode.usd);
      });
    });

    group('copyWith', () {
      // ignore: deprecated_member_use_from_same_package
      final original = Trip(
        id: 'trip1',
        name: 'Original Trip',
        baseCurrency: CurrencyCode.usd,
        allowedCurrencies: [CurrencyCode.usd],
        createdAt: now,
        updatedAt: now,
        isArchived: false,
      );

      test('copies with new allowedCurrencies', () {
        final copy = original.copyWith(
          allowedCurrencies: [CurrencyCode.eur, CurrencyCode.gbp],
        );

        expect(copy.allowedCurrencies, [CurrencyCode.eur, CurrencyCode.gbp]);
        expect(copy.defaultCurrency, CurrencyCode.eur);
        expect(copy.name, original.name); // Unchanged
      });

      test('copies with new name', () {
        final copy = original.copyWith(name: 'Updated Trip');

        expect(copy.name, 'Updated Trip');
        expect(copy.allowedCurrencies, original.allowedCurrencies); // Unchanged
      });

      test('copies with new isArchived', () {
        final copy = original.copyWith(isArchived: true);

        expect(copy.isArchived, true);
        expect(copy.name, original.name); // Unchanged
      });

      test('returns identical trip when no changes', () {
        final copy = original.copyWith();

        expect(copy.id, original.id);
        expect(copy.name, original.name);
        expect(copy.allowedCurrencies, original.allowedCurrencies);
        expect(copy.isArchived, original.isArchived);
      });
    });

    group('equality', () {
      final trip1 = Trip(
        id: 'trip1',
        name: 'Vietnam 2025',
        allowedCurrencies: [CurrencyCode.usd],
        createdAt: now,
        updatedAt: now,
      );

      final trip2 = Trip(
        id: 'trip1', // Same ID
        name: 'Different Name',
        allowedCurrencies: [CurrencyCode.eur],
        createdAt: now,
        updatedAt: now,
      );

      final trip3 = Trip(
        id: 'trip2', // Different ID
        name: 'Vietnam 2025',
        allowedCurrencies: [CurrencyCode.usd],
        createdAt: now,
        updatedAt: now,
      );

      test('trips with same ID are equal (regardless of other fields)', () {
        expect(trip1 == trip2, isTrue);
      });

      test('trips with different IDs are not equal', () {
        expect(trip1 == trip3, isFalse);
      });

      test('trips with same ID have same hashCode', () {
        expect(trip1.hashCode, trip2.hashCode);
      });

      test('trips with different IDs have different hashCode', () {
        expect(trip1.hashCode, isNot(trip3.hashCode));
      });
    });

    group('edge cases', () {
      test('handles trip with special characters in name', () {
        final trip = Trip(
          id: 'trip1',
          name: "Mom's Year-End Party & Celebration",
          allowedCurrencies: [CurrencyCode.usd],
          createdAt: now,
          updatedAt: now,
        );

        final error = trip.validate();
        expect(error, isNull);
        expect(trip.name, "Mom's Year-End Party & Celebration");
      });

      test('handles trip with Unicode characters in name', () {
        final trip = Trip(
          id: 'trip1',
          name: 'Café Tour in Zürich',
          allowedCurrencies: [CurrencyCode.chf],
          createdAt: now,
          updatedAt: now,
        );

        final error = trip.validate();
        expect(error, isNull);
      });

      test('handles lastExpenseModifiedAt timestamp', () {
        final modifiedAt = DateTime(2025, 11, 1);
        final trip = Trip(
          id: 'trip1',
          name: 'Trip with Expenses',
          allowedCurrencies: [CurrencyCode.usd],
          createdAt: now,
          updatedAt: now,
          lastExpenseModifiedAt: modifiedAt,
        );

        expect(trip.lastExpenseModifiedAt, modifiedAt);
      });

      test('toString includes allowedCurrencies when non-empty', () {
        final trip = Trip(
          id: 'trip1',
          name: 'Multi-Currency',
          allowedCurrencies: [CurrencyCode.usd, CurrencyCode.eur],
          createdAt: now,
          updatedAt: now,
        );

        final str = trip.toString();
        expect(str, contains('allowedCurrencies'));
        expect(str, contains('CurrencyCode.usd'));
        expect(str, contains('CurrencyCode.eur'));
      });

      test('toString indicates legacy mode when using baseCurrency', () {
        // ignore: deprecated_member_use_from_same_package
        final trip = Trip(
          id: 'trip1',
          name: 'Legacy',
          baseCurrency: CurrencyCode.usd,
          allowedCurrencies: [],
          createdAt: now,
          updatedAt: now,
        );

        final str = trip.toString();
        expect(str, contains('baseCurrency'));
        expect(str, contains('legacy'));
      });
    });
  });
}
