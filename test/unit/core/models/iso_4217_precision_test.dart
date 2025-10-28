import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/core/models/iso_4217_precision.dart';

void main() {
  group('Iso4217Precision', () {
    group('getDecimalPlaces', () {
      test('returns 2 for USD', () {
        expect(Iso4217Precision.getDecimalPlaces('USD'), 2);
      });

      test('returns 2 for EUR', () {
        expect(Iso4217Precision.getDecimalPlaces('EUR'), 2);
      });

      test('returns 0 for VND', () {
        expect(Iso4217Precision.getDecimalPlaces('VND'), 0);
      });

      test('returns 0 for JPY', () {
        expect(Iso4217Precision.getDecimalPlaces('JPY'), 0);
      });

      test('returns 3 for BHD', () {
        expect(Iso4217Precision.getDecimalPlaces('BHD'), 3);
      });

      test('returns 3 for KWD', () {
        expect(Iso4217Precision.getDecimalPlaces('KWD'), 3);
      });

      test('returns 2 for unknown currency (default)', () {
        expect(Iso4217Precision.getDecimalPlaces('XXX'), 2);
        expect(Iso4217Precision.getDecimalPlaces('UNKNOWN'), 2);
      });

      test('is case insensitive', () {
        expect(Iso4217Precision.getDecimalPlaces('usd'), 2);
        expect(Iso4217Precision.getDecimalPlaces('Usd'), 2);
        expect(Iso4217Precision.getDecimalPlaces('vnd'), 0);
      });
    });

    group('isZeroDecimalCurrency', () {
      test('returns true for VND', () {
        expect(Iso4217Precision.isZeroDecimalCurrency('VND'), true);
      });

      test('returns true for JPY', () {
        expect(Iso4217Precision.isZeroDecimalCurrency('JPY'), true);
      });

      test('returns false for USD', () {
        expect(Iso4217Precision.isZeroDecimalCurrency('USD'), false);
      });

      test('returns false for unknown currency', () {
        expect(Iso4217Precision.isZeroDecimalCurrency('XXX'), false);
      });
    });

    group('isThreeDecimalCurrency', () {
      test('returns true for BHD', () {
        expect(Iso4217Precision.isThreeDecimalCurrency('BHD'), true);
      });

      test('returns true for KWD', () {
        expect(Iso4217Precision.isThreeDecimalCurrency('KWD'), true);
      });

      test('returns false for USD', () {
        expect(Iso4217Precision.isThreeDecimalCurrency('USD'), false);
      });

      test('returns false for VND', () {
        expect(Iso4217Precision.isThreeDecimalCurrency('VND'), false);
      });
    });

    group('supportedCurrencies', () {
      test('returns sorted list of currency codes', () {
        final currencies = Iso4217Precision.supportedCurrencies;

        expect(currencies, isNotEmpty);
        expect(currencies, contains('USD'));
        expect(currencies, contains('EUR'));
        expect(currencies, contains('VND'));
        expect(currencies, contains('JPY'));
        expect(currencies, contains('BHD'));

        // Verify sorted
        final sorted = List<String>.from(currencies)..sort();
        expect(currencies, sorted);
      });
    });
  });
}
