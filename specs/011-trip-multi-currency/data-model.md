# Data Model: Trip Multi-Currency Selection

**Feature**: 011-trip-multi-currency
**Created**: 2025-11-02
**Version**: 1.0

## Overview

This document defines the data model changes for supporting multiple currencies per trip. The primary change is extending the Trip entity to include an `allowedCurrencies` field (list of 1-10 currencies) while maintaining backward compatibility with the legacy `baseCurrency` field during migration.

## Domain Model (Dart)

### Trip Entity (Updated)

**File**: `lib/features/trips/domain/models/trip.dart`

```dart
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

  /// Allowed currencies for this trip (1-10 currencies)
  /// First currency in list is the default for new expenses
  /// REQUIRED: Must have at least 1 currency
  final List<CurrencyCode> allowedCurrencies;  // NEW FIELD

  /// Base currency for trip (DEPRECATED - kept for migration)
  /// Use allowedCurrencies instead. This field will be removed after migration complete.
  @Deprecated('Use allowedCurrencies[0] as default currency')
  final CurrencyCode? baseCurrency;  // CHANGED: nullable for new trips

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
    required this.allowedCurrencies,  // NEW: required parameter
    @Deprecated('Use allowedCurrencies instead') this.baseCurrency,
    required this.createdAt,
    required this.updatedAt,
    this.lastExpenseModifiedAt,
    this.isArchived = false,
    this.participants = const [],
  });

  /// Get the default currency for new expenses (first in allowedCurrencies)
  CurrencyCode get defaultCurrency => allowedCurrencies.first;

  /// Validation rules for trip creation/update
  String? validate() {
    // Name validation (existing)
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      return 'Trip name cannot be empty';
    }
    if (trimmedName.length > 100) {
      return 'Trip name cannot exceed 100 characters';
    }

    // Currency validation (new)
    if (allowedCurrencies.isEmpty) {
      return 'Trip must have at least one currency';
    }
    if (allowedCurrencies.length > 10) {
      return 'Trip cannot have more than 10 currencies';
    }

    // Check for duplicate currencies
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
    List<CurrencyCode>? allowedCurrencies,  // NEW
    @Deprecated('Use allowedCurrencies instead') CurrencyCode? baseCurrency,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastExpenseModifiedAt,
    bool? isArchived,
    List<Participant>? participants,
  }) {
    return Trip(
      id: id ?? this.id,
      name: name ?? this.name,
      allowedCurrencies: allowedCurrencies ?? this.allowedCurrencies,  // NEW
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
    return 'Trip(id: $id, name: $name, '
        'allowedCurrencies: ${allowedCurrencies.map((c) => c.code).join(", ")}, '
        'defaultCurrency: ${defaultCurrency.code}, '
        'createdAt: $createdAt, updatedAt: $updatedAt, '
        'lastExpenseModifiedAt: $lastExpenseModifiedAt, '
        'isArchived: $isArchived, '
        'participants: ${participants.length} participants)';
  }
}
```

**Key Changes**:
1. Added `allowedCurrencies: List<CurrencyCode>` (required, 1-10 elements)
2. Made `baseCurrency` nullable and deprecated (legacy support)
3. Added `defaultCurrency` getter (returns first element of allowedCurrencies)
4. Updated `validate()` to check currency list constraints
5. Updated `copyWith()` to include allowedCurrencies parameter
6. Updated `toString()` to show allowedCurrencies and defaultCurrency

## Data Model (Firestore)

### Trip Document Schema

**Collection**: `trips`
**Document ID**: Auto-generated string

```typescript
interface TripDocument {
  id: string;                      // Auto-generated document ID
  name: string;                    // 1-100 characters, non-empty after trim
  allowedCurrencies: string[];     // NEW: Array of currency codes (1-10 elements)
                                    // Example: ["USD", "EUR", "GBP"]
                                    // First element = default currency
  baseCurrency?: string;           // DEPRECATED: Legacy field (kept during migration)
                                    // Will be removed after all trips migrated
  createdAt: Timestamp;            // Firestore timestamp
  updatedAt: Timestamp;            // Firestore timestamp
  lastExpenseModifiedAt?: Timestamp; // Firestore timestamp (optional)
  isArchived: boolean;             // Default: false
  participants: Participant[];     // Array of participant objects
}
```

**Example Documents**:

**New Trip (after feature deployed)**:
```json
{
  "id": "trip_abc123",
  "name": "Europe 2025",
  "allowedCurrencies": ["EUR", "CHF", "GBP"],
  "createdAt": "2025-11-02T10:00:00Z",
  "updatedAt": "2025-11-02T10:00:00Z",
  "isArchived": false,
  "participants": [...]
}
```

