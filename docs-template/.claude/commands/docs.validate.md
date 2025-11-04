---
description: Validate documentation consistency and quality
tags: [project]
---

Check documentation for consistency, broken links, outdated information, and completeness.

**When to use**: Before committing major documentation changes, or periodically to ensure docs quality.

**Validation Checks**:

1. **Broken Links Check**:
   - Scan all `.md` files for broken internal links
   - Check references to files that don't exist
   - Verify links to external resources (if accessible)
   - Check anchor links (e.g., `#section-name`)

2. **Cross-Reference Consistency**:
   - Verify CLAUDE.md links to all specialized docs
   - Check that specialized docs link back to CLAUDE.md
   - Ensure feature specs reference their CLAUDE.md files
   - Verify README.md links are correct

3. **Template Completeness**:
   - Check feature CLAUDE.md files have all required sections
   - Verify CHANGELOG.md entries have proper format
   - Check that documentation dates are recent

4. **Content Freshness**:
   - Identify docs not updated in >30 days
   - Check for TODO markers in documentation
   - Look for placeholder text that wasn't filled in

5. **Code Example Validation** (optional):
   - Check if code examples in docs still exist in codebase
   - Verify import paths are correct
   - Check if referenced files/functions exist

6. **Documentation Coverage**:
   - List features in `specs/` directory
   - Check which features have CLAUDE.md
   - Check which features have CHANGELOG.md
   - Identify features missing documentation

7. **Style Consistency**:
   - Check for consistent heading levels
   - Verify consistent use of code blocks
   - Check for consistent link formatting

**Validation Process**:

1. Read all markdown files in:
   - Root directory (CLAUDE.md, PROJECT_KNOWLEDGE.md, etc.)
   - `.claude/skills/` directory
   - `specs/` subdirectories

2. For each file, check:
   - Links to other files exist
   - Links to sections/anchors are valid
   - No placeholder text remains (e.g., "[TODO]", "[Add here]")
   - Last modified date (if available)

3. Generate validation report with:
   - ✅ Passed checks
   - ⚠️ Warnings (minor issues)
   - ❌ Errors (broken links, missing files)
   - 📊 Statistics (doc count, coverage percentage)

**Output Format**:

```
Documentation Validation Report
Generated: 2025-11-04

SUMMARY
-------
✅ 45 checks passed
⚠️ 8 warnings
❌ 3 errors

ERRORS
------
❌ Broken link in CLAUDE.md:
   Line 123: Link to 'old-file.md' (file not found)

❌ Missing feature documentation:
   Feature '005-export-reports' has no CLAUDE.md

WARNINGS
--------
⚠️ Stale documentation:
   TROUBLESHOOTING.md not updated in 45 days

⚠️ Placeholder text found:
   specs/003-activity-log/CLAUDE.md contains "[TODO: Add testing section]"

STATISTICS
----------
📊 Total markdown files: 28
📊 Root docs: 5
📊 Skills: 11
📊 Feature docs: 12
📊 Documentation coverage: 92% (11/12 features documented)
```

**Next Steps**:
Based on the report:
1. Fix all ❌ errors (broken links, missing files)
2. Address ⚠️ warnings (update stale docs, fill placeholders)
3. Consider adding docs for undocumented features
