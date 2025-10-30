# Read With Context Skill

## Description
This skill provides a systematic workflow for understanding code in context by finding and reading related files. Use this when you need to understand how a feature works, trace data flow, or gather context before making changes.

## When to Use
- Understanding a new feature before modifying it
- Tracing how data flows through the app
- Finding all files related to a specific feature
- Understanding dependencies before refactoring
- Debugging issues that span multiple files
- Before answering "how does X work?" questions

## Core Philosophy
**Code doesn't exist in isolation.** To truly understand a file, you must understand its dependencies, consumers, and the patterns it follows. Always read with context, not in isolation.

## Workflow

### Step 1: Identify the Feature/Component

Start by identifying what you're trying to understand:

**Examples**:
- "How does expense creation work?"
- "How is trip data stored?"
- "Where are participants managed?"
- "How does the activity log work?"

### Step 2: Find the Entry Point

Locate the main file(s) for the feature:

```bash
# Find files by name pattern
find . -name "*expense*" -type f

# Or use glob pattern
**/*expense*.dart

# Search for specific class/function names
grep -r "class ExpenseForm" lib/
```

**Common entry points**:
- **Pages**: `lib/features/*/presentation/pages/*_page.dart`
- **Widgets**: `lib/features/*/presentation/widgets/*.dart`
- **Cubits**: `lib/features/*/presentation/cubits/*_cubit.dart`
- **Models**: `lib/features/*/domain/models/*.dart`
- **Repositories**: `lib/features/*/domain/repositories/*_repository.dart`

### Step 3: Map the Architecture Layers

The app follows clean architecture. For any feature, map these layers:

```
Presentation Layer (UI)
├── Pages (lib/features/*/presentation/pages/)
├── Widgets (lib/features/*/presentation/widgets/)
└── Cubits (lib/features/*/presentation/cubits/)
    ↓ uses
Domain Layer (Business Logic)
├── Models (lib/features/*/domain/models/)
├── Repositories (lib/features/*/domain/repositories/) [interfaces]
└── Utils (lib/features/*/domain/utils/)
    ↓ implemented by
Data Layer (Implementation)
├── Repositories (lib/features/*/data/repositories/) [concrete]
├── Models (lib/features/*/data/models/) [serialization]
└── Data Sources (lib/features/*/data/datasources/)
```

### Step 4: Read in Dependency Order

Read files in this order to build understanding progressively:

#### 1. Domain Models (Data Structures)
Start with the data you're working with:

```dart
// lib/features/expenses/domain/models/expense.dart
// Understand: What fields? What types? Immutable? Validation?
```

#### 2. Domain Repository Interfaces (Contracts)
See what operations are available:

```dart
// lib/features/expenses/domain/repositories/expense_repository.dart
// Understand: What methods? What do they return? What errors?
```

#### 3. Cubit/State Management (Business Logic)
See how operations are orchestrated:

```dart
// lib/features/expenses/presentation/cubits/expense_cubit.dart
// Understand: What actions? What states? What dependencies?
```

#### 4. UI Layer (User Interface)
See how users interact:

```dart
// lib/features/expenses/presentation/pages/expense_form_page.dart
// Understand: What UI? What triggers? What displays states?
```

#### 5. Data Implementation (Storage)
See how data is persisted:

```dart
// lib/features/expenses/data/repositories/expense_repository_impl.dart
// Understand: Where stored? How serialized? Error handling?
```

### Step 5: Trace Data Flow

Follow the data through the system:

**Create Operation Example**:

1. **UI triggers action**:
   ```dart
   // expense_form_page.dart
   context.read<ExpenseCubit>().createExpense(expense, actorName: actorName);
   ```

2. **Cubit processes**:
   ```dart
   // expense_cubit.dart
   Future<void> createExpense(Expense expense, {String? actorName}) async {
     await _expenseRepository.createExpense(expense);
     await _activityLogRepository.addLog(...);
     emit(ExpenseCreatedState(expense));
   }
   ```

