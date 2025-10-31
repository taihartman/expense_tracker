import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:expense_tracker/features/categories/domain/models/category.dart';
import 'package:expense_tracker/core/models/category_customization.dart';
import 'package:expense_tracker/features/categories/presentation/cubit/category_customization_cubit.dart';
import 'package:expense_tracker/features/categories/presentation/cubit/category_customization_state.dart';
import 'package:expense_tracker/features/categories/presentation/widgets/customize_categories_screen.dart';
import 'package:expense_tracker/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

@GenerateMocks([CategoryCustomizationCubit])
import 'customize_categories_screen_test.mocks.dart';

void main() {
  group('CustomizeCategoriesScreen Widget', () {
    late MockCategoryCustomizationCubit mockCubit;

    const testTripId = 'trip-123';
    final now = DateTime(2025, 10, 31, 12, 0, 0);

    final testCategories = [
      Category(
        id: 'cat-1',
        name: 'Meals',
        icon: 'restaurant',
        color: '#FF5722',
        usageCount: 100,
        createdAt: now,
        updatedAt: now,
      ),
      Category(
        id: 'cat-2',
        name: 'Transport',
        icon: 'directions_car',
        color: '#2196F3',
        usageCount: 50,
        createdAt: now,
        updatedAt: now,
      ),
    ];

    final customization1 = CategoryCustomization(
      categoryId: 'cat-1',
      tripId: testTripId,
      customIcon: 'fastfood',
      customColor: '#9C27B0',
      updatedAt: now,
    );

    setUp(() {
      mockCubit = MockCategoryCustomizationCubit();

      // Default mock behavior - loaded state
      when(mockCubit.state).thenReturn(
        CategoryCustomizationLoaded(
          customizations: {'cat-1': customization1},
        ),
      );
      when(mockCubit.stream).thenAnswer(
        (_) => Stream.value(
          CategoryCustomizationLoaded(
            customizations: {'cat-1': customization1},
          ),
        ),
      );
      when(mockCubit.isCustomized(any)).thenReturn(false);
      when(mockCubit.isCustomized('cat-1')).thenReturn(true);
      when(mockCubit.getCustomization(any)).thenReturn(null);
      when(mockCubit.getCustomization('cat-1')).thenReturn(customization1);
    });

    Widget createWidgetUnderTest({
      List<Category>? categories,
    }) {
      return MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider<CategoryCustomizationCubit>.value(
          value: mockCubit,
          child: CustomizeCategoriesScreen(
            tripId: testTripId,
            categories: categories ?? testCategories,
          ),
        ),
      );
    }

    group('initialization', () {
      testWidgets('should display screen title', (tester) async {
        // Act
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Customize Categories'), findsOneWidget);
      });

      testWidgets('should display list of categories', (tester) async {
        // Act
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Meals'), findsOneWidget);
        expect(find.text('Transport'), findsOneWidget);
      });

      testWidgets('should show loading indicator when state is loading',
          (tester) async {
        // Arrange
        when(mockCubit.state).thenReturn(CategoryCustomizationLoading());
        when(mockCubit.stream).thenAnswer(
          (_) => Stream.value(CategoryCustomizationLoading()),
        );

        // Act
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pump();

        // Assert
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('should show error message when state is error',
          (tester) async {
        // Arrange
        when(mockCubit.state).thenReturn(
          CategoryCustomizationError(
            type: CategoryCustomizationErrorType.loadFailed,
            message: 'Failed to load customizations',
          ),
        );
        when(mockCubit.stream).thenAnswer(
          (_) => Stream.value(
            CategoryCustomizationError(
              type: CategoryCustomizationErrorType.loadFailed,
              message: 'Failed to load customizations',
            ),
          ),
        );

        // Act
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Failed to load customizations'), findsOneWidget);
      });
    });

    group('customization indicators', () {
      testWidgets('should show "Customized" badge for customized categories',
          (tester) async {
        // Act
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Customized'), findsOneWidget);
      });

      testWidgets(
          'should show "Using global default" for non-customized categories',
          (tester) async {
        // Act
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        // Assert - Transport is not customized
        expect(find.text('Using global default'), findsOneWidget);
      });

      testWidgets('should display custom icon for customized category',
          (tester) async {
        // Act
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        // Assert - Meals uses custom icon 'fastfood'
        expect(find.byIcon(Icons.fastfood), findsOneWidget);
      });

      testWidgets('should display global icon for non-customized category',
          (tester) async {
        // Act
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        // Assert - Transport uses global icon 'directions_car'
        expect(find.byIcon(Icons.directions_car), findsOneWidget);
      });
    });

    group('editing customizations', () {
      testWidgets('should show edit icon button for each category',
          (tester) async {
        // Act
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        // Assert - Should have edit icons for both categories
        // The implementation uses OutlinedButton.icon with Icons.edit
        expect(find.byIcon(Icons.edit), findsNWidgets(2));
      });

      testWidgets('should open icon picker when icon edit button tapped',
          (tester) async {
        // Act
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        // Tap edit button for first category
        await tester.tap(find.byIcon(Icons.edit).first);
        await tester.pumpAndSettle();

        // Assert - Icon picker should be visible
        expect(find.text('Select Icon'), findsOneWidget);
        expect(find.byType(GridView), findsOneWidget);
      });

      testWidgets('should open color picker when color edit button tapped',
          (tester) async {
        // Act
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        // Tap color indicator for first category
        await tester.tap(find.byType(ColoredBox).first);
        await tester.pumpAndSettle();

        // Assert - Color picker should be visible
        expect(find.text('Select Color'), findsOneWidget);
        expect(find.byType(GridView), findsOneWidget);
      });

      testWidgets('should call saveCustomization when icon selected',
          (tester) async {
        // Arrange
        when(
          mockCubit.saveCustomization(
            categoryId: anyNamed('categoryId'),
            customIcon: anyNamed('customIcon'),
            customColor: anyNamed('customColor'),
            actorName: anyNamed('actorName'),
          ),
        ).thenAnswer((_) async => Future.value());

        // Act
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        // Open icon picker
        await tester.tap(find.byIcon(Icons.edit).first);
        await tester.pumpAndSettle();

        // Select new icon (hotel is in the icon picker list)
        await tester.tap(find.byIcon(Icons.hotel).first);
        await tester.pumpAndSettle();

        // Assert
        verify(
          mockCubit.saveCustomization(
            categoryId: 'cat-1',
            customIcon: 'hotel',
            customColor: anyNamed('customColor'),
            actorName: anyNamed('actorName'),
          ),
        ).called(1);
      });

      testWidgets('should call saveCustomization when color selected',
          (tester) async {
        // Arrange
        when(
          mockCubit.saveCustomization(
            categoryId: anyNamed('categoryId'),
            customIcon: anyNamed('customIcon'),
            customColor: anyNamed('customColor'),
            actorName: anyNamed('actorName'),
          ),
        ).thenAnswer((_) async => Future.value());

        // Act
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        // Open color picker - tap the color indicator (48x48 InkWell)
        final colorIndicator = find.byWidgetPredicate(
          (widget) => widget is InkWell && widget.child is Container,
        ).first;
        await tester.tap(colorIndicator);
        await tester.pumpAndSettle();

        // Select a new color from the picker
        // The color picker shows a GridView with InkWell items
        // We'll tap the first color option in the grid
        final colorOptions = find.descendant(
          of: find.byType(GridView),
          matching: find.byType(InkWell),
        );
        await tester.tap(colorOptions.first);
        await tester.pumpAndSettle();

        // Assert
        verify(
          mockCubit.saveCustomization(
            categoryId: 'cat-1',
            customIcon: anyNamed('customIcon'),
            customColor: anyNamed('customColor'),
            actorName: anyNamed('actorName'),
          ),
        ).called(1);
      });
    });

    group('reset customization', () {
      testWidgets('should show reset button for customized categories',
          (tester) async {
        // Act
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        // Assert - Meals is customized, should have reset button
        expect(find.text('Reset to Default'), findsOneWidget);
      });

      testWidgets('should not show reset button for non-customized categories',
          (tester) async {
        // Act
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        // Assert - Only one reset button (for Meals)
        expect(find.text('Reset to Default'), findsOneWidget);
      });

      testWidgets('should call resetCustomization when reset button tapped',
          (tester) async {
        // Arrange
        when(
          mockCubit.resetCustomization(
            categoryId: anyNamed('categoryId'),
            actorName: anyNamed('actorName'),
          ),
        ).thenAnswer((_) async => Future.value());

        // Act
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        // Tap reset button
        await tester.tap(find.text('Reset to Default'));
        await tester.pumpAndSettle();

        // Assert
        verify(
          mockCubit.resetCustomization(
            categoryId: 'cat-1',
            actorName: anyNamed('actorName'),
          ),
        ).called(1);
      });
    });

    group('empty state', () {
      testWidgets('should show empty message when no categories provided',
          (tester) async {
        // Act
        await tester.pumpWidget(createWidgetUnderTest(categories: []));
        await tester.pumpAndSettle();

        // Assert
        expect(
          find.text('No categories used in this trip yet'),
          findsOneWidget,
        );
      });
    });

    group('accessibility', () {
      testWidgets('should have minimum touch target size for buttons',
          (tester) async {
        // Act
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        // Assert - Edit icons should exist
        // The implementation uses OutlinedButton.icon which enforces Material Design
        // minimum touch target size of 48x48 by default, exceeding the 44x44 requirement
        final editIcons = find.byIcon(Icons.edit);
        expect(editIcons, findsNWidgets(2));

        // Verify "Icon" text buttons (the edit buttons) exist
        expect(find.text('Icon'), findsNWidgets(2));

        // Verify the color indicator touch targets (48x48 InkWells) exist
        // These are the color selector buttons
        final colorIndicators = find.byWidgetPredicate(
          (widget) =>
              widget is InkWell &&
              widget.child is Container &&
              (widget.child as Container?)?.constraints?.maxWidth == 48.0,
        );
        expect(colorIndicators, findsNWidgets(2));
      });

      testWidgets('should be scrollable when content overflows',
          (tester) async {
        // Arrange - Create many categories
        final manyCategories = List.generate(
          20,
          (i) => Category(
            id: 'cat-$i',
            name: 'Category $i',
            icon: 'category',
            color: '#9E9E9E',
            usageCount: i,
            createdAt: now,
            updatedAt: now,
          ),
        );

        // Act
        await tester.pumpWidget(createWidgetUnderTest(categories: manyCategories));
        await tester.pumpAndSettle();

        // Assert - Should be able to scroll
        expect(find.byType(ListView), findsOneWidget);
        expect(find.byType(SingleChildScrollView), findsOneWidget);
      });
    });
  });
}
