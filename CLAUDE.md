# CLAUDE.md - Expense Tracker Quick Reference

This is the main entry point for understanding and working with the expense tracker codebase. Detailed information is organized into specialized documents.

## 📚 Documentation Structure

This project uses a **multi-document system** for better navigation:

- **[PROJECT_KNOWLEDGE.md](PROJECT_KNOWLEDGE.md)** - Architecture, design patterns, data flow
- **[MOBILE.md](MOBILE.md)** - Mobile-first design guidelines and patterns
- **[DEVELOPMENT.md](DEVELOPMENT.md)** - Development workflows and systems
- **[TROUBLESHOOTING.md](TROUBLESHOOTING.md)** - Common issues and solutions
- **`.claude/skills/`** - Reusable workflow skills (see below)
- **This file (CLAUDE.md)** - Quick reference hub

## 🎯 Quick Start

### Essential Commands

```bash
# Development
flutter run -d chrome                          # Run app
flutter run -d chrome --web-browser-flag "--window-size=375,667"  # Mobile viewport
flutter test                                    # Run tests
flutter analyze                                 # Lint code
flutter format .                                # Format code

# Testing
flutter test test/path/to/test.dart            # Run specific test
flutter test --coverage                         # Run with coverage
dart run build_runner build --delete-conflicting-outputs  # Generate mocks

# Build
flutter build web                               # Production build
flutter build web --base-href /expense_tracker/ # GitHub Pages build
```

### Before Every Commit

```bash
flutter analyze && flutter format . && flutter test
```

## 🛠️ Claude Code Skills System

This project includes **6 reusable workflow skills** in `.claude/skills/` that guide you through common tasks:

| Skill | Purpose | Use When |
|-------|---------|----------|
| **mobile-first-design.md** | Mobile-first UI implementation | Creating/refactoring UI components |
| **activity-logging.md** | Add activity logging to features | Adding state-changing operations |
| **localization-workflow.md** | Add localized strings | Adding user-facing text |
| **cubit-testing.md** | Write BLoC/Cubit tests | Testing state management |
| **currency-input.md** | Implement currency fields | Adding monetary input fields |
| **read-with-context.md** | Understand code in context | Investigating features or bugs |

**How to use skills**: These provide step-by-step workflows. Reference them when working on related tasks.

## 📋 Development Workflow Instructions

**CRITICAL**: Claude Code must follow the documentation workflow during development.

### Workflow Commands

- **`/docs.create`** - Create feature documentation (CLAUDE.md + CHANGELOG.md)
- **`/docs.log "description"`** - Log changes (use frequently!)
- **`/docs.update`** - Update feature architecture docs
- **`/docs.complete`** - Mark feature complete and roll up to root

### When to Document

**Use `/docs.log` after:**
- Completing significant todo items
- Creating new files
- Fixing bugs
- Architectural changes

**Use `/docs.update` after:**
- Adding models, repositories, cubits
- Adding routes or dependencies
- Changing design patterns
- Modifying core data structures

**Use `/docs.complete` when:**
- Feature is fully implemented and tested
- Ready to merge to main branch

## 🏗️ Project Architecture

### Clean Architecture Layers

```
Presentation Layer (UI)
├── Pages - Full-screen views
├── Widgets - Reusable UI components
└── Cubits - State management

Domain Layer (Business Logic)
├── Models - Domain entities
├── Repositories - Abstract interfaces
└── Utils - Business logic helpers

Data Layer (Implementation)
├── Repositories - Concrete implementations
├── Models - Serialization models
└── Data Sources - External API/database access
```

**For detailed architecture**: See [PROJECT_KNOWLEDGE.md](PROJECT_KNOWLEDGE.md)

## 📱 Mobile-First Philosophy

**⚠️ CRITICAL**: This is a mobile-first application. Design for 375x667px (iPhone SE) FIRST.

### Core Principles

1. Mobile is the primary target
2. Touch targets minimum 44x44px
3. Vertical scrolling preferred
4. Forms MUST use `SingleChildScrollView`
5. Use `MediaQuery` for responsive spacing

### Quick Mobile Checklist

- [ ] Tested on 375x667px viewport
- [ ] All text fields visible when keyboard appears
- [ ] No horizontal scrolling
- [ ] Touch targets minimum 44x44px
- [ ] Forms use `SingleChildScrollView`
- [ ] Responsive spacing with `isMobile` checks

