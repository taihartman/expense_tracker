import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/trips/presentation/cubits/trip_cubit.dart';
import '../../features/trips/presentation/widgets/trip_selector.dart';
import '../../features/trips/presentation/cubits/trip_state.dart';
import '../../features/trips/presentation/pages/trip_list_page.dart';
import '../../features/trips/presentation/pages/trip_create_page.dart';
import '../../features/expenses/presentation/pages/expense_list_page.dart';
import '../../features/expenses/presentation/pages/expense_form_page.dart';
import '../../features/trips/data/repositories/trip_repository_impl.dart';
import '../../features/expenses/data/repositories/expense_repository_impl.dart';
import '../../features/expenses/presentation/cubits/expense_cubit.dart';
import '../../shared/services/firestore_service.dart';

/// App routing configuration using go_router
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
    ],
    errorBuilder: (context, state) => _ErrorPage(error: state.error),
  );
}

/// Home page with trip selector and expense list
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(
          create: (context) => TripRepositoryImpl(
            firestoreService: FirestoreService(),
          ),
        ),
        RepositoryProvider(
          create: (context) => ExpenseRepositoryImpl(
            firestoreService: FirestoreService(),
          ),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => TripCubit(
              tripRepository: context.read<TripRepositoryImpl>(),
            )..loadTrips(),
          ),
          BlocProvider(
            create: (context) => ExpenseCubit(
              expenseRepository: context.read<ExpenseRepositoryImpl>(),
            ),
          ),
        ],
        child: const _HomePageContent(),
      ),
    );
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
                context.go('/trips/${state.selectedTrip!.id}/expenses/create');
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
