# Contract: Trip Currency Migration Cloud Function

**Feature**: 011-trip-multi-currency
**Component**: Firebase Cloud Functions (Server-Side)
**Created**: 2025-11-02

## Purpose

This Cloud Function performs a one-time server-side migration of all existing trips from the legacy `baseCurrency` field to the new `allowedCurrencies` array field. It ensures all trips have the required multi-currency structure without requiring user intervention or client-side migration.

## Function Specification

### File Location

`functions/src/migrations/migrate-trip-currencies.ts`

### Function Signature

```typescript
import * as admin from 'firebase-admin';
import * as functions from 'firebase-functions';

export interface MigrationResult {
  success: boolean;
  tripId: string;
  reason?: string;
  baseCurrency?: string;
}

export interface MigrationSummary {
  startTime: string;
  endTime: string;
  totalTrips: number;
  successful: number;
  failed: number;
  skipped: number;
  results: MigrationResult[];
}

export const migrateTripCurrencies = functions
  .runWith({
    timeoutSeconds: 540,  // 9 minutes (max for HTTP functions)
    memory: '512MB',
  })
  .https.onRequest(async (req, res) => {
    // Authentication check (optional - restrict to admin)
    const authHeader = req.headers.authorization;
    if (!authHeader || authHeader !== `Bearer ${functions.config().migration.secret}`) {
      res.status(403).send('Unauthorized');
      return;
    }
    
    const summary = await runMigration();
    res.status(200).json(summary);
  });

async function runMigration(): Promise<MigrationSummary> {
  // Implementation details below
}
```

### Trigger Mechanism

**HTTP Endpoint**:
- URL: `https://us-central1-{project-id}.cloudfunctions.net/migrateTripCurrencies`
- Method: `POST`
- Auth: Bearer token (configured in Firebase Functions config)
- Invocation: Manual via `curl` or Firebase Console

**Example Invocation**:
```bash
curl -X POST \
  https://us-central1-expense-tracker.cloudfunctions.net/migrateTripCurrencies \
  -H "Authorization: Bearer ${MIGRATION_SECRET}" \
  -H "Content-Type: application/json"
```

**Alternative: Cloud Scheduler** (optional):
- Schedule: One-time or recurring (for retry)
- Trigger: HTTP target to function URL
- Use case: Automated migration at specific time

## Migration Logic

### Step-by-Step Process

1. **Query Legacy Trips**
   ```typescript
   const db = admin.firestore();
   const tripsRef = db.collection('trips');
   
   // Find all trips without allowedCurrencies field
   const snapshot = await tripsRef
     .where('allowedCurrencies', '==', null)
     .get();
   ```

2. **Iterate and Migrate**
   ```typescript
   const results: MigrationResult[] = [];
   
   for (const doc of snapshot.docs) {
     const tripId = doc.id;
     const data = doc.data();
     const baseCurrency = data.baseCurrency;
     
     // Validate baseCurrency exists
     if (!baseCurrency) {
       results.push({
         success: false,
         tripId,
         reason: 'missing baseCurrency field'
       });
       continue;
     }
     
     try {
       // Update trip with allowedCurrencies = [baseCurrency]
       await doc.ref.update({
         allowedCurrencies: [baseCurrency],
         updatedAt: admin.firestore.FieldValue.serverTimestamp()
       });
       
       results.push({
         success: true,
         tripId,
         baseCurrency
       });
       
     } catch (error) {
       results.push({
         success: false,
         tripId,
         reason: error.message,
         baseCurrency
       });
     }
   }
   ```

3. **Generate Summary**
   ```typescript
   const summary: MigrationSummary = {
     startTime: new Date().toISOString(),
     endTime: new Date().toISOString(),
     totalTrips: snapshot.size,
     successful: results.filter(r => r.success).length,
     failed: results.filter(r => !r.success).length,
     skipped: 0,  // Reserved for future use
     results
   };
   
   return summary;
   ```

## Input/Output

### Input

**None** - Function queries Firestore directly for trips without `allowedCurrencies` field.

