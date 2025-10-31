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

### Edge Cases

- What happens when a category is customized in one trip but then deleted globally by another user?
- How does the system handle a trip with 50+ customized categories (performance)?
- What happens when user customizes a category but later that category's global default changes?
- How does the system behave when customization data fails to load (network error)?
- What happens when user tries to customize a category they haven't used in any expenses yet?

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

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can customize a category icon or color in under 30 seconds from trip settings
- **SC-002**: Customized visuals appear consistently across all screens (expense forms, lists, statistics) within 200ms of data load
- **SC-003**: System supports customization of up to 50 categories per trip without performance degradation
- **SC-004**: 95% of users successfully identify which categories are customized versus using defaults when viewing the customization screen
- **SC-005**: Customizations persist across app restarts and device syncs with 100% reliability
- **SC-006**: App performance (page load times) degrades by less than 5% when loading trips with customizations versus trips without

## Assumptions

- Users understand that customizations apply only to the current trip and don't affect global categories
- Category customizations are stored in a trip-specific subcollection (`/trips/{tripId}/categoryCustomizations/{categoryId}`)
- Default icon/color values remain stored in the global `/categories` collection
- Customizations are optional - trips can function perfectly well without any customizations
- Mobile-first design principles apply (touch targets 44x44px minimum)
- Icon picker will use Material Icons library (same as global categories)
- Color picker will offer a curated palette of 20-30 predefined colors (same as global categories)
- Customizations are cached in memory for the duration of a trip session

## Out of Scope

- Renaming categories on a per-trip basis (name must remain global for consistency)
- Creating trip-specific categories that don't exist globally
- Customizing category behavior or rules per trip
- Bulk customization operations (e.g., "apply theme to all categories")
- Sharing or importing customization schemes between trips
- Custom icon uploads (limited to Material Icons library)
- Custom color picker (limited to predefined palette)

## Dependencies

- Feature 008-global-category-system must be complete (already done)
- Global categories must be seeded and functional
- Category selector widget must exist and be functional
- Trip settings page must be accessible to trip members
