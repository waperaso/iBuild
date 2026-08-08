import 'package:flutter/material.dart';

import '../theme/app_dimens.dart';

/// Column count from available width — shared by box and sliver grids.
int responsiveCardColumns(double width) {
  if (width < AppBreakpoints.mobile) return 1;
  if (width < 900) return 2;
  if (width < 1200) return 3;
  return 4;
}

/// Intrinsic-height wrapping card grid (short lists). Prefer sliver variant in scroll views.
class ResponsiveCardGrid extends StatelessWidget {
  const ResponsiveCardGrid({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.spacing = AppSpacing.lg,
  });

  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    if (itemCount == 0) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = responsiveCardColumns(width);
        final cardWidth = columns == 1
            ? width
            : (width - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (var i = 0; i < itemCount; i++)
              SizedBox(width: cardWidth, child: itemBuilder(context, i)),
          ],
        );
      },
    );
  }
}

/// Lazy row-based grid for [CustomScrollView]. Only visible rows are built,
/// while each row still sizes to the tallest card (intrinsic height) so
/// variable card content never overflows a fixed [SliverGrid] extent.
class ResponsiveCardSliverGrid extends StatelessWidget {
  const ResponsiveCardSliverGrid({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.spacing = AppSpacing.lg,
  });

  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    if (itemCount == 0) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.crossAxisExtent;
        final columns = responsiveCardColumns(width);
        final rowCount = (itemCount + columns - 1) ~/ columns;

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, rowIndex) {
              final start = rowIndex * columns;
              final end = (start + columns).clamp(0, itemCount);
              final children = <Widget>[
                for (var i = start; i < end; i++)
                  Expanded(child: itemBuilder(context, i)),
                // Pad incomplete last rows so cards keep equal width.
                for (var i = end; i < start + columns; i++)
                  const Expanded(child: SizedBox.shrink()),
              ];

              return Padding(
                padding: EdgeInsets.only(
                  bottom: rowIndex < rowCount - 1 ? spacing : 0,
                ),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var c = 0; c < children.length; c++) ...[
                        if (c > 0) SizedBox(width: spacing),
                        children[c],
                      ],
                    ],
                  ),
                ),
              );
            },
            childCount: rowCount,
            addAutomaticKeepAlives: false,
            addRepaintBoundaries: true,
          ),
        );
      },
    );
  }
}
