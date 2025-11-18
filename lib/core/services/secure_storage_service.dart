import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Helper function to log with timestamps
void _log(String message) {
  debugPrint('[${DateTime.now().toIso8601String()}] [SecureStorage] $message');
}

/// Service for managing encrypted storage of sensitive data
///
/// Uses flutter_secure_storage which provides:
/// - iOS: Keychain
/// - Android: EncryptedSharedPreferences (AES encryption)
/// - Web: Web Crypto API with IndexedDB
/// - Desktop: Platform-specific secure storage
///
/// This service stores ONLY sensitive data:
/// - List of joined trip IDs
/// - User identity (participantId) per trip
///
/// Non-sensitive data (UI preferences, filters) should use LocalStorageService
class SecureStorageService {
  static const String _joinedTripIdsKey = 'secure_joined_trip_ids';
  static const String _tripIdentityKeyPrefix = 'secure_trip_identity_';

  final FlutterSecureStorage _secureStorage;

  SecureStorageService({FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(
                encryptedSharedPreferences: true,
              ),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock,
              ),
              webOptions: WebOptions(
                dbName: 'expense_tracker_secure',
                publicKey: 'expense_tracker_public_key',
              ),
            );

  /// Initialize the service
  static Future<SecureStorageService> init() async {
    _log('🔧 Initializing SecureStorageService...');
    _log('🌐 Platform: ${kIsWeb ? "Web" : "Native"}');

    final service = SecureStorageService();

    // Test read/write to verify storage is working
    try {
      await service._secureStorage.write(
        key: '_test_key',
        value: 'test',
      );
      final testRead = await service._secureStorage.read(key: '_test_key');
      if (testRead == 'test') {
        _log('✅ Secure storage read/write test passed');
        await service._secureStorage.delete(key: '_test_key');
      } else {
        _log('⚠️ Secure storage test failed: read returned $testRead');
      }
    } catch (e) {
      _log('❌ Secure storage test failed: $e');
    }

    _log('✅ SecureStorageService initialized');
    return service;
  }

  /// Get the list of joined trip IDs (encrypted)
  ///
  /// Returns an empty list if no trips have been joined
  Future<List<String>> getJoinedTripIds() async {
    _log('📖 Reading joined trip IDs from secure storage...');
    try {
      final String? jsonString =
          await _secureStorage.read(key: _joinedTripIdsKey);

      if (jsonString == null) {
        _log('📖 No joined trips found in secure storage');
        return [];
      }

      final List<dynamic> decoded = jsonDecode(jsonString);
      final List<String> tripIds = decoded.cast<String>();
      _log('📖 Found ${tripIds.length} joined trip(s): ${tripIds.join(", ")}');
      return tripIds;
    } catch (e) {
      _log('❌ Failed to read joined trip IDs: $e');
      return [];
    }
  }

  /// Add a trip ID to the list of joined trips (encrypted)
  Future<void> addJoinedTrip(String tripId) async {
    _log('➕ Adding joined trip ID to secure storage: $tripId');
    try {
      final currentIds = await getJoinedTripIds();

      if (currentIds.contains(tripId)) {
        _log('ℹ️ Trip ID $tripId already in joined trips list');
        return;
      }

      final updatedIds = [...currentIds, tripId];
      final jsonString = jsonEncode(updatedIds);

      await _secureStorage.write(
        key: _joinedTripIdsKey,
        value: jsonString,
      );

      _log('✅ Added trip ID. Total trips: ${updatedIds.length}');

      // Verification
      final verified = await getJoinedTripIds();
      if (!verified.contains(tripId)) {
        _log('⚠️ VERIFICATION FAILED: Trip ID $tripId not found after write!');
      } else {
        _log('✅ Verification passed: Trip ID $tripId confirmed in storage');
      }
    } catch (e) {
      _log('❌ Failed to add joined trip: $e');
      throw Exception('Failed to add joined trip: $e');
    }
  }

  /// Remove a trip ID from the list of joined trips (encrypted)
  Future<void> removeJoinedTrip(String tripId) async {
    _log('➖ Removing joined trip ID from secure storage: $tripId');
    try {
      final currentIds = await getJoinedTripIds();

      if (!currentIds.contains(tripId)) {
        _log('ℹ️ Trip ID $tripId not found in joined trips list');
        return;
      }

      final updatedIds = currentIds.where((id) => id != tripId).toList();
      final jsonString = jsonEncode(updatedIds);

      await _secureStorage.write(
        key: _joinedTripIdsKey,
        value: jsonString,
      );

      _log('✅ Removed trip ID. Remaining trips: ${updatedIds.length}');
    } catch (e) {
      _log('❌ Failed to remove joined trip: $e');
      throw Exception('Failed to remove joined trip: $e');
    }
  }

