import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/services/local_storage_service.dart';
import 'core/services/migration_service.dart';
import 'features/trips/data/repositories/trip_repository_impl.dart';
import 'features/trips/domain/repositories/trip_repository.dart';
import 'features/expenses/data/repositories/expense_repository_impl.dart';
import 'features/expenses/domain/repositories/expense_repository.dart';
import 'features/categories/data/repositories/category_repository_impl.dart';
import 'features/categories/domain/repositories/category_repository.dart';
import 'features/settlements/data/repositories/settlement_repository_impl.dart';
import 'features/settlements/domain/repositories/settlement_repository.dart';
import 'features/settlements/data/repositories/settled_transfer_repository_impl.dart';
import 'features/settlements/domain/repositories/settled_transfer_repository.dart';
import 'features/trips/presentation/cubits/trip_cubit.dart';
import 'features/expenses/presentation/cubits/expense_cubit.dart';
import 'features/settlements/presentation/cubits/settlement_cubit.dart';
import 'shared/services/firestore_service.dart';

/// Helper function to log with timestamps
void _log(String message) {
  debugPrint('[${DateTime.now().toIso8601String()}] $message');
}

/// Application entry point
///
/// Initializes Firebase and launches the Flutter application
Future<void> main() async {
  _log('🚀 APP START: main() called');

  final startTime = DateTime.now();
  WidgetsFlutterBinding.ensureInitialized();
  _log('✅ WidgetsFlutterBinding initialized (${DateTime.now().difference(startTime).inMilliseconds}ms)');

  // Initialize Firebase with correct project configuration
  _log('📡 Starting Firebase initialization...');
  final firebaseStart = DateTime.now();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  _log('✅ Firebase initialized (${DateTime.now().difference(firebaseStart).inMilliseconds}ms)');

  // Sign in anonymously to satisfy Firestore security rules
  _log('🔐 Signing in anonymously...');
  final authStart = DateTime.now();
  try {
    final userCredential = await FirebaseAuth.instance.signInAnonymously();
    _log('✅ Anonymous auth successful - UID: ${userCredential.user?.uid} (${DateTime.now().difference(authStart).inMilliseconds}ms)');
  } catch (e, stackTrace) {
    _log('❌ Anonymous auth failed: $e');
    _log('Stack trace: $stackTrace');
    // Auth failure will prevent Firestore access if security rules require authentication
    // Consider showing an error dialog or retry mechanism here
  }

  // Enable offline persistence with reasonable cache limit
  _log('💾 Configuring Firestore persistence...');
  final persistenceStart = DateTime.now();
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: 104857600, // 100MB cache limit (was unlimited)
  );
  _log('✅ Firestore persistence configured (${DateTime.now().difference(persistenceStart).inMilliseconds}ms)');

  // Initialize LocalStorageService for user preferences
  _log('💾 Initializing LocalStorageService...');
  final storageStart = DateTime.now();
  final localStorageService = await LocalStorageService.init();
  _log('✅ LocalStorageService initialized (${DateTime.now().difference(storageStart).inMilliseconds}ms)');

  // Run data migrations
  _log('🔄 Running data migrations...');
  final migrationStart = DateTime.now();
  final prefs = await SharedPreferences.getInstance();
  final firestoreService = FirestoreService();
  final migrationService = MigrationService(
    firestoreService: firestoreService,
    prefs: prefs,
  );
  await migrationService.runMigrations();
  _log('✅ Migrations completed (${DateTime.now().difference(migrationStart).inMilliseconds}ms)');

  _log('🎬 Launching app widget (total startup: ${DateTime.now().difference(startTime).inMilliseconds}ms)');
  runApp(ExpenseTrackerApp(localStorageService: localStorageService));
}

/// Root application widget with singleton BLoC providers
class ExpenseTrackerApp extends StatelessWidget {
  final LocalStorageService localStorageService;

  const ExpenseTrackerApp({
    super.key,
    required this.localStorageService,
  });

  // Singleton instances shared across the entire app
  static final _firestoreService = FirestoreService();
  static final _tripRepository = TripRepositoryImpl(firestoreService: _firestoreService);
  static final _expenseRepository = ExpenseRepositoryImpl(firestoreService: _firestoreService);
  static final _categoryRepository = CategoryRepositoryImpl(firestoreService: _firestoreService);
  static final _settledTransferRepository = SettledTransferRepositoryImpl(firestoreService: _firestoreService);
  static final _settlementRepository = SettlementRepositoryImpl(
    firestoreService: _firestoreService,
    expenseRepository: _expenseRepository,
    tripRepository: _tripRepository,
  );

  @override
  Widget build(BuildContext context) {
    _log('🏗️ Building ExpenseTrackerApp widget tree...');
    final buildStart = DateTime.now();

    _log('📦 Creating repository providers...');
    final widget = MultiRepositoryProvider(
      providers: [
        RepositoryProvider<TripRepository>.value(value: _tripRepository),
        RepositoryProvider<ExpenseRepository>.value(value: _expenseRepository),
        RepositoryProvider<CategoryRepository>.value(value: _categoryRepository),
        RepositoryProvider<SettlementRepository>.value(value: _settlementRepository),
        RepositoryProvider<SettledTransferRepository>.value(value: _settledTransferRepository),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) {
              _log('🔵 Creating TripCubit (lazy mode - will load when first accessed)...');
              final cubitStart = DateTime.now();
              final cubit = TripCubit(
                tripRepository: _tripRepository,
                localStorageService: localStorageService,
                categoryRepository: _categoryRepository,
              );
              _log('✅ TripCubit created (${DateTime.now().difference(cubitStart).inMilliseconds}ms)');
              return cubit;
            },
            lazy: true, // Lazy loading - only load when actually needed
          ),
          BlocProvider(
            create: (context) {
              _log('🔵 Creating ExpenseCubit...');
              return ExpenseCubit(expenseRepository: _expenseRepository);
            },
          ),
          BlocProvider(
            create: (context) {
              _log('🔵 Creating SettlementCubit (SIMPLIFIED)...');
              return SettlementCubit(
                settlementRepository: _settlementRepository,
                expenseRepository: _expenseRepository,
                tripRepository: _tripRepository,
                settledTransferRepository: _settledTransferRepository,
              );
            },
          ),
        ],
        child: MaterialApp.router(
          title: 'Expense Tracker',
          theme: AppTheme.lightTheme,
          routerConfig: AppRouter.router,
          debugShowCheckedModeBanner: false,
        ),
      ),
    );

    _log('✅ Widget tree built (${DateTime.now().difference(buildStart).inMilliseconds}ms)');
    return widget;
  }
}
