# Implementation Plan: Trip Multi-Currency Selection

**Branch**: `011-trip-multi-currency` | **Date**: 2025-11-02 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/011-trip-multi-currency/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

This feature extends the Trip entity to support multiple allowed currencies (1-10 currencies per trip) instead of a single baseCurrency. Users select currencies during trip creation/editing via a chip-based UI in a bottom sheet. Selected currencies filter the currency dropdown in expense forms, reducing cognitive load from 170+ options to 2-5 relevant currencies. Settlements are calculated independently per currency (no conversion). Existing trips are migrated from baseCurrency to allowedCurrencies via Firebase Cloud Functions.

**Primary requirement**: Allow trip organizers to pre-select 2-5 currencies for a trip, then filter expense form currency dropdowns to show only those currencies.

**Technical approach**: Update Trip domain model to include `List<CurrencyCode> allowedCurrencies`, create chip-based currency selector widget in trip settings (using existing CurrencySearchField for adding), filter expense form dropdowns to trip-allowed currencies, implement per-currency settlement views, and migrate existing trips server-side via Cloud Functions.

## Technical Context

**Language/Version**: Dart 3.9.0 with Flutter (SDK constraint: ^3.9.0)
**Primary Dependencies**: 
- Flutter SDK (flutter, flutter_localizations)
- Firebase: firebase_core ^3.8.1, cloud_firestore ^5.6.0, firebase_auth ^5.3.4, cloud_functions ^5.6.2
- State Management: flutter_bloc ^8.1.3, equatable ^2.0.5
- Testing: flutter_test, mockito ^5.4.4, build_runner ^2.4.7, bloc_test ^9.1.5

**Storage**: Cloud Firestore
- Trip documents: `allowedCurrencies` field (array of currency code strings)
- Legacy `baseCurrency` field retained during migration period
- Data model: `Trip.allowedCurrencies: List<CurrencyCode>` (domain), `allowedCurrencies: List<String>` (Firestore)

**Testing**: Flutter test framework
- Unit tests: Cubit logic, validation rules, migration logic
- Widget tests: MultiCurrencySelector UI, filtered dropdowns
- Integration tests: End-to-end trip creation with multiple currencies

**Target Platform**: Web (GitHub Pages primary), Mobile (iOS/Android future)

**Project Type**: Mobile-first web application (375x667px primary viewport)

**Performance Goals**: 
- Currency dropdown population: <100ms (SC-005)
- Trip currency update propagation: <500ms (SC-006)
- Currency selection process completion: <30s for 2-5 currencies (SC-001)
- Settlement calculation per currency: <2s for 100+ expenses (Constitution IV)

**Constraints**: 
- Mobile-first design: 375x667px iPhone SE viewport primary
- Maximum 10 currencies per trip (FR-004, prevent abuse)
- Minimum 1 currency per trip (FR-003)
- Backward compatibility: support legacy baseCurrency field during migration
- No currency conversion in Phase 1 (settlements per currency only)
- Touch targets minimum 44x44px

**Scale/Scope**: 
- Multi-currency selection UI (chip-based bottom sheet)
- Currency filtering in expense forms (reduce 170+ to 2-5 options)
- Per-currency settlement views (separate screen per currency)
- Cloud Functions migration for existing trips (server-side, non-blocking)
- Support reordering via up/down arrows (first currency = default)

## Mobile-First Design Considerations

**⚠️ CRITICAL: This application is mobile-first.** All UI features must be designed and tested for mobile (375x667px) first, then enhanced for larger screens.

**Mobile Target Viewport**: 375x667px (iPhone SE)
**Responsive Breakpoints**: Mobile (<600px), Tablet (600-1024px), Desktop (>1024px)

### UI/UX Design Requirements

- [x] Mobile layout designed first (portrait orientation, 375x667px)
  - Currency selection in modal bottom sheet (full-height on mobile)
  - Chip-based UI for selected currencies (horizontal wrap)
  - Up/down arrow buttons for reordering (44x44px touch targets)
  
