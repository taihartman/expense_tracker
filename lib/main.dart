import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/services/local_storage_service.dart';
import 'core/services/activity_logger_service.dart';
import 'core/services/activity_logger_service_impl.dart';
import 'core/services/auth_service.dart';
import 'core/cubits/initialization_cubit.dart';
import 'core/presentation/pages/initialization_splash_page.dart';
import 'core/widgets/debug_overlay.dart';
import 'core/widgets/update_notification_banner.dart';
import 'features/trips/data/repositories/trip_repository_impl.dart';
import 'features/trips/domain/repositories/trip_repository.dart';
import 'features/trips/data/repositories/activity_log_repository_impl.dart';
import 'features/trips/domain/repositories/activity_log_repository.dart';
import 'features/expenses/data/repositories/expense_repository_impl.dart';
import 'features/expenses/domain/repositories/expense_repository.dart';
import 'features/categories/data/repositories/category_repository_impl.dart';
import 'features/categories/domain/repositories/category_repository.dart';
import 'features/categories/data/repositories/category_customization_repository_impl.dart';
import 'core/repositories/category_customization_repository.dart';
import 'features/categories/data/services/rate_limiter_service.dart';
import 'features/categories/presentation/cubit/category_cubit.dart';
import 'features/settlements/data/repositories/settlement_repository_impl.dart';
import 'features/settlements/domain/repositories/settlement_repository.dart';
import 'features/settlements/data/repositories/settled_transfer_repository_impl.dart';
import 'features/settlements/domain/repositories/settled_transfer_repository.dart';
import 'features/trips/presentation/cubits/trip_cubit.dart';
import 'features/trips/presentation/cubits/activity_log_cubit.dart';
import 'features/expenses/presentation/cubits/expense_cubit.dart';
import 'features/settlements/presentation/cubits/settlement_cubit.dart';
import 'features/device_pairing/data/repositories/firestore_device_link_code_repository.dart';
import 'features/device_pairing/domain/repositories/device_link_code_repository.dart';
import 'features/device_pairing/presentation/cubits/device_pairing_cubit.dart';
import 'features/trips/data/repositories/firestore_trip_recovery_code_repository.dart';
import 'features/trips/domain/repositories/trip_recovery_code_repository.dart';
import 'l10n/app_localizations.dart';
import 'shared/services/firestore_service.dart';
import 'core/services/version_service.dart';

/// Helper function to log with timestamps
void _log(String message) {
  debugPrint('[${DateTime.now().toIso8601String()}] $message');
}

/// Helper to print errors in a very visible way
void _logError(String title, Object error, [StackTrace? stackTrace]) {
  debugPrint('\n');
  debugPrint('═══════════════════════════════════════════════════════════════');
  debugPrint('🔴 ERROR: $title');
  debugPrint('═══════════════════════════════════════════════════════════════');
  debugPrint('Error: $error');
  if (stackTrace != null) {
    debugPrint(
      '───────────────────────────────────────────────────────────────',
    );
    debugPrint('Stack Trace:');
    debugPrint(stackTrace.toString());
  }
  debugPrint('═══════════════════════════════════════════════════════════════');
  debugPrint('\n');
}

/// BLoC observer to log all state changes and errors
class AppBlocObserver extends BlocObserver {
  @override
  void onCreate(BlocBase bloc) {
    super.onCreate(bloc);
    _log('🔵 BLoC Created: ${bloc.runtimeType}');
  }

  @override
  void onEvent(Bloc bloc, Object? event) {
    super.onEvent(bloc, event);
    _log('🟢 BLoC Event: ${bloc.runtimeType} - $event');
  }

  @override
  void onChange(BlocBase bloc, Change change) {
    super.onChange(bloc, change);
    _log(
      '🟡 BLoC Change: ${bloc.runtimeType} - ${change.currentState.runtimeType} -> ${change.nextState.runtimeType}',
    );
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    _logError('BLoC Error in ${bloc.runtimeType}', error, stackTrace);
    super.onError(bloc, error, stackTrace);
  }

