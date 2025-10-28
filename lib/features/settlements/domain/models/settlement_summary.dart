import 'package:equatable/equatable.dart';
import '../../../../core/models/currency_code.dart';
import 'person_summary.dart';

/// Complete settlement summary for a trip
class SettlementSummary extends Equatable {
  final String tripId;
  final CurrencyCode baseCurrency;
  final Map<String, PersonSummary> personSummaries;
  final DateTime lastComputedAt;

  const SettlementSummary({
    required this.tripId,
    required this.baseCurrency,
    required this.personSummaries,
    required this.lastComputedAt,
  });

  @override
  List<Object?> get props => [
    tripId,
    baseCurrency,
    personSummaries,
    lastComputedAt,
  ];
}
