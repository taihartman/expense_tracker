# Feature Specification: Global Category Management System

**Feature Branch**: `008-global-category-system`
**Created**: 2025-10-31
**Status**: Draft
**Input**: User description: "Global category management system with smart defaults, autocomplete, and spam prevention"

## Clarifications

### Session 2025-10-31

- Q: When a rate-limited user searches for a non-existent category, what should the UI display? → A: Show "Create" button but disabled with tooltip/message: "Please wait before creating more categories"
- Q: What characters should be allowed in category names? → A: Letters (any language), numbers, spaces, and basic punctuation (apostrophes, hyphens, ampersands) only
- Q: How should existing expense categoryId references be handled during migration? → A: Automatically update all expense categoryId references to point to the new consolidated global category IDs during migration

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Quick Category Selection from Popular Defaults (Priority: P1)

Sarah is adding a restaurant expense during her group trip. She opens the expense form and immediately sees 5 popular category options (Meals, Transport, Accommodation, Activities, Shopping) as horizontal chips. She taps "Meals" and continues filling out her expense.

**Why this priority**: This is the most common use case - 80%+ of expenses use popular categories. Users need instant access to frequently-used categories without extra steps. This delivers immediate value and can function as a complete MVP.

**Independent Test**: Can be fully tested by creating an expense and selecting from the 5 default popular categories. Delivers value by allowing users to categorize expenses efficiently without any additional features.

**Acceptance Scenarios**:

1. **Given** a user is creating a new expense, **When** they view the category field, **Then** they see 5 horizontal chips displaying the most popular categories with icons and colors
2. **Given** popular categories are displayed, **When** the user taps a category chip, **Then** that category is selected and visually highlighted
3. **Given** a user is editing an existing expense with a category, **When** they view the category field, **Then** the previously selected category chip is pre-selected
4. **Given** no category is selected, **When** the user saves the expense, **Then** the expense is saved without a category (optional field)

---

### User Story 2 - Browse and Search All Available Categories (Priority: P2)

Mark is adding a "Ski Lift Pass" expense but doesn't see that category in the popular 5. He taps the "Other" chip which opens a bottom sheet showing all available categories. He types "ski" in the search field and sees "Ski Equipment", "Ski Passes", and "Winter Sports" appear. He selects "Ski Passes" and returns to the expense form with that category applied.

**Why this priority**: Enables discovery of the full category library while preventing category duplication. This is critical for the global category model to work effectively - users must be able to find existing categories before creating duplicates.

**Independent Test**: Can be tested independently by opening the category browser, searching for existing categories, and selecting them. Delivers value by providing access to hundreds of categories beyond the top 5.

**Acceptance Scenarios**:

1. **Given** a user is selecting a category, **When** they tap the "Other" chip, **Then** a bottom sheet opens displaying all available categories sorted by popularity
2. **Given** the category browser is open, **When** the user types in the search field, **Then** categories are filtered in real-time using case-insensitive matching
3. **Given** search results are displayed, **When** the user taps a category, **Then** that category is selected, the bottom sheet closes, and the expense form shows the selected category
4. **Given** the category browser is open, **When** the user scrolls down, **Then** they can browse through all available categories (pagination if needed)
5. **Given** a user searches for "MEAL" (uppercase), **When** results appear, **Then** "Meals", "Meal Plans", and other variations are shown (case-insensitive)
6. **Given** the category browser is open, **When** the user taps outside the sheet or swipes down, **Then** the bottom sheet closes without selecting a category

---

### User Story 3 - Create New Custom Categories (Priority: P3)

Lisa is adding an expense for "Pet Boarding" but can't find it in the existing categories. In the category browser bottom sheet, she types "pet boarding" in the search field. When no results appear, she sees a "Create 'Pet Boarding'" option at the top. She taps it, sees a category creation dialog with the name pre-filled and default icon/color. She taps "Create" and her new category is added to the global pool and selected for her expense.

**Why this priority**: Allows users to contribute new categories to the shared pool when needed. This enables the category library to grow organically while the spam prevention protects against abuse. This is P3 because most users will find what they need in P1/P2.

**Independent Test**: Can be tested independently by attempting to create new categories with various names, verifying spam prevention triggers, and confirming categories are available globally after creation.

