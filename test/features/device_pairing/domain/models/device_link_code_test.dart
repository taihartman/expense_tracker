import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/device_pairing/domain/models/device_link_code.dart';

void main() {
  group('DeviceLinkCode', () {
    final now = DateTime.now();
    final expiresAt = now.add(const Duration(minutes: 15));

    DeviceLinkCode createValidCode({
      String id = 'code123',
      String code = '1234-5678',
      String tripId = 'trip123',
      String memberName = 'Alice',
      DateTime? createdAt,
      DateTime? expiresAt,
      bool used = false,
      DateTime? usedAt,
    }) {
      return DeviceLinkCode(
        id: id,
        code: code,
        tripId: tripId,
        memberName: memberName,
        createdAt: createdAt ?? now,
        expiresAt: expiresAt ?? now.add(const Duration(minutes: 15)),
        used: used,
        usedAt: usedAt,
      );
    }

    group('constructor', () {
      test('creates instance with all required fields', () {
        final code = createValidCode();

        expect(code.id, 'code123');
        expect(code.code, '1234-5678');
        expect(code.tripId, 'trip123');
        expect(code.memberName, 'Alice');
        expect(code.createdAt, now);
        expect(code.expiresAt, expiresAt);
        expect(code.used, false);
        expect(code.usedAt, isNull);
      });

      test('creates instance with optional usedAt field', () {
        final usedAt = now.add(const Duration(minutes: 5));
        final code = createValidCode(used: true, usedAt: usedAt);

        expect(code.used, true);
        expect(code.usedAt, usedAt);
      });
    });

    group('validate', () {
      test('returns null for valid code', () {
        final code = createValidCode();
        expect(code.validate(), isNull);
      });

      test('returns error if code length is not 9 characters', () {
        final code = createValidCode(code: '1234-567'); // 8 chars
        expect(code.validate(), contains('Code must be 8 digits'));
      });

      test('returns error if code is too long', () {
        final code = createValidCode(code: '1234-56789'); // 10 chars
        expect(code.validate(), contains('Code must be 8 digits'));
      });

      test('returns error if tripId is empty', () {
        final code = createValidCode(tripId: '');
        expect(code.validate(), contains('Trip ID is required'));
      });

      test('returns error if memberName is empty', () {
        final code = createValidCode(memberName: '');
        expect(code.validate(), contains('Member name is required'));
      });

      test('returns error if expiresAt is before createdAt', () {
        final created = now;
        final expired = now.subtract(const Duration(minutes: 1));
        final code = createValidCode(createdAt: created, expiresAt: expired);
        expect(code.validate(), contains('Expiry time must be after creation'));
      });

      test('returns error if used is true but usedAt is null', () {
        final code = createValidCode(used: true, usedAt: null);
        expect(
          code.validate(),
          contains('Used codes must have usedAt timestamp'),
        );
      });

      test('allows used codes with usedAt timestamp', () {
        final code = createValidCode(
          used: true,
          usedAt: now.add(const Duration(minutes: 5)),
        );
        expect(code.validate(), isNull);
      });
    });

    group('isExpired', () {
      test('returns false for code that has not expired', () {
        final code = createValidCode(
          expiresAt: DateTime.now().add(const Duration(minutes: 10)),
        );
        expect(code.isExpired, false);
      });

      test('returns true for code that has expired', () {
        final code = createValidCode(
          expiresAt: DateTime.now().subtract(const Duration(minutes: 1)),
        );
        expect(code.isExpired, true);
      });

      test('returns true for code expiring exactly now', () {
        // Account for timing precision - code expiring within 1 second is considered expired
        final code = createValidCode(
          expiresAt: DateTime.now().subtract(const Duration(milliseconds: 100)),
        );
        expect(code.isExpired, true);
      });
    });

    group('isValid', () {
      test('returns true for unused, unexpired code', () {
        final code = createValidCode(
          used: false,
          expiresAt: DateTime.now().add(const Duration(minutes: 10)),
        );
        expect(code.isValid, true);
      });

      test('returns false for used code (even if not expired)', () {
        final code = createValidCode(
          used: true,
          usedAt: DateTime.now(),
          expiresAt: DateTime.now().add(const Duration(minutes: 10)),
        );
        expect(code.isValid, false);
      });

      test('returns false for expired code (even if not used)', () {
        final code = createValidCode(
          used: false,
          expiresAt: DateTime.now().subtract(const Duration(minutes: 1)),
        );
        expect(code.isValid, false);
      });

      test('returns false for used and expired code', () {
        final code = createValidCode(
          used: true,
          usedAt: DateTime.now().subtract(const Duration(minutes: 5)),
          expiresAt: DateTime.now().subtract(const Duration(minutes: 1)),
        );
        expect(code.isValid, false);
      });
    });

    group('timeUntilExpiry', () {
      test('returns positive duration for unexpired code', () {
        final code = createValidCode(
          expiresAt: DateTime.now().add(const Duration(minutes: 10)),
        );
        final timeLeft = code.timeUntilExpiry;
        expect(
          timeLeft.inMinutes,
          greaterThanOrEqualTo(9),
        ); // Account for test execution time
        expect(timeLeft.inMinutes, lessThanOrEqualTo(10));
      });

      test('returns negative duration for expired code', () {
        final code = createValidCode(
          expiresAt: DateTime.now().subtract(const Duration(minutes: 5)),
        );
        final timeLeft = code.timeUntilExpiry;
        expect(timeLeft.isNegative, true);
      });

      test('returns zero or negative for code expiring now', () {
        final code = createValidCode(expiresAt: DateTime.now());
        final timeLeft = code.timeUntilExpiry;
        expect(
          timeLeft.inSeconds,
          lessThanOrEqualTo(1),
        ); // Allow 1 second tolerance
      });
    });

    group('copyWith', () {
      test('creates new instance with updated fields', () {
        final original = createValidCode();
        final updated = original.copyWith(code: '8765-4321', memberName: 'Bob');

        expect(updated.code, '8765-4321');
        expect(updated.memberName, 'Bob');
        expect(updated.id, original.id); // Unchanged
        expect(updated.tripId, original.tripId); // Unchanged
      });

      test('creates new instance when marking as used', () {
        final original = createValidCode(used: false, usedAt: null);
        final usedTime = DateTime.now();
        final updated = original.copyWith(used: true, usedAt: usedTime);

        expect(updated.used, true);
        expect(updated.usedAt, usedTime);
        expect(original.used, false); // Original unchanged
        expect(original.usedAt, isNull); // Original unchanged
      });

      test('returns same instance if no fields changed', () {
        final original = createValidCode();
        final updated = original.copyWith();

        expect(updated, equals(original));
      });
    });

    group('toMap and fromMap', () {
      test('converts to map with all fields', () {
        final code = createValidCode(
          used: true,
          usedAt: now.add(const Duration(minutes: 5)),
        );
        final map = code.toMap();

        expect(map['id'], 'code123');
        expect(map['code'], '1234-5678');
        expect(map['tripId'], 'trip123');
        expect(map['memberName'], 'Alice');
        expect(map['createdAt'], isA<DateTime>());
        expect(map['expiresAt'], isA<DateTime>());
        expect(map['used'], true);
        expect(map['usedAt'], isA<DateTime>());
      });

      test('creates instance from map', () {
        final map = {
          'id': 'code456',
          'code': '5678-1234',
          'tripId': 'trip456',
          'memberName': 'Charlie',
          'createdAt': now,
          'expiresAt': expiresAt,
          'used': false,
          'usedAt': null,
        };
        final code = DeviceLinkCode.fromMap(map);

        expect(code.id, 'code456');
        expect(code.code, '5678-1234');
        expect(code.tripId, 'trip456');
        expect(code.memberName, 'Charlie');
        expect(code.used, false);
        expect(code.usedAt, isNull);
      });

      test('roundtrip conversion preserves data', () {
        final original = createValidCode();
        final map = original.toMap();
        final recovered = DeviceLinkCode.fromMap(map);

        expect(recovered.id, original.id);
        expect(recovered.code, original.code);
        expect(recovered.tripId, original.tripId);
        expect(recovered.memberName, original.memberName);
        expect(recovered.used, original.used);
      });
    });

    group('equality', () {
      test('two codes with same data are equal', () {
        final code1 = createValidCode();
        final code2 = createValidCode();

        expect(code1, equals(code2));
      });

      test('two codes with different IDs are not equal', () {
        final code1 = createValidCode(id: 'code1');
        final code2 = createValidCode(id: 'code2');

        expect(code1, isNot(equals(code2)));
      });

      test('two codes with different codes are not equal', () {
        final code1 = createValidCode(code: '1234-5678');
        final code2 = createValidCode(code: '8765-4321');

        expect(code1, isNot(equals(code2)));
      });
    });
  });
}
