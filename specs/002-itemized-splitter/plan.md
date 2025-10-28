# Implementation Plan: Plates-Style Itemized Expense Splitter

**Branch**: `002-itemized-splitter` | **Date**: 2025-10-28 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/002-itemized-splitter/spec.md`

## Summary

This feature extends the expense tracking system to support itemized receipt splitting (similar to Plates app), allowing users to assign individual line items from a single receipt to specific people, apply taxes/tips/fees with configurable allocation rules, and produce deterministic per-person breakdowns with full audit trails. The implementation extends the existing Expense entity (backward compatible), introduces new domain models (LineItem, Extras, AllocationRule), implements a deterministic calculation engine with Decimal arithmetic, creates a 4-step UI flow with review screen, and integrates with the existing SettlementCalculator via `participantAmounts` field.

**Technical Approach**: Extend existing Clean Architecture pattern with new domain models, create ItemizedExpenseCubit for state management, implement pure Dart calculation service with comprehensive test coverage, build multi-step UI wizard with validation, and modify SettlementCalculator to consume participantAmounts when splitType = "itemized".

## Technical Context

**Language/Version**: Dart 3.9.0, Flutter 3.35.1 (stable channel)
**Primary Dependencies**:
- State Management: flutter_bloc ^8.1.3 (Cubit pattern)
- Decimal Arithmetic: decimal ^2.3.3
- Firebase: cloud_firestore ^5.6.0, firebase_core ^3.8.1
- UI/Navigation: go_router ^12.1.1, fl_chart ^0.66.0
- Formatting: intl ^0.18.0

**Storage**: Cloud Firestore (existing collections: trips, expenses, categories)
**Testing**: flutter_test, mockito ^5.4.4, bloc_test ^9.1.5, integration_test
**Target Platform**: Flutter Web (GitHub Pages deployment)
**Project Type**: Single Flutter web application with feature-based architecture

**Architecture Pattern**: Clean Architecture
- Domain layer: Entities, repositories (interfaces), services
- Data layer: Repository implementations, Firestore models/serialization
- Presentation layer: Pages, widgets, Cubits (BLoC pattern)

**Performance Goals**:
- Calculation: <100ms for receipts with 50 items and 6 participants
- UI responsiveness: <16ms per frame (60fps) during item list scrolling
- Firestore write: <500ms for saving itemized expense with breakdown

**Constraints**:
- All monetary calculations MUST use Decimal (no floating point)
- Currency precision from ISO 4217 (USD: 2 decimals, VND: 0 decimals)
- Maximum 300 items per receipt (UI and payload size limits)
- Backward compatibility required (existing equal/weighted expenses unchanged)
- No new Firestore collections (extend existing expenses collection)

**Scale/Scope**:
- MVP: 6 fixed participants (Tai, Khiet, Bob, Ethan, Ryan, Izzy)
- 2 currencies (USD, VND)
- ~7 new domain classes, ~10 new UI screens/widgets, ~2000 LOC estimated
- Comprehensive test suite (target 80% domain coverage)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### I. Test-Driven Development (NON-NEGOTIABLE)
**Status**: ✅ **PASS** with plan
- **Commitment**: Tests will be written before implementation for all calculation logic
- **Approach**:
  - Golden test fixtures for calculation engine (10-15 scenarios covering edge cases)
  - Unit tests for each domain model's validation logic
  - Widget tests for all UI components
  - Integration tests for complete itemized expense flow
  - BLoC tests for ItemizedExpenseCubit state transitions
- **Justification**: Financial calculation correctness is paramount; TDD ensures deterministic, auditable results

### II. Code Quality & Maintainability
**Status**: ✅ **PASS**
- Cyclomatic complexity target: ≤10 per function (calculation engine will be decomposed into focused functions)
- Code coverage: 80% domain logic, 60% overall (enforced via CI)
- Documentation: All public APIs will have dartdoc comments
- DRY: Rounding logic, currency formatting, and validation will be extracted to reusable utilities

### III. User Experience Consistency
**Status**: ✅ **PASS**
- Follows existing expense flow patterns (modal bottom sheet entry, multi-step wizard)
- Reuses existing design system (8px grid, theme colors, typography)
- Error handling: Validation banners with clear messaging (unassigned items, negative totals)
- Loading states: Progress indicators during calculation and save operations
- Accessibility: 44x44px touch targets, semantic labels for screen readers
- Responsive: Supports 320px-4K viewports (card/table toggle for different screen sizes)

### IV. Performance Standards
**Status**: ✅ **PASS**
- Initial page load: Reuses existing app shell (<2s on 3G)
- User interactions: Live recalculation optimized with memoization (<100ms)
- Database operations: Single batch write for expense + trip timestamp (<500ms)
- Memory: No leaks expected (Cubits disposed properly, streams closed)
- Bundle size: Estimated +50KB for new code (well within 500KB budget)

### V. Data Integrity & Security
**Status**: ✅ **PASS**
- Monetary values: Decimal type throughout (spec requires FR-015)
- Validation: Client-side (UI + Cubit) and server-side (Firestore rules can enforce sum check)
- Atomicity: Firestore batch write for expense + trip update
- Audit trail: participantBreakdown provides complete per-person audit
- Error recovery: Save blocked on validation failures, clear user messaging
- Data persistence: Firestore ensures durability and sync

**Overall Constitution Assessment**: ✅ **APPROVED** - All principles satisfied with clear implementation plan

## Project Structure

### Documentation (this feature)

```
specs/002-itemized-splitter/
├── spec.md              # Feature specification (complete)
├── plan.md              # This file (in progress)
├── research.md          # Phase 0: Technical research and decisions
├── data-model.md        # Phase 1: Entity definitions and relationships
├── quickstart.md        # Phase 1: Developer onboarding guide
├── contracts/           # Phase 1: API contracts and schemas
│   ├── expense_dto.json          # Extended Expense Firestore schema
│   ├── line_item_dto.json        # LineItem serialization schema
│   ├── extras_dto.json           # Extras serialization schema
│   └── allocation_rule_dto.json  # AllocationRule serialization schema
├── CLAUDE.md            # Phase 2: Architecture decisions (created via /docs.create)
├── CHANGELOG.md         # Phase 2: Development log (created via /docs.create)
└── tasks.md             # Phase 2: Implementation tasks (created via /speckit.tasks)
```

### Source Code (repository root)

```
lib/
├── core/
│   ├── models/
│   │   ├── split_type.dart                    # [EXTEND] Add 'itemized' enum value
│   │   ├── currency_code.dart                 # [EXISTING] Currency with decimal places
│   │   └── iso_4217_precision.dart            # [NEW] Currency precision lookup
│   ├── services/
│   │   └── decimal_service.dart               # [NEW] Centralized rounding utilities
│   └── utils/
│       └── decimal_helpers.dart               # [EXISTING] Decimal arithmetic helpers
│
├── features/
│   ├── expenses/
│   │   ├── domain/
│   │   │   ├── models/
│   │   │   │   ├── expense.dart               # [EXTEND] Add itemized fields
│   │   │   │   ├── line_item.dart             # [NEW] Line item entity
│   │   │   │   ├── extras.dart                # [NEW] Tax/tip/fees entity
│   │   │   │   ├── allocation_rule.dart       # [NEW] Allocation config entity
│   │   │   │   ├── rounding_config.dart       # [NEW] Rounding policy entity
│   │   │   │   └── participant_breakdown.dart # [NEW] Per-person audit entity
│   │   │   ├── repositories/
│   │   │   │   └── expense_repository.dart    # [EXTEND] Interface unchanged
│   │   │   └── services/
│   │   │       ├── itemized_calculator.dart   # [NEW] Core calculation engine
│   │   │       └── rounding_service.dart      # [NEW] Rounding + remainder distribution
│   │   ├── data/
│   │   │   ├── models/
│   │   │   │   ├── expense_model.dart         # [EXTEND] Add itemized field serialization
│   │   │   │   ├── line_item_model.dart       # [NEW] Firestore DTO
│   │   │   │   ├── extras_model.dart          # [NEW] Firestore DTO
│   │   │   │   └── allocation_rule_model.dart # [NEW] Firestore DTO
│   │   │   └── repositories/
│   │   │       └── expense_repository_impl.dart # [EXTEND] Handle itemized serialization
│   │   └── presentation/
│   │       ├── cubits/
│   │       │   ├── expense_cubit.dart         # [EXISTING] May need minor changes
│   │       │   ├── itemized_expense_cubit.dart # [NEW] Draft state + validation
│   │       │   └── itemized_expense_state.dart # [NEW] State classes
│   │       ├── pages/
│   │       │   ├── add_expense_page.dart      # [EXTEND] Add "Itemized" option
│   │       │   └── itemized/
│   │       │       ├── itemized_expense_flow.dart  # [NEW] 4-step wizard coordinator
│   │       │       ├── people_step_page.dart       # [NEW] Select participants + payer
│   │       │       ├── items_step_page.dart        # [NEW] Add/assign items
│   │       │       ├── extras_step_page.dart       # [NEW] Tax/tip/fees/discounts
│   │       │       └── review_step_page.dart       # [NEW] Review + save
│   │       └── widgets/
│   │           ├── itemized/
│   │           │   ├── line_item_card.dart         # [NEW] Item with assignment
│   │           │   ├── item_assignment_picker.dart # [NEW] Even/custom picker
│   │           │   ├── extras_form.dart            # [NEW] Tax/tip inputs
│   │           │   ├── allocation_settings.dart    # [NEW] Advanced options
│   │           │   ├── review_summary_bar.dart     # [NEW] Grand total bar
│   │           │   ├── person_breakdown_card.dart  # [NEW] Per-person card view
│   │           │   ├── breakdown_table_view.dart   # [NEW] Table mode
│   │           │   └── validation_banner.dart      # [NEW] Error/warning display
│   │           └── expense_list_tile.dart          # [EXTEND] Show itemized badge
│   │
│   └── settlements/
│       └── domain/
│           └── services/
│               └── settlement_calculator.dart  # [EXTEND] Consume participantAmounts
│
└── shared/
    ├── utils/
    │   └── currency_formatter.dart            # [EXISTING] Format with precision
    └── widgets/
        └── currency_input.dart                # [EXISTING] Reused for item prices

