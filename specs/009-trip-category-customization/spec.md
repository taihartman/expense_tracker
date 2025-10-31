# Feature Specification: Per-Trip Category Visual Customization

**Feature Branch**: `009-trip-category-customization`
**Created**: 2025-10-31
**Status**: Draft
**Input**: User description: "Allow trips to customize category icons and colors while keeping global category system. Each trip can override the default icon/color for any category without affecting other trips."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Customize Category Icon for Specific Trip (Priority: P1)

Alice is managing her "Japan Trip" and wants the "Meals" category to use a "🍜 ramen bowl" icon instead of the default "🍽️ restaurant" icon, since most of their meals are from ramen shops. She wants this change to apply only to the Japan trip, not affecting her other trips.

**Why this priority**: Core feature functionality - enables the primary use case of per-trip visual personalization without affecting global category data.

**Independent Test**: Can be fully tested by: (1) Opening trip settings, (2) Selecting "Customize Categories", (3) Changing the "Meals" icon, (4) Creating an expense with "Meals" category and verifying the custom icon appears. Delivers immediate value by allowing visual personalization per trip.

**Acceptance Scenarios**:

1. **Given** a trip with expenses using the "Meals" category (global default icon: "restaurant"), **When** user navigates to Trip Settings → "Customize Categories" and changes "Meals" icon to "fastfood", **Then** all expenses in that trip now display the "fastfood" icon for "Meals" category
2. **Given** the "Meals" category has been customized in Trip A with "fastfood" icon, **When** user creates a new expense in Trip B using "Meals" category, **Then** Trip B displays the global default "restaurant" icon (customization is trip-specific)
3. **Given** a customized category icon in a trip, **When** user taps "Reset to Default" for that category, **Then** the category reverts to the global default icon

---

### User Story 2 - Customize Category Color for Specific Trip (Priority: P2)

Bob wants his "Work Trip" expenses to use a professional blue color scheme, so he customizes the "Transport" category from green to blue. This helps him visually distinguish work trips from personal trips.

**Why this priority**: Complements icon customization with color personalization, enhancing visual organization without requiring icon customization first.

**Independent Test**: Can be tested independently by: (1) Customizing category colors in trip settings, (2) Verifying color changes appear in expense forms and lists. Works standalone without icon customization.

**Acceptance Scenarios**:

1. **Given** a trip with the "Transport" category (global default color: "#2196F3"), **When** user changes the color to "#9C27B0" in trip settings, **Then** all "Transport" expenses in that trip display with the purple color
2. **Given** customized category colors in a trip, **When** user views the expense list, **Then** category chips display with the custom colors
3. **Given** a category with both custom icon and color, **When** user resets only the color, **Then** the color reverts to default while the custom icon remains

---

### User Story 3 - View Which Categories Are Customized (Priority: P3)

Clara manages multiple trips and wants to quickly see which categories have been customized in each trip, so she can maintain consistency or identify trips with personalized visuals.

**Why this priority**: Nice-to-have visibility feature that helps users manage customizations across trips but isn't critical for core functionality.

**Independent Test**: Can be tested by: (1) Customizing several categories, (2) Viewing the "Customize Categories" screen, (3) Verifying customized categories are visually indicated (e.g., with a badge or different styling). Delivers value as a standalone feature.

**Acceptance Scenarios**:

1. **Given** multiple categories with customizations in a trip, **When** user opens "Customize Categories" screen, **Then** customized categories display a visual indicator (e.g., "Customized" badge)
2. **Given** a mix of customized and default categories, **When** user scrolls through the category list, **Then** default categories show "Using global default" text
3. **Given** a customized category, **When** user views trip statistics, **Then** category appears with its customized visual (icon/color)

---

### User Story 4 - Seamless Icon Voting System (Priority: P1)

David creates an expense for "Skiing" and notices the category uses a tree icon (incorrect choice by the original creator). He customizes it to a ski icon for his trip. Unknown to David, this action automatically votes for the ski icon. After several other users make the same customization choice, the global default icon automatically updates to the ski icon, improving the experience for all future users.

**Why this priority**: Solves the "first creator wins" problem where poor icon choices become permanent. Enables crowd-sourced improvement of category icons without requiring explicit voting UI, making the system self-correcting over time.

