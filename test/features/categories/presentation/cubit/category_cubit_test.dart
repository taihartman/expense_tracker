import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:expense_tracker/features/categories/domain/models/category.dart';
import 'package:expense_tracker/features/categories/domain/repositories/category_repository.dart';
import 'package:expense_tracker/features/categories/data/services/rate_limiter_service.dart';
import 'package:expense_tracker/features/categories/presentation/cubit/category_cubit.dart';
import 'package:expense_tracker/features/categories/presentation/cubit/category_state.dart';

@GenerateMocks([CategoryRepository, RateLimiterService])
import 'category_cubit_test.mocks.dart';

void main() {
  late CategoryCubit cubit;
  late MockCategoryRepository mockCategoryRepository;
  late MockRateLimiterService mockRateLimiterService;

  final now = DateTime(2025, 10, 31, 12, 0, 0);

  final testCategory1 = Category(
    id: 'cat1',
    name: 'Meals',
    icon: 'restaurant',
    color: '#FF5722',
    usageCount: 100,
    createdAt: now,
    updatedAt: now,
  );

  final testCategory2 = Category(
    id: 'cat2',
    name: 'Transport',
    icon: 'directions_car',
    color: '#2196F3',
    usageCount: 50,
    createdAt: now,
    updatedAt: now,
  );

  setUp(() {
    mockCategoryRepository = MockCategoryRepository();
    mockRateLimiterService = MockRateLimiterService();

    cubit = CategoryCubit(
      categoryRepository: mockCategoryRepository,
      rateLimiterService: mockRateLimiterService,
    );
  });

  tearDown(() {
    cubit.close();
  });

  group('CategoryCubit', () {
    group('loadTopCategories', () {
      test(
        'should emit CategoryLoadingTop then CategoryTopLoaded on success',
        () async {
          // Arrange
          when(
            mockCategoryRepository.getTopCategories(limit: 5),
          ).thenAnswer((_) => Stream.value([testCategory1, testCategory2]));

          // Assert
          expect(
            cubit.stream,
            emitsInOrder([
              isA<CategoryLoadingTop>(),
              isA<CategoryTopLoaded>()
                  .having((s) => s.categories.length, 'categories length', 2)
                  .having(
                    (s) => s.categories[0].id,
                    'first category id',
                    'cat1',
                  )
                  .having(
                    (s) => s.categories[1].id,
                    'second category id',
                    'cat2',
                  ),
            ]),
          );

          // Act
          cubit.loadTopCategories(limit: 5);
        },
      );

      test('should use default limit of 5 when not specified', () async {
        // Arrange
        when(
          mockCategoryRepository.getTopCategories(limit: 5),
        ).thenAnswer((_) => Stream.value([testCategory1]));

        // Act
        cubit.loadTopCategories();

        // Wait for stream
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        verify(mockCategoryRepository.getTopCategories(limit: 5)).called(1);
      });

      test('should emit CategoryError on failure', () async {
        // Arrange
        when(
          mockCategoryRepository.getTopCategories(limit: anyNamed('limit')),
        ).thenAnswer((_) => Stream.error(Exception('Network error')));

        // Assert
        expect(
          cubit.stream,
          emitsInOrder([
            isA<CategoryLoadingTop>(),
            isA<CategoryError>()
                .having(
                  (s) => s.type,
                  'error type',
                  CategoryErrorType.loadFailed,
                )
                .having((s) => s.message, 'error message', contains('Failed')),
          ]),
        );

        // Act
        cubit.loadTopCategories();
      });

      test('should handle empty category list', () async {
        // Arrange
        when(
          mockCategoryRepository.getTopCategories(limit: anyNamed('limit')),
        ).thenAnswer((_) => Stream.value([]));

        // Assert
        expect(
          cubit.stream,
          emitsInOrder([
            isA<CategoryLoadingTop>(),
            isA<CategoryTopLoaded>().having(
              (s) => s.categories,
              'categories',
              isEmpty,
            ),
          ]),
        );

        // Act
        cubit.loadTopCategories();
      });
    });

    group('searchCategories', () {
      test('should emit CategorySearchResults with matching results', () async {
        // Arrange
        when(
          mockCategoryRepository.searchCategories('meal'),
        ).thenAnswer((_) => Stream.value([testCategory1]));

        // Assert
        expect(
          cubit.stream,
          emits(
            isA<CategorySearchResults>()
                .having((s) => s.query, 'query', 'meal')
                .having((s) => s.results.length, 'results length', 1)
                .having((s) => s.results[0].name, 'result name', 'Meals'),
          ),
        );

        // Act
        cubit.searchCategories('meal');
      });

      test(
        'should emit CategorySearchResults with empty results when no match',
        () async {
          // Arrange
          when(
            mockCategoryRepository.searchCategories('nonexistent'),
          ).thenAnswer((_) => Stream.value([]));

          // Assert
          expect(
            cubit.stream,
            emits(
              isA<CategorySearchResults>()
                  .having((s) => s.query, 'query', 'nonexistent')
                  .having((s) => s.results, 'results', isEmpty),
            ),
          );

          // Act
          cubit.searchCategories('nonexistent');
        },
      );

      test('should emit CategoryError on search failure', () async {
        // Arrange
        when(
          mockCategoryRepository.searchCategories(any),
        ).thenAnswer((_) => Stream.error(Exception('Search failed')));

        // Assert
        expect(
          cubit.stream,
          emits(
            isA<CategoryError>()
                .having(
                  (s) => s.type,
                  'error type',
                  CategoryErrorType.searchFailed,
                )
                .having(
                  (s) => s.message,
                  'error message',
                  contains('Failed to search'),
                ),
          ),
        );

        // Act
        cubit.searchCategories('test');
      });

      test('should handle empty query', () async {
        // Arrange
        when(
          mockCategoryRepository.searchCategories(''),
        ).thenAnswer((_) => Stream.value([testCategory1, testCategory2]));

        // Assert
        expect(
          cubit.stream,
          emits(
            isA<CategorySearchResults>()
                .having((s) => s.query, 'query', '')
                .having((s) => s.results.length, 'results length', 2),
          ),
        );

        // Act
        cubit.searchCategories('');
      });
    });

    group('createCategory', () {
      test('should emit CategoryCreated on successful creation', () async {
        // Arrange
        when(
          mockCategoryRepository.categoryExists('New Category'),
        ).thenAnswer((_) async => false);
        when(
          mockRateLimiterService.canUserCreateCategory('user1'),
        ).thenAnswer((_) async => true);
        when(
          mockCategoryRepository.createCategory(
            name: 'New Category',
            icon: 'label',
            color: '#FF5722',
            userId: 'user1',
          ),
        ).thenAnswer(
          (_) async => Category(
            id: 'cat3',
            name: 'New Category',
            icon: 'label',
            color: '#FF5722',
            usageCount: 0,
            createdAt: now,
            updatedAt: now,
          ),
        );

        // Assert
        expect(
          cubit.stream,
          emitsInOrder([
            isA<CategoryCreating>().having(
              (s) => s.name,
              'creating name',
              'New Category',
            ),
            isA<CategoryCreated>()
                .having((s) => s.category.name, 'category name', 'New Category')
                .having((s) => s.category.id, 'category id', 'cat3'),
          ]),
        );

        // Act
        await cubit.createCategory(
          name: 'New Category',
          icon: 'label',
          color: '#FF5722',
          userId: 'user1',
        );
      });

      test('should emit validation error for empty name', () async {
        // Assert
        expect(
          cubit.stream,
          emits(
            isA<CategoryError>()
                .having(
                  (s) => s.type,
                  'error type',
                  CategoryErrorType.validation,
                )
                .having(
                  (s) => s.message,
                  'error message',
                  contains('cannot be empty'),
                ),
          ),
        );

        // Act
        await cubit.createCategory(
          name: '',
          icon: 'label',
          color: '#FF5722',
          userId: 'user1',
        );
      });

      test(
        'should emit validation error for name with invalid characters',
        () async {
          // Assert
          expect(
            cubit.stream,
            emits(
              isA<CategoryError>()
                  .having(
                    (s) => s.type,
                    'error type',
                    CategoryErrorType.validation,
                  )
                  .having(
                    (s) => s.message,
                    'error message',
                    contains('can only contain'),
                  ),
            ),
          );

          // Act
          await cubit.createCategory(
            name: 'Invalid@Category',
            icon: 'label',
            color: '#FF5722',
            userId: 'user1',
          );
        },
      );

      test(
        'should emit validation error for name exceeding max length',
        () async {
          final longName = 'A' * 51; // Max is 50

          // Assert
          expect(
            cubit.stream,
            emits(
              isA<CategoryError>()
                  .having(
                    (s) => s.type,
                    'error type',
                    CategoryErrorType.validation,
                  )
                  .having(
                    (s) => s.message,
                    'error message',
                    contains('between 1'),
                  ),
            ),
          );

          // Act
          await cubit.createCategory(
            name: longName,
            icon: 'label',
            color: '#FF5722',
            userId: 'user1',
          );
        },
      );

      test(
        'should emit duplicate error when category already exists',
        () async {
          // Arrange
          when(
            mockCategoryRepository.categoryExists('Meals'),
          ).thenAnswer((_) async => true);

          // Assert
          expect(
            cubit.stream,
            emits(
              isA<CategoryError>()
                  .having(
                    (s) => s.type,
                    'error type',
                    CategoryErrorType.duplicate,
                  )
                  .having(
                    (s) => s.message,
                    'error message',
                    contains('already exists'),
                  ),
            ),
          );

          // Act
          await cubit.createCategory(
            name: 'Meals',
            icon: 'label',
            color: '#FF5722',
            userId: 'user1',
          );
        },
      );

      test('should emit rate limit error when user is rate-limited', () async {
        // Arrange
        when(
          mockCategoryRepository.categoryExists('New Category'),
        ).thenAnswer((_) async => false);
        when(
          mockRateLimiterService.canUserCreateCategory('user1'),
        ).thenAnswer((_) async => false);
        when(
          mockRateLimiterService.getTimeUntilNextCreation('user1'),
        ).thenAnswer((_) async => const Duration(minutes: 3));

        // Assert
        expect(
          cubit.stream,
          emits(
            isA<CategoryError>()
                .having(
                  (s) => s.type,
                  'error type',
                  CategoryErrorType.rateLimit,
                )
                .having(
                  (s) => s.message,
                  'error message',
                  contains('too many categories'),
                )
                .having((s) => s.message, 'minutes in message', contains('3')),
          ),
        );

        // Act
        await cubit.createCategory(
          name: 'New Category',
          icon: 'label',
          color: '#FF5722',
          userId: 'user1',
        );
      });

      test('should handle repository errors during creation', () async {
        // Arrange
        when(
          mockCategoryRepository.categoryExists(any),
        ).thenAnswer((_) async => false);
        when(
          mockRateLimiterService.canUserCreateCategory(any),
        ).thenAnswer((_) async => true);
        when(
          mockCategoryRepository.createCategory(
            name: anyNamed('name'),
            icon: anyNamed('icon'),
            color: anyNamed('color'),
            userId: anyNamed('userId'),
          ),
        ).thenThrow(Exception('Database error'));

        // Assert
        expect(
          cubit.stream,
          emitsInOrder([
            isA<CategoryCreating>(),
            isA<CategoryError>()
                .having(
                  (s) => s.type,
                  'error type',
                  CategoryErrorType.createFailed,
                )
                .having((s) => s.message, 'error message', contains('Failed')),
          ]),
        );

        // Act
        await cubit.createCategory(
          name: 'New Category',
          icon: 'label',
          color: '#FF5722',
          userId: 'user1',
        );
      });
    });

    group('incrementCategoryUsage', () {
      test('should emit CategoryUsageIncremented on success', () async {
        // Arrange
        when(
          mockCategoryRepository.incrementCategoryUsage('cat1'),
        ).thenAnswer((_) async => {});

        // Assert
        expect(
          cubit.stream,
          emits(
            isA<CategoryUsageIncremented>().having(
              (s) => s.categoryId,
              'categoryId',
              'cat1',
            ),
          ),
        );

        // Act
        await cubit.incrementCategoryUsage('cat1');
      });

      test('should emit generic error on failure (silent in UI)', () async {
        // Arrange
        when(
          mockCategoryRepository.incrementCategoryUsage('cat1'),
        ).thenThrow(Exception('Network error'));

        // Assert
        expect(
          cubit.stream,
          emits(
            isA<CategoryError>()
                .having((s) => s.type, 'error type', CategoryErrorType.generic)
                .having(
                  (s) => s.message,
                  'error message',
                  contains('Failed to update'),
                ),
          ),
        );

        // Act
        await cubit.incrementCategoryUsage('cat1');
      });
    });

    group('checkRateLimit', () {
      test(
        'should emit CategoryRateLimitChecked with can create = true',
        () async {
          // Arrange
          when(
            mockRateLimiterService.canUserCreateCategory('user1'),
          ).thenAnswer((_) async => true);
          when(
            mockRateLimiterService.getRecentCreationCount('user1'),
          ).thenAnswer((_) async => 1);
          when(
            mockRateLimiterService.getTimeUntilNextCreation('user1'),
          ).thenAnswer((_) async => null);

          // Assert
          expect(
            cubit.stream,
            emits(
              isA<CategoryRateLimitChecked>()
                  .having((s) => s.canCreate, 'canCreate', isTrue)
                  .having(
                    (s) => s.recentCreationCount,
                    'recentCreationCount',
                    1,
                  )
                  .having((s) => s.timeUntilNext, 'timeUntilNext', isNull),
            ),
          );

          // Act
          await cubit.checkRateLimit('user1');
        },
      );

      test(
        'should emit CategoryRateLimitChecked with can create = false',
        () async {
          // Arrange
          when(
            mockRateLimiterService.canUserCreateCategory('user1'),
          ).thenAnswer((_) async => false);
          when(
            mockRateLimiterService.getRecentCreationCount('user1'),
          ).thenAnswer((_) async => 3);
          when(
            mockRateLimiterService.getTimeUntilNextCreation('user1'),
          ).thenAnswer((_) async => const Duration(minutes: 2));

          // Assert
          expect(
            cubit.stream,
            emits(
              isA<CategoryRateLimitChecked>()
                  .having((s) => s.canCreate, 'canCreate', isFalse)
                  .having(
                    (s) => s.recentCreationCount,
                    'recentCreationCount',
                    3,
                  )
                  .having(
                    (s) => s.timeUntilNext?.inMinutes,
                    'minutes remaining',
                    2,
                  ),
            ),
          );

          // Act
          await cubit.checkRateLimit('user1');
        },
      );

      test('should emit CategoryError on rate limit check failure', () async {
        // Arrange
        when(
          mockRateLimiterService.canUserCreateCategory('user1'),
        ).thenThrow(Exception('Service unavailable'));

        // Assert
        expect(
          cubit.stream,
          emits(
            isA<CategoryError>()
                .having((s) => s.type, 'error type', CategoryErrorType.generic)
                .having(
                  (s) => s.message,
                  'error message',
                  contains('Failed to check'),
                ),
          ),
        );

        // Act
        await cubit.checkRateLimit('user1');
      });
    });
  });
}
