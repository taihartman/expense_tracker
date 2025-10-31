import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/shared/utils/icon_helper.dart';
import 'package:expense_tracker/core/enums/category_icon.dart';

void main() {
  group('IconHelper', () {
    group('getIconData', () {
      test('returns correct IconData for all 30 category icons', () {
        expect(IconHelper.getIconData('category'), Icons.category);
        expect(IconHelper.getIconData('restaurant'), Icons.restaurant);
        expect(IconHelper.getIconData('directions_car'), Icons.directions_car);
        expect(IconHelper.getIconData('hotel'), Icons.hotel);
        expect(IconHelper.getIconData('local_activity'), Icons.local_activity);
        expect(IconHelper.getIconData('shopping_bag'), Icons.shopping_bag);
        expect(IconHelper.getIconData('local_cafe'), Icons.local_cafe);
        expect(IconHelper.getIconData('flight'), Icons.flight);
        expect(IconHelper.getIconData('train'), Icons.train);
        expect(IconHelper.getIconData('directions_bus'), Icons.directions_bus);
        expect(IconHelper.getIconData('local_taxi'), Icons.local_taxi);
        expect(
          IconHelper.getIconData('local_gas_station'),
          Icons.local_gas_station,
        );
        expect(IconHelper.getIconData('fastfood'), Icons.fastfood);
        expect(
          IconHelper.getIconData('local_grocery_store'),
          Icons.local_grocery_store,
        );
        expect(IconHelper.getIconData('local_pharmacy'), Icons.local_pharmacy);
        expect(IconHelper.getIconData('local_hospital'), Icons.local_hospital);
        expect(IconHelper.getIconData('fitness_center'), Icons.fitness_center);
        expect(IconHelper.getIconData('spa'), Icons.spa);
        expect(IconHelper.getIconData('beach_access'), Icons.beach_access);
        expect(IconHelper.getIconData('camera_alt'), Icons.camera_alt);
        expect(IconHelper.getIconData('movie'), Icons.movie);
        expect(IconHelper.getIconData('music_note'), Icons.music_note);
        expect(IconHelper.getIconData('sports_soccer'), Icons.sports_soccer);
        expect(IconHelper.getIconData('pets'), Icons.pets);
        expect(IconHelper.getIconData('school'), Icons.school);
        expect(IconHelper.getIconData('work'), Icons.work);
        expect(IconHelper.getIconData('home'), Icons.home);
        expect(IconHelper.getIconData('phone'), Icons.phone);
        expect(IconHelper.getIconData('laptop'), Icons.laptop);
        expect(IconHelper.getIconData('book'), Icons.book);
        expect(IconHelper.getIconData('more_horiz'), Icons.more_horiz);
      });

      test('returns Icons.label for legacy "label" icon', () {
        expect(IconHelper.getIconData('label'), Icons.label);
      });

      test('returns Icons.category as fallback for unknown icons', () {
        expect(IconHelper.getIconData('unknown'), Icons.category);
        expect(IconHelper.getIconData('invalid'), Icons.category);
        expect(IconHelper.getIconData(''), Icons.category);
        expect(IconHelper.getIconData('nonexistent'), Icons.category);
      });

      test('is case-sensitive', () {
        // Uppercase should fall back to default
        expect(IconHelper.getIconData('Restaurant'), Icons.category);
        expect(IconHelper.getIconData('RESTAURANT'), Icons.category);
      });

      test('handles all enum icon names correctly', () {
        for (final icon in CategoryIcon.values) {
          final iconName = icon.iconName;
          final iconData = IconHelper.getIconData(iconName);
          expect(iconData, icon.iconData);
        }
      });
    });

    group('toCategoryIcon', () {
      test('converts valid string to CategoryIcon', () {
        expect(
          IconHelper.toCategoryIcon('restaurant'),
          CategoryIcon.restaurant,
        );
        expect(
          IconHelper.toCategoryIcon('directions_car'),
          CategoryIcon.directionsCar,
        );
        expect(IconHelper.toCategoryIcon('hotel'), CategoryIcon.hotel);
      });

      test('returns null for invalid strings', () {
        expect(IconHelper.toCategoryIcon('invalid'), null);
        expect(IconHelper.toCategoryIcon(''), null);
        expect(IconHelper.toCategoryIcon('unknown'), null);
      });

      test('handles all CategoryIcon enum values', () {
        for (final icon in CategoryIcon.values) {
          final iconName = icon.iconName;
          final parsed = IconHelper.toCategoryIcon(iconName);
          expect(parsed, icon);
        }
      });
    });

    group('fromCategoryIcon', () {
      test('converts CategoryIcon to string', () {
        expect(
          IconHelper.fromCategoryIcon(CategoryIcon.restaurant),
          'restaurant',
        );
        expect(
          IconHelper.fromCategoryIcon(CategoryIcon.directionsCar),
          'directions_car',
        );
        expect(IconHelper.fromCategoryIcon(CategoryIcon.hotel), 'hotel');
      });

      test('handles all CategoryIcon enum values', () {
        for (final icon in CategoryIcon.values) {
          final iconName = IconHelper.fromCategoryIcon(icon);
          expect(iconName, icon.iconName);
        }
      });
    });

    group('getAllIcons', () {
      test('returns list of all 31 icons', () {
        final icons = IconHelper.getAllIcons();
        expect(icons.length, 31); // 30 category icons + moreHoriz
      });

      test('each icon has both IconData and name', () {
        final icons = IconHelper.getAllIcons();
        for (final iconMap in icons) {
          expect(iconMap, containsPair('icon', isA<IconData>()));
          expect(iconMap, containsPair('name', isA<String>()));
          expect(iconMap['name'], isNotEmpty);
        }
      });

      test('all icon names are unique', () {
        final icons = IconHelper.getAllIcons();
        final names = icons.map((m) => m['name'] as String).toList();
        final uniqueNames = names.toSet();
        expect(names.length, uniqueNames.length);
      });

      test('icons match CategoryIcon enum values', () {
        final icons = IconHelper.getAllIcons();
        expect(icons.length, CategoryIcon.values.length);

        for (var i = 0; i < icons.length; i++) {
          final iconMap = icons[i];
          final enumValue = CategoryIcon.values[i];

          expect(iconMap['name'], enumValue.iconName);
          expect(iconMap['icon'], enumValue.iconData);
        }
      });
    });

    group('bidirectional conversions', () {
      test('string → CategoryIcon → string preserves value', () {
        const testStrings = [
          'restaurant',
          'directions_car',
          'hotel',
          'fastfood',
          'local_activity',
        ];

        for (final str in testStrings) {
          final icon = IconHelper.toCategoryIcon(str);
          expect(icon, isNotNull);
          final converted = IconHelper.fromCategoryIcon(icon!);
          expect(converted, str);
        }
      });

      test('CategoryIcon → string → CategoryIcon preserves value', () {
        for (final icon in CategoryIcon.values) {
          final name = IconHelper.fromCategoryIcon(icon);
          final parsed = IconHelper.toCategoryIcon(name);
          expect(parsed, icon);
        }
      });

      test('string → IconData matches enum → IconData', () {
        for (final icon in CategoryIcon.values) {
          final name = icon.iconName;
          final iconDataFromString = IconHelper.getIconData(name);
          final iconDataFromEnum = icon.iconData;
          expect(iconDataFromString, iconDataFromEnum);
        }
      });
    });

    group('code duplication elimination', () {
      test(
        'getIconData handles all icons that were in duplicated _getIconData methods',
        () {
          // These were the 8 icons previously handled in the duplicated methods
          expect(IconHelper.getIconData('restaurant'), Icons.restaurant);
          expect(IconHelper.getIconData('directions_car'), Icons.directions_car);
          expect(IconHelper.getIconData('hotel'), Icons.hotel);
          expect(IconHelper.getIconData('local_activity'), Icons.local_activity);
          expect(IconHelper.getIconData('shopping_bag'), Icons.shopping_bag);
          expect(IconHelper.getIconData('more_horiz'), Icons.more_horiz);
          expect(IconHelper.getIconData('label'), Icons.label);
          expect(IconHelper.getIconData('category'), Icons.category);
        },
      );

      test('getIconData now handles 22 additional icons', () {
        // These are the 22 icons that were NOT handled before (fell back to default)
        final additionalIcons = [
          'local_cafe',
          'flight',
          'train',
          'directions_bus',
          'local_taxi',
          'local_gas_station',
          'fastfood',
          'local_grocery_store',
          'local_pharmacy',
          'local_hospital',
          'fitness_center',
          'spa',
          'beach_access',
          'camera_alt',
          'movie',
          'music_note',
          'sports_soccer',
          'pets',
          'school',
          'work',
          'home',
          'phone',
          'laptop',
          'book',
        ];

        for (final iconName in additionalIcons) {
          final iconData = IconHelper.getIconData(iconName);
          // Verify it doesn't fall back to Icons.category
          // (except when we test with unknown icons)
          expect(iconData, isNot(Icons.category));
        }
      });
    });
  });
}
