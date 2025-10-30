#!/bin/bash
set -e

# Bump patch version automatically (e.g., 1.0.0 -> 1.0.1)
# This script updates both pubspec.yaml and lib/core/config/app_config.dart

echo "🔍 Reading current version from pubspec.yaml..."
CURRENT_VERSION=$(grep "^version:" pubspec.yaml | sed 's/version: //' | sed 's/+.*//')
BUILD_NUMBER=$(grep "^version:" pubspec.yaml | sed 's/.*+//')

echo "Current version: $CURRENT_VERSION+$BUILD_NUMBER"

# Split version into parts
IFS='.' read -r -a VERSION_PARTS <<< "$CURRENT_VERSION"
MAJOR="${VERSION_PARTS[0]}"
MINOR="${VERSION_PARTS[1]}"
PATCH="${VERSION_PARTS[2]}"

# Increment patch version
PATCH=$((PATCH + 1))
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
