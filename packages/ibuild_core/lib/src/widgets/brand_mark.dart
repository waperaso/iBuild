import 'package:flutter/material.dart';
import 'package:ibuild_core/ibuild_core.dart';

/// Official iBuild logo — light and dark variants from brand assets.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 44, this.onDark});

  final double size;

  /// When set, forces the dark-logo variant. When null, follows app [ThemeMode].
  final bool? onDark;

  @override
  Widget build(BuildContext context) {
    final useDark =
        onDark ?? Theme.of(context).brightness == Brightness.dark;
    final asset = useDark ? ibuildLogoDarkAsset : ibuildLogoAsset;
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.12),
      child: Image.asset(
        asset,
        package: 'ibuild_core',
        width: size,
        height: size,
        fit: BoxFit.cover,
        semanticLabel: 'iBuild',
        errorBuilder: (context, error, stackTrace) => Image.asset(
          asset,
          width: size,
          height: size,
          fit: BoxFit.cover,
          semanticLabel: 'iBuild',
        ),
      ),
    );
  }
}