- [x] All touch targets minimum 44x44px
  - Chip X buttons: 44x44px
  - Up/down arrow buttons: 44x44px
  - "Add Currency" button: full-width on mobile, min 44px height
  
- [x] Forms use `SingleChildScrollView` (keyboard-aware)
  - Bottom sheet content scrollable when keyboard appears
  - Chip list wraps vertically if needed
  
- [x] Complex input flows use modal bottom sheets on mobile
  - Entire currency selection interface in bottom sheet (not inline)
  - DraggableScrollableSheet for adjustable height
  
- [x] Responsive padding: 12px (mobile), 16px (desktop)
  - Bottom sheet padding: 12px on mobile, 16px on desktop
  - Chip spacing: 8px gap on mobile, 12px on desktop
  
- [x] Responsive font sizes: 13-18px (mobile), 14-20px (desktop)
  - Chip labels: 14px (mobile), 16px (desktop)
  - Button text: 16px (mobile), 18px (desktop)
  
- [x] Responsive icon sizes: 20px (mobile), 24px (desktop)
  - Chip X icons: 20px (mobile), 24px (desktop)
  - Arrow icons: 20px (mobile), 24px (desktop)
  
- [x] Primary actions positioned for thumb access (bottom/FAB)
  - "Add Currency" button at bottom of chip list (thumb-reachable)
  - "Save" button in bottom sheet footer (fixed position)
  
- [x] No horizontal scrolling
  - Chip list wraps to multiple rows
  - Bottom sheet width constrained to viewport
  
- [x] No fixed-height layouts competing for vertical space
  - Bottom sheet uses DraggableScrollableSheet (flexible height)
  - Currency list inside scrollable container

### Mobile Testing Plan

Before feature completion:
- [x] Test on 375x667px viewport in Chrome DevTools
- [x] Verify all text fields visible when keyboard appears (search in bottom sheet)
- [x] Verify forms are scrollable with keyboard open (bottom sheet scrolls)
- [x] Verify touch targets are easily tappable (44x44px minimum)
- [x] Verify no layout overflow on small screens (chips wrap properly)
- [x] Test on both mobile AND desktop viewports (responsive padding/sizing)

See `.mobile-design-checklist.md` and `CLAUDE.md` (Mobile-First Design Principles section) for complete guidelines.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### Principle I: Test-Driven Development (NON-NEGOTIABLE)
**Status**: ✅ PASS
- Plan includes TDD workflow: write tests first (unit, widget, integration)
- Test files specified in contracts (see Phase 1)
- Coverage requirements: 80% business logic, 60% overall

### Principle II: Code Quality & Maintainability
**Status**: ✅ PASS
- Follows Flutter/Dart style guide (linting enforced)
- DRY principle: reuses existing CurrencySearchField widget
- Documentation planned for all public APIs
- Complexity kept low (chip UI, simple validation logic)

### Principle III: User Experience Consistency
**Status**: ✅ PASS
- Consistent UI patterns: chip-based selection (matches Material Design)
- Reuses existing CurrencySearchField modal for adding currencies
- Error handling: validation errors with clear messages (min 1, max 10 currencies)
- Loading states: visual feedback for save operations
- Accessibility: 44x44px touch targets, semantic labels
- Responsive design: mobile-first (375x667px), scales to desktop

### Principle IV: Performance Standards
**Status**: ✅ PASS
- Dropdown population: <100ms (filtering in-memory array)
- Trip update propagation: <500ms (Firestore update + local cache)
- User interaction response: <100ms (chip add/remove immediate feedback)
- Settlement calculations: <2s for 100+ expenses (no change to existing logic)

