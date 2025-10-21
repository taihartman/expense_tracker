import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Responsive layout utilities for mobile-first design
/// Supports breakpoints: 375px (mobile), 768px (tablet), 1920px (desktop)
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= AppTheme.desktopBreakpoint) {
          return desktop ?? tablet ?? mobile;
        } else if (constraints.maxWidth >= AppTheme.tabletBreakpoint) {
          return tablet ?? mobile;
        } else {
          return mobile;
        }
      },
    );
  }
}

/// Responsive value selector - returns different values based on screen size
class ResponsiveValue<T> {
  final T mobile;
  final T? tablet;
  final T? desktop;

  const ResponsiveValue({
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  T getValue(BuildContext context) {
    if (AppTheme.isDesktop(context)) {
      return desktop ?? tablet ?? mobile;
    } else if (AppTheme.isTablet(context)) {
      return tablet ?? mobile;
    } else {
      return mobile;
    }
  }
}

/// Helper for responsive font sizes
double responsiveFontSize(BuildContext context, {
  required double mobile,
  double? tablet,
  double? desktop,
}) {
  return ResponsiveValue(
    mobile: mobile,
    tablet: tablet,
    desktop: desktop,
  ).getValue(context);
}

/// Helper for responsive spacing
double responsiveSpacing(BuildContext context, {
  required double mobile,
  double? tablet,
  double? desktop,
}) {
  return ResponsiveValue(
    mobile: mobile,
    tablet: tablet,
    desktop: desktop,
  ).getValue(context);
}

/// Responsive grid wrapper
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final double runSpacing;

  const ResponsiveGrid({
    super.key,
    required this.children,
    this.spacing = AppTheme.spacing2,
    this.runSpacing = AppTheme.spacing2,
  });

  @override
  Widget build(BuildContext context) {
    final columns = AppTheme.responsiveColumns(context);

    return Wrap(
      spacing: spacing,
      runSpacing: runSpacing,
      children: children.map((child) {
        return SizedBox(
          width: (MediaQuery.of(context).size.width -
                  (spacing * (columns + 1))) / columns,
          child: child,
        );
      }).toList(),
    );
  }
}