3. **Repository saves**:
   ```dart
   // expense_repository_impl.dart
   Future<Expense> createExpense(Expense expense) async {
     final doc = await _firestore.collection('expenses').add(expense.toJson());
     return expense.copyWith(id: doc.id);
   }
   ```

4. **UI reacts to state**:
   ```dart
   // expense_form_page.dart
   BlocListener<ExpenseCubit, ExpenseState>(
     listener: (context, state) {
       if (state is ExpenseCreatedState) {
         Navigator.pop(context);
       }
     },
   )
   ```

### Step 6: Identify Related Patterns

Look for common patterns used in the file:

**State Management**:
- Is it using BLoC/Cubit?
- What states are emitted?
- How are errors handled?

**Localization**:
- Are strings hardcoded? (❌ anti-pattern)
- Using `context.l10n.*`? (✅ correct)

**Activity Logging**:
- Is `ActivityLogRepository` injected?
- Is logging wrapped in try-catch?
- Is actorName passed from `getCurrentUserForTrip()`?

**Mobile-First Design**:
- Using `MediaQuery` for responsive sizing?
- Forms wrapped in `SingleChildScrollView`?
- Modal bottom sheets for complex input?

**Currency Handling**:
- Using `CurrencyTextField`? (✅ correct)
- Using plain TextField? (❌ anti-pattern)

### Step 7: Find Similar Implementations

If you're modifying or adding a feature, find similar existing code:

**Example: Adding a new form page**
```bash
# Find other form pages
find lib/ -name "*_form_page.dart"

# Read a reference implementation
# expense_form_page.dart - Good example with:
# - Mobile-first design
# - CurrencyTextField
# - Activity logging
# - L10n strings
```

**Example: Adding a new Cubit**
```bash
# Find other cubits
find lib/ -name "*_cubit.dart"

# Read trip_cubit.dart - Good example with:
# - Activity logging
# - Error handling
# - Stream management
```

## Common Investigation Patterns

### Pattern 1: Understanding a Bug

**Goal**: Fix a bug in expense editing

**Steps**:
1. Read the bug report/issue
2. Find the entry point (expense_form_page.dart)
3. Trace user action to cubit method (updateExpense)
4. Read cubit implementation
5. Check repository implementation
6. Look for related state handling
7. Check for missing error handling

### Pattern 2: Adding a Feature

**Goal**: Add a new field to expenses

**Steps**:
1. Read existing expense model
2. Check where expense is created/updated
3. Find all UI that displays expenses
4. Read similar feature implementations
5. Identify all files that need modification
6. Check for activity logging requirements
7. Look for l10n string patterns

### Pattern 3: Understanding Integration

**Goal**: Understand how activity logging integrates

**Steps**:
1. Read ActivityLog model
2. Read ActivityLogRepository interface
3. Find all cubits using ActivityLogRepository
4. See how actorName is obtained
5. Check UI that displays activity logs
6. Understand the full data flow

## Key File Locations Reference

### Feature Structure
```
lib/features/{feature}/
├── domain/
│   ├── models/          # Data structures
│   ├── repositories/    # Interfaces
│   └── utils/           # Business logic helpers
├── data/
│   ├── models/          # Serialization models
│   ├── repositories/    # Implementations
│   └── datasources/     # External data access
└── presentation/
    ├── pages/           # Full-screen views
    ├── widgets/         # Reusable UI components
    └── cubits/          # State management
```

### Core/Shared Files
```
lib/core/
├── models/              # Shared models (CurrencyCode, Participant)
├── services/            # Core services (ActivityLogger, LocalStorage)
└── l10n/                # Localization utilities

lib/shared/
├── widgets/             # Shared UI components (CurrencyTextField)
└── utils/               # Shared utilities (CurrencyInputFormatter)
```

## Tools for Finding Context

### Grep for Usage
```bash
# Find all files that import something
grep -r "import.*expense_cubit" lib/

# Find all usages of a class
grep -r "ExpenseCubit()" lib/

# Find all usages of a method
grep -r "createExpense" lib/
```

