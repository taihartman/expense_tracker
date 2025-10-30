# Mobile-First Design Guidelines

**⚠️ CRITICAL: This is a mobile-first application.** All features MUST be designed and tested for mobile devices FIRST (375x667px - iPhone SE), then enhanced for larger screens.

## Table of Contents
- [Core Principles](#core-principles)
- [Responsive Breakpoints](#responsive-breakpoints)
- [Required Responsive Patterns](#required-responsive-patterns)
- [Common Anti-Patterns](#common-anti-patterns)
- [Mobile Testing Checklist](#mobile-testing-checklist)
- [Testing Commands](#testing-commands)
- [Helper Utilities](#helper-utilities)
- [Real-World Examples](#real-world-examples)

## Core Principles

1. **Mobile is the primary target** - Design for 375x667px (iPhone SE) first
2. **Touch-first interactions** - All touch targets minimum 44x44px
3. **Vertical scrolling preferred** - Avoid horizontal scrolling
4. **Progressive enhancement** - Start with mobile, add desktop features
5. **Keyboard-aware layouts** - Forms must remain visible when keyboard appears

## Responsive Breakpoints

Use these breakpoints consistently across the app:

```dart
final screenWidth = MediaQuery.of(context).size.width;
final isMobile = screenWidth < 600;      // Phones
final isTablet = screenWidth >= 600 && screenWidth < 1024;  // Tablets
final isDesktop = screenWidth >= 1024;   // Desktop browsers
```

## Required Responsive Patterns

### Pattern 1: Spacing & Padding

**ALWAYS use MediaQuery for spacing/padding** - never hardcode values:

```dart
// Use MediaQuery to adjust spacing
final horizontalPadding = isMobile ? 12.0 : 16.0;
final verticalSpacing = isMobile ? 12.0 : 16.0;

Padding(
  padding: EdgeInsets.symmetric(
    horizontal: horizontalPadding,
    vertical: verticalSpacing,
  ),
  child: ...
)
```

**Why?** Mobile screens have less space. Reducing padding from 16px to 12px saves precious vertical space.

### Pattern 2: Font Sizes

**Reduce font sizes on mobile** for better space utilization:

```dart
// Reduce font sizes on mobile for better space utilization
Text(
  title,
  style: TextStyle(
    fontSize: isMobile ? 18 : 20,  // 10% smaller on mobile
    fontWeight: FontWeight.bold,
  ),
)

Text(
  description,
  style: TextStyle(
    fontSize: isMobile ? 13 : 14,  // 1px smaller on mobile
    color: Colors.grey.shade600,
  ),
)
```

**Guidelines**:
- Titles: 18px mobile, 20px desktop
- Body text: 13px mobile, 14px desktop
- Small text: 11px mobile, 12px desktop

### Pattern 3: Button & Icon Sizes

**Smaller icons/buttons on mobile** to save space:

```dart
// Smaller icons/buttons on mobile to save space
IconButton(
  icon: Icon(Icons.edit, size: isMobile ? 20 : 24),
  padding: isMobile ? EdgeInsets.all(4) : null,
  constraints: isMobile
    ? BoxConstraints(minWidth: 36, minHeight: 36)
    : null,
)
```

**Guidelines**:
- Icons: 20px mobile, 24px desktop
- Touch targets: minimum 36x36px mobile, 40x40px desktop
- Button padding: 4px mobile, 8px desktop

### Pattern 4: Scrollable Forms (CRITICAL!)

**ALWAYS wrap forms in SingleChildScrollView** - this prevents keyboard from hiding form fields:

```dart
// ALWAYS wrap forms in SingleChildScrollView
SingleChildScrollView(
  child: Form(
    child: Column(
      children: [
        // Form fields...
      ],
    ),
  ),
)
```

**Why?** When the keyboard appears (often taking 50% of screen height), forms without scrolling become unusable. This is the #1 cause of mobile UX issues.

### Pattern 5: Modal Bottom Sheets for Complex Input

**Use modals for multi-field forms on mobile** - gives more vertical space:

```dart
// Use modals for multi-field forms on mobile
showModalBottomSheet(
  context: context,
  isScrollControlled: true,  // CRITICAL for keyboard handling
  backgroundColor: Colors.transparent,
  builder: (context) => Container(
    padding: EdgeInsets.only(
      bottom: MediaQuery.of(context).viewInsets.bottom,  // Keyboard padding
    ),
    child: SingleChildScrollView(
      child: YourFormWidget(),
    ),
  ),
)
```

**When to use**:
- Forms with 3+ fields
- Forms with complex inputs (pickers, dropdowns)
- Any form that might be hidden by keyboard

## Common Anti-Patterns

### ❌ DON'T

1. **Use fixed-height layouts that compete for vertical space**
   ```dart
   // ❌ BAD: Fixed height on mobile = disaster
   Container(
     height: 500,
     child: Column(
       children: [
         Header(),  // 100px
         Form(),    // Needs 300px
         Footer(),  // 100px
       ],
     ),
   )
   ```

2. **Place forms at the bottom where keyboards will hide them**
   ```dart
   // ❌ BAD: Form at bottom = hidden by keyboard
   Column(
     children: [
       Expanded(child: Content()),
       Form(),  // User can't see this when typing!
     ],
   )
   ```

3. **Use `Expanded` widgets inside non-scrollable Columns with many children**
   ```dart
   // ❌ BAD: Expanded in Column = layout explosion
   Column(
     children: [
       Widget1(),
       Expanded(child: Widget2()),
       Widget3(),
       Widget4(),
     ],
   )
   ```

4. **Hardcode padding/spacing values without responsive adjustment**
   ```dart
   // ❌ BAD: Hardcoded padding wastes mobile space
   Padding(
     padding: EdgeInsets.all(16),  // Too much on mobile!
     child: ...
   )
   ```

5. **Create touch targets smaller than 44x44px**
   ```dart
   // ❌ BAD: Tiny buttons = frustrated users
   IconButton(
     icon: Icon(Icons.edit, size: 16),  // Too small!
     constraints: BoxConstraints(minWidth: 24, minHeight: 24),
   )
   ```

6. **Assume landscape orientation**
   ```dart
   // ❌ BAD: Assuming landscape = broken mobile
   Row(
     children: [
       Expanded(child: Panel1()),
       Expanded(child: Panel2()),
       Expanded(child: Panel3()),
     ],
   )
   ```

7. **Use desktop-first design**
   ```dart
   // ❌ BAD: Desktop-first = mobile afterthought
   final padding = isDesktop ? 16.0 : 12.0;  // Wrong priority!
   ```

### ✅ DO

1. **Use `SingleChildScrollView` for all form pages**
   ```dart
   // ✅ GOOD: Scrollable = keyboard-friendly
   SingleChildScrollView(
     child: Form(...),
   )
   ```

2. **Use modal bottom sheets for complex input flows on mobile**
   ```dart
   // ✅ GOOD: Modal = more space for forms
   if (isMobile) {
     showModalBottomSheet(...);
   } else {
     showDialog(...);
   }
   ```

3. **Test on 375x667px viewport before considering it "done"**
   ```bash
   flutter run -d chrome --web-browser-flag "--window-size=375,667"
   ```

4. **Make all text visible when keyboard appears**
   ```dart
   // ✅ GOOD: Keyboard padding
   padding: EdgeInsets.only(
     bottom: MediaQuery.of(context).viewInsets.bottom,
   )
   ```

5. **Use `MediaQuery` for responsive spacing and sizing**
   ```dart
   // ✅ GOOD: Responsive spacing
   final padding = isMobile ? 12.0 : 16.0;
   ```

6. **Design for portrait-first, then adapt**
   ```dart
   // ✅ GOOD: Mobile-first logic
   final layout = isMobile
       ? Column(children: [...])  // Portrait stack
       : Row(children: [...]);    // Desktop side-by-side
   ```

7. **Implement mobile-first, enhance for desktop**
   ```dart
   // ✅ GOOD: Mobile-first branching
   final fontSize = isMobile ? 13 : 14;
   final iconSize = isMobile ? 20 : 24;
   ```

## Mobile Testing Checklist

**Before marking any UI feature as complete, verify:**

- [ ] Tested on mobile viewport (375x667px in Chrome DevTools)
- [ ] All text fields visible when keyboard appears
- [ ] No horizontal scrolling required
- [ ] Touch targets are minimum 44x44px
- [ ] Forms use `SingleChildScrollView`
- [ ] Responsive spacing using `MediaQuery` (`isMobile` checks)
- [ ] Font sizes adjusted for mobile
- [ ] Icons/buttons sized appropriately for mobile
- [ ] No fixed-height layouts competing for vertical space
- [ ] Modals/bottom sheets used for complex input on mobile

## Testing Commands

### Run with Mobile Viewport

```bash
# Run with mobile viewport in Chrome
flutter run -d chrome --web-browser-flag "--window-size=375,667"

# Test specific mobile scenarios
# Open Chrome DevTools (F12) → Toggle device toolbar → Select iPhone SE
flutter run -d chrome
```

### Manual Testing Steps

1. **Open Chrome DevTools** (F12)
2. **Toggle device toolbar** (Ctrl+Shift+M / Cmd+Shift+M)
3. **Select "iPhone SE"** from device dropdown
4. **Test these scenarios**:
   - Fill out a form (check keyboard doesn't hide fields)
   - Scroll vertically (should be smooth)
   - Scroll horizontally (should NOT be needed)
   - Tap all interactive elements (minimum 44x44px?)
   - Rotate to landscape (should still work)

## Helper Utilities

Use these helpers from `lib/core/utils/responsive.dart` (if available):

```dart
import 'package:expense_tracker/core/utils/responsive.dart';

// Check device type
if (isMobile(context)) { ... }
if (isTablet(context)) { ... }
if (isDesktop(context)) { ... }

// Get responsive values
final padding = responsivePadding(context);  // 12 mobile, 16 desktop
final fontSize = responsiveFontSize(context, base: 16);  // 14 mobile, 16 desktop
```

**Note**: If these helpers don't exist yet, use the MediaQuery pattern shown in [Responsive Breakpoints](#responsive-breakpoints).

## Real-World Examples

### Example 1: Items Step Page

See [items_step_page.dart](lib/features/expenses/presentation/pages/itemized/steps/items_step_page.dart) for a complete mobile-first implementation:

**What it does right**:
- ✅ Uses modal bottom sheet for add/edit form
- ✅ ListView uses full available height
- ✅ Responsive padding/spacing with `MediaQuery`
- ✅ Responsive font sizes (18px mobile vs 20px desktop)
- ✅ Smaller icons on mobile (20px vs 24px)
- ✅ Auto-scroll animation when adding items
- ✅ FAB positioned for thumb access

**Code snippet**:
```dart
// Responsive padding
final horizontalPadding = isMobile ? 12.0 : 16.0;

// Responsive font sizes
Text(
  item.name,
  style: TextStyle(
    fontSize: isMobile ? 18 : 20,
    fontWeight: FontWeight.bold,
  ),
)

// Responsive icons
Icon(Icons.edit, size: isMobile ? 20 : 24)

// Modal bottom sheet for forms
showModalBottomSheet(
  context: context,
  isScrollControlled: true,
  builder: (context) => ItemFormModal(),
)
```

### Example 2: Expense Form Page

Mobile-first form implementation:

```dart
class ExpenseFormPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.expenseCreateTitle),
      ),
      body: SingleChildScrollView(  // CRITICAL for mobile
        padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
        child: Form(
          child: Column(
            children: [
              // Currency input with responsive sizing
              CurrencyTextField(
                label: context.l10n.expenseFieldAmountLabel,
                style: TextStyle(
                  fontSize: isMobile ? 16 : 18,
                ),
              ),
              SizedBox(height: isMobile ? 12 : 16),

              // Description field
              TextFormField(
                decoration: InputDecoration(
                  labelText: context.l10n.expenseFieldDescriptionLabel,
                  labelStyle: TextStyle(
                    fontSize: isMobile ? 13 : 14,
                  ),
                ),
              ),
              SizedBox(height: isMobile ? 12 : 16),

              // Save button with responsive sizing
              ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 24 : 32,
                    vertical: isMobile ? 12 : 16,
                  ),
                ),
                child: Text(
                  context.l10n.commonSave,
                  style: TextStyle(fontSize: isMobile ? 14 : 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

## Decision Framework

When implementing a UI component, ask yourself:

### 1. "Does this have forms or text input?"
- **YES** → Wrap in `SingleChildScrollView`, add keyboard padding
- **NO** → Proceed to next question

### 2. "Does this need complex multi-field input?"
- **YES** → Use modal bottom sheet pattern on mobile
- **NO** → Proceed to next question

### 3. "Does this have spacing, padding, or typography?"
- **YES** → Use responsive values with `isMobile` checks
- **NO** → Proceed to next question

### 4. "Does this have icons or buttons?"
- **YES** → Use smaller sizes on mobile (20px vs 24px)
- **NO** → Proceed to next question

### 5. "Test it on mobile (375x667px)"
- Check all items in the [Mobile Testing Checklist](#mobile-testing-checklist)

## Common Scenarios

### Scenario 1: Adding a List Page

**Mobile considerations**:
- Use ListView.builder (efficient)
- Card padding: 12px mobile, 16px desktop
- Font sizes: 18px title mobile, 20px desktop
- Icons: 20px mobile, 24px desktop
- No fixed heights

**Example**:
```dart
ListView.builder(
  padding: EdgeInsets.all(isMobile ? 12 : 16),
  itemBuilder: (context, index) {
    return Card(
      child: ListTile(
        leading: Icon(Icons.receipt, size: isMobile ? 20 : 24),
        title: Text(
          expense.description,
          style: TextStyle(fontSize: isMobile ? 16 : 18),
        ),
        subtitle: Text(
          formatCurrency(expense.amount),
          style: TextStyle(fontSize: isMobile ? 13 : 14),
        ),
      ),
    );
  },
)
```

### Scenario 2: Adding a Form Page

**Mobile considerations**:
- MUST use `SingleChildScrollView`
- MUST handle keyboard with `viewInsets.bottom`
- Consider modal bottom sheet for complex forms
- Reduce spacing between fields on mobile

**Example**: See [Example 2: Expense Form Page](#example-2-expense-form-page)

### Scenario 3: Adding a Dashboard Page

**Mobile considerations**:
- Stack vertically on mobile (Column)
- Side-by-side on desktop (Row with Expanded)
- Use cards with responsive padding
- Charts should resize properly

**Example**:
```dart
if (isMobile)
  Column(
    children: [
      StatCard1(),
      SizedBox(height: 12),
      StatCard2(),
      SizedBox(height: 12),
      ChartCard(),
    ],
  )
else
  Row(
    children: [
      Expanded(child: StatCard1()),
      SizedBox(width: 16),
      Expanded(child: StatCard2()),
      SizedBox(width: 16),
      Expanded(flex: 2, child: ChartCard()),
    ],
  )
```

## Performance Considerations

### Avoid Expensive Operations on Mobile

**Use**: Lazy loading, pagination, cached images
**Avoid**: Loading all data at once, large unoptimized images

### Test on Actual Devices

Emulators are faster than real devices. Always test on:
- Physical iPhone SE or similar (low-end device)
- Physical Android device (mid-range)

## Additional Resources

- Root [CLAUDE.md](CLAUDE.md) - Quick reference hub
- [PROJECT_KNOWLEDGE.md](PROJECT_KNOWLEDGE.md) - Architecture overview
- [DEVELOPMENT.md](DEVELOPMENT.md) - Development workflows
- `.claude/skills/mobile-first-design.md` - Mobile-first design skill
- `lib/features/expenses/presentation/pages/itemized/steps/items_step_page.dart` - Reference implementation
