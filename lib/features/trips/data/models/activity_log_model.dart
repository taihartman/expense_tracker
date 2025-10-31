import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/activity_log.dart';

/// Data model for ActivityLog with JSON and Firestore serialization
///
/// This model extends the domain ActivityLog with serialization capabilities
/// for Firestore storage and retrieval.
class ActivityLogModel extends ActivityLog {
  const ActivityLogModel({
    required super.id,
    required super.tripId,
    required super.actorName,
    required super.type,
    required super.description,
    required super.timestamp,
    super.metadata,
  });

  /// Create ActivityLogModel from domain ActivityLog
  factory ActivityLogModel.fromDomain(ActivityLog log) {
    return ActivityLogModel(
      id: log.id,
      tripId: log.tripId,
      actorName: log.actorName,
      type: log.type,
      description: log.description,
      timestamp: log.timestamp,
      metadata: log.metadata,
    );
  }

  /// Create ActivityLogModel from JSON map
  factory ActivityLogModel.fromJson(Map<String, dynamic> json) {
    return ActivityLogModel(
      id: json['id'] as String,
      tripId: json['tripId'] as String,
      actorName: json['actorName'] as String,
      type: _activityTypeFromString(json['type'] as String),
      description: json['description'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tripId': tripId,
      'actorName': actorName,
      'type': _activityTypeToString(type),
      'description': description,
      'timestamp': timestamp.toIso8601String(),
      if (metadata != null) 'metadata': metadata,
    };
  }

  /// Create ActivityLogModel from Firestore DocumentSnapshot
  factory ActivityLogModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ActivityLogModel(
      id: doc.id,
      tripId: data['tripId'] as String,
      actorName: data['actorName'] as String,
      type: _activityTypeFromString(data['type'] as String),
      description: data['description'] as String,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'tripId': tripId,
      'actorName': actorName,
      'type': _activityTypeToString(type),
      'description': description,
      'timestamp': FieldValue.serverTimestamp(),
      if (metadata != null) 'metadata': metadata,
    };
  }

  /// Convert ActivityType enum to string for serialization
  static String _activityTypeToString(ActivityType type) {
    switch (type) {
      case ActivityType.tripCreated:
        return 'tripCreated';
      case ActivityType.tripUpdated:
        return 'tripUpdated';
      case ActivityType.tripDeleted:
        return 'tripDeleted';
      case ActivityType.tripArchived:
        return 'tripArchived';
      case ActivityType.tripUnarchived:
        return 'tripUnarchived';
      case ActivityType.memberJoined:
        return 'memberJoined';
      case ActivityType.participantAdded:
        return 'participantAdded';
      case ActivityType.participantRemoved:
        return 'participantRemoved';
      case ActivityType.expenseAdded:
        return 'expenseAdded';
      case ActivityType.expenseEdited:
        return 'expenseEdited';
      case ActivityType.expenseDeleted:
        return 'expenseDeleted';
      case ActivityType.expenseCategoryChanged:
        return 'expenseCategoryChanged';
      case ActivityType.expenseSplitModified:
        return 'expenseSplitModified';
      case ActivityType.transferMarkedSettled:
        return 'transferMarkedSettled';
      case ActivityType.transferMarkedUnsettled:
        return 'transferMarkedUnsettled';
      case ActivityType.categoryCustomized:
        return 'categoryCustomized';
      case ActivityType.categoryResetToDefault:
        return 'categoryResetToDefault';
      case ActivityType.deviceVerified:
        return 'deviceVerified';
      case ActivityType.recoveryCodeUsed:
        return 'recoveryCodeUsed';
    }
  }

  /// Convert string to ActivityType enum
  static ActivityType _activityTypeFromString(String type) {
    switch (type) {
      case 'tripCreated':
        return ActivityType.tripCreated;
      case 'tripUpdated':
        return ActivityType.tripUpdated;
      case 'tripDeleted':
        return ActivityType.tripDeleted;
      case 'tripArchived':
        return ActivityType.tripArchived;
      case 'tripUnarchived':
        return ActivityType.tripUnarchived;
      case 'memberJoined':
        return ActivityType.memberJoined;
      case 'participantAdded':
        return ActivityType.participantAdded;
      case 'participantRemoved':
        return ActivityType.participantRemoved;
      case 'expenseAdded':
        return ActivityType.expenseAdded;
      case 'expenseEdited':
        return ActivityType.expenseEdited;
      case 'expenseDeleted':
        return ActivityType.expenseDeleted;
      case 'expenseCategoryChanged':
        return ActivityType.expenseCategoryChanged;
      case 'expenseSplitModified':
        return ActivityType.expenseSplitModified;
      case 'transferMarkedSettled':
        return ActivityType.transferMarkedSettled;
      case 'transferMarkedUnsettled':
        return ActivityType.transferMarkedUnsettled;
      case 'categoryCustomized':
        return ActivityType.categoryCustomized;
      case 'categoryResetToDefault':
        return ActivityType.categoryResetToDefault;
      case 'deviceVerified':
        return ActivityType.deviceVerified;
      case 'recoveryCodeUsed':
        return ActivityType.recoveryCodeUsed;
      default:
        throw ArgumentError('Unknown activity type: $type');
    }
  }
}
