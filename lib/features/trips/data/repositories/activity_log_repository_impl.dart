import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/activity_log.dart';
import '../../domain/repositories/activity_log_repository.dart';
import '../models/activity_log_model.dart';

/// Firestore implementation of ActivityLogRepository
///
/// Stores activity logs in a subcollection under each trip:
/// /trips/{tripId}/activityLog/{logId}
class ActivityLogRepositoryImpl implements ActivityLogRepository {
  final FirebaseFirestore _firestore;

  ActivityLogRepositoryImpl({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<String> addLog(ActivityLog log) async {
    final model = ActivityLogModel.fromDomain(log);
    final docRef = await _firestore
        .collection('trips')
        .doc(log.tripId)
        .collection('activityLog')
        .add(model.toFirestore());

    return docRef.id;
  }

  @override
  Stream<List<ActivityLog>> getActivityLogs(
    String tripId, {
    int limit = 50,
  }) {
    return _firestore
        .collection('trips')
        .doc(tripId)
        .collection('activityLog')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ActivityLogModel.fromFirestore(doc))
          .toList();
    });
  }
}
