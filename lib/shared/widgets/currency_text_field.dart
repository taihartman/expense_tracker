import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/l10n/l10n_extensions.dart';
import '../../core/models/currency_code.dart';
import '../utils/currency_input_formatter.dart';

/// Specialized text field for currency amount input with automatic formatting
/// and validation.
///
/// Features:
/// - Automatic thousand separators (1,000,000)
/// - Currency-aware decimal places (USD = 2, VND = 0)
/// - Built-in validation (required, valid number, > 0)
/// - Localized error messages
/// - Consistent styling across app
/// - Pre-fills with formatted values when editing
///
/// Usage:
/// ```dart
/// final _amountController = TextEditingController();
///
/// CurrencyTextField(
///   controller: _amountController,
///   currencyCode: CurrencyCode.usd,
///   label: context.l10n.expenseFieldAmountLabel,
///   onAmountChanged: (amount) {
///     // Called with parsed Decimal value
///     print('Amount: $amount');
///   },
/// )
/// ```
class CurrencyTextField extends StatefulWidget {
  /// Text editing controller for the input field
  final TextEditingController controller;

  /// Currency code for this input (determines decimal places)
  final CurrencyCode currencyCode;

  /// Label text for the field
  final String label;

  /// Hint text (optional)
  final String? hint;

  /// Whether the field is required (shows * and validates)
  final bool isRequired;

  /// Whether to allow zero as a valid value (default: false)
  final bool allowZero;

  /// Callback when the amount changes (provides parsed Decimal value)
  /// Returns null if the input is invalid or empty
  final ValueChanged<Decimal?>? onAmountChanged;

  /// Whether the field is enabled
  final bool enabled;

  /// Prefix icon (optional)
  final IconData? prefixIcon;

  const CurrencyTextField({
    super.key,
    required this.controller,
    required this.currencyCode,
    required this.label,
    this.hint,
    this.isRequired = true,
    this.allowZero = false,
    this.onAmountChanged,
    this.enabled = true,
    this.prefixIcon,
  });

  @override
  State<CurrencyTextField> createState() => _CurrencyTextFieldState();
}

class _CurrencyTextFieldState extends State<CurrencyTextField> {
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      decoration: InputDecoration(
        labelText: widget.isRequired ? '${widget.label} *' : widget.label,
        hintText: widget.hint,
        prefixIcon: widget.prefixIcon != null ? Icon(widget.prefixIcon) : null,
        suffixText: widget.currencyCode.code,
        border: const OutlineInputBorder(),
        enabled: widget.enabled,
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        CurrencyInputFormatter(currencyCode: widget.currencyCode),
      ],
      validator: (value) => _validateAmount(context, value),
      onChanged: (value) {
        if (widget.onAmountChanged != null) {
          final amount = _parseAmount(value);
          widget.onAmountChanged!(amount);
        }
      },
      enabled: widget.enabled,
    );
  }

  /// Validates the amount input
  String? _validateAmount(BuildContext context, String? value) {
    // Check if required
    if (widget.isRequired && (value == null || value.isEmpty)) {
      return context.l10n.validationRequired;
    }

    // If not required and empty, it's valid
    if (!widget.isRequired && (value == null || value.isEmpty)) {
      return null;
    }

    // Validate it's a valid number
    try {
      final cleanValue = stripCurrencyFormatting(value!);
      final amount = Decimal.parse(cleanValue);

      // Check if greater than zero (or >= 0 if allowZero is true)
      if (widget.allowZero) {
        if (amount < Decimal.zero) {
          return context.l10n.validationMustBeGreaterThanZero;
        }
      } else {
        if (amount <= Decimal.zero) {
          return context.l10n.validationMustBeGreaterThanZero;
        }
      }

      return null;
    } catch (e) {
      return context.l10n.validationInvalidNumber;
    }
  }

  /// Parses the formatted amount string to a Decimal
  /// Returns null if the input is invalid or empty
  Decimal? _parseAmount(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }

    try {
      final cleanValue = stripCurrencyFormatting(value);
      return Decimal.parse(cleanValue);
    } catch (e) {
      return null;
    }
  }
}

/// Helper function to format a Decimal amount for pre-filling in CurrencyTextField
///
/// Example:
/// ```dart
/// final controller = TextEditingController(
///   text: formatAmountForInput(expense.amount, currencyCode),
/// );
/// ```
String formatAmountForInput(Decimal amount, CurrencyCode currencyCode) {
  final decimalPlaces = currencyCode.decimalPlaces;

  // Format the decimal with the appropriate number of decimal places
  final pattern = decimalPlaces > 0 ? '#,##0.${'0' * decimalPlaces}' : '#,##0';
  final formatter = NumberFormat(pattern, 'en_US');

  // Convert Decimal to double for formatting
  final doubleValue = amount.toDouble();

  return formatter.format(doubleValue);
}
