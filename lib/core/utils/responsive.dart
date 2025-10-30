import 'package:flutter/widgets.dart';

/// Responsive design helper utilities for mobile-first design.
///
/// This file provides helper methods to make responsive design easier and more consistent
/// across the application. Use these helpers instead of duplicating MediaQuery logic.
///
/// Example usage:
/// ```dart
/// if (isMobile(context)) {
///   // Mobile-specific UI
/// }
///
/// final padding = responsivePadding(context);
/// final fontSize = responsiveFontSize(context, mobile: 14, desktop: 16);
/// ```

/// Standard responsive breakpoints used throughout the app.
class ResponsiveBreakpoints {
  /// Mobile viewport (phones): < 600px wide
  static const double mobile = 600;

  /// Tablet viewport: 600px - 1024px wide
  static const double tablet = 1024;

  /// Desktop viewport: > 1024px wide
  static const double desktop = 1024;
}

/// Returns true if the current device is considered mobile (< 600px wide).
///
/// Use this for mobile-specific layouts, spacing, and interactions.
/// Example:
/// ```dart
/// if (isMobile(context)) {
///   return MobileLayout();
/// }
/// return DesktopLayout();
/// ```
bool isMobile(BuildContext context) {
  final width = MediaQuery.of(context).size.width;
  return width < ResponsiveBreakpoints.mobile;
}

/// Returns true if the current device is considered a tablet (600px - 1024px wide).
///
/// Use this for tablet-specific layouts when the design differs from both mobile and desktop.
/// Example:
/// ```dart
/// if (isTablet(context)) {
///   return TabletLayout();
/// }
/// ```
bool isTablet(BuildContext context) {
  final width = MediaQuery.of(context).size.width;
  return width >= ResponsiveBreakpoints.mobile &&
      width < ResponsiveBreakpoints.tablet;
}

/// Returns true if the current device is considered desktop (>= 1024px wide).
///
/// Use this for desktop-specific layouts with more horizontal space.
/// Example:
/// ```dart
/// if (isDesktop(context)) {
///   return DesktopLayout();
/// }
/// ```
bool isDesktop(BuildContext context) {
  final width = MediaQuery.of(context).size.width;
  return width >= ResponsiveBreakpoints.desktop;
}

/// Returns standard responsive padding based on screen size.
///
/// Returns 12.0 for mobile, 16.0 for desktop.
/// Use this for consistent padding throughout the app.
///
/// Example:
/// ```dart
/// Padding(
///   padding: EdgeInsets.all(responsivePadding(context)),
///   child: ...
/// )
/// ```
double responsivePadding(
  BuildContext context, {
  double? mobile,
  double? desktop,
}) {
  final mobileValue = mobile ?? 12.0;
  final desktopValue = desktop ?? 16.0;
  return isMobile(context) ? mobileValue : desktopValue;
}

/// Returns responsive font size based on screen size.
///
/// By default, reduces font size by 2px on mobile (e.g., 16 -> 14).
/// You can customize mobile and desktop sizes.
///
/// Example:
/// ```dart
/// Text(
///   'Title',
///   style: TextStyle(
///     fontSize: responsiveFontSize(context, base: 20),  // 18 mobile, 20 desktop
///   ),
/// )
///
/// // Or specify both explicitly:
/// Text(
///   'Body',
///   style: TextStyle(
///     fontSize: responsiveFontSize(context, mobile: 13, desktop: 14),
///   ),
/// )
/// ```
double responsiveFontSize(
  BuildContext context, {
  double? base,
  double? mobile,
  double? desktop,
}) {
  // If both mobile and desktop are provided, use them directly
  if (mobile != null && desktop != null) {
    return isMobile(context) ? mobile : desktop;
  }

  // If base is provided, calculate mobile as base - 2
  if (base != null) {
    final mobileSize = mobile ?? (base - 2);
    final desktopSize = desktop ?? base;
    return isMobile(context) ? mobileSize : desktopSize;
  }

  // Default fallback: 14 mobile, 16 desktop
  return isMobile(context) ? (mobile ?? 14.0) : (desktop ?? 16.0);
}

