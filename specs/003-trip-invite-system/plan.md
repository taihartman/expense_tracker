# Implementation Plan: Trip Invite System

**Branch**: `003-trip-invite-system` | **Date**: 2025-10-28 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/003-trip-invite-system/spec.md`

## Summary

Implement a trip invite system that transforms the expense tracker from a fully public application to one with private, membership-based trips. Users will join trips via permanent invite codes (trip IDs) or shareable links, provide their name upon joining, and view a transparent activity log of all trip actions. The system maintains backward compatibility with existing trips while adding privacy controls that restrict trip visibility to members only.

**Technical Approach**: Leverage existing Firebase anonymous authentication and per-trip participant lists. Use trip ID as the permanent invite code (no additional field needed). Add membership checking to Firestore security rules and Flutter state management. Implement activity log as a Firestore subcollection with real-time streaming. Extend existing routing to support `/trips/:tripId/join` deep linking.

## Technical Context

**Language/Version**: Dart 3.0+ with Flutter SDK 3.9.0+
**Primary Dependencies**:
- `cloud_firestore` ^5.5.0 (database and real-time sync)
- `firebase_auth` ^5.3.2 (anonymous authentication)
- `flutter_bloc` ^8.1.6 (state management via Cubit pattern)
- `go_router` ^14.6.2 (routing and deep linking)

**Storage**: Cloud Firestore (NoSQL document database)
- Top-level collections: `/trips`, `/expenses`, `/categories`, `/exchangeRates`, `/settlementSummaries`
- New subcollection: `/trips/{tripId}/activityLog` for action history

**Testing**: `flutter test` with widget tests, unit tests, and integration tests
- Existing coverage: ~60% overall, 80%+ for business logic
- Target: Maintain 80%+ coverage for new membership and activity log logic

**Target Platform**: Web (Flutter for web, Chrome/Safari/Firefox)
- Deployment: GitHub Pages at https://{username}.github.io/expense_tracker/
- Responsive design: 320px to 4K displays

**Project Type**: Flutter mobile/web (single codebase)
- Architecture: Feature-driven with BLoC/Cubit state management
- Current features: trips, expenses, settlements, itemized-expenses

**Performance Goals**:
- Join trip: <2 seconds from link click to trip view
- Activity log load: <1 second for 100 entries
- Membership check: <100ms (cached in TripCubit state)
- Deep link navigation: <500ms

**Constraints**:
- Anonymous authentication only (no user accounts)
- Client-side membership tracking via browser storage (SharedPreferences)
- Backward compatibility: existing trips must work without migration
- No server-side API: all logic in Flutter + Firestore security rules

**Scale/Scope**:
- Expected: 10-50 trips per user
- Activity log: 100-1000 entries per trip
- Concurrent users per trip: 2-10 members
- Real-time sync: activity log updates within 2 seconds

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### I. Test-Driven Development ✅

**Compliance**: PASS
- Plan includes test requirements for membership logic, activity log operations, and join flow
- Will follow TDD cycle: write failing tests for `ActivityLogRepository`, `TripCubit.joinTrip()`, membership validation
- Existing test structure supports widget tests, unit tests, integration tests

**Gate Status**: Proceed to Phase 0

### II. Code Quality & Maintainability ✅

**Compliance**: PASS
- Leverages existing patterns: Cubit-based state management, Repository pattern, Model-Repository-Cubit layers
- No new architectural patterns introduced (maintains consistency)
- Reuses existing `Participant` model and `TripCubit` (extends rather than duplicates)
- Public APIs will have dartdoc comments
- Targets: 80% coverage for business logic (membership checks, activity logging)

**Gate Status**: Proceed to Phase 0

### III. User Experience Consistency ✅

**Compliance**: PASS
- Follows existing design patterns: bottom sheets (participant form), list pages (trip list), settings pages
- Error handling: user-friendly messages for invalid codes ("Trip not found"), already-member ("You've already joined this trip")
- Loading states: show shimmer during membership check, activity log load
- Accessibility: standard Material Design components with semantic labels
- Responsive: inherits existing 8px grid, typography, color scheme

**Gate Status**: Proceed to Phase 0

### IV. Performance Standards ✅

**Compliance**: PASS
- Join flow: <2 seconds (within <2s page load standard on 3G)
- Membership check: <100ms (cached in state, no network call per navigation)
- Activity log: real-time stream, lazy load 50 most recent entries initially
- Bundle size impact: +15KB estimated (ActivityLog model + repository + cubit + 2 pages)

**Gate Status**: Proceed to Phase 0

### V. Data Integrity & Security ✅

**Compliance**: PASS
- Membership validation: enforced in Firestore security rules + client-side checks
- Activity log: append-only (no edits/deletes to preserve audit trail)
- Atomicity: trip join is atomic (add participant + create activity log entry in single operation)
- Error recovery: graceful handling of "trip not found", "already member", "network error"
- Backward compatibility: existing trips accessible via trip ID (no data loss)

**Gate Status**: Proceed to Phase 0

### Constitution Compliance Summary

**Overall Status**: ✅ PASS - All 5 core principles satisfied

**Justification**:
- Feature extends existing architecture without introducing complexity
- Leverages established patterns (Cubit, Repository, Firestore subcollections)
- Maintains test coverage and code quality standards
- Preserves UX consistency and performance benchmarks
- Ensures data integrity via audit log and validation

**Post-Design Re-Check Required**: Yes, after Phase 1 (verify contracts and data model maintain compliance)

---

## Constitution Check - Post-Design Verification

*Re-evaluated after Phase 1 (Research & Design) completion*

### I. Test-Driven Development ✅

**Post-Design Compliance**: PASS
- Research and contracts define testable units:
  - `ActivityLogRepository` (unit tests defined in cubit-contracts.md)
  - `TripCubit.joinTrip()` (test cases documented)
  - `ActivityLogCubit` (state transition tests specified)
- Testing strategy documented in research.md (unit, widget, integration tests)
- Test coverage targets maintained: 80% for business logic

**Verified**: Design supports TDD workflow

---

### II. Code Quality & Maintainability ✅

**Post-Design Compliance**: PASS
- Data model clean and simple (1 new entity, 1 enum)
- Repository pattern maintained consistently
- Cubit pattern extended without deviation
- No architectural complexity introduced
- Public APIs documented in contracts

**Verified**: Design maintains code quality standards

---

### III. User Experience Consistency ✅

**Post-Design Compliance**: PASS
- Routing follows existing patterns (go_router with guards)
- UI components reuse existing widgets (bottom sheets, lists)
- Error handling standardized (localized strings in app_en.arb)
- Navigation flows documented in routing-contracts.md
- Loading states specified (shimmer, CircularProgressIndicator)

**Verified**: Design preserves UX consistency

---

### IV. Performance Standards ✅

**Post-Design Compliance**: PASS
- Activity log queries optimized (limit 50, indexed by timestamp)
- Membership checks cached (LocalStorageService)
- Real-time sync via Firestore streams (<2s latency)
- Bundle size impact minimal (+15KB estimated)
- Query performance documented: <200ms for 50 entries

**Verified**: Design meets performance standards

---

### V. Data Integrity & Security ✅

**Post-Design Compliance**: PASS
- Activity log immutable (firestore.rules: no update/delete)
- Firestore security rules enforce membership (defined in firestore-schema.md)
- Join operation atomic (participant + log in sequence, acceptable trade-off)
- Timestamp server-side (request.time validation)
- Audit trail preserved (append-only logs)

**Verified**: Design ensures data integrity

---

### Post-Design Constitution Summary

**Overall Status**: ✅ PASS - All 5 core principles maintained after design

**Design Quality**:
- Contracts are complete and implementation-ready
- No architectural compromises made
- All constitution gates remain green
- Ready for task generation and implementation

**Next Phase**: Proceed to `/speckit.tasks` for task breakdown

## Project Structure

### Documentation (this feature)

```
specs/003-trip-invite-system/
├── spec.md              # Feature specification
├── plan.md              # This file (/speckit.plan output)
├── research.md          # Phase 0 output (technical decisions)
├── data-model.md        # Phase 1 output (entities and relationships)
├── quickstart.md        # Phase 1 output (how to use/test feature)
├── contracts/           # Phase 1 output (Firestore schema, state contracts)
│   ├── firestore-schema.md
│   ├── cubit-contracts.md
│   └── routing-contracts.md
├── checklists/          # Quality validation checklists
│   └── requirements.md  # Spec quality checklist (completed)
├── CLAUDE.md            # Feature-specific development guide (created via /docs.create)
└── CHANGELOG.md         # Development log (updated via /docs.log)
```

### Source Code (repository root)

```
lib/
├── core/
│   ├── models/
│   │   └── participant.dart              # [EXISTING] Reused for membership
│   ├── router/
│   │   └── app_router.dart               # [MODIFIED] Add join routes
│   └── services/
│       ├── firestore_service.dart        # [EXISTING] Reused
│       └── local_storage_service.dart    # [MODIFIED] Store joined trip IDs
│
├── features/
│   ├── trips/
│   │   ├── domain/
│   │   │   ├── models/
│   │   │   │   ├── trip.dart             # [EXISTING] Already has participants list
│   │   │   │   └── activity_log.dart     # [NEW] Activity log entry model
│   │   │   └── repositories/
│   │   │       ├── trip_repository.dart  # [MODIFIED] Add membership methods
│   │   │       └── activity_log_repository.dart  # [NEW]
│   │   │
│   │   ├── data/
│   │   │   ├── models/
│   │   │   │   └── activity_log_model.dart  # [NEW] JSON serialization
│   │   │   └── repositories/
│   │   │       ├── trip_repository_impl.dart     # [MODIFIED] Implement membership
│   │   │       └── activity_log_repository_impl.dart  # [NEW]
│   │   │
│   │   └── presentation/
│   │       ├── cubits/
│   │       │   ├── trip_cubit.dart          # [MODIFIED] Filter to joined trips, add joinTrip()
│   │       │   ├── trip_state.dart          # [MODIFIED] Add joining state
│   │       │   ├── activity_log_cubit.dart  # [NEW]
│   │       │   └── activity_log_state.dart  # [NEW]
│   │       │
│   │       ├── pages/
│   │       │   ├── trip_list_page.dart      # [MODIFIED] Add "Join Trip" button
│   │       │   ├── trip_join_page.dart      # [NEW] Code entry + deep link landing
│   │       │   ├── trip_invite_page.dart    # [NEW] Show code, copy, share
│   │       │   └── trip_settings_page.dart  # [MODIFIED] Add activity log tab
│   │       │
│   │       └── widgets/
│   │           ├── activity_log_list.dart   # [NEW] Activity feed widget
│   │           └── activity_log_item.dart   # [NEW] Single log entry card
│   │
│   └── expenses/
│       └── presentation/
│           └── cubits/
│               └── expense_cubit.dart       # [MODIFIED] Log expense actions
│
├── l10n/
│   └── app_en.arb                           # [MODIFIED] Add invite/activity strings
│
└── main.dart                                # [MODIFIED] Register ActivityLogCubit

