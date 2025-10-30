# Migration Plan: Adopting ActivityLoggerService

**Version**: 1.0.0
**Date**: 2025-10-30
**Status**: Draft

## Overview

This document outlines the step-by-step plan for migrating existing cubits from manual activity logging (direct repository calls) to using the centralized ActivityLoggerService.

## Migration Strategy

### Phased Rollout

**Philosophy**: Gradual, non-breaking migration with backward compatibility at each step

1. **Phase 1**: Create service (no code changes to cubits)
2. **Phase 2**: Migrate one feature (ExpenseCubit) as pilot
3. **Phase 3**: Migrate remaining features (TripCubit, SettlementCubit)
4. **Phase 4**: Remove manual logging code (cleanup)

### Success Criteria

- ✅ Zero breaking changes to existing cubits
- ✅ All tests pass at each phase
- ✅ Activity logs continue working during migration
- ✅ Performance maintained or improved
- ✅ Code quality improved (reduced duplication)

## Phase 1: Create Service (Foundation)

**Goal**: Service is available but not used yet

### Tasks

1. **Create service files**
   - `lib/core/services/activity_logger_service.dart` (interface)
   - `lib/core/services/activity_logger_service_impl.dart` (implementation)
   - `test/core/services/activity_logger_service_test.dart` (unit tests)

2. **Add service to dependency injection**
   - Update main.dart or DI setup to provide `ActivityLoggerService`
   - Inject `ActivityLogRepository` and `TripRepository` into service

3. **Verify service works in isolation**
   - Run unit tests (all green)
   - Manual smoke test: instantiate service and call methods

### Verification

```bash
# Run service tests
flutter test test/core/services/activity_logger_service_test.dart

# Run all tests (should still pass)
flutter test
```

**Exit Criteria**: Service tests pass, no regressions in existing tests

---

## Phase 2: Migrate ExpenseCubit (Pilot)

**Goal**: Prove the pattern works with one complex feature

### Why ExpenseCubit First?

- Has the most complex logging logic (change detection, metadata)
- Most frequently used (higher ROI)
- Good test coverage to catch regressions

### Pre-Migration State

```dart
class ExpenseCubit extends Cubit<ExpenseState> {
  final ExpenseRepository _expenseRepository;
  final ActivityLogRepository? _activityLogRepository;
  final TripRepository? _tripRepository;

  ExpenseCubit({
    required ExpenseRepository expenseRepository,
    ActivityLogRepository? activityLogRepository,
    TripRepository? tripRepository,
  }) : _expenseRepository = expenseRepository,
       _activityLogRepository = activityLogRepository,
       _tripRepository = tripRepository,
       super(ExpenseInitial());
}
```

### Post-Migration State

```dart
class ExpenseCubit extends Cubit<ExpenseState> {
  final ExpenseRepository _expenseRepository;
  final ActivityLoggerService? _activityLogger;

  ExpenseCubit({
    required ExpenseRepository expenseRepository,
    ActivityLoggerService? activityLogger,
  }) : _expenseRepository = expenseRepository,
       _activityLogger = activityLogger,
       super(ExpenseInitial());
}
```

### Step-by-Step Migration

#### Step 2.1: Add Service Injection (Additive)

```dart
class ExpenseCubit extends Cubit<ExpenseState> {
  final ExpenseRepository _expenseRepository;
  final ActivityLogRepository? _activityLogRepository;  // KEEP for now
  final TripRepository? _tripRepository;                 // KEEP for now
  final ActivityLoggerService? _activityLogger;          // ADD

  ExpenseCubit({
    required ExpenseRepository expenseRepository,
    ActivityLogRepository? activityLogRepository,
    TripRepository? tripRepository,
    ActivityLoggerService? activityLogger,  // ADD
  }) : _expenseRepository = expenseRepository,
       _activityLogRepository = activityLogRepository,
       _tripRepository = tripRepository,
       _activityLogger = activityLogger,  // ADD
       super(ExpenseInitial());
}
```

**Verify**: Run tests (should still pass, service not used yet)

#### Step 2.2: Update Provider (DI Layer)

```dart
// In main.dart or wherever cubits are provided
BlocProvider<ExpenseCubit>(
  create: (context) => ExpenseCubit(
    expenseRepository: context.read<ExpenseRepository>(),
    activityLogRepository: context.read<ActivityLogRepository>(),  // KEEP
    tripRepository: context.read<TripRepository>(),                // KEEP
    activityLogger: context.read<ActivityLoggerService>(),         // ADD
  ),
)
```

**Verify**: App runs, no errors

#### Step 2.3: Replace Manual Logging in addExpense()

**Before**:
```dart
Future<void> addExpense(..., String? actorName) async {
  await _expenseRepository.addExpense(expense);

  // 15+ lines of manual logging
  if (_activityLogRepository != null && actorName != null && actorName.isNotEmpty) {
    try {
      final trip = await _tripRepository?.getTripById(expense.tripId);
      final payer = trip?.participants.firstWhere(...);
      final description = '${payer.name} paid ${expense.amount} ${expense.currency.code}';
      final activityLog = ActivityLog(...);
      await _activityLogRepository.addLog(activityLog);
    } catch (e) {
      _log('⚠️ Failed to log activity (non-fatal): $e');
    }
  }

  emit(ExpenseAdded());
}
```

