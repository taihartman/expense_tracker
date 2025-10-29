import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html show window;

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
    _log('✅ Added trip ID to joined trips. Total trips: ${updatedIds.length}. Result: $result');
  }

  /// Get the list of joined trip IDs
  ///
  /// Returns an empty list if no trips have been joined
  List<String> getJoinedTripIds() {
    _log('📖 Reading joined trip IDs from key: $_joinedTripIdsKey');
    final ids = _prefs.getStringList(_joinedTripIdsKey) ?? [];
    _log('📖 Found ${ids.length} joined trip(s): ${ids.isEmpty ? "none" : ids.join(", ")}');
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
    _log('✅ Removed trip ID from joined trips. Remaining trips: ${updatedIds.length}. Result: $result');
  }
}
