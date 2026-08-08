import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';

import '../../l10n/gen/app_localizations.dart';
import '../theme/app_dimens.dart';
import '../theme/app_theme_ext.dart';

/// Renders an [AsyncValue] with a consistent loading spinner / retry-on-error
/// state, so every screen backed by a `FutureProvider`/`AsyncNotifier`
/// behaves the same way while talking to the live API.
class AsyncValueView<T> extends StatelessWidget {
  const AsyncValueView({
    super.key,
    required this.value,
    required this.builder,
    this.onRetry,
    this.minHeight = 280,
  });

  final AsyncValue<T> value;
  final Widget Function(BuildContext context, T data) builder;
  final VoidCallback? onRetry;

  /// Minimum height reserved for the loading/error placeholder so layouts
  /// don't jump around while data streams in.
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    final child = value.when(
      data: (data) => builder(context, data),
      loading: () =>
          SizedBox(height: minHeight, child: const _SkeletonLoader()),
      error: (error, stack) =>
          _ErrorView(onRetry: onRetry, minHeight: minHeight),
    );

    // Cross-fade async states; stack children top-aligned to avoid a blank
    // gap while AnimatedSwitcher measures the incoming child.
    return AnimatedSwitcher(
      duration: AppDurations.medium,
      switchInCurve: AppDurations.enter,
      switchOutCurve: AppDurations.exit,
      layoutBuilder: (currentChild, previousChildren) => Stack(
        alignment: Alignment.topCenter,
        children: [...previousChildren, ?currentChild],
      ),
      child: KeyedSubtree(
        key: ValueKey(value.when(
          data: (_) => 'data',
          loading: () => 'loading',
          error: (_, _) => 'error',
        )),
        child: child,
      ),
    );
  }
}

/// Placeholder cards shown while data streams in. On Flutter web the
/// continuous shimmer animation burns frames, so skeletons stay static there.
class _SkeletonLoader extends StatelessWidget {
  const _SkeletonLoader();

  static const _cardCount = 3;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = AppSpacing.lg;
        const gaps = gap * (_cardCount - 1);
        final cardHeight = ((constraints.maxHeight - gaps) / _cardCount).clamp(
          64.0,
          96.0,
        );

        final column = Column(
          children: [
            for (var i = 0; i < _cardCount; i++)
              Padding(
                padding: EdgeInsets.only(
                  bottom: i < _cardCount - 1 ? gap : 0,
                ),
                child: Container(
                  height: cardHeight,
                  decoration: BoxDecoration(
                    color: colors.surfaceAlt,
                    borderRadius: BorderRadius.circular(AppRadii.card),
                  ),
                ),
              ),
          ],
        );

        if (kIsWeb) return column;

        return Shimmer.fromColors(
          baseColor: colors.surfaceAlt,
          highlightColor: colors.surface,
          child: column,
        );
      },
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({this.onRetry, required this.minHeight});

  final VoidCallback? onRetry;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    return SizedBox(
      height: minHeight,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_outlined, size: 32, color: colors.inkMuted),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.somethingWentWrong,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: colors.inkMuted),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.sm),
              TextButton(onPressed: onRetry, child: Text(l10n.retry)),
            ],
          ],
        ),
      ),
    );
  }
}
