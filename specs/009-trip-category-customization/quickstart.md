# Quickstart Guide: Per-Trip Category Customization

**Feature**: 009-trip-category-customization
**Audience**: Developers working on this feature
**Last Updated**: 2025-10-31

This guide helps you quickly understand and work with the category customization feature.

---

## 🎯 What This Feature Does

Allows trips to customize the visual appearance (icon and color) of global categories **without affecting other trips**. Think of it as a "skin" for categories that's trip-specific.

**Example**: Your "Japan Trip" can show "Meals" with a ramen bowl icon 🍜, while your "Work Trip" keeps the default restaurant icon 🍽️.

---

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────┐
│                    Presentation Layer                    │
│  ┌────────────────────────────────────────────────────┐ │
│  │  CategoryCustomizationCubit                        │ │
│  │  - Manages state (loading, loaded, error)          │ │
│  │  - Caches customizations in memory                 │ │
│  │  - Provides fast lookups (getCustomization)        │ │
│  └────────────────────────────────────────────────────┘ │
│                          ↓                               │
│  ┌────────────────────────────────────────────────────┐ │
│  │  CustomizeCategoriesScreen                         │ │
│  │  - Lists categories used in trip                   │ │
│  │  - Shows current icon/color                        │ │
│  │  - Allows editing with pickers                     │ │
│  └────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│                     Domain Layer                         │
│  ┌────────────────────────────────────────────────────┐ │
│  │  CategoryCustomization (Entity)                    │ │
│  │  - categoryId, tripId, customIcon?, customColor?   │ │
│  └────────────────────────────────────────────────────┘ │
│                                                          │
│  ┌────────────────────────────────────────────────────┐ │
│  │  CategoryCustomizationRepository (Interface)       │ │
│  │  - getCustomizationsForTrip(tripId)                │ │
│  │  - saveCustomization(customization)                │ │
│  │  - deleteCustomization(tripId, categoryId)         │ │
│  └────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│                      Data Layer                          │
│  ┌────────────────────────────────────────────────────┐ │
│  │  CategoryCustomizationRepositoryImpl               │ │
│  │  - Firestore operations                            │ │
│  │  - Streams for real-time updates                   │ │
│  └────────────────────────────────────────────────────┘ │
│                          ↓                               │
│           Firestore: /trips/{id}/categoryCustomizations │
└─────────────────────────────────────────────────────────┘
```

---

## 🚀 Quick Start

### 1. Display a Category with Customization

Use the `CategoryDisplayHelper` to merge global defaults with customizations:

```dart
import 'package:expense_tracker/shared/utils/category_display_helper.dart';

// In your widget
Widget buildCategoryChip(Category category, String tripId) {
  return BlocBuilder<CategoryCustomizationCubit, CategoryCustomizationState>(
    builder: (context, state) {
      if (state is! CategoryCustomizationLoaded) {
        // Fallback to global category while loading
        return CategoryChip(icon: category.icon, color: category.color);
      }

      // Get customization for this category (if exists)
      final customization = state.getCustomization(category.id);

      // Merge global + customization
      final displayCategory = DisplayCategory.fromGlobalAndCustomization(
        globalCategory: category,
        customization: customization,
      );

      // Render with display icon/color
      return CategoryChip(
        icon: displayCategory.icon,
        color: displayCategory.color,
        name: displayCategory.name,
        isCustomized: displayCategory.isCustomized, // Show indicator
      );
    },
  );
}
```

### 2. Save a Customization

```dart
import 'package:flutter_bloc/flutter_bloc.dart';

Future<void> customizeCategory(
  BuildContext context,
  String categoryId,
  String? customIcon,
  String? customColor,
) async {
  // Get actor name for activity logging
  final currentUser = context.read<TripCubit>().getCurrentUserForTrip(tripId);

  // Save customization via cubit
  await context.read<CategoryCustomizationCubit>().saveCustomization(
    categoryId: categoryId,
    customIcon: customIcon,
    customColor: customColor,
    actorName: currentUser?.name,
  );
}
```

### 3. Reset a Customization

```dart
Future<void> resetToDefaults(BuildContext context, String categoryId) async {
  final currentUser = context.read<TripCubit>().getCurrentUserForTrip(tripId);

  await context.read<CategoryCustomizationCubit>().resetCustomization(
    categoryId: categoryId,
    actorName: currentUser?.name,
  );
}
```

### 4. Check if Category is Customized

```dart
final cubit = context.read<CategoryCustomizationCubit>();
final isCustomized = cubit.isCustomized(categoryId);

