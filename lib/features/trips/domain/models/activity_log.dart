/// Types of activities that can be logged in a trip
enum ActivityType {
  /// Trip was created
  tripCreated,

  /// A member joined the trip
  memberJoined,

  /// An expense was added to the trip
  expenseAdded,

  /// An expense was edited
  expenseEdited,

  /// An expense was deleted
  expenseDeleted,
}

/// Domain model representing an activity log entry for a trip
///
/// Activity logs provide transparency and audit trail for all actions
/// taken in a trip (creation, member joins, expense changes).
class ActivityLog {
  /// Unique identifier for this activity log entry
  final String id;

  /// ID of the trip this activity belongs to
  final String tripId;

  /// Name of the person who performed the action
  final String actorName;

  /// Type of activity (trip created, member joined, expense added, etc.)
  final ActivityType type;

  /// Human-readable description of the activity
  final String description;

  /// When this activity occurred
  final DateTime timestamp;

  /// Optional metadata about the activity (e.g., expense ID, amount)
  final Map<String, dynamic>? metadata;

  const ActivityLog({
    required this.id,
    required this.tripId,
    required this.actorName,
    required this.type,
    required this.description,
    required this.timestamp,
    this.metadata,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActivityLog &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          tripId == other.tripId &&
          actorName == other.actorName &&
          type == other.type &&
          description == other.description &&
          timestamp == other.timestamp;

  @override
  int get hashCode =>
      id.hashCode ^
      tripId.hashCode ^
      actorName.hashCode ^
      type.hashCode ^
      description.hashCode ^
      timestamp.hashCode;

  @override
  String toString() {
    return 'ActivityLog(id: $id, tripId: $tripId, actorName: $actorName, '
        'type: $type, description: $description, timestamp: $timestamp)';
  }
}
