---
description: Mark feature as complete and update CHANGELOG.md
tags: [project]
---

Mark the current feature as complete in documentation and update the changelog.

**Steps**:

1. Identify the current feature branch (from git or SPECIFY_FEATURE env var)
2. Verify that the feature is ready to be marked complete:
   - All tasks in `specs/<feature-id>/tasks.md` are checked off
   - Tests are passing
   - Feature has been reviewed
3. Run the completion script:
   ```bash
   .specify/scripts/bash/update-feature-docs.sh complete <feature-id>
   ```
4. Verify changes:
   - Check that `specs/<feature-id>/CLAUDE.md` status is now "Completed"
   - Check that `CHANGELOG.md` has a new entry for this feature
5. Review the changelog entry and enhance it if needed with:
   - Specific features added
   - Breaking changes (if any)
   - Migration notes (if any)

**Output**: Updated feature documentation and changelog entry.
