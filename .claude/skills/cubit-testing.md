# Cubit Testing Skill

## Description
This skill provides a systematic workflow for writing comprehensive BLoC/Cubit tests in the expense tracker app. Tests use Mockito for mocking dependencies and flutter_test for assertions.

## When to Use
- Creating new cubits
- Adding methods to existing cubits
- Refactoring cubit logic
- Fixing bugs in state management
- When test coverage drops

## Core Philosophy
**Test behavior, not implementation.** Focus on testing what the cubit does (state emissions, method calls, side effects) rather than how it does it internally.

## Key Dependencies
- `flutter_test` - Flutter testing framework
- `mockito` - Mocking framework
- `build_runner` - Code generation for mocks

## Workflow

### Step 1: Create Test File Structure

Test files mirror the source file structure:

```
Source: lib/features/trips/presentation/cubits/trip_cubit.dart
Test:   test/features/trips/presentation/cubits/trip_cubit_test.dart
```

### Step 2: Set Up Mock Annotations

At the top of your test file, import dependencies and generate mocks:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

// Import the cubit and its dependencies
import 'package:expense_tracker/features/trips/presentation/cubits/trip_cubit.dart';
import 'package:expense_tracker/features/trips/presentation/cubits/trip_state.dart';
import 'package:expense_tracker/features/trips/domain/repositories/trip_repository.dart';
import 'package:expense_tracker/core/services/activity_logger_service.dart';

