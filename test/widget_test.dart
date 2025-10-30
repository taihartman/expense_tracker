import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:expense_tracker/main.dart';

void main() {
  testWidgets('App initializes without errors', (WidgetTester tester) async {
    // Build our app and trigger a frame (initialization happens internally)
    await tester.pumpWidget(const ExpenseTrackerApp());

    // Verify app builds successfully
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
