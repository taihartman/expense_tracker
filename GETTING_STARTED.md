# Getting Started Guide

Welcome to the Expense Tracker project! This guide will help you get set up and productive quickly.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Initial Setup](#initial-setup)
3. [Development Environment](#development-environment)
4. [Project Structure](#project-structure)
5. [Core Concepts](#core-concepts)
6. [Your First Task](#your-first-task)
7. [Development Workflow](#development-workflow)
8. [Getting Help](#getting-help)

---

## Prerequisites

Before you begin, ensure you have the following installed:

### Required

- **Flutter SDK** (latest stable) - [Install](https://docs.flutter.dev/get-started/install)
- **Dart SDK** (comes with Flutter)
- **Git** - Version control
- **A code editor** - VS Code (recommended) or Android Studio

### Recommended

- **Firebase CLI** - For Firebase operations (optional for frontend dev)
- **Chrome or Edge** - For web development and testing
- **Node.js** - For some dev tools (markdown linting, etc.)

### Check Your Installation

```bash
flutter doctor
git --version
dart --version
```

---

## Initial Setup

### 1. Clone the Repository

```bash
git clone https://github.com/taihartman/expense_tracker.git
cd expense_tracker
```

### 2. Install Dependencies

```bash
flutter pub get
```

This will:
- Download all Flutter/Dart packages
- Generate localization files
- Set up the project

### 3. Install Git Hooks (Recommended)

```bash
./.githooks/install.sh
```

This installs pre-commit hooks that remind you to update documentation.

### 4. Verify Setup

Run the app in development mode:

```bash
# Run in Chrome with mobile viewport
flutter run -d chrome --web-browser-flag "--window-size=375,667"
```

If the app loads successfully, you're ready to go! 🎉

---

## Development Environment

### IDE Setup

#### VS Code (Recommended)

1. Install extensions:
   - **Flutter** - Flutter support
   - **Dart** - Dart language support
   - **Error Lens** - Inline error display
   - **GitHub Copilot** (optional) - AI assistance

2. Open the project:
   ```bash
   code .
   ```

3. Run Flutter: Press `F5` or use the Run menu

#### Android Studio

1. Open the project in Android Studio
2. Ensure Flutter and Dart plugins are installed
3. Use the green play button to run

### Firebase Setup (Optional)

If you need to work with Firebase:

1. Contact the team for Firebase project access
2. Download the Firebase configuration files
3. Place them in the appropriate directories (ask the team for details)

---

## Project Structure

```
expense_tracker/
├── lib/                          # Application code
│   ├── main.dart                 # App entry point
│   ├── core/                     # Shared core functionality
│   │   ├── models/               # Shared models
│   │   ├── services/             # Core services
│   │   └── l10n/                 # Localization utilities
│   ├── shared/                   # Shared UI components
│   │   ├── widgets/              # Reusable widgets
│   │   └── utils/                # Shared utilities
│   └── features/                 # Feature modules
│       ├── trips/                # Trip management
│       ├── expenses/             # Expense tracking
│       └── settlements/          # Settlement calculations
│
├── test/                         # Test files (mirrors lib/)
├── .claude/                      # Claude Code configuration
│   ├── commands/                 # Custom slash commands
│   └── skills/                   # Reusable workflow skills
├── specs/                        # Feature specifications
└── docs/                         # Documentation

Key files:
├── CLAUDE.md                     # Quick reference hub (START HERE!)
├── PROJECT_KNOWLEDGE.md          # Architecture and patterns
├── MOBILE.md                     # Mobile-first guidelines
├── DEVELOPMENT.md                # Development workflows
├── TROUBLESHOOTING.md            # Common issues
├── CONTRIBUTING.md               # Contribution guidelines
└── FEATURES.md                   # Feature directory
```

---

## Core Concepts

### Architecture

This project uses **Clean Architecture** with three layers:

1. **Presentation Layer** - UI (Pages, Widgets, Cubits)
2. **Domain Layer** - Business Logic (Models, Repositories, Utils)
3. **Data Layer** - Implementation (Repositories, Data Sources)

**Read**: [PROJECT_KNOWLEDGE.md](PROJECT_KNOWLEDGE.md) for detailed architecture

### State Management

We use **BLoC/Cubit** for state management:
- Cubits handle business logic and state
- UI widgets listen to cubits and react to state changes
- **Never** modify state directly - always emit new states

### Mobile-First Design

**Critical**: This is a **mobile-first** application.

- Design for **375x667px** (iPhone SE) first
- Touch targets minimum **44x44px**
- Use `SingleChildScrollView` for forms
- Test on mobile viewport before considering features complete

**Read**: [MOBILE.md](MOBILE.md) for complete guidelines

### Localization

**Always use localized strings** - never hardcode user-facing text.

```dart
// ✅ CORRECT
Text(context.l10n.commonCancel)

// ❌ WRONG
Text('Cancel')
```

**Read**: [DEVELOPMENT.md#localization-system](DEVELOPMENT.md#localization-system)

### Documentation Workflow

We maintain comprehensive documentation:

- **`/docs.create`** - Create feature documentation
- **`/docs.log "description"`** - Log changes (use frequently!)
- **`/docs.update`** - Update feature architecture docs
- **`/docs.complete`** - Mark feature complete

**Philosophy**: Document as you code, not after.

---

## Your First Task

Let's make a simple change to get familiar with the workflow.

### Option 1: Fix a Typo

1. Find a typo in the UI or documentation
2. Create a branch: `git checkout -b fix/typo-in-readme`
3. Fix the typo
4. Run tests: `flutter test`
5. Format code: `flutter format .`
6. Commit and create a PR

### Option 2: Add a Localized String

1. Find hardcoded text in the UI (search for `Text('` or `Text("`)
2. Create a branch: `git checkout -b fix/localize-button-text`
3. Follow the [localization workflow](.claude/skills/localization-workflow.md)
4. Test your changes
5. Commit and create a PR

### Option 3: Write a Test

1. Find a cubit with low test coverage
2. Create a branch: `git checkout -b test/trip-cubit-coverage`
3. Follow the [cubit testing workflow](.claude/skills/cubit-testing.md)
4. Run tests: `flutter test`
5. Commit and create a PR

---

## Development Workflow

### Daily Development

1. **Pull latest changes**:
   ```bash
   git checkout master
   git pull origin master
   ```

2. **Create feature branch**:
   ```bash
   git checkout -b 012-feature-name
   ```

3. **Code with documentation**:
   - Make changes
   - Run `/docs.log "description"` frequently
   - Test your changes
   - Update documentation

4. **Before committing**:
   ```bash
   flutter analyze && flutter format . && flutter test
   ```

5. **Commit and push**:
   ```bash
   git add .
   git commit -m "feat: add feature description"
   git push origin 012-feature-name
   ```

6. **Create Pull Request**

### Using Spec-Kit (For New Features)

For significant new features, follow the Spec-Kit workflow:

1. `/speckit.specify` - Create specification
2. `/speckit.clarify` - Clarify underspecified areas
3. `/speckit.plan` - Generate implementation plan
4. `/speckit.tasks` - Generate task breakdown
5. `/speckit.analyze` - Validate consistency
6. `/speckit.checklist` - Generate quality checklist
7. `/speckit.implement` - Execute implementation

**Read**: [DEVELOPMENT.md#spec-driven-development](DEVELOPMENT.md#spec-driven-development)

### Essential Commands

```bash
# Run app (mobile viewport)
flutter run -d chrome --web-browser-flag "--window-size=375,667"

# Run tests
flutter test

# Run specific test
flutter test test/path/to/test.dart

# Lint code
flutter analyze

# Format code
flutter format .

# Generate mocks (after adding @GenerateMocks)
dart run build_runner build --delete-conflicting-outputs

# Build for production
flutter build web
```

---

## Getting Help

### Documentation

Start with **[CLAUDE.md](CLAUDE.md)** - it's the hub for everything.

Other key docs:
- **[PROJECT_KNOWLEDGE.md](PROJECT_KNOWLEDGE.md)** - Architecture
- **[MOBILE.md](MOBILE.md)** - Mobile-first design
- **[DEVELOPMENT.md](DEVELOPMENT.md)** - Workflows
- **[TROUBLESHOOTING.md](TROUBLESHOOTING.md)** - Common issues
- **[FEATURES.md](FEATURES.md)** - Feature directory

### Skills

Check **[.claude/skills/](.claude/skills/)** for step-by-step workflows:
- `mobile-first-design.md` - Mobile UI
- `activity-logging.md` - Activity tracking
- `localization-workflow.md` - Localized strings
- `cubit-testing.md` - BLoC/Cubit tests
- `currency-input.md` - Currency fields

### Common Issues

Check **[TROUBLESHOOTING.md](TROUBLESHOOTING.md)** first:
- Keyboard hiding form fields → Use `SingleChildScrollView`
- Cubit not emitting states → Create new objects
- Localization strings not found → Run `flutter pub get`
- Test mocks not found → Run `build_runner`

### Ask for Help

- **GitHub Issues** - Report bugs or ask questions
- **Team Chat** - Quick questions
- **Code Review** - Get feedback on PRs

---

## Next Steps

Now that you're set up:

1. ✅ Read [CLAUDE.md](CLAUDE.md) for quick reference
2. ✅ Browse [FEATURES.md](FEATURES.md) to understand what's built
3. ✅ Try the "Your First Task" exercise above
4. ✅ Read [CONTRIBUTING.md](CONTRIBUTING.md) for contribution guidelines
5. ✅ Join the team chat and introduce yourself!

---

## Quick Reference Card

```
Essential Commands:
  flutter run -d chrome --web-browser-flag "--window-size=375,667"  # Run app
  flutter test                                                       # Test
  flutter analyze && flutter format . && flutter test                # Before commit

Documentation Commands:
  /docs.log "description"   # Log changes
  /docs.create              # Create feature docs
  /docs.update              # Update architecture
  /docs.validate            # Check docs quality

Key Principles:
  ✅ Mobile-first (375x667px)
  ✅ Always use context.l10n.* (never hardcode strings)
  ✅ Document as you code
  ✅ Test before committing
  ✅ Follow clean architecture

Get Help:
  📚 CLAUDE.md - Start here
  🐛 TROUBLESHOOTING.md - Common issues
  💬 Team chat - Quick questions
```

---

**Welcome to the team! Happy coding! 🚀**
