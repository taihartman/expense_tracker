<!--
Sync Impact Report - 2025-10-21

Version Change: Template → 1.0.0
Change Type: MINOR (Initial constitution creation with 5 core principles)

Modified Principles: N/A (initial creation)

Added Sections:
- Core Principles (5 principles defined)
- Code Quality Standards
- Development Workflow
- Governance

Removed Sections: N/A (initial creation)

Templates Requiring Updates:
- ✅ .specify/templates/plan-template.md (verified - no changes needed)
- ✅ .specify/templates/spec-template.md (verified - no changes needed)
- ✅ .specify/templates/tasks-template.md (verified - no changes needed)

Follow-up TODOs: None

Rationale:
This is the initial constitution for the Expense Tracker project. Version 1.0.0 chosen as MINOR
release since this establishes the first set of governing principles. Focused on code quality,
testing standards, user experience consistency, and performance as requested by project owner.
-->

# Expense Tracker Constitution

## Core Principles

### I. Test-Driven Development (NON-NEGOTIABLE)

Tests MUST be written and approved before implementation begins. The TDD cycle is strictly enforced:
- Write failing tests first (Red)
- Implement minimum code to pass tests (Green)
- Refactor for quality while maintaining green tests (Refactor)

**Rationale**: TDD ensures testable, well-designed code and prevents untested features from entering
production. This discipline is particularly critical for financial calculations where correctness is
paramount.

### II. Code Quality & Maintainability

All code MUST adhere to the following quality standards:
- Follow Flutter/Dart style guide and linting rules without exceptions
- Maximum function complexity: cyclomatic complexity ≤ 10
- Code coverage minimum: 80% for business logic, 60% overall
- Every public API MUST have documentation comments
- No commented-out code in commits (use version control for history)
- DRY principle: duplicate logic MUST be extracted to reusable components

**Rationale**: High-quality, maintainable code reduces technical debt, accelerates feature delivery,
and enables confident refactoring. Financial calculations require clear, auditable code.

### III. User Experience Consistency

All user-facing features MUST maintain consistent UX patterns:
- Visual design: consistent spacing (8px grid), typography, and color scheme throughout
- Interaction patterns: identical controls perform identical actions across all screens
- Error handling: user-friendly error messages with clear recovery actions (no stack traces to users)
- Loading states: provide visual feedback for operations >300ms
- Accessibility: minimum touch targets 44x44px, semantic labels for screen readers
- Responsive design: support viewport widths from 320px to 4K displays

**Rationale**: Consistency builds user trust and reduces cognitive load. Users should learn once and
apply everywhere. Critical for financial apps where confusion can lead to costly mistakes.

### IV. Performance Standards

All features MUST meet or exceed the following performance criteria:
- Initial page load: <2 seconds on 3G connection
- User interactions: respond within 100ms (visual feedback) and complete within 1 second
- Database operations: settlement calculations update within 2 seconds for trips with 100+ expenses
- Memory: no memory leaks; monitor and fix any growth >10% over 1 hour of active use
- Bundle size: web app initial bundle <500KB gzipped

**Rationale**: Poor performance frustrates users and reduces engagement. Financial apps demand
responsiveness to build confidence in accuracy and reliability.

### V. Data Integrity & Security

All data operations MUST maintain integrity and security:
- Monetary values: use Decimal type (not floating point) for all calculations
- Validation: all user inputs validated on client AND server
- Atomicity: multi-step operations use transactions (all succeed or all fail)
- Audit trail: critical operations (expense creation, settlement calculations) logged with timestamp
- Error recovery: graceful degradation with clear user communication, no silent failures
- Data persistence: all user data MUST survive browser refresh and device changes

**Rationale**: Financial data requires absolute correctness. Users must trust that their expense
records and settlement calculations are accurate and permanent.

## Code Quality Standards

### Code Review Requirements

All code changes MUST pass review before merge:
- Minimum 1 approving review from project maintainer
- All automated tests passing (unit, integration, e2e)
- Linter warnings resolved (zero tolerance)
- Code coverage requirements met
- Performance benchmarks within acceptable thresholds

### Testing Requirements

Every feature MUST include:
- **Unit tests**: All business logic functions (settlement calculations, currency conversion, split algorithms)
- **Widget tests**: All UI components with user interactions
- **Integration tests**: Complete user flows (record expense → view settlement)
- **Golden tests**: Visual regression tests for critical screens (settlement summary, expense list)
- **Performance tests**: Settlement calculation benchmarks for large datasets (100+ expenses)

### Documentation Requirements

Every feature MUST include:
- API documentation: all public methods, classes, and functions
- User documentation: help text for complex features (weighted splits, exchange rates)
- Architecture decisions: ADRs for significant technical choices
- Inline comments: explain "why" for non-obvious logic (especially financial calculations)

## Development Workflow

### Feature Development Process

1. **Specification Phase**: Create spec using `/speckit.specify` (what and why, not how)
2. **Planning Phase**: Create implementation plan using `/speckit.plan` (technical design)
3. **Task Generation**: Generate tasks using `/speckit.tasks` (dependency-ordered work items)
4. **Implementation**: Write tests first, then implementation
5. **Review**: Code review, automated checks, manual testing
6. **Deployment**: Merge to main triggers automatic deployment to staging, then production

### Branch Strategy

- `master`: production-ready code, auto-deploys to GitHub Pages
- `###-feature-name`: feature branches from spec-kit, one per feature
- No direct commits to master (all changes via PR)

### Commit Standards

- Follow Conventional Commits format: `type(scope): description`
- Types: `feat`, `fix`, `docs`, `test`, `refactor`, `perf`, `chore`
- Include co-author attribution for AI assistance
- Reference issue/spec numbers in commit body

## Governance

### Constitutional Authority

This constitution supersedes all other practices and guidelines. When conflicts arise:
1. Constitution principles take precedence
2. Team discusses amendment if principle causes blockers
3. Amendments require documented rationale and migration plan

### Amendment Process

To amend this constitution:
1. Propose change via `/speckit.constitution` with clear rationale
2. Version bump follows semantic versioning (MAJOR for breaking changes to principles, MINOR for new
   principles, PATCH for clarifications)
3. Update all dependent templates and documentation
4. Document impact in Sync Impact Report
5. Commit with full team approval

### Compliance Verification

All PRs and code reviews MUST verify:
- TDD cycle followed (tests written before implementation)
- Code quality standards met (linting, coverage, complexity)
- UX consistency maintained (design patterns, accessibility)
- Performance standards achieved (benchmarks passing)
- Data integrity preserved (tests verify financial correctness)

### Enforcement

Non-compliance handling:
1. Automated checks block PRs (linting, tests, coverage)
2. Manual review catches UX/architectural violations
3. Post-merge issues require immediate fix or revert
4. Repeated violations trigger process review and team discussion

**Version**: 1.0.0 | **Ratified**: 2025-10-21 | **Last Amended**: 2025-10-21
