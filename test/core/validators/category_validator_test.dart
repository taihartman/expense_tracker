import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/core/validators/category_validator.dart';

void main() {
  group('CategoryValidator', () {
    group('validateCategoryName', () {
      group('valid names', () {
        test('accepts simple alphanumeric name', () {
          expect(CategoryValidator.validateCategoryName('Meals'), isNull);
          expect(CategoryValidator.validateCategoryName('Transport'), isNull);
          expect(CategoryValidator.validateCategoryName('Activities123'), isNull);
        });

        test('accepts name with spaces', () {
          expect(CategoryValidator.validateCategoryName('Food and Drinks'), isNull);
          expect(CategoryValidator.validateCategoryName('Year End Party'), isNull);
        });

        test('accepts name with apostrophes', () {
          expect(CategoryValidator.validateCategoryName("Mom's Birthday"), isNull);
          expect(CategoryValidator.validateCategoryName("New Year's Eve"), isNull);
        });

        test('accepts name with hyphens', () {
          expect(CategoryValidator.validateCategoryName('Year-End Party'), isNull);
          expect(CategoryValidator.validateCategoryName('Follow-up Meeting'), isNull);
        });

        test('accepts name with ampersands', () {
          expect(CategoryValidator.validateCategoryName('Food & Drinks'), isNull);
          expect(CategoryValidator.validateCategoryName('Mom & Dad'), isNull);
        });

        test('accepts name with all allowed special characters', () {
          expect(
            CategoryValidator.validateCategoryName("Mom's Year-End Party & Celebration"),
            isNull,
          );
        });

        test('accepts Unicode letters', () {
          expect(CategoryValidator.validateCategoryName('Café'), isNull);
          expect(CategoryValidator.validateCategoryName('Bäckerei'), isNull);
          expect(CategoryValidator.validateCategoryName('日本料理'), isNull);
          expect(CategoryValidator.validateCategoryName('Πάρτυ'), isNull);
        });

        test('accepts single character name', () {
          expect(CategoryValidator.validateCategoryName('A'), isNull);
          expect(CategoryValidator.validateCategoryName('1'), isNull);
        });

        test('accepts 50 character name (max length)', () {
          final fiftyChars = 'A' * 50;
          expect(CategoryValidator.validateCategoryName(fiftyChars), isNull);
        });

        test('accepts mixed case names', () {
          expect(CategoryValidator.validateCategoryName('MeAlS'), isNull);
          expect(CategoryValidator.validateCategoryName('TRANSPORT'), isNull);
          expect(CategoryValidator.validateCategoryName('activities'), isNull);
        });
      });

      group('invalid names - empty', () {
        test('rejects empty string', () {
          final result = CategoryValidator.validateCategoryName('');
          expect(result, contains('cannot be empty'));
        });

        test('rejects whitespace-only string', () {
          final result = CategoryValidator.validateCategoryName('   ');
          expect(result, contains('cannot be empty'));
        });

        test('rejects tabs and newlines', () {
          final result = CategoryValidator.validateCategoryName('\t\n');
          expect(result, contains('cannot be empty'));
        });
      });

      group('invalid names - length', () {
        test('rejects 51 character name (over max)', () {
          final fiftyOneChars = 'A' * 51;
          final result = CategoryValidator.validateCategoryName(fiftyOneChars);
          expect(result, contains('between 1 and 50 characters'));
        });

        test('rejects very long name', () {
          final veryLong = 'A' * 100;
          final result = CategoryValidator.validateCategoryName(veryLong);
          expect(result, contains('between 1 and 50 characters'));
        });
      });

      group('invalid names - forbidden characters', () {
        test('rejects emoji', () {
          final result = CategoryValidator.validateCategoryName('Café ☕');
          expect(result, contains('can only contain'));
        });

        test('rejects special symbols', () {
          expect(
            CategoryValidator.validateCategoryName('Meals@Home'),
            contains('can only contain'),
          );
          expect(
            CategoryValidator.validateCategoryName('Meals#1'),
            contains('can only contain'),
          );
          expect(
            CategoryValidator.validateCategoryName('Meals\$'),
            contains('can only contain'),
          );
          expect(
            CategoryValidator.validateCategoryName('Meals%'),
            contains('can only contain'),
          );
        });

        test('rejects punctuation (except allowed)', () {
          expect(
            CategoryValidator.validateCategoryName('Meals.'),
            contains('can only contain'),
          );
          expect(
            CategoryValidator.validateCategoryName('Meals!'),
            contains('can only contain'),
          );
          expect(
            CategoryValidator.validateCategoryName('Meals?'),
            contains('can only contain'),
          );
          expect(
            CategoryValidator.validateCategoryName('Meals,'),
            contains('can only contain'),
          );
        });

        test('rejects brackets', () {
          expect(
            CategoryValidator.validateCategoryName('Meals[Special]'),
            contains('can only contain'),
          );
          expect(
            CategoryValidator.validateCategoryName('Meals(Special)'),
            contains('can only contain'),
          );
        });

        test('rejects forward/backward slashes', () {
          expect(
            CategoryValidator.validateCategoryName('Meals/Drinks'),
            contains('can only contain'),
          );
          expect(
            CategoryValidator.validateCategoryName('Meals\\Drinks'),
            contains('can only contain'),
          );
        });
      });
    });

    group('isValid', () {
      test('returns true for valid names', () {
        expect(CategoryValidator.isValid('Meals'), isTrue);
        expect(CategoryValidator.isValid("Mom's Birthday"), isTrue);
        expect(CategoryValidator.isValid('Year-End Party'), isTrue);
        expect(CategoryValidator.isValid('Food & Drinks'), isTrue);
      });

      test('returns false for invalid names', () {
        expect(CategoryValidator.isValid(''), isFalse);
        expect(CategoryValidator.isValid('   '), isFalse);
        expect(CategoryValidator.isValid('Café ☕'), isFalse);
        expect(CategoryValidator.isValid('A' * 51), isFalse);
        expect(CategoryValidator.isValid('Meals@Home'), isFalse);
      });
    });

    group('sanitize', () {
      test('converts to lowercase', () {
        expect(CategoryValidator.sanitize('MEALS'), 'meals');
        expect(CategoryValidator.sanitize('MeAlS'), 'meals');
        expect(CategoryValidator.sanitize('meals'), 'meals');
      });

      test('trims whitespace', () {
        expect(CategoryValidator.sanitize('  Meals  '), 'meals');
        expect(CategoryValidator.sanitize('\tMeals\n'), 'meals');
        expect(CategoryValidator.sanitize('  Food & Drinks  '), 'food & drinks');
      });

      test('preserves special allowed characters', () {
        expect(CategoryValidator.sanitize("Mom's Birthday"), "mom's birthday");
        expect(CategoryValidator.sanitize('Year-End Party'), 'year-end party');
        expect(CategoryValidator.sanitize('Food & Drinks'), 'food & drinks');
      });

      test('handles Unicode characters', () {
        expect(CategoryValidator.sanitize('Café'), 'café');
        expect(CategoryValidator.sanitize('CAFÉ'), 'café');
      });

      test('handles empty string', () {
        expect(CategoryValidator.sanitize(''), '');
        expect(CategoryValidator.sanitize('   '), '');
      });
    });

    group('areDuplicates', () {
      test('returns true for exact matches (case-insensitive)', () {
        expect(CategoryValidator.areDuplicates('Meals', 'meals'), isTrue);
        expect(CategoryValidator.areDuplicates('MEALS', 'meals'), isTrue);
        expect(CategoryValidator.areDuplicates('MeAlS', 'meals'), isTrue);
      });

      test('returns true for matches with different whitespace', () {
        expect(CategoryValidator.areDuplicates('  Meals  ', 'meals'), isTrue);
        expect(CategoryValidator.areDuplicates('Meals', '  Meals  '), isTrue);
      });

      test('returns false for different names', () {
        expect(CategoryValidator.areDuplicates('Meals', 'Transport'), isFalse);
        expect(CategoryValidator.areDuplicates('Meals', 'Meal Plan'), isFalse);
        expect(CategoryValidator.areDuplicates('Food', 'Food & Drinks'), isFalse);
      });

      test('handles special characters', () {
        expect(
          CategoryValidator.areDuplicates("Mom's Birthday", "MOM'S BIRTHDAY"),
          isTrue,
        );
        expect(
          CategoryValidator.areDuplicates('Year-End Party', 'YEAR-END PARTY'),
          isTrue,
        );
        expect(
          CategoryValidator.areDuplicates('Food & Drinks', 'FOOD & DRINKS'),
          isTrue,
        );
      });

      test('handles Unicode characters', () {
        expect(CategoryValidator.areDuplicates('Café', 'café'), isTrue);
        expect(CategoryValidator.areDuplicates('CAFÉ', 'café'), isTrue);
      });

      test('handles empty strings', () {
        expect(CategoryValidator.areDuplicates('', ''), isTrue);
        expect(CategoryValidator.areDuplicates('   ', ''), isTrue);
        expect(CategoryValidator.areDuplicates('', '   '), isTrue);
      });
    });

    group('constants', () {
      test('minLength is 1', () {
        expect(CategoryValidator.minLength, 1);
      });

      test('maxLength is 50', () {
        expect(CategoryValidator.maxLength, 50);
      });
    });

    group('edge cases', () {
      test('handles name with only allowed special characters', () {
        final result = CategoryValidator.validateCategoryName("'-&");
        expect(result, isNull);
      });

      test('handles name with multiple consecutive spaces', () {
        final result = CategoryValidator.validateCategoryName('Food    and    Drinks');
        expect(result, isNull);
      });

      test('handles name starting with number', () {
        expect(CategoryValidator.validateCategoryName('123 Main St'), isNull);
        expect(CategoryValidator.validateCategoryName('2024 Expenses'), isNull);
      });

      test('handles name with only numbers', () {
        expect(CategoryValidator.validateCategoryName('123'), isNull);
        expect(CategoryValidator.validateCategoryName('2024'), isNull);
      });

      test('sanitize handles very long name', () {
        final longName = 'A' * 100;
        final sanitized = CategoryValidator.sanitize(longName);
        expect(sanitized, longName.toLowerCase());
      });

      test('areDuplicates is symmetric', () {
        expect(
          CategoryValidator.areDuplicates('Meals', 'MEALS'),
          CategoryValidator.areDuplicates('MEALS', 'Meals'),
        );
        expect(
          CategoryValidator.areDuplicates('Food', 'Transport'),
          CategoryValidator.areDuplicates('Transport', 'Food'),
        );
      });
    });
  });
}
