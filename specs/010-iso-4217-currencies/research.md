# Phase 0: Research & Technical Decisions

**Feature**: ISO 4217 Multi-Currency Support
**Date**: 2025-01-30
**Status**: Complete

## Overview

This document consolidates research findings and technical decisions for implementing support for all 170+ ISO 4217 currencies. The primary challenge is replacing a hardcoded 2-currency enum with a scalable, maintainable solution that preserves type safety and backward compatibility.

---

## Decision 1: Currency Data Source

**Decision**: Use static JSON file (`assets/currencies.json`) with ISO 4217 data

**Rationale**:
- ISO 4217 currency standard changes infrequently (typically 1-2 updates per year)
- No runtime dependency on external API reduces failure points
- Compile-time currency data enables type-safe code generation
- Full control over currency metadata (symbols, decimal places)
- Faster app startup vs. fetching from API

**Alternatives Considered**:

| Alternative | Pros | Cons | Rejected Because |
|-------------|------|------|------------------|
| **Fetch from ISO API at runtime** | Always up-to-date | Network dependency, startup delay, error handling complexity | Infrequent updates don't justify runtime dependency |
| **Use Flutter `intl` package** | Built-in, maintained | Limited symbol support, no enum generation, less control | Cannot generate type-safe enum from intl data |
| **Hardcode all 170 enums manually** | Simple approach | 10,000+ lines of boilerplate, error-prone, hard to maintain | Violates DRY principle, unmaintainable |

**Implementation**:
```json
{
  "currencies": [
    {
      "code": "USD",
      "numericCode": "840",
      "name": "United States Dollar",
      "symbol": "$",
      "decimalPlaces": 2,
      "active": true
    },
    ...
  ]
}
```

**Data Source**: Curated from official ISO 4217 tables + Unicode CLDR for symbols

---

## Decision 2: Code Generation Approach

**Decision**: Use `build_runner` with custom generator to create `currency_code.g.dart`

**Rationale**:
- Project already uses `build_runner` for mocks (consistent tooling)
- Generates type-safe Dart enum at compile-time
- Maintains existing API surface (minimal breaking changes)
- IDE autocomplete and type checking preserved
- Automatic code formatting via `dart format`

**Alternatives Considered**:

| Alternative | Pros | Cons | Rejected Because |
|-------------|------|------|------------------|
| **Runtime JSON parsing to class instances** | Simpler implementation | No type safety, no autocomplete, runtime overhead | Loses compile-time guarantees |
| **Manual codegen script** | Full control | Not integrated with Dart build system, manual invocation | build_runner is standard Dart/Flutter practice |
| **Package: `freezed` or `json_serializable`** | Existing tools | Designed for data classes, not enums | Enums require custom generator |

**Implementation**:
- Generator reads `assets/currencies.json`
- Outputs `lib/core/models/currency_code.g.dart` with:
  - Enum values for all currencies
  - Extension methods for `symbol`, `displayName`, `decimalPlaces`
  - `fromString()` factory with fallback
- Existing `currency_code.dart` becomes a small wrapper importing generated code

**Build Command**: `dart run build_runner build --delete-conflicting-outputs`

---

## Decision 3: Currency Picker UI Pattern

**Decision**: Create `CurrencySearchField` widget with modal bottom sheet + search

**Rationale**:
- 170+ items cannot fit in simple dropdown on mobile (would require scrolling through entire list)
- Search/filter essential for UX (users type "euro" instead of scrolling to "E")
- Modal bottom sheet follows mobile-first design pattern (full-screen takeover on small viewports)
- Virtualized list rendering (ListView.builder) handles large dataset efficiently
- Matches existing app's bottom sheet pattern for complex input

**Alternatives Considered**:

| Alternative | Pros | Cons | Rejected Because |
|-------------|------|------|------------------|
| **Autocomplete dropdown** | Less UI disruption | Small touch targets on mobile, vertical space constraints | Poor mobile UX for 170 items |
| **Paginated dropdown** | Works for any size | Non-intuitive UX, users don't expect pagination in pickers | Violates principle of least astonishment |
| **Grouped dropdown (by region)** | Logical organization | Users must know currency's region, extra tap required | Adds cognitive load |

