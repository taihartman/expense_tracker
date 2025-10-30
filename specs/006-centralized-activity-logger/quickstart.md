# Quick Start: Using ActivityLoggerService

**Feature**: 006-centralized-activity-logger
**Date**: 2025-10-30

## 5-Minute Quick Start

This guide shows you how to use ActivityLoggerService in your cubits to log user activities without writing boilerplate code.

## Step 1: Inject the Service

Add ActivityLoggerService to your cubit constructor as an optional parameter:

```dart
import 'package:expense_tracker/core/services/activity_logger_service.dart';

class MyCubit extends Cubit<MyState> {
  final MyRepository _myRepository;
  final ActivityLoggerService? _activityLogger;  // Add this

  MyCubit({
    required MyRepository myRepository,
    ActivityLoggerService? activityLogger,  // Add this
  })  : _myRepository = myRepository,
        _activityLogger = activityLogger,  // Add this
        super(MyInitialState());
}
```

**Why optional?** Backward compatibility and easier testing.

## Step 2: Use the Service

Call the appropriate logging method after your operation succeeds:

```dart
Future<void> updateExpense(
  Expense oldExpense,
  Expense newExpense,
  String actorName,
) async {
  // 1. Perform your main operation
  await _myRepository.updateExpense(newExpense);

  // 2. Log the activity (fire-and-forget)
  _activityLogger?.logExpenseEdited(
    oldExpense: oldExpense,
    newExpense: newExpense,
    actorName: actorName,
  );

  // 3. Update state
  emit(ExpenseUpdatedState());
}
```

