# Migration Script Testing Guide

**Feature ID**: 008-global-category-system
**Task**: T057 - Test migration script on staging data
**Date**: 2025-10-31

## Overview

This guide provides step-by-step instructions for testing the category migration script on staging/emulator before production deployment.

**Script Location**: `scripts/migrate_categories.dart`

---

## Prerequisites

### 1. Install Firebase Emulator Suite

```bash
# Install Firebase CLI (if not already installed)
npm install -g firebase-tools

# Login to Firebase
firebase login

# Initialize emulators (if not already done)
firebase init emulators
# Select: Firestore Emulator
# Port: 8080 (default)
```

### 2. Start Firestore Emulator

```bash
# Start emulator
firebase emulators:start --only firestore

# Output should show:
# ✔  firestore: Firestore Emulator running on http://localhost:8080
```

### 3. Verify Flutter/Dart Setup

```bash
# Verify Dart is available
dart --version

# Verify Firebase dependencies
flutter pub get
```

---

## Test Scenarios

### Scenario 1: Empty Database (Baseline Test)

**Purpose**: Verify script handles empty database gracefully.

**Setup**:
1. Start fresh emulator (no data)

**Execute**:
```bash
dart run scripts/migrate_categories.dart --dry-run
```

**Expected Result**:
- ✅ Pre-migration validation passes
- ✅ Log: "No trip-specific categories found. Migration not needed."
- ✅ Script exits cleanly
- ✅ No errors or crashes

---

### Scenario 2: Single Trip with Categories

**Purpose**: Test basic migration with simple data.

**Setup** (via Firebase Emulator UI or script):
```javascript
// Create trip
/trips/trip1
  name: "Vietnam Trip"

// Create trip categories
/trips/trip1/categories/cat1
  name: "Meals"
  icon: "restaurant"
  color: "#FF5722"
  usageCount: 5

/trips/trip1/categories/cat2
  name: "Transport"
  icon: "directions_car"
  color: "#2196F3"
  usageCount: 3

// Create expenses
/expenses/exp1
  tripId: "trip1"
  categoryId: "cat1"
  amount: 150000
  // ... other fields

/expenses/exp2
  tripId: "trip1"
  categoryId: "cat2"
  amount: 50000
```

**Execute**:
```bash
# Dry run first
dart run scripts/migrate_categories.dart --dry-run

# Live migration
dart run scripts/migrate_categories.dart
```

**Expected Results**:
- ✅ Scans 1 trip
- ✅ Finds 2 trip-specific categories
- ✅ Creates 2 global categories
- ✅ Updates 2 expense references
- ✅ Post-migration validation passes
- ✅ Logs saved to `_system/migration_log`
- ✅ ID mapping saved to `_system/migration_id_mapping`

**Verification**:
```javascript
// Check global categories created
/categories/{id1}
  name: "Meals"
  nameLowercase: "meals"
  icon: "restaurant"
  color: "#FF5722"
  usageCount: 5

/categories/{id2}
  name: "Transport"
  nameLowercase: "transport"
  icon: "directions_car"
  color: "#2196F3"
  usageCount: 3

// Check expenses updated
/expenses/exp1
  categoryId: "{new-global-id-for-meals}"

/expenses/exp2
  categoryId: "{new-global-id-for-transport}"
```

---

### Scenario 3: Multiple Trips with Duplicate Category Names

**Purpose**: Test deduplication logic and conflict resolution.

**Setup**:
```javascript
// Trip 1 categories
/trips/trip1/categories/cat1
  name: "Meals"
  icon: "restaurant"
  color: "#FF5722"
  usageCount: 10

/trips/trip1/categories/cat2
  name: "Transport"
  icon: "directions_car"
  color: "#2196F3"
  usageCount: 5

// Trip 2 categories (duplicate names, different icons/colors)
/trips/trip2/categories/cat1
  name: "Meals"
  icon: "fastfood"  // CONFLICT: different icon
  color: "#FF5722"
  usageCount: 7

/trips/trip2/categories/cat2
  name: "transport"  // Different casing
  icon: "directions_bus"  // CONFLICT: different icon
  color: "#4CAF50"  // CONFLICT: different color
  usageCount: 3

// Trip 3 categories
/trips/trip3/categories/cat1
  name: "Meals"
  icon: "restaurant"  // Matches trip1
  color: "#E91E63"  // CONFLICT: different color
  usageCount: 2

// Expenses referencing various categories
/expenses/exp1  categoryId: "cat1"  // trip1 Meals
/expenses/exp2  categoryId: "cat1"  // trip2 Meals
/expenses/exp3  categoryId: "cat1"  // trip3 Meals
/expenses/exp4  categoryId: "cat2"  // trip1 Transport
/expenses/exp5  categoryId: "cat2"  // trip2 transport
```

**Execute**:
```bash
dart run scripts/migrate_categories.dart --dry-run
```

