import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/localization/locale_controller.dart';
import '../../core/localization/status_labels.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_theme_ext.dart';
import '../../core/utils/redacted_phone.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/pill_button.dart';
import '../../l10n/gen/app_localizations.dart';
import '../admin/admin_api.dart';
import '../auth/auth.dart';
import '../crm/crm_shared.dart';
import 'ai_crm_pills.dart';
import 'ai_crm_providers.dart';

/// Root node id opened when the sheet first appears.
const _kRootNode = 'root';

/// Nodes whose whole answer *is* their option list: `cards` is empty there by
/// design, so the "nothing matched" state must never appear on them.
const _kMenuNodes = {'root', 'analytics', 'projectMenu'};

/// Outer bounds of the desktop dialog. The sheet used to be a hard 520x640
/// box, which left a mostly empty shell on a 1440x900 window and overflowed a
/// small one; it is sized from the window now and these only cap it.
const Size _kDialogMaxSize = Size(640, 720);
const Size _kDialogMinSize = Size(320, 420);

/// Window left visible around the dialog on each side.
const double _kDialogInset = 48;

/// Share of the sheet the pinned options footer may take before it scrolls
/// internally — a long menu must never squeeze the answer above it. On a menu
/// node the options *are* the answer, so they get most of the sheet instead.
const double _kFooterHeightShare = 0.42;
const double _kMenuFooterHeightShare = 0.66;

/// Width two option buttons / metric cards need before sitting side by side;
/// below it the ru/uz labels wrap into unreadable slivers.
const double _kTwoColumnMinWidth = 440;

/// Opens the guided (not free-text) b2b CRM assistant — bottom sheet on
/// mobile, dialog on desktop, matching the modal convention used elsewhere in
/// b2b (see `_openUnitSheet` in project_detail_admin.dart for the mobile
/// sheet shape and `CrmLeadEditorDialog` for the desktop dialog shape).
///
/// [projectId] scopes the very first request when the sheet is opened from a
/// project's own screen — e.g. straight into that project's `projectMenu`
/// instead of the platform-wide root, so a developer isn't asked "which ЖК".
Future<void> showAiCrmBotSheet(BuildContext context, {String? projectId}) {
  final surface = context.colors.surface;
  if (context.isMobile) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadii.card),
        ),
      ),
      builder: (_) => _AiCrmBotSheet(projectId: projectId, dialog: false),
    );
  }
  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      final window = MediaQuery.sizeOf(dialogContext);
      return Dialog(
        backgroundColor: surface,
        insetPadding: const EdgeInsets.all(AppSpacing.xl),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.card),
        ),
        child: SizedBox(
          width: _dialogSide(
            window.width,
            _kDialogMinSize.width,
            _kDialogMaxSize.width,
          ),
          height: _dialogSide(
            window.height,
            _kDialogMinSize.height,
            _kDialogMaxSize.height,
          ),
          child: _AiCrmBotSheet(projectId: projectId, dialog: true),
        ),
      );
    },
  );
}

/// Largest side within [max] that still leaves [_kDialogInset] of window on
/// both sides, never smaller than [min] (a tiny window scrolls the body
/// instead of collapsing the whole sheet).
double _dialogSide(double window, double min, double max) =>
    math.max(min, math.min(max, window - _kDialogInset * 2));

class _BotStep {
  const _BotStep({
    required this.node,
    required this.params,
    required this.response,
  });
  final String node;
  final Map<String, dynamic> params;
  final Map<String, dynamic> response;
}

class _AiCrmBotSheet extends ConsumerStatefulWidget {
  const _AiCrmBotSheet({required this.projectId, required this.dialog});

  final String? projectId;
  final bool dialog;

  @override
  ConsumerState<_AiCrmBotSheet> createState() => _AiCrmBotSheetState();
}

class _AiCrmBotSheetState extends ConsumerState<_AiCrmBotSheet> {
  final List<_BotStep> _stack = [];
  bool _loading = true;
  bool _unavailable = false;

  /// Node/params of the request in flight — a failed step never reaches
  /// [_stack], so this is what "try again" has to replay.
  late String _pendingNode;
  late Map<String, dynamic> _pendingParams;

