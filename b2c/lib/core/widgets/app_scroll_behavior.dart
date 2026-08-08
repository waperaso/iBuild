import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Desktop/web scroll: mouse/trackpad drag, clamping on web, no overscroll glow,
/// and a themed vertical scrollbar on desktop/web.
class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.stylus,
  };

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    if (kIsWeb) return const ClampingScrollPhysics();
    return super.getScrollPhysics(context);
  }

  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    final vertical = details.direction == AxisDirection.down ||
        details.direction == AxisDirection.up;
    if (!vertical) return child;

    if (kIsWeb || _usesDesktopScrollbar(context)) {
      return Scrollbar(
        controller: details.controller,
        interactive: true,
        child: child,
      );
    }
    return super.buildScrollbar(context, child, details);
  }

  bool _usesDesktopScrollbar(BuildContext context) {
    switch (getPlatform(context)) {
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
        return true;
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      case TargetPlatform.iOS:
        return false;
    }
  }

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    if (kIsWeb) return child;
    return super.buildOverscrollIndicator(context, child, details);
  }
}
