---
description: Analyze current work and suggest relevant Claude skills with workflow recommendations
tags: [productivity, skills, guidance]
---

Analyze the current work context and recommend relevant Claude skills.

## Instructions

### Step 1: Gather Context

**Check active todos** (if TodoWrite has been used):
- Look for task descriptions
- Identify types of work (UI, testing, bug fixes, new features)
- Note file types mentioned (.dart, *_cubit.dart, *_test.dart, etc.)

**Analyze recent conversation** (last 5-10 messages):
- What is the user trying to accomplish?
- What keywords appear? (UI, form, test, localization, currency, activity, etc.)
- What files or components are being discussed?
- What problems are being solved?

### Step 2: Match Keywords to Skills

Use this keyword → skill mapping:

**mobile-first-design.md**:
- Keywords: UI, form, layout, page, widget, responsive, mobile, keyboard, scroll, bottom sheet
- File patterns: *_page.dart, *_form*.dart, widgets/
- Tasks: "Create UI", "build form", "fix layout", "design screen"

**cubit-testing.md**:
- Keywords: test, cubit, bloc, mock, state, testing, coverage
- File patterns: *_cubit_test.dart, test/
- Tasks: "Write tests", "test cubit", "add coverage", "fix failing test"

**activity-logging.md**:
- Keywords: activity, logging, audit, state change, create, update, delete, repository
- File patterns: *_cubit.dart with create/update/delete methods
- Tasks: "Add logging", "track changes", "audit trail"

**localization-workflow.md**:
- Keywords: string, text, label, message, localization, l10n, translation, hardcoded
- File patterns: *.arb, strings in UI
- Tasks: "Add strings", "localize text", "fix hardcoded strings"

**currency-input.md**:
- Keywords: currency, amount, money, price, payment, expense amount, input
- File patterns: expense forms, amount fields
- Tasks: "Add amount field", "currency input", "expense form"

**read-with-context.md**:
- Keywords: understand, how does, investigate, explore, trace, bug, issue, unclear
- Tasks: "Understand X", "how does Y work", "investigate bug", "trace data flow"

**git-worktrees.md**:
- Keywords: feature, branch, isolation, workspace, new feature, parallel work
- Tasks: "Start new feature", "work on separate branch", "isolate work"

**test-driven-development.md**:
- Keywords: new feature, bug fix, TDD, red-green-refactor, test first, implement
- Tasks: "Implement X", "fix bug", "add feature", "refactor"

**finishing-development-branch.md**:
- Keywords: complete, done, merge, PR, pull request, finish, ready to merge
- Tasks: "Complete feature", "create PR", "merge branch", "ready to deploy"

### Step 3: Rank Skills by Relevance

Calculate relevance score (0-4 stars):

- **4 stars**: Multiple strong keyword matches + task directly relates to skill
- **3 stars**: Strong keyword match OR task clearly relates
- **2 stars**: Weak keyword match OR might be helpful
- **1 star**: Tangentially related
- **0 stars**: Not relevant

**Only show skills with 2+ stars**

### Step 4: Suggest Workflow Order

Based on typical development workflow:

**Investigation phase** (if understanding needed):
1. read-with-context

**Setup phase** (if starting new feature):
2. git-worktrees (for isolation)

**Development phase**:
3. test-driven-development (always recommended for new code)
4. mobile-first-design (if UI work)
5. currency-input (if monetary fields)
6. localization-workflow (if adding text)
7. activity-logging (if state changes)
8. cubit-testing (if testing cubits)

**Completion phase**:
9. finishing-development-branch (when done)

**Reorder based on what's detected** - put most relevant first.

### Step 5: Output Format

```
📋 Skill Recommendations for Current Work

[If todos exist, show brief summary of what you're working on]
[If no todos, show summary from conversation context]

## Highly Relevant (⭐⭐⭐⭐ or ⭐⭐⭐)

⭐⭐⭐⭐ **[Skill Name]** (`.claude/skills/[filename].md`)
→ [Why it's relevant - 1 line based on context]
→ [What it helps with - 1 line]

⭐⭐⭐ **[Skill Name]** (`.claude/skills/[filename].md`)
→ [Why it's relevant]
→ [What it helps with]

## Potentially Useful (⭐⭐)

⭐⭐ **[Skill Name]** (`.claude/skills/[filename].md`)
→ [Why it might help]

## Suggested Workflow Order

1. **[Skill]** - [Brief reason why first]
2. **[Skill]** - [Brief reason why second]
3. **[Skill]** - [Brief reason why third]
[etc.]

---
💡 **Tip**: Reference skills by saying "I'm using the [skill-name] skill" or "Let's follow the [skill-name] workflow"
```

### Step 6: Handle Edge Cases

