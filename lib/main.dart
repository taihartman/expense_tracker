import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';

/// Application entry point
///
/// Initializes Firebase and launches the Flutter application
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
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

  runApp(const ExpenseTrackerApp());
}

/// Root application widget
class ExpenseTrackerApp extends StatelessWidget {
  const ExpenseTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Expense Tracker',
      theme: AppTheme.lightTheme,
      routerConfig: AppRouter.router,
      debugShowCheckedModeBanner: false,
    );
  }
}
