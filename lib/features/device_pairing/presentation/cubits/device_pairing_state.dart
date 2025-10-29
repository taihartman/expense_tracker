import 'package:equatable/equatable.dart';
import '../../domain/models/device_link_code.dart';

/// Base state for device pairing operations.
sealed class DevicePairingState extends Equatable {
  const DevicePairingState();

  @override
  List<Object?> get props => [];
}

/// Initial state before any operations.
final class DevicePairingInitial extends DevicePairingState {
  const DevicePairingInitial();
}

// ============================================================================
// Code Generation States
// ============================================================================

/// Code is being generated.
final class CodeGenerating extends DevicePairingState {
  const CodeGenerating();
}

/// Code generation succeeded.
final class CodeGenerated extends DevicePairingState {
  final DeviceLinkCode code;

  const CodeGenerated(this.code);

  @override
  List<Object?> get props => [code];
}

/// Code generation failed.
final class CodeGenerationError extends DevicePairingState {
  final String message;

  const CodeGenerationError(this.message);

  @override
  List<Object?> get props => [message];
}

// ============================================================================
// Code Validation States
// ============================================================================

/// Code is being validated.
final class CodeValidating extends DevicePairingState {
  const CodeValidating();
}

/// Code validation succeeded - trip access granted.
final class CodeValidated extends DevicePairingState {
  final String tripId;

  const CodeValidated(this.tripId);

  @override
  List<Object?> get props => [tripId];
}

/// Code validation failed.
final class CodeValidationError extends DevicePairingState {
  final String message;

  const CodeValidationError(this.message);

  @override
  List<Object?> get props => [message];
}

// ============================================================================
// Active Codes Management States
// ============================================================================

/// Loading active codes for a trip.
final class ActiveCodesLoading extends DevicePairingState {
  const ActiveCodesLoading();
}

/// Active codes loaded successfully.
final class ActiveCodesLoaded extends DevicePairingState {
  final List<DeviceLinkCode> codes;

  const ActiveCodesLoaded(this.codes);

  @override
  List<Object?> get props => [codes];
}

/// Loading active codes failed.
final class ActiveCodesError extends DevicePairingState {
  final String message;

  const ActiveCodesError(this.message);

  @override
  List<Object?> get props => [message];
}

// ============================================================================
// Code Revocation States
// ============================================================================

/// Code is being revoked.
final class CodeRevoking extends DevicePairingState {
  const CodeRevoking();
}

/// Code revocation succeeded.
final class CodeRevoked extends DevicePairingState {
  const CodeRevoked();
}

/// Code revocation failed.
final class CodeRevocationError extends DevicePairingState {
  final String message;

  const CodeRevocationError(this.message);

  @override
  List<Object?> get props => [message];
}
