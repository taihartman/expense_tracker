# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project follows feature-driven versioning with Spec-Kit.

## [Unreleased]

### In Progress

- [001-group-expense-tracker] Group expense tracker with multi-currency support

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
