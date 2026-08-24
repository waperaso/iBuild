import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:ibuild_core/ibuild_core.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_theme_ext.dart';
import '../../core/widgets/app_network_image.dart';
import '../../core/widgets/pill_button.dart';
import '../../l10n/gen/app_localizations.dart';

/// Pipeline step index for [SitePhotoVerifyPipeline].
enum SitePhotoPipeStep { baseline, followUp, check, decision }

SitePhotoPipeStep sitePhotoPipeStepForStatus(String status) {
  return switch (status) {
    'awaiting_a' => SitePhotoPipeStep.baseline,
    // Waiting for the interval still points at the follow-up step (locked
    // until due) — no separate “pause” node in the pipeline.
    'waiting' || 'awaiting_b' => SitePhotoPipeStep.followUp,
    'analyzing' => SitePhotoPipeStep.check,
    'inspector' => SitePhotoPipeStep.decision,
    'confirmed' || 'rejected' || 'missed' => SitePhotoPipeStep.decision,
    _ => SitePhotoPipeStep.baseline,
  };
}

class SitePhotoStatusPill extends StatelessWidget {
  const SitePhotoStatusPill({super.key, required this.label, this.tone});

  final String label;
  final SitePhotoPillTone? tone;

  factory SitePhotoStatusPill.forStatus(
    AppLocalizations l10n,
    String status,
  ) {
    final label = switch (status) {
      'awaiting_a' => l10n.siteCycleStatusAwaitingA,
      'waiting' => l10n.siteCycleStatusWaiting,
      'awaiting_b' => l10n.siteCycleStatusAwaitingB,
      'inspector' => l10n.siteCycleStatusInspector,
      'analyzing' => l10n.siteCycleStatusAnalyzing,
      'confirmed' => l10n.siteCycleStatusConfirmed,
      'rejected' => l10n.siteCycleStatusRejected,
      'missed' => l10n.siteCycleStatusMissed,
      _ => status,
    };
    final tone = switch (status) {
      'confirmed' => SitePhotoPillTone.success,
      'rejected' || 'missed' => SitePhotoPillTone.danger,
      'inspector' || 'analyzing' => SitePhotoPillTone.accent,
      'waiting' => SitePhotoPillTone.muted,
      _ => SitePhotoPillTone.warning,
    };
    return SitePhotoStatusPill(label: label, tone: tone);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final t = tone ?? SitePhotoPillTone.warning;
    final (bg, fg) = switch (t) {
      SitePhotoPillTone.success => (
        colors.success.withValues(alpha: 0.14),
        colors.success,
      ),
      SitePhotoPillTone.danger => (
        colors.danger.withValues(alpha: 0.12),
        colors.danger,
      ),
      SitePhotoPillTone.accent => (
        colors.accent.withValues(alpha: 0.12),
        colors.accent,
      ),
      SitePhotoPillTone.muted => (
        colors.inkMuted.withValues(alpha: 0.1),
        colors.inkMuted,
      ),
      SitePhotoPillTone.warning => (
        colors.warning.withValues(alpha: 0.14),
        colors.warning,
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: fg,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

enum SitePhotoPillTone { warning, success, danger, accent, muted }

class SitePhotoProjectHeader extends StatelessWidget {
  const SitePhotoProjectHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.statusLabel,
    this.status,
  });

  final String title;
  final String subtitle;
  final String statusLabel;
  final String? status;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: colors.outline.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: colors.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.apartment_rounded, color: colors.accent),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                )),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    style: textTheme.bodySmall?.copyWith(color: colors.inkMuted),
                  ),
              ],
            ),
          ),
          if (status != null)
            SitePhotoStatusPill.forStatus(l10n, status!)
          else
            SitePhotoStatusPill(label: statusLabel),
        ],
      ),
    );
  }
}

class SitePhotoVerifyPipeline extends StatelessWidget {
  const SitePhotoVerifyPipeline({super.key, required this.active});

