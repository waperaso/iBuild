import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/localization/status_labels.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_theme_ext.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/horizontal_scroll_rail.dart';
import '../../core/widgets/pill_button.dart';
import '../../core/widgets/stat_card.dart';
import '../../l10n/gen/app_localizations.dart';
import '../crm/crm_shared.dart';
import 'ai_crm_bot_sheet.dart';
import 'ai_crm_pills.dart';
import 'ai_crm_providers.dart';

/// Plain info card used whenever the AI CRM engine is not available yet
/// (501 while the server sibling ships it, or any transient error) — never
/// a raw error dump, per the "Beta notice" design convention.
class AiUnavailableCard extends StatelessWidget {
  const AiUnavailableCard({super.key, this.compact = false});
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    return AppCard(
      padding: EdgeInsets.all(compact ? AppSpacing.md : AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: colors.warning),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              l10n.aiCrmUnavailable,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

/// Metrics strip: lead volume vs plan cap, per-manager workload, response
/// SLA, and funnel/conversion, per the `GET /ai/crm/leads` `metrics` object.
class AiMetricsRail extends StatelessWidget {
  const AiMetricsRail({super.key, required this.metrics});
  final Map<String, dynamic> metrics;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;

    final leadVolume = metrics['leadVolume'] as Map? ?? const {};
    final byBand = metrics['byBand'] as Map? ?? const {};
    final perManager = (metrics['perManager'] as List? ?? const []).cast<Map>();
    final responseSla = metrics['responseSla'] as Map? ?? const {};
    final funnel = metrics['funnel'] as Map? ?? const {};
    final conversion = (metrics['conversion'] as List? ?? const []).cast<Map>();

    final avgWorkload = perManager.isEmpty
        ? 0
        : (perManager
                      .map((m) => (m['openLeads'] as num?)?.toInt() ?? 0)
                      .fold<int>(0, (a, b) => a + b) /
                  perManager.length)
              .round();
    final avgConversion = conversion.isEmpty
        ? null
        : conversion
                  .map((c) => (c['rate'] as num?)?.toDouble() ?? 0)
                  .fold<double>(0, (a, b) => a + b) /
              conversion.length;

    final items = <(IconData, String, String, Color?)>[
      (
        Icons.trending_up,
        '${leadVolume['today'] ?? 0}/${leadVolume['planCap'] ?? '—'}',
        l10n.aiMetricLeadVolume,
        null,
      ),
      (
        Icons.local_fire_department_outlined,
        '${byBand['hot'] ?? 0}',
        l10n.aiMetricHotLeads,
        colors.danger,
      ),
      (Icons.groups_outlined, '$avgWorkload', l10n.aiMetricPerManagerAvg, null),
      (
        Icons.timer_outlined,
        responseSla['medianMinutes'] != null
            ? '${(responseSla['medianMinutes'] as num).round()}'
            : '—',
        l10n.aiMetricResponseSla,
        null,
      ),
      (
        Icons.report_gmailerrorred_outlined,
        '${responseSla['breachedCount'] ?? 0}',
        l10n.aiMetricSlaBreaches,
        colors.warning,
      ),
      (
        Icons.emoji_events_outlined,
        '${funnel['won'] ?? 0}',
        l10n.aiMetricFunnelWon,
        colors.success,
      ),
      (
        Icons.donut_small_outlined,
        avgConversion == null ? '—' : '${(avgConversion * 100).round()}%',
        l10n.aiMetricConversion,
        null,
      ),
    ];

    return HorizontalScrollRail(
      height: 132,
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return StatCard(
          icon: item.$1,
          value: item.$2,
          label: item.$3,
          tint: item.$4,
        );
      },
    );
  }
}

class _AiLeadCard extends ConsumerWidget {
  const _AiLeadCard({required this.lead, required this.statuses});

  final Map<String, dynamic> lead;
  final List<String> statuses;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final band = lead['aiBand']?.toString();
    final reasons = (lead['aiReasons'] as List? ?? const [])
        .map((r) => r.toString())
        .take(3);

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      onTap: () =>
          showDialog<CrmLeadEditResult>(
            context: context,
            builder: (_) => CrmLeadEditorDialog(lead: lead, statuses: statuses),
          ).then((result) async {
            if (result == null) return;
            await applyCrmLeadEdit(
              ref,
              leadId: lead['id'] as String,
              result: result,
            );
            ref.invalidate(aiCrmLeadsProvider);
          }),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  lead['projectName']?.toString() ?? '',
                  style: textTheme.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (band != null) AiBandPill(band: band),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            lead['contactPhone']?.toString() ?? '',
            style: textTheme.bodySmall?.copyWith(color: colors.inkMuted),
          ),
          if (reasons.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [for (final code in reasons) AiReasonChip(code: code)],
            ),
          ],
        ],
      ),
    );
  }
}

/// Ranked "требуют внимания сегодня" hot-leads panel, shared across the
/// platform AI CRM screen and the condensed embeds on /residence and a
/// project's own detail screen. [condensed] trims the list and tightens the
/// section chrome (title/subtitle) so it reads as one section among others.
/// [showHeader] drops the title row entirely — used when an enclosing
/// section (e.g. [AiInsightsSection]) already names the block.
///
/// With a header the panel draws its own bordered card so the title, the AI
/// badge, the "open assistant" button and the leads underneath share one set
/// of edges; loose rows on the page made the button look stranded at the far
/// right of an empty band.
class HotLeadsPanel extends ConsumerWidget {
  const HotLeadsPanel({
    super.key,
    required this.scope,
    this.condensed = false,
    this.showMetrics = true,
    this.showHeader = true,
    this.onOpenBot,
  });

