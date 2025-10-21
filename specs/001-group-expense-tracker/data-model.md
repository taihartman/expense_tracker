# Data Model: Group Expense Tracker for Trips

**Phase**: 1 (Design & Contracts)
**Date**: 2025-10-21
**Status**: Complete

## Overview

This document defines the domain entities and their relationships for the expense tracker application. All monetary values use Decimal type (stored as strings in Firestore) per constitutional requirements.

## Domain Entities

### Trip

**Purpose**: Represents a travel event with associated expenses and participants

**Fields**:
- `id`: String (unique identifier, auto-generated)
- `name`: String (user-provided trip name, e.g., "Vietnam 2025")
- `baseCurrency`: CurrencyCode enum (USD | VND)
- `createdAt`: DateTime (ISO 8601 timestamp)
- `updatedAt`: DateTime (ISO 8601 timestamp)

**Validation Rules**:
- `name`: Required, 1-100 characters, non-empty after trim
- `baseCurrency`: Required, must be USD or VND
- `createdAt`: Auto-set on creation, immutable
- `updatedAt`: Auto-set on creation/update

**Relationships**:
- One-to-many with Expense (trip → expenses)
- One-to-many with ExchangeRate (trip → rates)
- One-to-many with Category (trip → categories)
- One-to-one with SettlementSummary (trip → computed settlement)

**State Transitions**:
- Created → Active (immediately on creation)
- Active → Active (on updates)
- No deletion in MVP (future: Active → Archived)

---

### Participant

**Purpose**: Represents a person who can pay for or owe expenses (MVP: fixed list)

**Fields**:
- `id`: String (unique identifier, e.g., "tai", "khiet", "bob")
- `name`: String (display name, e.g., "Tai", "Khiet", "Bob")

**MVP Fixed List**:
```dart
const participants = [
  Participant(id: 'tai', name: 'Tai'),
  Participant(id: 'khiet', name: 'Khiet'),
  Participant(id: 'bob', name: 'Bob'),
  Participant(id: 'ethan', name: 'Ethan'),
  Participant(id: 'ryan', name: 'Ryan'),
  Participant(id: 'izzy', name: 'Izzy'),
];
```

**Validation Rules**:
- `id`: Required, lowercase alphanumeric
- `name`: Required, 1-50 characters

**Future Extension**: User entity with authentication (post-MVP)

---

### Expense

**Purpose**: Represents a single payment made by one participant

**Fields**:
- `id`: String (unique identifier, auto-generated)
- `tripId`: String (foreign key to Trip)
- `date`: DateTime (when expense occurred, date-only precision)
- `payerUserId`: String (participant ID who paid)
- `currency`: CurrencyCode enum (USD | VND)
- `amount`: Decimal (stored as string, e.g., "123.45")
- `description`: String? (optional, user note, e.g., "Dinner at Pho 24")
- `categoryId`: String? (optional, foreign key to Category)
- `splitType`: SplitType enum (Equal | Weighted)
- `participants`: Map<String, num> (userId → weight, weight=1 for Equal split)
- `createdAt`: DateTime (ISO 8601 timestamp)
- `updatedAt`: DateTime (ISO 8601 timestamp)

**Validation Rules**:
- `date`: Required, cannot be in future
- `payerUserId`: Required, must be valid participant ID
- `amount`: Required, > 0, max 12 digits + 2 decimals
- `description`: Optional, max 200 characters
- `splitType`: Required, Equal or Weighted
- `participants`: Required, at least 1 participant, all must be valid participant IDs
- `participants` (Equal): All weights = 1
- `participants` (Weighted): All weights > 0, sum > 0

**Relationships**:
- Many-to-one with Trip (expenses → trip)
- Many-to-one with Category (expenses → category)
- Logical relationship with Participants (via `payerUserId` and `participants` map)

**Derived Values** (computed, not stored):
- `baseAmount`: Decimal (amount converted to trip base currency via FX rates)
- `shares`: Map<String, Decimal> (userId → amount owed, calculated from splitType)

