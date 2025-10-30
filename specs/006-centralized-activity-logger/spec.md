# Feature Specification: Centralized Activity Logger Service

**Feature Branch**: `006-centralized-activity-logger`
**Created**: 2025-10-30
**Status**: Draft
**Input**: User description: "Create a centralized ActivityLoggerService that consolidates all activity logging logic from individual cubits into a single service. The service should provide simple methods like logExpenseEdit(), logTransferSettled(), etc. that encapsulate all the complexity of change detection, metadata generation, and activity log creation. This will eliminate boilerplate code from cubits, ensure consistent logging patterns across the app, and make it easier to add new activity types in the future."

## User Scenarios & Testing

### User Story 1 - Developer Adds New Activity Type (Priority: P1)

As a developer adding a new feature, I need to log user activities without writing complex boilerplate code so that I can focus on business logic and ensure consistent activity tracking across the app.

**Why this priority**: This is the primary value proposition - reducing developer effort and preventing logging inconsistencies. Without this, developers must manually implement change detection, metadata generation, and error handling in every cubit, leading to inconsistent patterns and forgotten logs.

**Independent Test**: Can be fully tested by having a developer add a new activity type (e.g., "category created") using the service's simple API and verifying the activity appears in the activity log with correct metadata.

**Acceptance Scenarios**:

1. **Given** a developer needs to log an expense edit, **When** they call `activityLogger.logExpenseEdit(oldExpense, newExpense, actorName)`, **Then** the system automatically detects all changes, generates metadata, and creates an activity log entry without the developer writing change detection code
2. **Given** a cubit needs to log multiple activity types, **When** the developer injects only the ActivityLoggerService, **Then** they have access to all logging methods without needing multiple repository injections
3. **Given** logging fails (e.g., network error), **When** the service encounters an error, **Then** the error is logged but does not crash or block the main operation

---

### User Story 2 - Consistent Activity Metadata Across Features (Priority: P2)

As a product manager reviewing activity logs, I need all activities to follow the same metadata structure and naming conventions so that I can analyze user behavior patterns and generate consistent reports.

**Why this priority**: Inconsistent logging makes analysis difficult and can hide important patterns. Centralizing logic ensures all logs follow the same structure, making them queryable and analyzable.

**Independent Test**: Can be tested by triggering activities from different features (expenses, settlements, trips) and verifying all logs follow the same metadata structure with consistent field names and value formats.

**Acceptance Scenarios**:

1. **Given** activities are logged from different features, **When** reviewing the activity log metadata, **Then** all change records use consistent field names (e.g., always "oldValue" and "newValue", not sometimes "before"/"after")
2. **Given** participant information is included in metadata, **When** any activity references participants, **Then** both IDs and human-readable names are always included
3. **Given** an activity involves multiple changes, **When** the log is created, **Then** changes are organized in a consistent structure (grouped by field type, with before/after values)

---

### User Story 3 - Performance Optimization Through Caching (Priority: P3)

As an end user performing multiple operations in a trip, I need the app to remain responsive even when logging many activities so that my workflow is not interrupted by slow activity tracking.

**Why this priority**: While important for user experience, this is an optimization that can be added after the core service works. The MVP can function without caching, though performance may suffer with high activity volumes.

**Independent Test**: Can be tested by performing 20+ operations in quick succession (multiple expense edits, settlement actions) and measuring response time, then verifying cached trip data is reused instead of fetched repeatedly.

**Acceptance Scenarios**:

1. **Given** a user edits multiple expenses in the same trip, **When** each edit is logged, **Then** trip participant data is fetched once and cached for subsequent logs
2. **Given** a user switches to a different trip, **When** logging activities in the new trip, **Then** the cache is cleared or updated to reflect the new trip context
3. **Given** high activity logging volume, **When** 50+ activities are logged in 1 minute, **Then** response time for each operation remains under 500ms

---

### Edge Cases

