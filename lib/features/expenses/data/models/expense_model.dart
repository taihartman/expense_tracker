import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:decimal/decimal.dart';
import '../../../../core/models/currency_code.dart';
import '../../../../core/models/split_type.dart';
import '../../domain/models/expense.dart';

/// Firestore model for Expense entity
///
/// Handles serialization/deserialization between domain entity and Firestore documents
class ExpenseModel {
  /// Convert Expense domain entity to Firestore JSON
  static Map<String, dynamic> toJson(Expense expense) {
    return {
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
  }

  /// Convert Firestore document to Expense domain entity
  static Expense fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Expense(
      id: doc.id,
      tripId: data['tripId'] as String,
      date: (data['date'] as Timestamp).toDate(),
      payerUserId: data['payerUserId'] as String,
      currency: CurrencyCode.fromString(data['currency'] as String) ??
          CurrencyCode.usd,
      amount: Decimal.parse(data['amount'] as String),
      description: data['description'] as String?,
      categoryId: data['categoryId'] as String?,
      splitType:
          SplitType.fromString(data['splitType'] as String) ?? SplitType.equal,
      participants: Map<String, num>.from(data['participants'] as Map),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  /// Convert Firestore document snapshot to Expense domain entity
  static Expense fromSnapshot(DocumentSnapshot snapshot) {
    return fromFirestore(snapshot);
  }
}
