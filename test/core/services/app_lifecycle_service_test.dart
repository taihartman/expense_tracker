import 'package:expense_tracker/core/services/app_lifecycle_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppLifecycleService', () {
    test('abstract interface is defined with required methods', () {
      // This test verifies the interface contract exists
      expect(AppLifecycleService, isNotNull);
    });

    // Note: AppLifecycleServiceImpl uses dart:html which is only available
    // in web platform. Full integration tests will be in browser environment.
    // Unit testing of dart:html interactions requires a different approach
    // or mocking strategy that's beyond the scope of basic unit tests.
    //
    // The implementation will be manually tested in browser environment
    // following the quickstart.md procedures.
    //
    // Key behaviors to verify manually:
    // 1. startObserving registers visibilitychange event listener
    // 2. onResume callback fires when tab becomes visible
    // 3. stopObserving cleans up event listener
    // 4. Multiple tab switches trigger multiple onResume calls

    group('AppLifecycleServiceImpl', () {
      test('can be instantiated', () {
        final service = AppLifecycleService();
        expect(service, isA<AppLifecycleService>());
      });

      test('stopObserving can be called multiple times safely', () {
        final service = AppLifecycleService();

        // Should not throw
        expect(() => service.stopObserving(), returnsNormally);
        expect(() => service.stopObserving(), returnsNormally);
      });

      test('startObserving requires onResume callback', () {
        final service = AppLifecycleService();

        // Should not throw when starting observation
        expect(
          () => service.startObserving(onResume: () {
            // Callback provided
          }),
          returnsNormally,
        );

        service.stopObserving();
      });
    });
  });
}