  final SitePhotoPipeStep active;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final steps = [
      (SitePhotoPipeStep.baseline, Icons.photo_camera_outlined, l10n.siteCyclePipeA),
      (SitePhotoPipeStep.followUp, Icons.cameraswitch_outlined, l10n.siteCyclePipeB),
      (SitePhotoPipeStep.check, Icons.shield_outlined, l10n.siteCyclePipeCheck),
      (SitePhotoPipeStep.decision, Icons.how_to_reg_outlined, l10n.siteCyclePipeDecision),
    ];
    final activeIdx = SitePhotoPipeStep.values.indexOf(active);

    return Row(
      children: [
        for (var i = 0; i < steps.length; i++) ...[
          if (i > 0)
            Expanded(
              child: Container(
                height: 2,
                margin: const EdgeInsets.only(bottom: 18),
                color: i <= activeIdx
                    ? colors.accent
                    : colors.outline.withValues(alpha: 0.35),
              ),
            ),
          _PipeNode(
            icon: steps[i].$2,
            label: steps[i].$3,
            done: i < activeIdx,
            on: i == activeIdx,
          ),
        ],
      ],
    );
  }
}

class _PipeNode extends StatelessWidget {
  const _PipeNode({
    required this.icon,
    required this.label,
    required this.done,
    required this.on,
  });

