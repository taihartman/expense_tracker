# Implementation Plan: Global Category Management System

**Branch**: `008-global-category-system` | **Date**: 2025-10-31 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/008-global-category-system/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

Transform the current trip-specific category system into a global shared category pool with intelligent defaults, autocomplete search, and spam prevention. Users will see the top 5 most popular categories by default, can browse/search thousands of global categories via a bottom sheet, and contribute new categories that immediately become available to all users. The system tracks category usage to provide smart defaults and prevent duplicate creation through case-insensitive search.

**Technical Approach**: Migrate existing trip-specific categories to a single global Firestore collection with usage tracking. Implement a new CategoryCubit for state management, refactor CategorySelector to use chips + "Other" button, create a new CategoryBrowserBottomSheet with search, and add CategoryCreationDialog with icon/color pickers. Rate limiting prevents spam via UserCategoryCreationLog tracking. Migration script updates all expense categoryId references automatically.

## Technical Context

**Language/Version**: Dart 3.x / Flutter 3.x (existing project)
**Primary Dependencies**:
- Firebase Firestore (existing)
- flutter_bloc/cubit 8.x (existing state management)
- Material Icons (existing)
- Localization: flutter_localizations, intl (existing)

**Storage**: Firebase Firestore
- `categories` collection (global, shared across all trips/users)
- Composite indexes: `usageCount DESC`, case-insensitive name queries
- Migration: Batch updates for expense categoryId references

**Testing**: flutter test (existing)
- Unit tests: Cubit logic, validation, rate limiting
- Widget tests: CategorySelector, bottom sheet, dialogs
- Integration tests: End-to-end category creation and selection flows
- Mock Firestore: mockito + build_runner (existing pattern)

**Target Platform**: Web (mobile-first responsive), iOS/Android future
**Project Type**: Mobile web application (Flutter web)

**Performance Goals**:
- Search results: <500ms for 95% of queries
- Cache load: <200ms for top 20 categories
- Bottom sheet open: <300ms
- Category creation: <1 second
- Popularity update: <1 minute after expense creation

**Constraints**:
- Mobile-first: 375x667px primary viewport
- Touch targets: 44x44px minimum
- Rate limiting: 3 categories per user per 5 minutes (hard limit)
- Cache size: Top 20 categories only (local storage constraints)
- Character validation: Letters, numbers, spaces, basic punctuation only
- Case-insensitive: All category name comparisons must be case-insensitive

**Scale/Scope**:
- Expected categories: 100-500 global categories initially, growing organically
- Top 5 categories handle 85% of usage (per success criteria)
- Expected concurrent users: 50-100 creating expenses simultaneously
- Migration: ~100-1000 existing trip-specific categories to consolidate

## Mobile-First Design Considerations

**⚠️ CRITICAL: This application is mobile-first.** All UI features must be designed and tested for mobile (375x667px) first, then enhanced for larger screens.

**Mobile Target Viewport**: 375x667px (iPhone SE)
**Responsive Breakpoints**: Mobile (<600px), Tablet (600-1024px), Desktop (>1024px)

### UI/UX Design Requirements

- [x] Mobile layout designed first (portrait orientation, 375x667px)
- [x] All touch targets minimum 44x44px (chip selectors, buttons, list items)
- [x] Forms use `SingleChildScrollView` (category creation dialog)
- [x] Complex input flows use modal bottom sheets on mobile (category browser)
- [x] Responsive padding: 12px (mobile), 16px (desktop)
- [x] Responsive font sizes: 13-18px (mobile), 14-20px (desktop)
- [x] Responsive icon sizes: 20px (mobile), 24px (desktop)
- [x] Primary actions positioned for thumb access (bottom sheet, FAB)
- [x] No horizontal scrolling (except scrollable chip row)
- [x] No fixed-height layouts competing for vertical space

### Mobile Testing Plan

Before feature completion:
- [ ] Test on 375x667px viewport in Chrome DevTools
- [ ] Verify category browser bottom sheet displays correctly on mobile
- [ ] Verify search field and results are scrollable
- [ ] Verify chip selectors are easily tappable (44x44px)
- [ ] Verify icon picker and color picker work on mobile
- [ ] Verify no layout overflow on small screens
- [ ] Test on both mobile AND desktop viewports

See `.mobile-design-checklist.md` and `CLAUDE.md` (Mobile-First Design Principles section) for complete guidelines.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### Principle I: Test-Driven Development (NON-NEGOTIABLE)
**Status**: ✅ COMPLIANT

Tests will be written first following TDD cycle:
- Unit tests for CategoryCubit state transitions (create, search, rate limit)
- Unit tests for validation logic (character rules, length, duplicates)
- Unit tests for rate limiting service
- Widget tests for CategorySelector, CategoryBrowserBottomSheet, CategoryCreationDialog
- Integration tests for complete flows (create → search → select)
- Mock Firestore repository for cubit tests

### Principle II: Code Quality & Maintainability
**Status**: ✅ COMPLIANT

- Flutter/Dart style guide: All code will use dart format and pass flutter analyze
- Cyclomatic complexity: State management kept simple (single responsibility per cubit method)
- Code coverage: Target 80% for cubit logic, 60% overall
- Public API documentation: All cubit methods, widgets, and repositories documented
- DRY: Shared validation logic in separate validator class, reusable widgets

### Principle III: User Experience Consistency
**Status**: ✅ COMPLIANT

