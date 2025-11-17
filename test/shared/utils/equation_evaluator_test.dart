import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/shared/utils/equation_evaluator.dart';

void main() {
  group('EquationEvaluator', () {
    group('evaluate()', () {
      test('should parse simple number', () {
        expect(
          EquationEvaluator.evaluate('100'),
          equals(Decimal.fromInt(100)),
        );
      });

      test('should parse decimal number', () {
        expect(
          EquationEvaluator.evaluate('100.50'),
          equals(Decimal.parse('100.50')),
        );
      });

      test('should handle addition', () {
        expect(
          EquationEvaluator.evaluate('100+50'),
          equals(Decimal.fromInt(150)),
        );
      });

      test('should handle subtraction', () {
        expect(
          EquationEvaluator.evaluate('100-50'),
          equals(Decimal.fromInt(50)),
        );
      });

      test('should handle multiplication', () {
        expect(
          EquationEvaluator.evaluate('100*2'),
          equals(Decimal.fromInt(200)),
        );
      });

      test('should handle percentage addition', () {
        expect(
          EquationEvaluator.evaluate('100+10%'),
          equals(Decimal.fromInt(110)),
        );
      });

      test('should handle percentage subtraction', () {
        expect(
          EquationEvaluator.evaluate('100-10%'),
          equals(Decimal.fromInt(90)),
        );
      });

      test('should handle order of operations (multiply before add)', () {
        expect(
          EquationEvaluator.evaluate('10+5*2'),
          equals(Decimal.fromInt(20)),
        );
      });

      test('should handle complex equation with multiple operations', () {
        expect(
          EquationEvaluator.evaluate('100+50-20'),
          equals(Decimal.fromInt(130)),
        );
      });

      test('should handle equation with decimals', () {
        expect(
          EquationEvaluator.evaluate('100.50+49.50'),
          equals(Decimal.fromInt(150)),
        );
      });

      test('should handle equation with commas', () {
        expect(
          EquationEvaluator.evaluate('1,000+500'),
          equals(Decimal.fromInt(1500)),
        );
      });

      test('should handle whitespace', () {
        expect(
          EquationEvaluator.evaluate(' 100 + 50 '),
          equals(Decimal.fromInt(150)),
        );
      });

      test('should return null for empty string', () {
        expect(EquationEvaluator.evaluate(''), isNull);
      });

      test('should return null for invalid input', () {
        expect(EquationEvaluator.evaluate('abc'), isNull);
      });

      test('should return null for malformed equation', () {
        expect(EquationEvaluator.evaluate('100++50'), isNull);
      });

      test('should handle percentage in middle of equation', () {
        expect(
          EquationEvaluator.evaluate('100+10%+20'),
          equals(Decimal.fromInt(30)),
        );
      });

      test('should handle multiple multiplications', () {
        expect(
          EquationEvaluator.evaluate('2*3*4'),
          equals(Decimal.fromInt(24)),
        );
      });

      test('should handle mixed operations', () {
        expect(
          EquationEvaluator.evaluate('100+50*2-25'),
          equals(Decimal.fromInt(175)),
        );
      });
    });

    group('isValidEquation()', () {
      test('should return true for simple number', () {
        expect(EquationEvaluator.isValidEquation('100'), isTrue);
      });

      test('should return true for valid equation', () {
        expect(EquationEvaluator.isValidEquation('100+50'), isTrue);
      });

      test('should return true for equation with all operators', () {
        expect(EquationEvaluator.isValidEquation('100+50-20*2'), isTrue);
      });

      test('should return false for empty string', () {
        expect(EquationEvaluator.isValidEquation(''), isFalse);
      });

      test('should return false for invalid characters', () {
        expect(EquationEvaluator.isValidEquation('abc'), isFalse);
      });

      test('should return false for malformed equation', () {
        expect(EquationEvaluator.isValidEquation('100++50'), isFalse);
      });

      test('should return true for equation with commas', () {
        expect(EquationEvaluator.isValidEquation('1,000+500'), isTrue);
      });

      test('should return true for equation with whitespace', () {
        expect(EquationEvaluator.isValidEquation(' 100 + 50 '), isTrue);
      });
    });
  });
}
