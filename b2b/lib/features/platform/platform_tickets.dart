import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_theme_ext.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/pill_button.dart';
import '../../l10n/gen/app_localizations.dart';
import '../admin/admin_api.dart';
import 'platform_widgets.dart';

const _kTicketStatuses = ['open', 'in_progress', 'resolved', 'closed'];

String _ticketStatusLabel(AppLocalizations l10n, String status) => switch (status) {
  'open' => l10n.ticketStatusOpen,
  'in_progress' => l10n.ticketStatusInProgress,
  'resolved' => l10n.ticketStatusResolved,
  'closed' => l10n.ticketStatusClosed,
  _ => status,
};

String _ticketCategoryLabel(AppLocalizations l10n, String category) => switch (category) {
  'billing' => l10n.ticketCategoryBilling,
  'moderation' => l10n.ticketCategoryModeration,
  'technical' => l10n.ticketCategoryTechnical,
  _ => l10n.ticketCategoryOther,
};

final _platformTicketsProvider = FutureProvider((ref) {
  return ref.watch(adminApiProvider).platformTickets();
});

String _lastMessage(Map<String, dynamic> ticket) {
  final replies = (ticket['replies'] as List? ?? []).cast<Map>();
  if (replies.isEmpty) return '';
  return replies.last['message']?.toString() ?? '';
}

/// Platform admin ticket triage inbox — support requests from any user
/// (buyer, renter, residence admin, developer), separate from project
/// moderation: a bug report or billing question is not a ЖК to approve.
class PlatformTickets extends ConsumerStatefulWidget {
  const PlatformTickets({super.key});

  @override
  ConsumerState<PlatformTickets> createState() => _PlatformTicketsState();
}

class _PlatformTicketsState extends ConsumerState<PlatformTickets> {
  String? _filter;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    final isWide = !context.isMobile;
    final tickets = ref.watch(_platformTicketsProvider);
    final filter = _filter;
    final pad = isWide ? AppSpacing.xl : AppSpacing.lg;

    final filtered = tickets.maybeWhen(
      data: (items) => filter == null
          ? items
          : items.where((t) => t['status'] == filter).toList(),
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
                Text(l10n.ticketsTitle, style: textTheme.headlineMedium),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  l10n.ticketsSubtitle,
                  style: textTheme.bodyMedium?.copyWith(color: colors.inkMuted),
                ),
                const SizedBox(height: AppSpacing.lg),
                Wrap(
                  spacing: AppSpacing.sm,
                  children: [
                    ChoiceChip(
                      label: Text(l10n.adminProjectsFilterAll),
                      selected: filter == null,
                      onSelected: (_) => setState(() => _filter = null),
                    ),
                    for (final status in _kTicketStatuses)
                      ChoiceChip(
                        label: Text(_ticketStatusLabel(l10n, status)),
                        selected: filter == status,
                        onSelected: (_) => setState(() => _filter = status),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (tickets.isLoading)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: CircularProgressIndicator()),
          )
        else if (tickets.hasError)
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: pad),
            sliver: SliverToBoxAdapter(child: Text('${tickets.error}')),
          )
        else if (filtered.isEmpty)
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: pad),
            sliver: SliverToBoxAdapter(
              child: EmptyState(
                compact: true,
                icon: Icons.support_agent_outlined,
                title: l10n.ticketsEmpty,
              ),
            ),
          )
        else
          SliverPadding(
            padding: EdgeInsets.fromLTRB(pad, 0, pad, AppSpacing.xxxl),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final ticket = filtered[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: AppCard(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(AppRadii.card),
                        onTap: () async {
                          await showDialog<void>(
                            context: context,
                            builder: (_) =>
                                _TicketDetailDialog(ticket: ticket),
                          );
                          ref.invalidate(_platformTicketsProvider);
                        },
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          ticket['subject']?.toString() ?? '',
                                          style: textTheme.titleMedium,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      _TicketStatusPill(
                                        status:
                                            ticket['status']?.toString() ??
                                            'open',
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    '${ticket['userName'] ?? ticket['userPhone'] ?? ''} · '
                                    '${_ticketCategoryLabel(l10n, ticket['category']?.toString() ?? 'other')}',
                                    style: textTheme.bodySmall?.copyWith(
                                      color: colors.inkMuted,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    _lastMessage(ticket),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
                childCount: filtered.length,
                addAutomaticKeepAlives: false,
              ),
            ),
          ),
      ],
    );
  }
}

class _TicketStatusPill extends StatelessWidget {
  const _TicketStatusPill({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    final color = switch (status) {
      'resolved' => colors.success,
      'closed' => colors.inkMuted,
      'in_progress' => colors.warning,
      _ => colors.accentSecondary,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Text(
        _ticketStatusLabel(l10n, status),
        style: Theme.of(context)
            .textTheme
            .labelSmall
            ?.copyWith(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _TicketDetailDialog extends ConsumerStatefulWidget {
  const _TicketDetailDialog({required this.ticket});
  final Map<String, dynamic> ticket;

  @override
  ConsumerState<_TicketDetailDialog> createState() =>
      _TicketDetailDialogState();
}

class _TicketDetailDialogState extends ConsumerState<_TicketDetailDialog> {
  final _reply = TextEditingController();
  late String _status;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _status = widget.ticket['status']?.toString() ?? 'open';
  }

  @override
  void dispose() {
    _reply.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    final replies = (widget.ticket['replies'] as List? ?? [])
        .cast<Map<String, dynamic>>();
    return AlertDialog(
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
      title: Text(widget.ticket['subject']?.toString() ?? ''),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 280),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final reply in replies)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: Align(
                          alignment: reply['isAdmin'] == true
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 360),
                            padding: const EdgeInsets.all(AppSpacing.sm),
                            decoration: BoxDecoration(
                              color: reply['isAdmin'] == true
                                  ? colors.accent.withValues(alpha: 0.15)
                                  : colors.surfaceAlt,
                              borderRadius: BorderRadius.circular(AppRadii.md),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  reply['authorName']?.toString() ?? '',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(color: colors.inkMuted),
                                ),
                                const SizedBox(height: 2),
                                Text(reply['message']?.toString() ?? ''),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                for (final status in _kTicketStatuses)
                  ChoiceChip(
                    label: Text(_ticketStatusLabel(l10n, status)),
                    selected: _status == status,
                    onSelected: (_) => setState(() => _status = status),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _reply,
              autofocus: true,
              maxLines: 3,
              decoration: InputDecoration(hintText: l10n.ticketReplyHint),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.commonClose),
        ),
        PillButton(
          label: l10n.ticketSend,
          loading: _sending,
          onPressed: _sending
              ? null
              : () async {
                  setState(() => _sending = true);
                  final ok = await runPlatformAction(
                    context,
                    ref,
                    action: () => ref
                        .read(adminApiProvider)
                        .platformReplyToTicket(
                          widget.ticket['id'] as String,
                          reply: _reply.text.trim().isEmpty
                              ? null
                              : _reply.text.trim(),
                          status: _status,
                        ),
                  );
                  if (!context.mounted) return;
                  if (ok) {
                    Navigator.pop(context);
                    return;
                  }
                  setState(() => _sending = false);
                },
        ),
      ],
    );
  }
}
