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
