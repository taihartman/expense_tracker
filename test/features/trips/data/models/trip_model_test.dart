import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:expense_tracker/features/trips/data/models/trip_model.dart';
import 'package:expense_tracker/features/trips/domain/models/trip.dart';
import 'package:expense_tracker/core/models/currency_code.dart';
import 'package:expense_tracker/core/models/participant.dart';

@GenerateMocks(
  [],
  customMocks: [
    MockSpec<DocumentSnapshot<Map<String, dynamic>>>(as: #MockDocSnapshot),
  ],
)
import 'trip_model_test.mocks.dart';

void main() {
  group('TripModel', () {
    final now = DateTime(2025, 11, 2, 12, 0, 0);
    final timestamp = Timestamp.fromDate(now);

    group('toJson', () {
      test('serializes trip with allowedCurrencies (new format)', () {
        // ignore: deprecated_member_use_from_same_package
        final trip = Trip(
          id: 'trip1',
          name: 'Vietnam 2025',
          allowedCurrencies: [CurrencyCode.usd, CurrencyCode.vnd],
          createdAt: now,
          updatedAt: now,
          isArchived: false,
        );

        final json = TripModel.toJson(trip);

        expect(json['name'], 'Vietnam 2025');
        expect(json['allowedCurrencies'], ['USD', 'VND']);
        expect(json['createdAt'], timestamp);
        expect(json['updatedAt'], timestamp);
        expect(json['isArchived'], false);
        expect(json['participants'], isEmpty);
        expect(json['lastExpenseModifiedAt'], isNull);
      });

      test('serializes trip with baseCurrency only (legacy format)', () {
        // ignore: deprecated_member_use_from_same_package
        final trip = Trip(
          id: 'trip1',
          name: 'Legacy Trip',
          baseCurrency: CurrencyCode.eur,
          allowedCurrencies: [],
          createdAt: now,
          updatedAt: now,
        );

        final json = TripModel.toJson(trip);

        expect(json['name'], 'Legacy Trip');
        expect(json['baseCurrency'], 'EUR');
        expect(json.containsKey('allowedCurrencies'), false); // Empty list not serialized
        expect(json['createdAt'], timestamp);
        expect(json['updatedAt'], timestamp);
      });

      test('serializes trip with both allowedCurrencies and baseCurrency for backward compatibility', () {
        // ignore: deprecated_member_use_from_same_package
        final trip = Trip(
          id: 'trip1',
          name: 'Transition Trip',
          baseCurrency: CurrencyCode.usd,
          allowedCurrencies: [CurrencyCode.usd, CurrencyCode.eur],
          createdAt: now,
          updatedAt: now,
        );

        final json = TripModel.toJson(trip);

        expect(json['allowedCurrencies'], ['USD', 'EUR']);
        expect(json['baseCurrency'], 'USD');
      });

      test('serializes trip with participants', () {
        final participants = [
          const Participant(id: 'user1', name: 'Alice'),
          const Participant(id: 'user2', name: 'Bob'),
        ];

        // ignore: deprecated_member_use_from_same_package
        final trip = Trip(
          id: 'trip1',
          name: 'Group Trip',
          allowedCurrencies: [CurrencyCode.usd],
          participants: participants,
          createdAt: now,
          updatedAt: now,
        );

        final json = TripModel.toJson(trip);

        expect(json['participants'], hasLength(2));
        expect(json['participants'][0]['id'], 'user1');
        expect(json['participants'][1]['name'], 'Bob');
      });

      test('serializes trip with lastExpenseModifiedAt', () {
        final modifiedAt = DateTime(2025, 11, 1);

        // ignore: deprecated_member_use_from_same_package
        final trip = Trip(
          id: 'trip1',
          name: 'Active Trip',
          allowedCurrencies: [CurrencyCode.usd],
          createdAt: now,
          updatedAt: now,
          lastExpenseModifiedAt: modifiedAt,
        );

        final json = TripModel.toJson(trip);

        expect(json['lastExpenseModifiedAt'], Timestamp.fromDate(modifiedAt));
      });

      test('serializes archived trip', () {
        // ignore: deprecated_member_use_from_same_package
        final trip = Trip(
          id: 'trip1',
          name: 'Archived Trip',
          allowedCurrencies: [CurrencyCode.usd],
          createdAt: now,
          updatedAt: now,
          isArchived: true,
        );

        final json = TripModel.toJson(trip);

        expect(json['isArchived'], true);
      });
    });

    group('fromFirestore', () {
      test('deserializes trip with allowedCurrencies (new format)', () {
        final mockDoc = _createMockDoc('trip1', {
          'name': 'Vietnam 2025',
          'allowedCurrencies': ['USD', 'VND'],
          'createdAt': timestamp,
          'updatedAt': timestamp,
          'isArchived': false,
          'participants': [],
        });

        final trip = TripModel.fromFirestore(mockDoc);

        expect(trip.id, 'trip1');
        expect(trip.name, 'Vietnam 2025');
        expect(trip.allowedCurrencies, [CurrencyCode.usd, CurrencyCode.vnd]);
        expect(trip.defaultCurrency, CurrencyCode.usd); // First in list
        expect(trip.createdAt, now);
        expect(trip.updatedAt, now);
        expect(trip.isArchived, false);
        expect(trip.participants, isEmpty);
      });

      test('deserializes legacy trip with baseCurrency only (migration)', () {
        final mockDoc = _createMockDoc('trip1', {
          'name': 'Legacy Trip',
          'baseCurrency': 'EUR',
          'createdAt': timestamp,
          'updatedAt': timestamp,
          'isArchived': false,
        });

        final trip = TripModel.fromFirestore(mockDoc);

        expect(trip.id, 'trip1');
        expect(trip.name, 'Legacy Trip');
        expect(trip.baseCurrency, CurrencyCode.eur);
        // Migration: baseCurrency should be migrated to allowedCurrencies
        expect(trip.allowedCurrencies, [CurrencyCode.eur]);
        expect(trip.defaultCurrency, CurrencyCode.eur);
      });

      test('deserializes trip with both allowedCurrencies and baseCurrency (prefers allowedCurrencies)', () {
        final mockDoc = _createMockDoc('trip1', {
          'name': 'Transition Trip',
          'allowedCurrencies': ['USD', 'EUR', 'GBP'],
          'baseCurrency': 'VND', // Should be ignored when allowedCurrencies exists
          'createdAt': timestamp,
          'updatedAt': timestamp,
        });

        final trip = TripModel.fromFirestore(mockDoc);

        expect(trip.allowedCurrencies, [CurrencyCode.usd, CurrencyCode.eur, CurrencyCode.gbp]);
        expect(trip.baseCurrency, CurrencyCode.vnd); // Still parsed for backward compat
        expect(trip.defaultCurrency, CurrencyCode.usd); // From allowedCurrencies, not baseCurrency
      });

      test('deserializes trip with participants', () {
        final mockDoc = _createMockDoc('trip1', {
          'name': 'Group Trip',
          'allowedCurrencies': ['USD'],
          'createdAt': timestamp,
          'updatedAt': timestamp,
          'participants': [
            {'id': 'user1', 'name': 'Alice'},
            {'id': 'user2', 'name': 'Bob'},
          ],
        });

        final trip = TripModel.fromFirestore(mockDoc);

        expect(trip.participants.length, 2);
        expect(trip.participants[0].id, 'user1');
        expect(trip.participants[0].name, 'Alice');
        expect(trip.participants[1].name, 'Bob');
      });

      test('deserializes trip with lastExpenseModifiedAt', () {
        final modifiedAt = DateTime(2025, 11, 1);
        final mockDoc = _createMockDoc('trip1', {
          'name': 'Active Trip',
          'allowedCurrencies': ['USD'],
          'createdAt': timestamp,
          'updatedAt': timestamp,
          'lastExpenseModifiedAt': Timestamp.fromDate(modifiedAt),
        });

        final trip = TripModel.fromFirestore(mockDoc);

        expect(trip.lastExpenseModifiedAt, modifiedAt);
      });

      test('handles missing lastExpenseModifiedAt (defaults to null)', () {
        final mockDoc = _createMockDoc('trip1', {
          'name': 'New Trip',
          'allowedCurrencies': ['USD'],
          'createdAt': timestamp,
          'updatedAt': timestamp,
        });

        final trip = TripModel.fromFirestore(mockDoc);

        expect(trip.lastExpenseModifiedAt, isNull);
      });

      test('handles missing isArchived (defaults to false)', () {
        final mockDoc = _createMockDoc('trip1', {
          'name': 'Trip',
          'allowedCurrencies': ['USD'],
          'createdAt': timestamp,
          'updatedAt': timestamp,
        });

        final trip = TripModel.fromFirestore(mockDoc);

        expect(trip.isArchived, false);
      });

      test('handles missing participants (defaults to empty list)', () {
        final mockDoc = _createMockDoc('trip1', {
          'name': 'Solo Trip',
          'allowedCurrencies': ['USD'],
          'createdAt': timestamp,
          'updatedAt': timestamp,
        });

        final trip = TripModel.fromFirestore(mockDoc);

        expect(trip.participants, isEmpty);
      });

      test('filters out invalid currency codes from allowedCurrencies', () {
        final mockDoc = _createMockDoc('trip1', {
          'name': 'Trip',
          'allowedCurrencies': ['USD', 'INVALID', 'EUR', 'NOTREAL'],
          'createdAt': timestamp,
          'updatedAt': timestamp,
        });

        final trip = TripModel.fromFirestore(mockDoc);

        // Invalid codes should be filtered out
        expect(trip.allowedCurrencies, [CurrencyCode.usd, CurrencyCode.eur]);
      });

      test('handles empty allowedCurrencies list with baseCurrency fallback', () {
        final mockDoc = _createMockDoc('trip1', {
          'name': 'Trip',
          'allowedCurrencies': [],
          'baseCurrency': 'JPY',
          'createdAt': timestamp,
          'updatedAt': timestamp,
        });

        final trip = TripModel.fromFirestore(mockDoc);

        // Should migrate baseCurrency to allowedCurrencies
        expect(trip.allowedCurrencies, [CurrencyCode.jpy]);
        expect(trip.defaultCurrency, CurrencyCode.jpy);
      });

      test('handles invalid baseCurrency (defaults to USD)', () {
        final mockDoc = _createMockDoc('trip1', {
          'name': 'Trip',
          'baseCurrency': 'INVALID',
          'createdAt': timestamp,
          'updatedAt': timestamp,
        });

        final trip = TripModel.fromFirestore(mockDoc);

        // Invalid baseCurrency should default to USD during parsing
        expect(trip.baseCurrency, CurrencyCode.usd);
        expect(trip.allowedCurrencies, [CurrencyCode.usd]); // Migrated from baseCurrency
      });
    });

    group('fromSnapshot', () {
      test('calls fromFirestore (alias)', () {
        final mockDoc = _createMockDoc('trip1', {
          'name': 'Test Trip',
          'allowedCurrencies': ['USD'],
          'createdAt': timestamp,
          'updatedAt': timestamp,
        });

        final trip = TripModel.fromSnapshot(mockDoc);

        expect(trip.id, 'trip1');
        expect(trip.name, 'Test Trip');
      });
    });

    group('migration logic', () {
      test('migrates baseCurrency to allowedCurrencies on read', () {
        // Simulate legacy Firestore document with only baseCurrency
        final mockDoc = _createMockDoc('trip1', {
          'name': 'Legacy Trip 2020',
          'baseCurrency': 'CAD',
          'createdAt': timestamp,
          'updatedAt': timestamp,
        });

        final trip = TripModel.fromFirestore(mockDoc);

        // Verify migration happened
        expect(trip.baseCurrency, CurrencyCode.cad); // Preserved for backward compat
        expect(trip.allowedCurrencies, [CurrencyCode.cad]); // Migrated!
        expect(trip.defaultCurrency, CurrencyCode.cad); // Works correctly
      });

      test('round-trip: legacy trip preserves currency after deserialization and serialization', () {
        // Start with legacy format
        final mockDoc = _createMockDoc('trip1', {
          'name': 'Round Trip Test',
          'baseCurrency': 'CHF',
          'createdAt': timestamp,
          'updatedAt': timestamp,
        });

        // Deserialize (triggers migration)
        final trip = TripModel.fromFirestore(mockDoc);

        // Serialize back
        final json = TripModel.toJson(trip);

        // Should write both formats for backward compatibility
        expect(json['allowedCurrencies'], ['CHF']); // New format
        expect(json['baseCurrency'], 'CHF'); // Old format preserved
      });
    });
  });
}

/// Helper to create mock DocumentSnapshot
MockDocSnapshot _createMockDoc(String id, Map<String, dynamic> data) {
  final mockDoc = MockDocSnapshot();
  when(mockDoc.id).thenReturn(id);
  when(mockDoc.data()).thenReturn(data);
  return mockDoc;
}
