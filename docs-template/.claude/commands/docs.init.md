---
description: Initialize root documentation system for a new project
tags: [project]
---

Initialize the complete documentation system for a new project, creating all core documentation files and directory structure.

**When to use**: Setting up documentation system for a brand new project or when porting the docs system to an existing project.

**Steps**:

1. **Verify project info**:
   - Ask user for project name
   - Ask user for project description
   - Ask user for main tech stack (e.g., "Flutter", "React", "Python/Django")
   - Ask if mobile-first (for Flutter/React Native projects)

2. **Create directory structure**:
   ```bash
   mkdir -p docs/archive
   mkdir -p .claude/skills
   mkdir -p .claude/commands
   mkdir -p specs
   ```

3. **Create core documentation files**:
   - `README.md` - Landing page with project overview
   - `CLAUDE.md` - Quick reference hub
   - `PROJECT_KNOWLEDGE.md` - Architecture and patterns
   - `DEVELOPMENT.md` - Development workflows
   - `TROUBLESHOOTING.md` - Common issues
   - `GETTING_STARTED.md` - Onboarding guide
   - `CONTRIBUTING.md` - Contribution guidelines
   - `CHANGELOG.md` - Root changelog

4. **Customize for tech stack**:
   - For **Flutter/mobile projects**: Create `MOBILE.md` with mobile-first guidelines
   - For **Web projects**: Consider creating `DEPLOYMENT.md` with deployment instructions
   - For **API projects**: Consider creating `API.md` with API documentation

5. **Create initial skills** (optional - can be added later):
   - `read-with-context.md` - Code investigation methodology
   - `test-driven-development.md` - TDD workflow
   - Add tech-specific skills based on stack

6. **Create documentation workflow commands**:
   - `/docs.create` - Create feature documentation
   - `/docs.log` - Log changes
   - `/docs.update` - Update architecture docs
   - `/docs.complete` - Mark feature complete
   - `/docs.validate` - Validate documentation
   - `/docs.search` - Search documentation

7. **Update README.md** with:
   - Project name and description
   - Link to documentation system
   - Quick start commands
   - Link to GETTING_STARTED.md

8. **Initialize root CHANGELOG.md** with:
   - Project initialization entry
   - Version format
   - Categories (Added, Changed, Fixed, etc.)

**Output**:
- Complete documentation system ready for use
- All core files created with appropriate content
- Directory structure established
- Documentation workflow commands available

**Next steps**:
Tell the user to:
1. Review and customize the generated documentation
2. Add project-specific architecture details to PROJECT_KNOWLEDGE.md
3. Add common issues to TROUBLESHOOTING.md as they arise
4. Use `/docs.create` when starting new features
