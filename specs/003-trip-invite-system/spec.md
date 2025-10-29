# Feature Specification: Trip Invite System

**Feature Branch**: `003-trip-invite-system`
**Created**: 2025-10-28
**Status**: Draft
**Input**: User description: "Trip invite system with shareable codes/links, private trip membership, user names on join, and activity log for transparency"

## Clarifications

### Session 2025-10-29

- Q: How should the activity log handle large entry counts (100+ entries)? → A: Limit with "Load More" - Show 50 most recent entries initially with a "Load More" button to fetch older entries in batches
- Q: When does the trip creator provide their name? → A: Prompt during creation - Trip creation form includes a "Your Name" field, creator provides name when creating trip
- Q: What format should timestamps use in the activity log display? → A: Relative with hover - Show relative time (e.g., "2 hours ago", "Yesterday") with absolute timestamp on hover/tooltip

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Join Trip via Invite Code (Priority: P1)

A user receives a trip invite code from a friend and wants to join the trip to start tracking shared expenses.

**Why this priority**: This is the core functionality that enables trip privacy and controlled access. Without this, the entire invite system cannot function.

**Independent Test**: Can be fully tested by creating a trip, obtaining its invite code, and successfully joining it by entering the code. Delivers immediate value by allowing users to join private trips.

**Acceptance Scenarios**:

1. **Given** a user has received a trip invite code, **When** they enter the code on the join trip screen, **Then** they are prompted to provide their name
2. **Given** a user has entered a valid code and provided their name, **When** they submit the join request, **Then** they are added to the trip's member list and can view the trip
3. **Given** a user has entered an invalid or non-existent code, **When** they submit, **Then** they see an error message indicating the code is invalid
4. **Given** a user is already a member of a trip, **When** they try to join using the same code again, **Then** they are redirected to the trip without duplication

---

### User Story 2 - Share Trip via Link (Priority: P1)

A trip member wants to invite others to join the trip by sharing a link via messaging apps, email, or social media.

**Why this priority**: Essential for usability - manual code entry alone creates friction. Shareable links are the expected modern UX pattern for invitations.

**Independent Test**: Can be fully tested by generating a shareable link for a trip, sending it to another user, and verifying they can join with one click. Delivers standalone value for easy trip sharing.

**Acceptance Scenarios**:

1. **Given** a user is a member of a trip, **When** they access the trip's invite options, **Then** they can view and copy a shareable link containing the trip code
2. **Given** a user receives a shareable link, **When** they click or paste it into their browser, **Then** they are taken directly to the join page with the trip code pre-filled
3. **Given** a user clicks a shareable link, **When** they arrive at the join page, **Then** they see trip details (name, currency, member count) before joining
4. **Given** a non-member clicks a shareable link, **When** they provide their name and confirm, **Then** they are added to the trip and redirected to the trip's expense list

---

### User Story 3 - View Trip Activity Log (Priority: P2)

Trip members want to see a history of all actions taken in the trip (who joined, who added expenses, etc.) for transparency and accountability.

**Why this priority**: Valuable for trust and transparency but not critical for basic trip functionality. The trip works without it, but it enhances user confidence.

**Independent Test**: Can be fully tested by performing various actions in a trip (join, add expense, edit expense) and verifying they appear in the activity log with timestamps and actor names. Delivers standalone transparency value.

**Acceptance Scenarios**:

