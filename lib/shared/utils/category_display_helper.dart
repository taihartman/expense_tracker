import '../../core/models/category_customization.dart';
import '../../features/categories/domain/models/category.dart';

/// Helper class representing a category as it should be displayed in UI
///
/// Merges global category data with trip-specific customizations.
/// This is a display model only - NOT persisted to database.
///
/// Example usage:
/// ```dart
/// final displayCategory = DisplayCategory.fromGlobalAndCustomization(
///   globalCategory: globalCategory,
///   customization: customization, // null if no customization
/// );
/// // Use displayCategory.icon, displayCategory.color for rendering
/// ```
class DisplayCategory {
  /// Global category ID
  final String id;

  /// Category name (always from global category)
  final String name;

  /// Display icon (customized or global default)
  final String icon;

  /// Display color (customized or global default)
  final String color;

  /// Whether this category has any customizations
  final bool isCustomized;

  const DisplayCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.isCustomized,
  });

  /// Creates DisplayCategory by merging global category with customization
  ///
  /// Rules:
  /// - Name always comes from global category (cannot be customized per spec)
  /// - Icon: Use custom if available, otherwise use global default
  /// - Color: Use custom if available, otherwise use global default
  /// - isCustomized: true if any customization exists
  factory DisplayCategory.fromGlobalAndCustomization({
    required Category globalCategory,
    CategoryCustomization? customization,
  }) {
    return DisplayCategory(
      id: globalCategory.id,
      name: globalCategory.name, // Always use global name
      icon: customization?.customIcon ?? globalCategory.icon,
      color: customization?.customColor ?? globalCategory.color,
      isCustomized: customization?.hasCustomization ?? false,
    );
  }
}
