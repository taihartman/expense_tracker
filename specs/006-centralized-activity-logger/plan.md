# Implementation Plan: Centralized Activity Logger Service

**Branch**: `006-centralized-activity-logger` | **Date**: 2025-10-30 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/006-centralized-activity-logger/spec.md`

## Summary

Create a centralized ActivityLoggerService that consolidates all activity logging logic from individual cubits into a single service. The service provides simple methods like `logExpenseEdit()`, `logTransferSettled()`, etc. that encapsulate all the complexity of change detection, metadata generation, and activity log creation. This eliminates 40+ lines of boilerplate code per logging operation in cubits, ensures consistent logging patterns across the app, and makes it easier to add new activity types in the future.

**Technical Approach**: Implement a singleton service class that wraps the ActivityLogRepository and TripRepository, providing type-safe methods for each ActivityType. The service will reuse the existing ExpenseChangeDetector pattern for change detection, cache trip data to minimize redundant fetches, and handle all errors gracefully (fire-and-forget pattern) to ensure logging failures never block business operations.

## Technical Context

**Language/Version**: Dart 3.9.0+ with Flutter SDK 3.9.0+
**Primary Dependencies**: 
- `flutter_bloc` 8.1.3+ (BLoC/Cubit state management)
- `cloud_firestore` 5.6.0+ (Firestore backend)
- Existing repositories: ActivityLogRepository, TripRepository, ExpenseRepository
**Storage**: Cloud Firestore (existing backend)
**Testing**: Flutter test framework with mockito for mocks, bloc_test for cubit testing
**Target Platform**: Web (primary), Flutter web architecture
**Project Type**: Flutter web application with feature-based architecture
**Performance Goals**: <50ms overhead for activity logging operations (non-blocking)
**Constraints**: 
- Fire-and-forget pattern (logging failures must not block operations)
- Graceful degradation (log with available data if context fetch fails)
- Non-breaking migration (existing cubits continue working during gradual rollout)
**Scale/Scope**: 
- Handle 50+ activities/minute per user during bulk operations
- Support 15+ activity types (current ActivityType enum)
- Reduce logging code by 70% (from ~40 lines to <5 lines per operation)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### TDD (NON-NEGOTIABLE) ✅
- Tests will be written first for all service methods
- Each activity logging method will have unit tests with mocked dependencies
- Integration tests will verify end-to-end logging with real change detection

### Code Quality ✅
- Service follows SOLID principles (Single Responsibility: activity logging only)
- Maximum cyclomatic complexity ≤ 10 per method
- 80%+ code coverage for service business logic
- Full API documentation with examples

### UX Consistency ✅
- No direct user-facing changes (this is an internal service)
- Logging patterns become consistent across all features (indirect UX improvement)

### Performance Standards ✅
- <50ms overhead per logging operation (well within 100ms interaction standard)
- Caching minimizes redundant network fetches
- Fire-and-forget pattern prevents blocking

### Data Integrity ✅
- Non-fatal logging failures preserve main operations (logging errors caught internally)
- All activity logs maintain consistent structure
- Change detection ensures accurate before/after tracking

## Project Structure

### Documentation (this feature)

```
specs/006-centralized-activity-logger/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output - design decisions and patterns
├── data-model.md        # Phase 1 output - service structure and API
├── quickstart.md        # Phase 1 output - usage examples for developers
├── contracts/           # Phase 1 output - interface specifications
│   ├── activity_logger_service_interface.md
│   └── migration_plan.md
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

```
lib/
├── core/
│   └── services/
│       ├── activity_logger_service.dart           # Abstract interface
│       └── activity_logger_service_impl.dart      # Concrete implementation
├── features/
│   ├── expenses/
│   │   ├── domain/
│   │   │   └── utils/
│   │   │       └── expense_change_detector.dart   # EXISTING - will be reused
│   │   └── presentation/
│   │       └── cubits/
│   │           └── expense_cubit.dart             # TO BE MIGRATED
│   ├── settlements/
│   │   └── presentation/
│   │       └── cubits/
│   │           └── settlement_cubit.dart          # TO BE MIGRATED
│   └── trips/
│       ├── domain/
│       │   ├── models/
│       │   │   └── activity_log.dart              # EXISTING - unchanged
│       │   └── repositories/
│       │       ├── activity_log_repository.dart   # EXISTING - injected into service
│       │       └── trip_repository.dart           # EXISTING - injected into service
│       └── presentation/
│           └── cubits/
│               └── trip_cubit.dart                # TO BE MIGRATED
test/
├── core/
│   └── services/
│       └── activity_logger_service_test.dart      # Unit tests for service
└── integration/
    └── activity_logger_integration_test.dart      # End-to-end tests
```

**Structure Decision**: This is a Flutter web application using feature-based architecture. The new service lives in `lib/core/services/` as it's a cross-cutting concern used by multiple features (trips, expenses, settlements). The service will be dependency-injected into cubits, following the existing pattern where repositories are injected as optional parameters. Tests follow Flutter convention with unit tests mirroring the source structure and integration tests in a separate directory.

## Complexity Tracking

*No constitutional violations - this feature adheres to all established principles.*

**Justification for New Service Layer**:
- **Problem**: Cubits currently have 40+ lines of boilerplate for each activity logging operation
- **Solution**: Centralize logic in a service to ensure consistency and reduce duplication
- **Rejected Alternative**: Repository pattern alone - repositories are for data access, not business logic like change detection and metadata enrichment
- **Compliance**: This follows DRY principle (Core Principle II) and improves maintainability

**Caching Strategy**:
- **Need**: Performance requirement (<50ms overhead) requires minimizing redundant Firestore fetches
- **Approach**: In-memory cache with trip-based invalidation
- **Trade-off**: Small memory overhead for significant performance gain (acceptable for web app)
