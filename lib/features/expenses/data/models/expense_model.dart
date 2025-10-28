import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:decimal/decimal.dart';
import '../../../../core/models/currency_code.dart';
import '../../../../core/models/split_type.dart';
import '../../domain/models/expense.dart';
import 'line_item_model.dart';
import 'extras_model.dart';
import 'allocation_rule_model.dart';
import 'participant_breakdown_model.dart';

/// Firestore model for Expense entity
///
/// Handles serialization/deserialization between domain entity and Firestore documents
class ExpenseModel {
  /// Convert Expense domain entity to Firestore JSON
  static Map<String, dynamic> toJson(Expense expense) {
    final json = {
      'tripId': expense.tripId,
      'date': Timestamp.fromDate(expense.date),
      'payerUserId': expense.payerUserId,
      'currency': expense.currency.code,
      'amount': expense.amount.toString(), // Store as string for precision
      'description': expense.description,
      'categoryId': expense.categoryId,
      'splitType': expense.splitType.name,
      'participants': expense.participants,
      'createdAt': Timestamp.fromDate(expense.createdAt),
      'updatedAt': Timestamp.fromDate(expense.updatedAt),
    };

    // Add optional itemized fields (backward compatible)
    if (expense.items != null) {
      json['items'] = expense.items!
          .map((item) => LineItemModel.toJson(item))
          .toList();
    }
    if (expense.extras != null) {
      json['extras'] = ExtrasModel.toJson(expense.extras!);
    }
    if (expense.allocation != null) {
      json['allocation'] = AllocationRuleModel.toJson(expense.allocation!);
    }
    if (expense.participantAmounts != null) {
      // Convert Map<String, Decimal> to Map<String, String>
      json['participantAmounts'] = expense.participantAmounts!.map(
        (key, value) => MapEntry(key, value.toString()),
      );
    }
    if (expense.participantBreakdown != null) {
      json['participantBreakdown'] = expense.participantBreakdown!.map(
        (key, value) => MapEntry(key, ParticipantBreakdownModel.toJson(value)),
      );
    }

    return json;
  }

  /// Convert Firestore document to Expense domain entity
  static Expense fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Expense(
      id: doc.id,
      tripId: data['tripId'] as String,
      date: (data['date'] as Timestamp).toDate(),
      payerUserId: data['payerUserId'] as String,
      currency:
          CurrencyCode.fromString(data['currency'] as String) ??
          CurrencyCode.usd,
      amount: Decimal.parse(data['amount'] as String),
      description: data['description'] as String?,
      categoryId: data['categoryId'] as String?,
      splitType:
          SplitType.fromString(data['splitType'] as String) ?? SplitType.equal,
      participants: Map<String, num>.from(data['participants'] as Map),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      // Optional itemized fields (backward compatible - null if not present)
      items: data.containsKey('items') && data['items'] != null
          ? (data['items'] as List)
                .map(
                  (item) =>
                      LineItemModel.fromJson(item as Map<String, dynamic>),
                )
                .toList()
          : null,
      extras: data.containsKey('extras') && data['extras'] != null
          ? ExtrasModel.fromJson(data['extras'] as Map<String, dynamic>)
          : null,
      allocation: data.containsKey('allocation') && data['allocation'] != null
          ? AllocationRuleModel.fromJson(
              data['allocation'] as Map<String, dynamic>,
            )
          : null,
      participantAmounts:
          data.containsKey('participantAmounts') &&
              data['participantAmounts'] != null
          ? (data['participantAmounts'] as Map<String, dynamic>).map(
              (key, value) => MapEntry(key, Decimal.parse(value as String)),
            )
          : null,
      participantBreakdown:
          data.containsKey('participantBreakdown') &&
              data['participantBreakdown'] != null
          ? (data['participantBreakdown'] as Map<String, dynamic>).map(
              (key, value) => MapEntry(
                key,
                ParticipantBreakdownModel.fromJson(
                  value as Map<String, dynamic>,
                ),
              ),
            )
          : null,
    );
  }

  /// Convert Firestore document snapshot to Expense domain entity
  static Expense fromSnapshot(DocumentSnapshot snapshot) {
    return fromFirestore(snapshot);
  }
}
