# Feature Changelog: Receipt Split UX Improvements

**Feature ID**: 005-receipt-split-ux

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

## 2025-10-30 - Initial Setup

### Added
- Created feature specification
- Set up feature branch
- Initialized documentation structure

### Changed
- **Phase 1 Complete**: Migrated 74 localization strings from 'itemized' to 'receiptSplit' terminology
- Updated `lib/l10n/app_en.arb`: Renamed all `itemized*` keys to `receiptSplit*`
- Updated string values: 'Itemized (Add Line Items)' → 'Receipt Split (Who Ordered What)'
- Updated code references: Find/replace `.l10n.itemized*` → `.l10n.receiptSplit*` across lib/ and test/
- Fixed 2 remaining references in `split_type.dart` and `expense_form_page.dart`
- Verified with `flutter analyze` (zero errors)
