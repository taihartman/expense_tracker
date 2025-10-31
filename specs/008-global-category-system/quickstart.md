# Quickstart: Global Category Management System

**Audience**: Developers implementing or using the category system
**Last Updated**: 2025-10-31

## Overview

The Global Category Management System provides a shared category pool across all trips and users. Users can:
- Select from top 5 popular categories (instant access)
- Browse/search thousands of global categories
- Create new categories that become available to everyone
- Enjoy smart defaults and spam prevention

## For Feature Developers

### Adding the Category Selector to a Form

**Scenario**: You're building a form that needs category selection (e.g., expense form, budget form).

**Step 1**: Import the CategorySelector widget

```dart
import 'package:expense_tracker/features/categories/presentation/widgets/category_selector.dart';
```

**Step 2**: Add CategorySelector to your form

```dart
class ExpenseFormPage extends StatefulWidget {
  @override
  _ExpenseFormPageState createState() => _ExpenseFormPageState();
}

class _ExpenseFormPageState extends State<ExpenseFormPage> {
  String? _selectedCategoryId;  // Store selected category ID

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ... other form fields

        CategorySelector(
          selectedCategoryId: _selectedCategoryId,
          onCategorySelected: (categoryId) {
            setState(() {
              _selectedCategoryId = categoryId;
            });
          },
        ),

        // ... submit button
      ],
    );
  }
}
```

**Step 3**: Use the selected category ID when saving

```dart
void _saveExpense() {
  final expense = Expense(
    // ... other fields
    categoryId: _selectedCategoryId,  // Optional field
  );

  await expenseRepository.createExpense(expense);
}
```

**That's it!** The CategorySelector handles:
- Loading top 5 categories
- Displaying chips with icons/colors
- Opening bottom sheet for search/browse
- Creating new categories

---

### Using CategoryCubit for Custom UI

**Scenario**: You want to build a custom category UI (not using CategorySelector).

**Step 1**: Provide CategoryCubit in your widget tree

```dart
BlocProvider(
  create: (context) => CategoryCubit(
    categoryRepository: context.read<CategoryRepository>(),
  )..loadTopCategories(),  // Load on init
  child: YourCustomWidget(),
)
```

**Step 2**: Listen to state and build UI

```dart
class YourCustomWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CategoryCubit, CategoryState>(
      builder: (context, state) {
        if (state is CategoryLoading) {
          return CircularProgressIndicator();
        }

        if (state is CategoryLoaded) {
          return ListView.builder(
            itemCount: state.categories.length,
            itemBuilder: (context, index) {
              final category = state.categories[index];
              return ListTile(
                leading: Icon(
                  IconData(
                    int.parse(category.icon),
                    fontFamily: 'MaterialIcons',
                  ),
                  color: Color(int.parse('0xFF${category.color.substring(1)}')),
                ),
                title: Text(category.name),
                subtitle: Text('${category.usageCount} uses'),
                onTap: () => _selectCategory(category),
              );
            },
          );
        }

        if (state is CategoryError) {
          return Text('Error: ${state.message}');
        }

        return SizedBox.shrink();
      },
    );
  }
}
```

**Step 3**: Trigger cubit methods

```dart
// Load top categories
context.read<CategoryCubit>().loadTopCategories(limit: 10);

// Search
context.read<CategoryCubit>().searchCategories('meal');

// Create new category
await context.read<CategoryCubit>().createCategory(
  name: 'Pet Care',
  icon: 'pets',
  color: '#4CAF50',
  userId: currentUser.id,
);
```

---

## For App Users

### Selecting a Category

**Step 1**: Open expense form (or any form with category selection)

**Step 2**: You'll see 5 popular category chips (e.g., Meals, Transport, Accommodation)

**Step 3**: Tap a chip to select it → Done!

---

### Browsing All Categories

**Step 1**: Tap the "Other" chip

**Step 2**: Bottom sheet opens showing all available categories

**Step 3**: Scroll or use search field to find your category