### Glob for Patterns
```bash
# Find all page files
**/*_page.dart

# Find all cubit files
**/*_cubit.dart

# Find all test files
test/**/*_test.dart
```

### Find Related Tests
```bash
# For every source file, look for test
# Source: lib/features/trips/presentation/cubits/trip_cubit.dart
# Test:   test/features/trips/presentation/cubits/trip_cubit_test.dart
```

## Best Practices

**✅ DO:**
- Start with domain models to understand data structures
- Read repository interfaces before implementations
- Trace data flow from UI → Cubit → Repository
- Look for similar existing implementations
- Check for common patterns (activity logging, l10n, mobile-first)
- Read tests to understand expected behavior
- Take notes on dependencies and relationships

**❌ DON'T:**
- Don't read files in isolation
- Don't skip understanding the domain models
- Don't assume patterns without checking
- Don't modify without understanding the full context
- Don't forget to check for tests
- Don't ignore common patterns used elsewhere

## Investigation Checklist

When investigating a feature, verify you've read:

- [ ] Domain model(s) - What data structure?
- [ ] Domain repository interface - What operations?
- [ ] Cubit(s) - What business logic?
- [ ] Main page/widget - How is UI structured?
- [ ] Data repository implementation - How is data persisted?
- [ ] Related widgets - What reusable components?
- [ ] Tests - What's the expected behavior?
- [ ] Similar features - What patterns are used?
- [ ] Documentation - Any CLAUDE.md or README references?

## Example: Tracing Expense Creation

Let's trace how expense creation works:

### 1. Domain Model
```dart
// lib/features/expenses/domain/models/expense.dart
class Expense {
  final String id;
  final Decimal amount;
  final CurrencyCode currency;
  final String description;
  // ... other fields
}
```

**Insight**: Expenses have amount (Decimal), currency (enum), and description

### 2. Repository Interface
```dart
// lib/features/expenses/domain/repositories/expense_repository.dart
abstract class ExpenseRepository {
  Future<Expense> createExpense(Expense expense);
  // ... other methods
}
```

**Insight**: createExpense returns Future<Expense>, likely with generated ID

### 3. Cubit Logic
```dart
// lib/features/expenses/presentation/cubits/expense_cubit.dart
Future<void> createExpense(Expense expense, {String? actorName}) async {
  emit(ExpenseLoadingState());
  try {
    final created = await _expenseRepository.createExpense(expense);
    await _activityLogRepository?.addLog(...); // Activity logging
    emit(ExpenseCreatedState(created));
  } catch (e) {
    emit(ExpenseErrorState(e.toString()));
  }
}
```

**Insight**: Emits loading → created/error states, logs activity

### 4. UI Layer
```dart
// lib/features/expenses/presentation/pages/expense_form_page.dart
CurrencyTextField(                           // ← Currency input pattern
  controller: _amountController,
  currencyCode: _selectedCurrency,
  label: context.l10n.expenseFieldAmountLabel, // ← L10n pattern
)

ElevatedButton(
  onPressed: () {
    final actorName = context.read<TripCubit>()
        .getCurrentUserForTrip(tripId)?.name; // ← Actor from current user
    context.read<ExpenseCubit>().createExpense(
      expense,
      actorName: actorName,
    );
  },
)
```

**Insight**: Uses CurrencyTextField, l10n strings, gets actor from TripCubit

### 5. Data Implementation
```dart
// lib/features/expenses/data/repositories/expense_repository_impl.dart
Future<Expense> createExpense(Expense expense) async {
  final doc = await _firestore
      .collection('trips/${expense.tripId}/expenses')
      .add(ExpenseModel.fromDomain(expense).toJson());
  return expense.copyWith(id: doc.id);
}
```

**Insight**: Stored in Firestore under trip subcollection, ID auto-generated

## Additional Resources

For more information, see:
- Root CLAUDE.md → Project Structure section
- Root CLAUDE.md → Architecture & Conventions section
- Existing feature implementations for patterns
- Test files for expected behavior
