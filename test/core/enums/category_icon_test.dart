import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/core/enums/category_icon.dart';

void main() {
  group('CategoryIcon', () {
    group('iconName', () {
      test('returns correct string for all 30 icons', () {
        expect(CategoryIcon.category.iconName, 'category');
        expect(CategoryIcon.restaurant.iconName, 'restaurant');
        expect(CategoryIcon.directionsCar.iconName, 'directions_car');
        expect(CategoryIcon.hotel.iconName, 'hotel');
        expect(CategoryIcon.localActivity.iconName, 'local_activity');
        expect(CategoryIcon.shoppingBag.iconName, 'shopping_bag');
        expect(CategoryIcon.localCafe.iconName, 'local_cafe');
        expect(CategoryIcon.flight.iconName, 'flight');
        expect(CategoryIcon.train.iconName, 'train');
        expect(CategoryIcon.directionsBus.iconName, 'directions_bus');
        expect(CategoryIcon.localTaxi.iconName, 'local_taxi');
        expect(CategoryIcon.localGasStation.iconName, 'local_gas_station');
        expect(CategoryIcon.fastfood.iconName, 'fastfood');
        expect(CategoryIcon.localGroceryStore.iconName, 'local_grocery_store');
        expect(CategoryIcon.localPharmacy.iconName, 'local_pharmacy');
        expect(CategoryIcon.localHospital.iconName, 'local_hospital');
        expect(CategoryIcon.fitnessCenter.iconName, 'fitness_center');
        expect(CategoryIcon.spa.iconName, 'spa');
        expect(CategoryIcon.beachAccess.iconName, 'beach_access');
        expect(CategoryIcon.cameraAlt.iconName, 'camera_alt');
        expect(CategoryIcon.movie.iconName, 'movie');
        expect(CategoryIcon.musicNote.iconName, 'music_note');
        expect(CategoryIcon.sportsSoccer.iconName, 'sports_soccer');
        expect(CategoryIcon.pets.iconName, 'pets');
        expect(CategoryIcon.school.iconName, 'school');
        expect(CategoryIcon.work.iconName, 'work');
        expect(CategoryIcon.home.iconName, 'home');
        expect(CategoryIcon.phone.iconName, 'phone');
        expect(CategoryIcon.laptop.iconName, 'laptop');
        expect(CategoryIcon.book.iconName, 'book');
        expect(CategoryIcon.moreHoriz.iconName, 'more_horiz');
      });

      test('all icon names are unique', () {
        final names = CategoryIcon.values.map((e) => e.iconName).toList();
        final uniqueNames = names.toSet();
        expect(names.length, uniqueNames.length);
      });
    });

    group('iconData', () {
      test('returns correct IconData for all 30 icons', () {
        expect(CategoryIcon.category.iconData, Icons.category);
        expect(CategoryIcon.restaurant.iconData, Icons.restaurant);
        expect(CategoryIcon.directionsCar.iconData, Icons.directions_car);
        expect(CategoryIcon.hotel.iconData, Icons.hotel);
        expect(CategoryIcon.localActivity.iconData, Icons.local_activity);
        expect(CategoryIcon.shoppingBag.iconData, Icons.shopping_bag);
        expect(CategoryIcon.localCafe.iconData, Icons.local_cafe);
        expect(CategoryIcon.flight.iconData, Icons.flight);
        expect(CategoryIcon.train.iconData, Icons.train);
        expect(CategoryIcon.directionsBus.iconData, Icons.directions_bus);
        expect(CategoryIcon.localTaxi.iconData, Icons.local_taxi);
        expect(CategoryIcon.localGasStation.iconData, Icons.local_gas_station);
        expect(CategoryIcon.fastfood.iconData, Icons.fastfood);
        expect(
          CategoryIcon.localGroceryStore.iconData,
          Icons.local_grocery_store,
        );
        expect(CategoryIcon.localPharmacy.iconData, Icons.local_pharmacy);
        expect(CategoryIcon.localHospital.iconData, Icons.local_hospital);
        expect(CategoryIcon.fitnessCenter.iconData, Icons.fitness_center);
        expect(CategoryIcon.spa.iconData, Icons.spa);
        expect(CategoryIcon.beachAccess.iconData, Icons.beach_access);
        expect(CategoryIcon.cameraAlt.iconData, Icons.camera_alt);
        expect(CategoryIcon.movie.iconData, Icons.movie);
        expect(CategoryIcon.musicNote.iconData, Icons.music_note);
        expect(CategoryIcon.sportsSoccer.iconData, Icons.sports_soccer);
        expect(CategoryIcon.pets.iconData, Icons.pets);
        expect(CategoryIcon.school.iconData, Icons.school);
        expect(CategoryIcon.work.iconData, Icons.work);
        expect(CategoryIcon.home.iconData, Icons.home);
        expect(CategoryIcon.phone.iconData, Icons.phone);
        expect(CategoryIcon.laptop.iconData, Icons.laptop);
        expect(CategoryIcon.book.iconData, Icons.book);
        expect(CategoryIcon.moreHoriz.iconData, Icons.more_horiz);
      });

      test('all iconData are valid IconData objects', () {
        for (final icon in CategoryIcon.values) {
          expect(icon.iconData, isA<IconData>());
        }
      });
    });

    group('tryFromString', () {
      test('returns correct enum for valid icon names', () {
        expect(
          CategoryIcon.tryFromString('restaurant'),
          CategoryIcon.restaurant,
        );
        expect(
          CategoryIcon.tryFromString('directions_car'),
          CategoryIcon.directionsCar,
        );
        expect(CategoryIcon.tryFromString('hotel'), CategoryIcon.hotel);
        expect(
          CategoryIcon.tryFromString('local_activity'),
          CategoryIcon.localActivity,
        );
        expect(
          CategoryIcon.tryFromString('shopping_bag'),
          CategoryIcon.shoppingBag,
        );
      });

      test('returns null for invalid icon names', () {
        expect(CategoryIcon.tryFromString('invalid'), null);
        expect(CategoryIcon.tryFromString('nonexistent'), null);
        expect(CategoryIcon.tryFromString(''), null);
      });

      test('is case-sensitive', () {
        expect(CategoryIcon.tryFromString('Restaurant'), null);
        expect(CategoryIcon.tryFromString('RESTAURANT'), null);
      });

      test('round-trip conversion works for all icons', () {
        for (final icon in CategoryIcon.values) {
          final name = icon.iconName;
          final parsed = CategoryIcon.tryFromString(name);
          expect(parsed, icon);
        }
      });
    });

    group('enum completeness', () {
      test('has exactly 30 icons', () {
        expect(CategoryIcon.values.length, 31); // 30 icons + moreHoriz
      });

      test('all enum values have both iconName and iconData', () {
        for (final icon in CategoryIcon.values) {
          expect(icon.iconName, isNotEmpty);
          expect(icon.iconData, isNotNull);
        }
      });
    });

    group('bidirectional conversion', () {
      test('string → enum → string preserves value', () {
        const testStrings = [
          'restaurant',
          'directions_car',
          'hotel',
          'fastfood',
        ];

        for (final str in testStrings) {
          final icon = CategoryIcon.tryFromString(str);
          expect(icon, isNotNull);
          expect(icon!.iconName, str);
        }
      });

      test('enum → string → enum preserves value', () {
        for (final icon in CategoryIcon.values) {
          final name = icon.iconName;
          final parsed = CategoryIcon.tryFromString(name);
          expect(parsed, icon);
        }
      });
    });
  });
}
