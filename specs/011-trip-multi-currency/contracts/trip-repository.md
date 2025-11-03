# Contract: TripRepository (Updated)

**Feature**: 011-trip-multi-currency
**Component**: Domain Repository Interface
**Created**: 2025-11-02

## Purpose

This contract defines the updated TripRepository interface for multi-currency support. The repository now handles trips with `allowedCurrencies` field while maintaining backward compatibility with legacy `baseCurrency` field during the migration period.

## Interface Updates

### File Location

`lib/features/trips/domain/repositories/trip_repository.dart`

### Updated Interface

```dart
import '../models/trip.dart';
import '../models/verified_member.dart';
import '../../../../core/models/currency_code.dart';

/// Repository interface for Trip operations
///
/// Defines the contract for trip data access
/// Implementation uses Firestore (see data/repositories/trip_repository_impl.dart)
abstract class TripRepository {
  /// Create a new trip
  /// Returns the created trip with generated ID
  Future<Trip> createTrip(Trip trip);

  /// Get a trip by ID
  /// Returns null if trip doesn't exist
  /// Handles legacy trips (baseCurrency → allowedCurrencies conversion)
  Future<Trip?> getTripById(String tripId);

  /// Get all trips
  /// Returns list ordered by createdAt descending (newest first)
  /// Handles legacy trips (baseCurrency → allowedCurrencies conversion)
  Stream<List<Trip>> getAllTrips();

  /// Update an existing trip
  /// Returns the updated trip
  /// Supports updating allowedCurrencies field
  Future<Trip> updateTrip(Trip trip);

  /// Delete a trip by ID
  /// Note: In MVP, deletion is not exposed in UI
  Future<void> deleteTrip(String tripId);

  /// Check if a trip exists
  Future<bool> tripExists(String tripId);

  /// Get allowed currencies for a trip (NEW)
  /// Returns list of currencies allowed for this trip (1-10 currencies)
  /// First currency in list is the default for new expenses
  /// Handles legacy trips (returns [baseCurrency] if allowedCurrencies not set)
  Future<List<CurrencyCode>> getAllowedCurrencies(String tripId);

  /// Update allowed currencies for a trip (NEW)
  /// Validates: 1-10 currencies, no duplicates, valid currency codes
  /// Throws [ArgumentError] if validation fails
  /// Updates trip.allowedCurrencies field in Firestore
  Future<void> updateAllowedCurrencies({
    required String tripId,
    required List<CurrencyCode> currencies,
  });

  /// Add a verified member to a trip
  /// Called when a participant successfully joins via device pairing or recovery code
  /// Stores verification status in Firestore for cross-device visibility
  Future<void> addVerifiedMember({
    required String tripId,
    required String participantId,
    required String participantName,
  });

  /// Get all verified members for a trip
  /// Returns list of participants who have verified their identity
  /// Ordered by verifiedAt descending (most recent first)
  Future<List<VerifiedMember>> getVerifiedMembers(String tripId);

  /// Remove a verified member (for leaving trip functionality)
  /// Note: Not exposed in MVP UI
  Future<void> removeVerifiedMember({
    required String tripId,
    required String participantId,
  });
}
```

### New Methods

#### getAllowedCurrencies

**Purpose**: Retrieve the list of allowed currencies for a trip (read-only access).

**Signature**:
```dart
Future<List<CurrencyCode>> getAllowedCurrencies(String tripId);
```

**Parameters**:
- `tripId`: Trip document ID

**Returns**: 
- `List<CurrencyCode>` - Ordered list of allowed currencies (1-10 elements)
- First element is the default currency for new expenses

**Behavior**:
- If trip has `allowedCurrencies` field: return it
- If trip has only `baseCurrency` field (legacy): return `[baseCurrency]`
- If trip doesn't exist: throw `TripNotFoundException`
- If trip has neither field (data corruption): throw `DataIntegrityException`