// Generate mocks using annotations
@GenerateMocks([
  TripRepository,
  ActivityLoggerService,
  // Add all dependencies here
])
import 'trip_cubit_test.mocks.dart'; // This file will be generated
```

**IMPORTANT**: After adding `@GenerateMocks`, run:

```bash
dart run build_runner build --delete-conflicting-outputs
```

This generates the `.mocks.dart` file.

### Step 3: Set Up Test Structure

Use `setUp`, `tearDown`, and `group` for organization:

```dart
void main() {
  late TripCubit cubit;
  late MockTripRepository mockTripRepository;
  late MockActivityLoggerService mockActivityLoggerService;

  setUp(() {
    // Initialize mocks
    mockTripRepository = MockTripRepository();
    mockActivityLoggerService = MockActivityLoggerService();

    // Set up default stubs (common return values)
    when(mockTripRepository.getAllTrips()).thenAnswer(
      (_) => Stream.value([]),
    );

    // Create cubit with mocks
    cubit = TripCubit(
      tripRepository: mockTripRepository,
      activityLoggerService: mockActivityLoggerService,
    );
  });

  tearDown(() {
    // Clean up
    cubit.close();
  });

  group('Feature Name or Behavior Group', () {
    test('should do something specific', () async {
      // Test code here
    });
  });
}
```

### Step 4: Write Tests Using Arrange-Act-Assert

Follow the AAA pattern for clarity:

```dart
test('should create trip and add creator as participant', () async {
  // Arrange - Set up test data and mock behavior
  const tripName = 'Test Trip';
  const creatorName = 'Alice';

  final createdTrip = Trip(
    id: 'trip-123',
    name: tripName,
    participants: [Participant.fromName(creatorName)],
    createdAt: DateTime.now(),
  );

  when(mockTripRepository.createTrip(any)).thenAnswer(
    (_) async => createdTrip,
  );
  when(mockActivityLoggerService.logTripCreated(any, any)).thenAnswer(
    (_) async {},
  );

  // Act - Call the method being tested
  await cubit.createTrip(
    name: tripName,
    creatorName: creatorName,
  );

  // Wait for async operations if needed
  await Future.delayed(const Duration(milliseconds: 100));

  // Assert - Verify expected behavior
  verify(mockTripRepository.createTrip(any)).called(1);
  verify(mockActivityLoggerService.logTripCreated(any, any)).called(1);

  final capturedTrip = verify(
    mockTripRepository.createTrip(captureAny),
  ).captured.single as Trip;

  expect(capturedTrip.participants.length, 1);
  expect(capturedTrip.participants.first.name, creatorName);
});
```

### Step 5: Test State Emissions

Use `expectLater` and `emitsInOrder` to test state changes:

```dart
test('should emit loading then loaded states', () async {
  // Arrange
  final trips = [
    Trip(id: '1', name: 'Trip 1', createdAt: DateTime.now()),
    Trip(id: '2', name: 'Trip 2', createdAt: DateTime.now()),
  ];

  when(mockTripRepository.getAllTrips()).thenAnswer(
    (_) => Stream.value(trips),
  );

  // Assert (before Act for stream tests)
  expectLater(
    cubit.stream,
    emitsInOrder([
      isA<TripLoadingState>(),
      isA<TripLoadedState>().having(
        (state) => state.trips,
        'trips',
        trips,
      ),
    ]),
  );

  // Act
  cubit.loadTrips();
});
```

### Step 6: Verify Method Calls and Arguments

Use `verify`, `verifyNever`, `verifyInOrder`, and `captureAny`:

```dart
test('should call repository with correct arguments', () async {
  // Arrange
  const tripName = 'Test Trip';
  const baseCurrency = CurrencyCode.usd;

  when(mockTripRepository.createTrip(any)).thenAnswer(
    (_) async => Trip(id: 'trip-123', name: tripName, createdAt: DateTime.now()),
  );

  // Act
  await cubit.createTrip(name: tripName, baseCurrency: baseCurrency);

  // Assert - Verify method called once
  verify(mockTripRepository.createTrip(any)).called(1);

  // Assert - Capture and verify arguments
  final capturedTrip = verify(
    mockTripRepository.createTrip(captureAny),
  ).captured.single as Trip;

  expect(capturedTrip.name, tripName);
  expect(capturedTrip.baseCurrency, baseCurrency);
});
```

### Step 7: Test Error Handling

Verify error states are emitted correctly:

```dart
test('should emit error state when repository throws', () async {
  // Arrange
  const errorMessage = 'Failed to create trip';

  when(mockTripRepository.createTrip(any)).thenThrow(
    Exception(errorMessage),
  );

  // Assert (before Act for stream tests)
  expectLater(
    cubit.stream,
    emitsInOrder([
      isA<TripLoadingState>(),
      isA<TripErrorState>().having(
        (state) => state.message,
        'error message',
        contains(errorMessage),
      ),
    ]),
  );

  // Act
  await cubit.createTrip(name: 'Test Trip');
});
```

### Step 8: Test Activity Logging (if applicable)

Verify activity logging calls:

```dart
test('should log trip_created activity', () async {
  // Arrange
  const tripName = 'Test Trip';
  const creatorName = 'Alice';

  final createdTrip = Trip(
    id: 'trip-123',
    name: tripName,
    createdAt: DateTime.now(),
  );

  when(mockTripRepository.createTrip(any)).thenAnswer(
    (_) async => createdTrip,
  );
  when(mockActivityLoggerService.logTripCreated(any, any)).thenAnswer(
    (_) async {},
  );

  // Act
  await cubit.createTrip(
    name: tripName,
    creatorName: creatorName,
  );

  // Assert - Verify activity logging was called
  verify(mockActivityLoggerService.logTripCreated(
    createdTrip.id,
    creatorName,
  )).called(1);
});
```

## Common Testing Patterns

### Pattern 1: Testing with Streams

```dart
test('should react to repository stream updates', () async {
  // Arrange
  final streamController = StreamController<List<Trip>>();
  final trips = [
    Trip(id: '1', name: 'Trip 1', createdAt: DateTime.now()),
  ];

  when(mockTripRepository.getAllTrips()).thenAnswer(
    (_) => streamController.stream,
  );

  // Act
  cubit.loadTrips();
  streamController.add(trips);
  await Future.delayed(const Duration(milliseconds: 100));

  // Assert
  expect(cubit.state, isA<TripLoadedState>());
  expect((cubit.state as TripLoadedState).trips, trips);

  // Cleanup
  await streamController.close();
});
```

### Pattern 2: Testing with Multiple Dependencies

```dart
test('should coordinate between multiple services', () async {
  // Arrange
  when(mockTripRepository.createTrip(any)).thenAnswer(
    (_) async => Trip(id: 'trip-123', name: 'Test', createdAt: DateTime.now()),
  );
  when(mockCategoryRepository.seedDefaultCategories(any)).thenAnswer(
    (_) async => [],
  );
  when(mockActivityLoggerService.logTripCreated(any, any)).thenAnswer(
    (_) async {},
  );

  // Act
  await cubit.createTrip(name: 'Test Trip', creatorName: 'Alice');

  // Assert - Verify order of operations
  verifyInOrder([
    mockTripRepository.createTrip(any),
    mockCategoryRepository.seedDefaultCategories(any),
    mockActivityLoggerService.logTripCreated(any, any),
  ]);
});
```

### Pattern 3: Testing Optional Dependencies

```dart
test('should work without optional dependencies', () async {
  // Arrange - Create cubit without activity logger
  final cubitWithoutLogger = TripCubit(
    tripRepository: mockTripRepository,
    // activityLoggerService: null (omit),
  );

  when(mockTripRepository.createTrip(any)).thenAnswer(
    (_) async => Trip(id: 'trip-123', name: 'Test', createdAt: DateTime.now()),
  );

  // Act
  await cubitWithoutLogger.createTrip(name: 'Test Trip');

  // Assert - Should succeed without logging
  verify(mockTripRepository.createTrip(any)).called(1);
  verifyNever(mockActivityLoggerService.logTripCreated(any, any));

  // Cleanup
  await cubitWithoutLogger.close();
});
```

## Running Tests

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/features/trips/presentation/cubits/trip_cubit_test.dart

# Run with coverage
flutter test --coverage

# Run specific test by name
flutter test --name "should create trip"
```

