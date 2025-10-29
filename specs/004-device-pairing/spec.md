# Feature Specification: Device Pairing for Multi-Device Access

**Feature Branch**: `004-device-pairing`
**Created**: 2025-10-29
**Status**: Draft
**Input**: User description: "Add device pairing via temporary 8-digit codes to solve multi-device access problem. Users generate codes on existing devices to grant access to new devices without email verification."

## Problem Statement

Users who join trips on one device cannot access those trips on other devices. This forces them to manually "re-join" trips using invite codes on each new device, creating a confusing user experience.

**Root Cause**: Trip membership is stored in browser-local storage (SharedPreferences), which doesn't sync across devices. The app uses anonymous Firebase authentication without user accounts, so there's no cloud-based identity to link devices together.

**Current Pain Points**:
- User creates trip on phone → Cannot see it on laptop
- User joins trip on laptop → Cannot see it on phone
- Must re-join same trip on each device (confusing)
- Users ask: "Why can't I see my trip?"

## Proposed Solution

Add device pairing via temporary 8-digit codes that allow users to link new devices to existing trip memberships without requiring email verification or external services. This provides a simple, zero-cost solution that works within the existing anonymous auth architecture.

## Clarifications

### Session 2025-10-29

- Q: How should the system track rate limiting "per device" for brute force protection? → A: No Device Tracking - Rate limit globally per trip (any device can make 5 attempts/min)
- Q: Where should users access the "Enter Device Code" page on Device B? → A: Member-assisted flow: When Device B user tries to join with duplicate name, system prompts them to request code from existing member. Existing member generates code FOR the requesting user from trip members/settings.
- Q: Should member name matching be case-sensitive or case-insensitive when detecting duplicates? → A: Case-insensitive - "Alice", "alice", and "ALICE" are treated as the same member

## User Scenarios & Testing

### User Story 1 - Detect Duplicate Member & Request Verification (Priority: P1)

A user on Device B tries to join a trip using a name that already exists as a member. The system detects this and prompts them to request a verification code from an existing member.

**Why this priority**: This is the trigger point for device pairing. Without duplicate detection, users on new devices would be added as separate participants. This story prevents duplicate memberships and initiates the verification flow.

**Independent Test**: Can be fully tested by attempting to join a trip with a name that already exists as a member, and verifying the system shows "This name is already a member. Request a code from them to verify." Delivers value by preventing duplicate participants and guiding users to proper verification.

**Acceptance Scenarios**:

1. **Given** trip has member named "Alice", **When** user on Device B tries to join with name "Alice", **Then** system detects duplicate and shows message: "A member named 'Alice' already exists. Are you accessing from another device? Request a verification code from an existing member."
2. **Given** duplicate detected, **When** user views prompt, **Then** system shows "Enter Verification Code" field with option to contact existing members
3. **Given** user tries to join with unique name (not a duplicate), **When** they submit join form, **Then** standard join flow proceeds without code verification
4. **Given** duplicate detected, **When** user cancels verification, **Then** they return to join form to try different name

---

### User Story 2 - Generate Code for Requesting Member (Priority: P1)

An existing trip member on Device A needs to help another member verify their device. They view trip members, see pending verification requests or select a member name, and generate a verification code for that specific person.

**Why this priority**: This completes the critical pairing flow started in P1. Together, P1 and P2 form the minimal viable feature. Without member-generated codes, requesting users cannot verify their identity.

**Independent Test**: Can be tested by navigating to trip members/settings, tapping on a member name, clicking "Generate Verification Code", and verifying an 8-digit code appears. Delivers value by enabling trusted members to help verify new devices.

**Acceptance Scenarios**:

1. **Given** existing member views trip members list, **When** they tap on member "Alice" and click "Generate Code", **Then** system generates 8-digit code in format "XXXX-XXXX" tied to member name "Alice"
2. **Given** code is displayed, **When** member clicks "Copy Code" button, **Then** code is copied to clipboard and success message shown
3. **Given** code is generated for "Alice", **When** 15 minutes pass, **Then** code expires and cannot be used
4. **Given** code exists for "Alice", **When** member generates new code for "Alice", **Then** previous code for that member is invalidated
5. **Given** member generates code, **When** they share it via text/call with requesting user, **Then** requesting user can enter it on Device B to complete verification

