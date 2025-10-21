import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/models/trip.dart';
import '../../domain/repositories/trip_repository.dart';
import 'trip_state.dart';
import '../../../../core/models/currency_code.dart';

class TripCubit extends Cubit<TripState> {
  final TripRepository _tripRepository;

  TripCubit({required TripRepository tripRepository})
      : _tripRepository = tripRepository,
        super(const TripInitial());

  /// Load all trips for the user
  Future<void> loadTrips() async {
    try {
      emit(const TripLoading());

      final tripsStream = _tripRepository.getAllTrips();

      await for (final trips in tripsStream) {
        // Get currently selected trip if any
        Trip? selectedTrip;
        if (state is TripLoaded) {
          selectedTrip = (state as TripLoaded).selectedTrip;

          // Verify selected trip still exists in the list
          if (selectedTrip != null) {
            final stillExists = trips.any((t) => t.id == selectedTrip!.id);
            if (!stillExists) {
              selectedTrip = null;
            }
          }
        }

        // If no trip selected and trips exist, select the first one
        if (selectedTrip == null && trips.isNotEmpty) {
          selectedTrip = trips.first;
        }

        emit(TripLoaded(
          trips: trips,
          selectedTrip: selectedTrip,
        ));
      }
    } catch (e) {
      emit(TripError('Failed to load trips: ${e.toString()}'));
    }
  }

  /// Create a new trip
  Future<void> createTrip({
    required String name,
    required CurrencyCode baseCurrency,
  }) async {
    try {
      emit(const TripCreating());

      final trip = Trip(
        id: '', // Firestore will generate this
        name: name,
        baseCurrency: baseCurrency,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final createdTrip = await _tripRepository.createTrip(trip);

      emit(TripCreated(createdTrip));

      // Reload trips to update the list
      await loadTrips();
    } catch (e) {
      emit(TripError('Failed to create trip: ${e.toString()}'));
    }
  }

  /// Select a trip
  void selectTrip(Trip trip) {
    if (state is TripLoaded) {
      final currentState = state as TripLoaded;
      emit(currentState.copyWith(selectedTrip: trip));
    }
  }

  /// Get the currently selected trip
  Trip? get selectedTrip {
    if (state is TripLoaded) {
      return (state as TripLoaded).selectedTrip;
    }
    return null;
  }

  /// Get all trips
  List<Trip> get trips {
    if (state is TripLoaded) {
      return (state as TripLoaded).trips;
    }
    return [];
  }

  /// Update a trip
  Future<void> updateTrip(Trip trip) async {
    try {
      await _tripRepository.updateTrip(trip);

      // Update the selected trip if it matches
      if (state is TripLoaded) {
        final currentState = state as TripLoaded;
        if (currentState.selectedTrip?.id == trip.id) {
          emit(currentState.copyWith(selectedTrip: trip));
        }
      }

      // Reload trips to refresh the list
      await loadTrips();
    } catch (e) {
      emit(TripError('Failed to update trip: ${e.toString()}'));
    }
  }

  /// Delete a trip
  Future<void> deleteTrip(String tripId) async {
    try {
      await _tripRepository.deleteTrip(tripId);

      // If deleted trip was selected, clear selection
      if (state is TripLoaded) {
        final currentState = state as TripLoaded;
        if (currentState.selectedTrip?.id == tripId) {
          emit(currentState.copyWith(selectedTrip: null));
        }
      }

      // Reload trips to refresh the list
      await loadTrips();
    } catch (e) {
      emit(TripError('Failed to delete trip: ${e.toString()}'));
    }
  }
}
