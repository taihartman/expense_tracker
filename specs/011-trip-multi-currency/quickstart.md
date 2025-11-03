# Quickstart Guide: Trip Multi-Currency Development

**Feature**: 011-trip-multi-currency
**Created**: 2025-11-02
**Audience**: Developers working on this feature

## Purpose

This guide helps developers quickly set up their environment to develop and test the trip multi-currency feature. It covers local development, testing multi-currency selection, Firebase Functions emulator setup, and creating test data.

## Prerequisites

Before starting, ensure you have:

- [x] Flutter SDK installed (3.9.0+)
- [x] Dart SDK installed (comes with Flutter)
- [x] Firebase CLI installed (`npm install -g firebase-tools`)
- [x] Node.js 18+ installed (for Cloud Functions)
- [x] Git repository cloned
- [x] IDE setup (VS Code or Android Studio recommended)

## Quick Start (5 Minutes)

### 1. Install Dependencies

```bash
# Navigate to project root
cd expense_tracker

# Install Flutter dependencies
flutter pub get

# Install Firebase Functions dependencies (if testing migration)
cd functions
npm install
cd ..
```

### 2. Run the App

```bash
# Run in Chrome with mobile viewport (375x667px)
flutter run -d chrome --web-browser-flag "--window-size=375,667"

# OR run in Chrome with desktop viewport
flutter run -d chrome
```

### 3. Create a Test Trip with Multiple Currencies

1. Launch app → Create new trip
2. Enter trip name (e.g., "Europe 2025")
3. Navigate to trip settings
4. Open currency selector bottom sheet
5. Add EUR, CHF, GBP currencies
6. Reorder currencies (use up/down arrows)
7. Save trip

### 4. Verify Currency Filtering in Expense Form

1. Navigate to trip → Create expense
2. Tap currency dropdown
3. Verify only EUR, CHF, GBP appear (not all 170+ currencies)
4. Verify EUR is pre-selected (default = first in list)

## Development Environment Setup

### Flutter Development

**Run with hot reload**:
```bash
# Chrome (mobile viewport)
flutter run -d chrome --web-browser-flag "--window-size=375,667"

# Chrome (desktop viewport)
flutter run -d chrome --web-browser-flag "--window-size=1200,800"

# Mobile emulator (iOS)
flutter run -d iPhone

# Mobile emulator (Android)
flutter run -d emulator-5554
```

**Run tests**:
```bash
# All tests
flutter test

# Specific test file
flutter test test/features/trips/presentation/widgets/multi_currency_selector_test.dart

# With coverage
flutter test --coverage

# Watch mode (re-run on file changes)
flutter test --watch
```

**Generate mocks** (after adding @GenerateMocks annotations):
```bash
dart run build_runner build --delete-conflicting-outputs
```

**Format code**:
```bash
flutter format .
```

**Analyze code**:
```bash
flutter analyze
```

### Firebase Functions Development (Migration Testing)

**Initialize Functions** (first time only):
```bash
# In project root
firebase init functions

# Select:
# - TypeScript
# - TSLint: No (use ESLint if prompted)
# - Install dependencies: Yes
```

**Start Firebase Emulators**:
```bash
# Start Firestore + Functions emulators
firebase emulators:start

# Expected output:
# ✔  Firestore Emulator: http://127.0.0.1:8080
# ✔  Functions Emulator: http://127.0.0.1:5001
```

**Run Functions Tests**:
```bash
cd functions

# Run all tests
npm test

# Run specific test
npm test -- --grep "migrateTripCurrencies"

# Run with coverage
npm run test:coverage
```

**Deploy Functions** (to Firebase):
```bash
# Set migration secret
firebase functions:config:set migration.secret="your-secret-key"

# Deploy migration function only
firebase deploy --only functions:migrateTripCurrencies

# Deploy all functions
firebase deploy --only functions
```

## Testing Multi-Currency Selection

### Creating Test Trips

**Test Case 1: New Trip with 3 Currencies**

```dart
// In Dart DevTools Console or test file
final trip = Trip(
  id: 'test_trip_1',
  name: 'Europe Vacation',
  allowedCurrencies: [CurrencyCode.eur, CurrencyCode.chf, CurrencyCode.gbp],
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
);

await tripRepository.createTrip(trip);
```

**Test Case 2: Legacy Trip (Single Currency)**

```dart
// Simulate legacy trip (before multi-currency feature)
final legacyTrip = Trip(
  id: 'test_trip_legacy',
  name: 'Old Trip',
  allowedCurrencies: [CurrencyCode.usd],  // Single currency
  baseCurrency: CurrencyCode.usd,  // Legacy field
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
);

await tripRepository.createTrip(legacyTrip);
```

