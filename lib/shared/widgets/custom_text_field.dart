import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Custom text field widget following Material Design 3 and 8px grid system
///
/// Provides consistent styling and behavior across the application
class CustomTextField extends StatelessWidget {
  /// Label text
  final String label;

  /// Hint text
  final String? hint;

  /// Current value
  final String? value;

  /// Callback when value changes
  final ValueChanged<String>? onChanged;

  /// Validation function
  final String? Function(String?)? validator;

  /// Text input type
  final TextInputType? keyboardType;

  /// Maximum lines (null for single line)
  final int? maxLines;

  /// Maximum length
  final int? maxLength;

  /// Input formatters
  final List<TextInputFormatter>? inputFormatters;

  /// Prefix icon
  final IconData? prefixIcon;

  /// Suffix icon
  final Widget? suffix;

  /// Whether field is enabled
  final bool enabled;

  /// Whether field is required
  final bool required;

  /// Text controller (alternative to value/onChanged)
  final TextEditingController? controller;

  const CustomTextField({
    super.key,
    required this.label,
    this.hint,
    this.value,
    this.onChanged,
    this.validator,
    this.keyboardType,
    this.maxLines = 1,
    this.maxLength,
    this.inputFormatters,
    this.prefixIcon,
    this.suffix,
    this.enabled = true,
    this.required = false,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      initialValue: controller == null ? value : null,
      decoration: InputDecoration(
        labelText: required ? '$label *' : label,
        hintText: hint,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
        suffix: suffix,
        border: const OutlineInputBorder(),
        enabled: enabled,
      ),
      keyboardType: keyboardType,
      maxLines: maxLines,
      maxLength: maxLength,
      inputFormatters: inputFormatters,
      validator: validator,
      onChanged: onChanged,
      enabled: enabled,
    );
  }
}
