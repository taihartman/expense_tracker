import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:expense_tracker/features/trips/domain/models/trip.dart';
import 'package:expense_tracker/features/trips/domain/repositories/trip_repository.dart';
import 'package:expense_tracker/core/services/activity_logger_service.dart';
import 'package:expense_tracker/features/categories/domain/repositories/category_repository.dart';
import 'package:expense_tracker/core/services/local_storage_service.dart';
import 'package:expense_tracker/core/models/currency_code.dart';
import 'package:expense_tracker/core/models/participant.dart';
import 'package:expense_tracker/features/trips/presentation/cubits/trip_cubit.dart';
import 'package:expense_tracker/features/trips/presentation/cubits/trip_state.dart';

// Generate mocks
@GenerateNiceMocks([
  MockSpec<TripRepository>(),
  MockSpec<ActivityLoggerService>(),
  MockSpec<CategoryRepository>(),
  MockSpec<LocalStorageService>(),
])
import 'trip_cubit_test.mocks.dart';

void main() {
  late TripCubit cubit;
  late MockTripRepository mockTripRepository;
  late MockActivityLoggerService mockActivityLoggerService;
  late MockCategoryRepository mockCategoryRepository;
  late MockLocalStorageService mockLocalStorageService;

  setUp(() {
    mockTripRepository = MockTripRepository();
    mockActivityLoggerService = MockActivityLoggerService();
    mockCategoryRepository = MockCategoryRepository();
    mockLocalStorageService = MockLocalStorageService();

    // Default stub: return empty list for getJoinedTripIds
    when(mockLocalStorageService.getJoinedTripIds()).thenAnswer((_) async => []);
    when(mockLocalStorageService.getSelectedTripId()).thenReturn(null);

    cubit = TripCubit(
      tripRepository: mockTripRepository,
      localStorageService: mockLocalStorageService,
      activityLoggerService: mockActivityLoggerService,
      categoryRepository: mockCategoryRepository,
    );
  });

  tearDown(() {
    cubit.close();
  });

  group('T012: TripCubit.createTrip adds creator as participant', () {
    test(
      'should add creator name to trip participants when creating trip',
      () async {
        // Arrange
        const tripName = 'Test Trip';
        const baseCurrency = CurrencyCode.usd;
        const creatorName = 'Alice';
        final creatorParticipant = Participant.fromName(creatorName);

        final createdTrip = Trip(
          id: 'trip-123',
          name: tripName,
          allowedCurrencies: [baseCurrency],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          participants: [creatorParticipant], // Creator should be added
        );

        when(
          mockTripRepository.createTrip(any),
        ).thenAnswer((_) async => createdTrip);
        when(
          mockCategoryRepository.seedDefaultCategories(),
        ).thenAnswer((_) async => []);
        when(
          mockActivityLoggerService.logTripCreated(any, any),
        ).thenAnswer((_) async {});
        when(
          mockLocalStorageService.addJoinedTrip(any),
        ).thenAnswer((_) async => {});
        when(
          mockTripRepository.getAllTrips(),
        ).thenAnswer((_) => Stream.value([createdTrip]));

        // Act
        await cubit.createTrip(
          name: tripName,
          allowedCurrencies: [baseCurrency],
          creatorName: creatorName,
        );

        // Wait for stream to complete
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        final capturedTrip =
            verify(mockTripRepository.createTrip(captureAny)).captured.single
                as Trip;
        expect(capturedTrip.participants.length, 1);
        expect(capturedTrip.participants.first.name, creatorName);
      },
    );
  });

  group('T013: TripCubit.createTrip logs trip_created activity', () {
    test('should log activity when trip is created', () async {
      // Arrange
      const tripName = 'Test Trip';
      const baseCurrency = CurrencyCode.usd;
      const creatorName = 'Alice';
      final creatorParticipant = Participant.fromName(creatorName);

      final createdTrip = Trip(
        id: 'trip-123',
        name: tripName,
        allowedCurrencies: [baseCurrency],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        participants: [creatorParticipant],
      );

      when(
        mockTripRepository.createTrip(any),
      ).thenAnswer((_) async => createdTrip);
      when(
        mockCategoryRepository.seedDefaultCategories(),
      ).thenAnswer((_) async => []);
      when(
        mockActivityLoggerService.logTripCreated(any, any),
      ).thenAnswer((_) async {});
      when(
        mockLocalStorageService.addJoinedTrip(any),
      ).thenAnswer((_) async => {});
      when(
        mockTripRepository.getAllTrips(),
      ).thenAnswer((_) => Stream.value([createdTrip]));

      // Act
      await cubit.createTrip(
        name: tripName,
        allowedCurrencies: [baseCurrency],
        creatorName: creatorName,
      );

      // Wait for stream to complete
      await Future.delayed(const Duration(milliseconds: 100));

      // Assert - verify service method was called
      verify(
        mockActivityLoggerService.logTripCreated(
          argThat(predicate((Trip t) => t.id == createdTrip.id)),
          creatorName,
        ),
      ).called(1);
    });
  });

  group('T014: TripCubit.createTrip caches joined trip ID', () {
    test('should cache trip ID in local storage after creation', () async {
      // Arrange
      const tripName = 'Test Trip';
      const baseCurrency = CurrencyCode.usd;
      const creatorName = 'Alice';
      final creatorParticipant = Participant.fromName(creatorName);

      final createdTrip = Trip(
        id: 'trip-123',
        name: tripName,
        allowedCurrencies: [baseCurrency],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        participants: [creatorParticipant],
      );

      when(
        mockTripRepository.createTrip(any),
      ).thenAnswer((_) async => createdTrip);
      when(
        mockCategoryRepository.seedDefaultCategories(),
      ).thenAnswer((_) async => []);
      when(
        mockActivityLoggerService.logTripCreated(any, any),
      ).thenAnswer((_) async {});
      when(
        mockLocalStorageService.addJoinedTrip(any),
      ).thenAnswer((_) async => {});
      when(
        mockTripRepository.getAllTrips(),
      ).thenAnswer((_) => Stream.value([createdTrip]));

      // Act
      await cubit.createTrip(
        name: tripName,
        allowedCurrencies: [baseCurrency],
        creatorName: creatorName,
      );

      // Wait for stream to complete
      await Future.delayed(const Duration(milliseconds: 100));

      // Assert
      verify(mockLocalStorageService.addJoinedTrip(createdTrip.id)).called(1);
    });
  });

  group('T015: TripCubit.loadTrips filters to joined trips only', () {
    test('should only load trips that user has joined', () async {
      // Arrange
      final joinedTrips = [
        Trip(
          id: 'trip-1',
          name: 'Joined Trip 1',
          allowedCurrencies: [CurrencyCode.usd],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        Trip(
          id: 'trip-2',
          name: 'Joined Trip 2',
          allowedCurrencies: [CurrencyCode.vnd],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      final allTrips = [
        ...joinedTrips,
        Trip(
          id: 'trip-3',
          name: 'Not Joined Trip',
          allowedCurrencies: [CurrencyCode.usd],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      when(
        mockLocalStorageService.getJoinedTripIds(),
      ).thenAnswer((_) async => ['trip-1', 'trip-2']);
      when(
        mockTripRepository.getAllTrips(),
      ).thenAnswer((_) => Stream.value(allTrips));

      // Act
      await cubit.loadTrips();

      // Wait for stream to process
      await Future.delayed(const Duration(milliseconds: 100));

      // Assert
      expect(cubit.state, isA<TripLoaded>());
      final loadedState = cubit.state as TripLoaded;
      expect(loadedState.trips.length, 2);
      expect(
        loadedState.trips.map((t) => t.id),
        containsAll(['trip-1', 'trip-2']),
      );
      expect(loadedState.trips.map((t) => t.id), isNot(contains('trip-3')));
    });

    test(
      'should show all trips if user has not joined any trips (backward compatibility)',
      () async {
        // Arrange
        final allTrips = [
          Trip(
            id: 'trip-1',
            name: 'Trip 1',
            allowedCurrencies: [CurrencyCode.usd],
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          Trip(
            id: 'trip-2',
            name: 'Trip 2',
            allowedCurrencies: [CurrencyCode.vnd],
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ];

        when(
          mockLocalStorageService.getJoinedTripIds(),
        ).thenAnswer((_) async => []); // No joined trips
        when(
          mockTripRepository.getAllTrips(),
        ).thenAnswer((_) => Stream.value(allTrips));

        // Act
        await cubit.loadTrips();

        // Wait for stream to process
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        expect(cubit.state, isA<TripLoaded>());
        final loadedState = cubit.state as TripLoaded;
        expect(
          loadedState.trips.length,
          2,
        ); // Shows all trips for backward compatibility
      },
    );
  });

  group('T026: TripCubit.joinTrip adds participant and logs activity', () {
    test(
      'should add user as participant and log activity when joining trip',
      () async {
        // Arrange
        const tripId = 'trip-456';
        const userName = 'Bob';
        final userParticipant = Participant.fromName(userName);

        final existingTrip = Trip(
          id: tripId,
          name: 'Existing Trip',
          allowedCurrencies: [CurrencyCode.usd],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          participants: [Participant.fromName('Alice')], // Alice created it
        );

        final updatedTrip = existingTrip.copyWith(
          participants: [...existingTrip.participants, userParticipant],
        );

        when(
          mockTripRepository.getTripById(tripId),
        ).thenAnswer((_) async => existingTrip);
        when(
          mockTripRepository.updateTrip(any),
        ).thenAnswer((_) async => updatedTrip);
        when(
          mockActivityLoggerService.logMemberJoined(
            tripId: anyNamed('tripId'),
            memberName: anyNamed('memberName'),
            joinMethod: anyNamed('joinMethod'),
            inviterId: anyNamed('inviterId'),
          ),
        ).thenAnswer((_) async {});
        when(
          mockLocalStorageService.addJoinedTrip(tripId),
        ).thenAnswer((_) async => {});
        when(
          mockTripRepository.getAllTrips(),
        ).thenAnswer((_) => Stream.value([updatedTrip]));

        // Act
        await cubit.joinTrip(tripId: tripId, userName: userName);

        // Wait for stream to complete
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert: Check participant was added
        final capturedTrip =
            verify(mockTripRepository.updateTrip(captureAny)).captured.single
                as Trip;
        expect(capturedTrip.id, tripId);
        expect(capturedTrip.participants.length, 2);
        expect(capturedTrip.participants.last.name, userName);

        // Assert: Check activity was logged
        verify(
          mockActivityLoggerService.logMemberJoined(
            tripId: tripId,
            memberName: userName,
            joinMethod: anyNamed('joinMethod'),
            inviterId: anyNamed('inviterId'),
          ),
        ).called(1);

        // Assert: Check trip ID was cached
        verify(mockLocalStorageService.addJoinedTrip(tripId)).called(1);
      },
    );
  });

  group('T027: TripCubit.joinTrip is idempotent (already member)', () {
    test(
      'should not add duplicate participant if user already a member',
      () async {
        // Arrange
        const tripId = 'trip-789';
        const userName = 'Charlie';

        final existingTrip = Trip(
          id: tripId,
          name: 'Existing Trip',
          allowedCurrencies: [CurrencyCode.usd],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          participants: [
            Participant.fromName('Alice'),
            Participant.fromName(userName), // Charlie already a member
          ],
        );

        when(
          mockTripRepository.getTripById(tripId),
        ).thenAnswer((_) async => existingTrip);
        when(mockLocalStorageService.getJoinedTripIds()).thenAnswer((_) async => [tripId]);
        when(
          mockTripRepository.getAllTrips(),
        ).thenAnswer((_) => Stream.value([existingTrip]));

        // Act
        await cubit.joinTrip(tripId: tripId, userName: userName);

        // Wait for stream to complete
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert: Should not update trip or log activity
        verifyNever(mockTripRepository.updateTrip(any));
        verifyNever(mockActivityLoggerService.logTripCreated(any, any));

        // But should still cache the trip ID (idempotent)
        verify(mockLocalStorageService.addJoinedTrip(tripId)).called(1);
      },
    );
  });

  group('T028: TripCubit.joinTrip handles trip not found', () {
    test('should emit error when trip does not exist', () async {
      // Arrange
      const tripId = 'nonexistent-trip';
      const userName = 'Dave';

      when(
        mockTripRepository.getTripById(tripId),
      ).thenAnswer((_) async => null);

      // Act
      await cubit.joinTrip(tripId: tripId, userName: userName);

      // Assert: Should emit error
      expect(cubit.state, isA<TripError>());
      final errorState = cubit.state as TripError;
      expect(errorState.message, contains('Trip not found'));

      // Should not update anything
      verifyNever(mockTripRepository.updateTrip(any));
      verifyNever(mockActivityLoggerService.logTripCreated(any, any));
      verifyNever(mockLocalStorageService.addJoinedTrip(any));
    });
  });

  group('T029: TripCubit.isUserMemberOf checks local cache', () {
    test('should return true if trip ID is in joined trips cache', () async {
      // Arrange
      const tripId = 'trip-999';
      when(
        mockLocalStorageService.getJoinedTripIds(),
      ).thenAnswer((_) async => [tripId, 'trip-888']);

      // Act
      final isMember = await cubit.isUserMemberOf(tripId);

      // Assert
      expect(isMember, true);
    });

    test('should return false if trip ID is not in joined trips cache', () async {
      // Arrange
      const tripId = 'trip-999';
      when(
        mockLocalStorageService.getJoinedTripIds(),
      ).thenAnswer((_) async => ['trip-888', 'trip-777']);

      // Act
      final isMember = await cubit.isUserMemberOf(tripId);

      // Assert
      expect(isMember, false);
    });
  });

  group('hasDuplicateMember', () {
    test(
      'returns true when participant with matching name exists (exact match)',
      () async {
        // Arrange
        final now = DateTime.now();
        final trip = Trip(
          id: 'trip-1',
          name: 'Test Trip',
          allowedCurrencies: [CurrencyCode.usd],
          participants: [
            const Participant(id: 'p1', name: 'Alice'),
            const Participant(id: 'p2', name: 'Bob'),
          ],
          createdAt: now,
          updatedAt: now,
        );

        when(
          mockTripRepository.getTripById('trip-1'),
        ).thenAnswer((_) async => trip);

        // Act
        final result = await cubit.hasDuplicateMember('trip-1', 'Alice');

        // Assert
        expect(result, true);
      },
    );

    test(
      'returns true when participant exists with different casing (case-insensitive)',
      () async {
        // Arrange
        final now = DateTime.now();
        final trip = Trip(
          id: 'trip-1',
          name: 'Test Trip',
          allowedCurrencies: [CurrencyCode.usd],
          participants: [
            const Participant(id: 'p1', name: 'Alice'),
            const Participant(id: 'p2', name: 'Bob'),
          ],
          createdAt: now,
          updatedAt: now,
        );

        when(
          mockTripRepository.getTripById('trip-1'),
        ).thenAnswer((_) async => trip);

        // Act - test various casings
        final resultLower = await cubit.hasDuplicateMember('trip-1', 'alice');
        final resultUpper = await cubit.hasDuplicateMember('trip-1', 'ALICE');
        final resultMixed = await cubit.hasDuplicateMember('trip-1', 'aLiCe');

        // Assert
        expect(resultLower, true);
        expect(resultUpper, true);
        expect(resultMixed, true);
      },
    );

    test(
      'returns false when no participant with matching name exists',
      () async {
        // Arrange
        final now = DateTime.now();
        final trip = Trip(
          id: 'trip-1',
          name: 'Test Trip',
          allowedCurrencies: [CurrencyCode.usd],
          participants: [
            const Participant(id: 'p1', name: 'Alice'),
            const Participant(id: 'p2', name: 'Bob'),
          ],
          createdAt: now,
          updatedAt: now,
        );

        when(
          mockTripRepository.getTripById('trip-1'),
        ).thenAnswer((_) async => trip);

        // Act
        final result = await cubit.hasDuplicateMember('trip-1', 'Charlie');

        // Assert
        expect(result, false);
      },
    );

    test('returns false when trip has no participants', () async {
      // Arrange
      final now = DateTime.now();
      final trip = Trip(
        id: 'trip-1',
        name: 'Test Trip',
        allowedCurrencies: [CurrencyCode.usd],
        participants: [],
        createdAt: now,
        updatedAt: now,
      );

      when(
        mockTripRepository.getTripById('trip-1'),
      ).thenAnswer((_) async => trip);

      // Act
      final result = await cubit.hasDuplicateMember('trip-1', 'Alice');

      // Assert
      expect(result, false);
    });

    test('handles null trip gracefully', () async {
      // Arrange
      when(
        mockTripRepository.getTripById('trip-1'),
      ).thenAnswer((_) async => null);

      // Act
      final result = await cubit.hasDuplicateMember('trip-1', 'Alice');

      // Assert
      expect(result, false);
    });
  });

  group('TripCubit.updateTripCurrencies', () {
    test('successfully updates trip currencies', () async {
      // Arrange
      const tripId = 'trip-123';
      const newCurrencies = [CurrencyCode.eur, CurrencyCode.usd];

      final existingTrip = Trip(
        id: tripId,
        name: 'Test Trip',
        allowedCurrencies: [CurrencyCode.usd],
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );

      final updatedTrip = existingTrip.copyWith(
        allowedCurrencies: newCurrencies,
      );

      when(
        mockTripRepository.getTripById(tripId),
      ).thenAnswer((_) async => existingTrip);
      when(
        mockTripRepository.updateTrip(any),
      ).thenAnswer((_) async => updatedTrip);
      when(
        mockTripRepository.getAllTrips(),
      ).thenAnswer((_) => Stream.value([updatedTrip]));

      // Act
      await cubit.updateTripCurrencies(
        tripId: tripId,
        currencies: newCurrencies,
      );

      // Wait for stream to process
      await Future.delayed(const Duration(milliseconds: 100));

      // Assert
      final capturedTrip =
          verify(mockTripRepository.updateTrip(captureAny)).captured.single
              as Trip;
      expect(capturedTrip.allowedCurrencies, newCurrencies);
      expect(cubit.state, isA<TripLoaded>());
    });

    test('emits error when trip not found', () async {
      // Arrange
      const tripId = 'non-existent-trip';
      const newCurrencies = [CurrencyCode.eur, CurrencyCode.usd];

      when(
        mockTripRepository.getTripById(tripId),
      ).thenAnswer((_) async => null);

      // Act
      await cubit.updateTripCurrencies(
        tripId: tripId,
        currencies: newCurrencies,
      );

      // Assert
      expect(cubit.state, isA<TripError>());
      final errorState = cubit.state as TripError;
      expect(errorState.message, contains('Trip not found'));
    });

    test('logs activity when actorName is provided', () async {
      // Arrange
      const tripId = 'trip-123';
      const actorName = 'Alice';
      const newCurrencies = [
        CurrencyCode.eur,
        CurrencyCode.usd,
        CurrencyCode.gbp,
      ];

      final existingTrip = Trip(
        id: tripId,
        name: 'Test Trip',
        allowedCurrencies: [CurrencyCode.usd],
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );

      final updatedTrip = existingTrip.copyWith(
        allowedCurrencies: newCurrencies,
      );

      when(
        mockTripRepository.getTripById(tripId),
      ).thenAnswer((_) async => existingTrip);
      when(
        mockTripRepository.updateTrip(any),
      ).thenAnswer((_) async => updatedTrip);
      when(
        mockTripRepository.getAllTrips(),
      ).thenAnswer((_) => Stream.value([updatedTrip]));
      when(
        mockActivityLoggerService.logTripUpdated(any, any, any),
      ).thenAnswer((_) async {});

      // Act
      await cubit.updateTripCurrencies(
        tripId: tripId,
        currencies: newCurrencies,
        actorName: actorName,
      );

      // Wait for activity logging
      await Future.delayed(const Duration(milliseconds: 100));

      // Assert
      verify(
        mockActivityLoggerService.logTripUpdated(existingTrip, any, actorName),
      ).called(1);
    });

    test('does not log activity when actorName is null', () async {
      // Arrange
      const tripId = 'trip-123';
      const newCurrencies = [CurrencyCode.eur, CurrencyCode.usd];

      final existingTrip = Trip(
        id: tripId,
        name: 'Test Trip',
        allowedCurrencies: [CurrencyCode.usd],
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );

      final updatedTrip = existingTrip.copyWith(
        allowedCurrencies: newCurrencies,
      );

      when(
        mockTripRepository.getTripById(tripId),
      ).thenAnswer((_) async => existingTrip);
      when(
        mockTripRepository.updateTrip(any),
      ).thenAnswer((_) async => updatedTrip);
      when(
        mockTripRepository.getAllTrips(),
      ).thenAnswer((_) => Stream.value([updatedTrip]));

      // Act
      await cubit.updateTripCurrencies(
        tripId: tripId,
        currencies: newCurrencies,
        // actorName not provided
      );

      // Wait for potential activity logging
      await Future.delayed(const Duration(milliseconds: 100));

      // Assert
      verifyNever(mockActivityLoggerService.logTripUpdated(any, any, any));
    });

    test('does not log activity when actorName is empty', () async {
      // Arrange
      const tripId = 'trip-123';
      const newCurrencies = [CurrencyCode.eur, CurrencyCode.usd];

      final existingTrip = Trip(
        id: tripId,
        name: 'Test Trip',
        allowedCurrencies: [CurrencyCode.usd],
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );

      final updatedTrip = existingTrip.copyWith(
        allowedCurrencies: newCurrencies,
      );

      when(
        mockTripRepository.getTripById(tripId),
      ).thenAnswer((_) async => existingTrip);
      when(
        mockTripRepository.updateTrip(any),
      ).thenAnswer((_) async => updatedTrip);
      when(
        mockTripRepository.getAllTrips(),
      ).thenAnswer((_) => Stream.value([updatedTrip]));

      // Act
      await cubit.updateTripCurrencies(
        tripId: tripId,
        currencies: newCurrencies,
        actorName: '', // Empty string
      );

      // Wait for potential activity logging
      await Future.delayed(const Duration(milliseconds: 100));

      // Assert
      verifyNever(mockActivityLoggerService.logTripUpdated(any, any, any));
    });

    test('handles repository errors gracefully', () async {
      // Arrange
      const tripId = 'trip-123';
      const newCurrencies = [CurrencyCode.eur, CurrencyCode.usd];

      final existingTrip = Trip(
        id: tripId,
        name: 'Test Trip',
        allowedCurrencies: [CurrencyCode.usd],
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );

      when(
        mockTripRepository.getTripById(tripId),
      ).thenAnswer((_) async => existingTrip);
      when(
        mockTripRepository.updateTrip(any),
      ).thenThrow(Exception('Database error'));

      // Act
      await cubit.updateTripCurrencies(
        tripId: tripId,
        currencies: newCurrencies,
      );

      // Assert
      expect(cubit.state, isA<TripError>());
      final errorState = cubit.state as TripError;
      expect(errorState.message, contains('Failed to update trip currencies'));
    });

    test('preserves other trip fields when updating currencies', () async {
      // Arrange
      const tripId = 'trip-123';
      const newCurrencies = [CurrencyCode.eur, CurrencyCode.usd];

      final participant1 = Participant.fromName('Alice');
      final participant2 = Participant.fromName('Bob');

      final existingTrip = Trip(
        id: tripId,
        name: 'Original Trip Name',
        allowedCurrencies: [CurrencyCode.usd],
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
        participants: [participant1, participant2],
        isArchived: false,
      );

      final updatedTrip = existingTrip.copyWith(
        allowedCurrencies: newCurrencies,
      );

      when(
        mockTripRepository.getTripById(tripId),
      ).thenAnswer((_) async => existingTrip);
      when(
        mockTripRepository.updateTrip(any),
      ).thenAnswer((_) async => updatedTrip);
      when(
        mockTripRepository.getAllTrips(),
      ).thenAnswer((_) => Stream.value([updatedTrip]));

      // Act
      await cubit.updateTripCurrencies(
        tripId: tripId,
        currencies: newCurrencies,
      );

      // Assert
      final capturedTrip =
          verify(mockTripRepository.updateTrip(captureAny)).captured.single
              as Trip;

      // Verify other fields are preserved
      expect(capturedTrip.name, existingTrip.name);
      expect(capturedTrip.participants, existingTrip.participants);
      expect(capturedTrip.isArchived, existingTrip.isArchived);
      expect(capturedTrip.createdAt, existingTrip.createdAt);

      // Verify only currencies changed
      expect(capturedTrip.allowedCurrencies, newCurrencies);
    });

    test('updates trip with single currency', () async {
      // Arrange
      const tripId = 'trip-123';
      const newCurrencies = [CurrencyCode.jpy];

      final existingTrip = Trip(
        id: tripId,
        name: 'Test Trip',
        allowedCurrencies: [CurrencyCode.usd],
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );

      final updatedTrip = existingTrip.copyWith(
        allowedCurrencies: newCurrencies,
      );

      when(
        mockTripRepository.getTripById(tripId),
      ).thenAnswer((_) async => existingTrip);
      when(
        mockTripRepository.updateTrip(any),
      ).thenAnswer((_) async => updatedTrip);
      when(
        mockTripRepository.getAllTrips(),
      ).thenAnswer((_) => Stream.value([updatedTrip]));

      // Act
      await cubit.updateTripCurrencies(
        tripId: tripId,
        currencies: newCurrencies,
      );

      // Assert
      final capturedTrip =
          verify(mockTripRepository.updateTrip(captureAny)).captured.single
              as Trip;
      expect(capturedTrip.allowedCurrencies, [CurrencyCode.jpy]);
      expect(capturedTrip.allowedCurrencies.length, 1);
    });

    test('updates trip with maximum (10) currencies', () async {
      // Arrange
      const tripId = 'trip-123';
      const newCurrencies = [
        CurrencyCode.usd,
        CurrencyCode.eur,
        CurrencyCode.gbp,
        CurrencyCode.jpy,
        CurrencyCode.cad,
        CurrencyCode.aud,
        CurrencyCode.chf,
        CurrencyCode.cny,
        CurrencyCode.sek,
        CurrencyCode.nzd,
      ];

      final existingTrip = Trip(
        id: tripId,
        name: 'Test Trip',
        allowedCurrencies: [CurrencyCode.usd],
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );

      final updatedTrip = existingTrip.copyWith(
        allowedCurrencies: newCurrencies,
      );

      when(
        mockTripRepository.getTripById(tripId),
      ).thenAnswer((_) async => existingTrip);
      when(
        mockTripRepository.updateTrip(any),
      ).thenAnswer((_) async => updatedTrip);
      when(
        mockTripRepository.getAllTrips(),
      ).thenAnswer((_) => Stream.value([updatedTrip]));

      // Act
      await cubit.updateTripCurrencies(
        tripId: tripId,
        currencies: newCurrencies,
      );

      // Assert
      final capturedTrip =
          verify(mockTripRepository.updateTrip(captureAny)).captured.single
              as Trip;
      expect(capturedTrip.allowedCurrencies, newCurrencies);
      expect(capturedTrip.allowedCurrencies.length, 10);
    });
  });
}
