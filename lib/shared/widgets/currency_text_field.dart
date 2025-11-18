import 'dart:async';

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/l10n/l10n_extensions.dart';
import '../../core/models/currency_code.dart';
import '../utils/currency_input_formatter.dart';
import '../utils/equation_evaluator.dart';
import 'equation_keyboard_toolbar.dart';

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

  /// Whether to enable equation support (shows operator toolbar)
  final bool enableEquations;

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
    this.enableEquations = false,
  });

  @override
  State<CurrencyTextField> createState() => _CurrencyTextFieldState();
}

class _CurrencyTextFieldState extends State<CurrencyTextField> {
  final FocusNode _focusNode = FocusNode();
  bool _showToolbar = false;
  Timer? _hideToolbarTimer;

  @override
  void initState() {
    super.initState();
    if (widget.enableEquations) {
      _focusNode.addListener(_onFocusChange);
    }
  }

  @override
  void dispose() {
    _hideToolbarTimer?.cancel();
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    print('[CurrencyTextField] Focus changed: hasFocus=${_focusNode.hasFocus}');

    if (_focusNode.hasFocus) {
      // Focus gained - show toolbar
      _hideToolbarTimer?.cancel();
      print('[CurrencyTextField] Focus gained - showing toolbar');
      setState(() {
        _showToolbar = true;
        print('[CurrencyTextField] Toolbar visibility set to: $_showToolbar');
      });
    } else {
      // Focus lost - keep toolbar visible (don't hide it)
      // User can continue using toolbar even when field isn't focused
      // Toolbar will only hide when user taps elsewhere on the form
      print('[CurrencyTextField] Focus lost - keeping toolbar visible for continued use');
    }
  }

  void _handleOperatorTap(String operator) {
    print('[CurrencyTextField] _handleOperatorTap called with operator: $operator');
    print('[CurrencyTextField] Current focus state: ${_focusNode.hasFocus}');

    // Insert operator at cursor position
    final currentText = widget.controller.text;
    final selection = widget.controller.selection;
    final int newCursorPosition;

    if (selection.isValid) {
      final newText = currentText.replaceRange(
        selection.start,
        selection.end,
        operator,
      );
      newCursorPosition = selection.start + operator.length;

      widget.controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newCursorPosition),
      );
    } else {
      // Just append to the end
      final newText = currentText + operator;
      newCursorPosition = newText.length;
      widget.controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newCursorPosition),
      );
    }

    print('[CurrencyTextField] Operator inserted. New text: ${widget.controller.text}');

    // Restore focus after the current event loop to counteract any focus loss
    // Use scheduleMicrotask to run before the next frame but after current event processing
    Future.microtask(() {
      if (mounted) {
        print('[CurrencyTextField] Microtask: Restoring focus (current: ${_focusNode.hasFocus})');
        _focusNode.requestFocus();
        // Restore cursor position immediately after requesting focus
        widget.controller.selection = TextSelection.collapsed(offset: newCursorPosition);
        print('[CurrencyTextField] Microtask: Focus requested, cursor at $newCursorPosition');
      }
    });
  }

  void _handleEvaluate() {
    final equation = widget.controller.text;
    final result = EquationEvaluator.evaluate(equation);

    if (result != null) {
      // Format the result using the currency formatter
      final formattedResult = formatAmountForInput(result, widget.currencyCode);
      widget.controller.text = formattedResult;

      // Notify listeners of the change
      if (widget.onAmountChanged != null) {
        widget.onAmountChanged!(result);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Wrap entire column in Focus to treat TextField and toolbar as single unit
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      descendantsAreFocusable: true,
      descendantsAreTraversable: true,
      onKeyEvent: (node, event) => KeyEventResult.ignored,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            controller: widget.controller,
            focusNode: widget.enableEquations ? _focusNode : null,
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
              if (widget.enableEquations)
                EquationInputFormatter(currencyCode: widget.currencyCode)
              else
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
          ),
          if (widget.enableEquations && _showToolbar)
            EquationKeyboardToolbar(
              onOperatorTap: _handleOperatorTap,
              onEvaluate: _handleEvaluate,
              textFieldFocusNode: _focusNode,
            ),
        ],
      ),
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

    // If equations are enabled, try to evaluate first
    if (widget.enableEquations && value != null && value.isNotEmpty) {
      final equation = stripCurrencyFormatting(value);
      final result = EquationEvaluator.evaluate(equation);

      if (result == null) {
        return context.l10n.validationInvalidNumber;
      }

      // Validate the result
      if (widget.allowZero) {
        if (result < Decimal.zero) {
          return context.l10n.validationMustBeGreaterThanZero;
        }
      } else {
        if (result <= Decimal.zero) {
          return context.l10n.validationMustBeGreaterThanZero;
        }
      }

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

      // If equations are enabled, try to evaluate first
      if (widget.enableEquations) {
        final result = EquationEvaluator.evaluate(cleanValue);
        if (result != null) {
          return result;
        }
      }

      // Otherwise, parse as a simple number
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
