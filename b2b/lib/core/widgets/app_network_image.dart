import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ibuild_core/ibuild_core.dart';

import '../env.dart';
import '../theme/app_dimens.dart';
import '../theme/app_theme_ext.dart';

/// Network image with decode-size hints and optional lazy loading on mobile web.
class AppNetworkImage extends StatelessWidget {
  const AppNetworkImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.memCacheWidth,
    this.memCacheHeight,
    this.lazy,
  });

  final String? url;
  final BoxFit fit;
  final double? width;
  final double? height;
  final int? memCacheWidth;
  final int? memCacheHeight;
  final bool? lazy;

  static String? resolveUrl(String? raw) => Env.resolveUrl(raw);

  bool _lazyLoad(BuildContext context) {
    if (lazy != null) return lazy!;
    return kIsWeb && context.isMobile;
  }

  Widget _placeholder(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: width,
      height: height,
      color: colors.surfaceAlt,
    );
  }

  Widget _missing(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: width,
      height: height,
      color: colors.surfaceAlt,
      child: Icon(Icons.image_outlined, color: colors.inkMuted),
    );
  }

  Widget _broken(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: width,
      height: height,
      color: colors.surfaceAlt,
      child: Icon(Icons.broken_image_outlined, color: colors.inkMuted),
    );
  }

  int _cacheWidth(BuildContext context) {
    if (memCacheWidth != null) return memCacheWidth!;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    if (width != null && width!.isFinite) {
      return (width! * dpr).round();
    }
    return context.isMobile ? 400 : 600;
  }

  int? _cacheHeight(BuildContext context) {
    if (memCacheHeight != null) return memCacheHeight;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    if (height != null && height!.isFinite) {
      return (height! * dpr).round();
    }
    return null;
  }

  /// Web bypasses [CachedNetworkImage]/cache-manager (unreliable for large
  /// residence PNGs); IO keeps disk caching. Both paths decode at [cacheWidth].
  Widget _buildImage(BuildContext context, String resolved) {
    final cacheW = _cacheWidth(context);
    final cacheH = _cacheHeight(context);

    if (kIsWeb) {
      return Image.network(
        resolved,
        key: ValueKey(resolved),
        width: width,
        height: height,
        fit: fit,
        cacheWidth: cacheW,
        cacheHeight: cacheH,
        filterQuality: FilterQuality.low,
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded || frame != null) return child;
          return _placeholder(context);
        },
        errorBuilder: (context, _, _) => _broken(context),
      );
    }

    return CachedNetworkImage(
      imageUrl: resolved,
      width: width,
      height: height,
      fit: fit,
      memCacheWidth: cacheW,
      memCacheHeight: cacheH,
      fadeInDuration: Duration.zero,
      fadeOutDuration: Duration.zero,
      placeholder: (context, _) => _placeholder(context),
      errorWidget: (context, _, _) => _broken(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    final resolved = resolveUrl(url);
    if (resolved == null) return _missing(context);

    final image = _buildImage(context, resolved);
    if (!_lazyLoad(context)) return image;

    return LazyVisibility(
      placeholder: _placeholder(context),
      preloadExtent: 320,
      child: image,
    );
  }
}