---

### User Story 3 - Verify Using Received Code (Priority: P1)

A user on Device B receives a verification code from an existing member and enters it to complete device pairing and gain trip access.

**Why this priority**: This is the final step of the P1 flow. Without code entry and validation, the entire member-assisted verification process cannot complete. This story delivers the actual device pairing.

**Independent Test**: Can be tested by entering a valid code in the verification prompt on Device B and verifying trip access is granted. Delivers value by completing the multi-device access solution.

**Acceptance Scenarios**:

1. **Given** user on Device B sees verification prompt, **When** they enter valid code received from member, **Then** system validates code matches member name "Alice" and grants trip access
2. **Given** user enters invalid code, **When** they submit, **Then** error message "Invalid or expired code" is shown
3. **Given** user enters expired code (>15 min old), **When** they submit, **Then** error message "Code has expired. Request a new one from a member." is shown
4. **Given** code was generated for "Alice" but user entered name "Bob", **When** they try to use code, **Then** error message "Code doesn't match your member name" is shown
5. **Given** code is successfully used by "Alice", **When** another user tries same code, **Then** error message "Code already used" is shown
6. **Given** user enters code without hyphen (e.g., "12345678"), **When** they submit, **Then** system accepts it (hyphen is optional)

---

### User Story 4 - Security - Rate Limiting (Priority: P2)

The system prevents brute force attacks by limiting code validation attempts to protect trip access.

**Why this priority**: Critical for security but not blocking for basic functionality. Users can test P1 and P2 without rate limiting, but it must be in place before public release.

**Independent Test**: Can be tested by attempting to validate codes 6 times in quick succession and verifying the 6th attempt is blocked. Delivers security value independently.

**Acceptance Scenarios**:

1. **Given** user makes 5 failed validation attempts in 1 minute, **When** they attempt 6th validation, **Then** error message "Too many attempts. Please wait 60 seconds." is shown
2. **Given** user is rate limited, **When** they wait 60 seconds, **Then** they can attempt validation again
3. **Given** user makes 3 failed attempts, **When** they wait 2 minutes then try again, **Then** attempt counter is reset and validation proceeds normally

---

### User Story 5 - View Active Codes (Priority: P3)

A trip member wants to see all currently active pairing codes for their trip and optionally revoke them.

**Why this priority**: Nice-to-have for advanced users and security consciousness, but not required for basic functionality. Most users will generate and use codes immediately without needing to manage them.

**Independent Test**: Can be tested by generating multiple codes and viewing them in a list in Trip Settings. Delivers transparency value independently.

**Acceptance Scenarios**:

1. **Given** user is in Trip Settings, **When** they view "Active Device Codes" section, **Then** all unexpired, unused codes are listed with creation time and expiry time
2. **Given** code is displayed in list, **When** user clicks "Revoke" button, **Then** code is immediately invalidated and removed from list
3. **Given** no active codes exist, **When** user views section, **Then** message "No active codes" is shown

---

### Edge Cases

- What happens when user's browser clears local storage after device is paired? → User must re-verify by requesting new code from existing member (acceptable limitation, documented in help)
- How does system handle simultaneous code generation for same member? → Latest code invalidates previous (only one active code per member at a time)
- What if existing member generates code for "Alice" but wrong person uses it? → Code only works if requesting user's name is "Alice" (validated during code check)
- What if user on Device B types wrong name that doesn't match any member? → Standard join flow proceeds (no verification needed for new unique members)
- What if no existing members are online to generate code? → User must wait for member availability or join with different name temporarily
- What happens if Firestore is offline during code generation? → Error shown: "Cannot generate code offline. Check connection."
- What if code validation times out? → Show error: "Validation timed out. Please try again."
- What happens when trip has 100+ members and codes are generated for many? → Firestore scales automatically, within free tier limits

