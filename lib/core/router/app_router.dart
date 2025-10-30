import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../presentation/pages/splash_page.dart';
import '../../features/trips/presentation/cubits/trip_cubit.dart';
import '../../features/trips/presentation/widgets/trip_selector.dart';
import '../../features/trips/presentation/cubits/trip_state.dart';
import '../../features/trips/presentation/pages/trip_list_page.dart';
import '../../features/trips/presentation/pages/trip_create_page.dart';
import '../../features/trips/presentation/pages/trip_join_page.dart';
import '../../features/trips/presentation/pages/trip_invite_page.dart';
import '../../features/trips/presentation/pages/trip_identity_selection_page.dart';
import '../../features/trips/presentation/pages/trip_activity_page.dart';
import '../../features/trips/presentation/pages/trip_edit_page.dart';
import '../../features/trips/presentation/pages/trip_settings_page.dart';
import '../../features/trips/presentation/pages/archived_trips_page.dart';
import '../../features/expenses/presentation/pages/expense_list_page.dart';
import '../../features/expenses/presentation/pages/expense_form_page.dart';
import '../../features/expenses/presentation/widgets/expense_form_bottom_sheet.dart';
import '../../features/expenses/presentation/cubits/expense_cubit.dart';
import '../../features/settlements/presentation/pages/settlement_summary_page.dart';
import '../theme/app_theme.dart';
import '../l10n/l10n_extensions.dart';

/// Check if user is a member of the trip (for route guarding)
/// DEPRECATED: No longer used for route-level blocking.
/// Identity verification is now handled at the page level.
// String? _checkTripMembership(BuildContext context, GoRouterState state) {
//   final tripId = state.pathParameters['tripId'];
//   if (tripId == null) return null;
//
//   // Get TripCubit to check membership
//   final tripCubit = context.read<TripCubit>();
//
//   // Check if user is a member of this trip
//   if (!tripCubit.isUserMemberOf(tripId)) {
//     // Check if trip exists and has participants
//     final trip = tripCubit.trips.where((t) => t.id == tripId).firstOrNull;
//
//     if (trip != null && trip.participants.isNotEmpty) {
//       // Redirect to identity selection page with return path
//       final returnPath = Uri.encodeComponent(state.uri.toString());
//       return '/trips/$tripId/identify?returnTo=$returnPath';
//     }
//
//     // Fallback to unauthorized for trips without participants
//     return '/unauthorized?tripId=$tripId';
//   }
//
//   return null; // Allow navigation
// }

/// App routing configuration using go_router
///
/// Note: BLoC providers are now managed at the app root level in main.dart
/// This ensures singleton cubit instances across all routes for proper caching
class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashPage(),
      ),
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
        path: '/trips/join',
        builder: (context, state) {
          final inviteCode = state.uri.queryParameters['code'];
          return TripJoinPage(inviteCode: inviteCode);
        },
      ),
      GoRoute(
        path: '/trips/archived',
        builder: (context, state) => const ArchivedTripsPage(),
      ),
      GoRoute(
        path: '/trips/:tripId/identify',
        builder: (context, state) {
          final tripId = state.pathParameters['tripId']!;
          final returnPath = state.uri.queryParameters['returnTo'];
          return TripIdentitySelectionPage(
            tripId: tripId,
            returnPath: returnPath,
          );
        },
      ),
      GoRoute(
        path: '/unauthorized',
        builder: (context, state) {
          final tripId = state.uri.queryParameters['tripId'];
          return _UnauthorizedPage(tripId: tripId);
        },
      ),
      GoRoute(
        path: '/trips/:tripId/edit',
        builder: (context, state) {
          final tripId = state.pathParameters['tripId']!;

          // Get trip from TripCubit
          final trip = context.read<TripCubit>().trips.firstWhere(
            (t) => t.id == tripId,
          );

          return TripEditPage(trip: trip);
        },
      ),
      GoRoute(
        path: '/trips/:tripId/settings',
        builder: (context, state) {
          final tripId = state.pathParameters['tripId']!;
          return TripSettingsPage(tripId: tripId);
        },
      ),
      GoRoute(
        path: '/trips/:tripId/invite',
        builder: (context, state) {
          final tripId = state.pathParameters['tripId']!;

          // Get trip from TripCubit
          final trip = context.read<TripCubit>().trips.firstWhere(
            (t) => t.id == tripId,
          );

          return TripInvitePage(trip: trip);
        },
      ),
      GoRoute(
        path: '/trips/:tripId/activity',
        builder: (context, state) {
          final tripId = state.pathParameters['tripId']!;
          return TripActivityPage(tripId: tripId);
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

          return ExpenseFormPage(tripId: tripId, expense: expense);
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
  Widget build(BuildContext context) {
    return const _HomePageContent();
  }
}

class _HomePageContent extends StatelessWidget {
  const _HomePageContent();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const TripSelectorWidget()),
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
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacing3),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.flight_takeoff,
                    size: 64,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: AppTheme.spacing2),
                  Text(
                    context.l10n.tripEmptyStateTitle,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppTheme.spacing1),
                  Text(
                    context.l10n.tripEmptyStateDescription,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppTheme.spacing3),
                  ElevatedButton.icon(
                    onPressed: () => context.go('/trips/create'),
                    icon: const Icon(Icons.add),
                    label: Text(context.l10n.tripCreateButton),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(200, 48),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacing2),
                  OutlinedButton.icon(
                    onPressed: () => context.push('/trips/join'),
                    icon: const Icon(Icons.group_add),
                    label: Text(context.l10n.tripJoinButton),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(200, 48),
                    ),
                  ),
                ],
              ),
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

/// Unauthorized access page
class _UnauthorizedPage extends StatelessWidget {
  final String? tripId;

  const _UnauthorizedPage({this.tripId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Access Denied')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline, size: 64, color: Colors.orange),
              const SizedBox(height: 24),
              Text(
                'Private Trip',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              Text(
                'You don\'t have access to this trip.',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Ask the trip creator to send you an invite link to join.',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => context.go('/'),
                icon: const Icon(Icons.home),
                label: const Text('Go to Home'),
              ),
              const SizedBox(height: 12),
              if (tripId != null)
                TextButton.icon(
                  onPressed: () => context.go('/trips/join?code=$tripId'),
                  icon: const Icon(Icons.vpn_key),
                  label: const Text('Try Joining This Trip'),
                ),
            ],
          ),
        ),
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
      appBar: AppBar(title: const Text('Error')),
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
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.go('/'),
              icon: const Icon(Icons.home),
              label: const Text('Go to Home'),
            ),
          ],
        ),
      ),
    );
  }
}
