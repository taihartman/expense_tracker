import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/models/currency_code.dart';
import '../../domain/models/settlement_summary.dart';
import '../../domain/models/person_summary.dart';

/// Firestore model for SettlementSummary
///
/// Handles serialization/deserialization between Firestore documents and domain entities
class SettlementSummaryModel {
  /// Convert SettlementSummary to Firestore JSON
  static Map<String, dynamic> toJson(SettlementSummary summary) {
    // Convert map of PersonSummary to map of maps
    final personSummariesMap = <String, Map<String, dynamic>>{};
    summary.personSummaries.forEach((userId, personSummary) {
      personSummariesMap[userId] = personSummary.toMap();
    });

    return {
      'tripId': summary.tripId,
      'baseCurrency': summary.baseCurrency.name,
      'personSummaries': personSummariesMap,
      'lastComputedAt': Timestamp.fromDate(summary.lastComputedAt),
    };
  }

  /// Convert Firestore document to SettlementSummary domain entity
  static SettlementSummary fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Parse personSummaries map
    final personSummariesData = data['personSummaries'] as Map<String, dynamic>;
    final personSummaries = <String, PersonSummary>{};

    personSummariesData.forEach((userId, summaryMap) {
      personSummaries[userId] = PersonSummary.fromMap(
        userId,
        summaryMap as Map<String, dynamic>,
      );
    });

    return SettlementSummary(
      tripId: data['tripId'] as String,
      baseCurrency: CurrencyCode.values.firstWhere(
        (c) => c.name == data['baseCurrency'],
      ),
      personSummaries: personSummaries,
      lastComputedAt: (data['lastComputedAt'] as Timestamp).toDate(),
    );
  }
}
