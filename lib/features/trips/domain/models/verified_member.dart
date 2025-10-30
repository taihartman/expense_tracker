import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Represents a participant who has verified their identity and joined a trip
///
/// This model tracks which participants have actually joined the trip
/// (via device pairing or recovery code) as opposed to just being in the
/// participant list for expense tracking purposes.
///
/// Stored in Firestore at: /trips/{tripId}/verifiedMembers/{participantId}
class VerifiedMember extends Equatable {
  /// Unique identifier for the participant (matches Participant.id)
  final String participantId;

  /// Display name of the participant
  final String participantName;

  /// When the participant verified and joined the trip
  final DateTime verifiedAt;

  const VerifiedMember({
    required this.participantId,
    required this.participantName,
    required this.verifiedAt,
  });

  /// Creates a VerifiedMember from Firestore data
  factory VerifiedMember.fromFirestore(
    Map<String, dynamic> data,
    String documentId,
  ) {
    return VerifiedMember(
      participantId: documentId, // Use document ID as participant ID
      participantName: data['participantName'] as String,
      verifiedAt: (data['verifiedAt'] as Timestamp).toDate(),
    );
  }

  /// Converts VerifiedMember to Firestore data
  Map<String, dynamic> toFirestore() {
    return {
      'participantName': participantName,
      'verifiedAt': Timestamp.fromDate(verifiedAt),
    };
  }

  @override
  List<Object?> get props => [participantId, participantName, verifiedAt];

  @override
  String toString() {
    return 'VerifiedMember(participantId: $participantId, participantName: $participantName, verifiedAt: $verifiedAt)';
  }

  /// Creates a copy with optional field updates
  VerifiedMember copyWith({
    String? participantId,
    String? participantName,
    DateTime? verifiedAt,
  }) {
    return VerifiedMember(
      participantId: participantId ?? this.participantId,
      participantName: participantName ?? this.participantName,
      verifiedAt: verifiedAt ?? this.verifiedAt,
    );
  }
}
