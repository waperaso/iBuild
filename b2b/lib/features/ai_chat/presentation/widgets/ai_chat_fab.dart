import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/env.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_theme_ext.dart';
import '../../../../core/widgets/pressable_scale.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../auth/auth.dart';
import '../../providers/ai_chat_fab_visibility_provider.dart';
import '../ai_chat_sheet.dart';

/// The B2B AI assistant FAB — mounted once in `b2b_adaptive_shell.dart` so
/// it floats over every authenticated admin surface. Visible only to signed
/// in admins (system admin or residence admin); a non-admin never reaches
/// the shell at all (see the router redirect in `app.dart`), but this is a
/// deliberate second gate rather than relying on that alone.
///
/// Deliberately pill-shaped with an "AI" wordmark (rather than the plain
/// circular chat-bubble puck b2c uses) so it reads as part of the same AI
/// surface as `AiMarkBadge`/`AiBandPill` in `ai_crm_pills.dart`, and stays
/// visually distinct from the "Open assistant" button that launches the
/// guided `AiCrmBotSheet` from inside the CRM screen.
class AiChatFab extends ConsumerWidget {
  const AiChatFab({super.key});

  static const double _expandedHeight = 52;
  static const double _collapsedSize = 48;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!Env.aiChatEnabled) return const SizedBox.shrink();
    final user = ref.watch(authControllerProvider).value;
    if (user == null || user.banned) return const SizedBox.shrink();
    if (!user.isSystemAdmin && !user.isResidenceAdmin) {
      return const SizedBox.shrink();
    }

    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    final collapsed = ref.watch(aiChatFabCollapsedProvider);

    return PressableScale(
      child: Semantics(
        button: true,
        label: l10n.b2bAiChatFabTooltip,
        child: Tooltip(
          message: l10n.b2bAiChatFabTooltip,
          child: GestureDetector(
            onTap: () => showAiChatSheet(context),
            child: AnimatedContainer(
              duration: AppDurations.medium,
              curve: AppDurations.enter,
              height: collapsed ? _collapsedSize : _expandedHeight,
              width: collapsed ? _collapsedSize : null,
              padding: collapsed
                  ? EdgeInsets.zero
                  : const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              decoration: BoxDecoration(
                color: colors.accent,
                shape: collapsed ? BoxShape.circle : BoxShape.rectangle,
                borderRadius: collapsed
                    ? null
                    : BorderRadius.circular(AppRadii.pill),
                boxShadow: AppShadows.raised(colors.ink),
              ),
              child: Center(
                child: AnimatedSwitcher(
                  duration: AppDurations.medium,
                  child: collapsed
                      ? Icon(
                          Icons.chat_bubble_outline_rounded,
                          key: const ValueKey('collapsed'),
                          size: 20,
                          color: colors.onAccent,
                        )
                      : Row(
                          key: const ValueKey('expanded'),
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline_rounded,
                              size: 18,
                              color: colors.onAccent,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              l10n.b2bAiChatFabLabel,
                              style: textTheme.labelLarge?.copyWith(
                                color: colors.onAccent,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
