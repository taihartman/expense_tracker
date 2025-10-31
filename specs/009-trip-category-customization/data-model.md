# Phase 1: Data Model Design

**Feature**: Per-Trip Category Visual Customization + Icon System Improvements
**Date**: 2025-10-31

## Entity Models

### 1. CategoryIcon (Enum)

**Location**: `lib/core/enums/category_icon.dart`

**Purpose**: Type-safe representation of all 30 available Material Icons for categories.

```dart
enum CategoryIcon {
  category,
  restaurant,
  directionsCar,
  hotel,
  localActivity,
  shoppingBag,
  localCafe,
  flight,
  train,
  directionsBus,
  localTaxi,
  localGasStation,
  fastfood,
  localGroceryStore,
  localPharmacy,
  localHospital,
  fitnessCenter,
  spa,
  beachAccess,
  cameraAlt,
  movie,
  musicNote,
  sportsSoccer,
  pets,
  school,
  work,
  home,
  phone,
  laptop,
  book,
  moreHoriz;

  String get iconName { /* string for Firestore */ }
  IconData get iconData { /* IconData for rendering */ }
  static CategoryIcon? tryFromString(String iconName) { /* parser */ }
}
```

**Fields**:
- Enum values map to Material Icons (30 total)
- `iconName`: String representation for Firestore persistence
- `iconData`: Flutter IconData for rendering
- `tryFromString()`: Safe parsing from Firestore strings

**Validation**: Compile-time via enum exhaustiveness checking

---

### 2. CategoryIconPreference (NEW)

**Location**: `lib/features/categories/domain/models/category_icon_preference.dart`

**Purpose**: Tracks voting data for icon choices per category.

```dart
class CategoryIconPreference extends Equatable {
  final String categoryId;
  final Map<String, int> preferences;  // iconName → voteCount
  final String mostPopular;
  final DateTime lastUpdatedAt;

  CategoryIconPreference({
    required this.categoryId,
    required this.preferences,
    required this.mostPopular,
    required this.lastUpdatedAt,
  });

  // Business logic
  int getVoteCount(String iconName) => preferences[iconName] ?? 0;
  bool hasReachedThreshold(String iconName, {int threshold = 3}) {
    return getVoteCount(iconName) >= threshold;
  }
}
```

**Fields**:
- `categoryId`: Links to global category
- `preferences`: Map of icon names to vote counts
- `mostPopular`: Denormalized field for fast access (most voted icon)
- `lastUpdatedAt`: Timestamp of last vote

**Relationships**:
- 1-to-1 with Category (optional, only exists if votes recorded)

**Validation Rules**:
- `preferences` values must be non-negative integers
- `mostPopular` must exist in `preferences` keys
- `categoryId` must reference valid category

---

### 3. Category (Enhanced)

**Location**: `lib/features/categories/domain/models/category.dart`

**Changes**: Add computed property for type-safe icon access.

```dart
class Category extends Equatable {
  final String id;
  final String name;
  final String nameLowercase;
  final String icon;              // Existing: string for Firestore
  final String color;
  final int usageCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  // NEW: Type-safe icon access
  CategoryIcon get iconEnum {
    return CategoryIcon.tryFromString(icon) ?? CategoryIcon.category;
  }
}
```

**New Fields**: None (icon enum is computed)

**Migration**: No Firestore migration needed; `iconEnum` is derived from existing `icon` field

---

### 4. CategoryCustomization (Existing, No Changes)

**Location**: `lib/core/models/category_customization.dart`

**Purpose**: Represents visual override for a category within a specific trip.

```dart
class CategoryCustomization extends Equatable {
  final String categoryId;
  final String tripId;
  final String? customIcon;
  final String? customColor;
  final DateTime updatedAt;
}
```

**No changes required** for icon system improvements. Voting logic triggers when `customIcon` is set.

---

## State Transitions

### Icon Voting State Machine

