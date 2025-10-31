import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/category_cubit.dart';
import '../cubit/category_state.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/validators/category_validator.dart';
import '../../../../core/l10n/l10n_extensions.dart';
import '../../domain/models/category.dart';
import '../../domain/repositories/category_repository.dart';
import '../../../../core/repositories/category_customization_repository.dart';
import 'category_icon_picker.dart';
import 'category_color_picker.dart';

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

  // Similar category detection
  List<SimilarCategoryMatch> _similarCategories = [];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  /// Check for similar categories as user types
  Future<void> _checkForSimilarCategories(String name) async {
    if (name.trim().length < 3) {
      // Don't check until user has typed at least 3 characters
      setState(() {
        _similarCategories = [];
      });
      return;
    }

    try {
      final repository = context.read<CategoryRepository>();
      final matches = await repository.findSimilarCategories(name);

      if (mounted) {
        setState(() {
          _similarCategories = matches;
        });
      }
    } catch (e) {
      // Silent failure - if similarity check fails, just continue
      if (mounted) {
        setState(() {
          _similarCategories = [];
        });
      }
    }
  }

  /// User selected an existing similar category - show icon picker
  Future<void> _useExistingCategory(Category category) async {
    try {
      // Get the most popular icon for this category (or use global icon as fallback)
      final repository = context.read<CategoryRepository>();
      final customizationRepository = context
          .read<CategoryCustomizationRepository>();

      final mostPopularIcon = await repository.getMostPopularIcon(category.id);
      final defaultIcon = mostPopularIcon ?? category.icon;

      if (!mounted) return;

      // Show icon picker dialog with most popular icon preselected
      await showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text('Customize "${category.name}" Icon'),
          content: SizedBox(
            width: double.maxFinite,
            child: CategoryIconPicker(
              selectedIcon: defaultIcon,
              onIconSelected: (selectedIcon) async {
                // Record the icon preference vote
                try {
                  await customizationRepository.recordIconPreference(
                    category.id,
                    selectedIcon,
                  );
                } catch (e) {
                  // Silent failure - voting is non-critical
                }

                // Close the dialog and the creation sheet
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }
                if (mounted) {
                  widget.onCategoryCreated();
                  Navigator.of(context).pop();
                }
              },
            ),
          ),
        ),
      );
    } catch (e) {
      // If anything fails, just close the sheet
      if (mounted) {
        widget.onCategoryCreated();
        Navigator.of(context).pop();
      }
    }
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
        _validateName(_nameController.text) == null &&
        _similarCategories.isEmpty; // Disable if similar category found
  }

  void _onCreateTapped() {
    setState(() {
      _nameError = _validateName(_nameController.text);
    });

    if (_nameError == null) {
      // Call cubit to create category
      // Note: userId is obtained internally by the cubit from AuthService
      context.read<CategoryCubit>().createCategory(
        name: _nameController.text.trim(),
        icon: _selectedIcon,
        color: _selectedColor,
      );
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
                                  // Check for similar categories
                                  _checkForSimilarCategories(value);
                                },
                              ),

                              const SizedBox(height: AppTheme.spacing2),

                              // Similar Category Warning
                              if (_similarCategories.isNotEmpty)
                                _buildSimilarityWarning(theme),

                              const SizedBox(height: AppTheme.spacing2),

                              // Icon picker
                              Text(
                                context.l10n.categoryCreationFieldIcon,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: AppTheme.spacing1),
                              CategoryIconPicker(
                                selectedIcon: _selectedIcon,
                                onIconSelected: (iconName) {
                                  setState(() {
                                    _selectedIcon = iconName;
                                  });
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
                              CategoryColorPicker(
                                selectedColor: _selectedColor,
                                onColorSelected: (colorHex) {
                                  setState(() {
                                    _selectedColor = colorHex;
                                  });
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

  /// Build similarity warning banner with existing category suggestions
  Widget _buildSimilarityWarning(ThemeData theme) {
    final topMatch = _similarCategories.first;

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing2),
      decoration: BoxDecoration(
        color: theme.colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(AppTheme.spacing1),
        border: Border.all(color: theme.colorScheme.tertiary, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: theme.colorScheme.onTertiaryContainer,
                size: 20,
              ),
              const SizedBox(width: AppTheme.spacing1),
              Expanded(
                child: Text(
                  'Category already exists',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.onTertiaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing1),
          Text(
            '"${topMatch.category.name}" already exists (used ${topMatch.category.usageCount} times)',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onTertiaryContainer,
            ),
          ),
          const SizedBox(height: AppTheme.spacing2),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _useExistingCategory(topMatch.category),
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.onTertiaryContainer,
                foregroundColor: theme.colorScheme.tertiaryContainer,
              ),
              icon: const Icon(Icons.edit, size: 18),
              label: const Text('Use & Customize Icon'),
            ),
          ),
        ],
      ),
    );
  }
}