**After**:
```dart
Future<void> addExpense(..., String? actorName) async {
  await _expenseRepository.addExpense(expense);

  // Single line
  if (_activityLogger != null && actorName != null && actorName.isNotEmpty) {
    _activityLogger!.logExpenseAdded(expense: expense, actorName: actorName);
  }

  emit(ExpenseAdded());
}
```

**Verify**: 
- Run `flutter test test/features/expenses/`
- Manual test: Add expense, check activity log

#### Step 2.4: Replace Manual Logging in updateExpense()

**Before**: ~40 lines of manual change detection and logging

**After**:
```dart
Future<void> updateExpense(..., String? actorName) async {
  final oldExpense = ...; // Get old expense before update
  await _expenseRepository.updateExpense(expense);

  // Single line
  if (_activityLogger != null && actorName != null && actorName.isNotEmpty) {
    _activityLogger!.logExpenseEdited(
      oldExpense: oldExpense,
      newExpense: expense,
      actorName: actorName,
    );
  }

  emit(ExpenseUpdated());
}
```

**Verify**: 
- Run tests
- Manual test: Edit expense, check change detection works

#### Step 2.5: Replace Manual Logging in deleteExpense()

**Before**: ~15 lines of manual logging

**After**:
```dart
Future<void> deleteExpense(..., String? actorName) async {
  final expense = ...; // Get expense before deletion
  await _expenseRepository.deleteExpense(expenseId);

  // Single line
  if (_activityLogger != null && actorName != null && actorName.isNotEmpty) {
    _activityLogger!.logExpenseDeleted(
      expenseId: expense.id,
      expenseDescription: expense.description ?? 'Expense',
      amount: expense.amount,
      currency: expense.currency.code,
      tripId: expense.tripId,
      actorName: actorName,
    );
  }

  emit(ExpenseDeleted());
}
```

**Verify**: Run tests, manual testing

#### Step 2.6: Remove Old Logging Code (Cleanup)

Once all methods migrated and verified:

```dart
class ExpenseCubit extends Cubit<ExpenseState> {
  final ExpenseRepository _expenseRepository;
  final ActivityLoggerService? _activityLogger;  // ONLY service remains

  ExpenseCubit({
    required ExpenseRepository expenseRepository,
    ActivityLoggerService? activityLogger,
  }) : _expenseRepository = expenseRepository,
       _activityLogger = activityLogger,
       super(ExpenseInitial());
}
```

Update provider:
```dart
BlocProvider<ExpenseCubit>(
  create: (context) => ExpenseCubit(
    expenseRepository: context.read<ExpenseRepository>(),
    activityLogger: context.read<ActivityLoggerService>(),  // Only service
  ),
)
```

**Verify**: Full test suite passes, manual regression testing

### Phase 2 Exit Criteria

- ✅ All ExpenseCubit tests pass
- ✅ Activity logs for expenses work correctly
- ✅ Code reduced by ~70% (measured in logging-related LOC)
- ✅ No performance regressions
- ✅ Manual testing confirms all expense operations log correctly

---

## Phase 3: Migrate Remaining Features

### Step 3.1: Migrate SettlementCubit

**Affected Methods**:
- `markTransferAsSettled()`
- `markTransferAsUnsettled()`

**Migration**:
```dart
// Before: Manual logging with repository
if (_activityLogRepository != null && actorName != null) {
  // 15+ lines of manual logging
}

// After: Use service
if (_activityLogger != null && actorName != null) {
  _activityLogger!.logTransferSettled(
    fromParticipantId: fromId,
    toParticipantId: toId,
    amount: amount,
    currency: currency,
    tripId: tripId,
    actorName: actorName,
  );
}
```

**Verification**:
- Run `flutter test test/features/settlements/`
- Manual test: Mark transfer settled, check activity log

### Step 3.2: Migrate TripCubit

**Affected Methods**:
- `createTrip()`
- `joinTrip()`

**Migration**:
```dart
// For trip creation
_activityLogger?.logTripCreated(trip: trip, actorName: creatorName);

// For member joining
_activityLogger?.logMemberJoined(
  participantId: participantId,
  tripId: tripId,
  actorName: actorName,
  joinMethod: joinMethod,
  invitedByParticipantId: invitedBy,
);
```

**Verification**:
- Run `flutter test test/features/trips/`
- Manual test: Create trip, join trip, check activity logs

### Phase 3 Exit Criteria

- ✅ All cubit tests pass
- ✅ All activity types logging correctly
- ✅ Code reduction across all features
- ✅ Full regression testing complete

---

## Phase 4: Final Cleanup

### Tasks

