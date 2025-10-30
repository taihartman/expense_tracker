// Utilities for generating shareable deep links

import '../config/app_config.dart';
import '../../features/trips/domain/models/trip.dart';
import '../../features/trips/domain/models/verified_member.dart';

/// Generates a shareable link for joining a trip
///
/// The generated link uses the format: {baseUrl}/#/trips/join?code={tripId}
/// The hash (#) is required for SPA routing.
/// When clicked, it will navigate to the join page with the trip ID pre-filled.
///
/// Optional [sharedBy] parameter tracks which member shared this invite (for activity logs).
///
/// Example:
/// ```dart
/// final link = generateShareableLink('trip-abc-123', sharedBy: 'participant-id');
/// // Returns: https://expenses.taihartman.com/#/trips/join?code=trip-abc-123&sharedBy=participant-id
/// ```
String generateShareableLink(String tripId, {String? sharedBy}) {
  var url = '${AppConfig.appBaseUrl}/#/trips/join?code=$tripId';
  if (sharedBy != null && sharedBy.isNotEmpty) {
    url += '&sharedBy=$sharedBy';
  }
  return url;
}

/// Generates a QR code link for joining a trip
///
/// Similar to [generateShareableLink] but includes a 'source=qr' parameter
/// to distinguish QR code scans from direct link clicks in activity logs.
///
/// Example:
/// ```dart
/// final qrLink = generateQrCodeLink('trip-abc-123', sharedBy: 'participant-id');
/// // Returns: https://expenses.taihartman.com/#/trips/join?code=trip-abc-123&source=qr&sharedBy=participant-id
/// ```
String generateQrCodeLink(String tripId, {String? sharedBy}) {
  var url = '${AppConfig.appBaseUrl}/#/trips/join?code=$tripId&source=qr';
  if (sharedBy != null && sharedBy.isNotEmpty) {
    url += '&sharedBy=$sharedBy';
  }
  return url;
}

/// Generates a human-sounding, personalized invite message
///
/// Creates a friendly message showing trip details and verified members.
/// The message format adapts based on how many verified members exist.
///
/// Optional [sharedByParticipantId] parameter tracks who shared this invite.
///
/// Example:
/// ```dart
/// final message = generateShareMessage(
///   trip: myTrip,
///   verifiedMembers: [member1, member2, member3],
///   sharedByParticipantId: 'participant-id',
/// );
/// ```
String generateShareMessage({
  required Trip trip,
  required List<VerifiedMember> verifiedMembers,
  String? sharedByParticipantId,
}) {
  final link = generateShareableLink(trip.id, sharedBy: sharedByParticipantId);
  final currency = trip.baseCurrency.name;

  // Build participant context line
  final participantContext = _buildParticipantContext(
    verifiedMembers: verifiedMembers,
    currency: currency,
  );

  return 'Hey! I\'m using Expense Tracker for our \'${trip.name}\' trip and wanted to invite you to join.\n\n'
      '$participantContext\n\n'
      'Join here: $link\n\n'
      'Or use this code if the link doesn\'t work: ${trip.id}';
}

/// Builds the participant context line based on verified member count
///
/// Formats:
/// - 0 members: "I'm tracking our expenses in USD. Be the first to join!"
/// - 1-2 members: "Tai and Khiet are tracking expenses in USD."
/// - 3+ members: "Tai, Khiet and 4 others are already tracking expenses in USD."
String _buildParticipantContext({
  required List<VerifiedMember> verifiedMembers,
  required String currency,
}) {
  if (verifiedMembers.isEmpty) {
    return 'I\'m tracking our expenses in $currency. Be the first to join!';
  }

  // Sort by verified date (most recent first) and take first 2-3 names
  final sortedMembers = List<VerifiedMember>.from(verifiedMembers)
    ..sort((a, b) => b.verifiedAt.compareTo(a.verifiedAt));

  if (sortedMembers.length == 1) {
    return '${sortedMembers[0].participantName} is tracking expenses in $currency.';
  }

  if (sortedMembers.length == 2) {
    return '${sortedMembers[0].participantName} and ${sortedMembers[1].participantName} are tracking expenses in $currency.';
  }

  // 3+ members: show first 2 names + "and X others"
  final firstTwo = sortedMembers
      .take(2)
      .map((m) => m.participantName)
      .join(', ');
  final remaining = sortedMembers.length - 2;

  return '$firstTwo and $remaining ${remaining == 1 ? 'other' : 'others'} are already tracking expenses in $currency.';
}

/// Legacy function for backward compatibility
///
/// Deprecated: Use generateShareMessage() with Trip and VerifiedMember instead.
@Deprecated('Use generateShareMessage() with Trip and verifiedMembers')
String generateShareMessageLegacy({
  required String tripName,
  required String inviteCode,
}) {
  final link = generateShareableLink(inviteCode);
  return 'Join my trip \'$tripName\' on Expense Tracker!\n\n'
      'Use code: $inviteCode\n'
      'Or click: $link';
}
