import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'secure_storage_service.dart';

// Conditional import for web-specific functionality
import 'web_storage_stub.dart' if (dart.library.html) 'dart:html' as html;

/// Helper function to log with timestamps
void _log(String message) {
  debugPrint('[${DateTime.now().toIso8601String()}] [LocalStorage] $message');
}

/// Service for managing local storage
///
/// SECURITY UPDATE: This service now uses two storage backends:
/// 1. SecureStorageService (encrypted) for sensitive data:
///    - Joined trip IDs
///    - User identities per trip
/// 2. SharedPreferences (plain-text) for non-sensitive data:
///    - Selected trip ID (transient UI state)
///    - Settlement filters (UI preferences)
///
/// Migration: Automatically migrates existing plain-text data to encrypted storage
class LocalStorageService {
  static const String _selectedTripIdKey = 'selected_trip_id';
  static const String _joinedTripIdsKey = 'joined_trip_ids';  // Legacy key
  static const String _tripIdentityKeyPrefix = 'trip_identity_';  // Legacy prefix
  static const String _settlementFilterUserKeyPrefix = 'settlement_filter_user_';
  static const String _settlementFilterModeKeyPrefix = 'settlement_filter_mode_';
  static const String _migrationCompletedKey = 'secure_storage_migration_completed';

  final SharedPreferences _prefs;
  final SecureStorageService _secureStorage;

  LocalStorageService(this._prefs, this._secureStorage);

  /// Initialize the service
  ///
  /// This must be called before using the service
  /// Automatically migrates sensitive data to encrypted storage
  static Future<LocalStorageService> init() async {
    _log('🔧 Initializing LocalStorageService...');
    _log('🌐 Platform: ${kIsWeb ? "Web" : "Native"}');

    final prefs = await SharedPreferences.getInstance();
    _log('✅ SharedPreferences instance obtained');

    // Initialize secure storage
    final secureStorage = await SecureStorageService.init();
    _log('✅ SecureStorageService initialized');

    // Log all existing keys for debugging
    final keys = prefs.getKeys();
    _log(
      '📋 Existing SharedPreferences keys: ${keys.isEmpty ? "none" : keys.join(", ")}',
    );

    // On web, check browser localStorage directly
    if (kIsWeb) {
      try {
        final storage = html.window.localStorage;
        _log('🌐 Browser localStorage keys: ${storage.keys.toList()}');
        _log('🌐 Browser localStorage length: ${storage.length}');
      } catch (e) {
        _log('⚠️ Failed to access browser localStorage: $e');
      }
    }

    final service = LocalStorageService(prefs, secureStorage);

    // Migrate legacy plain-text data to encrypted storage (one-time)
    await service._migrateSensitiveData();

    return service;
  }

  /// Migrate sensitive data from plain-text to encrypted storage
  ///
  /// This is a one-time migration that runs on app initialization
  Future<void> _migrateSensitiveData() async {
    // Check if migration already completed
    final migrationCompleted = _prefs.getBool(_migrationCompletedKey) ?? false;
    if (migrationCompleted) {
      _log('✅ Secure storage migration already completed');
      return;
    }

    _log('🔄 Starting migration of sensitive data to encrypted storage...');

    try {
      // Migrate trip IDs
      final plainTextTripIds = _prefs.getStringList(_joinedTripIdsKey) ?? [];

      // Migrate user identities
      final plainTextIdentities = <String, String>{};
      for (final key in _prefs.getKeys()) {
        if (key.startsWith(_tripIdentityKeyPrefix)) {
          final tripId = key.substring(_tripIdentityKeyPrefix.length);
          final participantId = _prefs.getString(key);
          if (participantId != null) {
            plainTextIdentities[tripId] = participantId;
          }
        }
      }

      if (plainTextTripIds.isNotEmpty || plainTextIdentities.isNotEmpty) {
        _log(
          '🔄 Found ${plainTextTripIds.length} trip IDs and ${plainTextIdentities.length} identities to migrate',
        );

        await _secureStorage.migrateFromPlainText(
          plainTextTripIds: plainTextTripIds,
          plainTextIdentities: plainTextIdentities,
        );

        // Remove plain-text data from SharedPreferences
        await _prefs.remove(_joinedTripIdsKey);
        for (final key in plainTextIdentities.keys) {
          await _prefs.remove('$_tripIdentityKeyPrefix$key');
        }

        _log('✅ Migration complete, plain-text data removed');
      } else {
        _log('ℹ️ No sensitive data to migrate');
      }

      // Mark migration as completed
      await _prefs.setBool(_migrationCompletedKey, true);
      _log('✅ Migration marked as completed');
    } catch (e) {
      _log('❌ Migration failed: $e');
      // Don't mark as completed so migration will retry next time
      rethrow;
    }
  }

