# Routing Contracts: Trip Invite System

**Version**: 1.0.0
**Date**: 2025-10-28
**Purpose**: Define routing structure, deep linking, navigation guards, and route transitions for trip invite system

## Router Overview

**Router**: `go_router` ^14.6.2
**Configuration File**: `lib/core/router/app_router.dart`

---

## New Routes

### 1. Trip Join Page (Manual Code Entry)

**Route Path**: `/trips/join`
**Route Name**: `tripJoin`

**Purpose**: Allow users to manually enter an invite code to join a trip

**Parameters**: None (user enters code in form)

**Page**: `TripJoinPage`

**Configuration**:
```dart
GoRoute(
  path: '/trips/join',
  name: 'tripJoin',
  builder: (context, state) => const TripJoinPage(),
),
```

**Access**: Public (no authentication guard, but requires anonymous Firebase auth)

**Navigation Example**:
```dart
context.goNamed('tripJoin');
// or
context.go('/trips/join');
```

---

### 2. Trip Join Page (Deep Link with Code)

**Route Path**: `/trips/:tripId/join`
**Route Name**: `tripJoinDirect`

**Purpose**: One-click joining via shareable link (pre-fills invite code)

**Parameters**:
- `tripId` (path parameter): The invite code/trip ID to join

**Query Parameters**: None

**Page**: `TripJoinPage` (same page, different entry point)

**Configuration**:
```dart
GoRoute(
  path: '/trips/:tripId/join',
  name: 'tripJoinDirect',
  builder: (context, state) {
    final tripId = state.pathParameters['tripId'];
    return TripJoinPage(inviteCode: tripId);
  },
),
```

**Access**: Public (no authentication guard)

**Navigation Example**:
```dart
context.goNamed('tripJoinDirect', pathParameters: {'tripId': 'abc123xyz'});
// or
context.go('/trips/abc123xyz/join');
```

**Shareable Link Format**:
```
https://taihartman.github.io/expense_tracker/#/trips/abc123xyz/join
```

---

### 3. Trip Invite Page

**Route Path**: `/trips/:tripId/invite`
**Route Name**: `tripInvite`

**Purpose**: Show trip invite code, copy button, share button for existing members

**Parameters**:
- `tripId` (path parameter): The trip to show invite details for

**Page**: `TripInvitePage`

**Configuration**:
```dart
GoRoute(
  path: '/trips/:tripId/invite',
  name: 'tripInvite',
  builder: (context, state) {
    final tripId = state.pathParameters['tripId']!;
    return TripInvitePage(tripId: tripId);
  },
  redirect: (context, state) async {
    final tripId = state.pathParameters['tripId'];
    if (tripId == null) return '/trips';

    // Guard: Only members can access invite page
    final tripCubit = context.read<TripCubit>();
    final isMember = await tripCubit.isUserMemberOf(tripId);
    if (!isMember) {
      return '/trips/$tripId/join';  // Redirect to join page
    }
    return null;  // Allow navigation
  },
),
```

**Access**: Members only (guarded by membership check)

**Navigation Example**:
```dart
context.goNamed('tripInvite', pathParameters: {'tripId': tripId});
// or
context.go('/trips/$tripId/invite');
```

---

## Modified Routes

### Trip Settings Page (Add Activity Log Tab)

**Route Path**: `/trips/:tripId/settings` (existing)
**Modification**: Add tab navigation for activity log

**Page**: `TripSettingsPage` (modified to include activity log tab)

**Configuration**: No route changes, only UI changes within page

**Navigation Example** (existing):
```dart
context.goNamed('tripSettings', pathParameters: {'tripId': tripId});
```

---

## Navigation Guards

### Membership Guard

**Purpose**: Redirect non-members to join page when accessing member-only routes

**Implementation**:
```dart
Future<String?> membershipGuard(BuildContext context, GoRouterState state, String tripId) async {
  final tripCubit = context.read<TripCubit>();
  final isMember = await tripCubit.isUserMemberOf(tripId);

  if (!isMember) {
    return '/trips/$tripId/join';  // Redirect to join page
  }

  return null;  // Allow navigation
}
```

**Applied to**:
- `/trips/:tripId/expenses` (existing)
- `/trips/:tripId/expenses/create` (existing)
- `/trips/:tripId/settings` (existing)
- `/trips/:tripId/settlement` (existing)
- `/trips/:tripId/invite` (new)

**Example Usage**:
```dart
GoRoute(
  path: '/trips/:tripId/expenses',
  name: 'tripExpenses',
  redirect: (context, state) async {
    final tripId = state.pathParameters['tripId'];
    if (tripId == null) return '/trips';
    return await membershipGuard(context, state, tripId);
  },
  builder: (context, state) {
    final tripId = state.pathParameters['tripId']!;
    return ExpenseListPage(tripId: tripId);
  },
),
```

---

## Route Hierarchy

### Updated Route Tree

```
/ (HomePage - expense list for selected trip)
│
├── /trips (TripListPage)
│   │
│   ├── /trips/create (TripCreatePage)
│   │
│   ├── /trips/join (TripJoinPage - manual code entry) [NEW]
│   │
│   └── /trips/:tripId/
│       │
│       ├── /trips/:tripId/join (TripJoinPage - deep link) [NEW]
│       │
│       ├── /trips/:tripId/invite (TripInvitePage - show code/share) [NEW] [GUARDED]
│       │
│       ├── /trips/:tripId/edit (TripEditPage) [GUARDED]
│       │
│       ├── /trips/:tripId/settings (TripSettingsPage + Activity Log) [GUARDED]
│       │
│       ├── /trips/:tripId/expenses (ExpenseListPage) [GUARDED]
│       │   │
│       │   ├── /trips/:tripId/expenses/create (ExpenseFormPage) [GUARDED]
│       │   └── /trips/:tripId/expenses/:expenseId/edit (ExpenseFormPage) [GUARDED]
│       │
│       └── /trips/:tripId/settlement (SettlementSummaryPage) [GUARDED]
```

**Key**: `[NEW]` = New route, `[GUARDED]` = Membership guard applied

---

## Deep Linking

### URL Structure

**Base URL**: `https://taihartman.github.io/expense_tracker/`
**Hash Routing**: Enabled (Flutter web default)

**Shareable Link Format**:
```
https://taihartman.github.io/expense_tracker/#/trips/[TRIP_ID]/join
```

**Example**:
```
https://taihartman.github.io/expense_tracker/#/trips/Abc123XyzDef456Ghi/join
```

### Link Generation

**Function**: `generateShareableLink(String tripId)`

**Implementation**:
```dart
String generateShareableLink(String tripId) {
  const baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'https://taihartman.github.io/expense_tracker',
  );
  return '$baseUrl/#/trips/$tripId/join';
}
```

**Usage**:
```dart
// In TripInvitePage
final shareLink = generateShareableLink(tripId);
Share.share('Join my trip: $shareLink');
```

### URL Parameter Extraction

**go_router Automatic Extraction**:
```dart
// In route builder
final tripId = state.pathParameters['tripId'];  // Extracted automatically
```

**Validation**:
```dart
if (tripId == null || tripId.isEmpty) {
  return '/trips';  // Redirect to trip list
}
```

---

## Navigation Flows

### 1. New User Joins via Shareable Link

```
[Click Link] https://.../#/trips/abc123/join
    │
    ▼
[go_router] Navigates to TripJoinPage(inviteCode: 'abc123')
    │
    ▼
[TripJoinPage] Pre-fills code, prompts for name
    │
    ▼
[User enters name] "Tai"
    │
    ▼
[TripCubit.joinTrip('abc123', 'Tai')]
    │
    ├─► Success ──► [TripJoined state]
    │                   │
    │                   ▼
    │               [Navigate to] /trips/abc123/expenses
    │
    └─► Failure ──► [TripJoinError state] ──► Show error, stay on page
```

**Code**:
```dart
// In TripJoinPage
BlocListener<TripCubit, TripState>(
  listener: (context, state) {
    if (state is TripJoined) {
      context.go('/trips/${state.trip.id}/expenses');
    } else if (state is TripJoinError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.message)),
      );
    }
  },
  // ...
);
```

---

### 2. Existing Member Shares Trip

```
[Member on Trip Settings] /trips/abc123/settings
    │
    ▼
[Tap "Invite Friends" button]
    │
    ▼
[Navigate to] /trips/abc123/invite
    │
    ▼
[TripInvitePage] Shows code: abc123, copy button, share button
    │
    ├─► [Tap Copy] ──► Copy code to clipboard
    │
    └─► [Tap Share] ──► Open native share dialog with link
```

**Code**:
```dart
// In TripSettingsPage
ElevatedButton(
  onPressed: () => context.go('/trips/$tripId/invite'),
  child: Text('Invite Friends'),
);

// In TripInvitePage - Copy button
IconButton(
  icon: Icon(Icons.copy),
  onPressed: () async {
    await Clipboard.setData(ClipboardData(text: tripId));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Invite code copied!')),
    );
  },
);

// In TripInvitePage - Share button
IconButton(
  icon: Icon(Icons.share),
  onPressed: () async {
    final link = generateShareableLink(tripId);
    await Share.share('Join my trip on Expense Tracker: $link');
  },
);
```

---

### 3. Non-Member Tries to Access Trip

```
[Non-member navigates to] /trips/abc123/expenses
    │
    ▼
[Membership guard checks] isUserMemberOf('abc123') ──► false
    │
    ▼
[Redirect to] /trips/abc123/join
    │
    ▼
[TripJoinPage] Shows trip details, prompts to join
```

**Code**:
```dart
// Automatic via redirect in route configuration
redirect: (context, state) async {
  final tripId = state.pathParameters['tripId'];
  final isMember = await context.read<TripCubit>().isUserMemberOf(tripId!);
  return isMember ? null : '/trips/$tripId/join';
},
```

---

### 4. User Joins Trip via Manual Code Entry

```
[User on Trip List] /trips
    │
    ▼
[Tap "Join Trip" button]
    │
    ▼
[Navigate to] /trips/join
    │
    ▼
[TripJoinPage] Shows code input field, no pre-fill
    │
    ▼
[User enters code] "abc123"
    │
    ▼
[User enters name] "Tai"
    │
    ▼
[TripCubit.joinTrip('abc123', 'Tai')]
    │
    └─► (same as shareable link flow)
```

**Code**:
```dart
// In TripListPage
FloatingActionButton(
  onPressed: () => context.go('/trips/join'),
  child: Icon(Icons.add),
  label: Text('Join Trip'),
);
```

---

## Error Handling

### Invalid Trip ID in URL

**Scenario**: User navigates to `/trips/invalid123/join`, but trip doesn't exist

**Handling**:
```dart
// In TripCubit.joinTrip()
final trip = await _tripRepository.getTripById(tripId);
if (trip == null) {
  emit(TripJoinError('Trip not found. Please check the invite code.'));
  return;
}

// In TripJoinPage
BlocListener<TripCubit, TripState>(
  listener: (context, state) {
    if (state is TripJoinError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.message),
          action: SnackBarAction(
            label: 'Back',
            onPressed: () => context.go('/trips'),
          ),
        ),
      );
    }
  },
);
```

---

### Unauthorized Access Attempt

**Scenario**: Non-member tries to access `/trips/abc123/settings` directly

**Handling**: Automatic redirect via membership guard (see Navigation Guard section)

---

## Testing Routing

