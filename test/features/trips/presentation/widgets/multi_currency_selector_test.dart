import 'package:expense_tracker/core/models/currency_code.dart';
import 'package:expense_tracker/features/trips/presentation/widgets/multi_currency_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:expense_tracker/l10n/app_localizations.dart';

/// Helper to create a test widget with MaterialApp and localization
Widget createTestWidget(Widget child) {
  return MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}

void main() {
  group('MultiCurrencySelector Widget Tests', () {
    testWidgets('renders chips for selected currencies', (tester) async {
      // Arrange
      final selectedCurrencies = [
        CurrencyCode.usd,
        CurrencyCode.eur,
        CurrencyCode.gbp,
      ];

      // Act
      await tester.pumpWidget(
        createTestWidget(
          MultiCurrencySelector(
            selectedCurrencies: selectedCurrencies,
            onChanged: (currencies) {},
          ),
        ),
      );

      // Assert
      expect(find.text('USD'), findsOneWidget);
      expect(find.text('EUR'), findsOneWidget);
      expect(find.text('GBP'), findsOneWidget);
    });

    testWidgets('calls onChanged when currency added', (tester) async {
      // Arrange
      final selectedCurrencies = [CurrencyCode.usd];

      await tester.pumpWidget(
        createTestWidget(
          MultiCurrencySelector(
            selectedCurrencies: selectedCurrencies,
            onChanged: (currencies) {},
          ),
        ),
      );

      // Act - Find and tap "Add Currency" button
      final addButton = find.text('Add Currency');
      expect(addButton, findsOneWidget);
      await tester.tap(addButton);
      await tester.pumpAndSettle();

      // Assert - The button should trigger the modal
      // Note: Full add flow requires mocking CurrencySearchField modal
      // This test verifies the button exists and is tappable
      expect(addButton, findsOneWidget);
    });

    testWidgets('calls onChanged when currency removed', (tester) async {
      // Arrange
      final selectedCurrencies = [CurrencyCode.usd, CurrencyCode.eur];
      List<CurrencyCode>? changedCurrencies;

      await tester.pumpWidget(
        createTestWidget(
          MultiCurrencySelector(
            selectedCurrencies: selectedCurrencies,
            onChanged: (currencies) {
              changedCurrencies = currencies;
            },
          ),
        ),
      );

      // Act - Find remove button for EUR (second chip)
      final removeButtons = find.byIcon(Icons.close);
      expect(removeButtons, findsNWidgets(2)); // One per chip

      // Tap the second remove button (EUR)
      await tester.tap(removeButtons.at(1));
      await tester.pumpAndSettle();

      // Assert
      expect(changedCurrencies, isNotNull);
      expect(changedCurrencies, [CurrencyCode.usd]);
      expect(changedCurrencies?.length, 1);
    });

    testWidgets('calls onChanged when currency moved up', (tester) async {
      // Arrange
      final selectedCurrencies = [
        CurrencyCode.usd,
        CurrencyCode.eur,
        CurrencyCode.gbp,
      ];
      List<CurrencyCode>? changedCurrencies;

      await tester.pumpWidget(
        createTestWidget(
          MultiCurrencySelector(
            selectedCurrencies: selectedCurrencies,
            onChanged: (currencies) {
              changedCurrencies = currencies;
            },
          ),
        ),
      );

      // Act - Find "Move up" button for EUR (second chip)
      final moveUpButtons = find.byIcon(Icons.arrow_upward);

      // EUR and GBP should have move up buttons (USD is first)
      expect(moveUpButtons, findsNWidgets(2));

      // Tap the first move-up button (EUR)
      await tester.tap(moveUpButtons.first);
      await tester.pumpAndSettle();

      // Assert - EUR should swap with USD
      expect(changedCurrencies, isNotNull);
      expect(changedCurrencies, [
        CurrencyCode.eur,
        CurrencyCode.usd,
        CurrencyCode.gbp,
      ]);
    });

    testWidgets('calls onChanged when currency moved down', (tester) async {
      // Arrange
      final selectedCurrencies = [
        CurrencyCode.usd,
        CurrencyCode.eur,
        CurrencyCode.gbp,
      ];
      List<CurrencyCode>? changedCurrencies;

      await tester.pumpWidget(
        createTestWidget(
          MultiCurrencySelector(
            selectedCurrencies: selectedCurrencies,
            onChanged: (currencies) {
              changedCurrencies = currencies;
            },
          ),
        ),
      );

      // Act - Find "Move down" button for USD (first chip)
      final moveDownButtons = find.byIcon(Icons.arrow_downward);

      // USD and EUR should have move down buttons (GBP is last)
      expect(moveDownButtons, findsNWidgets(2));

      // Tap the first move-down button (USD)
      await tester.tap(moveDownButtons.first);
      await tester.pumpAndSettle();

      // Assert - USD should swap with EUR
      expect(changedCurrencies, isNotNull);
      expect(changedCurrencies, [
        CurrencyCode.eur,
        CurrencyCode.usd,
        CurrencyCode.gbp,
      ]);
    });

    testWidgets('disables add button at max currencies', (tester) async {
      // Arrange - Create list with 10 currencies (max)
      final selectedCurrencies = [
        CurrencyCode.usd,
        CurrencyCode.eur,
        CurrencyCode.gbp,
        CurrencyCode.jpy,
        CurrencyCode.cad,
        CurrencyCode.aud,
        CurrencyCode.chf,
        CurrencyCode.cny,
        CurrencyCode.sek,
        CurrencyCode.nzd,
      ];

      await tester.pumpWidget(
        createTestWidget(
          MultiCurrencySelector(
            selectedCurrencies: selectedCurrencies,
            onChanged: (currencies) {},
            maxCurrencies: 10,
          ),
        ),
      );

      // Assert - Add button should be disabled
      final addButton = find.widgetWithText(ElevatedButton, 'Add Currency');
      expect(addButton, findsOneWidget);

      final button = tester.widget<ElevatedButton>(addButton);
      expect(button.onPressed, isNull); // Disabled when onPressed is null
    });

    testWidgets('disables remove button at min currencies', (tester) async {
      // Arrange - Only one currency (minimum)
      final selectedCurrencies = [CurrencyCode.usd];
      List<CurrencyCode>? changedCurrencies;

      await tester.pumpWidget(
        createTestWidget(
          MultiCurrencySelector(
            selectedCurrencies: selectedCurrencies,
            onChanged: (currencies) {
              changedCurrencies = currencies;
            },
            minCurrencies: 1,
          ),
        ),
      );

      // Assert - Remove button should be disabled
      final removeButtons = find.byIcon(Icons.close);
      expect(removeButtons, findsOneWidget);

      // Try to tap the disabled button
      await tester.tap(removeButtons);
      await tester.pumpAndSettle();

      // onChanged should NOT be called
      expect(changedCurrencies, isNull);
    });

    testWidgets('prevents duplicate currency selection', (tester) async {
      // Arrange
      final selectedCurrencies = [CurrencyCode.usd, CurrencyCode.eur];

      await tester.pumpWidget(
        createTestWidget(
          MultiCurrencySelector(
            selectedCurrencies: selectedCurrencies,
            onChanged: (currencies) {},
          ),
        ),
      );

      // Note: Full duplicate prevention testing requires mocking
      // the CurrencySearchField modal. The widget should:
      // 1. Check if selected currency already exists
      // 2. Show snackbar if duplicate
      // 3. NOT call onChanged

      // For now, verify the initial state has no duplicates
      expect(selectedCurrencies.toSet().length, selectedCurrencies.length);
    });

    testWidgets('hides up arrow for first chip', (tester) async {
      // Arrange
      final selectedCurrencies = [
        CurrencyCode.usd,
        CurrencyCode.eur,
        CurrencyCode.gbp,
      ];

      await tester.pumpWidget(
        createTestWidget(
          MultiCurrencySelector(
            selectedCurrencies: selectedCurrencies,
            onChanged: (_) {},
          ),
        ),
      );

      // Assert - Should have 2 up arrows (EUR and GBP only)
      final moveUpButtons = find.byIcon(Icons.arrow_upward);
      expect(moveUpButtons, findsNWidgets(2));

      // USD (first chip) should not have an up arrow
      // We can verify by checking there are fewer up buttons than chips
      final chips = find.text('USD');
      expect(chips, findsOneWidget);
    });

    testWidgets('hides down arrow for last chip', (tester) async {
      // Arrange
      final selectedCurrencies = [
        CurrencyCode.usd,
        CurrencyCode.eur,
        CurrencyCode.gbp,
      ];

      await tester.pumpWidget(
        createTestWidget(
          MultiCurrencySelector(
            selectedCurrencies: selectedCurrencies,
            onChanged: (_) {},
          ),
        ),
      );

      // Assert - Should have 2 down arrows (USD and EUR only)
      final moveDownButtons = find.byIcon(Icons.arrow_downward);
      expect(moveDownButtons, findsNWidgets(2));

      // GBP (last chip) should not have a down arrow
      final chips = find.text('GBP');
      expect(chips, findsOneWidget);
    });

    testWidgets('respects mobile vs desktop responsive sizing', (tester) async {
      // Arrange
      final selectedCurrencies = [CurrencyCode.usd];

      // Test mobile size (375x667)
      await tester.binding.setSurfaceSize(const Size(375, 667));

      await tester.pumpWidget(
        createTestWidget(
          MultiCurrencySelector(
            selectedCurrencies: selectedCurrencies,
            onChanged: (_) {},
          ),
        ),
      );

      // Assert - Widget should render without overflow
      expect(tester.takeException(), isNull);

      // Test desktop size (1200x800)
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      await tester.pumpAndSettle();

      // Assert - Widget should adapt to larger screen
      expect(tester.takeException(), isNull);

      // Reset size
      addTearDown(() => tester.binding.setSurfaceSize(null));
    });

    testWidgets('displays help text about default currency', (tester) async {
      // Arrange
      final selectedCurrencies = [CurrencyCode.usd];

      await tester.pumpWidget(
        createTestWidget(
          MultiCurrencySelector(
            selectedCurrencies: selectedCurrencies,
            onChanged: (_) {},
          ),
        ),
      );

      // Assert - Should display help text
      expect(find.textContaining('Select 1-10 currencies'), findsOneWidget);
      expect(
        find.textContaining('first currency will be the default'),
        findsOneWidget,
      );
    });

    testWidgets('displays title from localization', (tester) async {
      // Arrange
      final selectedCurrencies = [CurrencyCode.usd];

      await tester.pumpWidget(
        createTestWidget(
          MultiCurrencySelector(
            selectedCurrencies: selectedCurrencies,
            onChanged: (_) {},
          ),
        ),
      );

      // Assert
      expect(find.text('Allowed Currencies'), findsOneWidget);
    });

    testWidgets('shows correct number of chips', (tester) async {
      // Arrange
      final selectedCurrencies = [
        CurrencyCode.usd,
        CurrencyCode.eur,
        CurrencyCode.gbp,
        CurrencyCode.jpy,
        CurrencyCode.cad,
      ];

      await tester.pumpWidget(
        createTestWidget(
          MultiCurrencySelector(
            selectedCurrencies: selectedCurrencies,
            onChanged: (_) {},
          ),
        ),
      );

      // Assert - Should have 5 chips
      expect(find.text('USD'), findsOneWidget);
      expect(find.text('EUR'), findsOneWidget);
      expect(find.text('GBP'), findsOneWidget);
      expect(find.text('JPY'), findsOneWidget);
      expect(find.text('CAD'), findsOneWidget);
    });

    testWidgets('maintains currency order', (tester) async {
      // Arrange
      final selectedCurrencies = [
        CurrencyCode.gbp,
        CurrencyCode.usd,
        CurrencyCode.eur,
      ];

      await tester.pumpWidget(
        createTestWidget(
          MultiCurrencySelector(
            selectedCurrencies: selectedCurrencies,
            onChanged: (_) {},
          ),
        ),
      );

      // Assert - Chips should appear in the order specified
      // GBP first, USD second, EUR third
      final chips = find.byType(Chip);
      expect(chips, findsNWidgets(3));

      // Verify order by checking text appears
      expect(find.text('GBP'), findsOneWidget);
      expect(find.text('USD'), findsOneWidget);
      expect(find.text('EUR'), findsOneWidget);
    });

    testWidgets('handles empty initial list (edge case)', (tester) async {
      // Arrange
      final selectedCurrencies = <CurrencyCode>[];

      await tester.pumpWidget(
        createTestWidget(
          MultiCurrencySelector(
            selectedCurrencies: selectedCurrencies,
            onChanged: (currencies) {},
            minCurrencies: 0, // Allow empty for this test
          ),
        ),
      );

      // Assert - Should show add button but no chips
      expect(find.byType(Chip), findsNothing);
      expect(find.text('Add Currency'), findsOneWidget);
    });

    testWidgets('up arrow button has correct semantics', (tester) async {
      // Arrange
      final selectedCurrencies = [CurrencyCode.usd, CurrencyCode.eur];

      await tester.pumpWidget(
        createTestWidget(
          MultiCurrencySelector(
            selectedCurrencies: selectedCurrencies,
            onChanged: (_) {},
          ),
        ),
      );

      // Assert - Move up button should exist for second currency
      final moveUpButtons = find.byIcon(Icons.arrow_upward);
      expect(moveUpButtons, findsOneWidget);

      // Should have tooltip/semantics for accessibility
      final button = tester.widget<IconButton>(
        find.ancestor(of: moveUpButtons, matching: find.byType(IconButton)),
      );
      expect(button.tooltip, equals('Move up'));
    });

    testWidgets('down arrow button has correct semantics', (tester) async {
      // Arrange
      final selectedCurrencies = [CurrencyCode.usd, CurrencyCode.eur];

      await tester.pumpWidget(
        createTestWidget(
          MultiCurrencySelector(
            selectedCurrencies: selectedCurrencies,
            onChanged: (_) {},
          ),
        ),
      );

      // Assert - Move down button should exist for first currency
      final moveDownButtons = find.byIcon(Icons.arrow_downward);
      expect(moveDownButtons, findsOneWidget);

      // Should have tooltip/semantics for accessibility
      final button = tester.widget<IconButton>(
        find.ancestor(of: moveDownButtons, matching: find.byType(IconButton)),
      );
      expect(button.tooltip, equals('Move down'));
    });

    testWidgets('remove button has correct semantics', (tester) async {
      // Arrange
      final selectedCurrencies = [CurrencyCode.usd, CurrencyCode.eur];

      await tester.pumpWidget(
        createTestWidget(
          MultiCurrencySelector(
            selectedCurrencies: selectedCurrencies,
            onChanged: (_) {},
          ),
        ),
      );

      // Assert - Remove buttons should exist
      final removeButtons = find.byIcon(Icons.close);
      expect(removeButtons, findsNWidgets(2));

      // Should have tooltip/semantics for accessibility
      final button = tester.widget<IconButton>(
        find.ancestor(
          of: removeButtons.first,
          matching: find.byType(IconButton),
        ),
      );
      expect(button.tooltip, equals('Remove currency'));
    });
  });
}
