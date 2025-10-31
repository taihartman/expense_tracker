import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/models/category_customization.dart';
import '../../../../core/repositories/category_customization_repository.dart';
import '../../../trips/domain/models/activity_log.dart';
import '../../../trips/domain/repositories/activity_log_repository.dart';
import 'category_customization_state.dart';

/// Cubit for managing category customizations within a trip
///
/// Handles loading, saving, and resetting category customizations with
/// real-time updates from Firestore. Also logs activity when actorName is provided.
class CategoryCustomizationCubit extends Cubit<CategoryCustomizationState> {
  final CategoryCustomizationRepository _repository;
  final String _tripId;
  final ActivityLogRepository? _activityLogRepository;

  StreamSubscription<List<CategoryCustomization>>? _customizationsSubscription;

  CategoryCustomizationCubit({
    required CategoryCustomizationRepository repository,
    required String tripId,
    ActivityLogRepository? activityLogRepository,
  }) : _repository = repository,
       _tripId = tripId,
       _activityLogRepository = activityLogRepository,
       super(const CategoryCustomizationInitial());

  @override
  Future<void> close() {
    _customizationsSubscription?.cancel();
    return super.close();
  }

  /// Loads all customizations for the current trip
  ///
  /// Subscribes to real-time updates from Firestore
  void loadCustomizations() {
    emit(const CategoryCustomizationLoading());

    _customizationsSubscription?.cancel();
    _customizationsSubscription = _repository
        .getCustomizationsForTrip(_tripId)
        .listen(
          (customizations) {
            final customizationsMap = <String, CategoryCustomization>{};
            for (final customization in customizations) {
              customizationsMap[customization.categoryId] = customization;
            }

            emit(
              CategoryCustomizationLoaded(customizations: customizationsMap),
            );
          },
          onError: (error) {
            emit(
              CategoryCustomizationError(
                type: CategoryCustomizationErrorType.loadFailed,
                message: 'Failed to load category customizations: $error',
              ),
            );
          },
        );
  }

  /// Saves or updates a category customization
  ///
  /// [categoryId] - The global category ID being customized
  /// [customIcon] - Optional icon override
  /// [customColor] - Optional color override
  /// [actorName] - Optional actor name for activity logging (non-fatal if fails)
  Future<void> saveCustomization({
    required String categoryId,
    String? customIcon,
    String? customColor,
    String? actorName,
  }) async {
    // Preserve current customizations while saving
    final currentState = state;
    final currentCustomizations = currentState is CategoryCustomizationLoaded
        ? currentState.customizations
        : <String, CategoryCustomization>{};

    emit(const CategoryCustomizationSaving());

    try {
      final customization = CategoryCustomization(
        categoryId: categoryId,
        tripId: _tripId,
        customIcon: customIcon,
        customColor: customColor,
        updatedAt: DateTime.now(),
      );

      await _repository.saveCustomization(customization);

      // Log activity (non-fatal)
      if (_activityLogRepository != null && actorName != null) {
        try {
          await _activityLogRepository.addLog(
            ActivityLog(
              id: '', // Firestore will generate
              tripId: _tripId,
              type: ActivityType.categoryCustomized,
              actorName: actorName,
              description: 'Category customized',
              timestamp: DateTime.now(),
              metadata: {
                'categoryId': categoryId,
                if (customIcon != null) 'customIcon': customIcon,
                if (customColor != null) 'customColor': customColor,
              },
            ),
          );
        } catch (e) {
          // Activity logging failure should not prevent customization save
          // Silent failure - logging is secondary
        }
      }

      // Optimistically update UI with new customization
      // Stream subscription will sync with Firestore as source of truth
      final updatedCustomizations = Map<String, CategoryCustomization>.from(
        currentCustomizations,
      );
      updatedCustomizations[categoryId] = customization;
      emit(CategoryCustomizationLoaded(customizations: updatedCustomizations));
    } catch (e) {
      emit(
        CategoryCustomizationError(
          type: CategoryCustomizationErrorType.saveFailed,
          message: 'Failed to save category customization: $e',
        ),
      );
    }
  }

  /// Resets a category customization, reverting to global defaults
  ///
  /// [categoryId] - The category ID to reset
  /// [actorName] - Optional actor name for activity logging (non-fatal if fails)
  Future<void> resetCustomization({
    required String categoryId,
    String? actorName,
  }) async {
    // Preserve current customizations while resetting
    final currentState = state;
    final currentCustomizations = currentState is CategoryCustomizationLoaded
        ? currentState.customizations
        : <String, CategoryCustomization>{};

    emit(const CategoryCustomizationResetting());

    try {
      await _repository.deleteCustomization(_tripId, categoryId);

      // Log activity (non-fatal)
      if (_activityLogRepository != null && actorName != null) {
        try {
          await _activityLogRepository.addLog(
            ActivityLog(
              id: '', // Firestore will generate
              tripId: _tripId,
              type: ActivityType.categoryResetToDefault,
              actorName: actorName,
              description: 'Category reset to default',
              timestamp: DateTime.now(),
              metadata: {'categoryId': categoryId},
            ),
          );
        } catch (e) {
          // Activity logging failure should not prevent reset
          // Silent failure - logging is secondary
        }
      }

      // Optimistically remove customization from UI
      // Stream subscription will sync with Firestore as source of truth
      final updatedCustomizations = Map<String, CategoryCustomization>.from(
        currentCustomizations,
      );
      updatedCustomizations.remove(categoryId);
      emit(CategoryCustomizationLoaded(customizations: updatedCustomizations));
    } catch (e) {
      emit(
        CategoryCustomizationError(
          type: CategoryCustomizationErrorType.resetFailed,
          message: 'Failed to reset category customization: $e',
        ),
      );
    }
  }

  /// Gets a customization for a specific category
  ///
  /// Returns null if no customization exists or state is not loaded
  CategoryCustomization? getCustomization(String categoryId) {
    final currentState = state;
    if (currentState is CategoryCustomizationLoaded) {
      return currentState.customizations[categoryId];
    }
    return null;
  }

  /// Checks if a category has any customization
  ///
  /// Returns false if no customization exists or state is not loaded
  bool isCustomized(String categoryId) {
    final customization = getCustomization(categoryId);
    return customization != null;
  }
}
