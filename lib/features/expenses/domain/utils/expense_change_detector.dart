import '../models/expense.dart';
import '../../../../core/models/participant.dart';

/// Represents all changes detected between two expense versions
class ExpenseChanges {
  final Map<String, dynamic> changes;

  ExpenseChanges(this.changes);

  bool get hasChanges => changes.isNotEmpty;

  /// Returns a structured map suitable for ActivityLog metadata
  Map<String, dynamic> toMetadata(String expenseId) {
    return {'expenseId': expenseId, 'changes': changes};
  }
}

/// Utility class for detecting changes between two expense versions
class ExpenseChangeDetector {
  /// Detects all changes between old and new expense versions
  ///
  /// Returns an [ExpenseChanges] object containing structured before/after
  /// values for all changed fields. Includes participant names (not just IDs)
  /// for better readability in activity logs.
  ///
  /// Tracked fields:
  /// - amount
  /// - currency
  /// - description (text field)
  /// - category (ID and name)
  /// - payer (ID and name)
  /// - date
  /// - splitType
  /// - participants (added/removed/weight changes)
  static ExpenseChanges detectChanges(
    Expense oldExpense,
    Expense newExpense,
    List<Participant> allParticipants,
  ) {
    final changes = <String, dynamic>{};

    // Amount change
    if (oldExpense.amount != newExpense.amount) {
      changes['amount'] = {
        'old': oldExpense.amount.toString(),
        'new': newExpense.amount.toString(),
      };
    }

    // Currency change
    if (oldExpense.currency != newExpense.currency) {
      changes['currency'] = {
        'old': oldExpense.currency.code,
        'new': newExpense.currency.code,
      };
    }

    // Description change
    final oldDesc = oldExpense.description ?? '';
    final newDesc = newExpense.description ?? '';
    if (oldDesc != newDesc) {
      changes['description'] = {
        'old': oldDesc.isEmpty ? 'None' : oldDesc,
        'new': newDesc.isEmpty ? 'None' : newDesc,
      };
    }

    // Category change
    if (oldExpense.categoryId != newExpense.categoryId) {
      changes['category'] = {
        'oldId': oldExpense.categoryId,
        'newId': newExpense.categoryId,
        'oldName': oldExpense.categoryId ?? 'None',
        'newName': newExpense.categoryId ?? 'None',
      };
    }

    // Payer change
    if (oldExpense.payerUserId != newExpense.payerUserId) {
      final oldPayer = allParticipants.firstWhere(
        (p) => p.id == oldExpense.payerUserId,
        orElse: () => Participant(id: oldExpense.payerUserId, name: 'Unknown'),
      );
      final newPayer = allParticipants.firstWhere(
        (p) => p.id == newExpense.payerUserId,
        orElse: () => Participant(id: newExpense.payerUserId, name: 'Unknown'),
      );

      changes['payer'] = {
        'oldId': oldExpense.payerUserId,
        'newId': newExpense.payerUserId,
        'oldName': oldPayer.name,
        'newName': newPayer.name,
      };
    }

    // Date change
    if (!_isSameDay(oldExpense.date, newExpense.date)) {
      changes['date'] = {
        'old': _formatDate(oldExpense.date),
        'new': _formatDate(newExpense.date),
      };
    }

    // Split type change
    if (oldExpense.splitType != newExpense.splitType) {
      changes['splitType'] = {
        'old': oldExpense.splitType.name,
        'new': newExpense.splitType.name,
      };
    }

    // Participants change (added/removed/weight changes)
    final participantChanges = _detectParticipantChanges(
      oldExpense.participants,
      newExpense.participants,
      allParticipants,
    );
    if (participantChanges.isNotEmpty) {
      changes['participants'] = participantChanges;
    }

    return ExpenseChanges(changes);
  }

  /// Detects changes in participants (added/removed/weight changes)
  static Map<String, dynamic> _detectParticipantChanges(
    Map<String, num> oldParticipants,
    Map<String, num> newParticipants,
    List<Participant> allParticipants,
  ) {
    final changes = <String, dynamic>{};

    // Find added participants
    final added = <Map<String, dynamic>>[];
    for (final entry in newParticipants.entries) {
      if (!oldParticipants.containsKey(entry.key)) {
        final participant = allParticipants.firstWhere(
          (p) => p.id == entry.key,
          orElse: () => Participant(id: entry.key, name: 'Unknown'),
        );
        added.add({
          'id': entry.key,
          'name': participant.name,
          'weight': entry.value,
        });
      }
    }
    if (added.isNotEmpty) {
      changes['added'] = added;
    }

    // Find removed participants
    final removed = <Map<String, dynamic>>[];
    for (final entry in oldParticipants.entries) {
      if (!newParticipants.containsKey(entry.key)) {
        final participant = allParticipants.firstWhere(
          (p) => p.id == entry.key,
          orElse: () => Participant(id: entry.key, name: 'Unknown'),
        );
        removed.add({
          'id': entry.key,
          'name': participant.name,
          'weight': entry.value,
        });
      }
    }
    if (removed.isNotEmpty) {
      changes['removed'] = removed;
    }

    // Find weight changes (participants that exist in both but with different weights)
    final weightsChanged = <Map<String, dynamic>>[];
    for (final entry in newParticipants.entries) {
      if (oldParticipants.containsKey(entry.key)) {
        final oldWeight = oldParticipants[entry.key]!;
        final newWeight = entry.value;
        if (oldWeight != newWeight) {
          final participant = allParticipants.firstWhere(
            (p) => p.id == entry.key,
            orElse: () => Participant(id: entry.key, name: 'Unknown'),
          );
          weightsChanged.add({
            'id': entry.key,
            'name': participant.name,
            'oldWeight': oldWeight,
            'newWeight': newWeight,
          });
        }
      }
    }
    if (weightsChanged.isNotEmpty) {
      changes['weightsChanged'] = weightsChanged;
    }

    return changes;
  }

  /// Checks if two dates are on the same day
  static bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  /// Formats a date for display in activity logs
  static String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
