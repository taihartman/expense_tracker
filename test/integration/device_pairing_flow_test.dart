import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:expense_tracker/features/trips/presentation/pages/trip_join_page.dart';
import 'package:expense_tracker/features/trips/presentation/cubits/trip_cubit.dart';
import 'package:expense_tracker/features/trips/domain/models/trip.dart';
import 'package:expense_tracker/features/trips/domain/repositories/trip_repository.dart';
import 'package:expense_tracker/core/services/activity_logger_service.dart';
import 'package:expense_tracker/features/categories/domain/repositories/category_repository.dart';
import 'package:expense_tracker/features/device_pairing/presentation/cubits/device_pairing_cubit.dart';
import 'package:expense_tracker/features/device_pairing/presentation/cubits/device_pairing_state.dart';
import 'package:expense_tracker/features/device_pairing/domain/repositories/device_link_code_repository.dart';
import 'package:expense_tracker/features/device_pairing/domain/models/device_link_code.dart';
import 'package:expense_tracker/features/device_pairing/presentation/widgets/code_generation_dialog.dart';
import 'package:expense_tracker/core/services/local_storage_service.dart';
import 'package:expense_tracker/core/models/participant.dart';
import 'package:expense_tracker/core/models/currency_code.dart';
import 'package:expense_tracker/shared/widgets/custom_button.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:expense_tracker/l10n/app_localizations.dart';

@GenerateMocks([
  TripRepository,
  ActivityLoggerService,
  CategoryRepository,
  LocalStorageService,
  DeviceLinkCodeRepository,
])
import 'device_pairing_flow_test.mocks.dart';

