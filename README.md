# Expense Tracker

A Flutter-based expense tracking application for managing shared trip expenses with multi-currency support, settlement calculations, and real-time collaboration.

## Quick Links

- **[Getting Started Guide](GETTING_STARTED.md)** - New contributor onboarding
- **[CLAUDE.md](CLAUDE.md)** - Quick reference hub for development
- **[Contributing Guidelines](CONTRIBUTING.md)** - How to contribute

## Features

- Multi-currency expense tracking
- Shared trip management with multiple participants
- Automatic settlement calculations
- Activity logging and audit trail
- Firebase backend with offline support
- Mobile-first responsive design
- Localization support (English)

## Documentation System

This project uses a comprehensive multi-document system:

### Core Documentation

| Document | Purpose | Read When |
|----------|---------|-----------|
| **[CLAUDE.md](CLAUDE.md)** | Quick reference hub | Start here |
| **[PROJECT_KNOWLEDGE.md](PROJECT_KNOWLEDGE.md)** | Architecture & patterns | Understanding codebase structure |
| **[MOBILE.md](MOBILE.md)** | Mobile-first guidelines | Creating/refactoring UI |
| **[DEVELOPMENT.md](DEVELOPMENT.md)** | Development workflows | Using systems (localization, currency, etc.) |
| **[TROUBLESHOOTING.md](TROUBLESHOOTING.md)** | Common issues | Debugging problems |

### Workflow Skills

Reusable step-by-step guides in [`.claude/skills/`](.claude/skills/):

- `mobile-first-design.md` - Mobile-first UI implementation
- `activity-logging.md` - Add activity tracking to features
- `localization-workflow.md` - Add localized strings
- `cubit-testing.md` - Write BLoC/Cubit tests
- `currency-input.md` - Implement currency fields
- `read-with-context.md` - Understand code in context

### Feature Documentation

Each feature has its own documentation in [`specs/`](specs/):

```
specs/{feature-id}-{feature-name}/
├── spec.md           # Feature specification
├── plan.md           # Implementation plan
├── tasks.md          # Task breakdown
├── CLAUDE.md         # Feature architecture
└── CHANGELOG.md      # Development log
```

## Quick Start

### Prerequisites

- Flutter SDK (latest stable)
- Dart SDK (comes with Flutter)
- Firebase project configured
- Git

### Development Setup

```bash
# Clone repository
git clone https://github.com/taihartman/expense_tracker.git
cd expense_tracker

# Install dependencies
flutter pub get

# Run app (mobile viewport)
flutter run -d chrome --web-browser-flag "--window-size=375,667"

# Run tests
flutter test

# Lint code
flutter analyze

# Format code
flutter format .
```

### Before Every Commit

```bash
flutter analyze && flutter format . && flutter test
```

## Development Workflow

This project uses a **documentation-first workflow**:

1. **Create feature**: `/docs.create` - Initialize feature documentation
2. **Log changes**: `/docs.log "description"` - Log changes frequently
3. **Update architecture**: `/docs.update` - Update feature architecture docs
4. **Complete feature**: `/docs.complete` - Mark feature complete and roll up to root

## Architecture

Clean Architecture with three layers:

```
Presentation Layer (UI)
├── Pages - Full-screen views
├── Widgets - Reusable UI components
└── Cubits - State management (BLoC pattern)

Domain Layer (Business Logic)
├── Models - Domain entities
├── Repositories - Abstract interfaces
└── Utils - Business logic helpers

Data Layer (Implementation)
├── Repositories - Concrete implementations
├── Models - Serialization models
└── Data Sources - Firebase/database access
```

**For detailed architecture**: See [PROJECT_KNOWLEDGE.md](PROJECT_KNOWLEDGE.md)

## Tech Stack

- **Framework**: Flutter (web, mobile-first)
- **State Management**: BLoC/Cubit
- **Backend**: Firebase (Firestore, Auth)
- **Storage**: Local Storage API
- **Testing**: flutter_test, mockito
- **Localization**: flutter_localizations, intl
- **Currency**: decimal package

## Testing

```bash
# Run all tests
flutter test

# Run specific test
flutter test test/path/to/test.dart

# Run with coverage
flutter test --coverage

# Generate mocks (after modifying @GenerateMocks)
dart run build_runner build --delete-conflicting-outputs
```

## Deployment

Automatic deployment to GitHub Pages on push to `master`:

- **Live App**: https://taihartman.github.io/expense_tracker/
- **CI/CD**: `.github/workflows/deploy.yml`
- **Version Bumping**: Automated patch version bumps on merge

## Project Structure

```
lib/
├── main.dart                     # App entry point
├── core/                         # Shared core functionality
│   ├── models/                   # Shared models
│   ├── services/                 # Core services
│   └── l10n/                     # Localization utilities
├── shared/                       # Shared UI components
│   ├── widgets/                  # Reusable widgets
│   └── utils/                    # Shared utilities
└── features/                     # Feature modules
    ├── trips/                    # Trip management
    ├── expenses/                 # Expense tracking
    └── settlements/              # Settlement calculations

test/                             # Test files (mirrors lib/)
.claude/                          # Claude Code configuration
├── commands/                     # Custom slash commands
└── skills/                       # Reusable workflow skills
specs/                            # Feature specifications
```

## Contributing

We welcome contributions! Please read our [Contributing Guidelines](CONTRIBUTING.md) first.

### Quick Contribution Steps

1. Read [GETTING_STARTED.md](GETTING_STARTED.md) for onboarding
2. Create feature branch: `{id}-{feature-name}`
3. Follow Spec-Kit workflow (see [DEVELOPMENT.md#spec-driven-development](DEVELOPMENT.md#spec-driven-development))
4. Use `/docs.log` to document changes
5. Run tests and linting before committing
6. Create pull request

## License

[Add your license here]

## Support

- **Issues**: [GitHub Issues](https://github.com/taihartman/expense_tracker/issues)
- **Documentation**: Start with [CLAUDE.md](CLAUDE.md)
- **Troubleshooting**: See [TROUBLESHOOTING.md](TROUBLESHOOTING.md)

---

**For detailed development information, start with [CLAUDE.md](CLAUDE.md)**
