import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/locale_controller.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_theme_ext.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_chip.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/pressable_scale.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../data/ai_models.dart';
import '../../providers/ai_search_providers.dart';
import '../ai_search_results_sheet.dart';
import 'ai_mark_badge.dart';
import 'ai_search_labels.dart';
import 'ai_search_result_card.dart';
import 'typing_dots.dart';

/// Cross-fade between two consecutive status-line texts — long enough to read
/// as a swap, short enough that it never lags behind the step pacing.
const Duration _statusSwap = Duration(milliseconds: 180);

/// Renders the AI smart-search status line while a request is in flight, then
/// the constraint chip row + ranked results once it lands — or the "did you
/// mean" card when the server understood nothing (`blocked: true`), or a calm
/// inline message on any error (501/429/503/network, per the plan: "treat as a
/// normal error state, don't crash"). Idle (no search yet) renders nothing so
/// the normal discovery content shows through unchanged.
///
/// Every phase lays out as a single [Column] of explicitly spaced sections and
/// nothing is positioned or offset by an animation, so no two elements can
/// ever overlap regardless of where the reveal has got to.
///
/// [showResultCards] is disabled on the map tab: the pins + "Recommend for
/// you" list already reflect the AI-parsed constraints (both read from the
/// same [discoveryFiltersProvider]), so stacking full result cards on top of
/// the map overlay would just duplicate content and overflow the small
/// search-controls panel. The status line, error state, clarification card and
/// removable constraint chips are still shown there so the search feels
/// shared, not duplicated, across tabs.
class AiSearchPanel extends ConsumerWidget {
  const AiSearchPanel({super.key, this.showResultCards = true});

  final bool showResultCards;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(aiSearchProvider);
    if (state.phase == AiSearchPhase.idle) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg),
      child: switch (state.phase) {
        AiSearchPhase.thinking => _StatusLine(state: state),
        AiSearchPhase.error => _SearchErrorState(error: state.error),
        AiSearchPhase.needsClarification => _ClarificationCard(state: state),
        AiSearchPhase.success => _SearchResultsSection(
          state: state,
          showResultCards: showResultCards,
        ),
        AiSearchPhase.idle => const SizedBox.shrink(),
      },
    );
  }
}

/// One status row that updates in place — the AI mark, the *current* step's
/// text swapped through an [AnimatedSwitcher], typing dots, and a thin
/// determinate bar for how far through the traversal log the reveal is. The
/// row never grows: the text sits in a fixed-height box, so the card holds
/// still while the search runs.
class _StatusLine extends StatelessWidget {
  const _StatusLine({required this.state});

  final AiSearchState state;

  static const double _textHeight = 22;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    final step = state.currentStep;
    final label = step == null
        ? l10n.aiSearchStatusStarting
        : aiSearchStepLabel(l10n, state.query, step);

    return AppCard(
      color: colors.surfaceAlt,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const AiMarkBadge(compact: true),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: SizedBox(
                  height: _textHeight,
                  child: AnimatedSwitcher(
                    duration: _statusSwap,
                    layoutBuilder: (current, previous) => Stack(
                      alignment: AlignmentDirectional.centerStart,
                      children: [...previous, ?current],
                    ),
                    child: Text(
                      label,
                      key: ValueKey(label),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colors.inkMuted,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              const TypingDots(),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _RevealProgressBar(
            // Never fully empty: a hairline of accent reads as "started".
            progress: state.allSteps.isEmpty
                ? 0.06
                : state.revealProgress.clamp(0.06, 1.0),
          ),
        ],
      ),
    );
  }
}

class _RevealProgressBar extends StatelessWidget {
  const _RevealProgressBar({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadii.pill),
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: progress),
        duration: AppDurations.medium,
        curve: AppDurations.enter,
        builder: (context, value, _) => LinearProgressIndicator(
          value: value,
          minHeight: 3,
          backgroundColor: colors.outline.withValues(alpha: 0.35),
          color: colors.accent,
        ),
      ),
    );
  }
}

class _SearchErrorState extends StatelessWidget {
  const _SearchErrorState({required this.error});

  final AiException? error;

