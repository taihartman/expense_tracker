import '../models/activity_log.dart';

/// Repository interface for managing activity logs
///
/// Provides methods to add activity logs and retrieve them as a stream
/// for real-time updates.
abstract class ActivityLogRepository {
  /// Add a new activity log entry
  ///
  /// The timestamp will be set by the server to ensure consistency.
  /// Returns the ID of the created activity log entry.
  Future<String> addLog(ActivityLog log);

  /// Get a stream of activity logs for a trip
  ///
  /// Returns activity logs ordered by timestamp (most recent first).
  /// The stream will emit updates whenever activity logs are added.
  ///
  /// Parameters:
  /// - [tripId]: The ID of the trip to get activity logs for
  /// - [limit]: Maximum number of logs to retrieve (default: 50)
  Stream<List<ActivityLog>> getActivityLogs(String tripId, {int limit = 50});
}
