#!/usr/bin/env bash

# Script to update feature documentation and changelog
# Usage: ./update-feature-docs.sh <action> <feature-id> [message]
# Actions: create, update, log, complete

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

ACTION="$1"
FEATURE_ID="$2"
MESSAGE="$3"

if [ -z "$ACTION" ] || [ -z "$FEATURE_ID" ]; then
    echo "Usage: $0 <action> <feature-id> [message]"
    echo ""
    echo "Actions:"
    echo "  create    - Create initial feature CLAUDE.md and CHANGELOG.md"
    echo "  update    - Update feature CLAUDE.md with changes (manual)"
    echo "  log       - Add entry to feature CHANGELOG.md"
    echo "  complete  - Mark feature as complete and roll up to root CHANGELOG.md"
    echo ""
    echo "Examples:"
    echo "  $0 create 001-group-expense-tracker"
    echo "  $0 log 001-group-expense-tracker 'Added expense form validation'"
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
FEATURE_CHANGELOG="$FEATURE_DIR/CHANGELOG.md"
SPEC_FILE="$FEATURE_DIR/spec.md"
ROOT_CHANGELOG="$REPO_ROOT/CHANGELOG.md"

create_feature_claude() {
    if [ ! -f "$SPEC_FILE" ]; then
        echo "Error: Spec file not found at $SPEC_FILE"
        exit 1
    fi

    # Extract feature name from spec.md
    FEATURE_NAME=$(grep -m1 "^# Feature Specification:" "$SPEC_FILE" | sed 's/# Feature Specification: //' || echo "Unknown Feature")
    CREATED_DATE=$(grep -m1 "^\*\*Created\*\*:" "$SPEC_FILE" | sed 's/\*\*Created\*\*: //' || date +%Y-%m-%d)

    # Create CLAUDE.md from template
    CLAUDE_TEMPLATE="$REPO_ROOT/.specify/templates/feature-claude-template.md"
    if [ -f "$CLAUDE_TEMPLATE" ]; then
        cp "$CLAUDE_TEMPLATE" "$FEATURE_CLAUDE"

        # Replace placeholders
        sed -i.bak "s|\[FEATURE NAME\]|$FEATURE_NAME|g" "$FEATURE_CLAUDE"
        sed -i.bak "s|\[###-feature-name\]|$FEATURE_ID|g" "$FEATURE_CLAUDE"
        sed -i.bak "s|\[DATE\]|$CREATED_DATE|g" "$FEATURE_CLAUDE"
        sed -i.bak "s|\[In Progress / Completed / Archived\]|In Progress|g" "$FEATURE_CLAUDE"
        rm -f "$FEATURE_CLAUDE.bak"

        echo "✓ Created feature CLAUDE.md at $FEATURE_CLAUDE"
    else
        echo "Error: CLAUDE template not found at $CLAUDE_TEMPLATE"
        exit 1
    fi

    # Create CHANGELOG.md from template
    CHANGELOG_TEMPLATE="$REPO_ROOT/.specify/templates/feature-changelog-template.md"
    if [ -f "$CHANGELOG_TEMPLATE" ]; then
        cp "$CHANGELOG_TEMPLATE" "$FEATURE_CHANGELOG"

        # Replace placeholders
        sed -i.bak "s|\[FEATURE NAME\]|$FEATURE_NAME|g" "$FEATURE_CHANGELOG"
        sed -i.bak "s|\[###-feature-name\]|$FEATURE_ID|g" "$FEATURE_CHANGELOG"
        sed -i.bak "s|\[DATE\]|$CREATED_DATE|g" "$FEATURE_CHANGELOG"
        rm -f "$FEATURE_CHANGELOG.bak"

        echo "✓ Created feature CHANGELOG.md at $FEATURE_CHANGELOG"
        echo "  Use './update-feature-docs.sh log $FEATURE_ID \"message\"' to add entries"
    else
        echo "Error: CHANGELOG template not found at $CHANGELOG_TEMPLATE"
        exit 1
    fi
}