tests/
├── unit/
│   ├── expenses/
│   │   ├── domain/
│   │   │   ├── models/
│   │   │   │   ├── line_item_test.dart        # [NEW] LineItem validation
│   │   │   │   ├── extras_test.dart           # [NEW] Extras validation
│   │   │   │   └── allocation_rule_test.dart  # [NEW] Allocation validation
│   │   │   └── services/
│   │   │       ├── itemized_calculator_test.dart  # [NEW] Golden fixtures
│   │   │       └── rounding_service_test.dart     # [NEW] Rounding policies
│   │   └── presentation/
│   │       └── cubits/
│   │           └── itemized_expense_cubit_test.dart # [NEW] State transitions
│   └── settlements/
│       └── settlement_calculator_test.dart    # [EXTEND] Add itemized test cases
│
├── widget/
│   └── expenses/
│       └── itemized/
│           ├── line_item_card_test.dart       # [NEW]
│           ├── review_step_page_test.dart     # [NEW]
│           └── person_breakdown_card_test.dart # [NEW]
│
└── integration/
    └── itemized_expense_flow_test.dart        # [NEW] End-to-end test
```

**Structure Decision**: Single Flutter web project with feature-based architecture. The itemized splitter extends the existing `expenses` feature with new domain models, services, and UI components. Clean Architecture is maintained with clear separation between domain (business logic), data (Firestore integration), and presentation (UI + state management). The existing `settlements` feature is minimally modified to consume the new `participantAmounts` field.

## Complexity Tracking

*No violations - constitution gates all passed.*

## Phase 0: Research & Technical Decisions

**Output**: [research.md](./research.md)

Research tasks to resolve before design:
1. ✅ Rounding remainder distribution strategies (largestShare, payer, firstListed, random)
2. ✅ Decimal precision handling for zero-minor-unit currencies (VND)
3. ✅ Tax/tip allocation base options and their real-world use cases
4. ✅ Custom shares input UX (fractions vs percentages vs sliders)
5. ✅ Review screen performance for large receipts (50+ items)
6. ✅ Firestore schema extension best practices for backward compatibility

## Phase 1: Design & Contracts

**Output**:
- [data-model.md](./data-model.md) - Entity definitions with validation rules
- [contracts/](./contracts/) - Firestore DTOs in JSON schema format
- [quickstart.md](./quickstart.md) - Developer setup guide

Design artifacts to generate:
1. Domain entities: LineItem, Extras, AllocationRule, RoundingConfig, ParticipantBreakdown
2. Extended Expense entity with itemized fields (backward compatible)
3. ItemizedCalculator service interface and implementation strategy
4. Firestore DTOs with serialization logic
5. ItemizedExpenseCubit state machine diagram
6. UI component hierarchy for 4-step flow

## Phase 2: Task Breakdown

**Output**: [tasks.md](./tasks.md) via `/speckit.tasks` command

Tasks will be generated with dependencies in execution order. Estimated task categories:
- Domain models + validation (8-10 tasks)
- Calculation engine + rounding (6-8 tasks)
- Firestore serialization (4-6 tasks)
- State management (Cubit + states) (5-7 tasks)
- UI components (items, extras, review) (15-20 tasks)
- Settlement integration (2-3 tasks)
- Testing (unit, widget, integration) (20-25 tasks)

**Total Estimated Effort**: 60-80 tasks, 25-35 hours of implementation

## Next Steps

1. ✅ Phase 0: Generate research.md (resolve technical unknowns)
2. ✅ Phase 1: Generate data-model.md, contracts/, quickstart.md
3. ✅ Phase 1: Update agent context via `.specify/scripts/bash/update-agent-context.sh`
4. ⏳ Phase 2: Run `/speckit.tasks` to generate tasks.md
5. ⏳ Phase 2: Run `/docs.create` to create CLAUDE.md and CHANGELOG.md
6. ⏳ Phase 3: Run `/speckit.implement` to execute tasks
7. ⏳ Phase 4: Run `/docs.complete` to finalize feature

---

**Status**: ✅ Plan complete, proceeding to Phase 0 (research)
**Last Updated**: 2025-10-28
