import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubits/trip_cubit.dart';
import '../cubits/trip_state.dart';
import '../../../../core/theme/app_theme.dart';

/// Page displaying all trips
class TripListPage extends StatelessWidget {
  const TripListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Trips'),
      ),
      body: BlocBuilder<TripCubit, TripState>(
        builder: (context, state) {
          if (state is TripLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is TripError) {
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
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.flight_takeoff, size: 64),
                    const SizedBox(height: AppTheme.spacing2),
                    const Text('No trips yet'),
                  ],
                ),
              );
            }

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
                      color: isSelected ? Theme.of(context).colorScheme.primary : null,
                    ),
                    title: Text(trip.name),
                    subtitle: Text('Base: ${trip.baseCurrency.name.toUpperCase()}'),
                    trailing: isSelected
                        ? Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary)
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
        onPressed: () => Navigator.of(context).pushNamed('/trips/create'),
        child: const Icon(Icons.add),
      ),
    );
  }
}