**Optional Query Parameters** (future enhancement):
- `dryRun=true`: Simulate migration without writing to Firestore
- `batchSize=100`: Process trips in batches (prevent timeout)

### Output

**Success Response** (HTTP 200):
```json
{
  "startTime": "2025-11-02T14:30:00.000Z",
  "endTime": "2025-11-02T14:32:15.500Z",
  "totalTrips": 150,
  "successful": 148,
  "failed": 2,
  "skipped": 0,
  "results": [
    {
      "success": true,
      "tripId": "trip_abc123",
      "baseCurrency": "USD"
    },
    {
      "success": false,
      "tripId": "trip_xyz789",
      "reason": "missing baseCurrency field"
    }
  ]
}
```

**Error Response** (HTTP 403):
```json
{
  "error": "Unauthorized"
}
```

**Error Response** (HTTP 500):
```json
{
  "error": "Internal server error",
  "message": "Failed to connect to Firestore"
}
```

## Error Handling

### Trip-Level Errors

| Error Scenario | Behavior | Result |
|----------------|----------|--------|
| Missing `baseCurrency` | Log error, skip trip | `{ success: false, reason: 'missing baseCurrency field' }` |
| Invalid `baseCurrency` code | Migrate anyway (validation client-side) | `{ success: true }` (repository will handle invalid codes) |
| Firestore write failure | Log error, continue to next trip | `{ success: false, reason: 'Firestore error: ...' }` |
| Trip already migrated | Skip (query filters these out) | Not included in results |

### Function-Level Errors

| Error Scenario | Behavior | HTTP Response |
|----------------|----------|---------------|
| Authentication failure | Return 403 immediately | `{ error: 'Unauthorized' }` |
| Firestore connection failure | Return 500 | `{ error: 'Failed to connect to Firestore' }` |
| Timeout (>9 minutes) | Partial migration | Summary with `totalTrips > successful + failed` |

### Retry Logic

**No automatic retry** - function is idempotent, safe to re-run.

**Manual retry**:
- Re-invoke function URL
- Query filters out already-migrated trips (`allowedCurrencies != null`)
- Only processes remaining trips

## Logging

### Cloud Functions Logs

```typescript
console.log(`Starting trip currency migration...`);
console.log(`Found ${snapshot.size} trips to migrate`);

for (const doc of snapshot.docs) {
  if (success) {
    console.log(`✓ Migrated trip ${tripId}: ${baseCurrency} → [${baseCurrency}]`);
  } else {
    console.error(`✗ Failed to migrate trip ${tripId}: ${reason}`);
  }
}

console.log(`Migration complete: ${successful}/${totalTrips} successful, ${failed} failed`);
```

**Log Level**: INFO for success, ERROR for failures

**Log Retention**: 30 days (Firebase default)

### Firestore Audit Log (Optional)

Store migration summary in Firestore for historical record:

```typescript
await db.collection('migrations').add({
  type: 'trip-currency',
  timestamp: admin.firestore.FieldValue.serverTimestamp(),
  summary: summary,
});
```

**Collection**: `migrations`
**Document Fields**:
- `type`: "trip-currency"
- `timestamp`: Server timestamp
- `summary`: MigrationSummary object

## Testing

### Local Development (Emulator)

**Setup**:
1. Install Firebase emulators: `firebase init emulators`
2. Enable Firestore emulator
3. Run: `firebase emulators:start`

**Test Data**:
```typescript
// Create legacy trip in emulator
await db.collection('trips').add({
  name: 'Test Trip',
  baseCurrency: 'USD',
  createdAt: admin.firestore.FieldValue.serverTimestamp(),
  updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  isArchived: false,
  participants: []
});
```

**Invoke Function Locally**:
```bash
# Emulator URL
curl -X POST \
  http://localhost:5001/expense-tracker/us-central1/migrateTripCurrencies \
  -H "Authorization: Bearer test-secret" \
  -H "Content-Type: application/json"
```

