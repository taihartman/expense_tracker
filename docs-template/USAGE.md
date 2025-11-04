# How to Use This Template

This guide explains how to use the Claude Code Documentation System template in your projects.

## Table of Contents

1. [Quick Start](#quick-start)
2. [What Gets Created](#what-gets-created)
3. [Customization Required](#customization-required)
4. [Project-Specific Adaptations](#project-specific-adaptations)
5. [Maintenance](#maintenance)
6. [FAQ](#faq)

---

## Quick Start

### Method 1: Automatic Setup (Recommended)

```bash
# 1. Navigate to your project root
cd /path/to/your/project

# 2. Clone or download this template
git clone https://github.com/youruser/claude-docs-template.git /tmp/docs-template

# 3. Run the setup script
/tmp/docs-template/scripts/init-docs.sh

# 4. Follow the interactive prompts
# The script will ask for:
# - Project name
# - Project description
# - Tech stack
# - Whether it's mobile-first
# - GitHub username
# - Repository name

# 5. Review and customize the generated files
# See "Customization Required" section below

# 6. Commit the documentation
git add .
git commit -m "docs: initialize documentation system"
```

### Method 2: Manual Setup

```bash
# 1. Copy the template directory structure
cp -r /path/to/claude-docs-template/.claude your-project/
cp -r /path/to/claude-docs-template/.githooks your-project/
cp -r /path/to/claude-docs-template/.github your-project/

# 2. Copy and customize template files
cp /path/to/claude-docs-template/templates/README.template.md your-project/README.md
cp /path/to/claude-docs-template/templates/CLAUDE.template.md your-project/CLAUDE.md
# ... repeat for other templates

# 3. Find and replace placeholders
# Replace {{PROJECT_NAME}}, {{PROJECT_DESC}}, {{TECH_STACK}}, etc.

# 4. Install git hooks
cd your-project
./.githooks/install.sh
```

---

## What Gets Created

The setup script creates the following structure:

```
your-project/
├── README.md                    # Project landing page
├── CLAUDE.md                    # Quick reference hub
├── PROJECT_KNOWLEDGE.md         # Architecture documentation
├── DEVELOPMENT.md               # Development workflows
├── TROUBLESHOOTING.md           # Common issues
├── GETTING_STARTED.md           # Onboarding guide
├── CONTRIBUTING.md              # Contribution guidelines
├── FEATURES.md                  # Feature directory
├── CHANGELOG.md                 # Root changelog
├── MOBILE.md (optional)         # Mobile-first guidelines
│
├── .claude/
│   ├── commands/
│   │   ├── docs.init.md         # Initialize docs
│   │   ├── docs.create.md       # Create feature docs
│   │   ├── docs.log.md          # Log changes
│   │   ├── docs.update.md       # Update architecture
│   │   ├── docs.complete.md     # Complete feature
│   │   ├── docs.validate.md     # Validate docs
│   │   ├── docs.search.md       # Search docs
│   │   └── docs.archive.md      # Archive features
│   │
│   └── skills/
│       ├── _SKILL_TEMPLATE.md   # Skill template
│       └── read-with-context.md # Example skill
│
├── .githooks/
│   ├── pre-commit               # Pre-commit hook
│   ├── install.sh               # Hook installer
│   └── README.md                # Hook documentation
│
├── .github/workflows/
│   ├── docs-lint.yml            # Documentation linting
│   └── markdown-link-check-config.json
│
├── docs/
│   └── archive/                 # For archiving old docs
│
└── specs/                       # For feature specifications
```

---

## Customization Required

After running the setup script, you MUST customize these sections:

### 1. README.md

- [ ] Add actual features list
- [ ] Update prerequisites
- [ ] Add real setup commands (install, run, test)
- [ ] Add deployment information
- [ ] Update project structure diagram
- [ ] Add license

### 2. CLAUDE.md

- [ ] Add project-specific essential commands
- [ ] Update "Before Every Commit" checklist
- [ ] Replace architecture overview with your actual architecture
- [ ] Add common tasks specific to your project
- [ ] Add project-specific tips
- [ ] Update key file locations

### 3. PROJECT_KNOWLEDGE.md

- [ ] Document your actual architecture
- [ ] Add your design patterns
- [ ] Document your data models
- [ ] Add API documentation (if applicable)
- [ ] Document key abstractions

### 4. DEVELOPMENT.md

- [ ] Add your actual development workflows
- [ ] Document your build system
- [ ] Add testing strategy
- [ ] Add debugging tips
- [ ] Document environment setup

### 5. TROUBLESHOOTING.md

- [ ] Add common issues as you encounter them
- [ ] Document solutions
- [ ] Add debugging workflows

### 6. GETTING_STARTED.md

- [ ] Update prerequisites
- [ ] Add real setup steps
- [ ] Update project structure
- [ ] Add first task examples
- [ ] Update command reference

### 7. CONTRIBUTING.md

- [ ] Adjust coding standards for your language/framework
- [ ] Update branch naming conventions
- [ ] Adjust PR process for your team
- [ ] Update testing requirements

### 8. FEATURES.md

- [ ] Add features as you build them
- [ ] Update status as features progress
- [ ] Link to feature documentation

---

## Project-Specific Adaptations

### For Flutter/Mobile Projects

**Keep**:
- MOBILE.md (customize for your mobile-first approach)
- Add skills: `mobile-first-design.md`, `widget-testing.md`

**Update CLAUDE.md with**:
- Flutter commands (flutter run, flutter test, etc.)
- Localization workflow
- State management patterns (BLoC/Provider/Riverpod)

### For React/Web Projects

**Consider adding**:
- Component library documentation
- Storybook integration
- Accessibility guidelines

**Update CLAUDE.md with**:
- npm/yarn commands
- Component testing patterns
- State management (Redux/MobX/Context)

### For Python/Backend Projects

**Remove**:
- MOBILE.md (not relevant)

**Consider adding**:
- API.md for endpoint documentation
- DATABASE.md for schema documentation
- Skills: `database-migrations.md`, `api-testing.md`

**Update CLAUDE.md with**:
- Python/pip commands
- Testing with pytest
- Virtual environment setup

### For Data Science Projects

**Consider adding**:
- DATA_DICTIONARY.md
- Skills: `jupyter-workflows.md`, `data-validation.md`
- Model documentation

**Update CLAUDE.md with**:
- Jupyter notebook workflows
- Data pipeline commands
- Model training/evaluation

---

## Maintenance

### Regular Tasks

**Weekly**:
- Run `/docs.validate` to check for issues
- Review and update TROUBLESHOOTING.md with new issues

**Monthly**:
- Review stale documentation (>30 days old)
- Archive completed features with `/docs.archive`
- Update skill guides based on new patterns

**Per Feature**:
- Use `/docs.create` to initialize feature docs
- Use `/docs.log` frequently during development
- Use `/docs.update` when architecture changes
- Use `/docs.complete` when feature is done

### Keeping Documentation Fresh

1. **Encourage team adoption**:
   - Have everyone install git hooks (`./.githooks/install.sh`)
   - Include docs review in PR checklist
   - Celebrate good documentation in PR reviews

2. **Make it easy**:
   - Use the slash commands (`/docs.log`, `/docs.update`)
   - Keep skills up to date for common tasks
   - Link to docs in PR templates

3. **Automate quality**:
   - CI/CD runs documentation linting
   - Git hooks remind about documentation
   - `/docs.validate` catches issues early

---

## FAQ

### Q: Do I need to use all the documentation files?

**A**: No. Start with the essentials:
- README.md (required - project overview)
- CLAUDE.md (highly recommended - quick reference)
- GETTING_STARTED.md (recommended - onboarding)

Add others as your project grows and needs them.

### Q: Can I rename the files?

**A**: You can, but we don't recommend it. The standard names make it easier for:
- New contributors to find information
- Claude Code to reference documentation
- Cross-project consistency

### Q: How do I handle multiple languages/frameworks in one project?

**A**: Create subsections in each doc or split into subdirectories:

```
docs/
├── frontend/
│   └── CLAUDE.md (React-specific)
└── backend/
    └── CLAUDE.md (Python-specific)
```

Link to these from the root CLAUDE.md.

### Q: What if my team doesn't use Claude Code?

**A**: The documentation system still works! The slash commands are just conveniences. Your team can:
- Manually create/update documentation
- Use the templates as guides
- Benefit from the organized structure
- Use CI/CD linting regardless

### Q: How do I update the template later?

**A**: Add the template as a git remote:

```bash
git remote add docs-template https://github.com/youruser/claude-docs-template.git
git fetch docs-template
git checkout docs-template/main -- path/to/file
```

Review changes carefully before applying.

### Q: Can I use this with an existing project?

**A**: Yes! Run the setup script in your existing project. It won't overwrite existing files (you'll need to merge manually). Start by:
1. Running setup to create structure
2. Gradually migrating existing docs
3. Updating as you work on features

### Q: How do I contribute improvements back to the template?

**A**: Fork the template repo, make improvements, and submit a PR. Good contributions:
- New skill templates
- Better automation
- Project type examples
- Documentation improvements

---

## Getting Help

- **Template Issues**: Open an issue on the template repository
- **Usage Questions**: Check the FAQ first, then open a discussion
- **Feature Requests**: Open an issue with the "enhancement" label

---

**Happy documenting! 📚**
