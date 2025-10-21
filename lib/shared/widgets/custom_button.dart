import 'package:flutter/material.dart';

/// Custom button widget following Material Design 3 and 8px grid system
///
/// Provides consistent styling and behavior across the application
class CustomButton extends StatelessWidget {
  /// Button text
  final String text;

  /// Callback when button is pressed
  final VoidCallback? onPressed;

  /// Button variant
  final ButtonVariant variant;

  /// Whether button should expand to fill available width
  final bool fullWidth;

  /// Loading state (shows circular progress indicator)
  final bool isLoading;

  /// Leading icon
  final IconData? icon;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.variant = ButtonVariant.filled,
    this.fullWidth = false,
    this.isLoading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget button = switch (variant) {
      ButtonVariant.filled => _buildFilledButton(theme),
      ButtonVariant.outlined => _buildOutlinedButton(theme),
      ButtonVariant.text => _buildTextButton(theme),
    };

    if (fullWidth) {
      button = SizedBox(
        width: double.infinity,
        child: button,
      );
    }

    return button;
  }

  Widget _buildFilledButton(ThemeData theme) {
    return FilledButton(
      onPressed: isLoading ? null : onPressed,
      child: _buildButtonContent(),
    );
  }

  Widget _buildOutlinedButton(ThemeData theme) {
    return OutlinedButton(
      onPressed: isLoading ? null : onPressed,
      child: _buildButtonContent(),
    );
  }

  Widget _buildTextButton(ThemeData theme) {
    return TextButton(
      onPressed: isLoading ? null : onPressed,
      child: _buildButtonContent(),
    );
  }

  Widget _buildButtonContent() {
    if (isLoading) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text(text),
        ],
      );
    }

    return Text(text);
  }
}

/// Button style variants
enum ButtonVariant {
  /// Filled button (primary action)
  filled,

  /// Outlined button (secondary action)
  outlined,

  /// Text button (tertiary action)
  text,
}
