---
description: Add entry to feature CHANGELOG.md
tags: [project]
---

Add a changelog entry to the current feature's CHANGELOG.md file.

**Steps**:

1. Identify the current feature branch (from git or SPECIFY_FEATURE env var)
2. Ask the user what changes to log (if not already provided)
3. Run the log script:
   ```bash
   .specify/scripts/bash/update-feature-docs.sh log <feature-id> "<message>"
   ```
4. Verify the entry was added to `specs/<feature-id>/CHANGELOG.md`

**When to use**:
- After implementing a significant change or milestone
- When adding new files or components
- When fixing bugs
- When changing existing functionality
- At the end of each work session

**Best practices**:
- Use clear, descriptive messages
- Focus on what changed from a user/developer perspective
- Include file paths for major additions
- Group related changes into a single log entry

**Examples**:
```bash
# Log a new feature
.specify/scripts/bash/update-feature-docs.sh log 001-group-expense-tracker "Added expense form with validation"

# Log a bug fix
.specify/scripts/bash/update-feature-docs.sh log 001-group-expense-tracker "Fixed decimal precision in split calculations"

# Log UI changes
.specify/scripts/bash/update-feature-docs.sh log 001-group-expense-tracker "Updated settlement page layout with improved color coding"
```

**Output**: An entry is added to the feature's CHANGELOG.md with today's date.