**State Transitions**:
- None (immutable after creation in MVP)
- Future: Allow edits with audit trail

---

### ExchangeRate

**Purpose**: Represents currency conversion rate for a trip

**Fields**:
- `id`: String (unique identifier, auto-generated)
- `tripId`: String (foreign key to Trip)
- `date`: DateTime? (optional, when rate is effective; null = trip-level default)
- `fromCurrency`: CurrencyCode enum (USD | VND)
- `toCurrency`: CurrencyCode enum (USD | VND)
- `rate`: Decimal (stored as string, e.g., "23500.00" for USD→VND)
- `source`: RateSource enum (Manual in MVP)
- `createdAt`: DateTime (ISO 8601 timestamp)

**Validation Rules**:
- `fromCurrency` ≠ `toCurrency` (no self-conversion)
- `rate`: Required, > 0, max 12 digits + 6 decimals
- `source`: Required, must be "Manual" in MVP
- Unique constraint: (tripId, date, fromCurrency, toCurrency)

**Relationships**:
- Many-to-one with Trip (rates → trip)

**Conversion Logic** (not stored, applied at runtime):
1. Exact match: `(tripId, date, from, to)` → use rate
2. Date fallback: `(tripId, any date, from, to)` → use most recent rate
3. Reciprocal: `(tripId, date, to, from)` exists → use 1/rate
4. Same currency: from == to → rate = 1.0
5. No match: Error (prompt user to enter rate)

---

### Category

**Purpose**: Classifies expenses for spending analysis

**Fields**:
- `id`: String (unique identifier, auto-generated or predefined)
- `tripId`: String (foreign key to Trip)
- `name`: String (display name, e.g., "Meals", "Transport")
- `icon`: String? (optional, Material icon name, e.g., "restaurant", "directions_car")
- `color`: String? (optional, hex color code, e.g., "#FF5722")

