# Hooks Usage Guide

This guide explains how the Claude Code hooks system works in this project and how to verify it's functioning correctly.

## How Hooks Work

Hooks are **Markdown-based declarative instructions** that Claude Code automatically reads and injects into Claude's context at specific lifecycle events. Claude then follows these instructions autonomously.

**Key Points**:
- Hooks are **NOT executable code** - they're Markdown guidelines
- Hooks are **automatically triggered** by filename (no configuration needed)
- Claude reads and **follows the instructions** in the hooks
- Hooks work through **context injection** at lifecycle events

## Available Hooks

### 1. `user-prompt-submit.md`
**Triggers**: BEFORE Claude processes user's message
**Purpose**: Auto-inject skill reminders based on user intent

**Example Behavior**:
```
User types: "Add a new expense form page"

Hook detects keywords: "Add", "form", "page"
↓
Injects reminder: "📱 MOBILE-FIRST REMINDER: Use SingleChildScrollView, MediaQuery, etc."
↓
Claude receives both user message AND mobile-first skill reminder
↓
Claude follows mobile-first patterns automatically
```

**Verification**:
- Watch for Claude mentioning skills at the start of responses
- Check if Claude follows patterns without being reminded
- Review responses for mobile-first patterns when creating UI

### 2. `stop-event.md`
**Triggers**: AFTER Claude finishes responding
**Purpose**: Self-check for errors and pattern compliance

**Example Behavior**:
```
Claude finishes editing expense_form_page.dart
↓
stop-event hook triggers
↓
Claude runs: flutter analyze
Claude checks: Did I use SingleChildScrollView?
Claude checks: Did I use MediaQuery for spacing?
↓
Claude reports results or self-corrects
```

**Verification**:
- Watch for Claude running `flutter analyze` after code changes
- Check if Claude mentions self-checks in responses
- Notice if Claude catches and fixes its own mistakes

### 3. `pre-commit.md`
**Triggers**: BEFORE creating git commits
**Purpose**: Quality gates to ensure nothing is committed with errors

**Example Behavior**:
```
User asks: "Commit these changes"
↓
pre-commit hook triggers
↓
Claude runs:
  1. flutter analyze (check for errors)
  2. flutter format --set-exit-if-changed . (check formatting)
  3. flutter test (run tests)
  4. Pattern scan (check for anti-patterns)
↓
If any fail: Claude reports and fixes before committing
If all pass: Claude proceeds with commit
```

**Verification**:
- Request commits and watch for quality checks
- Intentionally introduce an error and request commit - Claude should catch it
- Check commit messages for quality gate confirmations

## Testing the Hooks System

### Test 1: Skill Auto-Injection (user-prompt-submit)

**Try this**:
```
User: "Create a new trip settings page with a form"
```

**Expected Claude Behavior**:
- Mentions mobile-first design in initial response
- Uses `SingleChildScrollView` automatically
- Uses `MediaQuery` for responsive spacing
- Uses `context.l10n.*` for strings
- Follows all mobile-first patterns WITHOUT being reminded

**If Claude doesn't do this**:
- Hook might not be triggering
- Check that file exists: `.claude/hooks/user-prompt-submit.md`
- Check filename spelling (must be exact)

### Test 2: Self-Check After Edits (stop-event)

**Try this**:
```
User: "Add a new text field to the expense form"
```

**Expected Claude Behavior**:
After editing the file, Claude should:
- Run `flutter analyze` to check for errors
- Mention self-checking for patterns
- Report any issues found
- Offer to fix issues immediately

**If Claude doesn't do this**:
- Hook might not be triggering
- Check that file exists: `.claude/hooks/stop-event.md`

### Test 3: Pre-Commit Quality Gates (pre-commit)

**Try this**:
```
User: "Commit these changes"
```

**Expected Claude Behavior**:
Before committing, Claude should:
- Run `flutter analyze`
- Run `flutter format --set-exit-if-changed .`
- Run `flutter test`
- Scan for anti-patterns (hardcoded strings, non-responsive UI)
- Report results
- Only proceed if all checks pass

**If Claude doesn't do this**:
- Hook might not be triggering
- Check that file exists: `.claude/hooks/pre-commit.md`

## Verifying Hook Activation

### Quick Check
Ask Claude directly:
```
User: "Are the hooks in .claude/hooks/ active?"
```

Claude should be able to:
- List the hooks
- Explain when they trigger
- Confirm they're being read by Claude Code

### Detailed Verification

1. **Check Hook Files Exist**:
```bash
ls -la .claude/hooks/
# Should show:
# user-prompt-submit.md
# stop-event.md
# pre-commit.md
# README.md
# USAGE_GUIDE.md
```

2. **Request Feature with Known Patterns**:
```
User: "Add a currency input field to the expense form"
```

Expected: Claude uses `CurrencyTextField` automatically (from currency-input skill)

3. **Request Commit with Error**:
```bash
# Introduce syntax error
echo "invalid dart code" >> lib/main.dart

# Then ask:
User: "Commit these changes"
```

Expected: Claude catches error during pre-commit check

## Hook Behavior Examples

### Example 1: Autonomous Mobile-First

**User Request**: "Create a new participant list page"

