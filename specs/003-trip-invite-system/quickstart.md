# Quickstart Guide: Trip Invite System

**Version**: 1.0.0
**Date**: 2025-10-28
**Purpose**: Quick reference for using and testing the trip invite system

## For Users

### How to Create a Private Trip

1. **Open the app** → Navigate to trip list (`/trips`)
2. **Tap "Create Trip"** button
3. **Enter trip details**:
   - Trip name (e.g., "Vietnam 2025")
   - Base currency (USD or VND)
4. **Provide your name** when prompted (first time only)
5. **Tap "Create Trip"**

**Result**:
- You are automatically added as the first member
- Trip appears in your trip list
- Invite code (trip ID) is generated automatically

---

### How to Share a Trip Invite

#### Method 1: Shareable Link (Recommended)

1. **Open trip settings** → Tap on trip → Tap settings icon
2. **Tap "Invite Friends"** button
3. **Choose sharing method**:
   - **Copy Link**: Copies invite link to clipboard
   - **Share**: Opens native share dialog (SMS, email, WhatsApp, etc.)
4. **Send the link** to your friends

**Link Format**: `https://taihartman.github.io/expense_tracker/#/trips/[TRIP_ID]/join`

**Example**: `https://taihartman.github.io/expense_tracker/#/trips/Abc123XyzDef456Ghi/join`

#### Method 2: Manual Code Sharing

1. **Open trip settings** → Tap on trip → Tap settings icon
2. **Tap "Invite Friends"** button
3. **Copy the invite code** (20-character string)
4. **Send the code** via any messaging app

**Example Code**: `Abc123XyzDef456Ghi`

---

### How to Join a Trip

#### Method 1: Click Shareable Link (Easiest)

1. **Click the invite link** sent by your friend
2. **Enter your name** when prompted
3. **Tap "Join Trip"**

**Result**:
- You are added to the trip's member list
- Trip appears in your trip list
- You can now view and add expenses

#### Method 2: Manual Code Entry

1. **Open the app** → Navigate to trip list (`/trips`)
2. **Tap "Join Trip"** button (floating action button)
3. **Enter the invite code** (paste or type)
4. **Enter your name**
5. **Tap "Join Trip"**

**Result**: Same as Method 1

---

### How to View Activity Log

1. **Open trip settings** → Tap on trip → Tap settings icon
2. **Tap "Activity" tab** (if tabbed interface) or scroll down
3. **View recent actions**:
   - Who created the trip
   - Who joined when
   - Who added/edited/deleted expenses

**Log Format**:
- `Tai joined the trip` - 2 hours ago
- `Khiet added expense "Dinner at Pho 24"` - 1 hour ago
- `Bob edited expense "Taxi to airport"` - 30 minutes ago

---

## For Developers

### Prerequisites

Before implementing this feature, ensure you have:

1. **Flutter SDK 3.9.0+** installed
2. **Firebase project** configured with Firestore and Authentication
3. **Dependencies** in `pubspec.yaml`:
   - `cloud_firestore: ^5.5.0`
   - `firebase_auth: ^5.3.2`
   - `flutter_bloc: ^8.1.6`
   - `go_router: ^14.6.2`

4. **Existing codebase** with:
   - Trip feature (TripCubit, TripRepository)
   - Expense feature (ExpenseCubit, ExpenseRepository)
   - Firestore service wrapper
   - LocalStorageService (SharedPreferences)

---

### Quick Setup (15 Minutes)

#### Step 1: Create ActivityLog Model (5 minutes)

**File**: `lib/features/trips/domain/models/activity_log.dart`

```dart
enum ActivityType {
  tripCreated,
  memberJoined,
  expenseAdded,
  expenseEdited,
  expenseDeleted,
}

class ActivityLog {
  final String id;
  final String tripId;
  final String actorName;
  final ActivityType type;
  final String description;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  ActivityLog({
    required this.id,
    required this.tripId,
    required this.actorName,
    required this.type,
    required this.description,
    required this.timestamp,
    this.metadata,
  });
}
```

#### Step 2: Create ActivityLogRepository (5 minutes)

**File**: `lib/features/trips/domain/repositories/activity_log_repository.dart`

```dart
abstract class ActivityLogRepository {
  Future<void> addLog(ActivityLog log);
  Stream<List<ActivityLog>> getActivityLogs(String tripId, {int limit = 50});
}
```

**Implementation**: See `contracts/firestore-schema.md` for details

#### Step 3: Add Routes (3 minutes)

**File**: `lib/core/router/app_router.dart`

