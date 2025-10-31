# Firestore Security Rules Review - Global Category System

**Feature ID**: 008-global-category-system
**Review Date**: 2025-10-31
**Status**: ⚠️ CRITICAL ISSUES FOUND

## Overview

This document reviews the Firestore Security Rules for the global category system and identifies security vulnerabilities, logic errors, and recommendations for production deployment.

## Current Rules Analysis

### `/categories/{categoryId}` (lines 38-50)

```javascript
match /categories/{categoryId} {
  // Anyone can read categories
  allow read: if isAuthenticated();

  // Create with validation, rate limiting, and duplicate checking
  allow create: if isAuthenticated()
                && isValidCategoryName(request.resource.data.name)
                && !isRateLimited(request.auth.uid)
                && !isDuplicateCategoryName(request.resource.data.nameLowercase);

  // No updates or deletes (categories are immutable to preserve expense references)
  allow update, delete: if false;
}
```

**Security Assessment**: ⚠️ **CRITICAL ISSUES**

**Problems**:

1. **Rate Limiting Function is Non-Functional** (lines 19-26)
   ```javascript
   function isRateLimited(userId) {
     let fiveMinutesAgo = request.time - duration.value(5, 'm');
     let recentLogs = firestore.get(/databases/$(database)/documents/categoryCreationLogs)
       .data
       .where('userId', '==', userId)
       .where('createdAt', '>', fiveMinutesAgo);
     return recentLogs.size() >= 3;
   }
   ```
   - **Issue**: `firestore.get()` cannot be used on collections, only on specific documents
   - **Impact**: Rate limiting is NOT enforced at all - users can create unlimited categories
   - **Severity**: HIGH - Allows spam/abuse

2. **Duplicate Checking Function is Non-Functional** (lines 29-34)
   ```javascript
   function isDuplicateCategoryName(nameLowercase) {
     let existing = firestore.get(/databases/$(database)/documents/categories)
       .data
       .where('nameLowercase', '==', nameLowercase);
     return existing.size() > 0;
   }
   ```
   - **Issue**: Same as above - cannot query collections in security rules
   - **Impact**: Duplicate categories can be created despite the rule
   - **Severity**: MEDIUM - Data quality issue, but not a security breach

**Positive Aspects**:

✅ Category name validation (`isValidCategoryName`) is correct and functional
✅ Immutability (no update/delete) is correctly enforced
✅ Authentication requirement is correct

### `/categoryCreationLogs/{logId}` (lines 53-62)

```javascript
match /categoryCreationLogs/{logId} {
  allow read: if isAuthenticated();

  allow create: if isAuthenticated()
                && request.resource.data.userId == request.auth.uid
                && request.resource.data.createdAt == request.time;

  // No updates or deletes
  allow update, delete: if false;
}
```

**Security Assessment**: ✅ **SECURE**

**Strengths**:
- Correctly validates userId matches authenticated user
- Enforces server timestamp (`request.time`)
- Prevents tampering (no update/delete)
- Append-only log for audit trail

**Note**: This collection is used by the client for rate limiting checks. Since the security rule doesn't enforce rate limits, the client-side implementation is the current defense.

## Limitations of Firestore Security Rules

Firestore Security Rules **cannot**:
- Query collections (no `.where()` on collections)
- Count documents across a collection
- Perform joins or aggregations
- Access data from multiple documents efficiently

This means:
- **Rate limiting cannot be enforced in security rules alone**
- **Duplicate checking cannot be enforced in security rules alone**

## Current Protection Layer

**Client-Side (Repository + RateLimiterService)**:
- ✅ Rate limiting: Enforced by `RateLimiterService.canUserCreateCategory()`
- ✅ Duplicate checking: Enforced by `CategoryRepositoryImpl.categoryExists()`
- ⚠️ **Weakness**: Can be bypassed by malicious clients or direct API calls

## Recommended Solutions

### Option 1: Accept Client-Side Enforcement (Current Approach)

**Pros**:
- Already implemented
- Works for honest users
- Simple to maintain

**Cons**:
- ⚠️ Can be bypassed
- No server-side defense
- Vulnerable to malicious actors

