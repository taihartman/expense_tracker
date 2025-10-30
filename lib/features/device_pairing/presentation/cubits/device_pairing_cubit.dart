import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../../../core/services/activity_logger_service.dart';
import '../../domain/repositories/device_link_code_repository.dart';
import '../../../trips/domain/repositories/trip_repository.dart';
import '../../../../core/models/participant.dart';
import 'device_pairing_state.dart';

/// Cubit for managing device pairing operations.
///
/// Handles code generation, validation, and active code management.
class DevicePairingCubit extends Cubit<DevicePairingState> {
  final DeviceLinkCodeRepository _repository;
  final LocalStorageService _localStorageService;
  final TripRepository? _tripRepository;
  final ActivityLoggerService? _activityLoggerService;

  DevicePairingCubit({
    required DeviceLinkCodeRepository repository,
    required LocalStorageService localStorageService,
    TripRepository? tripRepository,
    ActivityLoggerService? activityLoggerService,
  })  : _repository = repository,
        _localStorageService = localStorageService,
        _tripRepository = tripRepository,
        _activityLoggerService = activityLoggerService,
        super(const DevicePairingInitial());

  /// Generates a new device link code for the specified member.
  ///
  /// Emits [CodeGenerating] → [CodeGenerated] on success or [CodeGenerationError] on failure.
  Future<void> generateCode(String tripId, String memberName) async {
    emit(const CodeGenerating());
    try {
      // Call repository to generate code (handles invalidation automatically)
      final code = await _repository.generateCode(tripId, memberName);

      // Emit success state with generated code
      emit(CodeGenerated(code));
    } catch (e) {
      emit(CodeGenerationError(e.toString()));
    }
  }

  /// Validates a code and grants trip access if valid.
  ///
  /// Checks all 6 validation rules and uses rate limiting.
  /// On success, saves trip ID to local storage and emits [CodeValidated].
  ///
  /// Emits [CodeValidating] → [CodeValidated] on success or [CodeValidationError] on failure.
  Future<void> validateCode(
    String tripId,
    String code,
    String memberName,
  ) async {
    emit(const CodeValidating());
    try {
      // Call repository to validate code (includes all 6 validation rules)
      await _repository.validateCode(tripId, code, memberName);

      // Grant trip access by saving tripId to local storage and adding to verified members
      await _grantTripAccess(tripId, memberName);

      // Log device verification via centralized service
      if (_activityLoggerService != null) {
        // Use last 4 characters of code for reference (not the full code for security)
        final deviceCode = code.length >= 4 ? code.substring(code.length - 4) : code;
        await _activityLoggerService.logDeviceVerified(
          tripId: tripId,
          memberName: memberName,
          deviceCode: deviceCode,
        );
      }

      // Emit success state with tripId
      emit(CodeValidated(tripId));
    } catch (e) {
      emit(CodeValidationError(e.toString()));
    }
  }

  /// Revokes (deletes) an active code.
  ///
  /// Emits [CodeRevoking] → [CodeRevoked] on success or [CodeRevocationError] on failure.
  Future<void> revokeCode(String tripId, String codeId) async {
    emit(const CodeRevoking());
    try {
      // TODO: Implement code revocation
      // 1. Call repository.revokeCode()
      // 2. Emit CodeRevoked
      throw UnimplementedError('revokeCode not yet implemented');
    } catch (e) {
      emit(CodeRevocationError(e.toString()));
    }
  }

  /// Loads all active codes for a trip.
  ///
  /// Emits [ActiveCodesLoading] → [ActiveCodesLoaded] on success or [ActiveCodesError] on failure.
  Future<void> loadActiveCodes(String tripId) async {
    emit(const ActiveCodesLoading());
    try {
      // TODO: Implement loading active codes
      // 1. Call repository.getActiveCodes()
      // 2. Emit ActiveCodesLoaded with results
      throw UnimplementedError('loadActiveCodes not yet implemented');
    } catch (e) {
      emit(ActiveCodesError(e.toString()));
    }
  }

  // =========================================================================
  // Private Helper Methods
  // =========================================================================

  /// Checks if rate limited (>5 validation attempts in last 60 seconds).
  ///
  /// Returns true if rate limited, false otherwise.
  Future<bool> _isRateLimited(String tripId) async {
    // TODO: Implement rate limiting check
    // 1. Query validationAttempts for last 60 seconds
    // 2. Count attempts
    // 3. Return true if >= 5
    return false;
  }

  /// Records a validation attempt for rate limiting.
  Future<void> _recordAttempt(String tripId, bool success) async {
    // TODO: Implement attempt recording
    // 1. Create new document in validationAttempts subcollection
    // 2. Include timestamp and success flag
  }

  /// Grants trip access by saving trip ID to local storage
  /// and adding to verified members in Firestore.
  ///
  /// This adds the trip ID to the user's list of joined trips,
  /// allowing them to access the trip's data.
  Future<void> _grantTripAccess(String tripId, String memberName) async {
    // Add to local storage
    await _localStorageService.addJoinedTrip(tripId);

    // Add to verified members in Firestore (cross-device visibility)
    if (_tripRepository != null) {
      try {
        final participantId = Participant.fromName(memberName).id;
        await _tripRepository.addVerifiedMember(
          tripId: tripId,
          participantId: participantId,
          participantName: memberName,
        );
      } catch (e) {
        // Non-fatal - user still has local access
        // ignore: avoid_print
        print('⚠️ Failed to add verified member (non-fatal): $e');
      }
    }
  }
}
