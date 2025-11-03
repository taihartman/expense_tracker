# Implementation Plan: ISO 4217 Multi-Currency Support

**Branch**: `010-iso-4217-currencies` | **Date**: 2025-01-30 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/010-iso-4217-currencies/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

Expand currency support from 2 hardcoded currencies (USD, VND) to all 170+ ISO 4217 currencies using a code generation approach with build_runner. The system will generate a type-safe enum from a JSON data source containing currency metadata (code, symbol, decimal places, display name). This maintains the existing type-safe enum API while supporting all world currencies. A new searchable currency picker widget will replace simple dropdowns to handle the larger currency list efficiently on mobile devices.

**Technical Approach**: Use build_runner to generate `currency_code.g.dart` from `assets/currencies.json`, update CurrencyTextField to support 3 decimal places, create CurrencySearchField widget for mobile-optimized currency selection, and maintain 100% backward compatibility with existing USD/VND data.

## Technical Context

**Language/Version**: Dart 3.x / Flutter 3.x
**Primary Dependencies**:
  - `flutter_bloc` (state management)
  - `build_runner` (code generation - already in use for mocks)
  - `json_annotation` (currency data serialization)
  - `decimal` (monetary calculations)
  - `intl` (number formatting, potentially for currency symbols fallback)

**Storage**: Cloud Firestore (currency codes stored as strings: "USD", "EUR", etc.)
**Testing**:
  - `flutter_test` (widget and unit tests)
  - `mockito` (mocking with build_runner)
  - `bloc_test` (cubit testing)

**Target Platform**: Web (Chrome, primary), iOS/Android (future)
**Project Type**: Mobile-first web application (Flutter Web)
**Performance Goals**:
  - Currency picker search results <1 second
  - Enum generation build time <30 seconds
  - No runtime performance impact vs. current 2-currency system

**Constraints**:
  - Mobile viewport 375x667px primary target
  - Currency picker must handle 170+ items efficiently (virtualization/search required)
  - Maximum 3 decimal places (covers all ISO 4217 active currencies)
  - Backward compatibility with existing Firestore data (strings already in use)

**Scale/Scope**:
  - 170+ currency enum values generated
  - 27 files with CurrencyCode usage to update
  - 111 total CurrencyCode references
  - 4 UI files with currency dropdowns to replace with search widget

## Mobile-First Design Considerations

**⚠️ CRITICAL: This application is mobile-first.** All UI features must be designed and tested for mobile (375x667px) first, then enhanced for larger screens.

**Mobile Target Viewport**: 375x667px (iPhone SE)
**Responsive Breakpoints**: Mobile (<600px), Tablet (600-1024px), Desktop (>1024px)

### UI/UX Design Requirements

- [ ] Mobile layout designed first (portrait orientation, 375x667px)
- [ ] All touch targets minimum 44x44px
- [ ] Forms use `SingleChildScrollView` (keyboard-aware)
- [ ] Complex input flows use modal bottom sheets on mobile
- [ ] Responsive padding: 12px (mobile), 16px (desktop)
- [ ] Responsive font sizes: 13-18px (mobile), 14-20px (desktop)
- [ ] Responsive icon sizes: 20px (mobile), 24px (desktop)
- [ ] Primary actions positioned for thumb access (bottom/FAB)
- [ ] No horizontal scrolling
- [ ] No fixed-height layouts competing for vertical space

### Mobile Testing Plan

Before feature completion:
- [ ] Test on 375x667px viewport in Chrome DevTools
- [ ] Verify all text fields visible when keyboard appears
- [ ] Verify forms are scrollable with keyboard open
- [ ] Verify touch targets are easily tappable
- [ ] Verify no layout overflow on small screens
- [ ] Test on both mobile AND desktop viewports

See `.mobile-design-checklist.md` and `CLAUDE.md` (Mobile-First Design Principles section) for complete guidelines.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### Principle I: Test-Driven Development
**Status**: ✅ PASS
- Tests will be written for currency enum generation before implementation
- Tests for CurrencySearchField widget before implementation
- Tests for 3-decimal currency support before updating CurrencyTextField
- Backward compatibility tests for existing USD/VND data before migration

**Plan**: Follow TDD cycle for all new components (CurrencySearchField, code generator, formatter updates)

