import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_tracker/features/categories/data/repositories/category_repository_impl.dart';
import 'package:expense_tracker/features/categories/data/services/rate_limiter_service.dart';
import 'package:expense_tracker/features/categories/domain/models/category.dart';
import 'package:expense_tracker/shared/services/firestore_service.dart';

@GenerateMocks(
  [FirestoreService, RateLimiterService],
  customMocks: [
    MockSpec<CollectionReference<Map<String, dynamic>>>(as: #MockCollectionRef),
    MockSpec<DocumentReference<Map<String, dynamic>>>(as: #MockDocumentRef),
    MockSpec<Query<Map<String, dynamic>>>(as: #MockQuery),
    MockSpec<QuerySnapshot<Map<String, dynamic>>>(as: #MockQuerySnapshot),
    MockSpec<QueryDocumentSnapshot<Map<String, dynamic>>>(
      as: #MockQueryDocSnapshot,
    ),
    MockSpec<DocumentSnapshot<Map<String, dynamic>>>(as: #MockDocSnapshot),
  ],
)
import 'category_repository_impl_test.mocks.dart';

void main() {
  group('CategoryRepositoryImpl', () {
    late CategoryRepositoryImpl repository;
    late MockFirestoreService mockFirestoreService;
    late MockRateLimiterService mockRateLimiterService;
    late MockCollectionRef mockCategoriesCollection;
    late MockQuery mockQuery;
    late MockQuerySnapshot mockQuerySnapshot;
    late MockDocumentRef mockDocRef;
    late MockDocSnapshot mockDocSnapshot;

    final now = DateTime(2025, 10, 31, 12, 0, 0);

    setUp(() {
      mockFirestoreService = MockFirestoreService();
      mockRateLimiterService = MockRateLimiterService();
      mockCategoriesCollection = MockCollectionRef();
      mockQuery = MockQuery();
      mockQuerySnapshot = MockQuerySnapshot();
      mockDocRef = MockDocumentRef();
      mockDocSnapshot = MockDocSnapshot();

      // Setup default mocking
      when(
        mockFirestoreService.categories,
      ).thenReturn(mockCategoriesCollection);

      repository = CategoryRepositoryImpl(
        firestoreService: mockFirestoreService,
        rateLimiterService: mockRateLimiterService,
      );
    });

    group('getTopCategories', () {
      test(
        'should return stream of top N categories ordered by usage',
        () async {
          // Arrange
          final category1 = Category(
            id: 'cat1',
            name: 'Meals',
            icon: 'restaurant',
            color: '#FF5722',
            usageCount: 100,
            createdAt: now,
            updatedAt: now,
          );

          final category2 = Category(
            id: 'cat2',
            name: 'Transport',
            icon: 'directions_car',
            color: '#2196F3',
            usageCount: 50,
            createdAt: now,
            updatedAt: now,
          );

          final mockDocs = [
            _createMockDoc('cat1', {
              'name': 'Meals',
              'nameLowercase': 'meals',
              'icon': 'restaurant',
              'color': '#FF5722',
              'usageCount': 100,
              'createdAt': Timestamp.fromDate(now),
              'updatedAt': Timestamp.fromDate(now),
            }),
            _createMockDoc('cat2', {
              'name': 'Transport',
              'nameLowercase': 'transport',
              'icon': 'directions_car',
              'color': '#2196F3',
              'usageCount': 50,
              'createdAt': Timestamp.fromDate(now),
              'updatedAt': Timestamp.fromDate(now),
            }),
          ];

          when(
            mockCategoriesCollection.orderBy('usageCount', descending: true),
          ).thenReturn(mockQuery);
          when(mockQuery.limit(5)).thenReturn(mockQuery);
          when(
            mockQuery.snapshots(),
          ).thenAnswer((_) => Stream.value(mockQuerySnapshot));
          when(mockQuerySnapshot.docs).thenReturn(mockDocs);

          // Act
          final stream = repository.getTopCategories(limit: 5);
          final result = await stream.first;

          // Assert
          expect(result, hasLength(2));
          expect(result[0].id, category1.id);
          expect(result[0].name, category1.name);
          expect(result[0].usageCount, category1.usageCount);
          expect(result[1].id, category2.id);
          expect(result[1].name, category2.name);
          expect(result[1].usageCount, category2.usageCount);

          verify(
            mockCategoriesCollection.orderBy('usageCount', descending: true),
          ).called(1);
          verify(mockQuery.limit(5)).called(1);
        },
      );

      test('should use default limit of 5 when not specified', () async {
        when(
          mockCategoriesCollection.orderBy('usageCount', descending: true),
        ).thenReturn(mockQuery);
        when(mockQuery.limit(any)).thenReturn(mockQuery);
        when(
          mockQuery.snapshots(),
        ).thenAnswer((_) => Stream.value(mockQuerySnapshot));
        when(mockQuerySnapshot.docs).thenReturn([]);

        // Act
        final stream = repository.getTopCategories();
        await stream.first;

        // Assert
        verify(mockQuery.limit(5)).called(1);
      });

      test('should handle empty result', () async {
        when(
          mockCategoriesCollection.orderBy('usageCount', descending: true),
        ).thenReturn(mockQuery);
        when(mockQuery.limit(any)).thenReturn(mockQuery);
        when(
          mockQuery.snapshots(),
        ).thenAnswer((_) => Stream.value(mockQuerySnapshot));
        when(mockQuerySnapshot.docs).thenReturn([]);

        // Act
        final stream = repository.getTopCategories();
        final result = await stream.first;

        // Assert
        expect(result, isEmpty);
      });
    });

    group('searchCategories', () {
      test(
        'should return all categories sorted by usage when query is empty',
        () async {
          final mockDocs = [
            _createMockDoc('cat1', {
              'name': 'Meals',
              'nameLowercase': 'meals',
              'icon': 'restaurant',
              'color': '#FF5722',
              'usageCount': 100,
              'createdAt': Timestamp.fromDate(now),
              'updatedAt': Timestamp.fromDate(now),
            }),
          ];

          when(
            mockCategoriesCollection.orderBy('usageCount', descending: true),
          ).thenReturn(mockQuery);
          when(
            mockQuery.snapshots(),
          ).thenAnswer((_) => Stream.value(mockQuerySnapshot));
          when(mockQuerySnapshot.docs).thenReturn(mockDocs);

          // Act
          final stream = repository.searchCategories('');
          final result = await stream.first;

          // Assert
          expect(result, hasLength(1));
          verify(
            mockCategoriesCollection.orderBy('usageCount', descending: true),
          ).called(1);
        },
      );

      test('should perform case-insensitive prefix search', () async {
        final mockDocs = [
          _createMockDoc('cat1', {
            'name': 'Meals',
            'nameLowercase': 'meals',
            'icon': 'restaurant',
            'color': '#FF5722',
            'usageCount': 100,
            'createdAt': Timestamp.fromDate(now),
            'updatedAt': Timestamp.fromDate(now),
          }),
        ];

        when(
          mockCategoriesCollection.where(
            'nameLowercase',
            isGreaterThanOrEqualTo: anyNamed('isGreaterThanOrEqualTo'),
          ),
        ).thenReturn(mockQuery);
        when(
          mockQuery.where('nameLowercase', isLessThan: anyNamed('isLessThan')),
        ).thenReturn(mockQuery);
        when(mockQuery.orderBy('nameLowercase')).thenReturn(mockQuery);
        when(
          mockQuery.orderBy('usageCount', descending: true),
        ).thenReturn(mockQuery);
        when(
          mockQuery.snapshots(),
        ).thenAnswer((_) => Stream.value(mockQuerySnapshot));
        when(mockQuerySnapshot.docs).thenReturn(mockDocs);

        // Act
        final stream = repository.searchCategories('meal');
        final result = await stream.first;

        // Assert
        expect(result, hasLength(1));
        expect(result[0].name, 'Meals');

        verify(
          mockCategoriesCollection.where(
            'nameLowercase',
            isGreaterThanOrEqualTo: 'meal', // Sanitized query
          ),
        ).called(1);
      });

      test('should handle whitespace in search query', () async {
        when(
          mockCategoriesCollection.where(
            'nameLowercase',
            isGreaterThanOrEqualTo: anyNamed('isGreaterThanOrEqualTo'),
          ),
        ).thenReturn(mockQuery);
        when(
          mockQuery.where('nameLowercase', isLessThan: anyNamed('isLessThan')),
        ).thenReturn(mockQuery);
        when(mockQuery.orderBy(any)).thenReturn(mockQuery);
        when(mockQuery.orderBy(any, descending: true)).thenReturn(mockQuery);
        when(
          mockQuery.snapshots(),
        ).thenAnswer((_) => Stream.value(mockQuerySnapshot));
        when(mockQuerySnapshot.docs).thenReturn([]);

        // Act
        final stream = repository.searchCategories('  MEAL  ');
        await stream.first;

        // Assert - should sanitize to 'meal' (trimmed and lowercased)
        verify(
          mockCategoriesCollection.where(
            'nameLowercase',
            isGreaterThanOrEqualTo: 'meal',
          ),
        ).called(1);
      });
    });

    group('getCategoryById', () {
      test('should return category when it exists', () async {
        final categoryData = {
          'name': 'Meals',
          'nameLowercase': 'meals',
          'icon': 'restaurant',
          'color': '#FF5722',
          'usageCount': 100,
          'createdAt': Timestamp.fromDate(now),
          'updatedAt': Timestamp.fromDate(now),
        };

        when(mockCategoriesCollection.doc('cat1')).thenReturn(mockDocRef);
        when(mockDocRef.get()).thenAnswer((_) async => mockDocSnapshot);
        when(mockDocSnapshot.exists).thenReturn(true);
        when(mockDocSnapshot.id).thenReturn('cat1');
        when(mockDocSnapshot.data()).thenReturn(categoryData);

        // Act
        final result = await repository.getCategoryById('cat1');

        // Assert
        expect(result, isNotNull);
        expect(result!.id, 'cat1');
        expect(result.name, 'Meals');
        verify(mockCategoriesCollection.doc('cat1')).called(1);
      });

      test('should return null when category does not exist', () async {
        when(
          mockCategoriesCollection.doc('nonexistent'),
        ).thenReturn(mockDocRef);
        when(mockDocRef.get()).thenAnswer((_) async => mockDocSnapshot);
        when(mockDocSnapshot.exists).thenReturn(false);

        // Act
        final result = await repository.getCategoryById('nonexistent');

        // Assert
        expect(result, isNull);
      });
    });

    group('categoryExists', () {
      test(
        'should return true when category with name exists (case-insensitive)',
        () async {
          final mockDocs = [
            _createMockDoc('cat1', {
              'name': 'Meals',
              'nameLowercase': 'meals',
              'icon': 'restaurant',
              'color': '#FF5722',
              'usageCount': 0,
              'createdAt': Timestamp.fromDate(now),
              'updatedAt': Timestamp.fromDate(now),
            }),
          ];

          when(
            mockCategoriesCollection.where(
              'nameLowercase',
              isEqualTo: anyNamed('isEqualTo'),
            ),
          ).thenReturn(mockQuery);
          when(mockQuery.limit(1)).thenReturn(mockQuery);
          when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);
          when(mockQuerySnapshot.docs).thenReturn(mockDocs);

          // Act
          final result = await repository.categoryExists('MEALS');

          // Assert
          expect(result, isTrue);
          verify(
            mockCategoriesCollection.where(
              'nameLowercase',
              isEqualTo: 'meals', // Sanitized
            ),
          ).called(1);
        },
      );

      test('should return false when category does not exist', () async {
        when(
          mockCategoriesCollection.where(
            'nameLowercase',
            isEqualTo: anyNamed('isEqualTo'),
          ),
        ).thenReturn(mockQuery);
        when(mockQuery.limit(1)).thenReturn(mockQuery);
        when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);
        when(mockQuerySnapshot.docs).thenReturn([]);

        // Act
        final result = await repository.categoryExists('NonExistent');

        // Assert
        expect(result, isFalse);
      });
    });

    group('canUserCreateCategory', () {
      test('should delegate to rate limiter service', () async {
        when(
          mockRateLimiterService.canUserCreateCategory('user1'),
        ).thenAnswer((_) async => true);

        // Act
        final result = await repository.canUserCreateCategory('user1');

        // Assert
        expect(result, isTrue);
        verify(mockRateLimiterService.canUserCreateCategory('user1')).called(1);
      });

      test('should return false when rate limited', () async {
        when(
          mockRateLimiterService.canUserCreateCategory('user1'),
        ).thenAnswer((_) async => false);

        // Act
        final result = await repository.canUserCreateCategory('user1');

        // Assert
        expect(result, isFalse);
      });
    });

    group('getCategoriesByIds', () {
      test('should batch fetch categories by IDs using whereIn query', () async {
        // Arrange
        final categoryIds = ['cat1', 'cat2', 'cat3'];
        final mockDocs = [
          _createMockDoc('cat1', {
            'name': 'Meals',
            'nameLowercase': 'meals',
            'icon': 'restaurant',
            'color': '#FF5722',
            'usageCount': 100,
            'createdAt': Timestamp.fromDate(now),
            'updatedAt': Timestamp.fromDate(now),
          }),
          _createMockDoc('cat2', {
            'name': 'Transport',
            'nameLowercase': 'transport',
            'icon': 'directions_car',
            'color': '#2196F3',
            'usageCount': 50,
            'createdAt': Timestamp.fromDate(now),
            'updatedAt': Timestamp.fromDate(now),
          }),
          _createMockDoc('cat3', {
            'name': 'Entertainment',
            'nameLowercase': 'entertainment',
            'icon': 'movie',
            'color': '#9C27B0',
            'usageCount': 25,
            'createdAt': Timestamp.fromDate(now),
            'updatedAt': Timestamp.fromDate(now),
          }),
        ];

        when(
          mockCategoriesCollection.where(
            FieldPath.documentId,
            whereIn: categoryIds,
          ),
        ).thenReturn(mockQuery);
        when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);
        when(mockQuerySnapshot.docs).thenReturn(mockDocs);

        // Act
        final result = await repository.getCategoriesByIds(categoryIds);

        // Assert
        expect(result, hasLength(3));
        expect(result[0].id, 'cat1');
        expect(result[0].name, 'Meals');
        expect(result[1].id, 'cat2');
        expect(result[1].name, 'Transport');
        expect(result[2].id, 'cat3');
        expect(result[2].name, 'Entertainment');

        verify(
          mockCategoriesCollection.where(
            FieldPath.documentId,
            whereIn: categoryIds,
          ),
        ).called(1);
      });

      test('should handle empty ID list', () async {
        // Act
        final result = await repository.getCategoriesByIds([]);

        // Assert
        expect(result, isEmpty);
        // No Firestore call should be made for empty list
      });

      test('should handle single ID', () async {
        final mockDocs = [
          _createMockDoc('cat1', {
            'name': 'Meals',
            'nameLowercase': 'meals',
            'icon': 'restaurant',
            'color': '#FF5722',
            'usageCount': 100,
            'createdAt': Timestamp.fromDate(now),
            'updatedAt': Timestamp.fromDate(now),
          }),
        ];

        when(
          mockCategoriesCollection.where(
            FieldPath.documentId,
            whereIn: ['cat1'],
          ),
        ).thenReturn(mockQuery);
        when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);
        when(mockQuerySnapshot.docs).thenReturn(mockDocs);

        // Act
        final result = await repository.getCategoriesByIds(['cat1']);

        // Assert
        expect(result, hasLength(1));
        expect(result[0].id, 'cat1');
      });

      test('should chunk requests for more than 10 IDs (Firestore limit)', () async {
        // Arrange - 15 category IDs (requires 2 chunks: 10 + 5)
        final categoryIds = List.generate(15, (i) => 'cat$i');
        final chunk1Ids = categoryIds.sublist(0, 10);
        final chunk2Ids = categoryIds.sublist(10, 15);

        // Mock first chunk response (10 categories)
        final chunk1Docs = List.generate(
          10,
          (i) => _createMockDoc('cat$i', {
            'name': 'Category $i',
            'nameLowercase': 'category $i',
            'icon': 'label',
            'color': '#000000',
            'usageCount': 0,
            'createdAt': Timestamp.fromDate(now),
            'updatedAt': Timestamp.fromDate(now),
          }),
        );

        // Mock second chunk response (5 categories)
        final chunk2Docs = List.generate(
          5,
          (i) => _createMockDoc('cat${i + 10}', {
            'name': 'Category ${i + 10}',
            'nameLowercase': 'category ${i + 10}',
            'icon': 'label',
            'color': '#000000',
            'usageCount': 0,
            'createdAt': Timestamp.fromDate(now),
            'updatedAt': Timestamp.fromDate(now),
          }),
        );

        final mockQuerySnapshot1 = MockQuerySnapshot();
        final mockQuerySnapshot2 = MockQuerySnapshot();

        when(
          mockCategoriesCollection.where(
            FieldPath.documentId,
            whereIn: chunk1Ids,
          ),
        ).thenReturn(mockQuery);
        when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot1);
        when(mockQuerySnapshot1.docs).thenReturn(chunk1Docs);

        // Need to create a new mock query for the second chunk
        final mockQuery2 = MockQuery();
        when(
          mockCategoriesCollection.where(
            FieldPath.documentId,
            whereIn: chunk2Ids,
          ),
        ).thenReturn(mockQuery2);
        when(mockQuery2.get()).thenAnswer((_) async => mockQuerySnapshot2);
        when(mockQuerySnapshot2.docs).thenReturn(chunk2Docs);

        // Act
        final result = await repository.getCategoriesByIds(categoryIds);

        // Assert
        expect(result, hasLength(15));
        expect(result[0].id, 'cat0');
        expect(result[10].id, 'cat10');
        expect(result[14].id, 'cat14');

        // Verify two separate queries were made
        verify(
          mockCategoriesCollection.where(
            FieldPath.documentId,
            whereIn: chunk1Ids,
          ),
        ).called(1);
        verify(
          mockCategoriesCollection.where(
            FieldPath.documentId,
            whereIn: chunk2Ids,
          ),
        ).called(1);
      });

      test('should handle partial results (some IDs not found)', () async {
        // Arrange - Request 3 IDs but only 2 exist
        final categoryIds = ['cat1', 'cat2', 'nonexistent'];
        final mockDocs = [
          _createMockDoc('cat1', {
            'name': 'Meals',
            'nameLowercase': 'meals',
            'icon': 'restaurant',
            'color': '#FF5722',
            'usageCount': 100,
            'createdAt': Timestamp.fromDate(now),
            'updatedAt': Timestamp.fromDate(now),
          }),
          _createMockDoc('cat2', {
            'name': 'Transport',
            'nameLowercase': 'transport',
            'icon': 'directions_car',
            'color': '#2196F3',
            'usageCount': 50,
            'createdAt': Timestamp.fromDate(now),
            'updatedAt': Timestamp.fromDate(now),
          }),
          // 'nonexistent' is not in results
        ];

        when(
          mockCategoriesCollection.where(
            FieldPath.documentId,
            whereIn: categoryIds,
          ),
        ).thenReturn(mockQuery);
        when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);
        when(mockQuerySnapshot.docs).thenReturn(mockDocs);

        // Act
        final result = await repository.getCategoriesByIds(categoryIds);

        // Assert - Should only return the 2 categories that exist
        expect(result, hasLength(2));
        expect(result[0].id, 'cat1');
        expect(result[1].id, 'cat2');
      });
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
