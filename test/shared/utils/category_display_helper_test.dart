import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/shared/utils/category_display_helper.dart';
import 'package:expense_tracker/features/categories/domain/models/category.dart';
import 'package:expense_tracker/core/models/category_customization.dart';

void main() {
  group('DisplayCategory', () {
    final now = DateTime(2025, 10, 31, 12, 0, 0);

    final globalCategory = Category(
      id: 'cat-1',
      name: 'Meals',
      icon: 'restaurant',
      color: '#FF5722',
      usageCount: 100,
      createdAt: now,
      updatedAt: now,
    );

    group('fromGlobalAndCustomization', () {
      test('should use global category values when no customization provided',
          () {
        // Act
        final result = DisplayCategory.fromGlobalAndCustomization(
          globalCategory: globalCategory,
          customization: null,
        );

        // Assert
        expect(result.id, 'cat-1');
        expect(result.name, 'Meals');
        expect(result.icon, 'restaurant');
        expect(result.color, '#FF5722');
        expect(result.isCustomized, isFalse);
      });

      test('should override icon when customization has customIcon', () {
        // Arrange
        final customization = CategoryCustomization(
          categoryId: 'cat-1',
          tripId: 'trip-123',
          customIcon: 'fastfood',
          updatedAt: now,
        );

        // Act
        final result = DisplayCategory.fromGlobalAndCustomization(
          globalCategory: globalCategory,
          customization: customization,
        );

        // Assert
        expect(result.id, 'cat-1');
        expect(result.name, 'Meals');
        expect(result.icon, 'fastfood'); // Overridden
        expect(result.color, '#FF5722'); // Global value
        expect(result.isCustomized, isTrue);
      });

      test('should override color when customization has customColor', () {
        // Arrange
        final customization = CategoryCustomization(
          categoryId: 'cat-1',
          tripId: 'trip-123',
          customColor: '#2196F3',
          updatedAt: now,
        );

        // Act
        final result = DisplayCategory.fromGlobalAndCustomization(
          globalCategory: globalCategory,
          customization: customization,
        );

        // Assert
        expect(result.id, 'cat-1');
        expect(result.name, 'Meals');
        expect(result.icon, 'restaurant'); // Global value
        expect(result.color, '#2196F3'); // Overridden
        expect(result.isCustomized, isTrue);
      });

      test(
          'should override both icon and color when customization has both',
          () {
        // Arrange
        final customization = CategoryCustomization(
          categoryId: 'cat-1',
          tripId: 'trip-123',
          customIcon: 'local_pizza',
          customColor: '#9C27B0',
          updatedAt: now,
        );

        // Act
        final result = DisplayCategory.fromGlobalAndCustomization(
          globalCategory: globalCategory,
          customization: customization,
        );

        // Assert
        expect(result.id, 'cat-1');
        expect(result.name, 'Meals');
        expect(result.icon, 'local_pizza'); // Overridden
        expect(result.color, '#9C27B0'); // Overridden
        expect(result.isCustomized, isTrue);
      });

      test('should always use global category name (name cannot be customized)',
          () {
        // Arrange
        final customization = CategoryCustomization(
          categoryId: 'cat-1',
          tripId: 'trip-123',
          customIcon: 'fastfood',
          customColor: '#2196F3',
          updatedAt: now,
        );

        // Act
        final result = DisplayCategory.fromGlobalAndCustomization(
          globalCategory: globalCategory,
          customization: customization,
        );

        // Assert
        expect(result.name, 'Meals'); // Always from global category
      });

      test('should preserve category ID from global category', () {
        // Arrange
        final customization = CategoryCustomization(
          categoryId: 'cat-1',
          tripId: 'trip-123',
          customIcon: 'fastfood',
          updatedAt: now,
        );

        // Act
        final result = DisplayCategory.fromGlobalAndCustomization(
          globalCategory: globalCategory,
          customization: customization,
        );

        // Assert
        expect(result.id, globalCategory.id);
      });

      test('should handle empty customization (no icon, no color)', () {
        // Arrange
        final customization = CategoryCustomization(
          categoryId: 'cat-1',
          tripId: 'trip-123',
          updatedAt: now,
        );

        // Act
        final result = DisplayCategory.fromGlobalAndCustomization(
          globalCategory: globalCategory,
          customization: customization,
        );

        // Assert
        expect(result.icon, 'restaurant'); // Global value
        expect(result.color, '#FF5722'); // Global value
        expect(result.isCustomized, isFalse);
      });

      test('should set isCustomized to true only when hasCustomization is true',
          () {
        // Arrange
        final noCustomization = CategoryCustomization(
          categoryId: 'cat-1',
          tripId: 'trip-123',
          updatedAt: now,
        );

        final iconCustomization = CategoryCustomization(
          categoryId: 'cat-1',
          tripId: 'trip-123',
          customIcon: 'fastfood',
          updatedAt: now,
        );

        final colorCustomization = CategoryCustomization(
          categoryId: 'cat-1',
          tripId: 'trip-123',
          customColor: '#2196F3',
          updatedAt: now,
        );

        // Act & Assert
        expect(
          DisplayCategory.fromGlobalAndCustomization(
            globalCategory: globalCategory,
            customization: noCustomization,
          ).isCustomized,
          isFalse,
        );

        expect(
          DisplayCategory.fromGlobalAndCustomization(
            globalCategory: globalCategory,
            customization: iconCustomization,
          ).isCustomized,
          isTrue,
        );

        expect(
          DisplayCategory.fromGlobalAndCustomization(
            globalCategory: globalCategory,
            customization: colorCustomization,
          ).isCustomized,
          isTrue,
        );
      });

      test(
          'should work with different global categories (different icons/colors)',
          () {
        // Arrange
        final transportCategory = Category(
          id: 'cat-2',
          name: 'Transport',
          icon: 'directions_car',
          color: '#2196F3',
          usageCount: 50,
          createdAt: now,
          updatedAt: now,
        );

        final customization = CategoryCustomization(
          categoryId: 'cat-2',
          tripId: 'trip-123',
          customIcon: 'directions_bus',
          customColor: '#4CAF50',
          updatedAt: now,
        );

        // Act
        final result = DisplayCategory.fromGlobalAndCustomization(
          globalCategory: transportCategory,
          customization: customization,
        );

        // Assert
        expect(result.id, 'cat-2');
        expect(result.name, 'Transport');
        expect(result.icon, 'directions_bus');
        expect(result.color, '#4CAF50');
        expect(result.isCustomized, isTrue);
      });
    });
  });
}
