# Firestore Schema Contract

**Version**: 1.0.0
**Date**: 2025-10-21
**Purpose**: Define Firestore collection structure, document schemas, and indexing strategy

## Collection Structure

```
/trips/{tripId}
  ├── /categories/{categoryId}
  ├── /fxRates/{rateId}
  ├── /expenses/{expenseId}
  └── /computed/
        ├── summary (document)
        ├── /netted/{nettedId}
        └── /minimalTransfers/{transferId}
```

---

## Top-Level Collections

### `/trips/{tripId}`

**Document ID**: Auto-generated (Firestore auto-ID)

**Schema**:
```json
{
  "name": "Vietnam 2025",
  "baseCurrency": "USD",
  "createdAt": "2025-10-21T10:00:00.000Z",
  "updatedAt": "2025-10-21T15:30:00.000Z"
}
```

**Field Types**:
- `name`: string (1-100 chars)
- `baseCurrency`: string enum ("USD" | "VND")
- `createdAt`: Timestamp
- `updatedAt`: Timestamp

**Indexes**: None required (queries by document ID only)

**Security Rules**:
```javascript
match /trips/{tripId} {
  allow read, write: if request.auth != null;  // MVP: any authenticated user
}
```

---

## Subcollections

### `/trips/{tripId}/categories/{categoryId}`

**Document ID**: Auto-generated or predefined (e.g., "meals", "transport")

**Schema**:
```json
{
  "name": "Meals",
  "icon": "restaurant",
  "color": "#FF5722"
}
```