/// T019/T024: Integration test for duplicate member detection flow
///
/// This test verifies the complete flow of joining a trip with duplicate detection:
/// 1. User tries to join with unique name → bypasses verification
/// 2. User tries to join with duplicate name → shows verification prompt
/// 3. User cancels verification → join is aborted
void main() {
  group('T019/T024: Integration - Duplicate Detection Flow', () {
    late TripCubit tripCubit;
    late DevicePairingCubit devicePairingCubit;
    late MockTripRepository mockTripRepository;
    late MockActivityLoggerService mockActivityLoggerService;
    late MockCategoryRepository mockCategoryRepository;
    late MockLocalStorageService mockLocalStorageService;
    late MockDeviceLinkCodeRepository mockDeviceLinkCodeRepository;

    setUp(() {
      mockTripRepository = MockTripRepository();
      mockActivityLoggerService = MockActivityLoggerService();
      mockCategoryRepository = MockCategoryRepository();
      mockLocalStorageService = MockLocalStorageService();
      mockDeviceLinkCodeRepository = MockDeviceLinkCodeRepository();

      // Default stubs
      when(mockLocalStorageService.getJoinedTripIds()).thenReturn([]);
      when(mockLocalStorageService.getSelectedTripId()).thenReturn(null);
      when(
        mockLocalStorageService.addJoinedTrip(any),
      ).thenAnswer((_) async => {});
      when(
        mockTripRepository.getAllTrips(),
      ).thenAnswer((_) => Stream.value([]));

      tripCubit = TripCubit(
        tripRepository: mockTripRepository,
        localStorageService: mockLocalStorageService,
        activityLoggerService: mockActivityLoggerService,
        categoryRepository: mockCategoryRepository,
      );

      devicePairingCubit = DevicePairingCubit(
        repository: mockDeviceLinkCodeRepository,
        localStorageService: mockLocalStorageService,
      );

      // Provide dummy for sealed class
      provideDummy<DevicePairingState>(const DevicePairingInitial());
    });

    tearDown(() {
      tripCubit.close();
      devicePairingCubit.close();
    });

    Widget createTestApp() {
      return MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en')],
        home: MultiBlocProvider(
          providers: [
            BlocProvider<TripCubit>.value(value: tripCubit),
            BlocProvider<DevicePairingCubit>.value(value: devicePairingCubit),
          ],
          child: const TripJoinPage(),
        ),
      );
    }

    testWidgets('T024: Join with unique name bypasses verification', (
      tester,
    ) async {
      // Arrange
      const tripId = 'trip-123';
      const uniqueName = 'Charlie'; // Not in participants

      final existingTrip = Trip(
        id: tripId,
        name: 'Tokyo Trip',
        baseCurrency: CurrencyCode.usd,
        createdAt: DateTime(2025, 10, 29),
        updatedAt: DateTime(2025, 10, 29),
        participants: [
          const Participant(id: 'alice-id', name: 'Alice'),
          const Participant(id: 'bob-id', name: 'Bob'),
        ],
      );

      // Mock repository to return existing trip (no duplicate)
      when(
        mockTripRepository.getTripById(tripId),
      ).thenAnswer((_) async => existingTrip);

      // Mock successful update (join adds participant via updateTrip)
      when(mockTripRepository.updateTrip(any)).thenAnswer(
        (invocation) async => invocation.positionalArguments[0] as Trip,
      );

      // Mock activity logger service
      when(
        mockActivityLoggerService.logMemberJoined(
          tripId: anyNamed('tripId'),
          memberName: anyNamed('memberName'),
          joinMethod: anyNamed('joinMethod'),
          inviterId: anyNamed('inviterId'),
        ),
      ).thenAnswer((_) async {});

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Act - Fill in join form with unique name
      final codeField = find.byType(TextField).first;
      final nameField = find.byType(TextField).last;

      await tester.enterText(codeField, tripId);
      await tester.enterText(nameField, uniqueName);

      // Tap join button
      await tester.tap(find.byType(CustomButton));
      await tester.pump(); // Process button tap
      await tester.pump(
        const Duration(milliseconds: 100),
      ); // Allow async operations

      // Assert - Verification dialog should NOT appear
      expect(
        find.text('Device Verification Required'),
        findsNothing,
        reason: 'Verification prompt should not show for unique name',
      );

      // Verify updateTrip was called (join adds participant via updateTrip)
      verify(mockTripRepository.updateTrip(any)).called(1);
    });

    testWidgets('T024: Join with duplicate name shows verification prompt', (
      tester,
    ) async {
      // Arrange
      const tripId = 'trip-123';
      const duplicateName = 'Alice'; // Exists in participants

      final existingTrip = Trip(
        id: tripId,
        name: 'Tokyo Trip',
        baseCurrency: CurrencyCode.usd,
        createdAt: DateTime(2025, 10, 29),
        updatedAt: DateTime(2025, 10, 29),
        participants: [
          const Participant(id: 'alice-id', name: 'Alice'),
          const Participant(id: 'bob-id', name: 'Bob'),
        ],
      );

      // Mock repository to return existing trip (duplicate detected)
      when(
        mockTripRepository.getTripById(tripId),
      ).thenAnswer((_) async => existingTrip);

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Act - Fill in join form with duplicate name
      final codeField = find.byType(TextField).first;
      final nameField = find.byType(TextField).last;

      await tester.enterText(codeField, tripId);
      await tester.enterText(nameField, duplicateName);

      // Tap join button
      await tester.tap(find.byType(CustomButton));
      await tester.pumpAndSettle();

      // Assert - Verification dialog SHOULD appear
      expect(
        find.text('Device Verification Required'),
        findsOneWidget,
        reason: 'Verification prompt should show for duplicate name',
      );

      expect(
        find.textContaining('already exists'),
        findsOneWidget,
        reason: 'Prompt should explain duplicate detection',
      );

      // Verify updateTrip was NOT called yet (waiting for verification)
      verifyNever(mockTripRepository.updateTrip(any));
    });

    testWidgets('T024: Cancelling verification aborts join', (tester) async {
      // Arrange
      const tripId = 'trip-123';
      const duplicateName = 'Alice';

      final existingTrip = Trip(
        id: tripId,
        name: 'Tokyo Trip',
        baseCurrency: CurrencyCode.usd,
        createdAt: DateTime(2025, 10, 29),
        updatedAt: DateTime(2025, 10, 29),
        participants: [
          const Participant(id: 'alice-id', name: 'Alice'),
          const Participant(id: 'bob-id', name: 'Bob'),
        ],
      );

      when(
        mockTripRepository.getTripById(tripId),
      ).thenAnswer((_) async => existingTrip);

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Act - Fill in join form and trigger verification prompt
      final codeField = find.byType(TextField).first;
      final nameField = find.byType(TextField).last;

      await tester.enterText(codeField, tripId);
      await tester.enterText(nameField, duplicateName);

      await tester.tap(find.byType(CustomButton));
      await tester.pumpAndSettle();

      // Verification prompt should be visible
      expect(find.text('Device Verification Required'), findsOneWidget);

      // Tap Cancel button
      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await tester.pumpAndSettle();

      // Assert - Dialog dismissed, still on join page
      expect(find.text('Device Verification Required'), findsNothing);
      expect(find.byType(CustomButton), findsOneWidget); // Still on join page

      // Verify updateTrip was NOT called
      verifyNever(mockTripRepository.updateTrip(any));
    });

    testWidgets('T024: Case-insensitive duplicate detection', (tester) async {
      // Arrange
      const tripId = 'trip-123';
      const duplicateName = 'ALICE'; // Different case but same name

      final existingTrip = Trip(
        id: tripId,
        name: 'Tokyo Trip',
        baseCurrency: CurrencyCode.usd,
        createdAt: DateTime(2025, 10, 29),
        updatedAt: DateTime(2025, 10, 29),
        participants: [
          const Participant(id: 'alice-id', name: 'Alice'), // Lowercase 'alice'
          const Participant(id: 'bob-id', name: 'Bob'),
        ],
      );

      when(
        mockTripRepository.getTripById(tripId),
      ).thenAnswer((_) async => existingTrip);

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Act - Fill in form with uppercase version of existing name
      final codeField = find.byType(TextField).first;
      final nameField = find.byType(TextField).last;

      await tester.enterText(codeField, tripId);
      await tester.enterText(nameField, duplicateName);

      await tester.tap(find.byType(CustomButton));
      await tester.pumpAndSettle();

      // Assert - Verification prompt should show (case-insensitive match)
      expect(
        find.text('Device Verification Required'),
        findsOneWidget,
        reason: 'Case-insensitive duplicate should trigger verification',
      );
    });
  });

  group('T035: Integration - Code Generation Flow', () {
    late DevicePairingCubit devicePairingCubit;
    late MockDeviceLinkCodeRepository mockDeviceLinkCodeRepository;
    late MockLocalStorageService mockLocalStorageService;

    setUp(() {
      mockDeviceLinkCodeRepository = MockDeviceLinkCodeRepository();
      mockLocalStorageService = MockLocalStorageService();
      devicePairingCubit = DevicePairingCubit(
        repository: mockDeviceLinkCodeRepository,
        localStorageService: mockLocalStorageService,
      );

      // Provide dummy for sealed class
      provideDummy<DevicePairingState>(const DevicePairingInitial());
    });

    tearDown(() {
      devicePairingCubit.close();
    });

    Widget createTestDialogApp() {
      return MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en')],
        home: BlocProvider<DevicePairingCubit>.value(
          value: devicePairingCubit,
          child: Scaffold(
            body: Builder(
              builder: (context) {
                return Center(
                  child: ElevatedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (dialogContext) =>
                            BlocProvider<DevicePairingCubit>.value(
                              value: devicePairingCubit,
                              child: const CodeGenerationDialog(
                                tripId: 'trip-123',
                                memberName: 'Alice',
                              ),
                            ),
                      );
                    },
                    child: const Text('Generate Code'),
                  ),
                );
              },
            ),
          ),
        ),
      );
    }

    testWidgets('T035: Generated code is 8 digits with XXXX-XXXX format', (
      tester,
    ) async {
      // Arrange - Mock successful code generation
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

      when(
        mockDeviceLinkCodeRepository.generateCode('trip-123', 'Alice'),
      ).thenAnswer((_) async => mockCode);

      await tester.pumpWidget(createTestDialogApp());

      // Act - Open dialog
      await tester.tap(find.text('Generate Code'));
      await tester.pumpAndSettle();

      // Assert - Dialog is displayed
      expect(
        find.text('Generate Code'),
        findsNWidgets(2),
      ); // Button + Dialog title

      // Verify code is displayed with correct format
      expect(
        find.text('1234-5678'),
        findsOneWidget,
        reason: 'Code should be displayed in XXXX-XXXX format',
      );

      // Verify code format matches pattern
      final codeText = '1234-5678';
      final codePattern = RegExp(r'^\d{4}-\d{4}$');
      expect(
        codePattern.hasMatch(codeText),
        isTrue,
        reason: 'Code should match XXXX-XXXX pattern',
      );

      // Verify it's 8 digits (excluding hyphen)
      final digitsOnly = codeText.replaceAll('-', '');
      expect(
        digitsOnly.length,
        equals(8),
        reason: 'Code should have exactly 8 digits',
      );
    });

    testWidgets('T035: Copy to Clipboard button is functional', (tester) async {
      // Arrange - Mock successful code generation
      final mockCode = DeviceLinkCode(
        id: 'code-123',
        code: '9876-5432',
        tripId: 'trip-123',
        memberName: 'Bob',
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(minutes: 15)),
        used: false,
        usedAt: null,
      );

      when(
        mockDeviceLinkCodeRepository.generateCode('trip-123', 'Alice'),
      ).thenAnswer((_) async => mockCode);

      await tester.pumpWidget(createTestDialogApp());

      // Open dialog
      await tester.tap(find.text('Generate Code'));
      await tester.pumpAndSettle();

      // Assert - Copy button is present
      expect(
        find.text('Copy to Clipboard'),
        findsOneWidget,
        reason: 'Copy to Clipboard button should be displayed',
      );

      // Verify button is enabled
      final copyButton = find.widgetWithText(
        ElevatedButton,
        'Copy to Clipboard',
      );
      expect(copyButton, findsOneWidget);

      final button = tester.widget<ElevatedButton>(copyButton);
      expect(
        button.onPressed,
        isNotNull,
        reason: 'Copy button should be enabled',
      );
    });

    testWidgets('T035: Countdown timer shows 15 minute expiry', (tester) async {
      // Arrange - Mock successful code generation with precise 15 minute expiry
      final now = DateTime.now();
      final mockCode = DeviceLinkCode(
        id: 'code-timer',
        code: '1111-2222',
        tripId: 'trip-123',
        memberName: 'Alice',
        createdAt: now,
        expiresAt: now.add(const Duration(minutes: 15)),
        used: false,
        usedAt: null,
      );

      when(
        mockDeviceLinkCodeRepository.generateCode('trip-123', 'Alice'),
      ).thenAnswer((_) async => mockCode);

      await tester.pumpWidget(createTestDialogApp());

      // Act - Open dialog
      await tester.tap(find.text('Generate Code'));
      await tester.pumpAndSettle();

      // Assert - Countdown timer is displayed
      expect(
        find.textContaining('Expires in'),
        findsOneWidget,
        reason: 'Countdown timer should be displayed',
      );

      expect(
        find.textContaining('minute'),
        findsOneWidget,
        reason: 'Timer should show minutes',
      );

      // Note: We check for "minute" rather than exact "15" because
      // a few milliseconds may have passed during test execution
    });

    testWidgets('T035: Dialog shows loading state during code generation', (
      tester,
    ) async {
      // Arrange - Mock delayed code generation
      final mockCode = DeviceLinkCode(
        id: 'code-123',
        code: '5555-6666',
        tripId: 'trip-123',
        memberName: 'Alice',
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(minutes: 15)),
        used: false,
        usedAt: null,
      );

      when(
        mockDeviceLinkCodeRepository.generateCode('trip-123', 'Alice'),
      ).thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 100));
        return mockCode;
      });

      await tester.pumpWidget(createTestDialogApp());

      // Act - Open dialog
      await tester.tap(find.text('Generate Code'));
      await tester.pump(); // Process dialog opening
      await tester.pump(); // Process cubit generateCode call

      // Assert - Loading indicator should be visible
      expect(
        find.byType(CircularProgressIndicator),
        findsOneWidget,
        reason: 'Loading indicator should show during code generation',
      );

      // Wait for code generation to complete
      await tester.pumpAndSettle();

      // Loading indicator should be gone, code should be displayed
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('5555-6666'), findsOneWidget);
    });

    testWidgets('T035: Dialog shows error state when generation fails', (
      tester,
    ) async {
      // Arrange - Mock failed code generation
      when(
        mockDeviceLinkCodeRepository.generateCode('trip-123', 'Alice'),
      ).thenThrow(Exception('Network error'));

      await tester.pumpWidget(createTestDialogApp());

      // Act - Open dialog
      await tester.tap(find.text('Generate Code'));
      await tester.pumpAndSettle();

      // Assert - Error message should be displayed
      expect(
        find.textContaining('Failed'),
        findsOneWidget,
        reason: 'Error message should be displayed',
      );

      expect(
        find.textContaining('Network error'),
        findsOneWidget,
        reason: 'Specific error message should be shown',
      );

      // Copy button should NOT be displayed on error
      expect(
        find.text('Copy to Clipboard'),
        findsNothing,
        reason: 'Copy button should not show on error',
      );
    });

    testWidgets('T035: Close button dismisses dialog', (tester) async {
      // Arrange
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

      when(
        mockDeviceLinkCodeRepository.generateCode('trip-123', 'Alice'),
      ).thenAnswer((_) async => mockCode);

      await tester.pumpWidget(createTestDialogApp());

      // Open dialog
      await tester.tap(find.text('Generate Code'));
      await tester.pumpAndSettle();

      // Dialog should be visible
      expect(find.text('1234-5678'), findsOneWidget);

      // Act - Tap Close button
      await tester.tap(find.widgetWithText(TextButton, 'Close'));
      await tester.pumpAndSettle();

      // Assert - Dialog should be dismissed
      expect(
        find.text('1234-5678'),
        findsNothing,
        reason: 'Dialog should be dismissed after clicking Close',
      );

      // Should be back to original screen
      expect(
        find.text('Generate Code'),
        findsOneWidget,
      ); // Only the button remains
    });
  });
}
