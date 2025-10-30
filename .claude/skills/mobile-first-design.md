# Mobile-First Design Skill

## Description
This skill provides a systematic workflow for implementing mobile-first, responsive Flutter UI components. Use this when creating or refactoring any UI component in the expense tracker app.

## When to Use
- Creating new UI pages or widgets
- Refactoring existing UI components
- Fixing mobile layout issues
- Reviewing responsive design implementations
- When you see viewport or layout-related bugs

## Core Philosophy
**⚠️ CRITICAL**: This is a mobile-first application. All features MUST be designed and tested for mobile devices FIRST (375x667px - iPhone SE), then enhanced for larger screens.

## Workflow

### Step 1: Understand Responsive Breakpoints
```dart
final screenWidth = MediaQuery.of(context).size.width;
final isMobile = screenWidth < 600;      // Phones
final isTablet = screenWidth >= 600 && screenWidth < 1024;  // Tablets
final isDesktop = screenWidth >= 1024;   // Desktop browsers
```

### Step 2: Apply Required Responsive Patterns

#### Pattern 1: Responsive Spacing
```dart
// ALWAYS use MediaQuery for spacing/padding
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

#### Pattern 2: Responsive Typography
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

#### Pattern 3: Responsive Icons/Buttons
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

#### Pattern 4: Scrollable Forms (CRITICAL!)
```dart
// ALWAYS wrap forms in SingleChildScrollView
// This prevents keyboard from hiding form fields
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

#### Pattern 5: Modal Bottom Sheets for Complex Input
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

### Step 3: Avoid Common Anti-Patterns

**❌ DON'T:**
- Use fixed-height layouts that compete for vertical space
- Place forms at the bottom where keyboards will hide them
- Use `Expanded` widgets inside non-scrollable Columns with many children
- Hardcode padding/spacing values without responsive adjustment
- Create touch targets smaller than 44x44px
- Assume landscape orientation
- Use desktop-first design

**✅ DO:**
- Use `SingleChildScrollView` for all form pages
- Use modal bottom sheets for complex input flows on mobile
- Test on 375x667px viewport before considering it "done"
- Make all text visible when keyboard appears
- Use `MediaQuery` for responsive spacing and sizing
- Design for portrait-first, then adapt
- Implement mobile-first, enhance for desktop

### Step 4: Use Helper Utilities (if available)

Check if `lib/core/utils/responsive.dart` exists and use its helpers:

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

### Step 5: Run Mobile Testing Checklist

Before marking any UI feature as complete, verify:

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

```bash
# Run with mobile viewport in Chrome
flutter run -d chrome --web-browser-flag "--window-size=375,667"

# Test with Chrome DevTools
# 1. flutter run -d chrome
# 2. Open Chrome DevTools (F12)
# 3. Toggle device toolbar
# 4. Select iPhone SE
```

## Real-World Reference Example

See [items_step_page.dart](lib/features/expenses/presentation/pages/itemized/steps/items_step_page.dart) for a complete mobile-first implementation demonstrating:

- ✅ Uses modal bottom sheet for add/edit form
- ✅ ListView uses full available height
- ✅ Responsive padding/spacing with `MediaQuery`
- ✅ Responsive font sizes (18px mobile vs 20px desktop)
- ✅ Smaller icons on mobile (20px vs 24px)
- ✅ Auto-scroll animation when adding items
- ✅ FAB positioned for thumb access

## Decision Framework

When implementing a UI component, ask yourself:

1. **"Does this have forms or text input?"**
   - → YES: Wrap in `SingleChildScrollView`, add keyboard padding
   - → NO: Proceed to next question

2. **"Does this need complex multi-field input?"**
   - → YES: Use modal bottom sheet pattern on mobile
   - → NO: Proceed to next question

3. **"Does this have spacing, padding, or typography?"**
   - → YES: Use responsive values with `isMobile` checks
   - → NO: Proceed to next question

4. **"Does this have icons or buttons?"**
   - → YES: Use smaller sizes on mobile (20px vs 24px)
   - → NO: Proceed to next question

5. **"Test it on mobile (375x667px)"**
   - → Check all items in the testing checklist above

## Success Criteria

Your implementation is mobile-first compliant when:
- ✅ All testing checklist items pass
- ✅ No anti-patterns detected
- ✅ Responsive patterns applied consistently
- ✅ Keyboard doesn't hide form fields
- ✅ No horizontal scrolling
- ✅ Looks good on 375x667px viewport

## Additional Resources

For more detailed information, see:
- Root CLAUDE.md → Mobile-First Design Principles section
- MOBILE.md (if split from root CLAUDE.md)
