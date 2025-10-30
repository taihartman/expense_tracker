import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../core/models/currency_code.dart';

/// TextInputFormatter that formats currency input with thousand separators (commas)
/// and supports decimal places.
///
/// Can be configured either with a specific [CurrencyCode] or a manual [decimalDigits] count.
/// When [currencyCode] is provided, decimal places are automatically set based on currency
/// (e.g., USD = 2 decimals, VND = 0 decimals).
///
/// Examples:
/// - "1000" → "1,000"
/// - "1000000.50" → "1,000,000.50"
/// - "1234.5" → "1,234.5"
///
/// Usage:
/// ```dart
/// // Currency-aware (recommended)
/// inputFormatters: [CurrencyInputFormatter(currencyCode: CurrencyCode.usd)]
///
/// // Manual decimal places
/// inputFormatters: [CurrencyInputFormatter(decimalDigits: 2)]
/// ```
class CurrencyInputFormatter extends TextInputFormatter {
  final int decimalDigits;

  /// Creates a currency input formatter.
  ///
  /// If [currencyCode] is provided, decimal places are automatically configured.
  /// Otherwise, [decimalDigits] is used (defaults to 2).
  CurrencyInputFormatter({CurrencyCode? currencyCode, int? decimalDigits})
    : decimalDigits = currencyCode?.decimalPlaces ?? decimalDigits ?? 2;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // If the new value is empty, return it as-is
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Remove all commas from the input
    final newText = newValue.text.replaceAll(',', '');

    // Validate that it's a valid number format
    if (!_isValidInput(newText)) {
      return oldValue;
    }

    // Parse and format the number
    try {
      // Split into integer and decimal parts
      final parts = newText.split('.');
      final integerPart = parts[0];
      final decimalPart = parts.length > 1 ? parts[1] : '';

      // Limit decimal places
      String limitedDecimal = decimalPart;
      if (decimalPart.length > decimalDigits) {
        limitedDecimal = decimalPart.substring(0, decimalDigits);
      }

      // Parse the integer part and format with commas
      final intValue = int.tryParse(integerPart);
      if (intValue == null) {
        return oldValue;
      }

      // Format with thousand separators
      final formattedInt = NumberFormat('#,##0', 'en_US').format(intValue);

      // Combine integer and decimal parts
      String formattedText = formattedInt;
      if (parts.length > 1) {
        formattedText += '.$limitedDecimal';
      }

      // Calculate new cursor position
      // Count how many commas are before the cursor in the formatted text
      final oldSelection = newValue.selection.baseOffset;
      final oldTextBeforeCursor = newValue.text.substring(0, oldSelection);
      final digitsBeforeCursor = oldTextBeforeCursor.replaceAll(',', '').length;

      // Find the position in the formatted text that corresponds to the same number of digits
      int newCursorPos = 0;
      int digitCount = 0;
      for (int i = 0; i < formattedText.length; i++) {
        if (formattedText[i] != ',') {
          digitCount++;
        }
        if (digitCount >= digitsBeforeCursor) {
          newCursorPos = i + 1;
          break;
        }
      }

      // Make sure cursor position is valid
      newCursorPos = newCursorPos.clamp(0, formattedText.length);

      return TextEditingValue(
        text: formattedText,
        selection: TextSelection.collapsed(offset: newCursorPos),
      );
    } catch (e) {
      return oldValue;
    }
  }

  /// Validates that the input string is a valid number format
  bool _isValidInput(String input) {
    // Allow empty string
    if (input.isEmpty) {
      return true;
    }

    // Check if it matches a valid number pattern (optional decimal point)
    final regex = RegExp(r'^\d*\.?\d*$');
    return regex.hasMatch(input);
  }
}

/// Helper function to parse currency text with commas to Decimal
String stripCurrencyFormatting(String text) {
  return text.replaceAll(',', '');
}
