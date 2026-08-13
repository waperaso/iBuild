part of 'project_detail_admin.dart';

/// Result of the AI readiness check flow (`_runReadinessCheck`): whether the
/// caller should proceed with the real `uploadPhotoReport` call, and — for a
/// blocked ("Всё равно загрузить") override — the required comment to send
/// along with it.
class _ReadinessOutcome {
  const _ReadinessOutcome({required this.comment});
  final String? comment;
}

/// Non-dismissible "checking with AI" spinner shown while
/// `analyzePhotoReport` is in flight.
class _AnalyzingDialog extends StatelessWidget {
  const _AnalyzingDialog();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
      content: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2.4),
          ),
          const SizedBox(width: AppSpacing.md),
          Flexible(child: Text(l10n.readinessAnalyzing)),
        ],
      ),
    );
  }
}

/// Shown when `analyzePhotoReport` itself fails (network error, or the
/// engine still returning 501 while the server sibling ships it). Never a
/// dead end — the developer can proceed with the plain upload, unchecked.
class _ReadinessUnavailableDialog extends StatelessWidget {
  const _ReadinessUnavailableDialog();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
      title: Text(l10n.readinessUnavailableTitle),
      content: Text(l10n.readinessUnavailableMessage),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n.commonCancel),
        ),
        PillButton(
          label: l10n.readinessProceedWithoutCheck,
          onPressed: () => Navigator.pop(context, true),
        ),
      ],
    );
  }
}

/// Stage-by-stage stepper dialog rendering `checks[]` from
/// `analyzePhotoReport`'s response, gated by `overall_status` (plan Part 4):
/// `confirmed` auto-proceeds after a brief success flash, `requires_manual_review`
/// proceeds behind an acknowledgement, `discrepancy_found`/`violation_found`
/// block the upload behind "Переснять" / a commented override.
class _VerificationResultDialog extends StatefulWidget {
  const _VerificationResultDialog({required this.analysis});
  final Map<String, dynamic> analysis;

  @override
  State<_VerificationResultDialog> createState() =>
      _VerificationResultDialogState();
}

