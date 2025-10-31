# Implementation Plan: Per-Trip Category Visual Customization

**Branch**: `009-trip-category-customization` | **Date**: 2025-10-31 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/009-trip-category-customization/spec.md`

## Summary

This feature enables users to customize category icons and colors on a per-trip basis while maintaining a global category system. Additionally, it implements:
- **Icon System Improvements**: Type-safe CategoryIcon enum, shared IconHelper utility to eliminate code duplication, and full support for all 30 Material Icons
- **Voting System**: Seamless crowd-sourced improvement of global category icons through implicit voting when users customize icons
- **Duplicate Prevention**: Similar category detection using fuzzy matching to reduce category fragmentation

**Technical Approach**: Clean architecture with presentation layer (Cubit state management), domain layer (entities and contracts), and data layer (Firestore repository). Icon voting operates silently through existing customization flows.

## Technical Context

**Language/Version**: Dart 3.x with Flutter 3.x
**Primary Dependencies**: flutter_bloc (state management), cloud_firestore (persistence), equatable (value equality), decimal (currency precision), string_similarity (fuzzy matching)
**Storage**: Firebase Firestore (global categories, category customizations, icon preferences)
**Testing**: flutter_test, mockito (mocking), bloc_test (cubit testing)
**Target Platform**: Web (Chrome, deployed to GitHub Pages), iOS/Android support planned
**Project Type**: Mobile-first Flutter web application
**Performance Goals**: <200ms for customization operations, <2s for initial category load, 60fps animations
**Constraints**: Firebase free tier (no backend code), offline-first not required, real-time sync within 1s
**Scale/Scope**: Up to 50 categories per trip, 100+ expenses per trip, 10+ concurrent trips per user

## Mobile-First Design Considerations

**⚠️ CRITICAL: This application is mobile-first.** All UI features must be designed and tested for mobile (375x667px) first, then enhanced for larger screens.

**Mobile Target Viewport**: 375x667px (iPhone SE)
**Responsive Breakpoints**: Mobile (<600px), Tablet (600-1024px), Desktop (>1024px)

### UI/UX Design Requirements

- [x] Mobile layout designed first (portrait orientation, 375x667px)
- [x] All touch targets minimum 44x44px (icon picker grid, reset buttons)
- [x] Forms use `SingleChildScrollView` (keyboard-aware customization screens)
- [x] Complex input flows use modal bottom sheets on mobile (icon picker, color picker)
- [x] Responsive padding: 12px (mobile), 16px (desktop)
- [x] Responsive font sizes: 13-18px (mobile), 14-20px (desktop)
- [x] Responsive icon sizes: 20px (mobile), 24px (desktop)
- [x] Primary actions positioned for thumb access (bottom sheet actions)
- [x] No horizontal scrolling (6-column icon grid responsive)
- [x] No fixed-height layouts competing for vertical space

### Mobile Testing Plan

Before feature completion:
- [x] Test on 375x667px viewport in Chrome DevTools
- [x] Verify all text fields visible when keyboard appears
- [x] Verify forms are scrollable with keyboard open
- [x] Verify touch targets are easily tappable
- [x] Verify no layout overflow on small screens
- [x] Test on both mobile AND desktop viewports

See `.mobile-design-checklist.md` and `CLAUDE.md` (Mobile-First Design Principles section) for complete guidelines.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### Initial Check (Pre-Design)

| Principle | Status | Notes |
|-----------|--------|-------|
| **I. Test-Driven Development** | ✅ PASS | Tests written before implementation for all cubits, repositories, and widgets |
| **II. Code Quality & Maintainability** | ✅ PASS | DRY principle enforced via IconHelper utility; code duplication eliminated |
| **III. User Experience Consistency** | ✅ PASS | Consistent icon/color picker patterns; visual indicators for customizations; 44x44px touch targets |
| **IV. Performance Standards** | ✅ PASS | Customization operations <200ms; voting operations non-blocking; fuzzy matching optimized |
| **V. Data Integrity & Security** | ✅ PASS | Firestore transactions for vote updates; graceful fallback to defaults; validation at cubit layer |

**Overall**: ✅ NO VIOLATIONS - Feature aligns with all constitutional principles.

### Post-Design Check (After Phase 1)

*Will be updated after Phase 1 design completion*

## Project Structure

### Documentation (this feature)

```
specs/009-trip-category-customization/
├── spec.md              # Feature specification (user stories, requirements)
├── plan.md              # This file (implementation plan)
├── research.md          # Phase 0: Technical research and decisions
├── data-model.md        # Phase 1: Entity models and relationships
├── quickstart.md        # Phase 1: Developer onboarding guide
├── contracts/           # Phase 1: API contracts (Firestore schema)
├── CLAUDE.md            # Architecture documentation (live)
├── CHANGELOG.md         # Development log (live)
└── tasks.md             # Phase 2: Task breakdown (pending)
```

### Source Code (repository root)

```
lib/
├── core/
│   ├── enums/
│   │   └── category_icon.dart                    # NEW: Type-safe icon enum (30 icons)
│   ├── models/
│   │   └── category_customization.dart           # Existing: Trip-specific customization
│   ├── validators/
│   │   └── category_customization_validator.dart # Enhanced: Enum-based validation
│   └── services/
│       └── category_icon_updater_service.dart    # NEW: Voting logic and icon updates
│
├── shared/
│   └── utils/
│       ├── icon_helper.dart                      # NEW: Shared icon utilities
│       └── category_display_helper.dart          # Existing: Display merging logic
│
├── features/
│   └── categories/
│       ├── domain/
│       │   ├── models/
│       │   │   ├── category.dart                 # Enhanced: iconEnum getter
│       │   │   └── category_icon_preference.dart # NEW: Voting data model
│       │   └── repositories/
│       │       ├── category_repository.dart
│       │       └── category_customization_repository.dart
│       │
│       ├── data/
│       │   ├── models/
│       │   │   ├── category_model.dart
│       │   │   ├── category_customization_model.dart
│       │   │   └── category_icon_preference_model.dart # NEW: Firestore serialization
│       │   └── repositories/
│       │       ├── category_repository_impl.dart           # Enhanced: Similar category detection
│       │       └── category_customization_repository_impl.dart # Enhanced: Vote recording
│       │
│       └── presentation/
│           ├── cubit/
│           │   ├── category_cubit.dart                # Enhanced: Enum-based icon handling
│           │   └── category_customization_cubit.dart  # Enhanced: Vote triggering
│           └── widgets/
│               ├── category_icon_picker.dart          # Enhanced: Dynamic from enum
│               ├── category_selector.dart             # Enhanced: Use IconHelper
│               ├── category_browser_bottom_sheet.dart # Enhanced: Use IconHelper
│               ├── category_creation_bottom_sheet.dart # Enhanced: Similar category warnings
│               └── customize_categories_screen.dart   # Enhanced: Use IconHelper
│
└── l10n/
    └── app_en.arb                                # Enhanced: Voting/similarity strings

