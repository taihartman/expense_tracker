# Repository Contract: CategoryCustomizationRepository

**Feature**: 009-trip-category-customization
**Date**: 2025-10-31
**Type**: Domain Repository Interface

This document defines the contract for the `CategoryCustomizationRepository` interface that must be implemented by the data layer.

---

## Interface Definition

```dart
// lib/core/repositories/category_customization_repository.dart

import '../models/category_customization.dart';

/// Repository interface for category customization operations
///
/// Implementations must handle:
/// - CRUD operations for trip-specific category customizations
/// - Stream-based real-time updates
/// - Efficient batch reads
/// - Graceful error handling
abstract class CategoryCustomizationRepository {
  /// Loads all customizations for a specific trip
  ///
  /// Returns a stream that emits the complete list of customizations
  /// whenever any customization changes (add, update, delete).
  ///
  /// Parameters:
  /// - [tripId]: ID of the trip to load customizations for
  ///
  /// Returns:
  /// - Stream<List<CategoryCustomization>> - Real-time customizations list
  ///
  /// Behavior:
  /// - Empty list if no customizations exist
  /// - Updates automatically on remote changes
  /// - Stream never completes (closes on dispose)
  ///
  /// Errors:
  /// - Throws Exception if Firestore read fails
  /// - Emits error in stream if connection lost (can recover)
  ///
  /// Performance:
  /// - Target: <200ms for initial load
  /// - Supports up to 50 customizations per trip
  ///
  /// Example:
  /// ```dart
  /// final stream = repository.getCustomizationsForTrip('trip-123');
  /// stream.listen((customizations) {
  ///   print('Found ${customizations.length} customizations');
  /// });
  /// ```
  Stream<List<CategoryCustomization>> getCustomizationsForTrip(String tripId);

  /// Gets a specific customization for a category within a trip
  ///
  /// Returns null if no customization exists (category uses global defaults).
  ///
  /// Parameters:
  /// - [tripId]: ID of the trip
  /// - [categoryId]: ID of the category to get customization for
  ///
  /// Returns:
  /// - Future<CategoryCustomization?> - Customization or null
  ///
  /// Behavior:
  /// - Returns null if document doesn't exist (not an error)
  /// - Single read operation (not a stream)
  ///
  /// Errors:
  /// - Throws Exception if Firestore read fails
  ///
  /// Performance:
  /// - Target: <100ms
  /// - Should hit in-memory cache if possible
  ///
  /// Example:
  /// ```dart
  /// final customization = await repository.getCustomization(
  ///   'trip-123',
  ///   'category-456',
  /// );
  /// if (customization != null) {
  ///   print('Category is customized');
  /// }
  /// ```
  Future<CategoryCustomization?> getCustomization(
    String tripId,
    String categoryId,
  );

  /// Saves a customization (create or update)
  ///
  /// If customization exists, updates it. Otherwise creates new.
  ///
  /// Parameters:
  /// - [customization]: The customization to save
  ///
  /// Returns:
  /// - Future<void> - Completes when save succeeds
  ///
  /// Behavior:
  /// - Sets updatedAt to current timestamp
  /// - Validates icon and color before saving
  /// - Overwrites existing customization if present
  ///
  /// Errors:
  /// - Throws Exception if validation fails
  /// - Throws Exception if Firestore write fails
  /// - Throws Exception if user lacks permissions
  ///
  /// Performance:
  /// - Target: <500ms
  ///
  /// Example:
  /// ```dart
  /// final customization = CategoryCustomization(
  ///   categoryId: 'cat-123',
  ///   tripId: 'trip-456',
  ///   customIcon: 'fastfood',
  ///   customColor: '#FF5722',
  ///   updatedAt: DateTime.now(),
  /// );
  /// await repository.saveCustomization(customization);
  /// ```
  Future<void> saveCustomization(CategoryCustomization customization);

  /// Deletes a customization (resets category to global defaults)
  ///
  /// Parameters:
  /// - [tripId]: ID of the trip
  /// - [categoryId]: ID of the category to reset
  ///
  /// Returns:
  /// - Future<void> - Completes when delete succeeds
  ///
  /// Behavior:
  /// - Deletes Firestore document
  /// - Does nothing if customization doesn't exist (not an error)
  ///
  /// Errors:
  /// - Throws Exception if Firestore delete fails
  /// - Throws Exception if user lacks permissions
  ///
  /// Performance:
  /// - Target: <500ms
  ///
  /// Example:
  /// ```dart
  /// await repository.deleteCustomization('trip-123', 'category-456');
  /// print('Customization reset to global defaults');
  /// ```
  Future<void> deleteCustomization(String tripId, String categoryId);
}
```

---

## Implementation Requirements

### Firestore Data Layer Implementation

The data layer must implement this interface with Firestore operations:

**File**: `lib/features/categories/data/repositories/category_customization_repository_impl.dart`

**Dependencies**:
- `cloud_firestore` - Firestore access
- `FirestoreService` - Shared Firestore instance
- `CategoryCustomizationModel` - Firestore serialization

**Key Responsibilities**:
1. Convert domain entities to Firestore models and vice versa
2. Handle Firestore-specific errors (permission denied, network errors)
3. Provide efficient batch reads using Firestore queries
4. Ensure data consistency (validate before write)

---

## Error Handling Contract

### Exception Types

Implementations MUST throw specific exceptions:

```dart
/// Base exception for customization repository errors
class CategoryCustomizationException implements Exception {
  final String message;
  final CategoryCustomizationErrorType type;