**Step 4**: Tap a category to select it → Bottom sheet closes

---

### Searching for a Category

**Step 1**: Tap "Other" to open category browser

**Step 2**: Tap the search field at the top

**Step 3**: Type your search (e.g., "ski")

**Step 4**: Results appear instantly (e.g., "Ski Equipment", "Ski Passes")

**Step 5**: Tap a result to select it

---

### Creating a New Category

**Step 1**: Tap "Other" to open category browser

**Step 2**: Search for your desired category name (e.g., "Pet Boarding")

**Step 3**: If no results appear, you'll see "Create 'Pet Boarding'" at the top

**Step 4**: Tap "Create" → Dialog opens with name pre-filled

**Step 5**: (Optional) Customize icon and color

**Step 6**: Tap "Create" → Your category is now available to everyone!

**Note**: You can create up to 3 categories per 5 minutes. If you hit the limit, the "Create" button will be disabled with a message.

---

## For Repository Users

### Querying Categories Directly

**Use Case**: Building analytics, reports, or custom features that need category data.

**Step 1**: Inject CategoryRepository

```dart
final categoryRepository = context.read<CategoryRepository>();
```

**Step 2**: Use repository methods

```dart
// Get top 20 categories for a chart
final topCategories = await categoryRepository
  .getTopCategories(limit: 20)
  .first;

// Get a specific category by ID
final category = await categoryRepository
  .getCategoryById(expense.categoryId);

// Check if a name exists (before creating)
final exists = await categoryRepository
  .categoryExists('Meals');

// Search categories
final results = await categoryRepository
  .searchCategories('meal')
  .first;
```

---

## Testing Your Integration

### Unit Test: Form with CategorySelector

```dart
testWidgets('should save expense with selected category', (tester) async {
  // Arrange
  await tester.pumpWidget(
    MaterialApp(
      home: BlocProvider(
        create: (_) => mockCategoryCubit,
        child: ExpenseFormPage(),
      ),
    ),
  );

  // Act
  await tester.tap(find.byType(CategorySelector).descendant(
    find.text('Meals'),  // Tap "Meals" chip
  ));
  await tester.pumpAndSettle();

  await tester.tap(find.text('Save'));
  await tester.pumpAndSettle();

  // Assert
  verify(mockExpenseRepository.createExpense(
    argThat(predicate<Expense>((e) => e.categoryId == 'meals_category_id')),
  )).called(1);
});
```

---

### Widget Test: CategorySelector

```dart
testWidgets('should display top 5 categories as chips', (tester) async {
  // Arrange
  when(mockCategoryCubit.state).thenReturn(CategoryLoaded([
    Category(name: 'Meals', icon: 'restaurant', color: '#FF5722', usageCount: 100),
    Category(name: 'Transport', icon: 'directions_car', color: '#2196F3', usageCount: 80),
    // ... 3 more
  ]));

  // Act
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: BlocProvider.value(
          value: mockCategoryCubit,
          child: CategorySelector(
            selectedCategoryId: null,
            onCategorySelected: (_) {},
          ),
        ),
      ),
    ),
  );

  // Assert
  expect(find.text('Meals'), findsOneWidget);
  expect(find.text('Transport'), findsOneWidget);
  expect(find.text('Other'), findsOneWidget);  // Special "Other" chip
});
```

---

## Migration

### Running the Migration (One-Time)

**When**: Before deploying the global category feature to production

**How**: Run the migration script from your terminal

```bash
# From project root
dart scripts/migrations/migrate_categories_to_global.dart
```

**What it does**:
1. Queries all existing trip-specific categories
2. Groups duplicates by name (case-insensitive)
3. Creates consolidated global categories
4. Updates all expense `categoryId` references
5. Logs migration results

**Output**:
```
Migration started...
Found 347 trip-specific categories across 42 trips
Consolidated to 127 global categories
Updated 2,149 expense references
Migration complete! (12.3 seconds)
```

**Safety**: The script uses batched writes and is idempotent (can re-run if interrupted).

