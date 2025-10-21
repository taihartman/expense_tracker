import '../models/trip.dart';

/// Repository interface for Trip operations
///
/// Defines the contract for trip data access
/// Implementation uses Firestore (see data/repositories/trip_repository_impl.dart)
abstract class TripRepository {
  /// Create a new trip
  /// Returns the created trip with generated ID
  Future<Trip> createTrip(Trip trip);

  /// Get a trip by ID
  /// Returns null if trip doesn't exist
  Future<Trip?> getTripById(String tripId);

  /// Get all trips
  /// Returns list ordered by createdAt descending (newest first)
  Stream<List<Trip>> getAllTrips();

  /// Update an existing trip
  /// Returns the updated trip
  Future<Trip> updateTrip(Trip trip);

  /// Delete a trip by ID
  /// Note: In MVP, deletion is not exposed in UI
  Future<void> deleteTrip(String tripId);

  /// Check if a trip exists
  Future<bool> tripExists(String tripId);
}