  @override
  void initState() {
    super.initState();
    final initialNode = widget.projectId == null ? _kRootNode : 'projectMenu';
    final initialParams = widget.projectId == null
        ? const <String, dynamic>{}
        : {'projectId': widget.projectId};
    _query(initialNode, initialParams);
  }

  String get _language => ref.read(localeControllerProvider).languageCode;

  Future<void> _query(String node, Map<String, dynamic> params) async {
    setState(() {
      _pendingNode = node;
      _pendingParams = params;
      _loading = true;
      _unavailable = false;
    });
    try {
      final response = await ref
          .read(adminApiProvider)
          .aiCrmQuery(node: node, params: params, userLanguage: _language);
      if (!mounted) return;
      setState(() {
        _stack.add(_BotStep(node: node, params: params, response: response));
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _unavailable = true;
        _loading = false;
      });
    }
  }

  void _selectOption(Map option) => _query(
    option['id']?.toString() ?? _kRootNode,
    (option['params'] as Map?)?.cast<String, dynamic>() ?? const {},
  );

  void _back() {
    if (_stack.length <= 1) return;
    setState(() => _stack.removeLast());
  }

  /// Breadcrumbs are derived server-side and can be deeper than the path the
  /// user actually walked (`byImportance` always claims to sit under
  /// `analytics`), so a crumb rewinds to a step already on the stack rather
  /// than trusting its index.
  void _rewindTo(String? node) {
    final index = _stack.lastIndexWhere((step) => step.node == node);
    if (index < 0 || index >= _stack.length - 1) return;
    setState(() => _stack.removeRange(index + 1, _stack.length));
  }

  Future<void> _refreshCurrent() async {
    final current = _stack.isEmpty ? null : _stack.last;
    if (current == null) return;
    _stack.removeLast();
    await _query(current.node, current.params);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    final current = _stack.isEmpty ? null : _stack.last.response;
    final breadcrumb = ((current?['breadcrumb'] as List?) ?? const [])
        .cast<Map>();
    final options = ((current?['options'] as List?) ?? const []).cast<Map>();
    final hasCards = ((current?['cards'] as List?) ?? const []).isNotEmpty;

    final Widget body;
    if (_loading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_unavailable) {
      body = _CenteredState(
        icon: Icons.cloud_off,
        title: l10n.aiCrmUnavailable,
        actionLabel: l10n.crmBotRetry,
        onAction: () => _query(_pendingNode, _pendingParams),
      );
    } else if (current == null) {
      body = const SizedBox.shrink();
    } else {
      body = _BotAnswer(
        response: current,
        onSelectOption: _selectOption,
        onChanged: _refreshCurrent,
      );
    }

    final shell = LayoutBuilder(
      builder: (context, constraints) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!widget.dialog) const _DragHandle(),
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              widget.dialog ? AppSpacing.lg : 0,
              AppSpacing.sm,
              AppSpacing.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SheetHeader(
                  compact: !widget.dialog,
                  onBack: _stack.length > 1 && !_loading ? _back : null,
                ),
                if (breadcrumb.length > 1) ...[
                  const SizedBox(height: AppSpacing.md),
                  _BreadcrumbRow(
                    breadcrumb: breadcrumb,
                    onTap: _loading ? null : _rewindTo,
                    reachable: _stack.map((step) => step.node).toSet(),
                  ),
                ],
              ],
            ),
          ),
          Divider(height: 1, thickness: 1, color: colors.outline),
          Expanded(child: body),
          if (options.isNotEmpty)
            _OptionsFooter(
              options: options,
              enabled: !_loading,
              maxHeight:
                  constraints.maxHeight *
                  (hasCards ? _kFooterHeightShare : _kMenuFooterHeightShare),
              onSelect: _selectOption,
            ),
        ],
      ),
    );

    if (widget.dialog) return shell;

    final window = MediaQuery.sizeOf(context);
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: keyboard),
      child: SizedBox(
        height: math.max(
          _kDialogMinSize.height,
          window.height * 0.92 - keyboard,
        ),
        child: SafeArea(top: false, child: shell),
      ),
    );
  }
}