**Design Specifications**:
- **Mobile (<600px)**: Full-screen modal bottom sheet with search bar at top
- **Tablet/Desktop (≥600px)**: Centered dialog (600px wide) with search bar
- **Search**: Case-insensitive, matches currency code OR name (e.g., "eur" matches "EUR - Euro")
- **List**: Virtualized with ListView.builder (only renders visible items)
- **Highlighting**: Matched search terms highlighted in results
- **Accessibility**: Keyboard navigation, screen reader support, clear "close" action

**API**:
```dart
CurrencySearchField(
  value: CurrencyCode.usd,
  onChanged: (CurrencyCode? currency) { },
  label: 'Currency',
)
```

---

## Decision 4: Decimal Place Support

**Decision**: Extend system to support 0, 2, AND 3 decimal places

**Rationale**:
- ISO 4217 active currencies require: 0 (JPY, KRW, VND), 2 (USD, EUR, GBP), or 3 (BHD, KWD, OMR, TND, JOD)
- Current system only handles 0 and 2 decimals
- 5 active currencies use 3 decimals (important for Middle East users)
- Implementation cost is low (update CurrencyInputFormatter regex)

**Alternatives Considered**:

| Alternative | Pros | Cons | Rejected Because |
|-------------|------|------|------------------|
| **Only support 0 and 2 decimals** | Simpler implementation | Excludes 5 active currencies (BHD, KWD, OMR, TND, JOD) | Incomplete ISO 4217 support |
| **Support arbitrary decimals** | Future-proof | Complexity for no current benefit (no active currencies >3 decimals) | YAGNI principle |

**Implementation**:
- Update `CurrencyInputFormatter` to accept decimalPlaces: int (0-3)
- Update `CurrencyTextField` to read decimalPlaces from selected currency
- Update `formatAmountForInput()` and `stripCurrencyFormatting()` helpers
- Add validation tests for 3-decimal currencies

---

## Decision 5: Currency Symbol Handling

**Decision**: Use Unicode symbols when available, fallback to currency code

**Rationale**:
- Many currencies have widely-recognized Unicode symbols ($, €, £, ¥, ₹)
- Some currencies lack standard symbols (AED, THB, SGD)
- Displaying "AED" is more recognizable than inventing a symbol
- Users understand currency codes from payment forms, banking apps

**Symbol Strategy**:
```dart
String get symbol {
  switch (this) {
    case CurrencyCode.usd: return '\$';
    case CurrencyCode.eur: return '€';
    case CurrencyCode.gbp: return '£';
    case CurrencyCode.aed: return 'AED';  // No widely-recognized symbol
    // ... generated for all 170 currencies
  }
}
```

**Symbol Sources**:
1. Primary: Unicode CLDR currency symbols
2. Fallback: 3-letter ISO 4217 code

**Alternatives Considered**:

| Alternative | Pros | Cons | Rejected Because |
|-------------|------|------|------------------|
| **Always use currency code** | Consistent | Less visual, longer | Symbols provide better UX when available |
| **Always use symbol** | More visual | Confusing for currencies without recognized symbols | Some symbols are regional/ambiguous |
| **Fetch symbols from `intl` package** | Maintained by Google | Limited to Flutter's locale data | CLDR has better coverage |

---

## Decision 6: Display Name Localization

**Decision**: English display names only for initial release, use `app_en.arb`

**Rationale**:
- App currently only supports English (app_en.arb)
- 170 currency names * N languages = high translation cost
- Currency codes (EUR, USD, JPY) are internationally recognized
- Can add translations in future if multi-language support added

**Implementation**:
- Add 170 entries to `app_en.arb`: `"currencyUSD": "United States Dollar"`, etc.
- OR: Store English names in currencies.json and skip l10n for now (simpler)
- Display format: "USD - United States Dollar" (code first for scannability)

**Future Enhancement**: If app adds multi-language support, use `intl` package's built-in currency names

**Alternatives Considered**:

| Alternative | Pros | Cons | Rejected Because |
|-------------|------|------|------------------|
| **Multi-language from start** | Future-proof | 170 currencies * 5 languages = 850 translations | App not multi-language yet |
| **Use `intl` package names** | No translation needed | English-only, not in ARB format | Acceptable for MVP |

**Decision for MVP**: Store English names in `currencies.json`, skip ARB entries for now (can migrate later)

---

## Decision 7: Backward Compatibility Strategy

**Decision**: No data migration required; existing currency codes remain valid

**Rationale**:
- Firestore already stores currency codes as strings ("USD", "VND")
- Generated enum will include USD and VND (continuity)
- `fromString()` method validates against all 170 currencies
- Tests verify USD/VND data still loads correctly

