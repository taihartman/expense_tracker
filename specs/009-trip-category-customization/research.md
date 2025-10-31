# Phase 0: Technical Research

**Feature**: Per-Trip Category Visual Customization + Icon System Improvements
**Date**: 2025-10-31

## Research Questions

This document consolidates research findings for technical decisions required by the implementation plan.

---

## 1. Fuzzy Matching Algorithm for Similar Category Detection

**Question**: Which string similarity algorithm should we use for detecting similar category names with 80%+ similarity threshold?

### Decision

Use **Jaro-Winkler similarity** via the `string_similarity` Dart package.

### Rationale

- **Optimized for short strings**: Category names are typically 3-20 characters, where Jaro-Winkler excels
- **Prefix-biased**: Users often type partial names ("Ski" vs "Skiing"), and Jaro-Winkler weights prefix matches heavily
- **Industry standard**: Used by record linkage systems, spell checkers, and duplicate detection
- **Threshold calibration**: 0.85+ Jaro-Winkler score correlates well with human perception of "similar"
- **Performance**: O(n*m) where n,m are string lengths; fast enough for <1000 categories
- **Package available**: `string_similarity: ^2.0.0` provides battle-tested implementation

### Implementation Notes

```dart
import 'package:string_similarity/string_similarity.dart';

double calculateSimilarity(String a, String b) {
  return StringSimilarity.compareTwoStrings(
    a.toLowerCase(),
    b.toLowerCase(),
  );
}
```

---

## 2. Type-Safe Icon Enum vs String-Based Icons

**Question**: Should we use a Dart enum for CategoryIcon or continue with string-based icons?

### Decision

Implement **CategoryIcon enum** with string serialization.

### Rationale

- **Compile-time safety**: Typos caught at compile time, not runtime
- **IDE autocomplete**: Developers get full list of available icons with documentation
- **Backward compatible**: Enum values serialize to/from strings for Firestore

---

## 3. Icon Voting System Architecture

**Question**: How should we implement the crowd-sourced icon voting system?

### Decision

Use **Firestore document per category** with icon preference map and transaction-based vote increments.

### Data Structure

```dart
// Firestore: /categoryIconPreferences/{categoryId}
{
  "categoryId": "abc123",
  "preferences": {
    "restaurant": 5,
    "fastfood": 3
  },
  "mostPopular": "restaurant",
  "lastUpdatedAt": Timestamp
}
```

**Threshold**: 3 votes = community consensus

---

## Summary

All technical decisions resolved. Ready for Phase 1.

**Dependencies to add**:
- `string_similarity: ^2.0.0` (fuzzy matching)
