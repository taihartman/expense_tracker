# Implementation Plan: Per-Trip Category Visual Customization

**Branch**: `009-trip-category-customization` | **Date**: 2025-10-31 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/009-trip-category-customization/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

Allow trips to customize the visual appearance (icon and color) of global categories without affecting the underlying category data or other trips. Users can override the default icon/color for any category on a per-trip basis, with customizations appearing consistently throughout the app. The system maintains global category consistency while enabling visual personalization per trip.

**Technical Approach**: Create a Firestore subcollection `/trips/{tripId}/categoryCustomizations/{categoryId}` to store visual overrides. Implement CategoryCustomizationRepository and CategoryCustomizationCubit for state management. Enhance CategorySelector and other category displays to merge global defaults with trip-specific customizations. Cache customizations in memory per trip session for optimal performance. Add "Customize Categories" screen in trip settings with icon/color pickers and reset functionality.

## Technical Context

**Language/Version**: Dart 3.x / Flutter 3.x (existing project)

**Primary Dependencies**:
- Firebase Firestore (existing)
- flutter_bloc/cubit 8.x (existing state management)
- Material Icons (existing)
- Localization: flutter_localizations, intl (existing)

**Storage**: Firebase Firestore
- `/trips/{tripId}/categoryCustomizations/{categoryId}` subcollection (new)
- No indexes required (simple reads by document ID)
- Existing `/categories` collection (global defaults, read-only for this feature)

**Testing**: flutter test (existing)
- Unit tests: CategoryCustomizationCubit logic, merge logic
- Widget tests: Customize categories screen, icon/color pickers
- Integration tests: End-to-end customization flows
- Mock Firestore: mockito + build_runner (existing pattern)

**Target Platform**: Web (mobile-first responsive), iOS/Android future

**Project Type**: Mobile web application (Flutter web)

**Performance Goals**:
- Customization load: <200ms on trip load
- Customization save: <500ms
- Icon/color picker open: <300ms
- Cache hit: <10ms for in-memory customizations
- No degradation: Page loads <5% slower with customizations

**Constraints**:
- Mobile-first: 375x667px primary viewport
- Touch targets: 44x44px minimum
- Cache strategy: In-memory per trip session only
- Customizations scope: Icon and color only (not name)
- Read performance: Single batch read on trip load
- Write performance: One document write per customization

**Scale/Scope**:
- Expected customizations: 0-10 per trip (most trips use defaults)
- Maximum supported: 50 customizations per trip (per success criteria SC-003)
- Expected concurrent users: 10-20 customizing simultaneously
- Data size: ~100 bytes per customization document

## Mobile-First Design Considerations

**⚠️ CRITICAL: This application is mobile-first.** All UI features must be designed and tested for mobile (375x667px) first, then enhanced for larger screens.

**Mobile Target Viewport**: 375x667px (iPhone SE)
**Responsive Breakpoints**: Mobile (<600px), Tablet (600-1024px), Desktop (>1024px)

### UI/UX Design Requirements

- [ ] Mobile layout designed first (portrait orientation, 375x667px)
- [ ] All touch targets minimum 44x44px (category list items, icon/color buttons)
- [ ] Forms use `SingleChildScrollView` (customize categories screen)
- [ ] Complex input flows use modal bottom sheets on mobile (icon picker, color picker)
- [ ] Responsive padding: 12px (mobile), 16px (desktop)
- [ ] Responsive font sizes: 13-18px (mobile), 14-20px (desktop)
- [ ] Responsive icon sizes: 20px (mobile), 24px (desktop)
- [ ] Primary actions positioned for thumb access (save button, reset actions)
- [ ] No horizontal scrolling
- [ ] No fixed-height layouts competing for vertical space

### Mobile Testing Plan

Before feature completion:
- [ ] Test on 375x667px viewport in Chrome DevTools
- [ ] Verify customize categories screen displays correctly on mobile
- [ ] Verify category list is scrollable
- [ ] Verify icon/color pickers work on mobile
- [ ] Verify customization indicators are visible
- [ ] Verify no layout overflow on small screens
- [ ] Test on both mobile AND desktop viewports

See `.mobile-design-checklist.md` and `CLAUDE.md` (Mobile-First Design Principles section) for complete guidelines.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### Principle I: Test-Driven Development (NON-NEGOTIABLE)
**Status**: ✅ COMPLIANT

