import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_theme_ext.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/pill_button.dart';
import '../../l10n/gen/app_localizations.dart';
import '../admin/admin_api.dart';
import '../platform/platform_widgets.dart';

const _kSupportCategories = ['billing', 'moderation', 'technical', 'other'];

String _categoryLabel(AppLocalizations l10n, String category) => switch (category) {
  'billing' => l10n.ticketCategoryBilling,
  'moderation' => l10n.ticketCategoryModeration,
  'technical' => l10n.ticketCategoryTechnical,
  _ => l10n.ticketCategoryOther,
};

String _statusLabel(AppLocalizations l10n, String status) => switch (status) {
  'open' => l10n.ticketStatusOpen,
  'in_progress' => l10n.ticketStatusInProgress,
  'resolved' => l10n.ticketStatusResolved,
  'closed' => l10n.ticketStatusClosed,
  _ => status,
};

final _myTicketsProvider = FutureProvider((ref) {
  return ref.watch(adminApiProvider).myTickets();
});

/// "Поддержка" — any B2B user (residence admin or developer) can open a
/// support ticket to the platform team and follow the reply thread. Feeds
/// the system admin's platform-wide "Тикеты" triage inbox.
class SupportTickets extends ConsumerWidget {
  const SupportTickets({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    final isWide = !context.isMobile;
    final tickets = ref.watch(_myTicketsProvider);

    return ListView(
      padding: EdgeInsets.fromLTRB(
        isWide ? AppSpacing.xl : AppSpacing.lg,
        isWide ? AppSpacing.xl : AppSpacing.lg,
        isWide ? AppSpacing.xl : AppSpacing.lg,
        AppSpacing.xxxl,
      ),
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.ticketsTitle, style: textTheme.headlineMedium),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    l10n.supportTicketsSubtitle,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colors.inkMuted,
                    ),
                  ),
                ],
              ),
            ),
            PillButton(
              label: l10n.ticketNew,
              onPressed: () async {
                final created = await showDialog<bool>(
                  context: context,
                  builder: (_) => const _NewTicketDialog(),
                );
                if (created == true) ref.invalidate(_myTicketsProvider);
              },
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        tickets.when(
          data: (items) {
            if (items.isEmpty) {
              return EmptyState(
                compact: true,
                icon: Icons.support_agent_outlined,
                title: l10n.ticketsEmpty,
              );
            }
            return Column(
              children: [
                for (final ticket in items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: AppCard(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(AppRadii.card),
                        onTap: () async {
                          await showDialog<void>(
                            context: context,
                            builder: (_) => _MyTicketDialog(ticket: ticket),
                          );
                          ref.invalidate(_myTicketsProvider);
                        },
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    ticket['subject']?.toString() ?? '',
                                    style: textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    _categoryLabel(
                                      l10n,
                                      ticket['category']?.toString() ??
                                          'other',
                                    ),
                                    style: textTheme.bodySmall?.copyWith(
                                      color: colors.inkMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              _statusLabel(
                                l10n,
                                ticket['status']?.toString() ?? 'open',
                              ),
                              style: textTheme.labelMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('$e'),
        ),
      ],
    );
  }
}

class _NewTicketDialog extends ConsumerStatefulWidget {
  const _NewTicketDialog();

  @override
  ConsumerState<_NewTicketDialog> createState() => _NewTicketDialogState();
}

class _NewTicketDialogState extends ConsumerState<_NewTicketDialog> {
  final _subject = TextEditingController();
  final _message = TextEditingController();
  String _category = 'other';
  bool _sending = false;

  @override
  void dispose() {
    _subject.dispose();
    _message.dispose();
    super.dispose();
  }

  bool get _isValid =>
      _subject.text.trim().isNotEmpty && _message.text.trim().isNotEmpty;

  Future<void> _submit() async {
    if (!_isValid || _sending) return;
    setState(() => _sending = true);
    final ok = await runPlatformAction(
      context,
      ref,
      action: () => ref.read(adminApiProvider).createTicket(
        subject: _subject.text.trim(),
        message: _message.text.trim(),
        category: _category,
      ),
    );
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context, true);
      return;
    }
    setState(() => _sending = false);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
      title: Text(l10n.ticketNew),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                for (final c in _kSupportCategories)
                  ChoiceChip(
                    label: Text(_categoryLabel(l10n, c)),
                    selected: _category == c,
                    onSelected: (_) => setState(() => _category = c),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _subject,
              autofocus: true,
              inputFormatters: [LengthLimitingTextInputFormatter(120)],
              decoration: InputDecoration(hintText: l10n.ticketSubjectHint),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _message,
              maxLines: 4,
              inputFormatters: [LengthLimitingTextInputFormatter(1000)],
              decoration: InputDecoration(hintText: l10n.ticketMessageHint),
              onChanged: (_) => setState(() {}),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _sending ? null : () => Navigator.pop(context, false),
          child: Text(l10n.commonCancel),
        ),
        PillButton(
          label: l10n.ticketSend,
          loading: _sending,
          onPressed: !_isValid || _sending ? null : _submit,
        ),
      ],
    );
  }
}

class _MyTicketDialog extends ConsumerStatefulWidget {
  const _MyTicketDialog({required this.ticket});
  final Map<String, dynamic> ticket;

  @override
  ConsumerState<_MyTicketDialog> createState() => _MyTicketDialogState();
}

class _MyTicketDialogState extends ConsumerState<_MyTicketDialog> {
  final _reply = TextEditingController();
  bool _sending = false;

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
                              ? Alignment.centerLeft
                              : Alignment.centerRight,
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
            TextField(
              controller: _reply,
              autofocus: true,
              maxLines: 3,
              decoration: InputDecoration(hintText: l10n.ticketReplyHint),
              onChanged: (_) => setState(() {}),
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
          onPressed: _sending || _reply.text.trim().isEmpty
              ? null
              : () async {
                  setState(() => _sending = true);
                  final ok = await runPlatformAction(
                    context,
                    ref,
                    action: () => ref
                        .read(adminApiProvider)
                        .replyToTicket(
                          widget.ticket['id'] as String,
                          _reply.text.trim(),
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
