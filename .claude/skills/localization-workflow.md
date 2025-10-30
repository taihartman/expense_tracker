# Localization Workflow Skill

## Description
This skill provides a systematic workflow for adding and using localized strings in the expense tracker app. The app uses Flutter's built-in localization system (`flutter_localizations` + `intl`) with 250+ strings organized by category.

## When to Use
- Adding new UI text or labels
- Creating error messages or validation messages
- Building forms with user-facing text
- When you see hardcoded strings in code review
- When code uses string concatenation instead of l10n

## Core Philosophy
**Never hardcode user-facing strings.** All text that users see must be localized using the `context.l10n` pattern, even if only English is currently supported. This ensures easy internationalization later.

## Key Files
- `lib/l10n/app_en.arb` - English strings (250+ entries)
- `l10n.yaml` - Localization configuration
- `lib/core/l10n/l10n_extensions.dart` - Helper extension for easy access
- `.dart_tool/flutter_gen/gen_l10n/app_localizations.dart` - Auto-generated (DON'T edit)

## Workflow

### Step 1: Check if String Already Exists

Before adding a new string, search `lib/l10n/app_en.arb` to see if a similar string already exists:

```bash
# Search for existing strings
grep -i "cancel" lib/l10n/app_en.arb
grep -i "save" lib/l10n/app_en.arb
grep -i "delete" lib/l10n/app_en.arb
```

**Common reusable strings:**
- `commonCancel` - "Cancel"
- `commonSave` - "Save"
- `commonDelete` - "Delete"
- `commonClose` - "Close"
- `commonEdit` - "Edit"
- `validationRequired` - "This field is required"
- `validationInvalidNumber` - "Please enter a valid number"

### Step 2: Determine String Category and Naming

Follow these naming conventions based on string purpose:

**Common UI** (buttons, actions used across features):
- Pattern: `common{Action}`
- Examples: `commonCancel`, `commonSave`, `commonDelete`

**Validation** (form validation messages):
- Pattern: `validation{Type}`
- Examples: `validationRequired`, `validationInvalidNumber`, `validationMustBeGreaterThanZero`

**Feature-specific** (specific to one feature):
- Pattern: `{feature}{Component}{Property}`
- Examples:
  - `tripCreateTitle` - Trip feature, Create page, title
  - `expenseFieldAmountLabel` - Expense feature, field label
  - `settlementLoadError` - Settlement feature, error message

**Dialogs**:
- Pattern: `{feature}{Action}DialogTitle` and `{feature}{Action}DialogMessage`
- Examples: `expenseDeleteDialogTitle`, `expenseDeleteDialogMessage`

**Buttons**:
- Pattern: `{feature}{Action}Button`
- Examples: `expenseAddButton`, `tripCreateButton`

**Errors**:
- Pattern: `{feature}{Action}Error`
- Examples: `expenseLoadError`, `tripCreateError`

### Step 3: Add String to app_en.arb

Edit `lib/l10n/app_en.arb` and add your string in the appropriate category:

#### Simple String (no parameters):

```json
{
  "myNewString": "Hello World"
}
```

#### String with Parameter:

```json
{
  "expensePaidBy": "Paid by {payerName}",
  "@expensePaidBy": {
    "placeholders": {
      "payerName": {
        "type": "String"
      }
    }
  }
}
```

#### String with Pluralization:

```json
{
  "expenseParticipantCount": "{count, plural, =0{No participants} =1{1 participant} other{{count} participants}}",
  "@expenseParticipantCount": {
    "placeholders": {
      "count": {
        "type": "int"
      }
    }
  }
}
```

#### String with Multiple Parameters:

```json
{
  "expenseDetailText": "{payerName} paid {amount} on {date}",
  "@expenseDetailText": {
    "placeholders": {
      "payerName": {
        "type": "String"
      },
      "amount": {
        "type": "String"
      },
      "date": {
        "type": "String"
      }
    }
  }
}
```

**IMPORTANT**:
- Don't add comment keys like `"_COMMENT_": "..."` - they break generation
- The `@stringKey` metadata is required for strings with parameters

### Step 4: Regenerate Localization Files

After adding strings to `app_en.arb`, regenerate the localization files:

```bash
# Automatic regeneration (happens when you):
flutter pub get
flutter build web
flutter run

# Manual regeneration:
flutter gen-l10n
```

### Step 5: Use String in Code

Import the helper extension and use `context.l10n.stringKey`:

```dart
import 'package:expense_tracker/core/l10n/l10n_extensions.dart';

// Simple string
Text(context.l10n.commonCancel)

// String with parameter
Text(context.l10n.expensePaidBy(payerName))

// String with pluralization
Text(context.l10n.expenseParticipantCount(count))

// String with multiple parameters
Text(context.l10n.expenseDetailText(payerName, amount, date))
```

## String Categories in ARB File

The `app_en.arb` file is organized into these categories (250+ entries):

1. **Common UI** - Buttons, actions used across features
2. **Validation** - Form validation messages
3. **Trips** - Trip management strings
4. **Participants** - Participant management strings
5. **Expenses** - Expense management strings
6. **Itemized Expenses** - Wizard-specific strings
7. **Expense Card** - Detail display strings
8. **Settlements** - Transfer and settlement strings
9. **Date/Time** - Relative date formatting
10. **Currency** - Currency display names
11. **Categories** - Expense category names

## Common Patterns

### Pattern 1: Form Labels

```json
{
  "expenseFieldAmountLabel": "Amount",
  "expenseFieldDescriptionLabel": "Description",
  "expenseFieldDateLabel": "Date"
}
```

Usage:
```dart
TextFormField(
  decoration: InputDecoration(
    labelText: context.l10n.expenseFieldAmountLabel,
  ),
)
```

### Pattern 2: Error Messages

```json
{
  "expenseLoadError": "Failed to load expenses",
  "expenseCreateError": "Failed to create expense",
  "expenseUpdateError": "Failed to update expense"
}
```

Usage:
```dart
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text(context.l10n.expenseLoadError)),
);
```

### Pattern 3: Dialog Confirmation

```json
{
  "expenseDeleteDialogTitle": "Delete Expense?",
  "expenseDeleteDialogMessage": "This action cannot be undone."
}
```

Usage:
```dart
showDialog(
  context: context,
  builder: (context) => AlertDialog(
    title: Text(context.l10n.expenseDeleteDialogTitle),
    content: Text(context.l10n.expenseDeleteDialogMessage),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(context.l10n.commonCancel),
      ),
      TextButton(
        onPressed: () {
          Navigator.pop(context);
          _deleteExpense();
        },
        child: Text(context.l10n.commonDelete),
      ),
    ],
  ),
);
```

### Pattern 4: Dynamic Content with Parameters

```json
{
  "tripParticipantJoined": "{name} joined the trip",
  "@tripParticipantJoined": {
    "placeholders": {
      "name": {
        "type": "String"
      }
    }
  }
}
```

Usage:
```dart
Text(context.l10n.tripParticipantJoined(participantName))
```

## Best Practices

**✅ DO:**
- Always use `context.l10n.stringKey` for user-facing text
- Use parameters for dynamic content: `context.l10n.expensePaidBy(name)`
- Use pluralization for counts: `context.l10n.expenseParticipantCount(count)`
- Group related strings with common prefixes (e.g., all expense strings start with "expense")
- Add `@stringKey` metadata for parameters and placeholders
- Reuse common strings (like `commonCancel`) instead of creating duplicates

**❌ DON'T:**
- Never hardcode user-facing strings in widgets
- Don't use string concatenation for translated text
  - ❌ BAD: `"Paid by " + payerName`
  - ✅ GOOD: `context.l10n.expensePaidBy(payerName)`
- Don't create one-off strings - reuse common strings when possible
- Don't add comment keys to ARB (e.g., `"_COMMENT_": "..."`) - they break generation

## Adding New Languages

To add support for a new language (e.g., Vietnamese):

### 1. Create new ARB file

Create `lib/l10n/app_vi.arb` with translated strings:

```json
{
  "commonCancel": "Hủy",
  "commonSave": "Lưu",
  "commonDelete": "Xóa"
}
```

### 2. Update main.dart

Add the new locale to `supportedLocales`:

```dart
return MaterialApp(
  // ...
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: const [
    Locale('en'), // English
    Locale('vi'), // Vietnamese
  ],
);
```

### 3. Regenerate localization files

```bash
flutter pub get
```

The system will automatically use the user's device locale.

## Troubleshooting

**Problem**: "Undefined name 'context.l10n'"
- **Solution**: Import the extension: `import 'package:expense_tracker/core/l10n/l10n_extensions.dart';`

**Problem**: "The getter 'myNewString' isn't defined for the type 'AppLocalizations'"
- **Solution**: Regenerate localization files: `flutter pub get` or `flutter gen-l10n`

**Problem**: "FormatException: Illegal argument in locale string"
- **Solution**: Check that your ARB JSON is valid (no trailing commas, correct placeholders syntax)

**Problem**: Strings not updating after editing app_en.arb
- **Solution**: Stop the app, run `flutter pub get`, then restart the app

**Problem**: Comment keys breaking generation
- **Solution**: Remove any keys starting with underscore or named "_COMMENT_" from ARB file

## Decision Checklist

Before adding a new string, verify:

- [ ] Have I searched `app_en.arb` for similar existing strings?
- [ ] Am I reusing common strings (like `commonCancel`) instead of creating new ones?
- [ ] Does my string name follow the naming conventions?
- [ ] Have I added `@stringKey` metadata for parameters?
- [ ] Am I using parameters instead of string concatenation?
- [ ] Am I using pluralization for count-based strings?
- [ ] Have I placed the string in the correct category section?
- [ ] Have I regenerated localization files after adding the string?
- [ ] Have I imported `l10n_extensions.dart` in my widget file?
- [ ] Am I using `context.l10n.stringKey` instead of hardcoding?

## Quick Reference

**Import**:
```dart
import 'package:expense_tracker/core/l10n/l10n_extensions.dart';
```

**Usage**:
```dart
context.l10n.commonCancel              // Simple
context.l10n.expensePaidBy(name)       // With parameter
context.l10n.expenseParticipantCount(count)  // With pluralization
```

**Regenerate**:
```bash
flutter pub get
# or
flutter gen-l10n
```

## Additional Resources

For more information, see:
- Root CLAUDE.md → Localization & String Management section
- `lib/l10n/app_en.arb` - Browse existing strings for examples
- `lib/core/l10n/l10n_extensions.dart` - Helper extension implementation
