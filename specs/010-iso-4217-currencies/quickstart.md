# Quick Start: Currency System Maintenance

**Feature**: ISO 4217 Multi-Currency Support
**Date**: 2025-01-30
**Audience**: Developers maintaining the currency system

## Overview

This guide explains how to maintain the currency system, including adding new currencies, updating metadata, and regenerating code. The system uses code generation to create a type-safe enum from a JSON data source.

---

## Architecture Summary

```
assets/currencies.json (data source)
       ↓
build_runner + CurrencyCodeGenerator
       ↓
lib/core/models/currency_code.g.dart (generated enum)
       ↓
CurrencySearchField widget (UI)
       ↓
Trip & Expense models (data storage)
```

**Key Files**:
- `assets/currencies.json` - ISO 4217 currency data (edit this)
- `lib/generators/currency_code_generator.dart` - Code generator
- `lib/core/models/currency_code.g.dart` - Generated enum (do not edit manually)
- `lib/shared/widgets/currency_search_field.dart` - Currency picker widget

---

## Common Tasks

### Task 1: Add a New Currency

**When**: ISO 4217 introduces a new currency code

**Steps**:

1. **Edit** `assets/currencies.json`:
   ```json
   {
     "code": "XYZ",
     "numericCode": "123",
     "name": "Example Currency",
     "symbol": "XYZ",  // Or Unicode symbol if available
     "decimalPlaces": 2,  // 0, 2, or 3
     "active": true
   }
   ```

2. **Run** code generator:
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

3. **Verify** generated code:
   ```bash
   # Check that currency_code.g.dart includes new currency
   grep "xyz" lib/core/models/currency_code.g.dart
   ```

4. **Test** currency selection:
   - Run app: `flutter run -d chrome`
   - Create trip → select currency → verify "XYZ - Example Currency" appears

5. **Commit** both files:
   ```bash
   git add assets/currencies.json lib/core/models/currency_code.g.dart
   git commit -m "feat: add XYZ currency support"
   ```

**Time Estimate**: 5 minutes

---

### Task 2: Update Currency Metadata

**When**: Currency symbol or name changes, decimal places adjusted

**Example**: European Union updates Euro symbol or formatting

**Steps**:

1. **Edit** currency entry in `assets/currencies.json`:
   ```json
   {
     "code": "EUR",
     "symbol": "€",  // Updated symbol
     "name": "Euro (Updated Name)",  // Updated name
     "decimalPlaces": 2  // Updated decimal places
   }
   ```

2. **Regenerate** code:
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

3. **Run tests** to verify no regressions:
   ```bash
   flutter test test/core/models/currency_code_test.dart
   ```

4. **Commit** changes:
   ```bash
   git add assets/currencies.json lib/core/models/currency_code.g.dart
   git commit -m "fix: update EUR currency metadata"
   ```

**Time Estimate**: 3 minutes

---

### Task 3: Mark Currency as Inactive

**When**: Currency is deprecated by ISO 4217 (e.g., old currencies replaced by Euro)

**Important**: Never delete currencies (breaks existing data)

**Steps**:

1. **Edit** currency entry in `assets/currencies.json`:
   ```json
   {
     "code": "ITL",  // Italian Lira (replaced by EUR)
     "active": false  // Hide from currency picker
   }
   ```

2. **Regenerate** code:
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

3. **Verify** currency is hidden but still valid:
   ```dart
   // In tests or manually verify:
   assert(CurrencyCode.itl.isActive == false);  // Hidden from picker
   assert(CurrencyCode.fromString('ITL') == CurrencyCode.itl);  // Still parseable
   ```

4. **Test** backward compatibility:
   - Load trip created with ITL currency before deactivation
   - Verify trip displays correctly (shows "ITL" even though inactive)

5. **Commit** changes:
   ```bash
   git add assets/currencies.json lib/core/models/currency_code.g.dart
   git commit -m "chore: mark ITL as inactive currency"
   ```

**Time Estimate**: 5 minutes

---

### Task 4: Fix Generator Build Errors

**When**: Build runner fails after updating currencies.json

**Common Errors**:

#### Error: "Duplicate currency code 'USD'"

**Cause**: Two currencies with same code in JSON

**Fix**:
```bash
# Find duplicate
grep -n '"code": "USD"' assets/currencies.json

# Remove duplicate entry
# Edit assets/currencies.json and delete one entry

# Rebuild
dart run build_runner build --delete-conflicting-outputs
```

#### Error: "Invalid decimal places: 5"

**Cause**: Currency has unsupported decimal places

**Fix**:
```json
// Change from:
{"code": "XYZ", "decimalPlaces": 5}  // Invalid

// To:
{"code": "XYZ", "decimalPlaces": 3}  // Valid (max is 3)
```

#### Error: "Missing required field: symbol"

**Cause**: Currency missing a required field

**Fix**:
```json
// Add missing field:
{
  "code": "XYZ",
  "numericCode": "123",
  "name": "Example Currency",
  "symbol": "XYZ",  // ← Add this
  "decimalPlaces": 2,
  "active": true
}
```

---

### Task 5: Update to Latest ISO 4217 Standard

**When**: Quarterly maintenance or when ISO publishes amendments

**Steps**:

1. **Check** ISO 4217 amendments:
   - Visit: https://www.iso.org/iso-4217-currency-codes.html
   - Download latest amendment list

2. **Review** changes (typically 1-2 per year):
   - New currencies added
   - Currencies deactivated
   - Metadata corrections

3. **Update** `assets/currencies.json`:
   - Add new currencies with `active: true`
   - Mark deprecated currencies with `active: false`
   - Update metadata if changed