1. **Remove direct repository injections** from all cubits
   - Remove `ActivityLogRepository` parameters
   - Remove `TripRepository` parameters (where only used for logging)

2. **Update all DI/provider configurations**
   - Remove repository injections that are no longer needed
   - Keep only `ActivityLoggerService` for activity logging

3. **Update tests**
   - Remove repository mocks where no longer needed
   - Update test setup to only inject service

4. **Documentation updates**
   - Update CLAUDE.md with new patterns
   - Update quickstart.md with migration examples
   - Mark old patterns as deprecated in code comments

### Verification

```bash
# Full test suite
flutter test

# Analyze for unused code
flutter analyze

# Code coverage check
flutter test --coverage
lcov --summary coverage/lcov.info
```

### Phase 4 Exit Criteria

- ✅ No direct ActivityLogRepository injections in cubits (except ActivityLogCubit)
- ✅ All tests pass
- ✅ No unused imports or dead code
- ✅ Documentation updated
- ✅ Code coverage maintained or improved

---

## Rollback Plan

At any phase, rollback is straightforward:

### If Issues Found in Phase 2 (Pilot)

1. **Keep old code**: Don't delete manual logging code until verified
2. **Conditional logic**: Use both old and new paths temporarily
   ```dart
   if (_activityLogger != null) {
     _activityLogger!.logExpenseAdded(...);
   } else if (_activityLogRepository != null) {
     // Fallback to old code
   }
   ```
3. **Revert commits**: Git revert if needed (each phase is a separate commit)

### If Issues Found in Phase 3 or 4

1. **Rollback specific feature**: Each feature migration is independent
2. **Keep working features**: ExpenseCubit can use service while others don't
3. **Investigate and fix**: Debug issues in isolation, re-migrate when ready

---

## Testing Strategy

### Automated Tests

**Unit Tests** (per feature):
- Test cubit with service injected
- Test cubit without service (null) - should still work
- Verify service methods called with correct parameters
- Verify no exceptions thrown from cubit methods

**Integration Tests**:
- End-to-end flows: create → edit → delete expense
- Verify activity logs created correctly in Firestore
- Test caching behavior (multiple operations in same trip)

**Performance Tests**:
- Benchmark before and after migration
- Verify no performance regressions
- Confirm caching improves bulk operations

### Manual Testing Checklist

For each migrated feature:

- [ ] Create operation works, activity logged
- [ ] Edit operation works, changes detected correctly
- [ ] Delete operation works, activity logged
- [ ] Activity log UI shows correct entries
- [ ] Participant names appear correctly (not just IDs)
- [ ] Timestamps are accurate
- [ ] No console errors or warnings
- [ ] App performance feels the same or better

---

## Risk Mitigation

### Known Risks

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| Service has bugs | High | Medium | Comprehensive unit tests, pilot with one feature first |
| Performance degradation | Medium | Low | Caching strategy, performance benchmarks |
| Breaking existing features | High | Low | Phased rollout, keep old code until verified |
| Incomplete migration | Medium | Medium | Clear exit criteria per phase, tracking checklist |

### Mitigation Strategies

1. **TDD**: Write tests before implementing service
2. **Feature flags**: Could add config to toggle between old/new logging (overkill for MVP)
3. **Monitoring**: Add debug logs to track service usage
4. **Gradual rollout**: One feature at a time, verify before continuing

---

## Success Metrics

### Quantitative Metrics

- **Code reduction**: 70%+ reduction in logging-related code
- **Performance**: <50ms overhead for logging (after caching)
- **Test coverage**: Maintain or improve coverage (80%+ for service)
- **Migration time**: Complete migration in 1-2 days

### Qualitative Metrics

- **Developer experience**: Simpler API, less boilerplate
- **Consistency**: All activity logs follow same patterns
- **Maintainability**: Easier to add new activity types
- **Reliability**: No logging-related crashes or errors

---

## Timeline Estimate

| Phase | Estimated Time | Dependencies |
|-------|---------------|--------------|
| Phase 1: Create Service | 4-6 hours | None |
| Phase 2: Migrate ExpenseCubit | 3-4 hours | Phase 1 complete |
| Phase 3: Migrate SettlementCubit | 1-2 hours | Phase 2 verified |
| Phase 3: Migrate TripCubit | 1-2 hours | Phase 2 verified |
| Phase 4: Final Cleanup | 1-2 hours | Phase 3 complete |
| **Total** | **10-16 hours** | Linear progression |

**Note**: Timeline assumes tests are written first (TDD), which adds upfront time but reduces debugging later.

---

## Post-Migration

### Monitoring

- Watch for errors in ActivityLoggerService (check debug logs)
- Monitor Firestore usage (ensure no unexpected increase)
- Collect feedback from development team

### Future Enhancements

Once migration complete, consider:
- Batch logging for performance
- Retry logic for failed logs
- Analytics integration
- Admin dashboard for activity logs

### Knowledge Transfer

- Update developer documentation
- Add examples to quickstart.md
- Team walkthrough of new patterns
- Update code review checklist