**Acceptance Scenarios**:

1. **Given** a user is searching in the category browser, **When** no matching categories exist, **Then** a "Create '[search term]'" option appears at the top of results
2. **Given** the user taps "Create" option, **When** the creation dialog opens, **Then** the category name field is pre-filled with the search term, and default icon/color are shown
3. **Given** the creation dialog is open, **When** the user taps "Create" without changing anything, **Then** the new category is created with the provided name and default icon/color
4. **Given** a user has created 3 categories in the last 5 minutes, **When** they attempt to create another, **Then** they see an error message: "Please wait a moment before creating more categories"
5. **Given** a rate-limited user is searching for a non-existent category, **When** search returns no results, **Then** the "Create" button appears disabled with message: "Please wait before creating more categories"
6. **Given** a new category is created, **When** another user in a different trip searches for that category name, **Then** the category appears in their search results (global pool)
7. **Given** a user creates a category with the same name as an existing one (case-insensitive), **When** they tap "Create", **Then** they see an error: "This category already exists" and can select the existing one instead

---

### User Story 4 - Customize Category Icons (Priority: P4)

Tom is creating a "Brewery Tours" category. In the category creation dialog, he taps the icon selector and browses through available Material icons. He finds the "local_bar" icon and selects it. He also picks an amber color (#FFC107) from the color palette. His custom category is created with these visual attributes and will be available to all users.

**Why this priority**: Enhances personalization and helps categories become more recognizable. This is P4 because the system provides sensible defaults, making customization optional but nice-to-have.

**Independent Test**: Can be tested independently by creating categories and customizing their icons/colors, then verifying other users see these customizations when they use the same categories.

**Acceptance Scenarios**:

1. **Given** the category creation dialog is open, **When** the user taps the icon field, **Then** an icon picker opens showing Material icons organized by category
2. **Given** the icon picker is open, **When** the user searches for an icon name, **Then** matching icons are filtered and displayed
3. **Given** the user selects a custom icon, **When** they save the category, **Then** the category is created with the selected icon
4. **Given** a category name matches an existing category with icons, **When** the creation dialog opens, **Then** the most frequently used icon for that category name is shown as default
5. **Given** the category creation dialog is open, **When** the user taps the color field, **Then** a color picker opens with preset colors
6. **Given** multiple users have selected different icons for the same category name, **When** a new user creates that category, **Then** the most frequently used icon is suggested as default

---

### Edge Cases

- **What happens when a trip is created for the first time?** The system seeds the trip with the top 5 most popular global categories automatically
- **What happens when the global category pool is empty (new system)?** The system seeds with 6 default categories (Meals, Transport, Accommodation, Activities, Shopping, Other) on first initialization
- **How does the system handle rapid category creation attempts?** Rate limiting prevents users from creating more than 3 categories per 5-minute window
- **What happens when two users create the same category simultaneously?** The system performs case-insensitive duplicate checking; second creation attempt shows "already exists" error
- **What happens when a user searches with special characters or emojis?** Search sanitizes input and performs partial, case-insensitive matching on category names
- **What happens when a user tries to create a category with invalid characters (emojis, special symbols)?** System displays validation error: "Category names can only contain letters, numbers, spaces, and basic punctuation"
- **What happens when the category browser is opened on a slow connection?** Show cached popular categories immediately, load remaining categories in background with loading indicator
- **What happens when a category has no icon selected?** Display a default "category" icon (Material: "label")
- **What happens to existing trip-specific categories after migration?** Existing categories are migrated to the global pool with their trip associations preserved for reference; duplicate names are merged based on usage counts
- **What happens to existing expenses during migration?** All expense categoryId references are automatically updated to point to the new consolidated global category IDs; no data loss occurs and all categorization is preserved

## Requirements *(mandatory)*

### Functional Requirements

#### Global Category Management

- **FR-001**: System MUST maintain a single global category collection shared across all trips and users
- **FR-002**: System MUST track usage count for each category (incremented each time a category is assigned to an expense)
- **FR-003**: System MUST track icon usage frequency for each category name to determine the most popular icon
- **FR-004**: System MUST automatically seed new trips with the top 5 most popular categories based on global usage counts
- **FR-005**: System MUST perform case-insensitive duplicate checking when creating new categories (e.g., "meals" = "Meals" = "MEALS")

#### Category Selection Interface

- **FR-006**: Expense forms MUST display the top 5 most popular categories as horizontal chip selectors by default
- **FR-007**: Expense forms MUST include an "Other" chip that opens a category browser bottom sheet when tapped
- **FR-008**: The category browser MUST display all available categories sorted by popularity (usage count descending)
- **FR-009**: Selected categories MUST be visually highlighted in the chip selector and persist when returning from the category browser

#### Category Search and Browse

- **FR-010**: The category browser MUST include a search field that filters categories in real-time
- **FR-011**: Search MUST be case-insensitive and match partial category names (e.g., "meal" matches "Meals", "Meal Plan")
- **FR-012**: When search returns no results, the browser MUST display a "Create '[search term]'" option
- **FR-013**: The category browser MUST support scrolling/pagination for viewing all categories
- **FR-014**: Categories MUST display their icon and color in all interfaces (chips, browser, search results)

#### Category Creation

- **FR-015**: Users MUST be able to create new categories by tapping the "Create" option in the search results
- **FR-016**: The category creation dialog MUST pre-fill the name field with the user's search term
- **FR-017**: The category creation dialog MUST provide default icon and color based on the most popular choices for similar category names, or sensible defaults if no data exists
- **FR-018**: Users MUST be able to customize the category icon by selecting from Material icons
- **FR-019**: Users MUST be able to customize the category color from a preset color palette
- **FR-020**: System MUST validate that category names are between 1-50 characters
- **FR-020a**: System MUST validate that category names contain only letters (any language/Unicode), numbers, spaces, and basic punctuation (apostrophes, hyphens, ampersands); reject names with emojis or special Unicode characters
- **FR-021**: System MUST enforce rate limiting: maximum 3 category creations per user per 5-minute window
- **FR-022**: System MUST prevent duplicate category creation with case-insensitive name checking
- **FR-022a**: When a rate-limited user searches for a non-existent category, the "Create" option MUST be displayed but disabled with an explanatory message: "Please wait before creating more categories"

#### Category Icons and Customization

- **FR-023**: The icon picker MUST display Material icons organized by functional categories
- **FR-024**: The icon picker MUST include search functionality to find icons by name
- **FR-025**: When creating a category with a name that matches existing categories (case-insensitive), the system MUST suggest the most frequently used icon as default
- **FR-026**: The color picker MUST provide at least 12 preset colors commonly used for categories
- **FR-027**: Default icon for categories with no custom selection MUST be "label" (Material icon)

#### Performance and Caching

- **FR-028**: The system MUST cache the top 20 most popular categories locally for offline access
- **FR-029**: The category browser MUST load cached popular categories immediately while fetching remaining categories in the background
- **FR-030**: Category popularity rankings MUST be updated in near real-time (within 1 minute of expense creation)

#### Migration and Initialization

- **FR-031**: On system initialization, if the global category pool is empty, the system MUST seed with 6 default categories: Meals, Transport, Accommodation, Activities, Shopping, Other
- **FR-032**: Existing trip-specific categories MUST be migrated to the global pool with duplicate consolidation based on case-insensitive name matching and usage counts
- **FR-032a**: During migration, all existing expense categoryId references MUST be automatically updated to point to the new consolidated global category IDs, maintaining all categorization data

### Key Entities

- **GlobalCategory**: Represents a category in the shared global pool
  - **Attributes**: id (unique), name (string, 1-50 chars), icon (Material icon name), color (hex code), usageCount (integer, incremented on each use), createdAt, updatedAt
  - **Relationships**: Can be associated with multiple expenses across all trips

- **CategoryIconUsage**: Tracks icon selection frequency for category names
  - **Attributes**: categoryName (case-insensitive), iconName (Material icon), usageCount (integer)
  - **Purpose**: Determines the most popular icon for category names to provide smart defaults

- **UserCategoryCreationLog**: Tracks category creation for spam prevention
  - **Attributes**: userId, categoryId, createdAt
  - **Purpose**: Enables rate limiting (3 creations per 5 minutes per user)

- **TripCategoryCache**: Stores the top 5 popular categories for each trip
  - **Attributes**: tripId, categoryIds (array of 5 most popular global category IDs), lastUpdated
  - **Purpose**: Quick access to default categories for trip expense forms

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can select a category for their expense in under 5 seconds for 90% of cases (using popular defaults)
- **SC-002**: Category search returns results in under 500ms for 95% of queries
- **SC-003**: Category duplication rate is reduced by 80% compared to the current trip-specific model (measured over 30 days)
- **SC-004**: 85% of expenses use categories from the top 20 most popular global categories
- **SC-005**: Users successfully find an existing category before creating a new one 75% of the time (when the category already exists)
- **SC-006**: System prevents 100% of spam attempts (users blocked when exceeding rate limits)
- **SC-007**: Category browser loads and displays cached popular categories within 200ms
- **SC-008**: New categories appear in other users' search results within 1 minute of creation
- **SC-009**: 70% of newly created categories are reused by at least one other user within 7 days
- **SC-010**: Users complete the category creation flow in under 30 seconds on average

## Assumptions

1. **Material Icons Availability**: Assumes the app has access to the Material Icons library and can render icons by name
2. **User Authentication**: Assumes users are authenticated and have a unique userId for rate limiting
3. **Network Connectivity**: Primary flows work online; offline support limited to cached popular categories
4. **Firebase Usage**: Assumes Firebase Firestore is the data store with appropriate indexes for case-insensitive queries
5. **Icon Storage**: Icons are stored as Material icon names (strings) rather than image files to minimize storage
6. **Color Format**: Colors are stored as hex codes (#RRGGBB format)
7. **Existing Categories**: Assumes there are existing trip-specific categories to migrate; migration is a one-time operation
8. **Usage Tracking**: Assumes usage counts can be incremented transactionally to prevent race conditions
9. **Default Categories**: The 6 seed categories (Meals, Transport, Accommodation, Activities, Shopping, Other) are localized and match existing constants in the codebase
10. **Rate Limiting Window**: The 5-minute rate limiting window is sufficient to prevent spam while not overly restricting legitimate users

## Dependencies

1. **Firebase Firestore Indexes**: Requires case-insensitive indexes on category names for efficient duplicate checking and search
2. **Material Icons Library**: Must be included in the project for icon selection and display
3. **Localization System**: Category names and UI strings must support the existing l10n system
4. **Expense Model Update**: Expense entity must support category references (likely already exists as categoryId field)
5. **Activity Logging**: New category creation should log activities for audit trail
6. **Bottom Sheet Widget**: Requires a bottom sheet component for the category browser (likely exists in shared widgets)

## Out of Scope

1. **Category Deletion**: Users cannot delete categories from the global pool (to prevent breaking existing expense references)
2. **Category Editing**: Users cannot edit existing global category names (only create new ones with different names)
3. **Category Permissions**: No role-based restrictions on who can create categories (all authenticated users can create)
4. **Category Reporting/Moderation**: No admin interface to review, merge, or moderate categories
5. **Custom Icon Uploads**: Users cannot upload custom images; limited to Material icons only
6. **Category Hierarchies**: No support for parent/child category relationships or nested categories
7. **Category Translations**: Category names are not automatically translated; they remain in the language created
8. **Personal Category Lists**: Users cannot maintain private/favorite category lists separate from the global pool
9. **Category Synonyms**: No automatic matching of similar category names (e.g., "taxi" vs "cab")
10. **Usage Analytics Dashboard**: No reporting interface for viewing category usage statistics

## Constraints

1. **Rate Limiting**: Hard limit of 3 category creations per user per 5-minute window (non-configurable)
2. **Category Name Length**: 1-50 characters (consistent with existing model validation)
3. **Top 5 Limit**: Only 5 popular categories displayed by default (not configurable per user)
4. **Case Insensitivity**: All category name comparisons must be case-insensitive (no override option)
5. **Icon Library**: Limited to Material Icons only (no custom icon sets)
6. **Color Palette**: Users select from preset colors only (no custom color picker beyond the provided palette)
7. **Popularity Algorithm**: Categories ranked purely by usage count (no weighted algorithms or recency bias)
8. **Cache Size**: Only top 20 categories cached locally (to balance performance and storage)
9. **Search Performance**: Search must return results within 500ms (requires optimized queries/indexes)
10. **Migration**: One-time migration only; no rollback to trip-specific categories after migration
