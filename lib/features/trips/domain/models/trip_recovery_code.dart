import 'package:cloud_firestore/cloud_firestore.dart';

/// Recovery code for emergency trip access
///
/// Allows users to join a trip without device verification if all members
/// lose access. Each trip can have one recovery code.
class TripRecoveryCode {
  /// 12-digit recovery code in format "XXXX-XXXX-XXXX"
  final String code;

  /// Trip ID this recovery code belongs to
  final String tripId;

  /// When the recovery code was created
  final DateTime createdAt;

  /// Number of times this recovery code has been used
  final int usedCount;

  /// Last time this recovery code was used (null if never used)
  final DateTime? lastUsedAt;

  const TripRecoveryCode({
    required this.code,
    required this.tripId,
    required this.createdAt,
    required this.usedCount,
    this.lastUsedAt,
  });

  /// Create from Firestore document
  factory TripRecoveryCode.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TripRecoveryCode(
      code: data['code'] as String,
      tripId: data['tripId'] as String,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      usedCount: data['usedCount'] as int? ?? 0,
      lastUsedAt: data['lastUsedAt'] != null
          ? (data['lastUsedAt'] as Timestamp).toDate()
          : null,
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'code': code,
      'tripId': tripId,
      'createdAt': Timestamp.fromDate(createdAt),
      'usedCount': usedCount,
      'lastUsedAt': lastUsedAt != null ? Timestamp.fromDate(lastUsedAt!) : null,
    };
  }

  /// Copy with updated fields
  TripRecoveryCode copyWith({
    String? code,
    String? tripId,
    DateTime? createdAt,
    int? usedCount,
    DateTime? lastUsedAt,
  }) {
    return TripRecoveryCode(
      code: code ?? this.code,
      tripId: tripId ?? this.tripId,
      createdAt: createdAt ?? this.createdAt,
      usedCount: usedCount ?? this.usedCount,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
    );
  }

  @override
  String toString() {
    return 'TripRecoveryCode(code: $code, tripId: $tripId, usedCount: $usedCount)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is TripRecoveryCode &&
        other.code == code &&
        other.tripId == tripId &&
        other.createdAt == createdAt &&
        other.usedCount == usedCount &&
        other.lastUsedAt == lastUsedAt;
  }

  @override
  int get hashCode {
    return code.hashCode ^
        tripId.hashCode ^
        createdAt.hashCode ^
        usedCount.hashCode ^
        (lastUsedAt?.hashCode ?? 0);
  }
}