  /// Save the selected trip ID
  Future<void> saveSelectedTripId(String tripId) async {
    _log('💾 Saving selected trip ID: $tripId');
    _log('💾 Using key: $_selectedTripIdKey');

    final result = await _prefs.setString(_selectedTripIdKey, tripId);
    _log('✅ SharedPreferences.setString result: $result');

    // Immediate verification
    final verified = _prefs.getString(_selectedTripIdKey);
    _log('🔍 Immediate verification read from SharedPreferences: $verified');

    // On web, verify directly in browser localStorage
    if (kIsWeb) {
      try {
        final storage = html.window.localStorage;
        // SharedPreferences on web prefixes keys with 'flutter.'
        final webKey = 'flutter.$_selectedTripIdKey';
        final webValue = storage[webKey];
        _log('🌐 Browser localStorage[$webKey]: $webValue');

        // List all localStorage keys for debugging
        _log('🌐 All localStorage keys: ${storage.keys.toList()}');
      } catch (e) {
        _log('⚠️ Failed to verify in browser localStorage: $e');
      }
    }

    // Delayed verification to check persistence
    await Future.delayed(const Duration(milliseconds: 500));
    final delayedVerify = _prefs.getString(_selectedTripIdKey);
    _log('⏱️ Delayed verification (500ms): $delayedVerify');
  }

  /// Get the saved selected trip ID
  ///
  /// Returns null if no trip ID has been saved
  String? getSelectedTripId() {
    _log('📖 Reading selected trip ID from key: $_selectedTripIdKey');
    final tripId = _prefs.getString(_selectedTripIdKey);
    _log('📖 SharedPreferences value: ${tripId ?? "null (not set)"}');

    // On web, also check browser localStorage directly
    if (kIsWeb) {
      try {
        final storage = html.window.localStorage;
        final webKey = 'flutter.$_selectedTripIdKey';
        final webValue = storage[webKey];
        _log('🌐 Browser localStorage[$webKey]: ${webValue ?? "null"}');

        if (webValue != tripId) {
          _log(
            '⚠️ MISMATCH: SharedPreferences ($tripId) != localStorage ($webValue)',
          );
        }
      } catch (e) {
        _log('⚠️ Failed to read from browser localStorage: $e');
      }
    }

    return tripId;
  }

  /// Clear the selected trip ID
  Future<void> clearSelectedTripId() async {
    _log('🗑️ Clearing selected trip ID');
    await _prefs.remove(_selectedTripIdKey);
    _log('✅ Selected trip ID cleared from SharedPreferences');

    if (kIsWeb) {
      try {
        final storage = html.window.localStorage;
        final webKey = 'flutter.$_selectedTripIdKey';
        _log(
          '🌐 Browser localStorage[$webKey] after clear: ${storage[webKey] ?? "null"}',
        );
      } catch (e) {
        _log('⚠️ Failed to verify clear in browser localStorage: $e');
      }
    }
  }

  /// Add a trip ID to the list of joined trips (encrypted)
  Future<void> addJoinedTrip(String tripId) async {
    _log('➕ Delegating to SecureStorageService: addJoinedTrip($tripId)');
    await _secureStorage.addJoinedTrip(tripId);
  }

  /// Verify that a trip ID is in the joined trips list (encrypted)
  Future<bool> verifyJoinedTrip(String tripId) async {
    _log('🔍 Delegating to SecureStorageService: verifyJoinedTrip($tripId)');
    return await _secureStorage.verifyJoinedTrip(tripId);
  }

  /// Get the list of joined trip IDs (encrypted)
  ///
  /// Returns an empty list if no trips have been joined
  Future<List<String>> getJoinedTripIds() async {
    _log('📖 Delegating to SecureStorageService: getJoinedTripIds()');
    return await _secureStorage.getJoinedTripIds();
  }

