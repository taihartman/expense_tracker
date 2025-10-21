# Implementation Plan: Group Expense Tracker for Trips

**Branch**: `001-group-expense-tracker` | **Date**: 2025-10-21 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/001-group-expense-tracker/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

Implement a multi-currency group expense tracking application for trips that allows users to record expenses, split costs among participants, and calculate optimal settlement plans. The system will support USD and VND currencies with manual exchange rate management, compute pairwise debt netting and minimal settlement transfers, and provide visual dashboards with category-based spending analytics.

**Technical Approach**: Flutter web application with Firebase backend (Firestore for data, Cloud Functions for serverless compute). Client handles UI/UX and real-time data sync; server-side functions ensure consistent settlement calculations across all clients.

## Technical Context

**Language/Version**: Dart 3.9.0 / Flutter 3.35.1
**Primary Dependencies**: flutter_bloc (state management), cloud_firestore (database), firebase_auth (anonymous auth), firebase_functions (serverless compute), decimal (precise monetary calculations), fl_chart (data visualization), intl (formatting), go_router (navigation)
**Storage**: Firebase Firestore (NoSQL document database with real-time sync)
**Testing**: flutter_test (unit/widget tests), integration_test (e2e flows), golden tests (visual regression)
**Target Platform**: Web (Chrome, Safari, Firefox, Edge - responsive 320px to 4K)
**Project Type**: Web application (single Flutter web project + Firebase backend)
**Performance Goals**: <2s initial load on 3G, <100ms UI response, <2s settlement calculation for 100+ expenses, <500KB gzipped bundle
**Constraints**: 80% code coverage for business logic (60% overall), cyclomatic complexity ≤10, zero lint warnings, Decimal type for all monetary values (no floating point)
**Scale/Scope**: MVP targets 6 fixed users per trip, 100+ expenses per trip, multiple concurrent trips, real-time multi-device sync

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### Pre-Design Check (Phase 0)

**I. Test-Driven Development**
- ✅ PASS: Plan includes comprehensive testing strategy (unit, widget, integration, golden, performance tests)
- ✅ PASS: TDD workflow will be enforced in tasks (write tests before implementation)

**II. Code Quality & Maintainability**
- ✅ PASS: Flutter/Dart style guide enforced via linting
- ✅ PASS: Complexity limit (≤10) documented in constraints
- ✅ PASS: Coverage requirements specified (80% business logic, 60% overall)
- ✅ PASS: Public API documentation required for all services/cubits/repositories

**III. User Experience Consistency**
- ✅ PASS: Design system to be established (8px grid, Material Design 3 components)
- ✅ PASS: Consistent navigation patterns via go_router
- ✅ PASS: Accessibility standards (44x44px touch targets, semantic labels)
- ✅ PASS: Responsive design (320px-4K viewport support)

**IV. Performance Standards**
- ✅ PASS: All performance targets documented and measurable
- ✅ PASS: Performance testing planned for settlement calculations
- ✅ PASS: Bundle size target specified (<500KB gzipped)

**V. Data Integrity & Security**
- ✅ PASS: Decimal type mandated for all monetary calculations
- ✅ PASS: Client + server validation planned
- ✅ PASS: Firestore transactions for atomicity
- ✅ PASS: Audit trail via Firestore timestamps and server-side logging

**Result**: ✅ ALL GATES PASS - Proceed to Phase 0

## Project Structure

### Documentation (this feature)

```
specs/001-group-expense-tracker/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
│   └── firestore-schema.md
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

```
# Flutter Web + Firebase Architecture

