# Firestore Deployment Guide - Global Category System

**Feature ID**: 008-global-category-system
**Last Updated**: 2025-10-31

## Overview

This guide covers deploying Firestore indexes and security rules for the global category system to production.

## Prerequisites

- Firebase CLI installed: `npm install -g firebase-tools`
- Logged in to Firebase: `firebase login`
- Project selected: `firebase use <project-id>`

## 1. Firestore Indexes (T069)

### Required Indexes

The global category system requires 3 composite indexes, already defined in `firestore.indexes.json`:

#### Index 1: Category Search with Popularity Ranking
```json
{
  "collectionGroup": "categories",
  "queryScope": "COLLECTION",
  "fields": [
    { "fieldPath": "nameLowercase", "order": "ASCENDING" },
    { "fieldPath": "usageCount", "order": "DESCENDING" }
  ]
}
```

**Purpose**: Supports case-insensitive prefix search sorted by popularity
**Query**:
```dart
await _firestoreService.firestore
  .collection('categories')
  .where('nameLowercase', isGreaterThanOrEqualTo: queryLower)
  .where('nameLowercase', isLessThanOrEqualTo: '$queryLower\uf8ff')
  .orderBy('nameLowercase')
  .orderBy('usageCount', descending: true)
  .get();
```

---

#### Index 2: Top Categories by Usage
```json
{
  "collectionGroup": "categories",
  "queryScope": "COLLECTION",
  "fields": [
    { "fieldPath": "usageCount", "order": "DESCENDING" }
  ]
}
```

**Purpose**: Fetches most popular categories for the chip selector
**Query**:
```dart
await _firestoreService.firestore
  .collection('categories')
  .orderBy('usageCount', descending: true)
  .limit(limit)
  .get();
```

---

#### Index 3: Rate Limiting Logs
```json
{
  "collectionGroup": "categoryCreationLogs",
  "queryScope": "COLLECTION",
  "fields": [
    { "fieldPath": "userId", "order": "ASCENDING" },
    { "fieldPath": "createdAt", "order": "DESCENDING" }
  ]
}
```

**Purpose**: Checks if user has exceeded rate limit (3 creations in 5 minutes)
**Query**:
```dart
await _firestoreService.firestore
  .collection('categoryCreationLogs')
  .where('userId', isEqualTo: userId)
  .where('createdAt', isGreaterThan: Timestamp.fromDate(fiveMinutesAgo))
  .get();
```

### Deployment Steps

#### Option A: Firebase CLI (Recommended)

```bash
# Deploy indexes from firestore.indexes.json
firebase deploy --only firestore:indexes

# Output:
# ✔  firestore: deployed indexes
```

**Deployment Time**: 5-15 minutes (Firestore builds indexes in background)

**Monitoring**:
```bash
# Check index build status
firebase firestore:indexes
```

#### Option B: Firebase Console (Manual)

