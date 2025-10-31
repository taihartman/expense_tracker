import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:expense_tracker/core/models/category_customization.dart';
import 'package:expense_tracker/core/repositories/category_customization_repository.dart';
import 'package:expense_tracker/features/trips/domain/repositories/activity_log_repository.dart';
import 'package:expense_tracker/features/categories/presentation/cubit/category_customization_cubit.dart';
import 'package:expense_tracker/features/categories/presentation/cubit/category_customization_state.dart';

@GenerateMocks([CategoryCustomizationRepository, ActivityLogRepository])
import 'category_customization_cubit_test.mocks.dart';

void main() {
  late CategoryCustomizationCubit cubit;
  late MockCategoryCustomizationRepository mockRepository;
  late MockActivityLogRepository mockActivityLogRepository;

  const testTripId = 'trip-123';
  final now = DateTime(2025, 10, 31, 12, 0, 0);

  final testCustomization1 = CategoryCustomization(
    categoryId: 'cat-1',
    tripId: testTripId,
    customIcon: 'fastfood',
    customColor: '#FF5722',
    updatedAt: now,
  );

  final testCustomization2 = CategoryCustomization(
    categoryId: 'cat-2',
    tripId: testTripId,
    customIcon: 'directions_car',
    updatedAt: now,
  );

  setUp(() {
    mockRepository = MockCategoryCustomizationRepository();
    mockActivityLogRepository = MockActivityLogRepository();

    cubit = CategoryCustomizationCubit(
      repository: mockRepository,
      tripId: testTripId,
      activityLogRepository: mockActivityLogRepository,
    );
  });

  tearDown(() {
    cubit.close();
  });

  group('CategoryCustomizationCubit', () {
    group('loadCustomizations', () {
      test(
        'should emit CategoryCustomizationLoading then CategoryCustomizationLoaded on success',
        () async {
          // Arrange
          when(mockRepository.getCustomizationsForTrip(testTripId))
              .thenAnswer(
                  (_) => Stream.value([testCustomization1, testCustomization2]));

          // Assert
          expect(
            cubit.stream,
            emitsInOrder([
              isA<CategoryCustomizationLoading>(),
              isA<CategoryCustomizationLoaded>()
                  .having(
                    (s) => s.customizations.length,
                    'customizations count',
                    2,
                  )
                  .having(
                    (s) => s.customizations['cat-1']?.customIcon,
                    'cat-1 icon',
                    'fastfood',
                  )
                  .having(
                    (s) => s.customizations['cat-2']?.customIcon,
                    'cat-2 icon',
                    'directions_car',
                  ),
            ]),
          );

          // Act
          cubit.loadCustomizations();
        },
      );

      test('should handle empty customizations', () async {
        // Arrange
        when(mockRepository.getCustomizationsForTrip(testTripId))
            .thenAnswer((_) => Stream.value([]));

        // Assert
        expect(
          cubit.stream,
          emitsInOrder([
            isA<CategoryCustomizationLoading>(),
            isA<CategoryCustomizationLoaded>().having(
              (s) => s.customizations,
              'customizations',
              isEmpty,
            ),
          ]),
        );

        // Act
        cubit.loadCustomizations();
      });

      test('should emit CategoryCustomizationError on failure', () async {
        // Arrange
        when(mockRepository.getCustomizationsForTrip(testTripId))
            .thenAnswer((_) => Stream.error(Exception('Network error')));

        // Assert
        expect(
          cubit.stream,
          emitsInOrder([
            isA<CategoryCustomizationLoading>(),
            isA<CategoryCustomizationError>()
                .having(
                  (s) => s.type,
                  'error type',
                  CategoryCustomizationErrorType.loadFailed,
                )
                .having(
                  (s) => s.message,
                  'error message',
                  contains('Failed to load'),
                ),
          ]),
        );

        // Act
        cubit.loadCustomizations();
      });

      test('should update state when stream emits new data', () async {
        // Arrange
        final stream = Stream.fromIterable([
          [testCustomization1],
          [testCustomization1, testCustomization2],
        ]);

        when(mockRepository.getCustomizationsForTrip(testTripId))
            .thenAnswer((_) => stream);

        // Assert
        expect(
          cubit.stream,
          emitsInOrder([
            isA<CategoryCustomizationLoading>(),
            isA<CategoryCustomizationLoaded>().having(
              (s) => s.customizations.length,
              'first update count',
              1,
            ),
            isA<CategoryCustomizationLoaded>().having(
              (s) => s.customizations.length,
              'second update count',
              2,
            ),
          ]),
        );

        // Act
        cubit.loadCustomizations();
      });
    });

    group('getCustomization', () {
      test('should return customization from loaded state', () async {
        // Arrange
        when(mockRepository.getCustomizationsForTrip(testTripId))
            .thenAnswer((_) => Stream.value([testCustomization1]));

        cubit.loadCustomizations();
        await Future.delayed(const Duration(milliseconds: 100));

        // Act
        final result = cubit.getCustomization('cat-1');

        // Assert
        expect(result, isNotNull);
        expect(result!.categoryId, 'cat-1');
        expect(result.customIcon, 'fastfood');
      });

      test('should return null when customization does not exist', () async {
        // Arrange
        when(mockRepository.getCustomizationsForTrip(testTripId))
            .thenAnswer((_) => Stream.value([testCustomization1]));

        cubit.loadCustomizations();
        await Future.delayed(const Duration(milliseconds: 100));

        // Act
        final result = cubit.getCustomization('nonexistent');

        // Assert
        expect(result, isNull);
      });

      test('should return null when state is not loaded', () {
        // Act
        final result = cubit.getCustomization('cat-1');

        // Assert
        expect(result, isNull);
      });
    });

    group('isCustomized', () {
      test('should return true when category has customization', () async {
        // Arrange
        when(mockRepository.getCustomizationsForTrip(testTripId))
            .thenAnswer((_) => Stream.value([testCustomization1]));

        cubit.loadCustomizations();
        await Future.delayed(const Duration(milliseconds: 100));

        // Act
        final result = cubit.isCustomized('cat-1');

        // Assert
        expect(result, isTrue);
      });

      test('should return false when category has no customization', () async {
        // Arrange
        when(mockRepository.getCustomizationsForTrip(testTripId))
            .thenAnswer((_) => Stream.value([testCustomization1]));

        cubit.loadCustomizations();
        await Future.delayed(const Duration(milliseconds: 100));

        // Act
        final result = cubit.isCustomized('cat-999');

        // Assert
        expect(result, isFalse);
      });

      test('should return false when state is not loaded', () {
        // Act
        final result = cubit.isCustomized('cat-1');

        // Assert
        expect(result, isFalse);
      });
    });

    group('saveCustomization', () {
      test('should save customization and log activity', () async {
        // Arrange
        const actorName = 'Alice';
        when(mockRepository.saveCustomization(any))
            .thenAnswer((_) async => Future.value());
        when(mockActivityLogRepository.addLog(any))
            .thenAnswer((_) async => Future.value());

        // Assert
        expect(
          cubit.stream,
          emitsInOrder([
            isA<CategoryCustomizationSaving>(),
            isA<CategoryCustomizationLoaded>(),
          ]),
        );

        // Act
        await cubit.saveCustomization(
          categoryId: 'cat-1',
          customIcon: 'fastfood',
          customColor: '#FF5722',
          actorName: actorName,
        );

        // Verify
        final captured = verify(mockRepository.saveCustomization(captureAny))
            .captured
            .single as CategoryCustomization;
        expect(captured.categoryId, 'cat-1');
        expect(captured.tripId, testTripId);
        expect(captured.customIcon, 'fastfood');
        expect(captured.customColor, '#FF5722');

        verify(mockActivityLogRepository.addLog(any)).called(1);
      });

      test('should save icon-only customization', () async {
        // Arrange
        when(mockRepository.saveCustomization(any))
            .thenAnswer((_) async => Future.value());
        when(mockActivityLogRepository.addLog(any))
            .thenAnswer((_) async => Future.value());

        // Act
        await cubit.saveCustomization(
          categoryId: 'cat-1',
          customIcon: 'restaurant',
          actorName: 'Alice',
        );

        // Verify
        final captured = verify(mockRepository.saveCustomization(captureAny))
            .captured
            .single as CategoryCustomization;
        expect(captured.customIcon, 'restaurant');
        expect(captured.customColor, isNull);
      });

      test('should save color-only customization', () async {
        // Arrange
        when(mockRepository.saveCustomization(any))
            .thenAnswer((_) async => Future.value());
        when(mockActivityLogRepository.addLog(any))
            .thenAnswer((_) async => Future.value());

        // Act
        await cubit.saveCustomization(
          categoryId: 'cat-1',
          customColor: '#2196F3',
          actorName: 'Alice',
        );

        // Verify
        final captured = verify(mockRepository.saveCustomization(captureAny))
            .captured
            .single as CategoryCustomization;
        expect(captured.customIcon, isNull);
        expect(captured.customColor, '#2196F3');
      });

      test('should not log activity when actorName is null', () async {
        // Arrange
        when(mockRepository.saveCustomization(any))
            .thenAnswer((_) async => Future.value());

        // Act
        await cubit.saveCustomization(
          categoryId: 'cat-1',
          customIcon: 'fastfood',
        );

        // Verify
        verifyNever(mockActivityLogRepository.addLog(any));
      });

      test('should not fail when activity logging fails', () async {
        // Arrange
        when(mockRepository.saveCustomization(any))
            .thenAnswer((_) async => Future.value());
        when(mockActivityLogRepository.addLog(any))
            .thenThrow(Exception('Logging failed'));

        // Act & Assert (should not throw)
        await cubit.saveCustomization(
          categoryId: 'cat-1',
          customIcon: 'fastfood',
          actorName: 'Alice',
        );

        // Verify save still succeeded
        verify(mockRepository.saveCustomization(any)).called(1);
      });

      test('should emit error when save fails', () async {
        // Arrange
        when(mockRepository.saveCustomization(any))
            .thenThrow(Exception('Save failed'));

        // Assert
        expect(
          cubit.stream,
          emitsInOrder([
            isA<CategoryCustomizationSaving>(),
            isA<CategoryCustomizationError>()
                .having(
                  (s) => s.type,
                  'error type',
                  CategoryCustomizationErrorType.saveFailed,
                )
                .having(
                  (s) => s.message,
                  'error message',
                  contains('Failed to save'),
                ),
          ]),
        );

        // Act
        await cubit.saveCustomization(
          categoryId: 'cat-1',
          customIcon: 'fastfood',
        );
      });
    });

    group('resetCustomization', () {
      test('should delete customization and log activity', () async {
        // Arrange
        const actorName = 'Bob';
        when(mockRepository.deleteCustomization(testTripId, 'cat-1'))
            .thenAnswer((_) async => Future.value());
        when(mockActivityLogRepository.addLog(any))
            .thenAnswer((_) async => Future.value());

        // Assert
        expect(
          cubit.stream,
          emitsInOrder([
            isA<CategoryCustomizationResetting>(),
            isA<CategoryCustomizationLoaded>(),
          ]),
        );

        // Act
        await cubit.resetCustomization(
          categoryId: 'cat-1',
          actorName: actorName,
        );

        // Verify
        verify(mockRepository.deleteCustomization(testTripId, 'cat-1'))
            .called(1);
        verify(mockActivityLogRepository.addLog(any)).called(1);
      });

      test('should not log activity when actorName is null', () async {
        // Arrange
        when(mockRepository.deleteCustomization(testTripId, 'cat-1'))
            .thenAnswer((_) async => Future.value());

        // Act
        await cubit.resetCustomization(categoryId: 'cat-1');

        // Verify
        verifyNever(mockActivityLogRepository.addLog(any));
      });

      test('should not fail when activity logging fails', () async {
        // Arrange
        when(mockRepository.deleteCustomization(testTripId, 'cat-1'))
            .thenAnswer((_) async => Future.value());
        when(mockActivityLogRepository.addLog(any))
            .thenThrow(Exception('Logging failed'));

        // Act & Assert (should not throw)
        await cubit.resetCustomization(
          categoryId: 'cat-1',
          actorName: 'Bob',
        );

        // Verify delete still succeeded
        verify(mockRepository.deleteCustomization(testTripId, 'cat-1'))
            .called(1);
      });

      test('should emit error when delete fails', () async {
        // Arrange
        when(mockRepository.deleteCustomization(testTripId, 'cat-1'))
            .thenThrow(Exception('Delete failed'));

        // Assert
        expect(
          cubit.stream,
          emitsInOrder([
            isA<CategoryCustomizationResetting>(),
            isA<CategoryCustomizationError>()
                .having(
                  (s) => s.type,
                  'error type',
                  CategoryCustomizationErrorType.resetFailed,
                )
                .having(
                  (s) => s.message,
                  'error message',
                  contains('Failed to reset'),
                ),
          ]),
        );

        // Act
        await cubit.resetCustomization(categoryId: 'cat-1');
      });
    });
  });
}
