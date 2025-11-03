import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_tracker/features/categories/data/repositories/category_customization_repository_impl.dart';
import 'package:expense_tracker/core/models/category_customization.dart';
import 'package:expense_tracker/shared/services/firestore_service.dart';

@GenerateMocks(
  [FirestoreService],
  customMocks: [
    MockSpec<CollectionReference<Map<String, dynamic>>>(as: #MockCollectionRef),
    MockSpec<DocumentReference<Map<String, dynamic>>>(as: #MockDocumentRef),
    MockSpec<QuerySnapshot<Map<String, dynamic>>>(as: #MockQuerySnapshot),
    MockSpec<QueryDocumentSnapshot<Map<String, dynamic>>>(
      as: #MockQueryDocSnapshot,
    ),
    MockSpec<DocumentSnapshot<Map<String, dynamic>>>(as: #MockDocSnapshot),
  ],
)
import 'category_customization_repository_test.mocks.dart';

void main() {
  group('CategoryCustomizationRepositoryImpl', () {
    late CategoryCustomizationRepositoryImpl repository;
    late MockFirestoreService mockFirestoreService;
    late MockCollectionRef mockTripsCollection;
    late MockDocumentRef mockTripDocRef;
    late MockCollectionRef mockCustomizationsCollection;
    late MockDocumentRef mockCustomizationDocRef;
    late MockQuerySnapshot mockQuerySnapshot;
    late MockDocSnapshot mockDocSnapshot;

    final now = DateTime(2025, 10, 31, 12, 0, 0);
    const testTripId = 'trip-123';
    const testCategoryId = 'cat-456';

    setUp(() {
      mockFirestoreService = MockFirestoreService();
      mockTripsCollection = MockCollectionRef();
      mockTripDocRef = MockDocumentRef();
      mockCustomizationsCollection = MockCollectionRef();
      mockCustomizationDocRef = MockDocumentRef();
      mockQuerySnapshot = MockQuerySnapshot();
      mockDocSnapshot = MockDocSnapshot();

      // Setup default mocking chain for subcollection access
      when(mockFirestoreService.trips).thenReturn(mockTripsCollection);
      when(mockTripsCollection.doc(testTripId)).thenReturn(mockTripDocRef);
      when(
        mockTripDocRef.collection('categoryCustomizations'),
      ).thenReturn(mockCustomizationsCollection);

      repository = CategoryCustomizationRepositoryImpl(
        firestoreService: mockFirestoreService,
      );
    });

    group('getCustomizationsForTrip', () {
      test('should return stream of customizations for a trip', () async {
        // Arrange
        final mockDocs = [
          _createMockDoc('cat-1', {
            'tripId': testTripId,
            'customIcon': 'fastfood',
            'customColor': '#FF5722',
            'updatedAt': Timestamp.fromDate(now),
          }),
          _createMockDoc('cat-2', {
            'tripId': testTripId,
            'customIcon': 'directions_car',
            'updatedAt': Timestamp.fromDate(now),
          }),
        ];

        when(
          mockCustomizationsCollection.snapshots(),
        ).thenAnswer((_) => Stream.value(mockQuerySnapshot));
        when(mockQuerySnapshot.docs).thenReturn(mockDocs);

        // Act
        final stream = repository.getCustomizationsForTrip(testTripId);
        final result = await stream.first;

        // Assert
        expect(result, hasLength(2));
        expect(result[0].categoryId, 'cat-1');
        expect(result[0].tripId, testTripId);
        expect(result[0].customIcon, 'fastfood');
        expect(result[0].customColor, '#FF5722');
        expect(result[1].categoryId, 'cat-2');
        expect(result[1].tripId, testTripId);
        expect(result[1].customIcon, 'directions_car');
        expect(result[1].customColor, isNull);

        verify(mockTripsCollection.doc(testTripId)).called(1);
        verify(mockTripDocRef.collection('categoryCustomizations')).called(1);
        verify(mockCustomizationsCollection.snapshots()).called(1);
      });

      test('should handle empty customizations', () async {
        // Arrange
        when(
          mockCustomizationsCollection.snapshots(),
        ).thenAnswer((_) => Stream.value(mockQuerySnapshot));
        when(mockQuerySnapshot.docs).thenReturn([]);

        // Act
        final stream = repository.getCustomizationsForTrip(testTripId);
        final result = await stream.first;

        // Assert
        expect(result, isEmpty);
      });

      test('should emit updates when customizations change', () async {
        // Arrange
        final mockDocs1 = [
          _createMockDoc('cat-1', {
            'tripId': testTripId,
            'customIcon': 'fastfood',
            'updatedAt': Timestamp.fromDate(now),
          }),
        ];

        final mockDocs2 = [
          _createMockDoc('cat-1', {
            'tripId': testTripId,
            'customIcon': 'restaurant',
            'updatedAt': Timestamp.fromDate(now),
          }),
          _createMockDoc('cat-2', {
            'tripId': testTripId,
            'customColor': '#2196F3',
            'updatedAt': Timestamp.fromDate(now),
          }),
        ];

        final mockSnapshot1 = MockQuerySnapshot();
        final mockSnapshot2 = MockQuerySnapshot();
        when(mockSnapshot1.docs).thenReturn(mockDocs1);
        when(mockSnapshot2.docs).thenReturn(mockDocs2);

        when(mockCustomizationsCollection.snapshots()).thenAnswer(
          (_) => Stream.fromIterable([mockSnapshot1, mockSnapshot2]),
        );

        // Act
        final stream = repository.getCustomizationsForTrip(testTripId);
        final results = await stream.take(2).toList();

        // Assert
        expect(results, hasLength(2));
        expect(results[0], hasLength(1));
        expect(results[0][0].customIcon, 'fastfood');
        expect(results[1], hasLength(2));
        expect(results[1][0].customIcon, 'restaurant');
        expect(results[1][1].customColor, '#2196F3');
      });
    });

    group('getCustomization', () {
      test('should return customization when it exists', () async {
        // Arrange
        final customizationData = {
          'tripId': testTripId,
          'customIcon': 'fastfood',
          'customColor': '#FF5722',
          'updatedAt': Timestamp.fromDate(now),
        };

        when(
          mockCustomizationsCollection.doc(testCategoryId),
        ).thenReturn(mockCustomizationDocRef);
        when(
          mockCustomizationDocRef.get(),
        ).thenAnswer((_) async => mockDocSnapshot);
        when(mockDocSnapshot.exists).thenReturn(true);
        when(mockDocSnapshot.id).thenReturn(testCategoryId);
        when(mockDocSnapshot.data()).thenReturn(customizationData);

        // Act
        final result = await repository.getCustomization(
          testTripId,
          testCategoryId,
        );

        // Assert
        expect(result, isNotNull);
        expect(result!.categoryId, testCategoryId);
        expect(result.tripId, testTripId);
        expect(result.customIcon, 'fastfood');
        expect(result.customColor, '#FF5722');

        verify(mockTripsCollection.doc(testTripId)).called(1);
        verify(mockTripDocRef.collection('categoryCustomizations')).called(1);
        verify(mockCustomizationsCollection.doc(testCategoryId)).called(1);
      });

      test('should return null when customization does not exist', () async {
        // Arrange
        when(
          mockCustomizationsCollection.doc(testCategoryId),
        ).thenReturn(mockCustomizationDocRef);
        when(
          mockCustomizationDocRef.get(),
        ).thenAnswer((_) async => mockDocSnapshot);
        when(mockDocSnapshot.exists).thenReturn(false);

        // Act
        final result = await repository.getCustomization(
          testTripId,
          testCategoryId,
        );

        // Assert
        expect(result, isNull);
      });

      test('should handle icon-only customization', () async {
        // Arrange
        final customizationData = {
          'tripId': testTripId,
          'customIcon': 'fastfood',
          'updatedAt': Timestamp.fromDate(now),
        };

        when(
          mockCustomizationsCollection.doc(testCategoryId),
        ).thenReturn(mockCustomizationDocRef);
        when(
          mockCustomizationDocRef.get(),
        ).thenAnswer((_) async => mockDocSnapshot);
        when(mockDocSnapshot.exists).thenReturn(true);
        when(mockDocSnapshot.id).thenReturn(testCategoryId);
        when(mockDocSnapshot.data()).thenReturn(customizationData);

        // Act
        final result = await repository.getCustomization(
          testTripId,
          testCategoryId,
        );

        // Assert
        expect(result, isNotNull);
        expect(result!.customIcon, 'fastfood');
        expect(result.customColor, isNull);
      });

      test('should handle color-only customization', () async {
        // Arrange
        final customizationData = {
          'tripId': testTripId,
          'customColor': '#2196F3',
          'updatedAt': Timestamp.fromDate(now),
        };

        when(
          mockCustomizationsCollection.doc(testCategoryId),
        ).thenReturn(mockCustomizationDocRef);
        when(
          mockCustomizationDocRef.get(),
        ).thenAnswer((_) async => mockDocSnapshot);
        when(mockDocSnapshot.exists).thenReturn(true);
        when(mockDocSnapshot.id).thenReturn(testCategoryId);
        when(mockDocSnapshot.data()).thenReturn(customizationData);

        // Act
        final result = await repository.getCustomization(
          testTripId,
          testCategoryId,
        );

        // Assert
        expect(result, isNotNull);
        expect(result!.customIcon, isNull);
        expect(result.customColor, '#2196F3');
      });
    });

    group('saveCustomization', () {
      test('should save icon and color customization', () async {
        // Arrange
        final customization = CategoryCustomization(
          categoryId: testCategoryId,
          tripId: testTripId,
          customIcon: 'fastfood',
          customColor: '#FF5722',
          updatedAt: now,
        );

        when(
          mockCustomizationsCollection.doc(testCategoryId),
        ).thenReturn(mockCustomizationDocRef);
        when(
          mockCustomizationDocRef.set(any),
        ).thenAnswer((_) async => Future.value());

        // Act
        await repository.saveCustomization(customization);

        // Assert
        verify(mockTripsCollection.doc(testTripId)).called(1);
        verify(mockTripDocRef.collection('categoryCustomizations')).called(1);
        verify(mockCustomizationsCollection.doc(testCategoryId)).called(1);

        final captured =
            verify(mockCustomizationDocRef.set(captureAny)).captured.single
                as Map<String, dynamic>;
        expect(captured['tripId'], testTripId);
        expect(captured['customIcon'], 'fastfood');
        expect(captured['customColor'], '#FF5722');
        expect(captured['updatedAt'], isA<Timestamp>());
      });

      test('should save icon-only customization', () async {
        // Arrange
        final customization = CategoryCustomization(
          categoryId: testCategoryId,
          tripId: testTripId,
          customIcon: 'restaurant',
          updatedAt: now,
        );

        when(
          mockCustomizationsCollection.doc(testCategoryId),
        ).thenReturn(mockCustomizationDocRef);
        when(
          mockCustomizationDocRef.set(any),
        ).thenAnswer((_) async => Future.value());

        // Act
        await repository.saveCustomization(customization);

        // Assert
        final captured =
            verify(mockCustomizationDocRef.set(captureAny)).captured.single
                as Map<String, dynamic>;
        expect(captured['customIcon'], 'restaurant');
        expect(captured.containsKey('customColor'), isFalse);
      });

      test('should save color-only customization', () async {
        // Arrange
        final customization = CategoryCustomization(
          categoryId: testCategoryId,
          tripId: testTripId,
          customColor: '#2196F3',
          updatedAt: now,
        );

        when(
          mockCustomizationsCollection.doc(testCategoryId),
        ).thenReturn(mockCustomizationDocRef);
        when(
          mockCustomizationDocRef.set(any),
        ).thenAnswer((_) async => Future.value());

        // Act
        await repository.saveCustomization(customization);

        // Assert
        final captured =
            verify(mockCustomizationDocRef.set(captureAny)).captured.single
                as Map<String, dynamic>;
        expect(captured.containsKey('customIcon'), isFalse);
        expect(captured['customColor'], '#2196F3');
      });
    });

    group('deleteCustomization', () {
      test('should delete customization document', () async {
        // Arrange
        when(
          mockCustomizationsCollection.doc(testCategoryId),
        ).thenReturn(mockCustomizationDocRef);
        when(
          mockCustomizationDocRef.delete(),
        ).thenAnswer((_) async => Future.value());

        // Act
        await repository.deleteCustomization(testTripId, testCategoryId);

        // Assert
        verify(mockTripsCollection.doc(testTripId)).called(1);
        verify(mockTripDocRef.collection('categoryCustomizations')).called(1);
        verify(mockCustomizationsCollection.doc(testCategoryId)).called(1);
        verify(mockCustomizationDocRef.delete()).called(1);
      });

      test(
        'should not fail when deleting non-existent customization',
        () async {
          // Arrange
          when(
            mockCustomizationsCollection.doc(testCategoryId),
          ).thenReturn(mockCustomizationDocRef);
          when(
            mockCustomizationDocRef.delete(),
          ).thenAnswer((_) async => Future.value());

          // Act & Assert (should not throw)
          await repository.deleteCustomization(testTripId, testCategoryId);

          verify(mockCustomizationDocRef.delete()).called(1);
        },
      );
    });
  });
}

/// Helper function to create mock document snapshots
MockQueryDocSnapshot _createMockDoc(String id, Map<String, dynamic> data) {
  final mockDoc = MockQueryDocSnapshot();
  when(mockDoc.id).thenReturn(id);
  when(mockDoc.data()).thenReturn(data);
  return mockDoc;
}