## Generate Mocks

After adding or modifying `@GenerateMocks` annotations:

```bash
dart run build_runner build --delete-conflicting-outputs
```

## Best Practices

**✅ DO:**
- Use descriptive test names that describe behavior: `'should emit error when repository throws'`
- Follow Arrange-Act-Assert pattern for clarity
- Test one behavior per test
- Use `group` to organize related tests
- Mock all dependencies
- Verify method calls with `verify`
- Test error cases, not just happy paths
- Clean up with `tearDown` (call `cubit.close()`)
- Wait for async operations with `await Future.delayed(...)` when needed
- Use `captureAny` to verify arguments passed to mocks

**❌ DON'T:**
- Don't test implementation details (private methods, internal state)
- Don't create overly complex test setups
- Don't forget to call `cubit.close()` in `tearDown`
- Don't hardcode timing (use reasonable delays like 100ms)
- Don't mock the cubit being tested
- Don't forget to run `build_runner` after adding mocks
- Don't test multiple behaviors in one test

## Troubleshooting

**Problem**: "Missing stub" error when running tests
- **Solution**: Add `when(...).thenAnswer(...)` stub for the method being called

**Problem**: "Used on a mock that is not a Mockito mock" error
- **Solution**: Ensure you're using the generated `Mock*` class, not the real class

**Problem**: `.mocks.dart` file not found
- **Solution**: Run `dart run build_runner build --delete-conflicting-outputs`

**Problem**: Test times out waiting for stream
- **Solution**: Use `await Future.delayed(const Duration(milliseconds: 100))` after triggering async operations

**Problem**: "Bad state: No element" when capturing arguments
- **Solution**: Verify the method was actually called before trying to capture: `verify(...).called(1)`

**Problem**: State not updating in test
- **Solution**: Ensure you're awaiting async operations and giving time for state to propagate

## Test Coverage Goals

Aim for:
- **Line coverage**: >80%
- **Branch coverage**: >75%
- **Critical paths**: 100% (create, update, delete operations)

Run coverage report:

```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

## Decision Checklist

Before considering tests complete:

- [ ] Have I tested the happy path (success case)?
- [ ] Have I tested error cases (repository throws)?
- [ ] Have I verified state emissions?
- [ ] Have I verified method calls to dependencies?
- [ ] Have I verified activity logging (if applicable)?
- [ ] Have I tested with and without optional dependencies?
- [ ] Have I used descriptive test names?
- [ ] Have I organized tests with `group`?
- [ ] Have I called `cubit.close()` in `tearDown`?
- [ ] Have I run `dart run build_runner build` after adding mocks?
- [ ] Do all tests pass?

## Additional Resources

For more information, see:
- Existing test files in `test/features/*/presentation/cubits/*_test.dart`
- [Mockito documentation](https://pub.dev/packages/mockito)
- [BLoC testing guide](https://bloclibrary.dev/#/testing)
