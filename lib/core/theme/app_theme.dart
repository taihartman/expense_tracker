import 'package:flutter/material.dart';

/// Material Design 3 theme with 8px grid system and mobile-first responsive design
/// Constitutional requirement: Principle III (UX Consistency)
class AppTheme {
  // 8px base unit for spacing consistency
  static const double baseUnit = 8.0;

  // Spacing scale (multiples of 8px)
  static const double spacing1 = baseUnit; // 8px
  static const double spacing2 = baseUnit * 2; // 16px
  static const double spacing3 = baseUnit * 3; // 24px
  static const double spacing4 = baseUnit * 4; // 32px
  static const double spacing5 = baseUnit * 5; // 40px
  static const double spacing6 = baseUnit * 6; // 48px

  // Responsive breakpoints (mobile-first)
  static const double mobileBreakpoint = 375.0; // Mobile phones
  static const double tabletBreakpoint = 768.0; // Tablets
  static const double desktopBreakpoint = 1920.0; // Desktop/4K

  // Minimum touch target size (accessibility requirement - mobile-friendly)
  static const double minTouchTarget = 44.0;

  // Color scheme
  static const Color primaryColor = Color(0xFF6200EE);
  static const Color secondaryColor = Color(0xFF03DAC6);
  static const Color errorColor = Color(0xFFB00020);

  // Settlement summary colors (green = positive net, red = negative net)
  static const Color positiveNetColor = Color(0xFF4CAF50); // Green
  static const Color negativeNetColor = Color(0xFFF44336); // Red
  static const Color neutralColor = Color(0xFF9E9E9E); // Grey

  /// Check if screen is mobile size
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < tabletBreakpoint;
  }

  /// Check if screen is tablet size
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= tabletBreakpoint && width < desktopBreakpoint;
  }

  /// Check if screen is desktop size
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= desktopBreakpoint;
  }

  /// Get responsive padding based on screen size
  static EdgeInsets responsivePadding(BuildContext context) {
    if (isMobile(context)) {
      return const EdgeInsets.all(spacing2); // 16px on mobile
    } else if (isTablet(context)) {
      return const EdgeInsets.all(spacing3); // 24px on tablet
    } else {
      return const EdgeInsets.all(spacing4); // 32px on desktop
    }
  }

  /// Get responsive column count for grids
  static int responsiveColumns(BuildContext context) {
    if (isMobile(context)) {
      return 1; // Single column on mobile
    } else if (isTablet(context)) {
      return 2; // Two columns on tablet
    } else {
      return 3; // Three columns on desktop
    }
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        secondary: secondaryColor,
        error: errorColor,
      ),

      // Typography (mobile-optimized sizes)
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontSize: 57, fontWeight: FontWeight.w400),
        displayMedium: TextStyle(fontSize: 45, fontWeight: FontWeight.w400),
        displaySmall: TextStyle(fontSize: 36, fontWeight: FontWeight.w400),
        headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w400),
        headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w400),
        headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w400),
        titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
        bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
        bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
      ),

      // Component themes (mobile-optimized with 44px touch targets)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(minTouchTarget, minTouchTarget),
          padding: const EdgeInsets.symmetric(
            horizontal: spacing3,
            vertical: spacing2,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(minTouchTarget, minTouchTarget),
          padding: const EdgeInsets.symmetric(
            horizontal: spacing2,
            vertical: spacing1,
          ),
        ),
      ),

      inputDecorationTheme: const InputDecorationTheme(
        contentPadding: EdgeInsets.symmetric(
          horizontal: spacing2,
          vertical: spacing2,
        ),
        border: OutlineInputBorder(),
      ),

      cardTheme: CardThemeData(
        margin: const EdgeInsets.all(spacing2),
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(spacing2),
        ),
      ),

      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
      ),

      // List tile theme (mobile-friendly spacing)
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(
          horizontal: spacing2,
          vertical: spacing1,
        ),
        minVerticalPadding: spacing1,
      ),

      // Bottom sheet theme (mobile-optimized)
      bottomSheetTheme: const BottomSheetThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(spacing2),
          ),
        ),
      ),
    );
  }

  /// Helper method to get color based on balance value
  static Color getBalanceColor(num balance) {
    if (balance > 0) return positiveNetColor;
    if (balance < 0) return negativeNetColor;
    return neutralColor;
  }
}
