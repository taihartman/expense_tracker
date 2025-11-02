# Feature Changelog: Feature 010

**Feature ID**: 010-iso-4217-currencies

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

## 2025-11-02

### Changed
- Fixed critical compilation bug where Turkish Lira (TRY) conflicted with Dart's 'try' keyword. Implemented keyword escaping in currency code generator using $ prefix for all 29 Dart reserved keywords (assert, break, case, catch, class, const, continue, default, do, else, enum, extends, false, final, finally, for, if, in, is, new, null, rethrow, return, super, switch, this, throw, true, try, var, void, while, with). TRY currency now generates as  enum value. Code compiles successfully with all 170+ currencies working.


## 2025-11-02

### Changed
- Implemented complete ISO 4217 multi-currency support system with 170+ currencies. Created build_runner code generator that reads assets/currencies.json and generates type-safe CurrencyCode enum (1,149 lines). Implemented CurrencySearchField widget with mobile-optimized modal, virtualized list rendering, 300ms debounced search, and accessibility support. Updated CurrencyFormatters to dynamically support 0/2/3 decimal places based on ISO 4217 standard (JPY=0, USD=2, KWD=3). Replaced DropdownButtonFormField in trip_create_page and trip_edit_page with new searchable currency picker. Added 7 localized strings to app_en.arb for currency search UI. System maintains 100% backward compatibility with existing USD/VND data (no migration needed). Code generation completes in ~15 seconds with full validation. All changes compiled successfully with zero analyze issues.


## 2025-11-01 - Initial Setup

### Added
- Created feature specification
- Set up feature branch
- Initialized documentation structure
