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
  /// @deprecated Use [allowedCurrencies] instead. Retained for backward compatibility during migration.
  @Deprecated('Use allowedCurrencies instead')
  final CurrencyCode? baseCurrency;

  /// Allowed currencies for this trip (1-10 currencies)
  /// The first currency in the list is the default for new expenses
  final List<CurrencyCode> allowedCurrencies;

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
    @Deprecated('Use allowedCurrencies instead') this.baseCurrency,
    this.allowedCurrencies = const [],
    required this.createdAt,
    required this.updatedAt,
    this.lastExpenseModifiedAt,
    this.isArchived = false,
    this.participants = const [],
  });

  /// Get the default currency for new expenses (first in allowedCurrencies list)
  /// Falls back to baseCurrency for legacy trips during migration
  CurrencyCode get defaultCurrency {
    if (allowedCurrencies.isNotEmpty) {
      return allowedCurrencies.first;
    }
    // Fallback to baseCurrency for legacy trips
    if (baseCurrency != null) {
      return baseCurrency!;
    }
    // Ultimate fallback (should never happen in production)
    return CurrencyCode.usd;
  }

  /// Validation rules for trip creation/update
  String? validate() {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      return 'Trip name cannot be empty';
    }
    if (trimmedName.length > 100) {
      return 'Trip name cannot exceed 100 characters';
    }

    // Validate allowedCurrencies (1-10 currencies)
    if (allowedCurrencies.isEmpty && baseCurrency == null) {
      return 'At least one currency is required';
    }
    if (allowedCurrencies.length > 10) {
      return 'Maximum 10 currencies allowed';
    }

    // Check for duplicates in allowedCurrencies
    final uniqueCurrencies = allowedCurrencies.toSet();
    if (uniqueCurrencies.length != allowedCurrencies.length) {
      return 'Duplicate currencies are not allowed';
    }

    return null;
  }

  /// Create a copy of this trip with updated fields
  Trip copyWith({
    String? id,
    String? name,
    @Deprecated('Use allowedCurrencies instead') CurrencyCode? baseCurrency,
    List<CurrencyCode>? allowedCurrencies,
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
      allowedCurrencies: allowedCurrencies ?? this.allowedCurrencies,
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
    final currencyInfo = allowedCurrencies.isNotEmpty
        ? 'allowedCurrencies: $allowedCurrencies'
        : 'baseCurrency: $baseCurrency (legacy)';
    return 'Trip(id: $id, name: $name, $currencyInfo, '
        'createdAt: $createdAt, updatedAt: $updatedAt, '
        'lastExpenseModifiedAt: $lastExpenseModifiedAt, '
        'isArchived: $isArchived, '
        'participants: ${participants.length} participants)';
  }
}
