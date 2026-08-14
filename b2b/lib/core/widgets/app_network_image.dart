import 'package:cached_network_image/cached_network_image.dart';
import 'package:cached_network_image_platform_interface/cached_network_image_platform_interface.dart'
    show ImageRenderMethodForWeb;
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
      // memCacheWidth/memCacheHeight above. With enough full-resolution
      // photos live across screens, CanvasKit's single WebGL context runs
      // out of GPU memory and gets dropped — every image already painted
      // then renders solid black with no error (flutter/flutter#158093,
      // #160199, #178524). HttpGet actually decodes at the requested size.
      imageRenderMethodForWeb:
          kIsWeb ? ImageRenderMethodForWeb.HttpGet : ImageRenderMethodForWeb.HtmlImage,
      fadeInDuration: Duration.zero,
      fadeOutDuration: Duration.zero,
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
