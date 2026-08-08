import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_theme_ext.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/async_value_view.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/pill_button.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../models/review.dart';
import '../../../reviews/data/reviews_repository.dart';
import '../../../reviews/providers/reviews_providers.dart';

/// Published reviews for one project, plus write-review entry.
class ReviewsTab extends ConsumerWidget {
  const ReviewsTab({super.key, required this.projectId});

  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final reviewsAsync = ref.watch(reviewsProvider(projectId));

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(reviewsProvider(projectId)),
      child: AsyncValueView(
        value: reviewsAsync,
        onRetry: () => ref.invalidate(reviewsProvider(projectId)),
        builder: (context, reviews) {
          return ListView(
            children: [
              Row(
                children: [
                  Expanded(child: _RatingSummary(reviews: reviews)),
                  PillButton(
                    label: l10n.writeReviewAction,
                    variant: PillButtonVariant.outline,
                    onPressed: () => _openWriteReview(context, ref),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              if (reviews.isEmpty)
                EmptyState(
                  compact: true,
                  icon: Icons.reviews_outlined,
                  title: l10n.noReviewsYet,
                  subtitle: l10n.reviewsEmptySubtitle,
                  actionLabel: l10n.writeReviewAction,
                  onAction: () => _openWriteReview(context, ref),
                )
              else
                for (final review in reviews) ...[
                  _ReviewCard(review: review, projectId: projectId),
                  const SizedBox(height: AppSpacing.md),
                ],
            ],
          );
        },
      ),
    );
  }

  Future<void> _openWriteReview(BuildContext context, WidgetRef ref) async {
    final submitted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _WriteReviewSheet(projectId: projectId),
    );
    if (submitted == true) {
      ref.invalidate(reviewsProvider(projectId));
    }
  }
}

class _RatingSummary extends StatelessWidget {
  const _RatingSummary({required this.reviews});

  final List<Review> reviews;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    final avg = reviews.isEmpty
        ? 0.0
        : reviews.map((r) => r.ratingOverall).reduce((a, b) => a + b) /
              reviews.length;
    return Row(
      children: [
        Icon(Icons.star, color: colors.warning, size: 22),
        const SizedBox(width: AppSpacing.sm),
        Text(avg.toStringAsFixed(1), style: textTheme.headlineSmall),
        const SizedBox(width: AppSpacing.sm),
        Text(
          l10n.reviewsCount(reviews.length),
          style: textTheme.bodyMedium?.copyWith(color: colors.inkMuted),
        ),
      ],
    );
  }
}

class _ReviewCard extends ConsumerWidget {
  const _ReviewCard({required this.review, required this.projectId});

  final Review review;
  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: colors.surfaceAlt,
                child: Icon(Icons.person, size: 16, color: colors.inkMuted),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(review.userName, style: textTheme.titleSmall),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  5,
                  (i) => Icon(
                    i < review.ratingOverall ? Icons.star : Icons.star_border,
                    size: 14,
                    color: colors.warning,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.flag_outlined,
                  size: 16,
                  color: colors.inkMuted,
                ),
                tooltip: l10n.flagReviewAction,
                onPressed: () => _flag(context, ref),
              ),
            ],
          ),
          if (review.createdAt != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              Formatters.date(review.createdAt!),
              style: textTheme.labelSmall?.copyWith(color: colors.inkMuted),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Text(review.body, style: textTheme.bodyMedium),
        ],
      ),
    );
  }

  Future<void> _flag(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    try {
      await ref.read(reviewsRepositoryProvider).flag(review.id);
      ref.invalidate(reviewsProvider(projectId));
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.reviewFlaggedSnackbar)));
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.somethingWentWrong)));
    }
  }
}

class _WriteReviewSheet extends ConsumerStatefulWidget {
  const _WriteReviewSheet({required this.projectId});

  final String projectId;

  @override
  ConsumerState<_WriteReviewSheet> createState() => _WriteReviewSheetState();
}

class _WriteReviewSheetState extends ConsumerState<_WriteReviewSheet> {
  int _rating = 5;
  final _body = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _body.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting || _body.text.trim().isEmpty) return;
    setState(() => _submitting = true);
    final l10n = AppLocalizations.of(context);
    try {
      await ref
          .read(reviewsRepositoryProvider)
          .submit(
            projectId: widget.projectId,
            body: _body.text.trim(),
            ratingOverall: _rating,
          );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.somethingWentWrong)));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.lg,
          AppSpacing.xl,
          AppSpacing.xl,
        ),
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadii.card),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                decoration: BoxDecoration(
                  color: colors.outline,
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                ),
              ),
            ),
            Text(l10n.writeReviewAction, style: textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                5,
                (i) => IconButton(
                  onPressed: () => setState(() => _rating = i + 1),
                  icon: Icon(
                    i < _rating ? Icons.star : Icons.star_border,
                    color: colors.warning,
                    size: 32,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _body,
              maxLines: 4,
              maxLength: 1000,
              inputFormatters: [LengthLimitingTextInputFormatter(1000)],
              decoration: InputDecoration(hintText: l10n.reviewBodyHint),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: AppSpacing.lg),
            PillButton(
              label: l10n.submitReviewAction,
              expand: true,
              loading: _submitting,
              onPressed: _body.text.trim().isEmpty ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}
