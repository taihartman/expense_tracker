import 'package:flutter/material.dart';
import '../widgets/animated_dots.dart';

/// Simplified splash screen shown during Firebase initialization.
///
/// This is shown BEFORE the full app tree is built (before BLoCs/Cubits exist).
/// Once Firebase initialization completes, the app switches to the regular
/// SplashPage which loads trip data.
class InitializationSplashPage extends StatefulWidget {
  const InitializationSplashPage({super.key});

  @override
  State<InitializationSplashPage> createState() =>
      _InitializationSplashPageState();
}

class _InitializationSplashPageState extends State<InitializationSplashPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Set up icon scale animation (respects motion preferences)
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _scaleAnimation = Tween<double>(
      begin: 0.9,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _scaleController,
        curve: Curves.easeOut,
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Start animation if motion is not reduced
    if (_scaleController.status == AnimationStatus.dismissed) {
      if (!MediaQuery.disableAnimationsOf(context)) {
        _scaleController.forward();
      } else {
        // Skip animation, show at full scale
        _scaleController.value = 1.0;
      }
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Semantics(
          label: 'Loading Expense Tracker',
          child: Center(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Responsive sizing
                final isMobile = constraints.maxWidth < 768;
                final isTablet =
                    constraints.maxWidth >= 768 && constraints.maxWidth <= 1920;

                final iconSize = isMobile ? 80.0 : (isTablet ? 100.0 : 120.0);
                final appNameSize =
                    isMobile ? 28.0 : (isTablet ? 30.0 : 32.0);
                final horizontalPadding = isMobile ? 32.0 : 64.0;

                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Icon with optional scale animation
                      ScaleTransition(
                        scale: _scaleAnimation,
                        child: Icon(
                          Icons.account_balance_wallet,
                          size: iconSize,
                          color: const Color(0xFF6200EE), // Primary purple
                        ),
                      ),
                      const SizedBox(height: 24),

                      // App name
                      Text(
                        'Expense Tracker',
                        style: TextStyle(
                          fontSize: appNameSize,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.5,
                          color: const Color(0xFF1F1F1F), // Near-black
                        ),
                      ),
                      const SizedBox(height: 60),

                      // Loading indicator
                      const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedDots(),
                          SizedBox(height: 12),
                          Text(
                            'Loading...',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF757575), // Medium gray
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
