# Project Knowledge - Expense Tracker Architecture

This document provides architectural overview, design patterns, and integration points for the expense tracker project.

## Table of Contents
- [Project Overview](#project-overview)
- [Technology Stack](#technology-stack)
- [Project Structure](#project-structure)
- [Architecture Layers](#architecture-layers)
- [State Management](#state-management)
- [Data Flow](#data-flow)
- [Firebase Integration](#firebase-integration)
- [Key Design Patterns](#key-design-patterns)
- [Feature Organization](#feature-organization)

## Project Overview

This is a Flutter web application for tracking group expenses on trips with multi-currency support and settlement calculations. The project uses spec-driven development via GitHub Spec-Kit.

**Core Features**:
- Trip management with base currency (USD/VND)
- Expense recording with split types (equal/weighted)
- Multi-currency support with exchange rates
- Settlement calculations with pairwise netting
- Minimal transfer algorithm
- Per-person dashboards with category breakdown
- Comprehensive activity logging for audit trails

**Development Philosophy**:
- Mobile-first design (target: 375x667px iPhone SE)
- Spec-driven development with GitHub Spec-Kit
- Clean architecture with clear layer separation
- Comprehensive localization (250+ strings)
- Activity logging for all state-changing operations

## Technology Stack

**Core Framework**:
- Flutter SDK 3.9.0+ (web platform)
- Dart programming language

**State Management**:
- BLoC/Cubit pattern
- flutter_bloc package

**Localization**:
- flutter_localizations (built-in)
- intl package
- ARB format (250+ English strings)

**Backend/Database**:
- Firebase (Firestore for data, Auth for identity)
- Local storage for user preferences

**CI/CD**:
- GitHub Actions for automated deployment
- GitHub Pages for hosting

**Development Tools**:
- Spec-Kit for specification-driven development
- Mockito for testing
- build_runner for code generation

## Project Structure

```
expense_tracker/
├── lib/
│   ├── main.dart                    # Application entry point
│   ├── core/                        # Shared core functionality
│   │   ├── models/                  # Shared models (CurrencyCode, Participant)
│   │   ├── services/                # Core services (ActivityLogger, LocalStorage)
│   │   ├── l10n/                    # Localization utilities
│   │   └── utils/                   # Shared utilities
│   ├── shared/                      # Shared UI components
│   │   ├── widgets/                 # Reusable widgets (CurrencyTextField)
│   │   └── utils/                   # UI utilities (CurrencyInputFormatter)
│   ├── features/                    # Feature modules
│   │   ├── trips/                   # Trip management
│   │   ├── expenses/                # Expense tracking
│   │   ├── settlements/             # Settlement calculations
│   │   ├── categories/              # Expense categories
│   │   └── device_pairing/          # Device verification
│   └── l10n/                        # Localization files (ARB)
├── test/                            # Test files (mirrors lib/ structure)
├── web/                             # Web-specific files
├── specs/                           # Feature specifications (Spec-Kit)
├── .claude/                         # Claude Code configuration
│   ├── skills/                      # Reusable workflow skills
│   ├── commands/                    # Custom slash commands
│   └── memory/                      # Session memory
├── .specify/                        # Spec-Kit configuration
└── .github/                         # GitHub Actions workflows
```

## Architecture Layers

The app follows **Clean Architecture** with clear separation of concerns:

### Presentation Layer
**Responsibility**: UI and user interaction

**Components**:
- **Pages**: Full-screen views (`*_page.dart`)
- **Widgets**: Reusable UI components (`*.dart`)
- **Cubits**: State management (`*_cubit.dart` + `*_state.dart`)

**Location**: `lib/features/*/presentation/`

**Dependencies**:
- Can depend on Domain layer
- Cannot depend on Data layer

**Example**:
```dart
// lib/features/expenses/presentation/pages/expense_form_page.dart
// lib/features/expenses/presentation/cubits/expense_cubit.dart
```

### Domain Layer
**Responsibility**: Business logic and interfaces

**Components**:
- **Models**: Domain entities (immutable, business logic)
- **Repositories**: Abstract interfaces (contracts)
- **Utils**: Business logic helpers

**Location**: `lib/features/*/domain/`

**Dependencies**:
- No dependencies on other layers
- Pure Dart (no Flutter imports)

**Example**:
```dart
// lib/features/expenses/domain/models/expense.dart
// lib/features/expenses/domain/repositories/expense_repository.dart
```

### Data Layer
**Responsibility**: Data persistence and external services

**Components**:
- **Repositories**: Concrete implementations
- **Models**: Serialization models (toJson/fromJson)
- **Data Sources**: External API/database access

**Location**: `lib/features/*/data/`

**Dependencies**:
- Implements Domain layer interfaces
- Can use external packages (Firebase, HTTP, etc.)

**Example**:
```dart
// lib/features/expenses/data/repositories/expense_repository_impl.dart
// lib/features/expenses/data/models/expense_model.dart
```

## State Management

The app uses **BLoC/Cubit** pattern for state management:

### Cubit Structure

```dart
class ExpenseCubit extends Cubit<ExpenseState> {
  final ExpenseRepository _expenseRepository;
  final ActivityLogRepository? _activityLogRepository; // Optional

  ExpenseCubit({
    required ExpenseRepository expenseRepository,
    ActivityLogRepository? activityLogRepository,
  }) : _expenseRepository = expenseRepository,
       _activityLogRepository = activityLogRepository,
       super(ExpenseInitialState());

  Future<void> createExpense(Expense expense, {String? actorName}) async {
    emit(ExpenseLoadingState());
    try {
      final created = await _expenseRepository.createExpense(expense);

      // Activity logging (optional, non-fatal)
      if (_activityLogRepository != null && actorName != null) {
        try {
          await _activityLogRepository.addLog(...);
        } catch (e) {
          // Log but don't fail
        }
      }

      emit(ExpenseCreatedState(created));
    } catch (e) {
      emit(ExpenseErrorState(e.toString()));
    }
  }
}
```

### State Classes

```dart
abstract class ExpenseState {}

class ExpenseInitialState extends ExpenseState {}
class ExpenseLoadingState extends ExpenseState {}
class ExpenseLoadedState extends ExpenseState {
  final List<Expense> expenses;
  ExpenseLoadedState(this.expenses);
}
class ExpenseCreatedState extends ExpenseState {
  final Expense expense;
  ExpenseCreatedState(this.expense);
}
class ExpenseErrorState extends ExpenseState {
  final String message;
  ExpenseErrorState(this.message);
}
```

### UI Integration

```dart
BlocProvider(
  create: (context) => ExpenseCubit(
    expenseRepository: context.read<ExpenseRepository>(),
    activityLogRepository: context.read<ActivityLogRepository>(),
  ),
  child: BlocBuilder<ExpenseCubit, ExpenseState>(
    builder: (context, state) {
      if (state is ExpenseLoadingState) {
        return CircularProgressIndicator();
      } else if (state is ExpenseLoadedState) {
        return ExpenseList(expenses: state.expenses);
      } else if (state is ExpenseErrorState) {
        return ErrorMessage(message: state.message);
      }
      return Container();
    },
  ),
)
```

## Data Flow

### Create Operation Flow

```
User Action (UI)
    ↓
ExpenseFormPage
    ↓ context.read<ExpenseCubit>().createExpense(...)
ExpenseCubit
    ↓ emit(LoadingState)
    ↓ _expenseRepository.createExpense(...)
ExpenseRepositoryImpl
    ↓ Firestore.collection('expenses').add(...)
Firebase
    ↓ Returns created expense with ID
ExpenseRepositoryImpl
    ↓ Returns Expense
ExpenseCubit
    ↓ _activityLogRepository.addLog(...) [optional]
    ↓ emit(ExpenseCreatedState)
ExpenseFormPage
    ↓ BlocListener reacts to state
    ↓ Navigator.pop() or show success
User Sees Result
```

### Read Operation Flow (Stream)

```
ExpenseCubit.loadExpenses()
    ↓
ExpenseRepositoryImpl.getExpenses()
    ↓
Firestore.collection('expenses').snapshots()
    ↓ (Real-time stream)
ExpenseRepositoryImpl
    ↓ Maps snapshots to List<Expense>
    ↓ Returns Stream<List<Expense>>
ExpenseCubit
    ↓ Listens to stream
    ↓ emit(ExpenseLoadedState(expenses)) on each update
UI (BlocBuilder)
    ↓ Rebuilds with new expenses
User Sees Updated Data
```

## Firebase Integration

### Firestore Structure

```
firestore/
├── trips/
│   ├── {tripId}/
│   │   ├── fields: name, baseCurrency, createdAt, updatedAt, participants[]
│   │   └── subcollections:
│   │       ├── expenses/
│   │       │   └── {expenseId}/
│   │       │       └── fields: amount, currency, description, payerId, date, splits[]
│   │       ├── categories/
│   │       │   └── {categoryId}/
│   │       │       └── fields: name, icon, color
│   │       └── activityLogs/
│   │           └── {logId}/
│   │               └── fields: type, actorName, description, timestamp, metadata
```

### Repository Pattern

**Interface** (Domain Layer):
```dart
abstract class ExpenseRepository {
  Future<Expense> createExpense(Expense expense);
  Future<void> updateExpense(Expense expense);
  Future<void> deleteExpense(String expenseId);
  Stream<List<Expense>> getExpenses(String tripId);
}
```

**Implementation** (Data Layer):
```dart
class ExpenseRepositoryImpl implements ExpenseRepository {
  final FirebaseFirestore _firestore;

  @override
  Future<Expense> createExpense(Expense expense) async {
    final doc = await _firestore
        .collection('trips/${expense.tripId}/expenses')
        .add(ExpenseModel.fromDomain(expense).toJson());
    return expense.copyWith(id: doc.id);
  }

  // ... other methods
}
```

## Key Design Patterns

### 1. Repository Pattern
**Purpose**: Abstract data access

**Implementation**:
- Domain layer defines interface
- Data layer provides implementation
- Cubits depend on abstraction, not concrete implementation

### 2. BLoC/Cubit Pattern
**Purpose**: State management and business logic

**Implementation**:
- Cubit receives user actions
- Cubit coordinates between repositories
- Cubit emits states
- UI reacts to state changes

### 3. Dependency Injection
**Purpose**: Loose coupling, testability

**Implementation**:
- BlocProvider for Cubits
- RepositoryProvider for Repositories
- Constructor injection for dependencies

### 4. Immutable Models
**Purpose**: Predictable state, easier testing

**Implementation**:
- All models use `final` fields
- Use `copyWith` for updates
- Freezed package for some models

### 5. Activity Logging Pattern
**Purpose**: Audit trail for all state changes

**Implementation**:
- Optional ActivityLogRepository in Cubits
- Non-fatal logging (wrapped in try-catch)
- Actor from current user context
- Rich metadata for detailed audit trail

### 6. Localization Pattern
**Purpose**: Internationalization support

**Implementation**:
- ARB files for strings (app_en.arb)
- context.l10n.* for accessing strings
- Parameters for dynamic content
- Pluralization support

## Feature Organization

Each feature follows this structure:

```
lib/features/expenses/
├── domain/
│   ├── models/
│   │   └── expense.dart              # Domain model
│   ├── repositories/
│   │   └── expense_repository.dart   # Abstract interface
│   └── utils/
│       └── expense_calculator.dart   # Business logic helpers
├── data/
│   ├── models/
│   │   └── expense_model.dart        # Serialization model
│   ├── repositories/
│   │   └── expense_repository_impl.dart  # Concrete implementation
│   └── datasources/
│       └── expense_remote_datasource.dart  # Firebase access
└── presentation/
    ├── pages/
    │   ├── expense_list_page.dart
    │   └── expense_form_page.dart
    ├── widgets/
    │   ├── expense_card.dart
    │   └── expense_filter.dart
    └── cubits/
        ├── expense_cubit.dart
        └── expense_state.dart
```

### Cross-Feature Dependencies

**Allowed**:
- Features can depend on core/ and shared/
- Features can depend on other features' domain layer (read-only)

**Not Allowed**:
- Features should NOT depend on other features' presentation layer
- Features should NOT depend on other features' data layer

**Example**:
```dart
// ✅ ALLOWED: Expenses feature using Trip domain model
import 'package:expense_tracker/features/trips/domain/models/trip.dart';

// ❌ NOT ALLOWED: Expenses feature using Trip cubit
import 'package:expense_tracker/features/trips/presentation/cubits/trip_cubit.dart';
// (Instead, use dependency injection or shared service)
```

## Testing Strategy

### Unit Tests
**Target**: Cubits, Utils, Models

**Pattern**:
```dart
test('should emit success state when expense is created', () async {
  // Arrange
  when(mockRepository.createExpense(any)).thenAnswer((_) async => expense);

  // Act
  await cubit.createExpense(expense);

  // Assert
  expect(cubit.state, isA<ExpenseCreatedState>());
});
```

### Widget Tests
**Target**: Pages, Widgets

**Pattern**:
```dart
testWidgets('should display expense list', (tester) async {
  // Arrange
  await tester.pumpWidget(MaterialApp(
    home: BlocProvider.value(
      value: mockCubit,
      child: ExpenseListPage(),
    ),
  ));

  // Assert
  expect(find.byType(ExpenseCard), findsWidgets);
});
```

### Integration Tests
**Target**: End-to-end flows

**Pattern**:
```dart
testWidgets('should create expense and navigate back', (tester) async {
  // Full flow test
});
```

## Common Architectural Questions

### Q: Where should validation logic go?
**A**: In the Domain layer (models or utils), NOT in presentation or data layers.

### Q: Where should I put shared widgets?
**A**: In `lib/shared/widgets/` if used across multiple features, or in the feature's `presentation/widgets/` if feature-specific.

### Q: How do I share data between features?
**A**: Use shared services in `lib/core/services/` or dependency injection, NOT direct cubit dependencies.

### Q: Where do I put constants?
**A**: In the domain layer of the relevant feature, or `lib/core/` if truly global.

### Q: Should I create a new feature or extend an existing one?
**A**: Create a new feature if it has its own data models and business logic. Extend if it's a view or variant of existing functionality.

## Migration Notes

### From Old Pattern to New Pattern

If you encounter old code that doesn't follow these patterns:

1. **Hardcoded strings** → Use `context.l10n.*`
2. **Plain TextField for currency** → Use `CurrencyTextField`
3. **No activity logging** → Add ActivityLogRepository
4. **No responsive design** → Add MediaQuery checks
5. **Desktop-first layout** → Refactor for mobile-first

## Additional Resources

- [MOBILE.md](MOBILE.md) - Mobile-first design guidelines
- [DEVELOPMENT.md](DEVELOPMENT.md) - Development workflows
- [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - Common issues and solutions
- Root [CLAUDE.md](CLAUDE.md) - Quick reference hub
- `.claude/skills/` - Reusable workflow skills