**For complete mobile guidelines**: See [MOBILE.md](MOBILE.md)

## 🌍 Localization System

**ALWAYS use localized strings** - never hardcode user-facing text.

```dart
// Import extension
import 'package:expense_tracker/core/l10n/l10n_extensions.dart';

// Use in code
Text(context.l10n.commonCancel)                 // Simple
Text(context.l10n.expensePaidBy(payerName))     // With parameter
Text(context.l10n.expenseParticipantCount(count)) // With pluralization
```

**Adding new strings**: Edit `lib/l10n/app_en.arb`, then run `flutter pub get`

**For detailed workflow**: See [DEVELOPMENT.md#localization-system](DEVELOPMENT.md#localization-system) or `.claude/skills/localization-workflow.md`

## 💰 Currency Input System

**ALWAYS use `CurrencyTextField`** for monetary amounts - never plain `TextField`.

```dart
// Basic usage
CurrencyTextField(
  controller: _amountController,
  currencyCode: CurrencyCode.usd,
  label: context.l10n.expenseFieldAmountLabel,
)

// Pre-filling when editing
_amountController = TextEditingController(
  text: expense != null
      ? formatAmountForInput(expense.amount, expense.currency)
      : '',
);

// Parsing when saving
final cleanValue = stripCurrencyFormatting(_amountController.text);
final amount = Decimal.parse(cleanValue);
```

**For detailed workflow**: See [DEVELOPMENT.md#currency-input-system](DEVELOPMENT.md#currency-input-system) or `.claude/skills/currency-input.md`

## 📝 Activity Tracking System

**Every state-changing operation MUST include activity logging.**

```dart
// 1. Inject repository (optional)
class MyCubit extends Cubit<MyState> {
  final ActivityLogRepository? _activityLogRepository;

  MyCubit({ActivityLogRepository? activityLogRepository})
      : _activityLogRepository = activityLogRepository,
        super(MyInitialState());
}

// 2. Get current user in UI
final currentUser = context.read<TripCubit>().getCurrentUserForTrip(tripId);
context.read<MyCubit>().myAction(..., actorName: currentUser?.name);

// 3. Log after successful operation (non-fatal)
if (_activityLogRepository != null && actorName != null) {
  try {
    await _activityLogRepository.addLog(ActivityLog(...));
  } catch (e) {
    // Don't fail main operation
  }
}
```

**For detailed workflow**: See [DEVELOPMENT.md#activity-tracking-system](DEVELOPMENT.md#activity-tracking-system) or `.claude/skills/activity-logging.md`

## 🧪 Testing Strategy

### Cubit Tests (Unit Tests)

```dart
test('should emit success state', () async {
  // Arrange
  when(mockRepository.createExpense(any)).thenAnswer((_) async => expense);

  // Act
  await cubit.createExpense(expense);

  // Assert
  expect(cubit.state, isA<ExpenseCreatedState>());
});
```

**For detailed workflow**: See `.claude/skills/cubit-testing.md`

### Generating Mocks

After adding/modifying `@GenerateMocks` annotations:

```bash
dart run build_runner build --delete-conflicting-outputs
```

## 📦 Spec-Driven Development

This project uses **GitHub Spec-Kit** for structured feature development.

### Spec-Kit Commands

- `/speckit.specify` - Create/update feature specification
- `/speckit.plan` - Generate implementation plan
- `/speckit.tasks` - Generate task breakdown
- `/speckit.implement` - Execute implementation

### Feature Structure

```
specs/{feature-id}-{feature-name}/
├── spec.md           # Feature specification
├── plan.md           # Implementation plan
├── tasks.md          # Task breakdown
├── CLAUDE.md         # Feature architecture
└── CHANGELOG.md      # Development log
```

**For complete workflow**: See [DEVELOPMENT.md#spec-driven-development](DEVELOPMENT.md#spec-driven-development)

## 🚀 Deployment

### GitHub Pages Auto-Deploy

Automatically deploys to GitHub Pages on push to `master`:

- Workflow: `.github/workflows/deploy.yml`
- Base URL: `https://{username}.github.io/expense_tracker/`

### Version Management

```bash
# Automated (on push to master)
# - Patch version bumps automatically

# Manual (GitHub Actions)
# - Navigate to Actions → Manual Version Bump → Run workflow
# - Select major/minor/patch
```

## 🔧 Common Tasks

### Adding a Localized String

1. Edit `lib/l10n/app_en.arb`
2. Run `flutter pub get`
3. Use `context.l10n.stringKey` in code

**Detail**: See `.claude/skills/localization-workflow.md`

### Adding a Currency Input Field

1. Import `CurrencyTextField`
2. Use `CurrencyTextField` widget
3. Parse with `stripCurrencyFormatting()` before saving

**Detail**: See `.claude/skills/currency-input.md`

### Adding Activity Logging

1. Inject `ActivityLogRepository?` in cubit
2. Get `actorName` from `TripCubit.getCurrentUserForTrip()`
3. Log after successful operation (in try-catch)

**Detail**: See `.claude/skills/activity-logging.md`

### Creating Mobile-First UI

1. Use `SingleChildScrollView` for forms
2. Use `MediaQuery` for responsive spacing
3. Test on 375x667px viewport

**Detail**: See [MOBILE.md](MOBILE.md) or `.claude/skills/mobile-first-design.md`

### Writing Cubit Tests

1. Add `@GenerateMocks` annotations
2. Create mocks with `build_runner`
3. Follow Arrange-Act-Assert pattern

**Detail**: See `.claude/skills/cubit-testing.md`

## 🆘 Troubleshooting

Common issues and solutions:

- **Keyboard hides form fields** → Use `SingleChildScrollView`
- **Cubit not emitting states** → Create new objects, don't modify existing
- **Activity logging not working** → Check actorName is provided
- **Localization strings not found** → Run `flutter pub get`
- **Currency formatting not working** → Use `CurrencyTextField`
- **Test mocks not found** → Run `dart run build_runner build`

**For complete troubleshooting guide**: See [TROUBLESHOOTING.md](TROUBLESHOOTING.md)

## 🗂️ Key File Locations

```
lib/
├── main.dart                     # App entry point
├── core/                         # Shared core functionality
│   ├── models/                   # Shared models
│   ├── services/                 # Core services
│   └── l10n/                     # Localization utilities
├── shared/                       # Shared UI components
│   ├── widgets/                  # CurrencyTextField, etc.
│   └── utils/                    # CurrencyInputFormatter, etc.
├── features/                     # Feature modules
│   ├── trips/                    # Trip management
│   ├── expenses/                 # Expense tracking
│   └── settlements/              # Settlement calculations
└── l10n/                         # Localization files (ARB)

.claude/
├── skills/                       # Reusable workflow skills
├── commands/                     # Custom slash commands
└── memory/                       # Session memory

specs/                            # Feature specifications (Spec-Kit)
```

## 📖 Documentation Index

| Document | Purpose | When to Read |
|----------|---------|--------------|
| **This file (CLAUDE.md)** | Quick reference hub | Start here |
| **[PROJECT_KNOWLEDGE.md](PROJECT_KNOWLEDGE.md)** | Architecture, patterns, data flow | Understanding codebase structure |
| **[MOBILE.md](MOBILE.md)** | Mobile-first design guidelines | Creating/refactoring UI |
| **[DEVELOPMENT.md](DEVELOPMENT.md)** | Development workflows | Using localization, currency, activity logging |
| **[TROUBLESHOOTING.md](TROUBLESHOOTING.md)** | Common issues and solutions | Debugging problems |
| **`.claude/skills/`** | Step-by-step workflows | Detailed task guidance |

## 💡 Tips for Working with This Codebase

1. **Always mobile-first** - Design for 375x667px first
2. **Use the skills** - Reference `.claude/skills/` for workflows
3. **Document frequently** - Use `/docs.log` often
4. **Never hardcode strings** - Always use `context.l10n.*`
5. **Always use CurrencyTextField** - For all monetary amounts
6. **Always add activity logging** - For state-changing operations
7. **Test on mobile** - Before considering feature complete
8. **Follow clean architecture** - Respect layer boundaries
9. **Read with context** - Use `.claude/skills/read-with-context.md`
10. **Check troubleshooting first** - Before investigating bugs

## 🤝 Contributing

When adding new features:

1. Create feature branch: `{id}-{feature-name}`
2. Use `/speckit.specify` to create spec
3. Use `/docs.create` to initialize feature docs
4. Use `/docs.log` frequently during development
5. Use `/docs.complete` when feature is done

**For complete workflow**: See [DEVELOPMENT.md#adding-a-new-feature](DEVELOPMENT.md#adding-a-new-feature)

---

**Last Updated**: 2025-01-30
**Documentation Structure**: Multi-document system (Reddit post recommendations)
