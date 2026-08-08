import 'package:flutter/material.dart';

import '../theme/app_dimens.dart';
import '../theme/app_theme_ext.dart';

/// Text-field-styled picker with a custom option list (for short fixed choices).
class AppDropdownField<T> extends StatefulWidget {
  const AppDropdownField({
    super.key,
    required this.value,
    required this.options,
    required this.labelBuilder,
    required this.onChanged,
    this.label,
    this.icon,
  });

  final T? value;
  final List<T> options;
  final String Function(T option) labelBuilder;
  final ValueChanged<T> onChanged;
  final String? label;
  final IconData? icon;

  @override
  State<AppDropdownField<T>> createState() => _AppDropdownFieldState<T>();
}

class _AppDropdownFieldState<T> extends State<AppDropdownField<T>> {
  bool _open = false;

  Future<void> _showPicker() async {
    final renderBox = context.findRenderObject() as RenderBox?;
    final overlayBox =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (renderBox == null || overlayBox == null) return;
    final colors = context.colors;
    final topLeft = renderBox.localToGlobal(Offset.zero, ancestor: overlayBox);
    final size = renderBox.size;

    setState(() => _open = true);
    final selected = await showMenu<T>(
      context: context,
      position: RelativeRect.fromLTRB(
        topLeft.dx,
        topLeft.dy + size.height + AppSpacing.xs,
        overlayBox.size.width - topLeft.dx - size.width,
        0,
      ),
      color: colors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
        side: BorderSide(color: colors.outline),
      ),
      constraints: BoxConstraints(minWidth: size.width, maxWidth: size.width),
      items: [
        for (final option in widget.options)
          PopupMenuItem<T>(
            value: option,
            padding: EdgeInsets.zero,
            child: _OptionRow(
              label: widget.labelBuilder(option),
              selected: option == widget.value,
            ),
          ),
      ],
    );
    if (mounted) setState(() => _open = false);
    if (selected != null) widget.onChanged(selected);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final value = widget.value;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.input),
        onTap: _showPicker,
        child: InputDecorator(
          isEmpty: value == null,
          decoration: InputDecoration(
            labelText: widget.label,
            prefixIcon: widget.icon != null ? Icon(widget.icon) : null,
            suffixIcon: AnimatedRotation(
              duration: AppDurations.fast,
              turns: _open ? 0.5 : 0,
              child: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: colors.inkMuted,
              ),
            ),
          ),
          child: value == null
              ? null
              : Text(widget.labelBuilder(value), style: textTheme.bodyLarge),
        ),
      ),
    );
  }
}

class _OptionRow extends StatelessWidget {
  const _OptionRow({required this.label, required this.selected});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      color: selected ? colors.accent.withValues(alpha: 0.12) : null,
      child: Row(
        children: [
          Icon(
            Icons.location_on_outlined,
            size: 18,
            color: selected ? colors.ink : colors.inkMuted,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              label,
              style: textTheme.bodyMedium?.copyWith(
                color: colors.ink,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
          if (selected)
            Icon(Icons.check_rounded, size: 18, color: colors.accentSecondary),
        ],
      ),
    );
  }
}
