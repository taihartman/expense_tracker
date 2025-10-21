# Feature Documentation: [FEATURE NAME]

**Feature ID**: [###-feature-name]
**Branch**: `[###-feature-name]`
**Created**: [DATE]
**Status**: [In Progress / Completed / Archived]

## Quick Reference

### Key Commands for This Feature

```bash
# Run tests related to this feature
flutter test [test paths]

# Build with this feature
flutter build web

# Run specific widget tests
flutter test test/[feature]_test.dart
```

### Important Files Modified/Created

- `lib/[path]/[file].dart` - [Description]
- `test/[path]/[file]_test.dart` - [Description]

## Feature Overview

[Brief description of what this feature does and why it exists]

## Architecture Decisions

### Data Models

- **[Entity Name]**: [Description and location]
  - Location: `lib/models/[entity].dart`
  - Key properties: [list]
  - Used by: [list of components]

### State Management

- **Approach**: [BLoC/Cubit/Provider/etc.]
- **State files**:
  - `lib/[path]/[feature]_cubit.dart`
  - `lib/[path]/[feature]_state.dart`

### UI Components

- **Main screens**:
  - `lib/screens/[feature]_screen.dart` - [Description]

- **Widgets**:
  - `lib/widgets/[widget].dart` - [Description]

## Dependencies Added

```yaml
# From pubspec.yaml
dependencies:
  [package_name]: [version]  # [Purpose]

dev_dependencies:
  [package_name]: [version]  # [Purpose]
```

## Implementation Notes

### Key Design Patterns

- [Pattern name]: [Where used and why]

### Performance Considerations

- [Specific optimization or concern]

### Known Limitations

- [Limitation and potential future improvement]

## Testing Strategy

### Test Coverage

- Unit tests: `test/[feature]/`
- Widget tests: `test/widgets/[feature]/`
- Integration tests: `test/integration/[feature]/`

### Manual Testing Checklist

- [ ] [Test scenario 1]
- [ ] [Test scenario 2]
- [ ] [Edge case testing]

## Related Documentation

- Main spec: `specs/[###-feature-name]/spec.md`
- Implementation plan: `specs/[###-feature-name]/plan.md`
- Tasks: `specs/[###-feature-name]/tasks.md`

## Future Improvements

- [Potential enhancement 1]
- [Potential enhancement 2]

## Migration Notes

### Breaking Changes

- [None / List any breaking changes]

### Migration Steps

```bash
# If users need to run migrations
flutter pub get
flutter clean && flutter pub get  # If dependencies changed
```