/// Grab bar of the mobile sheet, same 44x5 outline pill the b2b AI chat sheet
/// uses.
class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 44,
        height: 5,
        margin: const EdgeInsets.only(
          top: AppSpacing.md,
          bottom: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: context.colors.outline,
          borderRadius: BorderRadius.circular(AppRadii.pill),
        ),
      ),
    );
  }
}

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({required this.compact, required this.onBack});

  final bool compact;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);

    return Row(
      children: [
        if (onBack != null) ...[
          IconButton(
            tooltip: l10n.crmBotBack,
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back),
            visualDensity: VisualDensity.compact,
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
        const _AiAvatar(size: 36),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.crmBotTitle,
                style: compact ? textTheme.titleMedium : textTheme.titleLarge,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                l10n.crmBotSubtitle,
                style: textTheme.bodySmall?.copyWith(color: colors.inkMuted),
                maxLines: 2,
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: l10n.commonClose,
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.close),
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }
}

/// Round assistant mark on a brand tint — the sheet's own face, next to the
/// title and again beside every message it sends.
class _AiAvatar extends StatelessWidget {
  const _AiAvatar({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: colors.accent.withValues(alpha: 0.10),
        shape: BoxShape.circle,
        border: Border.all(color: colors.accent.withValues(alpha: 0.28)),
      ),
      child: Icon(Icons.auto_awesome, size: size * 0.5, color: colors.accent),
    );
  }
}

class _BreadcrumbRow extends StatelessWidget {
  const _BreadcrumbRow({
    required this.breadcrumb,
    required this.onTap,
    required this.reachable,
  });

  final List<Map> breadcrumb;
  final ValueChanged<String?>? onTap;

  /// Nodes currently on the navigation stack — only those can be rewound to.
  final Set<String> reachable;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final style = Theme.of(context).textTheme.labelSmall?.copyWith(
      color: colors.inkMuted,
      fontWeight: FontWeight.w600,
    );

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < breadcrumb.length; i++) ...[
            if (i > 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Icon(
                  Icons.chevron_right,
                  size: 14,
                  color: colors.inkMuted,
                ),
              ),
            Builder(
              builder: (context) {
                final node = breadcrumb[i]['node']?.toString();
                final label = _botNodeLabel(
                  l10n,
                  node,
                  breadcrumb[i]['labelCode']?.toString(),
                );
                final last = i == breadcrumb.length - 1;
                final canTap =
                    !last && onTap != null && reachable.contains(node);
                return InkWell(
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                  onTap: canTap ? () => onTap!(node) : null,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 2,
                    ),
                    child: Text(
                      label,
                      style: last ? style?.copyWith(color: colors.ink) : style,
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

/// Transient body state (loading failure, nothing to show) centered in the
/// body — the old sheet parked these at the top of a 640px box, which read as
/// a broken dialog rather than a state.
class _CenteredState extends StatelessWidget {
  const _CenteredState({
    required this.icon,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            EmptyState(compact: true, icon: icon, title: title),
            if (actionLabel != null && onAction != null)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                child: PillButton(
                  label: actionLabel!,
                  icon: Icons.refresh,
                  variant: PillButtonVariant.outline,
                  onPressed: onAction,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BotAnswer extends StatelessWidget {
  const _BotAnswer({
    required this.response,
    required this.onSelectOption,
    required this.onChanged,
  });

  final Map<String, dynamic> response;
  final ValueChanged<Map> onSelectOption;
  final VoidCallback onChanged;

  static const _padding = EdgeInsets.all(AppSpacing.lg);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cards = (response['cards'] as List? ?? const []).cast<Map>();
    final node = response['node']?.toString();
    final isExample = response['isExample'] == true;

    final message = _AssistantBubble(
      text: _botMessage(
        l10n,
        response['messageCode']?.toString(),
        (response['messageParams'] as Map?)?.cast<String, dynamic>(),
      ),
    );

    if (cards.isEmpty) {
      // A menu node's answer *is* its options, so it gets the question alone,
      // centered against the footer instead of clinging to the divider.
      if (_kMenuNodes.contains(node)) {
        return Center(
          child: SingleChildScrollView(padding: _padding, child: message),
        );
      }
      return Padding(
        padding: _padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            message,
            Expanded(
              child: _CenteredState(
                icon: Icons.inbox_outlined,
                title: l10n.crmBotEmptyCards,
              ),
            ),
          ],
        ),
      );
    }

    final group = _CardGroup(
      cards: cards,
      onSelectOption: onSelectOption,
      onChanged: onChanged,
    );

    return SingleChildScrollView(
      padding: _padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          message,
          const SizedBox(height: AppSpacing.md),
          if (isExample) _ExampleFrame(child: group) else group,
        ],
      ),
    );
  }
}

class _AssistantBubble extends StatelessWidget {
  const _AssistantBubble({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _AiAvatar(size: 28),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: AppCard(
            color: colors.surfaceAlt,
            radius: AppRadii.md,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm + 2,
            ),
            child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ),
      ],
    );
  }
}

/// Wrapper for a card group the server flagged `isExample` — a demo answer for
/// a workspace with no leads yet. Tinted and badged so it reads as
/// illustrative at a glance and is never mistaken for live data.
class _ExampleFrame extends StatelessWidget {
  const _ExampleFrame({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.accent.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: colors.accent.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Align(alignment: Alignment.centerLeft, child: AiExampleBadge()),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}

/// The answer's cards, stacked. Metric cards are narrow by nature, so a run
/// of them pairs up into two columns once there is room — a column of thin
/// full-width strips is what made the analytics answers look empty.
class _CardGroup extends StatelessWidget {
  const _CardGroup({
    required this.cards,
    required this.onSelectOption,
    required this.onChanged,
  });

  final List<Map> cards;
  final ValueChanged<Map> onSelectOption;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final pairMetrics = constraints.maxWidth >= _kTwoColumnMinWidth;
        final rows = <Widget>[];
        var index = 0;
        while (index < cards.length) {
          final card = cards[index];
          final isMetric = card['type'] == 'metric';
          if (pairMetrics && isMetric) {
            final pair = cards
                .skip(index)
                .take(2)
                .takeWhile((c) => c['type'] == 'metric')
                .toList();
            rows.add(
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var column = 0; column < 2; column++) ...[
                      if (column > 0) const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: column < pair.length
                            ? _card(pair[column])
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ],
                ),
              ),
            );
            index += pair.length;
          } else {
            rows.add(_card(card));
            index += 1;
          }
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < rows.length; i++) ...[
              if (i > 0) const SizedBox(height: AppSpacing.sm),
              rows[i],
            ],
          ],
        );
      },
    );
  }

  Widget _card(Map card) => _BotCard(
    card: card.cast<String, dynamic>(),
    onSelectOption: onSelectOption,
    onChanged: onChanged,
  );
}

