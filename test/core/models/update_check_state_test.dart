import 'package:expense_tracker/core/models/update_check_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pub_semver/pub_semver.dart';

void main() {
  group('UpdateCheckState', () {
    group('shouldDebounce', () {
      test('returns false when lastCheckTime is null (first check)', () {
        const state = UpdateCheckState();

        expect(state.shouldDebounce(const Duration(seconds: 10)), false);
      });

      test('returns true when within minimum interval', () {
        final state = UpdateCheckState(
          lastCheckTime: DateTime.now().subtract(const Duration(seconds: 5)),
        );

        expect(state.shouldDebounce(const Duration(seconds: 10)), true);
      });

      test('returns false when exactly at minimum interval', () {
        final state = UpdateCheckState(
          lastCheckTime: DateTime.now().subtract(const Duration(seconds: 10)),
        );

        // Account for test execution time - should be very close to boundary
        expect(state.shouldDebounce(const Duration(seconds: 10)), false);
      });

      test('returns false when beyond minimum interval', () {
        final state = UpdateCheckState(
          lastCheckTime: DateTime.now().subtract(const Duration(seconds: 15)),
        );

        expect(state.shouldDebounce(const Duration(seconds: 10)), false);
      });

      test('handles different minimum intervals correctly', () {
        final state = UpdateCheckState(
          lastCheckTime: DateTime.now().subtract(const Duration(seconds: 3)),
        );

        expect(state.shouldDebounce(const Duration(seconds: 5)), true);
        expect(state.shouldDebounce(const Duration(seconds: 2)), false);
      });
    });

    group('copyWith', () {
      test('creates new instance with updated lastCheckTime', () {
        const original = UpdateCheckState();
        final newTime = DateTime.now();
        final updated = original.copyWith(lastCheckTime: newTime);

        expect(updated.lastCheckTime, newTime);
        expect(updated.isCheckingNow, original.isCheckingNow);
        expect(updated.updateAvailable, original.updateAvailable);
        expect(updated.serverVersion, original.serverVersion);
      });

      test('creates new instance with updated isCheckingNow', () {
        const original = UpdateCheckState(isCheckingNow: false);
        final updated = original.copyWith(isCheckingNow: true);

        expect(updated.isCheckingNow, true);
        expect(updated.lastCheckTime, original.lastCheckTime);
      });

      test('creates new instance with updated updateAvailable', () {
        const original = UpdateCheckState(updateAvailable: false);
        final updated = original.copyWith(updateAvailable: true);

        expect(updated.updateAvailable, true);
      });

      test('creates new instance with updated serverVersion', () {
        const original = UpdateCheckState();
        final version = Version.parse('1.0.1+2');
        final updated = original.copyWith(serverVersion: version);

        expect(updated.serverVersion, version);
      });

      test('preserves original values when no parameters provided', () {
        final originalTime = DateTime.now();
        final originalVersion = Version.parse('1.0.0+1');
        final original = UpdateCheckState(
          lastCheckTime: originalTime,
          isCheckingNow: true,
          updateAvailable: true,
          serverVersion: originalVersion,
        );

        final updated = original.copyWith();

        expect(updated.lastCheckTime, originalTime);
        expect(updated.isCheckingNow, true);
        expect(updated.updateAvailable, true);
        expect(updated.serverVersion, originalVersion);
      });
    });

    group('equality', () {
      test('two instances with same values are equal', () {
        final time = DateTime(2025, 1, 30);
        final version = Version.parse('1.0.0+1');

        final state1 = UpdateCheckState(
          lastCheckTime: time,
          isCheckingNow: false,
          updateAvailable: true,
          serverVersion: version,
        );

        final state2 = UpdateCheckState(
          lastCheckTime: time,
          isCheckingNow: false,
          updateAvailable: true,
          serverVersion: version,
        );

        expect(state1, equals(state2));
        expect(state1.hashCode, equals(state2.hashCode));
      });

      test('two instances with different lastCheckTime are not equal', () {
        final state1 = UpdateCheckState(
          lastCheckTime: DateTime(2025, 1, 30, 10, 0),
        );

        final state2 = UpdateCheckState(
          lastCheckTime: DateTime(2025, 1, 30, 10, 5),
        );

        expect(state1, isNot(equals(state2)));
      });

      test('two instances with different isCheckingNow are not equal', () {
        const state1 = UpdateCheckState(isCheckingNow: true);
        const state2 = UpdateCheckState(isCheckingNow: false);

        expect(state1, isNot(equals(state2)));
      });
    });

    group('toString', () {
      test('returns readable string representation', () {
        final time = DateTime(2025, 1, 30, 12, 0);
        final version = Version.parse('1.2.3+4');

        final state = UpdateCheckState(
          lastCheckTime: time,
          isCheckingNow: true,
          updateAvailable: true,
          serverVersion: version,
        );

        final string = state.toString();

        expect(string, contains('UpdateCheckState'));
        expect(string, contains('lastCheckTime: $time'));
        expect(string, contains('isCheckingNow: true'));
        expect(string, contains('updateAvailable: true'));
        expect(string, contains('serverVersion: $version'));
      });
    });

    group('state transitions', () {
      test('initial state has sensible defaults', () {
        const state = UpdateCheckState();

        expect(state.lastCheckTime, isNull);
        expect(state.isCheckingNow, false);
        expect(state.updateAvailable, false);
        expect(state.serverVersion, isNull);
      });

      test('transition to checking state', () {
        const initial = UpdateCheckState();
        final checking = initial.copyWith(isCheckingNow: true);

        expect(checking.isCheckingNow, true);
        expect(checking.updateAvailable, false);
      });

      test('transition from checking to update available', () {
        const checking = UpdateCheckState(isCheckingNow: true);
        final serverVersion = Version.parse('1.0.1+2');
        final updateAvailable = checking.copyWith(
          isCheckingNow: false,
          updateAvailable: true,
          serverVersion: serverVersion,
          lastCheckTime: DateTime.now(),
        );

        expect(updateAvailable.isCheckingNow, false);
        expect(updateAvailable.updateAvailable, true);
        expect(updateAvailable.serverVersion, serverVersion);
        expect(updateAvailable.lastCheckTime, isNotNull);
      });

      test('transition from checking to no update', () {
        const checking = UpdateCheckState(isCheckingNow: true);
        final noUpdate = checking.copyWith(
          isCheckingNow: false,
          updateAvailable: false,
          lastCheckTime: DateTime.now(),
        );

        expect(noUpdate.isCheckingNow, false);
        expect(noUpdate.updateAvailable, false);
        expect(noUpdate.lastCheckTime, isNotNull);
      });
    });
  });
}
