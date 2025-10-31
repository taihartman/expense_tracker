import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/utils/category_display_helper.dart';
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
      case 'local_cafe':
        return Icons.local_cafe;
      case 'flight':
        return Icons.flight;
      case 'train':
        return Icons.train;
      case 'directions_bus':
        return Icons.directions_bus;
      case 'local_taxi':
        return Icons.local_taxi;
      case 'local_gas_station':
        return Icons.local_gas_station;
      case 'shopping_cart':
        return Icons.shopping_cart;
      case 'local_grocery_store':
        return Icons.local_grocery_store;
      case 'local_mall':
        return Icons.local_mall;
      case 'movie':
        return Icons.movie;
      case 'theater_comedy':
        return Icons.theater_comedy;
      case 'sports_soccer':
        return Icons.sports_soccer;
      case 'fitness_center':
        return Icons.fitness_center;
      case 'spa':
        return Icons.spa;
      case 'local_hospital':
        return Icons.local_hospital;
      case 'local_pharmacy':
        return Icons.local_pharmacy;
      case 'school':
        return Icons.school;
      case 'work':
        return Icons.work;
      case 'computer':
        return Icons.computer;
      case 'phone_android':
        return Icons.phone_android;
      case 'home':
        return Icons.home;
      case 'pets':
        return Icons.pets;
      case 'child_care':
        return Icons.child_care;
      case 'local_florist':
        return Icons.local_florist;
      case 'fastfood':
        return Icons.fastfood;
      case 'local_pizza':
        return Icons.local_pizza;
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
                  _getIconData(displayCategory.icon),
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

                // Color Indicator (tappable)
                InkWell(
                  onTap: () => _showColorPicker(context),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _getColor(displayCategory.color),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outline,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(AppTheme.spacing1),
                    ),
                    child: ColoredBox(color: _getColor(displayCategory.color)),
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

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Select Icon'),
        content: SizedBox(
          width: double.maxFinite,
          child: CategoryIconPicker(
            selectedIcon: customization?.customIcon ?? category.icon,
            onIconSelected: (icon) {
              cubit.saveCustomization(
                categoryId: category.id,
                customIcon: icon,
                customColor: customization?.customColor,
                actorName: null, // TODO: Get from TripCubit
              );
              Navigator.of(dialogContext).pop();
            },
          ),
        ),
      ),
    );
  }

  void _showColorPicker(BuildContext context) {
    final cubit = context.read<CategoryCustomizationCubit>();
    final customization = cubit.getCustomization(category.id);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Select Color'),
        content: SizedBox(
          width: double.maxFinite,
          child: CategoryColorPicker(
            selectedColor: customization?.customColor ?? category.color,
            onColorSelected: (color) {
              cubit.saveCustomization(
                categoryId: category.id,
                customIcon: customization?.customIcon,
                customColor: color,
                actorName: null, // TODO: Get from TripCubit
              );
              Navigator.of(dialogContext).pop();
            },
          ),
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
