import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:expense_tracker/features/device_pairing/presentation/cubits/device_pairing_cubit.dart';
import 'package:expense_tracker/features/device_pairing/presentation/cubits/device_pairing_state.dart';
import 'package:expense_tracker/features/device_pairing/presentation/widgets/code_verification_prompt.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:expense_tracker/l10n/app_localizations.dart';

import 'code_verification_prompt_test.mocks.dart';

@GenerateNiceMocks([MockSpec<DevicePairingCubit>()])
void main() {
  group('CodeVerificationPrompt Widget -', () {
    late MockDevicePairingCubit mockCubit;

    setUp(() {
      mockCubit = MockDevicePairingCubit();
      // Provide dummy value for sealed class
      provideDummy<DevicePairingState>(const DevicePairingInitial());
      when(mockCubit.state).thenReturn(const DevicePairingInitial());
      when(mockCubit.stream).thenAnswer(
        (_) => Stream<DevicePairingState>.value(const DevicePairingInitial()),
      );
    });

    Widget createTestWidget({
      required String tripId,
      required String memberName,
    }) {
      return MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en')],
        home: BlocProvider<DevicePairingCubit>.value(
          value: mockCubit,
          child: Scaffold(
            body: CodeVerificationPrompt(
              tripId: tripId,
              memberName: memberName,
            ),
          ),
        ),
      );
    }

    testWidgets('displays title and message correctly', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          tripId: 'trip-123',
          memberName: 'Alice',
        ),
      );

      // Verify title
      expect(
        find.text('Device Verification Required'),
        findsOneWidget,
        reason: 'Should display verification title',
      );

      // Verify message includes member name
      expect(
        find.textContaining('Alice'),
        findsOneWidget,
        reason: 'Should display message with member name',
      );

      expect(
        find.textContaining('already exists'),
        findsOneWidget,
        reason: 'Should explain duplicate detection',
      );
    });

    testWidgets('displays code input field with correct formatting',
        (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          tripId: 'trip-123',
          memberName: 'Alice',
        ),
      );

      // Find code input field
      final codeField = find.byType(TextField);
      expect(codeField, findsOneWidget, reason: 'Should have code input field');

      // Verify placeholder/hint
      expect(
        find.text('1234-5678'),
        findsOneWidget,
        reason: 'Should show code format hint',
      );
    });

    testWidgets('accepts 8-digit code with hyphen', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          tripId: 'trip-123',
          memberName: 'Alice',
        ),
      );

      // Enter code with hyphen
      await tester.enterText(find.byType(TextField), '1234-5678');
      await tester.pump();

      // Verify text was accepted by checking the TextField contains it
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(
        textField.controller?.text,
        '1234-5678',
        reason: 'Should accept code with hyphen',
      );
    });

    testWidgets('accepts 8-digit code without hyphen', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          tripId: 'trip-123',
          memberName: 'Alice',
        ),
      );

      // Enter code without hyphen
      await tester.enterText(find.byType(TextField), '12345678');
      await tester.pump();

      // Verify text was accepted by checking the TextField contains it
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(
        textField.controller?.text,
        '12345678',
        reason: 'Should accept code without hyphen',
      );
    });

    testWidgets('displays Submit and Cancel buttons', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          tripId: 'trip-123',
          memberName: 'Alice',
        ),
      );

      // Find buttons
      expect(
        find.widgetWithText(TextButton, 'Submit Code'),
        findsOneWidget,
        reason: 'Should have Submit button',
      );

      expect(
        find.widgetWithText(TextButton, 'Cancel'),
        findsOneWidget,
        reason: 'Should have Cancel button',
      );
    });

    testWidgets('Submit button is disabled when code is empty',
        (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          tripId: 'trip-123',
          memberName: 'Alice',
        ),
      );

      // Find submit button
      final submitButton = find.widgetWithText(TextButton, 'Submit Code');
      expect(submitButton, findsOneWidget);

      // Verify button is disabled (onPressed is null)
      final button = tester.widget<TextButton>(submitButton);
      expect(
        button.onPressed,
        isNull,
        reason: 'Submit button should be disabled when code is empty',
      );
    });

    testWidgets('Submit button is enabled when code has 8 digits',
        (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          tripId: 'trip-123',
          memberName: 'Alice',
        ),
      );

      // Enter valid code
      await tester.enterText(find.byType(TextField), '12345678');
      await tester.pump();

      // Find submit button
      final submitButton = find.widgetWithText(TextButton, 'Submit Code');
      final button = tester.widget<TextButton>(submitButton);

      expect(
        button.onPressed,
        isNotNull,
        reason: 'Submit button should be enabled when code has 8 digits',
      );
    });

    testWidgets('Submit button triggers validation with correct parameters',
        (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          tripId: 'trip-123',
          memberName: 'Alice',
        ),
      );

      // Enter code
      await tester.enterText(find.byType(TextField), '1234-5678');
      await tester.pump();

      // Tap submit button
      await tester.tap(find.widgetWithText(TextButton, 'Submit Code'));
      await tester.pump();

      // Verify cubit.validateCode was called with correct parameters
      verify(
        mockCubit.validateCode('trip-123', '1234-5678', 'Alice'),
      ).called(1);
    });

    testWidgets('Cancel button pops the dialog', (tester) async {
      bool dialogPopped = false;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en')],
          home: BlocProvider<DevicePairingCubit>.value(
            value: mockCubit,
            child: Builder(
              builder: (context) {
                return Scaffold(
                  body: Center(
                    child: ElevatedButton(
                      onPressed: () async {
                        final result = await showDialog<bool>(
                          context: context,
                          builder: (dialogContext) => BlocProvider<DevicePairingCubit>.value(
                            value: mockCubit,
                            child: const CodeVerificationPrompt(
                              tripId: 'trip-123',
                              memberName: 'Alice',
                            ),
                          ),
                        );
                        dialogPopped = result == false;
                      },
                      child: const Text('Show Dialog'),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );

      // Open dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Tap Cancel button
      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await tester.pumpAndSettle();

      // Verify dialog was dismissed with false result
      expect(dialogPopped, isTrue, reason: 'Cancel should dismiss dialog');
    });

    testWidgets('shows loading indicator when validating', (tester) async {
      // Set state to validating
      when(mockCubit.state).thenReturn(const CodeValidating());
      when(mockCubit.stream).thenAnswer(
        (_) => Stream<DevicePairingState>.value(const CodeValidating()),
      );

      await tester.pumpWidget(
        createTestWidget(
          tripId: 'trip-123',
          memberName: 'Alice',
        ),
      );

      // Verify loading indicator is shown
      expect(
        find.byType(CircularProgressIndicator),
        findsOneWidget,
        reason: 'Should show loading indicator during validation',
      );

      // Verify submit button is disabled during loading
      final submitButton = find.widgetWithText(TextButton, 'Submit Code');
      final button = tester.widget<TextButton>(submitButton);
      expect(
        button.onPressed,
        isNull,
        reason: 'Submit button should be disabled during validation',
      );
    });

    testWidgets('shows error message when validation fails', (tester) async {
      // Set initial state
      when(mockCubit.state).thenReturn(const DevicePairingInitial());
      when(mockCubit.stream).thenAnswer(
        (_) => Stream<DevicePairingState>.fromIterable([
          const DevicePairingInitial(),
          const CodeValidationError('Invalid code'),
        ]),
      );

      await tester.pumpWidget(
        createTestWidget(
          tripId: 'trip-123',
          memberName: 'Alice',
        ),
      );

      // Wait for error state
      await tester.pumpAndSettle();

      // Verify error message is displayed via TextField's errorText
      expect(
        find.text('Invalid code'),
        findsOneWidget,
        reason: 'Should display validation error message in TextField',
      );

      // Verify TextField has error set
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(
        textField.decoration?.errorText,
        'Invalid code',
        reason: 'TextField should display error',
      );
    });

    testWidgets('pops dialog with true when validation succeeds',
        (tester) async {
      // Set up stream that emits success after initial state
      when(mockCubit.state).thenReturn(const DevicePairingInitial());
      when(mockCubit.stream).thenAnswer(
        (_) => Stream<DevicePairingState>.fromIterable([
          const CodeValidated('trip-123'),
        ]),
      );

      bool? dialogResult;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en')],
          home: BlocProvider<DevicePairingCubit>.value(
            value: mockCubit,
            child: Builder(
              builder: (context) {
                return Scaffold(
                  body: Center(
                    child: ElevatedButton(
                      onPressed: () async {
                        dialogResult = await showDialog<bool>(
                          context: context,
                          builder: (dialogContext) => BlocProvider<DevicePairingCubit>.value(
                            value: mockCubit,
                            child: const CodeVerificationPrompt(
                              tripId: 'trip-123',
                              memberName: 'Alice',
                            ),
                          ),
                        );
                      },
                      child: const Text('Show Dialog'),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );

      // Open dialog - this will trigger the stream listener
      await tester.tap(find.text('Show Dialog'));
      await tester.pump(); // Start showing dialog
      await tester.pump(); // Process BlocListener
      await tester.pump(); // Process Navigator.pop

      // Verify dialog was dismissed with true result
      expect(
        dialogResult,
        isTrue,
        reason: 'Successful validation should dismiss dialog with true',
      );
    });

    testWidgets('does not validate with invalid code format', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          tripId: 'trip-123',
          memberName: 'Alice',
        ),
      );

      // Enter invalid code (too short)
      await tester.enterText(find.byType(TextField), '123');
      await tester.pump();

      // Verify submit button is disabled
      final submitButton = find.widgetWithText(TextButton, 'Submit Code');
      final button = tester.widget<TextButton>(submitButton);
      expect(
        button.onPressed,
        isNull,
        reason: 'Submit button should be disabled for invalid code format',
      );

      // Verify validateCode was not called
      verifyNever(mockCubit.validateCode(any, any, any));
    });

    testWidgets('clears error message when user types', (tester) async {
      // Set initial error state
      when(mockCubit.state).thenReturn(
        const CodeValidationError('Invalid code'),
      );
      when(mockCubit.stream).thenAnswer(
        (_) => Stream<DevicePairingState>.value(
          const CodeValidationError('Invalid code'),
        ),
      );

      await tester.pumpWidget(
        createTestWidget(
          tripId: 'trip-123',
          memberName: 'Alice',
        ),
      );

      await tester.pumpAndSettle();

      // Verify error is displayed
      expect(find.text('Invalid code'), findsOneWidget);

      // Verify TextField has error text
      var textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.decoration?.errorText, 'Invalid code');

      // User types to correct the code
      await tester.enterText(find.byType(TextField), '87654321');
      await tester.pump();

      // Error should be cleared from TextField
      textField = tester.widget<TextField>(find.byType(TextField));
      expect(
        textField.decoration?.errorText,
        isNull,
        reason: 'Error should clear when user types',
      );
    });
  });
}
