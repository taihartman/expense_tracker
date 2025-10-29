import '../models/trip_recovery_code.dart';

/// Repository interface for trip recovery codes
abstract class TripRecoveryCodeRepository {
  /// Generate and store a new recovery code for a trip
  ///
  /// Returns the generated recovery code.
  /// Throws an exception if a recovery code already exists for this trip.
  Future<TripRecoveryCode> generateRecoveryCode(String tripId);

  /// Get the recovery code for a trip
  ///
  /// Returns null if no recovery code exists for this trip.
  Future<TripRecoveryCode?> getRecoveryCode(String tripId);

  /// Validate a recovery code for a trip
  ///
  /// Returns the recovery code if valid, null otherwise.
  /// Increments the usage count if validation succeeds.
  Future<TripRecoveryCode?> validateRecoveryCode(String tripId, String code);

  /// Check if a trip has a recovery code
  Future<bool> hasRecoveryCode(String tripId);
}
