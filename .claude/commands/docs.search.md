---
description: Search across all documentation files
tags: [project]
---

Search for specific content across all documentation files (root docs, skills, feature docs).

**Usage**: `/docs.search <search-term>`

**Example**: `/docs.search "activity logging"` or `/docs.search "CurrencyTextField"`

**Search Scope**:

1. **Root documentation**:
   - CLAUDE.md
   - PROJECT_KNOWLEDGE.md
   - MOBILE.md
   - DEVELOPMENT.md
   - TROUBLESHOOTING.md
   - GETTING_STARTED.md
   - CONTRIBUTING.md
   - README.md

2. **Skills directory**:
   - All `.md` files in `.claude/skills/`

3. **Feature documentation**:
   - All `spec.md` files in `specs/*/`
   - All `plan.md` files in `specs/*/`
   - All `CLAUDE.md` files in `specs/*/`
   - All `CHANGELOG.md` files in `specs/*/`

4. **Commands**:
   - All `.md` files in `.claude/commands/`

**Search Process**:

1. If no search term provided, ask user for search term

2. Use grep to search all markdown files:
   ```bash
   # Case-insensitive search with context
   grep -rni "search-term" *.md .claude/ specs/ --include="*.md" -C 2
   ```

3. Organize results by document type:
   - Root Documentation
   - Skills
   - Feature Documentation
   - Commands

4. For each match, show:
   - File path (as clickable link)
   - Line number
   - Surrounding context (2 lines before/after)
   - Match count per file

**Output Format**:

```
Documentation Search Results for: "activity logging"
Found 12 matches across 5 files

ROOT DOCUMENTATION (3 matches)
===============================
[CLAUDE.md](CLAUDE.md#L252)
252: ## 📝 Activity Tracking System
253:
254: **Every state-changing operation MUST include activity logging.**

[DEVELOPMENT.md](DEVELOPMENT.md#L145)
145: ### Activity Tracking System
146:
147: All state-changing operations must log activity for audit trail.

SKILLS (2 matches)
==================
[.claude/skills/activity-logging.md](.claude/skills/activity-logging.md#L1)
1: # Activity Logging Workflow
2:
3: This skill guides you through adding activity logging to features.

FEATURE DOCUMENTATION (7 matches)
==================================
[specs/003-activity-log/spec.md](specs/003-activity-log/spec.md#L10)
10: Activity logging system for tracking all user actions within trips.

[specs/005-export-reports/CLAUDE.md](specs/005-export-reports/CLAUDE.md#L89)
89: - Activity log integration for audit trail in reports
```

**Search Tips**:

- Use quotes for exact phrases: `"activity logging"`
- Use regex for pattern matching: `"Currency.*Field"`
- Search for code patterns: `"context.l10n"`
- Search for TODOs: `"TODO"`
- Search for specific sections: `"## Testing"`

**Advanced Usage**:

- **Search in specific doc type**: Filter results mentally or ask for specific subset
- **Search for missing documentation**: Look for placeholder text like "[TODO]" or "[Add here]"
- **Find related features**: Search for technology names to find all related features

**Next Steps**:

After finding results:
1. Review the matches in context
2. Navigate to relevant files using clickable links
3. Update documentation if needed
4. Use `/docs.log` to record documentation changes
