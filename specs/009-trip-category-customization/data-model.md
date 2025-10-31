# Data Model: Per-Trip Category Customization

**Feature**: 009-trip-category-customization
**Date**: 2025-10-31
**Status**: Finalized

This document defines all data entities, their fields, validation rules, and relationships for the per-trip category customization feature.

---

## Entity Overview

This feature introduces **one new entity** and **one helper class**:

1. **CategoryCustomization** (Domain Entity) - Represents visual override for a category within a trip
2. **DisplayCategory** (Helper Class) - Merged view of global category + customization for UI display

Existing entities referenced:
- **Category** (from Feature 008) - Global category entity
- **Trip** (existing) - Trip entity

---

## Entity 1: CategoryCustomization

### Purpose
Stores trip-specific visual customizations (icon and color) for a global category. Allows trips to personalize category appearance without affecting other trips or the global category data.

### Storage Location
Firestore: `/trips/{tripId}/categoryCustomizations/{categoryId}`

- **Collection Type**: Subcollection under trips
- **Document ID**: Global category ID (ensures one customization per category per trip)

### Domain Model

```dart
// lib/core/models/category_customization.dart

import 'package:equatable/equatable.dart';

/// Represents a trip-specific visual customization for a global category
///
/// Customizations are stored per trip and override the global category's
/// default icon and/or color for that specific trip only.
///
/// Naming note: Previously called "CategoryCustomization", now "TripCategoryCustomization"
/// to avoid confusion with the global Category entity.
class CategoryCustomization extends Equatable {
  /// ID of the global category being customized
  final String categoryId;

  /// ID of the trip this customization belongs to
  final String tripId;

  /// Custom icon override (Material Icons code name)
  /// If null, uses global category's default icon
  /// Example: "fastfood", "restaurant", "directions_car"
  final String? customIcon;

  /// Custom color override (hex code with # prefix)
  /// If null, uses global category's default color
  /// Example: "#FF5722", "#2196F3", "#4CAF50"
  final String? customColor;

  /// Timestamp of when this customization was last updated
  /// Used for audit trail and conflict resolution
  final DateTime updatedAt;

  const CategoryCustomization({
    required this.categoryId,
    required this.tripId,
    this.customIcon,
    this.customColor,
    required this.updatedAt,
  });

  /// Creates a copy with optional field replacements
  CategoryCustomization copyWith({
    String? categoryId,
    String? tripId,
    String? customIcon,
    String? customColor,
    DateTime? updatedAt,
  }) {
    return CategoryCustomization(
      categoryId: categoryId ?? this.categoryId,
      tripId: tripId ?? this.tripId,
      customIcon: customIcon ?? this.customIcon,
      customColor: customColor ?? this.customColor,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Checks if this customization has any overrides
  /// Returns false if both icon and color are null (no actual customization)
  bool get hasCustomization => customIcon != null || customColor != null;

  /// Checks if icon is customized (not using global default)
  bool get hasCustomIcon => customIcon != null;

  /// Checks if color is customized (not using global default)
  bool get hasCustomColor => customColor != null;

  @override
  List<Object?> get props => [
        categoryId,
        tripId,
        customIcon,
        customColor,
        updatedAt,
      ];

  @override
  String toString() {
    return 'CategoryCustomization('
        'categoryId: $categoryId, '
        'tripId: $tripId, '
        'customIcon: $customIcon, '
        'customColor: $customColor, '
        'updatedAt: $updatedAt'
        ')';
  }
}
```

### Firestore Model (Data Layer)

```dart
// lib/features/categories/data/models/category_customization_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/models/category_customization.dart';

/// Firestore serialization model for CategoryCustomization
class CategoryCustomizationModel extends CategoryCustomization {
  const CategoryCustomizationModel({
    required super.categoryId,
    required super.tripId,
    super.customIcon,
    super.customColor,
    required super.updatedAt,
  });

  /// Creates CategoryCustomization from Firestore document
  factory CategoryCustomizationModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return CategoryCustomizationModel(
      categoryId: doc.id, // Document ID is the category ID
      tripId: data['tripId'] as String,
      customIcon: data['customIcon'] as String?,
      customColor: data['customColor'] as String?,
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  /// Converts CategoryCustomization to Firestore document data
  Map<String, dynamic> toFirestore() {
    return {
      'tripId': tripId,
      'customIcon': customIcon,
      'customColor': customColor,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Creates model from domain entity
  factory CategoryCustomizationModel.fromDomain(
    CategoryCustomization customization,
  ) {
    return CategoryCustomizationModel(
      categoryId: customization.categoryId,
      tripId: customization.tripId,
      customIcon: customization.customIcon,
      customColor: customization.customColor,
      updatedAt: customization.updatedAt,
    );
  }
}
```

