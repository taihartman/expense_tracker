import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:expense_tracker/features/categories/domain/models/category.dart';
import 'package:expense_tracker/features/categories/presentation/cubit/category_cubit.dart';
import 'package:expense_tracker/features/categories/presentation/cubit/category_state.dart';
import 'package:expense_tracker/features/categories/presentation/cubit/category_customization_cubit.dart';
import 'package:expense_tracker/features/categories/presentation/cubit/category_customization_state.dart';
import 'package:expense_tracker/features/categories/presentation/widgets/category_browser_bottom_sheet.dart';
import 'package:expense_tracker/core/services/auth_service.dart';
import 'package:expense_tracker/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

@GenerateMocks([CategoryCubit, CategoryCustomizationCubit, AuthService])
import 'category_browser_bottom_sheet_test.mocks.dart';

void main() {
  group('CategoryBrowserBottomSheet Widget', () {
    late MockCategoryCubit mockCategoryCubit;
    late MockCategoryCustomizationCubit mockCustomizationCubit;
    late MockAuthService mockAuthService;

    const testTripId = 'test-trip-123';
    final now = DateTime(2025, 10, 31, 12, 0, 0);

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
      Category(
        id: 'cat4',
        name: 'Activities',
        icon: 'local_activity',
        color: '#4CAF50',
        usageCount: 20,
        createdAt: now,
        updatedAt: now,
      ),
      Category(
        id: 'cat5',
        name: 'Shopping',
        icon: 'shopping_bag',
        color: '#FF9800',
        usageCount: 10,
        createdAt: now,
        updatedAt: now,
      ),
    ];

    setUp(() {
      mockCategoryCubit = MockCategoryCubit();
      mockCustomizationCubit = MockCategoryCustomizationCubit();
      mockAuthService = MockAuthService();

      // Default mock behavior - return search results
      when(
        mockCategoryCubit.state,
      ).thenReturn(CategorySearchResults(query: '', results: testCategories));
      when(mockCategoryCubit.stream).thenAnswer(
        (_) => Stream.value(
          CategorySearchResults(query: '', results: testCategories),
        ),
      );

      // Mock auth service to return a test user ID
      when(mockAuthService.getAuthUidForRateLimiting()).thenReturn('test-user-123');

      // Mock hasUserCustomized to return true (user has customized before, so direct selection)
      when(mockCustomizationCubit.hasUserCustomized(any, any))
          .thenAnswer((_) async => true);

      // Mock customization cubit stream and state (empty initial state)
      when(mockCustomizationCubit.stream).thenAnswer((_) => const Stream.empty());
      when(mockCustomizationCubit.state).thenReturn(const CategoryCustomizationInitial());
    });

    Future<void> showBottomSheetUnderTest(
      WidgetTester tester, {
      ValueChanged<Category>? onCategorySelected,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: MultiProvider(
              providers: [
                BlocProvider<CategoryCubit>.value(value: mockCategoryCubit),
                BlocProvider<CategoryCustomizationCubit>.value(value: mockCustomizationCubit),
                Provider<AuthService>.value(value: mockAuthService),
              ],
              child: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (bottomSheetContext) => MultiProvider(
                          providers: [
                            BlocProvider<CategoryCubit>.value(value: mockCategoryCubit),
                            BlocProvider<CategoryCustomizationCubit>.value(value: mockCustomizationCubit),
                            Provider<AuthService>.value(value: mockAuthService),
                          ],
                          child: CategoryBrowserBottomSheet(
                            tripId: testTripId,
                            onCategorySelected: onCategorySelected ?? (_) {},
                          ),
                        ),
                      );
                    },
                    child: const Text('Show Browser'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      // Tap button to show bottom sheet
      await tester.tap(find.text('Show Browser'));
      await tester.pumpAndSettle();
    }

    group('initialization', () {
      testWidgets('should show bottom sheet when triggered', (tester) async {
        // Arrange & Act
        await showBottomSheetUnderTest(tester);

        // Assert - bottom sheet is visible
        expect(find.byType(CategoryBrowserBottomSheet), findsOneWidget);
      });

      testWidgets('should call searchCategories with empty query on init', (
        tester,
      ) async {
        // Arrange
        when(mockCategoryCubit.searchCategories('')).thenReturn(null);

        // Act
        await showBottomSheetUnderTest(tester);

        // Assert
        verify(mockCategoryCubit.searchCategories('')).called(1);
      });

      testWidgets('should display header with title', (tester) async {
        // Act
        await showBottomSheetUnderTest(tester);

        // Assert
        expect(find.text('Select Category'), findsOneWidget);
      });

      testWidgets('should display search field', (tester) async {
        // Act
        await showBottomSheetUnderTest(tester);

        // Assert
        expect(find.byType(TextField), findsOneWidget);
        expect(find.byIcon(Icons.search), findsOneWidget);
      });
    });

    group('category list display', () {
      testWidgets('should display all categories from search results', (
        tester,
      ) async {
        // Act
        await showBottomSheetUnderTest(tester);

        // Assert
        expect(find.text('Meals'), findsOneWidget);
        expect(find.text('Transport'), findsOneWidget);
        expect(find.text('Accommodation'), findsOneWidget);
        expect(find.text('Activities'), findsOneWidget);
        expect(find.text('Shopping'), findsOneWidget);
      });

      testWidgets('should display category icons', (tester) async {
        // Act
        await showBottomSheetUnderTest(tester);

        // Assert
        expect(find.byIcon(Icons.restaurant), findsOneWidget);
        expect(find.byIcon(Icons.directions_car), findsOneWidget);
        expect(find.byIcon(Icons.hotel), findsOneWidget);
        expect(find.byIcon(Icons.local_activity), findsOneWidget);
        expect(find.byIcon(Icons.shopping_bag), findsOneWidget);
      });

      testWidgets('should be scrollable with ListView', (tester) async {
        // Act
        await showBottomSheetUnderTest(tester);

        // Assert
        expect(find.byType(ListView), findsOneWidget);
      });
    });

    group('search functionality', () {
      testWidgets('should call searchCategories when typing in search field', (
        tester,
      ) async {
        // Arrange
        when(mockCategoryCubit.searchCategories('meal')).thenReturn(null);
        await showBottomSheetUnderTest(tester);

        // Act
        await tester.enterText(find.byType(TextField), 'meal');

        // Assert
        verify(mockCategoryCubit.searchCategories('meal')).called(1);
      });

      testWidgets('should update results when search results change', (
        tester,
      ) async {
        // Arrange
        final searchResults = [testCategories[0]]; // Only Meals
        when(mockCategoryCubit.state).thenReturn(
          CategorySearchResults(query: 'meal', results: searchResults),
        );
        when(mockCategoryCubit.stream).thenAnswer(
          (_) => Stream.value(
            CategorySearchResults(query: 'meal', results: searchResults),
          ),
        );

        // Act
        await showBottomSheetUnderTest(tester);

        // Assert - only Meals should be visible
        expect(find.text('Meals'), findsOneWidget);
        expect(find.text('Transport'), findsNothing);
      });

      testWidgets('should show empty state when no results found', (
        tester,
      ) async {
        // Arrange
        when(mockCategoryCubit.state).thenReturn(
          const CategorySearchResults(query: 'nonexistent', results: []),
        );
        when(mockCategoryCubit.stream).thenAnswer(
          (_) => Stream.value(
            const CategorySearchResults(query: 'nonexistent', results: []),
          ),
        );

        // Act
        await showBottomSheetUnderTest(tester);

        // Assert
        expect(find.text('No categories found'), findsOneWidget);
      });
    });

    group('loading state', () {
      testWidgets('should show shimmer loading indicator during search', (
        tester,
      ) async {
        // Arrange
        when(mockCategoryCubit.state).thenReturn(const CategoryInitial());
        when(
          mockCategoryCubit.stream,
        ).thenAnswer((_) => Stream.value(const CategoryInitial()));

        // Act - use pump() instead of pumpAndSettle() for loading states
        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: MultiProvider(
              providers: [
                BlocProvider<CategoryCubit>.value(value: mockCategoryCubit),
                BlocProvider<CategoryCustomizationCubit>.value(value: mockCustomizationCubit),
                Provider<AuthService>.value(value: mockAuthService),
              ],
              child: Scaffold(
                body: Builder(
                  builder: (context) {
                    return ElevatedButton(
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          builder: (bottomSheetContext) => MultiProvider(
                            providers: [
                              BlocProvider<CategoryCubit>.value(value: mockCategoryCubit),
                              BlocProvider<CategoryCustomizationCubit>.value(value: mockCustomizationCubit),
                              Provider<AuthService>.value(value: mockAuthService),
                            ],
                            child: CategoryBrowserBottomSheet(
                              tripId: testTripId,
                              onCategorySelected: (_) {},
                            ),
                          ),
                        );
                      },
                      child: const Text('Show Browser'),
                    );
                  },
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Show Browser'));
        await tester.pump(); // Use pump() instead of pumpAndSettle()

        // Assert - should show loading state (shimmer placeholders)
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });
    });

    group('error state', () {
      testWidgets('should show error message when search fails', (
        tester,
      ) async {
        // Arrange
        when(mockCategoryCubit.state).thenReturn(
          const CategoryError(
            message: 'Failed to load categories',
            type: CategoryErrorType.searchFailed,
          ),
        );
        when(mockCategoryCubit.stream).thenAnswer(
          (_) => Stream.value(
            const CategoryError(
              message: 'Failed to load categories',
              type: CategoryErrorType.searchFailed,
            ),
          ),
        );

        // Act
        await showBottomSheetUnderTest(tester);

        // Assert
        expect(find.text('Failed to load categories'), findsOneWidget);
      });
    });

    group('category selection', () {
      testWidgets('should call onCategorySelected when category is tapped', (
        tester,
      ) async {
        // Arrange
        Category? selectedCategory;
        await showBottomSheetUnderTest(
          tester,
          onCategorySelected: (category) => selectedCategory = category,
        );

        // Act
        await tester.tap(find.text('Meals'));
        await tester.pumpAndSettle();

        // Assert
        expect(selectedCategory, isNotNull);
        expect(selectedCategory?.id, 'cat1');
        expect(selectedCategory?.name, 'Meals');
      });

      testWidgets('should dismiss bottom sheet after selection', (
        tester,
      ) async {
        // Arrange
        await showBottomSheetUnderTest(tester);

        // Act
        await tester.tap(find.text('Meals'));
        await tester.pumpAndSettle();

        // Assert - bottom sheet should be dismissed
        expect(find.byType(CategoryBrowserBottomSheet), findsNothing);
      });
    });

    group('dismissal', () {
      testWidgets('should allow manual dismissal by dragging down', (
        tester,
      ) async {
        // Arrange
        await showBottomSheetUnderTest(tester);

        // Act - drag down to dismiss
        await tester.drag(
          find.byType(CategoryBrowserBottomSheet),
          const Offset(0, 500),
        );
        await tester.pumpAndSettle();

        // Assert - bottom sheet should be dismissed
        expect(find.byType(CategoryBrowserBottomSheet), findsNothing);
      });
    });

    group('accessibility', () {
      testWidgets('should have semantic labels for categories', (tester) async {
        // Act
        await showBottomSheetUnderTest(tester);

        // Assert - verify semanticsLabel is set on category text widgets
        final mealsText = tester.widget<Text>(
          find.descendant(
            of: find.widgetWithText(ListTile, 'Meals'),
            matching: find.text('Meals'),
          ),
        );
        expect(mealsText.semanticsLabel, 'Meals');

        final transportText = tester.widget<Text>(
          find.descendant(
            of: find.widgetWithText(ListTile, 'Transport'),
            matching: find.text('Transport'),
          ),
        );
        expect(transportText.semanticsLabel, 'Transport');
      });

      testWidgets('should have accessible search field', (tester) async {
        // Act
        await showBottomSheetUnderTest(tester);

        // Assert
        final textField = tester.widget<TextField>(find.byType(TextField));
        expect(textField.decoration?.hintText, isNotNull);
      });
    });
  });
}