  CategoryCustomizationException(this.message, this.type);

  @override
  String toString() => 'CategoryCustomizationException: $message';
}

/// Error types for customization operations
enum CategoryCustomizationErrorType {
  /// Firestore read failed (network, permissions, etc.)
  readFailed,

  /// Firestore write failed (network, permissions, validation, etc.)
  writeFailed,

  /// Firestore delete failed (network, permissions, etc.)
  deleteFailed,

  /// Validation failed (invalid icon, color, or missing fields)
  validationFailed,

  /// User lacks permissions to perform operation
  permissionDenied,
}
```

### Error Scenarios

| Scenario | Method | Exception | Type |
|----------|--------|-----------|------|
| Network timeout | Any | CategoryCustomizationException | readFailed/writeFailed/deleteFailed |
| Permission denied | Any | CategoryCustomizationException | permissionDenied |
| Invalid icon code | saveCustomization | CategoryCustomizationException | validationFailed |
| Invalid hex color | saveCustomization | CategoryCustomizationException | validationFailed |
| Missing categoryId | saveCustomization | CategoryCustomizationException | validationFailed |
| Firestore unavailable | Any | CategoryCustomizationException | readFailed/writeFailed/deleteFailed |

---

## Performance Contract

### Latency Targets

| Operation | Target | Maximum | Notes |
|-----------|--------|---------|-------|
| getCustomizationsForTrip (initial) | <200ms | <500ms | First emission |
| getCustomizationsForTrip (updates) | <100ms | <300ms | Subsequent emissions |
| getCustomization | <100ms | <300ms | Single document read |
| saveCustomization | <500ms | <1000ms | Single document write |
| deleteCustomization | <500ms | <1000ms | Single document delete |

### Scalability Contract

| Metric | Support Level |
|--------|---------------|
| Customizations per trip | Up to 50 |
| Concurrent reads (per trip) | Up to 10 |
| Concurrent writes (per trip) | Up to 3 |
| Batch read size | 50 documents |

---

## Testing Contract

### Required Unit Tests

Implementations MUST be tested with:

1. **Happy Path Tests**:
   - Load customizations for trip with 0, 1, 10, 50 customizations
   - Get specific customization (exists and doesn't exist)
   - Save new customization
   - Update existing customization
   - Delete customization

2. **Error Tests**:
   - Handle Firestore read failure
   - Handle Firestore write failure
   - Handle Firestore delete failure
   - Handle permission denied errors
   - Handle validation errors (invalid icon, color)

3. **Stream Tests**:
   - Stream emits initial data
   - Stream updates on remote changes
   - Stream handles errors gracefully
   - Stream closes on dispose

4. **Performance Tests**:
   - Batch read of 50 customizations <500ms
   - Single customization read <100ms

### Mock Requirements

Tests MUST use mocked Firestore:

```dart
// Using mockito
@GenerateMocks([FirebaseFirestore, CollectionReference, DocumentReference])
class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}
```

---

## Security Contract

### Firestore Security Rules

The repository assumes these security rules are enforced server-side:

```javascript
match /trips/{tripId}/categoryCustomizations/{categoryId} {
  allow read: if isAuthenticated() && isTripMember(tripId);
  allow write: if isAuthenticated() && isTripMember(tripId);
}
```

Implementations MUST NOT enforce security client-side (trust Firestore rules).

---

## Usage Examples

### Example 1: Load all customizations for a trip

```dart
final repository = context.read<CategoryCustomizationRepository>();

// Stream continuously updates
final subscription = repository
    .getCustomizationsForTrip('trip-123')
    .listen(
      (customizations) {
        print('Loaded ${customizations.length} customizations');
        // Update cubit state
      },
      onError: (error) {
        print('Error loading customizations: $error');
        // Show error to user
      },
    );

// Clean up when done
subscription.cancel();
```

### Example 2: Save a customization

```dart
final repository = context.read<CategoryCustomizationRepository>();

try {
  final customization = CategoryCustomization(
    categoryId: 'meals-id',
    tripId: 'japan-trip-id',
    customIcon: 'fastfood',
    customColor: '#FF5722',
    updatedAt: DateTime.now(),
  );

  await repository.saveCustomization(customization);
  print('Customization saved successfully');
} on CategoryCustomizationException catch (e) {
  if (e.type == CategoryCustomizationErrorType.validationFailed) {
    print('Invalid customization: ${e.message}');
  } else {
    print('Failed to save: ${e.message}');
  }
}
```

### Example 3: Reset customization to defaults

```dart
final repository = context.read<CategoryCustomizationRepository>();

try {
  await repository.deleteCustomization('trip-123', 'category-456');
  print('Category reset to global defaults');
} on CategoryCustomizationException catch (e) {
  print('Failed to reset: ${e.message}');
}
```

---

## API Stability

**Version**: 1.0.0
**Stability**: Stable
**Breaking Changes**: None planned

Future additions (non-breaking):
- Batch operations (saveMultiple, deleteMultiple)
- Export/import customizations
- Customization templates