test/
├── features/
│   └── trips/
│       ├── domain/
│       │   └── repositories/
│       │       └── activity_log_repository_test.dart  # [NEW]
│       │
│       └── presentation/
│           ├── cubits/
│           │   ├── trip_cubit_test.dart     # [MODIFIED] Test membership filtering
│           │   └── activity_log_cubit_test.dart  # [NEW]
│           │
│           ├── pages/
│           │   └── trip_join_page_test.dart  # [NEW] Widget tests
│           │
│           └── widgets/
│               └── activity_log_list_test.dart  # [NEW] Widget tests
│
└── integration/
    └── trip_join_flow_test.dart             # [NEW] End-to-end join test

firestore.rules                              # [MODIFIED] Add membership validation
```

**Structure Decision**: Flutter feature-driven architecture with domain-data-presentation layers. This feature integrates into the existing `trips` feature module, adding new domain models (ActivityLog), repositories (ActivityLogRepository), cubits (ActivityLogCubit), and pages (TripJoinPage, TripInvitePage). Follows established patterns: Cubit for state, Repository for data access, separation of domain and data layers. Modifications to existing files are minimal and focused (add methods, not refactor).

## Complexity Tracking

*No violations - all Constitution gates passed.*

This feature introduces no architectural complexity beyond existing patterns:
- ✅ Uses existing Cubit-based state management
- ✅ Uses existing Repository pattern
- ✅ Uses existing Firestore subcollection pattern
- ✅ Uses existing routing (go_router) with new routes
- ✅ No new external dependencies
- ✅ No new design patterns

**Simplicity Score**: Low complexity addition (extends existing system cleanly)
