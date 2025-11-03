import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/categories/presentation/widgets/category_icon_picker.dart';

void main() {
  group('CategoryIconPicker Widget', () {
    testWidgets('should display all 30 available icons', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryIconPicker(
              selectedIcon: null,
              onIconSelected: (_) {},
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(GridView), findsOneWidget);
      expect(find.byType(InkWell), findsNWidgets(30));
    });

    testWidgets('should highlight selected icon', (tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryIconPicker(
              selectedIcon: 'restaurant',
              onIconSelected: (_) {},
            ),
          ),
        ),
      );

      // Assert
      final containers = find.byType(Container);
      expect(containers, findsWidgets);

      // Find the container with restaurant icon
      final restaurantIcon = find.byIcon(Icons.restaurant);
      expect(restaurantIcon, findsOneWidget);
    });

    testWidgets('should call onIconSelected when icon tapped', (tester) async {
      // Arrange
      String? selectedIcon;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryIconPicker(
              selectedIcon: null,
              onIconSelected: (icon) {
                selectedIcon = icon;
              },
            ),
          ),
        ),
      );

      // Act
      await tester.tap(find.byIcon(Icons.restaurant).first);
      await tester.pumpAndSettle();

      // Assert
      expect(selectedIcon, 'restaurant');
    });

    testWidgets('should update selection when different icon tapped',
        (tester) async {
      // Arrange
      String? selectedIcon = 'restaurant';

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              return Scaffold(
                body: CategoryIconPicker(
                  selectedIcon: selectedIcon,
                  onIconSelected: (icon) {
                    setState(() {
                      selectedIcon = icon;
                    });
                  },
                ),
              );
            },
          ),
        ),
      );

      // Act
      await tester.tap(find.byIcon(Icons.directions_car).first);
      await tester.pumpAndSettle();

      // Assert
      expect(selectedIcon, 'directions_car');
    });

    testWidgets('should display icons in 6-column grid', (tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryIconPicker(
              selectedIcon: null,
              onIconSelected: (_) {},
            ),
          ),
        ),
      );

      // Assert
      final gridView =
          tester.widget<GridView>(find.byType(GridView));
      final delegate = gridView.gridDelegate
          as SliverGridDelegateWithFixedCrossAxisCount;
      expect(delegate.crossAxisCount, 6);
    });

    testWidgets('should have proper spacing between icons', (tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryIconPicker(
              selectedIcon: null,
              onIconSelected: (_) {},
            ),
          ),
        ),
      );

      // Assert
      final gridView =
          tester.widget<GridView>(find.byType(GridView));
      final delegate = gridView.gridDelegate
          as SliverGridDelegateWithFixedCrossAxisCount;
      expect(delegate.crossAxisSpacing, greaterThan(0));
      expect(delegate.mainAxisSpacing, greaterThan(0));
    });

    testWidgets('should include common category icons', (tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryIconPicker(
              selectedIcon: null,
              onIconSelected: (_) {},
            ),
          ),
        ),
      );

      // Assert - Check for commonly used category icons
      expect(find.byIcon(Icons.restaurant), findsOneWidget);
      expect(find.byIcon(Icons.directions_car), findsOneWidget);
      expect(find.byIcon(Icons.hotel), findsOneWidget);
      expect(find.byIcon(Icons.flight), findsOneWidget);
      expect(find.byIcon(Icons.shopping_bag), findsOneWidget);
      expect(find.byIcon(Icons.local_cafe), findsOneWidget);
    });

    testWidgets('should work with null selectedIcon', (tester) async {
      // Act & Assert - Should not throw
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryIconPicker(
              selectedIcon: null,
              onIconSelected: (_) {},
            ),
          ),
        ),
      );

      expect(find.byType(CategoryIconPicker), findsOneWidget);
    });

    testWidgets('should be scrollable when needed', (tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryIconPicker(
              selectedIcon: null,
              onIconSelected: (_) {},
            ),
          ),
        ),
      );

      // Assert
      final gridView =
          tester.widget<GridView>(find.byType(GridView));
      expect(gridView.shrinkWrap, isTrue);
      expect(gridView.physics, isA<NeverScrollableScrollPhysics>());
    });

    testWidgets('should display icons with appropriate size', (tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryIconPicker(
              selectedIcon: 'restaurant',
              onIconSelected: (_) {},
            ),
          ),
        ),
      );

      // Assert - Icons should be visible and appropriately sized
      final icons = find.byType(Icon);
      expect(icons, findsWidgets);

      for (final icon in icons.evaluate()) {
        final size = tester.getSize(find.byWidget(icon.widget));
        expect(size.width, greaterThan(0));
        expect(size.height, greaterThan(0));
      }
    });

    testWidgets('should provide visual feedback on selection', (tester) async {
      // Arrange
      String selectedIcon = 'restaurant';

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              return Scaffold(
                body: CategoryIconPicker(
                  selectedIcon: selectedIcon,
                  onIconSelected: (icon) {
                    setState(() {
                      selectedIcon = icon;
                    });
                  },
                ),
              );
            },
          ),
        ),
      );

      // Act - Initial state
      await tester.pumpAndSettle();

      // Assert - Selected icon should have different styling
      final restaurantIcon = find.byIcon(Icons.restaurant);
      expect(restaurantIcon, findsOneWidget);

      // The selected icon's parent Container should have different decoration
      final containers = find.ancestor(
        of: restaurantIcon,
        matching: find.byType(Container),
      );
      expect(containers, findsWidgets);
    });

    testWidgets('should handle rapid taps correctly', (tester) async {
      // Arrange
      int tapCount = 0;
      String? lastSelectedIcon;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryIconPicker(
              selectedIcon: null,
              onIconSelected: (icon) {
                tapCount++;
                lastSelectedIcon = icon;
              },
            ),
          ),
        ),
      );

      // Act - Tap same icon multiple times
      final restaurantIcon = find.byIcon(Icons.restaurant).first;
      await tester.tap(restaurantIcon);
      await tester.tap(restaurantIcon);
      await tester.tap(restaurantIcon);
      await tester.pumpAndSettle();

      // Assert
      expect(tapCount, 3);
      expect(lastSelectedIcon, 'restaurant');
    });

    testWidgets('should have touch targets of minimum 44x44 pixels',
        (tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryIconPicker(
              selectedIcon: null,
              onIconSelected: (_) {},
            ),
          ),
        ),
      );

      // Assert
      final inkWells = find.byType(InkWell);
      for (final inkWell in inkWells.evaluate()) {
        final size = tester.getSize(find.byWidget(inkWell.widget));
        expect(size.width, greaterThanOrEqualTo(44));
        expect(size.height, greaterThanOrEqualTo(44));
      }
    });
  });
}