  final IconData icon;
  final String label;
  final bool done;
  final bool on;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final bg = on
        ? colors.accent
        : done
            ? colors.success.withValues(alpha: 0.16)
            : colors.surface;
    final fg = on
        ? colors.onAccent
        : done
            ? colors.success
            : colors.inkMuted;
    return SizedBox(
      width: 58,
      child: Column(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: bg,
              shape: BoxShape.circle,
              border: on || done
                  ? null
                  : Border.all(color: colors.outline.withValues(alpha: 0.7)),
            ),
            child: Icon(icon, size: 18, color: fg),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: on || done ? colors.ink : colors.inkMuted,
              fontWeight: on ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class SitePhotoSlotTile extends StatelessWidget {
  const SitePhotoSlotTile({
    super.key,
    required this.badge,
    required this.caption,
    this.photo,
    this.bytes,
    this.dimmed = false,
    this.placeholderDark = true,
  });

  final String badge;
  final String caption;
  final SitePhotoRef? photo;
  final ImageProvider? bytes;
  final bool dimmed;
  final bool placeholderDark;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final url = photo?.photoUrl;
    return Opacity(
      opacity: dimmed ? 0.55 : 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 4 / 3,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadii.md),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (bytes != null)
                    Image(image: bytes!, fit: BoxFit.cover)
                  else if (url != null && url.isNotEmpty)
                    AppNetworkImage(url: url, fit: BoxFit.cover)
                  else
                    ColoredBox(
                      color: placeholderDark
                          ? const Color(0xFF0A1F35)
                          : colors.surfaceAlt,
                      child: Icon(
                        Icons.image_outlined,
                        size: 36,
                        color: placeholderDark
                            ? Colors.white38
                            : colors.inkMuted,
                      ),
                    ),
                  Positioned(
                    left: 10,
                    bottom: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.94),
                        borderRadius: BorderRadius.circular(AppRadii.pill),
                      ),
                      child: Text(
                        badge,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colors.ink,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            caption,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colors.inkMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

String sitePhotoSlotCaption(
  AppLocalizations l10n,
  SitePhotoRef? photo, {
  required bool emptyWaiting,
}) {
  if (photo == null) {
    return emptyWaiting ? l10n.siteCycleSlotWaiting : l10n.siteCycleEmptySlot;
  }
  final raw = photo.takenAt.trim();
  if (raw.isEmpty) return l10n.siteCycleSlotUploaded;
  final parsed = DateTime.tryParse(raw);
  if (parsed == null) return '${l10n.siteCycleSlotUploaded} · $raw';
  return '${l10n.siteCycleSlotUploaded} · ${DateFormat.yMMMd().format(parsed.toLocal())}';
}

enum SitePhotoCheckTone { pending, pass, fail, warn }

class SitePhotoCheckRow {
  const SitePhotoCheckRow({
    required this.title,
    required this.detail,
    required this.tone,
  });

  final String title;
  final String detail;
  final SitePhotoCheckTone tone;
}

const _machineSummaries = {
  'photo checks passed.',
  'submitted for review.',
  'automated check failed. manual review required.',
  'automated check timed out. manual review required.',
  'photos could not be read for automated checks. manual review required.',
  'automated check returned an incomplete answer. manual review required.',
  'schema_invalid',
  'отправлено на проверку специалисту.',
  'автопроверка не удалась. нужна ручная проверка.',
  'автопроверка не успела завершиться. нужна ручная проверка.',
  'фото не удалось прочитать для автопроверки. нужна ручная проверка.',
  'автопроверка вернула неполный ответ. нужна ручная проверка.',
  'mutaxassis tekshiruviga yuborildi.',
  'avtotekshiruv muvaffaqiyatsiz. qo‘lda ko‘rish kerak.',
  'avtotekshiruv vaqti tugadi. qo‘lda ko‘rish kerak.',
  'fotolar avtotekshiruv uchun o‘qilmadi. qo‘lda ko‘rish kerak.',
  'avtotekshiruv to‘liq javob bermadi. qo‘lda ko‘rish kerak.',
};

bool _isMachineSummary(String? raw) {
  final text = raw?.trim().toLowerCase() ?? '';
  return text.isEmpty || _machineSummaries.contains(text);
}

List<String> _resultFlags(Map<String, dynamic>? result) {
  return ((result?['flags'] as List?) ?? const [])
      .map((e) => e.toString())
      .where((e) => e.isNotEmpty)
      .toList();
}

String sitePhotoFlagExplanation(AppLocalizations l10n, String flag) {
  return switch (flag) {
    'verify_error' => l10n.siteCycleFlagVerifyError,
    'documentation_gap' => l10n.siteCycleFlagDocumentationGap,
    'prompt_not_shipped' => l10n.siteCycleFlagVisionOff,
    'vision_disabled' => l10n.siteCycleFlagVisionOff,
    'images_unavailable' => l10n.siteCycleFlagImagesUnavailable,
    'possible_staging' => l10n.siteCycleFlagPossibleStaging,
    'image_unusable' => l10n.siteCycleFlagImageUnusable,
    'viewpoint_mismatch' => l10n.siteCycleFlagViewpointMismatch,
    'no_visible_progress' => l10n.siteCycleFlagNoProgress,
    'hidden_work_not_visible' => l10n.siteCycleFlagHiddenWork,
    'wrong_site' => l10n.siteCycleFlagWrongSite,
    'integrity_concern' => l10n.siteCycleFlagIntegrityConcern,
    'progress_implausible_for_interval' => l10n.siteCycleFlagProgressImplausible,
    'regulatory_escalation_recommended' => l10n.siteCycleFlagRegulatoryEscalation,
    'interval_too_short' => l10n.siteCycleFlagIntervalTooShort,
    'b_before_a' => l10n.siteCycleFlagDatesReversed,
    _ => l10n.siteCycleFlagGeneric,
  };
}

String sitePhotoHumanSummary(
  AppLocalizations l10n,
  String status,
  Map<String, dynamic>? result,
) {
  final flags = _resultFlags(result);
  if (status == 'analyzing') return l10n.siteCycleAnalyzeRunning;
  if (flags.contains('verify_error')) return l10n.siteCycleSummaryVisionFailed;
  if (flags.contains('images_unavailable')) {
    return l10n.siteCycleFlagImagesUnavailable;
  }
  if (flags.contains('vision_disabled') ||
      flags.contains('prompt_not_shipped')) {
    return l10n.siteCycleSummaryVisionOff;
  }
  final integrity = result?['integrity'];
  if (integrity is Map && integrity['passed'] == false) {
    return l10n.siteCycleSummaryIntegrityFailed;
  }
  if (status == 'confirmed') return l10n.siteCycleHintConfirmed;
  if (status == 'rejected') return l10n.siteCycleHintRejected;
  final raw = result?['summary']?.toString();
  if (!_isMachineSummary(raw)) return l10n.siteCycleSummaryReady;
  if (status == 'inspector' || status == 'analyzing') {
    return l10n.siteCycleSummaryReady;
  }
  return l10n.siteCycleSummaryReady;
}

List<SitePhotoCheckRow> sitePhotoCheckRows(
  AppLocalizations l10n,
  Map<String, dynamic>? result, {
  required bool analyzing,
}) {
  if (analyzing) {
    return [
      SitePhotoCheckRow(
        title: l10n.siteCycleCheckViewpoint,
        detail: l10n.siteCycleAnalyzeRunning,
        tone: SitePhotoCheckTone.pending,
      ),
      SitePhotoCheckRow(
        title: l10n.siteCycleCheckDates,
        detail: l10n.siteCycleAnalyzeRunning,
        tone: SitePhotoCheckTone.pending,
      ),
      SitePhotoCheckRow(
        title: l10n.siteCycleCheckProgress,
        detail: l10n.siteCycleAnalyzeRunning,
        tone: SitePhotoCheckTone.pending,
      ),
      SitePhotoCheckRow(
        title: l10n.siteCycleCheckNotes,
        detail: l10n.siteCycleAnalyzeRunning,
        tone: SitePhotoCheckTone.pending,
      ),
    ];
  }

  final flags = _resultFlags(result);
  final same = result?['sameViewpoint'];
  final viewpoint = switch (same) {
    true => SitePhotoCheckRow(
      title: l10n.siteCycleCheckViewpoint,
      detail: l10n.siteCycleCheckViewpointYes,
      tone: SitePhotoCheckTone.pass,
    ),
    false => SitePhotoCheckRow(
      title: l10n.siteCycleCheckViewpoint,
      detail: l10n.siteCycleCheckViewpointNo,
      tone: SitePhotoCheckTone.fail,
    ),
    _ => SitePhotoCheckRow(
      title: l10n.siteCycleCheckViewpoint,
      detail: l10n.siteCycleCheckViewpointUnknown,
      tone: flags.contains('verify_error')
          ? SitePhotoCheckTone.warn
          : SitePhotoCheckTone.pending,
    ),
  };

  final temporal = result?['temporal'];
  final datesOk = temporal is Map ? temporal['ok'] : null;
  final dates = switch (datesOk) {
    true => SitePhotoCheckRow(
      title: l10n.siteCycleCheckDates,
      detail: l10n.siteCycleCheckDatesYes,
      tone: SitePhotoCheckTone.pass,
    ),
    false => SitePhotoCheckRow(
      title: l10n.siteCycleCheckDates,
      detail: l10n.siteCycleCheckDatesNo,
      tone: SitePhotoCheckTone.fail,
    ),
    _ => SitePhotoCheckRow(
      title: l10n.siteCycleCheckDates,
      detail: l10n.siteCycleCheckDatesUnknown,
      tone: SitePhotoCheckTone.pending,
    ),
  };

  final deltaRaw = result?['progressDelta'];
  final SitePhotoCheckRow progress;
  if (deltaRaw is num) {
    final rounded = deltaRaw.round();
    final label = rounded > 0 ? '+$rounded' : '$rounded';
    progress = SitePhotoCheckRow(
      title: l10n.siteCycleCheckProgress,
      detail: l10n.siteCycleCheckProgressValue(label),
      tone: rounded > 0
          ? SitePhotoCheckTone.pass
          : SitePhotoCheckTone.warn,
    );
  } else if (flags.contains('no_visible_progress')) {
    progress = SitePhotoCheckRow(
      title: l10n.siteCycleCheckProgress,
      detail: l10n.siteCycleCheckProgressNone,
      tone: SitePhotoCheckTone.warn,
    );
  } else {
    progress = SitePhotoCheckRow(
      title: l10n.siteCycleCheckProgress,
      detail: l10n.siteCycleCheckProgressUnknown,
      tone: SitePhotoCheckTone.pending,
    );
  }

  final explain = flags.map((f) => sitePhotoFlagExplanation(l10n, f)).toSet();
  final notes = SitePhotoCheckRow(
    title: l10n.siteCycleCheckNotes,
    detail: explain.isEmpty
        ? l10n.siteCycleCheckNotesNone
        : explain.join('\n'),
    tone: explain.isEmpty
        ? SitePhotoCheckTone.pass
        : flags.any((f) => f == 'verify_error' || f == 'possible_staging' || f == 'wrong_site')
            ? SitePhotoCheckTone.warn
            : SitePhotoCheckTone.warn,
  );

  return [viewpoint, dates, progress, notes];
}

class SitePhotoAnalyzeCard extends StatefulWidget {
  const SitePhotoAnalyzeCard({super.key});

  @override
  State<SitePhotoAnalyzeCard> createState() => _SitePhotoAnalyzeCardState();
}

class _SitePhotoAnalyzeCardState extends State<SitePhotoAnalyzeCard> {
  int _active = 0;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(milliseconds: 700), (_) {
      if (!mounted) return;
      setState(() => _active = (_active + 1) % 4);
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
    final rows = sitePhotoCheckRows(l10n, null, analyzing: true);
    return _VerifyPanel(
      icon: Icons.shield_outlined,
      title: l10n.siteCycleAnalyzeTitle,
      subtitle: l10n.siteCycleAnalyzeRunning,
      progress: true,
      rows: [
        for (var i = 0; i < rows.length; i++)
          SitePhotoCheckRow(
            title: rows[i].title,
            detail: rows[i].detail,
            tone: i <= _active
                ? SitePhotoCheckTone.pass
                : SitePhotoCheckTone.pending,
          ),
      ],
    );
  }
}

class SitePhotoInspectResultCard extends StatelessWidget {
  const SitePhotoInspectResultCard({
    super.key,
    required this.status,
    required this.result,
    this.verifyExport,
  });

  final String status;
  final Map<String, dynamic>? result;
  final Map<String, dynamic>? verifyExport;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final raw = result?['summary']?.toString();
    final showMarkdown = !_isMachineSummary(raw);
    return _VerifyPanel(
      icon: Icons.how_to_reg_outlined,
      title: l10n.siteCycleResultTitle,
      subtitle: sitePhotoHumanSummary(l10n, status, result),
      progress: false,
      leading: SitePhotoVerdictChip(result: result),
      extra: [
        if (showMarkdown) ...[
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: colors.surfaceAlt,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colors.outline.withValues(alpha: 0.35)),
            ),
            child: MarkdownBody(
              data: raw!.trim(),
              selectable: true,
              styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                p: textTheme.bodyMedium?.copyWith(height: 1.5, color: colors.ink),
                pPadding: const EdgeInsets.only(bottom: 2),
                h2: textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: colors.accent,
                  letterSpacing: 0.2,
                ),
                h2Padding: const EdgeInsets.only(top: 14, bottom: 2),
                h3: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                h3Padding: const EdgeInsets.only(top: 10, bottom: 2),
                listBullet: textTheme.bodyMedium?.copyWith(color: colors.ink),
                listBulletPadding: const EdgeInsets.only(right: 8),
                listIndent: 20,
                blockSpacing: 6,
                strong: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: colors.ink,
                ),
              ),
            ),
          ),
        ],
        if (verifyExport != null) ...[
          const SizedBox(height: AppSpacing.md),
          Align(
            alignment: Alignment.centerLeft,
            child: PillButton(
              label: l10n.siteCycleGetJson,
              icon: Icons.data_object_outlined,
              variant: PillButtonVariant.outline,
              onPressed: () => showSitePhotoVerifyJsonDialog(
                context,
                verifyExport!,
              ),
            ),
          ),
        ],
      ],
      rows: sitePhotoCheckRows(l10n, result, analyzing: false),
    );
  }
}

