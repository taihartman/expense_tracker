# Cubit Contracts: Trip Invite System

**Version**: 1.0.0
**Date**: 2025-10-28
**Purpose**: Define state management contracts for Cubits, including state types, methods, and state transitions

## Cubit Overview

### New Cubits

1. **ActivityLogCubit**: Manages activity log loading and streaming

### Modified Cubits

1. **TripCubit**: Add membership methods (`joinTrip`, filter trips)
2. **ExpenseCubit**: Add activity logging to expense operations

---

## 1. ActivityLogCubit (NEW)

### Purpose
Manage activity log state for a specific trip, including loading, streaming, and error handling.

### State Definition

**File**: `lib/features/trips/presentation/cubits/activity_log_state.dart`

```dart
abstract class ActivityLogState extends Equatable {
  const ActivityLogState();
}

class ActivityLogInitial extends ActivityLogState {
  @override
  List<Object> get props => [];
}

class ActivityLogLoading extends ActivityLogState {
  @override
  List<Object> get props => [];
}

class ActivityLogLoaded extends ActivityLogState {
  final List<ActivityLog> logs;
  final bool hasMore;  // For pagination

  const ActivityLogLoaded({
    required this.logs,
    this.hasMore = false,
  });

  @override
  List<Object> get props => [logs, hasMore];
}

class ActivityLogError extends ActivityLogState {
  final String message;

  const ActivityLogError(this.message);

  @override
  List<Object> get props => [message];
}
```

### Cubit Interface

**File**: `lib/features/trips/presentation/cubits/activity_log_cubit.dart`

```dart
class ActivityLogCubit extends Cubit<ActivityLogState> {
  final ActivityLogRepository _activityLogRepository;
  StreamSubscription<List<ActivityLog>>? _logSubscription;

  ActivityLogCubit({
    required ActivityLogRepository activityLogRepository,
  })  : _activityLogRepository = activityLogRepository,
        super(ActivityLogInitial());

  /// Load activity logs for a trip (real-time stream)
  Future<void> loadActivityLogs(String tripId, {int limit = 50}) async {
    emit(ActivityLogLoading());
    try {
      await _logSubscription?.cancel();
      _logSubscription = _activityLogRepository
          .getActivityLogs(tripId, limit: limit)
          .listen(
            (logs) => emit(ActivityLogLoaded(logs: logs, hasMore: logs.length >= limit)),
            onError: (error) => emit(ActivityLogError(error.toString())),
          );
    } catch (e) {
      emit(ActivityLogError('Failed to load activity logs: ${e.toString()}'));
    }
  }

  /// Load more logs (pagination)
  Future<void> loadMore(String tripId) async {
    final currentState = state;
    if (currentState is! ActivityLogLoaded || !currentState.hasMore) return;

    // Load next page starting from last timestamp
    // Implementation: offset or cursor-based pagination
  }

  @override
  Future<void> close() {
    _logSubscription?.cancel();
    return super.close();
  }
}
```

### State Transitions

```
[Initial]
    │
    ├─► loadActivityLogs() ──► [Loading]
    │                              │
    │                              ├─► Success ──► [Loaded]
    │                              │                   │
    │                              │                   ├─► New log added (stream) ──► [Loaded] (updated)
    │                              │                   └─► loadMore() ──► [Loading] ──► [Loaded] (appended)
    │                              │
    │                              └─► Failure ──► [Error]
    │
    └─► close() ──► Cancel stream
```

### Usage Example

```dart
// In TripSettingsPage
final activityLogCubit = context.read<ActivityLogCubit>();
activityLogCubit.loadActivityLogs(tripId, limit: 50);

// In UI
BlocBuilder<ActivityLogCubit, ActivityLogState>(
  builder: (context, state) {
    if (state is ActivityLogLoading) {
      return CircularProgressIndicator();
    } else if (state is ActivityLogLoaded) {
      return ActivityLogList(logs: state.logs);
    } else if (state is ActivityLogError) {
      return ErrorWidget(message: state.message);
    }
    return SizedBox.shrink();
  },
);
```

---

## 2. TripCubit (MODIFIED)

### Purpose
Extend existing TripCubit to support trip membership: joining trips, filtering to joined trips, and logging trip actions.

### State Definition (NEW States Added)

**File**: `lib/features/trips/presentation/cubits/trip_state.dart`

```dart
// Existing states: TripInitial, TripLoading, TripLoaded, TripError, TripCreating, TripCreated

// NEW STATES:

class TripJoining extends TripState {
  @override
  List<Object> get props => [];
}

class TripJoined extends TripState {
  final Trip trip;

  const TripJoined(this.trip);

  @override
  List<Object> get props => [trip];
}

class TripJoinError extends TripState {
  final String message;

  const TripJoinError(this.message);

  @override
  List<Object> get props => [message];
}
```

