import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_tracker/features/trips/data/repositories/trip_repository_impl.dart';
import 'package:expense_tracker/features/trips/domain/exceptions/trip_exceptions.dart';
import 'package:expense_tracker/core/models/currency_code.dart';
import 'package:expense_tracker/shared/services/firestore_service.dart';

@GenerateMocks(
  [FirestoreService],
  customMocks: [
    MockSpec<CollectionReference<Map<String, dynamic>>>(as: #MockCollectionRef),
    MockSpec<DocumentReference<Map<String, dynamic>>>(as: #MockDocumentRef),
    MockSpec<DocumentSnapshot<Map<String, dynamic>>>(as: #MockDocSnapshot),
  ],
)
import 'trip_repository_impl_test.mocks.dart';

void main() {
  group('TripRepositoryImpl - Multi-Currency Methods', () {
    late TripRepositoryImpl repository;
    late MockFirestoreService mockFirestoreService;
    late MockCollectionRef mockTripsCollection;
    late MockDocumentRef mockDocRef;
    late MockDocSnapshot mockDocSnapshot;

    final now = DateTime(2025, 11, 2, 12, 0, 0);
    final timestamp = Timestamp.fromDate(now);

    setUp(() {
      mockFirestoreService = MockFirestoreService();
      mockTripsCollection = MockCollectionRef();
      mockDocRef = MockDocumentRef();
      mockDocSnapshot = MockDocSnapshot();

      // Setup default mocking
      when(mockFirestoreService.trips).thenReturn(mockTripsCollection);
      when(mockTripsCollection.doc(any)).thenReturn(mockDocRef);

      repository = TripRepositoryImpl(firestoreService: mockFirestoreService);
    });

    group('getAllowedCurrencies', () {
      test('returns allowedCurrencies when field exists (new format)', () async {
        // Arrange
        const tripId = 'trip123';
        final tripData = {
          'name': 'Multi-Currency Trip',
          'allowedCurrencies': ['USD', 'EUR', 'GBP'],
          'createdAt': timestamp,
          'updatedAt': timestamp,
          'isArchived': false,
        };

        when(mockDocRef.get()).thenAnswer((_) async => mockDocSnapshot);
        when(mockDocSnapshot.exists).thenReturn(true);
        when(mockDocSnapshot.id).thenReturn(tripId);
        when(mockDocSnapshot.data()).thenReturn(tripData);

        // Act
        final result = await repository.getAllowedCurrencies(tripId);

        // Assert
        expect(result, [CurrencyCode.usd, CurrencyCode.eur, CurrencyCode.gbp]);
        verify(mockDocRef.get()).called(1);
      });

      test('returns [baseCurrency] for legacy trip (migration fallback)', () async {
        // Arrange
        const tripId = 'legacy123';
        final tripData = {
          'name': 'Legacy Trip',
          'baseCurrency': 'VND',
          'createdAt': timestamp,
          'updatedAt': timestamp,
          'isArchived': false,
        };

        when(mockDocRef.get()).thenAnswer((_) async => mockDocSnapshot);
        when(mockDocSnapshot.exists).thenReturn(true);
        when(mockDocSnapshot.id).thenReturn(tripId);
        when(mockDocSnapshot.data()).thenReturn(tripData);

        // Act
        final result = await repository.getAllowedCurrencies(tripId);

        // Assert
        // Migration happens in TripModel.fromFirestore - baseCurrency migrates to allowedCurrencies
        expect(result, [CurrencyCode.vnd]);
      });

      test('throws TripNotFoundException when trip does not exist', () async {
        // Arrange
        const tripId = 'nonexistent';

        when(mockDocRef.get()).thenAnswer((_) async => mockDocSnapshot);
        when(mockDocSnapshot.exists).thenReturn(false);

        // Act & Assert
        expect(
          () => repository.getAllowedCurrencies(tripId),
          throwsA(isA<TripNotFoundException>()),
        );
      });

      test('throws DataIntegrityException when both allowedCurrencies and baseCurrency are missing', () async {
        // Arrange
        const tripId = 'corrupt123';
        final tripData = {
          'name': 'Corrupt Trip',
          // No allowedCurrencies
          // No baseCurrency
          'createdAt': timestamp,
          'updatedAt': timestamp,
        };

        when(mockDocRef.get()).thenAnswer((_) async => mockDocSnapshot);
        when(mockDocSnapshot.exists).thenReturn(true);
        when(mockDocSnapshot.id).thenReturn(tripId);
        when(mockDocSnapshot.data()).thenReturn(tripData);

        // Act & Assert
        expect(
          () => repository.getAllowedCurrencies(tripId),
          throwsA(isA<DataIntegrityException>()),
        );
      });

      test('prefers allowedCurrencies over baseCurrency when both exist', () async {
        // Arrange
        const tripId = 'transition123';
        final tripData = {
          'name': 'Transition Trip',
          'allowedCurrencies': ['EUR', 'GBP'],
          'baseCurrency': 'USD', // Should be ignored
          'createdAt': timestamp,
          'updatedAt': timestamp,
        };

        when(mockDocRef.get()).thenAnswer((_) async => mockDocSnapshot);
        when(mockDocSnapshot.exists).thenReturn(true);
        when(mockDocSnapshot.id).thenReturn(tripId);
        when(mockDocSnapshot.data()).thenReturn(tripData);

        // Act
        final result = await repository.getAllowedCurrencies(tripId);

        // Assert
        expect(result, [CurrencyCode.eur, CurrencyCode.gbp]);
        expect(result, isNot(contains(CurrencyCode.usd)));
      });
    });

    group('updateAllowedCurrencies', () {
      test('updates Firestore with valid currencies', () async {
        // Arrange
        const tripId = 'trip123';
        final currencies = [CurrencyCode.jpy, CurrencyCode.krw];

        // Mock trip exists check
        when(mockDocRef.get()).thenAnswer((_) async => mockDocSnapshot);
        when(mockDocSnapshot.exists).thenReturn(true);

        // Mock update operation
        when(mockDocRef.update(any)).thenAnswer((_) async => {});

        // Act
        await repository.updateAllowedCurrencies(tripId, currencies);

        // Assert
        final captured = verify(mockDocRef.update(captureAny)).captured.single;
        final capturedMap = Map<String, dynamic>.from(captured as Map);

        expect(capturedMap['allowedCurrencies'], ['JPY', 'KRW']);
        expect(capturedMap['updatedAt'], isA<DateTime>());
      });

      test('throws ArgumentError when currency list is empty', () async {
        // Arrange
        const tripId = 'trip123';
        final currencies = <CurrencyCode>[];

        // Act & Assert
        expect(
          () => repository.updateAllowedCurrencies(tripId, currencies),
          throwsArgumentError,
        );

        // Should not call Firestore
        verifyNever(mockDocRef.update(any));
      });

      test('throws ArgumentError when more than 10 currencies', () async {
        // Arrange
        const tripId = 'trip123';
        final currencies = [
          CurrencyCode.usd,
          CurrencyCode.eur,
          CurrencyCode.gbp,
          CurrencyCode.jpy,
          CurrencyCode.aud,
          CurrencyCode.cad,
          CurrencyCode.chf,
          CurrencyCode.cny,
          CurrencyCode.sek,
          CurrencyCode.nzd,
          CurrencyCode.vnd, // 11th currency
        ];

        // Act & Assert
        expect(
          () => repository.updateAllowedCurrencies(tripId, currencies),
          throwsArgumentError,
        );

        // Should not call Firestore
        verifyNever(mockDocRef.update(any));
      });

      test('throws ArgumentError when duplicate currencies provided', () async {
        // Arrange
        const tripId = 'trip123';
        final currencies = [
          CurrencyCode.usd,
          CurrencyCode.eur,
          CurrencyCode.usd, // Duplicate
        ];

        // Act & Assert
        expect(
          () => repository.updateAllowedCurrencies(tripId, currencies),
          throwsArgumentError,
        );

        // Should not call Firestore
        verifyNever(mockDocRef.update(any));
      });

      test('throws TripNotFoundException when trip does not exist', () async {
        // Arrange
        const tripId = 'nonexistent';
        final currencies = [CurrencyCode.usd];

        // Mock trip does not exist
        when(mockDocRef.get()).thenAnswer((_) async => mockDocSnapshot);
        when(mockDocSnapshot.exists).thenReturn(false);

        // Act & Assert
        expect(
          () => repository.updateAllowedCurrencies(tripId, currencies),
          throwsA(isA<TripNotFoundException>()),
        );

        // Should not call update
        verifyNever(mockDocRef.update(any));
      });

      test('accepts exactly 1 currency (minimum valid)', () async {
        // Arrange
        const tripId = 'trip123';
        final currencies = [CurrencyCode.usd];

        // Mock trip exists
        when(mockDocRef.get()).thenAnswer((_) async => mockDocSnapshot);
        when(mockDocSnapshot.exists).thenReturn(true);
        when(mockDocRef.update(any)).thenAnswer((_) async => {});

        // Act
        await repository.updateAllowedCurrencies(tripId, currencies);

        // Assert
        final captured = verify(mockDocRef.update(captureAny)).captured.single;
        final capturedMap = Map<String, dynamic>.from(captured as Map);

        expect(capturedMap['allowedCurrencies'], ['USD']);
      });

      test('accepts exactly 10 currencies (maximum valid)', () async {
        // Arrange
        const tripId = 'trip123';
        final currencies = [
          CurrencyCode.usd,
          CurrencyCode.eur,
          CurrencyCode.gbp,
          CurrencyCode.jpy,
          CurrencyCode.aud,
          CurrencyCode.cad,
          CurrencyCode.chf,
          CurrencyCode.cny,
          CurrencyCode.sek,
          CurrencyCode.nzd,
        ];

        // Mock trip exists
        when(mockDocRef.get()).thenAnswer((_) async => mockDocSnapshot);
        when(mockDocSnapshot.exists).thenReturn(true);
        when(mockDocRef.update(any)).thenAnswer((_) async => {});

        // Act
        await repository.updateAllowedCurrencies(tripId, currencies);

        // Assert
        final captured = verify(mockDocRef.update(captureAny)).captured.single;
        final capturedMap = Map<String, dynamic>.from(captured as Map);

        expect(capturedMap['allowedCurrencies'], hasLength(10));
        expect(capturedMap['allowedCurrencies'], contains('USD'));
        expect(capturedMap['allowedCurrencies'], contains('NZD'));
      });

      test('updates trip timestamp when currencies are updated', () async {
        // Arrange
        const tripId = 'trip123';
        final currencies = [CurrencyCode.eur, CurrencyCode.usd];
        final beforeUpdate = DateTime.now();

        // Mock trip exists
        when(mockDocRef.get()).thenAnswer((_) async => mockDocSnapshot);
        when(mockDocSnapshot.exists).thenReturn(true);
        when(mockDocRef.update(any)).thenAnswer((_) async => {});

        // Act
        await repository.updateAllowedCurrencies(tripId, currencies);

        // Assert
        final captured = verify(mockDocRef.update(captureAny)).captured.single;
        final capturedMap = Map<String, dynamic>.from(captured as Map);

        final updatedAt = capturedMap['updatedAt'] as DateTime;
        expect(updatedAt.isAfter(beforeUpdate) || updatedAt.isAtSameMomentAs(beforeUpdate), true);
      });
    });
  });
}
