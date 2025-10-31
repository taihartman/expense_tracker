import 'package:equatable/equatable.dart';

/// Represents a trip-specific visual customization for a global category
///
/// Customizations are stored per trip and override the global category's
/// default icon and/or color for that specific trip only.
///
/// Example: A user's "Japan Trip" can show "Meals" with a ramen bowl icon 🍜,
/// while their "Work Trip" keeps the default restaurant icon 🍽️.
class CategoryCustomization extends Equatable {
  /// ID of the global category being customized
  final String categoryId;

  /// ID of the trip this customization belongs to
  final String tripId;

  /// Custom icon override (Material Icons code name)
  /// If null, uses global category's default icon
  /// Example: "fastfood", "restaurant", "directions_car"
  final String? customIcon;

  /// Custom color override (hex code with # prefix)
  /// If null, uses global category's default color
  /// Example: "#FF5722", "#2196F3", "#4CAF50"
  final String? customColor;

  /// Timestamp of when this customization was last updated
  /// Used for audit trail and conflict resolution
  final DateTime updatedAt;

  const CategoryCustomization({
    required this.categoryId,
    required this.tripId,
    this.customIcon,
    this.customColor,
    required this.updatedAt,
  });

  /// Creates a copy with optional field replacements
  CategoryCustomization copyWith({
    String? categoryId,
    String? tripId,
    String? customIcon,
    String? customColor,
    DateTime? updatedAt,
  }) {
    return CategoryCustomization(
      categoryId: categoryId ?? this.categoryId,
      tripId: tripId ?? this.tripId,
      customIcon: customIcon ?? this.customIcon,
      customColor: customColor ?? this.customColor,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Checks if this customization has any overrides
  /// Returns false if both icon and color are null (no actual customization)
  bool get hasCustomization => customIcon != null || customColor != null;

  /// Checks if icon is customized (not using global default)
  bool get hasCustomIcon => customIcon != null;

  /// Checks if color is customized (not using global default)
  bool get hasCustomColor => customColor != null;

  @override
  List<Object?> get props => [
        categoryId,
        tripId,
        customIcon,
        customColor,
        updatedAt,
      ];

  @override
  String toString() {
    return 'CategoryCustomization('
        'categoryId: $categoryId, '
        'tripId: $tripId, '
        'customIcon: $customIcon, '
        'customColor: $customColor, '
        'updatedAt: $updatedAt'
        ')';
  }
}