**Test Case 3: Maximum Currencies (10)**

```dart
final maxCurrencies = Trip(
  id: 'test_trip_max',
  name: 'World Tour',
  allowedCurrencies: [
    CurrencyCode.usd,
    CurrencyCode.eur,
    CurrencyCode.gbp,
    CurrencyCode.jpy,
    CurrencyCode.aud,
    CurrencyCode.cad,
    CurrencyCode.chf,
    CurrencyCode.cny,
    CurrencyCode.inr,
    CurrencyCode.krw,
  ],
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
);

await tripRepository.createTrip(maxCurrencies);
```

### Manual UI Testing Checklist

**Currency Selector Widget**:
- [x] Bottom sheet opens when clicking currency settings
- [x] Chips display correctly for selected currencies
- [x] Up arrow hidden for first chip
- [x] Down arrow hidden for last chip
- [x] Remove button works (removes chip)
- [x] Add Currency button opens CurrencySearchField modal
- [x] Reordering works (up/down arrows swap chips)
- [x] Validation: Cannot add >10 currencies
- [x] Validation: Cannot remove last currency
- [x] Duplicate prevention: Same currency can't be added twice
- [x] Save button updates trip

**Expense Form Filtering**:
- [x] Currency dropdown shows only trip's allowed currencies
- [x] Default currency (first in list) is pre-selected
- [x] Changing trip currencies updates dropdown immediately
- [x] Legacy trip (single currency) shows only that currency

**Mobile Responsiveness**:
- [x] Bottom sheet fills 90% of mobile viewport
- [x] Chips wrap to multiple rows on small screens
- [x] Touch targets are 44x44px minimum
- [x] Keyboard doesn't hide bottom sheet content
- [x] No horizontal scrolling

## Testing Migration (Cloud Functions)

### Setup Firestore Emulator

1. **Start emulator**:
   ```bash
   firebase emulators:start --only firestore
   ```

2. **Configure app to use emulator** (add to `main.dart`):
   ```dart
   void main() async {
     WidgetsFlutterBinding.ensureInitialized();
     await Firebase.initializeApp();
     
     // Use Firestore emulator (local testing only)
     if (kDebugMode) {
       FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
     }
     
     runApp(MyApp());
   }
   ```

3. **Create legacy trips in emulator**:
   ```dart
   // In Dart DevTools Console
   await FirebaseFirestore.instance.collection('trips').add({
     'name': 'Legacy Trip 1',
     'baseCurrency': 'USD',
     'createdAt': Timestamp.now(),
     'updatedAt': Timestamp.now(),
     'isArchived': false,
     'participants': [],
     // NOTE: No allowedCurrencies field
   });
   ```

### Run Migration Function Locally

1. **Build migration function**:
   ```bash
   cd functions
   npm run build
   ```

2. **Start Functions emulator**:
   ```bash
   firebase emulators:start --only functions,firestore
   ```

3. **Invoke migration function**:
   ```bash
   curl -X POST \
     http://localhost:5001/expense-tracker/us-central1/migrateTripCurrencies \
     -H "Authorization: Bearer test-secret" \
     -H "Content-Type: application/json"
   ```

4. **Verify migration results**:
   - Check emulator logs (shows migration summary)
   - Open Firestore Emulator UI: http://localhost:4000/firestore
   - Verify trips now have `allowedCurrencies` field

### Migration Testing Scenarios

**Scenario 1: Successful Migration**

```bash
# 1. Create legacy trip
firebase emulators:exec --only firestore "node scripts/create-legacy-trip.js"

# 2. Run migration
curl -X POST http://localhost:5001/.../migrateTripCurrencies ...

# 3. Verify
# - Open Firestore Emulator UI
# - Check trip has allowedCurrencies = [baseCurrency]
```

**Scenario 2: Missing baseCurrency**

```bash
# 1. Create corrupted trip (no baseCurrency)
await db.collection('trips').add({
  name: 'Corrupted Trip',
  createdAt: Timestamp.now(),
  updatedAt: Timestamp.now(),
});

# 2. Run migration
curl -X POST http://localhost:5001/.../migrateTripCurrencies ...

# 3. Verify
# - Migration summary shows 1 failed trip
# - Reason: "missing baseCurrency field"
```

**Scenario 3: Idempotency (Re-run)**

