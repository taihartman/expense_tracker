# Mobile Testing Checklist - Global Category System

**Feature ID**: 008-global-category-system
**Test Viewport**: 375x667px (iPhone SE)
**Test Date**: TBD

## Overview

This checklist covers manual testing for the global category system UI on mobile viewports. Complete all items before marking feature as production-ready.

## Setup

```bash
# Run app in mobile viewport
flutter run -d chrome --web-browser-flag "--window-size=375,667"
```

## T064: Mobile Viewport Layout Testing

### CategorySelector (Horizontal Chip List)

- [ ] Chips display horizontally in scrollable row
- [ ] No horizontal scrolling of page (only chip scroll)
- [ ] All chip text is readable (not truncated)
- [ ] Selected chip has visible highlight/border
- [ ] Touch targets are minimum 44x44px (measure with DevTools)
- [ ] Smooth scroll behavior (no jank)
- [ ] Icons display correctly at small size
- [ ] Color contrast meets accessibility standards

**Test Steps**:
1. Open expense creation form
2. Scroll to category section
3. Verify chip layout
4. Measure touch targets in Chrome DevTools (right-click → Inspect → Elements → measure)

### CategoryBrowserBottomSheet (Search & Browse)

- [ ] Bottom sheet opens from bottom (DraggableScrollableSheet)
- [ ] Drag handle visible and centered
- [ ] Header "Select Category" not truncated
- [ ] Search field full width with proper padding
- [ ] Search icon and clear button visible
- [ ] "+ Create New Category" button full width
- [ ] Category list scrolls smoothly
- [ ] Category icons display at proper size
- [ ] Category names don't overflow ListTile
- [ ] Usage count subtitle visible
- [ ] No content hidden behind software keyboard
- [ ] Can dismiss by dragging down

**Test Steps**:
1. Tap "Other" chip in CategorySelector
2. Verify bottom sheet animation
3. Test search functionality
4. Scroll through categories
5. Verify all interactive elements accessible

### CategoryCreationBottomSheet (Create Custom Category)

- [ ] Bottom sheet fills 90% of screen height
- [ ] Header "Create Category" visible
- [ ] Close button accessible (44x44px)
- [ ] Category name TextField full width
- [ ] Hint text visible: "e.g., Groceries, Gas, Dining"
- [ ] Icon grid displays 6 columns
- [ ] All 30 icons visible and tappable
- [ ] Icon selection highlights correctly
- [ ] Color grid displays 6 columns
- [ ] All 19 colors visible and tappable
- [ ] Color selection shows checkmark
- [ ] Create button fixed at bottom
- [ ] Create button spans full width
- [ ] Error messages display above TextField
- [ ] No content obscured by keyboard

**Test Steps**:
1. Open CategoryBrowserBottomSheet
2. Tap "+ Create New Category"
3. Verify layout and spacing
4. Test icon selection (tap multiple icons)
5. Test color selection (tap multiple colors)
6. Enter category name
7. Verify validation messages

## T065: Keyboard Interaction Testing

### Form Field Behavior

- [ ] Tapping category name field opens keyboard
- [ ] Keyboard doesn't cover TextField
- [ ] Keyboard doesn't cover Create button
- [ ] Bottom sheet scrolls to keep field visible
- [ ] Can type normally on virtual keyboard
- [ ] Keyboard dismiss on outside tap
- [ ] Field validation updates in real-time
- [ ] Error message visible while keyboard open

**Test Steps**:
1. Open CategoryCreationBottomSheet
2. Tap category name field
3. Verify keyboard appearance
4. Type "Test Category"
5. Verify field stays visible
6. Test validation by clearing field
7. Test validation with invalid characters "Test ☕"
8. Dismiss keyboard

### Scroll Behavior with Keyboard

- [ ] SingleChildScrollView allows full form access
- [ ] Can scroll to icon picker while keyboard open
- [ ] Can scroll to color picker while keyboard open
- [ ] Scrolling is smooth (no jank)
- [ ] Scroll resets after keyboard dismiss

