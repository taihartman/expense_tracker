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
    final json = <String, dynamic>{
      'name': trip.name,
      'createdAt': Timestamp.fromDate(trip.createdAt),
      'updatedAt': Timestamp.fromDate(trip.updatedAt),
      'lastExpenseModifiedAt': trip.lastExpenseModifiedAt != null
          ? Timestamp.fromDate(trip.lastExpenseModifiedAt!)
          : null,
      'isArchived': trip.isArchived,
      'participants': trip.participants.map((p) => p.toJson()).toList(),
    };

    // Add allowedCurrencies if present (new format)
    if (trip.allowedCurrencies.isNotEmpty) {
      json['allowedCurrencies'] =
          trip.allowedCurrencies.map((c) => c.code).toList();
    }

    // Keep baseCurrency for backward compatibility during migration
    if (trip.baseCurrency != null) {
      json['baseCurrency'] = trip.baseCurrency!.code;
    }

    return json;
  }

  /// Convert Firestore document to Trip domain entity
  static Trip fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Parse participants array (defaults to empty list if not present for backward compatibility)
    final participantsList = data['participants'] as List<dynamic>?;
    final participants = participantsList != null
        ? List<Participant>.from(
            participantsList.map(
              (p) => Participant.fromJson(p as Map<String, dynamic>),
            ),
          )
        : <Participant>[];

    // Parse allowedCurrencies (new format) or migrate from baseCurrency (legacy)
    List<CurrencyCode> allowedCurrencies = [];
    CurrencyCode? baseCurrency;

    if (data.containsKey('allowedCurrencies')) {
      // New format: allowedCurrencies array exists
      final currenciesList = data['allowedCurrencies'] as List<dynamic>?;
      if (currenciesList != null && currenciesList.isNotEmpty) {
        allowedCurrencies = currenciesList
            .map((code) => CurrencyCode.fromString(code as String))
            .whereType<CurrencyCode>() // Filter out nulls
            .toList();
      }
    }

    if (data.containsKey('baseCurrency')) {
      // Parse baseCurrency for backward compatibility
      baseCurrency =
          CurrencyCode.fromString(data['baseCurrency'] as String) ??
              CurrencyCode.usd;

      // If allowedCurrencies is empty but baseCurrency exists, migrate it
      if (allowedCurrencies.isEmpty) {
        allowedCurrencies = [baseCurrency];
      }
    }

    return Trip(
      id: doc.id,
      name: data['name'] as String,
      baseCurrency: baseCurrency,
      allowedCurrencies: allowedCurrencies,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      lastExpenseModifiedAt: data['lastExpenseModifiedAt'] != null
          ? (data['lastExpenseModifiedAt'] as Timestamp).toDate()
          : null,
      isArchived: data['isArchived'] as bool? ?? false,
      participants: participants,
    );
  }

  /// Convert Firestore document snapshot to Trip domain entity
  static Trip fromSnapshot(DocumentSnapshot snapshot) {
    return fromFirestore(snapshot);
  }
}
