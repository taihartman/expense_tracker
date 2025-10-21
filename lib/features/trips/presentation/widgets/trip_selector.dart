import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubits/trip_cubit.dart';
import '../cubits/trip_state.dart';
import '../../../../core/theme/app_theme.dart';

/// Widget for selecting the current trip
/// 
/// Shows current trip name and base currency, allows switching trips
class TripSelectorWidget extends StatelessWidget {
  const TripSelectorWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TripCubit, TripState>(
      builder: (context, state) {
        if (state is TripLoaded && state.selectedTrip != null) {
          final trip = state.selectedTrip!;
          
          return InkWell(
            onTap: () {
              _showTripSelector(context, state.trips);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacing2,
                vertical: AppTheme.spacing1,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.flight_takeoff,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: AppTheme.spacing1),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          trip.name,
                          style: Theme.of(context).textTheme.titleSmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            trip.baseCurrency.code,
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacing1),
                  Icon(
                    Icons.arrow_drop_down,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          );
        }

        if (state is TripLoading) {
          return const Padding(
            padding: EdgeInsets.all(AppTheme.spacing2),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }

        // No trip selected or error
        return TextButton.icon(
          onPressed: () {
            Navigator.of(context).pushNamed('/trip-create');
          },
          icon: const Icon(Icons.add),
          label: const Text('Create Trip'),
        );
      },
    );
  }

  void _showTripSelector(BuildContext context, List trips) {
    showModalBottomSheet(
      context: context,
      builder: (bottomSheetContext) => BlocProvider.value(
        value: context.read<TripCubit>(),
        child: Container(
          padding: const EdgeInsets.all(AppTheme.spacing2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Select Trip',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pushNamed('/trip-create');
                    },
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacing2),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: trips.length,
                  itemBuilder: (context, index) {
                    final trip = trips[index];
                    return ListTile(
                      leading: const Icon(Icons.flight_takeoff),
                      title: Text(trip.name),
                      subtitle: Text(trip.baseCurrency.code),
                      onTap: () {
                        context.read<TripCubit>().selectTrip(trip);
                        Navigator.of(context).pop();
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