test/
├── features/categories/
│   ├── domain/models/
│   │   └── category_icon_preference_test.dart   # NEW
│   ├── data/repositories/
│   │   └── category_customization_repository_test.dart # Enhanced: Vote tests
│   └── presentation/
│       ├── cubit/
│       │   └── category_customization_cubit_test.dart # Enhanced
│       └── widgets/
│           ├── category_icon_picker_test.dart
│           └── category_creation_bottom_sheet_test.dart # Enhanced: Similarity tests
│
├── shared/utils/
│   └── icon_helper_test.dart                    # NEW
│
└── integration/
    ├── category_customization_flow_test.dart
    └── icon_voting_flow_test.dart               # NEW
```

**Structure Decision**: Flutter clean architecture with three layers (Presentation/Domain/Data). New icon system components live in `core/enums/` and `shared/utils/`. Voting infrastructure added to existing category feature module. Fuzzy matching for similar category detection implemented in repository layer.

## Complexity Tracking

*No constitutional violations requiring justification.*

This feature maintains clean architecture principles, follows TDD practices, and enhances existing code quality by eliminating duplication.

---

**Next Steps**:
1. ✅ Phase 0: Complete research.md (fuzzy matching algorithms, enum best practices)
2. ✅ Phase 1: Complete data-model.md and contracts/ (Firestore schema for voting)
3. ⏳ Phase 2: Generate tasks.md via `/speckit.tasks`
4. ⏳ Implementation: Execute tasks following TDD cycle
