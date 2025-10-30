# Activity Logging Skill

## Description
This skill provides a step-by-step workflow for adding comprehensive activity logging to state-changing operations in the expense tracker app. Activity logging creates an audit trail for transparency and debugging.

## When to Use
- Adding new state-changing operations in Cubits
- Creating new features that modify trip/expense/participant data
- Implementing undo/history features
- Debugging user-reported issues
- When you see "TODO: Add activity logging" comments

## Core Philosophy
**Every state-changing operation MUST include activity logging** for transparency and audit purposes. Activity logging is:
- **Non-fatal**: Logging failures should never break the main operation
- **Optional**: Make `ActivityLogRepository` optional for testing
- **Descriptive**: Use clear descriptions and rich metadata

## Key Files
- `lib/features/trips/domain/models/activity_log.dart` - ActivityType enum and ActivityLog model
- `lib/features/trips/domain/repositories/activity_log_repository.dart` - Repository interface
- `lib/features/expenses/domain/utils/expense_change_detector.dart` - Change detection utility
- `lib/features/trips/presentation/pages/trip_activity_page.dart` - Activity log UI
- `lib/features/trips/presentation/widgets/activity_log_item.dart` - Activity log item widget

## Workflow

### Step 1: Inject ActivityLogRepository in Cubit

```dart
class MyCubit extends Cubit<MyState> {
  final MyRepository _myRepository;
  final ActivityLogRepository? _activityLogRepository; // MAKE OPTIONAL

  MyCubit({
    required MyRepository myRepository,
    ActivityLogRepository? activityLogRepository, // Optional parameter
  }) : _myRepository = myRepository,
       _activityLogRepository = activityLogRepository,
       super(MyInitialState());
}
```

**Why optional?** Makes testing easier and prevents errors if logging service is unavailable.

### Step 2: Get Current User in UI Layer

Activity logging requires knowing WHO performed the action. Always get this from the current user context:

```dart
// In your UI code (page/widget with BuildContext):
final currentUser = context.read<TripCubit>().getCurrentUserForTrip(tripId);

if (currentUser == null) {
  // User hasn't joined this trip or hasn't selected identity
  // Show error or prompt to join trip
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Please join the trip first')),
  );
  return;
}

// Use currentUser.name for activity logging
final actorName = currentUser.name;

// Pass actorName to cubit method
context.read<MyCubit>().myAction(..., actorName: actorName);
```

**IMPORTANT**:
- ✅ DO get actor from `TripCubit.getCurrentUserForTrip(tripId)`
- ❌ DON'T use payer/creator/participant names as actor

### Step 3: Log Activity After Successful Operation

```dart
Future<void> myAction(..., {String? actorName}) async {
  try {
    // 1. Perform the main operation FIRST
    await _myRepository.doSomething(...);

    // 2. Log activity (non-fatal, in try-catch)
    if (_activityLogRepository != null && actorName != null && actorName.isNotEmpty) {
      _log('📝 Logging my_action activity...');
      try {
        final activityLog = ActivityLog(
          id: '', // Firestore auto-generates
          tripId: tripId,
          type: ActivityType.myNewActionType, // See available types below
          actorName: actorName,
          description: 'Clear description of what happened',
          timestamp: DateTime.now(),
          metadata: {
            // Optional: store relevant details for richer logs
            'entityId': entityId,
            'oldValue': oldValue,
            'newValue': newValue,
          },
        );
        await _activityLogRepository.addLog(activityLog);
        _log('✅ Activity logged');
      } catch (e) {
        _log('⚠️ Failed to log activity (non-fatal): $e');
        // DON'T throw - logging failures should NOT break main operations
      }
    }

    // 3. Emit success state
    emit(MySuccessState());
  } catch (e) {
    // Main operation failed - DON'T log activity
    emit(MyErrorState(e.toString()));
  }
}
```

### Step 4: Choose Appropriate ActivityType

Available activity types from `ActivityType` enum:

**Trip Management**:
- `tripCreated`
- `tripUpdated`
- `tripDeleted`