### Cubit Interface (NEW Methods)

**File**: `lib/features/trips/presentation/cubits/trip_cubit.dart`

```dart
class TripCubit extends Cubit<TripState> {
  // Existing fields...
  final ActivityLogRepository _activityLogRepository;  // NEW dependency
  final LocalStorageService _localStorageService;

  // NEW METHODS:

  /// Join a trip by invite code (trip ID) and user name
  Future<void> joinTrip(String tripId, String userName) async {
    emit(TripJoining());
    try {
      // 1. Validate trip exists
      final trip = await _tripRepository.getTripById(tripId);
      if (trip == null) {
        emit(TripJoinError('Trip not found. Please check the invite code.'));
        return;
      }

      // 2. Check if already member (idempotent)
      if (trip.participants.any((p) => p.name == userName)) {
        // Already a member, just cache locally and redirect
        await _localStorageService.addJoinedTrip(tripId);
        emit(TripJoined(trip));
        await loadTrips();  // Refresh trip list
        return;
      }

      // 3. Add participant to trip
      final newParticipant = Participant.fromName(userName);
      final updatedTrip = trip.copyWith(
        participants: [...trip.participants, newParticipant],
      );
      await _tripRepository.updateTrip(updatedTrip);

      // 4. Create activity log entry
      await _activityLogRepository.addLog(
        ActivityLog(
          id: '',  // Auto-generated by Firestore
          tripId: tripId,
          actorName: userName,
          type: ActivityType.memberJoined,
          description: '$userName joined the trip',
          timestamp: DateTime.now(),
        ),
      );

      // 5. Cache joined trip ID locally
      await _localStorageService.addJoinedTrip(tripId);

      // 6. Select the joined trip
      await selectTrip(updatedTrip);

      emit(TripJoined(updatedTrip));
      await loadTrips();  // Refresh to show new trip in list
    } catch (e) {
      emit(TripJoinError('Failed to join trip: ${e.toString()}'));
    }
  }

  /// Check if user is a member of a trip (client-side cached check)
  Future<bool> isUserMemberOf(String tripId) async {
    final joinedIds = await _localStorageService.getJoinedTripIds();
    return joinedIds.contains(tripId);
  }

  /// Get list of trip IDs user has joined
  Future<List<String>> getJoinedTripIds() async {
    return await _localStorageService.getJoinedTripIds();
  }

  // MODIFIED METHOD:

  /// Load trips (filtered to only joined trips)
  Future<void> loadTrips() async {
    emit(TripLoading());
    try {
      final joinedIds = await _localStorageService.getJoinedTripIds();

      await _tripSubscription?.cancel();
      _tripSubscription = _tripRepository.getAllTrips().listen(
        (allTrips) {
          // Filter to only trips user has joined
          final joinedTrips = allTrips
              .where((trip) => joinedIds.contains(trip.id))
              .toList();

          final selected = selectedTrip != null
              ? joinedTrips.firstWhereOrNull((t) => t.id == selectedTrip!.id)
              : null;

          emit(TripLoaded(
            trips: joinedTrips,
            selectedTrip: selected,
          ));
        },
        onError: (error) => emit(TripError(error.toString())),
      );
    } catch (e) {
      emit(TripError('Failed to load trips: ${e.toString()}'));
    }
  }

  // MODIFIED METHOD (add activity logging):

  @override
  Future<void> createTrip(String name, CurrencyCode baseCurrency) async {
    emit(TripCreating());
    try {
      // Get current user name from somewhere (or prompt in UI)
      final creatorName = await _getCurrentUserName();  // Helper method

      // Create trip with creator as first participant
      final newTrip = Trip(
        id: '',  // Auto-generated by Firestore
        name: name.trim(),
        baseCurrency: baseCurrency,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        participants: [Participant.fromName(creatorName)],
      );

      final createdTrip = await _tripRepository.createTrip(newTrip);

      // Seed default categories
      await _categoryRepository.seedDefaultCategories(createdTrip.id);

      // Create activity log entry
      await _activityLogRepository.addLog(
        ActivityLog(
          id: '',
          tripId: createdTrip.id,
          actorName: creatorName,
          type: ActivityType.tripCreated,
          description: '$creatorName created the trip',
          timestamp: DateTime.now(),
        ),
      );

      // Cache joined trip ID
      await _localStorageService.addJoinedTrip(createdTrip.id);

      emit(TripCreated(createdTrip));
      await loadTrips();
    } catch (e) {
      emit(TripError('Failed to create trip: ${e.toString()}'));
    }
  }

  /// Helper: Get current user name (from local storage or prompt)
  Future<String> _getCurrentUserName() async {
    // Check if user has set their name in local storage
    final storedName = await _localStorageService.getUserName();
    return storedName ?? 'Anonymous';  // Fallback
  }
}
```

