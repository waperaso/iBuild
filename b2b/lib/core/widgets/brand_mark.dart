import 'package:flutter/material.dart';

import '../theme/app_theme_ext.dart';

/// The little dark rounded-square "iBuild" mark used in the sidebar logo —
/// pulled out so auth screens can reuse it as a brand anchor instead of
/// jumping straight into a headline with no visual identity.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 44});

  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: colors.ink,
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      child: Icon(Icons.apartment, color: colors.accent, size: size * 0.5),
    );
  }
}
