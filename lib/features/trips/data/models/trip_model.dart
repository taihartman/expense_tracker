import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/models/currency_code.dart';
import '../../../../core/models/participant.dart';
import '../../domain/models/trip.dart';

/// Firestore model for Trip entity
///
/// Handles serialization/deserialization between domain entity and Firestore documents
class TripModel {
  /// Convert Trip domain entity to Firestore JSON
  static Map<String, dynamic> toJson(Trip trip) {
    return {
      'name': trip.name,
      'baseCurrency': trip.baseCurrency.code,
      'createdAt': Timestamp.fromDate(trip.createdAt),
      'updatedAt': Timestamp.fromDate(trip.updatedAt),
      'participants': trip.participants.map((p) => p.toJson()).toList(),
    };
  }

  /// Convert Firestore document to Trip domain entity
  static Trip fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Parse participants array (defaults to empty list if not present for backward compatibility)
    final participantsList = data['participants'] as List<dynamic>?;
    final participants = participantsList != null
        ? participantsList
            .map((p) => Participant.fromJson(p as Map<String, dynamic>))
            .toList()
        : <Participant>[];

    return Trip(
      id: doc.id,
      name: data['name'] as String,
      baseCurrency: CurrencyCode.fromString(data['baseCurrency'] as String) ??
          CurrencyCode.usd,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      participants: participants,
    );
  }

  /// Convert Firestore document snapshot to Trip domain entity
  static Trip fromSnapshot(DocumentSnapshot snapshot) {
    return fromFirestore(snapshot);
  }
}