  @override
  void onClose(BlocBase bloc) {
    super.onClose(bloc);
    _log('🔵 BLoC Closed: ${bloc.runtimeType}');
  }
}

/// Application entry point
///
/// Launches the Flutter application immediately, with Firebase initialization
/// happening in the background via InitializationCubit
Future<void> main() async {
  _log('🚀 APP START: main() called');

  // Configure global error handlers FIRST
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    _logError('Flutter Framework Error', details.exception, details.stack);
  };

  // Catch errors outside of Flutter framework (async errors, etc.)
  PlatformDispatcher.instance.onError = (error, stack) {
    _logError('Platform/Async Error', error, stack);
    return true;
  };

  // Configure BLoC observer to log all state changes and errors
  Bloc.observer = AppBlocObserver();
  _log('✅ BLoC observer configured');

  final startTime = DateTime.now();
  WidgetsFlutterBinding.ensureInitialized();
  _log(
    '✅ WidgetsFlutterBinding initialized (${DateTime.now().difference(startTime).inMilliseconds}ms)',
  );

  // Initialize version service
  await VersionService.initialize();
  _log(
    '✅ VersionService initialized (${DateTime.now().difference(startTime).inMilliseconds}ms)',
  );

  // CRITICAL: Capture browser URL BEFORE creating widget tree
  // This preserves deep links (invite links) during app initialization
  final initialUrl = PlatformDispatcher.instance.defaultRouteName;
  _log('🌐 Initial URL from platform: $initialUrl');
  AppRouter.setInitialUrl(initialUrl);

  // Launch app immediately - Firebase initialization will happen in background
  _log(
    '🎬 Launching app widget (${DateTime.now().difference(startTime).inMilliseconds}ms) - Firebase initialization will happen in background',
  );
  runApp(const ExpenseTrackerApp());
}

/// Root application widget with initialization handling
class ExpenseTrackerApp extends StatelessWidget {
  const ExpenseTrackerApp({super.key});