**Verify**:
```typescript
const tripDoc = await db.collection('trips').doc(tripId).get();
const data = tripDoc.data();

console.log(data.allowedCurrencies);  // Should be ['USD']
```

### Unit Tests

**File**: `functions/test/migrations/migrate-trip-currencies.test.ts`

```typescript
import { expect } from 'chai';
import * as admin from 'firebase-admin';
import * as testing from '@firebase/rules-unit-testing';
import { runMigration } from '../../src/migrations/migrate-trip-currencies';

describe('migrateTripCurrencies', () => {
  let db: admin.firestore.Firestore;
  
  beforeEach(async () => {
    // Setup test environment
    const testEnv = await testing.initializeTestEnvironment({ ... });
    db = testEnv.firestore();
  });
  
  afterEach(async () => {
    await testing.clearFirestoreData({ ... });
  });
  
  it('migrates trip with baseCurrency to allowedCurrencies', async () => {
    // Create legacy trip
    const tripRef = await db.collection('trips').add({
      name: 'Legacy Trip',
      baseCurrency: 'USD',
      createdAt: admin.firestore.Timestamp.now(),
      updatedAt: admin.firestore.Timestamp.now(),
    });
    
    // Run migration
    const summary = await runMigration();
    
    // Verify
    expect(summary.successful).to.equal(1);
    expect(summary.failed).to.equal(0);
    
    const updatedDoc = await tripRef.get();
    const data = updatedDoc.data();
    expect(data.allowedCurrencies).to.deep.equal(['USD']);
  });
  
  it('skips trip already migrated', async () => {
    // Create already-migrated trip
    await db.collection('trips').add({
      name: 'New Trip',
      allowedCurrencies: ['EUR'],
      createdAt: admin.firestore.Timestamp.now(),
      updatedAt: admin.firestore.Timestamp.now(),
    });
    
    // Run migration
    const summary = await runMigration();
    
    // Verify (should not process any trips)
    expect(summary.totalTrips).to.equal(0);
  });
  
  it('handles trip missing baseCurrency', async () => {
    // Create corrupted trip (no baseCurrency)
    await db.collection('trips').add({
      name: 'Corrupted Trip',
      createdAt: admin.firestore.Timestamp.now(),
      updatedAt: admin.firestore.Timestamp.now(),
    });
    
    // Run migration
    const summary = await runMigration();
    
    // Verify
    expect(summary.failed).to.equal(1);
    expect(summary.results[0].reason).to.equal('missing baseCurrency field');
  });
  
  it('is idempotent (safe to re-run)', async () => {
    // Create legacy trip
    await db.collection('trips').add({
      name: 'Test Trip',
      baseCurrency: 'JPY',
      createdAt: admin.firestore.Timestamp.now(),
      updatedAt: admin.firestore.Timestamp.now(),
    });
    
    // Run migration twice
    const summary1 = await runMigration();
    const summary2 = await runMigration();
    
    // Verify: second run processes no trips
    expect(summary1.successful).to.equal(1);
    expect(summary2.totalTrips).to.equal(0);
  });
});
```

## Deployment

### Prerequisites

1. **Firebase CLI**: `npm install -g firebase-tools`
2. **Node.js**: v18+ (Cloud Functions runtime)
3. **TypeScript**: `npm install typescript --save-dev`
4. **Firebase Project**: Initialized with `firebase init functions`

### Setup

**File Structure**:
```
functions/
├── src/
│   ├── index.ts                  # Export all functions
│   └── migrations/
│       └── migrate-trip-currencies.ts
├── test/
│   └── migrations/
│       └── migrate-trip-currencies.test.ts
├── package.json
├── tsconfig.json
└── .env.local                     # Local secrets (not committed)
```

