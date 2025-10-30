import 'dart:convert';

import 'package:expense_tracker/core/models/version_response.dart';
import 'package:expense_tracker/core/services/app_lifecycle_service.dart';
import 'package:expense_tracker/core/services/version_check_service.dart';
import 'package:expense_tracker/core/widgets/update_notification_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'update_flow_test.mocks.dart';

@GenerateMocks([http.Client, AppLifecycleService])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Update Flow Integration Tests', () {
    late MockClient mockHttpClient;
    late MockAppLifecycleService mockLifecycleService;
    late VersionCheckService versionCheckService;

    setUp(() {
      mockHttpClient = MockClient();
      mockLifecycleService = MockAppLifecycleService();

      // Setup default PackageInfo for local version 1.0.0
      PackageInfo.setMockInitialValues(
        appName: 'expense_tracker',
        packageName: 'com.example.expense_tracker',
        version: '1.0.0',
        buildNumber: '1',
        buildSignature: '',
      );

      versionCheckService = VersionCheckServiceImpl(
        httpClient: mockHttpClient,
        versionJsonUrl: '/version.json',
        timeout: const Duration(seconds: 2),
        debounceInterval: const Duration(seconds: 10),
      );
    });

    tearDown(() {
      versionCheckService.dispose();
    });

    testWidgets('T037: Full update flow - version mismatch triggers notification',
        (tester) async {
      // Arrange: Mock HTTP response with newer version
      final newerVersion = VersionResponse(version: '1.1.0');
      when(mockHttpClient.get(Uri.parse('/version.json')))
          .thenAnswer((_) async => http.Response(
                jsonEncode(newerVersion.toJson()),
                200,
              ));

      // Setup lifecycle service to not call onResume immediately
      when(mockLifecycleService.startObserving(onResume: anyNamed('onResume')))
          .thenReturn(null);
      when(mockLifecycleService.stopObserving()).thenReturn(null);

      // Act: Render app with UpdateNotificationListener
      await tester.pumpWidget(
        MaterialApp(
          home: UpdateNotificationListener(
            versionCheckService: versionCheckService,
            lifecycleService: mockLifecycleService,
            child: const Scaffold(
              body: Center(child: Text('Test App')),
            ),
          ),
        ),
      );

      // Wait for initial check to complete
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Assert: Notification banner should appear
      expect(find.text('A new version is available'), findsOneWidget);
      expect(find.text('Update Now'), findsOneWidget);
      expect(find.text('Dismiss'), findsOneWidget);
      expect(find.byIcon(Icons.system_update), findsOneWidget);

      // Verify HTTP was called
      verify(mockHttpClient.get(Uri.parse('/version.json'))).called(1);
    });

    testWidgets('T038: Dismiss and reappear behavior', (tester) async {
      // Arrange: Mock HTTP response with newer version
      final newerVersion = VersionResponse(version: '1.1.0');
      when(mockHttpClient.get(Uri.parse('/version.json')))
          .thenAnswer((_) async => http.Response(
                jsonEncode(newerVersion.toJson()),
                200,
              ));

      VoidCallback? capturedOnResume;
      when(mockLifecycleService.startObserving(onResume: anyNamed('onResume')))
          .thenAnswer((invocation) {
        capturedOnResume =
            invocation.namedArguments[const Symbol('onResume')] as VoidCallback;
      });
      when(mockLifecycleService.stopObserving()).thenReturn(null);

      // Act: Render app and wait for initial notification
      await tester.pumpWidget(
        MaterialApp(
          home: UpdateNotificationListener(
            versionCheckService: versionCheckService,
            lifecycleService: mockLifecycleService,
            child: const Scaffold(
              body: Center(child: Text('Test App')),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Assert: Banner appears initially
      expect(find.text('A new version is available'), findsOneWidget);

      // Act: Dismiss the banner
      await tester.tap(find.text('Dismiss'));
      await tester.pumpAndSettle();

      // Assert: Banner is hidden
      expect(find.text('A new version is available'), findsNothing);

      // Act: Simulate app resume (tab becomes visible again)
      // Wait for debounce interval to pass
      await tester.pump(const Duration(seconds: 11));
      capturedOnResume?.call();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Assert: Banner reappears after resume
      expect(find.text('A new version is available'), findsOneWidget);

      // Verify HTTP was called twice (initial + resume)
      verify(mockHttpClient.get(Uri.parse('/version.json'))).called(2);
    });

    testWidgets('T039: No-update scenario - equal versions', (tester) async {
      // Arrange: Mock HTTP response with same version as local
      final sameVersion = VersionResponse(version: '1.0.0');
      when(mockHttpClient.get(Uri.parse('/version.json')))
          .thenAnswer((_) async => http.Response(
                jsonEncode(sameVersion.toJson()),
                200,
              ));

      when(mockLifecycleService.startObserving(onResume: anyNamed('onResume')))
          .thenReturn(null);
      when(mockLifecycleService.stopObserving()).thenReturn(null);

      // Act: Render app with UpdateNotificationListener
      await tester.pumpWidget(
        MaterialApp(
          home: UpdateNotificationListener(
            versionCheckService: versionCheckService,
            lifecycleService: mockLifecycleService,
            child: const Scaffold(
              body: Center(child: Text('Test App')),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Assert: No notification banner should appear
      expect(find.text('A new version is available'), findsNothing);
      expect(find.text('Update Now'), findsNothing);

      // App content should still be visible
      expect(find.text('Test App'), findsOneWidget);

      // Verify HTTP was called
      verify(mockHttpClient.get(Uri.parse('/version.json'))).called(1);
    });

    testWidgets('T039a: localStorage preservation after reload', (tester) async {
      // Note: This test verifies the conceptual behavior since window.location.reload()
      // cannot be fully tested in Flutter test environment without a real browser.
      // In practice, window.location.reload() DOES preserve localStorage.

      // Arrange: Mock HTTP response with newer version
      final newerVersion = VersionResponse(version: '1.1.0');
      when(mockHttpClient.get(Uri.parse('/version.json')))
          .thenAnswer((_) async => http.Response(
                jsonEncode(newerVersion.toJson()),
                200,
              ));

      when(mockLifecycleService.startObserving(onResume: anyNamed('onResume')))
          .thenReturn(null);
      when(mockLifecycleService.stopObserving()).thenReturn(null);

      // Act: Render app
      await tester.pumpWidget(
        MaterialApp(
          home: UpdateNotificationListener(
            versionCheckService: versionCheckService,
            lifecycleService: mockLifecycleService,
            child: const Scaffold(
              body: Center(child: Text('Test App')),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Assert: Banner appears
      expect(find.text('A new version is available'), findsOneWidget);

      // Note: Actual localStorage preservation is verified through:
      // 1. Manual browser testing (see quickstart.md)
      // 2. The implementation uses window.location.reload() which is
      //    documented to preserve localStorage by HTML5 spec
      // 3. No service worker unregister is performed
      //
      // This test validates the UI flow exists; manual testing validates
      // that the reload mechanism preserves localStorage.
    });

    testWidgets('T037: Network error handling - no notification on failure',
        (tester) async {
      // Arrange: Mock HTTP to throw exception
      when(mockHttpClient.get(Uri.parse('/version.json')))
          .thenThrow(Exception('Network error'));

      when(mockLifecycleService.startObserving(onResume: anyNamed('onResume')))
          .thenReturn(null);
      when(mockLifecycleService.stopObserving()).thenReturn(null);

      // Act: Render app
      await tester.pumpWidget(
        MaterialApp(
          home: UpdateNotificationListener(
            versionCheckService: versionCheckService,
            lifecycleService: mockLifecycleService,
            child: const Scaffold(
              body: Center(child: Text('Test App')),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Assert: No notification should appear on error
      expect(find.text('A new version is available'), findsNothing);
      expect(find.text('Test App'), findsOneWidget);

      // Verify HTTP was attempted
      verify(mockHttpClient.get(Uri.parse('/version.json'))).called(1);
    });

    testWidgets('T037: Debouncing prevents rapid checks', (tester) async {
      // Arrange: Mock HTTP response
      final newerVersion = VersionResponse(version: '1.1.0');
      when(mockHttpClient.get(Uri.parse('/version.json')))
          .thenAnswer((_) async => http.Response(
                jsonEncode(newerVersion.toJson()),
                200,
              ));

      VoidCallback? capturedOnResume;
      when(mockLifecycleService.startObserving(onResume: anyNamed('onResume')))
          .thenAnswer((invocation) {
        capturedOnResume =
            invocation.namedArguments[const Symbol('onResume')] as VoidCallback;
      });
      when(mockLifecycleService.stopObserving()).thenReturn(null);

      // Act: Render app
      await tester.pumpWidget(
        MaterialApp(
          home: UpdateNotificationListener(
            versionCheckService: versionCheckService,
            lifecycleService: mockLifecycleService,
            child: const Scaffold(
              body: Center(child: Text('Test App')),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify initial check
      verify(mockHttpClient.get(Uri.parse('/version.json'))).called(1);

      // Act: Trigger rapid resume events within debounce interval
      capturedOnResume?.call();
      await tester.pump(const Duration(milliseconds: 100));
      capturedOnResume?.call();
      await tester.pump(const Duration(milliseconds: 100));
      capturedOnResume?.call();
      await tester.pump(const Duration(milliseconds: 100));

      // Assert: No additional HTTP calls due to debouncing
      verify(mockHttpClient.get(Uri.parse('/version.json'))).called(1);

      // Act: Wait for debounce interval to expire
      await tester.pump(const Duration(seconds: 11));
      capturedOnResume?.call();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Assert: New check is performed after debounce interval
      verify(mockHttpClient.get(Uri.parse('/version.json'))).called(2);
    });
  });
}
