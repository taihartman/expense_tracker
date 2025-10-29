import 'package:equatable/equatable.dart';
import '../../domain/models/activity_log.dart';

/// Base state for ActivityLog feature
abstract class ActivityLogState extends Equatable {
  const ActivityLogState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class ActivityLogInitial extends ActivityLogState {
  const ActivityLogInitial();
}

/// Loading activity logs
class ActivityLogLoading extends ActivityLogState {
  const ActivityLogLoading();
}

/// Activity logs loaded successfully
class ActivityLogLoaded extends ActivityLogState {
  final List<ActivityLog> logs;
  final bool hasMore;

  const ActivityLogLoaded({
    required this.logs,
    this.hasMore = false,
  });

  @override
  List<Object?> get props => [logs, hasMore];

  ActivityLogLoaded copyWith({
    List<ActivityLog>? logs,
    bool? hasMore,
  }) {
    return ActivityLogLoaded(
      logs: logs ?? this.logs,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

/// Error loading activity logs
class ActivityLogError extends ActivityLogState {
  final String message;

  const ActivityLogError(this.message);

  @override
  List<Object?> get props => [message];
}