**Migration Checklist**:
- ✅ No database migration (codes are strings, already compatible)
- ✅ Enum includes USD and VND (existing defaults work)
- ✅ fromString() method handles existing codes
- ✅ Tests verify backward compatibility

**Risk Mitigation**:
- Add explicit tests loading old USD/VND trips and expenses
- Verify decimal places: USD=2, VND=0 (no change)
- Verify symbols: USD=$, VND=₫ (no change)

---

## Decision 8: Build Integration

**Decision**: Add `currency_code.g.dart` to git, regenerate when `currencies.json` changes

**Rationale**:
- Generated code is deterministic (same input → same output)
- Checking in generated code allows others to build without running generator first
- Standard practice for `build_runner` in Flutter projects
- CI/CD can verify generated code is up-to-date

**Build Workflow**:
1. Developer updates `currencies.json` (rare: ~1-2x/year)
2. Run `dart run build_runner build --delete-conflicting-outputs`
3. Commit both `currencies.json` AND `currency_code.g.dart`
4. CI verifies generated code matches source (fails if out of sync)

**Git Configuration**:
```gitignore
# Do NOT ignore generated currency code
# *.g.dart  <-- remove currency_code.g.dart from this pattern
```

---

## Best Practices Research

### Flutter `build_runner` Patterns

**Key Findings**:
- Use `@GeneratedCode` annotation to indicate machine-generated code
- Add header comment with generator version and timestamp
- Use `part` directive: `currency_code.dart` includes `part 'currency_code.g.dart';`
- Generator should be in `lib/generators/` or `tool/generators/`

**Example Generator Structure**:
```dart
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

Builder currencyCodeBuilder(BuilderOptions options) {
  return LibraryBuilder(
    CurrencyCodeGenerator(),
    generatedExtension: '.currency.g.dart',
  );
}

class CurrencyCodeGenerator extends Generator {
  @override
  String generate(LibraryReader library, BuildStep buildStep) {
    // Read currencies.json
    // Generate enum code
    // Return as string
  }
}
```

### Mobile-First Search UI Patterns

**Key Findings**:
- Use `showModalBottomSheet()` for mobile, `showDialog()` for desktop
- Debounce search input (300ms) to avoid excessive filtering
- Use `ListView.builder()` for virtualization (don't render all 170 items)
- Clear button in search field for easy reset
- Show "No results" message when filter returns empty

**Reference Implementations**:
- Flutter Material `SearchDelegate` (but full-screen, too heavy for currency picker)
- pub.dev package `flutter_typeahead` (autocomplete pattern)
- Custom implementation recommended (simpler, more control)

### Currency Data Maintenance

**Key Findings**:
- ISO 4217 updates: Check [ISO website](https://www.iso.org/iso-4217-currency-codes.html) quarterly
- Currency additions/removals are rare (1-2 per year)
- Symbol sources: Unicode CLDR > Wikipedia > Central Bank websites
- Decimal places: Always trust ISO 4217 official tables

**Update Workflow**:
1. Review ISO 4217 amendments list
2. Update `currencies.json` with changes
3. Run build_runner to regenerate enum
4. Update tests if new edge cases (e.g., first 4-decimal currency)
5. Commit and deploy

---

## Risk Analysis

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| **Build time increases significantly** | Low | Medium | Benchmark generator performance, optimize JSON parsing |
| **Large enum causes IDE slowdown** | Low | Low | Test with 170-value enum in IDE, unlikely to cause issues |
| **Users can't find their currency** | Medium | High | Implement robust search, show currency code + name, add "popular currencies" section |
| **3-decimal currencies break validation** | Medium | High | Comprehensive tests for BHD, KWD, OMR, TND, JOD before release |
| **Firestore query performance degrades** | Very Low | Low | Currency codes are strings, no schema change, no performance impact |

---

## Open Questions (Resolved)

All questions resolved during research phase. No blocking decisions remain.

---

## Next Steps (Phase 1)

1. ✅ Create `data-model.md` - Currency entity structure and generated enum design
2. ✅ Create `contracts/currency_search_field_api.md` - Widget API specification
3. ✅ Create `quickstart.md` - Developer guide for maintaining currencies
4. ✅ Update agent context with currency generation technology

**Status**: Research complete. Ready for Phase 1 design.
