import 'package:flutter/material.dart';

/// A loading indicator that displays three animated dots cycling through.
///
/// The animation shows dots lighting up sequentially in a loop, providing
/// a subtle loading indication. Respects user motion preferences.
class AnimatedDots extends StatefulWidget {
  /// The size of each dot in logical pixels.
  final double dotSize;

  /// The spacing between dots in logical pixels.
  final double spacing;

  /// The color of the active (lit) dot.
  final Color activeColor;

  /// The color of inactive (unlit) dots.
  final Color inactiveColor;

  /// Duration for one complete animation cycle.
  final Duration cycleDuration;

  const AnimatedDots({
    super.key,
    this.dotSize = 8.0,
    this.spacing = 12.0,
    this.activeColor = const Color(0xFF03DAC6), // Teal
    this.inactiveColor = const Color(0xFFE0E0E0), // Light gray
    this.cycleDuration = const Duration(milliseconds: 600),
  });

  @override
  State<AnimatedDots> createState() => _AnimatedDotsState();
}

class _AnimatedDotsState extends State<AnimatedDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.cycleDuration,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Check if user prefers reduced motion
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    if (reduceMotion) {
      // Show static dots for motion-sensitive users
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildDot(widget.activeColor),
          SizedBox(width: widget.spacing),
          _buildDot(widget.inactiveColor),
          SizedBox(width: widget.spacing),
          _buildDot(widget.inactiveColor),
        ],
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Calculate which dot should be active based on animation progress
        final progress = _controller.value;
        final activeDotIndex = (progress * 3).floor() % 3;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDot(activeDotIndex == 0 ? widget.activeColor : widget.inactiveColor),
            SizedBox(width: widget.spacing),
            _buildDot(activeDotIndex == 1 ? widget.activeColor : widget.inactiveColor),
            SizedBox(width: widget.spacing),
            _buildDot(activeDotIndex == 2 ? widget.activeColor : widget.inactiveColor),
          ],
        );
      },
    );
  }

  Widget _buildDot(Color color) {
    return Container(
      width: widget.dotSize,
      height: widget.dotSize,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}
