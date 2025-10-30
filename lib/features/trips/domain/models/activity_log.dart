/// How a member joined a trip
enum JoinMethod {
  /// Clicked an invite link with pre-filled trip code
  inviteLink,

  /// Scanned a QR code to join
  qrCode,

  /// Manually typed the trip code
  manualCode,

  /// Used a recovery code to bypass verification
  recoveryCode,

  /// Unknown or legacy (for existing logs without method)
  unknown,
}

/// Types of activities that can be logged in a trip
enum ActivityType {
  // Trip Management Activities
  /// Trip was created
  tripCreated,

  /// Trip details were updated (name, currency, etc.)
  tripUpdated,

  /// Trip was deleted
  tripDeleted,

  // Participant Activities
  /// A member joined the trip
  memberJoined,

  /// A participant was added to the trip
  participantAdded,

  /// A participant was removed from the trip
  participantRemoved,

  // Expense Activities
  /// An expense was added to the trip
  expenseAdded,

  /// An expense was edited
  expenseEdited,

  /// An expense was deleted
  expenseDeleted,

  /// Expense category was changed
  expenseCategoryChanged,

  /// Expense split configuration was modified
  expenseSplitModified,

  // Settlement Activities
  /// A transfer was marked as settled
  transferMarkedSettled,

  /// A settled transfer was marked as unsettled
  transferMarkedUnsettled,

  // Device Pairing & Security Activities
  /// A device was successfully verified and joined
  deviceVerified,

  /// A recovery code was used to join a trip
  recoveryCodeUsed,
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

  /// Optional metadata about the activity
  ///
  /// Examples:
  /// - For memberJoined: {'joinMethod': 'qrCode', 'invitedBy': 'participant-id'}
  /// - For expenseEdited: {
  ///     'expenseId': 'exp-123',
  ///     'changes': {
  ///       'amount': {'old': '100.00', 'new': '150.00'},
  ///       'currency': {'old': 'USD', 'new': 'VND'},
  ///       'description': {'old': 'Dinner', 'new': 'Lunch'},
  ///       'category': {'oldId': null, 'newId': 'cat-1', 'oldName': 'None', 'newName': 'Food'},
  ///       'payer': {'oldId': 'bob-id', 'newId': 'alice-id', 'oldName': 'Bob', 'newName': 'Alice'},
  ///       'date': {'old': '2025-01-01', 'new': '2025-01-02'},
  ///       'splitType': {'old': 'equal', 'new': 'weighted'},
  ///       'participants': {
  ///         'added': [{'id': 'charlie-id', 'name': 'Charlie', 'weight': 1}],
  ///         'removed': [{'id': 'dave-id', 'name': 'Dave', 'weight': 1}],
  ///         'weightsChanged': [{'id': 'bob-id', 'name': 'Bob', 'oldWeight': 1, 'newWeight': 2}]
  ///       }
  ///     }
  ///   }
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
