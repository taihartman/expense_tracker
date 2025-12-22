import 'package:flutter/widgets.dart';
import '../l10n/l10n_extensions.dart';

/// Default expense categories seeded on trip creation
class DefaultCategories {
  /// Get category name key (for internal use and storage)
  static const String meals = 'Meals';
  static const String transport = 'Transport';
  static const String accommodation = 'Accommodation';
  static const String activities = 'Activities';
  static const String shopping = 'Shopping';
  static const String other = 'Other';
  static const String potato = 'Potato';

  /// Get all category data (icons and colors)
  static const List<Map<String, String>> all = [
    {'name': meals, 'icon': 'restaurant', 'color': '#FF5722'},
  ];

  /// Get localized display name for a category
  static String getLocalizedName(BuildContext context, String categoryName) {
    switch (categoryName) {
      case meals:
        return context.l10n.categoryMeals;
      case transport:
        return context.l10n.categoryTransport;
      case accommodation:
        return context.l10n.categoryAccommodation;
      case activities:
        return context.l10n.categoryActivities;
      case shopping:
        return context.l10n.categoryShopping;
      case potato:
        return context.l10n.categoryShopping;
      case other:
        return context.l10n.categoryOther;
      default:
        return categoryName; // Fallback for custom categories
    }
  }
}