**Expected Results**:
- ✅ Scans 3 trips
- ✅ Finds 6 trip-specific categories
- ✅ Deduplicates to 2 unique categories (Meals, Transport)
- ✅ Logs icon conflict for "Meals": {restaurant, fastfood} → restaurant (majority vote 2/3)
- ✅ Logs color conflict for "Meals": {#FF5722, #E91E63} → #FF5722 (majority vote 2/3)
- ✅ Logs icon conflict for "Transport": {directions_car, directions_bus} → directions_car (tie, uses first)
- ✅ Logs color conflict for "Transport": {#2196F3, #4CAF50} → #2196F3 (tie, uses first)
- ✅ Creates 2 global categories with resolved values
- ✅ Aggregated usageCount for "Meals": 10 + 7 + 2 = 19
- ✅ Aggregated usageCount for "Transport": 5 + 3 = 8

**Verification**:
```javascript
/categories/{global-meals-id}
  name: "Meals"
  nameLowercase: "meals"
  icon: "restaurant"  // Majority vote winner
  color: "#FF5722"  // Majority vote winner
  usageCount: 19  // Sum of all instances

/categories/{global-transport-id}
  name: "Transport"  // First instance casing
  nameLowercase: "transport"
  icon: "directions_car"  // Tie, uses first
  color: "#2196F3"  // Tie, uses first
  usageCount: 8  // Sum
```

---

### Scenario 4: Expenses with Null Categories

**Purpose**: Verify null categories are preserved.

**Setup**:
```javascript
/expenses/exp1
  categoryId: "cat1"  // Has category

/expenses/exp2
  categoryId: null  // No category

/expenses/exp3
  categoryId: null  // No category
```

**Execute**:
```bash
dart run scripts/migrate_categories.dart
```

**Expected Results**:
- ✅ Migration stats show:
  - Updated: 1 expense
  - Already null: 2 expenses
- ✅ Null expenses remain null after migration

---

### Scenario 5: Orphaned Expense References

**Purpose**: Test handling of expenses referencing non-existent categories.

**Setup**:
```javascript
/trips/trip1/categories/cat1
  name: "Meals"

/expenses/exp1
  categoryId: "cat1"  // Valid reference

/expenses/exp2
  categoryId: "cat-deleted"  // ORPHANED: category doesn't exist

/expenses/exp3
  categoryId: "cat-missing"  // ORPHANED: category doesn't exist
```

**Execute**:
```bash
dart run scripts/migrate_categories.dart
```

**Expected Results**:
- ✅ Migration stats show:
  - Updated: 1 expense (exp1)
  - Orphaned: 2 expenses (exp2, exp3)
- ✅ Orphaned expenses have categoryId set to null
- ✅ Warnings logged for orphaned references

**Verification**:
```javascript
/expenses/exp1
  categoryId: "{new-global-id}"

/expenses/exp2
  categoryId: null  // Set to null (was orphaned)

/expenses/exp3
  categoryId: null  // Set to null (was orphaned)
```

---

### Scenario 6: Large Dataset (Performance Test)

**Purpose**: Test performance with realistic data volume.

**Setup** (use script to generate):
```javascript
// 50 trips
// 5 categories per trip (250 total, ~20 unique names)
// 20 expenses per trip (1,000 total)
```

**Execute**:
```bash
time dart run scripts/migrate_categories.dart
```

**Expected Results**:
- ✅ Completes in < 5 minutes
- ✅ All batch operations complete successfully
- ✅ Memory usage remains stable
- ✅ No timeout errors
- ✅ Statistics match expected counts

---

## Rollback Testing

### Test 1: Rollback After Successful Migration

**Setup**: Complete Scenario 2 migration first.

**Execute**:
```bash
dart run scripts/migrate_categories.dart --rollback
```

**Expected Results**:
- ✅ Loads ID mapping from Firestore
- ✅ Restores expense references to old category IDs
- ✅ Deletes all global categories
- ✅ Migration status updated to 'rolled_back'
- ✅ Statistics show correct restore count

**Verification**:
```javascript
// Global categories deleted
/categories  (collection empty)

// Expenses restored to old IDs
/expenses/exp1
  categoryId: "cat1"  // Original trip-specific ID

/expenses/exp2
  categoryId: "cat2"  // Original trip-specific ID

// Migration status
/_system/migration
  status: "rolled_back"
  restoredExpenses: 2
```

### Test 2: Rollback Without ID Mapping

**Setup**: Delete `_system/migration_id_mapping` document.

**Execute**:
```bash
dart run scripts/migrate_categories.dart --rollback
```

**Expected Results**:
- ✅ Error: "No ID mapping found!"
- ✅ Message: "You must restore from Firestore backup instead."
- ✅ Script exits with error code 1

---

## Retry Logic Testing

### Test 1: Simulated Network Failure

**Purpose**: Verify retry logic works under transient failures.

**Manual Test**:
1. Pause Firestore emulator mid-migration
2. Resume after 2 seconds
3. Verify migration continues with retry

**Expected**:
- ✅ Warnings logged: "Attempt 1 failed... Retrying in 1s"
- ✅ Migration completes after retry
- ✅ No data loss

### Test 2: Permanent Failure

**Purpose**: Verify script fails gracefully after max retries.

**Manual Test**:
1. Stop Firestore emulator completely
2. Attempt migration

**Expected**:
- ✅ Retries 3 times (1s, 2s, 4s delays)
- ✅ Error: "Max retry attempts (3) exceeded"
- ✅ Migration lock status: 'failed'
- ✅ Logs saved to Firestore (if possible)

---

## Edge Cases

### Edge Case 1: Category Name with Special Characters

**Setup**:
```javascript
/trips/trip1/categories/cat1
  name: "Café & Restaurants"
  icon: "restaurant"
  color: "#FF5722"
```

**Expected**: Name preserved exactly, nameLowercase: "café & restaurants"

### Edge Case 2: Very Long Category Name

**Setup**:
```javascript
/trips/trip1/categories/cat1
  name: "A" * 100  // 100 character name
```

**Expected**: Handled without truncation

### Edge Case 3: Unicode Category Names

**Setup**:
```javascript
/trips/trip1/categories/cat1
  name: "食事"  // Japanese

/trips/trip2/categories/cat1
  name: "भोजन"  // Hindi
```

**Expected**: Unicode preserved, case-insensitive comparison works

### Edge Case 4: Empty UsageCount

**Setup**:
```javascript
/trips/trip1/categories/cat1
  name: "Meals"
  // usageCount field missing
```

**Expected**: Defaults to 0

---

## Test Execution Checklist

### Pre-Migration Tests
- [ ] Scenario 1: Empty database
- [ ] Scenario 2: Single trip with categories
- [ ] Scenario 3: Multiple trips with duplicates
- [ ] Scenario 4: Null categories preserved
- [ ] Scenario 5: Orphaned references handled
- [ ] Scenario 6: Large dataset performance

### Rollback Tests
- [ ] Test 1: Successful rollback
- [ ] Test 2: Rollback without mapping

### Retry Logic Tests
- [ ] Test 1: Transient network failure
- [ ] Test 2: Permanent failure handling

### Edge Cases
- [ ] Special characters in names
- [ ] Very long category names
- [ ] Unicode category names
- [ ] Missing usageCount field

### Dry-Run Mode
- [ ] Verify --dry-run makes no Firestore writes
- [ ] Verify dry-run logs show correct operations
- [ ] Verify dry-run generates mock IDs

---

## Success Criteria

**Migration must**:
- ✅ Handle all 6 test scenarios correctly
- ✅ Preserve data integrity (no data loss)
- ✅ Complete large dataset in < 5 minutes
- ✅ Rollback successfully when requested
- ✅ Retry failed operations up to 3 times
- ✅ Log all operations comprehensively
- ✅ Handle edge cases without errors

**Before production deployment**:
- ✅ All test scenarios pass
- ✅ Rollback tested and verified
- ✅ Dry-run mode verified
- ✅ Performance acceptable
- ✅ Edge cases handled
- ✅ Code reviewed by lead engineer

---

## Common Issues and Solutions

### Issue: "Migration already in progress"

**Cause**: Previous migration didn't clear lock
**Solution**:
```bash
# Manually delete migration lock
# In Firestore UI: Delete /_system/migration document
```

### Issue: "Max retry attempts exceeded"

**Cause**: Firestore emulator not running
**Solution**:
```bash
firebase emulators:start --only firestore
```

### Issue: Expenses not updated

**Cause**: ID mapping incorrect
**Solution**: Check logs for warnings about orphaned references

### Issue: Rollback fails

**Cause**: ID mapping not saved during migration
**Solution**: Must restore from Firestore backup instead

---

## Test Data Generator Script

**TODO (T057.1)**: Create helper script to generate test data:

```dart
// scripts/generate_test_data.dart
// - Generates N trips with M categories each
// - Creates realistic expense data
// - Includes duplicate category names
// - Includes orphaned references
// - Seeds emulator for testing
```

---

## Production Readiness Checklist

Before running on production:

- [ ] All test scenarios passed on staging
- [ ] Rollback tested and verified working
- [ ] Performance acceptable (< 1 hour for expected data)
- [ ] Firestore backup created
- [ ] Indexes deployed and showing READY status
- [ ] Team notified of migration window
- [ ] Rollback plan documented and understood
- [ ] Monitoring/alerting configured
- [ ] Manual testing checklist prepared
- [ ] Post-migration verification plan ready

---

**Document Status**: ✅ **COMPLETE**
**Next Step**: Execute test scenarios and document results
**Prepared By**: Claude (AI Assistant)

