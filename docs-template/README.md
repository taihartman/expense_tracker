# Claude Code Documentation System Template

A comprehensive, multi-document documentation system designed for software projects using Claude Code. This template provides a complete documentation infrastructure with automation, quality checks, and workflow commands.

## 🎯 What This Template Provides

### Documentation Structure
- **Multi-document system** - Organized by purpose (architecture, mobile, development, troubleshooting)
- **Feature documentation** - Per-feature CLAUDE.md + CHANGELOG.md
- **Reusable skills** - Step-by-step workflow guides
- **Quick reference hub** - Central CLAUDE.md linking everything

### Automation & Quality
- **Documentation commands** - `/docs.create`, `/docs.log`, `/docs.update`, `/docs.complete`, `/docs.validate`, `/docs.search`, `/docs.archive`
- **CI/CD linting** - Automated checks for broken links, stale docs, placeholders
- **Git hooks** - Pre-commit reminders to update documentation
- **Templates** - Standardized formats for features and skills

### Benefits
- ✅ **Reduces cognitive load** - Information organized by context
- ✅ **Improves onboarding** - Clear entry points for new contributors
- ✅ **Encourages documentation** - Integrated into development workflow
- ✅ **Maintains quality** - Automated checks prevent drift
- ✅ **Scales well** - Structure works for small and large projects

## 🚀 Quick Start

### Option 1: Automatic Setup (Recommended)

```bash
# Download the template
git clone https://github.com/yourusername/claude-docs-template.git
cd your-project

# Run the setup script
../claude-docs-template/scripts/init-docs.sh

# Follow the prompts to customize for your project
```

### Option 2: Manual Setup

```bash
# Copy template files to your project
cp -r claude-docs-template/.claude your-project/
cp -r claude-docs-template/templates your-project/
cp claude-docs-template/templates/README.template.md your-project/README.md
cp claude-docs-template/templates/CLAUDE.template.md your-project/CLAUDE.md
# ... copy other templates

# Customize each file for your project
# Replace {{PROJECT_NAME}}, {{TECH_STACK}}, etc.

# Install git hooks
./.githooks/install.sh
```

## 📚 What's Included

### Core Documentation Files

| File | Purpose | Customization Required |
|------|---------|----------------------|
| **README.md** | Landing page and project overview | High |
| **CLAUDE.md** | Quick reference hub | Medium |
| **PROJECT_KNOWLEDGE.md** | Architecture and patterns | High |
| **DEVELOPMENT.md** | Development workflows | Medium |
| **TROUBLESHOOTING.md** | Common issues | Low (populate over time) |
| **GETTING_STARTED.md** | New contributor onboarding | Medium |
| **CONTRIBUTING.md** | Contribution guidelines | Low |
| **FEATURES.md** | Feature directory | Low (populate as you build) |
| **CHANGELOG.md** | Root changelog | Low |

### Documentation Commands

| Command | Purpose |
|---------|---------|
| `/docs.init` | Initialize documentation system |
| `/docs.create` | Create feature documentation |
| `/docs.log` | Log changes to feature changelog |
| `/docs.update` | Update feature architecture docs |
| `/docs.complete` | Mark feature complete |
| `/docs.validate` | Check documentation quality |
| `/docs.search` | Search all documentation |
| `/docs.archive` | Archive completed features |

### Reusable Skills

Template includes a skill template and examples:
- `_SKILL_TEMPLATE.md` - Template for creating new skills
- `read-with-context.md` - Example skill for code investigation

### Automation

- **CI/CD Workflow** - Documentation linting on PR/push
- **Git Hooks** - Pre-commit reminder for documentation updates
- **Markdown Link Checker** - Validates internal/external links

## 🛠️ Customization Guide

### For Different Project Types

#### Flutter/Mobile Projects
- Keep `MOBILE.md` for mobile-first guidelines
- Add skills: `mobile-first-design.md`, `widget-testing.md`
- Update CLAUDE.md with Flutter-specific quick reference

#### Web Projects
- Remove or adapt `MOBILE.md` for responsive design
- Add skills: `component-testing.md`, `accessibility.md`
- Consider adding `DEPLOYMENT.md` for hosting instructions

#### Backend/API Projects
- Remove `MOBILE.md`
- Add `API.md` for endpoint documentation
- Add skills: `api-design.md`, `database-migrations.md`
- Update CLAUDE.md with API-specific quick reference