  String _formatResetAt(DateTime resetAt) =>
      DateFormat('d MMM, HH:mm', Intl.defaultLocale).format(resetAt.toLocal());

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final err = error;
    final resetAt = err?.quota?.resetAt;

    final (icon, title, subtitle) = switch (err?.code) {
      'RATE_LIMITED' => (
        Icons.hourglass_bottom,
        l10n.aiSearchRateLimitedTitle,
        resetAt == null
            ? l10n.aiSearchGenericErrorBody
            : l10n.aiSearchRateLimitedBody(_formatResetAt(resetAt)),
      ),
      'NOT_IMPLEMENTED' || 'AI_UNAVAILABLE' => (
        Icons.travel_explore,
        l10n.aiSearchUnavailableTitle,
        l10n.aiSearchUnavailableBody,
      ),
      'DEMO_READ_ONLY' => (
        Icons.visibility_outlined,
        l10n.aiSearchUnavailableTitle,
        l10n.demoWriteBlocked,
      ),
      _ => (
        Icons.search_off,
        l10n.aiSearchGenericErrorTitle,
        l10n.aiSearchGenericErrorBody,
      ),
    };

    return EmptyState(compact: true, icon: icon, title: title, subtitle: subtitle);
  }
}

/// The `blocked: true` answer: the server understood none of the query, so it
/// never traversed the catalogue. There is deliberately no result section, no
/// match count and no empty cards here — only what was not understood and the
/// closest phrasings to try instead.
class _ClarificationCard extends StatelessWidget {
  const _ClarificationCard({required this.state});

  final AiSearchState state;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    final terms = state.unknownTerms.isEmpty
        ? [state.query]
        : state.unknownTerms;
    final quoted = terms.map(l10n.aiSearchQuotedTerm).join(', ');
    final suggestions = state.suggestions;

    return AppCard(
      color: colors.surfaceAlt,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const AiMarkBadge(compact: true),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  l10n.aiSearchClarifyTitle,
                  style: textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.aiSearchClarifyBody(quoted),
            style: textTheme.bodyMedium?.copyWith(color: colors.inkMuted),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (suggestions.isNotEmpty)
            _SuggestionChipRow(suggestions: suggestions)
          else ...[
            Text(
              l10n.aiSearchClarifyExamplesHint,
              style: textTheme.labelSmall?.copyWith(color: colors.inkMuted),
            ),
            const SizedBox(height: AppSpacing.sm),
            const _ExampleChipRow(),
          ],
        ],
      ),
    );
  }
}

/// "Вы имели в виду «...»?" chips. Tapping one submits that suggestion's full
/// [AiSearchSuggestion.query] — an explicit user action, so it searches.
class _SuggestionChipRow extends ConsumerWidget {
  const _SuggestionChipRow({required this.suggestions});

  final List<AiSearchSuggestion> suggestions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final suggestion in suggestions)
          AppChip(
            label: l10n.aiSearchDidYouMean(suggestion.suggestion),
            onTap: () => _runSearch(ref, suggestion.query),
          ),
      ],
    );
  }
}

class _ExampleChipRow extends ConsumerWidget {
  const _ExampleChipRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final examples = [
      l10n.aiSearchExample1,
      l10n.aiSearchExample2,
      l10n.aiSearchExample3,
    ];
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final example in examples)
          AppChip(label: example, onTap: () => _runSearch(ref, example)),
      ],
    );
  }
}

class _ConstraintChipRow extends ConsumerWidget {
  const _ConstraintChipRow({required this.chips});

  final List<AiConstraintChipData> chips;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final chip in chips)
          AppChip(
            label: chip.label,
            selected: true,
            icon: Icons.close,
            onTap: () => _removeConstraints(ref, chip.removeKeys),
          ),
      ],
    );
  }
}

class _SearchResultsSection extends ConsumerWidget {
  const _SearchResultsSection({required this.state, this.showResultCards = true});

  final AiSearchState state;
  final bool showResultCards;

  /// How many result cards render inline in the discovery scroll — the rest
  /// live in the full-screen sheet behind the "show all" affordance.
  static const int _maxInlineResults = 5;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    final chips = buildAiConstraintChips(context, state.constraints);
    final results = state.results;
    final inlineResults = results.length > _maxInlineResults
        ? results.sublist(0, _maxInlineResults)
        : results;

