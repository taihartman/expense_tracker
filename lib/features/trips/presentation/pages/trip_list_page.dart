import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../cubits/trip_cubit.dart';
import '../cubits/trip_state.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/l10n/l10n_extensions.dart';

/// Helper function to log with timestamps
void _log(String message) {
  debugPrint('[${DateTime.now().toIso8601String()}] [TripListPage] $message');
}

/// Page displaying all trips
class TripListPage extends StatefulWidget {
  const TripListPage({super.key});

  @override
  State<TripListPage> createState() => _TripListPageState();
}

class _TripListPageState extends State<TripListPage> {
  @override
  void initState() {
    super.initState();
    // Load trips when page initializes (lazy loading)
    _log('🔄 initState: Loading trips...');
    Future.microtask(() {
      if (mounted) {
        context.read<TripCubit>().loadTrips();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    _log('🎨 Building TripListPage');

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        title: Text(context.l10n.tripListTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.group_add),
            tooltip: context.l10n.tripJoinTitle,
            onPressed: () => context.push('/trips/join'),
          ),
        ],
      ),
      body: BlocBuilder<TripCubit, TripState>(
        builder: (context, state) {
          _log('🔄 BlocBuilder rebuilding with state: ${state.runtimeType}');

          if (state is TripLoading) {
            _log('⏳ Showing loading indicator');
            return const Center(child: CircularProgressIndicator());
          }

          if (state is TripError) {
            _log('❌ Showing error: ${state.message}');
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: AppTheme.spacing2),
                  Text(state.message),
                ],
              ),
            );
          }

          if (state is TripLoaded) {
            if (state.trips.isEmpty) {
              _log('📭 No trips to display');
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.flight_takeoff, size: 64),
                    const SizedBox(height: AppTheme.spacing2),
                    Text(context.l10n.tripEmptyStateTitle),
                  ],
                ),
              );
            }

            _log('✅ Rendering ${state.trips.length} trips');
            return Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(AppTheme.spacing2),
                    itemCount: state.trips.length,
                    itemBuilder: (context, index) {
                      final trip = state.trips[index];
                      final isSelected = state.selectedTrip?.id == trip.id;

                      return Card(
                        child: ListTile(
                          leading: Icon(
                            Icons.flight_takeoff,
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : null,
                          ),
                          title: Text(trip.name),
                          subtitle: Text(
                            '${context.l10n.tripBaseCurrencyPrefix}${trip.baseCurrency.name.toUpperCase()}',
                          ),
                          trailing: isSelected
                              ? Icon(
                                  Icons.check_circle,
                                  color: Theme.of(context).colorScheme.primary,
                                )
                              : null,
                          onTap: () async {
                            await context.read<TripCubit>().selectTrip(trip);
                            if (context.mounted) {
                              context.go('/');
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),
                // View Archived Trips button
                if (state.archivedTrips.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(AppTheme.spacing2),
                    child: OutlinedButton.icon(
                      onPressed: () => context.push('/trips/archived'),
                      icon: const Icon(Icons.archive),
                      label: Text(
                        'View Archived Trips (${state.archivedTrips.length})',
                      ),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),
                  ),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/trips/create'),
        child: const Icon(Icons.add),
      ),
    );
  }
}
