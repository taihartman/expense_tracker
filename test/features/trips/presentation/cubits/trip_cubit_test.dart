import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:expense_tracker/features/trips/domain/models/trip.dart';
import 'package:expense_tracker/features/trips/domain/repositories/trip_repository.dart';
import 'package:expense_tracker/features/trips/domain/repositories/activity_log_repository.dart';
import 'package:expense_tracker/features/trips/domain/models/activity_log.dart';
import 'package:expense_tracker/features/categories/domain/repositories/category_repository.dart';
import 'package:expense_tracker/core/services/local_storage_service.dart';
import 'package:expense_tracker/core/models/currency_code.dart';
import 'package:expense_tracker/features/trips/presentation/cubits/trip_cubit.dart';
import 'package:expense_tracker/features/trips/presentation/cubits/trip_state.dart';

// Generate mocks
@GenerateMocks([
  TripRepository,
  ActivityLogRepository,
  CategoryRepository,
  LocalStorageService,
])
import 'trip_cubit_test.mocks.dart';

void main() {
  late TripCubit cubit;
  late MockTripRepository mockTripRepository;
  late MockActivityLogRepository mockActivityLogRepository;
  late MockCategoryRepository mockCategoryRepository;
  late MockLocalStorageService mockLocalStorageService;

  setUp(() {
    mockTripRepository = MockTripRepository();
    mockActivityLogRepository = MockActivityLogRepository();
    mockCategoryRepository = MockCategoryRepository();
    mockLocalStorageService = MockLocalStorageService();

    // Default stub: return empty list for getJoinedTripIds
    when(mockLocalStorageService.getJoinedTripIds()).thenReturn([]);
    when(mockLocalStorageService.getSelectedTripId()).thenReturn(null);

    cubit = TripCubit(
      tripRepository: mockTripRepository,
      localStorageService: mockLocalStorageService,
      categoryRepository: mockCategoryRepository,
    );
  });

  tearDown(() {
    cubit.close();
  });

  group('T012: TripCubit.createTrip adds creator as participant', () {
    test('should add creator name to trip participants when creating trip', () async {
      // Arrange
      const tripName = 'Test Trip';
      const baseCurrency = CurrencyCode.usd;
      const creatorName = 'Alice';
      
      final createdTrip = Trip(
        id: 'trip-123',
        name: tripName,
        baseCurrency: baseCurrency,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        participants: const ['Alice'], // Creator should be added
      );

      when(mockTripRepository.createTrip(any)).thenAnswer((_) async => createdTrip);
      when(mockCategoryRepository.seedDefaultCategories(any)).thenAnswer((_) async => []);
      when(mockActivityLogRepository.addLog(any)).thenAnswer((_) async => 'log-123');
      when(mockTripRepository.getAllTrips()).thenAnswer((_) => Stream.value([createdTrip]));
      
      // Act
      await cubit.createTrip(
        name: tripName,
        baseCurrency: baseCurrency,
        creatorName: creatorName,
      );

      // Assert
      final capturedTrip = verify(mockTripRepository.createTrip(captureAny)).captured.single as Trip;
      expect(capturedTrip.participants, contains(creatorName));
      expect(capturedTrip.participants.length, 1);
    });
  });

  group('T013: TripCubit.createTrip logs trip_created activity', () {
    test('should log activity when trip is created', () async {
      // Arrange
      const tripName = 'Test Trip';
      const baseCurrency = CurrencyCode.usd;
      const creatorName = 'Alice';
      
      final createdTrip = Trip(
        id: 'trip-123',
        name: tripName,
        baseCurrency: baseCurrency,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        participants: const ['Alice'],
      );

      when(mockTripRepository.createTrip(any)).thenAnswer((_) async => createdTrip);
      when(mockCategoryRepository.seedDefaultCategories(any)).thenAnswer((_) async => []);
      when(mockActivityLogRepository.addLog(any)).thenAnswer((_) async => 'log-123');
      when(mockTripRepository.getAllTrips()).thenAnswer((_) => Stream.value([createdTrip]));
      
      // Act
      await cubit.createTrip(
        name: tripName,
        baseCurrency: baseCurrency,
        creatorName: creatorName,
      );

      // Assert
      final capturedLog = verify(mockActivityLogRepository.addLog(captureAny)).captured.single as ActivityLog;
      expect(capturedLog.type, ActivityType.tripCreated);
      expect(capturedLog.actorName, creatorName);
      expect(capturedLog.tripId, createdTrip.id);
      expect(capturedLog.description, contains(tripName));
    });
  });

  group('T014: TripCubit.createTrip caches joined trip ID', () {
    test('should cache trip ID in local storage after creation', () async {
      // Arrange
      const tripName = 'Test Trip';
      const baseCurrency = CurrencyCode.usd;
      const creatorName = 'Alice';
      
      final createdTrip = Trip(
        id: 'trip-123',
        name: tripName,
        baseCurrency: baseCurrency,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        participants: const ['Alice'],
      );

      when(mockTripRepository.createTrip(any)).thenAnswer((_) async => createdTrip);
      when(mockCategoryRepository.seedDefaultCategories(any)).thenAnswer((_) async => []);
      when(mockActivityLogRepository.addLog(any)).thenAnswer((_) async => 'log-123');
      when(mockLocalStorageService.addJoinedTrip(any)).thenAnswer((_) async => {});
      when(mockTripRepository.getAllTrips()).thenAnswer((_) => Stream.value([createdTrip]));
      
      // Act
      await cubit.createTrip(
        name: tripName,
        baseCurrency: baseCurrency,
        creatorName: creatorName,
      );

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

      when(mockLocalStorageService.getJoinedTripIds()).thenReturn(['trip-1', 'trip-2']);
      when(mockTripRepository.getAllTrips()).thenAnswer((_) => Stream.value(allTrips));
      
      // Act
      await cubit.loadTrips();
      
      // Wait for stream to process
      await Future.delayed(const Duration(milliseconds: 100));

      // Assert
      expect(cubit.state, isA<TripLoaded>());
      final loadedState = cubit.state as TripLoaded;
      expect(loadedState.trips.length, 2);
      expect(loadedState.trips.map((t) => t.id), containsAll(['trip-1', 'trip-2']));
      expect(loadedState.trips.map((t) => t.id), isNot(contains('trip-3')));
    });

    test('should show all trips if user has not joined any trips (backward compatibility)', () async {
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

      when(mockLocalStorageService.getJoinedTripIds()).thenReturn([]); // No joined trips
      when(mockTripRepository.getAllTrips()).thenAnswer((_) => Stream.value(allTrips));
      
      // Act
      await cubit.loadTrips();
      
      // Wait for stream to process
      await Future.delayed(const Duration(milliseconds: 100));

      // Assert
      expect(cubit.state, isA<TripLoaded>());
      final loadedState = cubit.state as TripLoaded;
      expect(loadedState.trips.length, 2); // Shows all trips for backward compatibility
    });
  });
}
