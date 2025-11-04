# {{PROJECT_NAME}}

{{PROJECT_DESC}}

## Quick Links

- **[Getting Started Guide](GETTING_STARTED.md)** - New contributor onboarding
- **[CLAUDE.md](CLAUDE.md)** - Quick reference hub for development
- **[Contributing Guidelines](CONTRIBUTING.md)** - How to contribute

## Features

<!-- TODO: List key features -->

- Feature 1
- Feature 2
- Feature 3

## Documentation System

This project uses a comprehensive multi-document system:

### Core Documentation

| Document | Purpose | Read When |
|----------|---------|-----------|
| **[CLAUDE.md](CLAUDE.md)** | Quick reference hub | Start here |
| **[PROJECT_KNOWLEDGE.md](PROJECT_KNOWLEDGE.md)** | Architecture & patterns | Understanding codebase structure |
| **[DEVELOPMENT.md](DEVELOPMENT.md)** | Development workflows | Daily development |
| **[TROUBLESHOOTING.md](TROUBLESHOOTING.md)** | Common issues | Debugging problems |

### Workflow Skills

Reusable step-by-step guides in [`.claude/skills/`](.claude/skills/) for common tasks.

### Feature Documentation

Each feature has its own documentation in [`specs/`](specs/).

## Quick Start

### Prerequisites

<!-- TODO: Add prerequisites -->

- Prerequisite 1
- Prerequisite 2
- Prerequisite 3

### Development Setup

```bash
# TODO: Add setup commands
git clone https://github.com/{{GITHUB_USER}}/{{REPO_NAME}}.git
cd {{REPO_NAME}}

# Install dependencies
# [Your install command]

# Run the project
# [Your run command]

# Run tests
# [Your test command]
```

### Before Every Commit

```bash
# TODO: Add pre-commit checks
# [Your lint/test command]
```

## Development Workflow

This project uses a **documentation-first workflow**:

1. **Create feature**: `/docs.create` - Initialize feature documentation
2. **Log changes**: `/docs.log "description"` - Log changes frequently
3. **Update architecture**: `/docs.update` - Update feature architecture docs
4. **Complete feature**: `/docs.complete` - Mark feature complete

## Architecture

<!-- TODO: Add architecture overview -->

**Tech Stack**: {{TECH_STACK}}

**For detailed architecture**: See [PROJECT_KNOWLEDGE.md](PROJECT_KNOWLEDGE.md)

## Testing

```bash
# TODO: Add test commands
# Run all tests
# [Your test command]

# Run specific test
# [Your specific test command]

# Run with coverage
# [Your coverage command]
```

## Deployment

<!-- TODO: Add deployment information -->

## Project Structure

```
<!-- TODO: Add project structure -->
project-root/
├── src/                      # Source code
├── test/                     # Tests
├── .claude/                  # Claude Code configuration
└── specs/                    # Feature specifications
```

## Contributing

We welcome contributions! Please read our [Contributing Guidelines](CONTRIBUTING.md) first.

### Quick Contribution Steps

1. Read [GETTING_STARTED.md](GETTING_STARTED.md) for onboarding
2. Create feature branch
3. Make your changes following our standards
4. Use `/docs.log` to document changes
5. Run tests and linting
6. Create pull request

## License

<!-- TODO: Add license -->

[Add your license here]

## Support

- **Issues**: [GitHub Issues](https://github.com/{{GITHUB_USER}}/{{REPO_NAME}}/issues)
- **Documentation**: Start with [CLAUDE.md](CLAUDE.md)
- **Troubleshooting**: See [TROUBLESHOOTING.md](TROUBLESHOOTING.md)

---

**For detailed development information, start with [CLAUDE.md](CLAUDE.md)**
