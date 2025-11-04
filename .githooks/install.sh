#!/bin/bash
# Install git hooks for this project

HOOKS_DIR=".githooks"
GIT_HOOKS_DIR=".git/hooks"

echo "Installing git hooks..."

# Check if .git/hooks directory exists
if [ ! -d "$GIT_HOOKS_DIR" ]; then
  echo "Error: .git/hooks directory not found. Are you in the repository root?"
  exit 1
fi

# Install pre-commit hook
if [ -f "$HOOKS_DIR/pre-commit" ]; then
  cp "$HOOKS_DIR/pre-commit" "$GIT_HOOKS_DIR/pre-commit"
  chmod +x "$GIT_HOOKS_DIR/pre-commit"
  echo "✅ Installed pre-commit hook"
else
  echo "⚠️  Warning: pre-commit hook not found in $HOOKS_DIR"
fi

# Install post-commit hook if it exists
if [ -f "$HOOKS_DIR/post-commit" ]; then
  cp "$HOOKS_DIR/post-commit" "$GIT_HOOKS_DIR/post-commit"
  chmod +x "$GIT_HOOKS_DIR/post-commit"
  echo "✅ Installed post-commit hook"
fi

echo ""
echo "Git hooks installed successfully!"
echo ""
echo "These hooks will:"
echo "  - Remind you to update documentation before commits (pre-commit)"
echo ""
echo "To uninstall, run: rm .git/hooks/pre-commit .git/hooks/post-commit"