**Field Types**:
- `name`: string (1-50 chars, unique per trip)
- `icon`: string (Material icon name, optional)
- `color`: string (hex #RRGGBB, optional)

**Indexes**: None required

**Security Rules**: Inherit from parent `/trips/{tripId}`

---

### `/trips/{tripId}/fxRates/{rateId}`

**Document ID**: Auto-generated (Firestore auto-ID)

**Schema**:
```json
{
  "date": "2025-10-15",
  "fromCurrency": "USD",
  "toCurrency": "VND",
  "rate": "23500.00",
  "source": "Manual",
  "createdAt": "2025-10-21T10:00:00.000Z"
}
```

**Field Types**:
- `date`: string (YYYY-MM-DD format, nullable for trip-level default)
- `fromCurrency`: string enum ("USD" | "VND")
- `toCurrency`: string enum ("USD" | "VND")
- `rate`: string (decimal as string, e.g., "23500.00")
- `source`: string enum ("Manual")
- `createdAt`: Timestamp

**Indexes**:
- Composite: `(fromCurrency ASC, toCurrency ASC, date DESC)` for rate lookup queries
- Single field: `date DESC` for filtering by date range

**Queries**:
```dart
// Get rate for USD→VND on specific date
collection('fxRates')
  .where('fromCurrency', isEqualTo: 'USD')
  .where('toCurrency', isEqualTo: 'VND')
  .where('date', isEqualTo: '2025-10-15')
  .limit(1)

// Get most recent rate for USD→VND (any date)
collection('fxRates')
  .where('fromCurrency', isEqualTo: 'USD')
  .where('toCurrency', isEqualTo: 'VND')
  .orderBy('date', descending: true)
  .limit(1)
```

**Security Rules**: Inherit from parent `/trips/{tripId}`

---

### `/trips/{tripId}/expenses/{expenseId}`

**Document ID**: Auto-generated (Firestore auto-ID)

**Schema**:
```json
{
  "date": "2025-10-20T00:00:00.000Z",
  "payerUserId": "tai",
  "currency": "VND",
  "amount": "500000.00",
  "description": "Dinner at Pho 24",
  "categoryId": "meals",
  "splitType": "Equal",
  "participants": {
    "tai": 1,
    "khiet": 1,
    "bob": 1,
    "ethan": 1
  },
  "createdAt": "2025-10-20T19:30:00.000Z",
  "updatedAt": "2025-10-20T19:30:00.000Z"
}
```

**Field Types**:
- `date`: Timestamp (date-only precision, time set to 00:00:00)
- `payerUserId`: string (participant ID)
- `currency`: string enum ("USD" | "VND")
- `amount`: string (decimal as string)
- `description`: string (0-200 chars, nullable)
- `categoryId`: string (foreign key to category, nullable)
- `splitType`: string enum ("Equal" | "Weighted")
- `participants`: map (userId → weight, number)
- `createdAt`: Timestamp
- `updatedAt`: Timestamp

**Indexes**:
- Composite: `(date DESC, payerUserId ASC)` for expense list with filters
- Single field: `categoryId ASC` for category-based filtering
- Single field: `createdAt DESC` for chronological sorting

**Queries**:
```dart
// Get all expenses for trip, sorted by date descending
collection('expenses')
  .orderBy('date', descending: true)

// Filter by payer
collection('expenses')
  .where('payerUserId', isEqualTo: 'tai')
  .orderBy('date', descending: true)

// Filter by category
collection('expenses')
  .where('categoryId', isEqualTo: 'meals')
  .orderBy('date', descending: true)
```

**Security Rules**: Inherit from parent `/trips/{tripId}`

**Cloud Function Triggers**:
```javascript
// Recalculate settlement when expense created/updated/deleted
exports.onExpenseWrite = functions.firestore
  .document('trips/{tripId}/expenses/{expenseId}')
  .onWrite(async (change, context) => {
    const tripId = context.params.tripId;
    await recomputeSettlement(tripId);
  });
```

---

## Computed Subcollections (Auto-Generated)

### `/trips/{tripId}/computed/summary` (Document)

**Document ID**: Fixed as "summary"

**Schema**:
```json
{
  "baseCurrency": "USD",
  "lastComputedAt": "2025-10-21T15:45:00.000Z",
  "personSummaries": {
    "tai": {
      "totalPaidBase": "150.00",
      "totalOwedBase": "100.00",
      "netBase": "50.00"
    },
    "khiet": {
      "totalPaidBase": "80.00",
      "totalOwedBase": "100.00",
      "netBase": "-20.00"
    },
    "bob": {
      "totalPaidBase": "70.00",
      "totalOwedBase": "100.00",
      "netBase": "-30.00"
    },
    "ethan": {
      "totalPaidBase": "0.00",
      "totalOwedBase": "0.00",
      "netBase": "0.00"
    }
  }
}
```

**Field Types**:
- `baseCurrency`: string enum ("USD" | "VND")
- `lastComputedAt`: Timestamp
- `personSummaries`: map (userId → PersonSummary object)
  - `totalPaidBase`: string (decimal)
  - `totalOwedBase`: string (decimal)
  - `netBase`: string (decimal, can be negative)

**Indexes**: None required (single document read)

**Security Rules**:
```javascript
match /trips/{tripId}/computed/summary {
  allow read: if request.auth != null;
  allow write: if false;  // Only Cloud Functions can write
}
```

---

### `/trips/{tripId}/computed/netted/{nettedId}`

**Document ID**: Auto-generated (Firestore auto-ID)

**Schema**:
```json
{
  "fromUserId": "khiet",
  "toUserId": "tai",
  "nettedBase": "20.00",
  "computedAt": "2025-10-21T15:45:00.000Z"
}
```

**Field Types**:
- `fromUserId`: string (participant ID)
- `toUserId`: string (participant ID)
- `nettedBase`: string (decimal, always > 0)
- `computedAt`: Timestamp

**Indexes**: None required (full collection scan acceptable for small datasets)

**Security Rules**: Read-only like `/computed/summary`

---

### `/trips/{tripId}/computed/minimalTransfers/{transferId}`

**Document ID**: Auto-generated (Firestore auto-ID)

**Schema**:
```json
{
  "fromUserId": "bob",
  "toUserId": "tai",
  "amountBase": "30.00",
  "computedAt": "2025-10-21T15:45:00.000Z"
}
```

**Field Types**:
- `fromUserId`: string (participant ID)
- `toUserId`: string (participant ID)
- `amountBase`: string (decimal, always > 0)
- `computedAt`: Timestamp

**Indexes**: None required

**Security Rules**: Read-only like `/computed/summary`

---

## Indexing Strategy

### Required Composite Indexes

Create via Firebase Console or `firestore.indexes.json`:

```json
{
  "indexes": [
    {
      "collectionGroup": "expenses",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "date", "order": "DESCENDING" },
        { "fieldPath": "payerUserId", "order": "ASCENDING" }
      ]
    },
    {
      "collectionGroup": "fxRates",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "fromCurrency", "order": "ASCENDING" },
        { "fieldPath": "toCurrency", "order": "ASCENDING" },
        { "fieldPath": "date", "order": "DESCENDING" }
      ]
    }
  ]
}
```

### Single-Field Indexes

Auto-created by Firestore:
- `expenses.categoryId`
- `expenses.createdAt`
- `fxRates.date`

---

## Security Rules (Complete)

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Helper: Check if user is authenticated (anonymous or full auth)
    function isAuthenticated() {
      return request.auth != null;
    }

    // Trips: Read/write if authenticated
    match /trips/{tripId} {
      allow read, write: if isAuthenticated();

      // Categories, fxRates, expenses: Inherit trip permissions
      match /{document=**} {
        allow read, write: if isAuthenticated();
      }

      // Computed data: Read-only (Cloud Functions write)
      match /computed/{document=**} {
        allow read: if isAuthenticated();
        allow write: if false;  // Only server can write
      }
    }
  }
}
```

**Future Enhancements** (post-MVP):
- Restrict write to trip participants only
- Role-based permissions (trip owner can delete, participants can add expenses)
- Validate expense inputs in security rules

---

## API Contracts (Cloud Functions)

### Callable Function: `getSettlement`

**Input**:
```json
{
  "tripId": "abc123def456"
}
```

**Output**:
```json
{
  "summary": {
    "baseCurrency": "USD",
    "personSummaries": { ... },
    "lastComputedAt": "2025-10-21T15:45:00.000Z"
  },
  "nettedDebts": [
    { "fromUserId": "khiet", "toUserId": "tai", "nettedBase": "20.00" }
  ],
  "minimalTransfers": [
    { "fromUserId": "bob", "toUserId": "tai", "amountBase": "30.00" }
  ]
}
```

**Errors**:
- `404`: Trip not found
- `500`: Calculation error (logged server-side)

---

### Firestore Trigger: `onExpenseWrite`

**Trigger**: `trips/{tripId}/expenses/{expenseId}` onCreate, onUpdate, onDelete

**Action**: Recompute and update `/trips/{tripId}/computed/` collections

**Logic**:
1. Fetch all expenses for `tripId`
2. Fetch all FX rates for `tripId`
3. Convert expenses to base currency
4. Calculate person summaries
5. Calculate netted debts
6. Calculate minimal transfers
7. Write to `/computed/` collections in transaction

**Error Handling**: Log errors, set `/computed/summary.error` field for client to detect

---

### Firestore Trigger: `onFxRateWrite`

**Trigger**: `trips/{tripId}/fxRates/{rateId}` onCreate, onUpdate, onDelete

**Action**: Same as `onExpenseWrite` (recalculate settlement)

---

## Data Migration Strategy

**Initial Seed** (per trip):
1. Create trip document
2. Seed 6 default categories
3. Initialize `/computed/summary` with empty personSummaries

**Version Upgrades**:
- Breaking schema changes require data migration Cloud Function
- Use Firestore batch writes (max 500 docs per batch)
- Version field in trip document tracks schema version

---

## Performance Optimization

### Read Optimization

- **Dashboard queries**: Single read of `/computed/summary` document
- **Expense list**: Use pagination (`limit(20).startAfter(lastDoc)`)
- **Caching**: Flutter app caches Firestore data, syncs on connection

### Write Optimization

- **Batch operations**: Group related writes (e.g., create trip + seed categories)
- **Transactions**: Use for settlement computation (atomic multi-doc write)
- **Offline persistence**: Enable Firestore offline cache for better UX

### Cost Optimization

- **Minimize reads**: Use snapshot listeners (real-time) instead of repeated queries
- **Index strategically**: Only create indexes for actual query patterns
- **Computed data**: Store pre-calculated settlements to avoid client-side re-computation

**Estimated Monthly Costs** (100 active trips, 1000 expenses/month):
- Reads: ~50,000 (dashboard views) = $0.18
- Writes: ~1,000 (expenses) + ~1,000 (settlements) = $0.54
- Storage: <1GB = $0.18
- **Total**: ~$1/month (well within free tier: 50K reads, 20K writes/day)

---

## Testing Contracts

### Firebase Emulator Suite

```bash
# Start emulators for local testing
firebase emulators:start --only firestore,functions

