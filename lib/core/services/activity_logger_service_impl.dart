import 'dart:developer' as developer;

import 'package:expense_tracker/core/models/participant.dart';
import 'package:expense_tracker/core/services/activity_logger_service.dart';
import 'package:expense_tracker/features/expenses/domain/models/expense.dart';
import 'package:expense_tracker/features/expenses/domain/utils/expense_change_detector.dart';
import 'package:expense_tracker/features/settlements/domain/models/minimal_transfer.dart';
import 'package:expense_tracker/features/trips/domain/models/activity_log.dart';
import 'package:expense_tracker/features/trips/domain/models/trip.dart';
import 'package:expense_tracker/features/trips/domain/repositories/activity_log_repository.dart';
import 'package:expense_tracker/features/trips/domain/repositories/trip_repository.dart';

/// Internal cache for trip context data
class _TripContextCache {
  final String tripId;
  final List<Participant> participants;
  final String tripName;
  final DateTime cachedAt;
  final int expirationMinutes;

  _TripContextCache({
    required this.tripId,
    required this.participants,
    required this.tripName,
    required this.cachedAt,
    required this.expirationMinutes,
  });

  bool isExpired() {
    final now = DateTime.now();
    final expirationTime = cachedAt.add(Duration(minutes: expirationMinutes));
    return now.isAfter(expirationTime);
  }
}

/// Implementation of [ActivityLoggerService]
///
/// Provides centralized activity logging with automatic change detection,
/// participant name resolution, and fire-and-forget error handling.
class ActivityLoggerServiceImpl implements ActivityLoggerService {
  final ActivityLogRepository _activityLogRepository;
  final TripRepository _tripRepository;
  final int _cacheExpirationMinutes;

  _TripContextCache? _tripContextCache;

  ActivityLoggerServiceImpl({
    required ActivityLogRepository activityLogRepository,
    required TripRepository tripRepository,
    int cacheExpirationMinutes = 5,
  })  : _activityLogRepository = activityLogRepository,
        _tripRepository = tripRepository,
        _cacheExpirationMinutes = cacheExpirationMinutes;

  @override
  Future<void> logExpenseAdded(Expense expense, String actorName) async {
    try {
      // Get trip context for participant names
      final context = await _getTripContext(expense.tripId);

      // Find payer name
      final payer = context.participants.firstWhere(
        (p) => p.id == expense.payerUserId,
        orElse: () => Participant(
          id: expense.payerUserId,
          name: 'Unknown',
          createdAt: DateTime.now(),
        ),
      );

      // Create description
      final description = expense.description ?? 'Expense';

      // Create activity log
      final activityLog = ActivityLog(
        id: '', // Firestore will generate
        tripId: expense.tripId,
        type: ActivityType.expenseAdded,
        actorName: actorName.isEmpty ? 'Unknown' : actorName,
        description: description,
        timestamp: DateTime.now(),
        metadata: {
          'expenseId': expense.id,
          'amount': expense.amount.toString(),
          'currency': expense.currency.code,
          'payerId': expense.payerUserId,
          'payerName': payer.name,
        },
      );

      await _logActivity(activityLog);
    } catch (e) {
      _logError('Failed to log expense added: $e');
      // Fire-and-forget: don't rethrow
    }
  }

  @override
  Future<void> logExpenseEdited(
    Expense oldExpense,
    Expense newExpense,
    String actorName,
  ) async {
    try {
      // Get trip context
      final context = await _getTripContext(newExpense.tripId);

      // Detect changes using existing utility
      final expenseChanges = _detectExpenseChanges(
        oldExpense,
        newExpense,
        context.participants,
      );

      // Skip logging if no changes detected
      if (!expenseChanges.hasChanges) {
        _logError('No changes detected for expense edit, skipping log');
        return;
      }

      // Create description
      final description = newExpense.description ?? 'Expense';

      // Create activity log with change metadata
      final activityLog = ActivityLog(
        id: '',
        tripId: newExpense.tripId,
        type: ActivityType.expenseEdited,
        actorName: actorName.isEmpty ? 'Unknown' : actorName,
        description: description,
        timestamp: DateTime.now(),
        metadata: expenseChanges.toMetadata(newExpense.id),
      );

      await _logActivity(activityLog);
    } catch (e) {
      _logError('Failed to log expense edited: $e');
    }
  }

