import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/categories/domain/models/category.dart';

void main() {
  group('Category Model', () {
    final now = DateTime(2025, 10, 31, 12, 0, 0);

    group('creation', () {
      test('creates category with all required fields', () {
        final category = Category(
          id: 'cat1',
          name: 'Meals',
          icon: 'restaurant',
          color: '#FF5722',
          createdAt: now,
          updatedAt: now,
        );

        expect(category.id, 'cat1');
        expect(category.name, 'Meals');
        expect(category.nameLowercase, 'meals'); // Auto-generated
        expect(category.icon, 'restaurant');
        expect(category.color, '#FF5722');
        expect(category.usageCount, 0); // Default value
        expect(category.createdAt, now);
        expect(category.updatedAt, now);
      });

      test('creates category with explicit nameLowercase', () {
        final category = Category(
          id: 'cat1',
          name: 'MEALS',
          nameLowercase: 'meals',
          icon: 'restaurant',
          color: '#FF5722',
          createdAt: now,
          updatedAt: now,
        );

        expect(category.name, 'MEALS');
        expect(category.nameLowercase, 'meals');
      });

      test('creates category with custom usage count', () {
        final category = Category(
          id: 'cat1',
          name: 'Meals',
          icon: 'restaurant',
          color: '#FF5722',
          usageCount: 42,
          createdAt: now,
          updatedAt: now,
        );

        expect(category.usageCount, 42);
      });

      test('uses default icon if not provided', () {
        final category = Category(
          id: 'cat1',
          name: 'Custom',
          color: '#FF5722',
          createdAt: now,
          updatedAt: now,
        );

        expect(category.icon, 'label'); // Default value
      });

      test('auto-generates nameLowercase from name', () {
        final category = Category(
          id: 'cat1',
          name: 'Food & Drinks',
          icon: 'restaurant',
          color: '#FF5722',
          createdAt: now,
          updatedAt: now,
        );

        expect(category.nameLowercase, 'food & drinks');
      });

      test('handles mixed-case names correctly', () {
        final category = Category(
          id: 'cat1',
          name: 'Year-End PARTY',
          icon: 'celebration',
          color: '#FF5722',
          createdAt: now,
          updatedAt: now,
        );

        expect(category.name, 'Year-End PARTY');
        expect(category.nameLowercase, 'year-end party');
      });
    });

    group('incrementUsage', () {
      test('increments usage count by 1', () {
        final original = Category(
          id: 'cat1',
          name: 'Meals',
          icon: 'restaurant',
          color: '#FF5722',
          usageCount: 5,
          createdAt: now,
          updatedAt: now,
        );

        final incremented = original.incrementUsage();

        expect(incremented.usageCount, 6);
        expect(incremented.id, original.id);
        expect(incremented.name, original.name);
      });

      test('preserves all other fields when incrementing', () {
        final original = Category(
          id: 'cat1',
          name: 'Meals',
          icon: 'restaurant',
          color: '#FF5722',
          usageCount: 5,
          createdAt: now,
          updatedAt: now,
        );

        final incremented = original.incrementUsage();

        expect(incremented.id, original.id);
        expect(incremented.name, original.name);
        expect(incremented.nameLowercase, original.nameLowercase);
        expect(incremented.icon, original.icon);
        expect(incremented.color, original.color);
        expect(incremented.createdAt, original.createdAt);
      });

      test('can increment multiple times', () {
        final original = Category(
          id: 'cat1',
          name: 'Meals',
          icon: 'restaurant',
          color: '#FF5722',
          usageCount: 0,
          createdAt: now,
          updatedAt: now,
        );

        final first = original.incrementUsage();
        final second = first.incrementUsage();
        final third = second.incrementUsage();

        expect(third.usageCount, 3);
      });
    });

    group('copyWith', () {
      final original = Category(
        id: 'cat1',
        name: 'Meals',
        icon: 'restaurant',
        color: '#FF5722',
        usageCount: 5,
        createdAt: now,
        updatedAt: now,
      );

      test('copies with new name', () {
        final copy = original.copyWith(name: 'Food');

        expect(copy.name, 'Food');
        expect(copy.id, original.id);
        expect(copy.icon, original.icon);
        expect(copy.color, original.color);
        expect(copy.usageCount, original.usageCount);
      });

      test('copies with new icon', () {
        final copy = original.copyWith(icon: 'fastfood');

        expect(copy.icon, 'fastfood');
        expect(copy.name, original.name);
      });

      test('copies with new color', () {
        final copy = original.copyWith(color: '#2196F3');

        expect(copy.color, '#2196F3');
        expect(copy.name, original.name);
      });

      test('copies with new usage count', () {
        final copy = original.copyWith(usageCount: 100);

        expect(copy.usageCount, 100);
        expect(copy.name, original.name);
      });

      test('copies with new timestamps', () {
        final newDate = DateTime(2025, 11, 1);
        final copy = original.copyWith(createdAt: newDate, updatedAt: newDate);

        expect(copy.createdAt, newDate);
        expect(copy.updatedAt, newDate);
      });

      test('returns identical category when no changes', () {
        final copy = original.copyWith();

        expect(copy.id, original.id);
        expect(copy.name, original.name);
        expect(copy.nameLowercase, original.nameLowercase);
        expect(copy.icon, original.icon);
        expect(copy.color, original.color);
        expect(copy.usageCount, original.usageCount);
        expect(copy.createdAt, original.createdAt);
        expect(copy.updatedAt, original.updatedAt);
      });
    });

    group('equality', () {
      final category1 = Category(
        id: 'cat1',
        name: 'Meals',
        icon: 'restaurant',
        color: '#FF5722',
        usageCount: 5,
        createdAt: now,
        updatedAt: now,
      );

      final category2 = Category(
        id: 'cat1',
        name: 'Meals',
        icon: 'restaurant',
        color: '#FF5722',
        usageCount: 5,
        createdAt: now,
        updatedAt: now,
      );

      final category3 = Category(
        id: 'cat2', // Different ID
        name: 'Meals',
        icon: 'restaurant',
        color: '#FF5722',
        usageCount: 5,
        createdAt: now,
        updatedAt: now,
      );

      test('equal categories have same properties', () {
        expect(category1 == category2, isTrue);
      });

      test('different IDs make categories unequal', () {
        expect(category1 == category3, isFalse);
      });

      test('equal categories have same hashCode', () {
        expect(category1.hashCode, category2.hashCode);
      });

      test('different categories have different hashCode', () {
        expect(category1.hashCode, isNot(category3.hashCode));
      });
    });

    group('edge cases', () {
      test('handles empty name with lowercase generation', () {
        final category = Category(
          id: 'cat1',
          name: '',
          icon: 'label',
          color: '#FF5722',
          createdAt: now,
          updatedAt: now,
        );

        expect(category.nameLowercase, '');
      });

      test('handles Unicode characters in name', () {
        final category = Category(
          id: 'cat1',
          name: 'Café & Bäckerei',
          icon: 'restaurant',
          color: '#FF5722',
          createdAt: now,
          updatedAt: now,
        );

        expect(category.nameLowercase, 'café & bäckerei');
      });

      test('handles very large usage count', () {
        final category = Category(
          id: 'cat1',
          name: 'Popular',
          icon: 'star',
          color: '#FF5722',
          usageCount: 999999,
          createdAt: now,
          updatedAt: now,
        );

        expect(category.usageCount, 999999);

        final incremented = category.incrementUsage();
        expect(incremented.usageCount, 1000000);
      });

      test('handles category with all special allowed characters', () {
        final category = Category(
          id: 'cat1',
          name: "Mom's Year-End Party & Celebration",
          icon: 'celebration',
          color: '#FF5722',
          createdAt: now,
          updatedAt: now,
        );

        expect(category.name, "Mom's Year-End Party & Celebration");
        expect(category.nameLowercase, "mom's year-end party & celebration");
      });
    });
  });
}
