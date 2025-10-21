import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'features/trips/data/repositories/trip_repository_impl.dart';
import 'features/expenses/data/repositories/expense_repository_impl.dart';
import 'features/trips/presentation/cubits/trip_cubit.dart';
import 'features/expenses/presentation/cubits/expense_cubit.dart';
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

  // Initialize Firebase
  _log('📡 Starting Firebase initialization...');
  final firebaseStart = DateTime.now();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: 'AIzaSyDYb8zKfPEY_EkYfz4EqU5QF5xZ8vX0zQo',
      authDomain: 'expense-tracker-d4f76.firebaseapp.com',
      projectId: 'expense-tracker-d4f76',
      storageBucket: 'expense-tracker-d4f76.firebasestorage.app',
      messagingSenderId: '1054891848903',
      appId: '1:1054891848903:web:bfb4e8f6f3c4d5e6f7a8b9',
    ),
  );
  _log('✅ Firebase initialized (${DateTime.now().difference(firebaseStart).inMilliseconds}ms)');

  // Enable offline persistence for instant data access
  _log('💾 Configuring Firestore persistence...');
  final persistenceStart = DateTime.now();
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );
  _log('✅ Firestore persistence configured (${DateTime.now().difference(persistenceStart).inMilliseconds}ms)');

  _log('🎬 Launching app widget (total startup: ${DateTime.now().difference(startTime).inMilliseconds}ms)');
  runApp(const ExpenseTrackerApp());
}

/// Root application widget with singleton BLoC providers
class ExpenseTrackerApp extends StatelessWidget {
  const ExpenseTrackerApp({super.key});

  // Singleton instances shared across the entire app
  static final _firestoreService = FirestoreService();
  static final _tripRepository = TripRepositoryImpl(firestoreService: _firestoreService);
  static final _expenseRepository = ExpenseRepositoryImpl(firestoreService: _firestoreService);

  @override
  Widget build(BuildContext context) {
    _log('🏗️ Building ExpenseTrackerApp widget tree...');
    final buildStart = DateTime.now();

    _log('📦 Creating repository providers...');
    final widget = MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: _tripRepository),
        RepositoryProvider.value(value: _expenseRepository),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) {
              _log('🔵 Creating TripCubit and loading trips...');
              final cubitStart = DateTime.now();
              final cubit = TripCubit(tripRepository: _tripRepository);
              _log('✅ TripCubit created (${DateTime.now().difference(cubitStart).inMilliseconds}ms)');

              _log('📥 Calling loadTrips()...');
              final loadStart = DateTime.now();
              cubit.loadTrips();
              _log('✅ loadTrips() called (${DateTime.now().difference(loadStart).inMilliseconds}ms)');

              return cubit;
            },
            lazy: false, // Load trips immediately on app start
          ),
          BlocProvider(
            create: (context) {
              _log('🔵 Creating ExpenseCubit...');
              return ExpenseCubit(expenseRepository: _expenseRepository);
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
