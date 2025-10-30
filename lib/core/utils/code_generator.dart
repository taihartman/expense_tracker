import 'dart:math';

/// Utility class for generating and validating device pairing codes.
///
/// Provides cryptographically secure 8-digit code generation using
/// [Random.secure()] to prevent predictability attacks.
class CodeGenerator {
  static final _random = Random.secure();

  /// Generates a cryptographically secure 8-digit code in format XXXX-XXXX.
  ///
  /// Uses [Random.secure()] to generate random numbers within the range
  /// 00000000 to 99999999, providing 100 million possible combinations.
  ///
  /// Returns a string in format "XXXX-XXXX" (e.g., "1234-5678").
  static String generate() {
    final code = _random.nextInt(100000000); // 0 to 99,999,999
    final codeString = code.toString().padLeft(8, '0');
    return '${codeString.substring(0, 4)}-${codeString.substring(4)}';
  }

  /// Generates a cryptographically secure 12-digit recovery code in format XXXX-XXXX-XXXX.
  ///
  /// Uses [Random.secure()] to generate random numbers within the range
  /// 000000000000 to 999999999999, providing 1 trillion possible combinations.
  ///
  /// Recovery codes are more secure than device pairing codes due to their length
  /// and the fact that they provide permanent trip access.
  ///
  /// Note: On web/JavaScript, Random.nextInt() has a max limit of 2^32, so we generate
  /// three 4-digit segments separately to create the full 12-digit code.
  ///
  /// Returns a string in format "XXXX-XXXX-XXXX" (e.g., "1234-5678-9012").
  static String generateRecoveryCode() {
    // Generate three 4-digit segments to avoid exceeding Random.nextInt() limit on web
    final segment1 = _random
        .nextInt(10000)
        .toString()
        .padLeft(4, '0'); // 0000-9999
    final segment2 = _random
        .nextInt(10000)
        .toString()
        .padLeft(4, '0'); // 0000-9999
    final segment3 = _random
        .nextInt(10000)
        .toString()
        .padLeft(4, '0'); // 0000-9999
    return '$segment1-$segment2-$segment3';
  }

  /// Normalizes a code by removing hyphens and spaces.
  ///
  /// Accepts codes in various formats:
  /// - "1234-5678" → "12345678"
  /// - "1234 5678" → "12345678"
  /// - "12 34-56 78" → "12345678"
  ///
  /// Returns the normalized code with only digits.
  static String normalize(String code) {
    return code.replaceAll('-', '').replaceAll(' ', '');
  }

  /// Validates that a code is 8 digits (with optional hyphens/spaces).
  ///
  /// Returns true if the code, after normalization, is exactly 8 numeric digits.
  ///
  /// Valid formats:
  /// - "1234-5678" ✓
  /// - "12345678" ✓
  /// - "1234 5678" ✓
  ///
  /// Invalid formats:
  /// - "1234-ABCD" ✗ (letters)
  /// - "1234567" ✗ (7 digits)
  /// - "123456789" ✗ (9 digits)
  static bool isValid(String code) {
    final normalized = normalize(code);
    return RegExp(r'^\d{8}$').hasMatch(normalized);
  }
}
