import 'package:flutter_test/flutter_test.dart';
import 'package:decimal/decimal.dart';
import 'package:expense_tracker/core/services/decimal_service.dart';
import 'package:expense_tracker/features/expenses/domain/models/rounding_mode.dart';

void main() {
  group('DecimalService', () {
    group('round', () {
      test('rounds USD to 2 decimal places with roundHalfUp', () {
        final result = DecimalService.round(
          Decimal.parse('1.235'),
          'USD',
          RoundingMode.roundHalfUp,
        );
        expect(result, Decimal.parse('1.24'));
      });

      test('rounds VND to 0 decimal places with roundHalfUp', () {
        final result = DecimalService.round(
          Decimal.parse('1000.7'),
          'VND',
          RoundingMode.roundHalfUp,
        );
        expect(result, Decimal.parse('1001'));
      });

      test('rounds VND down when fraction < 0.5', () {
        final result = DecimalService.round(
          Decimal.parse('1000.4'),
          'VND',
          RoundingMode.roundHalfUp,
        );
        expect(result, Decimal.parse('1000'));
      });
    });

    group('roundToPlaces - roundHalfUp', () {
      test('rounds 1.235 to 2 places → 1.24', () {
        final result = DecimalService.roundToPlaces(
          Decimal.parse('1.235'),
          2,
          RoundingMode.roundHalfUp,
        );
        expect(result, Decimal.parse('1.24'));
      });

      test('rounds 1.234 to 2 places → 1.23', () {
        final result = DecimalService.roundToPlaces(
          Decimal.parse('1.234'),
          2,
          RoundingMode.roundHalfUp,
        );
        expect(result, Decimal.parse('1.23'));
      });

      test('rounds 1.9 to 0 places → 2', () {
        final result = DecimalService.roundToPlaces(
          Decimal.parse('1.9'),
          0,
          RoundingMode.roundHalfUp,
        );
        expect(result, Decimal.parse('2'));
      });

      test('rounds 1.4 to 0 places → 1', () {
        final result = DecimalService.roundToPlaces(
          Decimal.parse('1.4'),
          0,
          RoundingMode.roundHalfUp,
        );
        expect(result, Decimal.parse('1'));
      });
    });

    group('roundToPlaces - roundHalfEven', () {
      test('rounds 1.235 to 2 places → 1.24 (even)', () {
        final result = DecimalService.roundToPlaces(
          Decimal.parse('1.235'),
          2,
          RoundingMode.roundHalfEven,
        );
        expect(result, Decimal.parse('1.24'));
      });

      test('rounds 1.245 to 2 places → 1.24 (even)', () {
        final result = DecimalService.roundToPlaces(
          Decimal.parse('1.245'),
          2,
          RoundingMode.roundHalfEven,
        );
        expect(result, Decimal.parse('1.24'));
      });

      test('rounds 1.5 to 0 places → 2 (even)', () {
        final result = DecimalService.roundToPlaces(
          Decimal.parse('1.5'),
          0,
          RoundingMode.roundHalfEven,
        );
        expect(result, Decimal.parse('2'));
      });

      test('rounds 2.5 to 0 places → 2 (even)', () {
        final result = DecimalService.roundToPlaces(
          Decimal.parse('2.5'),
          0,
          RoundingMode.roundHalfEven,
        );
        expect(result, Decimal.parse('2'));
      });
    });

    group('roundToPlaces - floor', () {
      test('rounds 1.239 to 2 places → 1.23 (down)', () {
        final result = DecimalService.roundToPlaces(
          Decimal.parse('1.239'),
          2,
          RoundingMode.floor,
        );
        expect(result, Decimal.parse('1.23'));
      });

      test('rounds 1.999 to 2 places → 1.99 (down)', () {
        final result = DecimalService.roundToPlaces(
          Decimal.parse('1.999'),
          2,
          RoundingMode.floor,
        );
        expect(result, Decimal.parse('1.99'));
      });

      test('rounds 1.9 to 0 places → 1 (down)', () {
        final result = DecimalService.roundToPlaces(
          Decimal.parse('1.9'),
          0,
          RoundingMode.floor,
        );
        expect(result, Decimal.parse('1'));
      });
    });

    group('roundToPlaces - ceil', () {
      test('rounds 1.231 to 2 places → 1.24 (up)', () {
        final result = DecimalService.roundToPlaces(
          Decimal.parse('1.231'),
          2,
          RoundingMode.ceil,
        );
        expect(result, Decimal.parse('1.24'));
      });

      test('rounds 1.001 to 2 places → 1.01 (up)', () {
        final result = DecimalService.roundToPlaces(
          Decimal.parse('1.001'),
          2,
          RoundingMode.ceil,
        );
        expect(result, Decimal.parse('1.01'));
      });

      test('rounds 1.1 to 0 places → 2 (up)', () {
        final result = DecimalService.roundToPlaces(
          Decimal.parse('1.1'),
          0,
          RoundingMode.ceil,
        );
        expect(result, Decimal.parse('2'));
      });
    });

    group('getCurrencyPrecision', () {
      test('returns 2 for USD', () {
        expect(DecimalService.getCurrencyPrecision('USD'), 2);
      });

      test('returns 0 for VND', () {
        expect(DecimalService.getCurrencyPrecision('VND'), 0);
      });

      test('returns 3 for BHD', () {
        expect(DecimalService.getCurrencyPrecision('BHD'), 3);
      });
    });

    group('areEqualWithinPrecision', () {
      test('returns true for values equal within USD precision', () {
        final result = DecimalService.areEqualWithinPrecision(
          Decimal.parse('10.00'),
          Decimal.parse('10.001'),
          'USD',
        );
        expect(result, true);
      });

      test('returns false for values not equal within USD precision', () {
        final result = DecimalService.areEqualWithinPrecision(
          Decimal.parse('10.00'),
          Decimal.parse('10.02'),
          'USD',
        );
        expect(result, false);
      });

      test('returns true for values equal within VND precision', () {
        final result = DecimalService.areEqualWithinPrecision(
          Decimal.parse('1000'),
          Decimal.parse('1000.9'),
          'VND',
        );
        expect(result, true);
      });

      test('returns false for values not equal within VND precision', () {
        final result = DecimalService.areEqualWithinPrecision(
          Decimal.parse('1000'),
          Decimal.parse('1002'),
          'VND',
        );
        expect(result, false);
      });
    });

    group('formatForCurrency', () {
      test('formats USD with 2 decimal places', () {
        final result = DecimalService.formatForCurrency(
          Decimal.parse('10.5'),
          'USD',
        );
        expect(result, '10.50');
      });

      test('formats VND with 0 decimal places', () {
        final result = DecimalService.formatForCurrency(
          Decimal.parse('10000.7'),
          'VND',
        );
        expect(result, '10001');
      });

      test('formats BHD with 3 decimal places', () {
        final result = DecimalService.formatForCurrency(
          Decimal.parse('10.5'),
          'BHD',
        );
        expect(result, '10.500');
      });
    });
  });
}
