# Development Workflows

This document covers the key development systems and workflows used in the expense tracker project.

## Table of Contents
- [Development Commands](#development-commands)
- [Localization System](#localization-system)
- [Currency Input System](#currency-input-system)
- [Activity Tracking System](#activity-tracking-system)
- [Spec-Driven Development](#spec-driven-development)
- [Documentation Workflow](#documentation-workflow)
- [Version Management](#version-management)
- [Code Quality](#code-quality)

## Development Commands

### Essential Commands

```bash
# Install dependencies
flutter pub get

# Run the application (web)
flutter run -d chrome

# Run with mobile viewport (375x667px)
flutter run -d chrome --web-browser-flag "--window-size=375,667"

# Run tests
flutter test

# Run specific test file
flutter test test/widget_test.dart

# Run analyzer/linter
flutter analyze

# Build for production (web)
flutter build web

# Build with custom base href (for GitHub Pages)
flutter build web --base-href /expense_tracker/
```

### Testing & Quality

```bash
# Run all tests with coverage
flutter test --coverage

# Format code
flutter format .

# Check formatting without making changes
flutter format --set-exit-if-changed .

# Generate mocks for testing
dart run build_runner build --delete-conflicting-outputs
```

## Localization System

The app uses **Flutter's built-in localization system** (`flutter_localizations` + `intl`) for all user-facing strings.

### Key Files
- `lib/l10n/app_en.arb` - English strings (250+ entries)
- `l10n.yaml` - Localization configuration
- `lib/core/l10n/l10n_extensions.dart` - Helper extension for easy access
- Generated files: `.dart_tool/flutter_gen/gen_l10n/app_localizations.dart` (auto-generated)

### Quick Reference

**1. Using strings in code:**

```dart
import 'package:expense_tracker/core/l10n/l10n_extensions.dart';

// In any widget with BuildContext:
Text(context.l10n.commonCancel)  // Simple string
Text(context.l10n.expensePaidBy(payerName))  // With parameter
Text(context.l10n.expenseParticipantCount(count))  // With pluralization
```

**2. Adding new strings:**

Edit `lib/l10n/app_en.arb`:

```json
{
  "myNewString": "Hello World",
  "myStringWithParam": "Hello {name}!",
  "@myStringWithParam": {
    "placeholders": {
      "name": {
        "type": "String"
      }
    }
  }
}
```

**3. Regenerating localization files:**

```bash
flutter pub get
# or
flutter gen-l10n
```

### String Naming Conventions

- **Common UI**: `commonCancel`, `commonSave`, `commonDelete`
- **Validation**: `validationRequired`, `validationInvalidNumber`
- **Feature-specific**: `{feature}{Component}{Property}`
  - `tripCreateTitle` - Trip feature, Create page, title
  - `expenseFieldAmountLabel` - Expense feature, field label
  - `settlementLoadError` - Settlement feature, error message
- **Dialogs**: `{feature}{Action}DialogTitle`, `{feature}{Action}DialogMessage`
- **Buttons**: `{feature}{Action}Button`
- **Errors**: `{feature}{Action}Error`

### Best Practices

**DO**:
- ✅ Always use `context.l10n.stringKey` for user-facing text
- ✅ Use parameters for dynamic content
- ✅ Use pluralization for counts
- ✅ Group related strings with common prefixes

**DON'T**:
- ❌ Never hardcode user-facing strings in widgets
- ❌ Don't use string concatenation for translated text
- ❌ Don't create one-off strings - reuse common strings
- ❌ Don't add comment keys to ARB (breaks generation)

**For detailed workflow, see**: `.claude/skills/localization-workflow.md`

## Currency Input System

The app uses a **unified currency input system** that automatically formats amounts with thousand separators and currency-specific decimal places.

### Key Files
- `lib/shared/widgets/currency_text_field.dart` - Reusable currency input widget
- `lib/shared/utils/currency_input_formatter.dart` - Currency-aware input formatter
- `lib/core/models/currency_code.dart` - Currency enum with metadata

### Quick Reference

**1. Basic usage:**

```dart
final _amountController = TextEditingController();

CurrencyTextField(
  controller: _amountController,
  currencyCode: CurrencyCode.usd,
  label: context.l10n.expenseFieldAmountLabel,
)
```

**2. Pre-filling when editing:**

```dart
_amountController = TextEditingController(
  text: expense != null
      ? formatAmountForInput(expense.amount, expense.currency)
      : '',
);
```

**3. Parsing user input:**

```dart
final cleanValue = stripCurrencyFormatting(_amountController.text);
final amount = Decimal.parse(cleanValue);
```

### Currency-Specific Behavior

**USD (2 decimal places)**:
- User enters: `1000.50` → Displays: `1,000.50`
- Maximum 2 decimals enforced

**VND (0 decimal places)**:
- User enters: `1000000` → Displays: `1,000,000`
- No decimal point allowed

### Best Practices

**DO**:
- ✅ Always use `CurrencyTextField` for monetary amounts
- ✅ Use `formatAmountForInput()` when pre-filling edit forms
- ✅ Use `stripCurrencyFormatting()` before parsing

**DON'T**:
- ❌ Never use plain `TextField` or `TextFormField` for currency amounts
- ❌ Don't hardcode decimal places - let the currency code determine it
- ❌ Don't parse `_controller.text` directly - use `stripCurrencyFormatting()` first

**For detailed workflow, see**: `.claude/skills/currency-input.md`

## Activity Tracking System

The app includes a **comprehensive activity tracking system** that logs all user actions for transparency and audit purposes.

### Key Files
- `lib/features/trips/domain/models/activity_log.dart` - ActivityType enum and ActivityLog model
- `lib/features/trips/domain/repositories/activity_log_repository.dart` - Repository interface
- `lib/features/expenses/domain/utils/expense_change_detector.dart` - Change detection utility
- `lib/features/trips/presentation/pages/trip_activity_page.dart` - Activity log UI

### Quick Reference

**1. Inject repository in cubit:**

```dart
class MyCubit extends Cubit<MyState> {
  final MyRepository _myRepository;
  final ActivityLogRepository? _activityLogRepository; // OPTIONAL

  MyCubit({
    required MyRepository myRepository,
    ActivityLogRepository? activityLogRepository,
  }) : _myRepository = myRepository,
       _activityLogRepository = activityLogRepository,
       super(MyInitialState());
}
```

**2. Get current user in UI:**

```dart
final currentUser = context.read<TripCubit>().getCurrentUserForTrip(tripId);
final actorName = currentUser?.name;

context.read<MyCubit>().myAction(..., actorName: actorName);
```

**3. Log activity after successful operation:**

```dart
Future<void> myAction(..., {String? actorName}) async {
  try {
    // 1. Perform main operation
    await _myRepository.doSomething(...);

    // 2. Log activity (non-fatal)
    if (_activityLogRepository != null && actorName != null) {
      try {
        await _activityLogRepository.addLog(
          ActivityLog(
            id: '',
            tripId: tripId,
            type: ActivityType.myAction,
            actorName: actorName,
            description: 'Clear description',
            timestamp: DateTime.now(),
            metadata: {'key': 'value'},
          ),
        );
      } catch (e) {
        // Don't fail main operation if logging fails
      }
    }

    // 3. Emit success state
    emit(MySuccessState());
  } catch (e) {
    emit(MyErrorState(e.toString()));
  }
}
```

### Available Activity Types

**Trip Management**: `tripCreated`, `tripUpdated`, `tripDeleted`
**Participants**: `memberJoined`, `participantAdded`, `participantRemoved`
**Expenses**: `expenseAdded`, `expenseEdited`, `expenseDeleted`
**Settlements**: `transferMarkedSettled`, `transferMarkedUnsettled`
**Security**: `deviceVerified`, `recoveryCodeUsed`

### Best Practices

**DO**:
- ✅ Always inject `ActivityLogRepository` as optional in cubits
- ✅ Always get `actorName` from `TripCubit.getCurrentUserForTrip()`
- ✅ Log AFTER successful operation
- ✅ Wrap logging in try-catch (non-fatal)

**DON'T**:
- ❌ Don't use payer/creator names as actor - use current user
- ❌ Don't fail operations if logging fails
- ❌ Don't log before the operation succeeds
- ❌ Don't require `ActivityLogRepository` (make it optional)

**For detailed workflow, see**: `.claude/skills/activity-logging.md`

## Spec-Driven Development

This project uses **GitHub Spec-Kit** for specification-driven development.

### Feature Development Pattern

1. **Feature Specification**: Each feature lives in `specs/{feature-id}-{feature-name}/spec.md`
2. **Branch Naming**: Feature branches use the format `{feature-id}-{feature-name}` (e.g., `001-group-expense-tracker`)
3. **Slash Commands**: Available Spec-Kit commands:
   - `/speckit.specify` - Create/update feature specification
   - `/speckit.plan` - Generate implementation plan
   - `/speckit.tasks` - Generate actionable task list
   - `/speckit.analyze` - Analyze spec consistency
   - `/speckit.clarify` - Ask clarification questions
   - `/speckit.implement` - Execute implementation
   - `/speckit.checklist` - Generate custom checklist

### Key Files per Feature
- `spec.md` - Detailed feature specification
- `plan.md` - Implementation design (generated)
- `tasks.md` - Dependency-ordered task list (generated)
- `checklists/` - Custom checklists (generated)

## Documentation Workflow

**⚠️ IMPORTANT**: Claude Code must proactively use these commands during development!

Each feature maintains TWO documentation files:
- **CLAUDE.md** (`specs/{feature-id}/CLAUDE.md`): Architecture, design decisions, implementation guide
- **CHANGELOG.md** (`specs/{feature-id}/CHANGELOG.md`): Day-to-day development log

### Available Slash Commands

- `/docs.create` - Create initial feature CLAUDE.md and CHANGELOG.md from templates
- `/docs.log` - Add entry to feature CHANGELOG.md (use frequently!)
- `/docs.update` - Update feature CLAUDE.md with recent changes (manual)
- `/docs.complete` - Mark feature complete and roll up to root CHANGELOG.md

### When to Update Documentation

**Feature CLAUDE.md** (update occasionally):
- After implementing major architectural decisions
- When adding new dependencies
- When creating significant new components
- After settling on state management patterns

**Feature CHANGELOG.md** (update frequently with `/docs.log`):
- After each significant change or milestone
- When adding new files or components
- When fixing bugs
- When changing existing functionality
- At the end of each work session

### Example Workflow

```bash
# Start feature
/docs.create

# During development - log changes frequently
/docs.log "Added expense form with validation"
/docs.log "Implemented settlement calculator with pairwise netting"
/docs.log "Fixed decimal precision in split calculations"

# Occasionally update architecture docs
/docs.update  # (manual edit of CLAUDE.md)

# When feature complete
/docs.complete
```

## Version Management

### Commands

```bash
# Bump patch version locally (1.0.0 -> 1.0.1)
.github/scripts/bump-version.sh

# Bump major/minor/patch version locally
.github/scripts/bump-major-minor.sh [major|minor|patch]

# Examples:
.github/scripts/bump-major-minor.sh major   # 1.0.0 -> 2.0.0
.github/scripts/bump-major-minor.sh minor   # 1.0.0 -> 1.1.0
.github/scripts/bump-major-minor.sh patch   # 1.0.0 -> 1.0.1
```

### Automated Version Bumping

- **Patch version**: Automatically bumps on every push to master via GitHub Actions
- **Major/Minor version**: Use GitHub Actions "Manual Version Bump" workflow
  - Navigate to Actions tab → Manual Version Bump → Run workflow
  - Select version type (major/minor/patch)
  - Workflow commits version change back to master

### Version Display

- Version is displayed at top left of the screen in super small text (8px)
- Format: `1.0.0+1` (semantic version + build number)
- Automatically reads from `pubspec.yaml` via `package_info_plus`
- Positioned to be visible on mobile web (not obscured by browser chrome)

## Code Quality

### Linting

Uses `flutter_lints` package (v5.0.0) with default recommended lints defined in `analysis_options.yaml`.

### Formatting

- Indentation: 2 spaces (Dart standard)
- Line length: Default 80 characters
- Always run `flutter format .` before committing

### Before Committing

```bash
flutter analyze
flutter format .
flutter test
```

## Adding a New Feature

1. Create feature branch: `{id}-{feature-name}`
2. Create spec directory: `specs/{id}-{feature-name}/`
3. Use `/speckit.specify` to create specification
4. **Create feature documentation**: Use `/docs.create` to create CLAUDE.md and CHANGELOG.md
5. Use `/speckit.plan` to generate implementation plan
6. Use `/speckit.tasks` to generate task breakdown
7. Use `/speckit.implement` to execute implementation
8. **During development**:
   - Use `/docs.log` frequently to track changes in feature CHANGELOG.md
   - Update feature CLAUDE.md occasionally with `/docs.update` for architectural changes
9. **Mark complete**: Use `/docs.complete` to finalize documentation and roll up to root CHANGELOG.md

## Testing Strategy

### Unit Tests (Cubits, Utils, Models)

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

**For detailed workflow, see**: `.claude/skills/cubit-testing.md`

### Widget Tests (Pages, Widgets)

```dart
testWidgets('should display expense list', (tester) async {
  await tester.pumpWidget(MaterialApp(
    home: BlocProvider.value(
      value: mockCubit,
      child: ExpenseListPage(),
    ),
  ));

  expect(find.byType(ExpenseCard), findsWidgets);
});
```

### Test Commands

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/features/trips/presentation/cubits/trip_cubit_test.dart

# Run with coverage
flutter test --coverage

# Run specific test by name
flutter test --name "should create trip"

# Generate mocks (after modifying @GenerateMocks)
dart run build_runner build --delete-conflicting-outputs
```

## Deployment

### GitHub Pages Auto-Deploy

The project automatically deploys to GitHub Pages on push to `master`:

```yaml
# .github/workflows/deploy.yml
- Triggers on: push to master, manual workflow_dispatch
- Builds Flutter web with base-href: /expense_tracker/
- Deploys to GitHub Pages
```

**Deployed URL**: https://{username}.github.io/expense_tracker/

## Common Development Tasks

### Adding a Localized String

1. Edit `lib/l10n/app_en.arb` and add string
2. Run `flutter pub get` to regenerate
3. Use `context.l10n.stringKey` in code

### Adding a Currency Input Field

1. Import `CurrencyTextField`
2. Create `TextEditingController`
3. Use `CurrencyTextField` widget
4. Parse with `stripCurrencyFormatting()` before saving

### Adding Activity Logging to a Cubit

1. Inject `ActivityLogRepository?` (optional)
2. Get `actorName` from `TripCubit.getCurrentUserForTrip()` in UI
3. Log after successful operation (in try-catch)

### Creating a Mobile-First Page

1. Wrap in `SingleChildScrollView` for forms
2. Use `MediaQuery` for responsive spacing
3. Adjust font sizes for mobile
4. Use smaller icons on mobile
5. Test on 375x667px viewport

## Additional Resources

- Root [CLAUDE.md](CLAUDE.md) - Quick reference hub
- [PROJECT_KNOWLEDGE.md](PROJECT_KNOWLEDGE.md) - Architecture overview
- [MOBILE.md](MOBILE.md) - Mobile-first design guidelines
- [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - Common issues and solutions
- `.claude/skills/` - Reusable workflow skills
- `.claude/commands/` - Custom slash commands
