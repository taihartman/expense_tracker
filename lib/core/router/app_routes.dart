/// Centralized route path constants for the entire app.
///
/// This provides a single source of truth for all route paths,
/// enabling compile-time safety and easier refactoring.
///
/// Usage:
/// ```dart
/// // Static routes
/// context.go(AppRoutes.tripCreate);
///
/// // Dynamic routes
/// context.push(AppRoutes.tripSettings(tripId));
/// context.go(AppRoutes.expenseEdit(tripId, expenseId));
/// ```
class AppRoutes {
  // ============================================================================
  // Static Routes (no parameters)
  // ============================================================================

  /// Splash screen route
  static const String splash = '/splash';

  /// Home/root route
  static const String home = '/';

  /// Trips list page
  static const String trips = '/trips';

  /// Create new trip page
  static const String tripCreate = '/trips/create';

  /// Join trip page
  static const String tripJoin = '/trips/join';

  /// Archived trips page
  static const String tripArchived = '/trips/archived';

  /// Unauthorized access page
  static const String unauthorized = '/unauthorized';

  // ============================================================================
  // Dynamic Routes (with parameters)
  // ============================================================================

  /// User identity selection page for a trip
  ///
  /// Optional [returnTo] query parameter for redirect after identification.
  ///
  /// Example:
  /// ```dart
  /// AppRoutes.tripIdentify('trip-123')
  /// // => '/trips/trip-123/identify'
  ///
  /// AppRoutes.tripIdentify('trip-123', '/trips/trip-123/expenses')
  /// // => '/trips/trip-123/identify?returnTo=/trips/trip-123/expenses'
  /// ```
  static String tripIdentify(String tripId, [String? returnTo]) {
    if (returnTo != null) {
      return '/trips/$tripId/identify?returnTo=$returnTo';
    }
    return '/trips/$tripId/identify';
  }

  /// Edit trip details page
  static String tripEdit(String tripId) => '/trips/$tripId/edit';

  /// Trip settings page
  static String tripSettings(String tripId) => '/trips/$tripId/settings';

  /// Trip invite/share page
  static String tripInvite(String tripId) => '/trips/$tripId/invite';

  /// Trip activity log page
  static String tripActivity(String tripId) => '/trips/$tripId/activity';

  /// Trip category customization page
  static String tripCategoryCustomization(String tripId) =>
      '/trips/$tripId/categories/customize';

  /// Trip expenses list page
  static String tripExpenses(String tripId) => '/trips/$tripId/expenses';

  /// Create new expense page for a trip
  static String expenseCreate(String tripId) =>
      '/trips/$tripId/expenses/create';

  /// Edit expense page
  static String expenseEdit(String tripId, String expenseId) =>
      '/trips/$tripId/expenses/$expenseId/edit';

  /// Trip settlement/transfers page
  static String settlement(String tripId) => '/trips/$tripId/settlement';

  // ============================================================================
  // Private Constructor
  // ============================================================================

  /// Private constructor to prevent instantiation.
  /// This class should only be used for its static members.
  AppRoutes._();
}