if (isCustomized) {
  // Show "Customized" badge
}
```

---

## 📁 Key Files

### Domain Layer
- **Entity**: `lib/core/models/category_customization.dart`
- **Repository Interface**: `lib/core/repositories/category_customization_repository.dart`
- **Validator**: `lib/core/validators/category_customization_validator.dart`

### Data Layer
- **Repository Impl**: `lib/features/categories/data/repositories/category_customization_repository_impl.dart`
- **Firestore Model**: `lib/features/categories/data/models/category_customization_model.dart`

### Presentation Layer
- **Cubit**: `lib/features/categories/presentation/cubit/category_customization_cubit.dart`
- **State**: `lib/features/categories/presentation/cubit/category_customization_state.dart`
- **Screen**: `lib/features/categories/presentation/widgets/customize_categories_screen.dart`
- **Icon Picker**: `lib/features/categories/presentation/widgets/category_icon_picker.dart`
- **Color Picker**: `lib/features/categories/presentation/widgets/category_color_picker.dart`

### Shared Utilities
- **Display Helper**: `lib/shared/utils/category_display_helper.dart`

---

## 🧪 Testing

### Unit Test: Cubit

```dart
// test/features/categories/presentation/cubit/category_customization_cubit_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

@GenerateMocks([CategoryCustomizationRepository, ActivityLogRepository])
void main() {
  late MockCategoryCustomizationRepository mockRepository;
  late CategoryCustomizationCubit cubit;

  setUp(() {
    mockRepository = MockCategoryCustomizationRepository();
    cubit = CategoryCustomizationCubit(
      repository: mockRepository,
      tripId: 'test-trip',
    );
  });

  tearDown(() {
    cubit.close();
  });

  test('should load customizations', () async {
    // Arrange
    final customizations = [
      CategoryCustomization(
        categoryId: 'cat-1',
        tripId: 'test-trip',
        customIcon: 'fastfood',
        customColor: '#FF5722',
        updatedAt: DateTime.now(),
      ),
    ];

    when(mockRepository.getCustomizationsForTrip('test-trip'))
        .thenAnswer((_) => Stream.value(customizations));

    // Act
    cubit.loadCustomizations();

    // Assert
    await expectLater(
      cubit.stream,
      emitsInOrder([
        isA<CategoryCustomizationLoading>(),
        isA<CategoryCustomizationLoaded>()
            .having((s) => s.customizations.length, 'count', 1),
      ]),
    );
  });
}
```

### Widget Test: Customize Screen

```dart
// test/features/categories/presentation/widgets/customize_categories_screen_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void main() {
  testWidgets('should show categories with customization indicators', (tester) async {
    // Arrange
    final cubit = CategoryCustomizationCubit(
      repository: mockRepository,
      tripId: 'test-trip',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(
          value: cubit,
          child: CustomizeCategoriesScreen(tripId: 'test-trip'),
        ),
      ),
    );

    // Act
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('Customize Categories'), findsOneWidget);
    expect(find.byType(CategoryListTile), findsWidgets);
  });
}
```

### Integration Test

```dart
// test/integration/category_customization_flow_test.dart

void main() {
  testWidgets('complete customization flow', (tester) async {
    // 1. Navigate to trip settings
    await tester.tap(find.text('Trip Settings'));
    await tester.pumpAndSettle();

    // 2. Open customize categories
    await tester.tap(find.text('Customize Categories'));
    await tester.pumpAndSettle();

    // 3. Select a category
    await tester.tap(find.text('Meals'));
    await tester.pumpAndSettle();

    // 4. Change icon
    await tester.tap(find.byIcon(Icons.fastfood));
    await tester.pumpAndSettle();

    // 5. Save
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    // 6. Verify in expense list
    await tester.tap(find.text('Back to Trip'));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.fastfood), findsWidgets);
  });
}
```

---

## 🔧 Common Tasks

### Task 1: Add a New Icon to Picker

1. Add icon to `CategoryIconPicker._availableIcons`:

```dart
// lib/features/categories/presentation/widgets/category_icon_picker.dart

final List<Map<String, dynamic>> _availableIcons = [
  // ... existing icons
  {'icon': Icons.new_icon, 'name': 'new_icon'}, // Add here
];
```

2. Add to validator:

```dart
// lib/core/validators/category_customization_validator.dart

static const Set<String> validIcons = {
  // ... existing icons
  'new_icon', // Add here
};
```

### Task 2: Add a New Color to Picker

1. Add color to `CategoryColorPicker._availableColors`:

```dart
// lib/features/categories/presentation/widgets/category_color_picker.dart

final List<String> _availableColors = [
  // ... existing colors
  '#XXXXXX', // Add hex code here
];
```

2. Add to validator:

```dart
// lib/core/validators/category_customization_validator.dart

static const Set<String> validColors = {
  // ... existing colors
  '#XXXXXX', // Add here
};
```

### Task 3: Display Customization in New Widget

Follow the pattern from "Quick Start #1":

```dart
import 'package:expense_tracker/shared/utils/category_display_helper.dart';