**Example**:
```dart
final currencies = await tripRepository.getAllowedCurrencies('trip_123');
// Returns: [CurrencyCode.usd, CurrencyCode.eur, CurrencyCode.gbp]

final defaultCurrency = currencies.first;  // CurrencyCode.usd
```

**Error Cases**:
```dart
// Trip not found
try {
  await tripRepository.getAllowedCurrencies('invalid_id');
} catch (e) {
  // Throws: TripNotFoundException('Trip invalid_id not found')
}

// Data corruption (missing both fields)
try {
  await tripRepository.getAllowedCurrencies('corrupted_trip');
} catch (e) {
  // Throws: DataIntegrityException('Trip corrupted_trip missing currency data')
}
```

#### updateAllowedCurrencies

**Purpose**: Update the list of allowed currencies for a trip.

**Signature**:
```dart
Future<void> updateAllowedCurrencies({
  required String tripId,
  required List<CurrencyCode> currencies,
});
```

**Parameters**:
- `tripId`: Trip document ID
- `currencies`: New list of allowed currencies (1-10 elements, ordered)

**Returns**: `void` (success) or throws exception on error

**Validation**:
1. **Minimum 1 currency**: `currencies.length >= 1`
   - Throws: `ArgumentError('Trip must have at least one currency')`
   
2. **Maximum 10 currencies**: `currencies.length <= 10`
   - Throws: `ArgumentError('Trip cannot have more than 10 currencies')`
   
3. **No duplicates**: `currencies.toSet().length == currencies.length`
   - Throws: `ArgumentError('Duplicate currencies are not allowed')`
   
4. **Trip exists**: `await tripExists(tripId) == true`
   - Throws: `TripNotFoundException('Trip $tripId not found')`

**Behavior**:
1. Validate input (see above)
2. Update Firestore: `trips/{tripId}` document
   - Set `allowedCurrencies` field to `currencies.map((c) => c.code).toList()`
   - Set `updatedAt` to server timestamp
3. Preserve `baseCurrency` field (if present) for backward compatibility
4. Return on success

**Example**:
```dart
// Valid update
await tripRepository.updateAllowedCurrencies(
  tripId: 'trip_123',
  currencies: [CurrencyCode.usd, CurrencyCode.eur, CurrencyCode.gbp],
);
// Success - Firestore updated

// Invalid update (too many)
try {
  await tripRepository.updateAllowedCurrencies(
    tripId: 'trip_123',
    currencies: List.generate(11, (i) => CurrencyCode.values[i]),
  );
} catch (e) {
  // Throws: ArgumentError('Trip cannot have more than 10 currencies')
}

// Invalid update (duplicates)
try {
  await tripRepository.updateAllowedCurrencies(
    tripId: 'trip_123',
    currencies: [CurrencyCode.usd, CurrencyCode.eur, CurrencyCode.usd],
  );
} catch (e) {
  // Throws: ArgumentError('Duplicate currencies are not allowed')
}
```

**Performance**:
- Single Firestore write operation
- Update propagates via Firestore listener to getAllTrips() stream
- Expect <500ms from method call to UI update (SC-006)

## Implementation Specifications

### TripRepositoryImpl Updates

**File**: `lib/features/trips/data/repositories/trip_repository_impl.dart`

#### getAllowedCurrencies Implementation

```dart
@override
Future<List<CurrencyCode>> getAllowedCurrencies(String tripId) async {
  final trip = await getTripById(tripId);
  
  if (trip == null) {
    throw TripNotFoundException('Trip $tripId not found');
  }
  
  // TripModel.toDomain() already handles migration logic
  // (allowedCurrencies or [baseCurrency] fallback)
  return trip.allowedCurrencies;
}
```

**Notes**:
- Reuses existing `getTripById()` method (DRY principle)
- Migration logic handled in `TripModel.toDomain()` (see data-model.md)

#### updateAllowedCurrencies Implementation

