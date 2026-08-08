import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../theme/app_dimens.dart';

/// Mouse/trackpad horizontal scrolling without the bulky overlay scrollbar
/// Flutter draws by default on desktop/web.
class _HorizontalScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.stylus,
  };

  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) => child;

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) => child;

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const ClampingScrollPhysics();
}

/// Horizontal list rail with mouse-drag scrolling — used for developer cards,
/// district chips and category filters.
class HorizontalScrollRail extends StatelessWidget {
  const HorizontalScrollRail({
    super.key,
    required this.height,
    required this.itemCount,
    required this.itemBuilder,
    this.separatorWidth = AppSpacing.sm,
    this.padding,
  });

  final double height;
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final double separatorWidth;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ScrollConfiguration(
        behavior: _HorizontalScrollBehavior(),
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: padding,
          physics: const ClampingScrollPhysics(),
          cacheExtent: 120,
          itemCount: itemCount,
          separatorBuilder: (_, _) => SizedBox(width: separatorWidth),
          itemBuilder: itemBuilder,
        ),
      ),
    );
  }
}

/// Wraps a row of children in the same horizontal-scroll behaviour as
/// [HorizontalScrollRail] (category chips, tag rows, etc.).
class HorizontalScrollRow extends StatelessWidget {
  const HorizontalScrollRow({
    super.key,
    required this.height,
    required this.children,
    this.padding,
  });

  final double height;
  final List<Widget> children;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ScrollConfiguration(
        behavior: _HorizontalScrollBehavior(),
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: padding,
          physics: const ClampingScrollPhysics(),
          cacheExtent: 120,
          children: children,
        ),
      ),
    );
  }
}
