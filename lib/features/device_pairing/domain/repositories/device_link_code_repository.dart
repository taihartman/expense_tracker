import '../models/device_link_code.dart';

/// Repository interface for device link code operations.
///
/// Defines the contract for generating, validating, and managing
/// temporary device pairing codes.
abstract class DeviceLinkCodeRepository {
  /// Generates a new device link code for the specified member.
  ///
  /// Creates a cryptographically secure 8-digit code that expires in 15 minutes.
  /// Invalidates any previous active codes for the same member.
  ///
  /// Parameters:
  /// - [tripId]: The trip this code grants access to
  /// - [memberName]: The member name this code is generated FOR
  ///
  /// Returns the generated [DeviceLinkCode].
  ///
  /// Throws:
  /// - [Exception] if code generation fails
  /// - [Exception] if trip doesn't exist
  Future<DeviceLinkCode> generateCode(String tripId, String memberName);

  /// Validates a code and grants trip access if valid.
  ///
  /// Checks all 6 validation rules:
  /// 1. Code exists in Firestore
  /// 2. Not expired (expiresAt > now)
  /// 3. Not used (used = false)
  /// 4. Matches specified trip
  /// 5. Code's memberName matches requesting user's name (case-insensitive)
  /// 6. Not rate limited (≤5 attempts in last 60 seconds)
  ///
  /// Uses Firestore transaction to atomically mark code as used.
  ///
  /// Parameters:
  /// - [tripId]: The trip to grant access to
  /// - [code]: The 8-digit code (with or without hyphen)
  /// - [memberName]: The requesting user's member name
  ///
  /// Returns the validated [DeviceLinkCode] on success.
  ///
  /// Throws:
  /// - [Exception] with specific error message for each validation failure
  Future<DeviceLinkCode> validateCode(String tripId, String code, String memberName);

  /// Revokes (deletes) an active code before expiry.
  ///
  /// Parameters:
  /// - [tripId]: The trip containing the code
  /// - [codeId]: The document ID of the code to revoke
  ///
  /// Throws:
  /// - [Exception] if code doesn't exist or user lacks permission
  Future<void> revokeCode(String tripId, String codeId);

  /// Gets all active (unused, unexpired) codes for a trip.
  ///
  /// Filters codes client-side to show only:
  /// - used = false
  /// - expiresAt > now
  ///
  /// Sorted by expiry time (soonest first).
  ///
  /// Returns list of [DeviceLinkCode] (empty if none active).
  Future<List<DeviceLinkCode>> getActiveCodes(String tripId);

  /// Watches active codes for a trip with real-time updates.
  ///
  /// Returns a stream that emits updated list whenever codes change.
  /// Useful for live UI updates in Active Codes page.
  ///
  /// Stream emits empty list if no active codes.
  Stream<List<DeviceLinkCode>> watchActiveCodes(String tripId);
}
