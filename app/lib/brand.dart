import 'package:flutter/material.dart';

import 'l10n.dart';
import 'theme.dart';

/// Spoken form of the iBuild line. The site says
/// «Доверие, заложенное в каждый квадратный метр».
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 40, this.onDark = false});

  final double size;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.18),
      child: Image.asset(
        onDark
            ? 'assets/brand/ibuild-logo-dark.png'
            : 'assets/brand/ibuild-logo.jpg',
        width: size,
        height: size,
        fit: BoxFit.cover,
        semanticLabel: 'iBuild',
      ),
    );
  }
}

class BrandLockup extends StatelessWidget {
  const BrandLockup({
    super.key,
    this.size = 40,
    this.onDark = false,
    this.showTagline = false,
  });

  final double size;
  final bool onDark;
  final bool showTagline;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final ink = onDark ? colors.onHeroSurface : colors.ink;
    final title = size >= 56
        ? Theme.of(context).textTheme.headlineMedium
        : Theme.of(context).textTheme.titleLarge;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        BrandMark(size: size, onDark: onDark),
        SizedBox(width: size < 36 ? AppSpacing.sm : AppSpacing.md),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'iBuild',
                style: title?.copyWith(color: ink, fontWeight: FontWeight.w700),
              ),
              if (showTagline) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  LocaleScope.copy(context).tagline,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: ink),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
