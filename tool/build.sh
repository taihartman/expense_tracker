#!/bin/bash
# Combined build and mock fix script
#
# This script runs dart build_runner and then automatically fixes
# the CurrencyCode type resolution issue in generated mocks.
#
# Usage:
#   ./tool/build.sh                    # Incremental build + fix
#   ./tool/build.sh --clean            # Clean build + fix
#   ./tool/build.sh --delete-conflicting-outputs  # Delete conflicting + fix

set -e  # Exit on error

echo "🏗️  Running build_runner..."

if [ "$1" == "--clean" ]; then
    dart run build_runner clean
    dart run build_runner build --delete-conflicting-outputs
elif [ -n "$1" ]; then
    dart run build_runner build "$@"
else
    dart run build_runner build
fi

echo ""
echo "🔧 Fixing generated mocks..."
dart tool/fix_mocks.dart

echo ""
echo "✅ Build and fix complete!"
echo ""
echo "💡 Tip: Run 'flutter analyze' to verify everything is working"
