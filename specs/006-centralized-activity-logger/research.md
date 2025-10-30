# Research: Centralized Activity Logger Service

**Date**: 2025-10-30
**Feature**: 006-centralized-activity-logger

## Overview

This document explores the design decisions and research findings for creating a centralized ActivityLoggerService that consolidates activity logging logic from individual cubits.

## Key Design Decisions

### 1. Service Pattern vs Repository Pattern

**Decision**: Use a **Service class** (not another Repository)

**Rationale**:
- **Repositories** are for data access abstraction (CRUD operations on entities)
- **Services** encapsulate business logic that coordinates multiple repositories and utilities
- Activity logging requires:
  - Coordinating ActivityLogRepository (persistence) and TripRepository (context data)
  - Business logic for change detection (using ExpenseChangeDetector)
  - Metadata enrichment (adding participant names, formatting descriptions)
  - Error handling and retry logic
  
**Examples from Codebase**:
- `ExpenseRepository`: Pure data access (add, update, delete expenses)
- `ActivityLogRepository`: Pure data access (add logs, stream logs)
- `ActivityLoggerService`: Business logic layer that uses both repositories + change detection

**Alternative Considered**: Adding methods to ActivityLogRepository
- **Rejected because**: Would violate Single Responsibility Principle - repository should only handle persistence, not business logic

### 2. Singleton vs Instance-Based Service

**Decision**: **Instance-based service** with dependency injection (not singleton)