**Independent Test**: Can be tested by: (1) Creating a category with a suboptimal icon, (2) Having multiple users customize the same icon for their trips, (3) Verifying the global default icon updates after reaching vote threshold. Works independently as it triggers from existing customization flow.

**Acceptance Scenarios**:

1. **Given** a category "Skiing" with global default icon "tree" (suboptimal), **When** 3 users customize it to "ski" icon for their respective trips, **Then** the global default icon updates to "ski" for all new users
2. **Given** a user customizes a category icon, **When** the customization is saved successfully, **Then** their icon preference is recorded as a vote (silently, no UI notification)
3. **Given** a global category icon has been updated via voting, **When** a user who hasn't customized that category views it, **Then** they see the new improved default icon
4. **Given** multiple icon choices for a category (e.g., "restaurant": 5 votes, "fastfood": 3 votes), **When** viewing category analytics, **Then** the icon with the most votes becomes the global default

---

### User Story 5 - Similar Category Detection (Priority: P2)

Emma is creating an expense and types "Ski" as a new category name. Before she can create it with a random icon, the system detects that "Skiing" already exists (used 45 times with ski icon) and suggests using the existing category instead. This prevents duplicate categories with different icons and reduces confusion.

**Why this priority**: Preventative measure that stops the "first creator wins" problem before it starts. Reduces category fragmentation and improves data quality by guiding users toward existing categories.

**Independent Test**: Can be tested by: (1) Creating a well-established category (e.g., "Skiing"), (2) Attempting to create similar names ("Ski", "skiing", "Skiiing"), (3) Verifying similarity warnings appear. Works independently during category creation flow.

**Acceptance Scenarios**:

1. **Given** an existing category "Skiing" (used 45 times), **When** user attempts to create a category named "Ski", **Then** system shows a banner: "Similar category exists: Skiing (⛷️, used 45 times)" with "Use Existing" and "Create Anyway" buttons
2. **Given** similar category suggestions during creation, **When** user taps "Use Existing", **Then** the existing category is selected and creation flow is cancelled
3. **Given** similar category warning appears, **When** user taps "Create Anyway", **Then** the new category is created and vote tracking begins immediately
4. **Given** multiple similar categories exist (e.g., "Food", "Foods", "Meal"), **When** user types "food", **Then** system shows the most-used similar category first in suggestions

---

### Edge Cases

- What happens when a category is customized in one trip but then deleted globally by another user?
- How does the system handle a trip with 50+ customized categories (performance)?
- What happens when user customizes a category but later that category's global default changes?
- How does the system behave when customization data fails to load (network error)?
- What happens when user tries to customize a category they haven't used in any expenses yet?
- What happens when two different icons reach the vote threshold simultaneously?
- How does the system handle malicious voting (one user creating many trips to vote)?
- What happens when similar category detection finds 10+ matches (UI overflow)?
- How does voting behave when icon preference data fails to save?
- What happens when a global icon update occurs while a user is actively customizing that category?

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST allow users to customize the icon of any category on a per-trip basis
- **FR-002**: System MUST allow users to customize the color of any category on a per-trip basis
- **FR-003**: System MUST display customized icons and colors throughout the app (expense forms, lists, statistics) for the specific trip
- **FR-004**: System MUST preserve global category data (name, usage tracking) when customizations are applied
- **FR-005**: System MUST allow users to reset customizations to global defaults on a per-category basis
- **FR-006**: System MUST show visual indicators distinguishing customized categories from default categories
- **FR-007**: System MUST persist category customizations across app sessions and device syncs
- **FR-008**: System MUST load customizations efficiently without degrading app performance
- **FR-009**: System MUST handle missing or failed customization data gracefully (fallback to global defaults)
- **FR-010**: System MUST only show categories used in expenses within the trip in the customization screen
- **FR-011**: System MUST provide type-safe icon selection using a CategoryIcon enum with all 30 available Material Icons
- **FR-012**: System MUST eliminate code duplication by using a single shared IconHelper utility for string-to-IconData conversion
- **FR-013**: System MUST track icon preferences when users customize category icons (voting mechanism)
- **FR-014**: System MUST update global category default icons when an alternative icon receives 3 or more votes
- **FR-015**: System MUST detect similar category names during creation using fuzzy matching (80%+ similarity threshold)
- **FR-016**: System MUST suggest existing categories with their icons and usage counts before allowing creation of similar categories

### Key Entities