### Field Specifications

| Field | Type | Required | Validation | Default | Notes |
|-------|------|----------|------------|---------|-------|
| `categoryId` | String | ✅ Yes | Non-empty, valid UUID/Firestore ID | N/A | References global category |
| `tripId` | String | ✅ Yes | Non-empty, valid UUID/Firestore ID | N/A | References parent trip |
| `customIcon` | String? | ❌ No | Valid Material Icons code name or null | null | Icon name from Material Icons library |
| `customColor` | String? | ❌ No | Valid hex color (#RRGGBB) or null | null | Must match /^#[0-9A-F]{6}$/i |
| `updatedAt` | DateTime | ✅ Yes | Valid date/time | Current timestamp | Auto-set on create/update |

### Validation Rules

#### Icon Validation
```dart
// lib/core/validators/category_customization_validator.dart

class CategoryCustomizationValidator {
  /// Available Material Icons for category customization
  /// Must match the list in CategoryIconPicker widget
  static const Set<String> validIcons = {
    'category', 'restaurant', 'directions_car', 'hotel',
    'local_activity', 'shopping_bag', 'local_cafe', 'flight',
    'train', 'directions_bus', 'local_taxi', 'local_gas_station',
    'fastfood', 'local_grocery_store', 'local_pharmacy',
    'local_hospital', 'fitness_center', 'spa', 'beach_access',
    'camera_alt', 'movie', 'music_note', 'sports_soccer',
    'pets', 'school', 'work', 'home', 'phone', 'laptop', 'book',
  };

  /// Validates custom icon (null is valid = use default)
  static String? validateIcon(String? icon) {
    if (icon == null) return null; // Null is valid (use default)
    if (icon.trim().isEmpty) return 'Icon cannot be empty';
    if (!validIcons.contains(icon)) {
      return 'Invalid icon. Must be one of the predefined Material Icons.';
    }
    return null; // Valid
  }
}
```

#### Color Validation
```dart
class CategoryCustomizationValidator {
  /// Hex color pattern (e.g., #FF5722)
  static final RegExp _colorPattern = RegExp(r'^#[0-9A-Fa-f]{6}$');

  /// Available colors for category customization
  /// Must match the list in CategoryColorPicker widget
  static const Set<String> validColors = {
    '#9E9E9E', // Grey
    '#F44336', // Red
    '#E91E63', // Pink
    '#9C27B0', // Purple
    '#673AB7', // Deep Purple
    '#3F51B5', // Indigo
    '#2196F3', // Blue
    '#03A9F4', // Light Blue
    '#00BCD4', // Cyan
    '#009688', // Teal
    '#4CAF50', // Green
    '#8BC34A', // Light Green
    '#CDDC39', // Lime
    '#FFEB3B', // Yellow
    '#FFC107', // Amber
    '#FF9800', // Orange
    '#FF5722', // Deep Orange
    '#795548', // Brown
    '#607D8B', // Blue Grey
  };

  /// Validates custom color (null is valid = use default)
  static String? validateColor(String? color) {
    if (color == null) return null; // Null is valid (use default)
    if (color.trim().isEmpty) return 'Color cannot be empty';
    if (!_colorPattern.hasMatch(color)) {
      return 'Color must be a valid hex code (e.g., #FF5722)';
    }
    if (!validColors.contains(color.toUpperCase())) {
      return 'Invalid color. Must be one of the predefined colors.';
    }
    return null; // Valid
  }
}
```

#### Complete Customization Validation
```dart
class CategoryCustomizationValidator {
  /// Validates an entire customization before saving
  static Map<String, String> validateCustomization(
    CategoryCustomization customization,
  ) {
    final errors = <String, String>{};

    // categoryId must be non-empty
    if (customization.categoryId.trim().isEmpty) {
      errors['categoryId'] = 'Category ID is required';
    }

    // tripId must be non-empty
    if (customization.tripId.trim().isEmpty) {
      errors['tripId'] = 'Trip ID is required';
    }

    // Validate icon if provided
    final iconError = validateIcon(customization.customIcon);
    if (iconError != null) {
      errors['customIcon'] = iconError;
    }

    // Validate color if provided
    final colorError = validateColor(customization.customColor);
    if (colorError != null) {
      errors['customColor'] = colorError;
    }

    // At least one customization must be set
    if (!customization.hasCustomization) {
      errors['general'] = 'At least one customization (icon or color) must be set';
    }

    return errors; // Empty map = valid
  }
}
```

---

## Helper Class: DisplayCategory

### Purpose
Provides a merged view of a global category with its trip-specific customization for UI display. This is NOT persisted to database - it's a runtime helper for rendering.

### Implementation

```dart
// lib/shared/utils/category_display_helper.dart

import 'package:expense_tracker/core/models/category.dart';
import 'package:expense_tracker/core/models/category_customization.dart';

/// Helper class representing a category as it should be displayed in UI
///
/// Merges global category data with trip-specific customizations.
/// This is a display model only - NOT persisted to database.
class DisplayCategory {
  /// Global category ID
  final String id;

  /// Category name (always from global category)
  final String name;

  /// Display icon (customized or global default)
  final String icon;

  /// Display color (customized or global default)
  final String color;

  /// Whether this category has any customizations
  final bool isCustomized;

  const DisplayCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.isCustomized,
  });

  /// Creates DisplayCategory by merging global category with customization
  factory DisplayCategory.fromGlobalAndCustomization({
    required Category globalCategory,
    CategoryCustomization? customization,
  }) {
    return DisplayCategory(
      id: globalCategory.id,
      name: globalCategory.name, // Always use global name
      icon: customization?.customIcon ?? globalCategory.icon,
      color: customization?.customColor ?? globalCategory.color,
      isCustomized: customization?.hasCustomization ?? false,
    );
  }
}
```

### Usage in UI

```dart
// Example: In expense list widget
final globalCategory = await categoryRepository.getCategoryById(expense.categoryId);
final customization = context.read<CategoryCustomizationCubit>()
    .getCustomization(expense.categoryId);

final displayCategory = DisplayCategory.fromGlobalAndCustomization(
  globalCategory: globalCategory,
  customization: customization,
);

// Use displayCategory.icon, displayCategory.color for rendering
```

---

## Relationships

### CategoryCustomization → Category (Many-to-One)
- **Type**: Reference (not embedded)
- **Cardinality**: Many customizations can reference one global category
- **Referential Integrity**: Customization stores categoryId, but global category can exist without customizations
- **Orphan Handling**: If global category is deleted, customizations become orphaned (graceful degradation: show as "Unknown Category")

### CategoryCustomization → Trip (Many-to-One)
- **Type**: Subcollection (parent-child)
- **Cardinality**: Many customizations belong to one trip
- **Lifecycle**: Customizations deleted when parent trip is deleted (Firestore cascade)
- **Access Pattern**: All customizations for a trip loaded together

### Diagram

```
┌─────────────┐
│   Category  │ (Global, Feature 008)
│  (Global)   │
│  id: string │
│  name       │
│  icon       │◄──────────┐
│  color      │           │ References (categoryId)
│  usageCount │           │
└─────────────┘           │
                          │
                          │
┌─────────────┐      ┌────┴────────────────────────┐
│    Trip     │      │  CategoryCustomization      │
│  id: string │◄─────│  (Subcollection)            │
│  name       │      │  categoryId: string         │
│  members    │      │  tripId: string             │
└─────────────┘      │  customIcon?: string        │
                     │  customColor?: string       │
                     │  updatedAt: DateTime        │
                     └─────────────────────────────┘
                          Stored at:
                          /trips/{tripId}/
                            categoryCustomizations/
                              {categoryId}
```

---

## State Transitions

### CategoryCustomization Lifecycle

```
1. [DOES NOT EXIST]
   ↓ User customizes icon/color
   ↓
2. [CREATED] - customIcon and/or customColor set
   ↓ User modifies customization
   ↓
3. [UPDATED] - updatedAt timestamp updated
   ↓ User resets to default (Option A)
   ↓
4. [DELETED] - Document removed

   OR (Option B)
   ↓ User resets to default
   ↓
5. [RESET] - customIcon and customColor set to null
   (Keep document for audit trail)
```

**Decision**: Use Option A (DELETE) for simplicity
- Reduces storage costs (no empty documents)
- Simpler queries (non-existence = no customization)
- Audit trail handled by ActivityLog

---

## Indexes

### Firestore Indexes Required

**None required.** Queries use simple document ID lookups:

```dart
// Query 1: Get all customizations for a trip
/trips/{tripId}/categoryCustomizations/*

// Query 2: Get specific customization
/trips/{tripId}/categoryCustomizations/{categoryId}
```

Both queries use collection scans on small datasets (<50 docs), no compound indexes needed.

---

## Migration

**No data migration needed.** This is a new feature with no existing data.

Customizations will be created on-demand as users customize categories in their trips.

---

## Performance Characteristics

| Operation | Expected Performance | Firestore Cost |
|-----------|---------------------|----------------|
| Load all customizations for trip | 100-150ms | 1 read × N documents (typically 0-10) |
| Get specific customization | <10ms (cached) | 0 reads (cached) or 1 read (cache miss) |
| Save/update customization | 200-300ms | 1 write |
| Delete customization | 200-300ms | 1 delete |
| Batch read (50 customizations) | <200ms | 50 reads (rare, most trips have <10) |

**Optimization**: In-memory caching (CategoryCustomizationCubit state) reduces reads to once per trip session.

---

## Security Rules

```javascript
// firestore.rules

match /trips/{tripId}/categoryCustomizations/{categoryId} {
  // Allow read if authenticated and trip member
  allow read: if isAuthenticated() && isTripMember(tripId);

  // Allow write if authenticated and trip member
  allow create, update, delete: if isAuthenticated() && isTripMember(tripId);
}

// Helper function (assumed to exist from existing trip rules)
function isTripMember(tripId) {
  return request.auth != null &&
         request.auth.uid in get(/databases/$(database)/documents/trips/$(tripId)).data.members;
}

function isAuthenticated() {
  return request.auth != null;
}
```

---

## Testing Data

### Valid Examples

```dart
// Example 1: Icon and color customized
CategoryCustomization(
  categoryId: 'meals-category-id',
  tripId: 'japan-trip-id',
  customIcon: 'fastfood',
  customColor: '#FF5722',
  updatedAt: DateTime.now(),
)

// Example 2: Only icon customized
CategoryCustomization(
  categoryId: 'transport-category-id',
  tripId: 'work-trip-id',
  customIcon: 'directions_car',
  customColor: null, // Uses global default
  updatedAt: DateTime.now(),
)

// Example 3: Only color customized
CategoryCustomization(
  categoryId: 'accommodation-category-id',
  tripId: 'vacation-trip-id',
  customIcon: null, // Uses global default
  customColor: '#2196F3',
  updatedAt: DateTime.now(),
)
```

### Invalid Examples

```dart
// Invalid: Empty categoryId
CategoryCustomization(
  categoryId: '',
  tripId: 'trip-id',
  customIcon: 'restaurant',
  customColor: '#FF0000',
  updatedAt: DateTime.now(),
) // Validation error: "Category ID is required"

// Invalid: Invalid icon code
CategoryCustomization(
  categoryId: 'cat-id',
  tripId: 'trip-id',
  customIcon: 'invalid_icon_name',
  customColor: '#FF0000',
  updatedAt: DateTime.now(),
) // Validation error: "Invalid icon. Must be one of the predefined Material Icons."

// Invalid: Invalid hex color format
CategoryCustomization(
  categoryId: 'cat-id',
  tripId: 'trip-id',
  customIcon: 'restaurant',
  customColor: 'FF0000', // Missing #
  updatedAt: DateTime.now(),
) // Validation error: "Color must be a valid hex code (e.g., #FF5722)"

// Invalid: No customizations
CategoryCustomization(
  categoryId: 'cat-id',
  tripId: 'trip-id',
  customIcon: null,
  customColor: null,
  updatedAt: DateTime.now(),
) // Validation error: "At least one customization (icon or color) must be set"
```

---

## Summary

**New Entities**: 1 (CategoryCustomization)
**Helper Classes**: 1 (DisplayCategory)
**Validation Classes**: 1 (CategoryCustomizationValidator)
**Firestore Collections**: 1 subcollection (`/trips/{tripId}/categoryCustomizations`)
**Indexes Required**: 0
**Migration Required**: No

All entities follow clean architecture principles with separation between domain models and Firestore models.
