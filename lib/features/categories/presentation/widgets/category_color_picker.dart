import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

/// Reusable widget for selecting a category color from a predefined set of colors.
///
/// Displays a 6-column grid of circular color swatches. The selected color is highlighted
/// with a primary color border and a white checkmark. This widget is stateless and relies
/// on the parent to manage selection state via the [onColorSelected] callback.
///
/// **Usage**:
/// ```dart
/// CategoryColorPicker(
///   selectedColor: '#F44336',
///   onColorSelected: (colorHex) {
///     setState(() => _selectedColor = colorHex);
///   },
/// )
/// ```
///
/// **Available Colors**: 19 predefined hex colors covering a wide spectrum (grey, red,
/// pink, purple, blue, teal, green, yellow, orange, brown). Colors are validated by
/// `CategoryCustomizationValidator.validColors`.
class CategoryColorPicker extends StatelessWidget {
  /// Currently selected color in hex format (e.g., '#F44336').
  /// If null, no color is initially selected.
  final String? selectedColor;

  /// Callback invoked when user taps a color. Receives the hex color string as parameter.
  final ValueChanged<String> onColorSelected;

  const CategoryColorPicker({
    super.key,
    this.selectedColor,
    required this.onColorSelected,
  });

  /// 19 available colors for category customization (hex format).
  ///
  /// Colors match Material Design color palette and are validated by
  /// CategoryCustomizationValidator.validColors.
  static final List<String> _availableColors = [
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
  ];

  /// Parses a hex color string to a Flutter Color object.
  ///
  /// Expected format: '#RRGGBB' (e.g., '#F44336')
  /// Returns grey if parsing fails.
  Color _parseColor(String colorHex) {
    try {
      return Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 6,
        crossAxisSpacing: AppTheme.spacing1,
        mainAxisSpacing: AppTheme.spacing1,
      ),
      itemCount: _availableColors.length,
      itemBuilder: (context, index) {
        final colorHex = _availableColors[index];
        final isSelected = selectedColor == colorHex;
        final color = _parseColor(colorHex);

        return InkWell(
          onTap: () => onColorSelected(colorHex),
          child: Container(
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected
                    ? theme.colorScheme.primary
                    : Colors.transparent,
                width: 3,
              ),
            ),
            child: isSelected
                ? const Icon(
                    Icons.check,
                    color: Colors.white,
                  )
                : null,
          ),
        );
      },
    );
  }
}