### Principle V: Data Integrity & Security
**Status**: ✅ PASS
- Validation: 1-10 currencies enforced client and server (Firestore rules)
- Atomicity: currency list updates are atomic (Firestore transaction)
- Audit trail: activity logging for currency changes (optional Phase 2)
- Data persistence: allowedCurrencies synced to Firestore
- Error recovery: legacy baseCurrency fallback during migration
- Backward compatibility: existing expenses preserve original currency

**Summary**: All constitution principles satisfied. No violations to justify.

## Project Structure

### Documentation (this feature)

```
specs/011-trip-multi-currency/
├── spec.md              # Feature specification (input)
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (UI patterns, migration strategy)
├── data-model.md        # Phase 1 output (Trip entity, Firestore schema)
├── quickstart.md        # Phase 1 output (developer setup guide)
├── contracts/           # Phase 1 output (widget/repository contracts)
│   ├── currency-selector-widget.md
│   ├── trip-repository.md
│   └── cloud-function.md
├── CLAUDE.md            # Feature architecture documentation (/docs.create)
└── CHANGELOG.md         # Development log (/docs.log)
```

### Source Code (repository root)

```
lib/
├── features/
│   ├── trips/
│   │   ├── domain/
│   │   │   ├── models/
│   │   │   │   └── trip.dart  (UPDATE: add allowedCurrencies field)
│   │   │   └── repositories/
│   │   │       └── trip_repository.dart  (UPDATE: add getAllowedCurrencies/updateAllowedCurrencies methods)
│   │   ├── data/
│   │   │   ├── models/
│   │   │   │   └── trip_model.dart  (UPDATE: serialize allowedCurrencies array)
│   │   │   └── repositories/
│   │   │       └── trip_repository_impl.dart  (UPDATE: implement new methods, handle legacy baseCurrency)
│   │   └── presentation/
│   │       ├── pages/
│   │       │   └── trip_settings_page.dart  (UPDATE: add currency management section)
│   │       └── widgets/
│   │           └── multi_currency_selector.dart  (NEW: chip-based UI with reordering)
│   ├── expenses/
│   │   └── presentation/
│   │       └── pages/
│   │           └── expense_form_page.dart  (UPDATE: filter currency dropdown to allowedCurrencies)
│   └── settlements/
│       └── presentation/
│           └── pages/
│               └── settlements_page.dart  (UPDATE: show per-currency settlements - Phase 2)
├── shared/
│   └── widgets/
│       └── currency_search_field.dart  (REUSE: for adding currencies to chip list)
└── core/
    └── models/
        └── currency_code.dart  (EXISTING: no changes)

test/
├── features/
│   └── trips/
│       ├── domain/
│       │   └── models/
│       │       └── trip_test.dart  (NEW: test allowedCurrencies validation)
│       ├── data/
│       │   └── repositories/
│       │       └── trip_repository_impl_test.dart  (UPDATE: test new methods, migration logic)
│       └── presentation/
│           └── widgets/
│               └── multi_currency_selector_test.dart  (NEW: widget tests)
└── integration/
    └── multi_currency_trip_test.dart  (NEW: end-to-end test)

functions/  (Firebase Cloud Functions - separate Node.js project)
├── src/
│   └── migrations/
│       └── migrate-trip-currencies.ts  (NEW: migrate baseCurrency → allowedCurrencies)
├── package.json  (NEW: Cloud Functions dependencies)
└── tsconfig.json  (NEW: TypeScript config)
```

**Structure Decision**: This is a single Flutter web/mobile project with modular feature structure. The Cloud Functions migration is a separate Node.js/TypeScript project deployed to Firebase (not part of the Flutter codebase). The Flutter app follows clean architecture with domain/data/presentation layers per feature.

## Complexity Tracking

*Fill ONLY if Constitution Check has violations that must be justified*

No violations - this section is empty.

## Phase 0: Research

See [research.md](research.md) for complete research output.

### Key Decisions