**Recommendation**: Only acceptable for low-stakes MVP/prototype

---

### Option 2: Cloud Function Proxy (RECOMMENDED for Production)

Move category creation to a Cloud Function that enforces all business rules:

```javascript
// Cloud Function
exports.createCategory = functions.https.onCall(async (data, context) => {
  // 1. Authentication check
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const { name, icon, color } = data;
  const userId = context.auth.uid;

  // 2. Validate name
  if (!isValidCategoryName(name)) {
    throw new functions.https.HttpsError('invalid-argument', 'Invalid category name');
  }

  // 3. Check rate limit (server-side query)
  const fiveMinutesAgo = admin.firestore.Timestamp.fromDate(
    new Date(Date.now() - 5 * 60 * 1000)
  );
  const recentLogs = await admin.firestore()
    .collection('categoryCreationLogs')
    .where('userId', '==', userId)
    .where('createdAt', '>', fiveMinutesAgo)
    .get();

  if (recentLogs.size >= 3) {
    throw new functions.https.HttpsError('resource-exhausted', 'Rate limit exceeded');
  }

  // 4. Check for duplicates (server-side query)
  const nameLowercase = name.trim().toLowerCase();
  const existingCategories = await admin.firestore()
    .collection('categories')
    .where('nameLowercase', '==', nameLowercase)
    .limit(1)
    .get();

  if (!existingCategories.empty) {
    throw new functions.https.HttpsError('already-exists', 'Category already exists');
  }

  // 5. Create category
  const categoryRef = admin.firestore().collection('categories').doc();
  const batch = admin.firestore().batch();

  batch.set(categoryRef, {
    name: name.trim(),
    nameLowercase,
    icon,
    color,
    usageCount: 0,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  // 6. Log creation
  batch.set(admin.firestore().collection('categoryCreationLogs').doc(), {
    userId,
    categoryId: categoryRef.id,
    categoryName: name.trim(),
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  await batch.commit();

  return { categoryId: categoryRef.id };
});
```

**Updated Security Rules**:
```javascript
match /categories/{categoryId} {
  // Anyone can read
  allow read: if isAuthenticated();

  // Only Cloud Function can create (enforces all rules server-side)
  allow create: if false;  // Reject all direct creates

  // No updates or deletes
  allow update, delete: if false;
}

match /categoryCreationLogs/{logId} {
  allow read: if isAuthenticated();

  // Only Cloud Function can create
  allow create: if false;

  allow update, delete: if false;
}
```

**Pros**:
- ✅ Enforces rate limiting server-side
- ✅ Enforces duplicate checking server-side
- ✅ Cannot be bypassed
- ✅ Single source of truth for business logic

**Cons**:
- Requires Cloud Functions deployment
- Additional cost (Firebase Functions)
- More complex architecture

---

### Option 3: Hybrid Approach (Temporary Compromise)

**Remove broken functions from security rules** and rely on client-side enforcement with documentation:

```javascript
// Simplified rules (remove broken functions)
match /categories/{categoryId} {
  allow read: if isAuthenticated();

  // Only validate name format (enforced by rules)
  // Rate limiting and duplicate checking handled client-side
  allow create: if isAuthenticated()
                && isValidCategoryName(request.resource.data.name);

  allow update, delete: if false;
}
```

**Document in firestore.rules**:
```javascript
// WARNING: Rate limiting and duplicate checking are enforced client-side only.
// This is acceptable for MVP but should be moved to Cloud Functions for production.
// See: specs/008-global-category-system/SECURITY_RULES_REVIEW.md
```

**Pros**:
- ✅ Honest about limitations
- ✅ Simpler rules (removes non-functional code)
- ✅ Still validates name format
- ✅ Easy to deploy

**Cons**:
- ⚠️ Same vulnerabilities as Option 1
- Not production-ready

## Additional Security Recommendations

### 1. Field Validation

Current rules don't validate all fields. Add validation:

