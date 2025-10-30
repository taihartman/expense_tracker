import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/l10n_extensions.dart';
import '../../router/app_routes.dart';
import '../widgets/animated_dots.dart';
import '../../../features/trips/presentation/cubits/trip_cubit.dart';
import '../../../features/trips/presentation/cubits/trip_state.dart';

/// Splash screen displayed during app initialization and data loading.
///
/// Shows brand identity (icon + app name) and loading indicator while:
/// - Firebase completes initialization
/// - Trip data loads from Firestore
/// - User preferences are loaded
///
/// Navigation is handled by AppRouter's redirect logic, which preserves deep links.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  bool _hasNavigated = false;

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
    ).animate(CurvedAnimation(parent: _scaleController, curve: Curves.easeOut));

    // Trigger trip data loading
    Future.microtask(() {
      if (mounted) {
        context.read<TripCubit>().loadTrips();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Start animation if motion is not reduced (check after dependencies are available)
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
    return BlocListener<TripCubit, TripState>(
      listener: (context, state) {
        // When trips are loaded, trigger navigation which will invoke the router's redirect
        // The redirect will navigate to the preserved deep link or home
        if (state is TripLoaded || state is TripError) {
          if (!_hasNavigated && mounted) {
            _hasNavigated = true;
            // Navigate to splash itself - this triggers the redirect callback
            // which will then navigate to the preserved deep link or home
            Future.delayed(const Duration(milliseconds: 100), () {
              if (mounted) {
                context.go(AppRoutes.splash);
              }
            });
          }
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Semantics(
            label: context.l10n.splashLoadingAccessibility,
            child: Center(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Responsive sizing
                  final isMobile = constraints.maxWidth < 768;
                  final isTablet =
                      constraints.maxWidth >= 768 &&
                      constraints.maxWidth <= 1920;

                  final iconSize = isMobile ? 80.0 : (isTablet ? 100.0 : 120.0);
                  final appNameSize = isMobile
                      ? 28.0
                      : (isTablet ? 30.0 : 32.0);
                  final horizontalPadding = isMobile ? 32.0 : 64.0;

                  return Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                    ),
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
                          context.l10n.splashAppName,
                          style: TextStyle(
                            fontSize: appNameSize,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.5,
                            color: const Color(0xFF1F1F1F), // Near-black
                          ),
                        ),
                        const SizedBox(height: 60),

                        // Loading indicator
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const AnimatedDots(),
                            const SizedBox(height: 12),
                            Text(
                              context.l10n.splashLoading,
                              style: const TextStyle(
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
      ),
    );
  }
}
