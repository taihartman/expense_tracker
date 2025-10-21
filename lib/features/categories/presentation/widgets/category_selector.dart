import 'package:flutter/material.dart';
import '../../../../core/constants/categories.dart';
import '../../../../core/theme/app_theme.dart';

/// Horizontal scrollable category selector with icons and colors
class CategorySelector extends StatelessWidget {
  final String? selectedCategoryId;
  final ValueChanged<String?> onCategoryChanged;

  const CategorySelector({
    required this.selectedCategoryId,
    required this.onCategoryChanged,
    super.key,
  });

  IconData _getIconData(String iconName) {
    switch (iconName) {
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
      case 'more_horiz':
        return Icons.more_horiz;
      default:
        return Icons.category;
    }
  }

  Color _getColor(String colorHex) {
    try {
      return Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CATEGORY',
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppTheme.spacing1),
        SizedBox(
          height: 50,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: DefaultCategories.all.length,
            separatorBuilder: (context, index) => const SizedBox(width: AppTheme.spacing1),
            itemBuilder: (context, index) {
              final category = DefaultCategories.all[index];
              final categoryName = category['name']!;
              final iconName = category['icon']!;
              final colorHex = category['color']!;

              final isSelected = selectedCategoryId == categoryName;
              final color = _getColor(colorHex);
              final icon = _getIconData(iconName);

              return FilterChip(
                selected: isSelected,
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      size: 18,
                      color: isSelected
                          ? theme.colorScheme.onPrimaryContainer
                          : color,
                    ),
                    const SizedBox(width: 6),
                    Text(categoryName),
                  ],
                ),
                onSelected: (selected) {
                  onCategoryChanged(selected ? categoryName : null);
                },
                selectedColor: color.withValues(alpha: 0.3),
                checkmarkColor: theme.colorScheme.onPrimaryContainer,
                backgroundColor: Colors.transparent,
                side: BorderSide(
                  color: isSelected ? color : theme.colorScheme.outline,
                  width: isSelected ? 2 : 1,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
