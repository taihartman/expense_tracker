#!/usr/bin/env bash

# Script to update feature documentation and changelog
# Usage: ./update-feature-docs.sh <feature-id> <action> [options]
# Actions: create, update, complete

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

ACTION="$1"
FEATURE_ID="$2"

if [ -z "$ACTION" ] || [ -z "$FEATURE_ID" ]; then
    echo "Usage: $0 <action> <feature-id> [options]"
    echo ""
    echo "Actions:"
    echo "  create    - Create initial feature CLAUDE.md"
    echo "  update    - Update feature CLAUDE.md with changes"
    echo "  complete  - Mark feature as complete and update CHANGELOG.md"
    echo ""
    echo "Examples:"
    echo "  $0 create 001-group-expense-tracker"
    echo "  $0 complete 001-group-expense-tracker"
    exit 1
fi

# Find repository root
if git rev-parse --show-toplevel >/dev/null 2>&1; then
    REPO_ROOT=$(git rev-parse --show-toplevel)
else
    REPO_ROOT="$(find_repo_root "$SCRIPT_DIR")"
fi

cd "$REPO_ROOT"

FEATURE_DIR="$REPO_ROOT/specs/$FEATURE_ID"
FEATURE_CLAUDE="$FEATURE_DIR/CLAUDE.md"
SPEC_FILE="$FEATURE_DIR/spec.md"
CHANGELOG="$REPO_ROOT/CHANGELOG.md"

create_feature_claude() {
    if [ ! -f "$SPEC_FILE" ]; then
        echo "Error: Spec file not found at $SPEC_FILE"
        exit 1
    fi

    # Extract feature name from spec.md
    FEATURE_NAME=$(grep -m1 "^# Feature Specification:" "$SPEC_FILE" | sed 's/# Feature Specification: //' || echo "Unknown Feature")
    CREATED_DATE=$(grep -m1 "^\*\*Created\*\*:" "$SPEC_FILE" | sed 's/\*\*Created\*\*: //' || date +%Y-%m-%d)

    # Copy template
    TEMPLATE="$REPO_ROOT/.specify/templates/feature-claude-template.md"
    if [ -f "$TEMPLATE" ]; then
        cp "$TEMPLATE" "$FEATURE_CLAUDE"

        # Replace placeholders
        sed -i.bak "s|\[FEATURE NAME\]|$FEATURE_NAME|g" "$FEATURE_CLAUDE"
        sed -i.bak "s|\[###-feature-name\]|$FEATURE_ID|g" "$FEATURE_CLAUDE"
        sed -i.bak "s|\[DATE\]|$CREATED_DATE|g" "$FEATURE_CLAUDE"
        sed -i.bak "s|\[In Progress / Completed / Archived\]|In Progress|g" "$FEATURE_CLAUDE"
        rm -f "$FEATURE_CLAUDE.bak"

        echo "✓ Created feature CLAUDE.md at $FEATURE_CLAUDE"
        echo "  Please update it with feature-specific information."
    else
        echo "Error: Template not found at $TEMPLATE"
        exit 1
    fi
}

complete_feature() {
    if [ ! -f "$FEATURE_CLAUDE" ]; then
        echo "Error: Feature CLAUDE.md not found. Run 'create' first."
        exit 1
    fi

    # Update feature CLAUDE.md status
    sed -i.bak "s|Status\*\*: In Progress|Status**: Completed|g" "$FEATURE_CLAUDE"
    rm -f "$FEATURE_CLAUDE.bak"

    # Extract feature info
    FEATURE_NAME=$(grep -m1 "^# Feature Documentation:" "$FEATURE_CLAUDE" | sed 's/# Feature Documentation: //' || echo "Unknown Feature")
    COMPLETION_DATE=$(date +%Y-%m-%d)

    # Update CHANGELOG.md
    if [ -f "$CHANGELOG" ]; then
        # Create changelog entry
        CHANGELOG_ENTRY="
## [$FEATURE_ID] - $COMPLETION_DATE

### Added
- $FEATURE_NAME (See specs/$FEATURE_ID/CLAUDE.md for details)

---
"

        # Insert after "<!-- Features will be appended below in reverse chronological order -->"
        # Use a temp file for cross-platform compatibility
        awk -v entry="$CHANGELOG_ENTRY" '
            /<!-- Features will be appended below in reverse chronological order -->/ {
                print
                print entry
                next
            }
            { print }
        ' "$CHANGELOG" > "$CHANGELOG.tmp"
        mv "$CHANGELOG.tmp" "$CHANGELOG"

        # Update "Unreleased" section - move from "In Progress" to completed
        sed -i.bak "/\[$FEATURE_ID\] $FEATURE_NAME/d" "$CHANGELOG"
        rm -f "$CHANGELOG.bak"

        echo "✓ Updated CHANGELOG.md with feature completion"
        echo "✓ Marked feature as completed in $FEATURE_CLAUDE"
    else
        echo "Warning: CHANGELOG.md not found at $CHANGELOG"
    fi
}

case "$ACTION" in
    create)
        create_feature_claude
        ;;
    complete)
        complete_feature
        ;;
    update)
        echo "Manual update: Edit $FEATURE_CLAUDE directly"
        echo "Location: $FEATURE_CLAUDE"
        ;;
    *)
        echo "Error: Unknown action '$ACTION'"
        echo "Valid actions: create, update, complete"
        exit 1
        ;;
esac
