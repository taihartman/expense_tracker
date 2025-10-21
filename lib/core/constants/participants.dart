import '../models/participant.dart';

/// Fixed list of participants for expense tracking
/// IDs match Firestore document references and are used across all trips
///
/// MVP participants: Tai, Khiet, Bob, Ethan, Ryan, Izzy
class Participants {
  static const List<Participant> all = [
    Participant(id: 'tai', name: 'Tai'),
    Participant(id: 'khiet', name: 'Khiet'),
    Participant(id: 'bob', name: 'Bob'),
    Participant(id: 'ethan', name: 'Ethan'),
    Participant(id: 'ryan', name: 'Ryan'),
    Participant(id: 'izzy', name: 'Izzy'),
  ];

  /// Get participant by ID
  static Participant? getById(String id) {
    try {
      return all.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get participant name by ID (fallback to ID if not found)
  static String getNameById(String id) {
    return getById(id)?.name ?? id;
  }

  /// Get all participant IDs
  static List<String> get allIds => all.map((p) => p.id).toList();
}

/// Alias for backwards compatibility with tests
const kFixedParticipants = Participants.all;
