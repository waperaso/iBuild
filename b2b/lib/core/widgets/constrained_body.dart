import 'package:flutter/material.dart';

import '../theme/app_dimens.dart';

/// Centers content with a max width on wide screens; passthrough on mobile.
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
