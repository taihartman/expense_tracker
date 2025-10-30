import 'dart:developer' as developer;

import '../models/participant.dart';
import '../models/split_type.dart';
import 'activity_logger_service.dart';
import '../../features/expenses/domain/models/expense.dart';
import '../../features/expenses/domain/utils/expense_change_detector.dart';
import '../../features/settlements/domain/models/minimal_transfer.dart';
import '../../features/trips/domain/models/activity_log.dart';
import '../../features/trips/domain/models/trip.dart';
import '../../features/trips/domain/repositories/activity_log_repository.dart';
import '../../features/trips/domain/repositories/trip_repository.dart';

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
  }) : _activityLogRepository = activityLogRepository,
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

      // Build base metadata
      final metadata = <String, dynamic>{
        'expenseId': expense.id,
        'amount': expense.amount.toString(),
        'currency': expense.currency.code,
        'payerId': expense.payerUserId,
        'payerName': payer.name,
        'splitType': expense.splitType.name,
      };

      // Add itemized-specific metadata
      if (expense.splitType == SplitType.itemized) {
        // Item count
        if (expense.items != null && expense.items!.isNotEmpty) {
          metadata['itemCount'] = expense.items!.length;

          // Sample items (first 3)
          final sampleItems = expense.items!
              .take(3)
              .map((item) => item.name)
              .toList();
          metadata['sampleItems'] = sampleItems.join(', ');
        }

        // Participant breakdown
        if (expense.participantAmounts != null) {
          final participantNames = expense.participantAmounts!.keys.map((
            userId,
          ) {
            final participant = context.participants.firstWhere(
              (p) => p.id == userId,
              orElse: () => Participant(
                id: userId,
                name: 'Unknown',
                createdAt: DateTime.now(),
              ),
            );
            return participant.name;
          }).toList();

          metadata['participantCount'] = participantNames.length;
          metadata['participants'] = participantNames.join(', ');
        }

        // Tax, tip, fees
        if (expense.extras != null) {
          final extras = expense.extras!;

          // Tax
          if (extras.tax != null) {
            metadata['hasTax'] = true;
            metadata['taxAmount'] = extras.tax!.value.toString();
          }

          // Tip
          if (extras.tip != null) {
            metadata['hasTip'] = true;
            metadata['tipAmount'] = extras.tip!.value.toString();
          }

          // Fees
          if (extras.fees.isNotEmpty) {
            metadata['feeCount'] = extras.fees.length;
          }

          // Discounts
          if (extras.discounts.isNotEmpty) {
            metadata['discountCount'] = extras.discounts.length;
          }
        }
      }

      // Create activity log
      final activityLog = ActivityLog(
        id: '', // Firestore will generate
        tripId: expense.tripId,
        type: ActivityType.expenseAdded,
        actorName: actorName.isEmpty ? 'Unknown' : actorName,
        description: description,
        timestamp: DateTime.now(),
        metadata: metadata,
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
    developer.log(message, name: 'ActivityLoggerService', error: message);
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

  @override
  Future<void> logTripUpdated(
    Trip oldTrip,
    Trip newTrip,
    String actorName,
  ) async {
    try {
      final changes = <String>[];

      // Detect name change
      if (oldTrip.name != newTrip.name) {
        changes.add('name: "${oldTrip.name}" → "${newTrip.name}"');
      }

      // Detect currency change
      if (oldTrip.baseCurrency != newTrip.baseCurrency) {
        changes.add(
          'currency: ${oldTrip.baseCurrency.code} → ${newTrip.baseCurrency.code}',
        );
      }

      // Skip logging if no changes detected
      if (changes.isEmpty) {
        _logError('No changes detected for trip update, skipping log');
        return;
      }

      final description = 'Updated ${changes.join(", ")}';
      final activityLog = ActivityLog(
        id: '',
        tripId: newTrip.id,
        type: ActivityType.tripUpdated,
        actorName: actorName.isEmpty ? 'Unknown' : actorName,
        description: description,
        timestamp: DateTime.now(),
        metadata: {
          'tripId': newTrip.id,
          'changes': changes,
          if (oldTrip.name != newTrip.name) ...{
            'oldName': oldTrip.name,
            'newName': newTrip.name,
          },
          if (oldTrip.baseCurrency != newTrip.baseCurrency) ...{
            'oldCurrency': oldTrip.baseCurrency.code,
            'newCurrency': newTrip.baseCurrency.code,
          },
        },
      );

      await _logActivity(activityLog);
    } catch (e) {
      _logError('Failed to log trip updated: $e');
    }
  }

  @override
  Future<void> logTripDeleted(Trip trip, String actorName) async {
    try {
      final activityLog = ActivityLog(
        id: '',
        tripId: trip.id,
        type: ActivityType.tripDeleted,
        actorName: actorName.isEmpty ? 'Unknown' : actorName,
        description: 'Deleted trip "${trip.name}"',
        timestamp: DateTime.now(),
        metadata: {
          'tripId': trip.id,
          'tripName': trip.name,
          'baseCurrency': trip.baseCurrency.code,
        },
      );

      await _logActivity(activityLog);
    } catch (e) {
      _logError('Failed to log trip deleted: $e');
    }
  }

  @override
  Future<void> logTripArchived(Trip trip, String actorName) async {
    try {
      final activityLog = ActivityLog(
        id: '',
        tripId: trip.id,
        type: ActivityType.tripArchived,
        actorName: actorName.isEmpty ? 'Unknown' : actorName,
        description: 'Archived trip "${trip.name}"',
        timestamp: DateTime.now(),
        metadata: {'tripId': trip.id, 'tripName': trip.name},
      );

      await _logActivity(activityLog);
    } catch (e) {
      _logError('Failed to log trip archived: $e');
    }
  }

  @override
  Future<void> logTripUnarchived(Trip trip, String actorName) async {
    try {
      final activityLog = ActivityLog(
        id: '',
        tripId: trip.id,
        type: ActivityType.tripUnarchived,
        actorName: actorName.isEmpty ? 'Unknown' : actorName,
        description: 'Unarchived trip "${trip.name}"',
        timestamp: DateTime.now(),
        metadata: {'tripId': trip.id, 'tripName': trip.name},
      );

      await _logActivity(activityLog);
    } catch (e) {
      _logError('Failed to log trip unarchived: $e');
    }
  }

  @override
  Future<void> logParticipantAdded({
    required String tripId,
    required String participantName,
    required String actorName,
  }) async {
    try {
      final activityLog = ActivityLog(
        id: '',
        tripId: tripId,
        type: ActivityType.participantAdded,
        actorName: actorName.isEmpty ? 'Unknown' : actorName,
        description: 'Added $participantName to the trip',
        timestamp: DateTime.now(),
        metadata: {'participantName': participantName, 'addedBy': actorName},
      );

      await _logActivity(activityLog);
    } catch (e) {
      _logError('Failed to log participant added: $e');
    }
  }

  @override
  Future<void> logParticipantRemoved({
    required String tripId,
    required String participantName,
    required String actorName,
  }) async {
    try {
      final activityLog = ActivityLog(
        id: '',
        tripId: tripId,
        type: ActivityType.participantRemoved,
        actorName: actorName.isEmpty ? 'Unknown' : actorName,
        description: 'Removed $participantName from the trip',
        timestamp: DateTime.now(),
        metadata: {'participantName': participantName, 'removedBy': actorName},
      );

      await _logActivity(activityLog);
    } catch (e) {
      _logError('Failed to log participant removed: $e');
    }
  }

  @override
  Future<void> logDeviceVerified({
    required String tripId,
    required String memberName,
    required String deviceCode,
  }) async {
    try {
      final activityLog = ActivityLog(
        id: '',
        tripId: tripId,
        type: ActivityType.deviceVerified,
        actorName: memberName,
        description: '$memberName verified their device',
        timestamp: DateTime.now(),
        metadata: {
          'memberName': memberName,
          'deviceCode': deviceCode.length >= 4
              ? deviceCode.substring(deviceCode.length - 4)
              : deviceCode,
        },
      );

      await _logActivity(activityLog);
    } catch (e) {
      _logError('Failed to log device verified: $e');
    }
  }

  @override
  Future<void> logRecoveryCodeUsed({
    required String tripId,
    required String memberName,
    required int usageCount,
  }) async {
    try {
      final activityLog = ActivityLog(
        id: '',
        tripId: tripId,
        type: ActivityType.recoveryCodeUsed,
        actorName: memberName,
        description: '$memberName used a recovery code to join',
        timestamp: DateTime.now(),
        metadata: {'memberName': memberName, 'usageCount': usageCount},
      );

      await _logActivity(activityLog);
    } catch (e) {
      _logError('Failed to log recovery code used: $e');
    }
  }
}