```dart
// Add these routes
GoRoute(
  path: '/trips/join',
  name: 'tripJoin',
  builder: (context, state) => const TripJoinPage(),
),
GoRoute(
  path: '/trips/:tripId/join',
  name: 'tripJoinDirect',
  builder: (context, state) {
    final tripId = state.pathParameters['tripId'];
    return TripJoinPage(inviteCode: tripId);
  },
),
GoRoute(
  path: '/trips/:tripId/invite',
  name: 'tripInvite',
  builder: (context, state) {
    final tripId = state.pathParameters['tripId']!;
    return TripInvitePage(tripId: tripId);
  },
),
```

#### Step 4: Update Firestore Security Rules (2 minutes)

**File**: `firestore.rules`

```javascript
match /trips/{tripId}/activityLog/{logId} {
  allow read: if request.auth != null;
  allow create: if request.auth != null && request.resource.data.timestamp == request.time;
  allow update, delete: if false;  // Immutable
}
```

**Deploy**: `firebase deploy --only firestore:rules`

---

### Testing Checklist

#### Unit Tests

- [ ] `ActivityLog` model serialization/deserialization
- [ ] `ActivityLogRepository.addLog()` creates Firestore document
- [ ] `ActivityLogRepository.getActivityLogs()` streams logs in order
- [ ] `TripCubit.joinTrip()` adds participant and creates log entry
- [ ] `TripCubit.joinTrip()` is idempotent (already member)
- [ ] `TripCubit.loadTrips()` filters to joined trips only
- [ ] `ExpenseCubit.createExpense()` logs activity
- [ ] `ExpenseCubit.updateExpense()` logs activity
- [ ] `ExpenseCubit.deleteExpense()` logs activity

#### Widget Tests

- [ ] `TripJoinPage` renders form with code and name inputs
- [ ] `TripJoinPage` shows error message for invalid code
- [ ] `TripJoinPage` pre-fills code when provided via deep link
- [ ] `TripInvitePage` displays invite code correctly
- [ ] `TripInvitePage` copy button copies code to clipboard
- [ ] `ActivityLogList` renders list of log entries
- [ ] `ActivityLogList` shows empty state when no logs
- [ ] `TripListPage` shows "Join Trip" button

#### Integration Tests

- [ ] End-to-end: User joins trip via shareable link
- [ ] End-to-end: User joins trip via manual code entry
- [ ] End-to-end: Member shares trip invite
- [ ] End-to-end: Non-member redirected to join page
- [ ] End-to-end: Activity log updates in real-time when expense added
- [ ] Backward compatibility: Existing trips work as invite codes

#### Manual Testing

- [ ] Create trip → Verify auto-added as member
- [ ] Join trip via link → Verify added to members → Verify log entry
- [ ] Join trip via code → Verify same as link
- [ ] Try to join same trip twice → Verify idempotent (no duplicate)
- [ ] Share trip → Copy code → Paste in another browser → Join successfully
- [ ] Share trip → Native share dialog opens
- [ ] Add expense → Verify activity log entry created
- [ ] Edit expense → Verify activity log entry created
- [ ] Delete expense → Verify activity log entry created
- [ ] View activity log → Verify chronological order
- [ ] Clear browser cache → Verify must rejoin trips

---

### Common Issues & Solutions

#### Issue 1: "Trip not found" when joining

**Symptoms**: Error message when entering valid-looking code

**Causes**:
- Typo in invite code
- Trip was deleted
- Firestore security rules blocking read access

**Solutions**:
1. Double-check invite code (case-sensitive, 20 characters)
2. Verify trip exists in Firestore console
3. Check Firestore rules: `allow read: if request.auth != null;`
4. Ensure user is authenticated (anonymous auth)

---

#### Issue 2: Activity log not updating in real-time

**Symptoms**: Log entries don't appear until page refresh

**Causes**:
- Firestore stream not set up correctly
- ActivityLogCubit not subscribed to stream
- Firestore offline persistence disabled

**Solutions**:
1. Verify `getActivityLogs()` returns a stream, not a future
2. Check `ActivityLogCubit` subscribes to stream in `loadActivityLogs()`
3. Ensure Firestore persistence enabled in `main.dart`:
   ```dart
   FirebaseFirestore.instance.settings = const Settings(
     persistenceEnabled: true,
   );
   ```

---

#### Issue 3: Trips disappear after clearing browser cache

**Symptoms**: User's trip list is empty after clearing cache

**Expected Behavior**: This is by design (anonymous auth limitation)

**Solutions**:
- Document in user guide: "You'll need to rejoin trips if you clear browser data"
- Future enhancement: Add email/password auth to persist membership

---

#### Issue 4: Cannot access trip after joining

