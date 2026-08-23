import 'package:flutter/material.dart';

/// Builds [child] only when the widget is near or inside a scroll viewport.
///
/// Off-screen placeholders keep layout stable via [placeholder] (same size as
/// [child]) so scroll metrics stay correct while network/decode work is skipped.
class LazyVisibility extends StatefulWidget {
  const LazyVisibility({
    super.key,
    required this.child,
    required this.placeholder,
    this.preloadExtent = 280,
    this.enabled = true,
  });

  final Widget child;
  final Widget placeholder;

  /// How many logical pixels before entering the viewport to start building.
  final double preloadExtent;

  /// When false, [child] is always built (desktop / tests).
  final bool enabled;

  @override
  State<LazyVisibility> createState() => _LazyVisibilityState();
}

class _LazyVisibilityState extends State<LazyVisibility> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    if (!widget.enabled) {
      _visible = true;
      return;
    }
    // First layout often has no size yet; retry a few frames so above-the-fold
    // items (e.g. AI search thumbs) are not stuck on the placeholder until the
    // user scrolls and a [ScrollNotification] fires.
    _scheduleVisibilityChecks();
  }

  void _scheduleVisibilityChecks() {
    var attempt = 0;
    void tick() {
      if (!mounted || _visible) return;
      _updateVisibility();
      if (_visible || attempt >= 8) return;
      attempt++;
      WidgetsBinding.instance.addPostFrameCallback((_) => tick());
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => tick());
  }

  bool _isNearViewport() {
    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return false;

    final scrollable = Scrollable.maybeOf(context);
    if (scrollable == null) return true;

    final position = scrollable.position;
    final scrollBox = scrollable.context.findRenderObject();
    if (scrollBox is! RenderBox) return true;

    final itemGlobal = renderObject.localToGlobal(Offset.zero);
    final scrollGlobal = scrollBox.localToGlobal(Offset.zero);
    final axis = position.axis;
    final itemStart = axis == Axis.vertical
        ? itemGlobal.dy - scrollGlobal.dy + position.pixels
        : itemGlobal.dx - scrollGlobal.dx + position.pixels;
    final itemExtent = axis == Axis.vertical
        ? renderObject.size.height
        : renderObject.size.width;
    final itemEnd = itemStart + itemExtent;
    final viewStart = position.pixels;
    final viewEnd = viewStart + position.viewportDimension;
    final preload = widget.preloadExtent;

    return itemEnd >= viewStart - preload && itemStart <= viewEnd + preload;
  }

  void _updateVisibility() {
    if (!mounted || _visible) return;
    if (_isNearViewport()) setState(() => _visible = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled || _visible) return widget.child;

    return NotificationListener<ScrollNotification>(
      onNotification: (_) {
        _updateVisibility();
        return false;
      },
      child: widget.placeholder,
    );
  }
}

/// Defers building heavy header sections until after the first frame so the
/// primary scroll feed can paint and respond to touch immediately.
class DeferredBuild extends StatefulWidget {
  const DeferredBuild({super.key, required this.builder});

  final WidgetBuilder builder;

  @override
  State<DeferredBuild> createState() => _DeferredBuildState();
}

class _DeferredBuildState extends State<DeferredBuild> {
  var _ready = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _ready = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return _ready ? widget.builder(context) : const SizedBox.shrink();
  }
}