- **CategoryCustomization**: Represents a visual override for a category within a specific trip
  - Links to a global category (by ID)
  - Links to a specific trip (by ID)
  - Contains optional custom icon (string identifier, e.g., "fastfood")
  - Contains optional custom color (hex code, e.g., "#FF9800")
  - Tracks when the customization was last updated

- **Category** (existing, enhanced): Global category entity
  - Maintains default icon and color values
  - Continues to track usage across all trips
  - Remains the single source of truth for category names and data

- **CategoryIcon** (enum): Type-safe representation of all available Material Icons for categories
  - Contains 30 predefined icon values (category, restaurant, directionsCar, hotel, localActivity, etc.)
  - Provides conversion methods: string ↔ enum ↔ IconData
  - Ensures compile-time type safety for icon selection
  - Used by icon pickers and all UI components displaying category icons

- **CategoryIconPreference**: Tracks voting data for icon choices per category
  - Links to a global category (by ID)
  - Maps icon names to vote counts (e.g., {"restaurant": 5, "fastfood": 3})
  - Tracks the currently most popular icon
  - Updates automatically when users customize category icons
  - Triggers global icon updates when vote thresholds are reached

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can customize a category icon or color in under 30 seconds from trip settings
- **SC-002**: Customized visuals appear consistently across all screens (expense forms, lists, statistics) within 200ms of data load
- **SC-003**: System supports customization of up to 50 categories per trip without performance degradation
- **SC-004**: 95% of users successfully identify which categories are customized versus using defaults when viewing the customization screen
- **SC-005**: Customizations persist across app restarts and device syncs with 100% reliability
- **SC-006**: App performance (page load times) degrades by less than 5% when loading trips with customizations versus trips without
- **SC-007**: All 30 available category icons render correctly in all UI components (icon picker, category selector, expense lists) with zero fallback to default icons
- **SC-008**: Icon string-to-IconData conversion code exists in exactly 1 shared utility location (zero code duplication across widgets)
- **SC-009**: Global category icons improve accuracy over time, with suboptimal icons replaced by community-preferred icons within 10 customizations by different users
- **SC-010**: Users are warned about similar existing categories 90% of the time when attempting to create categories with 80%+ name similarity

## Assumptions

- Users understand that customizations apply only to the current trip and don't affect global categories
- Category customizations are stored in a trip-specific subcollection (`/trips/{tripId}/categoryCustomizations/{categoryId}`)
- Default icon/color values remain stored in the global `/categories` collection
- Customizations are optional - trips can function perfectly well without any customizations
- Mobile-first design principles apply (touch targets 44x44px minimum)
- Icon picker will use Material Icons library (same as global categories)
- Color picker will offer a curated palette of 20-30 predefined colors (same as global categories)
- Customizations are cached in memory for the duration of a trip session
- Icon voting system operates silently without explicit user notification (unless global default changes)
- Vote threshold of 3 is sufficient to indicate community consensus for icon changes
- Icon preference data is stored in a top-level collection (`/categoryIconPreferences/{categoryId}`)
- Voting operates on a per-user basis (one vote per user per category, regardless of number of trips)
- Similar category detection uses string similarity algorithms (80% threshold balances precision and recall)
- Fuzzy matching for category names is case-insensitive and handles typos within edit distance of 2
- Type-safe CategoryIcon enum will be used throughout the codebase for compile-time safety
- All 30 Material Icons in CategoryIcon enum are visually distinct and appropriate for expense categories

## Out of Scope

- Renaming categories on a per-trip basis (name must remain global for consistency)
- Creating trip-specific categories that don't exist globally
- Customizing category behavior or rules per trip
- Bulk customization operations (e.g., "apply theme to all categories")
- Sharing or importing customization schemes between trips
- Custom icon uploads (limited to Material Icons library)
- Custom color picker (limited to predefined palette)
- Explicit voting UI for icon preferences (voting is implicit through customization)
- Admin controls or moderation for icon voting (crowd-sourced without manual intervention)
- Historical tracking of icon changes per category (only current state is maintained)
- User-level icon voting analytics or dashboards
- Machine learning-based category suggestions (uses rule-based fuzzy matching only)
- Automatic merging of duplicate categories created by different users

## Dependencies

- Feature 008-global-category-system must be complete (already done)
- Global categories must be seeded and functional
- Category selector widget must exist and be functional
- Trip settings page must be accessible to trip members
