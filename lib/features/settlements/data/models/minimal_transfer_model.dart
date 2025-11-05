import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:decimal/decimal.dart';
import '../../domain/models/minimal_transfer.dart';
import '../../../../core/models/currency_code.dart';

/// Firestore model for MinimalTransfer
///
/// Handles serialization/deserialization between Firestore documents and domain entities
class MinimalTransferModel {
  /// Convert MinimalTransfer to Firestore JSON
  static Map<String, dynamic> toJson(MinimalTransfer transfer) {
    return {
      'tripId': transfer.tripId,
      'fromUserId': transfer.fromUserId,
      'toUserId': transfer.toUserId,
      'amountBase': transfer.amountBase.toString(),
      'currency': transfer.currency?.code,
      'computedAt': Timestamp.fromDate(transfer.computedAt),
      'isSettled': transfer.isSettled,
      'settledAt': transfer.settledAt != null
          ? Timestamp.fromDate(transfer.settledAt!)
          : null,
    };
  }

  /// Convert Firestore document to MinimalTransfer domain entity
  static MinimalTransfer fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Parse currency if available
    CurrencyCode? currency;
    if (data['currency'] != null) {
      try {
        currency = CurrencyCode.fromCode(data['currency'] as String);
      } catch (e) {
        // If currency parsing fails, leave as null (backward compatibility)
        currency = null;
      }
    }

    return MinimalTransfer(
      id: doc.id,
      tripId: data['tripId'] as String,
      fromUserId: data['fromUserId'] as String,
      toUserId: data['toUserId'] as String,
      amountBase: Decimal.parse(data['amountBase'] as String),
      currency: currency,
      computedAt: (data['computedAt'] as Timestamp).toDate(),
      isSettled: data['isSettled'] as bool? ?? false,
      settledAt: data['settledAt'] != null
          ? (data['settledAt'] as Timestamp).toDate()
          : null,
    );
  }
}
