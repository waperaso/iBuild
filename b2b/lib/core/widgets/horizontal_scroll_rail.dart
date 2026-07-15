import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../theme/app_dimens.dart';
import '../theme/app_theme_ext.dart';

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
}

/// Horizontal list rail with mouse-drag scrolling and subtle edge fades on
/// desktop — used for developer cards, district chips and category filters.
class HorizontalScrollRail extends StatefulWidget {
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
  State<HorizontalScrollRail> createState() => _HorizontalScrollRailState();
}

class _HorizontalScrollRailState extends State<HorizontalScrollRail> {
  final _controller = ScrollController();
  bool _canScrollLeft = false;
  bool _canScrollRight = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_updateFadeHints);
  }

  @override
  void dispose() {
    _controller.removeListener(_updateFadeHints);
    _controller.dispose();
    super.dispose();
  }

  void _updateFadeHints() {
    if (!_controller.hasClients) return;
    final pos = _controller.position;
    final left = pos.pixels > 0.5;
    final right = pos.pixels < pos.maxScrollExtent - 0.5;
    if (left == _canScrollLeft && right == _canScrollRight) return;
    setState(() {
      _canScrollLeft = left;
      _canScrollRight = right;
    });
  }

  void _scheduleFadeUpdate() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) _updateFadeHints();
    });
  }

  @override
  void didUpdateWidget(covariant HorizontalScrollRail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.itemCount != widget.itemCount) _scheduleFadeUpdate();
  }

  @override
  Widget build(BuildContext context) {
    _scheduleFadeUpdate();

    final list = ListView.separated(
      controller: _controller,
      scrollDirection: Axis.horizontal,
      padding: widget.padding,
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      itemCount: widget.itemCount,
      separatorBuilder: (_, _) => SizedBox(width: widget.separatorWidth),
      itemBuilder: widget.itemBuilder,
    );

    return SizedBox(
      height: widget.height,
      child: _HorizontalScrollChrome(
        showFades: !context.isMobile,
        canScrollLeft: _canScrollLeft,
        canScrollRight: _canScrollRight,
        child: list,
      ),
    );
  }
}

/// Wraps a row of children in the same horizontal-scroll behaviour as
/// [HorizontalScrollRail] (category chips, tag rows, etc.).
class HorizontalScrollRow extends StatefulWidget {
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
  State<HorizontalScrollRow> createState() => _HorizontalScrollRowState();
}

class _HorizontalScrollRowState extends State<HorizontalScrollRow> {
  final _controller = ScrollController();
  bool _canScrollLeft = false;
  bool _canScrollRight = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_updateFadeHints);
  }

  @override
  void dispose() {
    _controller.removeListener(_updateFadeHints);
    _controller.dispose();
    super.dispose();
  }

  void _updateFadeHints() {
    if (!_controller.hasClients) return;
    final pos = _controller.position;
    final left = pos.pixels > 0.5;
    final right = pos.pixels < pos.maxScrollExtent - 0.5;
    if (left == _canScrollLeft && right == _canScrollRight) return;
    setState(() {
      _canScrollLeft = left;
      _canScrollRight = right;
    });
  }

  void _scheduleFadeUpdate() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) _updateFadeHints();
    });
  }

  @override
  void didUpdateWidget(covariant HorizontalScrollRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.children.length != widget.children.length) {
      _scheduleFadeUpdate();
    }
  }

  @override
  Widget build(BuildContext context) {
    _scheduleFadeUpdate();

    final list = ListView(
      controller: _controller,
      scrollDirection: Axis.horizontal,
      padding: widget.padding,
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      children: widget.children,
    );

    return SizedBox(
      height: widget.height,
      child: _HorizontalScrollChrome(
        showFades: !context.isMobile,
        canScrollLeft: _canScrollLeft,
        canScrollRight: _canScrollRight,
        child: list,
      ),
    );
  }
}

/// Scroll configuration + optional edge fades — no overlay scrollbar.
class _HorizontalScrollChrome extends StatelessWidget {
  const _HorizontalScrollChrome({
    required this.child,
    required this.showFades,
    required this.canScrollLeft,
    required this.canScrollRight,
  });

  final Widget child;
  final bool showFades;
  final bool canScrollLeft;
  final bool canScrollRight;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return ScrollConfiguration(
      behavior: _HorizontalScrollBehavior(),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          child,
          if (showFades && canScrollLeft)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: IgnorePointer(
                child: _EdgeFade(color: colors.background, alignLeft: true),
              ),
            ),
          if (showFades && canScrollRight)
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: IgnorePointer(
                child: _EdgeFade(color: colors.background, alignLeft: false),
              ),
            ),
        ],
      ),
    );
  }
}

class _EdgeFade extends StatelessWidget {
  const _EdgeFade({required this.color, required this.alignLeft});

  final Color color;
  final bool alignLeft;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: alignLeft ? Alignment.centerLeft : Alignment.centerRight,
          end: alignLeft ? Alignment.centerRight : Alignment.centerLeft,
          colors: [color, color.withValues(alpha: 0)],
        ),
      ),
    );
  }
}
