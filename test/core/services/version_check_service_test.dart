import 'package:expense_tracker/core/services/version_check_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:package_info_plus/package_info_plus.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('VersionCheckServiceImpl', () {
    group('version comparison logic', () {
      test('detects newer server version (patch increment)', () async {
        // Setup: Local = 1.0.0, Server = 1.0.1
        PackageInfo.setMockInitialValues(
          appName: 'expense_tracker',
          packageName: 'com.example.expense_tracker',
          version: '1.0.0',
          buildNumber: '1',
          buildSignature: '',
        );

        final mockClient = MockClient((request) async {
          return http.Response('{"version": "1.0.1+2"}', 200);
        });

        final service = VersionCheckServiceImpl(
          httpClient: mockClient,
          versionJsonUrl: 'https://example.com/version.json',
        );

        final result = await service.isUpdateAvailable();

        expect(result, true);
        service.dispose();
      });

      test('detects newer server version (minor increment)', () async {
        PackageInfo.setMockInitialValues(
          appName: 'expense_tracker',
          packageName: 'com.example.expense_tracker',
          version: '1.0.5',
          buildNumber: '1',
          buildSignature: '',
        );

        final mockClient = MockClient((request) async {
          return http.Response('{"version": "1.1.0+1"}', 200);
        });

        final service = VersionCheckServiceImpl(
          httpClient: mockClient,
          versionJsonUrl: 'https://example.com/version.json',
        );

        final result = await service.isUpdateAvailable();

        expect(result, true);
        service.dispose();
      });

      test('detects newer server version (major increment)', () async {
        PackageInfo.setMockInitialValues(
          appName: 'expense_tracker',
          packageName: 'com.example.expense_tracker',
          version: '1.9.9',
          buildNumber: '1',
          buildSignature: '',
        );

        final mockClient = MockClient((request) async {
          return http.Response('{"version": "2.0.0+1"}', 200);
        });

        final service = VersionCheckServiceImpl(
          httpClient: mockClient,
          versionJsonUrl: 'https://example.com/version.json',
        );

        final result = await service.isUpdateAvailable();

        expect(result, true);
        service.dispose();
      });

      test('returns false when versions are equal (including build)', () async {
        // Note: PackageInfo version format is "major.minor.patch" without build
        // so we need to ensure server version matches exactly
        PackageInfo.setMockInitialValues(
          appName: 'expense_tracker',
          packageName: 'com.example.expense_tracker',
          version: '1.0.1',
          buildNumber: '2',
          buildSignature: '',
        );

        final mockClient = MockClient((request) async {
          // Server version must match local version (1.0.1 from PackageInfo)
          return http.Response('{"version": "1.0.1"}', 200);
        });

        final service = VersionCheckServiceImpl(
          httpClient: mockClient,
          versionJsonUrl: 'https://example.com/version.json',
        );

        final result = await service.isUpdateAvailable();

        expect(result, false);
        service.dispose();
      });

      test('returns false when server version is older', () async {
        PackageInfo.setMockInitialValues(
          appName: 'expense_tracker',
          packageName: 'com.example.expense_tracker',
          version: '1.0.2',
          buildNumber: '3',
          buildSignature: '',
        );

        final mockClient = MockClient((request) async {
          return http.Response('{"version": "1.0.1+2"}', 200);
        });

        final service = VersionCheckServiceImpl(
          httpClient: mockClient,
          versionJsonUrl: 'https://example.com/version.json',
        );

        final result = await service.isUpdateAvailable();

        expect(result, false);
        service.dispose();
      });

      test('handles malformed version strings gracefully', () async {
        PackageInfo.setMockInitialValues(
          appName: 'expense_tracker',
          packageName: 'com.example.expense_tracker',
          version: '1.0.0',
          buildNumber: '1',
          buildSignature: '',
        );

        final mockClient = MockClient((request) async {
          return http.Response('{"version": "invalid-version"}', 200);
        });

        final service = VersionCheckServiceImpl(
          httpClient: mockClient,
          versionJsonUrl: 'https://example.com/version.json',
        );

        final result = await service.isUpdateAvailable();

        expect(result, false); // Silent failure
        service.dispose();
      });

      test('compares versions ignoring build number metadata', () async {
        // Semantic versioning: 1.0.1+99 > 1.0.0+1 (build number doesn't affect order)
        PackageInfo.setMockInitialValues(
          appName: 'expense_tracker',
          packageName: 'com.example.expense_tracker',
          version: '1.0.0',
          buildNumber: '999',
          buildSignature: '',
        );

        final mockClient = MockClient((request) async {
          return http.Response('{"version": "1.0.1+1"}', 200);
        });

        final service = VersionCheckServiceImpl(
          httpClient: mockClient,
          versionJsonUrl: 'https://example.com/version.json',
        );

        final result = await service.isUpdateAvailable();

        expect(result, true);
        service.dispose();
      });
    });

    group('debouncing behavior', () {
      test('performs first check immediately (no debounce)', () async {
        PackageInfo.setMockInitialValues(
          appName: 'expense_tracker',
          packageName: 'com.example.expense_tracker',
          version: '1.0.0',
          buildNumber: '1',
          buildSignature: '',
        );

        var callCount = 0;
        final mockClient = MockClient((request) async {
          callCount++;
          return http.Response('{"version": "1.0.1+2"}', 200);
        });

        final service = VersionCheckServiceImpl(
          httpClient: mockClient,
          versionJsonUrl: 'https://example.com/version.json',
          debounceInterval: const Duration(seconds: 10),
        );

        await service.isUpdateAvailable();

        expect(callCount, 1);
        service.dispose();
      });

      test('debounces rapid successive checks within interval', () async {
        PackageInfo.setMockInitialValues(
          appName: 'expense_tracker',
          packageName: 'com.example.expense_tracker',
          version: '1.0.0',
          buildNumber: '1',
          buildSignature: '',
        );

        var callCount = 0;
        final mockClient = MockClient((request) async {
          callCount++;
          return http.Response('{"version": "1.0.1+2"}', 200);
        });

        final service = VersionCheckServiceImpl(
          httpClient: mockClient,
          versionJsonUrl: 'https://example.com/version.json',
          debounceInterval: const Duration(seconds: 10),
        );

        // First check
        await service.isUpdateAvailable();
        expect(callCount, 1);

        // Rapid second check (within 10 seconds) - should be debounced
        await service.isUpdateAvailable();
        expect(callCount, 1); // Still 1, not 2

        service.dispose();
      });

      test('allows check after debounce interval expires', () async {
        PackageInfo.setMockInitialValues(
          appName: 'expense_tracker',
          packageName: 'com.example.expense_tracker',
          version: '1.0.0',
          buildNumber: '1',
          buildSignature: '',
        );

        var callCount = 0;
        final mockClient = MockClient((request) async {
          callCount++;
          return http.Response('{"version": "1.0.1+2"}', 200);
        });

        final service = VersionCheckServiceImpl(
          httpClient: mockClient,
          versionJsonUrl: 'https://example.com/version.json',
          debounceInterval: const Duration(milliseconds: 100),
        );

        // First check
        await service.isUpdateAvailable();
        expect(callCount, 1);

        // Wait for debounce interval to expire
        await Future.delayed(const Duration(milliseconds: 150));

        // Second check - should proceed
        await service.isUpdateAvailable();
        expect(callCount, 2);

        service.dispose();
      });

      test('prevents concurrent checks', () async {
        PackageInfo.setMockInitialValues(
          appName: 'expense_tracker',
          packageName: 'com.example.expense_tracker',
          version: '1.0.0',
          buildNumber: '1',
          buildSignature: '',
        );

        var callCount = 0;
        final mockClient = MockClient((request) async {
          callCount++;
          // Simulate slow network
          await Future.delayed(const Duration(milliseconds: 100));
          return http.Response('{"version": "1.0.1+2"}', 200);
        });

        final service = VersionCheckServiceImpl(
          httpClient: mockClient,
          versionJsonUrl: 'https://example.com/version.json',
          debounceInterval: Duration.zero, // Disable debounce for this test
        );

        // Start two checks simultaneously
        final check1 = service.isUpdateAvailable();
        final check2 = service.isUpdateAvailable(); // Should be skipped

        await Future.wait([check1, check2]);

        expect(callCount, 1); // Only one HTTP call should have been made
        service.dispose();
      });
    });

    group('HTTP timeout handling', () {
      test('times out after specified duration', () async {
        PackageInfo.setMockInitialValues(
          appName: 'expense_tracker',
          packageName: 'com.example.expense_tracker',
          version: '1.0.0',
          buildNumber: '1',
          buildSignature: '',
        );

        final mockClient = MockClient((request) async {
          // Simulate slow server (longer than timeout)
          await Future.delayed(const Duration(seconds: 5));
          return http.Response('{"version": "1.0.1+2"}', 200);
        });

        final service = VersionCheckServiceImpl(
          httpClient: mockClient,
          versionJsonUrl: 'https://example.com/version.json',
          timeout: const Duration(milliseconds: 100),
        );

        final result = await service.isUpdateAvailable();

        expect(result, false); // Should return false on timeout
        service.dispose();
      });

      test('handles network errors gracefully', () async {
        PackageInfo.setMockInitialValues(
          appName: 'expense_tracker',
          packageName: 'com.example.expense_tracker',
          version: '1.0.0',
          buildNumber: '1',
          buildSignature: '',
        );

        final mockClient = MockClient((request) async {
          throw Exception('Network error');
        });

        final service = VersionCheckServiceImpl(
          httpClient: mockClient,
          versionJsonUrl: 'https://example.com/version.json',
        );

        final result = await service.isUpdateAvailable();

        expect(result, false); // Silent failure
        service.dispose();
      });

      test('returns false on 404 Not Found', () async {
        PackageInfo.setMockInitialValues(
          appName: 'expense_tracker',
          packageName: 'com.example.expense_tracker',
          version: '1.0.0',
          buildNumber: '1',
          buildSignature: '',
        );

        final mockClient = MockClient((request) async {
          return http.Response('Not Found', 404);
        });

        final service = VersionCheckServiceImpl(
          httpClient: mockClient,
          versionJsonUrl: 'https://example.com/version.json',
        );

        final result = await service.isUpdateAvailable();

        expect(result, false);
        service.dispose();
      });

      test('returns false on 500 Server Error', () async {
        PackageInfo.setMockInitialValues(
          appName: 'expense_tracker',
          packageName: 'com.example.expense_tracker',
          version: '1.0.0',
          buildNumber: '1',
          buildSignature: '',
        );

        final mockClient = MockClient((request) async {
          return http.Response('Internal Server Error', 500);
        });

        final service = VersionCheckServiceImpl(
          httpClient: mockClient,
          versionJsonUrl: 'https://example.com/version.json',
        );

        final result = await service.isUpdateAvailable();

        expect(result, false);
        service.dispose();
      });
    });

    group('getServerVersion', () {
      test('returns version string on success', () async {
        final mockClient = MockClient((request) async {
          return http.Response('{"version": "1.2.3+4"}', 200);
        });

        final service = VersionCheckServiceImpl(
          httpClient: mockClient,
          versionJsonUrl: 'https://example.com/version.json',
        );

        final version = await service.getServerVersion();

        expect(version, '1.2.3+4');
        service.dispose();
      });

      test('returns null on invalid JSON', () async {
        final mockClient = MockClient((request) async {
          return http.Response('invalid json', 200);
        });

        final service = VersionCheckServiceImpl(
          httpClient: mockClient,
          versionJsonUrl: 'https://example.com/version.json',
        );

        final version = await service.getServerVersion();

        expect(version, isNull);
        service.dispose();
      });

      test('returns null on timeout', () async {
        final mockClient = MockClient((request) async {
          await Future.delayed(const Duration(seconds: 5));
          return http.Response('{"version": "1.0.0+1"}', 200);
        });

        final service = VersionCheckServiceImpl(
          httpClient: mockClient,
          versionJsonUrl: 'https://example.com/version.json',
          timeout: const Duration(milliseconds: 100),
        );

        final version = await service.getServerVersion();

        expect(version, isNull);
        service.dispose();
      });
    });
  });
}