class SitePhotoVerdictChip extends StatelessWidget {
  const SitePhotoVerdictChip({super.key, required this.result});

  final Map<String, dynamic>? result;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final raw = (result?['vendorVerdict'] ?? result?['verdict'])?.toString();
    final (label, tone) = switch (raw) {
      'confirm' => (l10n.siteCycleVerdictConfirm, SitePhotoPillTone.success),
      'reject' => (l10n.siteCycleVerdictReject, SitePhotoPillTone.danger),
      'needs_review' => (l10n.siteCycleVerdictReview, SitePhotoPillTone.warning),
      _ => (null, SitePhotoPillTone.muted),
    };
    if (label == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: SitePhotoStatusPill(label: label, tone: tone),
    );
  }
}

Future<void> showSitePhotoVerifyJsonDialog(
  BuildContext context,
  Map<String, dynamic> export,
) {
  final l10n = AppLocalizations.of(context);
  final pretty = const JsonEncoder.withIndent('  ').convert(export);
  return showDialog<void>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        title: Text(l10n.siteCycleGetJsonTitle),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: SelectableText(
              pretty,
              style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
                height: 1.4,
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: pretty));
              if (ctx.mounted) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(content: Text(l10n.siteCycleCopied)),
                );
              }
            },
            child: Text(l10n.siteCycleCopyJson),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(MaterialLocalizations.of(ctx).closeButtonLabel),
          ),
        ],
      );
    },
  );
}

