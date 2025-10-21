import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:expense_tracker/main.dart';
import 'package:expense_tracker/core/services/local_storage_service.dart';

void main() {
  testWidgets('App initializes without errors', (WidgetTester tester) async {
    // Initialize LocalStorageService for testing
    final localStorageService = await LocalStorageService.init();

    // Build our app and trigger a frame.
    await tester.pumpWidget(ExpenseTrackerApp(
      localStorageService: localStorageService,
    ));

    // Verify app builds successfully
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
