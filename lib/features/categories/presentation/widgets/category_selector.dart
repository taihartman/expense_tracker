import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/models/category.dart';
import '../cubit/category_cubit.dart';
import '../cubit/category_state.dart';
import 'category_browser_bottom_sheet.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/l10n/l10n_extensions.dart';

/// Horizontal scrollable category selector with top 5 popular categories
///
/// Displays:
/// - Top 5 most popular categories as FilterChips
/// - "Other" chip to browse/search all categories
/// - Loading indicator while fetching categories
/// - Fallback to "Other" only on error or empty state
class CategorySelector extends StatefulWidget {
  final String? selectedCategoryId;
  final ValueChanged<String?> onCategoryChanged;

  const CategorySelector({
    required this.selectedCategoryId,
    required this.onCategoryChanged,
    super.key,
  });

  @override
  State<CategorySelector> createState() => _CategorySelectorState();
}

class _CategorySelectorState extends State<CategorySelector> {
  @override
  void initState() {
    super.initState();
    // Load top 5 categories when widget initializes
    context.read<CategoryCubit>().loadTopCategories(limit: 5);
  }

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
      case 'label':
        return Icons.label;
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

  Widget _buildCategoryChip({
    required Category category,
    required bool isSelected,
    required ThemeData theme,
  }) {
    final color = _getColor(category.color);
    final icon = _getIconData(category.icon);

    return FilterChip(
      selected: isSelected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 18,
            color: isSelected ? theme.colorScheme.onPrimaryContainer : color,
          ),
          const SizedBox(width: 6),
          Text(category.name),
        ],
      ),
      onSelected: (selected) {
        widget.onCategoryChanged(selected ? category.id : null);
      },
      selectedColor: color.withValues(alpha: 0.3),
      checkmarkColor: theme.colorScheme.onPrimaryContainer,
      backgroundColor: Colors.transparent,
      side: BorderSide(
        color: isSelected ? color : theme.colorScheme.outline,
        width: isSelected ? 2 : 1,
      ),
    );
  }

  Widget _buildOtherChip({required bool isSelected, required ThemeData theme}) {
    final color = Colors.grey;

    return FilterChip(
      selected: isSelected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.more_horiz,
            size: 18,
            color: isSelected ? theme.colorScheme.onPrimaryContainer : color,
          ),
          const SizedBox(width: 6),
          Text(context.l10n.categoryOther),
        ],
      ),
      onSelected: (selected) {
        // Open CategoryBrowserBottomSheet when tapped
        if (selected) {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (context) => CategoryBrowserBottomSheet(
              onCategorySelected: (category) {
                widget.onCategoryChanged(category.id);
              },
            ),
          );
        }
      },
      selectedColor: color.withValues(alpha: 0.3),
      checkmarkColor: theme.colorScheme.onPrimaryContainer,
      backgroundColor: Colors.transparent,
      side: BorderSide(
        color: isSelected ? color : theme.colorScheme.outline,
        width: isSelected ? 2 : 1,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.expenseSectionCategory,
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppTheme.spacing1),
        SizedBox(
          height: 50,
          child: BlocBuilder<CategoryCubit, CategoryState>(
            builder: (context, state) {
              // Loading state
              if (state is CategoryLoadingTop) {
                return const Center(child: CircularProgressIndicator());
              }

              // Error or empty state - show only "Other" chip
              if (state is CategoryError || state is CategoryInitial) {
                return ListView(
                  scrollDirection: Axis.horizontal,
                  children: [_buildOtherChip(isSelected: false, theme: theme)],
                );
              }

              // Loaded state
              if (state is CategoryTopLoaded) {
                final categories = state.categories;

                // Empty state - show only "Other" chip
                if (categories.isEmpty) {
                  return ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildOtherChip(isSelected: false, theme: theme),
                    ],
                  );
                }

                // Build category chips + "Other" chip
                return ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length + 1, // +1 for "Other" chip
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: AppTheme.spacing1),
                  itemBuilder: (context, index) {
                    // Last item is "Other" chip
                    if (index == categories.length) {
                      return _buildOtherChip(isSelected: false, theme: theme);
                    }

                    // Regular category chips
                    final category = categories[index];
                    final isSelected = widget.selectedCategoryId == category.id;

                    return _buildCategoryChip(
                      category: category,
                      isSelected: isSelected,
                      theme: theme,
                    );
                  },
                );
              }

              // Fallback - show only "Other" chip
              return ListView(
                scrollDirection: Axis.horizontal,
                children: [_buildOtherChip(isSelected: false, theme: theme)],
              );
            },
          ),
        ),
      ],
    );
  }
}
