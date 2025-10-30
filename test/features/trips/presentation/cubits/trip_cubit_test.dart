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
@GenerateMocks([
  TripRepository,
  ActivityLoggerService,
  CategoryRepository,
  LocalStorageService,
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
    when(mockLocalStorageService.getJoinedTripIds()).thenReturn([]);
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
          baseCurrency: baseCurrency,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          participants: [creatorParticipant], // Creator should be added
        );

        when(
          mockTripRepository.createTrip(any),
        ).thenAnswer((_) async => createdTrip);
        when(
          mockCategoryRepository.seedDefaultCategories(any),
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
          baseCurrency: baseCurrency,
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
        baseCurrency: baseCurrency,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        participants: [creatorParticipant],
      );

      when(
        mockTripRepository.createTrip(any),
      ).thenAnswer((_) async => createdTrip);
      when(
        mockCategoryRepository.seedDefaultCategories(any),
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
        baseCurrency: baseCurrency,
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
        baseCurrency: baseCurrency,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        participants: [creatorParticipant],
      );

      when(
        mockTripRepository.createTrip(any),
      ).thenAnswer((_) async => createdTrip);
      when(
        mockCategoryRepository.seedDefaultCategories(any),
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
        baseCurrency: baseCurrency,
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
          baseCurrency: CurrencyCode.usd,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        Trip(
          id: 'trip-2',
          name: 'Joined Trip 2',
          baseCurrency: CurrencyCode.vnd,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      final allTrips = [
        ...joinedTrips,
        Trip(
          id: 'trip-3',
          name: 'Not Joined Trip',
          baseCurrency: CurrencyCode.usd,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      when(
        mockLocalStorageService.getJoinedTripIds(),
      ).thenReturn(['trip-1', 'trip-2']);
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
            baseCurrency: CurrencyCode.usd,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          Trip(
            id: 'trip-2',
            name: 'Trip 2',
            baseCurrency: CurrencyCode.vnd,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ];

        when(
          mockLocalStorageService.getJoinedTripIds(),
        ).thenReturn([]); // No joined trips
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
          baseCurrency: CurrencyCode.usd,
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
          baseCurrency: CurrencyCode.usd,
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
        when(mockLocalStorageService.getJoinedTripIds()).thenReturn([tripId]);
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
    test('should return true if trip ID is in joined trips cache', () {
      // Arrange
      const tripId = 'trip-999';
      when(
        mockLocalStorageService.getJoinedTripIds(),
      ).thenReturn([tripId, 'trip-888']);

      // Act
      final isMember = cubit.isUserMemberOf(tripId);

      // Assert
      expect(isMember, true);
    });

    test('should return false if trip ID is not in joined trips cache', () {
      // Arrange
      const tripId = 'trip-999';
      when(
        mockLocalStorageService.getJoinedTripIds(),
      ).thenReturn(['trip-888', 'trip-777']);

      // Act
      final isMember = cubit.isUserMemberOf(tripId);

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
          baseCurrency: CurrencyCode.usd,
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
          baseCurrency: CurrencyCode.usd,
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
          baseCurrency: CurrencyCode.usd,
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
        baseCurrency: CurrencyCode.usd,
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
}
