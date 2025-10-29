import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/models/trip.dart';
import '../../domain/models/trip_recovery_code.dart';
import '../../domain/repositories/trip_repository.dart';
import '../../domain/repositories/activity_log_repository.dart';
import '../../domain/repositories/trip_recovery_code_repository.dart';
import '../../domain/models/activity_log.dart';
import '../../../categories/domain/repositories/category_repository.dart';
import 'trip_state.dart';
import '../../../../core/models/currency_code.dart';
import '../../../../core/models/participant.dart';
import '../../../../core/services/local_storage_service.dart';

/// Helper function to log with timestamps
void _log(String message) {
  debugPrint('[${DateTime.now().toIso8601String()}] [TripCubit] $message');
}

class TripCubit extends Cubit<TripState> {
  final TripRepository _tripRepository;
  final ActivityLogRepository? _activityLogRepository;
  final CategoryRepository? _categoryRepository;
  final TripRecoveryCodeRepository? _recoveryCodeRepository;
  final LocalStorageService _localStorageService;
  StreamSubscription<List<Trip>>? _tripsSubscription;

  /// Currently selected trip ID (persisted across state changes)
  String? _selectedTripId;

  TripCubit({
    required TripRepository tripRepository,
    required LocalStorageService localStorageService,
    ActivityLogRepository? activityLogRepository,
    CategoryRepository? categoryRepository,
    TripRecoveryCodeRepository? recoveryCodeRepository,
  }) : _tripRepository = tripRepository,
       _activityLogRepository = activityLogRepository,
       _categoryRepository = categoryRepository,
       _recoveryCodeRepository = recoveryCodeRepository,
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

          // Filter trips to only those the user has joined
          final joinedTripIds = _localStorageService.getJoinedTripIds();
          _log(
            '🔍 User has joined ${joinedTripIds.length} trips: $joinedTripIds',
          );

          // Only show trips the user has explicitly joined or created
          final filteredTrips = trips
              .where((trip) => joinedTripIds.contains(trip.id))
              .toList();

          // Separate active and archived trips
          final activeTrips = filteredTrips
              .where((trip) => !trip.isArchived)
              .toList();
          final archivedTrips = filteredTrips
              .where((trip) => trip.isArchived)
              .toList();

          _log(
            '📦 Filtered to ${activeTrips.length} active trips, ${archivedTrips.length} archived trips',
          );

