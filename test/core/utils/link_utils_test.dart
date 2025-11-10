import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/core/utils/link_utils.dart';

void main() {
  group('extractTripIdFromQrUrl', () {
    group('valid URLs', () {
      test('extracts trip ID from basic QR URL', () {
        const url =
            'https://expenses.taihartman.com/#/trips/join?code=abc123xyz';
        final result = extractTripIdFromQrUrl(url);

        expect(result, 'abc123xyz');
      });

      test('extracts trip ID from QR URL with source parameter', () {
        const url =
            'https://expenses.taihartman.com/#/trips/join?code=trip-abc-123&source=qr';
        final result = extractTripIdFromQrUrl(url);

        expect(result, 'trip-abc-123');
      });

      test('extracts trip ID from QR URL with sharedBy parameter', () {
        const url =
            'https://expenses.taihartman.com/#/trips/join?code=xyz789&source=qr&sharedBy=participant-id';
        final result = extractTripIdFromQrUrl(url);

        expect(result, 'xyz789');
      });

      test('extracts trip ID from invite link without source parameter', () {
        const url =
            'https://expenses.taihartman.com/#/trips/join?code=invite123&sharedBy=user1';
        final result = extractTripIdFromQrUrl(url);

        expect(result, 'invite123');
      });

      test('handles trip ID with special characters', () {
        const url =
            'https://expenses.taihartman.com/#/trips/join?code=abc_123-xyz.456';
        final result = extractTripIdFromQrUrl(url);

        expect(result, 'abc_123-xyz.456');
      });

      test('handles very long trip ID', () {
        const longId =
            'very-long-trip-id-with-many-characters-and-dashes-12345678901234567890';
        final url =
            'https://expenses.taihartman.com/#/trips/join?code=$longId';
        final result = extractTripIdFromQrUrl(url);

        expect(result, longId);
      });
    });

    group('invalid URLs', () {
      test('returns null for wrong host', () {
        const url = 'https://example.com/#/trips/join?code=abc123';
        final result = extractTripIdFromQrUrl(url);

        expect(result, null);
      });

      test('returns null for wrong path', () {
        const url = 'https://expenses.taihartman.com/#/other/path?code=abc123';
        final result = extractTripIdFromQrUrl(url);

        expect(result, null);
      });

      test('returns null when code parameter is missing', () {
        const url =
            'https://expenses.taihartman.com/#/trips/join?source=qr&sharedBy=user1';
        final result = extractTripIdFromQrUrl(url);

        expect(result, null);
      });

      test('returns null when query string is missing', () {
        const url = 'https://expenses.taihartman.com/#/trips/join';
        final result = extractTripIdFromQrUrl(url);

        expect(result, null);
      });

      test('returns null for malformed URL', () {
        const url = 'not-a-valid-url';
        final result = extractTripIdFromQrUrl(url);

        expect(result, null);
      });

      test('returns null for empty string', () {
        const url = '';
        final result = extractTripIdFromQrUrl(url);

        expect(result, null);
      });

      test('returns null for URL without fragment', () {
        const url = 'https://expenses.taihartman.com/trips/join?code=abc123';
        final result = extractTripIdFromQrUrl(url);

        expect(result, null);
      });

      test('returns null for completely different URL', () {
        const url = 'https://google.com';
        final result = extractTripIdFromQrUrl(url);

        expect(result, null);
      });
    });

    group('edge cases', () {
      test('handles URL with empty code parameter', () {
        const url = 'https://expenses.taihartman.com/#/trips/join?code=';
        final result = extractTripIdFromQrUrl(url);

        expect(result, '');
      });

      test('handles URL with code parameter at different position', () {
        const url =
            'https://expenses.taihartman.com/#/trips/join?source=qr&code=xyz123&sharedBy=user1';
        final result = extractTripIdFromQrUrl(url);

        expect(result, 'xyz123');
      });

      test('handles URL with duplicate code parameters (returns first)', () {
        const url =
            'https://expenses.taihartman.com/#/trips/join?code=first&code=second';
        final result = extractTripIdFromQrUrl(url);

        expect(result, 'first');
      });

      test('handles URL with encoded characters in trip ID', () {
        const url =
            'https://expenses.taihartman.com/#/trips/join?code=trip%20with%20spaces';
        final result = extractTripIdFromQrUrl(url);

        expect(result, 'trip with spaces');
      });

      test('handles URL with fragment but wrong path format', () {
        const url =
            'https://expenses.taihartman.com/#/trips/create?code=abc123';
        final result = extractTripIdFromQrUrl(url);

        expect(result, null);
      });
    });
  });
}