**Without Hooks**:
```dart
// Claude might create:
TextField(...)  // Plain TextField
Padding(padding: EdgeInsets.all(16))  // Hardcoded padding
Text('Participants')  // Hardcoded string
```

**With Hooks Active**:
```dart
// Claude creates:
SingleChildScrollView(
  child: Padding(
    padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),  // Responsive
    child: Column(
      children: [
        Text(
          context.l10n.participantListTitle,  // Localized
          style: TextStyle(fontSize: isMobile ? 18 : 20),  // Responsive
        ),
        // ... mobile-first implementation
      ],
    ),
  ),
)
```

### Example 2: Self-Correction

**Scenario**: Claude forgets to use localization

**Without Hooks**:
```dart
Text('Save')  // Hardcoded string - no correction
```

**With stop-event Hook**:
```
1. Claude edits file with: Text('Save')
2. stop-event hook triggers
3. Claude checks: "Did I use context.l10n for strings?"
4. Claude detects issue
5. Claude responds: "I noticed I hardcoded a string. Let me fix that."
6. Claude corrects to: Text(context.l10n.commonSave)
```

### Example 3: Pre-Commit Safety

**Scenario**: User requests commit after breaking change

**Without Hooks**:
```
User: "Commit these changes"
Claude: *creates commit immediately*
Result: Broken code committed
```

**With pre-commit Hook**:
```
User: "Commit these changes"
Claude: "Running pre-commit checks..."
Claude: *runs flutter analyze*
Claude: "Found 3 errors. Cannot commit until fixed."
Claude: "Here are the errors: ..."
Claude: "Would you like me to fix these first?"
Result: Errors caught before commit
```

## Customizing Hooks

### Adding New Patterns to user-prompt-submit

Edit `.claude/hooks/user-prompt-submit.md`:

```markdown
### Step 1: Analyze User Intent

**Your New Pattern Keywords**: "keyword1", "keyword2"
→ **Action**: Inject your skill reminder

Example:
"Testing Keywords": "test", "spec", "unit test"
→ **Action**: Remind Claude to check `.claude/skills/cubit-testing.md`
```

### Adding New Checks to stop-event

Edit `.claude/hooks/stop-event.md`:

```markdown
### Step 3: Your Custom Check

#### If Your Condition (*.dart files with pattern X)
YOUR CHECK TITLE
Did you:
- [ ] Check item 1?
- [ ] Check item 2?

If not → Fix immediately
```

### Adding New Quality Gates to pre-commit

Edit `.claude/hooks/pre-commit.md`:

```markdown
### Step 4: Your Quality Gate

```bash
your-custom-check.sh
```

**If FAIL**: Don't commit, report issue
```

## Troubleshooting

### "Hooks don't seem to be working"

**Check 1**: Verify files exist
```bash
ls .claude/hooks/*.md
```

**Check 2**: Verify correct filenames (must be exact)
- `user-prompt-submit.md` (NOT `user-prompt-submit-hook.md`)
- `stop-event.md` (NOT `stop-event-hook.md`)
- `pre-commit.md` (NOT `pre-commit-hook.md`)

**Check 3**: Verify file permissions
```bash
chmod 644 .claude/hooks/*.md
```

**Check 4**: Ask Claude directly
```
User: "Read .claude/hooks/user-prompt-submit.md and tell me what it says"
```

If Claude can read it, the hook is accessible.

### "Skills aren't being injected"

**Possible causes**:
1. Keywords in `user-prompt-submit.md` don't match user's language
2. User request is too vague (add more keyword variations)
3. Hook file has syntax errors (validate Markdown)

**Fix**: Review and update keyword patterns in `user-prompt-submit.md`

### "Pre-commit checks not running"

**Possible causes**:
1. User didn't explicitly request commit
2. Hook filename is incorrect
3. Commands in hook are invalid

**Fix**:
- Use exact commit request: "Commit these changes"
- Verify filename is exactly `pre-commit.md`
- Test commands in hook manually

## Best Practices

### For Users

1. **Trust the Hooks**: Let Claude run checks - don't interrupt
2. **Be Explicit**: When requesting commits, say "commit these changes"
3. **Review Hook Output**: Check what Claude finds during self-checks
4. **Update Hooks**: As project evolves, update hook patterns

### For Claude (Future Sessions)

1. **Always Check Hooks**: Read hook files at session start
2. **Follow Hook Instructions**: They exist to ensure quality
3. **Report Hook Results**: Tell user what hooks detected
4. **Self-Correct**: Use hooks to catch mistakes early

## Summary

The hooks system makes Claude autonomous by:
- **user-prompt-submit**: Auto-injecting skill reminders → No manual reminders needed
- **stop-event**: Self-checking after responses → Catches mistakes immediately
- **pre-commit**: Quality gates before commits → No broken commits

**Result**: Claude follows best practices automatically, catches errors early, and maintains code quality without constant user supervision.

**Next Steps**:
1. Test the hooks with the examples above
2. Customize hook patterns for your workflow
3. Monitor Claude's autonomous behavior
4. Refine hooks based on what works

---

**Questions?** Ask Claude to demonstrate hook behavior or explain specific hook triggers.
