import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/env.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_theme_ext.dart';
import '../../../../core/widgets/pressable_scale.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../providers/ai_fab_visibility_provider.dart';
import '../ai_chat_sheet.dart';

/// The AI assistant FAB — mounted once in `adaptive_scaffold.dart` so it is
/// visible on every tab. Shrinks to a compact icon-only puck while the user
/// scrolls down the tab's content (see [aiFabCollapsedProvider]).
class AiAssistantFab extends ConsumerWidget {
  const AiAssistantFab({super.key});

  static const double _expandedSize = 56;
  static const double _collapsedSize = 44;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!Env.aiChatEnabled) return const SizedBox.shrink();
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    final collapsed = ref.watch(aiFabCollapsedProvider);
    final size = collapsed ? _collapsedSize : _expandedSize;

    return PressableScale(
      child: Semantics(
        button: true,
        label: l10n.aiFabTooltip,
        child: Tooltip(
          message: l10n.aiFabTooltip,
          child: GestureDetector(
            onTap: () => showAiChatSheet(context),
            child: AnimatedContainer(
              duration: AppDurations.medium,
              curve: AppDurations.enter,
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: colors.accent,
                shape: BoxShape.circle,
                boxShadow: AppShadows.raised(colors.ink),
              ),
              child: AnimatedSwitcher(
                duration: AppDurations.medium,
                child: Icon(
                  Icons.chat_bubble_outline_rounded,
                  key: ValueKey(collapsed),
                  size: collapsed ? 20 : 24,
                  color: colors.onAccent,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
