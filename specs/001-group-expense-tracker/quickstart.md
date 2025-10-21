# Quickstart Guide: Group Expense Tracker Development

**Last Updated**: 2025-10-21
**Audience**: Developers implementing the expense tracker feature

## Prerequisites

- Flutter 3.35.1+ installed ([flutter.dev/docs/get-started/install](https://flutter.dev/docs/get-started/install))
- Dart 3.9.0+ (bundled with Flutter)
- Firebase CLI installed (`npm install -g firebase-tools`)
- Firebase project created ([console.firebase.google.com](https://console.firebase.google.com))
- Git repository cloned and on branch `001-group-expense-tracker`

## Initial Setup (One-Time)

### 1. Install Flutter Dependencies

```bash
# Navigate to project root
cd expense_tracker

# Get Flutter dependencies
flutter pub get

# Verify installation
flutter doctor
```

### 2. Configure Firebase

```bash
# Login to Firebase
firebase login

# Initialize Firebase in project
firebase init

# Select features:
# - Firestore
# - Functions
# - Hosting

# Follow prompts:
# - Use existing project: [your-project-id]
# - Firestore rules: firestore.rules
# - Firestore indexes: firestore.indexes.json
# - Functions language: TypeScript
# - Use ESLint: Yes
# - Install dependencies: Yes
# - Public directory: build/web
# - Configure as SPA: Yes
# - Set up automatic builds: No
```

### 3. Add FlutterFire Configuration

```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure Firebase for Flutter
flutterfire configure --project=[your-project-id]

# This generates: lib/firebase_options.dart
```

### 4. Set Up Firebase Emulators (for local development)

```bash
# Start Firebase Emulators
firebase emulators:start --only firestore,functions

# Emulator UI available at: http://localhost:4000
# Firestore emulator: localhost:8080
# Functions emulator: localhost:5001
```

## Development Workflow

### TDD Cycle (Constitutional Requirement)

**RED → GREEN → REFACTOR**

#### Step 1: Write Failing Test (RED)

```bash
# Example: Testing expense split calculation

# Create test file
touch test/unit/features/expenses/expense_split_test.dart
```

```dart
// test/unit/features/expenses/expense_split_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:decimal/decimal.dart';
import 'package:expense_tracker/features/expenses/domain/models/expense.dart';

void main() {
  group('Expense Split Calculation', () {
    test('equal split divides amount evenly among participants', () {
      // Arrange
      final expense = Expense(
        amount: Decimal.parse('100.00'),
        splitType: SplitType.equal,
        participants: {'tai': 1, 'khiet': 1, 'bob': 1, 'ethan': 1},
      );

      // Act
      final shares = expense.calculateShares();

      // Assert
      expect(shares['tai'], equals(Decimal.parse('25.00')));
      expect(shares['khiet'], equals(Decimal.parse('25.00')));
      expect(shares['bob'], equals(Decimal.parse('25.00')));
      expect(shares['ethan'], equals(Decimal.parse('25.00')));
    });
  });
}
```

```bash
# Run test (should FAIL - method doesn't exist yet)
flutter test test/unit/features/expenses/expense_split_test.dart
```

#### Step 2: Implement Minimum Code (GREEN)

```dart
// lib/features/expenses/domain/models/expense.dart
import 'package:decimal/decimal.dart';

enum SplitType { equal, weighted }

class Expense {
  final Decimal amount;
  final SplitType splitType;
  final Map<String, num> participants;

  Expense({
    required this.amount,
    required this.splitType,
    required this.participants,
  });

  Map<String, Decimal> calculateShares() {
    if (splitType == SplitType.equal) {
      final shareAmount = amount / Decimal.fromInt(participants.length);
      return Map.fromEntries(
        participants.keys.map((userId) => MapEntry(userId, shareAmount)),
      );
    }
    // Weighted logic (to be implemented in next test)
    throw UnimplementedError('Weighted split not yet implemented');
  }
}
```

```bash
# Run test (should PASS)
flutter test test/unit/features/expenses/expense_split_test.dart
```

#### Step 3: Refactor (if needed)

```dart
// Refactor for clarity (example: extract helper method)
Map<String, Decimal> calculateShares() {
  return splitType == SplitType.equal
      ? _calculateEqualShares()
      : _calculateWeightedShares();
}

Map<String, Decimal> _calculateEqualShares() {
  final shareAmount = amount / Decimal.fromInt(participants.length);
  return Map.fromEntries(
    participants.keys.map((userId) => MapEntry(userId, shareAmount)),
  );
}
```

```bash
# Re-run test (must still PASS after refactor)
flutter test test/unit/features/expenses/expense_split_test.dart
```

#### Step 4: Repeat for Next Feature

Add test for weighted split, implement, refactor, repeat.

### Running Tests

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/unit/features/expenses/expense_split_test.dart

# Run with coverage
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html  # View coverage report

# Run integration tests (requires Firebase emulator)
firebase emulators:exec --only firestore,functions "flutter test integration_test/"
```

### Code Quality Checks

```bash
# Lint check (must pass - zero tolerance)
flutter analyze

# Format code
flutter format lib/ test/

# Verify complexity (manual check via analyzer)
# Ensure no function has cyclomatic complexity > 10
```

### Building and Running

```bash
# Run in dev mode (hot reload enabled)
flutter run -d chrome

# Run with Firebase emulator
flutter run -d chrome --dart-define=USE_FIREBASE_EMULATOR=true

# Build for production
flutter build web --release

# Preview production build locally
firebase serve --only hosting
```

## Project Structure Navigation

```
lib/
├── main.dart                          # Start here for app initialization
├── core/
│   ├── theme/app_theme.dart           # Material Design 3 theme (8px grid)
│   ├── router/app_router.dart         # go_router configuration
│   └── utils/decimal_helpers.dart     # Decimal formatting utilities
├── features/
│   └── expenses/
│       ├── domain/
│       │   ├── models/expense.dart    # Domain entity (business logic here)
│       │   └── repositories/expense_repository.dart  # Interface
│       ├── data/
│       │   ├── models/expense_model.dart     # Firestore model (toJson/fromJson)
│       │   └── repositories/expense_repository_impl.dart
│       └── presentation/
│           ├── cubits/expense_cubit.dart     # State management
│           ├── pages/expense_list_page.dart  # UI screen
│           └── widgets/expense_card.dart     # Reusable UI component
└── shared/
    ├── widgets/custom_button.dart     # Shared UI components
    └── services/firestore_service.dart # Firebase wrapper

test/
├── unit/                              # Pure logic tests (no Flutter dependencies)
├── widget/                            # UI component tests
├── integration/                       # End-to-end flow tests
└── golden/                            # Visual regression tests
```

## Common Tasks

### Add New Feature

```bash
# 1. Create feature folder structure
mkdir -p lib/features/my_feature/{domain,data,presentation}/{models,repositories,cubits,pages,widgets}

# 2. Write domain model test (TDD - RED)
touch test/unit/features/my_feature/my_model_test.dart

# 3. Implement domain model (GREEN)
touch lib/features/my_feature/domain/models/my_model.dart

# 4. Refactor and continue TDD cycle
```

### Add New Firestore Collection

```bash
# 1. Update Firestore schema contract
vim specs/001-group-expense-tracker/contracts/firestore-schema.md

# 2. Add Firestore model with toJson/fromJson
touch lib/features/my_feature/data/models/my_model_firestore.dart

# 3. Update security rules
vim firestore.rules

# 4. Add required indexes
vim firestore.indexes.json

# 5. Deploy rules and indexes
firebase deploy --only firestore:rules,firestore:indexes
```

### Add New Cloud Function

```bash
# Navigate to functions directory
cd functions

# Install dependencies if needed
npm install

# Create function file
touch src/my-function.ts

# Register in index.ts
echo "export { myFunction } from './my-function';" >> src/index.ts

# Deploy function
firebase deploy --only functions:myFunction
```

### Update Dependencies

```bash
# Check for outdated packages
flutter pub outdated

# Update to latest compatible versions
flutter pub upgrade

# Update to specific version
flutter pub add decimal:^2.3.3
```

## Debugging

### Flutter DevTools

```bash
# Run app in debug mode
flutter run -d chrome

# In terminal, press 'v' to open Flutter DevTools in browser
# Or visit: http://localhost:9100
```

**Key DevTools Features**:
- **Inspector**: UI widget tree visualization
- **Performance**: Frame rendering profiling
- **Network**: Firestore query monitoring
- **Logging**: Console output and errors

### Firebase Debugging

```bash
# View Firestore emulator data
# Open: http://localhost:4000/firestore

# View Functions logs (local)
# Check terminal where `firebase emulators:start` is running

# View production Firebase logs
firebase functions:log

# View Firestore indexes
# Open: https://console.firebase.google.com/project/[project-id]/firestore/indexes
```

### Common Issues

**Issue**: "MissingPluginException"
```bash
# Solution: Stop app, clean, rebuild
flutter clean
flutter pub get
flutter run -d chrome
```

**Issue**: Firestore queries fail with "index required" error
```bash
# Solution: Click the link in error message to create index in Firebase Console
# Or add to firestore.indexes.json and deploy
firebase deploy --only firestore:indexes
```

**Issue**: Tests fail with "Null check operator used on a null value"
```bash
# Solution: Initialize Firebase in test setup
setUpAll(() async {
  // Initialize Firebase mock or use emulator
});
```

## Performance Profiling

```bash
# Profile build performance
flutter build web --profile --source-maps

# Analyze bundle size
flutter build web --analyze-size

# Run performance tests
flutter test test/performance/settlement_calculation_benchmark_test.dart
```

## Deployment

```bash
# 1. Run full test suite
flutter test --coverage

# 2. Verify coverage meets requirements (80% business logic)
# Open coverage/html/index.html and check

# 3. Build for production
flutter build web --release

# 4. Deploy to Firebase Hosting
firebase deploy --only hosting

# 5. Deploy Cloud Functions
firebase deploy --only functions

# Visit: https://[project-id].web.app
```

## Git Workflow

```bash
# Create feature sub-branch (optional)
git checkout -b 001-group-expense-tracker/expense-split

# Make changes, run tests, commit
git add .
git commit -m "feat(expenses): implement equal split calculation

- Add Expense.calculateShares() method
- Add unit tests for equal split
- Coverage: 100% for split logic

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"

# Push to remote
git push -u origin 001-group-expense-tracker/expense-split

# Create PR on GitHub
gh pr create --title "feat: implement expense split calculation" --body "Implements equal and weighted split algorithms per spec FR-004, FR-006"
```

## Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [Firebase for Flutter](https://firebase.flutter.dev/)
- [BLoC Library Docs](https://bloclibrary.dev/)
- [Decimal Package](https://pub.dev/packages/decimal)
- [Project Constitution](../../.specify/memory/constitution.md)
- [Feature Specification](./spec.md)
- [Implementation Plan](./plan.md)

## Next Steps

After setup complete:

1. Review [spec.md](./spec.md) for functional requirements
2. Review [data-model.md](./data-model.md) for domain entities
3. Run `/speckit.tasks` to generate actionable tasks
4. Start with P1 user stories (expense recording, settlement summary)
5. Follow TDD cycle for every task

**Constitutional Reminder**: Tests must pass before merge, coverage ≥ 80% business logic, zero lint warnings.