```
[Category Created with Icon X]
    ↓
User 1 customizes to Icon Y → preferences: {X: 0, Y: 1}
    ↓
User 2 customizes to Icon Y → preferences: {X: 0, Y: 2}
    ↓
User 3 customizes to Icon Y → preferences: {X: 0, Y: 3}
    ↓
THRESHOLD REACHED (3 votes) → Update global category icon to Y
    ↓
[New users see Icon Y as default]
```

**Transition Rules**:
1. Vote recorded atomically in Firestore transaction
2. Most popular icon recalculated on every vote
3. Global icon updated when threshold reached (3 votes)
4. Existing trip customizations remain unchanged

---

## Firestore Collections

### categoryIconPreferences (NEW)

**Path**: `/categoryIconPreferences/{categoryId}`

**Document Structure**:
```json
{
  "categoryId": "abc123",
  "preferences": {
    "restaurant": 5,
    "fastfood": 3,
    "local_cafe": 1
  },
  "mostPopular": "restaurant",
  "lastUpdatedAt": "2025-10-31T12:00:00Z"
}
```

**Indexes**: None required (single-document reads)

**Security Rules**:
```javascript
match /categoryIconPreferences/{categoryId} {
  allow read: if request.auth != null;
  allow write: if request.auth != null;  // Voting requires authentication
}
```

---

### categories (Enhanced)

**Path**: `/categories/{categoryId}`

**Changes**: `icon` field can be updated by voting system.

**Document Structure** (unchanged):
```json
{
  "name": "Meals",
  "nameLowercase": "meals",
  "icon": "restaurant",
  "color": "#FF5722",
  "usageCount": 45,
  "createdAt": "2025-10-30T10:00:00Z",
  "updatedAt": "2025-10-31T12:00:00Z"
}
```

**New behavior**: `icon` field updates when vote threshold reached.

---

## Repository Contracts

### CategoryCustomizationRepository (Enhanced)

**New Method**:
```dart
Future<void> recordIconPreference({
  required String categoryId,
  required String iconName,
}) async;
```

**Purpose**: Record user's icon preference as a vote.

**Behavior**:
- Increment vote count in `categoryIconPreferences/{categoryId}`
- Recalculate `mostPopular` field
- Update global category icon if threshold reached (3 votes)
- Non-blocking: Exceptions logged but don't fail customization operation

---

### CategoryRepository (Enhanced)

**New Method**:
```dart
Future<List<Category>> findSimilarCategories({
  required String name,
  double similarityThreshold = 0.80,
}) async;
```

**Purpose**: Find categories with similar names using fuzzy matching.

**Behavior**:
- Load all categories (cached in memory)
- Calculate Jaro-Winkler similarity for each
- Return categories above threshold, sorted by similarity descending
- Limit: Top 3 matches maximum

---

## Migration Strategy

### Enum Migration

**Goal**: Transition from string-based icons to enum-based icons in codebase.

**Steps**:
1. Create `CategoryIcon` enum with all 30 icons
2. Add `iconEnum` getter to `Category` model (computed from string)
3. Create `IconHelper` utility with comprehensive icon mapping
4. Update widgets to use `IconHelper.getIconData()` (remove duplication)
5. Update cubits to use `CategoryIcon` enum internally
6. Update tests to use enum values

**Backward Compatibility**: Firestore still stores strings; enum is in-memory only.

### Data Migration

**No Firestore migration required**:
- Existing `icon` strings remain valid
- `CategoryIcon.tryFromString()` handles all existing values
- Unknown icons fall back to `CategoryIcon.category`

**New collection**: `categoryIconPreferences` will be populated on-demand as users vote.

---

## Validation Rules Summary

| Entity | Field | Rules |
|--------|-------|-------|
| CategoryIcon | enum value | Must be one of 30 predefined icons |
| CategoryIconPreference | preferences | Map values ≥ 0, mostPopular must exist in keys |
| Category | icon | Must map to valid CategoryIcon enum (fallback to 'category') |
| CategoryCustomization | customIcon | Optional; if present, must be valid icon name |

---

**Phase 1 Complete**: Ready for contract generation and quickstart guide.