  /// Verify that a trip ID is in the joined trips list
  Future<bool> verifyJoinedTrip(String tripId) async {
    _log('🔍 Verifying trip ID in secure storage: $tripId');
    final joinedIds = await getJoinedTripIds();
    final isPresent = joinedIds.contains(tripId);
    _log('🔍 Verification result: ${isPresent ? "FOUND" : "NOT FOUND"}');
    return isPresent;
  }

  /// Get the user's identity (participantId) for a specific trip (encrypted)
  ///
  /// Returns null if the user has not selected their identity for this trip
  Future<String?> getUserIdentityForTrip(String tripId) async {
    final key = '$_tripIdentityKeyPrefix$tripId';
    _log('📖 Reading user identity for trip $tripId from secure storage...');
    try {
      final participantId = await _secureStorage.read(key: key);
      _log('📖 User identity: ${participantId ?? "null (not set)"}');
      return participantId;
    } catch (e) {
      _log('❌ Failed to read user identity: $e');
      return null;
    }
  }

  /// Save the user's identity (participantId) for a specific trip (encrypted)
  Future<void> saveUserIdentityForTrip(
    String tripId,
    String participantId,
  ) async {
    final key = '$_tripIdentityKeyPrefix$tripId';
    _log('💾 Saving user identity for trip $tripId: $participantId');
    _log('💾 Using key: $key');
    try {
      await _secureStorage.write(key: key, value: participantId);
      _log('✅ User identity saved');

      // Verification
      final verified = await _secureStorage.read(key: key);
      _log('🔍 Verification: $verified');
    } catch (e) {
      _log('❌ Failed to save user identity: $e');
      throw Exception('Failed to save user identity: $e');
    }
  }

  /// Remove the user's identity for a specific trip (encrypted)
  Future<void> removeUserIdentityForTrip(String tripId) async {
    final key = '$_tripIdentityKeyPrefix$tripId';
    _log('🗑️ Removing user identity for trip $tripId');
    try {
      await _secureStorage.delete(key: key);
      _log('✅ User identity removed');
    } catch (e) {
      _log('❌ Failed to remove user identity: $e');
      throw Exception('Failed to remove user identity: $e');
    }
  }

  /// Clear all user identities for all trips (encrypted)
  Future<void> clearAllUserIdentities() async {
    _log('🗑️ Clearing all user identities from secure storage');
    try {
      final allKeys = await _secureStorage.readAll();
      final identityKeys = allKeys.keys.where(
        (k) => k.startsWith(_tripIdentityKeyPrefix),
      );

      for (final key in identityKeys) {
        await _secureStorage.delete(key: key);
      }

      _log('✅ Cleared ${identityKeys.length} user identity entries');
    } catch (e) {
      _log('❌ Failed to clear user identities: $e');
      throw Exception('Failed to clear user identities: $e');
    }
  }

  /// Clear all secure storage data
  ///
  /// ⚠️ WARNING: This will delete all encrypted data including trip IDs and identities
  Future<void> clearAll() async {
    _log('🗑️ Clearing ALL secure storage data');
    try {
      await _secureStorage.deleteAll();
      _log('✅ All secure storage cleared');
    } catch (e) {
      _log('❌ Failed to clear secure storage: $e');
      throw Exception('Failed to clear secure storage: $e');
    }
  }

  /// Migrate data from plain-text SharedPreferences to encrypted storage
  ///
  /// This is a one-time migration for existing users
  Future<void> migrateFromPlainText({
    required List<String> plainTextTripIds,
    required Map<String, String> plainTextIdentities,
  }) async {
    _log('🔄 Migrating data from plain-text to encrypted storage...');
    try {
      // Migrate trip IDs
      if (plainTextTripIds.isNotEmpty) {
        _log('🔄 Migrating ${plainTextTripIds.length} trip IDs...');
        final jsonString = jsonEncode(plainTextTripIds);
        await _secureStorage.write(
          key: _joinedTripIdsKey,
          value: jsonString,
        );
        _log('✅ Trip IDs migrated');
      }

      // Migrate user identities
      if (plainTextIdentities.isNotEmpty) {
        _log('🔄 Migrating ${plainTextIdentities.length} user identities...');
        for (final entry in plainTextIdentities.entries) {
          final tripId = entry.key;
          final participantId = entry.value;
          await saveUserIdentityForTrip(tripId, participantId);
        }
        _log('✅ User identities migrated');
      }

      _log('✅ Migration complete');
    } catch (e) {
      _log('❌ Migration failed: $e');
      throw Exception('Migration failed: $e');
    }
  }
}