class _BotCard extends StatelessWidget {
  const _BotCard({
    required this.card,
    required this.onSelectOption,
    required this.onChanged,
  });

  final Map<String, dynamic> card;
  final ValueChanged<Map> onSelectOption;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return switch (card['type']?.toString()) {
      'lead' => _LeadCard(card: card, onChanged: onChanged),
      'metric' => _MetricCard(card: card),
      'project' => _ProjectCard(
        card: card,
        onTap: (projectId) => onSelectOption({
          'id': 'projectMenu',
          'params': {'projectId': projectId},
        }),
      ),
      'manager' => _ManagerCard(
        card: card,
        onTap: (userId) => onSelectOption({
          'id': 'managerLeads',
          'params': {'userId': userId},
        }),
      ),
      _ => const SizedBox.shrink(),
    };
  }
}

class _LeadCard extends ConsumerWidget {
  const _LeadCard({required this.card, required this.onChanged});
  final Map<String, dynamic> card;
  final VoidCallback onChanged;

  Map<String, dynamic> get _leadShape => {
    'id': card['leadId'],
    'number': card['number'],
    'projectName': card['projectName'],
    'contactPhone': card['contactPhone'],
    'status': card['status'],
    'createdAt': card['createdAt'],
    'score': null,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final band = card['aiBand']?.toString();
    final score = (card['aiScore'] as num?)?.round();
    final reasons = (card['aiReasons'] as List? ?? const [])
        .map((r) => r.toString())
        .take(3)
        .toList();
    // Example cards carry no `leadId`, so the server sends them without
    // actions — nothing here may offer to open a lead that doesn't exist.
    final actions = (card['actions'] as List? ?? const [])
        .map((a) => a.toString())
        .toList();
    final leadId = card['leadId']?.toString();

    Future<void> handleAction(String action) async {
      if (leadId == null) return;
      final api = ref.read(adminApiProvider);
      switch (action) {
        case 'openLead':
          final result = await showDialog<CrmLeadEditResult>(
            context: context,
            builder: (_) => CrmLeadEditorDialog(
              lead: _leadShape,
              statuses: kAiCrmLeadStatuses,
            ),
          );
          if (result == null) return;
          await applyCrmLeadEdit(ref, leadId: leadId, result: result);
          onChanged();
        case 'assignToMe':
          final me = ref.read(authControllerProvider).value;
          if (me == null) return;
          await api.updateLead(leadId, ownerUserId: me.id);
          onChanged();
        case 'markContacted':
          await api.updateLeadStatus(leadId, 'contacted');
          onChanged();
      }
    }

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  [
                    card['number'],
                    card['projectName'],
                  ].where((v) => v != null).join(' · '),
                  style: textTheme.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              if (score != null)
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.xs),
                  child: Text(
                    '$score',
                    style: textTheme.titleSmall?.copyWith(
                      color: colors.inkMuted,
                    ),
                  ),
                ),
              if (band != null) AiBandPill(band: band),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            displayPhone(l10n, card['contactPhone']?.toString()),
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
          if (actions.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                for (final action in actions)
                  PillButton(
                    label: switch (action) {
                      'openLead' => l10n.crmBotActionOpenLead,
                      'assignToMe' => l10n.crmBotActionAssignToMe,
                      'markContacted' => l10n.crmBotActionMarkContacted,
                      _ => action,
                    },
                    variant: PillButtonVariant.outline,
                    onPressed: () => handleAction(action),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.card});
  final Map<String, dynamic> card;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final value = card['value'] as num?;
    final unit = card['unit']?.toString();
    // The server reads `up` as the good direction and `down` as the bad one
    // (SLA breaches going up is sent as `down`), so the tint follows the
    // meaning, not the arrow.
    final (trendIcon, trendColor) = switch (card['trend']?.toString()) {
      'up' => (Icons.trending_up, colors.success),
      'down' => (Icons.trending_down, colors.danger),
      'flat' => (Icons.trending_flat, colors.inkMuted),
      _ => (null, colors.inkMuted),
    };

    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _botMetricLabel(
                l10n,
                card['metricCode']?.toString(),
                (card['metricParams'] as Map?)?.cast<String, dynamic>(),
              ),
              style: textTheme.bodyMedium,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            value == null ? '—' : _formatNumber(value),
            style: textTheme.titleLarge,
          ),
          if (value != null && unit == 'percent')
            Text('%', style: textTheme.titleLarge),
          if (value != null && unit == 'minutes') ...[
            const SizedBox(width: AppSpacing.xs),
            Text(
              l10n.aiMetricMinutesSuffix,
              style: textTheme.bodySmall?.copyWith(color: colors.inkMuted),
            ),
          ],
          if (trendIcon != null) ...[
            const SizedBox(width: AppSpacing.xs),
            Icon(trendIcon, size: 18, color: trendColor),
          ],
        ],
      ),
    );
  }
}

