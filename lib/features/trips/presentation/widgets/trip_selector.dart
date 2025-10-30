import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../cubits/trip_cubit.dart';
import '../cubits/trip_state.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/l10n/l10n_extensions.dart';

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
              _showTripSelector(
                context,
                state.trips,
                state.archivedTrips.length,
              );
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
                            color: Theme.of(
                              context,
                            ).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            trip.baseCurrency.code,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onPrimaryContainer,
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
            context.push(AppRoutes.tripCreate);
          },
          icon: const Icon(Icons.add),
          label: Text(context.l10n.tripCreateButton),
        );
      },
    );
  }

  void _showTripSelector(BuildContext context, List trips, int archivedCount) {
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
                    context.l10n.tripSelectTitle,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      Navigator.of(context).pop();
                      _showTripActionOptions(context);
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
                      onTap: () async {
                        await context.read<TripCubit>().selectTrip(trip);
                        if (context.mounted) {
                          Navigator.of(context).pop();
                        }
                      },
                    );
                  },
                ),
              ),
              // Add archived trips button at the bottom
              if (archivedCount > 0) ...[
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.archive),
                  title: Text(context.l10n.tripViewArchivedButton),
                  trailing: Text('($archivedCount)'),
                  onTap: () {
                    Navigator.of(bottomSheetContext).pop();
                    context.push(AppRoutes.tripArchived);
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showTripActionOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (bottomSheetContext) => Container(
        padding: const EdgeInsets.all(AppTheme.spacing2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.add_circle_outline),
              title: Text(context.l10n.tripCreateButton),
              subtitle: Text(context.l10n.tripCreateTitle),
              onTap: () {
                Navigator.of(bottomSheetContext).pop();
                context.push(AppRoutes.tripCreate);
              },
            ),
            ListTile(
              leading: const Icon(Icons.group_add),
              title: Text(context.l10n.tripJoinButton),
              subtitle: Text(context.l10n.tripJoinTitle),
              onTap: () {
                Navigator.of(bottomSheetContext).pop();
                context.push(AppRoutes.tripJoin);
              },
            ),
          ],
        ),
      ),
    );
  }
}
