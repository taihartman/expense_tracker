# Quick Start - 5 Minute Setup

Get the Claude Code documentation system running in your project in 5 minutes.

## One Command Setup

```bash
# From your project root
curl -sSL https://raw.githubusercontent.com/yourusername/claude-docs-template/main/scripts/init-docs.sh | bash
```

Or manually:

```bash
# 1. Clone/download template
git clone https://github.com/yourusername/claude-docs-template.git /tmp/docs-template

# 2. Navigate to your project
cd /path/to/your-project

# 3. Run setup
/tmp/docs-template/scripts/init-docs.sh
```

## What It Will Ask

1. **Project name** - e.g., "My Awesome App"
2. **Project description** - Brief one-liner
3. **Tech stack** - e.g., "Flutter", "React/TypeScript", "Python/Django"
4. **Mobile-first?** - y/n (adds MOBILE.md if yes)
5. **GitHub username** - For repo links
6. **Repository name** - Usually your project folder name

## What You Get

✅ Complete documentation structure
✅ README.md with project overview
✅ CLAUDE.md quick reference hub
✅ GETTING_STARTED.md onboarding guide
✅ CONTRIBUTING.md guidelines
✅ 8 documentation workflow commands
✅ CI/CD linting for docs quality
✅ Git hooks for reminders
✅ Feature tracking system

## Next Steps (5 minutes)

1. **Review generated files** (2 min)
   - Open CLAUDE.md
   - Skim through README.md
   - Check GETTING_STARTED.md

2. **Customize quick wins** (2 min)
   - Add real commands to CLAUDE.md "Essential Commands"
   - Update README.md features list
   - Add your tech stack specifics

3. **Install git hooks** (30 sec)
   ```bash
   ./.githooks/install.sh
   ```

4. **Commit** (30 sec)
   ```bash
   git add .
   git commit -m "docs: initialize documentation system"
   ```

## First Use

Try the documentation commands:

```bash
# Search all docs
/docs.search "keyword"

# Validate docs quality
/docs.validate

# Create feature documentation
/docs.create

# Log changes frequently
/docs.log "your change description"
```

## Customization Priorities

**High Priority** (do first):
- [ ] Update CLAUDE.md with your essential commands
- [ ] Add your architecture to PROJECT_KNOWLEDGE.md
- [ ] Update DEVELOPMENT.md with your setup steps

**Medium Priority** (do as you work):
- [ ] Add project-specific skills to `.claude/skills/`
- [ ] Populate TROUBLESHOOTING.md as issues arise
- [ ] Update FEATURES.md as you build features

**Low Priority** (nice to have):
- [ ] Customize CONTRIBUTING.md for your team
- [ ] Add more detailed architecture docs
- [ ] Create additional workflow guides

## For Different Project Types

### Flutter/Mobile
Keep: MOBILE.md ✅
Add skills: `mobile-first-design.md`, `widget-testing.md`

### React/Web
Remove: MOBILE.md ❌
Add skills: `component-testing.md`, `accessibility.md`

### Python/Backend
Remove: MOBILE.md ❌
Add: `API.md`, `DATABASE.md`
Add skills: `api-testing.md`, `database-migrations.md`

## Common Issues

**Q: Setup script fails with "Not in a git repository"**
A: Run `git init` first, or run the script from your repo root

**Q: Placeholders still showing ({{PROJECT_NAME}})**
A: Re-run the script or manually find/replace in files

**Q: Git hooks not working**
A: Run `./.githooks/install.sh` manually

**Q: CI/CD workflow not running**
A: Ensure `.github/workflows/docs-lint.yml` is committed and pushed

## Getting Help

- 📖 Full guide: See `USAGE.md`
- ❓ FAQ: See `USAGE.md` FAQ section
- 🐛 Issues: Open an issue on template repo
- 💬 Questions: Start a discussion on template repo

## One More Thing

**Tell your team!**

After setup, share with your team:
1. Have everyone run `./.githooks/install.sh`
2. Point new contributors to `GETTING_STARTED.md`
3. Include documentation in PR checklists
4. Celebrate good documentation in reviews

---

**Setup complete? Start with [CLAUDE.md](CLAUDE.md)** 🚀
