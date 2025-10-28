import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/models/trip.dart';
import '../../domain/repositories/trip_repository.dart';
import '../../../categories/domain/repositories/category_repository.dart';
import 'trip_state.dart';
import '../../../../core/models/currency_code.dart';
import '../../../../core/services/local_storage_service.dart';

/// Helper function to log with timestamps
void _log(String message) {
  debugPrint('[${DateTime.now().toIso8601String()}] [TripCubit] $message');
}

class TripCubit extends Cubit<TripState> {
  final TripRepository _tripRepository;
  final CategoryRepository? _categoryRepository;
  final LocalStorageService _localStorageService;
  StreamSubscription<List<Trip>>? _tripsSubscription;

  /// Currently selected trip ID (persisted across state changes)
  String? _selectedTripId;

  TripCubit({
    required TripRepository tripRepository,
    required LocalStorageService localStorageService,
    CategoryRepository? categoryRepository,
  }) : _tripRepository = tripRepository,
       _categoryRepository = categoryRepository,
       _localStorageService = localStorageService,
       super(const TripInitial()) {
    // Load saved selected trip ID from storage
    _log('🔄 TripCubit constructor called - loading saved trip ID...');
    _selectedTripId = _localStorageService.getSelectedTripId();
    _log(
      '🔄 Initialized with saved trip ID: ${_selectedTripId ?? "null (no saved trip)"}',
    );
  }

  /// Load all trips for the user
  Future<void> loadTrips() async {
    try {
      _log('📥 loadTrips() started');
      final loadStart = DateTime.now();

      // Cancel existing subscription if any
      await _tripsSubscription?.cancel();

      emit(const TripLoading());
      _log('✅ Emitted TripLoading state');

      _log('🔍 Calling repository.getAllTrips()...');
      final repoStart = DateTime.now();
      final tripsStream = _tripRepository.getAllTrips();
      _log(
        '✅ Got trips stream (${DateTime.now().difference(repoStart).inMilliseconds}ms)',
      );

      _log('⏳ Waiting for first stream emission...');
      final streamStart = DateTime.now();

      // Use listen instead of await for to properly manage subscription
      _tripsSubscription = tripsStream.listen(
        (trips) async {
          _log(
            '📦 Received ${trips.length} trips from stream (${DateTime.now().difference(streamStart).inMilliseconds}ms)',
          );

          // Only emit if cubit is not closed
          if (!isClosed) {
            // Try to restore the selected trip using persisted ID
            Trip? selectedTrip;

            _log('🔍 Trip restoration logic:');
            _log('  - Received ${trips.length} trips');
            _log('  - Saved trip ID in memory: ${_selectedTripId ?? "null"}');

            // Log all trip IDs for debugging
            for (var trip in trips) {
              _log('  - Available trip: ${trip.name} (ID: ${trip.id})');
            }

            if (_selectedTripId != null) {
              _log('🔎 Attempting to restore trip with ID: $_selectedTripId');
              // Try to find the trip with the persisted ID
              selectedTrip = trips
                  .where((t) => t.id == _selectedTripId)
                  .firstOrNull;

              if (selectedTrip != null) {
                _log(
                  '✅ Restored selected trip from storage: ${selectedTrip.name} (ID: ${selectedTrip.id})',
                );
              } else {
                _log(
                  '⚠️ Saved trip ID $_selectedTripId not found in trips list',
                );
                _log('⚠️ Clearing invalid trip ID from storage');
                _selectedTripId = null;
                await _localStorageService.clearSelectedTripId();
              }
            } else {
              _log('ℹ️ No saved trip ID found in storage');
            }

            // If no trip selected and trips exist, select the first one
            if (selectedTrip == null && trips.isNotEmpty) {
              selectedTrip = trips.first;
              _selectedTripId = selectedTrip.id;
              _log(
                '🎯 Auto-selecting first trip: ${selectedTrip.name} (ID: ${selectedTrip.id})',
              );
              await _localStorageService.saveSelectedTripId(selectedTrip.id);
              _log('💾 Auto-selected trip saved to storage');
            }

            emit(TripLoaded(trips: trips, selectedTrip: selectedTrip));
            _log(
              '✅ Emitted TripLoaded state with selected trip: ${selectedTrip?.name ?? "none"} (total time: ${DateTime.now().difference(loadStart).inMilliseconds}ms)',
            );
          } else {
            _log('⚠️ Cubit closed, skipping emit');
          }
        },
        onError: (error) {
          _log('❌ Stream error: $error');
          if (!isClosed) {
            emit(TripError('Failed to load trips: ${error.toString()}'));
          }
        },
      );
    } catch (e) {
      _log('❌ Error loading trips: $e');
      if (!isClosed) {
        emit(TripError('Failed to load trips: ${e.toString()}'));
      }
    }
  }

