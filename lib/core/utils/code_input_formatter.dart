import 'package:flutter/services.dart';

/// Text input formatter for trip/invite codes
/// Automatically formats codes with dashes for readability
/// Example: "abc123def456" -> "abc-123-def-456"
class CodeInputFormatter extends TextInputFormatter {
  /// Maximum length without formatting
  final int? maxLength;

  /// Number of characters between dashes
  final int groupSize;

  CodeInputFormatter({this.maxLength, this.groupSize = 3});

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Remove all non-alphanumeric characters
    final text = newValue.text.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');

    // Apply max length if specified
    final limitedText = maxLength != null && text.length > maxLength!
        ? text.substring(0, maxLength)
        : text;

    // Add dashes every groupSize characters
    final buffer = StringBuffer();
    for (int i = 0; i < limitedText.length; i++) {
      if (i > 0 && i % groupSize == 0) {
        buffer.write('-');
      }
      buffer.write(limitedText[i]);
    }

    final formattedText = buffer.toString();

    // Calculate new cursor position
    final selectionIndex = newValue.selection.end;

    // Adjust cursor position based on added dashes
    int dashesBeforeCursor = 0;
    int cleanPosition = 0;
    for (
      int i = 0;
      i < formattedText.length && cleanPosition < selectionIndex;
      i++
    ) {
      if (formattedText[i] == '-') {
        dashesBeforeCursor++;
      } else {
        cleanPosition++;
      }
    }

    // Place cursor after the character or dash
    final newOffset = (selectionIndex + dashesBeforeCursor).clamp(
      0,
      formattedText.length,
    );

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: newOffset),
    );
  }

  /// Strips all formatting from a code string
  /// Use this before sending the code to the backend
  static String stripFormatting(String code) {
    return code.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
  }
}
