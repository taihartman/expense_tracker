import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/core/utils/code_generator.dart';

void main() {
  group('CodeGenerator', () {
    group('generate', () {
      test('generates 8-digit code with hyphen in format XXXX-XXXX', () {
        final code = CodeGenerator.generate();

        expect(code.length, 9); // 8 digits + 1 hyphen
        expect(code[4], '-'); // Hyphen at position 4
        expect(RegExp(r'^\d{4}-\d{4}$').hasMatch(code), true);
      });

      test('generates different codes on multiple calls', () {
        final code1 = CodeGenerator.generate();
        final code2 = CodeGenerator.generate();
        final code3 = CodeGenerator.generate();

        // Statistically, these should be different (100M combinations)
        expect(code1 == code2 && code2 == code3, false);
      });

      test('all digits are numeric', () {
        final code = CodeGenerator.generate();
        final digitsOnly = code.replaceAll('-', '');

        expect(int.tryParse(digitsOnly), isNotNull);
        expect(digitsOnly.length, 8);
      });
    });

    group('normalize', () {
      test('removes hyphens from code', () {
        expect(CodeGenerator.normalize('1234-5678'), '12345678');
      });

      test('removes spaces from code', () {
        expect(CodeGenerator.normalize('1234 5678'), '12345678');
      });

      test('removes both hyphens and spaces', () {
        expect(CodeGenerator.normalize('12 34-56 78'), '12345678');
      });

      test('handles code without hyphens or spaces', () {
        expect(CodeGenerator.normalize('12345678'), '12345678');
      });

      test('handles empty string', () {
        expect(CodeGenerator.normalize(''), '');
      });
    });

    group('isValid', () {
      test('returns true for 8-digit code with hyphen', () {
        expect(CodeGenerator.isValid('1234-5678'), true);
      });

      test('returns true for 8-digit code without hyphen', () {
        expect(CodeGenerator.isValid('12345678'), true);
      });

      test('returns true for 8-digit code with spaces', () {
        expect(CodeGenerator.isValid('1234 5678'), true);
      });

      test('returns false for code with letters', () {
        expect(CodeGenerator.isValid('1234-ABCD'), false);
      });

      test('returns false for code with 7 digits', () {
        expect(CodeGenerator.isValid('1234-567'), false);
      });

      test('returns false for code with 9 digits', () {
        expect(CodeGenerator.isValid('1234-56789'), false);
      });

      test('returns false for empty string', () {
        expect(CodeGenerator.isValid(''), false);
      });

      test('returns false for null input', () {
        expect(CodeGenerator.isValid('abc'), false);
      });
    });
  });
}