lib/
├── main.dart                    # App entry point, Firebase initialization
├── core/
│   ├── theme/                   # Material Design 3 theme, 8px grid system
│   ├── router/                  # go_router navigation configuration
│   ├── utils/                   # Decimal helpers, formatters, validators
│   └── constants/               # Fixed user list, categories, currencies
├── features/
│   ├── trips/
│   │   ├── domain/
│   │   │   ├── models/          # Trip entity
│   │   │   └── repositories/    # Trip repository interface
│   │   ├── data/
│   │   │   ├── models/          # Trip Firestore model
│   │   │   └── repositories/    # Trip repository implementation
│   │   ├── presentation/
│   │   │   ├── cubits/          # Trip selection cubit
│   │   │   ├── widgets/         # Trip selector, trip card
│   │   │   └── pages/           # Trip overview page
│   │   └── ...
│   ├── expenses/
│   │   ├── domain/              # Expense entity, split logic
│   │   ├── data/                # Expense Firestore model, repository
│   │   └── presentation/        # Expense list, expense form, cubits
│   ├── exchange_rates/
│   │   ├── domain/              # FX rate entity, conversion logic
│   │   ├── data/                # FX rate Firestore model, repository
│   │   └── presentation/        # FX rate table, rate form
│   ├── settlements/
│   │   ├── domain/              # Settlement algorithms (netting, minimal transfers)
│   │   ├── data/                # Computed settlement Firestore models
│   │   └── presentation/        # Settlement summary, transfer list, dashboards
│   └── categories/
│       ├── domain/              # Category entity
│       ├── data/                # Category Firestore model, repository
│       └── presentation/        # Category selector, category form
└── shared/
    ├── widgets/                 # Reusable components (buttons, inputs, cards)
    └── services/                # Firebase services wrapper

test/
├── unit/
│   ├── core/                    # Decimal helpers, formatters, validators
│   ├── features/
│   │   ├── expenses/            # Split calculation tests
│   │   ├── exchange_rates/      # Currency conversion tests
│   │   └── settlements/         # Netting and minimal transfer algorithm tests
│   └── ...
├── widget/
│   ├── features/                # Widget tests for each feature's UI components
│   └── shared/                  # Reusable widget tests
├── integration/
│   └── flows/                   # End-to-end user flow tests
└── golden/
    └── snapshots/               # Golden file snapshots for visual regression

functions/                        # Firebase Cloud Functions (TypeScript)
├── src/
│   ├── compute-settlement.ts    # Triggered on expense/rate changes
│   └── get-settlement.ts        # Callable function for manual refresh
├── package.json
└── tsconfig.json

web/                             # Flutter web assets
├── index.html
├── manifest.json
└── icons/
```

**Structure Decision**: Flutter web application with clean architecture (domain/data/presentation layers). Firebase Cloud Functions handle server-side settlement computation to ensure consistency. Feature-based organization enables independent development and testing of each capability.

## Complexity Tracking

*No constitutional violations requiring justification.*

All architectural decisions align with constitution principles:
- Clean architecture supports testability (Principle I)
- Feature-based structure promotes maintainability (Principle II)
- Consistent Material Design 3 patterns ensure UX consistency (Principle III)
- Firebase real-time sync and Cloud Functions enable performance targets (Principle IV)
- Decimal type usage and server-side validation ensure data integrity (Principle V)

---

### Post-Design Check (Phase 1)

**Re-evaluation after data model and contracts defined**:

**I. Test-Driven Development**
- ✅ PASS: Test strategy documented in quickstart.md with concrete TDD examples
- ✅ PASS: All domain entities designed for testability (pure functions, no Firebase dependencies)

**II. Code Quality & Maintainability**
- ✅ PASS: Clean architecture enforces separation of concerns
- ✅ PASS: Domain models use value objects (Decimal) and enums for type safety
- ✅ PASS: Documentation requirements specified (API docs, inline comments for financial logic)

**III. User Experience Consistency**
- ✅ PASS: Data model supports all UX requirements (categories, colors, responsive design data)
- ✅ PASS: Error handling designed into validation rules (client + server)
- ✅ PASS: Loading states supported via Cubit pattern (documented in quickstart)

**IV. Performance Standards**
- ✅ PASS: Firestore indexing strategy optimizes queries (composite indexes for expenses, rates)
- ✅ PASS: Computed collections cache expensive calculations (settlement summary)
- ✅ PASS: Server-side settlement computation offloads client (Cloud Functions)

**V. Data Integrity & Security**
- ✅ PASS: Decimal type enforced in data model (all monetary fields)
- ✅ PASS: Validation rules defined for all entities (client + server)
- ✅ PASS: Firestore transactions ensure atomicity (settlement recalculation)
- ✅ PASS: Audit trail via timestamps in all entities
- ✅ PASS: Security rules prevent unauthorized writes to computed data

**Result**: ✅ ALL GATES PASS - Ready for Phase 2 (Task Generation via `/speckit.tasks`)