### Unit Tests (go_router_builder)

**Test Cases**:

```dart
test('route to tripJoin builds TripJoinPage', () {
  final route = router.findRoute('/trips/join');
  expect(route, isNotNull);
  expect(route!.page, isA<TripJoinPage>());
});

test('route to tripJoinDirect extracts tripId', () {
  final state = GoRouterState(router, Uri.parse('/trips/abc123/join'));
  final tripId = state.pathParameters['tripId'];
  expect(tripId, 'abc123');
});

test('membership guard redirects non-members', () async {
  // Mock: User is not member of trip123
  when(tripCubit.isUserMemberOf('trip123')).thenAnswer((_) async => false);

  final redirect = await membershipGuard(context, state, 'trip123');
  expect(redirect, '/trips/trip123/join');
});

test('membership guard allows members', () async {
  // Mock: User is member of trip123
  when(tripCubit.isUserMemberOf('trip123')).thenAnswer((_) async => true);

  final redirect = await membershipGuard(context, state, 'trip123');
  expect(redirect, isNull);  // Allow navigation
});
```

### Integration Tests

**Test Cases**:

```dart
testWidgets('deep link navigates to join page', (tester) async {
  await tester.pumpWidget(MyApp());

  // Simulate deep link navigation
  final router = GoRouter.of(tester.element(find.byType(MyApp)));
  router.go('/trips/abc123/join');
  await tester.pumpAndSettle();

  // Verify TripJoinPage is displayed
  expect(find.byType(TripJoinPage), findsOneWidget);

  // Verify invite code is pre-filled
  expect(find.text('abc123'), findsOneWidget);
});

testWidgets('non-member redirected to join page', (tester) async {
  await tester.pumpWidget(MyApp());

  // Navigate to member-only route
  final router = GoRouter.of(tester.element(find.byType(MyApp)));
  router.go('/trips/abc123/expenses');
  await tester.pumpAndSettle();

  // Verify redirected to join page
  expect(find.byType(TripJoinPage), findsOneWidget);
  expect(find.text('Join Trip'), findsOneWidget);
});
```

---

## Localization

### Route-Specific Strings

**File**: `lib/l10n/app_en.arb`

**New Strings**:
```json
{
  "tripJoinTitle": "Join Trip",
  "tripJoinCodeLabel": "Invite Code",
  "tripJoinCodeHint": "Enter the trip code",
  "tripJoinNameLabel": "Your Name",
  "tripJoinNameHint": "How should we call you?",
  "tripJoinButton": "Join Trip",
  "tripJoinInvalidCode": "Trip not found. Please check the invite code.",
  "tripJoinAlreadyMember": "You've already joined this trip!",

  "tripInviteTitle": "Invite Friends",
  "tripInviteCodeLabel": "Invite Code",
  "tripInviteCopyButton": "Copy Code",
  "tripInviteShareButton": "Share Link",
  "tripInviteCodeCopied": "Invite code copied to clipboard!",
  "tripInviteShareMessage": "Join my trip on Expense Tracker: {link}"
}
```

**Usage**:
```dart
Text(context.l10n.tripJoinTitle);
```

---

## Summary

**New Routes**: 3
- `/trips/join` (manual code entry)
- `/trips/:tripId/join` (deep link)
- `/trips/:tripId/invite` (show invite details)

**Modified Routes**: 4 (add membership guards)
- `/trips/:tripId/expenses`
- `/trips/:tripId/settings`
- `/trips/:tripId/settlement`
- `/trips/:tripId/edit`

**Navigation Guards**: 1 (membership guard)
**Deep Linking**: Enabled (hash routing)
**Shareable Link Format**: `https://.../#/trips/{tripId}/join`

**Routing Complexity**: Low
- Extends existing go_router configuration
- Standard path parameters and redirects
- No nested navigation or complex state passing

**Ready for Implementation**: Yes - Routing structure defined and validated