```bash
# 1. Run migration once
curl -X POST http://localhost:5001/.../migrateTripCurrencies ...

# 2. Run migration again (should process 0 trips)
curl -X POST http://localhost:5001/.../migrateTripCurrencies ...

# 3. Verify
# - Second run shows totalTrips: 0
# - No duplicate updates
```

## Common Development Tasks

### Adding a New Localization String

1. Edit `lib/l10n/app_en.arb`:
   ```json
   {
     "multiCurrencySelectorTitle": "Allowed Currencies",
     "multiCurrencySelectorAddButton": "Add Currency"
   }
   ```

2. Run `flutter pub get` (generates localization code)

3. Use in code:
   ```dart
   import 'package:expense_tracker/core/l10n/l10n_extensions.dart';
   
   Text(context.l10n.multiCurrencySelectorTitle)
   ```

### Creating a Widget Test

1. Create test file: `test/features/trips/presentation/widgets/multi_currency_selector_test.dart`

2. Write test:
   ```dart
   import 'package:flutter_test/flutter_test.dart';
   import 'package:expense_tracker/features/trips/presentation/widgets/multi_currency_selector.dart';
   
   void main() {
     testWidgets('renders chips for selected currencies', (tester) async {
       await tester.pumpWidget(
         MaterialApp(
           home: Scaffold(
             body: MultiCurrencySelector(
               selectedCurrencies: [CurrencyCode.usd, CurrencyCode.eur],
               onChanged: (_) {},
             ),
           ),
         ),
       );
       
       expect(find.text('USD'), findsOneWidget);
       expect(find.text('EUR'), findsOneWidget);
     });
   }
   ```

3. Run test:
   ```bash
   flutter test test/features/trips/presentation/widgets/multi_currency_selector_test.dart
   ```

### Debugging Tips

**Flutter DevTools**:
```bash
# Run app with DevTools
flutter run -d chrome --web-browser-flag "--window-size=375,667"

# Open DevTools (shown in terminal output)
# Navigate to Widget Inspector, Network, Logging tabs
```

**Firestore Debugging**:
```dart
// Enable Firestore logging
FirebaseFirestore.setLoggingEnabled(true);

// In Dart DevTools Console, query trips
final trips = await FirebaseFirestore.instance.collection('trips').get();
trips.docs.forEach((doc) => print(doc.data()));
```

**Cloud Functions Debugging**:
```bash
# View emulator logs
firebase emulators:start --only functions

# In separate terminal, tail logs
firebase functions:log --only migrateTripCurrencies
```

## Troubleshooting

### Issue: "CurrencyCode enum not found"

**Solution**: Generate currency code enum:
```bash
dart run build_runner build --delete-conflicting-outputs
```

### Issue: "Firestore permission denied"

**Solution**: Check Firebase emulator is running:
```bash
firebase emulators:start --only firestore
```

And app is configured to use emulator (see "Setup Firestore Emulator" above).

### Issue: "Migration function returns 403 Unauthorized"

**Solution**: Check authorization header matches function config:
```bash
# Set secret
firebase functions:config:set migration.secret="test-secret"

# Use in curl
curl ... -H "Authorization: Bearer test-secret"
```

### Issue: "Bottom sheet doesn't open"

**Solution**: Check modal context is correct:
```dart
showModalBottomSheet(
  context: context,  // Must be BuildContext from Scaffold
  builder: (context) => MultiCurrencySelector(...),
);
```

### Issue: "Tests fail with 'Missing MaterialApp'"

**Solution**: Wrap widget in MaterialApp:
```dart
await tester.pumpWidget(
  MaterialApp(
    home: Scaffold(
      body: MultiCurrencySelector(...),
    ),
  ),
);
```

## Reference Documentation

**Internal Docs**:
- [spec.md](spec.md) - Feature specification
- [plan.md](plan.md) - Implementation plan
- [data-model.md](data-model.md) - Data model details
- [contracts/](contracts/) - Widget, repository, and function contracts

**External Docs**:
- [Flutter Testing](https://docs.flutter.dev/testing)
- [Firebase Functions](https://firebase.google.com/docs/functions)
- [Firestore Emulator](https://firebase.google.com/docs/emulator-suite/connect_firestore)

## Next Steps

After setting up:
1. Review [plan.md](plan.md) for implementation workflow
2. Review [data-model.md](data-model.md) for entity changes
3. Review [contracts/](contracts/) for API specifications
4. Run `/speckit.tasks` to generate task breakdown
5. Begin TDD implementation (write tests first!)

---

**Quickstart Version**: 1.0 | **Created**: 2025-11-02 | **Last Updated**: 2025-11-02
