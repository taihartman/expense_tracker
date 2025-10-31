# Developer Quickstart: Feature 009

**Feature**: Per-Trip Category Visual Customization + Icon System Improvements
**Branch**: `009-trip-category-customization`
**Status**: In Development

## Quick Links

- **Spec**: [spec.md](./spec.md)
- **Implementation Plan**: [plan.md](./plan.md)
- **Data Model**: [data-model.md](./data-model.md)
- **Contracts**: [contracts/](./contracts/)
- **Tasks**: [tasks.md](./tasks.md) (pending generation)

## Getting Started

### Prerequisites

```bash
# Ensure you're on the feature branch
git checkout 009-trip-category-customization

# Install dependencies
flutter pub get

# Generate mocks if needed
dart run build_runner build --delete-conflicting-outputs
```

### Running Tests

```bash
# Run all tests for this feature
flutter test test/features/categories/

# Run specific test suites
flutter test test/shared/utils/icon_helper_test.dart
flutter test test/integration/icon_voting_flow_test.dart

# Run with coverage
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

### Local Development

```bash
# Run app in Chrome (mobile viewport)
flutter run -d chrome --web-browser-flag "--window-size=375,667"

# Run with hot reload
flutter run -d chrome

# Check for lint errors
flutter analyze

# Format code
flutter format .
```

## Feature Components

### 1. Icon System (Core)

**Files**:
- `lib/core/enums/category_icon.dart` - Type-safe icon enum (30 icons)
- `lib/shared/utils/icon_helper.dart` - Shared conversion utilities
- `test/shared/utils/icon_helper_test.dart` - Comprehensive icon tests

**Key Classes**:
```dart
// Using the enum
CategoryIcon icon = CategoryIcon.restaurant;
String firestore = icon.iconName;  // "restaurant"
IconData flutter = icon.iconData;  // Icons.restaurant

// Using the helper
IconData icon = IconHelper.getIconData("restaurant");
```

**Testing**:
```bash
flutter test test/shared/utils/icon_helper_test.dart
```

### 2. Voting System (Domain)

**Files**:
- `lib/features/categories/domain/models/category_icon_preference.dart` - Vote model
- `lib/core/services/category_icon_updater_service.dart` - Vote logic
- `lib/features/categories/data/repositories/category_customization_repository_impl.dart` - Vote recording

**Key Flow**:
```dart
// User customizes icon
await cubit.customizeCategory(iconName: 'ski');

// Behind the scenes (non-blocking)
await repository.recordIconPreference(
  categoryId: category.id,
  iconName: 'ski',
);
// → Increments vote count
// → Updates global icon if threshold reached (3 votes)
```

**Testing**:
```bash
flutter test test/features/categories/data/repositories/
```

### 3. Similar Category Detection (Repository)

**Files**:
- `lib/features/categories/data/repositories/category_repository_impl.dart` - Fuzzy matching
- `lib/features/categories/presentation/widgets/category_creation_bottom_sheet.dart` - Warning UI

**Key Flow**:
```dart
// User types "Ski"
final similar = await repository.findSimilarCategories(name: 'Ski');
// Returns: [Category(name: 'Skiing', similarity: 0.87)]

// Show warning banner
if (similar.isNotEmpty) {
  showBanner('Similar category exists: ${similar.first.name}');
}
```

**Testing**:
```bash
flutter test test/features/categories/presentation/widgets/category_creation_bottom_sheet_test.dart
```

### 4. UI Enhancements (Presentation)

**Modified Widgets**:
- `category_icon_picker.dart` - Dynamic grid from CategoryIcon.values
- `category_selector.dart` - Uses IconHelper (removed _getIconData)
- `category_browser_bottom_sheet.dart` - Uses IconHelper
- `customize_categories_screen.dart` - Uses IconHelper

**Pattern**:
```dart
// Before (duplicated in 3 places)
IconData _getIconData(String name) {
  switch (name) {
    case 'restaurant': return Icons.restaurant;
    // ...
  }
}

