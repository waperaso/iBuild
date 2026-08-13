import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/localization/locale_controller.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_theme_ext.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/pill_button.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../ai_crm/ai_crm_pills.dart';
import '../../auth/auth.dart';
import '../providers/ai_chat_providers.dart';
import 'widgets/typing_dots.dart';

/// Opens the free-form B2B AI assistant chat — bottom sheet on mobile,
/// dialog on desktop, matching the modal convention `ai_crm_bot_sheet.dart`
/// already uses in this app (surface background, rounded-top on mobile,
/// fixed-size `Dialog` on desktop). Distinct entry point and distinct
/// header/title from that guided lead bot: this one answers free-form
/// questions about projects, leads and analytics rather than walking a
/// fixed menu tree.
Future<void> showAiChatSheet(BuildContext context) {
  final surface = context.colors.surface;
  if (context.isMobile) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.card)),
      ),
      builder: (_) => const AiChatSheet(),
    );
  }
  return showDialog<void>(
    context: context,
    builder: (_) => Dialog(
      backgroundColor: surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
      child: const SizedBox(width: 480, height: 680, child: AiChatSheet(dialog: true)),
    ),
  );
}

class AiChatSheet extends ConsumerStatefulWidget {
  const AiChatSheet({super.key, this.dialog = false});

  final bool dialog;

  @override
  ConsumerState<AiChatSheet> createState() => _AiChatSheetState();
}

class _AiChatSheetState extends ConsumerState<AiChatSheet> {
  final _input = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _input.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: AppDurations.medium,
        curve: AppDurations.enter,
      );
    });
  }

  Future<void> _send([String? quickPrompt]) async {
    final text = quickPrompt ?? _input.text;
    if (text.trim().isEmpty) return;
    if (quickPrompt == null) _input.clear();
    final language = ref.read(localeControllerProvider).languageCode;
    await ref.read(aiChatProvider.notifier).sendMessage(text, language);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(aiChatProvider);
    final user = ref.watch(authControllerProvider).value;

    ref.listen(aiChatProvider.select((s) => s.transientErrorCode), (
      previous,
      code,
    ) {
      if (code == null) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            code == 'DEMO_READ_ONLY'
                ? l10n.demoWriteBlocked
                : l10n.b2bAiChatErrorSnackbar,
          ),
        ),
      );
      ref.read(aiChatProvider.notifier).clearTransientError();
    });

    ref.listen(aiChatProvider.select((s) => s.messages.length), (_, _) {
      _scrollToBottom();
    });

    final quota = state.quota;

    final body = Column(
      mainAxisSize: MainAxisSize.min,
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AiMarkBadge(),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.b2bAiChatTitle, style: textTheme.headlineSmall),
                  Text(
                    l10n.b2bAiChatSubtitle,
                    style: textTheme.bodySmall?.copyWith(
                      color: colors.inkMuted,
                    ),
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
        ),
        if (quota != null && !quota.isExhausted) ...[
          const SizedBox(height: AppSpacing.xs),
          Padding(
            padding: const EdgeInsets.only(left: AppSpacing.xxl + AppSpacing.xs),
            child: Text(
              l10n.b2bAiChatQuotaRemaining(quota.remaining, quota.limit),
              style: textTheme.labelSmall?.copyWith(color: colors.inkMuted),
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        Expanded(
          child: state.messages.isEmpty && !state.sending
              ? _ChatEmptyPrompt(l10n: l10n, user: user, onQuickPrompt: _send)
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.sm,
                  ),
                  itemCount: state.messages.length + (state.sending ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index >= state.messages.length) {
                      return const _ChatBubble(
                        isUser: false,
                        child: TypingDots(),
                      );
                    }
                    final turn = state.messages[index];
                    return _ChatBubble(
                      isUser: turn.isUser,
                      child: Text(turn.content),
                    );
                  },
                ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (state.status == AiChatUiStatus.ready)
          _ChatInputRow(
            controller: _input,
            sending: state.sending,
            onSend: () => _send(),
          )
        else
          EmptyState(
            compact: true,
            icon: switch (state.status) {
              AiChatUiStatus.quotaExhausted => Icons.hourglass_bottom,
              AiChatUiStatus.forbidden => Icons.lock_outline,
              _ => Icons.cloud_off,
            },
            title: switch (state.status) {
              AiChatUiStatus.quotaExhausted => l10n.b2bAiChatQuotaExhaustedTitle,
              AiChatUiStatus.forbidden => l10n.b2bAiChatForbiddenTitle,
              _ => l10n.b2bAiChatUnavailableTitle,
            },
            subtitle: switch (state.status) {
              AiChatUiStatus.quotaExhausted => state.resetAt == null
                  ? l10n.b2bAiChatQuotaExhaustedBody
                  : l10n.b2bAiChatQuotaResetLabel(
                      DateFormat(
                        'd MMM, HH:mm',
                        Intl.defaultLocale,
                      ).format(state.resetAt!.toLocal()),
                    ),
              AiChatUiStatus.forbidden => l10n.b2bAiChatForbiddenBody,
              _ => l10n.b2bAiChatUnavailableBody,
            },
          ),
      ],
    );

    if (widget.dialog) {
      return Padding(padding: const EdgeInsets.all(AppSpacing.xl), child: body);
    }

    return SafeArea(
      top: false,
      child: Container(
        height: MediaQuery.sizeOf(context).height * 0.82,
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.lg,
          AppSpacing.xl,
          AppSpacing.lg,
        ),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadii.card),
          ),
        ),
        child: body,
      ),
    );
  }
}

