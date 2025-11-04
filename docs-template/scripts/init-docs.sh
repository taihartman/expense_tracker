#!/bin/bash
# Documentation System Setup Script
# This script initializes the Claude Code documentation system in your project

set -e  # Exit on error

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_DIR="$(dirname "$SCRIPT_DIR")"

echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}  Claude Code Documentation Setup${NC}"
echo -e "${BLUE}======================================${NC}"
echo ""

# Check if we're in a git repository
if [ ! -d ".git" ]; then
    echo -e "${RED}Error: Not in a git repository root${NC}"
    echo "Please run this script from your project's root directory"
    exit 1
fi

echo -e "${GREEN}✓${NC} Found git repository"
echo ""

# Gather project information
echo -e "${BLUE}Project Information${NC}"
echo "-------------------"
echo ""

read -p "Project name: " PROJECT_NAME
read -p "Project description: " PROJECT_DESC
read -p "Tech stack (e.g., 'Flutter', 'React/TypeScript', 'Python/Django'): " TECH_STACK
read -p "Is this a mobile-first project? (y/n): " IS_MOBILE
read -p "Your GitHub username: " GITHUB_USER
read -p "Repository name (default: $(basename $(pwd))): " REPO_NAME
REPO_NAME=${REPO_NAME:-$(basename $(pwd))}

echo ""
echo -e "${YELLOW}Creating documentation structure...${NC}"

# Create directory structure
mkdir -p docs/archive
mkdir -p .claude/commands
mkdir -p .claude/skills
mkdir -p .githooks
mkdir -p specs

echo -e "${GREEN}✓${NC} Created directory structure"

# Function to copy and customize template
copy_template() {
    local src="$1"
    local dest="$2"

    if [ -f "$TEMPLATE_DIR/templates/$src" ]; then
        cp "$TEMPLATE_DIR/templates/$src" "$dest"

        # Replace placeholders
        sed -i.bak "s/{{PROJECT_NAME}}/$PROJECT_NAME/g" "$dest"
        sed -i.bak "s/{{PROJECT_DESC}}/$PROJECT_DESC/g" "$dest"
        sed -i.bak "s/{{TECH_STACK}}/$TECH_STACK/g" "$dest"
        sed -i.bak "s/{{GITHUB_USER}}/$GITHUB_USER/g" "$dest"
        sed -i.bak "s/{{REPO_NAME}}/$REPO_NAME/g" "$dest"
        sed -i.bak "s/{{DATE}}/$(date +%Y-%m-%d)/g" "$dest"

        # Remove backup file
        rm "$dest.bak"

        echo -e "${GREEN}✓${NC} Created $dest"
    else
        echo -e "${YELLOW}⚠${NC}  Template $src not found, skipping"
    fi
}

# Copy core documentation files
echo ""
echo -e "${YELLOW}Copying documentation files...${NC}"

copy_template "README.template.md" "README.md"
copy_template "CLAUDE.template.md" "CLAUDE.md"
copy_template "PROJECT_KNOWLEDGE.template.md" "PROJECT_KNOWLEDGE.md"
copy_template "DEVELOPMENT.template.md" "DEVELOPMENT.md"
copy_template "TROUBLESHOOTING.template.md" "TROUBLESHOOTING.md"
copy_template "GETTING_STARTED.template.md" "GETTING_STARTED.md"
copy_template "CONTRIBUTING.template.md" "CONTRIBUTING.md"
copy_template "FEATURES.template.md" "FEATURES.md"
copy_template "CHANGELOG.template.md" "CHANGELOG.md"

# Copy MOBILE.md only if mobile-first
if [ "$IS_MOBILE" = "y" ] || [ "$IS_MOBILE" = "Y" ]; then
    copy_template "MOBILE.template.md" "MOBILE.md"
    echo -e "${GREEN}✓${NC} Created MOBILE.md (mobile-first project)"
fi

# Copy commands
echo ""
echo -e "${YELLOW}Setting up documentation commands...${NC}"