**UI Pattern**: Chip-based selection with bottom sheet
- Selected currencies displayed as removable chips
- Up/down arrows for reordering (first = default)
- "Add Currency" button opens existing CurrencySearchField modal
- Rationale: Mobile-friendly, clear visual feedback, reuses existing component

**Migration Strategy**: Firebase Cloud Functions (server-side)
- One-time migration job triggered manually or scheduled
- Iterates all trips, adds allowedCurrencies = [baseCurrency]
- Rationale: Non-blocking for users, atomic server-side processing

**Settlement Architecture**: Per-currency settlements (no conversion)
- Separate settlement screen per allowed currency
- Future enhancement: unified view with exchange rates
- Rationale: Simpler implementation, no external API dependencies

**Data Model**: Array field in Trip document
- `allowedCurrencies: List<String>` in Firestore
- First element = default currency for new expenses
- Rationale: Firestore arrays efficient, simple ordering mechanism

## Phase 1: Design Artifacts

### A. Data Model

See [data-model.md](data-model.md) for complete data model specification.

**Summary**:
- Trip entity: add `List<CurrencyCode> allowedCurrencies` field
- Firestore schema: `allowedCurrencies: array<string>`
- Validation: 1-10 currencies, no duplicates, valid ISO 4217 codes
- Migration: `baseCurrency → allowedCurrencies = [baseCurrency]`

### B. Contracts

See [contracts/](contracts/) directory for complete contracts.

**Widget Contract**: [contracts/currency-selector-widget.md](contracts/currency-selector-widget.md)
- MultiCurrencySelector widget specification
- Input/output parameters, validation, UI behavior

**Repository Contract**: [contracts/trip-repository.md](contracts/trip-repository.md)
- Updated TripRepository interface
- New methods: getAllowedCurrencies, updateAllowedCurrencies
- Legacy baseCurrency handling

**Cloud Function Contract**: [contracts/cloud-function.md](contracts/cloud-function.md)
- Migration function specification
- Trigger mechanism, processing logic, error handling

### C. Quickstart

See [quickstart.md](quickstart.md) for developer setup guide.

**Summary**:
- Local development setup for multi-currency testing
- Firebase Functions emulator setup for migration testing
- Test data creation scripts

## Phase 2: Task Generation

Tasks will be generated in the next phase via `/speckit.tasks` command.

Expected task categories:
1. **Data Layer**: Update Trip model, TripModel serialization, repository implementation
2. **Presentation Layer**: MultiCurrencySelector widget, trip settings integration, expense form filtering
3. **Migration**: Cloud Functions setup, migration script, deployment
4. **Testing**: Unit tests, widget tests, integration tests
5. **Documentation**: Update CLAUDE.md, feature docs, changelog

## Implementation Workflow

### Development Process

1. **Setup** (Phase 0):
   - Review research.md for design decisions
   - Review data-model.md for entity changes
   - Review contracts for API specifications
   - Setup Firebase Functions development environment (see quickstart.md)

2. **TDD Cycle** (Phase 2):
   - Write failing tests for Trip model validation (1-10 currencies, no duplicates)
   - Implement Trip.allowedCurrencies field and validation
   - Write tests for TripModel serialization (Firestore array ↔ List<CurrencyCode>)
   - Implement serialization logic
   - Write tests for MultiCurrencySelector widget (chip add/remove, reorder, validation)
   - Implement widget UI and behavior
   - Continue TDD for all components

3. **Integration** (Phase 2):
   - Connect MultiCurrencySelector to trip settings page
   - Filter expense form currency dropdown
   - Test end-to-end flow (create trip → select currencies → create expense)

4. **Migration** (Phase 2):
   - Write tests for migration logic (baseCurrency → allowedCurrencies)
   - Implement Cloud Function migration script
   - Test migration on local Firestore emulator
   - Deploy to production after manual verification

5. **Documentation** (Throughout):
   - Use `/docs.log` after completing significant work
   - Use `/docs.update` when modifying architecture
   - Use `/docs.complete` when feature is ready for merge