/// Role-appropriate quick prompts shown when the transcript is empty — a
/// system admin gets platform-wide phrasing, a residence admin gets "my
/// project(s)" phrasing.
List<String> _quickPrompts(AppLocalizations l10n, AdminUser? user) {
  if (user?.isSystemAdmin == true) {
    return [
      l10n.b2bAiChatQuickSystemSummary,
      l10n.b2bAiChatQuickSystemOverdue,
      l10n.b2bAiChatQuickSystemAttention,
    ];
  }
  return [
    l10n.b2bAiChatQuickResidenceSummary,
    l10n.b2bAiChatQuickResidenceHotLeads,
    l10n.b2bAiChatQuickResidenceWeekChanges,
  ];
}

class _ChatEmptyPrompt extends StatelessWidget {
  const _ChatEmptyPrompt({
    required this.l10n,
    required this.user,
    required this.onQuickPrompt,
  });

  final AppLocalizations l10n;
  final AdminUser? user;
  final ValueChanged<String> onQuickPrompt;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final prompts = _quickPrompts(l10n, user);

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          EmptyState(
            compact: true,
            icon: Icons.chat_bubble_outline_rounded,
            title: l10n.b2bAiChatEmptyTitle,
            subtitle: l10n.b2bAiChatEmptyBody,
          ),
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              l10n.b2bAiChatQuickPromptsLabel,
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: colors.inkMuted),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final prompt in prompts)
                PillButton(
                  label: prompt,
                  variant: PillButtonVariant.outline,
                  onPressed: () => onQuickPrompt(prompt),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.isUser, required this.child});

  final bool isUser;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.72,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: AppCard(
            color: isUser ? colors.accent : colors.surfaceAlt,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: DefaultTextStyle.merge(
              style: textTheme.bodyMedium?.copyWith(
                color: isUser ? colors.onAccent : colors.ink,
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class _ChatInputRow extends StatelessWidget {
  const _ChatInputRow({
    required this.controller,
    required this.sending,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    final pill = BorderRadius.circular(AppRadii.pill);

    return Row(
      children: [
        Expanded(
          child: Material(
            color: colors.surfaceAlt,
            borderRadius: pill,
            clipBehavior: Clip.antiAlias,
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              decoration: InputDecoration(
                hintText: l10n.b2bAiChatInputHint,
                filled: true,
                fillColor: colors.surfaceAlt,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                border: OutlineInputBorder(
                  borderRadius: pill,
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: pill,
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: pill,
                  borderSide: BorderSide(
                    color: colors.accent.withValues(alpha: 0.45),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Material(
          color: colors.accent,
          shape: const CircleBorder(),
          child: IconButton(
            tooltip: l10n.b2bAiChatSendTooltip,
            onPressed: sending ? null : onSend,
            icon: Icon(Icons.arrow_upward_rounded, color: colors.onAccent),
          ),
        ),
      ],
    );
  }
}