**If no clear context** (no todos, unclear conversation):
```
📋 Skill Recommendations

I don't have enough context to suggest specific skills. Here's what I can recommend:

**Tell me what you're working on**, and I'll suggest relevant skills. For example:
- "I'm building a new expense form" → Mobile-First Design, Currency Input, Localization
- "I'm fixing a bug in settlements" → Read With Context, TDD, Cubit Testing
- "I'm starting a new feature" → Git Worktrees, TDD

**Or browse all available skills**:
- activity-logging.md - Add activity logging to operations
- cubit-testing.md - Write BLoC/Cubit tests
- currency-input.md - Implement currency input fields
- finishing-development-branch.md - Complete and merge work
- git-worktrees.md - Set up isolated workspaces
- localization-workflow.md - Add localized strings
- mobile-first-design.md - Mobile-first UI implementation
- read-with-context.md - Understand code in context
- test-driven-development.md - TDD workflow
```

**If only 1-2 skills relevant**:
- Still show the full format
- Be specific about why those skills apply
- Suggest checking others if task changes

## Examples

### Example 1: Building Expense Form

**Context**: Todos include "Create expense form UI", "Add amount validation"

**Output**:
```
📋 Skill Recommendations for Current Work

Working on: Creating expense form UI with amount validation

## Highly Relevant

⭐⭐⭐⭐ **Mobile-First Design** (`.claude/skills/mobile-first-design.md`)
→ You're creating a form UI - needs mobile-first approach
→ Ensures keyboard doesn't hide fields, proper scrolling, responsive layout

⭐⭐⭐⭐ **Currency Input** (`.claude/skills/currency-input.md`)
→ Expense forms require currency/amount inputs
→ Provides CurrencyTextField with auto-formatting and validation

⭐⭐⭐ **Localization Workflow** (`.claude/skills/localization-workflow.md`)
→ Forms need labels, validation messages, user-facing text
→ Use context.l10n instead of hardcoded strings

⭐⭐⭐ **Test-Driven Development** (`.claude/skills/test-driven-development.md`)
→ New UI component - write tests first
→ Ensures validation logic works correctly

## Potentially Useful

⭐⭐ **Activity Logging** (`.claude/skills/activity-logging.md`)
→ If expense creation needs audit trail

## Suggested Workflow Order

1. **Mobile-First Design** - Design the form layout properly first
2. **Currency Input** - Set up amount field with proper formatting
3. **Localization Workflow** - Add all labels and messages
4. **Test-Driven Development** - Write tests for form validation
5. **Activity Logging** - Add logging after form saves expenses
```

### Example 2: Debugging Issue

**Context**: Conversation mentions "settlement calculation is wrong"

**Output**:
```
📋 Skill Recommendations for Current Work

Working on: Debugging settlement calculation issue

## Highly Relevant

⭐⭐⭐⭐ **Read With Context** (`.claude/skills/read-with-context.md`)
→ Need to understand how settlement calculations work
→ Trace data flow from expenses → splits → settlements

⭐⭐⭐⭐ **Test-Driven Development** (`.claude/skills/test-driven-development.md`)
→ Bug fixes start with failing test reproducing the issue
→ Ensures fix works and prevents regression

⭐⭐⭐ **Cubit Testing** (`.claude/skills/cubit-testing.md`)
→ Settlement logic likely in a cubit
→ Write tests for settlement calculation edge cases

## Suggested Workflow Order

1. **Read With Context** - Understand existing settlement calculation code
2. **Test-Driven Development** - Write failing test reproducing the bug
3. **Cubit Testing** - Add comprehensive tests for edge cases
```

### Example 3: Starting New Feature

**Context**: Todo "Implement photo upload for receipts"

**Output**:
```
📋 Skill Recommendations for Current Work

Working on: Implementing photo upload for receipts feature

## Highly Relevant

⭐⭐⭐⭐ **Git Worktrees** (`.claude/skills/git-worktrees.md`)
→ New feature - work in isolated workspace
→ Keeps main branch clean while developing

⭐⭐⭐⭐ **Test-Driven Development** (`.claude/skills/test-driven-development.md`)
→ New feature - write tests before implementation
→ Ensures upload, storage, and retrieval work correctly

⭐⭐⭐ **Mobile-First Design** (`.claude/skills/mobile-first-design.md`)
→ Photo upload UI needs mobile camera access
→ Design for mobile capture first, desktop upload second

## Potentially Useful

⭐⭐ **Activity Logging** (`.claude/skills/activity-logging.md`)
→ Log when users attach/remove photos for audit trail

⭐⭐ **Finishing Development Branch** (`.claude/skills/finishing-development-branch.md`)
→ When feature complete - merge or create PR

## Suggested Workflow Order

1. **Git Worktrees** - Set up isolated workspace for this feature
2. **Test-Driven Development** - Write tests for upload/storage/retrieval
3. **Mobile-First Design** - Design photo capture UI for mobile
4. **Activity Logging** - Add logging after photo operations work
5. **Finishing Development Branch** - When ready, merge or create PR
```

## Best Practices

**✅ DO:**
- Be specific about why each skill is relevant to the current context
- Only suggest skills with clear applicability (2+ stars)
- Provide actionable workflow order
- Reference actual todo items or conversation context
- Keep descriptions concise (1-2 lines per skill)

**❌ DON'T:**
- Suggest all skills regardless of context
- Be vague ("this might help")
- Overwhelm with too many recommendations
- Ignore the actual work being done
- Suggest skills just to have more results
