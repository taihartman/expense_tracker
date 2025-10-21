import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubits/trip_cubit.dart';
import '../cubits/trip_state.dart';
import '../../domain/models/trip.dart';
import '../../../../core/theme/app_theme.dart';

/// Widget for selecting the current trip
/// Displays current trip name and base currency, with a dropdown to switch trips
class TripSelectorWidget extends StatelessWidget {
  const TripSelectorWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TripCubit, TripState>(
      builder: (context, state) {
        if (state is TripLoading) {
          return const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }

        if (state is TripLoaded) {
          final trips = state.trips;
          final selectedTrip = state.selectedTrip;

          if (trips.isEmpty) {
            return TextButton.icon(
              onPressed: () {
                // TODO: Navigate to trip creation page
              },
              icon: const Icon(Icons.add),
              label: const Text('Create Trip'),
            );
          }

          return DropdownButton<Trip>(
            value: selectedTrip,
            underline: Container(),
            items: trips.map((trip) {
              return DropdownMenuItem<Trip>(
                value: trip,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      trip.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(width: AppTheme.spacing1),
                    Chip(
                      label: Text(
                        trip.baseCurrency.name.toUpperCase(),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSecondaryContainer,
                            ),
                      ),
                      backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacing1,
                      ),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ],
                ),
              );
            }).toList(),
            onChanged: (trip) {
              if (trip != null) {
                context.read<TripCubit>().selectTrip(trip);
              }
            },
          );
        }

        if (state is TripError) {
          return Text(
            'Error',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}
