import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/models/category.dart';
import '../cubit/category_cubit.dart';
import '../cubit/category_state.dart';
import '../cubit/category_customization_cubit.dart';
import 'category_browser_bottom_sheet.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/l10n/l10n_extensions.dart';
import '../../../../shared/utils/category_display_helper.dart';

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
    // Get customization from CategoryCustomizationCubit if available
    final customizationCubit = context.read<CategoryCustomizationCubit?>();
    final customization = customizationCubit?.getCustomization(category.id);

    // Merge global category with trip-specific customizations
    final displayCategory = DisplayCategory.fromGlobalAndCustomization(
      globalCategory: category,
      customization: customization,
    );

    final color = _getColor(displayCategory.color);
    final icon = _getIconData(displayCategory.icon);

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
          Text(displayCategory.name),
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
            Icons.search,
            size: 18,
            color: isSelected ? theme.colorScheme.onPrimaryContainer : color,
          ),
          const SizedBox(width: 6),
          Text(context.l10n.categoryBrowseAndCreate),
        ],
      ),
      onSelected: (selected) async {
        // Open CategoryBrowserBottomSheet when tapped
        if (selected) {
          await showModalBottomSheet<String?>(
            context: context,
            isScrollControlled: true,
            builder: (context) => CategoryBrowserBottomSheet(
              onCategorySelected: (category) {
                widget.onCategoryChanged(category.id);
                Navigator.of(context).pop(category.id);
              },
            ),
          );

          // Restore top categories state when sheet closes (with 24h cache)
          // This ensures chips remain visible even if user cancels
          // Only queries Firebase if cache is stale (24+ hours old)
          if (mounted) {
            context.read<CategoryCubit>().loadTopCategoriesIfStale(limit: 5);
          }
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
                final allCategories = state.categories;

                // Empty state - show only "Browse & Create" button
                if (allCategories.isEmpty) {
                  return ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildOtherChip(isSelected: false, theme: theme),
                    ],
                  );
                }

                // Extract "Other" category and build display order
                // Order: Top 4 popular (non-Other) → "Other" → "Browse & Create"
                final otherCategory = allCategories
                    .where((c) => c.id.toLowerCase() == 'other')
                    .firstOrNull;

                final nonOtherCategories = allCategories
                    .where((c) => c.id.toLowerCase() != 'other')
                    .take(4)
                    .toList();

                // Calculate total items: top 4 + "Other" (if exists) + "Browse & Create"
                final hasOtherCategory = otherCategory != null;
                final itemCount = nonOtherCategories.length +
                    (hasOtherCategory ? 1 : 0) +
                    1; // +1 for "Browse & Create"

                return ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: itemCount,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: AppTheme.spacing1),
                  itemBuilder: (context, index) {
                    // First 4 positions: non-Other categories
                    if (index < nonOtherCategories.length) {
                      final category = nonOtherCategories[index];
                      final isSelected = widget.selectedCategoryId == category.id;
                      return _buildCategoryChip(
                        category: category,
                        isSelected: isSelected,
                        theme: theme,
                      );
                    }

                    // Next position: "Other" category (if it exists)
                    if (hasOtherCategory && index == nonOtherCategories.length) {
                      final isSelected = widget.selectedCategoryId == otherCategory.id;
                      return _buildCategoryChip(
                        category: otherCategory,
                        isSelected: isSelected,
                        theme: theme,
                      );
                    }

                    // Last position: "Browse & Create" button
                    return _buildOtherChip(isSelected: false, theme: theme);
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
