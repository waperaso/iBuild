import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/localization/status_labels.dart';
import '../../core/network/ws_client.dart';import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_theme_ext.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/lead_kanban_board.dart';
import '../../core/widgets/pill_button.dart';
import '../../l10n/gen/app_localizations.dart';
import '../admin/admin_api.dart';
import '../crm/crm_shared.dart';
import 'platform_widgets.dart';

const _kLeadStatuses = [
  'new',
  'contacted',
  'scheduled',
  'visited',
  'qualified',
  'won',
  'lost',
];

final _platformLeadsProvider = FutureProvider.family<
    List<Map<String, dynamic>>,
    String>((ref, ownerFilter) {
  final owner = ownerFilter == 'all' ? null : ownerFilter;
  return ref.watch(adminApiProvider).platformLeads(owner: owner);
});

/// Platform-wide lead CRM with owner filters, assignee display, and transfer.
class PlatformCrm extends ConsumerStatefulWidget {
  const PlatformCrm({super.key});

  @override
  ConsumerState<PlatformCrm> createState() => _PlatformCrmState();
}

class _PlatformCrmState extends ConsumerState<PlatformCrm> {
  String? _statusFilter;
  String _ownerFilter = 'all';
  String _search = '';
  StreamSubscription<WsEvent>? _wsSub;

  @override
  void initState() {
    super.initState();
    final client = ref.read(wsClientProvider);
    _wsSub = client.connect().listen((event) {
      if (event.type == WsEventType.leadOwnerChanged ||
          event.type == WsEventType.leadStatusChanged ||
          event.type == WsEventType.leadCreated) {
        ref.invalidate(_platformLeadsProvider(_ownerFilter));
      }
    });
  }

  @override
  void dispose() {
    _wsSub?.cancel();
    super.dispose();
  }

  Future<void> _updateLeadStatus(
    Map<String, dynamic> lead,
    String status,
  ) async {
    await runPlatformAction(
      context,
      ref,
      action: () => ref
          .read(adminApiProvider)
          .updateLeadStatus(lead['id'] as String, status),
      onSuccess: () => ref.invalidate(_platformLeadsProvider(_ownerFilter)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    final isWide = !context.isMobile;
    final leads = ref.watch(_platformLeadsProvider(_ownerFilter));
    final statusFilter = _statusFilter;
    final search = _search.trim().toLowerCase();
    final pad = isWide ? AppSpacing.xl : AppSpacing.lg;

    final filtered = leads.maybeWhen(
      data: (items) => items.where((lead) {
        if (statusFilter != null && lead['status'] != statusFilter) {
          return false;
        }
        if (search.isEmpty) return true;
        final haystack = [
          lead['projectName'],
          lead['contactPhone'],
          lead['message'],
          lead['assignedManager'],
        ].map((v) => v?.toString().toLowerCase() ?? '').join(' ');
        return haystack.contains(search);
      }).toList(),
      orElse: () => const <Map<String, dynamic>>[],
    );

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(pad, pad, pad, AppSpacing.lg),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.crmTitle, style: textTheme.headlineMedium),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  l10n.crmSubtitle,
                  style: textTheme.bodyMedium?.copyWith(color: colors.inkMuted),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.crmKanbanHint,
                  style: textTheme.bodySmall?.copyWith(color: colors.inkMuted),
                ),
                const SizedBox(height: AppSpacing.lg),
                TextField(
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: l10n.crmSearchHint,
                  ),
                  onChanged: (v) => setState(() => _search = v),
                ),
                const SizedBox(height: AppSpacing.md),
                CrmOwnerFilterChips(
                  selected: _ownerFilter,
                  onChanged: (v) => setState(() => _ownerFilter = v),
                ),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  children: [
                    ChoiceChip(
                      label: Text(l10n.adminProjectsFilterAll),
                      selected: statusFilter == null,
                      onSelected: (_) => setState(() => _statusFilter = null),
                    ),
                    for (final status in _kLeadStatuses)
                      ChoiceChip(
                        label: Text(leadStatusLabel(l10n, status)),
                        selected: statusFilter == status,
                        onSelected: (_) =>
                            setState(() => _statusFilter = status),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (leads.isLoading)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: CircularProgressIndicator()),
          )
        else if (leads.hasError)
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: pad),
            sliver: SliverToBoxAdapter(child: Text('${leads.error}')),
          )
        else if (filtered.isEmpty)
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: pad),
            sliver: SliverToBoxAdapter(
              child: EmptyState(
                compact: true,
                icon: Icons.inbox_outlined,
                title: l10n.crmEmpty,
              ),
            ),
          )
        else
          SliverPadding(
            padding: EdgeInsets.fromLTRB(pad, 0, pad, AppSpacing.xxxl),
            sliver: SliverToBoxAdapter(
              child: LeadKanbanBoard(
                leads: filtered,
                statuses: _kLeadStatuses,
                statusLabel: (status) => leadStatusLabel(l10n, status),
                onStatusChanged: _updateLeadStatus,
                cardBuilder: (context, lead) => _CrmKanbanCard(
                  lead: lead,
                  onEdit: () async {
                    final result = await showDialog<CrmLeadEditResult>(
                      context: context,
                      builder: (_) => CrmLeadEditorDialog(
                        lead: lead,
                        statuses: _kLeadStatuses,
                      ),
                    );
                    if (result == null || !context.mounted) return;
                    await runPlatformAction(
                      context,
                      ref,
                      action: () => applyCrmLeadEdit(
                        ref,
                        leadId: lead['id'] as String,
                        result: result,
                      ),
                      onSuccess: () =>
                          ref.invalidate(_platformLeadsProvider(_ownerFilter)),
                    );
                  },
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _CrmKanbanCard extends StatelessWidget {
  const _CrmKanbanCard({required this.lead, required this.onEdit});

  final Map<String, dynamic> lead;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
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
              if (lead['score'] != null)
                _ScorePill(score: lead['score'].toString()),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            lead['contactPhone']?.toString() ?? '',
            style: textTheme.bodySmall?.copyWith(color: colors.inkMuted),
          ),
          if ((lead['message'] as String?)?.isNotEmpty == true) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              lead['message'].toString(),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: AppSpacing.xs),
          LeadOwnerLine(lead: lead),
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: Alignment.centerRight,
            child: PillButton(
              label: l10n.crmEdit,
              variant: PillButtonVariant.outline,
              onPressed: onEdit,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScorePill extends StatelessWidget {
  const _ScorePill({required this.score});
  final String score;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    final color = switch (score) {
      'hot' => colors.danger,
      'warm' => colors.warning,
      _ => colors.inkMuted,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Text(
        leadScoreLabel(l10n, score),
        style: Theme.of(context)
            .textTheme
            .labelSmall
            ?.copyWith(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}