// After (shared utility)
import 'package:expense_tracker/shared/utils/icon_helper.dart';
final icon = IconHelper.getIconData(category.icon);
```

## Common Tasks

### Adding a New Icon

1. Add enum value to `CategoryIcon`:
```dart
enum CategoryIcon {
  // ...
  newIcon,  // NEW
}
```

2. Add mapping in `iconName` getter:
```dart
String get iconName {
  switch (this) {
    // ...
    case CategoryIcon.newIcon: return 'new_icon';
  }
}
```

3. Add mapping in `iconData` getter:
```dart
IconData get iconData {
  switch (this) {
    // ...
    case CategoryIcon.newIcon: return Icons.new_icon;
  }
}
```

4. Update `IconHelper.getIconData()`:
```dart
static IconData getIconData(String iconName) {
  switch (iconName) {
    // ...
    case 'new_icon': return Icons.new_icon;
  }
}
```

5. Add validator entry:
```dart
// lib/core/validators/category_customization_validator.dart
static const Set<String> validIcons = {
  // ...
  'new_icon',  // NEW
};
```

6. Write tests for all 4 changes

### Testing Icon Voting Flow

```dart
// Integration test example
test('icon voting updates global default after 3 votes', () async {
  // Create category with suboptimal icon
  await createCategory(name: 'Skiing', icon: 'tree');

  // User 1 votes for ski
  await customizeCategory(tripId: 'trip1', icon: 'ski');
  expect(await getGlobalIcon('Skiing'), 'tree');  // Not updated yet

  // User 2 votes for ski
  await customizeCategory(tripId: 'trip2', icon: 'ski');
  expect(await getGlobalIcon('Skiing'), 'tree');  // Not updated yet

  // User 3 votes for ski (threshold reached)
  await customizeCategory(tripId: 'trip3', icon: 'ski');
  expect(await getGlobalIcon('Skiing'), 'ski');  // Updated!
});
```

### Testing Similar Category Detection

```dart
test('warns about similar category during creation', () async {
  // Seed existing category
  await createCategory(name: 'Skiing', usageCount: 45);

  // User types similar name
  final similar = await findSimilarCategories(name: 'Ski');

  expect(similar, hasLength(1));
  expect(similar.first.name, 'Skiing');
  expect(similar.first.similarity, greaterThan(0.80));
});
```

## Troubleshooting

### Issue: Icons not rendering (shows default)

**Cause**: Icon name not in IconHelper switch statement

**Fix**: Add icon to `IconHelper.getIconData()` method

### Issue: Voting not working

**Cause**: Firestore transaction failing silently

**Fix**: Enable debug logging:
```dart
// In repository_impl.dart
try {
  await recordIconPreference(...);
} catch (e) {
  print('Vote failed: $e');  // Add logging
}
```

### Issue: Similar category detection too sensitive

**Cause**: Threshold too low (0.80)

**Fix**: Adjust threshold in `findSimilarCategories()`:
```dart
double similarityThreshold = 0.85;  // Increase from 0.80
```

## Code Review Checklist

Before submitting PR:

- [ ] All tests passing (`flutter test`)
- [ ] Code formatted (`flutter format .`)
- [ ] No lint warnings (`flutter analyze`)
- [ ] Icon enum has all 30 icons
- [ ] IconHelper covers all 30 icons
- [ ] Voting logic uses Firestore transactions
- [ ] Similar category detection shows top 3 matches
- [ ] Mobile viewport tested (375x667px)
- [ ] Documentation updated (CLAUDE.md, CHANGELOG.md)

## Next Steps

1. **Generate tasks**: Run `/speckit.tasks` to create task breakdown
2. **Implement TDD**: Write tests first, then implementation
3. **Follow tasks**: Complete tasks in dependency order
4. **Document progress**: Use `/docs.log` frequently

---

**Questions?** Check the spec, plan, or data model documents linked above.
