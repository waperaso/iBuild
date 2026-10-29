import 'package:flutter/material.dart';

import 'l10n.dart';
import 'theme.dart';

/// Dialogs open in place. A fade keeps the page underneath and leaves a
/// second picture on the web canvas.
Future<T?> showPlainDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) {
  return showDialog<T>(
    context: context,
    animationStyle: AnimationStyle.noAnimation,
    builder: builder,
  );
}

class IBuildCard extends StatelessWidget {
  const IBuildCard({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: colors.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.card),
        side: BorderSide(color: colors.outline),
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(AppSpacing.xl),
        child: child,
      ),
    );
  }
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.busy = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return FilledButton(
      onPressed: busy ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: colors.accent,
        foregroundColor: colors.onAccent,
        disabledBackgroundColor: colors.surfaceAlt,
        minimumSize: const Size(64, 44),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.input),
        ),
        textStyle: Theme.of(context).textTheme.labelLarge,
      ),
      child: Text(label),
    );
  }
}

class ErrorNote extends StatelessWidget {
  const ErrorNote({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      key: const Key('login-error'),
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadii.sm),
      ),
      child: Text(
        LocaleScope.copy(context).known(message),
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: colors.danger),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return IBuildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          Text(
            body,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: colors.inkMuted),
          ),
        ],
      ),
    );
  }
}

class StatusText extends StatelessWidget {
  const StatusText({super.key, required this.label, required this.tone});

  final String label;
  final StatusTone tone;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final color = switch (tone) {
      StatusTone.neutral => colors.inkMuted,
      StatusTone.good => colors.success,
      StatusTone.wait => colors.warning,
      StatusTone.bad => colors.danger,
    };
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppSpacing.sm),
        Flexible(
          child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    );
  }
}

enum StatusTone { neutral, good, wait, bad }

final backLinkStyle = TextButton.styleFrom(
  padding: EdgeInsets.zero,
  minimumSize: Size.zero,
  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
  alignment: Alignment.centerLeft,
);

class ScreenScroll extends StatelessWidget {
  const ScreenScroll({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final inset = width >= kTabletBreakpoint
        ? AppSpacing.xxl
        : width >= kPhoneBreakpoint
            ? AppSpacing.xl
            : AppSpacing.lg;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(inset, inset, inset, AppSpacing.xxxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

/// Dialog fields stay on screen on a phone and do not stretch on a tablet.
double dialogFieldWidth(BuildContext context) {
  final available = MediaQuery.sizeOf(context).width - 96;
  if (available < 280) return 280;
  if (available > 420) return 420;
  return available;
}
