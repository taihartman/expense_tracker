// Utilities for formatting timestamps

/// Formats a DateTime to a relative time string
///
/// Examples:
/// - "Just now" (< 1 minute ago)
/// - "2 minutes ago"
/// - "1 hour ago"
/// - "Yesterday"
/// - "2 days ago"
/// - "Oct 29" (this year)
/// - "Oct 29, 2024" (previous year)
String formatRelativeTime(DateTime dateTime) {
  final now = DateTime.now();
  final difference = now.difference(dateTime);

  // Just now (< 1 minute)
  if (difference.inMinutes < 1) {
    return 'Just now';
  }

  // Minutes ago (< 1 hour)
  if (difference.inHours < 1) {
    final minutes = difference.inMinutes;
    return '$minutes ${minutes == 1 ? 'minute' : 'minutes'} ago';
  }

  // Hours ago (< 24 hours)
  if (difference.inHours < 24) {
    final hours = difference.inHours;
    return '$hours ${hours == 1 ? 'hour' : 'hours'} ago';
  }

  // Yesterday
  final yesterday = DateTime(now.year, now.month, now.day - 1);
  final dateOnly = DateTime(dateTime.year, dateTime.month, dateTime.day);
  if (dateOnly.isAtSameMomentAs(yesterday)) {
    return 'Yesterday';
  }

  // Days ago (< 7 days)
  if (difference.inDays < 7) {
    final days = difference.inDays;
    return '$days ${days == 1 ? 'day' : 'days'} ago';
  }

  // Same year: "Oct 29"
  if (dateTime.year == now.year) {
    return _formatMonthDay(dateTime);
  }

  // Different year: "Oct 29, 2024"
  return '${_formatMonthDay(dateTime)}, ${dateTime.year}';
}

/// Formats absolute timestamp for tooltip
/// Example: "Oct 29, 2025 2:30 PM"
String formatAbsoluteTime(DateTime dateTime) {
  final hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
  final minute = dateTime.minute.toString().padLeft(2, '0');
  final period = dateTime.hour < 12 ? 'AM' : 'PM';

  return '${_formatMonthDay(dateTime)}, ${dateTime.year} $hour:$minute $period';
}

String _formatMonthDay(DateTime dateTime) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[dateTime.month - 1]} ${dateTime.day}';
}
