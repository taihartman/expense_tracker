/// Validator for category names
///
/// Ensures category names meet the global category system requirements:
/// - Length: 1-50 characters
/// - Characters: Letters (any language/Unicode), numbers, spaces, and basic punctuation only
/// - Allowed punctuation: apostrophes ('), hyphens (-), ampersands (&)
/// - Not allowed: Emojis, special Unicode characters
class CategoryValidator {
  /// Regular expression for allowed characters in category names
  ///
  /// Matches: letters (any language), numbers, spaces, apostrophes, hyphens, ampersands
  /// \p{L} = any Unicode letter
  /// \p{N} = any Unicode number
  /// \s = whitespace (spaces, tabs, etc.)
  /// ' - & = specific allowed punctuation
  static final RegExp _validCharsRegex = RegExp(
    r"^[\p{L}\p{N}\s'\-&]+$",
    unicode: true,
  );

  /// Minimum allowed category name length
  static const int minLength = 1;

  /// Maximum allowed category name length
  static const int maxLength = 50;

  /// Validate a category name
  ///
  /// Returns null if the name is valid.
  /// Returns an error message string if validation fails.
  ///
  /// Validation rules:
  /// 1. Name cannot be empty (after trimming)
  /// 2. Name must be between 1-50 characters
  /// 3. Name can only contain letters, numbers, spaces, and basic punctuation (', -, &)
  ///
  /// Examples:
  /// - "Meals" ✓
  /// - "Mom's Birthday" ✓
  /// - "Year-End Party" ✓
  /// - "Food & Drinks" ✓
  /// - "Café ☕" ✗ (emoji not allowed)
  /// - "" ✗ (empty)
  /// - "A very long category name that exceeds fifty characters limit" ✗ (too long)
  static String? validateCategoryName(String name) {
    // Check for empty name
    if (name.trim().isEmpty) {
      return 'Category name cannot be empty';
    }

    // Check length
    if (name.length < minLength || name.length > maxLength) {
      return 'Category name must be between $minLength and $maxLength characters';
    }

    // Check for valid characters
    if (!_validCharsRegex.hasMatch(name)) {
      return 'Category names can only contain letters, numbers, spaces, and basic punctuation';
    }

    return null; // Valid
  }

  /// Check if a category name is valid (boolean)
  ///
  /// Returns true if valid, false otherwise.
  /// Useful for quick validation checks without needing the error message.
  static bool isValid(String name) {
    return validateCategoryName(name) == null;
  }

  /// Sanitize a category name for search/comparison
  ///
  /// Converts to lowercase for case-insensitive operations.
  /// Trims whitespace.
  ///
  /// Used for:
  /// - Duplicate detection (case-insensitive)
  /// - Search queries (case-insensitive)
  static String sanitize(String name) {
    return name.trim().toLowerCase();
  }

  /// Check if two category names are duplicates (case-insensitive)
  ///
  /// Returns true if names are the same when case-insensitive.
  ///
  /// Examples:
  /// - "Meals" == "meals" → true
  /// - "Meals" == "MEALS" → true
  /// - "Meals" == "Meal Plan" → false
  static bool areDuplicates(String name1, String name2) {
    return sanitize(name1) == sanitize(name2);
  }
}