**Test Steps**:
1. Open category name field (keyboard appears)
2. Try to scroll down to icon section
3. Verify smooth scrolling
4. Verify icons still accessible
5. Dismiss keyboard
6. Verify scroll position

## T066: Touch Target Verification

### Minimum Touch Target: 44x44px

Use Chrome DevTools to measure each interactive element:

**CategorySelector Chips**:
- [ ] Each chip ≥ 44px height
- [ ] Adequate horizontal spacing between chips
- [ ] Tap area doesn't overlap adjacent chips

**CategoryBrowserBottomSheet**:
- [ ] Search field ≥ 48px height
- [ ] Clear button ≥ 44x44px
- [ ] "+ Create New Category" button ≥ 48px height
- [ ] Each category ListTile ≥ 56px height
- [ ] Category tap area covers full ListTile

**CategoryCreationBottomSheet**:
- [ ] Close button ≥ 44x44px
- [ ] Category name TextField ≥ 48px height
- [ ] Each icon grid cell ≥ 44x44px
- [ ] Each color grid cell ≥ 44x44px
- [ ] Create button ≥ 48px height

**Measurement Steps** (Chrome DevTools):
1. Right-click element → Inspect
2. In Elements panel, select element
3. Check Computed tab for dimensions
4. Or use Measure tool (Cmd+Shift+M on Mac)

## T067: Performance Testing

### CategoryBrowserBottomSheet Performance

- [ ] Search results appear < 500ms after typing
- [ ] No visible lag when scrolling category list
- [ ] Bottom sheet animation smooth (60fps)
- [ ] Icon rendering doesn't cause jank

**Test Steps**:
1. Open DevTools Performance tab
2. Start recording
3. Open CategoryBrowserBottomSheet
4. Type search query
5. Scroll through results
6. Stop recording
7. Verify < 500ms search latency
8. Verify no dropped frames

### CategoryCreationBottomSheet Performance

- [ ] Icon grid renders < 200ms
- [ ] Color grid renders < 200ms
- [ ] Icon selection immediate visual feedback
- [ ] Color selection immediate visual feedback
- [ ] Form validation < 100ms

**Test Steps**:
1. Open DevTools Performance tab
2. Record opening CategoryCreationBottomSheet
3. Measure initial render time
4. Test interaction responsiveness

## Accessibility Testing

### Screen Reader Support

- [ ] Category names announced correctly
- [ ] Usage counts announced
- [ ] Form fields have labels
- [ ] Error messages announced
- [ ] Button purposes clear

**Test Steps** (macOS VoiceOver):
1. Enable VoiceOver (Cmd+F5)
2. Navigate through category UI
3. Verify all elements announced properly

### Color Contrast

- [ ] Text readable on all backgrounds
- [ ] Selected state clearly visible
- [ ] Error states clearly visible
- [ ] Icons visible on colored backgrounds

**Tool**: Chrome DevTools Lighthouse Accessibility Audit

## Edge Cases

### Long Category Names

- [ ] 50-character name displays without overflow
- [ ] Text wraps or truncates gracefully
- [ ] Icon and color still accessible

**Test**: Create category with name "A Very Long Category Name That Is Fifty Characters"

### Many Categories

- [ ] List scrolls smoothly with 100+ categories
- [ ] Search performance still good
- [ ] No memory leaks on repeated open/close

### Network Conditions

- [ ] Loading state visible during fetch
- [ ] Error state visible on failure
- [ ] Retry mechanism works
- [ ] Offline behavior graceful

**Test**: Use Chrome DevTools Network → Throttling

## Sign-Off

- [ ] All T064 items passed
- [ ] All T065 items passed
- [ ] All T066 items passed
- [ ] All T067 items passed
- [ ] Accessibility checks passed
- [ ] Edge cases handled
- [ ] No critical bugs found

**Tested By**: ________________
**Date**: ________________
**Notes**:

---

## Known Issues

(Document any issues found during testing)

- Issue 1:
- Issue 2:

## Recommendations

(Document any UX improvements or optimizations)

- Recommendation 1:
- Recommendation 2:
