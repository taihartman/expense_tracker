---
description: Create feature documentation (CLAUDE.md) for the current feature
tags: [project]
---

Create a feature-specific CLAUDE.md file for the current feature branch.

**Steps**:

1. Identify the current feature branch (from git or SPECIFY_FEATURE env var)
2. Run the update-feature-docs script:
   ```bash
   .specify/scripts/bash/update-feature-docs.sh create <feature-id>
   ```
3. Read the generated `specs/<feature-id>/CLAUDE.md` file
4. Fill in the template sections based on:
   - The feature spec (`specs/<feature-id>/spec.md`)
   - The implementation plan (`specs/<feature-id>/plan.md` if exists)
   - Files that have been created or modified
   - Dependencies added to `pubspec.yaml`
5. Update the following sections with actual content:
   - Important Files Modified/Created
   - Data Models (from plan.md entities)
   - State Management approach
   - UI Components created
   - Dependencies Added
   - Testing Strategy
   - Architecture Decisions

**Output**: A complete feature CLAUDE.md that future Claude instances can use to understand this feature's implementation.
