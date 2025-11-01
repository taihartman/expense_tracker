---
description: Load all project documentation and context into the conversation
tags: [context, documentation]
---

Quickly load comprehensive project context by reading all documentation files, configuration, and project structure.

**Steps**:

1. Read all documentation files in parallel:
   - CLAUDE.md (main project reference)
   - PROJECT_KNOWLEDGE.md (architecture and design patterns)
   - MOBILE.md (mobile-first design guidelines)
   - DEVELOPMENT.md (development workflows)
   - TROUBLESHOOTING.md (common issues and solutions)

2. Read project configuration:
   - pubspec.yaml (Flutter dependencies and project metadata)

3. Display project structure:
   - Run `git ls-files | grep "^lib/" | head -100` to show source files
   - Run `find lib/ -type d -maxdepth 3 | sort` to show directory structure

4. Show git status:
   - Run `git status --short` to show current changes
   - Run `git branch --show-current` to show current branch

**When to use**:
- At the start of a new session
- When you need to re-establish project context
- Before starting work on a new feature
- When debugging complex issues requiring full context
- After being away from the project for a while

**What you'll get**:
- Complete understanding of project architecture
- Knowledge of development workflows and patterns
- Awareness of mobile-first design requirements
- Understanding of testing and localization systems
- Current project state and active changes

**Example output includes**:
- Flutter project structure and dependencies
- Clean architecture layer organization
- BLoC/Cubit state management patterns
- Firebase integration details
- Mobile-first UI guidelines
- Activity logging requirements
- Localization workflow
- Current git branch and status