## Requirements

### Functional Requirements

- **FR-001**: System MUST generate cryptographically secure random 8-digit codes using `Random.secure()` to prevent predictability
- **FR-002**: System MUST store pairing codes in Firestore subcollection `/trips/{tripId}/deviceLinkCodes/{autoId}` with fields: code, memberName, createdAt, expiresAt, used, usedAt (code is generated FOR a specific member name)
- **FR-003**: System MUST set code expiry to 15 minutes from generation time
- **FR-004**: System MUST validate codes by checking all 6 rules: (1) code exists in Firestore, (2) not expired (expiresAt > now), (3) not used (used=false), (4) matches specified trip, (5) code's memberName matches requesting user's name (case-insensitive comparison), (6) not rate limited (validation attempts within allowed threshold)
- **FR-005**: System MUST mark codes as used (used=true) on successful validation to prevent reuse
- **FR-006**: System MUST accept code input with or without hyphen (e.g., both "1234-5678" and "12345678" are valid)
- **FR-007**: System MUST display codes in hyphenated format "XXXX-XXXX" for readability
- **FR-008**: System MUST detect when user tries to join trip with name matching existing participant (case-insensitive comparison via storing both memberName and memberNameLower fields) and trigger verification prompt instead of adding duplicate
- **FR-009**: System MUST cache trip ID in local storage after successful pairing (reusing existing caching mechanism)
- **FR-010**: System MUST limit code validation attempts to 5 per minute per trip (global rate limit across all devices) via application logic with Firestore-backed attempt tracking
- **FR-011**: System MUST show fixed 60-second wait message after rate limit is reached (5 attempts in 1 minute): "Too many attempts. Please wait 60 seconds before trying again"
- **FR-012**: System MUST invalidate previous code when new code is generated for same member name (only one active code per member at a time)
- **FR-013**: System MUST provide "Generate Code" option when existing member views trip members list (accessible per member)
- **FR-014**: System MUST show verification code prompt when duplicate member name is detected during trip join attempt
- **FR-015**: System MUST copy code to clipboard when user clicks "Copy Code" button
- **FR-016**: System MUST show visual countdown of code expiry time (e.g., "Expires in 14:32")
- **FR-017**: System MUST filter out expired codes client-side when querying (MVP approach). Note: Server-side auto-deletion would require Cloud Functions (deferred to future enhancement due to cost implications)
- **FR-018**: Users MUST be able to manually revoke active codes before expiry (P3 feature)
- **FR-019**: System MUST show clear error messages for all failure cases: invalid code, expired code, already used, rate limited, network error

### Key Entities

- **DeviceLinkCode**: Represents a temporary pairing code for device verification
  - code (8-digit string)
  - tripId (which trip this grants access to)
  - memberName (which member this code was generated FOR)
  - createdAt (timestamp of generation)
  - expiresAt (timestamp when code becomes invalid, 15 min from creation)
  - used (boolean flag, true after successful verification)
  - usedAt (timestamp when code was used)

- **Trip** (existing entity, enhanced): No structural changes, but pairing codes are linked via tripId

- **Participant** (existing entity): Members who already exist in trip. Device verification allows them to access trip from additional devices without creating duplicates

## Success Criteria

### Measurable Outcomes

- **SC-001**: Users can generate a pairing code in under 2 seconds from clicking "Link Another Device" button
- **SC-002**: Users can complete full device pairing flow (generate code on Device A, enter code on Device B) in under 3 minutes
- **SC-003**: Code validation completes in under 1 second (excluding network latency)
- **SC-004**: System successfully prevents brute force attacks by blocking validation after 5 attempts in 1 minute
- **SC-005**: 95% of users successfully pair devices on first attempt without errors
- **SC-006**: Zero external service costs incurred (all operations within Firestore free tier: <50K reads, <20K writes per day)
- **SC-007**: Feature supports 1000 concurrent users generating and validating codes without performance degradation
- **SC-008**: Expired codes (>15 minutes old) are rejected 100% of the time during validation
- **SC-009**: Used codes cannot be reused (100% prevention of duplicate pairing with same code)
- **SC-010**: System handles Firestore offline scenarios gracefully with clear error messages (no silent failures)