          // Only emit if cubit is not closed
          if (!isClosed) {
            // Try to restore the selected trip using persisted ID
            Trip? selectedTrip;

            _log('🔍 Trip restoration logic:');
            _log('  - Active trips: ${activeTrips.length}');
            _log('  - Archived trips: ${archivedTrips.length}');
            _log('  - Saved trip ID in memory: ${_selectedTripId ?? "null"}');

            // Log all trip IDs for debugging
            for (var trip in activeTrips) {
              _log('  - Active trip: ${trip.name} (ID: ${trip.id})');
            }
            for (var trip in archivedTrips) {
              _log('  - Archived trip: ${trip.name} (ID: ${trip.id})');
            }

            if (_selectedTripId != null) {
              _log('🔎 Attempting to restore trip with ID: $_selectedTripId');
              // Try to find the trip with the persisted ID (can be active or archived)
              selectedTrip = filteredTrips
                  .where((t) => t.id == _selectedTripId)
                  .firstOrNull;

              if (selectedTrip != null) {
                _log(
                  '✅ Restored selected trip from storage: ${selectedTrip.name} (ID: ${selectedTrip.id}, archived: ${selectedTrip.isArchived})',
                );
              } else {
                _log(
                  '⚠️ Saved trip ID $_selectedTripId not found in filtered trips list',
                );
                _log('⚠️ Clearing invalid trip ID from storage');
                _selectedTripId = null;
                await _localStorageService.clearSelectedTripId();
              }
            } else {
              _log('ℹ️ No saved trip ID found in storage');
            }

            // If no trip selected and active trips exist, select the first active one
            if (selectedTrip == null && activeTrips.isNotEmpty) {
              selectedTrip = activeTrips.first;
              _selectedTripId = selectedTrip.id;
              _log(
                '🎯 Auto-selecting first active trip: ${selectedTrip.name} (ID: ${selectedTrip.id})',
              );
              await _localStorageService.saveSelectedTripId(selectedTrip.id);
              _log('💾 Auto-selected trip saved to storage');
            }

            emit(
              TripLoaded(
                trips: activeTrips,
                archivedTrips: archivedTrips,
                selectedTrip: selectedTrip,
              ),
            );
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
    String? creatorName,
  }) async {
    try {
      _log('🆕 Creating trip: $name with base currency: ${baseCurrency.name}');
      _log('👤 Creator name: ${creatorName ?? "none"}');
      emit(const TripCreating());

      // Add creator as first participant if provided
      final participants = creatorName != null && creatorName.isNotEmpty
          ? [Participant.fromName(creatorName)]
          : <Participant>[];

      final trip = Trip(
        id: '', // Firestore will generate this
        name: name,
        baseCurrency: baseCurrency,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        participants: participants,
      );

      final createdTrip = await _tripRepository.createTrip(trip);
      _log('✅ Trip created with ID: ${createdTrip.id}');

      // Cache trip ID in local storage (user has joined this trip)
      _log('💾 Caching trip ID in local storage...');
      await _localStorageService.addJoinedTrip(createdTrip.id);
      _log('✅ Trip ID cached');

      // Generate recovery code for the new trip
      if (_recoveryCodeRepository != null) {
        _log('🔑 Generating recovery code for trip ${createdTrip.id}...');
        try {
          final recoveryCode = await _recoveryCodeRepository
              .generateRecoveryCode(createdTrip.id);
          _log('✅ Recovery code generated: ${recoveryCode.code}');
          _log('   Code details: tripId=${recoveryCode.tripId}, usedCount=${recoveryCode.usedCount}, createdAt=${recoveryCode.createdAt}');
        } catch (e, stackTrace) {
          _log('❌ Failed to generate recovery code (non-fatal): $e');
          _log('   Stack trace: ${stackTrace.toString().split('\n').take(3).join('\n   ')}');
          // Don't fail trip creation if recovery code generation fails
          // User can manually generate recovery code later from trip settings
        }
      } else {
        _log(
          '⚠️ RecoveryCodeRepository not provided, skipping recovery code generation',
        );
      }

      // Log trip creation activity if repository is available
      if (_activityLogRepository != null &&
          creatorName != null &&
          creatorName.isNotEmpty) {
        _log('📝 Logging trip_created activity...');
        try {
          final activityLog = ActivityLog(
            id: '', // Firestore will generate this
            tripId: createdTrip.id,
            type: ActivityType.tripCreated,
            actorName: creatorName,
            description: 'Created trip "$name"',
            timestamp: DateTime.now(),
          );
          await _activityLogRepository.addLog(activityLog);
          _log('✅ Activity logged');
        } catch (e) {
          _log('⚠️ Failed to log activity (non-fatal): $e');
          // Don't fail trip creation if activity logging fails
        }
      } else {
        _log(
          '⚠️ ActivityLogRepository not provided or no creator name, skipping activity logging',
        );
      }

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

      // Auto-select the newly created trip
      _selectedTripId = createdTrip.id;
      await _localStorageService.saveSelectedTripId(createdTrip.id);
      _log('🎯 Auto-selected newly created trip: ${createdTrip.name}');

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

  /// Archive a trip (hide from active trip list)
  Future<void> archiveTrip(String tripId) async {
    try {
      _log('📦 Archiving trip: $tripId');

      // Get the current trip
      final currentTrip = await _tripRepository.getTripById(tripId);
      if (currentTrip == null) {
        throw Exception('Trip not found');
      }

      // Check if we're archiving the currently selected trip
      final isCurrentlySelected = _selectedTripId == tripId;

      // Create updated trip with archived flag
      final updatedTrip = currentTrip.copyWith(
        isArchived: true,
        updatedAt: DateTime.now(),
      );

      await _tripRepository.updateTrip(updatedTrip);
      _log('✅ Trip archived successfully');

      // If archiving current trip, clear selection
      if (isCurrentlySelected) {
        _selectedTripId = null;
        await _localStorageService.clearSelectedTripId();
        _log('🔄 Cleared archived trip selection - will auto-select first active trip');
      }

      // Reload trips to refresh the list (will auto-select if needed)
      await loadTrips();
    } catch (e) {
      _log('❌ Failed to archive trip: $e');
      emit(TripError('Failed to archive trip: ${e.toString()}'));
    }
  }

  /// Unarchive a trip (restore to active trip list)
  Future<void> unarchiveTrip(String tripId) async {
    try {
      _log('📤 Unarchiving trip: $tripId');

      // Get the current trip
      final currentTrip = await _tripRepository.getTripById(tripId);
      if (currentTrip == null) {
        throw Exception('Trip not found');
      }

      // Create updated trip with archived flag cleared
      final updatedTrip = currentTrip.copyWith(
        isArchived: false,
        updatedAt: DateTime.now(),
      );

      await _tripRepository.updateTrip(updatedTrip);
      _log('✅ Trip unarchived successfully');

      // Reload trips to refresh the list
      await loadTrips();
    } catch (e) {
      _log('❌ Failed to unarchive trip: $e');
      emit(TripError('Failed to unarchive trip: ${e.toString()}'));
    }
  }

  /// Leave a trip (remove from local storage, user will need to rejoin)
  Future<void> leaveTrip(String tripId) async {
    try {
      _log('🚪 Leaving trip: $tripId');

      // Remove trip from joined trips list
      await _localStorageService.removeJoinedTrip(tripId);
      _log('✅ Trip removed from joined trips list');

      // If left trip was selected, clear selection
      if (_selectedTripId == tripId) {
        _selectedTripId = null;
        await _localStorageService.clearSelectedTripId();
        _log('🗑️ Cleared selected trip from storage (trip left)');
      }

      // Clear user identity for this trip
      await _localStorageService.removeUserIdentityForTrip(tripId);
      _log('👤 Cleared user identity for trip');

      // Reload trips to refresh the list (will filter out the left trip)
      await loadTrips();
      _log('✅ Successfully left trip');
    } catch (e) {
      _log('❌ Failed to leave trip: $e');
      emit(TripError('Failed to leave trip: ${e.toString()}'));
    }
  }

  /// Join an existing trip by trip ID
  Future<void> joinTrip({
    required String tripId,
    required String userName,
  }) async {
    try {
      _log('👥 Joining trip: $tripId as $userName');
      emit(const TripJoining());

      // Get the trip
      final trip = await _tripRepository.getTripById(tripId);

      if (trip == null) {
        _log('❌ Trip not found: $tripId');
        emit(const TripError('Trip not found'));
        return;
      }

      _log('✅ Trip found: ${trip.name}');

      // Check if user is already a member
      final userParticipant = Participant.fromName(userName);
      final isAlreadyMember = trip.participants.any(
        (p) => p.id == userParticipant.id,
      );

      if (isAlreadyMember) {
        _log('ℹ️ User already a member of trip');
        // Still cache the trip ID and reload (idempotent)
        await _localStorageService.addJoinedTrip(tripId);
        _log('💾 Trip ID cached (idempotent)');

        // Save user identity for this trip (idempotent)
        await _localStorageService.saveUserIdentityForTrip(
          tripId,
          userParticipant.id,
        );
        _log('👤 User identity saved: ${userParticipant.id}');

        emit(TripJoined(trip));
        await loadTrips();
        return;
      }

      // Add user as participant
      final updatedTrip = trip.copyWith(
        participants: [...trip.participants, userParticipant],
      );

      _log('➕ Adding user as participant...');
      await _tripRepository.updateTrip(updatedTrip);
      _log('✅ User added to trip');

      // Log activity
      if (_activityLogRepository != null) {
        _log('📝 Logging member_joined activity...');
        try {
          final activityLog = ActivityLog(
            id: '', // Firestore will generate this
            tripId: tripId,
            type: ActivityType.memberJoined,
            actorName: userName,
            description: '$userName joined the trip',
            timestamp: DateTime.now(),
          );
          await _activityLogRepository.addLog(activityLog);
          _log('✅ Activity logged');
        } catch (e) {
          _log('⚠️ Failed to log activity (non-fatal): $e');
        }
      }

      // Cache trip ID in local storage
      _log('💾 Caching trip ID in local storage...');
      await _localStorageService.addJoinedTrip(tripId);
      _log('✅ Trip ID cached');

      // Save user identity for this trip
      _log('👤 Saving user identity for trip...');
      await _localStorageService.saveUserIdentityForTrip(
        tripId,
        userParticipant.id,
      );
      _log('✅ User identity saved: ${userParticipant.id}');

      // Auto-select the newly joined trip
      _log('🎯 Auto-selecting newly joined trip...');
      _selectedTripId = tripId;
      await _localStorageService.saveSelectedTripId(tripId);
      _log('✅ Newly joined trip set as selected');

      emit(TripJoined(updatedTrip));

      // Reload trips to update the list
      await loadTrips();
    } catch (e) {
      _log('❌ Failed to join trip: $e');
      emit(TripError('Failed to join trip: ${e.toString()}'));
    }
  }

  /// Check if a member name already exists in a trip (case-insensitive).
  ///
  /// Used for duplicate detection during device pairing.
  /// Returns true if a participant with the given name already exists.
  Future<bool> hasDuplicateMember(String tripId, String memberName) async {
    try {
      final trip = await _tripRepository.getTripById(tripId);

      if (trip == null) {
        return false;
      }

      // Case-insensitive comparison
      final lowerName = memberName.toLowerCase();
      return trip.participants.any(
        (participant) => participant.name.toLowerCase() == lowerName,
      );
    } catch (e) {
      _log('❌ Error checking duplicate member: $e');
      return false;
    }
  }

  /// Check if the user is a member of a trip (checks local cache)
  bool isUserMemberOf(String tripId) {
    final joinedTripIds = _localStorageService.getJoinedTripIds();
    return joinedTripIds.contains(tripId);
  }

  /// Get a trip by ID from Firestore (does not modify local state)
  ///
  /// Used for trip join flow to fetch trip details before joining.
  /// Returns null if trip doesn't exist.
  Future<Trip?> getTripById(String tripId) async {
    try {
      _log('🔍 Fetching trip by ID: $tripId');
      final trip = await _tripRepository.getTripById(tripId);
      if (trip != null) {
        _log('✅ Trip found: ${trip.name}');
      } else {
        _log('❌ Trip not found: $tripId');
      }
      return trip;
    } catch (e) {
      _log('❌ Error fetching trip: $e');
      return null;
    }
  }

  // =========================================================================
  // Recovery Code Methods
  // =========================================================================

  /// Generate a recovery code for a trip
  ///
  /// Returns the generated recovery code string.
  /// Throws an exception if a recovery code already exists or if repository is not available.
  Future<String> generateRecoveryCode(String tripId) async {
    if (_recoveryCodeRepository == null) {
      throw Exception('Recovery code repository not available');
    }

    _log('🔐 Generating recovery code for trip: $tripId');
    final recoveryCode = await _recoveryCodeRepository.generateRecoveryCode(
      tripId,
    );
    _log('✅ Recovery code generated: ${recoveryCode.code}');
    return recoveryCode.code;
  }

  /// Get the recovery code for a trip
  ///
  /// Returns the recovery code if it exists, null otherwise.
  Future<TripRecoveryCode?> getRecoveryCode(String tripId) async {
    if (_recoveryCodeRepository == null) {
      _log('⚠️ Recovery code repository not available');
      return null;
    }

    _log('🔍 Getting recovery code for trip: $tripId');
    return await _recoveryCodeRepository.getRecoveryCode(tripId);
  }

  /// Check if a trip has a recovery code
  Future<bool> hasRecoveryCode(String tripId) async {
    if (_recoveryCodeRepository == null) {
      return false;
    }

    return await _recoveryCodeRepository.hasRecoveryCode(tripId);
  }

  /// Validate recovery code and join trip
  ///
  /// Validates the recovery code, then joins the trip bypassing device verification.
  /// Returns true if successful, false otherwise.
  Future<bool> validateAndJoinWithRecoveryCode({
    required String tripId,
    required String code,
    required String userName,
  }) async {
    if (_recoveryCodeRepository == null) {
      _log('❌ Recovery code repository not available');
      emit(const TripError('Recovery code feature not available'));
      return false;
    }

    _log('🔐 Validating recovery code for trip: $tripId, user: $userName');

    try {
      // Validate recovery code
      final recoveryCode = await _recoveryCodeRepository.validateRecoveryCode(
        tripId,
        code,
      );

      if (recoveryCode == null) {
        _log('❌ Invalid recovery code');
        emit(const TripError('Invalid recovery code'));
        return false;
      }

      _log('✅ Recovery code validated, joining trip...');

      // Join trip (bypassing verification since recovery code is valid)
      await joinTrip(tripId: tripId, userName: userName);

      return true;
    } catch (e) {
      _log('❌ Error validating recovery code: $e');
      emit(TripError('Failed to validate recovery code: ${e.toString()}'));
      return false;
    }
  }

  /// Get the current user's participant for a specific trip.
  ///
  /// This retrieves the participant identity that was selected/stored when
  /// the user joined the trip. Returns null if:
  /// - The user hasn't joined this trip yet
  /// - The user hasn't selected their identity for this trip
  /// - The trip doesn't exist in the loaded trips
  ///
  /// This is used for proper attribution of actions in activity logs.
  Participant? getCurrentUserForTrip(String tripId) {
    _log('👤 Getting current user for trip $tripId');

    // Get the stored participant ID for this trip
    final participantId = _localStorageService.getUserIdentityForTrip(tripId);

    if (participantId == null) {
      _log('⚠️ No user identity found for trip $tripId');
      return null;
    }

    _log('🔍 User identity: $participantId');

    // Find the trip in the current state
    final currentState = state;
    List<Trip>? trips;

    if (currentState is TripLoaded) {
      trips = currentState.trips;
    } else {
      _log('⚠️ State is not TripLoaded, cannot retrieve trip');
      return null;
    }

    // Find the specific trip
    final trip = trips.cast<Trip?>().firstWhere(
      (t) => t?.id == tripId,
      orElse: () => null,
    );

    if (trip == null) {
      _log('⚠️ Trip $tripId not found in loaded trips');
      return null;
    }

    // Find the participant in the trip
    final participant = trip.participants.cast<Participant?>().firstWhere(
      (p) => p?.id == participantId,
      orElse: () => null,
    );

    if (participant == null) {
      _log('⚠️ Participant $participantId not found in trip ${trip.name}');
      return null;
    }

    _log('✅ Found current user: ${participant.name} (${participant.id})');
    return participant;
  }

  @override
  Future<void> close() {
    _log('🔴 Closing TripCubit - cancelling stream subscription');
    _tripsSubscription?.cancel();
    return super.close();
  }
}