### Testing Strategy

**Unit Tests**:
- Trip model: allowedCurrencies validation (min 1, max 10, no duplicates)
- TripModel: Firestore serialization (array ↔ List<CurrencyCode>)
- Migration logic: baseCurrency → allowedCurrencies conversion
- Coverage: 80% for business logic

**Widget Tests**:
- MultiCurrencySelector: chip rendering, add/remove, reordering
- Expense form: currency dropdown filtered to allowedCurrencies
- Trip settings: currency section display
- Coverage: 60% overall

**Integration Tests**:
- End-to-end: create trip with 3 currencies → create expense → verify dropdown shows only 3
- Migration: create legacy trip → run migration → verify allowedCurrencies set
- Settlement: create expenses in multiple currencies → verify per-currency settlements

**Performance Tests**:
- Currency dropdown population: <100ms (measure with stopwatch in test)
- Trip update propagation: <500ms (measure Firestore write + UI update)

### Deployment Plan

**Branch Strategy**:
- Feature branch: `011-trip-multi-currency`
- PR to `master` after all tests pass and `/review` complete
- Auto-deploy to GitHub Pages on merge

**Migration Execution**:
1. Deploy Cloud Function to Firebase (production)
2. Test on staging environment (create legacy trip, run migration)
3. Run migration manually via Firebase Console or scheduled trigger
4. Monitor migration logs for errors
5. Verify all trips have allowedCurrencies field (Firestore query)

**Rollback Plan**:
- If migration fails: Cloud Function logs provide trip IDs for manual fix
- If UI breaks: revert PR, fix issues in feature branch, re-deploy
- Legacy baseCurrency field retained (backward compatibility during rollout)

## Risk Assessment

| Risk | Impact | Mitigation |
|------|--------|------------|
| Migration fails for some trips | High | Cloud Function logs errors per trip; manual fix script available; legacy baseCurrency fallback in app |
| Performance degradation (filtering) | Medium | In-memory array filtering <100ms; pre-test with 170+ currencies |
| User confusion (reordering mechanism) | Low | Clear UI labels "First currency is default"; help text in trip settings |
| Breaking change (API) | Low | Backward compatible: legacy baseCurrency handled in repository layer |
| Cloud Functions cost | Low | One-time migration; minimal ongoing cost for maintenance |

## Success Metrics

From spec.md Success Criteria:

- **SC-001**: Users can select 2-5 currencies in <30 seconds
  - Measure: Manual testing with stopwatch, user feedback
  
- **SC-002**: Dropdown reduced from 170+ to 2-5 currencies
  - Measure: Verify filtered list length in integration tests
  
- **SC-003**: 100% migration without data loss
  - Measure: Firestore query count before/after, verify all trips have allowedCurrencies
  
- **SC-004**: Per-currency settlements accurate
  - Measure: Unit tests for settlement calculations per currency
  
- **SC-005**: Dropdown loads in <100ms
  - Measure: Performance test with stopwatch, average over 10 runs
  
- **SC-006**: Currency changes reflected in <500ms
  - Measure: Measure Firestore write latency + UI update time

## Next Steps

1. **Review this plan** with project owner for approval
2. **Run `/speckit.tasks`** to generate dependency-ordered task breakdown
3. **Run `/docs.create`** to initialize feature documentation (CLAUDE.md, CHANGELOG.md)
4. **Begin implementation** following TDD workflow
5. **Update agent context** after plan approval (see below)

## Agent Context Update

After approving this plan, run:
```bash
.specify/scripts/bash/update-agent-context.sh claude
```

This updates `.claude/memory/agent-context.md` with:
- New technologies: Cloud Functions migration pattern
- New patterns: Chip-based multi-select UI, array field reordering
- New testing approaches: Cloud Functions emulator testing

---

**Plan Version**: 1.0 | **Created**: 2025-11-02 | **Status**: Draft
