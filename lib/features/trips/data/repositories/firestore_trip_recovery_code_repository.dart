import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/repositories/trip_recovery_code_repository.dart';
import '../../domain/models/trip_recovery_code.dart';
import '../../../../core/utils/code_generator.dart';

/// Firestore implementation of TripRecoveryCodeRepository
class FirestoreTripRecoveryCodeRepository
    implements TripRecoveryCodeRepository {
  final FirebaseFirestore _firestore;

  FirestoreTripRecoveryCodeRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Get reference to recovery code document for a trip
  DocumentReference _getRecoveryCodeDoc(String tripId) {
    return _firestore
        .collection('trips')
        .doc(tripId)
        .collection('recovery')
        .doc('code');
  }

  @override
  Future<TripRecoveryCode> generateRecoveryCode(String tripId) async {
    final docRef = _getRecoveryCodeDoc(tripId);

    // Check if recovery code already exists
    final existingDoc = await docRef.get();
    if (existingDoc.exists) {
      throw Exception('Recovery code already exists for this trip');
    }

    // Generate new recovery code
    final code = CodeGenerator.generateRecoveryCode();
    final recoveryCode = TripRecoveryCode(
      code: code,
      tripId: tripId,
      createdAt: DateTime.now(),
      usedCount: 0,
    );

    // Store in Firestore
    await docRef.set(recoveryCode.toFirestore());

    return recoveryCode;
  }

  @override
  Future<TripRecoveryCode?> getRecoveryCode(String tripId) async {
    final docRef = _getRecoveryCodeDoc(tripId);
    final doc = await docRef.get();

    if (!doc.exists) {
      return null;
    }

    return TripRecoveryCode.fromFirestore(doc);
  }

  @override
  Future<TripRecoveryCode?> validateRecoveryCode(
    String tripId,
    String code,
  ) async {
    final docRef = _getRecoveryCodeDoc(tripId);
    final doc = await docRef.get();

    if (!doc.exists) {
      return null;
    }

    final recoveryCode = TripRecoveryCode.fromFirestore(doc);

    // Normalize codes for comparison (remove hyphens/spaces)
    final normalizedInput = code.replaceAll('-', '').replaceAll(' ', '');
    final normalizedStored = recoveryCode.code
        .replaceAll('-', '')
        .replaceAll(' ', '');

    if (normalizedInput != normalizedStored) {
      return null;
    }

    // Valid! Increment usage count
    final updatedCode = recoveryCode.copyWith(
      usedCount: recoveryCode.usedCount + 1,
      lastUsedAt: DateTime.now(),
    );

    await docRef.update({
      'usedCount': updatedCode.usedCount,
      'lastUsedAt': Timestamp.fromDate(updatedCode.lastUsedAt!),
    });

    return updatedCode;
  }

  @override
  Future<bool> hasRecoveryCode(String tripId) async {
    final docRef = _getRecoveryCodeDoc(tripId);
    final doc = await docRef.get();
    return doc.exists;
  }
}