```dart
@override
Future<void> updateAllowedCurrencies({
  required String tripId,
  required List<CurrencyCode> currencies,
}) async {
  // Validation
  if (currencies.isEmpty) {
    throw ArgumentError('Trip must have at least one currency');
  }
  if (currencies.length > 10) {
    throw ArgumentError('Trip cannot have more than 10 currencies');
  }
  
  final uniqueCurrencies = currencies.toSet();
  if (uniqueCurrencies.length != currencies.length) {
    throw ArgumentError('Duplicate currencies are not allowed');
  }
  
  // Check trip exists
  final tripExists = await this.tripExists(tripId);
  if (!tripExists) {
    throw TripNotFoundException('Trip $tripId not found');
  }
  
  // Update Firestore
  final docRef = _firestore.collection('trips').doc(tripId);
  await docRef.update({
    'allowedCurrencies': currencies.map((c) => c.code).toList(),
    'updatedAt': FieldValue.serverTimestamp(),
  });
  
  // No return value needed (void)
}
```

**Notes**:
- Validation duplicates Trip.validate() for safety (defense in depth)
- Uses Firestore transaction for atomicity (optional, but recommended)
- Does NOT remove baseCurrency field (backward compatibility)

### Migration Logic (Already Handled)

Migration logic is **NOT** in the repository layer. It is handled in two places:

1. **TripModel.toDomain()**: Client-side fallback (see data-model.md)
   - If `allowedCurrencies` exists: use it
   - Else if `baseCurrency` exists: return `[baseCurrency]`
   - Else: throw exception (data corruption)

2. **Cloud Functions**: Server-side migration (see cloud-function.md contract)
   - One-time job to migrate all trips
   - Updates Firestore directly (bypasses repository layer)

## Error Handling

### Custom Exceptions

**File**: `lib/features/trips/domain/exceptions/trip_exceptions.dart` (NEW)

```dart
/// Thrown when a trip is not found by ID
class TripNotFoundException implements Exception {
  final String message;
  const TripNotFoundException(this.message);
  
  @override
  String toString() => 'TripNotFoundException: $message';
}

/// Thrown when trip data is corrupted (missing required fields)
class DataIntegrityException implements Exception {
  final String message;
  const DataIntegrityException(this.message);
  
  @override
  String toString() => 'DataIntegrityException: $message';
}
```

### Error Cases

| Scenario | Error Type | Message |
|----------|------------|---------|
| Trip not found | `TripNotFoundException` | "Trip {id} not found" |
| Empty currency list | `ArgumentError` | "Trip must have at least one currency" |
| >10 currencies | `ArgumentError` | "Trip cannot have more than 10 currencies" |
| Duplicate currencies | `ArgumentError` | "Duplicate currencies are not allowed" |
| Missing both fields | `DataIntegrityException` | "Trip {id} missing currency data" |
| Firestore write failure | `FirebaseException` | (Firebase error message) |

## Testing Contract

### Unit Tests

**File**: `test/features/trips/data/repositories/trip_repository_impl_test.dart`