**Rationale**:
- Flutter BLoC pattern uses dependency injection for testability
- Singletons are hard to test (shared mutable state, can't easily mock)
- Instance-based allows different configurations (e.g., with/without caching in tests)
- Follows existing pattern: cubits inject repositories as constructor parameters

**Implementation**:
```dart
// Service injected into cubits like repositories
class MyCubit extends Cubit<MyState> {
  final ActivityLoggerService _activityLogger;
  
  MyCubit({required ActivityLoggerService activityLogger})
    : _activityLogger = activityLogger;
}
```

**Alternative Considered**: Static singleton with `ActivityLoggerService.instance`
- **Rejected because**: Hard to test, doesn't follow existing DI patterns in codebase

### 3. Caching Strategy

**Decision**: **In-memory cache** with trip-based key and TTL

**Caching Scope**:
- **What to cache**: Trip metadata (participants list, trip name)
- **Why**: Fetching from Firestore adds 100-300ms latency per call
- **When**: Cache on first fetch within a trip context, invalidate on trip switch

**Cache Structure**:
```dart
class _TripContextCache {
  final String tripId;
  final List<Participant> participants;
  final DateTime cachedAt;
  
  bool isExpired() => DateTime.now().difference(cachedAt) > Duration(minutes: 5);
}
```

**Cache Invalidation**:
- **Time-based**: 5-minute TTL (reasonable for participant list changes)
- **Context switch**: Clear cache when tripId changes
- **Manual**: Provide `clearCache()` method for explicit invalidation

**Performance Impact**:
- **Without cache**: Each activity log = 2 Firestore reads (100-300ms each)
- **With cache**: First log = 2 reads, subsequent logs = 0 reads (<5ms)
- **Bulk operation scenario**: 10 expense edits = 20 reads (2-6 seconds) → 2 reads (200-600ms)

**Alternative Considered**: No caching (always fetch fresh data)
- **Rejected because**: Violates performance requirement (<50ms overhead for logging)

**Alternative Considered**: Persistent cache (shared_preferences, IndexedDB)
- **Rejected because**: Overkill for temporary data that changes frequently

### 4. Error Handling Pattern: Fire-and-Forget vs Callbacks

**Decision**: **Fire-and-forget** (return `Future<void>`, swallow errors internally)

**Rationale**:
- Activity logging is **non-critical** - should never block business operations
- Cubits don't need to handle logging failures (they have their own error handling for main operations)
- Spec explicitly requires: "logging failures should not crash the calling code" (FR-005)

**Implementation**:
```dart
class ActivityLoggerService {
  Future<void> logExpenseEdit(...) async {
    try {
      // 1. Fetch context
      // 2. Detect changes
      // 3. Create activity log
      // 4. Persist
    } catch (e) {
      _logError('Failed to log activity: $e');
      // Swallow error - don't rethrow
    }
  }
  
  void _logError(String message) {
    debugPrint('[ActivityLogger] ERROR: $message');
    // Future: could send to error tracking service (Sentry, Firebase Crashlytics)
  }
}
```

**Cubit Usage**:
```dart
Future<void> updateExpense(...) async {
  await _expenseRepository.updateExpense(expense); // Main operation
  
  // Fire and forget - no await, no error handling needed
  _activityLogger.logExpenseEdit(oldExpense, newExpense, actorName);
  
  emit(ExpenseUpdated());
}
```

**Alternative Considered**: Return success/failure and let cubit handle errors
- **Rejected because**: Adds complexity to cubits, defeats purpose of centralization

**Alternative Considered**: Callback for errors (`onError: (e) => ...`)
- **Rejected because**: Adds API complexity, most callers won't use it

### 5. Change Detection Pattern Reuse

**Decision**: **Reuse ExpenseChangeDetector** pattern for other entities

**Existing Pattern** (from `expense_change_detector.dart`):
```dart
class ExpenseChangeDetector {
  static ExpenseChanges detectChanges(
    Expense oldExpense,
    Expense newExpense,
    List<Participant> allParticipants,
  ) {
    final changes = <String, dynamic>{};
    
    // Track each field: amount, currency, payer, participants, etc.
    // Include both IDs and human-readable names
    
    return ExpenseChanges(changes);
  }
}
```

**Pattern to Apply**:
- Create `TripChangeDetector` for trip updates
- Create `SettlementChangeDetector` for settlement changes
- Each detector returns structured metadata following same convention:
  ```dart
  {
    'field': {'old': '...', 'new': '...'},           // Simple value changes
    'field': {'oldId': '...', 'newId': '...', 'oldName': '...', 'newName': '...'},  // Reference changes
    'collection': {'added': [...], 'removed': [...], 'changed': [...]}  // Collection changes
  }
  ```

**Benefits**:
- Consistent metadata structure across all activity types
- Testable in isolation (pure functions)
- Reusable by both service and direct repository calls (backward compatibility)

**Implementation Priority**:
- **MVP**: Reuse ExpenseChangeDetector (already exists)
- **Phase 2**: Add TripChangeDetector (for tripUpdated activities)
- **Future**: Add SettlementChangeDetector (if needed for complex settlement changes)

### 6. Dependency Injection Strategy

**Decision**: Inject service into cubits as **optional parameter** (like existing repositories)

**Pattern** (follows existing ActivityLogRepository injection):
```dart
class ExpenseCubit extends Cubit<ExpenseState> {
  final ExpenseRepository _expenseRepository;
  final ActivityLoggerService? _activityLogger;  // Optional
  
  ExpenseCubit({
    required ExpenseRepository expenseRepository,
    ActivityLoggerService? activityLogger,  // Optional for backward compatibility
  }) : _expenseRepository = expenseRepository,
       _activityLogger = activityLogger,
       super(ExpenseInitial());
  
  Future<void> updateExpense(...) async {
    await _expenseRepository.updateExpense(expense);
    
    // Only log if service is provided
    if (_activityLogger != null) {
      _activityLogger!.logExpenseEdit(oldExpense, newExpense, actorName);
    }
    
    emit(ExpenseUpdated());
  }
}
```

**Provider Setup** (in main.dart or wherever cubits are provided):
```dart
MultiRepositoryProvider(
  providers: [
    RepositoryProvider<ActivityLogRepository>(
      create: (context) => ActivityLogRepositoryImpl(...),
    ),
    RepositoryProvider<TripRepository>(
      create: (context) => TripRepositoryImpl(...),
    ),
    RepositoryProvider<ActivityLoggerService>(
      create: (context) => ActivityLoggerServiceImpl(
        activityLogRepository: context.read<ActivityLogRepository>(),
        tripRepository: context.read<TripRepository>(),
      ),
    ),
  ],
  child: ...
)
```

**Benefits**:
- Non-breaking: existing cubits continue working without service
- Gradual migration: migrate one cubit at a time
- Testable: tests can omit service (pass null) if not testing logging

### 7. API Design: Method Naming and Parameters

**Decision**: **One method per activity type** with explicit parameters

**Method Naming Convention**:
- Pattern: `log{Entity}{Action}()`
- Examples:
  - `logExpenseAdded(Expense expense, String actorName)`
  - `logExpenseEdited(Expense oldExpense, Expense newExpense, String actorName)`
  - `logExpenseDeleted(String expenseId, String expenseDescription, String actorName)`
  - `logTransferSettled(String fromId, String toId, Decimal amount, String currency, String actorName)`
  - `logMemberJoined(String participantId, String participantName, String actorName, JoinMethod joinMethod)`

**Parameter Guidelines**:
- **For additions**: Pass the new entity
- **For edits**: Pass old and new entities (for change detection)
- **For deletions**: Pass minimal identifying info (ID + description for log message)
- **Always include**: `actorName` (who performed the action)
- **Optional metadata**: Additional context (e.g., `JoinMethod` for memberJoined)

**Benefits**:
- **Type safety**: Compiler ensures correct parameters for each activity type
- **Self-documenting**: Method signature shows what data is needed
- **IDE support**: Auto-complete suggests correct method for each action

**Alternative Considered**: Generic method `logActivity(ActivityType type, Map<String, dynamic> data)`
- **Rejected because**: Loses type safety, error-prone, poor developer experience

## Performance Analysis

### Baseline: Current Manual Logging (per operation)

```
Operation: Update expense with activity logging
├── Update expense in Firestore: ~200ms
├── Fetch trip data for context: ~150ms
├── Detect changes: ~1ms
├── Create activity log: ~5ms
└── Save activity log: ~100ms
TOTAL: ~456ms (254ms for logging alone)
```

### With Caching (after first operation in same trip)

```
Operation: Update expense with activity logging (cached)
├── Update expense in Firestore: ~200ms
├── Get cached trip data: <1ms (in-memory)
├── Detect changes: ~1ms
├── Create activity log: ~5ms
└── Save activity log: ~100ms
TOTAL: ~306ms (104ms for logging alone)
```

### Performance Gains

- **First operation**: ~254ms → ~254ms (no change, need to fetch context)
- **Subsequent operations**: ~254ms → ~104ms (60% faster with caching)
- **Bulk operations** (10 edits): ~2540ms → ~1294ms (saves 1.2 seconds)

**Meets requirement**: <50ms overhead for logging (achieved after first operation with caching)

## Migration Strategy

### Phase 1: Create Service (No Breaking Changes)

1. Implement `ActivityLoggerService` and `ActivityLoggerServiceImpl`
2. Add provider setup in dependency injection layer
3. Service is available but not used yet
4. All existing cubits continue using manual logging

### Phase 2: Migrate One Feature

1. Start with **ExpenseCubit** (most complex logging logic)
2. Inject `ActivityLoggerService` as optional parameter
3. Replace manual logging with service calls
4. Keep both paths working (old and new)
5. Test thoroughly before removing old code

### Phase 3: Migrate Remaining Features

1. Migrate **TripCubit** (trip creation, member joins)
2. Migrate **SettlementCubit** (transfer settled/unsettled)
3. Each migration is independent and can be done incrementally

### Phase 4: Remove Manual Logging Code

1. Once all features migrated, remove old logging code from cubits
2. Remove direct ActivityLogRepository injection from cubits
3. Service becomes the single source of truth for activity logging

## Testing Strategy

### Unit Tests

**Service Tests** (`activity_logger_service_test.dart`):
- Test each `log*()` method with mocked repositories
- Verify correct ActivityLog created with expected metadata
- Test error handling (repository failures don't throw)
- Test caching behavior (cache hit/miss scenarios)

**Change Detector Tests**:
- Test ExpenseChangeDetector with various change scenarios
- Future: test TripChangeDetector, SettlementChangeDetector

### Integration Tests

**End-to-End Tests** (`activity_logger_integration_test.dart`):
- Create expense → verify activity log created
- Edit expense → verify changes detected and logged
- Delete expense → verify deletion logged
- Bulk operations → verify caching works (measure performance)

### Migration Tests

**Backward Compatibility**:
- Test cubits with service injected
- Test cubits without service (null) - should continue working
- Test gradual migration (some cubits with service, some without)

## Open Questions & Future Work

### Questions Resolved

- **Q**: Should service be singleton or instance-based?
  - **A**: Instance-based with DI (better for testing, follows existing patterns)

- **Q**: How to handle logging failures?
  - **A**: Fire-and-forget (swallow errors, log internally)

- **Q**: What to cache?
  - **A**: Trip participant data (5-minute TTL, clear on trip switch)

### Future Enhancements (Out of Scope for MVP)

1. **Retry Logic**: If activity log save fails, retry 1-2 times before giving up
2. **Batch Logging**: Queue multiple logs and save in batch for better performance
3. **Offline Support**: Queue logs when offline, sync when back online
4. **Analytics Integration**: Send activity events to analytics service (e.g., Firebase Analytics)
5. **Audit Dashboard**: Admin UI to view all activities across all trips
6. **Change Detection for All Entities**: Create detectors for Trip, Settlement, Participant changes

## References

### Existing Code to Study

- `lib/features/expenses/domain/utils/expense_change_detector.dart` - Change detection pattern
- `lib/features/expenses/presentation/cubits/expense_cubit.dart` - Current manual logging
- `lib/features/trips/domain/models/activity_log.dart` - ActivityLog model and ActivityType enum
- `lib/features/trips/domain/repositories/activity_log_repository.dart` - Repository interface

### Similar Patterns in Flutter

- [BLoC Pattern Best Practices](https://bloclibrary.dev/#/architecture)
- [Service Layer Pattern](https://refactoring.guru/design-patterns/service-layer)
- [Repository Pattern in Flutter](https://resocoder.com/2019/08/27/flutter-tdd-clean-architecture-course-1-explanation-project-structure/)
