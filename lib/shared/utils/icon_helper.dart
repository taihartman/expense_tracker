import 'package:flutter/material.dart';
import 'package:expense_tracker/core/enums/category_icon.dart';

/// Shared utility for category icon conversion and rendering.
///
/// This helper eliminates code duplication by providing a single location
/// for all icon-related conversions. Previously, the `_getIconData()` method
/// was duplicated across 3 widgets (category_selector, category_browser_bottom_sheet,
/// customize_categories_screen).
///
/// Usage:
/// ```dart
/// // Convert string to IconData for rendering
/// final icon = IconHelper.getIconData('restaurant'); // Icons.restaurant
///
/// // Convert string to enum
/// final iconEnum = IconHelper.toCategoryIcon('restaurant'); // CategoryIcon.restaurant
///
/// // Convert enum to string
/// final iconName = IconHelper.fromCategoryIcon(CategoryIcon.restaurant); // 'restaurant'
/// ```
class IconHelper {
  IconHelper._(); // Private constructor to prevent instantiation

  /// Converts a string icon name to Flutter IconData for rendering.
  ///
  /// This method handles all 30 available category icons. If the icon name
  /// is not recognized, it falls back to `Icons.category`.
  ///
  /// This replaces the duplicated `_getIconData()` methods that were
  /// previously in category_selector, category_browser_bottom_sheet,
  /// and customize_categories_screen.
  ///
  /// Example:
  /// ```dart
  /// final icon = IconHelper.getIconData('restaurant'); // Icons.restaurant
  /// final fallback = IconHelper.getIconData('unknown'); // Icons.category (fallback)
  /// ```
  static IconData getIconData(String iconName) {
    switch (iconName) {
      case 'category':
        return Icons.category;
      case 'restaurant':
        return Icons.restaurant;
      case 'directions_car':
        return Icons.directions_car;
      case 'hotel':
        return Icons.hotel;
      case 'local_activity':
        return Icons.local_activity;
      case 'shopping_bag':
        return Icons.shopping_bag;
      case 'local_cafe':
        return Icons.local_cafe;
      case 'flight':
        return Icons.flight;
      case 'train':
        return Icons.train;
      case 'directions_bus':
        return Icons.directions_bus;
      case 'local_taxi':
        return Icons.local_taxi;
      case 'local_gas_station':
        return Icons.local_gas_station;
      case 'fastfood':
        return Icons.fastfood;
      case 'local_grocery_store':
        return Icons.local_grocery_store;
      case 'local_pharmacy':
        return Icons.local_pharmacy;
      case 'local_hospital':
        return Icons.local_hospital;
      case 'fitness_center':
        return Icons.fitness_center;
      case 'spa':
        return Icons.spa;
      case 'beach_access':
        return Icons.beach_access;
      case 'camera_alt':
        return Icons.camera_alt;
      case 'movie':
        return Icons.movie;
      case 'music_note':
        return Icons.music_note;
      case 'sports_soccer':
        return Icons.sports_soccer;
      case 'pets':
        return Icons.pets;
      case 'school':
        return Icons.school;
      case 'work':
        return Icons.work;
      case 'home':
        return Icons.home;
      case 'phone':
        return Icons.phone;
      case 'laptop':
        return Icons.laptop;
      case 'book':
        return Icons.book;
      case 'more_horiz':
        return Icons.more_horiz;
      case 'label':
        return Icons.label;
      default:
        return Icons.category; // Fallback for unknown icons
    }
  }

  /// Converts a string icon name to a CategoryIcon enum value.
  ///
  /// Returns null if the icon name doesn't match any known icon.
  ///
  /// Example:
  /// ```dart
  /// final icon = IconHelper.toCategoryIcon('restaurant'); // CategoryIcon.restaurant
  /// final unknown = IconHelper.toCategoryIcon('invalid'); // null
  /// ```
  static CategoryIcon? toCategoryIcon(String iconName) {
    return CategoryIcon.tryFromString(iconName);
  }

  /// Converts a CategoryIcon enum value to its string representation.
  ///
  /// Example:
  /// ```dart
  /// final name = IconHelper.fromCategoryIcon(CategoryIcon.restaurant); // 'restaurant'
  /// ```
  static String fromCategoryIcon(CategoryIcon icon) {
    return icon.iconName;
  }

  /// Returns all available category icons as a list of maps.
  ///
  /// Each map contains the icon's IconData and its string name.
  /// This is useful for generating icon picker UI dynamically.
  ///
  /// Example:
  /// ```dart
  /// final icons = IconHelper.getAllIcons();
  /// // Returns: [
  /// //   {'icon': Icons.category, 'name': 'category'},
  /// //   {'icon': Icons.restaurant, 'name': 'restaurant'},
  /// //   ...
  /// // ]
  /// ```
  static List<Map<String, dynamic>> getAllIcons() {
    return CategoryIcon.values.map((iconEnum) {
      return {
        'icon': iconEnum.iconData,
        'name': iconEnum.iconName,
      };
    }).toList();
  }
}
