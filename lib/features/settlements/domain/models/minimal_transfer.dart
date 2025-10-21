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

  const MinimalTransfer({
    required this.id,
    required this.tripId,
    required this.fromUserId,
    required this.toUserId,
    required this.amountBase,
    required this.computedAt,
  });

  @override
  List<Object?> get props => [id, tripId, fromUserId, toUserId, amountBase, computedAt];
}
