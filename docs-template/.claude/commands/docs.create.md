---
description: Create feature documentation (CLAUDE.md and CHANGELOG.md) for the current feature
tags: [project]
---

Create feature-specific CLAUDE.md and CHANGELOG.md files for the current feature branch.

**Steps**:

1. Identify the current feature branch (from git or SPECIFY_FEATURE env var)
2. Run the update-feature-docs script:
   ```bash
   .specify/scripts/bash/update-feature-docs.sh create <feature-id>
   ```
3. This creates TWO files:
   - `specs/<feature-id>/CLAUDE.md` - Feature documentation
   - `specs/<feature-id>/CHANGELOG.md` - Development changelog
4. Read the generated `specs/<feature-id>/CLAUDE.md` file
5. Fill in the template sections based on:
   - The feature spec (`specs/<feature-id>/spec.md`)
   - The implementation plan (`specs/<feature-id>/plan.md` if exists)
   - Files that have been created or modified
   - Dependencies added to `pubspec.yaml`
6. Update the following sections with actual content:
   - Important Files Modified/Created
   - Data Models (from plan.md entities)
   - State Management approach
   - UI Components created
   - Dependencies Added
   - Testing Strategy
   - Architecture Decisions

**Output**:
- A complete feature CLAUDE.md that future Claude instances can use to understand this feature's implementation
- An initialized feature CHANGELOG.md ready for logging development changes with `/docs.log`
