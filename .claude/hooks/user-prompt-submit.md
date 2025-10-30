# User Prompt Submit Hook

This hook runs BEFORE Claude sees the user's message. It analyzes the request and auto-injects relevant context.

## Trigger: Before Processing User Request

### Step 1: Analyze User Intent

Check the user's message for keywords and intent:

**UI/Form Creation Keywords**: "create", "add", "build" + "page", "form", "screen", "UI", "widget"
→ **Action**: Inject mobile-first design reminder

**State Management Keywords**: "cubit", "bloc", "state", "emit", "repository"
→ **Action**: Inject activity logging reminder

**Text/String Keywords**: "text", "label", "message", "title", "button text"
→ **Action**: Inject localization reminder

**Currency/Amount Keywords**: "amount", "price", "cost", "budget", "currency", "money"
→ **Action**: Inject currency input reminder

**Test Keywords**: "test", "spec", "unit test", "widget test"
→ **Action**: Inject testing patterns reminder

**Bug/Fix Keywords**: "bug", "fix", "issue", "broken", "not working"
→ **Action**: Check TROUBLESHOOTING.md first

---

### Step 2: Auto-Inject Skill Reminders

Based on detected intent, inject skill references into your context:

#### For UI/Form Creation:
```
📱 MOBILE-FIRST REMINDER:
- Design for 375x667px (iPhone SE) FIRST
- Use SingleChildScrollView for forms
- Use MediaQuery for responsive spacing (isMobile ? 12 : 16)
- Use smaller fonts/icons on mobile
- Test on mobile viewport before considering done

Reference: .claude/skills/mobile-first-design.md for complete workflow
```

#### For State-Changing Operations:
```
📝 ACTIVITY LOGGING REMINDER:
- Inject ActivityLogRepository? (optional) in cubit constructor
- Get actorName from TripCubit.getCurrentUserForTrip() in UI
- Log after successful operation (in try-catch, non-fatal)
- Add new ActivityType to enum if needed

Reference: .claude/skills/activity-logging.md for complete workflow
```

#### For User-Facing Text:
```
🌍 LOCALIZATION REMINDER:
- NEVER hardcode user-facing strings
- Check lib/l10n/app_en.arb for existing strings first
- Add new strings with proper naming (featureComponentProperty)
- Run flutter pub get after adding strings
- Use context.l10n.stringKey in code

Reference: .claude/skills/localization-workflow.md for complete workflow
```

#### For Currency Input:
```
💰 CURRENCY INPUT REMINDER:
- ALWAYS use CurrencyTextField (never plain TextField)
- Use formatAmountForInput() when pre-filling
- Use stripCurrencyFormatting() before parsing
- Let CurrencyCode determine decimal places

Reference: .claude/skills/currency-input.md for complete workflow
```

#### For Testing:
```
🧪 TESTING REMINDER:
- Add @GenerateMocks annotations for dependencies
- Run dart run build_runner build after adding mocks
- Follow Arrange-Act-Assert pattern
- Test happy path, error cases, and activity logging
- Verify method calls with verify() and captureAny

Reference: .claude/skills/cubit-testing.md for complete workflow
```

#### For Bug Fixes:
```
🐛 BUG FIX REMINDER:
- Check TROUBLESHOOTING.md FIRST for known solutions
- Use .claude/skills/read-with-context.md to investigate
- Test fix on mobile viewport (375x667px)
- Run existing tests to ensure no regression
- Document fix with /docs.log

Reference: TROUBLESHOOTING.md for common issues
```

---

### Step 3: Inject Feature Documentation Reminder

If working on a feature branch:
```
📚 DOCUMENTATION REMINDER:
- Use /docs.log after completing each significant milestone
- Use /docs.log when creating new files
- Use /docs.log when fixing bugs
- Use /docs.update after architectural changes
- Use /docs.complete when feature is done

DOCUMENT AS YOU GO - Don't wait until the end!
```

---

### Step 4: Inject Project Context

Always remind Claude of critical project principles:

```
🎯 PROJECT PRINCIPLES:
1. Mobile-first application - Design for 375x667px FIRST
2. Clean architecture - Respect layer boundaries (Presentation → Domain → Data)
3. Activity logging required for all state-changing operations
4. Localization required for all user-facing text
5. CurrencyTextField required for all monetary amounts
6. Test coverage required for all cubits and business logic

See CLAUDE.md for quick reference hub
```

---

## Implementation Note

This hook should be lightweight and non-blocking. It adds context to help Claude follow best practices automatically, but doesn't prevent Claude from proceeding.

The injected reminders appear as system messages that Claude sees before processing the user's request, ensuring consistent pattern adherence without manual reminders.
