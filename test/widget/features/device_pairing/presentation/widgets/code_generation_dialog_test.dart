import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:expense_tracker/features/device_pairing/presentation/cubits/device_pairing_cubit.dart';
import 'package:expense_tracker/features/device_pairing/presentation/cubits/device_pairing_state.dart';
import 'package:expense_tracker/features/device_pairing/presentation/widgets/code_generation_dialog.dart';
import 'package:expense_tracker/features/device_pairing/domain/models/device_link_code.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:expense_tracker/l10n/app_localizations.dart';

import 'code_generation_dialog_test.mocks.dart';

@GenerateNiceMocks([MockSpec<DevicePairingCubit>()])
void main() {
  group('T028/T028a: CodeGenerationDialog Widget -', () {
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
            body: CodeGenerationDialog(
              tripId: tripId,
              memberName: memberName,
            ),
          ),
        ),
      );
    }

    testWidgets('displays title and member name correctly', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          tripId: 'trip-123',
          memberName: 'Alice',
        ),
      );

      // Verify title
      expect(
        find.text('Generate Code'),
        findsOneWidget,
        reason: 'Should display dialog title',
      );

      // Verify message includes member name
      expect(
        find.textContaining('Alice'),
        findsOneWidget,
        reason: 'Should display message with member name',
      );
    });

    testWidgets('shows loading indicator while generating code',
        (tester) async {
      // Set state to generating
      when(mockCubit.state).thenReturn(const CodeGenerating());
      when(mockCubit.stream).thenAnswer(
        (_) => Stream<DevicePairingState>.value(const CodeGenerating()),
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
        reason: 'Should show loading indicator during code generation',
      );
    });

    testWidgets('displays generated code in large readable format',
        (tester) async {
      // Set state to code generated
      final mockCode = DeviceLinkCode(
        id: 'code-123',
        code: '1234-5678',
        tripId: 'trip-123',
        memberName: 'Alice',
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(minutes: 15)),
        used: false,
        usedAt: null,
      );

      when(mockCubit.state).thenReturn(CodeGenerated(mockCode));
      when(mockCubit.stream).thenAnswer(
        (_) => Stream<DevicePairingState>.value(CodeGenerated(mockCode)),
      );

      await tester.pumpWidget(
        createTestWidget(
          tripId: 'trip-123',
          memberName: 'Alice',
        ),
      );

      // Verify code is displayed
      expect(
        find.text('1234-5678'),
        findsOneWidget,
        reason: 'Should display the generated code',
      );
    });

    testWidgets('displays Copy to Clipboard button', (tester) async {
      final mockCode = DeviceLinkCode(
        id: 'code-123',
        code: '1234-5678',
        tripId: 'trip-123',
        memberName: 'Alice',
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(minutes: 15)),
        used: false,
        usedAt: null,
      );

      when(mockCubit.state).thenReturn(CodeGenerated(mockCode));
      when(mockCubit.stream).thenAnswer(
        (_) => Stream<DevicePairingState>.value(CodeGenerated(mockCode)),
      );

      await tester.pumpWidget(
        createTestWidget(
          tripId: 'trip-123',
          memberName: 'Alice',
        ),
      );

      // Verify copy button exists
      expect(
        find.widgetWithText(ElevatedButton, 'Copy to Clipboard'),
        findsOneWidget,
        reason: 'Should have Copy to Clipboard button',
      );
    });

    testWidgets('T028a: Copy button copies code to clipboard', (tester) async {
      final mockCode = DeviceLinkCode(
        id: 'code-123',
        code: '1234-5678',
        tripId: 'trip-123',
        memberName: 'Alice',
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(minutes: 15)),
        used: false,
        usedAt: null,
      );

      when(mockCubit.state).thenReturn(CodeGenerated(mockCode));
      when(mockCubit.stream).thenAnswer(
        (_) => Stream<DevicePairingState>.value(CodeGenerated(mockCode)),
      );

      // Set up system channel for clipboard testing
      final List<MethodCall> log = <MethodCall>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall methodCall) async {
          log.add(methodCall);
          return null;
        },
      );

      await tester.pumpWidget(
        createTestWidget(
          tripId: 'trip-123',
          memberName: 'Alice',
        ),
      );

      // Tap copy button
      await tester.tap(find.widgetWithText(ElevatedButton, 'Copy to Clipboard'));
      await tester.pumpAndSettle();

      // Verify clipboard.setData was called with correct code
      expect(
        log,
        contains(
          isA<MethodCall>()
              .having((call) => call.method, 'method', 'Clipboard.setData')
              .having(
                (call) => call.arguments,
                'arguments',
                {'text': '1234-5678'},
              ),
        ),
        reason: 'Should copy code to clipboard',
      );
    });

    testWidgets('T028a: shows confirmation snackbar after copying',
        (tester) async {
      final mockCode = DeviceLinkCode(
        id: 'code-123',
        code: '1234-5678',
        tripId: 'trip-123',
        memberName: 'Alice',
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(minutes: 15)),
        used: false,
        usedAt: null,
      );

      when(mockCubit.state).thenReturn(CodeGenerated(mockCode));
      when(mockCubit.stream).thenAnswer(
        (_) => Stream<DevicePairingState>.value(CodeGenerated(mockCode)),
      );

      // Set up system channel for clipboard testing
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall methodCall) async {
          return null;
        },
      );

      await tester.pumpWidget(
        createTestWidget(
          tripId: 'trip-123',
          memberName: 'Alice',
        ),
      );

      // Tap copy button
      await tester.tap(find.widgetWithText(ElevatedButton, 'Copy to Clipboard'));
      await tester.pump(); // Start the snackbar animation
      await tester.pump(const Duration(milliseconds: 100)); // Let it appear

      // Verify snackbar appears
      expect(
        find.byType(SnackBar),
        findsOneWidget,
        reason: 'Should show confirmation snackbar after copying',
      );

      expect(
        find.textContaining('Copied'),
        findsOneWidget,
        reason: 'Snackbar should contain "Copied" message',
      );
    });

    testWidgets('displays countdown timer showing expiry time', (tester) async {
      final now = DateTime.now();
      final mockCode = DeviceLinkCode(
        id: 'code-123',
        code: '1234-5678',
        tripId: 'trip-123',
        memberName: 'Alice',
        createdAt: now,
        expiresAt: now.add(const Duration(minutes: 15)),
        used: false,
        usedAt: null,
      );

      when(mockCubit.state).thenReturn(CodeGenerated(mockCode));
      when(mockCubit.stream).thenAnswer(
        (_) => Stream<DevicePairingState>.value(CodeGenerated(mockCode)),
      );

      await tester.pumpWidget(
        createTestWidget(
          tripId: 'trip-123',
          memberName: 'Alice',
        ),
      );

      // Verify countdown/expiry info is displayed
      expect(
        find.textContaining('Expires in'),
        findsOneWidget,
        reason: 'Should show expiry message',
      );

      expect(
        find.textContaining('minute'),
        findsOneWidget,
        reason: 'Should show time unit (minute)',
      );
    });

    testWidgets('displays Close button', (tester) async {
      final mockCode = DeviceLinkCode(
        id: 'code-123',
        code: '1234-5678',
        tripId: 'trip-123',
        memberName: 'Alice',
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(minutes: 15)),
        used: false,
        usedAt: null,
      );

      when(mockCubit.state).thenReturn(CodeGenerated(mockCode));
      when(mockCubit.stream).thenAnswer(
        (_) => Stream<DevicePairingState>.value(CodeGenerated(mockCode)),
      );

      await tester.pumpWidget(
        createTestWidget(
          tripId: 'trip-123',
          memberName: 'Alice',
        ),
      );

      // Verify close button exists
      expect(
        find.widgetWithText(TextButton, 'Close'),
        findsOneWidget,
        reason: 'Should have Close button',
      );
    });

    testWidgets('Close button dismisses dialog', (tester) async {
      final mockCode = DeviceLinkCode(
        id: 'code-123',
        code: '1234-5678',
        tripId: 'trip-123',
        memberName: 'Alice',
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(minutes: 15)),
        used: false,
        usedAt: null,
      );

      when(mockCubit.state).thenReturn(CodeGenerated(mockCode));
      when(mockCubit.stream).thenAnswer(
        (_) => Stream<DevicePairingState>.value(CodeGenerated(mockCode)),
      );

      bool dialogDismissed = false;

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
                          builder: (dialogContext) =>
                              BlocProvider<DevicePairingCubit>.value(
                            value: mockCubit,
                            child: const CodeGenerationDialog(
                              tripId: 'trip-123',
                              memberName: 'Alice',
                            ),
                          ),
                        );
                        dialogDismissed = result == null;
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

      // Tap Close button
      await tester.tap(find.widgetWithText(TextButton, 'Close'));
      await tester.pumpAndSettle();

      // Verify dialog was dismissed
      expect(dialogDismissed, isTrue, reason: 'Close should dismiss dialog');
    });

    testWidgets('shows error message when code generation fails',
        (tester) async {
      // Set state to error
      when(mockCubit.state).thenReturn(
        const CodeGenerationError('Failed to generate code'),
      );
      when(mockCubit.stream).thenAnswer(
        (_) => Stream<DevicePairingState>.value(
          const CodeGenerationError('Failed to generate code'),
        ),
      );

      await tester.pumpWidget(
        createTestWidget(
          tripId: 'trip-123',
          memberName: 'Alice',
        ),
      );

      // Verify error message is displayed
      expect(
        find.textContaining('Failed'),
        findsOneWidget,
        reason: 'Should display error message',
      );

      // Verify no code or copy button is shown
      expect(
        find.widgetWithText(ElevatedButton, 'Copy to Clipboard'),
        findsNothing,
        reason: 'Should not show copy button when error occurred',
      );
    });

    testWidgets('automatically calls generateCode on dialog open',
        (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          tripId: 'trip-123',
          memberName: 'Alice',
        ),
      );

      // Wait for initState to complete
      await tester.pump();

      // Verify cubit.generateCode was called with correct parameters
      verify(mockCubit.generateCode('trip-123', 'Alice')).called(1);
    });

    testWidgets('displays code in selectable text widget', (tester) async {
      final mockCode = DeviceLinkCode(
        id: 'code-123',
        code: '1234-5678',
        tripId: 'trip-123',
        memberName: 'Alice',
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(minutes: 15)),
        used: false,
        usedAt: null,
      );

      when(mockCubit.state).thenReturn(CodeGenerated(mockCode));
      when(mockCubit.stream).thenAnswer(
        (_) => Stream<DevicePairingState>.value(CodeGenerated(mockCode)),
      );

      await tester.pumpWidget(
        createTestWidget(
          tripId: 'trip-123',
          memberName: 'Alice',
        ),
      );

      // Verify code is in SelectableText widget for manual copying
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is SelectableText && widget.data == '1234-5678',
        ),
        findsOneWidget,
        reason: 'Code should be displayed in SelectableText for manual copying',
      );
    });

    testWidgets('handles member names with special characters',
        (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          tripId: 'trip-123',
          memberName: "O'Brien",
        ),
      );

      // Wait for initState
      await tester.pump();

      // Verify cubit was called with correct name
      verify(mockCubit.generateCode('trip-123', "O'Brien")).called(1);

      // Verify name is displayed correctly
      expect(
        find.textContaining("O'Brien"),
        findsOneWidget,
        reason: 'Should handle member names with special characters',
      );
    });
  });
}