**Migrated Trip (legacy baseCurrency converted)**:
```json
{
  "id": "trip_xyz789",
  "name": "Vietnam 2024",
  "allowedCurrencies": ["VND"],
  "baseCurrency": "VND",
  "createdAt": "2024-06-15T08:30:00Z",
  "updatedAt": "2025-11-02T12:00:00Z",
  "isArchived": false,
  "participants": [...]
}
```

**Legacy Trip (before migration)**:
```json
{
  "id": "trip_old456",
  "name": "Japan 2023",
  "baseCurrency": "JPY",
  "createdAt": "2023-09-01T14:20:00Z",
  "updatedAt": "2023-09-01T14:20:00Z",
  "isArchived": false,
  "participants": [...]
}
```

## Serialization Model (TripModel)

**File**: `lib/features/trips/data/models/trip_model.dart`

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/models/currency_code.dart';
import '../../../../core/models/participant.dart';
import '../../domain/models/trip.dart';

/// Firestore serialization model for Trip
class TripModel {
  final String id;
  final String name;
  final List<String>? allowedCurrencies;  // NEW: Firestore array
  final String? baseCurrency;  // LEGACY: kept for migration
  final Timestamp createdAt;
  final Timestamp updatedAt;
  final Timestamp? lastExpenseModifiedAt;
  final bool isArchived;
  final List<Map<String, dynamic>> participants;

  TripModel({
    required this.id,
    required this.name,
    this.allowedCurrencies,  // NEW: optional (for legacy trips)
    this.baseCurrency,  // LEGACY
    required this.createdAt,
    required this.updatedAt,
    this.lastExpenseModifiedAt,
    this.isArchived = false,
    this.participants = const [],
  });

