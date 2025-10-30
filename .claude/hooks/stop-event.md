# Stop Event Hook

This hook runs AFTER Claude finishes responding. It checks for errors, pattern compliance, and reminds about documentation.

## Trigger: After Claude Completes Response

### Step 1: Check for Build Errors

If files were edited, check for TypeScript/Dart errors:

```bash
# Run Flutter analyzer
flutter analyze 2>&1 | head -20
```

**If errors found**:
```
⚠️ BUILD ERRORS DETECTED

Found X issue(s) in the code:
[List errors]

NEXT STEPS:
1. Review and fix the errors above
2. Run flutter analyze to verify fixes
3. Consider using TROUBLESHOOTING.md if stuck
```

**If < 5 errors**: Show them and fix immediately
**If ≥ 5 errors**: Recommend systematic debugging

---

### Step 2: Pattern Compliance Check

Based on files edited, verify patterns were followed:

#### If Form/UI Files Edited (*.dart in presentation/pages/ or presentation/widgets/)

Check for mobile-first patterns:
```
📱 MOBILE-FIRST SELF-CHECK

Files edited: [list files]

Did you:
- [ ] Use SingleChildScrollView for forms?
- [ ] Use MediaQuery for responsive spacing?
- [ ] Use isMobile checks for font sizes/icons?
- [ ] Test on 375x667px viewport?
- [ ] Avoid hardcoded padding values?

If not, consider reviewing .claude/skills/mobile-first-design.md
```

#### If Cubit Files Edited (*_cubit.dart)

Check for activity logging:
```
📝 ACTIVITY LOGGING SELF-CHECK

Files edited: [list files]

For state-changing operations, did you:
- [ ] Inject ActivityLogRepository? (optional)?
- [ ] Get actorName from TripCubit.getCurrentUserForTrip()?
- [ ] Log after successful operation (in try-catch)?
- [ ] Add new ActivityType to enum if needed?

If not, consider reviewing .claude/skills/activity-logging.md
```

#### If UI Files With Text Edited

Check for localization:
```
🌍 LOCALIZATION SELF-CHECK

Files edited: [list files]

Did you:
- [ ] Avoid hardcoding user-facing strings?
- [ ] Add new strings to lib/l10n/app_en.arb?
- [ ] Use context.l10n.* for all text?
- [ ] Run flutter pub get after adding strings?

If not, consider reviewing .claude/skills/localization-workflow.md
```

#### If Files With Currency Input Edited

Check for CurrencyTextField usage:
```
💰 CURRENCY INPUT SELF-CHECK

Files edited: [list files]

Did you:
- [ ] Use CurrencyTextField (not plain TextField)?
- [ ] Use formatAmountForInput() when pre-filling?
- [ ] Use stripCurrencyFormatting() before parsing?

If not, consider reviewing .claude/skills/currency-input.md
```

---

### Step 3: Test Reminder

If significant code was added:
```
🧪 TEST REMINDER

New code added. Don't forget to:
- [ ] Write unit tests for cubits/business logic
- [ ] Run flutter test to verify
- [ ] Test on mobile viewport (375x667px) for UI changes

Use .claude/skills/cubit-testing.md for testing patterns
```

---

### Step 4: Documentation Reminder

If this was a significant change:
```
📚 DOCUMENTATION REMINDER

Significant changes detected. Consider:
- /docs.log "description of what changed"

Examples:
- /docs.log "Added BudgetFormPage with mobile-first design"
- /docs.log "Fixed keyboard hiding form fields"
- /docs.log "Implemented activity logging for budget operations"

DOCUMENT NOW - Don't wait until the end of the day!
```

---

### Step 5: Format Check

If Dart files were edited:
```bash
# Check if files need formatting
flutter format --set-exit-if-changed . 2>&1 | head -10
```

**If formatting needed**:
```
🎨 FORMATTING REMINDER

Some files need formatting. Run:
flutter format .

This will be required before committing.
```

---

## Self-Check Philosophy

These reminders are **gentle nudges**, not blocking errors. They help Claude:
1. Self-assess code quality
2. Remember project patterns
3. Stay consistent with conventions
4. Avoid common mistakes

Claude should review each checklist and either:
- ✅ Confirm pattern was followed
- ⚠️ Acknowledge gap and fix it
- ℹ️ Explain why pattern doesn't apply

---

## Implementation Note

This hook should be **non-intrusive** but **consistent**. It runs after every response, but only shows relevant checks based on what files were actually edited.

The goal is to create a "second pair of eyes" that catches mistakes before they become bugs.
