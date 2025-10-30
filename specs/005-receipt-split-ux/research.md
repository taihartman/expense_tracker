# Research: Receipt Split UX Improvements

**Feature**: 005-receipt-split-ux
**Date**: 2025-10-30
**Phase**: 0 (Research & Technology Choices)

## Overview

This document consolidates research findings for implementing the Receipt Split UX improvements. Key areas: Material Design FAB Speed Dial patterns, localization key migration strategies, backward compatibility approaches, and responsive FAB positioning.

---

## 1. Material Design FAB Speed Dial Pattern

### Decision

**Use custom implementation** of Speed Dial using built-in Flutter Material widgets (`FloatingActionButton`, `AnimatedContainer`, `Stack`).

### Rationale

**Options Evaluated**:

1. **Built-in Material Library** (`material.dart`):
   - **Pros**: Zero dependencies, Material Design compliant by default
   - **Cons**: No built-in Speed Dial widget (only single FAB)
   - **Verdict**: Need custom implementation

2. **Third-party Package** (e.g., `flutter_speed_dial`):
   - **Pros**: Battle-tested, feature-rich, customizable
   - **Cons**: Adds dependency, may have breaking changes, overkill for 2 options
   - **Verdict**: Not needed for simple 2-option case

3. **Custom Implementation**:
   - **Pros**: Full control, no dependencies, lightweight, Material Design compliant
   - **Cons**: Requires implementation effort (minimal for 2 options)
   - **Verdict**: ✅ **Selected** - best balance for this use case

### Implementation Approach

**Components**:
- **Main FAB**: `FloatingActionButton` with "+" icon (closed state)
- **Mini FABs**: Two `FloatingActionButton.small` widgets (Quick Expense, Receipt Split)
- **Animation**: `AnimatedOpacity` + `AnimatedScale` for expansion
- **Backdrop**: `GestureDetector` with semi-transparent `Container` (dismisses on tap)
- **Layout**: `Stack` with `Positioned` widgets for mini FAB placement

**Animation Timing** (Material Design 3):
- Expansion duration: 200ms
- Easing curve: `Curves.easeOutCubic`
- Stagger delay: 50ms between mini FABs

**Code Structure**:
```dart
class ExpenseFabSpeedDial extends StatefulWidget {
  bool _isOpen = false;

  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (_isOpen) _buildBackdrop(),
        _buildMainFAB(),
        if (_isOpen) ...[
          _buildMiniFAB(option1),
          _buildMiniFAB(option2),
        ],
      ],
    );
  }
}
```

**Positioning**:
- Main FAB: Bottom-right (16dp margin)
- Mini FAB 1 (Quick Expense): 72dp above main FAB
- Mini FAB 2 (Receipt Split): 144dp above main FAB
- Vertical stacking (most common Speed Dial pattern)

### Alternatives Considered

- **Horizontal expansion**: Rejected (takes more horizontal space, uncommon pattern)
- **Bottom sheet with options**: Rejected (extra tap, less discoverable than Speed Dial)
- **Long-press menu**: Rejected (poor discoverability, non-standard interaction)

### References

