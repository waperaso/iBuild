import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Staggered fade + slide-up for list/grid items. No-op on web (perf).
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({
    super.key,
    required this.child,
    this.index = 0,
    this.delayStep = const Duration(milliseconds: 35),
  });

  final Widget child;
  final int index;
  final Duration delayStep;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  Animation<double>? _fade;
  Animation<Offset>? _slide;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) return;

    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 340),
    );
    _controller = controller;
    _fade = CurvedAnimation(parent: controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(_fade!);

    // Cap stagger depth on long lists.
    final delay = widget.delayStep * widget.index.clamp(0, 10);
    if (delay == Duration.zero) {
      controller.forward();
    } else {
      Future.delayed(delay, () {
        if (mounted) controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb || _controller == null || _fade == null || _slide == null) {
      return widget.child;
    }
    return FadeTransition(
      opacity: _fade!,
      child: SlideTransition(position: _slide!, child: widget.child),
    );
  }
}
