# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 🤖 IMPORTANT: Claude Code Workflow Instructions

**READ THIS FIRST BEFORE EVERY SESSION:**

Claude Code must follow the documentation workflow defined in `.claude-workflow-checklist.md`.

**REQUIRED ACTIONS during development:**

1. **After completing each significant todo item** → Use `/docs.log "description"`
2. **When creating new files** → Use `/docs.log "added [filename] for [purpose]"`
3. **When fixing bugs** → Use `/docs.log "fixed [issue]"`
4. **After architectural changes** → Use `/docs.update` (see checklist for criteria)
5. **Before marking feature complete** → Use `/docs.update` then `/docs.complete`

**Architectural changes include:** Adding models, repositories, cubits, routes, dependencies, design patterns, or modifying core data structures.

**DO NOT wait for the user to remind you about documentation!** This is YOUR responsibility as the AI assistant.

**Check `.claude-workflow-checklist.md` regularly** to ensure you're following best practices.

---

## Project Overview

This is a Flutter web application for tracking group expenses on trips with multi-currency support and settlement calculations. The project uses spec-driven development via GitHub Spec-Kit.

**Technology Stack**:
- Flutter SDK 3.9.0+ (web platform)
- Dart programming language
- GitHub Actions for CI/CD
- GitHub Pages for deployment

## Development Commands

### Essential Commands

```bash
# Install dependencies
flutter pub get

# Run the application (web)
flutter run -d chrome

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
```

## Architecture & Conventions

### Project Structure

- `lib/main.dart` - Application entry point
- `lib/l10n/` - Localization files (ARB format)
- `lib/core/l10n/` - Localization utilities and extensions
- `test/` - Test files (currently minimal)
- `web/` - Web-specific files (index.html, icons, manifest)
- `specs/` - Feature specifications managed by Spec-Kit
- `.specify/` - Spec-Kit configuration and templates

### Localization & String Management

The app uses **Flutter's built-in localization system** (`flutter_localizations` + `intl`) for all user-facing strings.

**Key Files**:
- `lib/l10n/app_en.arb` - English strings (250+ entries)
- `l10n.yaml` - Localization configuration
- `lib/core/l10n/l10n_extensions.dart` - Helper extension for easy access
- Generated files: `.dart_tool/flutter_gen/gen_l10n/app_localizations.dart` (auto-generated)

**Configuration** (`pubspec.yaml`):
```yaml
dependencies:
  flutter_localizations:
    sdk: flutter
  intl: ^0.20.2

flutter:
  generate: true  # Enables automatic l10n generation
```

#### How to Use Localization

**1. Accessing strings in widgets:**

```dart
import 'package:expense_tracker/core/l10n/l10n_extensions.dart';

// In any widget with BuildContext:
Text(context.l10n.commonCancel)  // Simple string
Text(context.l10n.expensePaidBy(payerName))  // With parameter
Text(context.l10n.expenseParticipantCount(count))  // With pluralization
```

**2. Adding new strings:**

