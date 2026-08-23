import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_theme_ext.dart';
import '../../l10n/gen/app_localizations.dart';

/// Full-screen verify UI so the check does not look pre-baked.
class SitePhotoVerifyOverlay extends StatefulWidget {
  const SitePhotoVerifyOverlay({
    super.key,
    required this.done,
    this.minVisible = const Duration(seconds: 5),
  });

  /// Completes when the server leaves `analyzing`.
  final Future<void> done;
  final Duration minVisible;

  @override
  State<SitePhotoVerifyOverlay> createState() => _SitePhotoVerifyOverlayState();
}

class _SitePhotoVerifyOverlayState extends State<SitePhotoVerifyOverlay> {
  int _step = 0;
  Timer? _ticker;
  var _jobDone = false;
  late final DateTime _started;

  static const _stepCount = 5;

  @override
  void initState() {
    super.initState();
    _started = DateTime.now();
    _ticker = Timer.periodic(const Duration(milliseconds: 900), (_) {
      if (!mounted) return;
      setState(() {
        if (_step < _stepCount - 1) _step += 1;
      });
    });
    widget.done.then((_) {
      _jobDone = true;
      _maybeClose();
    });
  }

  void _maybeClose() {
    if (!mounted || !_jobDone) return;
    final elapsed = DateTime.now().difference(_started);
    final wait = widget.minVisible - elapsed;
    Future<void>.delayed(wait.isNegative ? Duration.zero : wait, () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final steps = [
      l10n.siteCycleOverlayStepRead,
      l10n.siteCycleOverlayStepView,
      l10n.siteCycleOverlayStepDates,
      l10n.siteCycleOverlayStepProgress,
      l10n.siteCycleOverlayStepNotes,
    ];

    return Material(
      color: colors.ink.withValues(alpha: 0.72),
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.siteCycleOverlayTitle,
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        l10n.siteCycleOverlaySubtitle,
                        style: textTheme.bodyMedium?.copyWith(
                          color: colors.inkMuted,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadii.pill),
                        child: LinearProgressIndicator(
                          minHeight: 8,
                          backgroundColor: colors.ink.withValues(alpha: 0.08),
                          color: colors.accent,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      for (var i = 0; i < steps.length; i++) ...[
                        if (i > 0) const SizedBox(height: AppSpacing.sm),
                        _OverlayStep(
                          label: steps[i],
                          active: i == _step && !_jobDone,
                          done: i < _step || (_jobDone && i <= _step),
                        ),
                      ],
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

class _OverlayStep extends StatelessWidget {
  const _OverlayStep({
    required this.label,
    required this.active,
    required this.done,
  });

  final String label;
  final bool active;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final icon = done
        ? Icons.check_circle
        : active
        ? Icons.timelapse
        : Icons.radio_button_unchecked;
    final color = done
        ? colors.success
        : active
        ? colors.accent
        : colors.inkMuted;
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: active || done ? colors.ink : colors.inkMuted,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