### State Transitions (NEW)

```
[Join Trip Flow]

[TripLoaded]
    │
    ├─► joinTrip(tripId, userName) ──► [TripJoining]
    │                                       │
    │                                       ├─► Trip exists, not member ──► Add participant ──► Log action ──► [TripJoined] ──► [TripLoaded]
    │                                       │
    │                                       ├─► Trip exists, already member ──► [TripJoined] ──► [TripLoaded]
    │                                       │
    │                                       └─► Trip not found ──► [TripJoinError]
```

### Usage Example

```dart
// In TripJoinPage
final tripCubit = context.read<TripCubit>();
await tripCubit.joinTrip(inviteCode, userName);

// In UI
BlocConsumer<TripCubit, TripState>(
  listener: (context, state) {
    if (state is TripJoined) {
      // Navigate to trip details
      context.go('/trips/${state.trip.id}/expenses');
    } else if (state is TripJoinError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.message)),
      );
    }
  },
  builder: (context, state) {
    if (state is TripJoining) {
      return CircularProgressIndicator();
    }
    // ... form UI
  },
);
```

---

## 3. ExpenseCubit (MODIFIED)

### Purpose
Extend existing ExpenseCubit to log expense actions (create, edit, delete) to activity log.

### Cubit Interface (MODIFIED Methods)

**File**: `lib/features/expenses/presentation/cubits/expense_cubit.dart`

```dart
class ExpenseCubit extends Cubit<ExpenseState> {
  // Existing fields...
  final ActivityLogRepository _activityLogRepository;  // NEW dependency

  // MODIFIED METHODS (add activity logging):

  @override
  Future<void> createExpense(Expense expense, String actorName) async {
    emit(ExpenseCreating());
    try {
      final createdExpense = await _expenseRepository.createExpense(expense);

      // Log activity
      await _activityLogRepository.addLog(
        ActivityLog(
          id: '',
          tripId: expense.tripId,
          actorName: actorName,
          type: ActivityType.expenseAdded,
          description: '$actorName added expense "${expense.title}"',
          timestamp: DateTime.now(),
          metadata: {
            'expenseId': createdExpense.id,
            'amount': expense.amount,
            'currency': expense.currency.code,
          },
        ),
      );

      emit(ExpenseCreated(createdExpense));
      await loadExpenses(expense.tripId);
    } catch (e) {
      emit(ExpenseError('Failed to create expense: ${e.toString()}'));
    }
  }

  @override
  Future<void> updateExpense(Expense expense, String actorName) async {
    emit(ExpenseUpdating());
    try {
      await _expenseRepository.updateExpense(expense);

      // Log activity
      await _activityLogRepository.addLog(
        ActivityLog(
          id: '',
          tripId: expense.tripId,
          actorName: actorName,
          type: ActivityType.expenseEdited,
          description: '$actorName edited expense "${expense.title}"',
          timestamp: DateTime.now(),
          metadata: {
            'expenseId': expense.id,
          },
        ),
      );

      emit(ExpenseUpdated(expense));
      await loadExpenses(expense.tripId);
    } catch (e) {
      emit(ExpenseError('Failed to update expense: ${e.toString()}'));
    }
  }

  @override
  Future<void> deleteExpense(String tripId, String expenseId, String actorName, String expenseTitle) async {
    emit(ExpenseDeleting());
    try {
      await _expenseRepository.deleteExpense(expenseId);

      // Log activity
      await _activityLogRepository.addLog(
        ActivityLog(
          id: '',
          tripId: tripId,
          actorName: actorName,
          type: ActivityType.expenseDeleted,
          description: '$actorName deleted expense "$expenseTitle"',
          timestamp: DateTime.now(),
          metadata: {
            'expenseId': expenseId,
          },
        ),
      );

      emit(ExpenseDeleted());
      await loadExpenses(tripId);
    } catch (e) {
      emit(ExpenseError('Failed to delete expense: ${e.toString()}'));
    }
  }
}
```

### Usage Example

```dart
// In ExpenseFormPage
final expenseCubit = context.read<ExpenseCubit>();
final actorName = await context.read<TripCubit>()._getCurrentUserName();
await expenseCubit.createExpense(expense, actorName);
```

---

## Dependency Injection

### New Repository Registration

**File**: `lib/main.dart`