- Visual design: 8px grid spacing, existing color scheme and typography
- Interaction patterns: Bottom sheet pattern (existing), chip selection pattern (existing)
- Error handling: User-friendly messages with recovery actions (rate limit: "wait", duplicate: "select existing")
- Loading states: Shimmer for category browser, spinners for creation (<300ms)
- Accessibility: 44x44px touch targets, semantic labels for screen readers
- Responsive design: Mobile-first (375x667px), scales to desktop

### Principle IV: Performance Standards
**Status**: ✅ COMPLIANT - with monitoring

- Initial load: Top 5 categories cached (instant load)
- Interaction response: <100ms visual feedback (search typing, button taps)
- Operations: Search <500ms (SC-002), cache load <200ms (SC-007)
- Memory: No leaks (dispose controllers, close streams)
- Bundle size: Minimal impact (reuses existing Material icons, no new dependencies)

**Performance Monitoring**: Track search latency, cache hit rates, category creation time in analytics.

### Principle V: Data Integrity & Security
**Status**: ✅ COMPLIANT

- Monetary values: N/A (no monetary calculations in this feature)
- Validation: Category names validated client-side (character rules, length, duplicates)
- Atomicity: Migration uses batched writes (all succeed or all fail)
- Audit trail: Activity logging for category creation (dependency noted in spec)
- Error recovery: Graceful degradation (cached categories work offline)
- Data persistence: Firestore ensures durability, cache survives refresh

### Summary
**All constitutional principles satisfied.** No violations or exceptions required.

## Project Structure

### Documentation (this feature)

```
specs/008-global-category-system/
├── spec.md              # Feature specification (completed)
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (to be generated)
├── data-model.md        # Phase 1 output (to be generated)
├── quickstart.md        # Phase 1 output (to be generated)
├── contracts/           # Phase 1 output (to be generated)
│   └── category_api.md  # Category operations interface
├── CLAUDE.md            # Feature architecture docs (existing)
└── CHANGELOG.md         # Development log (existing)
```

### Source Code (repository root)

**Structure Decision**: Flutter mobile web application with clean architecture (existing pattern)

```
lib/
├── features/
│   ├── categories/
│   │   ├── domain/
│   │   │   ├── models/
│   │   │   │   └── category.dart                    # EXISTING - update for global model
│   │   │   └── repositories/
│   │   │       └── category_repository.dart         # EXISTING - update interface
│   │   ├── data/
│   │   │   ├── models/
│   │   │   │   └── category_model.dart              # EXISTING - update for global model
│   │   │   └── repositories/
│   │   │       └── category_repository_impl.dart    # EXISTING - major refactor
│   │   └── presentation/
│   │       ├── cubits/
│   │       │   ├── category_cubit.dart              # NEW - state management
│   │       │   └── category_state.dart              # NEW - state definitions
│   │       ├── widgets/
│   │       │   ├── category_selector.dart           # EXISTING - refactor for chips + "Other"
│   │       │   ├── category_browser_bottom_sheet.dart  # NEW - search and browse UI
│   │       │   ├── category_creation_dialog.dart    # NEW - create category form
│   │       │   ├── icon_picker.dart                 # NEW - Material icon selector
│   │       │   └── color_picker.dart                # NEW - color palette selector
│   │       └── pages/                                # (Optional: dedicated category management page - out of scope)
│   │
│   └── expenses/
│       └── presentation/
│           └── pages/
│               └── expense_form_page.dart           # EXISTING - update to use new CategorySelector
│
├── core/
│   ├── constants/
│   │   └── categories.dart                          # EXISTING - update for global seed categories
│   ├── services/
│   │   └── rate_limiter_service.dart                # NEW - rate limiting logic
│   └── validators/
│       └── category_validator.dart                  # NEW - character and length validation
│
├── shared/
│   └── widgets/
│       └── loading_shimmer.dart                     # EXISTING - reuse for category browser
│
└── l10n/
    └── app_en.arb                                   # EXISTING - add new category UI strings

test/
├── features/
│   └── categories/
│       ├── domain/
│       │   └── models/
│       │       └── category_test.dart               # EXISTING - update tests
│       ├── data/
│       │   └── repositories/
│       │       └── category_repository_impl_test.dart  # EXISTING - major test updates
│       └── presentation/
│           ├── cubits/
│           │   └── category_cubit_test.dart         # NEW - comprehensive cubit tests
│           └── widgets/
│               ├── category_selector_test.dart      # EXISTING - update widget tests
│               ├── category_browser_bottom_sheet_test.dart  # NEW - widget tests
│               ├── category_creation_dialog_test.dart  # NEW - widget tests
│               ├── icon_picker_test.dart            # NEW - widget tests
│               └── color_picker_test.dart           # NEW - widget tests
│
├── core/
│   ├── services/
│   │   └── rate_limiter_service_test.dart          # NEW - rate limiting logic tests
│   └── validators/
│       └── category_validator_test.dart            # NEW - validation tests
│
└── integration/
    └── category_flow_test.dart                     # NEW - end-to-end category flows

scripts/
└── migrations/
    └── migrate_categories_to_global.dart           # NEW - one-time migration script
```

**Key Changes**:
- **NEW**: CategoryCubit for state management (presentation layer)
- **NEW**: 5 new widgets (bottom sheet, dialog, pickers)
- **NEW**: Rate limiter service and validator
- **NEW**: Migration script
- **REFACTOR**: CategoryRepository interface and implementation (global model)
- **REFACTOR**: CategorySelector widget (chips + "Other" button)
- **UPDATE**: Category domain and data models (remove tripId, add usageCount)

## Complexity Tracking

*Fill ONLY if Constitution Check has violations that must be justified*

**No violations.** This section intentionally left empty - all constitutional principles are satisfied without exceptions.