  @override
  Future<void> logExpenseDeleted(Expense expense, String actorName) async {
    try {
      final description = expense.description ?? 'Expense';

      final activityLog = ActivityLog(
        id: '',
        tripId: expense.tripId,
        type: ActivityType.expenseDeleted,
        actorName: actorName.isEmpty ? 'Unknown' : actorName,
        description: description,
        timestamp: DateTime.now(),
        metadata: {
          'expenseId': expense.id,
          'amount': expense.amount.toString(),
          'currency': expense.currency.code,
          'description': description,
        },
      );

      await _logActivity(activityLog);
    } catch (e) {
      _logError('Failed to log expense deleted: $e');
    }
  }

  @override
  Future<void> logTransferSettled(
    MinimalTransfer transfer,
    String actorName,
  ) async {
    try {
      final context = await _getTripContext(transfer.tripId);

      // Lookup participant names
      final fromParticipant = context.participants.firstWhere(
        (p) => p.id == transfer.fromUserId,
        orElse: () => Participant(
          id: transfer.fromUserId,
          name: 'Unknown',
          createdAt: DateTime.now(),
        ),
      );

      final toParticipant = context.participants.firstWhere(
        (p) => p.id == transfer.toUserId,
        orElse: () => Participant(
          id: transfer.toUserId,
          name: 'Unknown',
          createdAt: DateTime.now(),
        ),
      );

      final description =
          '${fromParticipant.name} → ${toParticipant.name}: ${transfer.amountBase}';

      final activityLog = ActivityLog(
        id: '',
        tripId: transfer.tripId,
        type: ActivityType.transferMarkedSettled,
        actorName: actorName.isEmpty ? 'Unknown' : actorName,
        description: description,
        timestamp: DateTime.now(),
        metadata: {
          'transferId': transfer.id,
          'fromId': transfer.fromUserId,
          'fromName': fromParticipant.name,
          'toId': transfer.toUserId,
          'toName': toParticipant.name,
          'amount': transfer.amountBase.toString(),
        },
      );

      await _logActivity(activityLog);
    } catch (e) {
      _logError('Failed to log transfer settled: $e');
    }
  }

  @override
  Future<void> logTransferUnsettled(
    MinimalTransfer transfer,
    String actorName,
  ) async {
    try {
      final context = await _getTripContext(transfer.tripId);

      // Lookup participant names
      final fromParticipant = context.participants.firstWhere(
        (p) => p.id == transfer.fromUserId,
        orElse: () => Participant(
          id: transfer.fromUserId,
          name: 'Unknown',
          createdAt: DateTime.now(),
        ),
      );

      final toParticipant = context.participants.firstWhere(
        (p) => p.id == transfer.toUserId,
        orElse: () => Participant(
          id: transfer.toUserId,
          name: 'Unknown',
          createdAt: DateTime.now(),
        ),
      );

      final description =
          '${fromParticipant.name} → ${toParticipant.name}: ${transfer.amountBase}';

      final activityLog = ActivityLog(
        id: '',
        tripId: transfer.tripId,
        type: ActivityType.transferMarkedUnsettled,
        actorName: actorName.isEmpty ? 'Unknown' : actorName,
        description: description,
        timestamp: DateTime.now(),
        metadata: {
          'transferId': transfer.id,
          'fromId': transfer.fromUserId,
          'fromName': fromParticipant.name,
          'toId': transfer.toUserId,
          'toName': toParticipant.name,
          'amount': transfer.amountBase.toString(),
        },
      );

      await _logActivity(activityLog);
    } catch (e) {
      _logError('Failed to log transfer unsettled: $e');
    }
  }

