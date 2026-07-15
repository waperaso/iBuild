import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../config/env.dart';
import '../theme/app_theme_ext.dart';

/// Network image with a shimmer placeholder and a graceful fallback.
class AppNetworkImage extends StatelessWidget {
  const AppNetworkImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.memCacheWidth,
    this.memCacheHeight,
  });

  final String? url;
  final BoxFit fit;
  final double? width;
  final double? height;

  /// Decode-size hint for [CachedNetworkImage] — keeps card thumbnails from
  /// decoding full-resolution gallery photos into GPU memory.
  final int? memCacheWidth;
  final int? memCacheHeight;

  /// Turns server-relative paths (`/v1/static/...`) into absolute URLs using
  /// [Env.apiBaseUrl] so locally hosted residence photos work in every build.
  static String? resolveUrl(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;
    if (raw.startsWith('/')) {
      return Uri.parse(Env.apiBaseUrl).resolve(raw).toString();
    }
    return raw;
  }

  Widget _placeholder(BuildContext context) {
    final colors = context.colors;
    final box = Container(
      width: width,
      height: height,
      color: colors.surfaceAlt,
    );
    if (kIsWeb) return box;
    return Shimmer.fromColors(
      baseColor: colors.surfaceAlt,
      highlightColor: colors.surface,
      child: box,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final resolved = resolveUrl(url);
    if (resolved == null) {
      return Container(
        width: width,
        height: height,
        color: colors.surfaceAlt,
        child: Icon(Icons.image_outlined, color: colors.inkMuted),
      );
    }

    final dpr = MediaQuery.devicePixelRatioOf(context);
    final cacheW = memCacheWidth ??
        (width != null && width!.isFinite ? (width! * dpr).round() : 600);
    final cacheH = memCacheHeight ??
        (height != null && height!.isFinite ? (height! * dpr).round() : null);

    return CachedNetworkImage(
      imageUrl: resolved,
      width: width,
      height: height,
      fit: fit,
      memCacheWidth: cacheW,
      memCacheHeight: cacheH,
      fadeInDuration: kIsWeb ? Duration.zero : const Duration(milliseconds: 300),
      fadeOutDuration: kIsWeb ? Duration.zero : const Duration(milliseconds: 300),
      placeholder: (context, _) => _placeholder(context),
      errorWidget: (context, _, _) => Container(
        width: width,
        height: height,
        color: colors.surfaceAlt,
        child: Icon(Icons.broken_image_outlined, color: colors.inkMuted),
      ),
    );
  }
}
