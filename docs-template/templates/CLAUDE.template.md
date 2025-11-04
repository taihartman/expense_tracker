# CLAUDE.md - {{PROJECT_NAME}} Quick Reference

This is the main entry point for understanding and working with the {{PROJECT_NAME}} codebase. Detailed information is organized into specialized documents.

## 📚 Documentation Structure

This project uses a **multi-document system** for better navigation:

- **[PROJECT_KNOWLEDGE.md](PROJECT_KNOWLEDGE.md)** - Architecture, design patterns, data flow
- **[DEVELOPMENT.md](DEVELOPMENT.md)** - Development workflows and systems
- **[TROUBLESHOOTING.md](TROUBLESHOOTING.md)** - Common issues and solutions
- **[GETTING_STARTED.md](GETTING_STARTED.md)** - New contributor onboarding
- **[CONTRIBUTING.md](CONTRIBUTING.md)** - Contribution guidelines
- **[FEATURES.md](FEATURES.md)** - Feature directory with status
- **`.claude/skills/`** - Reusable workflow skills (see below)
- **This file (CLAUDE.md)** - Quick reference hub

## 🎯 Quick Start

### Essential Commands

```bash
# TODO: Add your project-specific commands here
# Examples:
# npm start                    # Start development server
# npm test                     # Run tests
# npm run build                # Production build
```

### Before Every Commit

```bash
# TODO: Add your pre-commit checklist
# Examples:
# npm run lint && npm test
# flutter analyze && flutter format . && flutter test
# pytest && black . && mypy .
```

## 🛠️ Claude Code Skills System

This project includes **reusable workflow skills** in `.claude/skills/` that guide you through common tasks.

**How to use skills**: These provide step-by-step workflows. Reference them when working on related tasks.

**Adding skills**: Use `.claude/skills/_SKILL_TEMPLATE.md` as a template for creating new skills.

## 📋 Development Workflow Instructions

**CRITICAL**: Follow the documentation workflow during development.

### Workflow Commands

- **`/docs.create`** - Create feature documentation (CLAUDE.md + CHANGELOG.md)
- **`/docs.log "description"`** - Log changes (use frequently!)
- **`/docs.update`** - Update feature architecture docs
- **`/docs.complete`** - Mark feature complete and roll up to root
- **`/docs.validate`** - Check documentation quality
- **`/docs.search "keyword"`** - Search across all documentation
- **`/docs.archive "feature-id"`** - Archive completed features

### When to Document

**Use `/docs.log` after:**
- Completing significant todo items
- Creating new files
- Fixing bugs
- Architectural changes

**Use `/docs.update` after:**
- Adding major components
- Adding routes or dependencies
- Changing design patterns
- Modifying core data structures

**Use `/docs.complete` when:**
- Feature is fully implemented and tested
- Ready to merge to main branch

## 🏗️ Project Architecture

<!-- TODO: Replace with your architecture overview -->

### [Your Architecture Pattern Here]

```
<!-- Example for Clean Architecture: -->
Presentation Layer
├── Views/Components - UI
└── Controllers/State - State management

Domain Layer
├── Models - Domain entities
└── Services - Business logic

Data Layer
├── Repositories - Data access
└── API - External integrations
```

**For detailed architecture**: See [PROJECT_KNOWLEDGE.md](PROJECT_KNOWLEDGE.md)

## 📂 Feature Directory

<!-- This will be populated as you build features -->

See [FEATURES.md](FEATURES.md) for the complete directory with descriptions and links.

**To add a new feature**: Follow the Spec-Kit workflow (if using) and update FEATURES.md

## 🔧 Common Tasks

<!-- TODO: Add common tasks specific to your project -->

### Example Task 1

1. Step 1
2. Step 2
3. Step 3

**Detail**: See `.claude/skills/task-name.md`

### Example Task 2

1. Step 1
2. Step 2
3. Step 3

**Detail**: See [DEVELOPMENT.md#section](DEVELOPMENT.md#section)

## 🆘 Troubleshooting

Common issues and solutions:

<!-- TODO: Add common issues as they arise -->

- **Issue 1** → Solution 1
- **Issue 2** → Solution 2

**For complete troubleshooting guide**: See [TROUBLESHOOTING.md](TROUBLESHOOTING.md)

## 🗂️ Key File Locations

```
<!-- TODO: Update with your project structure -->
project-root/
├── src/                      # Source code
│   ├── main.*                # Entry point
│   ├── core/                 # Core functionality
│   └── features/             # Feature modules
│
├── test/                     # Tests
├── .claude/                  # Claude Code configuration
│   ├── commands/             # Custom slash commands
│   └── skills/               # Reusable workflow skills
└── specs/                    # Feature specifications
```

## 📖 Documentation Index

| Document | Purpose | When to Read |
|----------|---------|--------------|
| **This file (CLAUDE.md)** | Quick reference hub | Start here |
| **[PROJECT_KNOWLEDGE.md](PROJECT_KNOWLEDGE.md)** | Architecture, patterns | Understanding codebase structure |
| **[DEVELOPMENT.md](DEVELOPMENT.md)** | Development workflows | Setting up and daily development |
| **[TROUBLESHOOTING.md](TROUBLESHOOTING.md)** | Common issues | Debugging problems |
| **[GETTING_STARTED.md](GETTING_STARTED.md)** | Onboarding guide | First time contributors |
| **[CONTRIBUTING.md](CONTRIBUTING.md)** | Contribution guidelines | Before contributing |
| **[FEATURES.md](FEATURES.md)** | Feature directory | Finding specific features |

## 💡 Tips for Working with This Codebase

<!-- TODO: Add project-specific tips -->

1. **Tip 1** - Description
2. **Tip 2** - Description
3. **Tip 3** - Description
4. **Document frequently** - Use `/docs.log` often
5. **Check troubleshooting first** - Before investigating bugs

## 🤝 Contributing

When adding new features:

1. Create feature branch: `feature-name` or `{id}-{feature-name}`
2. Use `/docs.create` to initialize feature docs (if applicable)
3. Use `/docs.log` frequently during development
4. Use `/docs.complete` when feature is done

**For complete workflow**: See [CONTRIBUTING.md](CONTRIBUTING.md)

---

**Last Updated**: {{DATE}}
**Maintained By**: {{PROJECT_NAME}} team
