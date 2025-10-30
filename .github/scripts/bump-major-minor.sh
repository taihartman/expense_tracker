#!/bin/bash
set -e

# Bump major, minor, or patch version based on argument
# Usage: ./bump-major-minor.sh [major|minor|patch]

BUMP_TYPE=$1

if [ -z "$BUMP_TYPE" ]; then
  echo "❌ Error: Please specify bump type (major, minor, or patch)"
  echo "Usage: ./bump-major-minor.sh [major|minor|patch]"
  exit 1
fi

echo "🔍 Reading current version from pubspec.yaml..."
CURRENT_VERSION=$(grep "^version:" pubspec.yaml | sed 's/version: //' | sed 's/+.*//')
BUILD_NUMBER=$(grep "^version:" pubspec.yaml | sed 's/.*+//')

echo "Current version: $CURRENT_VERSION+$BUILD_NUMBER"

# Split version into parts
IFS='.' read -r -a VERSION_PARTS <<< "$CURRENT_VERSION"
MAJOR="${VERSION_PARTS[0]}"
MINOR="${VERSION_PARTS[1]}"
PATCH="${VERSION_PARTS[2]}"

# Bump version based on type
case "$BUMP_TYPE" in
  major)
    MAJOR=$((MAJOR + 1))
    MINOR=0
    PATCH=0
    echo "🚀 Bumping MAJOR version"
    ;;
  minor)
    MINOR=$((MINOR + 1))
    PATCH=0
    echo "✨ Bumping MINOR version"
    ;;
  patch)
    PATCH=$((PATCH + 1))
    echo "🔧 Bumping PATCH version"
    ;;
  *)
    echo "❌ Error: Invalid bump type '$BUMP_TYPE'"
    echo "Valid options: major, minor, patch"
    exit 1
    ;;
esac

NEW_VERSION="$MAJOR.$MINOR.$PATCH"

# Increment build number
NEW_BUILD=$((BUILD_NUMBER + 1))

echo "New version: $NEW_VERSION+$NEW_BUILD"

# Update pubspec.yaml
echo "📝 Updating pubspec.yaml..."
sed -i.bak "s/^version: .*/version: $NEW_VERSION+$NEW_BUILD/" pubspec.yaml
rm pubspec.yaml.bak

# Update app_config.dart if it exists
if [ -f "lib/core/config/app_config.dart" ]; then
  echo "📝 Updating lib/core/config/app_config.dart..."
  sed -i.bak "s/static const String appVersion = '.*';/static const String appVersion = '$NEW_VERSION';/" lib/core/config/app_config.dart
  rm lib/core/config/app_config.dart.bak
fi

echo "✅ Version bumped to $NEW_VERSION+$NEW_BUILD"
