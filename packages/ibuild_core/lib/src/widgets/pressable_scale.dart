import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Hover lift (desktop/web) and press scale. Uses [Listener] so it does not
/// compete with tap handlers below. Motion skipped on Flutter web (perf).
class PressableScale extends StatefulWidget {
  const PressableScale({
    super.key,
    required this.child,
    this.hoverScale = 1.02,
    this.pressScale = 0.97,
    this.enabled = true,
  });

  final Widget child;
  final double hoverScale;
  final double pressScale;
  final bool enabled;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _hovered = false;
  bool _pressed = false;

  double get _scale {
    if (!widget.enabled) return 1;
    if (_pressed) return widget.pressScale;
    if (_hovered) return widget.hoverScale;
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb || !widget.enabled) return widget.child;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Listener(
        onPointerDown: (_) => setState(() => _pressed = true),
        onPointerUp: (_) => setState(() => _pressed = false),
        onPointerCancel: (_) => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _scale,
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          child: widget.child,
        ),
      ),
    );
  }
}