/// One manager's workload, tappable into their own lead queue. Example cards
/// carry no `userId`, so those stay inert.
class _ManagerCard extends StatelessWidget {
  const _ManagerCard({required this.card, required this.onTap});
  final Map<String, dynamic> card;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final userId = card['userId']?.toString();
    final name = card['name']?.toString() ?? '';
    final initials = _initials(name);
    final avgMinutes = card['avgResponseMinutes'] as num?;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      onTap: userId == null ? null : () => onTap(userId),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.surfaceAlt,
              shape: BoxShape.circle,
            ),
            child: initials.isEmpty
                ? Icon(Icons.person_outline, size: 20, color: colors.inkMuted)
                : Text(
                    initials,
                    style: textTheme.labelLarge?.copyWith(
                      color: colors.inkMuted,
                    ),
                  ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: textTheme.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.crmBotManagerMeta(
                    (card['openLeads'] as num?)?.toInt() ?? 0,
                    (card['hotLeads'] as num?)?.toInt() ?? 0,
                  ),
                  style: textTheme.bodySmall?.copyWith(color: colors.inkMuted),
                ),
                if (avgMinutes != null)
                  Text(
                    l10n.crmBotManagerAvgResponse(_formatNumber(avgMinutes)),
                    style: textTheme.bodySmall?.copyWith(
                      color: colors.inkMuted,
                    ),
                  ),
              ],
            ),
          ),
          if (userId != null) Icon(Icons.chevron_right, color: colors.inkMuted),
        ],
      ),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({required this.card, required this.onTap});
  final Map<String, dynamic> card;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final projectId = card['projectId']?.toString();
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      onTap: projectId == null ? null : () => onTap(projectId),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  card['projectName']?.toString() ?? '',
                  style: textTheme.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.crmBotProjectMeta(
                    (card['hotLeads'] as num?)?.toInt() ?? 0,
                    (card['openLeads'] as num?)?.toInt() ?? 0,
                    (card['availableUnits'] as num?)?.toInt() ?? 0,
                  ),
                  style: textTheme.bodySmall?.copyWith(color: colors.inkMuted),
                ),
              ],
            ),
          ),
          if (projectId != null)
            Icon(Icons.chevron_right, color: colors.inkMuted),
        ],
      ),
    );
  }
}

