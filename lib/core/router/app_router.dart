import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/trips/presentation/cubits/trip_cubit.dart';
import '../../features/trips/presentation/widgets/trip_selector.dart';
import '../../features/trips/presentation/cubits/trip_state.dart';
import '../../features/trips/presentation/pages/trip_list_page.dart';
import '../../features/trips/presentation/pages/trip_create_page.dart';
import '../../features/trips/presentation/pages/trip_settings_page.dart';
import '../../features/expenses/presentation/pages/expense_list_page.dart';
import '../../features/expenses/presentation/pages/expense_form_page.dart';
import '../../features/expenses/presentation/widgets/expense_form_bottom_sheet.dart';
import '../../features/expenses/presentation/cubits/expense_cubit.dart';
import '../../features/settlements/presentation/pages/settlement_summary_page.dart';

/// App routing configuration using go_router
///
/// Note: BLoC providers are now managed at the app root level in main.dart
/// This ensures singleton cubit instances across all routes for proper caching
class AppRouter {

  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: '/trips',
        builder: (context, state) => const TripListPage(),
      ),
      GoRoute(
        path: '/trips/create',
        builder: (context, state) => const TripCreatePage(),
      ),
      GoRoute(
        path: '/trips/:tripId/settings',
        builder: (context, state) {
          final tripId = state.pathParameters['tripId']!;
          return TripSettingsPage(tripId: tripId);
        },
      ),
      GoRoute(
        path: '/trips/:tripId/expenses',
        builder: (context, state) {
          final tripId = state.pathParameters['tripId']!;
          return ExpenseListPage(tripId: tripId);
        },
      ),
      GoRoute(
        path: '/trips/:tripId/expenses/create',
        builder: (context, state) {
          final tripId = state.pathParameters['tripId']!;
          return ExpenseFormPage(tripId: tripId);
        },
      ),
      GoRoute(
        path: '/trips/:tripId/expenses/:expenseId/edit',
        builder: (context, state) {
          final tripId = state.pathParameters['tripId']!;
          final expenseId = state.pathParameters['expenseId']!;

          // Get expense from ExpenseCubit
          final expense = context.read<ExpenseCubit>().expenses.firstWhere(
            (e) => e.id == expenseId,
          );

          return ExpenseFormPage(
            tripId: tripId,
            expense: expense,
          );
        },
      ),
      GoRoute(
        path: '/trips/:tripId/settlement',
        builder: (context, state) {
          final tripId = state.pathParameters['tripId']!;
          return SettlementSummaryPage(tripId: tripId);
        },
      ),
    ],
    errorBuilder: (context, state) => _ErrorPage(error: state.error),
  );
}

/// Home page with trip selector and expense list
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    // Load trips when home page initializes (lazy loading)
    Future.microtask(() {
      if (mounted) {
        context.read<TripCubit>().loadTrips();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const _HomePageContent();
  }
}

class _HomePageContent extends StatelessWidget {
  const _HomePageContent();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const TripSelectorWidget(),
        actions: [
          IconButton(
            icon: const Icon(Icons.list),
            tooltip: 'All Trips',
            onPressed: () {
              context.go('/trips');
            },
          ),
        ],
      ),
      body: BlocBuilder<TripCubit, TripState>(
        builder: (context, state) {
          if (state is TripLoaded && state.selectedTrip != null) {
            final tripId = state.selectedTrip!.id;
            
            // Load expenses for selected trip
            context.read<ExpenseCubit>().loadExpenses(tripId);
            
            return ExpenseListPage(tripId: tripId);
          }

          if (state is TripLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          // No trips yet
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.flight_takeoff, size: 64),
                const SizedBox(height: 16),
                const Text('No trips yet'),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => context.go('/trips/create'),
                  child: const Text('Create Your First Trip'),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: BlocBuilder<TripCubit, TripState>(
        builder: (context, state) {
          if (state is TripLoaded && state.selectedTrip != null) {
            return FloatingActionButton(
              onPressed: () {
                showExpenseFormBottomSheet(
                  context: context,
                  tripId: state.selectedTrip!.id,
                );
              },
              child: const Icon(Icons.add),
            );
          }
          return const SizedBox.shrink();
        },
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
