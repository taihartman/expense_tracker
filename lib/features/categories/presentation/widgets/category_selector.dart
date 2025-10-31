import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/models/category.dart';
import '../../domain/repositories/category_repository.dart';
import '../cubit/category_cubit.dart';
import '../cubit/category_state.dart';
import '../cubit/category_customization_cubit.dart';
import 'category_browser_bottom_sheet.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/l10n/l10n_extensions.dart';
import '../../../../shared/utils/category_display_helper.dart';
import '../../../../shared/utils/icon_helper.dart';

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
  Category? _selectedCategory;
  List<Category>? _cachedCategories; // Cache last successful load

  @override
  void initState() {
    super.initState();
    debugPrint(
      '🔵 [CategorySelector] initState - selectedId: ${widget.selectedCategoryId}',
    );
    // Load top 5 categories after first frame to avoid state changes during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<CategoryCubit>().loadTopCategories(limit: 5);
      }
    });
    // Load selected category if one is set
    _loadSelectedCategory();
  }

  @override
  void didUpdateWidget(CategorySelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    debugPrint(
      '🟡 [CategorySelector] didUpdateWidget - old: ${oldWidget.selectedCategoryId}, new: ${widget.selectedCategoryId}',
    );
    // Reload selected category if it changed
    if (widget.selectedCategoryId != oldWidget.selectedCategoryId) {
      debugPrint(
        '🟢 [CategorySelector] Selection changed, loading selected category',
      );
      _loadSelectedCategory();
    }
  }

  Future<void> _loadSelectedCategory() async {
    debugPrint(
      '🔍 [CategorySelector] _loadSelectedCategory called for: ${widget.selectedCategoryId}',
    );
    if (widget.selectedCategoryId == null) {
      if (mounted) {
        setState(() {
          _selectedCategory = null;
        });
      }
      return;
    }

    try {
      final repository = context.read<CategoryRepository>();
      final category = await repository.getCategoryById(
        widget.selectedCategoryId!,
      );

      debugPrint(
        '✅ [CategorySelector] Loaded selected category: ${category?.name}',
      );
      if (mounted) {
        setState(() {
          _selectedCategory = category;
        });
      }
    } catch (e) {
      debugPrint('❌ [CategorySelector] Failed to load category: $e');
      // If we can't fetch the category, just clear it
      if (mounted) {
        setState(() {
          _selectedCategory = null;
        });
      }
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
    final icon = IconHelper.getIconData(displayCategory.icon);

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
                // CategoryBrowserBottomSheet handles its own dismissal
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
              // Cache successful loads
              if (state is CategoryTopLoaded) {
                _cachedCategories = state.categories;
              }

              // Loading state - show cached categories if available
              if (state is CategoryLoadingTop) {
                if (_cachedCategories == null) {
                  // Only show loading spinner on first load (no cache yet)
                  return const Center(child: CircularProgressIndicator());
                }
                // Otherwise fall through to render with cached data
                debugPrint(
                  '🔄 [CategorySelector] Loading state but showing cached ${_cachedCategories!.length} categories',
                );
              }

              // Error or empty state - show only "Other" chip (but try cached first)
              if (state is CategoryError || state is CategoryInitial) {
                if (_cachedCategories == null || _cachedCategories!.isEmpty) {
                  return ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildOtherChip(isSelected: false, theme: theme),
                    ],
                  );
                }
                // Otherwise fall through to render with cached data
                debugPrint(
                  '🔄 [CategorySelector] Error/Initial state but showing cached ${_cachedCategories!.length} categories',
                );
              }

              // Get categories from state or cache
              final List<Category> allCategories;
              if (state is CategoryTopLoaded) {
                allCategories = state.categories;
              } else if (_cachedCategories != null) {
                allCategories = _cachedCategories!;
              } else {
                // Fallback - show only "Other" chip
                return ListView(
                  scrollDirection: Axis.horizontal,
                  children: [_buildOtherChip(isSelected: false, theme: theme)],
                );
              }

              // Render chips with categories
              {
                // final allCategories = state.categories; // Removed - using variable from above

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
                // Order: Top 3 popular (non-Other) → Selected (if not in top) → "Other" → "Browse & Create"
                final otherCategory = allCategories
                    .where((c) => c.id.toLowerCase() == 'other')
                    .firstOrNull;

                // Check if selected category is already in the top categories
                final selectedIsInTop =
                    widget.selectedCategoryId != null &&
                    allCategories.any((c) => c.id == widget.selectedCategoryId);

                // Get top 3 or 4 categories depending on whether we need to show selected
                final maxTopCategories = selectedIsInTop ? 4 : 3;
                final nonOtherCategories = allCategories
                    .where((c) => c.id.toLowerCase() != 'other')
                    .take(maxTopCategories)
                    .toList();

                // Calculate total items: top 3/4 + selected (if not in top) + "Other" (if exists) + "Browse & Create"
                final hasOtherCategory = otherCategory != null;
                final hasSelectedNotInTop =
                    !selectedIsInTop &&
                    _selectedCategory != null &&
                    _selectedCategory!.id.toLowerCase() != 'other';

                final itemCount =
                    nonOtherCategories.length +
                    (hasSelectedNotInTop ? 1 : 0) +
                    (hasOtherCategory ? 1 : 0) +
                    1; // +1 for "Browse & Create"

                return ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: itemCount,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: AppTheme.spacing1),
                  itemBuilder: (context, index) {
                    var currentIndex = 0;

                    // First N positions: non-Other top categories
                    if (index < nonOtherCategories.length) {
                      final category = nonOtherCategories[index];
                      final isSelected =
                          widget.selectedCategoryId == category.id;
                      return _buildCategoryChip(
                        category: category,
                        isSelected: isSelected,
                        theme: theme,
                      );
                    }
                    currentIndex = nonOtherCategories.length;

                    // Next position: Selected category (if not in top categories)
                    if (hasSelectedNotInTop && index == currentIndex) {
                      return _buildCategoryChip(
                        category: _selectedCategory!,
                        isSelected: true,
                        theme: theme,
                      );
                    }
                    if (hasSelectedNotInTop) currentIndex++;

                    // Next position: "Other" category (if it exists)
                    if (hasOtherCategory && index == currentIndex) {
                      final isSelected =
                          widget.selectedCategoryId == otherCategory.id;
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
            },
          ),
        ),
      ],
    );
  }
}
