part of 'project_detail_admin.dart';

/// Result of [_PhotoReportDetailsDialog]: the date a photo was taken plus an
/// optional construction-progress percentage to tag onto the upload (Track
/// B.4, matches the Photo Reports API's `takenAt`/`progressPercent` fields),
/// plus the declared construction stage the AI readiness check (plan Part 4)
/// verifies the photo against.
class _PhotoReportSpec {
  const _PhotoReportSpec({
    required this.takenAt,
    required this.declaredStage,
    this.progressPercent,
  });

  final DateTime takenAt;
  final String declaredStage;
  final int? progressPercent;
}

/// Collects the date, declared construction stage, and optional progress
/// percent before the file (already picked by the caller) goes through the
/// AI readiness check and then the upload.
class _PhotoReportDetailsDialog extends StatefulWidget {
  const _PhotoReportDetailsDialog();

  @override
  State<_PhotoReportDetailsDialog> createState() =>
      _PhotoReportDetailsDialogState();
}

class _PhotoReportDetailsDialogState
    extends State<_PhotoReportDetailsDialog> {
  DateTime _takenAt = DateTime.now();
  String _declaredStage = kReadinessStages.first;
  final _progress = TextEditingController();

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _takenAt,
      firstDate: DateTime(2015),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _takenAt = picked);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    final dateFormat = DateFormat.yMMMd(
      Localizations.localeOf(context).toString(),
    );

    return AlertDialog(
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
      title: Text(l10n.projectPhotoReportDialogTitle),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(AppRadii.input),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: l10n.projectPhotoReportDateLabel,
                  suffixIcon: const Icon(Icons.calendar_today_outlined),
                ),
                child: Text(dateFormat.format(_takenAt)),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<String>(
              initialValue: _declaredStage,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: l10n.projectPhotoReportDeclaredStageLabel,
              ),
              items: [
                for (final stage in kReadinessStages)
                  DropdownMenuItem(
                    value: stage,
                    child: Text(readinessStageLabel(l10n, stage)),
                  ),
              ],
              onChanged: (value) =>
                  setState(() => _declaredStage = value ?? _declaredStage),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _progress,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(3),
              ],
              decoration: InputDecoration(
                labelText: l10n.projectPhotoReportProgressLabel,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.commonCancel),
        ),
        PillButton(
          label: l10n.commonAdd,
          onPressed: () {
            final progress = int.tryParse(_progress.text.trim())?.clamp(0, 100);
            Navigator.pop(
              context,
              _PhotoReportSpec(
                takenAt: _takenAt,
                declaredStage: _declaredStage,
                progressPercent: progress,
              ),
            );
          },
        ),
      ],
    );
  }
}

/// Renders [reports] (already newest-first per the Photo Reports API
/// contract) grouped by calendar month, each month as its own subsection of
/// thumbnail tiles.
class _PhotoReportsByMonth extends StatelessWidget {
  const _PhotoReportsByMonth({required this.reports, required this.onDelete});

  final List<Map<String, dynamic>> reports;
  final void Function(String id) onDelete;

  Map<String, List<Map<String, dynamic>>> _groupByMonth() {
    final groups = <String, List<Map<String, dynamic>>>{};
    for (final report in reports) {
      final takenAt =
          DateTime.tryParse(report['takenAt']?.toString() ?? '') ??
          DateTime.now();
      final key = '${takenAt.year}-${takenAt.month.toString().padLeft(2, '0')}';
      groups.putIfAbsent(key, () => []).add(report);
    }
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final groups = _groupByMonth();
    final monthFormat = DateFormat.yMMMM(
      Localizations.localeOf(context).toString(),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final entry in groups.entries) ...[
          Text(
            monthFormat.format(
              DateTime(
                int.parse(entry.key.split('-')[0]),
                int.parse(entry.key.split('-')[1]),
              ),
            ),
            style: textTheme.titleSmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: [
              for (final report in entry.value)
                _PhotoReportTile(
                  report: report,
                  onDelete: () => onDelete(report['id'] as String),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ],
    );
  }
}

class _PhotoReportTile extends StatelessWidget {
  const _PhotoReportTile({required this.report, required this.onDelete});

  final Map<String, dynamic> report;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    final url = Env.resolveUrl(report['photoUrl']?.toString());
    final progress = (report['progressPercent'] as num?)?.round();
    final takenAt =
        DateTime.tryParse(report['takenAt']?.toString() ?? '') ?? DateTime.now();
    final verificationStatus = report['verificationStatus']?.toString();
    final verificationColor = switch (verificationStatus) {
      'confirmed' => colors.success,
      'requires_manual_review' => colors.warning,
      'discrepancy_found' || 'violation_found' => colors.danger,
      _ => null,
    };

    return SizedBox(
      width: 160,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadii.sm),
                child: GestureDetector(
                  onTap: url == null
                      ? null
                      : () => launchUrl(
                          Uri.parse(url),
                          mode: LaunchMode.externalApplication,
                        ),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: url == null
                        ? Container(color: colors.surfaceAlt)
                        : AppNetworkImage(
                            url: report['photoUrl']?.toString(),
                            width: double.infinity,
                            height: double.infinity,
                            memCacheWidth: 400,
                            memCacheHeight: 400,
                          ),
                  ),
                ),
              ),
              if (progress != null)
                Positioned(
                  left: 6,
                  bottom: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: colors.ink.withValues(alpha: 0.72),
                      borderRadius: BorderRadius.circular(AppRadii.pill),
                    ),
                    child: Text(
                      l10n.projectPhotoReportProgressBadge(progress),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colors.surface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              Positioned(
                right: 2,
                top: 2,
                child: Material(
                  color: colors.surface.withValues(alpha: 0.85),
                  shape: const CircleBorder(),
                  clipBehavior: Clip.antiAlias,
                  child: IconButton(
                    tooltip: l10n.projectPhotoReportDeleteTooltip,
                    iconSize: 16,
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(),
                    onPressed: onDelete,
                    icon: const Icon(Icons.close),
                  ),
                ),
              ),
              if (verificationColor != null)
                Positioned(
                  left: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: verificationColor.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(AppRadii.pill),
                    ),
                    child: Text(
                      readinessStatusLabel(l10n, verificationStatus!),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colors.surface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            DateFormat.yMMMd(
              Localizations.localeOf(context).toString(),
            ).format(takenAt),
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: colors.inkMuted),
          ),
        ],
      ),
    );
  }
}
