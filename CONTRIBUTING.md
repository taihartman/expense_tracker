# Contributing Guidelines

Thank you for your interest in contributing to the Expense Tracker project! This document provides guidelines and workflows for contributors.

## Table of Contents

1. [Code of Conduct](#code-of-conduct)
2. [Getting Started](#getting-started)
3. [Development Workflow](#development-workflow)
4. [Coding Standards](#coding-standards)
5. [Documentation Requirements](#documentation-requirements)
6. [Testing Requirements](#testing-requirements)
7. [Pull Request Process](#pull-request-process)
8. [Review Process](#review-process)

---

## Code of Conduct

### Our Standards

- **Be respectful** - Treat all contributors with respect
- **Be constructive** - Provide helpful feedback and suggestions
- **Be collaborative** - Work together to improve the project
- **Be patient** - Remember that everyone is learning

### Unacceptable Behavior

- Harassment, discrimination, or offensive language
- Trolling, insulting comments, or personal attacks
- Publishing others' private information
- Any conduct that would be inappropriate in a professional setting

---

## Getting Started

### First Time Contributors

1. **Read the documentation**:
   - Start with [GETTING_STARTED.md](GETTING_STARTED.md)
   - Read [CLAUDE.md](CLAUDE.md) for quick reference
   - Browse [FEATURES.md](FEATURES.md) to understand what's built

2. **Set up your environment**:
   - Follow the setup instructions in GETTING_STARTED.md
   - Install git hooks: `./.githooks/install.sh`
   - Verify your setup with `flutter doctor`

3. **Find an issue to work on**:
   - Look for issues labeled `good first issue`
   - Check for issues labeled `help wanted`
   - Ask in the team chat if you need suggestions

### Before You Start

- **Check existing issues** - Someone may already be working on it
- **Create an issue** - If one doesn't exist for your proposed change
- **Discuss major changes** - Before investing significant time

---

## Development Workflow

### 1. Create a Feature Branch

```bash
# Pull latest changes
git checkout master
git pull origin master

# Create feature branch with ID
git checkout -b 012-feature-name
```

**Branch naming convention**:
- Features: `012-feature-name` (3-digit ID + descriptive name)
- Bugs: `fix/description-of-bug`
- Docs: `docs/description-of-change`
- Tests: `test/description-of-test`

### 2. Follow the Appropriate Workflow

#### For Small Changes (< 100 lines)

1. Make your changes
2. Test your changes
3. Update documentation if needed
4. Create PR

#### For New Features

Follow the **Spec-Kit workflow**:

1. `/speckit.specify` - Create feature specification
2. `/speckit.clarify` - Clarify underspecified areas
3. `/speckit.plan` - Generate implementation plan
4. `/speckit.tasks` - Generate task breakdown
5. `/speckit.analyze` - Validate consistency
6. `/speckit.checklist` - Generate quality checklist
7. `/speckit.implement` - Execute implementation

**Documentation workflow**:

1. `/docs.create` - Initialize feature documentation
2. `/docs.log "description"` - Log changes frequently (after each significant change)
3. `/docs.update` - Update feature architecture docs (when structure changes)
4. `/docs.complete` - Mark feature complete (when ready to merge)

### 3. Make Your Changes

**Key principles**:

- ✅ **Mobile-first** - Design for 375x667px first
- ✅ **Localize all strings** - Use `context.l10n.*`, never hardcode text
- ✅ **Add activity logging** - For all state-changing operations
- ✅ **Use CurrencyTextField** - For all monetary inputs
- ✅ **Follow clean architecture** - Respect layer boundaries
- ✅ **Document as you code** - Don't wait until the end

**Leverage skills**:

- [`.claude/skills/mobile-first-design.md`](.claude/skills/mobile-first-design.md) - Mobile UI guidelines
- [`.claude/skills/activity-logging.md`](.claude/skills/activity-logging.md) - Activity tracking
- [`.claude/skills/localization-workflow.md`](.claude/skills/localization-workflow.md) - Localization
- [`.claude/skills/currency-input.md`](.claude/skills/currency-input.md) - Currency fields
- [`.claude/skills/cubit-testing.md`](.claude/skills/cubit-testing.md) - Testing cubits

### 4. Test Your Changes

**Before every commit**:

```bash
flutter analyze    # Check for code issues
flutter format .   # Format code
flutter test       # Run all tests
```

**Test checklist**:
- [ ] All new code has unit tests
- [ ] All existing tests pass
- [ ] Tested on 375x667px mobile viewport
- [ ] Keyboard doesn't hide form fields
- [ ] Loading states work correctly
- [ ] Error handling works correctly

### 5. Commit Your Changes

**Commit message format**:

```
type(scope): brief description

Detailed description if needed

- Bullet points for multiple changes
- Reference issues with #123
```

**Types**:
- `feat` - New feature
- `fix` - Bug fix
- `docs` - Documentation changes
- `test` - Test changes
- `refactor` - Code refactoring
- `style` - Code formatting
- `chore` - Maintenance tasks

**Examples**:

```
feat(expenses): add multi-currency support

- Added currency selection to expense form
- Updated settlement calculations for multiple currencies
- Added currency conversion utilities

Closes #123
```

```
fix(trips): prevent duplicate trip creation

Fixed race condition in trip creation that allowed duplicate trips
when the user clicked the button multiple times quickly.

Fixes #456
```

**The pre-commit hook will remind you to update documentation.**

---

## Coding Standards

### Dart/Flutter

**Follow the official style guides**:
- [Effective Dart](https://dart.dev/guides/language/effective-dart)
- [Flutter Style Guide](https://github.com/flutter/flutter/wiki/Style-guide-for-Flutter-repo)

**Project-specific standards**:

1. **Naming Conventions**:
   - Classes: `PascalCase`
   - Functions/Variables: `camelCase`
   - Constants: `lowerCamelCase`
   - Private members: `_leadingUnderscore`

2. **File Organization**:
   ```dart
   // 1. Imports (sorted: dart, flutter, package, relative)
   import 'dart:async';
   import 'package:flutter/material.dart';
   import 'package:expense_tracker/core/models/trip.dart';
   import '../widgets/trip_card.dart';

   // 2. Class definition
   class MyWidget extends StatelessWidget {
     // 3. Constants
     static const double padding = 16.0;

     // 4. Fields
     final String title;

     // 5. Constructor
     const MyWidget({Key? key, required this.title}) : super(key: key);

     // 6. Methods
     @override
     Widget build(BuildContext context) { ... }
   }
   ```

3. **Clean Architecture**:
   - Presentation layer: UI only, no business logic
   - Domain layer: Business logic, no dependencies on presentation/data
   - Data layer: Implementation details, no business logic

4. **State Management**:
   - Use BLoC/Cubit pattern
   - Create new state objects, never modify existing
   - Keep cubits focused and single-purpose

### Mobile-First Design

**Critical requirements**:
- Design for 375x667px (iPhone SE) FIRST
- Touch targets minimum 44x44px
- Use `SingleChildScrollView` for all forms
- Use `MediaQuery` for responsive spacing
- Test on mobile viewport before considering complete

**See**: [MOBILE.md](MOBILE.md) for complete guidelines

### Localization

**Always use localized strings**:

```dart
// ✅ CORRECT
Text(context.l10n.commonCancel)
Text(context.l10n.expensePaidBy(payerName))

// ❌ WRONG
Text('Cancel')
Text('Paid by $payerName')
```

**Adding new strings**:
1. Edit `lib/l10n/app_en.arb`
2. Run `flutter pub get`
3. Use `context.l10n.stringKey`

**See**: [DEVELOPMENT.md#localization-system](DEVELOPMENT.md#localization-system)

### Currency Handling

**Always use CurrencyTextField**:

```dart
// ✅ CORRECT
CurrencyTextField(
  controller: _amountController,
  currencyCode: CurrencyCode.usd,
  label: context.l10n.expenseFieldAmountLabel,
)

// ❌ WRONG
TextField(
  controller: _amountController,
  keyboardType: TextInputType.number,
)
```

**See**: [DEVELOPMENT.md#currency-input-system](DEVELOPMENT.md#currency-input-system)

---

## Documentation Requirements

**Documentation is not optional** - it's part of the definition of "done."

### For All Changes

1. **Code comments** - Document complex logic, edge cases, workarounds
2. **Update relevant docs** - If you change behavior, update docs
3. **Changelog entries** - Use `/docs.log` for feature branches

### For New Features

Required documentation:

1. **Feature specification** (`spec.md`) - What you're building and why
2. **Implementation plan** (`plan.md`) - How you'll build it
3. **Feature CLAUDE.md** - Architecture and design decisions
4. **Feature CHANGELOG.md** - Development log
5. **Update root docs** - Add to FEATURES.md, update CLAUDE.md if needed

**Use the documentation workflow commands**:
- `/docs.create` - Initialize feature docs
- `/docs.log "description"` - Log changes frequently
- `/docs.update` - Update architecture docs
- `/docs.complete` - Mark feature complete

---

## Testing Requirements

**All new code must be tested.**

### Unit Tests (Required)

- **Cubits**: Test all state transitions, error cases, edge cases
- **Models**: Test serialization, deserialization, validation
- **Utilities**: Test all functions, edge cases, error handling

**Minimum coverage**: 80% for new code

### Widget Tests (Encouraged)

- Test critical user flows
- Test form validation
- Test error states

### Integration Tests (For Major Features)

- Test complete user flows end-to-end
- Test data persistence
- Test Firebase integration

**See**: [`.claude/skills/cubit-testing.md`](.claude/skills/cubit-testing.md)

---

## Pull Request Process

### Before Creating a PR

1. **Self-review your changes**:
   - Review every line of your diff
   - Remove debug code, console.log statements
   - Remove commented-out code
   - Check for TODO comments

2. **Run the full test suite**:
   ```bash
   flutter analyze && flutter format . && flutter test
   ```

3. **Test on mobile viewport**:
   ```bash
   flutter run -d chrome --web-browser-flag "--window-size=375,667"
   ```

4. **Update documentation**:
   - Run `/docs.update` if architecture changed
   - Verify all `/docs.log` entries are complete
   - Update FEATURES.md if adding/modifying features

### Creating the PR

1. **Push your branch**:
   ```bash
   git push origin 012-feature-name
   ```

2. **Create PR on GitHub**:
   - Use a clear, descriptive title
   - Fill out the PR template completely
   - Link related issues with "Closes #123" or "Fixes #456"
   - Add screenshots/videos for UI changes
   - Mark as draft if not ready for review

3. **PR description should include**:
   - **What** changed
   - **Why** it changed
   - **How** to test it
   - **Screenshots** (for UI changes)
   - **Breaking changes** (if any)
   - **Related issues**

**PR title format**:

```
feat(expenses): add multi-currency support (#123)
fix(trips): prevent duplicate trip creation (#456)
docs: update CONTRIBUTING.md with new workflow
```

### After Creating the PR

1. **Address CI failures** - Fix any failing tests or linting issues
2. **Respond to reviews** - Address feedback promptly
3. **Keep PR updated** - Rebase on master if needed
4. **Be patient** - Reviews take time

---

## Review Process

### For Reviewers

**Review checklist**:

- [ ] Code follows project standards
- [ ] Tests are comprehensive
- [ ] Documentation is complete
- [ ] Mobile-first principles followed
- [ ] Localization used correctly
- [ ] Activity logging added (if applicable)
- [ ] Currency handling correct (if applicable)
- [ ] No hardcoded strings
- [ ] Clean architecture respected
- [ ] Performance considerations addressed

**Review guidelines**:
- Be constructive and respectful
- Explain *why*, not just *what* needs to change
- Praise good work
- Suggest improvements, don't demand perfection
- Use "nit:" prefix for minor suggestions

### For Contributors

**Responding to reviews**:
- Thank reviewers for their time
- Ask questions if feedback is unclear
- Address all feedback (or explain why not)
- Mark conversations as resolved when done
- Push updates to the same branch

**If requested changes**:
- Make changes in new commits (don't force-push)
- Reply to each comment when addressed
- Request re-review when ready

---

## Questions?

- **Documentation**: Start with [CLAUDE.md](CLAUDE.md)
- **Issues**: Check [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
- **Chat**: Ask in the team chat
- **GitHub**: Create an issue or discussion

---

**Thank you for contributing! 🙏**
