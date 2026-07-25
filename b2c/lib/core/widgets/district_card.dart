import 'package:flutter/material.dart';

import '../theme/app_dimens.dart';
import '../theme/app_theme_ext.dart';
import 'app_network_image.dart';
import 'pressable_scale.dart';

/// Small image-backed card for the "Popular districts" rail: a thumbnail
/// from one of that district's listings, a gradient legibility overlay, the
/// district name and a listing count.
class DistrictCard extends StatelessWidget {
  const DistrictCard({
    super.key,
    required this.name,
    required this.count,
    this.imageUrl,
    this.selected = false,
    this.onTap,
  });

  final String name;
  final String count;
  final String? imageUrl;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;

    return PressableScale(
      child: Material(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          child: Container(
            width: 152,
            height: 108,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadii.lg),
              border: selected
                  ? Border.all(color: colors.accent, width: 2)
                  : null,
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                AppNetworkImage(
                  url: imageUrl,
                  width: double.infinity,
                  height: double.infinity,
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    height: 56,
                    color: Colors.black.withValues(alpha: 0.55),
                  ),
                ),
                Positioned(
                  left: AppSpacing.sm + 2,
                  right: AppSpacing.sm + 2,
                  bottom: AppSpacing.sm,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.labelLarge?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        count,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.labelSmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
