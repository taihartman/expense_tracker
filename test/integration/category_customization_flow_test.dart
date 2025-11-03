import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:expense_tracker/core/models/category_customization.dart';
import 'package:expense_tracker/core/repositories/category_customization_repository.dart';
import 'package:expense_tracker/features/categories/domain/models/category.dart';
import 'package:expense_tracker/features/categories/presentation/cubit/category_cubit.dart';
import 'package:expense_tracker/features/categories/presentation/cubit/category_state.dart';
import 'package:expense_tracker/features/categories/presentation/cubit/category_customization_cubit.dart';
import 'package:expense_tracker/features/categories/presentation/cubit/category_customization_state.dart';
import 'package:expense_tracker/features/trips/domain/repositories/activity_log_repository.dart';
import 'package:expense_tracker/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

@GenerateMocks([
  CategoryCustomizationRepository,
  ActivityLogRepository,
  CategoryCubit,
])
import 'category_customization_flow_test.mocks.dart';

void main() {
  group('Category Customization Integration Flow', () {
    late MockCategoryCustomizationRepository mockRepository;
    late MockActivityLogRepository mockActivityLogRepository;
    late MockCategoryCubit mockCategoryCubit;

    const testTripId = 'trip-123';
    final now = DateTime(2025, 10, 31, 12, 0, 0);

    final mealsCategory = Category(
      id: 'cat-meals',
      name: 'Meals',
      icon: 'restaurant',
      color: '#FF5722',
      usageCount: 100,
      createdAt: now,
      updatedAt: now,
    );

    final transportCategory = Category(
      id: 'cat-transport',
      name: 'Transport',
      icon: 'directions_car',
      color: '#2196F3',
      usageCount: 50,
      createdAt: now,
      updatedAt: now,
    );

    setUp(() {
      mockRepository = MockCategoryCustomizationRepository();
      mockActivityLogRepository = MockActivityLogRepository();
      mockCategoryCubit = MockCategoryCubit();

      // Mock category cubit
      when(mockCategoryCubit.state).thenReturn(
        CategoryTopLoaded(categories: [mealsCategory, transportCategory]),
      );
      when(mockCategoryCubit.stream).thenAnswer(
        (_) => Stream.value(
          CategoryTopLoaded(categories: [mealsCategory, transportCategory]),
        ),
      );

      // Mock repository - start with no customizations
      when(mockRepository.getCustomizationsForTrip(testTripId))
          .thenAnswer((_) => Stream.value([]));

      when(mockRepository.saveCustomization(any))
          .thenAnswer((_) async => Future.value());

      when(mockRepository.deleteCustomization(any, any))
          .thenAnswer((_) async {});

      when(mockActivityLogRepository.addLog(any))
          .thenAnswer((_) async => 'test-log-id');
    });

    testWidgets(
      'complete flow: customize icon → verify in expense list → reset',
      (tester) async {
        // Arrange
        late CategoryCustomizationCubit cubit;

        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: MultiBlocProvider(
              providers: [
                BlocProvider<CategoryCubit>.value(
                  value: mockCategoryCubit,
                ),
                BlocProvider<CategoryCustomizationCubit>(
                  create: (context) {
                    cubit = CategoryCustomizationCubit(
                      repository: mockRepository,
                      tripId: testTripId,
                      activityLogRepository: mockActivityLogRepository,
                    );
                    cubit.loadCustomizations();
                    return cubit;
                  },
                ),
              ],
              child: const Scaffold(
                body: Text('Test Scaffold'),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Step 1: Verify initial state - no customizations
        expect(cubit.isCustomized('cat-meals'), isFalse);
        expect(cubit.getCustomization('cat-meals'), isNull);

        // Step 2: Save icon customization
        await cubit.saveCustomization(
          categoryId: 'cat-meals',
          customIcon: 'fastfood',
          actorName: 'Alice',
        );

        await tester.pumpAndSettle();

        // Step 3: Verify save was called
        verify(
          mockRepository.saveCustomization(
            argThat(
              predicate<CategoryCustomization>((c) =>
                  c.categoryId == 'cat-meals' && c.customIcon == 'fastfood'),
            ),
          ),
        ).called(1);

        // Step 4: Verify activity log was called
        verify(mockActivityLogRepository.addLog(any)).called(1);

        // Step 5: Simulate repository emitting the new customization
        final customization = CategoryCustomization(
          categoryId: 'cat-meals',
          tripId: testTripId,
          customIcon: 'fastfood',
          updatedAt: now,
        );

        when(mockRepository.getCustomizationsForTrip(testTripId))
            .thenAnswer((_) => Stream.value([customization]));

        // Reload to get updated customization
        cubit.loadCustomizations();
        await tester.pumpAndSettle();

        // Step 6: Verify customization is now active
        expect(cubit.isCustomized('cat-meals'), isTrue);
        expect(cubit.getCustomization('cat-meals'), isNotNull);
        expect(cubit.getCustomization('cat-meals')!.customIcon, 'fastfood');

        // Step 7: Reset customization
        await cubit.resetCustomization(
          categoryId: 'cat-meals',
          actorName: 'Alice',
        );

        await tester.pumpAndSettle();

        // Step 8: Verify delete was called
        verify(
          mockRepository.deleteCustomization(testTripId, 'cat-meals'),
        ).called(1);

        // Step 9: Simulate repository emitting empty list after reset
        when(mockRepository.getCustomizationsForTrip(testTripId))
            .thenAnswer((_) => Stream.value([]));

        cubit.loadCustomizations();
        await tester.pumpAndSettle();

        // Step 10: Verify customization is removed
        expect(cubit.isCustomized('cat-meals'), isFalse);
        expect(cubit.getCustomization('cat-meals'), isNull);
      },
    );

    testWidgets(
      'complete flow: customize color → save → verify state',
      (tester) async {
        // Arrange
        late CategoryCustomizationCubit cubit;

        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: BlocProvider<CategoryCustomizationCubit>(
              create: (context) {
                cubit = CategoryCustomizationCubit(
                  repository: mockRepository,
                  tripId: testTripId,
                  activityLogRepository: mockActivityLogRepository,
                );
                cubit.loadCustomizations();
                return cubit;
              },
              child: const Scaffold(
                body: Text('Test Scaffold'),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Step 1: Save color customization
        await cubit.saveCustomization(
          categoryId: 'cat-transport',
          customColor: '#9C27B0',
          actorName: 'Bob',
        );

        await tester.pumpAndSettle();

        // Step 2: Verify save was called
        verify(
          mockRepository.saveCustomization(
            argThat(
              predicate<CategoryCustomization>((c) =>
                  c.categoryId == 'cat-transport' &&
                  c.customColor == '#9C27B0'),
            ),
          ),
        ).called(1);

        // Step 3: Simulate repository emitting the new customization
        final customization = CategoryCustomization(
          categoryId: 'cat-transport',
          tripId: testTripId,
          customColor: '#9C27B0',
          updatedAt: now,
        );

        when(mockRepository.getCustomizationsForTrip(testTripId))
            .thenAnswer((_) => Stream.value([customization]));

        cubit.loadCustomizations();
        await tester.pumpAndSettle();

        // Step 4: Verify color customization is active
        expect(cubit.isCustomized('cat-transport'), isTrue);
        expect(cubit.getCustomization('cat-transport')!.customColor, '#9C27B0');
        expect(cubit.getCustomization('cat-transport')!.customIcon, isNull);
      },
    );

    testWidgets(
      'complete flow: customize both icon and color → verify combined',
      (tester) async {
        // Arrange
        late CategoryCustomizationCubit cubit;

        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: BlocProvider<CategoryCustomizationCubit>(
              create: (context) {
                cubit = CategoryCustomizationCubit(
                  repository: mockRepository,
                  tripId: testTripId,
                  activityLogRepository: mockActivityLogRepository,
                );
                cubit.loadCustomizations();
                return cubit;
              },
              child: const Scaffold(
                body: Text('Test Scaffold'),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Step 1: Save combined customization
        await cubit.saveCustomization(
          categoryId: 'cat-meals',
          customIcon: 'local_pizza',
          customColor: '#E91E63',
          actorName: 'Charlie',
        );

        await tester.pumpAndSettle();

        // Step 2: Verify save was called with both values
        verify(
          mockRepository.saveCustomization(
            argThat(
              predicate<CategoryCustomization>((c) =>
                  c.categoryId == 'cat-meals' &&
                  c.customIcon == 'local_pizza' &&
                  c.customColor == '#E91E63'),
            ),
          ),
        ).called(1);

        // Step 3: Simulate repository emitting combined customization
        final customization = CategoryCustomization(
          categoryId: 'cat-meals',
          tripId: testTripId,
          customIcon: 'local_pizza',
          customColor: '#E91E63',
          updatedAt: now,
        );

        when(mockRepository.getCustomizationsForTrip(testTripId))
            .thenAnswer((_) => Stream.value([customization]));

        cubit.loadCustomizations();
        await tester.pumpAndSettle();

        // Step 4: Verify both customizations are active
        final result = cubit.getCustomization('cat-meals');
        expect(result, isNotNull);
        expect(result!.customIcon, 'local_pizza');
        expect(result.customColor, '#E91E63');
        expect(cubit.isCustomized('cat-meals'), isTrue);
      },
    );

    testWidgets(
      'error handling: save failure shows error state',
      (tester) async {
        // Arrange
        when(mockRepository.saveCustomization(any))
            .thenThrow(Exception('Network error'));

        late CategoryCustomizationCubit cubit;

        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: BlocProvider<CategoryCustomizationCubit>(
              create: (context) {
                cubit = CategoryCustomizationCubit(
                  repository: mockRepository,
                  tripId: testTripId,
                  activityLogRepository: mockActivityLogRepository,
                );
                cubit.loadCustomizations();
                return cubit;
              },
              child: const Scaffold(
                body: Text('Test Scaffold'),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Act
        await cubit.saveCustomization(
          categoryId: 'cat-meals',
          customIcon: 'fastfood',
        );

        await tester.pumpAndSettle();

        // Assert
        expect(cubit.state, isA<CategoryCustomizationError>());
        expect(
          (cubit.state as CategoryCustomizationError).type,
          CategoryCustomizationErrorType.saveFailed,
        );
      },
    );

    testWidgets(
      'activity logging: continues even if logging fails',
      (tester) async {
        // Arrange
        when(mockActivityLogRepository.addLog(any))
            .thenThrow(Exception('Logging failed'));

        late CategoryCustomizationCubit cubit;

        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: BlocProvider<CategoryCustomizationCubit>(
              create: (context) {
                cubit = CategoryCustomizationCubit(
                  repository: mockRepository,
                  tripId: testTripId,
                  activityLogRepository: mockActivityLogRepository,
                );
                cubit.loadCustomizations();
                return cubit;
              },
              child: const Scaffold(
                body: Text('Test Scaffold'),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Act - Should not throw despite logging failure
        await cubit.saveCustomization(
          categoryId: 'cat-meals',
          customIcon: 'fastfood',
          actorName: 'Alice',
        );

        await tester.pumpAndSettle();

        // Assert - Save should still succeed
        verify(mockRepository.saveCustomization(any)).called(1);
        expect(cubit.state, isA<CategoryCustomizationLoaded>());
      },
    );
  });
}