/// The answer's options, pinned under the body behind a hairline so the menu
/// is always reachable without scrolling the cards away.
class _OptionsFooter extends StatelessWidget {
  const _OptionsFooter({
    required this.options,
    required this.enabled,
    required this.maxHeight,
    required this.onSelect,
  });

  final List<Map> options;
  final bool enabled;
  final double maxHeight;
  final ValueChanged<Map> onSelect;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.outline)),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= _kTwoColumnMinWidth
                  ? 2
                  : 1;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < options.length; i += columns) ...[
                    if (i > 0) const SizedBox(height: AppSpacing.sm),
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (var column = 0; column < columns; column++) ...[
                            if (column > 0)
                              const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: i + column < options.length
                                  ? _button(l10n, options[i + column])
                                  : const SizedBox.shrink(),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _button(AppLocalizations l10n, Map option) => PillButton(
    label: _botOptionLabel(
      l10n,
      option['id']?.toString(),
      option['labelCode']?.toString(),
      (option['labelParams'] as Map?)?.cast<String, dynamic>(),
    ),
    variant: PillButtonVariant.outline,
    expand: true,
    onPressed: enabled ? () => onSelect(option) : null,
  );
}

/// Up to two leading letters of [name] for an avatar. Falls back to an empty
/// string when there is nothing to initialise (a manager row whose display
/// label is a bare phone number), so the caller can show an icon instead.
String _initials(String name) {
  final letter = RegExp(r'\p{L}', unicode: true);
  return name
      .split(RegExp(r'[\s.]+'))
      .map((word) => word.isEmpty ? '' : word.substring(0, 1))
      .where(letter.hasMatch)
      .take(2)
      .join()
      .toUpperCase();
}

/// Whole numbers stay whole: `38.0` minutes reads `38`, not `38.0`.
String _formatNumber(num value) {
  final rounded = value.round();
  return (value - rounded).abs() < 0.05 ? '$rounded' : value.toStringAsFixed(1);
}

// --- Code -> ARB localization -----------------------------------------
//
// The server ships display text as `code + params` (never prose) so all
// three languages come from the b2b ARB files. Every switch below falls
// back to a generic ARB string (never the raw code, never a crash) for any
// node/option/metric the sibling documents later that this pass didn't
// anticipate.

String _botMessage(
  AppLocalizations l10n,
  String? code,
  Map<String, dynamic>? params,
) {
  final count = (params?['count'] as num?)?.toInt() ?? 0;
  final name = params?['name']?.toString() ?? '';
  return switch (code) {
    'crmBot.root.message' => l10n.crmBotMessageRoot,
    'crmBot.hotLeads.message' => l10n.crmBotMessageHotLeads(count),
    'crmBot.byProject.message' => l10n.crmBotMessageByProject,
    'crmBot.byImportance.message' => l10n.crmBotMessageByImportance,
    'crmBot.todaySummary.message' => l10n.crmBotMessageTodaySummary,
    'crmBot.whatNext.message' => l10n.crmBotMessageWhatNext,
    'crmBot.needsResponse.message' => l10n.crmBotMessageNeedsResponse(count),
    'crmBot.unassigned.message' => l10n.crmBotMessageUnassigned(count),
    'crmBot.byManager.message' => l10n.crmBotMessageByManager(count),
    'crmBot.managerLeads.message' => l10n.crmBotMessageManagerLeads(
      name,
      count,
    ),
    'crmBot.analytics.message' => l10n.crmBotMessageAnalytics,
    'crmBot.weekSummary.message' => l10n.crmBotMessageWeekSummary(count),
    'crmBot.conversion.message' => l10n.crmBotMessageConversion,
    'crmBot.demand.message' => l10n.crmBotMessageDemand(count),
    'crmBot.projectMenu.message' => l10n.crmBotMessageProjectMenu,
    'crmBot.projectHot.message' => l10n.crmBotMessageProjectHot(count),
    'crmBot.projectNoResponse48h.message' =>
      l10n.crmBotMessageProjectNoResponse48h(count),
    'crmBot.projectNewToday.message' => l10n.crmBotMessageProjectNewToday(
      count,
    ),
    'crmBot.projectFunnel.message' => l10n.crmBotMessageProjectFunnel,
    'crmBot.projectDemand.message' => l10n.crmBotMessageProjectDemand(name),
    'crmBot.example.message' => l10n.crmBotMessageExample,
    _ => l10n.crmBotMessageGeneric,
  };
}

String _botOptionLabel(
  AppLocalizations l10n,
  String? id,
  String? code,
  Map<String, dynamic>? params,
) {
  // `_byProject`/`_byManager`'s per-row options have no fixed vocabulary —
  // their label *is* the project's or manager's name (`labelParams.name`),
  // not a code to look up.
  if (code == 'crmBot.option.project' || code == 'crmBot.option.manager') {
    return (params?['name'] as String?) ?? id ?? '';
  }
  return switch (code ?? id) {
    'crmBot.option.hotLeads' || 'hotLeads' => l10n.crmBotOptionHotLeads,
    'crmBot.option.byProject' || 'byProject' => l10n.crmBotOptionByProject,
    'crmBot.option.byImportance' ||
    'byImportance' => l10n.crmBotOptionByImportance,
    'crmBot.option.todaySummary' ||
    'todaySummary' => l10n.crmBotOptionTodaySummary,
    'crmBot.option.whatNext' || 'whatNext' => l10n.crmBotOptionWhatNext,
    'crmBot.option.needsResponse' ||
    'needsResponse' => l10n.crmBotOptionNeedsResponse,
    'crmBot.option.unassigned' || 'unassigned' => l10n.crmBotOptionUnassigned,
    'crmBot.option.byManager' || 'byManager' => l10n.crmBotOptionByManager,
    'crmBot.option.analytics' || 'analytics' => l10n.crmBotOptionAnalytics,
    'crmBot.option.weekSummary' ||
    'weekSummary' => l10n.crmBotOptionWeekSummary,
    'crmBot.option.conversion' || 'conversion' => l10n.crmBotOptionConversion,
    'crmBot.option.demand' || 'demand' => l10n.crmBotOptionDemand,
    'crmBot.option.projectHot' || 'projectHot' => l10n.crmBotOptionProjectHot,
    'crmBot.option.projectNoResponse48h' ||
    'projectNoResponse48h' => l10n.crmBotOptionProjectNoResponse48h,
    'crmBot.option.projectNewToday' ||
    'projectNewToday' => l10n.crmBotOptionProjectNewToday,
    'crmBot.option.projectFunnel' ||
    'projectFunnel' => l10n.crmBotOptionProjectFunnel,
    'crmBot.option.projectDemand' ||
    'projectDemand' => l10n.crmBotOptionProjectDemand,
    'crmBot.option.backToRoot' => l10n.crmBotOptionBackToRoot,
    'crmBot.option.backToProjects' => l10n.crmBotOptionBackToProjects,
    'crmBot.option.backToProjectMenu' => l10n.crmBotOptionBackToProjectMenu,
    'crmBot.option.backToAnalytics' => l10n.crmBotOptionBackToAnalytics,
    'crmBot.option.backToManagers' => l10n.crmBotOptionBackToManagers,
    _ => (params?['label'] as String?) ?? id ?? '',
  };
}

String _botNodeLabel(AppLocalizations l10n, String? node, String? code) {
  return switch (code ?? node) {
    'crmBot.node.root' || 'root' => l10n.crmBotNodeRoot,
    'crmBot.node.hotLeads' || 'hotLeads' => l10n.crmBotNodeHotLeads,
    'crmBot.node.byProject' || 'byProject' => l10n.crmBotNodeByProject,
    'crmBot.node.byImportance' || 'byImportance' => l10n.crmBotNodeByImportance,
    'crmBot.node.todaySummary' || 'todaySummary' => l10n.crmBotNodeTodaySummary,
    'crmBot.node.whatNext' || 'whatNext' => l10n.crmBotNodeWhatNext,
    'crmBot.node.needsResponse' ||
    'needsResponse' => l10n.crmBotNodeNeedsResponse,
    'crmBot.node.unassigned' || 'unassigned' => l10n.crmBotNodeUnassigned,
    'crmBot.node.byManager' || 'byManager' => l10n.crmBotNodeByManager,
    'crmBot.node.managerLeads' || 'managerLeads' => l10n.crmBotNodeManagerLeads,
    'crmBot.node.analytics' || 'analytics' => l10n.crmBotNodeAnalytics,
    'crmBot.node.weekSummary' || 'weekSummary' => l10n.crmBotNodeWeekSummary,
    'crmBot.node.conversion' || 'conversion' => l10n.crmBotNodeConversion,
    'crmBot.node.demand' || 'demand' => l10n.crmBotNodeDemand,
    'crmBot.node.projectMenu' || 'projectMenu' => l10n.crmBotNodeProjectMenu,
    'crmBot.node.projectHot' || 'projectHot' => l10n.crmBotNodeProjectHot,
    'crmBot.node.projectNoResponse48h' ||
    'projectNoResponse48h' => l10n.crmBotNodeProjectNoResponse48h,
    'crmBot.node.projectNewToday' ||
    'projectNewToday' => l10n.crmBotNodeProjectNewToday,
    'crmBot.node.projectFunnel' ||
    'projectFunnel' => l10n.crmBotNodeProjectFunnel,
    'crmBot.node.projectDemand' ||
    'projectDemand' => l10n.crmBotNodeProjectDemand,
    _ => node ?? '',
  };
}

String _botMetricLabel(
  AppLocalizations l10n,
  String? code,
  Map<String, dynamic>? params,
) {
  // `_projectFunnel` emits one `crmBot.metric.funnel.<status>` card per
  // funnel stage (see `lead_scoring_engine.dart`'s `CrmQueryEngine`) —
  // labeled with the same lead-status vocabulary used across the rest of
  // the CRM rather than a brand-new set of ARB strings.
  if (code != null && code.startsWith('crmBot.metric.funnel.')) {
    return leadStatusLabel(
      l10n,
      code.substring('crmBot.metric.funnel.'.length),
    );
  }
  final rooms = (params?['rooms'] as num?)?.toInt() ?? 0;
  return switch (code) {
    'crmBot.metric.leadsToday' => l10n.crmBotMetricLeadsToday,
    'crmBot.metric.hotLeads' => l10n.crmBotMetricHotLeads,
    'crmBot.metric.leadVolume' => l10n.crmBotMetricLeadVolume,
    'crmBot.metric.byBand' => l10n.crmBotMetricByBand,
    'crmBot.metric.responseSla' => l10n.crmBotMetricResponseSla,
    'crmBot.metric.funnel' => l10n.crmBotMetricFunnel,
    'crmBot.metric.conversion' => l10n.crmBotMetricConversion,
    'crmBot.metric.leadsWeek' => l10n.crmBotMetricLeadsWeek,
    'crmBot.metric.leadsPrevWeek' => l10n.crmBotMetricLeadsPrevWeek,
    'crmBot.metric.wonWeek' => l10n.crmBotMetricWonWeek,
    'crmBot.metric.slaBreached' => l10n.crmBotMetricSlaBreached,
    'crmBot.metric.demandRooms' => l10n.crmBotMetricDemandRooms(rooms),
    'crmBot.metric.availableRooms' => l10n.crmBotMetricAvailableRooms(rooms),
    'crmBot.metric.conversionStep' => l10n.crmBotMetricConversionStep(
      leadStatusLabel(l10n, params?['from']?.toString() ?? ''),
      leadStatusLabel(l10n, params?['to']?.toString() ?? ''),
    ),
    _ => l10n.crmBotMetricGeneric,
  };
}