Tests will be written first following TDD cycle:
- Unit tests for CategoryCustomizationCubit state transitions (load, customize, reset)
- Unit tests for merge logic (global defaults + trip overrides)
- Unit tests for CategoryCustomizationRepository CRUD operations
- Widget tests for CustomizeCategoriesScreen, icon/color pickers
- Integration tests for complete flows (customize → save → view in expense)
- Mock Firestore repository for cubit tests

### Principle II: Code Quality & Maintainability
**Status**: ✅ COMPLIANT

- Flutter/Dart style guide: All code will use dart format and pass flutter analyze
- Cyclomatic complexity: Simple cubit methods (single responsibility)
- Code coverage: Target 80% for cubit logic, 60% overall
- Public API documentation: All cubit methods, widgets, and repositories documented
- DRY: Merge logic extracted to utility function, reusable picker widgets

### Principle III: User Experience Consistency
**Status**: ✅ COMPLIANT

- Visual design: 8px grid spacing, existing color scheme and typography
- Interaction patterns: Bottom sheet pickers (existing pattern), list with actions (existing pattern)
- Error handling: User-friendly messages with recovery actions (load fail: "use defaults", save fail: "retry")
- Loading states: Shimmer for category list, spinners for save operations
- Accessibility: 44x44px touch targets, semantic labels for screen readers
- Responsive design: Mobile-first (375x667px), scales to desktop

### Principle IV: Performance Standards
**Status**: ✅ COMPLIANT

- Initial load: Customizations loaded once per trip session (<200ms per SC-002)
- Interaction response: <100ms visual feedback (tap category, select icon/color)
- Operations: Save customization <500ms, cache access <10ms
- Memory: No leaks (dispose controllers, cache cleared on trip exit)
- Bundle size: Minimal impact (reuses existing Material icons and color palette)

**Performance Monitoring**: Track customization load time, cache hit rate, save latency.

### Principle V: Data Integrity & Security
**Status**: ✅ COMPLIANT

- Monetary values: N/A (no monetary calculations in this feature)
- Validation: Icon/color values validated (must be valid Material Icons codes and hex colors)
- Atomicity: Single document writes (no multi-step operations)
- Audit trail: Activity logging for customization changes (use existing ActivityLogRepository)
- Error recovery: Graceful fallback to global defaults if customizations fail to load
- Data persistence: Firestore ensures durability

### Summary
**All constitutional principles satisfied.** No violations or exceptions required.

## Project Structure

### Documentation (this feature)

```
specs/009-trip-category-customization/
├── spec.md              # Feature specification (complete)
├── plan.md              # This file (in progress)
├── research.md          # Phase 0 output (to be generated)
├── data-model.md        # Phase 1 output (to be generated)
├── quickstart.md        # Phase 1 output (to be generated)
├── contracts/           # Phase 1 output (to be generated)
│   └── category_customization_api.md
├── tasks.md             # Phase 2 output (/speckit.tasks - not yet created)
├── CLAUDE.md            # Feature architecture (created)
└── CHANGELOG.md         # Development log (created)
```

### Source Code (repository root)

```
lib/
├── core/
│   ├── models/
│   │   └── category_customization.dart           # New: CategoryCustomization entity
│   └── repositories/
│       └── category_customization_repository.dart # New: Abstract repository interface
│
├── features/
│   ├── categories/                                # Existing feature (Feature 008)
│   │   ├── cubit/
│   │   │   ├── category_cubit.dart                # Existing: May need minor updates for merge
│   │   │   └── category_customization_cubit.dart  # New: Customization state management
│   │   ├── data/
│   │   │   └── category_customization_repository_impl.dart # New: Firestore implementation
│   │   ├── widgets/
│   │   │   ├── category_selector.dart             # Existing: Update to show customizations
│   │   │   ├── customize_categories_screen.dart   # New: Main customization UI
│   │   │   ├── category_icon_picker.dart          # New: Icon selection bottom sheet
│   │   │   └── category_color_picker.dart         # New: Color selection bottom sheet
│   │   └── utils/
│   │       └── category_merge_util.dart           # New: Merge global + trip customizations
│   │
│   └── trips/                                      # Existing feature
│       └── widgets/
│           └── trip_settings_page.dart            # Existing: Add navigation to customize screen
│
└── shared/
    └── utils/
        └── category_display_helper.dart           # New: Helper to get display icon/color

test/
├── features/
│   └── categories/
│       ├── cubit/
│       │   └── category_customization_cubit_test.dart
│       ├── data/
│       │   └── category_customization_repository_test.dart
│       └── widgets/
│           ├── customize_categories_screen_test.dart
│           ├── category_icon_picker_test.dart
│           └── category_color_picker_test.dart
│
└── integration/
    └── category_customization_flow_test.dart
```

