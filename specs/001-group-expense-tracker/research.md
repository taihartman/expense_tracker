# Research: Group Expense Tracker for Trips

**Phase**: 0 (Outline & Research)
**Date**: 2025-10-21
**Status**: Complete

## Overview

This document captures technical research and architectural decisions for implementing the group expense tracker. All technology choices are finalized based on project requirements and constitutional principles.

## Technology Stack Decisions

### 1. Flutter Web for Frontend

**Decision**: Use Flutter 3.35.1 (stable) for web application development

**Rationale**:
- Single codebase for responsive web experience (320px-4K viewports)
- Hot reload accelerates development iteration
- Material Design 3 built-in for consistent UX
- Strong type safety (Dart) reduces runtime errors
- Excellent performance for complex UI (charts, real-time updates)

**Alternatives Considered**:
- React: Rejected due to less integrated tooling, requires more boilerplate for state management
- Vue.js: Rejected due to smaller ecosystem for complex data visualization
- Angular: Rejected due to steeper learning curve and heavier bundle size

**Best Practices**:
- Use BLoC/Cubit pattern for predictable state management
- Implement clean architecture (domain/data/presentation) for testability
- Leverage go_router for declarative routing
- Use const constructors extensively to reduce rebuilds

### 2. Firebase for Backend-as-a-Service

**Decision**: Use Firebase (Firestore + Cloud Functions + Auth + Hosting)

**Rationale**:
- Real-time sync enables multi-device collaboration without manual refresh
- Serverless functions (Cloud Functions) reduce infrastructure overhead
- Built-in authentication (anonymous for MVP) with upgrade path
- Automatic scaling handles variable load
- Firebase Hosting provides CDN-backed static hosting

**Alternatives Considered**:
- Custom Node.js + PostgreSQL: Rejected due to increased infrastructure management overhead for MVP
- Supabase: Rejected due to less mature Flutter integration and serverless compute
- AWS Amplify: Rejected due to more complex setup and vendor lock-in concerns

**Best Practices**:
- Use Firestore security rules for data access control (even with anonymous auth)
- Batch operations where possible to reduce read/write costs
- Index frequently queried fields (trip ID, expense date)
- Use Cloud Functions triggers (onWrite) for automatic settlement recalculation
- Implement caching strategies to minimize Firestore reads

### 3. Decimal Package for Monetary Calculations

**Decision**: Use `decimal` package (not native double/int) for all monetary values

**Rationale**:
- Eliminates floating-point precision errors (critical for financial accuracy)
- Supports arbitrary precision arithmetic
- Constitutional requirement (Principle V: Data Integrity)
- Matches Firestore string storage (convert on read/write)

**Alternatives Considered**:
- Native double: REJECTED - floating point errors unacceptable for money (0.1 + 0.2 ≠ 0.3)
- Int (store cents): Rejected due to complexity with VND (no decimals) vs USD (2 decimals)
- BigInt: Rejected due to lack of decimal arithmetic support

**Best Practices**:
- Store as string in Firestore: `"amount": "123.45"`
- Convert to Decimal for calculations: `Decimal.parse(amount)`
- Use `toStringAsFixed(2)` for USD display, `toStringAsFixed(0)` for VND
- Never use `double` in calculation pipeline

### 4. State Management: BLoC Pattern

**Decision**: Use `flutter_bloc` for state management

**Rationale**:
- Predictable state transitions (event → state)
- Excellent testability (mock events, verify state emissions)
- Clear separation of business logic and UI
- Built-in debugging tools (BlocObserver)
- Well-suited for complex async operations (Firestore queries)

**Alternatives Considered**:
- Provider: Rejected due to less structure for complex state flows
- Riverpod: Rejected due to less proven patterns for large apps
- GetX: Rejected due to non-idiomatic Dart patterns

**Best Practices**:
- Use Cubit for simple state (trip selection, form state)
- Use Bloc for complex flows (expense submission with validation + settlement recalc)
- Emit loading states for operations >300ms (constitutional requirement)
- Handle errors with dedicated error states (not thrown exceptions)

## Architectural Patterns

### Clean Architecture

**Structure**:
```
feature/
├── domain/       # Business entities, repository interfaces, use cases
├── data/         # Firestore models, repository implementations
└── presentation/ # Cubits, widgets, pages
```

**Benefits**:
- Testability: Mock repositories for unit testing domain logic
- Maintainability: Changes to Firestore don't affect domain/presentation
- Scalability: Easy to add new data sources (e.g., local cache)

**Implementation Guidelines**:
- Domain layer has zero Flutter/Firebase dependencies
- Data layer depends on domain (implements interfaces)
- Presentation layer depends on domain (uses repositories via cubits)
- Never import presentation into domain/data

### Settlement Calculation Strategy

**Decision**: Server-side computation via Cloud Functions

**Rationale**:
- Ensures consistency across all clients (no drift from client-side calculation bugs)
- Centralized logging for audit trail
- Reduces client bundle size (algorithm code on server only)
- Firestore triggers enable automatic recalc on expense/rate changes

**Algorithm**:
1. **Currency Conversion**: Query FX rates, convert all expenses to base currency
2. **Share Calculation**: For each expense, compute participant shares (equal or weighted)
3. **Pairwise Accumulation**: Build matrix of who owes whom (raw debts)
4. **Netting**: For each pair (A, B), net[A][B] = debt[A][B] - debt[B][A]
5. **Minimal Settlement**: Greedy algorithm - match largest creditor with largest debtor until all settled