Edit `lib/l10n/app_en.arb` and add your string:

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
  },
  "myPluralString": "{count, plural, =1{1 item} other{{count} items}}",
  "@myPluralString": {
    "placeholders": {
      "count": {
        "type": "int"
      }
    }
  }
}
```

**3. Regenerating localization files:**

Files are automatically regenerated when you:
- Run `flutter pub get`
- Build the app (`flutter build web`)
- Run the app (`flutter run`)

Or manually: `flutter gen-l10n`

#### String Naming Conventions

Strings in `app_en.arb` follow these conventions:

- **Common UI**: `commonCancel`, `commonSave`, `commonDelete`
- **Validation**: `validationRequired`, `validationInvalidNumber`
- **Feature-specific**: `{feature}{Component}{Property}`
  - `tripCreateTitle` - Trip feature, Create page, title
  - `expenseFieldAmountLabel` - Expense feature, field label
  - `settlementLoadError` - Settlement feature, error message
- **Dialogs**: `{feature}{Action}DialogTitle`, `{feature}{Action}DialogMessage`
- **Buttons**: `{feature}{Action}Button`
- **Errors**: `{feature}{Action}Error`

#### String Categories in ARB File

1. **Common UI** - Buttons, actions used across features
2. **Validation** - Form validation messages
3. **Trips** - Trip management strings
4. **Participants** - Participant management strings
5. **Expenses** - Expense management strings
6. **Itemized Expenses** - Wizard-specific strings
7. **Expense Card** - Detail display strings
8. **Settlements** - Transfer and settlement strings
9. **Date/Time** - Relative date formatting
10. **Currency** - Currency display names
11. **Categories** - Expense category names

#### Best Practices

**DO**:
- ✅ Always use `context.l10n.stringKey` for user-facing text
- ✅ Use parameters for dynamic content: `context.l10n.expensePaidBy(name)`
- ✅ Use pluralization for counts: `context.l10n.expenseParticipantCount(count)`
- ✅ Group related strings with common prefixes
- ✅ Add `@stringKey` metadata for parameters and placeholders

**DON'T**:
- ❌ Never hardcode user-facing strings in widgets
- ❌ Don't use string concatenation for translated text
- ❌ Don't create one-off strings - reuse common strings when possible
- ❌ Don't add comment keys to ARB (e.g., `"_COMMENT_": "..."`) - they break generation

#### Adding New Languages

To add a new language (e.g., Vietnamese):

1. Create `lib/l10n/app_vi.arb` with translated strings
2. Update `main.dart`:
   ```dart
   supportedLocales: const [
     Locale('en'), // English
     Locale('vi'), // Vietnamese
   ],
   ```
3. Run `flutter pub get` to regenerate localization files

The system will automatically use the user's device locale.

### Activity Tracking & Audit Trail

The app includes a **comprehensive activity tracking system** that logs all user actions for transparency and audit purposes. Every state-changing operation must include activity logging.

**Key Files**:
- `lib/features/trips/domain/models/activity_log.dart` - ActivityType enum and ActivityLog model
- `lib/features/trips/domain/repositories/activity_log_repository.dart` - Repository interface
- `lib/features/trips/presentation/pages/trip_activity_page.dart` - Activity log UI
- `lib/features/trips/presentation/widgets/activity_log_item.dart` - Activity log item widget

#### Activity Types

The `ActivityType` enum defines all trackable actions:

**Trip Management**: `tripCreated`, `tripUpdated`, `tripDeleted`
**Participants**: `memberJoined`, `participantAdded`, `participantRemoved`
**Expenses**: `expenseAdded`, `expenseEdited`, `expenseDeleted`, `expenseCategoryChanged`, `expenseSplitModified`
**Settlements**: `transferMarkedSettled`, `transferMarkedUnsettled`
**Security**: `deviceVerified`, `recoveryCodeUsed`

#### How to Add Activity Logging to New Features

**1. Inject ActivityLogRepository in your Cubit:**

```dart
class MyCubit extends Cubit<MyState> {
  final MyRepository _myRepository;
  final ActivityLogRepository? _activityLogRepository; // Make optional

  MyCubit({
    required MyRepository myRepository,
    ActivityLogRepository? activityLogRepository, // Optional
  }) : _myRepository = myRepository,
       _activityLogRepository = activityLogRepository,
       super(MyInitialState());
}
```

**2. Get the current user for actor attribution:**

```dart
// In your UI code (page/widget):
final currentUser = context.read<TripCubit>().getCurrentUserForTrip(tripId);
final actorName = currentUser?.name;

