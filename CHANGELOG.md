# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project follows feature-driven versioning with Spec-Kit.

## [Unreleased]

### In Progress

- [001-group-expense-tracker] Group expense tracker with multi-currency support

### Fixed

**[2025-10-31] Category Creation Authentication Bug** - Fixed Firestore permission denied error when creating categories and implemented centralized authentication architecture:

- **Root Cause**: Widget was hardcoding `'current-user'` string instead of using actual Firebase Auth UID, causing security rule validation to fail
- **Solution**: Created `AuthService` to centralize Firebase Auth access and enforce proper separation of concerns
- **Architecture Improvement**: Removed all direct `FirebaseAuth` imports from presentation layer
- **Documentation**: Added comprehensive authentication architecture section to `CLAUDE.md` explaining the two-identity system:
  - Firebase Auth UID: For rate limiting and security rule validation only
  - Participant ID: For all business logic, activity logging, and user identity
- **Files Created**:
  - `lib/core/services/auth_service.dart` (new centralized auth service with extensive documentation)
- **Files Modified**:
  - `lib/core/cubits/initialization_cubit.dart` (uses AuthService)
  - `lib/features/categories/presentation/cubit/category_cubit.dart` (gets auth UID from AuthService internally, removed userId parameter)
  - `lib/features/categories/presentation/widgets/category_creation_bottom_sheet.dart` (removed Firebase Auth import and userId logic)
  - `lib/main.dart` (provides AuthService to CategoryCubit)
  - `CLAUDE.md` (added authentication architecture section with clear guidelines)
  - All related tests updated and mocks regenerated
- **Impact**: Prevents future authentication bugs by enforcing architectural boundaries and providing clear patterns for when to use auth UID vs participant ID

**[2025-10-31] Settlement Display Inconsistency** - Fixed UX bug where Individual Balance Card and Everyone's Summary showed different amounts:

- **Individual Balance Card** now calculates "Total Owed" from active transfers (matching Everyone's Summary) instead of raw expense shares
- Both views now show consistent values and properly exclude settled transfers
- Modified `PersonDashboardCard` to accept `activeTransfers` and calculate payment obligations from netted transfers
- Updated `settlement_summary_page.dart` to pass active transfers to dashboard cards
- Files changed:
  - `lib/features/settlements/presentation/widgets/person_dashboard_card.dart`
  - `lib/features/settlements/presentation/pages/settlement_summary_page.dart`

### Added - Infrastructure

**[2025-01-30] Claude Code Workflow Improvements** - Implemented Reddit post recommendations for improved development experience:

- **Skills System**: Created 6 reusable workflow skills in `.claude/skills/`
  - `mobile-first-design.md` - Mobile-first UI implementation workflow
  - `activity-logging.md` - Activity logging integration guide
  - `localization-workflow.md` - Localized string management
  - `cubit-testing.md` - BLoC/Cubit testing patterns
  - `currency-input.md` - Currency field implementation
  - `read-with-context.md` - Code investigation methodology

- **Documentation Split**: Transformed monolithic 1101-line CLAUDE.md into multi-document system
  - `CLAUDE.md` (400 lines) - Quick reference hub with links
  - `PROJECT_KNOWLEDGE.md` - Architecture, design patterns, data flow
  - `MOBILE.md` - Mobile-first design guidelines
  - `DEVELOPMENT.md` - Development workflows (localization, currency, activity logging)
  - `TROUBLESHOOTING.md` - Common issues and solutions

- **Hooks System**: Created 3 autonomous hooks in `.claude/hooks/` for automatic pattern enforcement
  - `user-prompt-submit.md` - Auto-injects skill reminders based on user intent (keyword detection)
  - `stop-event.md` - Self-checks for errors and pattern compliance after responses
  - `pre-commit.md` - Quality gates before commits (analyze, format, test, pattern checks)
  - `README.md` - Hook system documentation
  - `USAGE_GUIDE.md` - Testing instructions, behavior examples, troubleshooting, and customization guide
  - **Technical Note**: Hooks are Markdown-based declarative instructions that Claude Code automatically reads at lifecycle events, not TypeScript executables. They work through context injection - Claude reads the instructions and follows them autonomously.

**Impact:**
- 64% reduction in main documentation file size (1101 → 400 lines)
- Faster navigation with specialized documents
- Consistent patterns via reusable skills
- Comprehensive troubleshooting guide for common issues
- **Autonomous Claude**: Skills and patterns enforced automatically without manual reminders
- **Quality gates**: Errors caught immediately before becoming bugs
- **Zero errors left behind**: Pre-commit hooks ensure all commits meet quality standards

---

## [006-centralized-activity-logger] - 2025-10-30

### Added

Centralized ActivityLoggerService that consolidates all activity logging logic across the application.

**Impact:**
- **67% code reduction**: 189 lines → 62 lines across 3 cubits
- **Developer experience**: Single method call vs 15-30 lines of boilerplate per operation
- **Performance**: <10ms overhead with 5-minute trip context caching
- **Reliability**: Fire-and-forget pattern ensures logging failures never block business operations

**New Components:**
- `ActivityLoggerService` - Abstract interface with 8 logging methods
- `ActivityLoggerServiceImpl` - Complete implementation with smart caching
- Comprehensive test suite with 17 test cases

**Migrated Cubits:**
- ExpenseCubit: 68% code reduction (102 → 33 lines)
- SettlementCubit: 84% code reduction (31 → 5 lines)
- TripCubit: 57% code reduction (56 → 24 lines)

**Documentation:** See [specs/006-centralized-activity-logger/](./specs/006-centralized-activity-logger/) for detailed implementation guide, architecture decisions, and migration patterns.

---

## How to Read This Changelog

Each feature is tracked with its feature ID (e.g., `001-group-expense-tracker`).

### Categories:
- **Added**: New features
- **Changed**: Changes to existing functionality
- **Deprecated**: Soon-to-be removed features
- **Removed**: Removed features
- **Fixed**: Bug fixes
- **Security**: Security improvements

### Format:
```markdown
## [Feature ID] - YYYY-MM-DD

### Added
- Description of what was added

### Changed
- Description of what changed
```

---

<!-- Features will be appended below in reverse chronological order -->

## Future Features

Features planned but not yet started:
- TBD

---

## Initial Release - 2024-10-20

### Added
- Initial Flutter web project setup
- GitHub Actions CI/CD with auto-deploy to GitHub Pages
- Claude Code Action integration
- GitHub Spec-Kit integration for spec-driven development
- Project structure and basic configuration