  // Singleton instances shared across the entire app
  static final _firestoreService = FirestoreService();
  static final _tripRepository = TripRepositoryImpl(
    firestoreService: _firestoreService,
  );
  static final _activityLogRepository = ActivityLogRepositoryImpl();
  static final _activityLoggerService = ActivityLoggerServiceImpl(
    activityLogRepository: _activityLogRepository,
    tripRepository: _tripRepository,
  );
  static final _expenseRepository = ExpenseRepositoryImpl(
    firestoreService: _firestoreService,
  );
  static final _rateLimiterService = RateLimiterService(
    firestoreService: _firestoreService,
  );
  static final _categoryRepository = CategoryRepositoryImpl(
    firestoreService: _firestoreService,
    rateLimiterService: _rateLimiterService,
  );
  static final _categoryCustomizationRepository =
      CategoryCustomizationRepositoryImpl(firestoreService: _firestoreService);
  static final _settledTransferRepository = SettledTransferRepositoryImpl(
    firestoreService: _firestoreService,
  );
  static final _settlementRepository = SettlementRepositoryImpl(
    firestoreService: _firestoreService,
    expenseRepository: _expenseRepository,
    tripRepository: _tripRepository,
  );
  static final _deviceLinkCodeRepository = FirestoreDeviceLinkCodeRepository(
    firestore: FirebaseFirestore.instance,
  );
  static final _tripRecoveryCodeRepository =
      FirestoreTripRecoveryCodeRepository(
        firestore: FirebaseFirestore.instance,
      );

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final cubit = InitializationCubit();
        // Start initialization immediately
        cubit.initialize();
        return cubit;
      },
      child: BlocBuilder<InitializationCubit, InitializationState>(
        builder: (context, state) {
          if (state is InitializationError) {
            // Show error UI
            return MaterialApp(
              home: Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        state.message,
                        style: const TextStyle(fontSize: 18),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          // Retry initialization
                          context.read<InitializationCubit>().initialize();
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          if (state is InitializationComplete) {
            // Firebase is initialized - build the full app
            return _buildInitializedApp(state.localStorageService);
          }

          // Show splash page during initialization (default case)
          return MaterialApp(
            theme: AppTheme.lightTheme,
            debugShowCheckedModeBanner: false,
            home: const InitializationSplashPage(),
          );
        },
      ),
    );
  }

  /// Builds the full app widget tree after initialization is complete
  Widget _buildInitializedApp(LocalStorageService localStorageService) {
    _log('🏗️ Building initialized app widget tree...');
    final buildStart = DateTime.now();

    _log('📦 Creating repository providers...');
    final widget = MultiRepositoryProvider(
      providers: [
        RepositoryProvider<TripRepository>.value(value: _tripRepository),
        RepositoryProvider<ActivityLogRepository>.value(
          value: _activityLogRepository,
        ),
        RepositoryProvider<ActivityLoggerService>.value(
          value: _activityLoggerService,
        ),
        RepositoryProvider<ExpenseRepository>.value(value: _expenseRepository),
        RepositoryProvider<CategoryRepository>.value(
          value: _categoryRepository,
        ),
        RepositoryProvider<CategoryCustomizationRepository>.value(
          value: _categoryCustomizationRepository,
        ),
        RepositoryProvider<SettlementRepository>.value(
          value: _settlementRepository,
        ),
        RepositoryProvider<SettledTransferRepository>.value(
          value: _settledTransferRepository,
        ),
        RepositoryProvider<DeviceLinkCodeRepository>.value(
          value: _deviceLinkCodeRepository,
        ),
        RepositoryProvider<TripRecoveryCodeRepository>.value(
          value: _tripRecoveryCodeRepository,
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) {
              _log(
                '🔵 Creating TripCubit (lazy mode - will load when first accessed)...',
              );
              final cubitStart = DateTime.now();
              final cubit = TripCubit(
                tripRepository: _tripRepository,
                localStorageService: localStorageService,
                activityLoggerService: _activityLoggerService,
                categoryRepository: _categoryRepository,
                recoveryCodeRepository: _tripRecoveryCodeRepository,
              );
              _log(
                '✅ TripCubit created (${DateTime.now().difference(cubitStart).inMilliseconds}ms)',
              );
              return cubit;
            },
            lazy: true, // Lazy loading - only load when actually needed
          ),
          BlocProvider(
            create: (context) {
              _log('🔵 Creating ActivityLogCubit...');
              return ActivityLogCubit(repository: _activityLogRepository);
            },
          ),
          BlocProvider(
            create: (context) {
              _log('🔵 Creating ExpenseCubit...');
              return ExpenseCubit(
                expenseRepository: _expenseRepository,
                categoryRepository: _categoryRepository,
                activityLoggerService: _activityLoggerService,
              );
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
                categoryRepository: _categoryRepository,
                localStorageService: localStorageService,
                activityLoggerService: _activityLoggerService,
              );
            },
          ),
          BlocProvider(
            create: (context) {
              _log('🔵 Creating DevicePairingCubit...');
              return DevicePairingCubit(
                repository: _deviceLinkCodeRepository,
                localStorageService: localStorageService,
                tripRepository: _tripRepository,
                activityLoggerService: _activityLoggerService,
              );
            },
          ),
          BlocProvider(
            create: (context) {
              _log('🔵 Creating CategoryCubit...');
              return CategoryCubit(
                categoryRepository: _categoryRepository,
                rateLimiterService: _rateLimiterService,
                authService: AuthService(),
              );
            },
          ),
        ],
        child: MaterialApp.router(
          title: 'Expense Tracker',
          theme: AppTheme.lightTheme,
          routerConfig: AppRouter.router,
          debugShowCheckedModeBanner: false,
          // Localization configuration
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en'), // English
          ],
          // Wrap app with debug overlay and update notification listener
          builder: (context, child) {
            return UpdateNotificationListener(
              child: DebugOverlay(child: child ?? const SizedBox.shrink()),
            );
          },
        ),
      ),
    );

    _log(
      '✅ Widget tree built (${DateTime.now().difference(buildStart).inMilliseconds}ms)',
    );
    return widget;
  }
}
