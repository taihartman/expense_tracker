import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/l10n/l10n_extensions.dart';
import '../cubits/activity_log_cubit.dart';
import '../cubits/trip_cubit.dart';
import '../widgets/activity_log_list.dart';
import '../widgets/trip_verification_prompt.dart';

/// Page for displaying trip activity log
class TripActivityPage extends StatefulWidget {
  final String tripId;

  const TripActivityPage({super.key, required this.tripId});

  @override
  State<TripActivityPage> createState() => _TripActivityPageState();
}

class _TripActivityPageState extends State<TripActivityPage> {
  // Cache cubit reference to avoid accessing context in dispose()
  late ActivityLogCubit _activityLogCubit;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Cache the cubit reference safely during the widget lifecycle
    _activityLogCubit = context.read<ActivityLogCubit>();
  }

  @override
  void initState() {
    super.initState();
    // Load activity logs when page initializes
    Future.microtask(() {
      if (mounted) {
        context.read<ActivityLogCubit>().loadActivityLogs(widget.tripId);
      }
    });
  }

  @override
  void dispose() {
    // Clear logs when leaving the page using cached reference
    _activityLogCubit.clearLogs();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Check if user has verified their identity for this trip
    final tripCubit = context.read<TripCubit>();
    if (!tripCubit.isUserMemberOf(widget.tripId)) {
      return Scaffold(
        appBar: AppBar(
          title: Text(context.l10n.activityLogTitle),
          elevation: 0,
        ),
        body: TripVerificationPrompt(tripId: widget.tripId),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.activityLogTitle), elevation: 0),
      body: ActivityLogList(tripId: widget.tripId),
    );
  }
}