  /// Remove a trip ID from the list of joined trips (encrypted)
  Future<void> removeJoinedTrip(String tripId) async {
    _log('➖ Delegating to SecureStorageService: removeJoinedTrip($tripId)');
    await _secureStorage.removeJoinedTrip(tripId);
  }

  /// Save the user's identity (participant ID) for a specific trip (encrypted)
  ///
  /// This stores which participant the current user is in a given trip,
  /// enabling proper attribution of actions to the correct user.
  Future<void> saveUserIdentityForTrip(
    String tripId,
    String participantId,
  ) async {
    _log(
      '💾 Delegating to SecureStorageService: saveUserIdentityForTrip($tripId, $participantId)',
    );
    await _secureStorage.saveUserIdentityForTrip(tripId, participantId);
  }

  /// Get the user's identity (participant ID) for a specific trip (encrypted)
  ///
  /// Returns null if the user has not selected their identity for this trip.
  /// This happens when accessing a trip without going through the join flow.
  Future<String?> getUserIdentityForTrip(String tripId) async {
    _log(
      '📖 Delegating to SecureStorageService: getUserIdentityForTrip($tripId)',
    );
    return await _secureStorage.getUserIdentityForTrip(tripId);
  }

  /// Remove the user's identity for a specific trip (encrypted)
  ///
  /// This should be called when leaving a trip or when identity needs to be re-selected.
  Future<void> removeUserIdentityForTrip(String tripId) async {
    _log(
      '🗑️ Delegating to SecureStorageService: removeUserIdentityForTrip($tripId)',
    );
    await _secureStorage.removeUserIdentityForTrip(tripId);
  }

  /// Clear all user identities for all trips (encrypted)
  ///
  /// Useful for testing or complete app reset scenarios.
  Future<void> clearAllUserIdentities() async {
    _log('🗑️ Delegating to SecureStorageService: clearAllUserIdentities()');
    await _secureStorage.clearAllUserIdentities();
  }

  /// Save the settlement filter for a specific trip
  ///
  /// Stores the selected user ID and filter mode for the settlement screen.
  /// Pass null to userId or filterMode to skip updating that value.
  Future<void> saveSettlementFilter(
    String tripId, {
    String? userId,
    String? filterMode,
  }) async {
    _log('💾 Saving settlement filter for trip $tripId');

    if (userId != null) {
      final userKey = '$_settlementFilterUserKeyPrefix$tripId';
      _log('💾 Saving user filter: $userId (key: $userKey)');
      await _prefs.setString(userKey, userId);
    }

    if (filterMode != null) {
      final modeKey = '$_settlementFilterModeKeyPrefix$tripId';
      _log('💾 Saving filter mode: $filterMode (key: $modeKey)');
      await _prefs.setString(modeKey, filterMode);
    }

    _log('✅ Settlement filter saved');
  }

  /// Get the settlement filter for a specific trip
  ///
  /// Returns a record with the saved userId and filterMode.
  /// Returns null userId if no user filter is saved.
  /// Returns 'all' as default filterMode if none is saved.
  ({String? userId, String filterMode}) getSettlementFilter(String tripId) {
    final userKey = '$_settlementFilterUserKeyPrefix$tripId';
    final modeKey = '$_settlementFilterModeKeyPrefix$tripId';

    _log('📖 Reading settlement filter for trip $tripId');

    final userId = _prefs.getString(userKey);
    final filterMode = _prefs.getString(modeKey) ?? 'all';

    _log(
      '📖 Settlement filter: userId=${userId ?? "null"}, mode=$filterMode',
    );

    return (userId: userId, filterMode: filterMode);
  }

  /// Clear the settlement filter for a specific trip
  ///
  /// Removes both the user filter and filter mode from storage.
  Future<void> clearSettlementFilter(String tripId) async {
    final userKey = '$_settlementFilterUserKeyPrefix$tripId';
    final modeKey = '$_settlementFilterModeKeyPrefix$tripId';

    _log('🗑️ Clearing settlement filter for trip $tripId');

    await _prefs.remove(userKey);
    await _prefs.remove(modeKey);

    _log('✅ Settlement filter cleared');
  }
}