1. **Given** a user is a member of a trip, **When** they access the trip's activity log, **Then** they see a chronological list of all actions taken in the trip with relative timestamps (e.g., "2 hours ago")
2. **Given** a user hovers over an activity log timestamp, **When** the tooltip appears, **Then** they see the absolute timestamp (e.g., "Oct 29, 2025 2:30 PM")
3. **Given** a new member joins the trip, **When** they join, **Then** an activity log entry is created showing "[Name] joined the trip" with relative timestamp
4. **Given** a member creates an expense, **When** the expense is saved, **Then** an activity log entry is created showing "[Name] added expense [Title]" with relative timestamp
5. **Given** a member edits an expense, **When** the changes are saved, **Then** an activity log entry is created showing "[Name] edited expense [Title]" with relative timestamp
6. **Given** a member deletes an expense, **When** the deletion is confirmed, **Then** an activity log entry is created showing "[Name] deleted expense [Title]" with relative timestamp
7. **Given** a trip is created, **When** creation completes, **Then** an activity log entry is created showing "[Name] created the trip" with relative timestamp

---

### User Story 4 - Create Private Trip (Priority: P1)

A user wants to create a new trip that only invited members can access, preventing strangers from viewing or modifying their expense data.

**Why this priority**: Core to the privacy model. Without private trips, the invite system has no purpose. Must be implemented for the feature to deliver value.

**Independent Test**: Can be fully tested by creating a trip and verifying that only the creator can initially access it, and that it doesn't appear in other users' trip lists. Delivers immediate privacy protection.

**Acceptance Scenarios**:

1. **Given** a user creates a new trip, **When** they fill in trip details including their name, **Then** the trip creation form validates the name field (1-50 characters required)
2. **Given** a user submits a valid trip creation form with their name, **When** the trip is saved, **Then** the creator is automatically added as the first member with their provided name
3. **Given** a trip exists, **When** a non-member views their trip list, **Then** the trip does not appear in their list
4. **Given** a user is a member of multiple trips, **When** they view their trip list, **Then** they see only trips they have joined
5. **Given** a new trip is created, **When** creation completes, **Then** an invite code (trip ID) is automatically generated and available for sharing

---

### User Story 5 - Access Trip Invite Details (Priority: P2)

A trip member wants to view the trip's invite code and access sharing options so they can invite others.

**Why this priority**: Important for ongoing trip management and growth, but not critical for initial setup. A trip can function with just the creator until they need to invite others.

**Independent Test**: Can be fully tested by accessing trip settings or invite section and verifying the invite code is displayed along with copy/share options. Delivers standalone invitation management value.

**Acceptance Scenarios**:

1. **Given** a user is a member of a trip, **When** they access the trip's invite section, **Then** they see the trip's permanent invite code displayed
2. **Given** a user views the invite code, **When** they tap a copy button, **Then** the code is copied to their clipboard
3. **Given** a user views the invite section, **When** they tap a share button, **Then** their device's native share sheet opens with the shareable link pre-filled
4. **Given** a user views the invite section, **When** they view trip details, **Then** they see the current member list and member count

---

### Edge Cases

