import '../models/category_customization.dart';

/// Validator for category customization operations
///
/// Validates icon and color values against predefined sets to ensure
/// consistency with the icon/color pickers in the UI.
class CategoryCustomizationValidator {
  /// Available Material Icons for category customization
  /// Must match the list in CategoryIconPicker widget
  static const Set<String> validIcons = {
    'category',
    'restaurant',
    'directions_car',
    'hotel',
    'local_activity',
    'shopping_bag',
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
  };

  /// Available colors for category customization
  /// Must match the list in CategoryColorPicker widget
  static const Set<String> validColors = {
    '#9E9E9E', // Grey
    '#F44336', // Red
    '#E91E63', // Pink
    '#9C27B0', // Purple
    '#673AB7', // Deep Purple
    '#3F51B5', // Indigo
    '#2196F3', // Blue
    '#03A9F4', // Light Blue
    '#00BCD4', // Cyan
    '#009688', // Teal
    '#4CAF50', // Green
    '#8BC34A', // Light Green
    '#CDDC39', // Lime
    '#FFEB3B', // Yellow
    '#FFC107', // Amber
    '#FF9800', // Orange
    '#FF5722', // Deep Orange
    '#795548', // Brown
    '#607D8B', // Blue Grey
  };

  /// Hex color pattern (e.g., #FF5722)
  static final RegExp _colorPattern = RegExp(r'^#[0-9A-Fa-f]{6}$');

  /// Validates custom icon (null is valid = use default)
  ///
  /// Returns null if valid, error message if invalid.
  static String? validateIcon(String? icon) {
    if (icon == null) return null; // Null is valid (use default)
    if (icon.trim().isEmpty) return 'Icon cannot be empty';
    if (!validIcons.contains(icon)) {
      return 'Invalid icon. Must be one of the predefined Material Icons.';
    }
    return null; // Valid
  }

  /// Validates custom color (null is valid = use default)
  ///
  /// Returns null if valid, error message if invalid.
  static String? validateColor(String? color) {
    if (color == null) return null; // Null is valid (use default)
    if (color.trim().isEmpty) return 'Color cannot be empty';
    if (!_colorPattern.hasMatch(color)) {
      return 'Color must be a valid hex code (e.g., #FF5722)';
    }
    // Normalize to uppercase for comparison
    final normalizedColor = color.toUpperCase();
    if (!validColors.contains(normalizedColor)) {
      return 'Invalid color. Must be one of the predefined colors.';
    }
    return null; // Valid
  }

  /// Validates an entire customization before saving
  ///
  /// Returns a map of field names to error messages.
  /// Empty map = valid.
  static Map<String, String> validateCustomization(
    CategoryCustomization customization,
  ) {
    final errors = <String, String>{};

    // categoryId must be non-empty
    if (customization.categoryId.trim().isEmpty) {
      errors['categoryId'] = 'Category ID is required';
    }

    // tripId must be non-empty
    if (customization.tripId.trim().isEmpty) {
      errors['tripId'] = 'Trip ID is required';
    }

    // Validate icon if provided
    final iconError = validateIcon(customization.customIcon);
    if (iconError != null) {
      errors['customIcon'] = iconError;
    }

    // Validate color if provided
    final colorError = validateColor(customization.customColor);
    if (colorError != null) {
      errors['customColor'] = colorError;
    }

    // At least one customization must be set
    if (!customization.hasCustomization) {
      errors['general'] =
          'At least one customization (icon or color) must be set';
    }

    return errors; // Empty map = valid
  }
}