#### Python/Data Science Projects
- Remove `MOBILE.md`
- Add skills: `jupyter-workflows.md`, `data-validation.md`
- Consider adding `DATA_DICTIONARY.md`

### Customization Checklist

- [ ] Replace all `{{PROJECT_NAME}}` placeholders
- [ ] Replace all `{{TECH_STACK}}` placeholders
- [ ] Replace all `{{YOUR_USERNAME}}` with GitHub username
- [ ] Update README.md with project-specific information
- [ ] Customize CLAUDE.md quick reference for your tech stack
- [ ] Update PROJECT_KNOWLEDGE.md with your architecture
- [ ] Adapt DEVELOPMENT.md workflows for your project
- [ ] Remove irrelevant sections (e.g., MOBILE.md if not mobile)
- [ ] Add project-specific skills to `.claude/skills/`
- [ ] Update `.github/workflows/docs-lint.yml` paths if needed
- [ ] Run `./.githooks/install.sh` to install git hooks

## 📖 Documentation Philosophy

This template follows these principles:

### 1. **Separation of Concerns**
- Each document has a clear, focused purpose
- Avoid duplication - link to detailed docs instead
- Quick reference in CLAUDE.md, details in specialized docs

### 2. **Progressive Disclosure**
- Start with README.md (project overview)
- Move to CLAUDE.md (developer quick reference)
- Dive into specialized docs as needed (MOBILE.md, PROJECT_KNOWLEDGE.md, etc.)

### 3. **Documentation as Code**
- Documentation workflow integrated into development
- Automated quality checks (CI/CD linting)
- Git hooks encourage frequent updates

### 4. **Discoverability**
- Clear navigation from CLAUDE.md hub
- Feature directory (FEATURES.md) for finding features
- Search command (`/docs.search`) for keyword searches

### 5. **Maintainability**
- Templates ensure consistency
- Commands reduce manual work
- Automation catches issues early

## 🎓 Best Practices

### When Setting Up

1. **Start minimal** - Don't create all docs at once, add as needed
2. **Customize for your team** - Adapt workflows to match your process
3. **Set expectations** - Document documentation requirements in CONTRIBUTING.md
4. **Install hooks** - Ensure everyone runs `./.githooks/install.sh`

### During Development

1. **Document as you code** - Use `/docs.log` frequently
2. **Update on structure changes** - Run `/docs.update` when architecture changes
3. **Link to docs in PRs** - Reference relevant documentation
4. **Review docs in code review** - Documentation is part of "done"

### Maintenance

1. **Run `/docs.validate` regularly** - Check for broken links, stale docs
2. **Archive completed features** - Use `/docs.archive` to keep docs clean
3. **Update skills** - Add new workflow guides as patterns emerge
4. **Refine based on feedback** - Improve docs when confusion arises

## 🔄 Keeping Up to Date

This template will evolve. To get updates:

```bash
# Add template as a remote
cd your-project
git remote add docs-template https://github.com/yourusername/claude-docs-template.git

# Fetch updates
git fetch docs-template

# Selectively merge updates (review carefully!)
git checkout docs-template/main -- path/to/updated/file
```

## 📝 Examples

See `examples/` directory for complete setups:
- `examples/flutter-app/` - Mobile app documentation
- `examples/react-app/` - Web app documentation
- `examples/python-api/` - Backend API documentation
- `examples/data-science/` - Data science project documentation

## 🤝 Contributing

Found a bug or have a suggestion? Please:
1. Open an issue describing the problem/suggestion
2. If submitting a PR, update relevant templates
3. Test changes on a real project before submitting

## 📜 License

[Choose appropriate license - MIT recommended for templates]

## 🙏 Acknowledgments

This template was created based on lessons learned from the [Expense Tracker](https://github.com/taihartman/expense_tracker) project and the broader Claude Code community.

**Inspired by**:
- Reddit discussions on documentation systems
- GitHub Spec-Kit for structured development
- Clean Architecture documentation patterns

---

## Quick Links

- [Installation Guide](docs/INSTALLATION.md)
- [Customization Guide](docs/CUSTOMIZATION.md)
- [Command Reference](docs/COMMANDS.md)
- [Template Files](templates/)
- [Example Projects](examples/)

---

**Questions?** Open an issue or discussion on GitHub.

**Happy documenting! 📚**