- What happens when a user tries to join a trip that has been deleted? (Show error: "This trip no longer exists")
- What happens when a user provides a name that already exists in the trip? (Allow duplicate names - differentiate by join timestamp if needed)
- What happens when a user clears their browser cache/data and loses their membership association? (They would need to rejoin using the invite code - anonymous auth limitation)
- What happens when the activity log grows very large (100+ entries)? (Show 50 most recent entries initially with a "Load More" button to fetch older entries in batches of 50)
- What happens when a user tries to access a trip URL directly without being a member? (Redirect to join page for that trip)
- What happens when a trip has no members (all cleared cache)? (Trip remains accessible via invite code - permanent until explicitly deleted)

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST restrict trip visibility so users only see trips they are members of
- **FR-002**: System MUST generate a permanent, unique invite code for each trip that never conflicts with other trip codes
- **FR-003**: System MUST allow users to join a trip by entering an invite code manually
- **FR-004**: System MUST allow users to join a trip by clicking a shareable link containing the invite code
- **FR-005**: System MUST prompt users to provide their name (1-50 characters) when joining a trip or creating a trip
- **FR-006**: System MUST add users to the trip's member list upon successful join
- **FR-007**: System MUST automatically add trip creators as the first member of their new trip using the name provided during trip creation
- **FR-008**: System MUST display trip invite codes and shareable links to all trip members
- **FR-009**: System MUST provide a copy-to-clipboard function for invite codes
- **FR-010**: System MUST provide a share function that opens the device's native share dialog with a pre-filled shareable link
- **FR-011**: System MUST record all significant trip actions in an activity log (trip creation, member join, expense create/edit/delete)
- **FR-012**: System MUST display the activity log to all trip members in chronological order (most recent first), showing 50 entries initially with a "Load More" button to fetch older entries in batches of 50
- **FR-013**: System MUST include the actor's name, action type, description, and timestamp in each activity log entry
- **FR-021**: System MUST display timestamps in relative format (e.g., "2 hours ago", "Yesterday") with absolute timestamp (e.g., "Oct 29, 2025 2:30 PM") shown on hover/tooltip
- **FR-014**: System MUST validate that users cannot access trip data unless they are members
- **FR-015**: System MUST show trip details (name, currency, member count) on the join page before requiring commitment
- **FR-016**: System MUST prevent duplicate membership when a user tries to join a trip they're already in
- **FR-017**: System MUST support backward compatibility so existing trip IDs function as invite codes
- **FR-018**: System MUST display an empty state message when users have not joined any trips yet
- **FR-019**: System MUST provide an option to create a new trip or join an existing trip from the empty state
- **FR-020**: System MUST include a name field in the trip creation form that accepts 1-50 characters and is required for trip creation

### Key Entities

- **Trip Membership**: Represents a user's participation in a trip, including their provided name and join timestamp. Links users to the trips they can access.

- **Activity Log Entry**: Represents a single action taken in a trip, including who performed the action (actor name), what type of action (join, expense add/edit/delete, trip create), a human-readable description, and when it occurred (timestamp). May include optional metadata about the action (e.g., expense amount, title).

- **Invite Code**: The trip's unique identifier that serves as the permanent invitation mechanism. Must be unique across all trips and never expire or change.

- **Shareable Link**: A URL containing the trip's invite code that enables one-click joining. Format: `[app-url]/trips/[invite-code]/join`

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can join a trip in under 30 seconds by either entering an invite code or clicking a shareable link
- **SC-002**: Users only see trips they are members of, with no accidental exposure of other users' trip data
- **SC-003**: 100% of trip actions (create, join, expense add/edit/delete) are logged and visible to all trip members
- **SC-004**: All trip members can generate and share invite codes/links without requiring special permissions
- **SC-005**: The invite code system works with existing trips without requiring data migration or user action (backward compatibility)
- **SC-006**: Users can identify who performed any action in a trip and when it occurred by viewing the activity log
- **SC-007**: New users can understand how to join a trip within 5 seconds of viewing the join trip screen
- **SC-008**: Trip members can share invites through any communication channel (SMS, email, social media, messaging apps) using the shareable link

## Assumptions

- Users access the application through a web browser (existing Flutter web platform)
- Users trust members of their trips and are comfortable with equal permissions (no role-based access control)
- Anonymous authentication is acceptable for the MVP, with users identified only by their self-provided names
- Trip invite codes (trip IDs) are sufficiently unique and random to prevent guessing or enumeration attacks
- Users understand that clearing browser data may require them to rejoin trips
- Activity logs will be read-only (no editing or deletion of log entries)
- The system does not need to prevent duplicate names within a trip
- Shareable links will use the application's production URL structure

## Out of Scope for MVP

- User account authentication (email/password, OAuth, etc.)
- Role-based permissions (admin, editor, viewer)
- Ability to remove members from trips
- Ability to leave a trip voluntarily
- Invite code expiration or one-time use codes
- Invite code customization (user-chosen codes)
- Activity log filtering, search, or export
- Detailed activity log metadata (e.g., showing exact fields changed in an expense edit)
- Push notifications for new activity log entries
- Trip transfer or ownership management
- User profiles or persistent identity across trips