  /// Convert Firestore document to TripModel
  factory TripModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return TripModel(
      id: doc.id,
      name: data['name'] as String,
      allowedCurrencies: (data['allowedCurrencies'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),  // NEW: deserialize array
      baseCurrency: data['baseCurrency'] as String?,  // LEGACY
      createdAt: data['createdAt'] as Timestamp,
      updatedAt: data['updatedAt'] as Timestamp,
      lastExpenseModifiedAt: data['lastExpenseModifiedAt'] as Timestamp?,
      isArchived: data['isArchived'] as bool? ?? false,
      participants: (data['participants'] as List<dynamic>?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList() ?? [],
    );
  }

  /// Convert TripModel to Firestore document data
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'allowedCurrencies': allowedCurrencies,  // NEW: array of strings
      if (baseCurrency != null) 'baseCurrency': baseCurrency,  // LEGACY: only if present
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      if (lastExpenseModifiedAt != null) 'lastExpenseModifiedAt': lastExpenseModifiedAt,
      'isArchived': isArchived,
      'participants': participants,
    };
  }

  /// Convert TripModel to domain Trip entity
  Trip toDomain() {
    // Migration logic: if allowedCurrencies exists, use it; else fallback to baseCurrency
    List<CurrencyCode> currencies;
    
    if (allowedCurrencies != null && allowedCurrencies!.isNotEmpty) {
      // New format: use allowedCurrencies array
      currencies = allowedCurrencies!
          .map((code) => CurrencyCodeExtension.fromCode(code))
          .whereType<CurrencyCode>()  // Filter out invalid codes
          .toList();
      
      if (currencies.isEmpty) {
        throw Exception('Trip $id has invalid currency codes in allowedCurrencies');
      }
    } else if (baseCurrency != null) {
      // Legacy format: convert baseCurrency to single-element list
      final currency = CurrencyCodeExtension.fromCode(baseCurrency!);
      if (currency == null) {
        throw Exception('Trip $id has invalid baseCurrency: $baseCurrency');
      }
      currencies = [currency];
    } else {
      // Missing both fields: data corruption
      throw Exception('Trip $id missing both allowedCurrencies and baseCurrency');
    }

    return Trip(
      id: id,
      name: name,
      allowedCurrencies: currencies,  // NEW
      baseCurrency: baseCurrency != null 
          ? CurrencyCodeExtension.fromCode(baseCurrency!)
          : null,  // LEGACY: preserve for migration period
      createdAt: createdAt.toDate(),
      updatedAt: updatedAt.toDate(),
      lastExpenseModifiedAt: lastExpenseModifiedAt?.toDate(),
      isArchived: isArchived,
      participants: participants
          .map((p) => Participant.fromJson(p))
          .toList(),
    );
  }

  /// Create TripModel from domain Trip entity
  factory TripModel.fromDomain(Trip trip) {
    return TripModel(
      id: trip.id,
      name: trip.name,
      allowedCurrencies: trip.allowedCurrencies
          .map((c) => c.code)
          .toList(),  // NEW: convert List<CurrencyCode> to List<String>
      baseCurrency: trip.baseCurrency?.code,  // LEGACY: preserve if present
      createdAt: Timestamp.fromDate(trip.createdAt),
      updatedAt: Timestamp.fromDate(trip.updatedAt),
      lastExpenseModifiedAt: trip.lastExpenseModifiedAt != null
          ? Timestamp.fromDate(trip.lastExpenseModifiedAt!)
          : null,
      isArchived: trip.isArchived,
      participants: trip.participants
          .map((p) => p.toJson())
          .toList(),
    );
  }
}
```

**Key Points**:
1. `allowedCurrencies` is optional (null for legacy trips before migration)
2. `toDomain()` handles migration logic: use allowedCurrencies if present, else fall back to baseCurrency
3. `fromDomain()` always populates allowedCurrencies (for new/updated trips)
4. Invalid currency codes are filtered out (graceful degradation)
5. Throws exception if trip has neither field (data corruption)

## Validation Rules

### Client-Side Validation (Trip.validate())

1. **Minimum 1 currency**: `allowedCurrencies.length >= 1`
   - Error message: "Trip must have at least one currency"

2. **Maximum 10 currencies**: `allowedCurrencies.length <= 10`
   - Error message: "Trip cannot have more than 10 currencies"

3. **No duplicates**: `allowedCurrencies.toSet().length == allowedCurrencies.length`
   - Error message: "Duplicate currencies are not allowed"

4. **Valid currency codes**: All codes exist in CurrencyCode enum
   - Handled by type system (CurrencyCode enum ensures validity)

5. **Name validation** (existing): 1-100 characters, non-empty after trim

### Server-Side Validation (Firestore Security Rules)

```javascript
// firestore.rules (to be added after migration complete)
match /trips/{tripId} {
  allow create: if request.auth != null 
                && request.resource.data.allowedCurrencies is list
                && request.resource.data.allowedCurrencies.size() >= 1
                && request.resource.data.allowedCurrencies.size() <= 10;
                
  allow update: if request.auth != null
                && request.resource.data.allowedCurrencies is list
                && request.resource.data.allowedCurrencies.size() >= 1
                && request.resource.data.allowedCurrencies.size() <= 10;
}
```

**Note**: Security rules update is deferred until after migration completes (to allow legacy trips).

## Migration Logic

### Cloud Function (TypeScript)

**File**: `functions/src/migrations/migrate-trip-currencies.ts`

```typescript
import * as admin from 'firebase-admin';

interface MigrationResult {
  success: boolean;
  tripId: string;
  reason?: string;
}

export async function migrateTripCurrencies(): Promise<{
  total: number;
  successful: number;
  failed: number;
  results: MigrationResult[];
}> {
  const db = admin.firestore();
  const tripsRef = db.collection('trips');
  
  // Query trips without allowedCurrencies field
  const snapshot = await tripsRef
    .where('allowedCurrencies', '==', null)
    .get();
  
  const results: MigrationResult[] = [];
  let successful = 0;
  let failed = 0;
  
  for (const doc of snapshot.docs) {
    const data = doc.data();
    const baseCurrency = data.baseCurrency;
    
    // Skip if missing baseCurrency
    if (!baseCurrency) {
      console.error(`Trip ${doc.id} missing baseCurrency, skipping`);
      results.push({
        success: false,
        tripId: doc.id,
        reason: 'missing baseCurrency'
      });
      failed++;
      continue;
    }
    
    try {
      // Update trip with allowedCurrencies = [baseCurrency]
      await doc.ref.update({
        allowedCurrencies: [baseCurrency],
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });
      
      console.log(`Migrated trip ${doc.id}: ${baseCurrency} → [${baseCurrency}]`);
      results.push({
        success: true,
        tripId: doc.id
      });
      successful++;
      
    } catch (error) {
      console.error(`Failed to migrate trip ${doc.id}:`, error);
      results.push({
        success: false,
        tripId: doc.id,
        reason: error.message
      });
      failed++;
    }
  }
  
  return {
    total: snapshot.size,
    successful,
    failed,
    results
  };
}
```

**Migration Execution**:
1. Deploy Cloud Function to Firebase
2. Trigger manually via HTTP endpoint or Cloud Scheduler
3. Function queries all trips without `allowedCurrencies` field
4. For each trip: read `baseCurrency`, update with `allowedCurrencies = [baseCurrency]`
5. Log results (total, successful, failed, trip IDs)
6. Manual fix for failed trips (if any)

## Impact on Related Entities

### Expense Entity

**No changes required** - Expense entity still has single `currency` field.

**Validation change**: When creating/editing an expense, validate that `expense.currency` is in `trip.allowedCurrencies` (for new expenses). Existing expenses can keep their original currency even if not in allowed list.

### Settlement Calculations

**No changes to algorithm** - Settlement calculations work per currency.

**UI change**: Settlements page shows separate views per currency in `trip.allowedCurrencies`. Each view runs the existing settlement algorithm filtered to that currency's expenses.

### Activity Logs

**Optional enhancement**: Log when user adds/removes currencies from trip.

**Example log entry**:
```
"Sarah added EUR and GBP to allowed currencies"
"John removed CHF from allowed currencies"
```

## Testing Data

### Test Case 1: New Trip with Multiple Currencies

```dart
final trip = Trip(
  id: 'test_trip_1',
  name: 'Europe Vacation',
  allowedCurrencies: [CurrencyCode.eur, CurrencyCode.chf, CurrencyCode.gbp],
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
);

