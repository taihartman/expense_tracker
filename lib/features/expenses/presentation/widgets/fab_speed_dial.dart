import 'package:flutter/material.dart';
import '../../../../core/l10n/l10n_extensions.dart';

/// A Material Design Speed Dial FAB for expense entry options.
///
/// Displays a main FAB that expands to show two options:
/// - Quick Expense (equal/weighted splits)
/// - Receipt Split (itemized wizard)
///
/// Implements Material Design 3 Speed Dial pattern with animations.
class ExpenseFabSpeedDial extends StatefulWidget {
  /// The ID of the trip this FAB belongs to
  final String tripId;

  /// Callback when Quick Expense option is tapped
  final VoidCallback onQuickExpenseTap;

  /// Callback when Receipt Split option is tapped
  final VoidCallback onReceiptSplitTap;

  const ExpenseFabSpeedDial({
    super.key,
    required this.tripId,
    required this.onQuickExpenseTap,
    required this.onReceiptSplitTap,
  });

  @override
  State<ExpenseFabSpeedDial> createState() => _ExpenseFabSpeedDialState();
}

class _ExpenseFabSpeedDialState extends State<ExpenseFabSpeedDial>
    with SingleTickerProviderStateMixin {
  bool _isOpen = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_scaleAnimation);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  void _close() {
    if (_isOpen) {
      setState(() {
        _isOpen = false;
        _animationController.reverse();
      });
    }
  }

  void _handleQuickExpenseTap() {
    _close();
    widget.onQuickExpenseTap();
  }

  void _handleReceiptSplitTap() {
    _close();
    widget.onReceiptSplitTap();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        // Mini FAB 2: Receipt Split (144dp above main)
        if (_isOpen)
          Positioned(
            bottom: 144,
            child: FadeTransition(
              opacity: _opacityAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Builder(
                  builder: (context) => Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      // Text label positioned to the left
                      Positioned(
                        right: 72, // 56 (FAB width) + 16 (spacing)
                        child: Text(
                          'Receipt Split',
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                      ),
                      // FAB stays centered
                      FloatingActionButton(
                        heroTag: 'receiptSplit',
                        onPressed: _handleReceiptSplitTap,
                        tooltip: context.l10n.expenseFabReceiptSplitTooltip,
                        child: const Icon(Icons.receipt_long),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

        // Mini FAB 1: Quick Expense (72dp above main)
        if (_isOpen)
          Positioned(
            bottom: 72,
            child: FadeTransition(
              opacity: _opacityAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Builder(
                  builder: (context) => Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      // Text label positioned to the left
                      Positioned(
                        right: 72, // 56 (FAB width) + 16 (spacing)
                        child: Text(
                          'Quick Expense',
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                      ),
                      // FAB stays centered
                      FloatingActionButton(
                        heroTag: 'quickExpense',
                        onPressed: _handleQuickExpenseTap,
                        tooltip: context.l10n.expenseFabQuickExpenseTooltip,
                        child: const Icon(Icons.flash_on),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

        // Main FAB
        Builder(
          builder: (context) => FloatingActionButton(
            onPressed: _toggle,
            tooltip: context.l10n.expenseFabMainTooltip,
            child: AnimatedRotation(
              turns: _isOpen ? 0.125 : 0.0, // 45° rotation when open
              duration: const Duration(milliseconds: 200),
              child: const Icon(Icons.add),
            ),
          ),
        ),
      ],
    );
  }
}
