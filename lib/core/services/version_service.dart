import 'package:package_info_plus/package_info_plus.dart';

/// Service for accessing application version information.
///
/// This service reads version data from the package info at runtime,
/// providing access to both the semantic version and build number.
class VersionService {
  static PackageInfo? _packageInfo;

  /// Initialize the version service.
  ///
  /// Should be called once during app startup.
  static Future<void> initialize() async {
    _packageInfo = await PackageInfo.fromPlatform();
  }

  /// Get the semantic version (e.g., "1.0.0").
  static String getVersion() {
    return _packageInfo?.version ?? '1.0.0';
  }

  /// Get the build number (e.g., "1").
  static String getBuildNumber() {
    return _packageInfo?.buildNumber ?? '1';
  }

  /// Get the full version with build number (e.g., "1.0.0+1").
  static String getFullVersion() {
    return '${getVersion()}+${getBuildNumber()}';
  }
}
