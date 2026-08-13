import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/localization/locale_controller.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_theme_ext.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../providers/ai_chat_providers.dart';
import 'widgets/ai_info_sheet.dart' as info;
import 'widgets/ai_mark_badge.dart';
import 'widgets/typing_dots.dart';

/// Opens the AI assistant chat — full-height bottom sheet on mobile, dialog
/// on desktop. Same rounded-top container convention as `filter_sheet.dart`
/// / `mortgage_calculator_sheet.dart`.
Future<void> showAiChatSheet(BuildContext context) {
  if (context.isMobile) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AiChatSheet(),
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
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 680),
        child: const AiChatSheet(dialog: true),
      ),
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

  Future<void> _send() async {
    final text = _input.text;
    if (text.trim().isEmpty) return;
    _input.clear();
    final language = ref.read(localeControllerProvider).languageCode;
    await ref.read(aiChatProvider.notifier).sendMessage(text, language);
    _scrollToBottom();
  }

  void _openInfo(AiChatState state) {
    final l10n = AppLocalizations.of(context);
    info.showAiInfoSheet(
      context,
      title: l10n.aiChatTitle,
      description: l10n.aiChatInfoBody,
      quota: state.quota,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(aiChatProvider);

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
                : l10n.aiChatErrorSnackbar,
          ),
        ),
      );
      ref.read(aiChatProvider.notifier).clearTransientError();
    });

    ref.listen(aiChatProvider.select((s) => s.messages.length), (_, _) {
      _scrollToBottom();
    });

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
          children: [
            const AiMarkBadge(),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(l10n.aiChatTitle, style: textTheme.headlineSmall),
            ),
            IconButton(
              tooltip: l10n.aiChatInfoTooltip,
              onPressed: () => _openInfo(state),
              icon: const Icon(Icons.info_outline),
              visualDensity: VisualDensity.compact,
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
          child: state.messages.isEmpty && !state.sending
              ? _ChatEmptyPrompt(l10n: l10n)
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
            onSend: _send,
          )
        else
          EmptyState(
            compact: true,
            icon: state.status == AiChatUiStatus.quotaExhausted
                ? Icons.hourglass_bottom
                : Icons.cloud_off,
            title: state.status == AiChatUiStatus.quotaExhausted
                ? l10n.aiChatQuotaExhaustedTitle
                : l10n.aiChatUnavailableTitle,
            subtitle: state.status == AiChatUiStatus.quotaExhausted
                ? (state.resetAt == null
                      ? l10n.aiChatQuotaExhaustedBody
                      : l10n.aiQuotaResetLabel(
                          DateFormat(
                            'd MMM, HH:mm',
                            Intl.defaultLocale,
                          ).format(state.resetAt!.toLocal()),
                        ))
                : l10n.aiChatUnavailableBody,
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
          color: colors.background,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadii.card),
          ),
        ),
        child: body,
      ),
    );
  }
}

class _ChatEmptyPrompt extends StatelessWidget {
  const _ChatEmptyPrompt({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: EmptyState(
        compact: true,
        icon: Icons.chat_bubble_outline_rounded,
        title: l10n.aiChatEmptyTitle,
        subtitle: l10n.aiChatEmptyBody,
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
            color: isUser ? colors.accent : colors.surface,
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
            color: colors.surface,
            borderRadius: pill,
            clipBehavior: Clip.antiAlias,
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              decoration: InputDecoration(
                hintText: l10n.aiChatInputHint,
                filled: true,
                fillColor: colors.surface,
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
            tooltip: l10n.aiChatSendTooltip,
            onPressed: sending ? null : onSend,
            icon: Icon(Icons.arrow_upward_rounded, color: colors.onAccent),
          ),
        ),
      ],
    );
  }
}