  /// Create a new trip
  Future<void> createTrip({
    required String name,
    required CurrencyCode baseCurrency,
  }) async {
    try {
      _log('🆕 Creating trip: $name with base currency: ${baseCurrency.name}');
      emit(const TripCreating());

      final trip = Trip(
        id: '', // Firestore will generate this
        name: name,
        baseCurrency: baseCurrency,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final createdTrip = await _tripRepository.createTrip(trip);
      _log('✅ Trip created with ID: ${createdTrip.id}');

      // Seed default categories for the new trip
      if (_categoryRepository != null) {
        _log('🌱 Seeding default categories for trip ${createdTrip.id}...');
        try {
          final categories = await _categoryRepository.seedDefaultCategories(
            createdTrip.id,
          );
          _log('✅ Seeded ${categories.length} default categories');
        } catch (e) {
          _log('⚠️ Failed to seed categories (non-fatal): $e');
          // Don't fail trip creation if category seeding fails
        }
      } else {
        _log('⚠️ CategoryRepository not provided, skipping category seeding');
      }

      emit(TripCreated(createdTrip));

      // Reload trips to update the list
      await loadTrips();
    } catch (e) {
      _log('❌ Failed to create trip: $e');
      emit(TripError('Failed to create trip: ${e.toString()}'));
    }
  }

  /// Select a trip
  Future<void> selectTrip(Trip trip) async {
    _log('👆 User selected trip: ${trip.name} (ID: ${trip.id})');
    if (state is TripLoaded) {
      final currentState = state as TripLoaded;
      _selectedTripId = trip.id;
      _log('💾 Saving trip ID to storage...');
      await _localStorageService.saveSelectedTripId(trip.id);
      _log('✅ Trip selection complete - emitting new state');
      emit(currentState.copyWith(selectedTrip: trip));
    } else {
      _log(
        '⚠️ Cannot select trip - state is not TripLoaded (current state: ${state.runtimeType})',
      );
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

  /// Update trip details (name and base currency)
  Future<void> updateTripDetails({
    required String tripId,
    required String name,
    required CurrencyCode baseCurrency,
  }) async {
    try {
      _log(
        '✏️ Updating trip $tripId: name="$name", baseCurrency=${baseCurrency.name}',
      );

      // Get the current trip to preserve other fields
      final currentTrip = await _tripRepository.getTripById(tripId);
      if (currentTrip == null) {
        throw Exception('Trip not found');
      }

      // Create updated trip with new details
      final updatedTrip = currentTrip.copyWith(
        name: name,
        baseCurrency: baseCurrency,
      );

      // Use existing updateTrip method
      await updateTrip(updatedTrip);
      _log('✅ Trip details updated successfully');
    } catch (e) {
      _log('❌ Failed to update trip details: $e');
      emit(TripError('Failed to update trip: ${e.toString()}'));
    }
  }

  /// Delete a trip
  Future<void> deleteTrip(String tripId) async {
    try {
      await _tripRepository.deleteTrip(tripId);

      // If deleted trip was selected, clear selection
      if (_selectedTripId == tripId) {
        _selectedTripId = null;
        await _localStorageService.clearSelectedTripId();
        _log('🗑️ Cleared selected trip from storage (trip deleted)');
      }

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

  @override
  Future<void> close() {
    _log('🔴 Closing TripCubit - cancelling stream subscription');
    _tripsSubscription?.cancel();
    return super.close();
  }
}
