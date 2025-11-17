import 'package:decimal/decimal.dart';

/// Evaluates simple mathematical equations for currency input
///
/// Supports the following operators:
/// - Addition: + (e.g., "100+50" = 150)
/// - Subtraction: - (e.g., "100-50" = 50)
/// - Multiplication: * (e.g., "100*2" = 200)
/// - Percentage: % (e.g., "100+10%" = 110, "100-10%" = 90)
///
/// Features:
/// - Order of operations (*, / before +, -)
/// - Percentage operator (% applies to previous number)
/// - High precision using Decimal
/// - Graceful error handling (returns null on invalid input)
///
/// Usage:
/// ```dart
/// final result = EquationEvaluator.evaluate("100+10%");
/// // result = Decimal.fromInt(110)
///
/// final invalid = EquationEvaluator.evaluate("abc");
/// // invalid = null
/// ```
class EquationEvaluator {
  /// Evaluates a mathematical equation string and returns the result as a Decimal
  ///
  /// Returns null if the equation is invalid or cannot be evaluated
  static Decimal? evaluate(String equation) {
    if (equation.isEmpty) {
      return null;
    }

    try {
      // Remove whitespace and commas
      final clean = equation.replaceAll(' ', '').replaceAll(',', '');

      // Check if it's just a number (no operators)
      if (!_containsOperators(clean)) {
        return Decimal.parse(clean);
      }

      // Tokenize the equation
      final tokens = _tokenize(clean);
      if (tokens.isEmpty) {
        return null;
      }

      // Evaluate with order of operations
      return _evaluateTokens(tokens);
    } catch (e) {
      return null;
    }
  }

  /// Checks if the string contains any operators
  static bool _containsOperators(String str) {
    return str.contains('+') ||
        str.contains('-') ||
        str.contains('*') ||
        str.contains('%');
  }

  /// Tokenizes the equation into numbers and operators
  static List<String> _tokenize(String equation) {
    final tokens = <String>[];
    final buffer = StringBuffer();

    for (int i = 0; i < equation.length; i++) {
      final char = equation[i];

      if (_isOperator(char)) {
        // Save the number before the operator
        if (buffer.isNotEmpty) {
          tokens.add(buffer.toString());
          buffer.clear();
        }
        tokens.add(char);
      } else if (_isDigit(char) || char == '.') {
        buffer.write(char);
      } else {
        // Invalid character
        return [];
      }
    }

    // Add the last number
    if (buffer.isNotEmpty) {
      tokens.add(buffer.toString());
    }

    return tokens;
  }

  /// Evaluates a list of tokens with order of operations
  static Decimal? _evaluateTokens(List<String> tokens) {
    if (tokens.isEmpty) {
      return null;
    }

    // First pass: handle * and %
    final firstPass = <String>[];
    for (int i = 0; i < tokens.length; i++) {
      final token = tokens[i];

      if (token == '*' && i > 0 && i < tokens.length - 1) {
        // Pop the last number from firstPass
        final left = Decimal.parse(firstPass.removeLast());
        final right = Decimal.parse(tokens[i + 1]);
        final result = left * right;
        firstPass.add(result.toString());
        i++; // Skip the next token (already consumed)
      } else if (token == '%' && i > 0) {
        // Percentage: convert to decimal multiplier
        // Pop the last number from firstPass
        final value = Decimal.parse(firstPass.removeLast());
        final percentage = value / Decimal.fromInt(100);
        firstPass.add(percentage.toString());
      } else {
        firstPass.add(token);
      }
    }

    // Second pass: handle + and -
    Decimal? result;
    String? pendingOp;

    for (final token in firstPass) {
      if (token == '+' || token == '-') {
        pendingOp = token;
      } else {
        final value = Decimal.parse(token);
        if (result == null) {
          result = value;
        } else {
          if (pendingOp == '+') {
            result = result + value;
          } else if (pendingOp == '-') {
            result = result - value;
          }
          pendingOp = null;
        }
      }
    }

    return result;
  }

  /// Checks if a character is an operator
  static bool _isOperator(String char) {
    return char == '+' || char == '-' || char == '*' || char == '%';
  }

  /// Checks if a character is a digit
  static bool _isDigit(String char) {
    return char.codeUnitAt(0) >= '0'.codeUnitAt(0) &&
        char.codeUnitAt(0) <= '9'.codeUnitAt(0);
  }

  /// Checks if a string is a valid equation (contains only numbers, operators, and decimal points)
  static bool isValidEquation(String equation) {
    if (equation.isEmpty) {
      return false;
    }

    // Remove whitespace and commas
    final clean = equation.replaceAll(' ', '').replaceAll(',', '');

    // Check for valid characters only
    final validPattern = RegExp(r'^[0-9+\-*%.]+$');
    if (!validPattern.hasMatch(clean)) {
      return false;
    }

    // Try to evaluate - if it succeeds, it's valid
    return evaluate(equation) != null;
  }
}
