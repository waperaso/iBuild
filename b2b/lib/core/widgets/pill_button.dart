import 'package:flutter/material.dart';

import '../theme/app_dimens.dart';
import '../theme/app_theme_ext.dart';
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

  TextStyle _labelStyle(BuildContext context, Color fg) {
    return Theme.of(context).textTheme.labelLarge!.copyWith(
      color: fg,
      height: 1.25,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final (bg, fg, border) = switch (variant) {
      PillButtonVariant.accent => (colors.accent, colors.onAccent, null),
      PillButtonVariant.ink => (colors.ink, colors.surface, null),
      PillButtonVariant.outline => (colors.surface, colors.ink, colors.outline),
    };

    final labelStyle = _labelStyle(context, fg);
    final content = loading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              color: fg,
            ),
          )
        : Row(
            mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: fg),
                const SizedBox(width: AppSpacing.sm),
              ],
              if (expand)
                Flexible(
                  child: Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: labelStyle,
                    textHeightBehavior: const TextHeightBehavior(
                      applyHeightToFirstAscent: false,
                      applyHeightToLastDescent: false,
                    ),
                  ),
                )
              else
                Text(
                  label,
                  softWrap: false,
                  style: labelStyle,
                  textHeightBehavior: const TextHeightBehavior(
                    applyHeightToFirstAscent: false,
                    applyHeightToLastDescent: false,
                  ),
                ),
            ],
          );

    // IntrinsicWidth keeps Wrap from squeezing the label when a row is almost full.
    final button = Material(
      color: bg,
      clipBehavior: Clip.antiAlias,
      borderRadius: BorderRadius.circular(AppRadii.pill),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.pill),
        onTap: loading ? null : onPressed,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.pill),
            border: border != null ? Border.all(color: border) : null,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: content,
          ),
        ),
      ),
    );

    return PressableScale(
      enabled: !loading && onPressed != null,
      child: expand
          ? SizedBox(width: double.infinity, child: button)
          : IntrinsicWidth(child: button),
    );
  }
}