    final sections = <Widget>[
      if (chips.isNotEmpty) _ConstraintChipRow(chips: chips),
      // Non-blocking hints: the search did run, some tokens were just unclear.
      if (state.suggestions.isNotEmpty)
        _SuggestionChipRow(suggestions: state.suggestions),
      Text(
        // Always the TOTAL match count, even though only 5 cards render.
        l10n.aiSearchSummary(results.length),
        style: textTheme.labelLarge?.copyWith(color: colors.inkMuted),
      ),
      if (showResultCards && results.isEmpty) _EmptyResults(state: state),
      if (showResultCards)
        for (final result in inlineResults) AiSearchResultCard(result: result),
      if (showResultCards && results.length > _maxInlineResults)
        _ShowAllResultsButton(total: results.length),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < sections.length; i++)
          Padding(
            padding: EdgeInsets.only(top: i == 0 ? 0 : AppSpacing.md),
            child: sections[i],
          ),
      ],
    );
  }
}

/// Full-width "Показать все N" affordance under the 5th inline card — the
/// same pill vocabulary as the chips around it (surface fill, outline,
/// accent label) so it reads as part of the AI surface, not a page button.
/// Opens the full-screen scrollable result sheet.
class _ShowAllResultsButton extends StatelessWidget {
  const _ShowAllResultsButton({required this.total});

  final int total;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);

    return PressableScale(
      child: Material(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadii.pill),
          onTap: () => showAiSearchResultsSheet(context),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadii.pill),
              border: Border.all(color: colors.outline),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.aiSearchShowAll(total),
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: colors.accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Icon(Icons.expand_more_rounded, size: 18, color: colors.accent),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Nothing matched, but the query itself was understood — offer to drop the
/// one condition most likely to be responsible instead of a dead end.
class _EmptyResults extends ConsumerWidget {
  const _EmptyResults({required this.state});

  final AiSearchState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final relax = _relaxCandidate(context, state.constraints);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EmptyState(
          compact: true,
          icon: Icons.search_off,
          title: l10n.aiSearchResultsEmptyTitle,
          subtitle: l10n.aiSearchResultsEmptyBody,
        ),
        if (relax != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Align(
            child: AppChip(
              label: l10n.aiSearchRelaxConstraint(relax.label),
              icon: Icons.tune,
              onTap: () => _removeConstraints(ref, relax.removeKeys),
            ),
          ),
        ],
      ],
    );
  }
}

void _runSearch(WidgetRef ref, String query) {
  final language = ref.read(localeControllerProvider).languageCode;
  ref.read(aiSearchProvider.notifier).search(query, userLanguage: language);
}

/// Re-runs with the remaining constraints as a structured override. Only ever
/// reached from a chip tap — an explicit user action, unlike typing.
void _removeConstraints(WidgetRef ref, Set<String> keys) {
  final language = ref.read(localeControllerProvider).languageCode;
  ref
      .read(aiSearchProvider.notifier)
      .removeConstraintKeys(keys, userLanguage: language);
}

/// The single condition most likely to be why nothing matched: the budget cap
/// first, then the district, then the area/room floor. Returns `null` when the
/// parsed constraints hold nothing obvious to relax.
AiConstraintChipData? _relaxCandidate(
  BuildContext context,
  AiSearchConstraints constraints,
) {
  final district = constraints.district;
  final relaxable = <String>{
    if (constraints.priceMax != null) 'priceMax',
    if (district != null && district.isNotEmpty) 'district',
    if (constraints.areaMin != null) 'areaMin',
    if (constraints.rooms?.isNotEmpty ?? false) 'rooms',
  };
  if (relaxable.isEmpty) return null;

  final chips = buildAiConstraintChips(context, constraints);
  for (final key in const ['priceMax', 'district', 'areaMin', 'rooms']) {
    if (!relaxable.contains(key)) continue;
    for (final chip in chips) {
      if (chip.removeKeys.contains(key)) return chip;
    }
  }
  return null;
}