```dart
void main() async {
  // ... existing setup

  // NEW: Activity Log Repository
  final activityLogRepository = ActivityLogRepositoryImpl(
    firestoreService: firestoreService,
  );

  runApp(
    MultiBlocProvider(
      providers: [
        // Existing cubits...

        // MODIFIED: TripCubit with new dependency
        BlocProvider(
          create: (_) => TripCubit(
            tripRepository: tripRepository,
            localStorageService: localStorageService,
            categoryRepository: categoryRepository,
            activityLogRepository: activityLogRepository,  // NEW
          )..loadTrips(),
          lazy: true,
        ),

        // NEW: ActivityLogCubit
        BlocProvider(
          create: (_) => ActivityLogCubit(
            activityLogRepository: activityLogRepository,
          ),
          lazy: true,
        ),

        // MODIFIED: ExpenseCubit with new dependency
        BlocProvider(
          create: (_) => ExpenseCubit(
            expenseRepository: expenseRepository,
            activityLogRepository: activityLogRepository,  // NEW
          ),
          lazy: true,
        ),
      ],
      child: MyApp(),
    ),
  );
}
```

---

## Testing Contracts

### Unit Tests

**TripCubit Tests** (new test cases):

```dart
test('joinTrip adds participant and logs activity', () async {
  // Arrange
  final trip = Trip(id: 'trip123', participants: []);
  when(tripRepository.getTripById('trip123')).thenAnswer((_) async => trip);

  // Act
  await tripCubit.joinTrip('trip123', 'Tai');

  // Assert
  verify(tripRepository.updateTrip(any)).called(1);
  verify(activityLogRepository.addLog(any)).called(1);
  verify(localStorageService.addJoinedTrip('trip123')).called(1);
  expect(tripCubit.state, isA<TripJoined>());
});

test('joinTrip is idempotent (already member)', () async {
  // Arrange
  final participant = Participant.fromName('Tai');
  final trip = Trip(id: 'trip123', participants: [participant]);
  when(tripRepository.getTripById('trip123')).thenAnswer((_) async => trip);

  // Act
  await tripCubit.joinTrip('trip123', 'Tai');

  // Assert
  verify(tripRepository.updateTrip(any)).called(0);  // No update
  verify(activityLogRepository.addLog(any)).called(0);  // No log
  verify(localStorageService.addJoinedTrip('trip123')).called(1);
  expect(tripCubit.state, isA<TripJoined>());
});

test('loadTrips filters to joined trips only', () async {
  // Arrange
  final allTrips = [
    Trip(id: 'trip1', name: 'Trip 1'),
    Trip(id: 'trip2', name: 'Trip 2'),
    Trip(id: 'trip3', name: 'Trip 3'),
  ];
  when(tripRepository.getAllTrips()).thenAnswer((_) => Stream.value(allTrips));
  when(localStorageService.getJoinedTripIds()).thenAnswer((_) async => ['trip1', 'trip3']);

  // Act
  await tripCubit.loadTrips();

  // Assert
  final state = tripCubit.state as TripLoaded;
  expect(state.trips.length, 2);
  expect(state.trips.map((t) => t.id), ['trip1', 'trip3']);
});
```

**ActivityLogCubit Tests**:

```dart
test('loadActivityLogs emits loaded state with logs', () async {
  // Arrange
  final logs = [
    ActivityLog(id: 'log1', actorName: 'Tai', type: ActivityType.memberJoined, ...),
    ActivityLog(id: 'log2', actorName: 'Khiet', type: ActivityType.expenseAdded, ...),
  ];
  when(activityLogRepository.getActivityLogs('trip123', limit: 50))
      .thenAnswer((_) => Stream.value(logs));

  // Act
  await activityLogCubit.loadActivityLogs('trip123', limit: 50);

  // Assert
  expect(activityLogCubit.state, isA<ActivityLogLoaded>());
  final state = activityLogCubit.state as ActivityLogLoaded;
  expect(state.logs, logs);
});

test('loadActivityLogs emits error state on failure', () async {
  // Arrange
  when(activityLogRepository.getActivityLogs('trip123', limit: 50))
      .thenAnswer((_) => Stream.error(Exception('Network error')));

  // Act
  await activityLogCubit.loadActivityLogs('trip123', limit: 50);

  // Assert
  await Future.delayed(Duration(milliseconds: 100));  // Wait for stream error
  expect(activityLogCubit.state, isA<ActivityLogError>());
});
```

---

## Summary

**New Cubits**: 1 (ActivityLogCubit)
**Modified Cubits**: 2 (TripCubit, ExpenseCubit)
**New States**: 3 (TripJoining, TripJoined, TripJoinError)
**New Methods**: 3 (joinTrip, isUserMemberOf, getJoinedTripIds)

**State Management Complexity**: Low
- Extends existing Cubit pattern
- No new state management paradigms
- Clean separation of concerns (ActivityLogCubit independent)

**Testing Coverage Target**: 80%+ for new/modified methods
