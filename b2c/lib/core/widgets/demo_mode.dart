import 'package:flutter/material.dart';
import 'package:ibuild_core/ibuild_core.dart';

import '../theme/app_dimens.dart';
import '../theme/app_theme_ext.dart';
import '../widgets/pill_button.dart';
import '../../l10n/gen/app_localizations.dart';

/// One-time popup when entering demo mode.
Future<void> showDemoModeDialog(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  final colors = context.colors;
  final textTheme = Theme.of(context).textTheme;

  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
      title: Row(
        children: [
          Icon(Icons.visibility_outlined, color: colors.accent),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(l10n.demoModeTitle)),
        ],
      ),
      content: Text(l10n.demoModeMessage, style: textTheme.bodyMedium),
      actions: [
        PillButton(
          label: l10n.demoModeGotIt,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    ),
  );
}

/// Persistent strip shown while [DemoSession.isActive].
class DemoModeStrip extends StatelessWidget {
  const DemoModeStrip({super.key});

  @override
  Widget build(BuildContext context) {
    if (!DemoSession.isActive) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context);
    final colors = context.colors;

    return Material(
      color: colors.warning.withValues(alpha: 0.16),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 18, color: colors.warning),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  l10n.demoModeBanner,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: colors.ink,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Wraps [child] with [DemoModeStrip] when demo mode is active.
class DemoModeBanner extends StatelessWidget {
  const DemoModeBanner({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const DemoModeStrip(),
        Expanded(child: child),
      ],
    );
  }
}

void showDemoWriteBlockedSnackBar(BuildContext context) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(content: Text(AppLocalizations.of(context).demoWriteBlocked)),
  );
}
