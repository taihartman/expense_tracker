import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';

/// App routing configuration using go_router
/// Supports deep linking and navigation state management
class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const _PlaceholderHomePage(),
      ),
      // Additional routes will be added as features are implemented:
      // - /trips (trip list)
      // - /trips/:tripId/expenses (expense list)
      // - /trips/:tripId/expenses/new (expense form)
      // - /trips/:tripId/settlement (settlement summary)
      // - /trips/:tripId/fx-rates (exchange rate management)
      // - /trips/:tripId/categories (category management)
      // - /trips/:tripId/person/:userId (person dashboard)
    ],
    errorBuilder: (context, state) => _ErrorPage(error: state.error),
  );
}

/// Placeholder home page (to be replaced in Phase 3)
class _PlaceholderHomePage extends StatelessWidget {
  const _PlaceholderHomePage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Tracker'),
      ),
      body: const Center(
        child: Text('Home Page - Implementation in progress'),
      ),
    );
  }
}

/// Error page for navigation failures
class _ErrorPage extends StatelessWidget {
  final Exception? error;

  const _ErrorPage({this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Error'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Navigation Error',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              error?.toString() ?? 'Unknown error',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