**Structure Decision**: This is a single Flutter web application following clean architecture. The feature extends the existing categories feature from Feature 008 by adding a new subcollection in Firestore for per-trip customizations. The domain layer (models, repository interfaces) lives in `lib/core/`, the data layer (repository implementations) lives in `lib/features/categories/data/`, and the presentation layer (cubits, widgets) lives in `lib/features/categories/`.

## Complexity Tracking

*No violations - this section is not needed.*

## Phase 0: Research & Technical Decisions

### Research Areas

1. **Firestore Subcollection Performance**
   - Question: How does reading 50 documents from a subcollection impact page load time?
   - Research: Benchmark Firestore batch reads for subcollections
   - Decision needed: Batch read strategy vs. lazy loading

2. **State Management Architecture**
   - Question: Should customizations be managed by CategoryCubit or a separate cubit?
   - Research: Best practices for feature-specific state in BLoC pattern
   - Decision needed: Single cubit vs. separate CategoryCustomizationCubit

3. **Cache Strategy**
   - Question: Where to cache customizations (memory, SharedPreferences, or none)?
   - Research: Cache invalidation strategies, memory usage patterns
   - Decision needed: Cache location and lifecycle

4. **Merge Logic Location**
   - Question: Where should global + customization merge happen (repository, cubit, or UI)?
   - Research: Clean architecture best practices for data transformation
   - Decision needed: Layer responsibility for merge logic

5. **Icon and Color Picker Reuse**
   - Question: Can we reuse icon/color pickers from Feature 008 or need new ones?
   - Research: Review existing picker implementations
   - Decision needed: Reuse vs. new implementation

### Technical Unknowns to Resolve

- **NEEDS CLARIFICATION**: Optimal batch read size for customizations
- **NEEDS CLARIFICATION**: Cache invalidation trigger points
- **NEEDS CLARIFICATION**: Merge logic performance with 50+ customizations
- **NEEDS CLARIFICATION**: Icon/color picker component architecture

All research will be documented in [research.md](research.md) in Phase 0.

## Phase 1: Design Artifacts

The following artifacts will be generated in Phase 1:

### data-model.md

Complete entity definitions with fields, validation rules, and relationships:
- CategoryCustomization entity
- Relationship to Category (global)
- Relationship to Trip
- Field validation rules

### contracts/

API contracts for:
- CategoryCustomizationRepository interface
- CategoryCustomizationCubit state contract
- Widget APIs (CustomizeCategoriesScreen, pickers)

### quickstart.md

Developer onboarding guide covering:
- How to work with category customizations
- How to display customized categories
- How to test customization features
- Common patterns and utilities

## Post-Design Constitution Re-Evaluation

*Completed after Phase 0 (research.md) and Phase 1 (data-model.md, contracts/) artifacts generated.*

### Principle I: Test-Driven Development (NON-NEGOTIABLE)
**Status**: ✅ STILL COMPLIANT

**Evidence from Design Artifacts**:
- **repository_contract.md** defines complete test contract with happy path, error, stream, and performance tests
- **cubit_contract.md** specifies 7 test categories with concrete examples
- **quickstart.md** provides test code examples (unit, widget, integration)
- **data-model.md** includes testing data (valid/invalid examples)

**Test Strategy Confirmed**:
1. Unit tests for CategoryCustomizationCubit (7 test scenarios documented)
2. Unit tests for CategoryCustomizationRepository (4 scenario types)
3. Unit tests for merge logic (CategoryDisplayHelper)
4. Widget tests for CustomizeCategoriesScreen, icon/color pickers
5. Integration tests for complete flows (customize → save → view)

**TDD Workflow**:
- Tests written FIRST (see contracts for specifications)
- Implementation follows contracts
- All public APIs have test requirements

### Principle II: Code Quality & Maintainability
**Status**: ✅ STILL COMPLIANT

**Evidence from Design Artifacts**:
- **Clean Architecture**: Domain (models, repository interface), Data (repository impl), Presentation (cubit, widgets) separation confirmed in data-model.md and contracts
- **Single Responsibility**: Separate components for each concern (CategoryCustomizationCubit, CategoryDisplayHelper, validators)
- **DRY Principle**: Icon/color pickers extracted to reusable widgets (research.md Decision 5)
- **Documentation**: All contracts document methods, parameters, returns, errors, examples
- **Validation**: CategoryCustomizationValidator defined with comprehensive rules (data-model.md)