// Pass actorName to cubit methods:
context.read<MyCubit>().myAction(..., actorName: actorName);
```

**3. Log the activity after successful operations:**

```dart
Future<void> myAction(..., {String? actorName}) async {
  try {
    // 1. Perform the main operation
    await _myRepository.doSomething(...);

    // 2. Log activity (non-fatal)
    if (_activityLogRepository != null && actorName != null && actorName.isNotEmpty) {
      _log('📝 Logging my_action activity...');
      try {
        final activityLog = ActivityLog(
          id: '', // Firestore auto-generates
          tripId: tripId,
          type: ActivityType.myNewActionType, // Add to enum if new
          actorName: actorName,
          description: 'Clear description of what happened',
          timestamp: DateTime.now(),
          metadata: {
            // Optional: store relevant details
            'entityId': entityId,
            'oldValue': oldValue,
            'newValue': newValue,
          },
        );
        await _activityLogRepository.addLog(activityLog);
        _log('✅ Activity logged');
      } catch (e) {
        _log('⚠️ Failed to log activity (non-fatal): $e');
        // Don't fail the main operation if logging fails
      }
    }

    // 3. Emit success state
    emit(MySuccessState());
  } catch (e) {
    emit(MyErrorState(e.toString()));
  }
}
```

#### Identity Management

**How Users Are Identified:**
- When users join a trip, they select their identity from the participant list
- This identity is stored per-trip in `LocalStorageService` using `saveUserIdentityForTrip()`
- Retrieved via `TripCubit.getCurrentUserForTrip(tripId)` for activity logging

**Current User Pattern:**

```dart
// In your UI layer (page/widget with BuildContext):
final currentUser = context.read<TripCubit>().getCurrentUserForTrip(tripId);

if (currentUser == null) {
  // User hasn't joined this trip or hasn't selected identity
  // Show error or prompt to join trip
  return;
}

// Use currentUser.name for activity logging
final actorName = currentUser.name;
```

#### Adding New Activity Types

**1. Add to ActivityType enum** (`lib/features/trips/domain/models/activity_log.dart`):

```dart
enum ActivityType {
  // ... existing types ...

  /// My new action was performed
  myNewAction,
}
```

**2. Update serialization** (`lib/features/trips/data/models/activity_log_model.dart`):

```dart
// In _activityTypeToString():
case ActivityType.myNewAction:
  return 'myNewAction';

// In _activityTypeFromString():
case 'myNewAction':
  return ActivityType.myNewAction;
```

**3. Update UI** (`lib/features/trips/presentation/widgets/activity_log_item.dart`):

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

**4. Run code generation** to regenerate mock files for tests:

```bash
dart run build_runner build --delete-conflicting-outputs
```

#### Best Practices

**DO**:
- ✅ Always inject `ActivityLogRepository` in cubits that perform state changes
- ✅ Always get `actorName` from `TripCubit.getCurrentUserForTrip()` (not from payer, creator, etc.)
- ✅ Log AFTER successful operation (so failed operations aren't logged)
- ✅ Wrap logging in try-catch (logging failures should never break main operations)
- ✅ Use clear, descriptive text in `description` field
- ✅ Store relevant details in `metadata` for richer logs (optional but recommended)

**DON'T**:
- ❌ Don't use payer/creator/participant names as actor - always use current user
- ❌ Don't fail operations if activity logging fails (it's optional, non-fatal)
- ❌ Don't log before the operation succeeds (only log successful actions)
- ❌ Don't require `ActivityLogRepository` (make it optional for testing)
- ❌ Don't forget to add new ActivityTypes to serialization methods

#### Testing Activity Logging

When writing tests for cubits with activity logging:

```dart
// Mock the repository as optional
final mockActivityLogRepo = MockActivityLogRepository();

// Create cubit with mock
final cubit = MyCubit(
  myRepository: mockRepository,
  activityLogRepository: mockActivityLogRepo, // Optional
);

// Verify activity was logged
verify(mockActivityLogRepo.addLog(any)).called(1);

