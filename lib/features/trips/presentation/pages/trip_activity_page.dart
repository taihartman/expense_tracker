import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubits/activity_log_cubit.dart';
import '../widgets/activity_log_list.dart';

/// Page for displaying trip activity log
class TripActivityPage extends StatefulWidget {
  final String tripId;

  const TripActivityPage({super.key, required this.tripId});

  @override
  State<TripActivityPage> createState() => _TripActivityPageState();
}

class _TripActivityPageState extends State<TripActivityPage> {
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
    // Clear logs when leaving the page
    context.read<ActivityLogCubit>().clearLogs();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip Activity'),
        elevation: 0,
      ),
      body: ActivityLogList(tripId: widget.tripId),
    );
  }
}
