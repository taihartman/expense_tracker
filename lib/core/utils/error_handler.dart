import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Error handling utilities for the application
///
/// Provides centralized error handling and user-friendly error messages
class ErrorHandler {
  /// Convert exception to user-friendly error message
  static String getUserFriendlyMessage(dynamic error) {
    if (error is FirebaseException) {
      return _handleFirebaseException(error);
    } else if (error is ArgumentError) {
      return error.message?.toString() ?? 'Invalid input provided';
    } else if (error is FormatException) {
      return 'Invalid format: ${error.message}';
    } else if (error is Exception) {
      return error.toString().replaceFirst('Exception: ', '');
    } else {
      return 'An unexpected error occurred. Please try again.';
    }
  }

  /// Handle Firebase-specific exceptions
  static String _handleFirebaseException(FirebaseException exception) {
    switch (exception.code) {
      case 'permission-denied':
        return 'You do not have permission to perform this action';
      case 'not-found':
        return 'The requested data was not found';
      case 'already-exists':
        return 'This data already exists';
      case 'resource-exhausted':
        return 'Too many requests. Please try again later';
      case 'failed-precondition':
        return 'Operation cannot be performed in the current state';
      case 'aborted':
        return 'Operation was aborted. Please try again';
      case 'out-of-range':
        return 'The value provided is out of range';
      case 'unimplemented':
        return 'This feature is not yet implemented';
      case 'internal':
        return 'An internal error occurred. Please try again';
      case 'unavailable':
        return 'Service is currently unavailable. Please try again';
      case 'unauthenticated':
        return 'You must be signed in to perform this action';
      case 'deadline-exceeded':
        return 'Operation timed out. Please try again';
      default:
        return exception.message ?? 'An error occurred with Firebase';
    }
  }

  /// Log error for debugging
  static void logError(dynamic error, StackTrace? stackTrace) {
    if (kDebugMode) {
      print('Error: $error');
      if (stackTrace != null) {
        print('Stack trace: $stackTrace');
      }
    }
  }

  /// Handle async operation with error logging
  static Future<T?> handleAsync<T>(
    Future<T> Function() operation, {
    String? context,
    void Function(String)? onError,
  }) async {
    try {
      return await operation();
    } catch (error, stackTrace) {
      final message = getUserFriendlyMessage(error);
      final contextMessage =
          context != null ? '$context: $message' : message;

      logError(error, stackTrace);

      if (onError != null) {
        onError(contextMessage);
      }

      return null;
    }
  }

  /// Validate required field
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  /// Validate string length
  static String? validateLength(
    String? value,
    String fieldName, {
    int? min,
    int? max,
  }) {
    if (value == null) return null;

    final length = value.trim().length;

    if (min != null && length < min) {
      return '$fieldName must be at least $min characters';
    }

    if (max != null && length > max) {
      return '$fieldName cannot exceed $max characters';
    }

    return null;
  }

  /// Validate positive number
  static String? validatePositive(num? value, String fieldName) {
    if (value == null) {
      return '$fieldName is required';
    }

    if (value <= 0) {
      return '$fieldName must be greater than 0';
    }

    return null;
  }

  /// Validate date not in future
  static String? validateNotFuture(DateTime? value, String fieldName) {
    if (value == null) {
      return '$fieldName is required';
    }

    if (value.isAfter(DateTime.now())) {
      return '$fieldName cannot be in the future';
    }

    return null;
  }
}
