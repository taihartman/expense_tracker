---
description: Validate implementation against spec and run comprehensive quality checks
tags: [review, validation, quality]
---

Perform comprehensive review of the current feature implementation to validate against specification, run all tests and quality checks.

**Steps**:

1. **Identify current feature**:
   - Get current branch: `git branch --show-current`
   - If on feature branch, identify feature ID from branch name
   - Or ask user which feature to review

2. **Load specification**:
   - Read `specs/{feature-id}/spec.md` to understand requirements
   - Read `specs/{feature-id}/plan.md` to understand implementation approach
   - Read `specs/{feature-id}/tasks.md` to see planned tasks

3. **Review implementation changes**:
   - Run `git diff master...HEAD` to see all changes since branch creation
   - Compare implementation against spec requirements
   - Check that all planned tasks are completed

4. **Run Flutter quality checks**:
   ```bash
   # Code analysis
   flutter analyze

   # Format check
   dart format --set-exit-if-changed lib/ test/

   # Run all tests
   flutter test

   # Check test coverage (if needed)
   flutter test --coverage
   ```

5. **Verify Flutter-specific requirements**:
   - **Mobile-first**: Check that UI is designed for 375x667px (iPhone SE)
   - **Localization**: Ensure no hardcoded strings, all use `context.l10n.*`
   - **Currency**: Verify monetary inputs use `CurrencyTextField`
   - **Activity logging**: Check state-changing operations include activity logs
   - **Clean architecture**: Verify proper layer separation (presentation/domain/data)
   - **State management**: Ensure Cubits follow BLoC patterns correctly

6. **Check documentation**:
   - Verify `specs/{feature-id}/CLAUDE.md` is up to date with architecture
   - Check `specs/{feature-id}/CHANGELOG.md` has recent entries
   - Ensure code documentation (comments, docstrings) exists for complex logic

7. **Generate review report**:

```markdown
## Feature Review: {feature-name}

### Specification Compliance
- [ ] All spec requirements implemented
- [ ] Plan followed without major deviations
- [ ] All tasks from tasks.md completed

### Code Quality
- [ ] `flutter analyze` passes with no issues
- [ ] `dart format` check passes (all code formatted)
- [ ] All tests pass (`flutter test`)
- [ ] Test coverage acceptable

### Flutter Best Practices
- [ ] Mobile-first design (tested on 375x667px)
- [ ] No hardcoded strings (all localized)
- [ ] Currency inputs use `CurrencyTextField`
- [ ] Activity logging included for state changes
- [ ] Clean architecture layers respected
- [ ] BLoC/Cubit patterns followed correctly

### Documentation
- [ ] CLAUDE.md updated with architecture changes
- [ ] CHANGELOG.md has recent entries
- [ ] Code comments for complex logic

### Issues Found
{List any deviations, failed checks, or concerns}

### Recommendations
{Suggested improvements or fixes}

### Overall Status: [APPROVED | NEEDS WORK]
```

**When to use**:
- Before marking feature as complete with `/docs.complete`
- After implementing all tasks from `tasks.md`
- Before creating pull request
- When requested by code review process
- After significant refactoring

**Pass criteria**:
- All Flutter quality checks pass
- Spec requirements met
- Mobile-first guidelines followed
- Documentation up to date
- No critical issues found

**If review fails**:
- Fix identified issues
- Re-run quality checks
- Update documentation as needed
- Run `/review` again before completing feature

**Example usage**:
```
/review
```

This will perform a complete review of the current feature branch against its specification and Flutter best practices.
