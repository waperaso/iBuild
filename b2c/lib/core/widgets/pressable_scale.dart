import 'package:flutter/material.dart';



/// Identity wrapper kept for call-site compatibility.

///

/// Hover/press scale used to live here, but on Flutter web those

/// [AnimatedScale] rebuilds made every card and button feel laggy. Taps are

/// plain now — no motion tax on interaction.

class PressableScale extends StatelessWidget {

  const PressableScale({

    super.key,

    required this.child,

    this.hoverScale = 1.02,

    this.pressScale = 0.97,

    this.enabled = true,

  });



  final Widget child;



  /// Retained so existing call sites keep compiling; ignored.

  final double hoverScale;



  /// Retained so existing call sites keep compiling; ignored.

  final double pressScale;

  final bool enabled;



  @override

  Widget build(BuildContext context) => child;

}


