import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_tracker/features/device_pairing/data/repositories/firestore_device_link_code_repository.dart';

@GenerateMocks([
  FirebaseFirestore,
  DocumentSnapshot,
  WriteBatch,
], customMocks: [
  MockSpec<CollectionReference<Map<String, dynamic>>>(as: #MockCollectionRef),
  MockSpec<DocumentReference<Map<String, dynamic>>>(as: #MockDocumentRef),
  MockSpec<Query<Map<String, dynamic>>>(as: #MockQuery),
  MockSpec<QuerySnapshot<Map<String, dynamic>>>(as: #MockQuerySnapshot),
  MockSpec<QueryDocumentSnapshot<Map<String, dynamic>>>(as: #MockQueryDocSnapshot),
])
import 'firestore_device_link_code_repository_test.mocks.dart';

/// T025: Unit tests for FirestoreDeviceLinkCodeRepository.generateCode()
///
/// Tests code generation with:
/// - Secure 8-digit code generation
/// - Firestore document creation
/// - 15-minute expiry
/// - memberNameLower field for case-insensitive matching
/// - Invalidation of previous codes for same member
void main() {
  group('T025: FirestoreDeviceLinkCodeRepository.generateCode() -', () {
    late FirestoreDeviceLinkCodeRepository repository;
    late MockFirebaseFirestore mockFirestore;
    late MockCollectionRef mockTripsCollection;
    late MockDocumentRef mockTripDoc;
    late MockCollectionRef mockCodesCollection;
    late MockDocumentRef mockCodeDoc;
    late MockQuery mockQuery;
    late MockQuerySnapshot mockQuerySnapshot;

    setUp(() {
      mockFirestore = MockFirebaseFirestore();
      mockTripsCollection = MockCollectionRef();
      mockTripDoc = MockDocumentRef();
      mockCodesCollection = MockCollectionRef();
      mockCodeDoc = MockDocumentRef();
      mockQuery = MockQuery();
      mockQuerySnapshot = MockQuerySnapshot();

      // Provide dummy values for sealed/generic types
      provideDummy<QuerySnapshot<Map<String, dynamic>>>(mockQuerySnapshot);

      // Setup default Firestore mocking chain
      when(mockFirestore.collection('trips')).thenReturn(mockTripsCollection);
      when(mockTripsCollection.doc(any)).thenReturn(mockTripDoc);
      when(mockTripDoc.collection('deviceLinkCodes')).thenReturn(mockCodesCollection);
      when(mockCodesCollection.add(any)).thenAnswer((_) async => mockCodeDoc);
      when(mockCodeDoc.id).thenReturn('generated-code-id-123');

      // Mock query for finding previous codes
      when(mockCodesCollection.where('memberNameLower', isEqualTo: anyNamed('isEqualTo')))
          .thenReturn(mockQuery);
      when(mockQuery.where('used', isEqualTo: anyNamed('isEqualTo')))
          .thenReturn(mockQuery);
      when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);
      when(mockQuerySnapshot.docs).thenReturn([]);

      repository = FirestoreDeviceLinkCodeRepository(firestore: mockFirestore);
    });

    test('should generate 8-digit code with correct format', () async {
      // Act
      final result = await repository.generateCode('trip-123', 'Alice');

      // Assert
      expect(result.code, matches(r'^\d{4}-\d{4}$'),
          reason: 'Code should be formatted as XXXX-XXXX');
      expect(result.code.replaceAll('-', '').length, equals(8),
          reason: 'Code should have exactly 8 digits');
    });

    test('should create code with memberName and memberNameLower', () async {
      // Arrange
      const tripId = 'trip-123';
      const memberName = 'Alice';

      // Act
      await repository.generateCode(tripId, memberName);

      // Assert - Verify Firestore add was called with correct data
      final captured = verify(mockCodesCollection.add(captureAny)).captured.single
          as Map<String, dynamic>;

      expect(captured['memberName'], equals('Alice'));
      expect(captured['memberNameLower'], equals('alice'),
          reason: 'Should store lowercase version for case-insensitive matching');
    });

    test('should set expiry to 15 minutes from now', () async {
      // Arrange
      final beforeGeneration = DateTime.now();

      // Act
      final result = await repository.generateCode('trip-123', 'Alice');

      // Assert
      final afterGeneration = DateTime.now();
      final expectedExpiry = beforeGeneration.add(const Duration(minutes: 15));

      expect(result.expiresAt.isAfter(beforeGeneration),
          isTrue, reason: 'Expiry should be after generation start');
      expect(result.expiresAt.isBefore(afterGeneration.add(const Duration(minutes: 15, seconds: 1))),
          isTrue, reason: 'Expiry should be approximately 15 minutes from now');

      // Allow 1 second tolerance for test execution time
      final diff = result.expiresAt.difference(expectedExpiry).abs();
      expect(diff.inSeconds, lessThan(2),
          reason: 'Expiry should be within 2 seconds of expected 15-minute mark');
    });

    test('should set used=false and usedAt=null for new code', () async {
      // Act
      final result = await repository.generateCode('trip-123', 'Alice');

      // Assert
      expect(result.used, isFalse, reason: 'New code should not be marked as used');
      expect(result.usedAt, isNull, reason: 'New code should have no usedAt timestamp');
    });

    test('should store correct tripId and return entity with generated ID', () async {
      // Arrange
      const tripId = 'trip-tokyo-456';

      // Act
      final result = await repository.generateCode(tripId, 'Bob');

      // Assert
      expect(result.tripId, equals(tripId), reason: 'Code should reference correct trip');
      expect(result.id, equals('generated-code-id-123'),
          reason: 'Should use Firestore-generated document ID');
    });

    test('should query for previous codes with same memberNameLower', () async {
      // Arrange
      const memberName = 'Charlie';

      // Act
      await repository.generateCode('trip-123', memberName);

      // Assert - Verify query was constructed correctly
      verify(mockCodesCollection.where('memberNameLower', isEqualTo: 'charlie')).called(1);
      verify(mockQuery.where('used', isEqualTo: false)).called(1);
    });

    test('should invalidate previous unused codes for same member', () async {
      // Arrange
      const memberName = 'Alice';

      // Mock existing unused codes
      final mockPreviousCode1 = MockQueryDocSnapshot();
      final mockPreviousCode2 = MockQueryDocSnapshot();
      final mockPreviousRef1 = MockDocumentRef();
      final mockPreviousRef2 = MockDocumentRef();

      when(mockPreviousCode1.reference).thenReturn(mockPreviousRef1);
      when(mockPreviousCode2.reference).thenReturn(mockPreviousRef2);
      when(mockPreviousRef1.update(any)).thenAnswer((_) async {});
      when(mockPreviousRef2.update(any)).thenAnswer((_) async {});

      when(mockQuerySnapshot.docs).thenReturn([mockPreviousCode1, mockPreviousCode2]);

      // Act
      await repository.generateCode('trip-123', memberName);

      // Assert - Verify both previous codes were marked as used
      final captured1 = verify(mockPreviousRef1.update(captureAny)).captured.single as Map;
      final captured2 = verify(mockPreviousRef2.update(captureAny)).captured.single as Map;

      expect(captured1['used'], isTrue);
      expect(captured1['usedAt'], isNotNull);
      expect(captured2['used'], isTrue);
      expect(captured2['usedAt'], isNotNull);
    });

    test('should handle case-insensitive member name in invalidation', () async {
      // Arrange - Mix of cases
      final testCases = ['Alice', 'ALICE', 'aLiCe'];

      for (final name in testCases) {
        // Act
        await repository.generateCode('trip-123', name);
      }

      // Assert - All should query for 'alice' (lowercase) - called 3 times total
      verify(mockCodesCollection.where('memberNameLower', isEqualTo: 'alice')).called(3);
    });

    test('should generate different codes on successive calls', () async {
      // Act
      final code1 = await repository.generateCode('trip-123', 'Alice');
      final code2 = await repository.generateCode('trip-123', 'Alice');
      final code3 = await repository.generateCode('trip-123', 'Alice');

      // Assert
      expect(code1.code, isNot(equals(code2.code)),
          reason: 'Should generate unique codes');
      expect(code2.code, isNot(equals(code3.code)),
          reason: 'Should generate unique codes');
      expect(code1.code, isNot(equals(code3.code)),
          reason: 'Should generate unique codes');
    });

    test('should include all required fields in Firestore document', () async {
      // Act
      await repository.generateCode('trip-123', 'TestUser');

      // Assert
      final captured = verify(mockCodesCollection.add(captureAny)).captured.single
          as Map<String, dynamic>;

      expect(captured, containsPair('code', anything));
      expect(captured, containsPair('tripId', 'trip-123'));
      expect(captured, containsPair('memberName', 'TestUser'));
      expect(captured, containsPair('memberNameLower', 'testuser'));
      expect(captured, containsPair('createdAt', anything));
      expect(captured, containsPair('expiresAt', anything));
      expect(captured, containsPair('used', false));
      expect(captured, containsPair('usedAt', null));
    });

    test('should handle member names with special characters', () async {
      // Arrange
      const specialNames = ["O'Brien", "José", "Mary-Jane", "李明"];

      for (final name in specialNames) {
        // Act
        final result = await repository.generateCode('trip-123', name);

        // Assert
        expect(result.memberName, equals(name),
            reason: 'Should preserve original name with special characters');

        // Verify query used lowercase version
        verify(mockCodesCollection.where('memberNameLower', isEqualTo: name.toLowerCase()));
      }
    });
  });

  group('T036: FirestoreDeviceLinkCodeRepository.validateCode() -', () {
    late FirestoreDeviceLinkCodeRepository repository;
    late MockFirebaseFirestore mockFirestore;
    late MockCollectionRef mockTripsCollection;
    late MockDocumentRef mockTripDoc;
    late MockCollectionRef mockCodesCollection;
    late MockQuery mockQuery;
    late MockQuerySnapshot mockQuerySnapshot;

    setUp(() {
      mockFirestore = MockFirebaseFirestore();
      mockTripsCollection = MockCollectionRef();
      mockTripDoc = MockDocumentRef();
      mockCodesCollection = MockCollectionRef();
      mockQuery = MockQuery();
      mockQuerySnapshot = MockQuerySnapshot();

      // Provide dummy values
      provideDummy<QuerySnapshot<Map<String, dynamic>>>(mockQuerySnapshot);

      // Setup Firestore hierarchy
      when(mockFirestore.collection('trips')).thenReturn(mockTripsCollection);
      when(mockTripsCollection.doc(any)).thenReturn(mockTripDoc);
      when(mockTripDoc.collection('deviceLinkCodes')).thenReturn(mockCodesCollection);

      repository = FirestoreDeviceLinkCodeRepository(firestore: mockFirestore);
    });

    group('Validation Rule 1: Code exists -', () {
      test('should throw exception when code does not exist', () async {
        // Arrange - Empty query result (code not found)
        when(mockCodesCollection.where(any, isEqualTo: any)).thenReturn(mockQuery);
        when(mockQuery.where(any, isEqualTo: any)).thenReturn(mockQuery);
        when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);
        when(mockQuerySnapshot.docs).thenReturn([]);

        // Act & Assert
        expect(
          () => repository.validateCode('trip-123', '1234-5678', 'Alice'),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Invalid code'),
          )),
        );
      });

      test('should succeed when valid code exists', () async {
        // Arrange - Valid code found
        final mockCodeDoc = MockQueryDocSnapshot();
        final mockCodeDocRef = MockDocumentRef();
        final now = DateTime.now();
        final codeData = {
          'code': '1234-5678',
          'tripId': 'trip-123',
          'memberName': 'Alice',
          'memberNameLower': 'alice',
          'createdAt': Timestamp.fromDate(now),
          'expiresAt': Timestamp.fromDate(now.add(const Duration(minutes: 15))),
          'used': false,
          'usedAt': null,
        };

        when(mockCodeDoc.data()).thenReturn(codeData);
        when(mockCodeDoc.id).thenReturn('code-id-123');
        when(mockCodeDoc.reference).thenReturn(mockCodeDocRef);

        when(mockCodesCollection.where('code', isEqualTo: '1234-5678')).thenReturn(mockQuery);
        when(mockQuery.where('tripId', isEqualTo: 'trip-123')).thenReturn(mockQuery);
        when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);
        when(mockQuerySnapshot.docs).thenReturn([mockCodeDoc]);

        // Mock transaction for marking as used
        when(mockCodeDocRef.update(any)).thenAnswer((_) async {});

        // Act
        final result = await repository.validateCode('trip-123', '1234-5678', 'Alice');

        // Assert
        expect(result.code, equals('1234-5678'));
        expect(result.memberName, equals('Alice'));
      });
    });

    group('Validation Rule 2: Not expired -', () {
      test('should throw exception when code is expired', () async {
        // Arrange - Expired code
        final mockCodeDoc = MockQueryDocSnapshot();
        final now = DateTime.now();
        final expiredCodeData = {
          'code': '1234-5678',
          'tripId': 'trip-123',
          'memberName': 'Alice',
          'memberNameLower': 'alice',
          'createdAt': Timestamp.fromDate(now.subtract(const Duration(minutes: 20))),
          'expiresAt': Timestamp.fromDate(now.subtract(const Duration(minutes: 5))), // Expired
          'used': false,
          'usedAt': null,
        };

        when(mockCodeDoc.data()).thenReturn(expiredCodeData);
        when(mockCodeDoc.id).thenReturn('code-id-123');

        when(mockCodesCollection.where('code', isEqualTo: '1234-5678')).thenReturn(mockQuery);
        when(mockQuery.where('tripId', isEqualTo: 'trip-123')).thenReturn(mockQuery);
        when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);
        when(mockQuerySnapshot.docs).thenReturn([mockCodeDoc]);

        // Act & Assert
        expect(
          () => repository.validateCode('trip-123', '1234-5678', 'Alice'),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('expired'),
          )),
        );
      });

      test('should succeed when code is not expired', () async {
        // Arrange - Valid unexpired code
        final mockCodeDoc = MockQueryDocSnapshot();
        final mockDocRef = MockDocumentRef();
        final now = DateTime.now();
        final validCodeData = {
          'code': '1234-5678',
          'tripId': 'trip-123',
          'memberName': 'Alice',
          'memberNameLower': 'alice',
          'createdAt': Timestamp.fromDate(now),
          'expiresAt': Timestamp.fromDate(now.add(const Duration(minutes: 10))), // Still valid
          'used': false,
          'usedAt': null,
        };

        when(mockCodeDoc.data()).thenReturn(validCodeData);
        when(mockCodeDoc.id).thenReturn('code-id-123');
        when(mockCodeDoc.reference).thenReturn(mockDocRef);

        when(mockCodesCollection.where('code', isEqualTo: '1234-5678')).thenReturn(mockQuery);
        when(mockQuery.where('tripId', isEqualTo: 'trip-123')).thenReturn(mockQuery);
        when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);
        when(mockQuerySnapshot.docs).thenReturn([mockCodeDoc]);

        when(mockDocRef.update(any)).thenAnswer((_) async {});

        // Act
        final result = await repository.validateCode('trip-123', '1234-5678', 'Alice');

        // Assert
        expect(result.code, equals('1234-5678'));
      });
    });

    group('Validation Rule 3: Not used -', () {
      test('should throw exception when code is already used', () async {
        // Arrange - Already used code
        final mockCodeDoc = MockQueryDocSnapshot();
        final now = DateTime.now();
        final usedCodeData = {
          'code': '1234-5678',
          'tripId': 'trip-123',
          'memberName': 'Alice',
          'memberNameLower': 'alice',
          'createdAt': Timestamp.fromDate(now),
          'expiresAt': Timestamp.fromDate(now.add(const Duration(minutes: 10))),
          'used': true, // Already used
          'usedAt': Timestamp.fromDate(now.subtract(const Duration(minutes: 5))),
        };

        when(mockCodeDoc.data()).thenReturn(usedCodeData);
        when(mockCodeDoc.id).thenReturn('code-id-123');

        when(mockCodesCollection.where('code', isEqualTo: '1234-5678')).thenReturn(mockQuery);
        when(mockQuery.where('tripId', isEqualTo: 'trip-123')).thenReturn(mockQuery);
        when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);
        when(mockQuerySnapshot.docs).thenReturn([mockCodeDoc]);

        // Act & Assert
        expect(
          () => repository.validateCode('trip-123', '1234-5678', 'Alice'),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('already been used'),
          )),
        );
      });

      test('should succeed when code is not used', () async {
        // Arrange - Unused code
        final mockCodeDoc = MockQueryDocSnapshot();
        final mockDocRef = MockDocumentRef();
        final now = DateTime.now();
        final unusedCodeData = {
          'code': '1234-5678',
          'tripId': 'trip-123',
          'memberName': 'Alice',
          'memberNameLower': 'alice',
          'createdAt': Timestamp.fromDate(now),
          'expiresAt': Timestamp.fromDate(now.add(const Duration(minutes: 10))),
          'used': false, // Not used
          'usedAt': null,
        };

        when(mockCodeDoc.data()).thenReturn(unusedCodeData);
        when(mockCodeDoc.id).thenReturn('code-id-123');
        when(mockCodeDoc.reference).thenReturn(mockDocRef);

        when(mockCodesCollection.where('code', isEqualTo: '1234-5678')).thenReturn(mockQuery);
        when(mockQuery.where('tripId', isEqualTo: 'trip-123')).thenReturn(mockQuery);
        when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);
        when(mockQuerySnapshot.docs).thenReturn([mockCodeDoc]);

        when(mockDocRef.update(any)).thenAnswer((_) async {});

        // Act & Assert - Should not throw
        await expectLater(
          repository.validateCode('trip-123', '1234-5678', 'Alice'),
          completes,
        );
      });
    });

    group('Validation Rule 4: Trip matches -', () {
      test('should throw exception when tripId does not match', () async {
        // Arrange - Query with tripId filter will return empty
        when(mockCodesCollection.where('code', isEqualTo: '1234-5678')).thenReturn(mockQuery);
        when(mockQuery.where('tripId', isEqualTo: 'trip-999')).thenReturn(mockQuery); // Wrong trip
        when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);
        when(mockQuerySnapshot.docs).thenReturn([]); // Not found because trip doesn't match

        // Act & Assert
        expect(
          () => repository.validateCode('trip-999', '1234-5678', 'Alice'),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Invalid code'),
          )),
        );
      });

      test('should verify tripId is used in query', () async {
        // Arrange
        final mockCodeDoc = MockQueryDocSnapshot();
        final mockDocRef = MockDocumentRef();
        final now = DateTime.now();
        final codeData = {
          'code': '1234-5678',
          'tripId': 'trip-correct',
          'memberName': 'Alice',
          'memberNameLower': 'alice',
          'createdAt': Timestamp.fromDate(now),
          'expiresAt': Timestamp.fromDate(now.add(const Duration(minutes: 10))),
          'used': false,
          'usedAt': null,
        };

        when(mockCodeDoc.data()).thenReturn(codeData);
        when(mockCodeDoc.id).thenReturn('code-id-123');
        when(mockCodeDoc.reference).thenReturn(mockDocRef);

        when(mockCodesCollection.where('code', isEqualTo: '1234-5678')).thenReturn(mockQuery);
        when(mockQuery.where('tripId', isEqualTo: 'trip-correct')).thenReturn(mockQuery);
        when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);
        when(mockQuerySnapshot.docs).thenReturn([mockCodeDoc]);

        when(mockDocRef.update(any)).thenAnswer((_) async {});

        // Act
        await repository.validateCode('trip-correct', '1234-5678', 'Alice');

        // Assert - Verify query included tripId filter
        verify(mockQuery.where('tripId', isEqualTo: 'trip-correct')).called(1);
      });
    });

    group('Validation Rule 5: Name matches (case-insensitive) -', () {
      test('should throw exception when member name does not match', () async {
        // Arrange - Code for Alice, but Bob is trying to use it
        final mockCodeDoc = MockQueryDocSnapshot();
        final now = DateTime.now();
        final codeData = {
          'code': '1234-5678',
          'tripId': 'trip-123',
          'memberName': 'Alice',
          'memberNameLower': 'alice',
          'createdAt': Timestamp.fromDate(now),
          'expiresAt': Timestamp.fromDate(now.add(const Duration(minutes: 10))),
          'used': false,
          'usedAt': null,
        };

        when(mockCodeDoc.data()).thenReturn(codeData);
        when(mockCodeDoc.id).thenReturn('code-id-123');

        when(mockCodesCollection.where('code', isEqualTo: '1234-5678')).thenReturn(mockQuery);
        when(mockQuery.where('tripId', isEqualTo: 'trip-123')).thenReturn(mockQuery);
        when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);
        when(mockQuerySnapshot.docs).thenReturn([mockCodeDoc]);

        // Act & Assert
        expect(
          () => repository.validateCode('trip-123', '1234-5678', 'Bob'), // Wrong name
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('does not match'),
          )),
        );
      });

      test('should succeed with exact case match', () async {
        // Arrange
        final mockCodeDoc = MockQueryDocSnapshot();
        final mockDocRef = MockDocumentRef();
        final now = DateTime.now();
        final codeData = {
          'code': '1234-5678',
          'tripId': 'trip-123',
          'memberName': 'Alice',
          'memberNameLower': 'alice',
          'createdAt': Timestamp.fromDate(now),
          'expiresAt': Timestamp.fromDate(now.add(const Duration(minutes: 10))),
          'used': false,
          'usedAt': null,
        };

        when(mockCodeDoc.data()).thenReturn(codeData);
        when(mockCodeDoc.id).thenReturn('code-id-123');
        when(mockCodeDoc.reference).thenReturn(mockDocRef);

        when(mockCodesCollection.where('code', isEqualTo: '1234-5678')).thenReturn(mockQuery);
        when(mockQuery.where('tripId', isEqualTo: 'trip-123')).thenReturn(mockQuery);
        when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);
        when(mockQuerySnapshot.docs).thenReturn([mockCodeDoc]);

        when(mockDocRef.update(any)).thenAnswer((_) async {});

        // Act
        final result = await repository.validateCode('trip-123', '1234-5678', 'Alice');

        // Assert
        expect(result.memberName, equals('Alice'));
      });

      test('should succeed with case-insensitive match', () async {
        // Arrange - Code for "Alice", trying with "ALICE"
        final mockCodeDoc = MockQueryDocSnapshot();
        final mockDocRef = MockDocumentRef();
        final now = DateTime.now();
        final codeData = {
          'code': '1234-5678',
          'tripId': 'trip-123',
          'memberName': 'Alice',
          'memberNameLower': 'alice',
          'createdAt': Timestamp.fromDate(now),
          'expiresAt': Timestamp.fromDate(now.add(const Duration(minutes: 10))),
          'used': false,
          'usedAt': null,
        };

        when(mockCodeDoc.data()).thenReturn(codeData);
        when(mockCodeDoc.id).thenReturn('code-id-123');
        when(mockCodeDoc.reference).thenReturn(mockDocRef);

        when(mockCodesCollection.where('code', isEqualTo: '1234-5678')).thenReturn(mockQuery);
        when(mockQuery.where('tripId', isEqualTo: 'trip-123')).thenReturn(mockQuery);
        when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);
        when(mockQuerySnapshot.docs).thenReturn([mockCodeDoc]);

        when(mockDocRef.update(any)).thenAnswer((_) async {});

        // Act
        final result = await repository.validateCode('trip-123', '1234-5678', 'ALICE'); // Different case

        // Assert
        expect(result.memberName, equals('Alice'));
      });
    });

    group('Validation Rule 6: Rate limiting (placeholder) -', () {
      test('should allow validation without rate limiting check for now', () async {
        // Arrange - Valid code
        final mockCodeDoc = MockQueryDocSnapshot();
        final mockDocRef = MockDocumentRef();
        final now = DateTime.now();
        final codeData = {
          'code': '1234-5678',
          'tripId': 'trip-123',
          'memberName': 'Alice',
          'memberNameLower': 'alice',
          'createdAt': Timestamp.fromDate(now),
          'expiresAt': Timestamp.fromDate(now.add(const Duration(minutes: 10))),
          'used': false,
          'usedAt': null,
        };

        when(mockCodeDoc.data()).thenReturn(codeData);
        when(mockCodeDoc.id).thenReturn('code-id-123');
        when(mockCodeDoc.reference).thenReturn(mockDocRef);

        when(mockCodesCollection.where('code', isEqualTo: '1234-5678')).thenReturn(mockQuery);
        when(mockQuery.where('tripId', isEqualTo: 'trip-123')).thenReturn(mockQuery);
        when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);
        when(mockQuerySnapshot.docs).thenReturn([mockCodeDoc]);

        when(mockDocRef.update(any)).thenAnswer((_) async {});

        // Act - Should succeed without rate limiting check
        final result = await repository.validateCode('trip-123', '1234-5678', 'Alice');

        // Assert
        expect(result, isNotNull);
        // Note: Rate limiting will be implemented in Phase 6 (User Story 4)
      });
    });

    group('Code normalization (T040) -', () {
      test('should accept code with hyphen (1234-5678)', () async {
        // Arrange
        final mockCodeDoc = MockQueryDocSnapshot();
        final mockDocRef = MockDocumentRef();
        final now = DateTime.now();
        final codeData = {
          'code': '1234-5678',
          'tripId': 'trip-123',
          'memberName': 'Alice',
          'memberNameLower': 'alice',
          'createdAt': Timestamp.fromDate(now),
          'expiresAt': Timestamp.fromDate(now.add(const Duration(minutes: 10))),
          'used': false,
          'usedAt': null,
        };

        when(mockCodeDoc.data()).thenReturn(codeData);
        when(mockCodeDoc.id).thenReturn('code-id-123');
        when(mockCodeDoc.reference).thenReturn(mockDocRef);

        when(mockCodesCollection.where('code', isEqualTo: '1234-5678')).thenReturn(mockQuery);
        when(mockQuery.where('tripId', isEqualTo: 'trip-123')).thenReturn(mockQuery);
        when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);
        when(mockQuerySnapshot.docs).thenReturn([mockCodeDoc]);

        when(mockDocRef.update(any)).thenAnswer((_) async {});

        // Act
        final result = await repository.validateCode('trip-123', '1234-5678', 'Alice');

        // Assert
        expect(result.code, equals('1234-5678'));
      });

      test('should accept code without hyphen (12345678) and normalize', () async {
        // Arrange - Code stored with hyphen
        final mockCodeDoc = MockQueryDocSnapshot();
        final mockDocRef = MockDocumentRef();
        final now = DateTime.now();
        final codeData = {
          'code': '1234-5678',
          'tripId': 'trip-123',
          'memberName': 'Alice',
          'memberNameLower': 'alice',
          'createdAt': Timestamp.fromDate(now),
          'expiresAt': Timestamp.fromDate(now.add(const Duration(minutes: 10))),
          'used': false,
          'usedAt': null,
        };

        when(mockCodeDoc.data()).thenReturn(codeData);
        when(mockCodeDoc.id).thenReturn('code-id-123');
        when(mockCodeDoc.reference).thenReturn(mockDocRef);

        // Repository should normalize input and query for '1234-5678'
        when(mockCodesCollection.where('code', isEqualTo: '1234-5678')).thenReturn(mockQuery);
        when(mockQuery.where('tripId', isEqualTo: 'trip-123')).thenReturn(mockQuery);
        when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);
        when(mockQuerySnapshot.docs).thenReturn([mockCodeDoc]);

        when(mockDocRef.update(any)).thenAnswer((_) async {});

        // Act - User enters code without hyphen
        final result = await repository.validateCode('trip-123', '12345678', 'Alice');

        // Assert
        expect(result.code, equals('1234-5678'));
        // Verify repository normalized the code before querying
        verify(mockCodesCollection.where('code', isEqualTo: '1234-5678')).called(1);
      });
    });
  });
}