- [Material Design 3 - FAB Guidelines](https://m3.material.io/components/floating-action-button/guidelines)
- [Flutter FAB Documentation](https://api.flutter.dev/flutter/material/FloatingActionButton-class.html)
- [Material Motion - Speed Dial](https://material.io/design/components/buttons-floating-action-button.html#types-of-transitions)

---

## 2. Localization Key Migration Best Practices

### Decision

**Rename all localization keys** from `itemized*` prefix to `receiptSplit*` prefix in `app_en.arb` and update all code references.

### Rationale

**Options Evaluated**:

1. **Full Key Rename** (`itemized*` → `receiptSplit*`):
   - **Pros**: Consistent terminology, clear intent, future-proof
   - **Cons**: Requires updating ~60 strings + all code references
   - **Verdict**: ✅ **Selected** - aligns with feature goals

2. **Keep Keys, Change String Values Only**:
   - **Pros**: Minimal code changes, faster implementation
   - **Cons**: Misleading key names (`itemizedWizardTitle` says "Receipt Split"), confusing for future developers
   - **Verdict**: ❌ Rejected - poor maintainability

3. **Gradual Migration** (support both old and new keys):
   - **Pros**: No breaking changes, smooth transition
   - **Cons**: Doubled string count, complexity, confusion
   - **Verdict**: ❌ Rejected - overkill for UI-only change

### Migration Strategy

**Step-by-Step Process**:

1. **Backup**: Create copy of `app_en.arb` (rollback if needed)

2. **ARB File Updates**:
   ```bash
   # Find all itemized keys (excluding metadata)
   grep -o '"itemized[^"]*"' lib/l10n/app_en.arb

   # Replace itemized → receiptSplit (case-sensitive)
   sed -i '' 's/"itemized/"receiptSplit/g' lib/l10n/app_en.arb
   ```

3. **String Value Updates**:
   - Manually update string values to use "Receipt Split" terminology
   - Example: `"New Itemized Expense"` → `"New Receipt Split"`
   - Keep hint text: `"(Who Ordered What)"`

4. **Code Reference Updates**:
   ```bash
   # Find all code references
   grep -r "context\.l10n\.itemized" lib/ test/

   # Replace in all Dart files
   find lib test -name "*.dart" -exec sed -i '' 's/\.l10n\.itemized/.l10n.receiptSplit/g' {} +
   ```

5. **Regenerate L10n Files**:
   ```bash
   flutter pub get  # Triggers l10n generation
   dart format .    # Format generated files
   ```

6. **Verification**:
   ```bash
   flutter analyze                    # Check for broken references
   grep -r "itemized" lib/l10n/       # Ensure no old keys remain (except @metadata)
   flutter test                       # Run all tests
   ```

### Testing Strategy

**Automated Tests**:
- Widget tests verify strings render correctly
- Analyzer catches broken l10n references
- Tests use `context.l10n.receiptSplit*` syntax

**Manual Verification**:
- Visual inspection of wizard screens
- Check all 4 wizard steps render correct labels
- Verify expense card displays "Receipt Split" label
- Test edit flow opens with correct titles

### Rollback Plan

If migration fails:
1. Restore `app_en.arb` from backup
2. Run `flutter pub get` to regenerate old l10n files
3. Revert code changes via git

### Files Requiring Updates

**ARB Files** (1 file):
- `lib/l10n/app_en.arb`

**Dart Code Files** (~10-15 files):
- `lib/features/expenses/presentation/pages/itemized/itemized_expense_wizard.dart`
- `lib/features/expenses/presentation/pages/itemized/steps/people_step_page.dart`
- `lib/features/expenses/presentation/pages/itemized/steps/items_step_page.dart`
- `lib/features/expenses/presentation/pages/itemized/steps/extras_step_page.dart`
- `lib/features/expenses/presentation/pages/itemized/steps/review_step_page.dart`
- `lib/features/expenses/presentation/widgets/expense_card.dart`
- `lib/features/expenses/presentation/pages/expense_form_page.dart`
- `lib/features/expenses/presentation/widgets/expense_form_bottom_sheet.dart`
- Test files referencing `itemized*` strings

### String Count Estimate

**Total strings to update**: ~60-65
- Wizard titles/steps: 5 strings
- People step: 6 strings
- Items step: 11 strings
- Extras step: 8 strings
- Review step: 10 strings
- Error messages: 8 strings
- Card display: 5 strings
- Form labels: 2 strings
- Metadata entries (@itemized*): ~15 entries

---

## 3. Backward Compatibility for Enum Values

### Decision

**Keep `SplitType.itemized` enum value unchanged**. Only update UI terminology from "Itemized" to "Receipt Split".

### Rationale

**Options Evaluated**:

1. **Keep Enum as `itemized`** (UI-only change):
   - **Pros**: Zero data migration, zero Firestore impact, zero serialization changes
   - **Cons**: Internal code uses `itemized`, UI shows "Receipt Split" (minor inconsistency)
   - **Verdict**: ✅ **Selected** - safest, simplest approach

2. **Rename Enum to `receiptSplit`**:
   - **Pros**: Perfect consistency between code and UI
   - **Cons**: Firestore deserialization breaks, requires data migration, high risk
   - **Verdict**: ❌ Rejected - unnecessary complexity and risk

3. **Add New Enum Value** (`receiptSplit`) + deprecate `itemized`:
   - **Pros**: Gradual migration path
   - **Cons**: Two enum values for same concept, confusion, increased complexity
   - **Verdict**: ❌ Rejected - doubles complexity for no benefit

### Implementation Details

**Enum Definition** (`lib/core/models/split_type.dart`):
```dart
enum SplitType {
  equal,
  weighted,
  itemized,  // ← Keep this value unchanged
}
```

**Serialization** (unchanged):
```dart
String _splitTypeToString(SplitType type) {
  switch (type) {
    case SplitType.equal:
      return 'equal';
    case SplitType.weighted:
      return 'weighted';
    case SplitType.itemized:  // ← Still serializes as "itemized"
      return 'itemized';
  }
}
```

**UI Display** (use localization):
```dart
// OLD
Text(context.l10n.expenseSplitTypeItemized)  // "Itemized (Add Line Items)"

// NEW
Text(context.l10n.expenseSplitTypeReceiptSplit)  // "Receipt Split (Who Ordered What)"
```

**Backward Compatibility**:
- Existing Firestore documents: `{ "splitType": "itemized" }` deserialize correctly
- Edit flow: `if (expense.splitType == SplitType.itemized)` still works
- No migration script needed

### Testing Strategy

**Tests**:
1. Create new Receipt Split expense → saves with `splitType: itemized`
2. Load existing itemized expense from Firestore → deserializes correctly
3. Edit existing itemized expense → opens wizard, saves correctly
4. Display expense card with itemized type → shows "Receipt Split" label

### Alternatives Considered

- **Alias enum value**: Dart doesn't support enum aliases
- **String-based split type**: Rejected (type safety loss, error-prone)
- **Migration script**: Rejected (overkill for UI-only change)

---

## 4. FAB Positioning and Responsive Design

### Decision

**Use `Scaffold.floatingActionButton` with Material Design standard positioning** (bottom-right, 16dp margin). Implement responsive adjustments for small screens (<360dp width).

### Rationale

**Options Evaluated**:

1. **Standard FAB Positioning** (bottom-right, 16dp):
   - **Pros**: Material Design compliant, familiar, works on most devices
   - **Cons**: May overlap content on very small screens
   - **Verdict**: ✅ **Selected** with responsive fallback

2. **Bottom Navigation Bar** (FAB in center of bottom bar):
   - **Pros**: More stable, doesn't overlap content
   - **Cons**: Requires bottom navigation bar (not in current design), major UI change
   - **Verdict**: ❌ Rejected - out of scope

3. **AppBar Menu** (keep "+" button in AppBar):
   - **Pros**: No overlap issues, consistent with current design
   - **Cons**: Doesn't separate Quick vs Receipt Split, defeats feature purpose
   - **Verdict**: ❌ Rejected - contradicts feature goals

### Implementation Approach

**Standard Positioning**:
```dart
Scaffold(
  body: ExpenseListContent(...),
  floatingActionButton: ExpenseFabSpeedDial(...),
  floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,  // Bottom-right
)
```

**Material Design Specs**:
- FAB size: 56x56dp (standard)
- Margin from screen edge: 16dp (left/right/bottom)
- Elevation: 6dp (standard FAB elevation)
- Mini FAB size: 40x40dp (small variant)

### Responsive Design Strategy

**Screen Size Breakpoints**:

| Viewport Width | FAB Behavior | Rationale |
|----------------|--------------|-----------|
| ≥360dp | Standard bottom-right FAB | Material Design standard, most devices |
| 320-359dp | Slightly smaller FAB (48x48dp) | Prevent overlap, still tappable (44x44px minimum) |
| <320dp | Consider alternative (rare, future work) | Very rare viewport size, low priority |

**Implementation**:
```dart
Widget build(BuildContext context) {
  final screenWidth = MediaQuery.of(context).size.width;
  final fabSize = screenWidth < 360 ? 48.0 : 56.0;

  return FloatingActionButton(
    mini: screenWidth < 360,
    onPressed: _toggleSpeedDial,
    child: Icon(Icons.add, size: fabSize * 0.6),
  );
}
```

### Overlap Prevention

**Potential Conflicts**:

1. **Bottom Sheet** (expense form):
   - Issue: FAB might be hidden when bottom sheet opens
   - Solution: Flutter automatically adjusts FAB position when bottom sheet opens (built-in behavior)
   - Test: Verify FAB visible and tappable when bottom sheet at 50% height

2. **Expense List Scroll**:
   - Issue: FAB might overlap last expense card
   - Solution: Add bottom padding to expense list (`EdgeInsets.only(bottom: 80)`)
   - Ensures last card fully scrollable above FAB

3. **Settlement Cards**:
   - Issue: FAB might overlap settlement summary at bottom of page
   - Solution: Same as above - bottom padding on scrollable content

**Code Example**:
```dart
ListView(
  padding: EdgeInsets.only(
    left: 16,
    right: 16,
    top: 16,
    bottom: 80,  // ← Extra space for FAB
  ),
  children: expenseCards,
)
```

### Accessibility Considerations

**Touch Targets**:
- Main FAB: 56x56dp (exceeds 44x44px minimum) ✅
- Mini FABs: 40x40dp (< 48x48dp recommended, but acceptable for secondary actions)
- Touch padding: `EdgeInsets.all(8)` around mini FABs (effective 56x56dp touch area)

**Screen Reader Support**:
```dart
Semantics(
  label: 'Add expense options',
  button: true,
  child: FloatingActionButton(...),
)
```

**Keyboard Navigation**:
- FAB receives focus in tab order
- Enter/Space activates FAB
- Esc closes Speed Dial

### Testing Strategy

**Manual Tests**:
- Test on Chrome DevTools with various viewport sizes (320dp, 360dp, 480dp, 768dp)
- Test on iOS Safari (iPhone SE, iPhone 12, iPad)
- Test on Android Chrome (small, medium, large devices)
- Verify FAB doesn't overlap expense cards when scrolled to bottom
- Verify FAB visible when bottom sheet open at 50% and 90% height

**Automated Tests**:
- Widget test verifies FAB present in Scaffold
- Widget test verifies FAB responds to viewport size changes (using `MediaQuery.of`)

---

## 5. Additional Considerations

### Animation Performance

**Concern**: Speed Dial expansion might cause jank on lower-end devices

**Mitigation**:
- Use `RepaintBoundary` around Speed Dial to isolate repaints
- Profile with Flutter DevTools Timeline
- Target <16ms frame time (60 FPS)
- Simplify animation if profiling shows issues

**Benchmark**:
```dart
// Before optimization
Timeline.startSync('SpeedDialExpansion');
_animateExpansion();
Timeline.finishSync();

// Measure with DevTools → ensure <16ms
```

### Icon Selection

**Icons Chosen**:
- **Main FAB (closed)**: `Icons.add` (standard, familiar)
- **Quick Expense**: `Icons.flash_on` or `Icons.bolt` (fast, simple)
- **Receipt Split**: `Icons.receipt_long` (clearly represents receipt)

**Rationale**:
- `Icons.receipt_long` clearly communicates "receipt-based splitting"
- `Icons.flash_on` suggests speed/simplicity for Quick Expense
- Both are part of Material Icons (no custom assets needed)

### Localization for FAB Labels

**New Keys Required**:
```json
{
  "fabSpeedDialAddExpense": "Add expense options",
  "fabQuickExpenseLabel": "Quick Expense",
  "fabQuickExpenseTooltip": "Add simple expense (equal or weighted split)",
  "fabReceiptSplitLabel": "Receipt Split",
  "fabReceiptSplitTooltip": "Add detailed receipt (who ordered what)"
}
```

---

## Summary of Decisions

| Research Area | Decision | Rationale |
|---------------|----------|-----------|
| **Speed Dial Implementation** | Custom implementation using Flutter Material widgets | No dependencies, full control, lightweight |
| **Localization Migration** | Rename all `itemized*` keys to `receiptSplit*` | Consistent terminology, clear intent |
| **Enum Backward Compatibility** | Keep `SplitType.itemized` unchanged | Zero migration, safest approach |
| **FAB Positioning** | Standard bottom-right with responsive adjustments | Material Design compliant, familiar pattern |
| **Animation** | Material Design standard (200ms, `easeOutCubic`) | Smooth, performant, on-brand |
| **Icons** | `receipt_long` for Receipt Split, `flash_on` for Quick Expense | Clear metaphors, built-in Material icons |

---

## Next Phase

**Phase 1**: Generate `quickstart.md` implementation guide and update agent context with final technical decisions.

**Ready for**: `/speckit.tasks` command to generate dependency-ordered implementation tasks.
