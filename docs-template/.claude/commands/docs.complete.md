---
description: Mark feature as complete and roll up to root CHANGELOG.md
tags: [project]
---

Mark the current feature as complete in documentation and roll up the feature changelog to the root CHANGELOG.md.

**Steps**:

1. Identify the current feature branch (from git or SPECIFY_FEATURE env var)
2. Verify that the feature is ready to be marked complete:
   - All tasks in `specs/<feature-id>/tasks.md` are checked off
   - Tests are passing
   - Feature has been reviewed
   - Feature CLAUDE.md is up to date
   - Feature CHANGELOG.md has all development changes logged
3. Run the completion script:
   ```bash
   .specify/scripts/bash/update-feature-docs.sh complete <feature-id>
   ```
4. This will:
   - Mark `specs/<feature-id>/CLAUDE.md` status as "Completed"
   - Extract feature summary from CLAUDE.md
   - Create entry in root `CHANGELOG.md` with link to feature docs
   - Preserve detailed `specs/<feature-id>/CHANGELOG.md` for historical reference
   - Remove feature from "Unreleased" section in root CHANGELOG.md
5. Review the changelog entry and enhance it if needed with:
   - Specific features added
   - Breaking changes (if any)
   - Migration notes (if any)

**What happens to changelogs**:
- **Feature CHANGELOG.md**: Preserved as-is in `specs/<feature-id>/CHANGELOG.md` for detailed development history
- **Root CHANGELOG.md**: Gets a new entry with feature summary and links to feature docs

**Output**:
- Updated feature documentation (status changed to "Completed")
- New entry in root CHANGELOG.md
- Feature changelog preserved for reference
