import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/activity_log_repository.dart';
import 'activity_log_state.dart';

/// Cubit for managing activity log state
class ActivityLogCubit extends Cubit<ActivityLogState> {
  final ActivityLogRepository _repository;
  StreamSubscription? _logsSubscription;

  ActivityLogCubit({required ActivityLogRepository repository})
    : _repository = repository,
      super(const ActivityLogInitial());

  /// Load activity logs for a specific trip
  void loadActivityLogs(String tripId, {int limit = 50}) {
    _log('📥 Loading activity logs for trip: $tripId (limit: $limit)');

    // Cancel previous subscription if exists
    _logsSubscription?.cancel();

    emit(const ActivityLogLoading());

    try {
      final logsStream = _repository.getActivityLogs(tripId, limit: limit);

      _logsSubscription = logsStream.listen(
        (logs) {
          _log('📦 Received ${logs.length} activity logs');
          if (!isClosed) {
            emit(ActivityLogLoaded(logs: logs, hasMore: logs.length >= limit));
          }
        },
        onError: (error) {
          _log('❌ Error loading activity logs: $error');
          if (!isClosed) {
            emit(ActivityLogError('Failed to load activity logs: $error'));
          }
        },
      );
    } catch (e) {
      _log('❌ Failed to start activity log stream: $e');
      emit(ActivityLogError('Failed to load activity logs: $e'));
    }
  }

  /// Clear activity logs (e.g., when navigating away)
  void clearLogs() {
    _log('🗑️ Clearing activity logs');
    _logsSubscription?.cancel();
    emit(const ActivityLogInitial());
  }

  void _log(String message) {
    debugPrint(
      '[${DateTime.now().toIso8601String()}] [ActivityLogCubit] $message',
    );
  }

  @override
  Future<void> close() {
    _log('🔴 Closing ActivityLogCubit - cancelling subscription');
    _logsSubscription?.cancel();
    return super.close();
  }
}