**package.json**:
```json
{
  "name": "functions",
  "scripts": {
    "build": "tsc",
    "deploy": "firebase deploy --only functions:migrateTripCurrencies",
    "test": "mocha --require ts-node/register test/**/*.test.ts"
  },
  "dependencies": {
    "firebase-admin": "^12.0.0",
    "firebase-functions": "^5.0.0"
  },
  "devDependencies": {
    "@firebase/rules-unit-testing": "^3.0.0",
    "@types/chai": "^4.3.0",
    "@types/mocha": "^10.0.0",
    "chai": "^4.3.0",
    "mocha": "^10.0.0",
    "ts-node": "^10.9.0",
    "typescript": "^5.0.0"
  }
}
```

**tsconfig.json**:
```json
{
  "compilerOptions": {
    "module": "commonjs",
    "target": "es2018",
    "outDir": "lib",
    "strict": true,
    "esModuleInterop": true
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "test"]
}
```

### Deploy to Firebase

**Step 1: Set Migration Secret**:
```bash
firebase functions:config:set migration.secret="your-secret-key-here"
```

**Step 2: Deploy Function**:
```bash
cd functions
npm install
npm run build
firebase deploy --only functions:migrateTripCurrencies
```

**Step 3: Verify Deployment**:
```bash
firebase functions:log --only migrateTripCurrencies
```

### Execute Migration

**Step 1: Get Function URL**:
```bash
firebase functions:config:get | grep migrateTripCurrencies
# Example output: https://us-central1-expense-tracker.cloudfunctions.net/migrateTripCurrencies
```

**Step 2: Invoke**:
```bash
curl -X POST \
  https://us-central1-expense-tracker.cloudfunctions.net/migrateTripCurrencies \
  -H "Authorization: Bearer your-secret-key-here" \
  -H "Content-Type: application/json"
```

**Step 3: Monitor Logs**:
```bash
firebase functions:log --only migrateTripCurrencies
```

**Step 4: Verify Results**:
```bash
# Check Firestore Console
# Verify all trips have allowedCurrencies field
```

## Rollback Plan

### If Migration Fails

**Scenario**: Function times out after migrating 50 of 150 trips.

**Solution**:
1. Check summary response (shows which trips succeeded)
2. Re-run function (idempotent - only processes remaining 100 trips)
3. Monitor logs for new failures

### If Migration Corrupts Data

**Scenario**: Migration sets invalid allowedCurrencies values.

**Solution**:
1. **Immediate**: Deploy hotfix to client app (TripModel.toDomain() falls back to baseCurrency)
2. **Short-term**: Write corrective Cloud Function to fix corrupted trips
3. **Long-term**: Re-run migration with fixed logic

**Backup Strategy** (optional):
- Before migration: Export Firestore trips collection to JSON
- Use `firebase-import-export` or Firestore export API
- Restore from backup if catastrophic failure

## Performance Considerations

### Scalability

**Small Projects** (<1000 trips):
- Single function invocation
- Completes in <1 minute
- No batching needed

**Large Projects** (1000-10,000 trips):
- Single invocation may timeout (9 min limit)
- Solution: Implement batching (process 500 trips per invocation)
- Use Firestore pagination (startAfter cursor)

**Very Large Projects** (>10,000 trips):
- Use Firebase Admin SDK script (not Cloud Function)
- Run from local machine or Cloud Run (no timeout)
- Process in batches of 500 with progress logging

### Cost

**Cloud Functions**:
- Invocations: 1 (free tier: 2M/month)
- Compute time: ~5 minutes for 150 trips (free tier: 400k GB-seconds/month)
- **Cost**: Free for typical project sizes

**Firestore**:
- Reads: 150 (one per trip)
- Writes: 150 (one per trip)
- **Cost**: ~$0.02 for 150 trips (first 50k ops/day free)

## Future Enhancements

1. **Dry Run Mode**: Simulate migration without writing
2. **Batch Processing**: Process in chunks to avoid timeout
3. **Progress Tracking**: Store progress in Firestore, resume if interrupted
4. **Notifications**: Send email/Slack notification when complete
5. **Rollback Command**: Revert migration (remove allowedCurrencies, restore baseCurrency)

---

**Contract Version**: 1.0 | **Created**: 2025-11-02 | **Status**: Draft
