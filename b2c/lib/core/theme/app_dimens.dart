import 'package:flutter/widgets.dart';

/// Spacing, radii and layout breakpoints. Central place so the whole UI stays
/// on a consistent rhythm and the "computer view" vs "mobile view" cutoffs live
/// in one spot.
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
  /// Geometric-but-rounded corner for compact controls (inputs, small chips).
  static const double input = 10;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;

  /// Default card radius seen throughout the mockups.
  static const double card = 24;

  /// Full pill (chips, bottom nav, primary buttons).
  static const double pill = 999;
}

/// Motion tokens for page/element transitions — a shared, deliberate rhythm so
/// navigation and micro-interactions feel intentional instead of instant cuts.
abstract class AppDurations {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration medium = Duration(milliseconds: 260);
  static const Duration slow = Duration(milliseconds: 400);

  static const Curve enter = Curves.easeOutCubic;
  static const Curve exit = Curves.easeInCubic;
}

/// Soft, layered shadow tokens for a premium sense of depth (deliberately
/// gentler than Material's default hard drop-shadow). Callers pass the active
/// palette's ink tone so shadows stay consistent across light/dark schemes.
abstract class AppShadows {
  /// Resting elevation for cards and surfaces.
  static List<BoxShadow> soft(Color ink) => [
    BoxShadow(
      color: ink.withValues(alpha: 0.04),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
    BoxShadow(
      color: ink.withValues(alpha: 0.06),
      blurRadius: 24,
      offset: const Offset(0, 12),
    ),
  ];

  /// Higher elevation for floating controls, sheets and hovered cards.
  static List<BoxShadow> raised(Color ink) => [
    BoxShadow(
      color: ink.withValues(alpha: 0.08),
      blurRadius: 16,
      offset: const Offset(0, 6),
    ),
    BoxShadow(
      color: ink.withValues(alpha: 0.10),
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
