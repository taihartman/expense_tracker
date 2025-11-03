import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/models/category.dart';
import '../cubit/category_cubit.dart';
import '../cubit/category_state.dart';
import '../cubit/category_customization_cubit.dart';
import 'category_creation_bottom_sheet.dart';
import 'category_icon_picker.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/l10n/l10n_extensions.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../shared/utils/icon_helper.dart';
import '../../../../shared/utils/category_display_helper.dart';

/// Bottom sheet for browsing and searching all available categories
///
/// Features:
/// - DraggableScrollableSheet for mobile-friendly interaction
/// - Real-time search with debouncing
/// - Shimmer loading state
/// - Empty state handling
/// - Error state handling
/// - Category selection with auto-dismiss
/// - Conditional icon picker based on user customization history
class CategoryBrowserBottomSheet extends StatefulWidget {
  final ValueChanged<Category> onCategorySelected;
  final String tripId;

  const CategoryBrowserBottomSheet({
    required this.onCategorySelected,
    required this.tripId,
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

  Future<void> _onCategoryTap(Category category) async {
    debugPrint(
      '🎯 [CategoryBrowser] Category tapped: ${category.name} (${category.id})',
    );

    // Get userId from auth service
    final authService = context.read<AuthService>();
    final userId = authService.getAuthUidForRateLimiting();

    // If no userId, treat as first-time (show icon picker)
    if (userId == null) {
      debugPrint('⚠️ [CategoryBrowser] No userId, showing icon picker');
      await _showIconPickerForCategory(category, null);
      return;
    }

    // Check if user has customized this category before
    final customizationCubit = context.read<CategoryCustomizationCubit?>();
    bool hasCustomized = false;

    if (customizationCubit != null) {
      hasCustomized = await customizationCubit.hasUserCustomized(
        category.id,
        userId,
      );
      debugPrint(
        '🔍 [CategoryBrowser] User $userId has customized ${category.id}: $hasCustomized',
      );
    }

    if (!mounted) return;

    // If user has NOT customized before, show icon picker first
    if (!hasCustomized) {
      debugPrint(
        '🎨 [CategoryBrowser] First time selecting ${category.name}, showing icon picker',
      );
      await _showIconPickerForCategory(category, userId);
      return; // Icon picker handles selection + dismissal
    }

    // User has customized before → Direct selection
    debugPrint(
      '✅ [CategoryBrowser] User has customized before, direct selection',
    );
    widget.onCategorySelected(category);
    debugPrint('👋 [CategoryBrowser] Calling Navigator.pop()');
    Navigator.of(context).pop(); // Dismiss bottom sheet
    debugPrint('✅ [CategoryBrowser] Navigator.pop() completed');
  }

  /// Shows icon picker for first-time category selection
  ///
  /// When a user selects a category for the first time, show them an icon
  /// picker to customize the icon. The most popular icon is pre-selected.
  /// After confirmation, save the customization and proceed with selection.
  Future<void> _showIconPickerForCategory(
    Category category,
    String? userId,
  ) async {
    final theme = Theme.of(context);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        // Default to category's current icon (most popular via voting system)
        String currentSelectedIcon = category.icon;

        return StatefulBuilder(
          builder: (context, setSheetState) {
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

                      // Title bar
                      Padding(
                        padding: const EdgeInsets.all(AppTheme.spacing2),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Customize "${category.name}" Icon',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => Navigator.of(sheetContext).pop(),
                            ),
                          ],
                        ),
                      ),

                      const Divider(height: 1),

                      // Icon picker
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(AppTheme.spacing2),
                          child: CategoryIconPicker(
                            selectedIcon: currentSelectedIcon,
                            scrollController: scrollController,
                            onIconSelected: (selectedIcon) {
                              debugPrint(
                                '🎨 [CategoryBrowser] Icon selected: $selectedIcon',
                              );
                              setSheetState(() {
                                currentSelectedIcon = selectedIcon;
                              });
                            },
                          ),
                        ),
                      ),

                      // Action buttons
                      Padding(
                        padding: const EdgeInsets.all(AppTheme.spacing2),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.of(sheetContext).pop(),
                              child: Text(context.l10n.commonCancel),
                            ),
                            const SizedBox(width: AppTheme.spacing1),
                            FilledButton(
                              onPressed: () async {
                                debugPrint(
                                  '💾 [CategoryBrowser] Saving customization: ${category.id} → $currentSelectedIcon',
                                );

                                // Save customization
                                final customizationCubit =
                                    this.context.read<CategoryCustomizationCubit?>();

                                if (customizationCubit != null && userId != null) {
                                  await customizationCubit.saveCustomization(
                                    categoryId: category.id,
                                    customIcon: currentSelectedIcon,
                                    userId: userId,
                                    // Note: actorName not needed for icon customization
                                  );
                                }

                                // Close icon picker sheet
                                if (sheetContext.mounted) {
                                  Navigator.of(sheetContext).pop();
                                }

                                // Proceed with category selection
                                debugPrint(
                                  '✅ [CategoryBrowser] Customization saved, proceeding with selection',
                                );
                                widget.onCategorySelected(category);

                                // Close browser sheet
                                if (mounted) {
                                  Navigator.of(this.context).pop();
                                }
                              },
                              child: Text(context.l10n.commonConfirm),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
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
                    hintText: context.l10n.categoryBrowserSearchHint,
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

              // Category list
              Expanded(
                child: BlocBuilder<CategoryCubit, CategoryState>(
                  // Prevent rebuilds after widget disposal (when navigating away)
                  // This fixes "Trying to render a disposed EngineFlutterView" error
                  buildWhen: (previous, current) {
                    // Allow initial load and search results
                    if (current is CategoryInitial ||
                        current is CategoryLoadingTop ||
                        current is CategorySearchResults ||
                        current is CategoryError) {
                      return true;
                    }
                    // Prevent rebuild when transitioning from search back to top categories
                    // This happens after Navigator.pop() when search stream completes
                    if (current is CategoryTopLoaded && previous is CategorySearchResults) {
                      return false;
                    }
                    return true;
                  },
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
                      final query = state.query;

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
                                  query.isNotEmpty
                                      ? context.l10n.categoryBrowserNoResults
                                      : 'Start typing to search categories',
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                if (query.isNotEmpty) ...[
                                  const SizedBox(height: AppTheme.spacing2),
                                  FilledButton.icon(
                                    onPressed: () async {
                                      // Open CategoryCreationBottomSheet with pre-filled name
                                      await showModalBottomSheet(
                                        context: context,
                                        isScrollControlled: true,
                                        builder: (creationContext) =>
                                            BlocProvider<CategoryCubit>.value(
                                          value: context.read<CategoryCubit>(),
                                          child: CategoryCreationBottomSheet(
                                            initialName: query,
                                            onCategoryCreated: () {
                                              // Refresh categories list after creation
                                              context.read<CategoryCubit>().searchCategories('');
                                              // Close browser sheet
                                              Navigator.of(context).pop();
                                            },
                                          ),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.add),
                                    label: Text(
                                      context.l10n.categoryBrowserCreateNew(query),
                                    ),
                                  ),
                                ],
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

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: color.withValues(alpha: 0.2),
                              child: Icon(icon, color: color),
                            ),
                            title: Text(
                              displayCategory.name,
                              semanticsLabel: displayCategory.name,
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