**Symptoms**: Redirected to join page even after joining successfully

**Causes**:
- Joined trip ID not saved to LocalStorageService
- TripCubit not reloaded after join

**Solutions**:
1. Verify `TripCubit.joinTrip()` calls `_localStorageService.addJoinedTrip(tripId)`
2. Ensure `loadTrips()` called after join to refresh list
3. Check LocalStorageService properly saves to SharedPreferences

---

### Performance Optimization Tips

#### 1. Limit Activity Log Queries

```dart
// Load only 50 most recent entries
_activityLogRepository.getActivityLogs(tripId, limit: 50)
```

#### 2. Cache Membership Checks

```dart
// In TripCubit, cache joined trip IDs in memory
List<String> _cachedJoinedIds = [];

Future<bool> isUserMemberOf(String tripId) async {
  if (_cachedJoinedIds.isEmpty) {
    _cachedJoinedIds = await _localStorageService.getJoinedTripIds();
  }
  return _cachedJoinedIds.contains(tripId);
}
```

#### 3. Use Firestore Cache

```dart
// Enable offline persistence for faster reads
FirebaseFirestore.instance.settings = const Settings(
  persistenceEnabled: true,
  cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
);
```

#### 4. Debounce Real-Time Updates

```dart
// Throttle activity log stream updates
_activityLogRepository
    .getActivityLogs(tripId)
    .debounceTime(Duration(milliseconds: 500))
    .listen(...);
```

---

### Deployment

#### 1. Update Firestore Rules

```bash
firebase deploy --only firestore:rules
```

#### 2. Build Flutter Web

```bash
flutter build web --base-href /expense_tracker/
```

#### 3. Deploy to GitHub Pages

```bash
# Automatic via GitHub Actions on push to master
git push origin 003-trip-invite-system
```

#### 4. Verify Deployment

```bash
# Test deep linking
open "https://taihartman.github.io/expense_tracker/#/trips/test123/join"
```

---

## Quick Reference

### Key Files

**Models**:
- `lib/features/trips/domain/models/activity_log.dart`

**Repositories**:
- `lib/features/trips/domain/repositories/activity_log_repository.dart`
- `lib/features/trips/data/repositories/activity_log_repository_impl.dart`

**Cubits**:
- `lib/features/trips/presentation/cubits/activity_log_cubit.dart`
- `lib/features/trips/presentation/cubits/trip_cubit.dart` (modified)

**Pages**:
- `lib/features/trips/presentation/pages/trip_join_page.dart`
- `lib/features/trips/presentation/pages/trip_invite_page.dart`

**Widgets**:
- `lib/features/trips/presentation/widgets/activity_log_list.dart`

**Config**:
- `lib/core/router/app_router.dart` (routes)
- `firestore.rules` (security)
- `lib/l10n/app_en.arb` (strings)

### Key Commands

```bash
# Run app
flutter run -d chrome

# Run tests
flutter test

# Run specific test
flutter test test/features/trips/presentation/cubits/trip_cubit_test.dart

# Analyze code
flutter analyze

# Format code
flutter format .

# Build for production
flutter build web --base-href /expense_tracker/

# Deploy Firestore rules
firebase deploy --only firestore:rules
```

### Key Routes

- `/trips` - Trip list
- `/trips/join` - Join trip (manual code entry)
- `/trips/:tripId/join` - Join trip (deep link)
- `/trips/:tripId/invite` - Show invite code/share
- `/trips/:tripId/settings` - Trip settings (includes activity log)

### Key Functions

```dart
// Join trip
await context.read<TripCubit>().joinTrip(tripId, userName);

// Check membership
final isMember = await context.read<TripCubit>().isUserMemberOf(tripId);

// Load activity logs
await context.read<ActivityLogCubit>().loadActivityLogs(tripId);

// Generate shareable link
final link = generateShareableLink(tripId);

// Log activity
await _activityLogRepository.addLog(ActivityLog(...));
```

---

## Next Steps

After completing this quickstart:

1. **Read contracts** for detailed schemas:
   - `contracts/firestore-schema.md`
   - `contracts/cubit-contracts.md`
   - `contracts/routing-contracts.md`

2. **Review data model**: `data-model.md`

3. **Review research decisions**: `research.md`

4. **Generate tasks**: Run `/speckit.tasks` to create implementation checklist

5. **Start implementation**: Follow TDD approach (write tests first!)

---

## Support

**Documentation**: See `specs/003-trip-invite-system/` directory

**Issues**: Report at https://github.com/taihartman/expense_tracker/issues

**Questions**: Check `research.md` for technical decisions and rationale
