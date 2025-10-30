# Contract: ActivityLoggerService Interface

**Version**: 1.0.0
**Date**: 2025-10-30
**Status**: Draft

## Purpose

This contract defines the public interface for the ActivityLoggerService. All implementations must adhere to this contract to ensure consistent behavior across the application.

## Interface Definition

```dart
abstract class ActivityLoggerService {
  Future<void> logExpenseAdded({
    required Expense expense,
    required String actorName,
  });

  Future<void> logExpenseEdited({
    required Expense oldExpense,
    required Expense newExpense,
    required String actorName,
  });

  Future<void> logExpenseDeleted({
    required String expenseId,
    required String expenseDescription,
    required Decimal amount,
    required String currency,
    required String tripId,
    required String actorName,
  });

  Future<void> logTransferSettled({
    required String fromParticipantId,
    required String toParticipantId,
    required Decimal amount,
    required String currency,
    required String tripId,
    required String actorName,
  });

  Future<void> logTransferUnsettled({
    required String fromParticipantId,
    required String toParticipantId,
    required Decimal amount,
    required String currency,
    required String tripId,
    required String actorName,
  });

  Future<void> logMemberJoined({
    required String participantId,
    required String tripId,
    required String actorName,
    required JoinMethod joinMethod,
    String? invitedByParticipantId,
  });

  Future<void> logTripCreated({
    required Trip trip,
    required String actorName,
  });

  void clearCache();
}
```

## Method Contracts

### logExpenseAdded

**Purpose**: Log when a new expense is created

**Preconditions**:
- `expense` must be a valid Expense object with non-null tripId
- `actorName` must be a non-empty string

**Postconditions**:
- An ActivityLog with type `ActivityType.expenseAdded` is created in Firestore
- Log includes metadata: expenseId, amount, currency, payerId, payerName

**Error Handling**:
- All exceptions caught internally
- Errors logged to debug console
- Never throws exceptions to caller

**Performance**:
- First call for a trip: ~250ms (includes cache miss)
- Subsequent calls: ~100ms (uses cached trip data)

---

### logExpenseEdited

**Purpose**: Log when an existing expense is updated, with automatic change detection

**Preconditions**:
- `oldExpense` and `newExpense` must be valid Expense objects
- Both expenses must belong to the same trip (same tripId)
- `actorName` must be a non-empty string

**Postconditions**:
- An ActivityLog with type `ActivityType.expenseEdited` is created
- Changes are detected using ExpenseChangeDetector
- Log includes metadata with all detected changes (amount, currency, payer, etc.)

**Error Handling**:
- All exceptions caught internally
- Errors logged to debug console
- Never throws exceptions to caller

**Performance**:
- First call for a trip: ~260ms (includes change detection + cache miss)
- Subsequent calls: ~110ms (uses cached trip data)

---

### logExpenseDeleted

**Purpose**: Log when an expense is deleted

**Preconditions**:
- `expenseId` must be a non-empty string
- `expenseDescription` can be empty (will show as "(no description)")
- `amount` must be a valid Decimal
- `currency` must be a valid currency code
- `tripId` must be a non-empty string
- `actorName` must be a non-empty string

**Postconditions**:
- An ActivityLog with type `ActivityType.expenseDeleted` is created
- Log includes metadata: expenseId, description, amount, currency

**Error Handling**:
- All exceptions caught internally
- Errors logged to debug console
- Never throws exceptions to caller

**Performance**:
- ~105ms (no trip context needed, only repository write)

---

### logTransferSettled

**Purpose**: Log when a transfer between participants is marked as settled

**Preconditions**:
- `fromParticipantId` and `toParticipantId` must be non-empty strings
- Participants must exist in the trip (graceful degradation if not found)
- `amount` must be a valid Decimal
- `currency` must be a valid currency code
- `tripId` must be a non-empty string
- `actorName` must be a non-empty string

**Postconditions**:
- An ActivityLog with type `ActivityType.transferMarkedSettled` is created
- Log includes metadata: fromId, fromName, toId, toName, amount, currency

**Error Handling**:
- All exceptions caught internally
- If participants not found, uses "Unknown" as name
- Errors logged to debug console
- Never throws exceptions to caller

**Performance**:
- First call for a trip: ~255ms (includes cache miss)
- Subsequent calls: ~105ms (uses cached trip data)

---

### logTransferUnsettled

**Purpose**: Log when a settled transfer is marked as unsettled

**Contract**: Same as logTransferSettled, except:
- Activity type is `ActivityType.transferMarkedUnsettled`
- Description says "unsettled" instead of "settled"

---

### logMemberJoined

**Purpose**: Log when a participant joins a trip

