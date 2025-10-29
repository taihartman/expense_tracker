import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubits/activity_log_cubit.dart';
import '../cubits/activity_log_state.dart';
import 'activity_log_item.dart';
import '../../../../core/theme/app_theme.dart';

/// Widget that displays a list of activity logs for a trip
class ActivityLogList extends StatelessWidget {
  final String tripId;

  const ActivityLogList({super.key, required this.tripId});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ActivityLogCubit, ActivityLogState>(
      builder: (context, state) {
        if (state is ActivityLogLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is ActivityLogError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: AppTheme.spacing2),
                Text(
                  'Failed to load activity log',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppTheme.spacing1),
                Text(
                  state.message,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.spacing3),
                ElevatedButton.icon(
                  onPressed: () {
                    context.read<ActivityLogCubit>().loadActivityLogs(tripId);
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (state is ActivityLogLoaded) {
          if (state.logs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history,
                    size: 64,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: AppTheme.spacing2),
                  Text(
                    'No activity yet',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppTheme.spacing1),
                  Text(
                    'Trip activity will appear here',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppTheme.spacing2),
            itemCount: state.logs.length,
            itemBuilder: (context, index) {
              return ActivityLogItem(log: state.logs[index]);
            },
          );
        }

        // Initial state - load activity logs
        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}