```dart
group('TripRepositoryImpl - Multi-Currency', () {
  late TripRepositoryImpl repository;
  late MockFirebaseFirestore mockFirestore;
  
  setUp(() {
    mockFirestore = MockFirebaseFirestore();
    repository = TripRepositoryImpl(firestore: mockFirestore);
  });
  
  group('getAllowedCurrencies', () {
    test('returns allowedCurrencies when field exists', () async {
      // Mock trip with allowedCurrencies = [USD, EUR]
      final currencies = await repository.getAllowedCurrencies('trip_1');
      expect(currencies, equals([CurrencyCode.usd, CurrencyCode.eur]));
    });
    
    test('returns [baseCurrency] for legacy trip', () async {
      // Mock trip with only baseCurrency = USD
      final currencies = await repository.getAllowedCurrencies('trip_legacy');
      expect(currencies, equals([CurrencyCode.usd]));
    });
    
    test('throws TripNotFoundException when trip missing', () async {
      expect(
        () => repository.getAllowedCurrencies('invalid_id'),
        throwsA(isA<TripNotFoundException>()),
      );
    });
    
    test('throws DataIntegrityException when both fields missing', () async {
      // Mock trip with neither allowedCurrencies nor baseCurrency
      expect(
        () => repository.getAllowedCurrencies('corrupted_trip'),
        throwsA(isA<DataIntegrityException>()),
      );
    });
  });
  
  group('updateAllowedCurrencies', () {
    test('updates Firestore with valid currencies', () async {
      await repository.updateAllowedCurrencies(
        tripId: 'trip_1',
        currencies: [CurrencyCode.usd, CurrencyCode.eur],
      );
      
      // Verify Firestore update called
      verify(mockFirestore.collection('trips').doc('trip_1').update({
        'allowedCurrencies': ['USD', 'EUR'],
        'updatedAt': any,
      })).called(1);
    });
    
    test('throws ArgumentError when empty list', () async {
      expect(
        () => repository.updateAllowedCurrencies(
          tripId: 'trip_1',
          currencies: [],
        ),
        throwsArgumentError,
      );
    });
    
    test('throws ArgumentError when >10 currencies', () async {
      final tooMany = List.generate(11, (i) => CurrencyCode.values[i]);
      expect(
        () => repository.updateAllowedCurrencies(
          tripId: 'trip_1',
          currencies: tooMany,
        ),
        throwsArgumentError,
      );
    });
    
    test('throws ArgumentError when duplicates', () async {
      expect(
        () => repository.updateAllowedCurrencies(
          tripId: 'trip_1',
          currencies: [CurrencyCode.usd, CurrencyCode.usd],
        ),
        throwsArgumentError,
      );
    });
    
    test('throws TripNotFoundException when trip missing', () async {
      // Mock tripExists() to return false
      expect(
        () => repository.updateAllowedCurrencies(
          tripId: 'invalid_id',
          currencies: [CurrencyCode.usd],
        ),
        throwsA(isA<TripNotFoundException>()),
      );
    });
  });
});
```

### Integration Tests

- Create trip with multiple currencies → verify Firestore document
- Update trip currencies → verify changes reflected in getAllTrips() stream
- Create legacy trip (baseCurrency only) → verify getAllowedCurrencies() returns fallback

## Backward Compatibility

### Legacy Trip Handling

**Before Migration**:
- Trip has only `baseCurrency` field
- `getAllowedCurrencies('trip_id')` returns `[baseCurrency]`
- `updateAllowedCurrencies('trip_id', [EUR])` updates to new format (adds allowedCurrencies field)

**After Migration**:
- Trip has both `allowedCurrencies` and `baseCurrency` fields
- `getAllowedCurrencies('trip_id')` returns `allowedCurrencies`
- `baseCurrency` ignored (but preserved for rollback safety)

**Future Cleanup**:
- After 30 days: remove baseCurrency field from new trips
- After 60 days: remove baseCurrency fallback logic
- After 90 days: remove baseCurrency field entirely (breaking change)

## Performance Considerations

### getAllowedCurrencies

- **Firestore read**: 1 document fetch (~50-100ms)
- **Deserialization**: Trivial (array → List<CurrencyCode>)
- **Total**: <100ms expected

### updateAllowedCurrencies

- **Validation**: In-memory (<1ms)
- **Firestore write**: 1 document update (~100-300ms)
- **Listener propagation**: Automatic (Firestore real-time listener)
- **UI update**: <500ms expected (SC-006)

## Dependencies

### Internal

- Trip domain model (updated with allowedCurrencies)
- TripModel data model (updated serialization)
- CurrencyCode enum (from feature 010)

### External

- cloud_firestore: Firestore access
- Firebase SDK: Authentication, timestamps

---

**Contract Version**: 1.0 | **Created**: 2025-11-02 | **Status**: Draft
