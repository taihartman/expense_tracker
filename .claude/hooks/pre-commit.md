# Pre-Commit Hook

This hook runs BEFORE creating commits. It ensures code quality and pattern compliance.

## Trigger: Before Git Commit

### Step 1: Run Quality Checks

```bash
# Check for analysis errors
echo "🔍 Running flutter analyze..."
flutter analyze

# Check formatting
echo "🎨 Checking code formatting..."
flutter format --set-exit-if-changed .

# Run tests
echo "🧪 Running tests..."
flutter test
```

**If any check fails**:
```
❌ PRE-COMMIT CHECKS FAILED

Please fix the issues above before committing:
1. flutter analyze - Fix analysis errors
2. flutter format . - Format code
3. flutter test - Fix failing tests

Run these commands to fix issues, then try committing again.
```

---

### Step 2: Pattern Compliance Final Check

Review staged files for pattern compliance:

#### Check for Hardcoded Strings

```bash
# Search for hardcoded strings in staged Dart files
git diff --cached --name-only | grep '\.dart$' | while read file; do
  if git diff --cached "$file" | grep -E "Text\(['\"]" | grep -v "context\.l10n"; then
    echo "⚠️ Found hardcoded string in $file"
  fi
done
```

**If found**:
```
🌍 LOCALIZATION WARNING

Found hardcoded strings in staged files.
All user-facing text should use context.l10n.*

Please update before committing.
See .claude/skills/localization-workflow.md
```

#### Check for Plain TextField with Currency

```bash
# Search for TextField being used with amount/currency
git diff --cached --name-only | grep '\.dart$' | while read file; do
  if git diff --cached "$file" | grep -i "TextField.*amount\|TextField.*currency"; then
    echo "⚠️ Found potential currency TextField in $file"
  fi
done
```

**If found**:
```
💰 CURRENCY INPUT WARNING

Found TextField with amount/currency keywords.
Should this use CurrencyTextField instead?

See .claude/skills/currency-input.md
```

#### Check for Missing Activity Logging

```bash
# Check if new cubit files added without ActivityLogRepository
git diff --cached --name-only | grep '_cubit\.dart$' | while read file; do
  if ! git diff --cached "$file" | grep -q "ActivityLogRepository"; then
    echo "⚠️ Cubit $file may be missing activity logging"
  fi
done
```

**If found**:
```
📝 ACTIVITY LOGGING WARNING

Found cubit file(s) without ActivityLogRepository injection.
State-changing operations should include activity logging.

See .claude/skills/activity-logging.md
```

#### Check for Missing SingleChildScrollView in Forms

```bash
# Check for Form without SingleChildScrollView
git diff --cached --name-only | grep '\.dart$' | while read file; do
  if git diff --cached "$file" | grep -E "Form\(" | grep -v "SingleChildScrollView"; then
    echo "⚠️ Found Form without SingleChildScrollView in $file"
  fi
done
```

**If found**:
```
📱 MOBILE-FIRST WARNING

Found Form widget(s) not wrapped in SingleChildScrollView.
This will cause keyboard hiding issues on mobile.

See TROUBLESHOOTING.md or .claude/skills/mobile-first-design.md
```

---

### Step 3: Documentation Check

Check if significant changes were documented:

```bash
# Check if CHANGELOG was updated for significant changes
if git diff --cached --stat | grep -E "lib/.*\.dart" | wc -l | grep -E "^[3-9]|[1-9][0-9]"; then
  if ! git diff --cached --name-only | grep -q "CHANGELOG\|specs/.*CHANGELOG"; then
    echo "⚠️ Significant changes detected but no CHANGELOG update"
  fi
done
```

**If not documented**:
```
📚 DOCUMENTATION REMINDER

You've modified multiple files but haven't updated documentation.
Consider using /docs.log to document these changes:

/docs.log "Brief description of what changed"

This helps maintain project history and makes reviews easier.
```

---

### Step 4: Mobile Testing Reminder

If UI files were changed:

```bash
# Check if UI files were modified
if git diff --cached --name-only | grep -E "presentation/(pages|widgets)/.*\.dart"; then
  echo "📱 UI files modified"
fi
```

**If UI modified**:
```
📱 MOBILE TESTING REMINDER

UI files were modified. Before committing, verify:
- [ ] Tested on mobile viewport (375x667px)
- [ ] Keyboard doesn't hide form fields
- [ ] No horizontal scrolling
- [ ] Touch targets minimum 44x44px

Run: flutter run -d chrome --web-browser-flag "--window-size=375,667"
```

---

### Step 5: Commit Message Quality Check

After running all checks, remind about commit message format:

```
📝 COMMIT MESSAGE REMINDER

Good commit message format:
<type>: <short summary>

<detailed description>

Examples:
feat: Add budget alerts with mobile-first UI
fix: Keyboard hiding expense form fields on mobile
refactor: Extract activity logging to service
test: Add comprehensive tests for BudgetCubit

Optional footer:
🤖 Generated with Claude Code
Co-Authored-By: Claude <noreply@anthropic.com>
```

---

## Error Severity Levels

**🔴 BLOCKING (Must Fix)**:
- Build/analysis errors
- Failing tests
- Code formatting issues

**🟡 WARNING (Should Fix)**:
- Hardcoded strings
- Missing activity logging
- Missing SingleChildScrollView in forms
- Plain TextField for currency

**🔵 INFO (Nice to Have)**:
- Documentation reminders
- Mobile testing reminders
- Commit message format

---

## Implementation Note

This hook should be **helpful but not annoying**. It catches real issues that would cause problems, while giving gentle reminders for best practices.

The goal is to ensure every commit is:
1. ✅ Builds without errors
2. ✅ Properly formatted
3. ✅ Passes existing tests
4. ✅ Follows project patterns
5. ✅ Documented appropriately

This creates a quality gate that makes Claude autonomous in maintaining code quality.
