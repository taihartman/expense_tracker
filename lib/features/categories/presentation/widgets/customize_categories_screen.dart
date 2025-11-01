import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/utils/category_display_helper.dart';
import '../../../../shared/utils/icon_helper.dart';
import '../../domain/models/category.dart';
import '../cubit/category_customization_cubit.dart';
import '../cubit/category_customization_state.dart';
import 'category_color_picker.dart';
import 'category_icon_picker.dart';

/// Screen for customizing category icons and colors for a specific trip
///
/// Allows users to override global category appearance on a per-trip basis
/// without affecting other trips.
class CustomizeCategoriesScreen extends StatelessWidget {
  final String tripId;
  final List<Category> categories;

  const CustomizeCategoriesScreen({
    super.key,
    required this.tripId,
    required this.categories,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Customize Categories')),
      body: BlocBuilder<CategoryCustomizationCubit, CategoryCustomizationState>(
        builder: (context, state) {
          if (state is CategoryCustomizationLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is CategoryCustomizationError) {
            return Center(
              child: Text(
                state.message,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            );
          }

          if (categories.isEmpty) {
            return const Center(
              child: Text('No categories used in this trip yet'),
            );
          }

          return SingleChildScrollView(
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                return _CategoryCustomizationTile(
                  category: category,
                  tripId: tripId,
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _CategoryCustomizationTile extends StatelessWidget {
  final Category category;
  final String tripId;

  const _CategoryCustomizationTile({
    required this.category,
    required this.tripId,
  });

  Color _getColor(String colorHex) {
    try {
      return Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<CategoryCustomizationCubit>();
    final customization = cubit.getCustomization(category.id);
    final isCustomized = cubit.isCustomized(category.id);

    final displayCategory = DisplayCategory.fromGlobalAndCustomization(
      globalCategory: category,
      customization: customization,
    );

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacing2,
        vertical: AppTheme.spacing1,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Icon, Name, Badge
            Row(
              children: [
                Icon(
                  IconHelper.getIconData(displayCategory.icon),
                  size: 32,
                  color: _getColor(displayCategory.color),
                ),
                const SizedBox(width: AppTheme.spacing2),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayCategory.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isCustomized ? 'Customized' : 'Using global default',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isCustomized
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacing2),

            // Edit Controls: Icon and Color
            Row(
              children: [
                // Icon Edit Button
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showIconPicker(context),
                    icon: const Icon(Icons.edit),
                    label: const Text('Icon'),
                  ),
                ),
                const SizedBox(width: AppTheme.spacing1),

                // Color Edit Button
                OutlinedButton(
                  onPressed: () => _showColorPicker(context),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: _getColor(displayCategory.color),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outline,
                            width: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacing1),
                      const Text('Color'),
                    ],
                  ),
                ),
              ],
            ),

            // Reset Button (only if customized)
            if (isCustomized) ...[
              const SizedBox(height: AppTheme.spacing1),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => _resetCustomization(context),
                  child: const Text('Reset to Default'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showIconPicker(BuildContext context) {
    final cubit = context.read<CategoryCustomizationCubit>();
    final customization = cubit.getCustomization(category.id);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            // Title bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Select Icon',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
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
                padding: const EdgeInsets.all(16),
                child: CategoryIconPicker(
                  selectedIcon: customization?.customIcon ?? category.icon,
                  onIconSelected: (icon) {
                    cubit.saveCustomization(
                      categoryId: category.id,
                      customIcon: icon,
                      customColor: customization?.customColor,
                      actorName: null, // TODO: Get from TripCubit
                    );
                    Navigator.of(sheetContext).pop();
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showColorPicker(BuildContext context) {
    final cubit = context.read<CategoryCustomizationCubit>();
    final customization = cubit.getCustomization(category.id);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            // Title bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Select Color',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
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
            // Color picker
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: CategoryColorPicker(
                  selectedColor: customization?.customColor ?? category.color,
                  onColorSelected: (color) {
                    cubit.saveCustomization(
                      categoryId: category.id,
                      customIcon: customization?.customIcon,
                      customColor: color,
                      actorName: null, // TODO: Get from TripCubit
                    );
                    Navigator.of(sheetContext).pop();
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _resetCustomization(BuildContext context) {
    final cubit = context.read<CategoryCustomizationCubit>();
    cubit.resetCustomization(
      categoryId: category.id,
      actorName: null, // TODO: Get from TripCubit
    );
  }
}
