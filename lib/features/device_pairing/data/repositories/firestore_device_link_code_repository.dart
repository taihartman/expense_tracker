import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/device_link_code.dart';
import '../../domain/repositories/device_link_code_repository.dart';
import '../../../../core/utils/code_generator.dart';

/// Firestore implementation of [DeviceLinkCodeRepository].
///
/// Stores device link codes in subcollection:
/// `/trips/{tripId}/deviceLinkCodes/{autoId}`
class FirestoreDeviceLinkCodeRepository implements DeviceLinkCodeRepository {
  final FirebaseFirestore _firestore;

  FirestoreDeviceLinkCodeRepository({
    required FirebaseFirestore firestore,
  }) : _firestore = firestore;

  @override
  Future<DeviceLinkCode> generateCode(String tripId, String memberName) async {
    // 1. Invalidate previous unused codes for this member (case-insensitive)
    final memberNameLower = memberName.toLowerCase();
    final previousCodesQuery = await _getCodesCollection(tripId)
        .where('memberNameLower', isEqualTo: memberNameLower)
        .where('used', isEqualTo: false)
        .get();

    // Mark all previous codes as used
    final now = DateTime.now();
    for (final doc in previousCodesQuery.docs) {
      await doc.reference.update({
        'used': true,
        'usedAt': Timestamp.fromDate(now),
      });
    }

    // 2. Generate new 8-digit code
    final code = CodeGenerator.generate();

    // 3. Create new code entity
    final createdAt = DateTime.now();
    final expiresAt = createdAt.add(const Duration(minutes: 15));

    final newCode = DeviceLinkCode(
      id: '', // Will be set after Firestore generates it
      code: code,
      tripId: tripId,
      memberName: memberName,
      createdAt: createdAt,
      expiresAt: expiresAt,
      used: false,
      usedAt: null,
    );

    // 4. Save to Firestore
    final docRef = await _getCodesCollection(tripId).add(_codeToMap(newCode));

    // 5. Return entity with generated ID
    return newCode.copyWith(id: docRef.id);
  }

  @override
  Future<DeviceLinkCode> validateCode(String tripId, String code, String memberName) async {
    // 1. Normalize code (remove hyphens for consistent querying)
    final normalizedCode = _normalizeCode(code);

    // 2. Query Firestore for matching code with tripId
    final codesQuery = await _getCodesCollection(tripId)
        .where('code', isEqualTo: normalizedCode)
        .where('tripId', isEqualTo: tripId)
        .get();

    // Validation Rule 1: Code exists
    if (codesQuery.docs.isEmpty) {
      throw Exception('Invalid code');
    }

    final codeDoc = codesQuery.docs.first;
    final codeData = codeDoc.data() as Map<String, dynamic>;
    final now = DateTime.now();

    // Validation Rule 2: Not expired
    final expiresAt = (codeData['expiresAt'] as Timestamp).toDate();
    if (now.isAfter(expiresAt)) {
      throw Exception('Code has expired');
    }

    // Validation Rule 3: Not used
    final used = codeData['used'] as bool;
    if (used) {
      throw Exception('Code has already been used');
    }

    // Validation Rule 4: Trip matches (already filtered in query)
    // This is implicitly validated by the where clause above

    // Validation Rule 5: Member name matches (case-insensitive)
    final codeMemberName = codeData['memberName'] as String;
    if (codeMemberName.toLowerCase() != memberName.toLowerCase()) {
      throw Exception('Member name does not match');
    }

    // Validation Rule 6: Rate limiting (placeholder for now)
    // TODO: Implement rate limiting in Phase 6 (User Story 4)
    // Will check _getAttemptsCollection() for attempts in last 60 seconds

    // All validations passed - mark code as used
    await codeDoc.reference.update({
      'used': true,
      'usedAt': Timestamp.fromDate(now),
    });

    // Return the validated code entity
    return _documentToCode(codeDoc);
  }

  /// Normalizes a code by ensuring it has the standard XXXX-XXXX format
  String _normalizeCode(String code) {
    // Remove any existing hyphens
    final digitsOnly = code.replaceAll('-', '');

    // Add hyphen in the middle if not present
    if (digitsOnly.length == 8 && !code.contains('-')) {
      return '${digitsOnly.substring(0, 4)}-${digitsOnly.substring(4)}';
    }

    return code;
  }

  @override
  Future<void> revokeCode(String tripId, String codeId) async {
    // TODO: Implement code revocation
    // Delete code document from Firestore
    throw UnimplementedError('revokeCode not yet implemented');
  }

  @override
  Future<List<DeviceLinkCode>> getActiveCodes(String tripId) async {
    // TODO: Implement fetching active codes
    // 1. Query Firestore for codes where used=false and expiresAt>now
    // 2. Convert documents to DeviceLinkCode entities
    // 3. Sort by expiresAt
    // 4. Return list
    throw UnimplementedError('getActiveCodes not yet implemented');
  }

  @override
  Stream<List<DeviceLinkCode>> watchActiveCodes(String tripId) {
    // TODO: Implement real-time watching of active codes
    // Return Firestore snapshot stream
    throw UnimplementedError('watchActiveCodes not yet implemented');
  }

  /// Helper: Get reference to deviceLinkCodes subcollection for a trip
  CollectionReference _getCodesCollection(String tripId) {
    return _firestore
        .collection('trips')
        .doc(tripId)
        .collection('deviceLinkCodes');
  }

  /// Helper: Get reference to validationAttempts subcollection for rate limiting
  CollectionReference _getAttemptsCollection(String tripId) {
    return _firestore
        .collection('trips')
        .doc(tripId)
        .collection('validationAttempts');
  }

  /// Helper: Convert Firestore document to DeviceLinkCode entity
  DeviceLinkCode _documentToCode(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DeviceLinkCode(
      id: doc.id,
      code: data['code'] as String,
      tripId: data['tripId'] as String,
      memberName: data['memberName'] as String,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      expiresAt: (data['expiresAt'] as Timestamp).toDate(),
      used: data['used'] as bool,
      usedAt: data['usedAt'] != null
          ? (data['usedAt'] as Timestamp).toDate()
          : null,
    );
  }

  /// Helper: Convert DeviceLinkCode entity to Firestore map
  Map<String, dynamic> _codeToMap(DeviceLinkCode code) {
    return {
      'code': code.code,
      'tripId': code.tripId,
      'memberName': code.memberName,
      'memberNameLower': code.memberName.toLowerCase(),
      'createdAt': Timestamp.fromDate(code.createdAt),
      'expiresAt': Timestamp.fromDate(code.expiresAt),
      'used': code.used,
      'usedAt': code.usedAt != null ? Timestamp.fromDate(code.usedAt!) : null,
    };
  }
}
