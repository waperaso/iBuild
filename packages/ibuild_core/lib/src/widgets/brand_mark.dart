import 'package:flutter/material.dart';
import 'package:ibuild_core/ibuild_core.dart';

/// Official iBuild logo — contrast variants from brand assets.
///
/// Light theme → dark navy mark ([ibuildLogoAsset]).
/// Dark theme → light silver mark ([ibuildLogoDarkAsset]).
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 44, this.onDark});

  final double size;

  /// When set, forces the variant for a dark (`true`) or light (`false`)
  /// surface. When null, follows [ThemeData.brightness].
  final bool? onDark;

  @override
  Widget build(BuildContext context) {
    final onDarkSurface =
        onDark ?? Theme.of(context).brightness == Brightness.dark;
    // Dark surface → light logo; light surface → dark logo.
    final asset = onDarkSurface ? ibuildLogoDarkAsset : ibuildLogoAsset;
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.12),
      child: _BrandLogoImage(asset: asset, size: size, onDark: onDarkSurface),
    );
  }
}

/// Flutter web reliably bundles app `assets/brand/`; package assets are fallback.
class _BrandLogoImage extends StatelessWidget {
  const _BrandLogoImage({
    required this.asset,
    required this.size,
    required this.onDark,
  });

  final String asset;
  final double size;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      asset,
      width: size,
      height: size,
      fit: BoxFit.cover,
      semanticLabel: 'iBuild',
      errorBuilder: (context, error, stackTrace) => Image.asset(
        asset,
        package: 'ibuild_core',
        width: size,
        height: size,
        fit: BoxFit.cover,
        semanticLabel: 'iBuild',
        errorBuilder: (context, error, stackTrace) =>
            _IbMonogramFallback(size: size, onDark: onDark),
      ),
    );
  }
}

class _IbMonogramFallback extends StatelessWidget {
  const _IbMonogramFallback({required this.size, required this.onDark});

  final double size;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: onDark ? const Color(0xFF002147) : const Color(0xFFC8CCD2),
      child: Center(
        child: Text(
          'IB',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontStyle: FontStyle.italic,
            fontSize: size * 0.42,
            height: 1,
            color: onDark ? const Color(0xFFC8CCD2) : const Color(0xFF002147),
          ),
        ),
      ),
    );
  }
}