### Principle II: Code Quality & Maintainability
**Status**: ✅ PASS
- Code generation reduces manual enum maintenance (DRY principle)
- Generated code will be linted and formatted automatically
- Public API documentation will be added to CurrencySearchField widget
- Code coverage: aim for 80% on currency formatter logic, 60% overall

**Plan**: Configure build_runner to format generated code, add comprehensive tests for currency search logic

### Principle III: User Experience Consistency
**Status**: ✅ PASS with mobile-first focus
- CurrencySearchField will follow existing app design patterns (consistent spacing, typography)
- Touch targets minimum 44x44px per accessibility requirements
- Loading states for currency search >300ms
- Error handling for "no results found" scenarios
- Mobile-first: searchable picker optimized for 375x667px viewport

**Plan**: Create CurrencySearchField using existing design system components (same input styling as CurrencyTextField)

### Principle IV: Performance Standards
**Status**: ✅ PASS
- Currency search results <1 second (within 100ms interaction guideline)
- Build_runner generation <30 seconds (acceptable for dev-time operation)
- No memory leaks from 170-item list (will use ListView.builder for virtualization)
- Bundle size impact minimal (generated code ~100KB, currency JSON ~50KB)

**Plan**: Benchmark currency search performance, use virtualized list rendering for mobile

### Principle V: Data Integrity & Security
**Status**: ✅ PASS
- Monetary values continue using Decimal type (no change)
- Currency codes validated against generated enum (compile-time type safety)
- Backward compatibility preserved (existing "USD"/"VND" strings still valid)
- No data migration required (currency codes already stored as strings)

**Plan**: Add validation tests to ensure all stored currency codes are valid against generated enum

**Overall Gate Status**: ✅ **PASS** - All constitutional principles satisfied. No violations to justify.

## Project Structure

### Documentation (this feature)

```
specs/010-iso-4217-currencies/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (currency data source, code generation patterns)
├── data-model.md        # Phase 1 output (Currency entity, generated enum structure)
├── quickstart.md        # Phase 1 output (developer guide for adding currencies)
├── contracts/           # Phase 1 output (CurrencySearchField API, code generator interface)
│   └── currency_search_field_api.md
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created yet)
```

### Source Code (repository root)

```
lib/
├── core/
│   ├── models/
│   │   ├── currency_code.dart           # MODIFIED: Now imports generated code
│   │   └── currency_code.g.dart         # NEW: Generated enum values
│   └── utils/
│       └── formatters.dart               # MODIFIED: Support 3 decimals
├── shared/
│   ├── widgets/
│   │   ├── currency_text_field.dart      # MODIFIED: Support 3 decimals
│   │   └── currency_search_field.dart    # NEW: Searchable currency picker
│   └── utils/
│       └── currency_input_formatter.dart # MODIFIED: Support 3 decimals
└── features/
    ├── trips/presentation/pages/
    │   ├── trip_create_page.dart         # MODIFIED: Use CurrencySearchField
    │   └── trip_edit_page.dart           # MODIFIED: Use CurrencySearchField
    └── expenses/presentation/
        ├── pages/expense_form_page.dart  # MODIFIED: Use CurrencySearchField
        └── widgets/expense_form_bottom_sheet.dart  # MODIFIED: Use CurrencySearchField

assets/
└── currencies.json                       # NEW: ISO 4217 currency data source

lib/generators/
└── currency_code_generator.dart          # NEW: build_runner generator

test/
├── core/models/
│   └── currency_code_test.dart           # MODIFIED: Test all currencies
├── shared/widgets/
│   └── currency_search_field_test.dart   # NEW: Widget tests
└── generators/
    └── currency_code_generator_test.dart # NEW: Generator tests
```

**Structure Decision**: This is a Flutter web/mobile application using clean architecture. The feature touches:
- **Core layer**: Currency enum (generated) and formatters
- **Shared layer**: Reusable widgets (CurrencyTextField, new CurrencySearchField)
- **Presentation layer**: 4 pages using currency selection (trips + expenses)
- **Build system**: New code generator for currency enum

No backend changes required (Firestore already stores currency codes as strings).

## Complexity Tracking

*Fill ONLY if Constitution Check has violations that must be justified*

**Status**: No violations detected. All constitutional requirements satisfied.

