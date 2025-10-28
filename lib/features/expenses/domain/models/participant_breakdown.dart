import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';
import 'item_contribution.dart';

/// Complete per-person breakdown for itemized expense
///
/// Provides full audit trail showing:
/// - Item subtotal (sum of assigned item shares)
/// - Allocated extras (tax, tip, fees, discounts)
/// - Rounding adjustment (if remainder was assigned to this person)
/// - Final total
/// - Item-by-item contributions
class ParticipantBreakdown extends Equatable {
  /// User ID of this participant
  final String userId;

  /// Sum of assigned item shares (before extras)
  final Decimal itemsSubtotal;

  /// Allocated extras breakdown
  /// Keys: 'tax', 'tip', 'fee_DeliveryFee', 'discount_Coupon', etc.
  /// Values: Decimal amounts allocated to this person
  final Map<String, Decimal> extrasAllocated;

  /// Rounding adjustment (if any)
  /// Positive if this person received the remainder, zero otherwise
  final Decimal roundedAdjustment;

  /// Final total amount this person owes
  /// itemsSubtotal + sum(extrasAllocated.values) + roundedAdjustment
  final Decimal total;

  /// Item-by-item contribution details
  final List<ItemContribution> items;

  const ParticipantBreakdown({
    required this.userId,
    required this.itemsSubtotal,
    required this.extrasAllocated,
    required this.roundedAdjustment,
    required this.total,
    required this.items,
  });

  @override
  List<Object?> get props => [
    userId,
    itemsSubtotal,
    extrasAllocated,
    roundedAdjustment,
    total,
    items,
  ];

  @override
  String toString() {
    return 'ParticipantBreakdown(userId: $userId, itemsSubtotal: $itemsSubtotal, total: $total)';
  }
}