**Participants**:
- `memberJoined`
- `participantAdded`
- `participantRemoved`

**Expenses**:
- `expenseAdded`
- `expenseEdited`
- `expenseDeleted`
- `expenseCategoryChanged`
- `expenseSplitModified`

**Settlements**:
- `transferMarkedSettled`
- `transferMarkedUnsettled`

**Security**:
- `deviceVerified`
- `recoveryCodeUsed`

### Step 5: Add Rich Metadata (Optional but Recommended)

For better audit trails, include relevant metadata:

```dart
metadata: {
  'expenseId': expense.id,
  'oldAmount': oldExpense.amount.toString(),
  'newAmount': newExpense.amount.toString(),
  'currency': expense.currency.code,
  'participantCount': expense.splits.length,
}
```

**For expense edits**, use `ExpenseChangeDetector` to track detailed changes:

```dart
import 'package:expense_tracker/features/expenses/domain/utils/expense_change_detector.dart';

// Fetch old expense first
final oldExpense = await _expenseRepository.getExpense(expenseId);

// Update expense
await _expenseRepository.updateExpense(newExpense);

// Detect changes
final changes = ExpenseChangeDetector.detectChanges(
  oldExpense,
  newExpense,
  tripRepository: _tripRepository, // For fetching participant names
);

// Log with rich metadata
final activityLog = ActivityLog(
  type: ActivityType.expenseEdited,
  actorName: actorName,
  description: 'edited ${newExpense.description}',
  metadata: {
    'expenseId': expenseId,
    'changes': changes, // Includes all field changes with before/after
  },
);
```

## Adding New Activity Types

If you need a new activity type not in the enum:

### 1. Add to ActivityType enum

File: `lib/features/trips/domain/models/activity_log.dart`

```dart
enum ActivityType {
  // ... existing types ...

  /// My new action was performed
  myNewAction,
}
```

### 2. Update serialization

File: `lib/features/trips/data/models/activity_log_model.dart`

```dart
// In _activityTypeToString():
case ActivityType.myNewAction:
  return 'myNewAction';

// In _activityTypeFromString():
case 'myNewAction':
  return ActivityType.myNewAction;
```

### 3. Update UI

File: `lib/features/trips/presentation/widgets/activity_log_item.dart`

```dart
// In _getIconForActivityType():
case ActivityType.myNewAction:
  return Icons.my_icon;

// In _getColorForActivityType():
case ActivityType.myNewAction:
  return Colors.blue; // Choose appropriate color

// In _getActionText():
case ActivityType.myNewAction:
  return 'performed my action';
```

### 4. Run code generation

```bash
dart run build_runner build --delete-conflicting-outputs
```

This regenerates mock files for tests.

## Testing Activity Logging

### Testing WITH activity logging:

```dart
// Mock the repository
final mockActivityLogRepo = MockActivityLogRepository();

// Create cubit with mock
final cubit = MyCubit(
  myRepository: mockRepository,
  activityLogRepository: mockActivityLogRepo,
);

// Perform action
await cubit.myAction(..., actorName: 'Test User');

// Verify activity was logged
verify(mockActivityLogRepo.addLog(any)).called(1);
```

### Testing WITHOUT activity logging:

```dart
// Create cubit without activity logging
final cubit = MyCubit(
  myRepository: mockRepository,
  // activityLogRepository: null (omit),
);

// Tests should still pass without activity logging
await cubit.myAction(..., actorName: 'Test User');
```

## Best Practices

**✅ DO:**
- Always inject `ActivityLogRepository` as optional in cubits that perform state changes
- Always get `actorName` from `TripCubit.getCurrentUserForTrip()` (not from payer, creator, etc.)
- Log AFTER successful operation (so failed operations aren't logged)
- Wrap logging in try-catch (logging failures should never break main operations)
- Use clear, descriptive text in `description` field
- Store relevant details in `metadata` for richer logs (optional but recommended)

**❌ DON'T:**
- Don't use payer/creator/participant names as actor - always use current user
- Don't fail operations if activity logging fails (it's optional, non-fatal)
- Don't log before the operation succeeds (only log successful actions)
- Don't require `ActivityLogRepository` (make it optional for testing)
- Don't forget to add new ActivityTypes to serialization methods

