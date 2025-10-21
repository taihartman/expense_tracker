import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';

/// Optimal transfer minimizing number of transactions
class MinimalTransfer extends Equatable {
  final String id;
  final String tripId;
  final String fromUserId;  // Who pays
  final String toUserId;    // Who receives
  final Decimal amountBase; // Transfer amount in base currency
  final DateTime computedAt;
  final bool isSettled;     // Whether this transfer has been marked as settled
  final DateTime? settledAt; // When this transfer was marked as settled

  const MinimalTransfer({
    required this.id,
    required this.tripId,
    required this.fromUserId,
    required this.toUserId,
    required this.amountBase,
    required this.computedAt,
    this.isSettled = false,
    this.settledAt,
  });

  @override
  List<Object?> get props => [id, tripId, fromUserId, toUserId, amountBase, computedAt, isSettled, settledAt];

  /// Create a copy with updated fields
  MinimalTransfer copyWith({
    String? id,
    String? tripId,
    String? fromUserId,
    String? toUserId,
    Decimal? amountBase,
    DateTime? computedAt,
    bool? isSettled,
    DateTime? settledAt,
  }) {
    return MinimalTransfer(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      fromUserId: fromUserId ?? this.fromUserId,
      toUserId: toUserId ?? this.toUserId,
      amountBase: amountBase ?? this.amountBase,
      computedAt: computedAt ?? this.computedAt,
      isSettled: isSettled ?? this.isSettled,
      settledAt: settledAt ?? this.settledAt,
    );
  }
}