// Validation should pass
expect(trip.validate(), isNull);

// Default currency should be EUR (first in list)
expect(trip.defaultCurrency, equals(CurrencyCode.eur));
```

### Test Case 2: Validation Errors

```dart
// Test minimum 1 currency
final noActiveCurrencies = Trip(
  id: 'test_trip_2',
  name: 'Invalid Trip',
  allowedCurrencies: [],  // Empty list
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
);
expect(noActiveCurrencies.validate(), contains('at least one currency'));

// Test maximum 10 currencies
final tooManyCurrencies = Trip(
  id: 'test_trip_3',
  name: 'Invalid Trip',
  allowedCurrencies: List.generate(11, (i) => CurrencyCode.values[i]),  // 11 currencies
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
);
expect(tooManyCurrencies.validate(), contains('more than 10 currencies'));

// Test duplicates
final duplicates = Trip(
  id: 'test_trip_4',
  name: 'Invalid Trip',
  allowedCurrencies: [CurrencyCode.usd, CurrencyCode.eur, CurrencyCode.usd],  // USD twice
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
);
expect(duplicates.validate(), contains('Duplicate currencies'));
```

### Test Case 3: Migration (Legacy Trip)

```dart
// Simulate legacy trip from Firestore
final legacyDoc = {
  'id': 'legacy_trip',
  'name': 'Old Trip',
  'baseCurrency': 'USD',
  'createdAt': Timestamp.now(),
  'updatedAt': Timestamp.now(),
  'isArchived': false,
  'participants': [],
  // Note: NO allowedCurrencies field
};

final tripModel = TripModel.fromFirestore(/* mock doc with legacyDoc data */);
final trip = tripModel.toDomain();

// Should convert baseCurrency to allowedCurrencies
expect(trip.allowedCurrencies, equals([CurrencyCode.usd]));
expect(trip.defaultCurrency, equals(CurrencyCode.usd));
```

## Backward Compatibility

### During Migration Period

**Legacy trips** (before migration):
- Firestore: has `baseCurrency`, no `allowedCurrencies`
- App behavior: TripModel.toDomain() converts to `allowedCurrencies = [baseCurrency]`
- User experience: No change (still sees one currency)

**Migrated trips** (after migration):
- Firestore: has both `baseCurrency` and `allowedCurrencies`
- App behavior: Uses `allowedCurrencies`, ignores `baseCurrency`
- User experience: Can now add more currencies

**New trips** (after feature deployed):
- Firestore: has `allowedCurrencies`, may or may not have `baseCurrency`
- App behavior: Uses `allowedCurrencies`
- User experience: Full multi-currency support

### After Migration Complete

**Future cleanup** (30 days after migration):
1. Remove `baseCurrency` field from new trip creation
2. Update Firestore security rules to require `allowedCurrencies`
3. Remove fallback logic from TripModel.toDomain()
4. Remove `@Deprecated` annotation from Trip.baseCurrency
5. Eventually remove `baseCurrency` field entirely (breaking change, major version bump)

---

**Data Model Version**: 1.0 | **Created**: 2025-11-02 | **Status**: Draft
