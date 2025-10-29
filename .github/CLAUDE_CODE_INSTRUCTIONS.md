# Instructions for Claude Code AI

## 🚨 MANDATORY WORKFLOW - READ FIRST

When working on this codebase, you (Claude Code) MUST follow these documentation practices:

### After Each Significant Change

**IMMEDIATELY after completing a todo or making a significant change:**

```bash
/docs.log "brief description of what changed"
```

### After Architectural Changes

**IMMEDIATELY after making architectural changes:**

```bash
/docs.update
```

**Architectural changes include:**
- Adding new models, repositories, cubits, or routes
- Modifying core data structures (adding/removing fields)
- Adding dependencies to pubspec.yaml
- Implementing new design patterns
- Creating major new components

### Examples of When to Log

- ✅ Just completed a TodoWrite item → `/docs.log`
- ✅ Created a new file → `/docs.log "added [filename]"`
- ✅ Fixed a bug → `/docs.log "fixed [issue]"`
- ✅ Modified core functionality → `/docs.log "updated [feature]"`
- ✅ About to mark a todo as complete → `/docs.log` first
- ✅ Added a domain model → `/docs.update` (then `/docs.log`)
- ✅ Created a new cubit → `/docs.update` (then `/docs.log`)
- ✅ Modified data structures → `/docs.update` (then `/docs.log`)

### DO NOT

- ❌ Wait for the user to remind you
- ❌ Batch all documentation at the end
- ❌ Skip documentation because you "forgot"
- ❌ Assume the user will handle it

### This is YOUR Responsibility

Documentation is part of the development workflow, not an afterthought. The user relies on you to maintain accurate, up-to-date changelogs.

## Workflow Checklist Location

Full checklist: `.claude-workflow-checklist.md`

## Why This Matters

- Keeps feature changelogs accurate
- Makes it easy to track what changed
- Helps with release notes
- Documents decision-making process
- **The user shouldn't have to ask!**