1. Navigate to [Firebase Console](https://console.firebase.google.com/)
2. Select project
3. Go to **Firestore Database** → **Indexes** tab
4. Click **Add Index** for each index
5. Configure fields and order as specified above
6. Save and wait for index build completion

**Note**: Manual approach is error-prone. Use CLI deployment instead.

### Verification

After deployment, verify indexes are active:

```bash
# List all indexes
firebase firestore:indexes

# Expected output:
# categories (nameLowercase ASC, usageCount DESC) - READY
# categories (usageCount DESC) - READY
# categoryCreationLogs (userId ASC, createdAt DESC) - READY
```

**In Firebase Console**:
- All indexes show status: **Enabled**
- No indexes show status: **Building** or **Error**

## 2. Security Rules Review (T068)

⚠️ **IMPORTANT**: See [SECURITY_RULES_REVIEW.md](./SECURITY_RULES_REVIEW.md) for critical security issues.

### Current Status

**Issues**:
- Rate limiting function is non-functional (Firestore rules can't query collections)
- Duplicate checking function is non-functional (same issue)
- Field validation incomplete

**Impact**:
- Rate limiting only enforced client-side (can be bypassed)
- Duplicate categories can be created by malicious clients
- Acceptable for MVP, NOT production-ready

### Deployment Options

#### Option 1: Deploy Current Rules (MVP Only)

**For**: Development, testing, MVP demos
**Not for**: Production with real users

```bash
# Review current rules
cat firestore.rules

# Deploy
firebase deploy --only firestore:rules

# WARNING: This deploys rules with known limitations
```

#### Option 2: Deploy Simplified Rules (Recommended for MVP)

Remove broken helper functions before deployment:

**Edit firestore.rules**:
```javascript
// Remove lines 18-34 (isRateLimited and isDuplicateCategoryName functions)

// Simplify category create rule (line 43)
allow create: if isAuthenticated()
              && isValidCategoryName(request.resource.data.name);
```

**Deploy**:
```bash
firebase deploy --only firestore:rules
```

#### Option 3: Wait for Cloud Function Implementation (Production)

See Phase 3 in [SECURITY_RULES_REVIEW.md](./SECURITY_RULES_REVIEW.md#option-2-cloud-function-proxy-recommended-for-production).

**Do not deploy to production** without implementing server-side enforcement.

## 3. Data Migration (T070)

### Migration Script Status

❌ **NOT YET IMPLEMENTED**

**Required**: Scripts to migrate existing trip-specific categories to global system (T053-T057).

**Impact**: Existing expense categories will need manual re-selection after migration.

**See**: Tasks T053-T057 in implementation plan

## 4. Pre-Deployment Checklist

Before deploying to production:

- [ ] All indexes deployed and showing **READY** status
- [ ] Security rules reviewed and understood
- [ ] Known limitations documented
- [ ] Monitoring/alerting configured
- [ ] Rollback plan prepared
- [ ] Migration script tested (if applicable)
- [ ] Load testing completed
- [ ] Manual testing checklist completed ([MOBILE_TESTING_CHECKLIST.md](./MOBILE_TESTING_CHECKLIST.md))
- [ ] Stakeholders informed of known limitations

## 5. Deployment Commands Summary

```bash
# Complete deployment (indexes + rules)
firebase deploy --only firestore

# Deploy indexes only
firebase deploy --only firestore:indexes

# Deploy rules only
firebase deploy --only firestore:rules

# Check deployment status
firebase firestore:indexes
```

## 6. Rollback Plan

If issues arise after deployment:

### Rollback Indexes

```bash
# Indexes cannot be "rolled back" but can be deleted
# Navigate to Firebase Console → Firestore → Indexes
# Delete problematic indexes
# Re-deploy previous firestore.indexes.json
firebase deploy --only firestore:indexes
```

**Impact**: Queries will fail with "requires index" error until new indexes build.

### Rollback Security Rules

```bash
# View rule history
firebase firestore:rules:releases

# Rollback to previous version
firebase firestore:rules:rollback <release-name>
```

**Alternative**: Re-deploy previous firestore.rules file:
```bash
# Checkout previous version from git
git checkout <commit-hash> -- firestore.rules

# Deploy
firebase deploy --only firestore:rules

# Restore current version
git checkout HEAD -- firestore.rules
```

## 7. Monitoring After Deployment

### Metrics to Watch

**Firestore Console** → **Usage** tab:
- Read operations (should increase with category searches)
- Write operations (category creations should be limited)
- Document count for `categories` collection
- Document count for `categoryCreationLogs` collection

### Alerts to Configure

1. **Excessive Writes** to `categories`:
   - Threshold: > 100 writes/hour
   - Indicates bypassed rate limiting

2. **Large categoryCreationLogs** collection:
   - Threshold: > 10,000 documents
   - Indicates TTL cleanup needed

3. **Query Errors**:
   - Index not found errors
   - Permission denied errors

### Logs to Review

**Firebase Console** → **Firestore** → **Audit Logs**:
- Category creation patterns
- Rate limit hits
- Security rule violations

## 8. Cost Implications

### Index Storage
- 3 indexes × average category count (~50-200 categories)
- **Estimated cost**: < $1/month

### Reads
- Top categories: 1 read per expense form open
- Search: 1 read per keystroke (debounced to ~3/second max)
- **Estimated cost**: $0.01 per 1,000 operations

### Writes
- Category creation: Limited by rate limiting (3 per user per 5 min)
- Usage count increments: 1 per expense created
- **Estimated cost**: $0.01 per 1,000 operations

**Total Estimated Cost**: < $5/month for 1,000 active users

## 9. Next Steps After Deployment

1. Monitor for 24-48 hours
2. Review error logs
3. Check performance metrics
4. Gather user feedback
5. Plan Phase 2 enhancements (see SECURITY_RULES_REVIEW.md)
6. Implement Cloud Function proxy for production hardening

## 10. Contact & Support

**Issues**: Report in GitHub Issues
**Documentation**: See specs/008-global-category-system/
**Code Review**: Request review before production deployment

---

**Deployment Sign-Off**

- [ ] Indexes deployed and verified
- [ ] Security rules deployed with documented limitations
- [ ] Monitoring configured
- [ ] Team notified
- [ ] Rollback plan tested

**Deployed By**: ________________
**Date**: ________________
**Environment**: [ ] Staging [ ] Production
**Notes**:
