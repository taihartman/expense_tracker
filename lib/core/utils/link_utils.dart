// Utilities for generating shareable deep links

/// Base URL for the expense tracker app
///
/// In production, this would be the actual deployed URL.
/// For GitHub Pages: https://{username}.github.io/expense_tracker/
const String _baseUrl = 'https://expense-tracker.app';

/// Generates a shareable link for joining a trip
///
/// The generated link uses the format: {baseUrl}/trips/join?code={tripId}
/// When clicked, it will navigate to the join page with the trip ID pre-filled.
///
/// Example:
/// ```dart
/// final link = generateShareableLink('trip-abc-123');
/// // Returns: https://expense-tracker.app/trips/join?code=trip-abc-123
/// ```
String generateShareableLink(String tripId) {
  return '$_baseUrl/trips/join?code=$tripId';
}

/// Generates a shareable message for inviting someone to a trip
///
/// Example:
/// ```dart
/// final message = generateShareMessage(tripName: 'Vietnam 2025', inviteCode: 'trip-abc-123');
/// // Returns: "Join my trip 'Vietnam 2025' on Expense Tracker!
/// //          Use code: trip-abc-123
/// //          Or click: https://expense-tracker.app/trips/join?code=trip-abc-123"
/// ```
String generateShareMessage({
  required String tripName,
  required String inviteCode,
}) {
  final link = generateShareableLink(inviteCode);
  return 'Join my trip \'$tripName\' on Expense Tracker!\n\n'
      'Use code: $inviteCode\n'
      'Or click: $link';
}