  @override
  Future<void> logMemberJoined({
    required String tripId,
    required String memberName,
    required String joinMethod,
    String? inviterId,
  }) async {
    try {
      String? inviterName;
      if (inviterId != null) {
        try {
          final context = await _getTripContext(tripId);
          final inviter = context.participants.firstWhere(
            (p) => p.id == inviterId,
            orElse: () => Participant(
              id: inviterId,
              name: 'Unknown',
              createdAt: DateTime.now(),
            ),
          );
          inviterName = inviter.name;
        } catch (e) {
          _logError('Failed to lookup inviter name: $e');
        }
      }

      final description = '$memberName joined';

      final metadata = <String, dynamic>{
        'memberName': memberName,
        'joinMethod': _formatJoinMethod(joinMethod),
      };

      if (inviterName != null) {
        metadata['inviterId'] = inviterId;
        metadata['inviterName'] = inviterName;
      }

      final activityLog = ActivityLog(
        id: '',
        tripId: tripId,
        type: ActivityType.memberJoined,
        actorName: memberName,
        description: description,
        timestamp: DateTime.now(),
        metadata: metadata,
      );

      await _logActivity(activityLog);
    } catch (e) {
      _logError('Failed to log member joined: $e');
    }
  }

  @override
  Future<void> logTripCreated(Trip trip, String creatorName) async {
    try {
      final activityLog = ActivityLog(
        id: '',
        tripId: trip.id,
        type: ActivityType.tripCreated,
        actorName: creatorName.isEmpty ? 'Unknown' : creatorName,
        description: trip.name,
        timestamp: DateTime.now(),
        metadata: {
          'tripName': trip.name,
          'baseCurrency': trip.baseCurrency.code,
        },
      );

      await _logActivity(activityLog);
    } catch (e) {
      _logError('Failed to log trip created: $e');
    }
  }

  @override
  void clearCache() {
    _tripContextCache = null;
  }

  /// Get trip context (participants, trip name) with caching
  ///
  /// Fetches trip data and caches it for [_cacheExpirationMinutes] minutes.
  /// Returns cached data if available and not expired.
  Future<_TripContextCache> _getTripContext(String tripId) async {
    // Check cache
    if (_tripContextCache != null &&
        _tripContextCache!.tripId == tripId &&
        !_tripContextCache!.isExpired()) {
      return _tripContextCache!;
    }

    // Fetch fresh data
    final trip = await _tripRepository.getTripById(tripId);
    if (trip == null) {
      throw Exception('Trip not found: $tripId');
    }

    // Update cache
    _tripContextCache = _TripContextCache(
      tripId: trip.id,
      participants: trip.participants,
      tripName: trip.name,
      cachedAt: DateTime.now(),
      expirationMinutes: _cacheExpirationMinutes,
    );

    return _tripContextCache!;
  }

  /// Log an activity to the repository
  ///
  /// Wraps repository call with error handling.
  Future<void> _logActivity(ActivityLog activityLog) async {
    try {
      await _activityLogRepository.addLog(activityLog);
    } catch (e) {
      _logError('Failed to log activity: $e');
      rethrow; // For testing - will be caught by outer try-catch
    }
  }

  /// Log an error message
  ///
  /// Uses developer.log for non-fatal errors.
  void _logError(String message) {
    developer.log(
      message,
      name: 'ActivityLoggerService',
      error: message,
    );
  }

  /// Detect expense changes using ExpenseChangeDetector utility
  ///
  /// Reuses existing change detection logic.
  ExpenseChanges _detectExpenseChanges(
    Expense oldExpense,
    Expense newExpense,
    List<Participant> participants,
  ) {
    return ExpenseChangeDetector.detectChanges(
      oldExpense,
      newExpense,
      participants,
    );
  }

  /// Format join method for display
  ///
  /// Converts technical join method strings to human-readable format.
  String _formatJoinMethod(String joinMethod) {
    switch (joinMethod.toLowerCase()) {
      case 'invite_link':
        return 'via invite link';
      case 'direct_add':
        return 'added directly';
      case 'qr_code':
        return 'via QR code';
      default:
        return joinMethod;
    }
  }
}