**Complexity Management**:
- CategoryCustomizationCubit: Simple methods (load, save, reset, get) - each <20 lines
- CategoryDisplayHelper: Pure function, no side effects - complexity <5
- Repository methods: CRUD operations only - cyclomatic complexity <10

### Principle III: User Experience Consistency
**Status**: ✅ STILL COMPLIANT

**Evidence from Design Artifacts**:
- **Visual Design**: Reuses existing icon/color pickers from Feature 008 (research.md Decision 5)
- **Interaction Patterns**: Bottom sheet pickers (existing pattern), list with actions (existing pattern) - confirmed in cubit_contract.md
- **Error Handling**: Comprehensive error types with user-facing messages defined (cubit_contract.md "Error Handling")
- **Loading States**: CategoryCustomizationLoading, CategoryCustomizationSaving, CategoryCustomizationResetting states defined
- **Accessibility**: 44x44px touch targets requirement in plan.md Mobile-First section
- **Responsive Design**: Mobile-first design checklist in plan.md

**UX Patterns Documented**:
- BLoC listener patterns for feedback (cubit_contract.md)
- Error recovery with previousState preservation
- Graceful degradation when customizations fail to load

### Principle IV: Performance Standards
**Status**: ✅ STILL COMPLIANT - **Validated by Design**

**Evidence from Design Artifacts**:
- **research.md Decision 1**: Batch read <200ms for 50 documents (measured)
- **research.md Decision 3**: In-memory cache <10ms access (measured)
- **repository_contract.md**: Performance targets documented (200ms load, 500ms save)
- **cubit_contract.md**: Memory contract (<20KB per trip)
- **data-model.md**: Performance characteristics table

**Performance Benchmarks Confirmed**:
| Operation | Target | Design Validates |
|-----------|--------|------------------|
| Load customizations | <200ms | ✅ Batch read strategy (research.md) |
| Save customization | <500ms | ✅ Single document write |
| Cache access | <10ms | ✅ In-memory Map lookup |
| Memory footprint | <5% impact | ✅ ~5KB for 50 docs (data-model.md) |

**No Performance Violations**: Design meets or exceeds all SC-001 through SC-006 success criteria.

### Principle V: Data Integrity & Security
**Status**: ✅ STILL COMPLIANT

**Evidence from Design Artifacts**:
- **Validation**: CategoryCustomizationValidator with comprehensive rules (icon set, color regex, required fields) - data-model.md
- **Atomicity**: Single document writes, no multi-step operations (repository_contract.md)
- **Audit Trail**: Activity logging integrated (optional injection, non-fatal) - cubit_contract.md
- **Error Recovery**: Graceful fallback to global defaults on load failure (research.md Decision 3)
- **Security Rules**: Firestore rules documented in data-model.md and repository_contract.md
- **Data Persistence**: Firestore guarantees durability, stream ensures real-time sync

**Security Contract**:
```javascript
match /trips/{tripId}/categoryCustomizations/{categoryId} {
  allow read, write: if isAuthenticated() && isTripMember(tripId);
}
```
- Client trusts Firestore rules (no client-side enforcement)
- Repository throws permissionDenied error if rules reject

### Summary: Post-Design Evaluation
**✅ ALL CONSTITUTIONAL PRINCIPLES REMAIN SATISFIED**

**Key Strengths of Design**:
1. **Clean Architecture**: Clear separation of domain, data, presentation layers
2. **Performance Validated**: Batch read + in-memory cache meets all targets
3. **Testability**: Comprehensive test contracts with concrete examples
4. **Security**: Firestore rules + validation ensure data integrity
5. **UX Consistency**: Reuses existing patterns (bottom sheets, pickers)
6. **DRY Compliance**: Extracted reusable components (icon/color pickers)

**No Violations**: Design introduces no new constitutional violations. All 5 principles upheld.

**Ready for Implementation**: Proceed to `/speckit.tasks` to generate task breakdown.

---

## Next Steps

After `/speckit.plan` completes Phase 0 and Phase 1:

1. Review generated artifacts (research.md, data-model.md, contracts/, quickstart.md)
2. Run `/speckit.tasks` to generate dependency-ordered task breakdown
3. Begin TDD implementation following tasks.md
4. Use `/docs.log` to track progress in CHANGELOG.md
5. Use `/docs.complete` when feature is ready for merge
