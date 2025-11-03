import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

/// Reusable widget for selecting a category icon from a predefined set of Material Icons.
///
/// Displays a 6-column grid of available icons. The selected icon is highlighted with
/// a primary color border and background. This widget is stateless and relies on the
/// parent to manage selection state via the [onIconSelected] callback.
///
/// **Usage**:
/// ```dart
/// CategoryIconPicker(
///   selectedIcon: 'restaurant',
///   onIconSelected: (iconName) {
///     setState(() => _selectedIcon = iconName);
///   },
/// )
/// ```
///
/// **Available Icons**: 30 Material Icons covering common expense categories (meals,
/// transport, shopping, entertainment, etc.). Icon names match Material Icons names
/// and are validated by `CategoryCustomizationValidator.validIcons`.
class CategoryIconPicker extends StatelessWidget {
  /// Currently selected icon name (e.g., 'restaurant', 'directions_car').
  /// If null, no icon is initially selected.
  final String? selectedIcon;

  /// Callback invoked when user taps an icon. Receives the icon name as parameter.
  final ValueChanged<String> onIconSelected;

  /// Optional scroll controller for the grid view. Required when this widget is
  /// embedded in a DraggableScrollableSheet to ensure tap gestures work correctly.
  final ScrollController? scrollController;

  const CategoryIconPicker({
    super.key,
    this.selectedIcon,
    required this.onIconSelected,
    this.scrollController,
  });

  /// 30 available Material Icons for category customization.
  ///
  /// Each entry contains:
  /// - `icon`: IconData from Material Icons
  /// - `name`: String identifier matching Material Icons name (validated by CategoryCustomizationValidator)
  ///
  /// Icons are organized by category type (general, food, transport, activities, shopping).
  static final List<Map<String, dynamic>> _availableIcons = [
    {'icon': Icons.category, 'name': 'category'},
    {'icon': Icons.restaurant, 'name': 'restaurant'},
    {'icon': Icons.directions_car, 'name': 'directions_car'},
    {'icon': Icons.hotel, 'name': 'hotel'},
    {'icon': Icons.local_activity, 'name': 'local_activity'},
    {'icon': Icons.shopping_bag, 'name': 'shopping_bag'},
    {'icon': Icons.local_cafe, 'name': 'local_cafe'},
    {'icon': Icons.flight, 'name': 'flight'},
    {'icon': Icons.train, 'name': 'train'},
    {'icon': Icons.directions_bus, 'name': 'directions_bus'},
    {'icon': Icons.local_taxi, 'name': 'local_taxi'},
    {'icon': Icons.local_gas_station, 'name': 'local_gas_station'},
    {'icon': Icons.shopping_cart, 'name': 'shopping_cart'},
    {'icon': Icons.local_grocery_store, 'name': 'local_grocery_store'},
    {'icon': Icons.local_mall, 'name': 'local_mall'},
    {'icon': Icons.movie, 'name': 'movie'},
    {'icon': Icons.theater_comedy, 'name': 'theater_comedy'},
    {'icon': Icons.sports_soccer, 'name': 'sports_soccer'},
    {'icon': Icons.fitness_center, 'name': 'fitness_center'},
    {'icon': Icons.spa, 'name': 'spa'},
    {'icon': Icons.local_hospital, 'name': 'local_hospital'},
    {'icon': Icons.local_pharmacy, 'name': 'local_pharmacy'},
    {'icon': Icons.school, 'name': 'school'},
    {'icon': Icons.work, 'name': 'work'},
    {'icon': Icons.computer, 'name': 'computer'},
    {'icon': Icons.phone_android, 'name': 'phone_android'},
    {'icon': Icons.home, 'name': 'home'},
    {'icon': Icons.pets, 'name': 'pets'},
    {'icon': Icons.child_care, 'name': 'child_care'},
    {'icon': Icons.local_florist, 'name': 'local_florist'},
  ];

  @override
  Widget build(BuildContext context) {
    print(
      '[CategoryIconPicker] 🎨 Building with scrollController: ${scrollController != null}, selectedIcon: $selectedIcon, shrinkWrap: ${scrollController == null}',
    );
    final theme = Theme.of(context);

    return GridView.builder(
      controller: scrollController,
      shrinkWrap: scrollController == null,
      physics: scrollController == null
          ? const NeverScrollableScrollPhysics()
          : null,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 6,
        crossAxisSpacing: AppTheme.spacing1,
        mainAxisSpacing: AppTheme.spacing1,
      ),
      itemCount: _availableIcons.length,
      itemBuilder: (context, index) {
        final iconData = _availableIcons[index];
        final isSelected = selectedIcon == iconData['name'];

        return InkWell(
          onTap: () {
            print(
              '[CategoryIconPicker] 👆 InkWell TAPPED! Icon: ${iconData['name']}, Index: $index',
            );
            onIconSelected(iconData['name']);
            print(
              '[CategoryIconPicker] ✅ onIconSelected called for: ${iconData['name']}',
            );
          },
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline,
                width: isSelected ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(AppTheme.spacing1),
              color: isSelected ? theme.colorScheme.primaryContainer : null,
            ),
            child: Icon(
              iconData['icon'],
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        );
      },
    );
  }
}
