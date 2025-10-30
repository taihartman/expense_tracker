# Claude Code Hooks

This directory contains hooks that make Claude autonomous by automatically enforcing best practices and project patterns.

## 📋 Available Hooks

### 1. `user-prompt-submit.md`
**Triggers**: BEFORE Claude processes user's request

**Purpose**: Analyzes user intent and auto-injects relevant skill reminders

**What it does**:
- Detects keywords (UI, cubit, text, currency, test, bug)
- Injects relevant skill reminders automatically
- Reminds Claude of project principles
- Suggests documentation workflow

**Result**: Claude automatically remembers to use skills without manual reminders

---

### 2. `stop-event.md`
**Triggers**: AFTER Claude finishes responding

**Purpose**: Checks for errors and pattern compliance

**What it does**:
- Runs `flutter analyze` to catch errors
- Verifies mobile-first patterns in UI files
- Checks activity logging in cubits
- Verifies localization in text
- Checks CurrencyTextField usage
- Reminds about testing
- Reminds about documentation
- Checks code formatting

**Result**: Claude self-checks and catches mistakes before they become bugs

---

### 3. `pre-commit.md`
**Triggers**: BEFORE creating git commits

**Purpose**: Ensures code quality and pattern compliance

**What it does**:
- Runs `flutter analyze`, `flutter format`, `flutter test`
- Scans for hardcoded strings (should use l10n)
- Checks for plain TextField with currency (should use CurrencyTextField)
- Verifies activity logging in cubits
- Checks forms have SingleChildScrollView
- Reminds about documentation
- Reminds about mobile testing
- Suggests commit message format

**Result**: Every commit meets quality standards automatically

---

## 🚀 How It Works

### Automatic Triggering

Claude Code automatically runs these hooks at the appropriate times:

1. **User types a message** → `user-prompt-submit.md` runs → Claude sees injected reminders
2. **Claude finishes response** → `stop-event.md` runs → Self-check reminders appear
3. **Before committing code** → `pre-commit.md` runs → Quality gates enforced

### Non-Blocking Design

All hooks are designed to be **helpful, not annoying**:

- ✅ Auto-inject context (don't require manual skill references)
- ✅ Gentle reminders (not blocking errors)
- ✅ Self-checks (Claude reviews its own work)
- ✅ Quality gates (prevent bad commits)

### Severity Levels

**🔴 BLOCKING**: Must fix before proceeding
- Build errors
- Test failures
- Formatting issues

**🟡 WARNING**: Should fix (best practices)
- Hardcoded strings
- Missing activity logging
- Missing mobile patterns

**🔵 INFO**: Nice to have
- Documentation reminders
- Testing reminders

---

## 💡 Benefits

### Before Hooks
❌ Had to manually remind Claude to use skills
❌ Patterns sometimes forgotten
❌ Errors discovered later
❌ Inconsistent code quality
❌ Documentation often skipped

### After Hooks
✅ Claude automatically follows patterns
✅ Skills used consistently
✅ Errors caught immediately
✅ Quality gates enforced
✅ Documentation prompted

---

## 🎯 Hook Philosophy (from Reddit Post)

These hooks implement the **"automation over reminders"** principle from the Reddit post:

> "The hook system is honestly what ties everything together. Without hooks, skills sit unused, errors slip through, code is inconsistently formatted, and there's no automatic quality checks."

**Key Benefits**:
1. **Consistency**: Patterns followed every time
2. **Quality**: Errors caught automatically
3. **Efficiency**: No manual reminders needed
4. **Documentation**: Prompted at right times
5. **Confidence**: Quality gates prevent bad code

---

## 🔧 Customization

You can customize these hooks by editing the markdown files:

### To Add New Pattern Checks:

Edit `stop-event.md` or `pre-commit.md` and add your check in the appropriate section.

Example - checking for TODO comments:
```markdown
#### Check for TODO Comments

```bash
# Search for TODO comments in staged files
git diff --cached | grep -i "TODO"
```

**If found**:
```
⚠️ TODO COMMENTS FOUND

Found TODO comments in staged code.
Please resolve or create GitHub issues for them.
```

### To Add New Skill Triggers:

Edit `user-prompt-submit.md` and add keyword detection + skill injection.

Example - for navigation/routing:
```markdown
**Navigation/Routing Keywords**: "route", "navigation", "navigate", "screen transition"
→ **Action**: Inject routing patterns reminder
```

---

## 📊 Expected Impact

Based on Reddit post recommendations, hooks should:

- **Reduce errors by 80%+**: Caught automatically before they cause issues
- **Improve pattern consistency**: 95%+ adherence to project patterns
- **Faster development**: No context switching to check patterns
- **Better documentation**: Prompted at right times
- **Higher confidence**: Quality gates prevent regressions

---

## 🧪 Testing Hooks

To test if hooks are working:

### Test 1: User Prompt Submit Hook
1. Say: "Create a new expense form page"
2. Claude should automatically mention mobile-first patterns
3. Claude should reference mobile-first-design.md skill

### Test 2: Stop Event Hook
1. Have Claude edit a cubit file
2. After response, Claude should self-check for activity logging
3. Claude should remind about /docs.log

### Test 3: Pre-Commit Hook
1. Make changes and try to commit
2. Claude should run flutter analyze
3. Claude should check for pattern compliance
4. Claude should remind about documentation

---

## 📚 Related Documentation

- [CLAUDE.md](../../CLAUDE.md) - Quick reference hub
- [.claude/skills/](../skills/) - Reusable workflow skills
- [TROUBLESHOOTING.md](../../TROUBLESHOOTING.md) - Common issues
- Reddit post: "6 months of Claude Code - Tips & Tricks"

---

## 🤝 Contributing

When adding new patterns to the project:

1. Add pattern documentation to skills
2. Add hook checks to verify the pattern
3. Add troubleshooting entry if commonly misused
4. Update this README

**Goal**: Make Claude autonomous in following ALL project patterns.

---

**Created**: 2025-01-30
**Based on**: Reddit post recommendations for autonomous Claude Code workflow
