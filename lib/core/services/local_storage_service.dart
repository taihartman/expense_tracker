import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Conditional import for web-specific functionality
import 'web_storage_stub.dart' if (dart.library.html) 'dart:html' as html;

/// Helper function to log with timestamps
void _log(String message) {
  debugPrint('[${DateTime.now().toIso8601String()}] [LocalStorage] $message');
}

/// Service for managing local storage using SharedPreferences
///
/// Provides persistent storage for user preferences and app state
class LocalStorageService {
  static const String _selectedTripIdKey = 'selected_trip_id';
  static const String _joinedTripIdsKey = 'joined_trip_ids';
  static const String _tripIdentityKeyPrefix = 'trip_identity_';

  final SharedPreferences _prefs;

  LocalStorageService(this._prefs);

  /// Initialize the service
  ///
  /// This must be called before using the service
  static Future<LocalStorageService> init() async {
    _log('🔧 Initializing LocalStorageService...');
    _log('🌐 Platform: ${kIsWeb ? "Web" : "Native"}');

    final prefs = await SharedPreferences.getInstance();
    _log('✅ SharedPreferences instance obtained');

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

    return LocalStorageService(prefs);
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

  /// Add a trip ID to the list of joined trips
  Future<void> addJoinedTrip(String tripId) async {
    _log('➕ Adding joined trip ID: $tripId');
    final currentIds = getJoinedTripIds();

    if (currentIds.contains(tripId)) {
      _log('ℹ️ Trip ID $tripId already in joined trips list');
      return;
    }

    final updatedIds = [...currentIds, tripId];
    final result = await _prefs.setStringList(_joinedTripIdsKey, updatedIds);
    _log(
      '✅ Added trip ID to joined trips. Total trips: ${updatedIds.length}. Result: $result',
    );

    // Immediate verification
    final verified = _prefs.getStringList(_joinedTripIdsKey) ?? [];
    _log('🔍 Immediate verification: ${verified.length} trips in storage');

    if (!verified.contains(tripId)) {
      _log(
        '⚠️ VERIFICATION FAILED: Trip ID $tripId not found in storage after write!',
      );
    } else {
      _log('✅ Verification passed: Trip ID $tripId confirmed in storage');
    }

    // On web, verify directly in browser localStorage
    if (kIsWeb) {
      try {
        final storage = html.window.localStorage;
        final webKey = 'flutter.$_joinedTripIdsKey';
        final webValue = storage[webKey];
        _log('🌐 Browser localStorage[$webKey]: $webValue');
      } catch (e) {
        _log('⚠️ Failed to verify in browser localStorage: $e');
      }
    }
  }

  /// Verify that a trip ID is in the joined trips list
  ///
  /// Returns true if the trip ID is found, false otherwise.
  /// This is useful for post-write verification.
  bool verifyJoinedTrip(String tripId) {
    _log('🔍 Verifying trip ID in storage: $tripId');
    final joinedIds = getJoinedTripIds();
    final isPresent = joinedIds.contains(tripId);
    _log('🔍 Verification result: ${isPresent ? "FOUND" : "NOT FOUND"}');

    if (kIsWeb) {
      try {
        final storage = html.window.localStorage;
        final webKey = 'flutter.$_joinedTripIdsKey';
        final webValue = storage[webKey];
        _log('🌐 Browser localStorage[$webKey]: $webValue');
        _log(
          '🌐 Browser localStorage contains "$tripId": ${webValue?.contains(tripId) ?? false}',
        );
      } catch (e) {
        _log('⚠️ Failed to check browser localStorage: $e');
      }
    }

    return isPresent;
  }

  /// Get the list of joined trip IDs
  ///
  /// Returns an empty list if no trips have been joined
  List<String> getJoinedTripIds() {
    _log('📖 Reading joined trip IDs from key: $_joinedTripIdsKey');
    final ids = _prefs.getStringList(_joinedTripIdsKey) ?? [];
    _log(
      '📖 Found ${ids.length} joined trip(s): ${ids.isEmpty ? "none" : ids.join(", ")}',
    );
    return ids;
  }

  /// Remove a trip ID from the list of joined trips
  Future<void> removeJoinedTrip(String tripId) async {
    _log('➖ Removing joined trip ID: $tripId');
    final currentIds = getJoinedTripIds();

    if (!currentIds.contains(tripId)) {
      _log('ℹ️ Trip ID $tripId not found in joined trips list');
      return;
    }

    final updatedIds = currentIds.where((id) => id != tripId).toList();
    final result = await _prefs.setStringList(_joinedTripIdsKey, updatedIds);
    _log(
      '✅ Removed trip ID from joined trips. Remaining trips: ${updatedIds.length}. Result: $result',
    );
  }

  /// Save the user's identity (participant ID) for a specific trip
  ///
  /// This stores which participant the current user is in a given trip,
  /// enabling proper attribution of actions to the correct user.
  Future<void> saveUserIdentityForTrip(
    String tripId,
    String participantId,
  ) async {
    final key = '$_tripIdentityKeyPrefix$tripId';
    _log('💾 Saving user identity for trip $tripId: $participantId');
    _log('💾 Using key: $key');

    final result = await _prefs.setString(key, participantId);
    _log('✅ User identity saved. Result: $result');

    // Verification
    final verified = _prefs.getString(key);
    _log('🔍 Verification: $verified');
  }

  /// Get the user's identity (participant ID) for a specific trip
  ///
  /// Returns null if the user has not selected their identity for this trip.
  /// This happens when accessing a trip without going through the join flow.
  String? getUserIdentityForTrip(String tripId) {
    final key = '$_tripIdentityKeyPrefix$tripId';
    _log('📖 Reading user identity for trip $tripId from key: $key');
    final participantId = _prefs.getString(key);
    _log('📖 User identity: ${participantId ?? "null (not set)"}');
    return participantId;
  }

  /// Remove the user's identity for a specific trip
  ///
  /// This should be called when leaving a trip or when identity needs to be re-selected.
  Future<void> removeUserIdentityForTrip(String tripId) async {
    final key = '$_tripIdentityKeyPrefix$tripId';
    _log('🗑️ Removing user identity for trip $tripId');
    await _prefs.remove(key);
    _log('✅ User identity removed');
  }

  /// Clear all user identities for all trips
  ///
  /// Useful for testing or complete app reset scenarios.
  Future<void> clearAllUserIdentities() async {
    _log('🗑️ Clearing all user identities');
    final keys = _prefs.getKeys();
    final identityKeys = keys.where(
      (k) => k.startsWith(_tripIdentityKeyPrefix),
    );

    for (final key in identityKeys) {
      await _prefs.remove(key);
    }

    _log('✅ Cleared ${identityKeys.length} user identity entries');
  }
}
