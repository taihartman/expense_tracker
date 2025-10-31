import 'package:firebase_auth/firebase_auth.dart';

/// Centralized authentication service for Firebase Auth operations
///
/// This service provides a clean abstraction over Firebase Authentication
/// and enforces proper separation between authentication and business logic.
///
/// **CRITICAL ARCHITECTURE PRINCIPLE**:
/// The app uses TWO separate identity systems:
///
/// 1. **Firebase Auth UID** (managed by this service)
///    - Purpose: Firestore security rules validation and rate limiting
///    - Access: Only through this AuthService
///    - Usage: ONLY for rate limiting and security rule userId validation
///    - Example: Creating categories (rate limiting enforcement)
///
/// 2. **Participant ID** (managed by Participant/TripCubit)
///    - Purpose: User identity within trips (business logic)
///    - Access: Via TripCubit.getCurrentUserForTrip()
///    - Usage: All business logic, activity logging, user references
///    - Example: Creating expenses, settlements, activity logs
///
/// **When to use Auth UID vs Participant ID**:
/// - ✅ Use Auth UID: Rate limiting, security rule validation
/// - ❌ Never use Auth UID: Business logic, user display, activity logs
/// - ✅ Use Participant: Expenses, settlements, activity logs, user names
///
/// See CLAUDE.md for complete authentication architecture documentation.
class AuthService {
  final FirebaseAuth _auth;

  AuthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  /// Check if user is currently authenticated
  ///
  /// Returns true if there is a signed-in user (anonymous or full auth).
  /// Returns false if no user is signed in.
  ///
  /// Used for:
  /// - Guard checks before Firebase operations
  /// - UI state management (showing login vs authenticated screens)
  bool get isAuthenticated => _auth.currentUser != null;

  /// Get current user's Firebase Auth UID for rate limiting purposes
  ///
  /// ⚠️ **WARNING: Use this ONLY for rate limiting operations!**
  ///
  /// This UID should ONLY be used for:
  /// - Rate limiting enforcement (e.g., category creation)
  /// - Firestore security rules that validate userId == request.auth.uid
  /// - Internal security validation
  ///
  /// ❌ **DO NOT use this UID for**:
  /// - Business logic (use Participant ID instead)
  /// - User identity display (use Participant.name instead)
  /// - Activity logging (use Participant.name instead)
  /// - Associating data with users (use Participant ID instead)
  ///
  /// Returns null if user is not authenticated.
  ///
  /// Example (CORRECT usage):
  /// ```dart
  /// final userId = _authService.getAuthUidForRateLimiting();
  /// if (userId == null) {
  ///   throw Exception('Not authenticated');
  /// }
  /// await _rateLimiter.logCategoryCreation(userId: userId);
  /// ```
  ///
  /// Example (INCORRECT usage):
  /// ```dart
  /// // ❌ WRONG - Don't use for activity logging
  /// final userId = _authService.getAuthUidForRateLimiting();
  /// await activityLog.add(actorId: userId); // Should use Participant name!
  /// ```
  String? getAuthUidForRateLimiting() => _auth.currentUser?.uid;

  /// Sign in anonymously (called during app initialization)
  ///
  /// Creates an anonymous Firebase Auth user if none exists.
  /// This provides a unique UID for Firestore security rules validation.
  ///
  /// Returns the UserCredential for the signed-in anonymous user.
  ///
  /// Throws FirebaseAuthException if sign-in fails.
  Future<UserCredential> signInAnonymously() async {
    return await _auth.signInAnonymously();
  }

  /// Sign out the current user
  ///
  /// Removes the current Firebase Auth session.
  /// Note: This will prevent access to Firestore due to security rules.
  ///
  /// Typically not used in this app since we rely on anonymous auth,
  /// but provided for completeness.
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Get the current Firebase Auth user object
  ///
  /// ⚠️ **WARNING: Internal use only!**
  ///
  /// This is provided for rare cases where you need the full User object.
  /// In most cases, use isAuthenticated or getAuthUidForRateLimiting() instead.
  ///
  /// Returns null if no user is signed in.
  User? get currentUser => _auth.currentUser;
}
