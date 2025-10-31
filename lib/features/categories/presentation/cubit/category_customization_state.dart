import 'package:equatable/equatable.dart';
import '../../../../core/models/category_customization.dart';

/// Base state for category customization
abstract class CategoryCustomizationState extends Equatable {
  const CategoryCustomizationState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class CategoryCustomizationInitial extends CategoryCustomizationState {
  const CategoryCustomizationInitial();
}

/// Loading customizations from Firestore
class CategoryCustomizationLoading extends CategoryCustomizationState {
  const CategoryCustomizationLoading();
}

/// Customizations loaded successfully
class CategoryCustomizationLoaded extends CategoryCustomizationState {
  final Map<String, CategoryCustomization> customizations;

  const CategoryCustomizationLoaded({
    required this.customizations,
  });

  @override
  List<Object?> get props => [customizations];
}

/// Saving a customization
class CategoryCustomizationSaving extends CategoryCustomizationState {
  const CategoryCustomizationSaving();
}

/// Resetting a customization
class CategoryCustomizationResetting extends CategoryCustomizationState {
  const CategoryCustomizationResetting();
}

/// Error state
class CategoryCustomizationError extends CategoryCustomizationState {
  final CategoryCustomizationErrorType type;
  final String message;

  const CategoryCustomizationError({
    required this.type,
    required this.message,
  });

  @override
  List<Object?> get props => [type, message];
}

/// Types of errors that can occur
enum CategoryCustomizationErrorType {
  loadFailed,
  saveFailed,
  resetFailed,
}
