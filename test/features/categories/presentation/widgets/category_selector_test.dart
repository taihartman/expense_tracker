import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:expense_tracker/features/categories/domain/models/category.dart';
import 'package:expense_tracker/features/categories/presentation/cubit/category_cubit.dart';
import 'package:expense_tracker/features/categories/presentation/cubit/category_state.dart';
import 'package:expense_tracker/features/categories/presentation/widgets/category_selector.dart';
import 'package:expense_tracker/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

@GenerateMocks([CategoryCubit])
import 'category_selector_test.mocks.dart';

void main() {
  group('CategorySelector Widget', () {
    late MockCategoryCubit mockCategoryCubit;

    final now = DateTime(2025, 10, 31, 12, 0, 0);

    // Realistic test data with 10 categories to match production scenario
    // This exposes bugs where "selectedIsInTop" checks against cached top 10
    // instead of rendered top 3
    final testCategories = [
      Category(
        id: 'cat1',
        name: 'Meals',
        icon: 'restaurant',
        color: '#FF5722',
        usageCount: 100,
        createdAt: now,
        updatedAt: now,
      ),
      Category(
        id: 'cat2',
        name: 'Transport',
        icon: 'directions_car',
        color: '#2196F3',
        usageCount: 50,
        createdAt: now,
        updatedAt: now,
      ),
      Category(
        id: 'cat3',
        name: 'Accommodation',
        icon: 'hotel',
        color: '#9C27B0',
        usageCount: 30,
        createdAt: now,
        updatedAt: now,
      ),
      // Categories 4-10 are in cached top 10 but NOT in rendered top 3
      Category(
        id: 'cat4',
        name: 'Activities',
        icon: 'local_activity',
        color: '#FF9800',
        usageCount: 25,
        createdAt: now,
        updatedAt: now,
      ),
      Category(
        id: 'cat5',
        name: 'Drinks',
        icon: 'local_bar',
        color: '#795548',
        usageCount: 20,
        createdAt: now,
        updatedAt: now,
      ),
      Category(
        id: 'cat6',
        name: 'Groceries',
        icon: 'shopping_cart',
        color: '#4CAF50',
        usageCount: 15,
        createdAt: now,
        updatedAt: now,
      ),
      Category(
        id: 'cat7',
        name: 'Entertainment',
        icon: 'movie',
        color: '#E91E63',
        usageCount: 12,
        createdAt: now,
        updatedAt: now,
      ),
      Category(
        id: 'cat8',
        name: 'Shopping',
        icon: 'shopping_bag',
        color: '#00BCD4',
        usageCount: 10,
        createdAt: now,
        updatedAt: now,
      ),
      Category(
        id: 'cat9',
        name: 'Health',
        icon: 'local_hospital',
        color: '#009688',
        usageCount: 8,
        createdAt: now,
        updatedAt: now,
      ),
      Category(
        id: 'other', // ID must be 'other' for special rendering logic
        name: 'Other',
        icon: 'more_horiz',
        color: '#9E9E9E',
        usageCount: 5,
        createdAt: now,
        updatedAt: now,
      ),
    ];

    setUp(() {
      mockCategoryCubit = MockCategoryCubit();

      // Default mock behavior - return loaded state with test categories
      when(
        mockCategoryCubit.state,
      ).thenReturn(CategoryTopLoaded(categories: testCategories));
      when(mockCategoryCubit.stream).thenAnswer(
        (_) => Stream.value(CategoryTopLoaded(categories: testCategories)),
      );
    });

    Widget createWidgetUnderTest({
      String? selectedCategoryId,
      ValueChanged<String?>? onCategoryChanged,
    }) {
      return MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: BlocProvider<CategoryCubit>.value(
            value: mockCategoryCubit,
            child: CategorySelector(
              selectedCategoryId: selectedCategoryId,
              onCategoryChanged: onCategoryChanged ?? (_) {},
            ),
          ),
        ),
      );
    }

    group('initialization', () {
      testWidgets('should load top categories on init with TTL cache', (
        tester,
      ) async {
        // Arrange
        when(
          mockCategoryCubit.loadTopCategoriesIfStale(limit: 5),
        ).thenReturn(null);

        // Act
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        // Assert
        verify(mockCategoryCubit.loadTopCategoriesIfStale(limit: 5)).called(1);
      });
    });

    group('cache behavior (performance optimization)', () {
      testWidgets(
        'should use cached category without loading when category is already cached',
        (tester) async {
          // Test verifies the performance optimization
          // Expected behavior: CategorySelector checks cubit cache before loading
          // No Firebase read needed when category is already cached

          // Arrange - Pre-populate cubit cache with 'Meals' category
          final mealsCategory = testCategories[0]; // 'Meals' with id 'cat1'
          when(
            mockCategoryCubit.getCategoryById('cat1'),
          ).thenReturn(mealsCategory);
          when(
            mockCategoryCubit.loadTopCategoriesIfStale(limit: 5),
          ).thenReturn(null);

          // Act - Create selector with pre-cached category
          await tester.pumpWidget(
            createWidgetUnderTest(selectedCategoryId: 'cat1'),
          );
          await tester.pumpAndSettle();

          // Assert - Category should be loaded from cache, no need to call loadCategoriesByIds
          verifyNever(mockCategoryCubit.loadCategoriesByIds(any));

          // The category should still display correctly
          expect(find.text('Meals'), findsOneWidget);
        },
      );

      testWidgets(
        'should call loadCategoriesByIds when category is NOT in cache',
        (tester) async {
          // Arrange - Cubit cache doesn't have the category initially
          when(
            mockCategoryCubit.getCategoryById('unknown-cat'),
          ).thenReturn(null); // First call: not in cache
          when(
            mockCategoryCubit.loadTopCategoriesIfStale(limit: 5),
          ).thenReturn(null);

          final unknownCategory = Category(
            id: 'unknown-cat',
            name: 'Custom Category',
            icon: 'star',
            color: '#FFD700',
            usageCount: 1,
            createdAt: now,
            updatedAt: now,
          );

          // After loadCategoriesByIds is called, it should be in cache
          when(
            mockCategoryCubit.loadCategoriesByIds(['unknown-cat']),
          ).thenAnswer((_) async {
            // Simulate category being added to cache
            when(
              mockCategoryCubit.getCategoryById('unknown-cat'),
            ).thenReturn(unknownCategory);
          });

          // Act
          await tester.pumpWidget(
            createWidgetUnderTest(selectedCategoryId: 'unknown-cat'),
          );
          await tester.pumpAndSettle();

          // Assert - loadCategoriesByIds SHOULD be called for uncached category
          verify(
            mockCategoryCubit.loadCategoriesByIds(['unknown-cat']),
          ).called(1);
          expect(find.text('Custom Category'), findsOneWidget);
        },
      );
    });

    group('category chips display', () {
      testWidgets('should display FilterChips for all loaded categories', (
        tester,
      ) async {
        // Act
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        // Assert - Top 3 categories should be visible
        expect(find.text('Meals'), findsOneWidget);
        expect(find.text('Transport'), findsOneWidget);
        expect(find.text('Accommodation'), findsOneWidget);

        // Assert - "Other" should be visible
        expect(find.text('Other'), findsOneWidget);

        // Assert - Total chips: 3 (top) + 1 (Other) + 1 (Browse) = 5
        expect(
          find.byType(FilterChip),
          findsNWidgets(5),
        );
      });

      testWidgets('should display category icons', (tester) async {
        // Act
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        // Assert
        expect(find.byIcon(Icons.restaurant), findsOneWidget);
        expect(find.byIcon(Icons.directions_car), findsOneWidget);
        expect(find.byIcon(Icons.hotel), findsOneWidget);
      });

      testWidgets('should display "Browse & Create" chip at the end', (
        tester,
      ) async {
        // Act
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Browse & Create'), findsOneWidget);
        expect(find.byIcon(Icons.search), findsOneWidget);
      });

      testWidgets('should highlight selected category', (tester) async {
        // Arrange - Mock getCategoryById for sync cache check
        final mealsCategory = testCategories[0]; // 'Meals' with id 'cat1'
        when(
          mockCategoryCubit.getCategoryById('cat1'),
        ).thenReturn(mealsCategory);

        // Act
        await tester.pumpWidget(
          createWidgetUnderTest(selectedCategoryId: 'cat1'),
        );
        await tester.pumpAndSettle();

        // Assert
        final mealsChip = find.widgetWithText(FilterChip, 'Meals');
        expect(mealsChip, findsOneWidget);

        final mealsChipWidget = tester.widget<FilterChip>(mealsChip);
        expect(mealsChipWidget.selected, isTrue);
      });

      testWidgets('should not highlight unselected categories', (tester) async {
        // Arrange - Mock getCategoryById for sync cache check
        final mealsCategory = testCategories[0]; // 'Meals' with id 'cat1'
        when(
          mockCategoryCubit.getCategoryById('cat1'),
        ).thenReturn(mealsCategory);

        // Act
        await tester.pumpWidget(
          createWidgetUnderTest(selectedCategoryId: 'cat1'),
        );
        await tester.pumpAndSettle();

        // Assert
        final transportChip = find.widgetWithText(FilterChip, 'Transport');
        final transportChipWidget = tester.widget<FilterChip>(transportChip);
        expect(transportChipWidget.selected, isFalse);
      });
    });

    group('category selection', () {
      testWidgets('should call onCategoryChanged when chip is tapped', (
        tester,
      ) async {
        // Arrange
        String? selectedId;
        await tester.pumpWidget(
          createWidgetUnderTest(onCategoryChanged: (id) => selectedId = id),
        );
        await tester.pumpAndSettle();

        // Act
        await tester.tap(find.text('Meals'));
        await tester.pumpAndSettle();

        // Assert
        expect(selectedId, 'cat1');
      });

      testWidgets('should deselect category when tapping selected chip', (
        tester,
      ) async {
        // Arrange - Mock getCategoryById for sync cache check
        final mealsCategory = testCategories[0]; // 'Meals' with id 'cat1'
        when(
          mockCategoryCubit.getCategoryById('cat1'),
        ).thenReturn(mealsCategory);

        String? selectedId = 'cat1';
        await tester.pumpWidget(
          createWidgetUnderTest(
            selectedCategoryId: 'cat1',
            onCategoryChanged: (id) => selectedId = id,
          ),
        );
        await tester.pumpAndSettle();

        // Act
        await tester.tap(find.text('Meals'));
        await tester.pumpAndSettle();

        // Assert
        expect(selectedId, isNull);
      });
    });

    group('loading state', () {
      testWidgets('should show loading indicator when state is loading', (
        tester,
      ) async {
        // Arrange
        when(mockCategoryCubit.state).thenReturn(const CategoryLoadingTop());
        when(
          mockCategoryCubit.stream,
        ).thenAnswer((_) => Stream.value(const CategoryLoadingTop()));

        // Act
        await tester.pumpWidget(createWidgetUnderTest());
        await tester
            .pump(); // Use pump() instead of pumpAndSettle() for loading states

        // Assert
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });
    });

    group('empty state', () {
      testWidgets(
        'should show "Browse & Create" chip only when no categories loaded',
        (tester) async {
          // Arrange
          when(
            mockCategoryCubit.state,
          ).thenReturn(const CategoryTopLoaded(categories: []));
          when(mockCategoryCubit.stream).thenAnswer(
            (_) => Stream.value(const CategoryTopLoaded(categories: [])),
          );

          // Act
          await tester.pumpWidget(createWidgetUnderTest());
          await tester.pumpAndSettle();

          // Assert
          expect(find.text('Browse & Create'), findsOneWidget);
          expect(
            find.byType(FilterChip),
            findsOneWidget,
          ); // Only "Browse & Create" chip
        },
      );
    });

    group('error state', () {
      testWidgets('should show fallback "Browse & Create" chip on error', (
        tester,
      ) async {
        // Arrange
        when(mockCategoryCubit.state).thenReturn(
          const CategoryError(
            message: 'Failed to load categories',
            type: CategoryErrorType.loadFailed,
          ),
        );
        when(mockCategoryCubit.stream).thenAnswer(
          (_) => Stream.value(
            const CategoryError(
              message: 'Failed to load categories',
              type: CategoryErrorType.loadFailed,
            ),
          ),
        );

        // Act
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Browse & Create'), findsOneWidget);
        expect(
          find.byType(FilterChip),
          findsOneWidget,
        ); // Only "Browse & Create" chip
      });
    });

    group('horizontal scrolling', () {
      testWidgets('should be horizontally scrollable', (tester) async {
        // Act
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        // Assert
        final listView = find.byType(ListView);
        expect(listView, findsOneWidget);

        final listViewWidget = tester.widget<ListView>(listView);
        expect(listViewWidget.scrollDirection, Axis.horizontal);
      });
    });

    group('accessibility', () {
      testWidgets('should have semantic labels for chips', (tester) async {
        // Act
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        // Assert
        expect(find.bySemanticsLabel('Meals'), findsOneWidget);
        expect(find.bySemanticsLabel('Transport'), findsOneWidget);
        expect(find.bySemanticsLabel('Accommodation'), findsOneWidget);
      });
    });

    group('browse sheet selection', () {
      testWidgets(
        'should display selected category chip when selected from browse sheet (not in top 5)',
        (tester) async {
          // This test verifies that categories selected from CategoryBrowserBottomSheet
          // appear in the chips, even if they're not in the top 5 categories.
          // This is the key scenario that's currently broken.

          // Arrange - Top 3 categories loaded
          when(
            mockCategoryCubit.loadTopCategoriesIfStale(limit: 5),
          ).thenReturn(null);

          // Create a category that's NOT in the top 3
          final coffeeCategory = Category(
            id: 'coffee-cat',
            name: 'Coffee',
            icon: 'local_cafe',
            color: '#8D6E63',
            usageCount: 5, // Lower than top 3
            createdAt: now,
            updatedAt: now,
          );

          // Simulate it being in the cubit cache (as if loaded from browse sheet)
          when(
            mockCategoryCubit.getCategoryById('coffee-cat'),
          ).thenReturn(coffeeCategory);

          // Act - Render with this category selected
          await tester.pumpWidget(
            createWidgetUnderTest(selectedCategoryId: 'coffee-cat'),
          );
          await tester.pumpAndSettle();

          // Assert - The "Coffee" chip should be visible
          expect(find.text('Coffee'), findsOneWidget);

          // Assert - All top categories should also be visible
          expect(find.text('Meals'), findsOneWidget);
          expect(find.text('Transport'), findsOneWidget);
          expect(find.text('Accommodation'), findsOneWidget);

          // Assert - Coffee chip should be selected
          final coffeeChip = find.widgetWithText(FilterChip, 'Coffee');
          expect(coffeeChip, findsOneWidget);
          final coffeeChipWidget = tester.widget<FilterChip>(coffeeChip);
          expect(coffeeChipWidget.selected, isTrue);
        },
      );

      testWidgets(
        'should display selected category chip even when category loads asynchronously',
        (tester) async {
          // This test simulates the real user flow:
          // 1. CategorySelector loads with top 5 categories
          // 2. User selects a category from browse sheet (not in top 5)
          // 3. Category needs to be loaded asynchronously
          // 4. Chip should appear after loading completes

          // Arrange - Start with top categories loaded, NO selected category
          when(
            mockCategoryCubit.loadTopCategoriesIfStale(limit: 5),
          ).thenReturn(null);

          // Act - Render initially with no selection
          await tester.pumpWidget(createWidgetUnderTest(selectedCategoryId: null));
          await tester.pumpAndSettle();

          // Assert - Only top categories visible
          expect(find.text('Meals'), findsOneWidget);
          expect(find.text('Transport'), findsOneWidget);
          expect(find.text('Accommodation'), findsOneWidget);
          expect(find.text('Coffee'), findsNothing);

          // Arrange - Create category NOT in cache yet
          final coffeeCategory = Category(
            id: 'coffee-cat',
            name: 'Coffee',
            icon: 'local_cafe',
            color: '#8D6E63',
            usageCount: 5,
            createdAt: now,
            updatedAt: now,
          );

          // Simulate async loading when getCategoryById is called
          when(
            mockCategoryCubit.getCategoryById('coffee-cat'),
          ).thenReturn(null); // Not in cache initially

          when(
            mockCategoryCubit.loadCategoriesByIds(['coffee-cat']),
          ).thenAnswer((_) async {
            // Simulate loading delay
            await Future.delayed(const Duration(milliseconds: 50));
            // After loading, it's in cache
            when(
              mockCategoryCubit.getCategoryById('coffee-cat'),
            ).thenReturn(coffeeCategory);
          });

          // Act - User selects Coffee from browse sheet
          // This triggers didUpdateWidget with new selectedCategoryId
          await tester.pumpWidget(
            createWidgetUnderTest(selectedCategoryId: 'coffee-cat'),
          );

          // Pump a few frames to allow async loading
          await tester.pump(const Duration(milliseconds: 100));
          await tester.pumpAndSettle();

          // Assert - Coffee chip should now be visible
          expect(find.text('Coffee'), findsOneWidget);
          expect(find.text('Meals'), findsOneWidget);

          // Assert - Coffee chip should be selected
          final coffeeChip = find.widgetWithText(FilterChip, 'Coffee');
          expect(coffeeChip, findsOneWidget);
          final coffeeChipWidget = tester.widget<FilterChip>(coffeeChip);
          expect(coffeeChipWidget.selected, isTrue);
        },
      );

      testWidgets(
        'REGRESSION: should display category in position 4-10 as extra chip (in cached top 10 but not rendered top 3)',
        (tester) async {
          // This test catches the bug we fixed where selectedIsInTop was checking
          // against allCategories (top 10 cached) instead of nonOtherCategories (top 3 rendered)
          //
          // Bug scenario:
          // - User has 10 categories cached
          // - Top 3 rendered: Meals, Transport, Accommodation
          // - User selects "Activities" (position 4)
          // - OLD BUG: selectedIsInTop = true (because in cached top 10)
          // - FIXED: selectedIsInTop = false (because NOT in rendered top 3)
          // - Result: "Activities" appears as extra chip

          // Arrange - Load all 10 categories
          when(
            mockCategoryCubit.loadTopCategoriesIfStale(limit: 5),
          ).thenReturn(null);
          when(mockCategoryCubit.state).thenReturn(
            CategoryTopLoaded(categories: testCategories),
          );
          when(mockCategoryCubit.stream).thenAnswer(
            (_) => Stream.value(CategoryTopLoaded(categories: testCategories)),
          );

          // Select "Activities" which is position 4 (in top 10, NOT in top 3)
          final activitiesCategory = testCategories[3]; // Position 4: "Activities"
          when(
            mockCategoryCubit.getCategoryById('cat4'),
          ).thenReturn(activitiesCategory);

          // Act - Render with Activities selected
          await tester.pumpWidget(
            createWidgetUnderTest(selectedCategoryId: 'cat4'),
          );
          await tester.pumpAndSettle();

          // Assert - Top 3 should be rendered
          expect(find.text('Meals'), findsOneWidget);
          expect(find.text('Transport'), findsOneWidget);
          expect(find.text('Accommodation'), findsOneWidget);

          // Assert - "Activities" should appear as EXTRA chip (position 4)
          expect(find.text('Activities'), findsOneWidget);

          // Assert - Activities chip should be selected
          final activitiesChip = find.widgetWithText(FilterChip, 'Activities');
          expect(activitiesChip, findsOneWidget);
          final activitiesChipWidget = tester.widget<FilterChip>(activitiesChip);
          expect(activitiesChipWidget.selected, isTrue);

          // Assert - Categories 5-9 should NOT appear (not in top 3, not selected)
          expect(find.text('Drinks'), findsNothing);
          expect(find.text('Groceries'), findsNothing);
          expect(find.text('Entertainment'), findsNothing);
          expect(find.text('Shopping'), findsNothing);
          expect(find.text('Health'), findsNothing);

          // The key assertion: "Activities" appears even though it's NOT in top 3
          // This proves the bug fix works - old code would NOT show Activities
          // because it incorrectly thought it was "in top" (position 4 in cached top 10)
        },
      );
    });

    group('state persistence', () {
      testWidgets(
        'should keep chips visible when CategoryCreated is emitted',
        (tester) async {
          // Arrange
          final streamController =
              StreamController<CategoryState>.broadcast();
          when(mockCategoryCubit.state).thenReturn(
            CategoryTopLoaded(categories: testCategories),
          );
          when(mockCategoryCubit.stream).thenAnswer(
            (_) => streamController.stream,
          );

          // Act - Build widget
          await tester.pumpWidget(createWidgetUnderTest());
          await tester.pumpAndSettle();

          // Assert - Chips visible initially
          expect(find.text('Meals'), findsOneWidget);

          // Act - Emit CategoryCreated (happens after creating a new category)
          final newCategory = Category(
            id: 'new-cat',
            name: 'New Category',
            icon: 'star',
            color: '#FFD700',
            usageCount: 0,
            createdAt: now,
            updatedAt: now,
          );
          streamController.add(CategoryCreated(category: newCategory));
          await tester.pumpAndSettle();

          // Assert - Original chips should STILL be visible
          expect(find.text('Meals'), findsOneWidget);
          expect(find.text('Transport'), findsOneWidget);
          expect(find.text('Accommodation'), findsOneWidget);

          await streamController.close();
        },
      );
    });
  });
}
