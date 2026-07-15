import 'package:flutter/material.dart';

import '../theme/app_dimens.dart';
import '../theme/app_theme_ext.dart';
import 'app_loading_indicator.dart';
import 'pressable_scale.dart';

enum PillButtonVariant { accent, outline, ink }

/// Full-radius primary button used for CTAs (Start, Book a viewing, etc.).
class PillButton extends StatelessWidget {
  const PillButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.variant = PillButtonVariant.accent,
    this.expand = false,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final PillButtonVariant variant;
  final bool expand;

  /// Shows a small spinner in place of the label/icon and disables taps.
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final (bg, fg, border) = switch (variant) {
      PillButtonVariant.accent => (colors.accent, colors.onAccent, null),
      PillButtonVariant.ink => (colors.ink, colors.surface, null),
      PillButtonVariant.outline => (colors.surface, colors.ink, colors.outline),
    };

    return PressableScale(
      enabled: !loading && onPressed != null,
      child: SizedBox(
        width: expand ? double.infinity : null,
        child: Material(
          color: bg,
          borderRadius: BorderRadius.circular(AppRadii.pill),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadii.pill),
            onTap: loading ? null : onPressed,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
                vertical: AppSpacing.lg,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadii.pill),
                border: border != null ? Border.all(color: border) : null,
              ),
              child: loading
                  ? AppLoadingIndicator(
                      size: 20,
                      strokeWidth: 2.4,
                      color: fg,
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (icon != null) ...[
                          Icon(icon, size: 18, color: fg),
                          const SizedBox(width: AppSpacing.sm),
                        ],
                        Text(
                          label,
                          style: Theme.of(
                            context,
                          ).textTheme.labelLarge?.copyWith(color: fg),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
