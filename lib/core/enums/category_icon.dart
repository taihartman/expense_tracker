import 'package:flutter/material.dart';

/// Type-safe representation of all 30 available Material Icons for categories.
///
/// This enum provides compile-time safety for icon selection and eliminates
/// the need for string-based icon handling throughout the codebase.
///
/// Usage:
/// ```dart
/// // Get icon name for Firestore
/// final iconName = CategoryIcon.restaurant.iconName; // "restaurant"
///
/// // Get IconData for rendering
/// final iconData = CategoryIcon.restaurant.iconData; // Icons.restaurant
///
/// // Parse from Firestore string
/// final icon = CategoryIcon.tryFromString("restaurant"); // CategoryIcon.restaurant
/// ```
enum CategoryIcon {
  category,
  restaurant,
  directionsCar,
  hotel,
  localActivity,
  shoppingBag,
  localCafe,
  flight,
  train,
  directionsBus,
  localTaxi,
  localGasStation,
  fastfood,
  localGroceryStore,
  localPharmacy,
  localHospital,
  fitnessCenter,
  spa,
  beachAccess,
  cameraAlt,
  movie,
  musicNote,
  sportsSoccer,
  pets,
  school,
  work,
  home,
  phone,
  laptop,
  book,
  moreHoriz;

  /// Returns the string representation of this icon for Firestore persistence.
  ///
  /// This converts the camelCase enum name to snake_case for consistency
  /// with Material Icons naming conventions.
  String get iconName {
    switch (this) {
      case CategoryIcon.category:
        return 'category';
      case CategoryIcon.restaurant:
        return 'restaurant';
      case CategoryIcon.directionsCar:
        return 'directions_car';
      case CategoryIcon.hotel:
        return 'hotel';
      case CategoryIcon.localActivity:
        return 'local_activity';
      case CategoryIcon.shoppingBag:
        return 'shopping_bag';
      case CategoryIcon.localCafe:
        return 'local_cafe';
      case CategoryIcon.flight:
        return 'flight';
      case CategoryIcon.train:
        return 'train';
      case CategoryIcon.directionsBus:
        return 'directions_bus';
      case CategoryIcon.localTaxi:
        return 'local_taxi';
      case CategoryIcon.localGasStation:
        return 'local_gas_station';
      case CategoryIcon.fastfood:
        return 'fastfood';
      case CategoryIcon.localGroceryStore:
        return 'local_grocery_store';
      case CategoryIcon.localPharmacy:
        return 'local_pharmacy';
      case CategoryIcon.localHospital:
        return 'local_hospital';
      case CategoryIcon.fitnessCenter:
        return 'fitness_center';
      case CategoryIcon.spa:
        return 'spa';
      case CategoryIcon.beachAccess:
        return 'beach_access';
      case CategoryIcon.cameraAlt:
        return 'camera_alt';
      case CategoryIcon.movie:
        return 'movie';
      case CategoryIcon.musicNote:
        return 'music_note';
      case CategoryIcon.sportsSoccer:
        return 'sports_soccer';
      case CategoryIcon.pets:
        return 'pets';
      case CategoryIcon.school:
        return 'school';
      case CategoryIcon.work:
        return 'work';
      case CategoryIcon.home:
        return 'home';
      case CategoryIcon.phone:
        return 'phone';
      case CategoryIcon.laptop:
        return 'laptop';
      case CategoryIcon.book:
        return 'book';
      case CategoryIcon.moreHoriz:
        return 'more_horiz';
    }
  }

  /// Returns the Flutter IconData for rendering this icon in the UI.
  IconData get iconData {
    switch (this) {
      case CategoryIcon.category:
        return Icons.category;
      case CategoryIcon.restaurant:
        return Icons.restaurant;
      case CategoryIcon.directionsCar:
        return Icons.directions_car;
      case CategoryIcon.hotel:
        return Icons.hotel;
      case CategoryIcon.localActivity:
        return Icons.local_activity;
      case CategoryIcon.shoppingBag:
        return Icons.shopping_bag;
      case CategoryIcon.localCafe:
        return Icons.local_cafe;
      case CategoryIcon.flight:
        return Icons.flight;
      case CategoryIcon.train:
        return Icons.train;
      case CategoryIcon.directionsBus:
        return Icons.directions_bus;
      case CategoryIcon.localTaxi:
        return Icons.local_taxi;
      case CategoryIcon.localGasStation:
        return Icons.local_gas_station;
      case CategoryIcon.fastfood:
        return Icons.fastfood;
      case CategoryIcon.localGroceryStore:
        return Icons.local_grocery_store;
      case CategoryIcon.localPharmacy:
        return Icons.local_pharmacy;
      case CategoryIcon.localHospital:
        return Icons.local_hospital;
      case CategoryIcon.fitnessCenter:
        return Icons.fitness_center;
      case CategoryIcon.spa:
        return Icons.spa;
      case CategoryIcon.beachAccess:
        return Icons.beach_access;
      case CategoryIcon.cameraAlt:
        return Icons.camera_alt;
      case CategoryIcon.movie:
        return Icons.movie;
      case CategoryIcon.musicNote:
        return Icons.music_note;
      case CategoryIcon.sportsSoccer:
        return Icons.sports_soccer;
      case CategoryIcon.pets:
        return Icons.pets;
      case CategoryIcon.school:
        return Icons.school;
      case CategoryIcon.work:
        return Icons.work;
      case CategoryIcon.home:
        return Icons.home;
      case CategoryIcon.phone:
        return Icons.phone;
      case CategoryIcon.laptop:
        return Icons.laptop;
      case CategoryIcon.book:
        return Icons.book;
      case CategoryIcon.moreHoriz:
        return Icons.more_horiz;
    }
  }

  /// Safely parses a string icon name to a CategoryIcon enum value.
  ///
  /// Returns null if the icon name doesn't match any known icon.
  /// Use this when reading from Firestore or user input.
  ///
  /// Example:
  /// ```dart
  /// final icon = CategoryIcon.tryFromString("restaurant"); // CategoryIcon.restaurant
  /// final unknown = CategoryIcon.tryFromString("invalid"); // null
  /// ```
  static CategoryIcon? tryFromString(String iconName) {
    return CategoryIcon.values.cast<CategoryIcon?>().firstWhere(
          (icon) => icon?.iconName == iconName,
          orElse: () => null,
        );
  }
}
