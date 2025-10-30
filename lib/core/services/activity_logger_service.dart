import 'package:expense_tracker/features/expenses/domain/models/expense.dart';
import 'package:expense_tracker/features/settlements/domain/models/minimal_transfer.dart';
import 'package:expense_tracker/features/trips/domain/models/trip.dart';

/// Centralized service for activity logging across the application.
///
/// This service encapsulates all activity logging complexity including:
/// - Change detection
/// - Metadata generation
/// - Participant name resolution
/// - Error handling (fire-and-forget pattern)
///
/// All methods follow fire-and-forget pattern - logging failures will never
/// throw exceptions or block the calling code.
abstract class ActivityLoggerService {
  /// Log an expense addition.
  ///
  /// Resolves payer name and creates activity log with expense metadata.
  ///
  /// - [expense]: The expense that was added
  /// - [actorName]: Name of the user who added the expense
  Future<void> logExpenseAdded(Expense expense, String actorName);

  /// Log an expense edit.
  ///
  /// Uses ExpenseChangeDetector to detect all changes and generates rich
  /// metadata with before/after values.
  ///
  /// - [oldExpense]: The expense before editing
  /// - [newExpense]: The expense after editing
  /// - [actorName]: Name of the user who edited the expense
  Future<void> logExpenseEdited(
    Expense oldExpense,
    Expense newExpense,
    String actorName,
  );

  /// Log an expense deletion.
  ///
  /// Creates activity log with expense details in metadata.
  ///
  /// - [expense]: The expense that was deleted
  /// - [actorName]: Name of the user who deleted the expense
  Future<void> logExpenseDeleted(Expense expense, String actorName);

  /// Log a transfer being marked as settled.
  ///
  /// Resolves participant names for from/to users.
  ///
  /// - [transfer]: The transfer that was settled
  /// - [actorName]: Name of the user who marked it settled
  Future<void> logTransferSettled(MinimalTransfer transfer, String actorName);

  /// Log a transfer being marked as unsettled.
  ///
  /// Resolves participant names for from/to users.
  ///
  /// - [transfer]: The transfer that was unsettled
  /// - [actorName]: Name of the user who marked it unsettled
  Future<void> logTransferUnsettled(
    MinimalTransfer transfer,
    String actorName,
  );

  /// Log a member joining a trip.
  ///
  /// Optionally includes inviter information if available.
  ///
  /// - [tripId]: ID of the trip being joined
  /// - [memberName]: Name of the member joining
  /// - [joinMethod]: How they joined (e.g., 'invite_link', 'direct_add')
  /// - [inviterId]: Optional ID of user who invited them
  Future<void> logMemberJoined({
    required String tripId,
    required String memberName,
    required String joinMethod,
    String? inviterId,
  });

  /// Log a trip creation.
  ///
  /// Includes trip name and base currency in metadata.
  ///
  /// - [trip]: The trip that was created
  /// - [creatorName]: Name of the user who created the trip
  Future<void> logTripCreated(Trip trip, String creatorName);

  /// Log trip details being updated (name, currency, etc.).
  ///
  /// Includes change details in metadata.
  ///
  /// - [oldTrip]: The trip before changes
  /// - [newTrip]: The trip after changes
  /// - [actorName]: Name of the user who made the update
  Future<void> logTripUpdated(
    Trip oldTrip,
    Trip newTrip,
    String actorName,
  );

  /// Log a trip being deleted.
  ///
  /// Includes trip name and ID in metadata.
  ///
  /// - [trip]: The trip being deleted
  /// - [actorName]: Name of the user who deleted the trip
  Future<void> logTripDeleted(Trip trip, String actorName);

  /// Log a trip being archived.
  ///
  /// - [trip]: The trip being archived
  /// - [actorName]: Name of the user who archived the trip
  Future<void> logTripArchived(Trip trip, String actorName);

  /// Log a trip being unarchived/restored.
  ///
  /// - [trip]: The trip being unarchived
  /// - [actorName]: Name of the user who unarchived the trip
  Future<void> logTripUnarchived(Trip trip, String actorName);

  /// Log a participant being manually added to a trip.
  ///
  /// This is different from memberJoined - this is when an admin adds someone.
  ///
  /// - [tripId]: ID of the trip
  /// - [participantName]: Name of the participant being added
  /// - [actorName]: Name of the user who added the participant
  Future<void> logParticipantAdded({
    required String tripId,
    required String participantName,
    required String actorName,
  });

  /// Log a participant being removed from a trip.
  ///
  /// - [tripId]: ID of the trip
  /// - [participantName]: Name of the participant being removed
  /// - [actorName]: Name of the user who removed the participant
  Future<void> logParticipantRemoved({
    required String tripId,
    required String participantName,
    required String actorName,
  });

  /// Log a device being successfully verified.
  ///
  /// - [tripId]: ID of the trip
  /// - [memberName]: Name of the member who verified their device
  /// - [deviceCode]: Last 4 characters of the device code (for reference)
  Future<void> logDeviceVerified({
    required String tripId,
    required String memberName,
    required String deviceCode,
  });

  /// Log recovery code usage.
  ///
  /// - [tripId]: ID of the trip
  /// - [memberName]: Name of the member who used the recovery code
  /// - [usageCount]: How many times this code has been used
  Future<void> logRecoveryCodeUsed({
    required String tripId,
    required String memberName,
    required int usageCount,
  });

  /// Clear cached trip context.
  ///
  /// Should be called when switching trips or when trip data changes.
  void clearCache();
}