// OR test without activity logging
final cubitWithoutLogging = MyCubit(
  myRepository: mockRepository,
  // activityLogRepository: null (omit),
);
```

### Spec-Driven Development Workflow

This project uses **GitHub Spec-Kit** for specification-driven development. Features are developed in branches following this pattern:

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

**Key Files per Feature**:
- `spec.md` - Detailed feature specification with user stories, requirements, and success criteria
- `plan.md` - Implementation design (generated)
- `tasks.md` - Dependency-ordered task list (generated)
- `checklists/` - Custom checklists (generated)

### Current Feature

**Branch**: `001-group-expense-tracker`

**Scope**: Multi-currency group expense tracker with:
- Trip management with base currency (USD/VND)
- Expense recording with split types (equal/weighted)
- Multi-currency support with exchange rates
- Settlement calculations with pairwise netting
- Minimal transfer algorithm
- Per-person dashboards with category breakdown
- Fixed participant list (Tai, Khiet, Bob, Ethan, Ryan, Izzy)

See `specs/001-group-expense-tracker/spec.md` for complete requirements.

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

### Claude Code Action

The repository includes Claude Code GitHub Action that responds to:
- Issue comments
- Pull request comments
- New issues
- Pull request updates

Requires `ANTHROPIC_API_KEY` secret in repository settings.

## Code Quality

### Linting

Uses `flutter_lints` package (v5.0.0) with default recommended lints defined in `analysis_options.yaml`.

### Formatting

- Indentation: 2 spaces (Dart standard)
- Line length: Default 80 characters
- Always run `flutter format .` before committing

## Working with This Codebase

### Adding a New Feature

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

**Documentation Best Practice**: Use `/docs.log` after every significant change to keep a detailed development history. This makes it easy to generate release notes and understand feature evolution.

### Documentation Workflow

**⚠️ CRITICAL: Claude Code must proactively use these commands during development!**

See `.claude-workflow-checklist.md` for the complete workflow checklist.

Each feature maintains TWO documentation files:
- **CLAUDE.md** (`specs/{feature-id}/CLAUDE.md`): Architecture, design decisions, and implementation guide
- **CHANGELOG.md** (`specs/{feature-id}/CHANGELOG.md`): Day-to-day development log

#### Available Slash Commands

- `/docs.create` - Create initial feature CLAUDE.md and CHANGELOG.md from templates
- `/docs.log` - Add entry to feature CHANGELOG.md (use frequently!)
- `/docs.update` - Update feature CLAUDE.md with recent changes (manual)
- `/docs.complete` - Mark feature complete and roll up to root CHANGELOG.md

#### Manual Script Usage

```bash
# Create feature documentation (both CLAUDE.md and CHANGELOG.md)
.specify/scripts/bash/update-feature-docs.sh create {feature-id}

# Log a development change (use frequently during development)
.specify/scripts/bash/update-feature-docs.sh log {feature-id} "Description of what changed"

# Mark feature as complete (rolls up to root CHANGELOG.md)
.specify/scripts/bash/update-feature-docs.sh complete {feature-id}
```

#### When to Update Documentation

**Feature CLAUDE.md** (update occasionally):
- After implementing major architectural decisions
- When adding new dependencies
- When creating significant new components
- After settling on state management patterns
- Document known limitations and trade-offs

**Feature CHANGELOG.md** (update frequently with `/docs.log`):
- After each significant change or milestone
- When adding new files or components
- When fixing bugs
- When changing existing functionality
- At the end of each work session

**Example workflow**:
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

#### What Each File Contains

**Feature CLAUDE.md** (`specs/{feature-id}/CLAUDE.md`):
- Quick reference commands specific to the feature
- Files created/modified by the feature
- Architecture decisions and design patterns
- Dependencies added
- Testing strategy
- Migration notes and breaking changes

**Feature CHANGELOG.md** (`specs/{feature-id}/CHANGELOG.md`):
- Chronological development log with dates
- Specific changes, additions, fixes
- Preserved as historical reference after feature completion
- Follows [Keep a Changelog](https://keepachangelog.com/) format

**Root CHANGELOG.md**:
- High-level feature completion summary
- Automatically updated when feature is marked complete
- Links to feature-specific docs for details
- Release history for the entire project

### Before Committing

```bash
flutter analyze
flutter format .
flutter test
```

### Creating Pull Requests

- Target branch: `master` (no main branch configured)
- Include reference to feature spec in description
- Ensure GitHub Actions pass (deploy workflow)

## Important Notes

- This is a **web-only** Flutter application (no mobile platform support currently)
- The app targets GitHub Pages deployment with specific base-href configuration
- Uses Dart SDK 3.9.0+ which requires Flutter 3.19.0+
- Fixed participant list for MVP (no dynamic user management)
- Multi-currency limited to USD and VND for MVP
- No backend authentication or database (storage mechanism TBD in implementation plan)
