/// Participant value object
///
/// Represents a person who can pay for or owe expenses
/// MVP: Fixed list of 6 participants (Tai, Khiet, Bob, Ethan, Ryan, Izzy)
class Participant {
  /// Unique identifier (lowercase alphanumeric, e.g., "tai", "khiet")
  final String id;

  /// Display name (e.g., "Tai", "Khiet")
  final String name;

  const Participant({
    required this.id,
    required this.name,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Participant &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Participant(id: $id, name: $name)';
}
