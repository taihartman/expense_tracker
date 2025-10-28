import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';
import 'assignment_mode.dart';

/// Defines how a line item is assigned to participants
///
/// Supports even split (equal shares) or custom shares (weighted distribution)
class ItemAssignment extends Equatable {
  /// Assignment mode (even or custom)
  final AssignmentMode mode;

  /// List of user IDs who share this item
  /// Must have at least 1 user
  final List<String> users;

  /// Custom shares for each user (only for custom mode)
  /// - Keys must match users list
  /// - Values must sum to 1.0 (±0.01 tolerance)
  /// - All values must be positive
  /// - Must be null for even mode
  final Map<String, Decimal>? shares;

  const ItemAssignment({
    required this.mode,
    required this.users,
    this.shares,
  });

  /// Validate assignment
  ///
  /// Returns error message if invalid, null if valid
  String? validate() {
    // Must have at least one user
    if (users.isEmpty) {
      return 'At least one user is required';
    }

    if (mode == AssignmentMode.even) {
      // Even mode: shares must be null
      if (shares != null) {
        return 'Even mode cannot have custom shares';
      }
    } else if (mode == AssignmentMode.custom) {
      // Custom mode: shares required
      if (shares == null) {
        return 'Custom mode requires shares';
      }

      // Keys must match users
      final shareKeys = shares!.keys.toSet();
      final userSet = users.toSet();
      if (!shareKeys.containsAll(userSet) || !userSet.containsAll(shareKeys)) {
        return 'Share keys must match users list';
      }

      // All shares must be positive
      if (shares!.values.any((share) => share <= Decimal.zero)) {
        return 'All shares must be positive';
      }

      // Shares must sum to 1.0 (±0.01 tolerance)
      final sum = shares!.values.fold(Decimal.zero, (a, b) => a + b);
      final diff = (sum - Decimal.one).abs();
      if (diff > Decimal.parse('0.01')) {
        return 'Shares must sum to 1.0 (current sum: $sum)';
      }
    }

    return null;
  }

  /// Create a copy with updated fields
  ItemAssignment copyWith({
    AssignmentMode? mode,
    List<String>? users,
    Map<String, Decimal>? shares,
  }) {
    return ItemAssignment(
      mode: mode ?? this.mode,
      users: users ?? this.users,
      shares: shares ?? this.shares,
    );
  }

  @override
  List<Object?> get props => [mode, users, shares];

  @override
  String toString() {
    return 'ItemAssignment(mode: $mode, users: ${users.length}, shares: $shares)';
  }
}
