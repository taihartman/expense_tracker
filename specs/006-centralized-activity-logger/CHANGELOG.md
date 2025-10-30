# Feature Changelog: Feature 006

**Feature ID**: 006-centralized-activity-logger

This changelog tracks all changes made during the development of this feature.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [Unreleased]

### Added
- [New features, files, or capabilities added]

### Changed
- [Changes to existing functionality]

### Fixed
- [Bug fixes]

### Removed
- [Removed features or files]

---

## Development Log

<!-- Add entries below in reverse chronological order (newest first) -->

## 2025-10-30 - Enhanced tasks.md with TDD enforcement

- Added explicit TDD enforcement with "PREREQUISITE: Verify test fails first" to all implementation tasks
- Added TDD CHECKPOINT section before Phase 3 implementation to verify all tests fail before proceeding
- Added 6 new verification tasks for edge cases and coverage validation:
  - T004b: Partial failure scenario testing
  - T005b: _getTripContext() failure handling
  - T011b: Baseline performance measurement
  - T022b: ExpenseChangeDetector reuse verification
  - T029c, T049b, T061b: 80%+ coverage verification after each user story
- Enhanced T014 to test both skip-logging and log-with-empty-metadata scenarios
- Enhanced T048 with specific metadata documentation requirements (field naming, structure examples)
- Addresses /speckit.analyze findings: 1 critical issue (F006 - TDD enforcement), 4 high-priority gaps (F001, F009, F018, F019), and 3 medium-priority issues (F002, F003, F004)

## 2025-10-30 - Receipt Split Workflow Redesign

- Implemented new 5-step receipt split wizard flow
- Added receipt info step (step 1) for collecting subtotal and tax amount upfront
- Reordered steps: Receipt Info, Payer, Items, Tip, Review
- Added live validation banner in items step showing expected vs current total
- Validation banner uses green/orange color coding for match/mismatch status
- Simplified extras step to tip-only (tax now collected in receipt info step)
- Updated ItemizedExpenseEditing state with expectedSubtotal and taxAmount fields
- Added setReceiptInfo() method to ItemizedExpenseCubit
- Created receipt_info_step_page.dart for step 1
- Updated localization strings for new flow

## 2025-10-30 - Initial Setup

### Added
- Created feature specification
- Set up feature branch
- Initialized documentation structure