That's it! The service handles:
- Fetching trip context (participants, trip name)
- Detecting changes between old and new
- Generating human-readable descriptions
- Creating and saving the activity log
- Error handling (won't crash your operation)

## Common Use Cases

### Logging Expense Operations

#### Add Expense

```dart
Future<void> addExpense(Expense expense, String actorName) async {
  await _expenseRepository.addExpense(expense);

  _activityLogger?.logExpenseAdded(
    expense: expense,
    actorName: actorName,
  );

  emit(ExpenseAddedState());
}
```

#### Edit Expense (with Change Detection)

```dart
Future<void> updateExpense(
  Expense oldExpense,
  Expense newExpense,
  String actorName,
) async {
  await _expenseRepository.updateExpense(newExpense);

  // Service automatically detects what changed
  _activityLogger?.logExpenseEdited(
    oldExpense: oldExpense,
    newExpense: newExpense,
    actorName: actorName,
  );

  emit(ExpenseUpdatedState());
}
```

#### Delete Expense

```dart
Future<void> deleteExpense(
  String expenseId,
  String tripId,
  String actorName,
) async {
  // Get expense details before deleting
  final expense = await _expenseRepository.getExpenseById(expenseId);
  
  await _expenseRepository.deleteExpense(expenseId);

  if (expense != null) {
    _activityLogger?.logExpenseDeleted(
      expenseId: expense.id,
      expenseDescription: expense.description ?? 'Expense',
      amount: expense.amount,
      currency: expense.currency.code,
      tripId: tripId,
      actorName: actorName,
    );
  }

  emit(ExpenseDeletedState());
}
```

### Logging Settlement Operations

#### Mark Transfer Settled

```dart
Future<void> markTransferAsSettled(
  String fromId,
  String toId,
  Decimal amount,
  String currency,
  String tripId,
  String actorName,
) async {
  await _settlementRepository.markAsSettled(fromId, toId, amount);

  _activityLogger?.logTransferSettled(
    fromParticipantId: fromId,
    toParticipantId: toId,
    amount: amount,
    currency: currency,
    tripId: tripId,
    actorName: actorName,
  );

  emit(TransferSettledState());
}
```

#### Mark Transfer Unsettled

```dart
Future<void> markTransferAsUnsettled(
  String fromId,
  String toId,
  Decimal amount,
  String currency,
  String tripId,
  String actorName,
) async {
  await _settlementRepository.markAsUnsettled(fromId, toId, amount);

  _activityLogger?.logTransferUnsettled(
    fromParticipantId: fromId,
    toParticipantId: toId,
    amount: amount,
    currency: currency,
    tripId: tripId,
    actorName: actorName,
  );

  emit(TransferUnsettledState());
}
```

### Logging Trip Operations

#### Create Trip

```dart
Future<void> createTrip(
  String name,
  String baseCurrency,
  String creatorName,
) async {
  final trip = await _tripRepository.createTrip(
    Trip(
      id: '',  // Firestore generates
      name: name,
      baseCurrency: Currency.fromCode(baseCurrency),
      participants: [...],
      createdAt: DateTime.now(),
    ),
  );

  _activityLogger?.logTripCreated(
    trip: trip,
    actorName: creatorName,
  );

  emit(TripCreatedState(trip));
}
```

#### Member Joins Trip

```dart
Future<void> joinTrip(
  String tripId,
  String participantId,
  String participantName,
  JoinMethod joinMethod,
  String? invitedBy,
) async {
  await _tripRepository.addVerifiedMember(
    tripId: tripId,
    participantId: participantId,
    participantName: participantName,
  );

  _activityLogger?.logMemberJoined(
    participantId: participantId,
    tripId: tripId,
    actorName: participantName,
    joinMethod: joinMethod,
    invitedByParticipantId: invitedBy,
  );

  emit(TripJoinedState());
}
```

## Adding a New Activity Type

If you need to log a new type of activity that isn't supported yet, follow these steps:

### 1. Add to ActivityType Enum

```dart
// In lib/features/trips/domain/models/activity_log.dart
enum ActivityType {
  // ... existing types ...
  
  /// My new activity type
  myNewActivity,
}
```

### 2. Add Method to Service Interface

```dart
// In lib/core/services/activity_logger_service.dart
abstract class ActivityLoggerService {
  // ... existing methods ...

  /// Log when my new activity happens
  ///
  /// Parameters:
  /// - [param1]: Description
  /// - [actorName]: Name of the person who performed the action
  Future<void> logMyNewActivity({
    required String param1,
    required String actorName,
  });
}
```

### 3. Implement in Service

```dart
// In lib/core/services/activity_logger_service_impl.dart
@override
Future<void> logMyNewActivity({
  required String param1,
  required String actorName,
}) async {
  try {
    // Get trip context if needed
    // final context = await _getTripContext(tripId);
    
    // Create description
    final description = 'My activity description';
    
    // Create activity log
    final activityLog = ActivityLog(
      id: '',
      tripId: tripId,
      type: ActivityType.myNewActivity,
      actorName: actorName,
      description: description,
      timestamp: DateTime.now(),
      metadata: {
        'param1': param1,
        // Add other relevant metadata
      },
    );
    
    await _logActivity(activityLog);
  } catch (e) {
    _logError('Failed to log my new activity: $e');
  }
}
```

### 4. Update UI (Activity Log Display)

```dart
// In lib/features/trips/presentation/widgets/activity_log_item.dart
Icon _getIconForActivityType(ActivityType type) {
  switch (type) {
    // ... existing cases ...
    case ActivityType.myNewActivity:
      return Icons.my_icon;
  }
}

Color _getColorForActivityType(ActivityType type) {
  switch (type) {
    // ... existing cases ...
    case ActivityType.myNewActivity:
      return Colors.blue;
  }
}

String _getActionText(ActivityType type) {
  switch (type) {
    // ... existing cases ...
    case ActivityType.myNewActivity:
      return 'did something';
  }
}
```

### 5. Write Tests

```dart
// In test/core/services/activity_logger_service_test.dart
test('logMyNewActivity creates activity log', () async {
  // Arrange
  when(mockActivityLogRepository.addLog(any))
      .thenAnswer((_) async => 'log-id');

  // Act
  await service.logMyNewActivity(
    param1: 'test-value',
    actorName: 'Test User',
  );

  // Assert
  final captured = verify(
    mockActivityLogRepository.addLog(captureAny),
  ).captured.single as ActivityLog;

  expect(captured.type, ActivityType.myNewActivity);
  expect(captured.actorName, 'Test User');
  expect(captured.metadata?['param1'], 'test-value');
});
```

## Dependency Injection Setup

Add the service to your DI configuration (usually in `main.dart`):

```dart
import 'package:expense_tracker/core/services/activity_logger_service.dart';
import 'package:expense_tracker/core/services/activity_logger_service_impl.dart';

void main() {
  runApp(
    MultiRepositoryProvider(
      providers: [
        // Repositories
        RepositoryProvider<ActivityLogRepository>(
          create: (context) => ActivityLogRepositoryImpl(...),
        ),
        RepositoryProvider<TripRepository>(
          create: (context) => TripRepositoryImpl(...),
        ),
        
        // Service (depends on repositories)
        RepositoryProvider<ActivityLoggerService>(
          create: (context) => ActivityLoggerServiceImpl(
            activityLogRepository: context.read<ActivityLogRepository>(),
            tripRepository: context.read<TripRepository>(),
          ),
        ),
        
        // Other repositories...
      ],
      child: MultiBlocProvider(
        providers: [
          // Inject service into cubits
          BlocProvider<ExpenseCubit>(
            create: (context) => ExpenseCubit(
              expenseRepository: context.read<ExpenseRepository>(),
              activityLogger: context.read<ActivityLoggerService>(),
            ),
          ),
          // Other cubits...
        ],
        child: MyApp(),
      ),
    ),
  );
}
```

## Testing with the Service

### Unit Test with Mock Service

```dart
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

@GenerateMocks([ActivityLoggerService])
void main() {
  late ExpenseCubit cubit;
  late MockActivityLoggerService mockActivityLogger;

  setUp(() {
    mockActivityLogger = MockActivityLoggerService();
    cubit = ExpenseCubit(
      expenseRepository: mockExpenseRepository,
      activityLogger: mockActivityLogger,
    );
  });

  test('updateExpense logs activity', () async {
    // Arrange
    final oldExpense = Expense(...);
    final newExpense = Expense(...);

    // Act
    await cubit.updateExpense(oldExpense, newExpense, 'Test User');

    // Assert
    verify(mockActivityLogger.logExpenseEdited(
      oldExpense: oldExpense,
      newExpense: newExpense,
      actorName: 'Test User',
    )).called(1);
  });
}
```

### Test Without Service (Backward Compatibility)

```dart
test('updateExpense works without activity logger', () async {
  // Create cubit without service (null)
  final cubit = ExpenseCubit(
    expenseRepository: mockExpenseRepository,
    // activityLogger: null (omitted),
  );

  // Should complete without errors
  await cubit.updateExpense(oldExpense, newExpense, 'Test User');

  // Main operation still works
  verify(mockExpenseRepository.updateExpense(newExpense)).called(1);
});
```

## Performance Optimization

### Cache Clearing

The service automatically caches trip data for 5 minutes. You rarely need to clear the cache manually, but you can if needed:

```dart
// Clear cache when switching trips
void loadTrip(String newTripId) {
  _activityLogger?.clearCache();
  // Load new trip...
}

// Clear cache after updating trip participants
Future<void> updateTripParticipants(...) async {
  await _tripRepository.updateTrip(trip);
  _activityLogger?.clearCache();  // Ensure fresh data on next log
}
```

### Bulk Operations

For bulk operations (e.g., importing 50 expenses), the service automatically benefits from caching:

```dart
Future<void> importExpenses(List<Expense> expenses, String actorName) async {
  for (final expense in expenses) {
    await _expenseRepository.addExpense(expense);
    
    // First call fetches trip data, subsequent calls use cache
    _activityLogger?.logExpenseAdded(
      expense: expense,
      actorName: actorName,
    );
  }
}
```

**Performance**: First log ~250ms, subsequent logs ~100ms (60% faster)

## Troubleshooting

### Activity Not Appearing in Log

**Check**:
1. Is `actorName` provided and non-empty?
2. Is service injected into cubit?
3. Check debug console for errors (service logs failures)

```dart
// Ensure actorName is valid
if (actorName == null || actorName.isEmpty) {
  debugPrint('Warning: actorName is empty, activity will not be logged');
}
```

### Service Failing Silently

The service catches all errors to prevent crashing your app. Check the debug console:

```
[ActivityLoggerService] ERROR: Failed to log expense added: Exception: Trip not found
```

### Performance Issues

If logging seems slow:
1. Check Firestore connection (slow network?)
2. Verify caching is working (should be fast after first call)
3. Check if you're clearing cache unnecessarily

## Best Practices

### ✅ DO

- Always provide `actorName` (required for audit trail)
- Call logging methods AFTER main operation succeeds
- Use `?.` for optional chaining (service is optional)
- Let service handle errors (fire-and-forget)

```dart
// Good
await _expenseRepository.updateExpense(expense);
_activityLogger?.logExpenseEdited(...);
```

### ❌ DON'T

- Don't call logging BEFORE main operation (log only success)
- Don't try to catch errors from service (it handles them)
- Don't skip `actorName` (logs won't be created)
- Don't clear cache unnecessarily (hurts performance)

```dart
// Bad - logging before operation
_activityLogger?.logExpenseEdited(...);  // Too early!
await _expenseRepository.updateExpense(expense);

// Bad - trying to handle service errors
try {
  _activityLogger?.logExpenseEdited(...);
} catch (e) {
  // Service never throws, this is unnecessary
}
```

## Further Reading

- **Interface Contract**: `contracts/activity_logger_service_interface.md`
- **Migration Guide**: `contracts/migration_plan.md`
- **Architecture**: `data-model.md`
- **Design Decisions**: `research.md`
- **Full Spec**: `spec.md`

## Getting Help

If you encounter issues or have questions:

1. Check the contracts and documentation in this feature folder
2. Look at existing usage in `ExpenseCubit`, `TripCubit`, or `SettlementCubit`
3. Check test files for examples: `test/core/services/activity_logger_service_test.dart`
4. Review debug console for service error messages
