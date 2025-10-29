import '../../../../core/models/currency_code.dart';
import '../../../../core/models/participant.dart';

/// Trip domain entity
///
/// Represents a travel event with associated expenses and participants
class Trip {
  /// Unique identifier (auto-generated)
  final String id;

  /// User-provided trip name (e.g., "Vietnam 2025")
  /// Required, 1-100 characters, non-empty after trim
  final String name;

  /// Base currency for trip (USD or VND)
  final CurrencyCode baseCurrency;

  /// When the trip was created (immutable)
  final DateTime createdAt;

  /// When the trip was last updated
  final DateTime updatedAt;

  /// When any expense was last added/modified/deleted for this trip
  /// Used for smart settlement refresh to detect if recomputation is needed
  final DateTime? lastExpenseModifiedAt;

  /// Whether this trip is archived (hidden from main trip list)
  final bool isArchived;

  /// Participants specific to this trip
  /// Empty list means no participants configured yet (needs migration)
  final List<Participant> participants;

  const Trip({
    required this.id,
    required this.name,
    required this.baseCurrency,
    required this.createdAt,
    required this.updatedAt,
    this.lastExpenseModifiedAt,
    this.isArchived = false,
    this.participants = const [],
  });

  /// Validation rules for trip creation/update
  String? validate() {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      return 'Trip name cannot be empty';
    }
    if (trimmedName.length > 100) {
      return 'Trip name cannot exceed 100 characters';
    }
    return null;
  }

  /// Create a copy of this trip with updated fields
  Trip copyWith({
    String? id,
    String? name,
    CurrencyCode? baseCurrency,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastExpenseModifiedAt,
    bool? isArchived,
    List<Participant>? participants,
  }) {
    return Trip(
      id: id ?? this.id,
      name: name ?? this.name,
      baseCurrency: baseCurrency ?? this.baseCurrency,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastExpenseModifiedAt:
          lastExpenseModifiedAt ?? this.lastExpenseModifiedAt,
      isArchived: isArchived ?? this.isArchived,
      participants: participants ?? this.participants,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Trip && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Trip(id: $id, name: $name, baseCurrency: $baseCurrency, '
        'createdAt: $createdAt, updatedAt: $updatedAt, '
        'lastExpenseModifiedAt: $lastExpenseModifiedAt, '
        'isArchived: $isArchived, '
        'participants: ${participants.length} participants)';
  }
}
