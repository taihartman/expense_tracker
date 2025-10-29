import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../cubits/trip_cubit.dart';
import '../cubits/trip_state.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/l10n/l10n_extensions.dart';

/// Helper function to log with timestamps
void _log(String message) {
  debugPrint(
    '[${DateTime.now().toIso8601String()}] [ArchivedTripsPage] $message',
  );
}

/// Page displaying archived trips
class ArchivedTripsPage extends StatefulWidget {
  const ArchivedTripsPage({super.key});

  @override
  State<ArchivedTripsPage> createState() => _ArchivedTripsPageState();
}

class _ArchivedTripsPageState extends State<ArchivedTripsPage> {
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
    _log('🎨 Building ArchivedTripsPage');

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        title: Text(context.l10n.tripArchivedPageTitle),
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
            if (state.archivedTrips.isEmpty) {
              _log('📭 No archived trips to display');
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.archive,
                      size: 64,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: AppTheme.spacing2),
                    Text(
                      context.l10n.tripArchivedEmptyStateTitle,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppTheme.spacing1),
                    Text(
                      context.l10n.tripArchivedEmptyStateMessage,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              );
            }

            _log('✅ Rendering ${state.archivedTrips.length} archived trips');
            return ListView.builder(
              padding: const EdgeInsets.all(AppTheme.spacing2),
              itemCount: state.archivedTrips.length,
              itemBuilder: (context, index) {
                final trip = state.archivedTrips[index];
                final isSelected = state.selectedTrip?.id == trip.id;

                return Card(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: ListTile(
                    leading: Icon(
                      Icons.archive,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    title: Text(
                      trip.name,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    subtitle: Text(
                      '${context.l10n.tripBaseCurrencyPrefix}${trip.baseCurrency.name.toUpperCase()}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    trailing: PopupMenuButton(
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          child: Row(
                            children: [
                              const Icon(Icons.unarchive),
                              const SizedBox(width: AppTheme.spacing2),
                              const Text('Unarchive'),
                            ],
                          ),
                          onTap: () async {
                            // Delay to allow menu to close
                            await Future.delayed(
                              const Duration(milliseconds: 100),
                            );
                            if (context.mounted) {
                              await context.read<TripCubit>().unarchiveTrip(
                                trip.id,
                              );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '${context.l10n.tripUnarchiveSuccess}: "${trip.name}"',
                                    ),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            }
                          },
                        ),
                        PopupMenuItem(
                          child: Row(
                            children: [
                              const Icon(Icons.visibility),
                              const SizedBox(width: AppTheme.spacing2),
                              const Text('View'),
                            ],
                          ),
                          onTap: () async {
                            await Future.delayed(
                              const Duration(milliseconds: 100),
                            );
                            if (context.mounted) {
                              await context.read<TripCubit>().selectTrip(trip);
                              if (context.mounted) {
                                context.go('/');
                              }
                            }
                          },
                        ),
                      ],
                    ),
                    onTap: isSelected
                        ? null
                        : () async {
                            await context.read<TripCubit>().selectTrip(trip);
                            if (context.mounted) {
                              context.go('/');
                            }
                          },
                  ),
                );
              },
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}