if [ -d "$TEMPLATE_DIR/.claude/commands" ]; then
    cp "$TEMPLATE_DIR/.claude/commands/"*.md ".claude/commands/" 2>/dev/null || true
    echo -e "${GREEN}✓${NC} Copied documentation commands"
fi

# Copy skill template and examples
echo ""
echo -e "${YELLOW}Setting up skills...${NC}"

if [ -d "$TEMPLATE_DIR/.claude/skills" ]; then
    cp "$TEMPLATE_DIR/.claude/skills/_SKILL_TEMPLATE.md" ".claude/skills/" 2>/dev/null || true
    cp "$TEMPLATE_DIR/.claude/skills/read-with-context.md" ".claude/skills/" 2>/dev/null || true
    echo -e "${GREEN}✓${NC} Copied skill templates"
fi

# Copy git hooks
echo ""
echo -e "${YELLOW}Setting up git hooks...${NC}"

if [ -d "$TEMPLATE_DIR/.githooks" ]; then
    cp -r "$TEMPLATE_DIR/.githooks/"* ".githooks/" 2>/dev/null || true
    chmod +x .githooks/*.sh 2>/dev/null || true
    chmod +x .githooks/pre-commit 2>/dev/null || true
    echo -e "${GREEN}✓${NC} Copied git hooks"

    read -p "Install git hooks now? (y/n): " INSTALL_HOOKS
    if [ "$INSTALL_HOOKS" = "y" ] || [ "$INSTALL_HOOKS" = "Y" ]; then
        ./.githooks/install.sh
    fi
fi

# Copy CI/CD workflows
echo ""
echo -e "${YELLOW}Setting up CI/CD...${NC}"

if [ -d "$TEMPLATE_DIR/.github" ]; then
    mkdir -p .github/workflows
    cp "$TEMPLATE_DIR/.github/workflows/docs-lint.yml" ".github/workflows/" 2>/dev/null || true
    cp "$TEMPLATE_DIR/.github/markdown-link-check-config.json" ".github/" 2>/dev/null || true
    echo -e "${GREEN}✓${NC} Copied CI/CD workflows"
fi

# Create initial CHANGELOG entry
echo ""
echo "## $(date +%Y-%m-%d)" >> CHANGELOG.md
echo "" >> CHANGELOG.md
echo "**Documentation System Initialized** - Set up Claude Code documentation system with multi-document structure, workflow commands, CI/CD linting, and git hooks." >> CHANGELOG.md
echo "" >> CHANGELOG.md

echo ""
echo -e "${GREEN}======================================${NC}"
echo -e "${GREEN}  Setup Complete! 🎉${NC}"
echo -e "${GREEN}======================================${NC}"
echo ""
echo -e "Next steps:"
echo ""
echo -e "1. ${BLUE}Review and customize${NC} the generated documentation files"
echo -e "   - CLAUDE.md: Update quick reference for your tech stack"
echo -e "   - PROJECT_KNOWLEDGE.md: Add your architecture details"
echo -e "   - DEVELOPMENT.md: Customize workflows for your project"
echo ""
echo -e "2. ${BLUE}Add project-specific content${NC}"
echo -e "   - Create skills in .claude/skills/ for common workflows"
echo -e "   - Update TROUBLESHOOTING.md as issues arise"
echo -e "   - Update FEATURES.md as you build features"
echo ""
echo -e "3. ${BLUE}Commit the documentation${NC}"
echo -e "   git add ."
echo -e "   git commit -m \"docs: initialize documentation system\""
echo ""
echo -e "4. ${BLUE}Share with your team${NC}"
echo -e "   - Have everyone run: ./.githooks/install.sh"
echo -e "   - Point new contributors to GETTING_STARTED.md"
echo ""
echo -e "For more information, see:"
echo -e "  - ${BLUE}CLAUDE.md${NC} - Quick reference hub"
echo -e "  - ${BLUE}GETTING_STARTED.md${NC} - Onboarding guide"
echo -e "  - ${BLUE}docs-template/README.md${NC} - Template documentation"
echo ""
