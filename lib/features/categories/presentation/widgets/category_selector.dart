import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/models/category.dart';
import '../cubit/category_cubit.dart';
import '../cubit/category_state.dart';
import '../cubit/category_customization_cubit.dart';
import '../cubit/category_customization_state.dart';
import 'category_browser_bottom_sheet.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/l10n/l10n_extensions.dart';
import '../../../../core/services/auth_service.dart';
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
  final String tripId;

  const CategorySelector({
    required this.selectedCategoryId,
    required this.onCategoryChanged,
    required this.tripId,
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
    // Use loadTopCategoriesIfStale() for 24-hour TTL cache
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<CategoryCubit>().loadTopCategoriesIfStale(limit: 5);
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
      final categoryCubit = context.read<CategoryCubit>();

      // First check cache
      var category = categoryCubit.getCategoryById(widget.selectedCategoryId!);

      // If not in cache, load it
      if (category == null) {
        debugPrint(
          '🔄 [CategorySelector] Category not in cache, loading from repository',
        );
        await categoryCubit.loadCategoriesByIds([widget.selectedCategoryId!]);
        category = categoryCubit.getCategoryById(widget.selectedCategoryId!);
      } else {
        debugPrint(
          '✨ [CategorySelector] Category found in cache: ${category.name}',
        );
      }

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
          // Capture providers from current context
          final categoryCubit = context.read<CategoryCubit>();
          final categoryCustomizationCubit = context.read<CategoryCustomizationCubit?>();
          final authService = context.read<AuthService>();

          await showModalBottomSheet<String?>(
            context: context,
            isScrollControlled: true,
            builder: (sheetContext) => MultiRepositoryProvider(
              providers: [
                // Provide AuthService via RepositoryProvider
                RepositoryProvider<AuthService>.value(
                  value: authService,
                ),
              ],
              child: MultiBlocProvider(
                providers: [
                  BlocProvider<CategoryCubit>.value(
                    value: categoryCubit,
                  ),
                  if (categoryCustomizationCubit != null)
                    BlocProvider<CategoryCustomizationCubit>.value(
                      value: categoryCustomizationCubit,
                    ),
                ],
                child: CategoryBrowserBottomSheet(
                  tripId: widget.tripId,
                  onCategorySelected: (category) {
                    widget.onCategoryChanged(category.id);
                    // CategoryBrowserBottomSheet handles its own dismissal
                  },
                ),
              ),
            ),
          );
          // Restore CategoryCubit to CategoryTopLoaded state after sheet closes
          // This ensures new CategorySelector instances can populate their cache
          if (mounted) {
            debugPrint(
              '🔄 [CategorySelector] Browse sheet closed, restoring top categories state',
            );
            context.read<CategoryCubit>().resetToTopCategories();
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

    // Listen to customization changes and rebuild when loaded
    return BlocListener<CategoryCustomizationCubit, CategoryCustomizationState>(
      listener: (context, state) {
        if (state is CategoryCustomizationLoaded && mounted) {
          debugPrint(
            '🎨 [CategorySelector] Customizations loaded, triggering rebuild to show custom icons/colors',
          );
          // Trigger rebuild to show custom icons/colors
          setState(() {});
        }
      },
      child: Column(
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

              // Determine which categories to display
              final List<Category> categoriesToShow;

              // Show loading spinner ONLY on first load (no cache available)
              if (state is CategoryLoadingTop && _cachedCategories == null) {
                return const Center(child: CircularProgressIndicator());
              }

              // For CategoryTopLoaded, use fresh data
              if (state is CategoryTopLoaded) {
                categoriesToShow = state.categories;
              }
              // For ALL other states, use cached data if available
              else if (_cachedCategories != null) {
                categoriesToShow = _cachedCategories!;
                debugPrint(
                  '🔄 [CategorySelector] State: ${state.runtimeType}, using cached ${_cachedCategories!.length} categories',
                );
              }
              // No cache and error/initial state - show fallback
              else {
                return ListView(
                  scrollDirection: Axis.horizontal,
                  children: [_buildOtherChip(isSelected: false, theme: theme)],
                );
              }

              // Ensure selected category is loaded from cache for rendering
              // This fixes race condition where async _loadSelectedCategory() hasn't completed yet
              // When user selects from browse sheet, category is already in cubit cache
              debugPrint(
                '🔍 [CategorySelector] Sync cache check - selectedId: ${widget.selectedCategoryId}, _selectedCategory: ${_selectedCategory?.id}, _selectedCategory.name: ${_selectedCategory?.name}',
              );
              if (widget.selectedCategoryId != null &&
                  (_selectedCategory == null ||
                      _selectedCategory!.id != widget.selectedCategoryId)) {
                debugPrint(
                  '🔎 [CategorySelector] Attempting to load from cache for: ${widget.selectedCategoryId}',
                );
                final categoryFromCache = context
                    .read<CategoryCubit>()
                    .getCategoryById(widget.selectedCategoryId!);
                debugPrint(
                  '🔎 [CategorySelector] Cache result: ${categoryFromCache?.name ?? "NOT FOUND"}',
                );
                if (categoryFromCache != null) {
                  _selectedCategory = categoryFromCache;
                  debugPrint(
                    '🎯 [CategorySelector] Loaded selected category from cache synchronously: ${categoryFromCache.name}',
                  );
                } else {
                  debugPrint(
                    '❌ [CategorySelector] Category NOT in cache: ${widget.selectedCategoryId}',
                  );
                }
              } else {
                debugPrint(
                  '✅ [CategorySelector] _selectedCategory already set correctly: ${_selectedCategory?.name}',
                );
              }

              // Render chips with categories
              {
                final allCategories = categoriesToShow;
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
                // Order: Top 3 popular (non-Other) → Selected (if not in top 3) → "Other" → "Browse & Create"
                final otherCategory = allCategories
                    .where((c) => c.id.toLowerCase() == 'other')
                    .firstOrNull;

                // Get top 3 non-Other categories for rendering
                // We always show top 3, then add selected as extra if needed
                final nonOtherCategories = allCategories
                    .where((c) => c.id.toLowerCase() != 'other')
                    .take(3)
                    .toList();

                // Check if selected category is already in the TOP 3 RENDERED categories
                // (Not in the full cached top 10 - only in what we're actually showing!)
                final selectedIsInTop =
                    widget.selectedCategoryId != null &&
                    nonOtherCategories.any((c) => c.id == widget.selectedCategoryId);

                debugPrint(
                  '📊 [CategorySelector] Rendering logic - selectedId: ${widget.selectedCategoryId}, selectedIsInTop: $selectedIsInTop (in rendered top 3), _selectedCategory: ${_selectedCategory?.name}',
                );

                debugPrint(
                  '📊 [CategorySelector] Top categories (${nonOtherCategories.length}): ${nonOtherCategories.map((c) => c.name).join(", ")}',
                );

                // Calculate total items: top 3/4 + selected (if not in top) + "Other" (if exists) + "Browse & Create"
                final hasOtherCategory = otherCategory != null;
                final hasSelectedNotInTop =
                    !selectedIsInTop &&
                    _selectedCategory != null &&
                    _selectedCategory!.id.toLowerCase() != 'other';

                debugPrint(
                  '📊 [CategorySelector] hasSelectedNotInTop: $hasSelectedNotInTop (will add extra chip: ${_selectedCategory?.name})',
                );

                final itemCount =
                    nonOtherCategories.length +
                    (hasSelectedNotInTop ? 1 : 0) +
                    (hasOtherCategory ? 1 : 0) +
                    1; // +1 for "Browse & Create"

                debugPrint(
                  '📊 [CategorySelector] Total chips to render: $itemCount',
                );


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
                      debugPrint(
                        '🏷️  [CategorySelector] Rendering chip [$index]: ${category.name} (selected: $isSelected)',
                      );
                      return _buildCategoryChip(
                        category: category,
                        isSelected: isSelected,
                        theme: theme,
                      );
                    }
                    currentIndex = nonOtherCategories.length;

                    // Next position: Selected category (if not in top categories)
                    if (hasSelectedNotInTop && index == currentIndex) {
                      debugPrint(
                        '🏷️  [CategorySelector] Rendering EXTRA chip [$index]: ${_selectedCategory!.name} (selected: true)',
                      );
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
                      debugPrint(
                        '🏷️  [CategorySelector] Rendering OTHER chip [$index]: ${otherCategory.name} (selected: $isSelected)',
                      );
                      return _buildCategoryChip(
                        category: otherCategory,
                        isSelected: isSelected,
                        theme: theme,
                      );
                    }

                    // Last position: "Browse & Create" button
                    debugPrint(
                      '🏷️  [CategorySelector] Rendering BROWSE chip [$index]',
                    );
                    return _buildOtherChip(isSelected: false, theme: theme);
                  },
                );
              }
            },
          ),
        ),
        ],
      ), // Close Column
    ); // Close BlocListener
  }
}
