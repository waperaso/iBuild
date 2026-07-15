import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:ibuild_core/ibuild_core.dart';

import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_theme_ext.dart';
import '../../../../core/utils/floor_plan_assets.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../l10n/gen/app_localizations.dart';

/// A small square thumbnail for a [MediaItem], with a badge for non-photo
/// media (floor plan / render / tour) so "look inside" browsing can tell
/// them apart at a glance.
///
/// When [item] is a floor plan and the caller can supply the unit's
/// [rooms]/[layout], a bundled local SVG diagram is rendered instead of the
/// (placeholder) network image — callers that don't have that context keep
/// falling back to [AppNetworkImage] unchanged.
class MediaThumbnail extends StatelessWidget {
  const MediaThumbnail({
    super.key,
    required this.item,
    this.size = 84,
    this.rooms,
    this.layout,
  });

  final MediaItem item;
  final double size;
  final int? rooms;
  final String? layout;

  @override
  Widget build(BuildContext context) {
    final useLocalFloorPlan =
        item.type == MediaType.floorplan && (rooms != null || layout != null);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (useLocalFloorPlan)
            ColoredBox(
              color: context.colors.surfaceAlt,
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: SvgPicture.asset(
                  floorPlanAssetFor(rooms: rooms, layout: layout) ??
                      fallbackFloorPlanAsset,
                  width: size,
                  height: size,
                  fit: BoxFit.contain,
                ),
              ),
            )
          else
            AppNetworkImage(url: item.url, width: size, height: size),
          if (item.type != MediaType.photo)
            Positioned(
              bottom: 4,
              right: 4,
              child: _MediaTypeBadge(type: item.type),
            ),
        ],
      ),
    );
  }
}

class _MediaTypeBadge extends StatelessWidget {
  const _MediaTypeBadge({required this.type});

  final MediaType type;

  @override
  Widget build(BuildContext context) {
    final icon = switch (type) {
      MediaType.floorplan => Icons.architecture_outlined,
      MediaType.render => Icons.view_in_ar_outlined,
      MediaType.tour => Icons.threed_rotation_outlined,
      MediaType.photo => Icons.photo_outlined,
    };
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(icon, size: 12, color: Colors.white),
    );
  }
}

/// Opens a full-screen, swipeable viewer over [media] — used for both a
/// project's photo gallery and a unit's photos/floor plan so buyers can
/// "look inside" before booking a viewing.
Future<void> showMediaGalleryViewer(
  BuildContext context, {
  required List<MediaItem> media,
  int initialIndex = 0,
}) {
  if (media.isEmpty) return Future.value();
  return Navigator.of(context).push(
    PageRouteBuilder<void>(
      opaque: false,
      barrierColor: Colors.black,
      pageBuilder: (context, animation, secondaryAnimation) => FadeTransition(
        opacity: animation,
        child: _GalleryScreen(media: media, initialIndex: initialIndex),
      ),
    ),
  );
}

class _GalleryScreen extends StatefulWidget {
  const _GalleryScreen({required this.media, required this.initialIndex});

  final List<MediaItem> media;
  final int initialIndex;

  @override
  State<_GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<_GalleryScreen> {
  late final PageController _controller = PageController(
    initialPage: widget.initialIndex,
  );
  late int _index = widget.initialIndex;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                Expanded(
                  child: Text(
                    l10n.galleryPhotoOfTotal(_index + 1, widget.media.length),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: widget.media.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) => InteractiveViewer(
                  child: Center(
                    child: AppNetworkImage(
                      url: widget.media[i].url,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 72,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                scrollDirection: Axis.horizontal,
                itemCount: widget.media.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(width: AppSpacing.sm),
                itemBuilder: (context, i) => GestureDetector(
                  onTap: () => _controller.animateToPage(
                    i,
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOut,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadii.sm),
                      border: Border.all(
                        color: i == _index
                            ? context.colors.accent
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadii.sm - 2),
                      child: MediaThumbnail(item: widget.media[i], size: 56),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
