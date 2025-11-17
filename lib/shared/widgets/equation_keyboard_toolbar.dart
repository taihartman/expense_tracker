import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Custom keyboard toolbar for equation input
///
/// Displays a row of operator buttons (+, -, *, %, =) above the system keyboard
/// to enable equation entry in currency fields.
///
/// Features:
/// - Material Design 3 styling
/// - Minimum 44px touch targets (mobile-friendly)
/// - Consistent with app theme
/// - Responsive sizing
///
/// Usage:
/// ```dart
/// EquationKeyboardToolbar(
///   onOperatorTap: (operator) {
///     // Insert operator into text field
///     controller.text += operator;
///   },
///   onEvaluate: () {
///     // Evaluate the equation
///     final result = EquationEvaluator.evaluate(controller.text);
///     if (result != null) {
///       controller.text = result.toString();
///     }
///   },
/// )
/// ```
class EquationKeyboardToolbar extends StatelessWidget {
  /// Callback when an operator button is tapped
  final ValueChanged<String> onOperatorTap;

  /// Callback when the equals button is tapped
  final VoidCallback onEvaluate;

  const EquationKeyboardToolbar({
    super.key,
    required this.onOperatorTap,
    required this.onEvaluate,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        border: Border(
          top: BorderSide(
            color: colorScheme.outlineVariant,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacing2,
            vertical: AppTheme.spacing1,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildOperatorButton(context, '+'),
              _buildOperatorButton(context, '-'),
              _buildOperatorButton(context, '*'),
              _buildOperatorButton(context, '%'),
              _buildEvaluateButton(context),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds an operator button (+, -, *, %)
  Widget _buildOperatorButton(BuildContext context, String operator) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: () => onOperatorTap(operator),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          constraints: const BoxConstraints(
            minWidth: AppTheme.minTouchTarget,
            minHeight: AppTheme.minTouchTarget,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacing2,
            vertical: AppTheme.spacing1,
          ),
          child: Center(
            child: Text(
              operator,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the equals button (evaluate equation)
  Widget _buildEvaluateButton(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.primary,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onEvaluate,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          constraints: const BoxConstraints(
            minWidth: AppTheme.minTouchTarget,
            minHeight: AppTheme.minTouchTarget,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacing2,
            vertical: AppTheme.spacing1,
          ),
          child: Center(
            child: Text(
              '=',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: colorScheme.onPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