# Run integration tests against emulators
flutter test integration_test/ --dart-define=USE_FIREBASE_EMULATOR=true
```

### Sample Data (Test Fixtures)

```json
// Test trip with 3 expenses
{
  "tripId": "test-trip-001",
  "name": "Test Trip",
  "baseCurrency": "USD",
  "expenses": [
    { "amount": "100.00", "currency": "USD", "payerUserId": "tai", "participants": {"tai": 1, "khiet": 1} },
    { "amount": "200000.00", "currency": "VND", "payerUserId": "khiet", "participants": {"tai": 1, "khiet": 1, "bob": 1} },
    { "amount": "50.00", "currency": "USD", "payerUserId": "bob", "participants": {"bob": 1} }
  ],
  "fxRates": [
    { "fromCurrency": "USD", "toCurrency": "VND", "rate": "23500.00" }
  ]
}

// Expected settlement:
// tai paid $100, owes $50 (half of $100) + ~$2.84 (1/3 of 200K VND) = net ~$47.16
// khiet paid ~$8.51 (200K VND), owes $50 + ~$2.84 = net ~-$44.33
// bob paid $50, owes ~$2.84 = net ~$47.16
```

---

## Constitutional Compliance

✅ **Principle I (TDD)**: All Firestore operations covered by integration tests
✅ **Principle II (Code Quality)**: Schema clearly documented, types enforced
✅ **Principle IV (Performance)**: Indexing strategy optimizes query performance
✅ **Principle V (Data Integrity)**: Security rules prevent unauthorized writes, transactions ensure atomicity
