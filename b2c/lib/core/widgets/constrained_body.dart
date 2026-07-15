import 'package:flutter/material.dart';

import '../theme/app_dimens.dart';

/// Caps content width and centers it on wide desktop windows.
///
/// Detail routes (project, unit, unit grid, lead form) push onto the root
/// navigator — outside [AdaptiveScaffold] — so without this they'd render
/// edge-to-edge on a big monitor. On mobile it's a no-op passthrough.
class ConstrainedBody extends StatelessWidget {
  const ConstrainedBody({super.key, required this.child, this.maxWidth = 760});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.sizeOf(context).width < AppBreakpoints.mobile) {
      return child;
    }
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