class _VerifyPanel extends StatelessWidget {
  const _VerifyPanel({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.progress,
    required this.rows,
    this.leading,
    this.extra,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool progress;
  final List<SitePhotoCheckRow> rows;
  final Widget? leading;
  final List<Widget>? extra;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.outline.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ?leading,
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: colors.accent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 18, color: colors.onAccent),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: textTheme.bodySmall?.copyWith(
                        color: colors.ink,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (progress) ...[
            const SizedBox(height: AppSpacing.md),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadii.pill),
              child: LinearProgressIndicator(
                minHeight: 8,
                backgroundColor: colors.ink.withValues(alpha: 0.08),
                color: colors.accent,
              ),
            ),
          ],
          ...?extra,
          const SizedBox(height: AppSpacing.md),
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.sm),
            _CheckTile(row: rows[i]),
          ],
        ],
      ),
    );
  }
}

class _CheckTile extends StatelessWidget {
  const _CheckTile({required this.row});

  final SitePhotoCheckRow row;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final (Color bg, Color fg, IconData icon) = switch (row.tone) {
      SitePhotoCheckTone.pass => (
        colors.success.withValues(alpha: 0.1),
        colors.success,
        Icons.check_circle_outline,
      ),
      SitePhotoCheckTone.fail => (
        colors.danger.withValues(alpha: 0.1),
        colors.danger,
        Icons.highlight_off,
      ),
      SitePhotoCheckTone.warn => (
        colors.warning.withValues(alpha: 0.12),
        colors.warning,
        Icons.info_outline,
      ),
      SitePhotoCheckTone.pending => (
        colors.ink.withValues(alpha: 0.04),
        colors.inkMuted,
        Icons.radio_button_unchecked,
      ),
    };
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: fg),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.title,
                  style: textTheme.labelLarge?.copyWith(
                    color: row.tone == SitePhotoCheckTone.pending
                        ? colors.inkMuted
                        : colors.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  row.detail,
                  style: textTheme.bodySmall?.copyWith(
                    color: colors.ink,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