  final AiCrmScope scope;
  final bool condensed;
  final bool showMetrics;
  final bool showHeader;
  final VoidCallback? onOpenBot;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final result = ref.watch(aiCrmLeadsProvider(scope));

    return result.when(
      data: (data) {
        if (!data.available) return AiUnavailableCard(compact: condensed);
        final leads = condensed ? data.leads.take(3).toList() : data.leads;
        final metrics = data.metrics;

        final content = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showMetrics && metrics != null) ...[
              AiMetricsRail(metrics: metrics),
              const SizedBox(height: AppSpacing.lg),
            ],
            if (leads.isEmpty)
              EmptyState(
                compact: true,
                icon: Icons.inbox_outlined,
                title: l10n.aiCrmEmpty,
                // What the panel will hold once leads arrive — worth saying
                // here, unless the (non-condensed) header already says it.
                subtitle: showHeader && !condensed
                    ? null
                    : l10n.aiCrmPanelSubtitle,
              )
            else
              for (var i = 0; i < leads.length; i++) ...[
                if (i > 0) const SizedBox(height: AppSpacing.md),
                _AiLeadCard(lead: leads[i], statuses: kAiCrmLeadStatuses),
              ],
          ],
        );

        if (!showHeader) return content;
        return AppCard(
          color: colors.surfaceAlt.withValues(alpha: 0.5),
          border: true,
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _PanelHeader(condensed: condensed, onOpenBot: onOpenBot),
              const SizedBox(height: AppSpacing.lg),
              content,
            ],
          ),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => AiUnavailableCard(compact: condensed),
    );
  }
}

/// Title + AI badge on one side, the assistant button on the other, both
/// vertically centered. Stacks when the panel is too narrow to hold the ru/uz
/// title and the button on one line.
class _PanelHeader extends StatelessWidget {
  const _PanelHeader({required this.condensed, required this.onOpenBot});

  final bool condensed;
  final VoidCallback? onOpenBot;

  static const double _stackBelow = 420;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    final title = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                l10n.aiCrmPanelTitle,
                style: condensed
                    ? textTheme.titleMedium
                    : textTheme.headlineMedium,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            const AiMarkBadge(),
          ],
        ),
        if (!condensed) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.aiCrmPanelSubtitle,
            style: textTheme.bodyMedium?.copyWith(
              color: context.colors.inkMuted,
            ),
          ),
        ],
      ],
    );

    if (onOpenBot == null) return title;

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < _stackBelow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              title,
              const SizedBox(height: AppSpacing.md),
              PillButton(
                label: l10n.aiCrmOpenBot,
                icon: Icons.assistant_outlined,
                variant: PillButtonVariant.outline,
                expand: true,
                onPressed: onOpenBot,
              ),
            ],
          );
        }
        return Row(
          crossAxisAlignment: condensed
              ? CrossAxisAlignment.center
              : CrossAxisAlignment.start,
          children: [
            Expanded(child: title),
            const SizedBox(width: AppSpacing.md),
            PillButton(
              label: l10n.aiCrmOpenBot,
              icon: Icons.assistant_outlined,
              variant: PillButtonVariant.outline,
              onPressed: onOpenBot,
            ),
          ],
        );
      },
    );
  }
}

/// `aiBand` filter values used by [AiBandFilterChips]; `all` means no filter.
const kAiBandFilters = ['all', 'hot', 'warm', 'cold'];

/// Collapsible AI block that opens a lead workspace — the metrics rail and
/// the ranked hot-leads list, folded away by default on narrow layouts so it
/// never buries the kanban board underneath it.
class AiInsightsSection extends StatefulWidget {
  const AiInsightsSection({
    super.key,
    required this.scope,
    required this.initiallyExpanded,
    this.showMetrics = true,
  });

  final AiCrmScope scope;
  final bool initiallyExpanded;
  final bool showMetrics;

  @override
  State<AiInsightsSection> createState() => _AiInsightsSectionState();
}

class _AiInsightsSectionState extends State<AiInsightsSection> {
  late bool _expanded = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);

    return AppCard(
      color: colors.surfaceAlt.withValues(alpha: 0.5),
      border: true,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(AppRadii.sm),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      l10n.crmAiInsightsTitle,
                      style: textTheme.titleMedium,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  const AiMarkBadge(),
                  const Spacer(),
                  Tooltip(
                    message: _expanded
                        ? l10n.crmAiInsightsCollapse
                        : l10n.crmAiInsightsExpand,
                    child: AnimatedRotation(
                      turns: _expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      child: Icon(
                        Icons.arrow_drop_down,
                        size: 24,
                        color: colors.inkMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            const SizedBox(height: AppSpacing.md),
            HotLeadsPanel(
              scope: widget.scope,
              condensed: true,
              showHeader: false,
              showMetrics: widget.showMetrics,
            ),
          ],
        ],
      ),
    );
  }
}

/// hot/warm/cold filter over a lead's computed `aiBand`, shown next to the
/// classic owner and status chips of a lead workspace.
class AiBandFilterChips extends StatelessWidget {
  const AiBandFilterChips({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          l10n.crmBandFilterLabel,
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(color: colors.inkMuted),
        ),
        for (final band in kAiBandFilters)
          ChoiceChip(
            label: Text(aiBandFilterLabel(l10n, band)),
            selected: selected == band,
            onSelected: (_) => onChanged(band),
          ),
      ],
    );
  }
}

/// Opens the guided bot sheet (bottom sheet on mobile, dialog on desktop).
Future<void> openAiCrmBot(BuildContext context, {String? projectId}) {
  return showAiCrmBotSheet(context, projectId: projectId);
}
