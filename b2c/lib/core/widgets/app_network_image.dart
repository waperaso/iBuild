import 'package:cached_network_image/cached_network_image.dart';
import 'package:cached_network_image_platform_interface/cached_network_image_platform_interface.dart'
    show ImageRenderMethodForWeb;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ibuild_core/ibuild_core.dart';
import 'package:shimmer/shimmer.dart';

import '../config/env.dart';
import '../theme/app_dimens.dart';
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
    this.lazy,
  });

  final String? url;
  final BoxFit fit;
  final double? width;
  final double? height;

  /// Decode-size hint for [CachedNetworkImage] — keeps card thumbnails from
  /// decoding full-resolution gallery photos into GPU memory.
  final int? memCacheWidth;
  final int? memCacheHeight;

  /// When true, the image fetch/decode is deferred until near the viewport.
  /// Defaults to lazy on mobile web where scroll jank is most noticeable.
  final bool? lazy;

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

  bool _lazyLoad(BuildContext context) {
    if (lazy != null) return lazy!;
    return kIsWeb && context.isMobile;
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

  int _cacheWidth(BuildContext context) {
    if (memCacheWidth != null) return memCacheWidth!;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    if (width != null && width!.isFinite) {
      return (width! * dpr).round();
    }
    // Mobile cards rarely exceed ~400 logical px — cap decode cost on phones.
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

    final image = CachedNetworkImage(
      imageUrl: resolved,
      width: width,
      height: height,
      fit: fit,
      memCacheWidth: _cacheWidth(context),
      memCacheHeight: _cacheHeight(context),
      // Web defaults to ImageRenderMethodForWeb.HtmlImage, which uploads the
      // *original* image as a GPU texture and silently ignores
      // memCacheWidth/memCacheHeight above. With many full-resolution photos
      // (our residence renders run 1-1.5MB) live across several screens,
      // CanvasKit's single WebGL context runs out of GPU memory and gets
      // dropped — every image already painted then renders solid black with
      // no error, and it only "fixes itself" after a full page reload
      // (flutter/flutter#158093, #160199, #178524). HttpGet actually decodes
      // at the requested size, so cards stay small textures instead of
      // full-size ones.
      imageRenderMethodForWeb:
          kIsWeb ? ImageRenderMethodForWeb.HttpGet : ImageRenderMethodForWeb.HtmlImage,
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

    if (!_lazyLoad(context)) return image;

    return LazyVisibility(
      placeholder: _placeholder(context),
      preloadExtent: 320,
      child: image,
    );
  }
}
