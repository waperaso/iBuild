import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Desktop/web-friendly scroll: mouse + trackpad drag, clamping physics, no
/// glow/overscroll chrome. Bounce physics on Flutter web felt laggy — every
/// list in the app (admin dashboards, CRM tables, forms) inherits this via
/// `MaterialApp.router(scrollBehavior: ...)` instead of each screen tuning
/// its own `physics:`.
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
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    if (kIsWeb) return child;
    return super.buildOverscrollIndicator(context, child, details);
  }
}
