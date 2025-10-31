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
      testWidgets('should load top categories on init', (tester) async {
        // Arrange
        when(mockCategoryCubit.loadTopCategories(limit: 5)).thenReturn(null);

        // Act
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        // Assert
        verify(mockCategoryCubit.loadTopCategories(limit: 5)).called(1);
      });
    });

    group('category chips display', () {
      testWidgets('should display FilterChips for all loaded categories', (
        tester,
      ) async {
        // Act
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Meals'), findsOneWidget);
        expect(find.text('Transport'), findsOneWidget);
        expect(find.text('Accommodation'), findsOneWidget);
        expect(
          find.byType(FilterChip),
          findsNWidgets(4),
        ); // 3 categories + "Other"
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

      testWidgets('should display "Other" chip at the end', (tester) async {
        // Act
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Other'), findsOneWidget);
        expect(find.byIcon(Icons.more_horiz), findsOneWidget);
      });

      testWidgets('should highlight selected category', (tester) async {
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
        // Arrange
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
      testWidgets('should show "Other" chip only when no categories loaded', (
        tester,
      ) async {
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
        expect(find.text('Other'), findsOneWidget);
        expect(find.byType(FilterChip), findsOneWidget); // Only "Other" chip
      });
    });

    group('error state', () {
      testWidgets('should show fallback "Other" chip on error', (tester) async {
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
        expect(find.text('Other'), findsOneWidget);
        expect(find.byType(FilterChip), findsOneWidget); // Only "Other" chip
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
  });
}