- What happens when trip data cannot be fetched (network error, deleted trip)? System should log activity with available data and gracefully degrade (e.g., use participant IDs instead of names)
- How does system handle partial failures (activity saved but metadata generation failed)? Service should ensure atomic operations or log with minimal metadata rather than failing completely
- What happens when actor name is not provided? Service should have a reasonable default (e.g., "Unknown" or "System") rather than crashing
- How are rapid successive changes to the same entity handled? Each change should generate a separate log entry with accurate timestamps
- What happens when change detection finds no changes (old and new are identical)? Service should either skip logging or log with empty change metadata, depending on activity type

## Requirements

### Functional Requirements

- **FR-001**: Service MUST provide dedicated methods for each activity type (logExpenseEdit, logExpenseAdded, logTransferSettled, logMemberJoined, etc.)
- **FR-002**: Service MUST automatically detect changes by comparing old and new entity states for edit operations
- **FR-003**: Service MUST generate metadata that includes both identifiers (IDs) and human-readable names for all referenced entities (participants, categories, etc.)
- **FR-004**: Service MUST fetch necessary context data (e.g., trip participants) to enrich activity log metadata
- **FR-005**: Service MUST handle logging failures gracefully without throwing exceptions that would crash the calling code
- **FR-006**: Service MUST log all errors internally for debugging while preventing them from bubbling up to business logic
- **FR-007**: Service MUST support caching of frequently accessed data (e.g., trip information) to minimize redundant fetches
- **FR-008**: Service MUST accept an actor name parameter for all logging methods to attribute actions to specific users
- **FR-009**: Service MUST reuse existing change detection utilities (e.g., ExpenseChangeDetector) rather than reimplementing logic
- **FR-010**: Service MUST create activity logs with consistent structure: id, tripId, actorName, type, description, timestamp, metadata

### Key Entities

- **ActivityLoggerService**: Central service that encapsulates all activity logging logic; provides simple method-based API for logging different activity types; manages dependencies (ActivityLogRepository, TripRepository, etc.); handles error recovery and caching
- **Activity Log Methods**: Each method corresponds to one activity type (e.g., logExpenseEdit, logTransferSettled); accepts domain entities and actor name as parameters; internally handles change detection, metadata generation, and persistence; returns void (fire-and-forget pattern with internal error handling)
- **Cache**: Internal storage for frequently accessed data (trip information, participant lists); cleared or updated when context changes (e.g., switching trips); used to avoid repeated network fetches during bulk logging operations

## Success Criteria

### Measurable Outcomes

- **SC-001**: Developers can add activity logging with a single method call instead of 40+ lines of boilerplate code
- **SC-002**: All activity logs across the app follow identical metadata structure with consistent field naming
- **SC-003**: 100% of activity types are migrated from manual repository injection to centralized service by end of rollout
- **SC-004**: Logging-related code in cubits is reduced by at least 70% (measured by lines of code dedicated to activity logging)
- **SC-005**: Activity logging does not increase operation response time by more than 50ms (measured from user action to state update)
- **SC-006**: Zero crashes or operation failures caused by activity logging errors (logging failures are caught and logged internally)

## Assumptions

- The existing ExpenseChangeDetector utility provides a good pattern for change detection that can be reused or adapted for other entity types
- Trip data (participants, metadata) changes infrequently enough that caching provides meaningful performance benefits
- Activity logging is non-critical enough that silent failure (with internal error logging) is acceptable rather than blocking operations
- The current activity log structure (ActivityLog model with optional metadata field) is sufficient and does not need schema changes
- Developers will gradually migrate existing cubits to use the service rather than requiring immediate full migration
- The app uses dependency injection patterns that allow service injection into cubits

## Out of Scope

- Modifying the ActivityLog data model or database schema
- Adding new activity types beyond those already defined in ActivityType enum
- Implementing real-time activity log sync or push notifications
- Adding analytics or reporting features on top of activity logs
- Modifying existing change detection logic (ExpenseChangeDetector remains as-is)
- Adding authorization/permissions for activity logging (assumes all logged-in users can create logs)
- Implementing activity log filtering, search, or advanced querying capabilities
- Creating automated tests for the service (testing is separate task)