**Complexity**: O(n²) for n participants (acceptable for 6-person MVP)

### Data Modeling Best Practices

**Firestore Structure**:
- Top-level collections: `/trips`, not nested under users (enable multi-user access)
- Subcollections for trip-specific data: `/trips/{tripId}/expenses`
- Computed collections: `/trips/{tripId}/computed/settlement` (auto-updated by Cloud Functions)
- Denormalization where needed: store participant names with expenses (avoid extra reads)

**Indexing Strategy**:
- Composite index: `(tripId, date DESC)` for expense queries
- Single-field index: `categoryId`, `payerUserId` for filtering

**Security Rules**:
```
// For MVP (anonymous auth), allow read/write to all trips
// Future: restrict to trip participants only
match /trips/{tripId} {
  allow read, write: if request.auth != null;
}
```

## Performance Optimization Strategies

### Bundle Size (<500KB gzipped)

**Tactics**:
- Tree shaking: Import specific packages, not entire libraries
- Code splitting: Lazy load routes via go_router
- Font subsetting: Include only used glyphs
- Image optimization: Use WebP format, compress PNGs
- Analyze bundle: `flutter build web --analyze-size`

**Expected Breakdown**:
- Framework: ~200KB (Flutter + Material Design)
- Firebase SDK: ~150KB (Firestore + Auth + Functions)
- App code: ~100KB (business logic + UI)
- Charts (fl_chart): ~50KB

### Initial Load (<2s on 3G)

**Tactics**:
- Minimize initial bundle (defer non-critical features)
- Use service worker caching (Flutter web default)
- Lazy load trip data (only fetch current trip on startup)
- Prefetch common queries (current trip's expenses)
- CDN delivery via Firebase Hosting

**Performance Budget**:
- HTML/JS download: 800ms (500KB @ 3G ~600KB/s)
- Parse/execute: 400ms
- Initial render: 400ms
- Data fetch + render: 400ms
- **Total**: 2000ms

### Settlement Calculation (<2s for 100+ expenses)

**Tactics**:
- Server-side compute (Cloud Functions with 1GB memory, 60s timeout)
- Batch Firestore reads (single query for all expenses)
- In-memory calculation (no intermediate Firestore writes)
- Atomic writes (transaction for settlement results)

**Expected Performance**:
- 100 expenses: ~500ms (query 200ms + compute 100ms + write 200ms)
- 1000 expenses: ~1500ms (query 500ms + compute 500ms + write 500ms)

## Testing Strategy

### Unit Tests (Target: 80% business logic coverage)

**Priority Areas**:
1. **Settlement algorithms** (netting, minimal transfer)
2. **Currency conversion** (FX rate matching, fallback logic)
3. **Split calculations** (equal, weighted, edge cases)
4. **Decimal arithmetic** (precision, rounding)
5. **Validation** (expense inputs, rate inputs)

**Tools**: flutter_test, mockito (for repository mocks)

### Widget Tests (Target: all interactive components)

**Priority Areas**:
1. Form validation (expense form, rate form)
2. List rendering (expenses, settlements)
3. State transitions (loading, error, success)
4. User interactions (button clicks, input changes)

**Tools**: flutter_test, flutter_bloc_test

### Integration Tests (Critical user flows)

**Scenarios**:
1. Create trip → Add expense → View settlement
2. Add multiple expenses → Verify net calculations
3. Multi-currency: USD + VND expenses → Verify conversions
4. Weighted split → Verify correct share allocation

**Tools**: integration_test package, Firebase Emulator Suite (local testing)

### Golden Tests (Visual regression)

**Screens**:
1. Settlement summary table
2. Expense list with categories
3. Per-person dashboard with charts
4. Responsive layouts (mobile 375px, tablet 768px, desktop 1920px)

**Tools**: flutter_test (matchesGoldenFile)

## Dependencies Reference

```yaml
dependencies:
  flutter:
    sdk: flutter

  # State Management
  flutter_bloc: ^8.1.3
  equatable: ^2.0.5           # Value equality for state

  # Firebase
  firebase_core: ^2.24.0
  cloud_firestore: ^4.14.0
  firebase_auth: ^4.16.0
  firebase_functions: ^4.6.0

  # Utilities
  decimal: ^2.3.3             # Precise monetary calculations
  intl: ^0.18.0               # Date/number formatting

  # UI/Navigation
  go_router: ^12.1.1
  fl_chart: ^0.66.0           # Category pie charts

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.1
  mockito: ^5.4.4
  build_runner: ^2.4.7
  bloc_test: ^9.1.5
  integration_test:
    sdk: flutter
```

## Open Questions / Future Decisions

*None remaining - all technical decisions finalized.*

**Post-MVP Considerations** (out of current scope):
- Live FX rate API integration (OpenExchangeRates, Fixer.io)
- Persistent authentication (Email/Password, Google Sign-In)
- Offline support (local SQLite cache + sync)
- Native mobile apps (iOS/Android builds)
- Payment tracking (mark settlements as paid)

## References

- [Flutter Clean Architecture](https://resocoder.com/2019/08/27/flutter-tdd-clean-architecture-course-1-explanation-project-structure/)
- [Firebase Best Practices](https://firebase.google.com/docs/firestore/best-practices)
- [BLoC Pattern Guide](https://bloclibrary.dev/#/coreconcepts)
- [Decimal Package Docs](https://pub.dev/packages/decimal)
- [Material Design 3](https://m3.material.io/)
