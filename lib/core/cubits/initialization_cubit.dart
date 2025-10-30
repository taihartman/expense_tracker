import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../firebase_options.dart';
import '../services/local_storage_service.dart';
import '../services/migration_service.dart';
import '../../shared/services/firestore_service.dart';

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

/// States for app initialization
abstract class InitializationState {}

/// Initial state before initialization starts
class InitializationInitial extends InitializationState {}

/// Initialization is in progress
class InitializationInProgress extends InitializationState {
  final String currentStep;

  InitializationInProgress(this.currentStep);
}

/// Initialization completed successfully
class InitializationComplete extends InitializationState {
  final LocalStorageService localStorageService;

  InitializationComplete(this.localStorageService);
}

/// Initialization failed
class InitializationError extends InitializationState {
  final String message;
  final Object? error;
  final StackTrace? stackTrace;

  InitializationError(this.message, {this.error, this.stackTrace});
}

/// Cubit that manages async initialization of Firebase and other services
class InitializationCubit extends Cubit<InitializationState> {
  InitializationCubit() : super(InitializationInitial());

  /// Initialize all required services
  Future<void> initialize() async {
    try {
      final startTime = DateTime.now();
      _log('🚀 InitializationCubit: Starting initialization...');

      // Step 1: Initialize Firebase
      emit(InitializationInProgress('Initializing Firebase...'));
      _log('📡 Step 1/5: Starting Firebase initialization...');
      final firebaseStart = DateTime.now();
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _log(
        '✅ Firebase initialized (${DateTime.now().difference(firebaseStart).inMilliseconds}ms)',
      );

      // Step 2: Sign in anonymously
      emit(InitializationInProgress('Authenticating...'));
      _log('🔐 Step 2/5: Signing in anonymously...');
      final authStart = DateTime.now();
      try {
        final userCredential = await FirebaseAuth.instance.signInAnonymously();
        _log(
          '✅ Anonymous auth successful - UID: ${userCredential.user?.uid} (${DateTime.now().difference(authStart).inMilliseconds}ms)',
        );
      } catch (e, stackTrace) {
        _logError('Anonymous Auth Failed', e, stackTrace);
        // Re-throw to fail initialization if auth is critical
        emit(
          InitializationError(
            'Authentication failed. Please check your internet connection.',
            error: e,
            stackTrace: stackTrace,
          ),
        );
        return;
      }

      // Step 3: Configure Firestore persistence
      emit(InitializationInProgress('Configuring database...'));
      _log('💾 Step 3/5: Configuring Firestore persistence...');
      final persistenceStart = DateTime.now();
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: 104857600, // 100MB cache limit
      );
      _log(
        '✅ Firestore persistence configured (${DateTime.now().difference(persistenceStart).inMilliseconds}ms)',
      );

      // Step 4: Initialize LocalStorageService
      emit(InitializationInProgress('Loading preferences...'));
      _log('💾 Step 4/5: Initializing LocalStorageService...');
      final storageStart = DateTime.now();
      final localStorageService = await LocalStorageService.init();
      _log(
        '✅ LocalStorageService initialized (${DateTime.now().difference(storageStart).inMilliseconds}ms)',
      );

      // Step 5: Run data migrations
      emit(InitializationInProgress('Running migrations...'));
      _log('🔄 Step 5/5: Running data migrations...');
      final migrationStart = DateTime.now();
      final prefs = await SharedPreferences.getInstance();
      final firestoreService = FirestoreService();
      final migrationService = MigrationService(
        firestoreService: firestoreService,
        prefs: prefs,
      );
      await migrationService.runMigrations();
      _log(
        '✅ Migrations completed (${DateTime.now().difference(migrationStart).inMilliseconds}ms)',
      );

      // All done!
      final totalTime = DateTime.now().difference(startTime).inMilliseconds;
      _log('✅ InitializationCubit: All initialization completed ($totalTime ms)');
      emit(InitializationComplete(localStorageService));
    } catch (e, stackTrace) {
      _logError('Initialization Failed', e, stackTrace);
      emit(
        InitializationError(
          'Failed to initialize app. Please restart and try again.',
          error: e,
          stackTrace: stackTrace,
        ),
      );
    }
  }
}
