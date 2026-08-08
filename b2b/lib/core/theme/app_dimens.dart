import 'package:flutter/widgets.dart';

/// Spacing scale.
abstract class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;
}

abstract class AppRadii {
  /// Inputs/dropdowns — tighter than [sm] so fields stay rectangular, not pills.
  static const double input = 8;

  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;

  /// Default card radius seen throughout the mockups.
  static const double card = 24;

  /// Full pill (chips, bottom nav, primary buttons).
  static const double pill = 999;
}

/// Shared motion durations/curves.
abstract class AppDurations {
  static const Duration fast = Duration(milliseconds: 160);
  static const Duration medium = Duration(milliseconds: 240);
  static const Duration slow = Duration(milliseconds: 360);

  static const Curve enter = Curves.easeOutCubic;
  static const Curve exit = Curves.easeInCubic;
}

/// Low-opacity layered shadows for elevated surfaces.
abstract class AppShadows {
  static List<BoxShadow> soft(Color ink) => [
    BoxShadow(
      color: ink.withValues(alpha: 0.04),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: ink.withValues(alpha: 0.03),
      blurRadius: 24,
      offset: const Offset(0, 12),
    ),
  ];

  static List<BoxShadow> raised(Color ink) => [
    BoxShadow(
      color: ink.withValues(alpha: 0.06),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
    BoxShadow(
      color: ink.withValues(alpha: 0.04),
      blurRadius: 40,
      offset: const Offset(0, 20),
    ),
  ];
}

/// Responsive breakpoints (logical pixels of the shortest usable width).
abstract class AppBreakpoints {
  static const double mobile = 700;
  static const double tablet = 1100;

  /// Content is capped at this width on very wide desktop windows.
  static const double maxContentWidth = 1280;
}

/// Which layout family the current width falls into.
enum ScreenSize { mobile, tablet, desktop }

extension ScreenSizeContext on BuildContext {
  ScreenSize get screenSize {
    final width = MediaQuery.sizeOf(this).width;
    if (width < AppBreakpoints.mobile) return ScreenSize.mobile;
    if (width < AppBreakpoints.tablet) return ScreenSize.tablet;
    return ScreenSize.desktop;
  }

  bool get isMobile => screenSize == ScreenSize.mobile;
  bool get isDesktop => screenSize == ScreenSize.desktop;
}
