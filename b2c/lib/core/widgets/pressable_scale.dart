import 'package:flutter/material.dart';

/// Pass-through wrapper; [hoverScale]/[pressScale] kept for call-site compat.
class PressableScale extends StatelessWidget {
  const PressableScale({
    super.key,
    required this.child,
    this.hoverScale = 1.02,
    this.pressScale = 0.97,
    this.enabled = true,
  });

  final Widget child;

  /// Ignored; retained for call-site compatibility.
  final double hoverScale;

  /// Ignored; retained for call-site compatibility.
  final double pressScale;

  final bool enabled;

  @override
  Widget build(BuildContext context) => child;
}
