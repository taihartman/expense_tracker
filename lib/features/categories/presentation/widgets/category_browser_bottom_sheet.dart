import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/models/category.dart';
import '../cubit/category_cubit.dart';
import '../cubit/category_state.dart';
import 'category_creation_bottom_sheet.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/l10n/l10n_extensions.dart';

/// Bottom sheet for browsing and searching all available categories
///
/// Features:
/// - DraggableScrollableSheet for mobile-friendly interaction
/// - Real-time search with debouncing
/// - Shimmer loading state
/// - Empty state handling
/// - Error state handling
/// - Category selection with auto-dismiss
class CategoryBrowserBottomSheet extends StatefulWidget {
  final ValueChanged<Category> onCategorySelected;

  const CategoryBrowserBottomSheet({
    required this.onCategorySelected,
    super.key,
  });

  @override
  State<CategoryBrowserBottomSheet> createState() =>
      _CategoryBrowserBottomSheetState();
}

class _CategoryBrowserBottomSheetState
    extends State<CategoryBrowserBottomSheet> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load all categories on init (empty query)
    context.read<CategoryCubit>().searchCategories('');

    // Listen to search field changes
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    context.read<CategoryCubit>().searchCategories(_searchController.text);
  }

  void _onCategoryTap(Category category) {
    widget.onCategorySelected(category);
    Navigator.of(context).pop(); // Dismiss bottom sheet
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppTheme.spacing2),
            ),
          ),
          child: Column(
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.only(top: AppTheme.spacing1),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.4,
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.all(AppTheme.spacing2),
                child: Row(
                  children: [
                    Text(
                      'Select Category',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),

              // Search field
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacing2,
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search categories...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.spacing1),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: AppTheme.spacing2),

              // Create new category button
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacing2,
                ),
                child: OutlinedButton.icon(
                  onPressed: () async {
                    // Open CategoryCreationBottomSheet
                    await showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (creationContext) =>
                          BlocProvider<CategoryCubit>.value(
                            value: context.read<CategoryCubit>(),
                            child: CategoryCreationBottomSheet(
                              onCategoryCreated: () {
                                // Refresh categories list after creation
                                context.read<CategoryCubit>().searchCategories(
                                  _searchController.text,
                                );
                              },
                            ),
                          ),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: Text(context.l10n.categoryCreationButtonCreateNew),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
              ),

              const SizedBox(height: AppTheme.spacing2),

              // Category list
              Expanded(
                child: BlocBuilder<CategoryCubit, CategoryState>(
                  builder: (context, state) {
                    // Loading state
                    if (state is CategoryInitial) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    // Error state
                    if (state is CategoryError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(AppTheme.spacing3),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 64,
                                color: theme.colorScheme.error,
                              ),
                              const SizedBox(height: AppTheme.spacing2),
                              Text(
                                state.message,
                                style: theme.textTheme.bodyLarge,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    // Search results state
                    if (state is CategorySearchResults) {
                      final categories = state.results;

                      // Empty state
                      if (categories.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(AppTheme.spacing3),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.search_off,
                                  size: 64,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(height: AppTheme.spacing2),
                                Text(
                                  'No categories found',
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      // Category list
                      return ListView.builder(
                        controller: scrollController,
                        itemCount: categories.length,
                        itemBuilder: (context, index) {
                          final category = categories[index];
                          final color = _getColor(category.color);
                          final icon = _getIconData(category.icon);

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: color.withValues(alpha: 0.2),
                              child: Icon(icon, color: color),
                            ),
                            title: Text(
                              category.name,
                              semanticsLabel: category.name,
                            ),
                            subtitle: Text(
                              'Used ${category.usageCount} times',
                              style: theme.textTheme.bodySmall,
                            ),
                            onTap: () => _onCategoryTap(category),
                          );
                        },
                      );
                    }

                    // Fallback
                    return const Center(child: CircularProgressIndicator());
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