4. **Regenerate** and test:
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   flutter test
   flutter run -d chrome  # Manual smoke test
   ```

5. **Document** changes:
   ```bash
   git commit -m "chore: update currencies to ISO 4217 amendment #123 (2025-Q1)"
   ```

**Time Estimate**: 30 minutes (including research and testing)

---

## Development Workflow

### Initial Setup (First Time)

```bash
# 1. Install dependencies (if not already done)
flutter pub get

# 2. Generate currency code
dart run build_runner build --delete-conflicting-outputs

# 3. Verify generation succeeded
ls -lh lib/core/models/currency_code.g.dart

# 4. Run tests
flutter test

# 5. Run app
flutter run -d chrome
```

### Regular Development

```bash
# 1. Make changes to currencies.json (if needed)

# 2. Regenerate code
dart run build_runner build --delete-conflicting-outputs

# 3. Run tests before committing
flutter test && flutter analyze

# 4. Commit both source and generated files
git add assets/currencies.json lib/core/models/currency_code.g.dart
git commit -m "feat: update currency data"
```

---

## Testing

### Run All Currency Tests

```bash
# Unit tests for enum
flutter test test/core/models/currency_code_test.dart

# Widget tests for picker
flutter test test/shared/widgets/currency_search_field_test.dart

# Integration tests
flutter test test/integration/currency_integration_test.dart
```

### Manual Testing Checklist

- [ ] Open currency picker (trip creation page)
- [ ] Verify all currencies appear (170+ items)
- [ ] Search for "euro" → EUR appears
- [ ] Search for "USD" → USD appears
- [ ] Select currency → modal closes, selection saved
- [ ] Create expense → verify amount field respects decimal places
  - USD: allows 2 decimals (1,234.56)
  - JPY: allows 0 decimals (1,234)
  - KWD: allows 3 decimals (1,234.567)
- [ ] Load existing trip with USD/VND → verify backward compatibility

---

## Debugging

### Problem: Currency picker shows empty list

**Diagnosis**:
```dart
// Check if active currencies exist
print(CurrencyCode.activeCurrencies.length);  // Should be ~170
```

**Solution**: Verify `currencies.json` has currencies with `active: true`

### Problem: Generated code has syntax errors

**Diagnosis**:
```bash
# Check generator output for errors
dart run build_runner build --delete-conflicting-outputs --verbose
```

**Solution**: Fix validation errors in `currencies.json` (see Task 4 above)

### Problem: Currency symbol not displaying

**Diagnosis**:
```dart
// Check symbol in generated code
print(CurrencyCode.usd.symbol);  // Should print "$"
```

**Solution**: Update `symbol` field in `currencies.json`

---

## Performance Optimization

### Build Time Optimization

If code generation becomes slow (>5 seconds):

```bash
# Use watch mode during development (auto-rebuild on changes)
dart run build_runner watch --delete-conflicting-outputs

# Or build only currency code (if other generators exist)
dart run build_runner build --build-filter="lib/core/models/currency_code.g.dart"
```

### Runtime Performance

Currency search should be fast (<50ms filter time). If slow:

1. **Check list size**: Verify CurrencySearchField uses `ListView.builder` (virtualization)
2. **Profile search**: Use Flutter DevTools to measure filter performance
3. **Optimize search**: Consider caching filtered results

---

## Data Source References

### ISO 4217 Official Source

- **URL**: https://www.iso.org/iso-4217-currency-codes.html
- **Update Frequency**: 1-2 amendments per year
- **Format**: XML table with currency codes, numeric codes, names, decimal places

### Unicode CLDR (Currency Symbols)

- **URL**: https://cldr.unicode.org/
- **Data**: Currency symbols by locale
- **Format**: JSON/XML locale data

### Curated Currency Data

Our `currencies.json` is curated from:
1. ISO 4217 official tables (codes, decimal places, active status)
2. Unicode CLDR (symbols)
3. Manual verification (conflicting sources)

---

## Best Practices

### DO ✅

- Commit both `currencies.json` AND `currency_code.g.dart`
- Run tests after regenerating code
- Use `active: false` instead of deleting currencies
- Document ISO 4217 amendment number in commit messages
- Verify backward compatibility for inactive currencies

### DON'T ❌

- Don't edit `currency_code.g.dart` manually (always regenerate)
- Don't delete currencies from JSON (breaks backward compatibility)
- Don't use decimal places >3 (not supported by ISO 4217 active currencies)
- Don't forget to rebuild after editing JSON
- Don't skip tests (currency changes can break existing data)

---

## Troubleshooting Reference

| Symptom | Cause | Solution |
|---------|-------|----------|
| Build fails with "duplicate code" | Two currencies have same code | Remove duplicate from JSON |
| Currency not appearing in picker | `active: false` or missing from JSON | Set `active: true` or add to JSON |
| Symbol not displaying | Missing or incorrect symbol in JSON | Update `symbol` field in JSON |
| Decimal validation fails | Currency has wrong `decimalPlaces` | Update `decimalPlaces` in JSON (0, 2, or 3) |
| Existing data shows wrong currency | `fromString()` returning wrong enum | Check for duplicates or typos in JSON |

---

## Getting Help

**Issues**:
- Check `lib/generators/currency_code_generator.dart` for validation logic
- Review build_runner logs: `dart run build_runner build --verbose`
- Search existing GitHub issues: [project repo]/issues

**Questions**:
- Consult [data-model.md](data-model.md) for currency data structure
- Consult [contracts/currency_search_field_api.md](contracts/currency_search_field_api.md) for widget API

---

**Last Updated**: 2025-01-30
**Maintainer**: Development Team