/// Returns responsive icon size based on screen size.
///
/// Returns 20.0 for mobile, 24.0 for desktop by default.
/// Use this for consistent icon sizing.
///
/// Example:
/// ```dart
/// Icon(
///   Icons.edit,
///   size: responsiveIconSize(context),
/// )
/// ```
double responsiveIconSize(
  BuildContext context, {
  double? mobile,
  double? desktop,
}) {
  final mobileSize = mobile ?? 20.0;
  final desktopSize = desktop ?? 24.0;
  return isMobile(context) ? mobileSize : desktopSize;
}

/// Returns responsive spacing based on screen size.
///
/// Returns 12.0 for mobile, 16.0 for desktop by default.
/// Use this for consistent spacing between elements.
///
/// Example:
/// ```dart
/// Column(
///   children: [
///     Widget1(),
///     SizedBox(height: responsiveSpacing(context)),
///     Widget2(),
///   ],
/// )
/// ```
double responsiveSpacing(
  BuildContext context, {
  double? mobile,
  double? desktop,
}) {
  final mobileValue = mobile ?? 12.0;
  final desktopValue = desktop ?? 16.0;
  return isMobile(context) ? mobileValue : desktopValue;
}

/// Returns responsive button padding based on screen size.
///
/// Returns 12.0 for mobile, 16.0 for desktop by default.
/// Use this for consistent button sizing.
///
/// Example:
/// ```dart
/// ElevatedButton(
///   style: ElevatedButton.styleFrom(
///     padding: EdgeInsets.all(responsiveButtonPadding(context)),
///   ),
///   child: Text('Submit'),
/// )
/// ```
double responsiveButtonPadding(
  BuildContext context, {
  double? mobile,
  double? desktop,
}) {
  final mobileValue = mobile ?? 12.0;
  final desktopValue = desktop ?? 16.0;
  return isMobile(context) ? mobileValue : desktopValue;
}

/// Returns responsive EdgeInsets based on screen size.
///
/// Convenience method for creating responsive padding/margins.
///
/// Example:
/// ```dart
/// Padding(
///   padding: responsiveEdgeInsets(context),  // 12 mobile, 16 desktop
///   child: ...
/// )
///
/// // Or with custom values:
/// Padding(
///   padding: responsiveEdgeInsets(
///     context,
///     mobile: EdgeInsets.all(8),
///     desktop: EdgeInsets.all(20),
///   ),
///   child: ...
/// )
/// ```
EdgeInsets responsiveEdgeInsets(
  BuildContext context, {
  EdgeInsets? mobile,
  EdgeInsets? desktop,
}) {
  final mobileInsets = mobile ?? const EdgeInsets.all(12.0);
  final desktopInsets = desktop ?? const EdgeInsets.all(16.0);
  return isMobile(context) ? mobileInsets : desktopInsets;
}

/// Returns the screen width category as a string.
///
/// Useful for debugging or analytics.
/// Returns: 'mobile', 'tablet', or 'desktop'
///
/// Example:
/// ```dart
/// print('Screen type: ${getScreenType(context)}');
/// ```
String getScreenType(BuildContext context) {
  if (isMobile(context)) return 'mobile';
  if (isTablet(context)) return 'tablet';
  return 'desktop';
}

/// Returns responsive constraints for IconButton touch targets.
///
/// Returns smaller constraints on mobile (36x36) to save space,
/// larger on desktop (44x44) for better mouse targeting.
///
/// Example:
/// ```dart
/// IconButton(
///   icon: Icon(Icons.edit),
///   constraints: responsiveIconButtonConstraints(context),
///   padding: EdgeInsets.all(responsiveIconButtonPadding(context)),
///   onPressed: () {},
/// )
/// ```
BoxConstraints responsiveIconButtonConstraints(BuildContext context) {
  return isMobile(context)
      ? const BoxConstraints(minWidth: 36, minHeight: 36)
      : const BoxConstraints(minWidth: 44, minHeight: 44);
}

/// Returns responsive padding for IconButton.
///
/// Returns 4.0 for mobile, 8.0 for desktop.
///
/// Example: See [responsiveIconButtonConstraints].
double responsiveIconButtonPadding(BuildContext context) {
  return isMobile(context) ? 4.0 : 8.0;
}
