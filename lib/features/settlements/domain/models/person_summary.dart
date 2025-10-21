import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';

/// Summary of a person's financial activity in a trip
class PersonSummary extends Equatable {
  final String userId;
  final Decimal totalPaidBase;  // Sum of expenses where user is payer
  final Decimal totalOwedBase;  // Sum of shares where user is participant
  final Decimal netBase;        // totalPaidBase - totalOwedBase

  const PersonSummary({
    required this.userId,
    required this.totalPaidBase,
    required this.totalOwedBase,
    required this.netBase,
  });

  /// Factory constructor from map
  factory PersonSummary.fromMap(String userId, Map<String, dynamic> map) {
    return PersonSummary(
      userId: userId,
      totalPaidBase: Decimal.parse(map['totalPaidBase'] as String),
      totalOwedBase: Decimal.parse(map['totalOwedBase'] as String),
      netBase: Decimal.parse(map['netBase'] as String),
    );
  }

  /// Convert to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'totalPaidBase': totalPaidBase.toString(),
      'totalOwedBase': totalOwedBase.toString(),
      'netBase': netBase.toString(),
    };
  }

  @override
  List<Object?> get props => [userId, totalPaidBase, totalOwedBase, netBase];
}
