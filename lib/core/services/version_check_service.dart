import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pub_semver/pub_semver.dart';

import '../models/update_check_state.dart';
import '../models/version_response.dart';

/// Service for checking if app updates are available
///
/// Fetches version information from /version.json endpoint and compares
/// with local app version. Implements debouncing to prevent excessive checks.
///
/// Example usage:
/// ```dart
/// final versionCheck = VersionCheckServiceImpl();
///
/// // Check if update is available
/// final updateAvailable = await versionCheck.isUpdateAvailable();
/// if (updateAvailable) {
///   print('New version available!');
///   // Show notification to user
/// }
///
/// // Get server version details
/// final serverVersion = await versionCheck.getServerVersion();
/// print('Server version: $serverVersion');
///
/// // Clean up when done
/// versionCheck.dispose();
/// ```
///
/// For testing, inject mock dependencies:
/// ```dart
/// final mockClient = MockClient();
/// when(mockClient.get(any)).thenAnswer(
///   (_) async => http.Response('{"version": "1.1.0"}', 200),
/// );
///
/// final versionCheck = VersionCheckServiceImpl(
///   httpClient: mockClient,
///   versionJsonUrl: 'https://test.com/version.json',
/// );
/// ```
abstract class VersionCheckService {
  /// Checks if an update is available
  ///
  /// Returns true if server version > local version
  /// Returns false if versions are equal, server is older, or on any error
  /// Never throws exceptions - all errors result in false return
  ///
  /// Implements 10-second debouncing to prevent excessive network requests.
  Future<bool> isUpdateAvailable();

  /// Gets the server version string if available
  ///
  /// Returns null on fetch failure or parse error
  /// Never throws exceptions
  ///
  /// Fetches from /version.json endpoint with 2-second timeout.
  Future<String?> getServerVersion();

  /// Disposes of any resources held by the service
  ///
  /// Should be called when the service is no longer needed.
  /// Closes HTTP client and releases any held resources.
  void dispose();
}

/// Implementation of VersionCheckService with HTTP client and debouncing
class VersionCheckServiceImpl implements VersionCheckService {
  final http.Client _httpClient;
  final String _versionJsonUrl;
  final Duration _timeout;
  final Duration _debounceInterval;

  UpdateCheckState _state = const UpdateCheckState();

  VersionCheckServiceImpl({
    http.Client? httpClient,
    String? versionJsonUrl,
    Duration? timeout,
    Duration? debounceInterval,
  }) : _httpClient = httpClient ?? http.Client(),
       _versionJsonUrl = versionJsonUrl ?? '/version.json',
       _timeout = timeout ?? const Duration(seconds: 2),
       _debounceInterval = debounceInterval ?? const Duration(seconds: 10);

  void _log(String message) {
    if (kDebugMode) {
      debugPrint('[VersionCheck] $message');
    }
  }

  @override
  Future<bool> isUpdateAvailable() async {
    // Check debouncing
    if (_state.shouldDebounce(_debounceInterval)) {
      _log('Debouncing - skipping check (last check: ${_state.lastCheckTime})');
      return _state.updateAvailable;
    }

    // Prevent concurrent checks
    if (_state.isCheckingNow) {
      _log('Check already in progress - skipping');
      return _state.updateAvailable;
    }

    _state = _state.copyWith(isCheckingNow: true);

    try {
      // Get server version
      final serverVersionString = await getServerVersion();
      if (serverVersionString == null) {
        _log('Failed to get server version');
        _state = _state.copyWith(
          isCheckingNow: false,
          lastCheckTime: DateTime.now(),
        );
        return false;
      }

      // Parse server version
      final serverVersion = Version.parse(serverVersionString);

      // Get local version
      final packageInfo = await PackageInfo.fromPlatform();
      final localVersion = Version.parse(packageInfo.version);

      _log('Version comparison: local=$localVersion, server=$serverVersion');

      // Compare versions
      final updateAvailable = serverVersion > localVersion;

      _state = _state.copyWith(
        isCheckingNow: false,
        updateAvailable: updateAvailable,
        serverVersion: serverVersion,
        lastCheckTime: DateTime.now(),
      );

      if (updateAvailable) {
        _log('Update available: $localVersion -> $serverVersion');
      } else {
        _log('No update available (local version is current)');
      }

      return updateAvailable;
    } on FormatException catch (e) {
      _log('Invalid version format: $e');
      _state = _state.copyWith(
        isCheckingNow: false,
        lastCheckTime: DateTime.now(),
      );
      return false;
    } on TimeoutException catch (e) {
      _log('Version check timeout: $e');
      _state = _state.copyWith(
        isCheckingNow: false,
        lastCheckTime: DateTime.now(),
      );
      return false;
    } catch (e) {
      _log('Version check failed: $e');
      _state = _state.copyWith(
        isCheckingNow: false,
        lastCheckTime: DateTime.now(),
      );
      return false;
    }
  }

  @override
  Future<String?> getServerVersion() async {
    try {
      _log('Fetching version from $_versionJsonUrl');

      final uri = Uri.parse(_versionJsonUrl);
      final response = await _httpClient.get(uri).timeout(_timeout);

      if (response.statusCode == 404) {
        _log('Version endpoint not found (404)');
        return null;
      }

      if (response.statusCode != 200) {
        _log('Version endpoint returned ${response.statusCode}');
        return null;
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final versionResponse = VersionResponse.fromJson(json);

      _log('Server version: ${versionResponse.version}');
      return versionResponse.version;
    } on TimeoutException catch (e) {
      _log('Timeout fetching server version: $e');
      return null;
    } on FormatException catch (e) {
      _log('Invalid JSON in version response: $e');
      return null;
    } catch (e) {
      _log('Error fetching server version: $e');
      return null;
    }
  }

  @override
  void dispose() {
    _httpClient.close();
  }
}