class _VerificationResultDialogState
    extends State<_VerificationResultDialog> {
  final _commentController = TextEditingController();
  bool _autoProceeded = false;

  String get _overallStatus =>
      widget.analysis['overall_status']?.toString() ?? '';

  @override
  void initState() {
    super.initState();
    if (_overallStatus == 'confirmed') {
      Future.delayed(const Duration(milliseconds: 1100), () {
        if (mounted && !_autoProceeded) _proceed(null);
      });
    }
    _commentController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _proceed(String? comment) {
    if (_autoProceeded) return;
    _autoProceeded = true;
    Navigator.pop(context, _ReadinessOutcome(comment: comment));
  }

  void _reshoot() => Navigator.pop(context, null);

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final analysis = widget.analysis;
    final checks = (analysis['checks'] as List? ?? const [])
        .cast<Map>()
        .map((c) => c.cast<String, dynamic>())
        .toList();
    final confidence = (analysis['confidence'] as num?)?.toDouble();
    final blocked =
        _overallStatus == 'discrepancy_found' ||
        _overallStatus == 'violation_found';
    final statusColor = switch (_overallStatus) {
      'confirmed' => colors.success,
      'requires_manual_review' => colors.warning,
      'discrepancy_found' || 'violation_found' => colors.danger,
      _ => colors.inkMuted,
    };
    final summary = localizeVerificationCode(
      l10n,
      analysis['summaryCode']?.toString(),
      (analysis['summaryParams'] as Map?)?.cast<String, dynamic>(),
      analysis['summary_for_buyer']?.toString(),
    );

    return Dialog(
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 640),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.assistant_outlined, color: colors.accent),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      l10n.readinessCheckDialogTitle,
                      style: textTheme.titleLarge,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadii.input),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        readinessStatusLabel(l10n, _overallStatus),
                        style: textTheme.titleSmall?.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (confidence != null)
                      Text(
                        l10n.readinessConfidenceLabel(
                          (confidence * 100).round(),
                        ),
                        style: textTheme.labelSmall?.copyWith(
                          color: colors.inkMuted,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(summary, style: textTheme.bodyMedium),
              const SizedBox(height: AppSpacing.md),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final check in checks) _CheckRow(check: check),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              if (blocked) ...[
                TextField(
                  controller: _commentController,
                  minLines: 2,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: l10n.readinessOverrideCommentLabel,
                    hintText: l10n.readinessOverrideCommentHint,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: _reshoot,
                        child: Text(l10n.readinessReshoot),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: PillButton(
                        label: l10n.readinessOverrideUpload,
                        onPressed: _commentController.text.trim().isEmpty
                            ? null
                            : () => _proceed(_commentController.text.trim()),
                      ),
                    ),
                  ],
                ),
              ] else if (_overallStatus == 'requires_manual_review') ...[
                Align(
                  alignment: Alignment.centerRight,
                  child: PillButton(
                    label: l10n.readinessAckAndUpload,
                    onPressed: () => _proceed(null),
                  ),
                ),
              ] else if (_overallStatus == 'confirmed') ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Icon(Icons.check_circle, color: colors.success, size: 18),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      l10n.readinessConfirmedProceeding,
                      style: textTheme.bodySmall?.copyWith(
                        color: colors.success,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CheckRow extends StatelessWidget {
  const _CheckRow({required this.check});
  final Map<String, dynamic> check;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    // `checks[].status` is `passed | failed | warning` (see
    // `ReadinessCheck.status` in `readiness_engine.dart`), not `pass`/`fail`.
    final status = check['status']?.toString();
    final (icon, color) = switch (status) {
      'passed' => (Icons.check_circle, colors.success),
      'warning' => (Icons.warning_amber_rounded, colors.warning),
      'failed' => (Icons.cancel, colors.danger),
      _ => (Icons.circle_outlined, colors.inkMuted),
    };
    final finding = localizeVerificationCode(
      l10n,
      check['findingCode']?.toString(),
      (check['findingParams'] as Map?)?.cast<String, dynamic>(),
      check['finding']?.toString(),
    );
    final evidence = localizeVerificationCode(
      l10n,
      check['evidenceCode']?.toString(),
      (check['evidenceParams'] as Map?)?.cast<String, dynamic>(),
      check['evidence']?.toString(),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  check['name']?.toString() ?? '',
                  style: textTheme.titleSmall,
                ),
                if (finding.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(finding, style: textTheme.bodySmall),
                  ),
                if (evidence.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      evidence,
                      style: textTheme.labelSmall?.copyWith(
                        color: colors.inkMuted,
                      ),
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

/// Per-project "AI consultant on objects" readiness digest (plan Part 4):
/// the latest verification status per report, a rolling trend across the
/// last 5 reports, and any outstanding items needing attention. Computed
/// client-side from [reports] (`projectPhotoReports`) — reports without a
/// `verificationStatus` (pre-AI or engine not shipped yet) are ignored, and
/// the whole section quietly renders as an empty note rather than an error.
class _ReadinessDigest extends StatelessWidget {
  const _ReadinessDigest({required this.reports});
  final List<Map<String, dynamic>> reports;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    final withStatus = reports
        .where((r) => r['verificationStatus'] != null)
        .toList();
    if (withStatus.isEmpty) {
      return AppCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Icon(Icons.assistant_outlined, color: colors.inkMuted, size: 18),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                l10n.readinessDigestEmpty,
                style: textTheme.bodySmall?.copyWith(color: colors.inkMuted),
              ),
            ),
          ],
        ),
      );
    }

    final recent = withStatus.take(5).toList();
    final confirmedCount = recent
        .where((r) => r['verificationStatus'] == 'confirmed')
        .length;
    final outstanding = withStatus
        .where(
          (r) =>
              r['verificationStatus'] == 'requires_manual_review' ||
              r['verificationStatus'] == 'violation_found' ||
              r['verificationStatus'] == 'discrepancy_found',
        )
        .take(5)
        .toList();

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.assistant_outlined, color: colors.accent, size: 18),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  l10n.readinessDigestTitle,
                  style: textTheme.titleSmall,
                ),
              ),
              const AiMarkBadge(),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.readinessDigestTrend(confirmedCount, recent.length),
            style: textTheme.bodyMedium,
          ),
          if (outstanding.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.readinessDigestOutstandingTitle,
              style: textTheme.labelLarge,
            ),
            const SizedBox(height: AppSpacing.xs),
            for (final report in outstanding)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Row(
                  children: [
                    Icon(
                      Icons.priority_high,
                      size: 14,
                      color: colors.warning,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        readinessStatusLabel(
                          l10n,
                          report['verificationStatus'].toString(),
                        ),
                        style: textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}
