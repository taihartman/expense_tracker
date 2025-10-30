# Test Fixtures

This directory contains mock version.json files for testing the web auto-update feature (007-web-auto-update).

## Files

- `version_older.json` - Older version (0.9.0) - should NOT trigger update notification
- `version_equal.json` - Same version (1.0.0) - should NOT trigger update notification
- `version_newer_patch.json` - Patch increment (1.0.1) - SHOULD trigger update
- `version_newer_minor.json` - Minor increment (1.1.0) - SHOULD trigger update
- `version_newer_major.json` - Major increment (2.0.0) - SHOULD trigger update
- `version_with_build.json` - Version with build number (1.0.0+5) - behavior depends on semantic version comparison
- `version_invalid.json` - Invalid version format - should fail gracefully (no update shown)
- `version_malformed.json` - Missing required field - should fail gracefully (no update shown)

## Usage

These fixtures can be used in manual testing or as reference data for integration tests.

For manual testing, you can temporarily replace `/web/version.json` with one of these files to simulate different server responses.