**Preconditions**:
- `participantId` must be a non-empty string
- `tripId` must be a non-empty string
- `actorName` must be a non-empty string (same as participant's name)
- `joinMethod` must be a valid JoinMethod enum value
- `invitedByParticipantId` is optional (null if self-joined)

**Postconditions**:
- An ActivityLog with type `ActivityType.memberJoined` is created
- Log includes metadata: participantId, joinMethod, invitedBy (if applicable)
- If invitedBy is provided, includes inviter's name from trip context

**Error Handling**:
- All exceptions caught internally
- If inviter not found, continues without inviter name
- Errors logged to debug console
- Never throws exceptions to caller

**Performance**:
- Without invitedBy: ~105ms
- With invitedBy (first call): ~255ms (cache miss)
- With invitedBy (subsequent): ~105ms (cached)

---

### logTripCreated

**Purpose**: Log when a new trip is created

**Preconditions**:
- `trip` must be a valid Trip object with non-empty id and name
- `actorName` must be a non-empty string

**Postconditions**:
- An ActivityLog with type `ActivityType.tripCreated` is created
- Log includes metadata: tripName, baseCurrency

**Error Handling**:
- All exceptions caught internally
- Errors logged to debug console
- Never throws exceptions to caller

**Performance**:
- ~105ms (no trip context needed for new trips)

---

### clearCache

**Purpose**: Manually clear the internal trip context cache

**Preconditions**: None

**Postconditions**:
- Internal cache is set to null
- Next logging operation will fetch fresh trip data

**Error Handling**: N/A (synchronous operation, cannot fail)

**Performance**: <1ms (in-memory operation)

**Use Cases**:
- Switching between trips
- After updating trip participants
- After detecting stale data (optional - cache auto-expires after 5 minutes)

## Data Structures

### Input Types

All input types are existing domain models:

- `Expense`: `lib/features/expenses/domain/models/expense.dart`
- `Trip`: `lib/features/trips/domain/models/trip.dart`
- `JoinMethod`: `lib/features/trips/domain/models/activity_log.dart` (enum)
- `Decimal`: From `decimal` package (for monetary amounts)

### Output Types

All methods return `Future<void>` (fire-and-forget pattern).

### Activity Log Structure

All methods create an `ActivityLog` object:

```dart
ActivityLog(
  id: '',  // Auto-generated by Firestore
  tripId: String,
  type: ActivityType,  // Specific to each method
  actorName: String,
  description: String,  // Human-readable description
  timestamp: DateTime.now(),
  metadata: Map<String, dynamic>?,  // Optional, method-specific
)
```

## Implementation Requirements

### MUST Requirements

1. **Non-blocking**: All methods must handle errors internally (fire-and-forget)
2. **Caching**: Must cache trip context data with 5-minute TTL
3. **Error logging**: Must log errors to debug console (using `debugPrint`)
4. **Change detection**: Must use ExpenseChangeDetector for expense edits
5. **Participant names**: Must include both IDs and human-readable names in metadata
6. **Performance**: Must meet performance targets (<50ms overhead after caching)

### SHOULD Requirements

1. **Graceful degradation**: If trip data unavailable, log with available data
2. **Consistent formatting**: Follow existing description patterns in activity logs
3. **Descriptive metadata**: Include relevant context for future querying/reporting

### MUST NOT Requirements

1. **MUST NOT throw exceptions**: Callers should never need try-catch blocks
2. **MUST NOT block operations**: Logging failures should not affect main operations
3. **MUST NOT modify input objects**: All inputs are read-only

## Testing Requirements

### Unit Tests

Each method must have unit tests covering:
- ✅ Happy path (successful logging)
- ✅ Repository failure (error caught and logged)
- ✅ Cache hit scenario (trip data reused)
- ✅ Cache miss scenario (trip data fetched)
- ✅ Cache expiration (fresh fetch after TTL)
- ✅ Invalid/missing trip data (graceful degradation)

### Integration Tests

End-to-end tests must verify:
- ✅ Activity log persisted to Firestore
- ✅ Metadata structure matches expectations
- ✅ Multiple operations in sequence use cache correctly
- ✅ Switching trips clears cache

### Performance Tests

Benchmarks must verify:
- ✅ First call per trip ≤ 300ms
- ✅ Cached calls ≤ 150ms
- ✅ Bulk operations (10+ logs) complete within 2 seconds

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0.0 | 2025-10-30 | Initial interface definition |

## Breaking Change Policy

Changes to this interface are considered **breaking changes** if they:
- Remove or rename methods
- Change method signatures (parameters, return types)
- Change error handling behavior (start throwing exceptions)
- Change performance characteristics significantly (>2x slower)

Breaking changes require:
1. Major version bump (1.x.x → 2.0.0)
2. Migration guide for all cubits using the service
3. Deprecation period (keep old methods for one release)
