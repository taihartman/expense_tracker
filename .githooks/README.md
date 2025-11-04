# Git Hooks

This directory contains git hooks that help maintain documentation quality and consistency.

## Installation

Run the install script from the repository root:

```bash
./.githooks/install.sh
```

This will copy the hooks to `.git/hooks/` and make them executable.

## Available Hooks

### pre-commit

Reminds developers to update documentation before committing changes to feature branches.

**What it does**:
- Detects if you're on a feature branch (format: `001-feature-name`)
- Reminds you to run `/docs.log "description"` to update the feature changelog
- Prompts for confirmation before proceeding with commit

**Benefits**:
- Encourages frequent documentation updates
- Prevents forgotten changelog entries
- Maintains comprehensive feature history

## Uninstalling

To remove the hooks:

```bash
rm .git/hooks/pre-commit
```

## For Template/New Projects

When setting up a new project with this documentation system:

1. Copy the `.githooks/` directory to your new project
2. Run `./.githooks/install.sh` after cloning
3. Add installation instruction to your GETTING_STARTED.md or README.md

## Customization

You can customize the hooks by editing the files in `.githooks/` and running the install script again.

**Example customizations**:
- Change the feature branch pattern (currently `^[0-9]{3}`)
- Add additional validation checks
- Modify the reminder message
- Add hooks for other git events (post-commit, pre-push, etc.)
