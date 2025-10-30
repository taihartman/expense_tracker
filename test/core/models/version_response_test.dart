import 'package:expense_tracker/core/models/version_response.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('VersionResponse', () {
    group('fromJson', () {
      test('parses valid JSON with version field', () {
        final json = {'version': '1.0.1+2'};
        final response = VersionResponse.fromJson(json);

        expect(response.version, '1.0.1+2');
      });

      test('parses version without build number', () {
        final json = {'version': '2.3.4'};
        final response = VersionResponse.fromJson(json);

        expect(response.version, '2.3.4');
      });

      test('throws TypeError when version field is missing', () {
        final json = <String, dynamic>{};

        expect(() => VersionResponse.fromJson(json), throwsA(isA<TypeError>()));
      });

      test('throws TypeError when version field is null', () {
        final json = {'version': null};

        expect(() => VersionResponse.fromJson(json), throwsA(isA<TypeError>()));
      });

      test('throws TypeError when version field is not a string', () {
        final json = {'version': 123};

        expect(() => VersionResponse.fromJson(json), throwsA(isA<TypeError>()));
      });
    });

    group('toJson', () {
      test('converts to JSON correctly', () {
        final response = VersionResponse(version: '1.0.1+2');
        final json = response.toJson();

        expect(json, {'version': '1.0.1+2'});
      });

      test('handles version without build number', () {
        final response = VersionResponse(version: '3.2.1');
        final json = response.toJson();

        expect(json, {'version': '3.2.1'});
      });
    });

    group('equality', () {
      test('two instances with same version are equal', () {
        final response1 = VersionResponse(version: '1.0.0+1');
        final response2 = VersionResponse(version: '1.0.0+1');

        expect(response1, equals(response2));
        expect(response1.hashCode, equals(response2.hashCode));
      });

      test('two instances with different versions are not equal', () {
        final response1 = VersionResponse(version: '1.0.0+1');
        final response2 = VersionResponse(version: '1.0.0+2');

        expect(response1, isNot(equals(response2)));
      });
    });

    group('toString', () {
      test('returns readable string representation', () {
        final response = VersionResponse(version: '1.2.3+4');

        expect(response.toString(), 'VersionResponse(version: 1.2.3+4)');
      });
    });
  });
}
