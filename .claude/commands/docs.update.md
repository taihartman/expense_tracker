---
description: Update feature CLAUDE.md with recent changes
tags: [project]
---

Update the feature-specific CLAUDE.md file with recent implementation changes.

**Steps**:

1. Identify the current feature branch (from git or SPECIFY_FEATURE env var)
2. Read the current `specs/<feature-id>/CLAUDE.md`
3. Check for recent changes:
   - New files created (use `git status` or `git diff`)
   - Modified files
   - New dependencies in `pubspec.yaml`
   - New tests added
4. Update the following sections in CLAUDE.md:
   - **Important Files Modified/Created**: Add new files
   - **Dependencies Added**: Add new packages
   - **Implementation Notes**: Document any important decisions
   - **Testing Strategy**: Update test coverage info
   - **Known Limitations**: Add any discovered limitations
5. Commit the updated CLAUDE.md

**Note**: This is a manual process - edit `specs/<feature-id>/CLAUDE.md` directly.
