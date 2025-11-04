---
description: Archive completed or stale documentation
tags: [project]
---

Move completed features or stale documentation to the `docs/archive/` directory to keep the active documentation clean and focused.

**When to use**:
- After a feature is fully complete and stable (no active development)
- When documentation becomes obsolete or superseded
- To clean up historical migration/refactoring documentation
- To preserve old documentation without cluttering active docs

**Usage**: `/docs.archive <file-or-feature>`

**Examples**:
- `/docs.archive REFACTORING_COMPLETE.md` - Archive a single file
- `/docs.archive 003-activity-log` - Archive an entire feature directory
- `/docs.archive migration` - Archive all files matching "migration"

**Archive Process**:

1. **Identify items to archive**:
   - Ask user what to archive (file name, feature ID, or pattern)
   - Confirm the files/directories to be archived

2. **Create archive structure**:
   ```bash
   mkdir -p docs/archive/features
   mkdir -p docs/archive/historical
   ```

3. **Determine archive location**:
   - **Feature documentation** → `docs/archive/features/{feature-id}/`
   - **Historical docs** (refactoring, migrations) → `docs/archive/historical/`
   - **Stale root docs** → `docs/archive/historical/`

4. **Move files**:
   ```bash
   # For single file
   git mv FILE.md docs/archive/historical/

   # For feature directory
   git mv specs/{feature-id} docs/archive/features/
   ```

5. **Create archive index** (if it doesn't exist):
   - Create `docs/archive/INDEX.md` listing all archived items
   - Include: Name, Date archived, Reason, Original location

6. **Update references**:
   - Search for links to archived files in active docs
   - Update or remove broken links
   - Add note that content was archived (if referenced)

**Archive Index Format**:

```markdown
# Documentation Archive Index

## Archived Features

### 003-activity-log (Archived: 2025-11-04)
**Reason**: Feature complete and stable, no active development
**Original Location**: `specs/003-activity-log/`
**Files**: spec.md, plan.md, tasks.md, CLAUDE.md, CHANGELOG.md

### 007-legacy-export (Archived: 2025-10-15)
**Reason**: Feature deprecated and removed from codebase
**Original Location**: `specs/007-legacy-export/`

## Historical Documentation

### REFACTORING_COMPLETE.md (Archived: 2025-11-04)
**Reason**: Refactoring completed, kept for historical reference
**Original Location**: Root directory

### LOCALIZATION_MIGRATION_STATUS.md (Archived: 2025-11-04)
**Reason**: Migration completed, no longer relevant
**Original Location**: Root directory
```

**Safety Checks**:

Before archiving:
1. ✅ Confirm files are not actively referenced in code or docs
2. ✅ Verify feature is truly complete (if archiving feature)
3. ✅ Check git history to ensure not recently modified
4. ✅ Ask user for confirmation before moving files

**Do NOT archive**:
- ❌ Active feature documentation
- ❌ Core documentation (CLAUDE.md, PROJECT_KNOWLEDGE.md, etc.)
- ❌ Skills that are still useful
- ❌ Recently modified files (< 30 days old)

**Output**:

```
Archiving Documentation
=======================

Files to archive:
  - REFACTORING_COMPLETE.md (170 lines)
  - LOCALIZATION_MIGRATION_STATUS.md (423 lines)
  - ARCHITECTURE_SIMPLIFICATION.md (259 lines)

Destination: docs/archive/historical/

✅ Moved 3 files to archive
✅ Updated docs/archive/INDEX.md
✅ Checked for broken links (none found)

Next steps:
- Run /docs.validate to confirm no broken links
- Commit changes with: git commit -m "docs: archive historical documentation"
```

**Next Steps**:

After archiving:
1. Run `/docs.validate` to check for broken links
2. Update any docs that referenced archived content
3. Commit the changes
4. Consider updating root CHANGELOG.md if significant cleanup
