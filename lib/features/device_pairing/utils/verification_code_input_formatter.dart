import 'package:flutter/services.dart';
import '../../../core/utils/code_generator.dart';

/// TextInputFormatter that formats verification codes as XXXX-XXXX.
///
/// Features:
/// - Auto-inserts dash after 4th digit when typing
/// - Smart paste handling (normalizes then re-formats)
/// - Maintains correct cursor position
/// - Prevents double-dashing
/// - Limits to 8 digits (9 characters with dash)
///
/// Examples:
/// - Type "1234" → cursor after 4, then type "5" → "1234-5"
/// - Paste "12345678" → "1234-5678"
/// - Paste "1234-5678" → "1234-5678" (no double dash)
/// - Paste "1234 5678" → "1234-5678" (normalizes spaces)
class VerificationCodeInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // If the new value is empty, return it as-is
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Normalize: Remove all dashes, spaces, and non-digit characters
    final normalized = CodeGenerator.normalize(newValue.text);

    // Only allow digits
    if (!RegExp(r'^\d*$').hasMatch(normalized)) {
      return oldValue;
    }

    // Limit to 8 digits maximum
    final digits = normalized.length > 8 ? normalized.substring(0, 8) : normalized;

    // Format: Insert dash after 4th digit if we have more than 4 digits
    String formattedText;
    if (digits.length <= 4) {
      formattedText = digits;
    } else {
      formattedText = '${digits.substring(0, 4)}-${digits.substring(4)}';
    }

    // Calculate new cursor position
    // Strategy: Count how many digits are before the cursor in the old value,
    // then place cursor after the same number of digits in the formatted value
    final oldSelection = newValue.selection.baseOffset;
    final oldTextBeforeCursor = newValue.text.substring(0, oldSelection.clamp(0, newValue.text.length));
    final digitsBeforeCursor = CodeGenerator.normalize(oldTextBeforeCursor).length;

    // Find position in formatted text corresponding to same number of digits
    int newCursorPos = 0;
    int digitCount = 0;
    for (int i = 0; i < formattedText.length; i++) {
      if (formattedText[i] != '-') {
        digitCount++;
      }
      if (digitCount >= digitsBeforeCursor) {
        newCursorPos = i + 1;
        break;
      }
    }

    // Handle edge case: if user's cursor was at the end
    if (oldSelection >= oldValue.text.length) {
      newCursorPos = formattedText.length;
    }

    // Make sure cursor position is valid
    newCursorPos = newCursorPos.clamp(0, formattedText.length);

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: newCursorPos),
    );
  }
}
