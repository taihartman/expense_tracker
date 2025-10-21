import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';

/// Represents netted debt between two participants
class PairwiseDebt extends Equatable {
  final String id;
  final String tripId;
  final String fromUserId;  // Who owes
  final String toUserId;    // Who is owed
  final Decimal nettedBase; // Amount owed in base currency
  final DateTime computedAt;

  const PairwiseDebt({
    required this.id,
    required this.tripId,
    required this.fromUserId,
    required this.toUserId,
    required this.nettedBase,
    required this.computedAt,
  });

  @override
  List<Object?> get props => [id, tripId, fromUserId, toUserId, nettedBase, computedAt];
}
