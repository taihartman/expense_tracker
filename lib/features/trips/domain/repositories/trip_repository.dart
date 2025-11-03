import '../../../../core/models/currency_code.dart';
import '../models/trip.dart';
import '../models/verified_member.dart';

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

  /// Add a verified member to a trip
  /// Called when a participant successfully joins via device pairing or recovery code
  /// Stores verification status in Firestore for cross-device visibility
  Future<void> addVerifiedMember({
    required String tripId,
    required String participantId,
    required String participantName,
  });

  /// Get all verified members for a trip
  /// Returns list of participants who have verified their identity
  /// Ordered by verifiedAt descending (most recent first)
  Future<List<VerifiedMember>> getVerifiedMembers(String tripId);

  /// Remove a verified member (for leaving trip functionality)
  /// Note: Not exposed in MVP UI
  Future<void> removeVerifiedMember({
    required String tripId,
    required String participantId,
  });

  /// Get allowed currencies for a trip
  /// Throws [TripNotFoundException] if trip doesn't exist
  /// Throws [DataIntegrityException] if trip has neither baseCurrency nor allowedCurrencies
  /// Returns allowedCurrencies if present, otherwise [baseCurrency] for legacy trips
  Future<List<CurrencyCode>> getAllowedCurrencies(String tripId);

  /// Update allowed currencies for a trip
  /// Validates: 1-10 currencies, no duplicates, trip exists
  /// Throws [ArgumentError] if validation fails
  /// Throws [TripNotFoundException] if trip doesn't exist
  Future<void> updateAllowedCurrencies(
    String tripId,
    List<CurrencyCode> currencies,
  );
}
