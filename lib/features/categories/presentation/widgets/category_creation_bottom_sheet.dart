import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/category_cubit.dart';
import '../cubit/category_state.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/validators/category_validator.dart';
import '../../../../core/l10n/l10n_extensions.dart';

/// Bottom sheet for creating new custom categories
///
/// Features:
/// - Category name TextField with validation
/// - Icon picker with grid of common icons
/// - Color picker with grid of predefined colors
/// - Form validation (name length, invalid characters)
/// - Error handling (rate limiting, duplicate names, generic errors)
/// - Loading state during creation
/// - Auto-dismiss on success
class CategoryCreationBottomSheet extends StatefulWidget {
  final VoidCallback onCategoryCreated;

  const CategoryCreationBottomSheet({
    required this.onCategoryCreated,
    super.key,
  });

  @override
  State<CategoryCreationBottomSheet> createState() =>
      _CategoryCreationBottomSheetState();
}

class _CategoryCreationBottomSheetState
    extends State<CategoryCreationBottomSheet> {
  final TextEditingController _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // Default selections
  String _selectedIcon = 'category';
  String _selectedColor = '#9E9E9E'; // Grey

  // Validation error
  String? _nameError;

  // Available icons for categories
  final List<Map<String, dynamic>> _availableIcons = [
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
    {'icon': Icons.fastfood, 'name': 'fastfood'},
    {'icon': Icons.local_grocery_store, 'name': 'local_grocery_store'},
    {'icon': Icons.local_pharmacy, 'name': 'local_pharmacy'},
    {'icon': Icons.local_hospital, 'name': 'local_hospital'},
    {'icon': Icons.fitness_center, 'name': 'fitness_center'},
    {'icon': Icons.spa, 'name': 'spa'},
    {'icon': Icons.beach_access, 'name': 'beach_access'},
    {'icon': Icons.camera_alt, 'name': 'camera_alt'},
    {'icon': Icons.movie, 'name': 'movie'},
    {'icon': Icons.music_note, 'name': 'music_note'},
    {'icon': Icons.sports_soccer, 'name': 'sports_soccer'},
    {'icon': Icons.pets, 'name': 'pets'},
    {'icon': Icons.school, 'name': 'school'},
    {'icon': Icons.work, 'name': 'work'},
    {'icon': Icons.home, 'name': 'home'},
    {'icon': Icons.phone, 'name': 'phone'},
    {'icon': Icons.laptop, 'name': 'laptop'},
    {'icon': Icons.book, 'name': 'book'},
  ];

  // Available colors for categories
  final List<String> _availableColors = [
    '#9E9E9E', // Grey (default)
    '#F44336', // Red
    '#E91E63', // Pink
    '#9C27B0', // Purple
    '#673AB7', // Deep Purple
    '#3F51B5', // Indigo
    '#2196F3', // Blue
    '#03A9F4', // Light Blue
    '#00BCD4', // Cyan
    '#009688', // Teal
    '#4CAF50', // Green
    '#8BC34A', // Light Green
    '#CDDC39', // Lime
    '#FFEB3B', // Yellow
    '#FFC107', // Amber
    '#FF9800', // Orange
    '#FF5722', // Deep Orange
    '#795548', // Brown
    '#607D8B', // Blue Grey
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Category name cannot be empty';
    }

    // CategoryValidator returns String? directly (error message or null)
    return CategoryValidator.validateCategoryName(value);
  }

  bool get _isFormValid {
    return _nameController.text.trim().isNotEmpty &&
        _validateName(_nameController.text) == null;
  }

  void _onCreateTapped() {
    setState(() {
      _nameError = _validateName(_nameController.text);
    });

    if (_nameError == null) {
      // Call cubit to create category
      context.read<CategoryCubit>().createCategory(
        name: _nameController.text.trim(),
        icon: _selectedIcon,
        color: _selectedColor,
        userId: 'current-user', // TODO: Get from auth
      );
    }
  }

  Color _parseColor(String colorHex) {
    try {
      return Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocListener<CategoryCubit, CategoryState>(
      listener: (context, state) {
        if (state is CategoryCreated) {
          // Success - call callback and dismiss
          widget.onCategoryCreated();
          Navigator.of(context).pop();
        }
      },
      child: DraggableScrollableSheet(
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
                        context.l10n.categoryCreationDialogTitle,
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

                // Content (scrollable)
                Expanded(
                  child: BlocBuilder<CategoryCubit, CategoryState>(
                    builder: (context, state) {
                      // Show error message if present
                      Widget? errorWidget;
                      if (state is CategoryError) {
                        errorWidget = Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: AppTheme.spacing2,
                            vertical: AppTheme.spacing1,
                          ),
                          padding: const EdgeInsets.all(AppTheme.spacing2),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(
                              AppTheme.spacing1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: theme.colorScheme.error,
                              ),
                              const SizedBox(width: AppTheme.spacing1),
                              Expanded(
                                child: Text(
                                  state.message,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.error,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return SingleChildScrollView(
                        controller: scrollController,
                        padding: const EdgeInsets.all(AppTheme.spacing2),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Error message
                              if (errorWidget != null) ...[
                                errorWidget,
                                const SizedBox(height: AppTheme.spacing2),
                              ],

                              // Name TextField
                              TextField(
                                controller: _nameController,
                                decoration: InputDecoration(
                                  labelText:
                                      context.l10n.categoryCreationFieldName,
                                  hintText: context
                                      .l10n
                                      .categoryCreationFieldNameHint,
                                  errorText: _nameError,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppTheme.spacing1,
                                    ),
                                  ),
                                ),
                                onChanged: (value) {
                                  setState(() {
                                    _nameError = _validateName(value);
                                  });
                                },
                              ),

                              const SizedBox(height: AppTheme.spacing3),

                              // Icon picker
                              Text(
                                context.l10n.categoryCreationFieldIcon,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: AppTheme.spacing1),
                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 6,
                                      crossAxisSpacing: AppTheme.spacing1,
                                      mainAxisSpacing: AppTheme.spacing1,
                                    ),
                                itemCount: _availableIcons.length,
                                itemBuilder: (context, index) {
                                  final iconData = _availableIcons[index];
                                  final isSelected =
                                      _selectedIcon == iconData['name'];

                                  return InkWell(
                                    onTap: () {
                                      setState(() {
                                        _selectedIcon = iconData['name'];
                                      });
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: isSelected
                                              ? theme.colorScheme.primary
                                              : theme.colorScheme.outline,
                                          width: isSelected ? 2 : 1,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          AppTheme.spacing1,
                                        ),
                                        color: isSelected
                                            ? theme.colorScheme.primaryContainer
                                            : null,
                                      ),
                                      child: Icon(
                                        iconData['icon'],
                                        color: isSelected
                                            ? theme.colorScheme.primary
                                            : theme
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                      ),
                                    ),
                                  );
                                },
                              ),

                              const SizedBox(height: AppTheme.spacing3),

                              // Color picker
                              Text(
                                context.l10n.categoryCreationFieldColor,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: AppTheme.spacing1),
                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 6,
                                      crossAxisSpacing: AppTheme.spacing1,
                                      mainAxisSpacing: AppTheme.spacing1,
                                    ),
                                itemCount: _availableColors.length,
                                itemBuilder: (context, index) {
                                  final colorHex = _availableColors[index];
                                  final isSelected = _selectedColor == colorHex;
                                  final color = _parseColor(colorHex);

                                  return InkWell(
                                    onTap: () {
                                      setState(() {
                                        _selectedColor = colorHex;
                                      });
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: color,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isSelected
                                              ? theme.colorScheme.primary
                                              : Colors.transparent,
                                          width: 3,
                                        ),
                                      ),
                                      child: isSelected
                                          ? const Icon(
                                              Icons.check,
                                              color: Colors.white,
                                            )
                                          : null,
                                    ),
                                  );
                                },
                              ),

                              const SizedBox(height: AppTheme.spacing3),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Create button (fixed at bottom)
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacing2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    border: Border(
                      top: BorderSide(color: theme.colorScheme.outlineVariant),
                    ),
                  ),
                  child: BlocBuilder<CategoryCubit, CategoryState>(
                    builder: (context, state) {
                      final isCreating = state is CategoryCreating;

                      return SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: (_isFormValid && !isCreating)
                              ? _onCreateTapped
                              : null,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              vertical: AppTheme.spacing2,
                            ),
                          ),
                          child: isCreating
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(context.l10n.categoryCreationButtonCreate),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