log_to_feature_changelog() {
    if [ ! -f "$FEATURE_CHANGELOG" ]; then
        echo "Error: Feature CHANGELOG.md not found at $FEATURE_CHANGELOG"
        echo "Run '$0 create $FEATURE_ID' first."
        exit 1
    fi

    if [ -z "$MESSAGE" ]; then
        echo "Error: Log message required"
        echo "Usage: $0 log $FEATURE_ID \"Your log message\""
        exit 1
    fi

    # Current date
    LOG_DATE=$(date +%Y-%m-%d)

    # Create a temporary file with the log entry
    TEMP_ENTRY=$(mktemp)
    cat > "$TEMP_ENTRY" << EOF

## $LOG_DATE

### Changed
- $MESSAGE

EOF

    # Insert after "<!-- Add entries below in reverse chronological order (newest first) -->"
    # If that marker doesn't exist, insert after "## Development Log"
    if grep -q "<!-- Add entries below in reverse chronological order" "$FEATURE_CHANGELOG"; then
        # Find the line number of the marker
        LINE_NUM=$(grep -n "<!-- Add entries below in reverse chronological order" "$FEATURE_CHANGELOG" | cut -d: -f1)
        # Insert the entry after the marker
        head -n "$LINE_NUM" "$FEATURE_CHANGELOG" > "$FEATURE_CHANGELOG.tmp"
        cat "$TEMP_ENTRY" >> "$FEATURE_CHANGELOG.tmp"
        tail -n +"$((LINE_NUM + 1))" "$FEATURE_CHANGELOG" >> "$FEATURE_CHANGELOG.tmp"
    else
        # Find the line number of "## Development Log"
        LINE_NUM=$(grep -n "## Development Log" "$FEATURE_CHANGELOG" | cut -d: -f1)
        # Insert the entry after "## Development Log"
        head -n "$LINE_NUM" "$FEATURE_CHANGELOG" > "$FEATURE_CHANGELOG.tmp"
        cat "$TEMP_ENTRY" >> "$FEATURE_CHANGELOG.tmp"
        tail -n +"$((LINE_NUM + 1))" "$FEATURE_CHANGELOG" >> "$FEATURE_CHANGELOG.tmp"
    fi

    # Clean up temp file
    rm -f "$TEMP_ENTRY"

    mv "$FEATURE_CHANGELOG.tmp" "$FEATURE_CHANGELOG"

    echo "✓ Added log entry to $FEATURE_CHANGELOG"
    echo "  Entry: $MESSAGE"
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

    # Read summary from feature CLAUDE.md "Feature Overview" section
    FEATURE_SUMMARY=""
    if [ -f "$FEATURE_CLAUDE" ]; then
        # Extract first paragraph of Feature Overview
        FEATURE_SUMMARY=$(awk '/## Feature Overview/,/##/ {if (!/##/ && NF) print}' "$FEATURE_CLAUDE" | head -1)
    fi

    # Create changelog entry with summary from feature changelog
    CHANGELOG_ENTRY="
## [$FEATURE_ID] - $COMPLETION_DATE

$FEATURE_SUMMARY

See \`specs/$FEATURE_ID/CLAUDE.md\` and \`specs/$FEATURE_ID/CHANGELOG.md\` for complete details.

---
"

    # Update root CHANGELOG.md
    if [ -f "$ROOT_CHANGELOG" ]; then
        # Insert after "<!-- Features will be appended below in reverse chronological order -->"
        awk -v entry="$CHANGELOG_ENTRY" '
            /<!-- Features will be appended below in reverse chronological order -->/ {
                print
                print entry
                next
            }
            { print }
        ' "$ROOT_CHANGELOG" > "$ROOT_CHANGELOG.tmp"
        mv "$ROOT_CHANGELOG.tmp" "$ROOT_CHANGELOG"

        # Update "Unreleased" section - remove from "In Progress"
        sed -i.bak "/\[$FEATURE_ID\]/d" "$ROOT_CHANGELOG"
        rm -f "$ROOT_CHANGELOG.bak"

        echo "✓ Updated root CHANGELOG.md with feature completion"
        echo "✓ Marked feature as completed in $FEATURE_CLAUDE"
        echo "✓ Feature changelog preserved at $FEATURE_CHANGELOG"
    else
        echo "Warning: Root CHANGELOG.md not found at $ROOT_CHANGELOG"
    fi
}

case "$ACTION" in
    create)
        create_feature_claude
        ;;
    log)
        log_to_feature_changelog
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
        echo "Valid actions: create, log, update, complete"
        exit 1
        ;;
esac