**Validation Rules**:
- `name`: Required, 1-50 characters, unique per trip
- `icon`: Optional, must be valid Material icon name if provided
- `color`: Optional, must be valid hex color (#RRGGBB) if provided

**Relationships**:
- Many-to-one with Trip (categories → trip)
- One-to-many with Expense (category → expenses)

**MVP Pre-seeded Categories** (per trip):
```dart
const defaultCategories = [
  Category(name: 'Meals', icon: 'restaurant', color: '#FF5722'),
  Category(name: 'Transport', icon: 'directions_car', color: '#2196F3'),
  Category(name: 'Accommodation', icon: 'hotel', color: '#4CAF50'),
  Category(name: 'Activities', icon: 'attractions', color: '#9C27B0'),
  Category(name: 'Shopping', icon: 'shopping_cart', color: '#FFC107'),
  Category(name: 'Other', icon: 'more_horiz', color: '#757575'),
];
```

---

### SettlementSummary (Computed)

**Purpose**: Aggregates per-person financial summary for a trip

**Fields**:
- `tripId`: String (foreign key to Trip, also document ID)
- `baseCurrency`: CurrencyCode enum (matches trip base currency)
- `personSummaries`: Map<String, PersonSummary>
- `lastComputedAt`: DateTime (when Cloud Function last ran)

**PersonSummary Structure**:
```dart
class PersonSummary {
  String userId;
  Decimal totalPaidBase;    // Sum of expenses where user is payer (in base currency)
  Decimal totalOwedBase;    // Sum of shares where user is participant (in base currency)
  Decimal netBase;          // totalPaidBase - totalOwedBase (positive = owed money, negative = owes money)
}
```

**Validation Rules**:
- Auto-generated by Cloud Function (not user-editable)
- `personSummaries`: Includes all participants who appear in any expense
- Sum of all `netBase` values MUST = 0 (conservation of money)

**Relationships**:
- One-to-one with Trip (settlement → trip)

---

### PairwiseDebt (Computed)

**Purpose**: Represents netted debt between two participants

**Fields**:
- `id`: String (unique identifier, auto-generated)
- `tripId`: String (foreign key to Trip)
- `fromUserId`: String (participant who owes)
- `toUserId`: String (participant who is owed)
- `nettedBase`: Decimal (amount owed in base currency, always > 0)
- `computedAt`: DateTime (when Cloud Function computed this)

**Validation Rules**:
- Auto-generated by Cloud Function (not user-editable)
- `nettedBase`: Always > 0 (zero debts not stored)
- `fromUserId` ≠ `toUserId` (no self-debt)
- Unique constraint: (tripId, fromUserId, toUserId)
- Directional: only store one direction (e.g., if A owes B, store (A→B), not (B→A))

**Computation Logic**:
1. Build matrix: debt[A][B] = sum of (expense shares where A owes B)
2. Net: netted[A][B] = debt[A][B] - debt[B][A]
3. Store: if netted[A][B] > 0, store (A→B, amount); discard zero/negative

**Relationships**:
- Many-to-one with Trip (debts → trip)

---

### MinimalTransfer (Computed)

**Purpose**: Optimal settlement plan minimizing number of transfers

**Fields**:
- `id`: String (unique identifier, auto-generated)
- `tripId`: String (foreign key to Trip)
- `fromUserId`: String (participant who pays)
- `toUserId`: String (participant who receives)
- `amountBase`: Decimal (transfer amount in base currency, always > 0)
- `computedAt`: DateTime (when Cloud Function computed this)

**Validation Rules**:
- Auto-generated by Cloud Function (not user-editable)
- `amountBase`: Always > 0
- `fromUserId` ≠ `toUserId`
- No constraints on count (algorithm minimizes automatically)

**Computation Algorithm** (Greedy Matching):
```
1. Build balances: Map<userId, netBalance> from PersonSummary
2. Split into creditors (net > 0) and debtors (net < 0)
3. While creditors and debtors exist:
   a. Pick largest creditor (most owed)
   b. Pick largest debtor (owes most)
   c. transferAmount = min(creditor.balance, abs(debtor.balance))
   d. Create transfer: debtor → creditor, transferAmount
   e. Update balances: creditor -= transferAmount, debtor += transferAmount
   f. Remove creditors/debtors with balance ~= 0
4. Store all transfers
```

**Relationships**:
- Many-to-one with Trip (transfers → trip)

---

## Enumerations

### CurrencyCode

```dart
enum CurrencyCode {
  USD,  // United States Dollar (decimals: 2)
  VND,  // Vietnamese Dong (decimals: 0)
}
```

### SplitType

```dart
enum SplitType {
  Equal,     // Divide evenly among participants
  Weighted,  // Divide proportionally by custom weights
}
```

### RateSource

```dart
enum RateSource {
  Manual,    // User-entered (MVP only)
  // Future: API (OpenExchangeRates, Fixer.io, etc.)
}
```

---

## Entity Relationship Diagram

```
Trip (1) ──────┬──── (many) Expense
               │
               ├──── (many) ExchangeRate
               │
               ├──── (many) Category
               │
               └──── (1) SettlementSummary
                            │
                            ├──── (embedded) PersonSummary (many)
                            │
                            └──── (many) PairwiseDebt
                            │
                            └──── (many) MinimalTransfer

Participant (fixed list, no DB storage in MVP)
    │
    └──── Referenced by: Expense.payerUserId, Expense.participants
```

---

## Validation Summary

**Client-Side Validation** (Flutter UI):
- Form input validation (required fields, format, ranges)
- Real-time feedback (error messages on input change)
- Prevent submission if invalid

**Server-Side Validation** (Cloud Functions):
- Re-validate all inputs (never trust client)
- Enforce referential integrity (trip exists, participant exists)
- Atomicity (Firestore transactions for multi-document operations)

**Constitutional Compliance**:
- ✅ Decimal type for all monetary values (Principle V)
- ✅ All inputs validated client AND server (Principle V)
- ✅ Atomicity via transactions (Principle V)
- ✅ Audit trail via timestamps (Principle V)

---

## Storage Mapping (Firestore)

See [contracts/firestore-schema.md](contracts/firestore-schema.md) for detailed Firestore collection structure and indexing strategy.
