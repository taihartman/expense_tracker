import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../cubits/trip_cubit.dart';
import '../cubits/trip_state.dart';
import '../../../../core/theme/app_theme.dart';

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
      appBar: AppBar(title: const Text('My Trips')),
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
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.flight_takeoff, size: 64),
                    SizedBox(height: AppTheme.spacing2),
                    Text('No trips yet'),
                  ],
                ),
              );
            }

            _log('✅ Rendering ${state.trips.length} trips');
            return ListView.builder(
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
                      'Base: ${trip.baseCurrency.name.toUpperCase()}',
                    ),
                    trailing: isSelected
                        ? Icon(
                            Icons.check_circle,
                            color: Theme.of(context).colorScheme.primary,
                          )
                        : null,
                    onTap: () {
                      context.read<TripCubit>().selectTrip(trip);
                      Navigator.of(context).pop();
                    },
                  ),
                );
              },
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
