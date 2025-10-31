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

@GenerateMocks([
  TripRepository,
  ActivityLoggerService,
  CategoryRepository,
  LocalStorageService,
])
import 'trip_create_flow_test.mocks.dart';

/// T016: Integration test for create trip flow
///
/// This test verifies the complete flow of creating a private trip:
/// 1. User provides trip name, currency, and their name
/// 2. Trip is created with creator as first participant
/// 3. Activity log entry is created for trip creation
/// 4. Trip ID is cached in local storage
/// 5. Trip list is reloaded and filtered to joined trips
void main() {
  group('T016: Integration - Create Trip Flow', () {
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

      // Default stubs
      when(mockLocalStorageService.getJoinedTripIds()).thenReturn([]);
      when(mockLocalStorageService.getSelectedTripId()).thenReturn(null);
      when(
        mockLocalStorageService.addJoinedTrip(any),
      ).thenAnswer((_) async => {});

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

    test(
      'should complete full trip creation flow with all side effects',
      () async {
        // Arrange
        const tripName = 'Tokyo Adventure';
        const baseCurrency = CurrencyCode.usd;
        const creatorName = 'Alice';
        final creatorParticipant = Participant.fromName(creatorName);

        final createdTrip = Trip(
          id: 'trip-tokyo-123',
          name: tripName,
          baseCurrency: baseCurrency,
          createdAt: DateTime(2025, 10, 29, 10, 30),
          updatedAt: DateTime(2025, 10, 29, 10, 30),
          participants: [creatorParticipant],
        );

        // Mock repository responses
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
          mockTripRepository.getAllTrips(),
        ).thenAnswer((_) => Stream.value([createdTrip]));

        // Track state emissions
        final stateEmissions = <TripState>[];
        cubit.stream.listen(stateEmissions.add);

        // Act: Create the trip
        await cubit.createTrip(
          name: tripName,
          baseCurrency: baseCurrency,
          creatorName: creatorName,
        );

        // Wait for async operations
        await Future.delayed(const Duration(milliseconds: 150));

        // Assert: Verify complete flow

        // 1. Check trip was created with creator as participant
        final capturedTrip =
            verify(mockTripRepository.createTrip(captureAny)).captured.single
                as Trip;
        expect(capturedTrip.name, tripName);
        expect(capturedTrip.baseCurrency, baseCurrency);
        expect(capturedTrip.participants.length, 1);
        expect(capturedTrip.participants.first.name, creatorName);

        // 2. Check activity log was created
        verify(
          mockActivityLoggerService.logTripCreated(
            argThat(predicate((Trip t) => t.id == createdTrip.id)),
            creatorName,
          ),
        ).called(1);

        // 3. Check trip ID was cached in local storage
        verify(mockLocalStorageService.addJoinedTrip(createdTrip.id)).called(1);

        // 4. Check trips were reloaded
        verify(
          mockTripRepository.getAllTrips(),
        ).called(greaterThanOrEqualTo(1));

        // 5. Check state emissions
        expect(stateEmissions, [
          isA<TripCreating>(),
          isA<TripCreated>().having(
            (s) => s.trip.id,
            'trip.id',
            createdTrip.id,
          ),
          isA<TripLoading>(),
          isA<TripLoaded>().having((s) => s.trips.length, 'trips.length', 1),
        ]);

        // 6. Check final state has the created trip
        expect(cubit.state, isA<TripLoaded>());
        final finalState = cubit.state as TripLoaded;
        expect(finalState.trips, hasLength(1));
        expect(finalState.trips.first.id, createdTrip.id);
        expect(finalState.trips.first.participants.first.name, creatorName);
      },
    );

    test('should handle trip creation failure gracefully', () async {
      // Arrange
      const tripName = 'Failed Trip';
      const baseCurrency = CurrencyCode.usd;

      when(
        mockTripRepository.createTrip(any),
      ).thenThrow(Exception('Network error'));

      // Act
      await cubit.createTrip(name: tripName, baseCurrency: baseCurrency);

      // Assert
      expect(cubit.state, isA<TripError>());
      final errorState = cubit.state as TripError;
      expect(errorState.message, contains('Failed to create trip'));
      expect(errorState.message, contains('Network error'));

      // Verify no side effects occurred
      verifyNever(mockActivityLoggerService.logTripCreated(any, any));
      verifyNever(mockLocalStorageService.addJoinedTrip(any));
    });
  });
}
