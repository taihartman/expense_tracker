/// Application-wide configuration and constants.
///
/// This provides a centralized location for all app-wide configuration values
/// including URLs, app metadata, and other constants that need to be shared
/// across the application.
///
/// Usage:
/// ```dart
/// final url = AppConfig.appBaseUrl;
/// final version = AppConfig.appVersion;
/// ```
class AppConfig {
  // ============================================================================
  // URLs
  // ============================================================================

  /// Base URL for the expense tracker web application.
  ///
  /// This is used for generating shareable deep links and external references.
  /// Custom domain deployment URL with hash-based routing for SPA compatibility.
  static const String appBaseUrl = 'https://expenses.taihartman.com';

  // ============================================================================
  // App Metadata
  // ============================================================================

  /// Application name
  static const String appName = 'Expense Tracker';

  /// Application version
  ///
  /// Should be kept in sync with pubspec.yaml version.
  static const String appVersion = '1.0.13';

  // ============================================================================
  // Debug & Development
  // ============================================================================

  /// Enable debug panel for mobile debugging.
  ///
  /// Set to `true` to show floating debug panel with routing logs.
  /// Set to `false` to completely disable (zero overhead).
  /// Uses `kDebugMode` by default (only enabled in debug builds).
  ///
  /// To disable: Change to `static const bool enableDebugPanel = false;`
  static const bool enableDebugPanel =
      false; // Disabled after fixing deep link issue

  // ============================================================================
  // Future Configuration
  // ============================================================================

  // Add more configuration as needed:
  // - Feature flags
  // - API endpoints
  // - Limits and constraints
  // - Environment-specific settings

  // ============================================================================
  // Private Constructor
  // ============================================================================

  /// Private constructor to prevent instantiation.
  /// This class should only be used for its static members.
  AppConfig._();
}