## Assumptions

- Users have reliable internet connection during pairing process (offline pairing not supported)
- Users can communicate pairing code between devices via external means (text message, email, verbally, etc.)
- 15-minute expiry window is sufficient for users to transfer code and complete pairing
- Users understand concept of temporary codes (similar to 2FA codes, password reset codes)
- Firestore free tier limits (50K reads, 20K writes/day) are sufficient for expected usage (<1000 users × 2 devices)
- Device B has access to trip invite code or trip ID (user must know which trip they're joining)
- Anonymous Firebase auth continues to be used (no migration to full user accounts)
- Browser local storage is reliable (not frequently cleared by users)

## Out of Scope

The following are explicitly NOT included in this feature and may be considered for future iterations:

- QR code pairing (requires camera access, more complex UX for web app)
- Email verification as alternative to device codes
- Push notifications when new device is paired
- Multi-device management dashboard (view/revoke all paired devices)
- Device naming/labeling (e.g., "iPhone", "Work Laptop")
- Permanent backup codes (2FA-style recovery codes)
- Analytics/tracking of device pairing patterns
- Automatic device detection and suggestions
- Single Sign-On (SSO) or OAuth integration
- Migration from anonymous auth to full user accounts

## Dependencies

- **Existing Systems**:
  - Firebase/Firestore infrastructure (already set up)
  - Anonymous Firebase Authentication (already implemented)
  - TripCubit and trip join flow (reused for adding participants)
  - SharedPreferences local storage (reused for caching trip IDs)
  - Trip invite system (003-trip-invite-system feature)

- **New Dependencies**:
  - None (feature uses only existing infrastructure)

- **External Services**:
  - None (zero external dependencies, all in-house)

## Risks & Mitigation

| Risk | Impact | Likelihood | Mitigation |
|------|--------|-----------|------------|
| Brute force code guessing | High | Low | 8-digit codes (100M combinations) + rate limiting (5 attempts/min) + 15-min expiry |
| User shares code publicly | Medium | Low | 15-minute expiry limits exposure window + user education messaging |
| User loses code before using | Low | Medium | Codes can be regenerated instantly (invalidates old code) |
| Browser clears local storage | Medium | Medium | User must re-pair device (acceptable, documented in help) |
| Firestore costs exceed free tier | Low | Very Low | Usage well within limits: 1000 users × 2 devices × 10 attempts = 20K ops/month (<50K limit) |
| Network timeout during validation | Medium | Medium | Clear error messages + retry mechanism + timeout set to 10 seconds |
| Code enumeration attack | Very Low | Very Low | Random secure generation + Firestore query required (can't enumerate) |
| Simultaneous code usage | Very Low | Very Low | Firestore transaction ensures one-time use via atomic update |

## Implementation Notes

**Technology-Agnostic Guidance** (for planning phase):

1. **Code Generation**: Use industry-standard secure random number generation. Display in human-readable format with hyphen separator.

2. **Storage**: Use cloud document database with subcollections. Enable automatic cleanup of old documents.

3. **Validation**: Implement server-side validation to prevent client-side tampering. Use atomic operations to ensure one-time use.

4. **Rate Limiting**: Leverage database security rules rather than custom backend to minimize infrastructure.

5. **User Experience**: Follow patterns from popular apps (Signal, Telegram) for temporary code flows. Provide immediate feedback for all actions.

6. **Testing**: Focus on edge cases: expired codes, used codes, invalid codes, network failures, concurrent access.

7. **Security**: All code operations must happen server-side (Firestore). Never trust client-side validation alone.

## Open Questions

None at this time. All critical design decisions have been made based on research and industry best practices.
