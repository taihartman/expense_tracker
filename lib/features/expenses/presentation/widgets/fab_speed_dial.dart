import 'package:flutter/material.dart';

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
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      _scaleAnimation,
    );
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
      alignment: Alignment.bottomRight,
      children: [
        // Backdrop (dismisses Speed Dial when tapped)
        if (_isOpen)
          Positioned.fill(
            child: GestureDetector(
              onTap: _close,
              child: Container(
                color: Colors.black.withOpacity(0.3),
              ),
            ),
          ),

        // Mini FAB 2: Receipt Split (144dp above main)
        if (_isOpen)
          Positioned(
            right: 0,
            bottom: 144,
            child: FadeTransition(
              opacity: _opacityAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: FloatingActionButton.small(
                  heroTag: 'receiptSplit',
                  onPressed: _handleReceiptSplitTap,
                  tooltip: 'Receipt Split (Who Ordered What)',
                  child: const Icon(Icons.receipt_long),
                ),
              ),
            ),
          ),

        // Mini FAB 1: Quick Expense (72dp above main)
        if (_isOpen)
          Positioned(
            right: 0,
            bottom: 72,
            child: FadeTransition(
              opacity: _opacityAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: FloatingActionButton.small(
                  heroTag: 'quickExpense',
                  onPressed: _handleQuickExpenseTap,
                  tooltip: 'Quick Expense',
                  child: const Icon(Icons.flash_on),
                ),
              ),
            ),
          ),

        // Main FAB
        FloatingActionButton(
          onPressed: _toggle,
          tooltip: 'Add expense options',
          child: AnimatedRotation(
            turns: _isOpen ? 0.125 : 0.0, // 45° rotation when open
            duration: const Duration(milliseconds: 200),
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }
}