**Rollback**: If needed, the `migratedFrom` field in each global category tracks original trip-specific categories.

---

## Common Patterns

### Pattern 1: Preselecting a Category

**Use Case**: User is editing an existing expense, preselect the category

```dart
CategorySelector(
  selectedCategoryId: expense.categoryId,  // Preselect
  onCategorySelected: (categoryId) {
    // Update expense
  },
)
```

---

### Pattern 2: Filtering Categories by Usage

**Use Case**: Show only popular categories (e.g., usage > 10)

```dart
final popularCategories = (await categoryRepository
  .getTopCategories(limit: 50)
  .first)
  .where((c) => c.usageCount > 10)
  .toList();
```

---

### Pattern 3: Displaying Category in Expense Card

**Use Case**: Show category icon/color in expense list

```dart
class ExpenseCard extends StatelessWidget {
  final Expense expense;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Category?>(
      future: context.read<CategoryRepository>().getCategoryById(expense.categoryId),
      builder: (context, snapshot) {
        final category = snapshot.data;

        return ListTile(
          leading: category != null
            ? Icon(
                IconData(int.parse(category.icon), fontFamily: 'MaterialIcons'),
                color: Color(int.parse('0xFF${category.color.substring(1)}')),
              )
            : Icon(Icons.category),  // Default if no category
          title: Text(expense.description),
          subtitle: Text(category?.name ?? 'Uncategorized'),
        );
      },
    );
  }
}
```

---

### Pattern 4: Analytics by Category

**Use Case**: Show spending breakdown by category

```dart
Future<Map<Category, Decimal>> getSpendingByCategory(String tripId) async {
  final expenses = await expenseRepository.getExpensesByTrip(tripId).first;
  final categoryRepository = context.read<CategoryRepository>();

  final Map<Category, Decimal> spending = {};

  for (final expense in expenses) {
    if (expense.categoryId != null) {
      final category = await categoryRepository.getCategoryById(expense.categoryId);
      if (category != null) {
        spending[category] = (spending[category] ?? Decimal.zero) + expense.amount;
      }
    }
  }

  return spending;
}
```

---

## Troubleshooting

### Issue: "Categories not loading"

**Possible Causes**:
- No network connection
- Firestore indexes not created
- Repository not injected

**Solution**:
1. Check network connectivity
2. Deploy Firestore indexes (see `data-model.md`)
3. Ensure CategoryRepository is provided in DI

---

### Issue: "Create button disabled"

**Cause**: User hit rate limit (3 categories in 5 minutes)

**Solution**: Wait 5 minutes or inform user about the limit

---

### Issue: "Duplicate category error"

**Cause**: Category name already exists (case-insensitive)

**Solution**: Search for the existing category and select it instead

---

### Issue: "Category icon not displaying"

**Possible Causes**:
- Invalid icon code stored
- Material Icons font not loaded

**Solution**:
1. Verify `category.icon` is a valid Material icon codepoint
2. Ensure `MaterialIcons` font family is available

---

## Performance Tips

1. **Cache aggressively**: Use local cache (Hive) for top 20 categories
2. **Batch operations**: Increment category usage with expense creation
3. **Lazy load**: Only load full category list when "Other" is tapped
4. **Debounce search**: Wait 300ms after typing before querying

---

## Next Steps

- **Implementation**: Run `/speckit.tasks` to generate task breakdown
- **Testing**: Write tests following TDD principles (tests first!)
- **Deployment**: Run migration script before deploying feature

---

## Resources

- **Spec**: [spec.md](spec.md) - Full feature specification
- **Plan**: [plan.md](plan.md) - Technical implementation plan
- **Data Model**: [data-model.md](data-model.md) - Entity definitions
- **API Contract**: [contracts/category_api.md](contracts/category_api.md) - Repository and cubit interface

---

**Questions?** Check `CLAUDE.md` in the project root or refer to the comprehensive documentation in `.claude/skills/`.
