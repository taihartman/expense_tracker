# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

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
- `test/` - Test files (currently minimal)
- `web/` - Web-specific files (index.html, icons, manifest)
- `specs/` - Feature specifications managed by Spec-Kit
- `.specify/` - Spec-Kit configuration and templates

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
4. **Create feature documentation**: Use `/docs.create` to create feature-specific CLAUDE.md
5. Use `/speckit.plan` to generate implementation plan
6. Use `/speckit.tasks` to generate task breakdown
7. Use `/speckit.implement` to execute implementation
8. **Update docs during development**: Use `/docs.update` as you make changes
9. **Mark complete**: Use `/docs.complete` to finalize documentation and update CHANGELOG.md

### Documentation Workflow

Each feature maintains its own CLAUDE.md file in `specs/{feature-id}/CLAUDE.md`:

**Available commands**:
- `/docs.create` - Create initial feature CLAUDE.md from template
- `/docs.update` - Update feature CLAUDE.md with recent changes
- `/docs.complete` - Mark feature complete and update CHANGELOG.md

**Manual script usage**:
```bash
# Create feature documentation
.specify/scripts/bash/update-feature-docs.sh create {feature-id}

# Mark feature as complete (updates CLAUDE.md and CHANGELOG.md)
.specify/scripts/bash/update-feature-docs.sh complete {feature-id}
```

**Feature CLAUDE.md includes**:
- Quick reference commands specific to the feature
- Files created/modified by the feature
- Architecture decisions and design patterns
- Dependencies added
- Testing strategy
- Migration notes and breaking changes

**CHANGELOG.md**:
- Automatically updated when feature is marked complete
- Tracks all features in reverse chronological order
- Follows [Keep a Changelog](https://keepachangelog.com/) format

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