## Common Patterns

### Pattern 1: Simple Operation

```dart
Future<void> deleteExpense(String expenseId, {String? actorName}) async {
  try {
    // 1. Main operation
    final expense = await _expenseRepository.getExpense(expenseId);
    await _expenseRepository.deleteExpense(expenseId);

    // 2. Log activity
    if (_activityLogRepository != null && actorName != null && actorName.isNotEmpty) {
      try {
        await _activityLogRepository.addLog(
          ActivityLog(
            id: '',
            tripId: expense.tripId,
            type: ActivityType.expenseDeleted,
            actorName: actorName,
            description: 'deleted ${expense.description}',
            timestamp: DateTime.now(),
            metadata: {'expenseId': expenseId},
          ),
        );
      } catch (e) {
        _log('⚠️ Failed to log activity: $e');
      }
    }

    emit(ExpenseDeletedState());
  } catch (e) {
    emit(ExpenseErrorState(e.toString()));
  }
}
```

### Pattern 2: Complex Edit with Change Detection

```dart
Future<void> updateExpense(Expense newExpense, {String? actorName}) async {
  try {
    // 1. Fetch old expense
    final oldExpense = await _expenseRepository.getExpense(newExpense.id);

    // 2. Update expense
    await _expenseRepository.updateExpense(newExpense);

    // 3. Detect changes
    final changes = ExpenseChangeDetector.detectChanges(
      oldExpense,
      newExpense,
      tripRepository: _tripRepository,
    );

    // 4. Log with rich metadata
    if (_activityLogRepository != null && actorName != null && actorName.isNotEmpty) {
      try {
        await _activityLogRepository.addLog(
          ActivityLog(
            id: '',
            tripId: newExpense.tripId,
            type: ActivityType.expenseEdited,
            actorName: actorName,
            description: 'edited ${newExpense.description}',
            timestamp: DateTime.now(),
            metadata: {
              'expenseId': newExpense.id,
              'changes': changes,
            },
          ),
        );
      } catch (e) {
        _log('⚠️ Failed to log activity: $e');
      }
    }

    emit(ExpenseUpdatedState(newExpense));
  } catch (e) {
    emit(ExpenseErrorState(e.toString()));
  }
}
```

## Decision Checklist

Before implementing activity logging, verify:

- [ ] Is this a state-changing operation? (Create/Update/Delete/Modify)
- [ ] Have I injected `ActivityLogRepository?` (optional) in the cubit constructor?
- [ ] Am I getting `actorName` from `TripCubit.getCurrentUserForTrip()`?
- [ ] Am I logging AFTER the main operation succeeds?
- [ ] Is my logging wrapped in try-catch (non-fatal)?
- [ ] Have I chosen the appropriate `ActivityType`?
- [ ] Is my description clear and descriptive?
- [ ] Should I include metadata for a richer audit trail?
- [ ] If adding new ActivityType, have I updated serialization and UI?
- [ ] Have I run `dart run build_runner build` after enum changes?

## Troubleshooting

**Problem**: Activity not showing in Activity Log UI
- **Check**: Is the user logged in and has joined the trip?
- **Check**: Is `actorName` being passed correctly?
- **Check**: Is the activity being logged without errors? (Check cubit logs)
- **Check**: Is Firestore repository properly saving the activity?

**Problem**: Tests failing after adding activity logging
- **Solution**: Make `ActivityLogRepository` optional and test without it
- **Solution**: Mock the repository and verify calls

**Problem**: "ActivityType.X not found" error
- **Solution**: Run `dart run build_runner build --delete-conflicting-outputs`

## Additional Resources

For more information, see:
- Root CLAUDE.md → Activity Tracking & Audit Trail section
- `lib/features/expenses/domain/utils/expense_change_detector.dart` - Change detection example
- `lib/features/trips/presentation/cubits/trip_cubit.dart` - Activity logging example
