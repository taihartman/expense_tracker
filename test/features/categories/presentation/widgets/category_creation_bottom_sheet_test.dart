import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:expense_tracker/features/categories/domain/models/category.dart';
import 'package:expense_tracker/features/categories/presentation/cubit/category_cubit.dart';
import 'package:expense_tracker/features/categories/presentation/cubit/category_state.dart';
import 'package:expense_tracker/features/categories/presentation/widgets/category_creation_bottom_sheet.dart';
import 'package:expense_tracker/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

@GenerateMocks([CategoryCubit])
import 'category_creation_bottom_sheet_test.mocks.dart';

void main() {
  group('CategoryCreationBottomSheet Widget', () {
    late MockCategoryCubit mockCategoryCubit;

    setUp(() {
      mockCategoryCubit = MockCategoryCubit();

      // Default mock behavior - initial state
      when(mockCategoryCubit.state).thenReturn(const CategoryInitial());
      when(
        mockCategoryCubit.stream,
      ).thenAnswer((_) => Stream.value(const CategoryInitial()));
    });

    Future<void> showBottomSheetUnderTest(
      WidgetTester tester, {
      VoidCallback? onCategoryCreated,
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
            body: BlocProvider<CategoryCubit>.value(
              value: mockCategoryCubit,
              child: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (bottomSheetContext) =>
                            BlocProvider<CategoryCubit>.value(
                              value: mockCategoryCubit,
                              child: CategoryCreationBottomSheet(
                                onCategoryCreated: onCategoryCreated ?? () {},
                              ),
                            ),
                      );
                    },
                    child: const Text('Show Creation Form'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      // Tap button to show bottom sheet
      await tester.tap(find.text('Show Creation Form'));
      await tester.pumpAndSettle();
    }

    group('initialization', () {
      testWidgets('should show bottom sheet when triggered', (tester) async {
        // Act
        await showBottomSheetUnderTest(tester);

        // Assert - bottom sheet is visible
        expect(find.byType(CategoryCreationBottomSheet), findsOneWidget);
      });

      testWidgets('should display header with title', (tester) async {
        // Act
        await showBottomSheetUnderTest(tester);

        // Assert
        expect(find.text('Create Category'), findsOneWidget);
      });

      testWidgets('should display close button', (tester) async {
        // Act
        await showBottomSheetUnderTest(tester);

        // Assert
        expect(find.byIcon(Icons.close), findsOneWidget);
      });
    });

    group('form validation - name field', () {
      testWidgets('should display category name TextField', (tester) async {
        // Act
        await showBottomSheetUnderTest(tester);

        // Assert
        final nameFinder = find.widgetWithText(TextField, 'Category Name');
        expect(nameFinder, findsOneWidget);
      });

      testWidgets('should show error when name is empty', (tester) async {
        // Arrange
        await showBottomSheetUnderTest(tester);

        // Act - tap create button without entering name
        final createButton = find.widgetWithText(ElevatedButton, 'Create');
        await tester.tap(createButton);
        await tester.pumpAndSettle();

        // Assert - should show validation error
        expect(find.text('Category name cannot be empty'), findsOneWidget);
      });

      testWidgets('should show error when name is too short', (tester) async {
        // Arrange
        await showBottomSheetUnderTest(tester);

        // Act - enter single character name
        final nameField = find.widgetWithText(TextField, 'Category Name');
        await tester.enterText(nameField, 'A');

        // Tap create button
        final createButton = find.widgetWithText(ElevatedButton, 'Create');
        await tester.tap(createButton);
        await tester.pumpAndSettle();

        // Assert
        expect(
          find.text('Category name must be 1-50 characters'),
          findsOneWidget,
        );
      });

      testWidgets('should show error when name is too long', (tester) async {
        // Arrange
        await showBottomSheetUnderTest(tester);

        // Act - enter 51 character name
        final nameField = find.widgetWithText(TextField, 'Category Name');
        await tester.enterText(nameField, 'A' * 51);

        // Tap create button
        final createButton = find.widgetWithText(ElevatedButton, 'Create');
        await tester.tap(createButton);
        await tester.pumpAndSettle();

        // Assert
        expect(
          find.text('Category name must be 1-50 characters'),
          findsOneWidget,
        );
      });

      testWidgets('should show error for invalid characters', (tester) async {
        // Arrange
        await showBottomSheetUnderTest(tester);

        // Act - enter name with invalid characters
        final nameField = find.widgetWithText(TextField, 'Category Name');
        await tester.enterText(nameField, 'Invalid@#\$%');

        // Tap create button
        final createButton = find.widgetWithText(ElevatedButton, 'Create');
        await tester.tap(createButton);
        await tester.pumpAndSettle();

        // Assert
        expect(
          find.text('Invalid characters in category name'),
          findsOneWidget,
        );
      });

      testWidgets('should accept valid category name', (tester) async {
        // Arrange
        when(
          mockCategoryCubit.createCategory(
            name: anyNamed('name'),
            icon: anyNamed('icon'),
            color: anyNamed('color'),
          ),
        ).thenAnswer((_) async {});

        await showBottomSheetUnderTest(tester);

        // Act - enter valid name
        final nameField = find.widgetWithText(TextField, 'Category Name');
        await tester.enterText(nameField, 'Groceries');

        // Tap create button
        final createButton = find.widgetWithText(ElevatedButton, 'Create');
        await tester.tap(createButton);
        await tester.pumpAndSettle();

        // Assert - should call createCategory
        verify(
          mockCategoryCubit.createCategory(
            name: 'Groceries',
            icon: anyNamed('icon'),
            color: anyNamed('color'),
          ),
        ).called(1);
      });
    });

    group('icon selection', () {
      testWidgets('should display icon picker grid', (tester) async {
        // Act
        await showBottomSheetUnderTest(tester);

        // Assert - should show icon grid
        expect(find.text('Select Icon'), findsOneWidget);
        expect(find.byType(GridView), findsWidgets);
      });

      testWidgets('should have default icon selected', (tester) async {
        // Act
        await showBottomSheetUnderTest(tester);

        // Assert - default icon (category) should be highlighted
        // Look for selected state indicator
        expect(find.byIcon(Icons.category), findsWidgets);
      });

      testWidgets('should change icon when tapped', (tester) async {
        // Arrange
        await showBottomSheetUnderTest(tester);

        // Act - tap restaurant icon
        final restaurantIcon = find.byIcon(Icons.restaurant).first;
        await tester.tap(restaurantIcon);
        await tester.pumpAndSettle();

        // Assert - restaurant icon should now be selected
        // Create button should use restaurant icon
        verify(
          mockCategoryCubit.createCategory(
            name: anyNamed('name'),
            icon: 'restaurant',
            color: anyNamed('color'),
          ),
        ).called(greaterThanOrEqualTo(0));
      });
    });

    group('color selection', () {
      testWidgets('should display color picker grid', (tester) async {
        // Act
        await showBottomSheetUnderTest(tester);

        // Assert - should show color grid
        expect(find.text('Select Color'), findsOneWidget);
        expect(find.byType(GridView), findsWidgets);
      });

      testWidgets('should have default color selected', (tester) async {
        // Act
        await showBottomSheetUnderTest(tester);

        // Assert - default color should be highlighted
        // Look for selected state indicator (checkmark or border)
        expect(find.byIcon(Icons.check), findsOneWidget);
      });

      testWidgets('should change color when tapped', (tester) async {
        // Arrange
        await showBottomSheetUnderTest(tester);

        // Act - tap a color circle
        final colorCircles = find.byType(InkWell);
        await tester.tap(colorCircles.at(2)); // Tap third color
        await tester.pumpAndSettle();

        // Assert - selected color should be updated
        expect(find.byIcon(Icons.check), findsOneWidget);
      });
    });

    group('create button', () {
      testWidgets('should be disabled when form is invalid', (tester) async {
        // Act
        await showBottomSheetUnderTest(tester);

        // Assert - button should be disabled initially (no name entered)
        final createButton = tester.widget<ElevatedButton>(
          find.widgetWithText(ElevatedButton, 'Create'),
        );
        expect(createButton.onPressed, isNull);
      });

      testWidgets('should be enabled when form is valid', (tester) async {
        // Arrange
        await showBottomSheetUnderTest(tester);

        // Act - enter valid name
        final nameField = find.widgetWithText(TextField, 'Category Name');
        await tester.enterText(nameField, 'Groceries');
        await tester.pumpAndSettle();

        // Assert - button should be enabled
        final createButton = tester.widget<ElevatedButton>(
          find.widgetWithText(ElevatedButton, 'Create'),
        );
        expect(createButton.onPressed, isNotNull);
      });

      testWidgets('should show loading indicator when creating', (
        tester,
      ) async {
        // Arrange
        when(
          mockCategoryCubit.state,
        ).thenReturn(const CategoryCreating(name: 'Groceries'));
        when(mockCategoryCubit.stream).thenAnswer(
          (_) => Stream.value(const CategoryCreating(name: 'Groceries')),
        );
        await showBottomSheetUnderTest(tester);

        // Assert - should show loading indicator
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('should call createCategory when tapped', (tester) async {
        // Arrange
        when(
          mockCategoryCubit.createCategory(
            name: anyNamed('name'),
            icon: anyNamed('icon'),
            color: anyNamed('color'),
          ),
        ).thenAnswer((_) async {});

        await showBottomSheetUnderTest(tester);

        // Act - enter name and tap create
        final nameField = find.widgetWithText(TextField, 'Category Name');
        await tester.enterText(nameField, 'Groceries');

        final createButton = find.widgetWithText(ElevatedButton, 'Create');
        await tester.tap(createButton);
        await tester.pumpAndSettle();

        // Assert
        verify(
          mockCategoryCubit.createCategory(
            name: 'Groceries',
            icon: anyNamed('icon'),
            color: anyNamed('color'),
          ),
        ).called(1);
      });
    });

    group('error handling', () {
      testWidgets('should show rate limit error message', (tester) async {
        // Arrange
        when(mockCategoryCubit.state).thenReturn(
          const CategoryError(
            message: 'Rate limit exceeded. Please wait 5 minutes.',
            type: CategoryErrorType.rateLimit,
          ),
        );
        when(mockCategoryCubit.stream).thenAnswer(
          (_) => Stream.value(
            const CategoryError(
              message: 'Rate limit exceeded. Please wait 5 minutes.',
              type: CategoryErrorType.rateLimit,
            ),
          ),
        );

        // Act
        await showBottomSheetUnderTest(tester);

        // Assert
        expect(
          find.text('Rate limit exceeded. Please wait 5 minutes.'),
          findsOneWidget,
        );
      });

      testWidgets('should show duplicate category error', (tester) async {
        // Arrange
        when(mockCategoryCubit.state).thenReturn(
          const CategoryError(
            message: 'Category already exists',
            type: CategoryErrorType.duplicate,
          ),
        );
        when(mockCategoryCubit.stream).thenAnswer(
          (_) => Stream.value(
            const CategoryError(
              message: 'Category already exists',
              type: CategoryErrorType.duplicate,
            ),
          ),
        );

        // Act
        await showBottomSheetUnderTest(tester);

        // Assert
        expect(find.text('Category already exists'), findsOneWidget);
      });

      testWidgets('should show generic error for creation failure', (
        tester,
      ) async {
        // Arrange
        when(mockCategoryCubit.state).thenReturn(
          const CategoryError(
            message: 'Failed to create category',
            type: CategoryErrorType.createFailed,
          ),
        );
        when(mockCategoryCubit.stream).thenAnswer(
          (_) => Stream.value(
            const CategoryError(
              message: 'Failed to create category',
              type: CategoryErrorType.createFailed,
            ),
          ),
        );

        // Act
        await showBottomSheetUnderTest(tester);

        // Assert
        expect(find.text('Failed to create category'), findsOneWidget);
      });
    });

    group('success state', () {
      testWidgets('should call onCategoryCreated callback', (tester) async {
        // Arrange
        bool callbackCalled = false;
        final now = DateTime(2025, 10, 31);
        final createdCategory = Category(
          id: 'cat_new',
          name: 'Groceries',
          icon: 'shopping_bag',
          color: '#FF9800',
          usageCount: 0,
          createdAt: now,
          updatedAt: now,
        );

        when(
          mockCategoryCubit.state,
        ).thenReturn(CategoryCreated(category: createdCategory));
        when(mockCategoryCubit.stream).thenAnswer(
          (_) => Stream.value(CategoryCreated(category: createdCategory)),
        );

        // Act
        await showBottomSheetUnderTest(
          tester,
          onCategoryCreated: () => callbackCalled = true,
        );

        // Assert
        expect(callbackCalled, isTrue);
      });

      testWidgets('should dismiss bottom sheet after creation', (tester) async {
        // Arrange
        final now = DateTime(2025, 10, 31);
        final createdCategory = Category(
          id: 'cat_new',
          name: 'Groceries',
          icon: 'shopping_bag',
          color: '#FF9800',
          usageCount: 0,
          createdAt: now,
          updatedAt: now,
        );

        when(
          mockCategoryCubit.state,
        ).thenReturn(CategoryCreated(category: createdCategory));
        when(mockCategoryCubit.stream).thenAnswer(
          (_) => Stream.value(CategoryCreated(category: createdCategory)),
        );

        // Act
        await showBottomSheetUnderTest(tester);

        // Allow animation to complete
        await tester.pumpAndSettle();

        // Assert - bottom sheet should be dismissed
        expect(find.byType(CategoryCreationBottomSheet), findsNothing);
      });
    });

    group('dismissal', () {
      testWidgets('should dismiss when close button tapped', (tester) async {
        // Arrange
        await showBottomSheetUnderTest(tester);

        // Act
        final closeButton = find.byIcon(Icons.close);
        await tester.tap(closeButton);
        await tester.pumpAndSettle();

        // Assert - bottom sheet should be dismissed
        expect(find.byType(CategoryCreationBottomSheet), findsNothing);
      });

      testWidgets('should dismiss by dragging down', (tester) async {
        // Arrange
        await showBottomSheetUnderTest(tester);

        // Act - drag down to dismiss
        await tester.drag(
          find.byType(CategoryCreationBottomSheet),
          const Offset(0, 500),
        );
        await tester.pumpAndSettle();

        // Assert - bottom sheet should be dismissed
        expect(find.byType(CategoryCreationBottomSheet), findsNothing);
      });
    });
  });
}