```javascript
allow create: if isAuthenticated()
              && isValidCategoryName(request.resource.data.name)
              && request.resource.data.nameLowercase == request.resource.data.name.lower()
              && request.resource.data.icon is string
              && request.resource.data.icon.size() > 0
              && request.resource.data.color is string
              && request.resource.data.color.matches('^#[0-9A-Fa-f]{6}$')  // Hex color
              && request.resource.data.usageCount == 0
              && request.resource.data.createdAt == request.time
              && request.resource.data.updatedAt == request.time
              && request.resource.data.keys().hasOnly([
                'name', 'nameLowercase', 'icon', 'color',
                'usageCount', 'createdAt', 'updatedAt'
              ]);
```

### 2. Usage Count Updates

Currently, `usageCount` increments are done client-side. Add a rule:

```javascript
// Allow incrementing usageCount only
allow update: if isAuthenticated()
              && request.resource.data.diff(resource.data).affectedKeys().hasOnly(['usageCount', 'updatedAt'])
              && request.resource.data.usageCount == resource.data.usageCount + 1
              && request.resource.data.updatedAt == request.time;
```

This allows tracking while preventing other modifications.

### 3. TTL for categoryCreationLogs

Add Time-To-Live for logs to prevent unbounded growth:

**Firestore Console**:
1. Navigate to `categoryCreationLogs` collection
2. Add TTL policy: Delete documents 7 days after `createdAt`

**OR Cloud Function**:
```javascript
// Clean up old logs weekly
exports.cleanupCategoryLogs = functions.pubsub
  .schedule('every sunday 00:00')
  .onRun(async (context) => {
    const sevenDaysAgo = admin.firestore.Timestamp.fromDate(
      new Date(Date.now() - 7 * 24 * 60 * 60 * 1000)
    );
    const oldLogs = await admin.firestore()
      .collection('categoryCreationLogs')
      .where('createdAt', '<', sevenDaysAgo)
      .get();

    const batch = admin.firestore().batch();
    oldLogs.docs.forEach(doc => batch.delete(doc.ref));
    await batch.commit();
  });
```

## Implementation Roadmap

### Phase 1: Immediate Fixes (Before Production)

1. **Remove non-functional helper functions** from firestore.rules
   ```javascript
   // Delete lines 18-34 (isRateLimited and isDuplicateCategoryName)
   ```

2. **Simplify category create rule**
   ```javascript
   allow create: if isAuthenticated()
                 && isValidCategoryName(request.resource.data.name);
   ```

3. **Add documentation warning** in firestore.rules

### Phase 2: Enhanced Client-Side Validation

4. **Add field validation** to category create rule (see recommendation #1)

5. **Add usageCount update rule** (see recommendation #2)

### Phase 3: Production Hardening

6. **Implement Cloud Function** for category creation (Option 2)

7. **Lock down security rules** to only allow Cloud Function access

8. **Add TTL cleanup** for categoryCreationLogs

9. **Add monitoring/alerting** for abuse patterns

## Testing Checklist

Before deploying to production:

- [ ] Deploy updated security rules to staging
- [ ] Test category creation (should work)
- [ ] Test category update (should fail)
- [ ] Test category delete (should fail)
- [ ] Test unauthenticated access (should fail)
- [ ] Test malicious payloads (invalid names, emojis, long strings)
- [ ] Load test: Can user create 100 categories? (Yes - rate limiting not enforced)
- [ ] Load test: Can user create duplicate "Meals"? (Yes - duplicate checking not enforced)
- [ ] Monitor categoryCreationLogs collection size
- [ ] Verify usageCount increments work correctly

## Conclusion

**Current Status**: ⚠️ **NOT PRODUCTION-READY**

**Critical Issues**:
1. Rate limiting is NOT enforced (broken helper function)
2. Duplicate checking is NOT enforced (broken helper function)
3. Field validation is incomplete
4. No cleanup mechanism for logs

**Immediate Action Required** (Phase 1):
- Remove broken helper functions
- Simplify security rules
- Document limitations

**For Production** (Phase 3):
- Implement Cloud Function proxy
- Add comprehensive monitoring
- Set up abuse detection

**Risk Assessment**:
- **Current MVP**: Acceptable with documentation
- **Production deployment**: Requires Phase 3 implementation

---

**Reviewed By**: Claude (AI Assistant)
**Next Review**: After implementing Phase 1 fixes
**Sign-off Required**: Lead Engineer
