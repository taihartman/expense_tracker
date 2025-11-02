/// Exception thrown when a trip is not found
class TripNotFoundException implements Exception {
  final String tripId;
  final String? message;

  TripNotFoundException(this.tripId, {this.message});

  @override
  String toString() {
    final msg = message ?? 'Trip not found';
    return 'TripNotFoundException: $msg (tripId: $tripId)';
  }
}

/// Exception thrown when data integrity is compromised
/// (e.g., trip has neither baseCurrency nor allowedCurrencies)
class DataIntegrityException implements Exception {
  final String message;
  final String? tripId;
  final Map<String, dynamic>? details;

  DataIntegrityException(
    this.message, {
    this.tripId,
    this.details,
  });

  @override
  String toString() {
    final buffer = StringBuffer('DataIntegrityException: $message');
    if (tripId != null) {
      buffer.write(' (tripId: $tripId)');
    }
    if (details != null && details!.isNotEmpty) {
      buffer.write(' - Details: $details');
    }
    return buffer.toString();
  }
}