// Get customization from cubit state
final customization = context
    .read<CategoryCustomizationCubit>()
    .getCustomization(category.id);

// Merge with global category
final displayCategory = DisplayCategory.fromGlobalAndCustomization(
  globalCategory: category,
  customization: customization,
);

// Use displayCategory.icon, displayCategory.color for rendering
```

---

## 🐛 Debugging

### Issue: Customizations Not Loading

**Check**:
1. Is CategoryCustomizationCubit provided at trip scope?
2. Was `loadCustomizations()` called on cubit creation?
3. Check Firestore security rules allow reading customizations

**Debug**:
```dart
BlocObserver to log state transitions:

class CustomizationObserver extends BlocObserver {
  @override
  void onTransition(Bloc bloc, Transition transition) {
    if (bloc is CategoryCustomizationCubit) {
      print('Customization State: ${transition.currentState} → ${transition.nextState}');
    }
    super.onTransition(bloc, transition);
  }
}
```

### Issue: Customization Not Appearing in UI

**Check**:
1. Is widget using `BlocBuilder<CategoryCustomizationCubit, ...>`?
2. Is state a `CategoryCustomizationLoaded`?
3. Is `DisplayCategory.fromGlobalAndCustomization` being called?

**Debug**:
```dart
print('Customization for category: ${cubit.getCustomization(categoryId)}');
print('Current state: ${cubit.state}');
```

### Issue: Save Failing Silently

**Check**:
1. Is `BlocListener` set up to show errors?
2. Check Firestore console for write errors
3. Verify icon/color values are valid

**Debug**:
```dart
BlocListener<CategoryCustomizationCubit, CategoryCustomizationState>(
  listener: (context, state) {
    if (state is CategoryCustomizationError) {
      print('Error type: ${state.type}');
      print('Error message: ${state.message}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.message)),
      );
    }
  },
  // ...
)
```

---

## 📊 Performance Tips

### Tip 1: Batch Reads on Trip Load

Always load all customizations at once when entering a trip:

```dart
@override
void initState() {
  super.initState();
  // Load once, cache in memory
  context.read<CategoryCustomizationCubit>().loadCustomizations();
}
```

### Tip 2: Use In-Memory Cache

Don't query repository directly. Use cubit's cached state:

```dart
// ❌ Bad: Queries repository every time
final customization = await repository.getCustomization(tripId, categoryId);

// ✅ Good: Uses in-memory cache
final customization = context.read<CategoryCustomizationCubit>()
    .getCustomization(categoryId);
```

### Tip 3: Dispose Cubit When Leaving Trip

Ensure cubit is disposed to free memory and cancel streams:

```dart
MultiBlocProvider(
  providers: [
    BlocProvider(
      create: (context) => CategoryCustomizationCubit(...)
        ..loadCustomizations(),
    ),
  ],
  child: TripDetailScreen(), // Cubit disposed when navigating away
)
```

---

## 🔐 Security

### Firestore Rules

Customizations are protected by trip membership:

```javascript
match /trips/{tripId}/categoryCustomizations/{categoryId} {
  allow read, write: if isAuthenticated() && isTripMember(tripId);
}
```

### Client-Side

- Repository does NOT enforce security (trusts Firestore rules)
- Cubit assumes user has permission (Firestore will reject if not)
- UI should hide customization options for non-members

---

## 📚 Related Documentation

- **Feature Spec**: [spec.md](spec.md)
- **Implementation Plan**: [plan.md](plan.md)
- **Data Model**: [data-model.md](data-model.md)
- **Repository Contract**: [contracts/repository_contract.md](contracts/repository_contract.md)
- **Cubit Contract**: [contracts/cubit_contract.md](contracts/cubit_contract.md)

---

## ❓ FAQs

### Q: Can users rename categories per trip?

**A**: No. Only icon and color can be customized. Category names must remain global for consistency across trips. This is by design (see spec.md "Out of Scope").

### Q: What happens if a customized category is deleted globally?

**A**: The customization becomes orphaned. UI should gracefully handle this by showing "Unknown Category" and allowing cleanup.

### Q: Do customizations sync across devices?

**A**: Yes. Firestore automatically syncs customizations. The stream-based approach ensures real-time updates across all devices.

### Q: Can I bulk customize all categories at once?

**A**: Not in v1.0.0. Future enhancement (see cubit_contract.md "Future Additions").

### Q: Performance impact of 50 customizations?

**A**: Minimal (<200ms load time, <5KB memory). Tested and meets success criteria SC-003 and SC-006.

---

**Need help?** Check the contracts in `/contracts/` or refer to Feature 008 (Global Category System) for similar patterns.
