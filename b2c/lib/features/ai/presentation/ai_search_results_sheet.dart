import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_theme_ext.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../data/ai_models.dart';
import '../providers/ai_search_providers.dart';
import 'widgets/ai_mark_badge.dart';
import 'widgets/ai_search_result_card.dart';

/// Opens the full AI search result list — the inline panel shows only the
/// first 5 cards, this sheet scrolls through all of them. Draggable bottom
/// sheet on mobile (same pattern as the floor-plans units sheet), constrained
/// dialog on desktop (same branching as `showAiChatSheet`).
Future<void> showAiSearchResultsSheet(BuildContext context) {
  if (context.isMobile) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadii.card),
        ),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, controller) =>
            AiSearchResultsSheet(scrollController: controller),
      ),
    );
  }

  return showDialog<void>(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: context.colors.background,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.xxl,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 720),
        child: const AiSearchResultsSheet(dialog: true),
      ),
    ),
  );
}

class AiSearchResultsSheet extends ConsumerStatefulWidget {
  const AiSearchResultsSheet({
    super.key,
    this.scrollController,
    this.dialog = false,
  });

  final ScrollController? scrollController;
  final bool dialog;

  @override
  ConsumerState<AiSearchResultsSheet> createState() =>
      _AiSearchResultsSheetState();
}

class _AiSearchResultsSheetState extends ConsumerState<AiSearchResultsSheet> {
  /// The last successful result set. If a new search resets the provider to
  /// thinking (or an error) while the sheet is open, the list it opened with
  /// stays on screen instead of flashing empty — the user closes it whenever.
  List<AiSearchResult> _results = const [];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);

    final state = ref.watch(aiSearchProvider);
    if (state.phase == AiSearchPhase.success && state.results.isNotEmpty) {
      _results = state.results;
    }
    final results = _results;

    return Padding(
      padding: EdgeInsets.all(widget.dialog ? AppSpacing.xl : AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!widget.dialog)
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
          Row(
            children: [
              const AiMarkBadge(compact: true),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.aiSearchAllResultsTitle,
                      style: textTheme.titleLarge,
                    ),
                    Text(
                      l10n.aiSearchSummary(results.length),
                      style: textTheme.labelMedium?.copyWith(
                        color: colors.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: ListView.separated(
              controller: widget.scrollController,
              itemCount: results.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) => AiSearchResultCard(
                result: results[index],
                onBeforeNavigate: () => Navigator.of(context).pop(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
