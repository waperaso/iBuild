import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ibuild_core/ibuild_core.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_theme_ext.dart';
import '../../core/widgets/pill_button.dart';
import '../../core/widgets/section_header.dart';
import '../../l10n/gen/app_localizations.dart';
import '../admin/admin_api.dart';
import 'site_photo_library_picker.dart';
import 'site_photo_test_library.dart';
import 'site_photo_verify_chrome.dart';
import 'site_photo_verify_overlay.dart';

class SitePhotoCycleCard extends ConsumerStatefulWidget {
  const SitePhotoCycleCard({
    super.key,
    required this.projectId,
    this.showIntro = true,
  });

  final String projectId;

  /// When false, skips the page-level title/subtitle (dedicated photos screen
  /// already provides them).
  final bool showIntro;

  @override
  ConsumerState<SitePhotoCycleCard> createState() => _SitePhotoCycleCardState();
}

class _SitePhotoCycleCardState extends ConsumerState<SitePhotoCycleCard> {
  SitePhotoCycle? _cycle;
  String? _error;
  bool _loading = true;
  bool _uploading = false;
  double _uploadProgress = 0;
  Timer? _ticker;
  Duration _remaining = Duration.zero;
  Duration _lockRemaining = Duration.zero;
  var _overlayOpen = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String get _uiLanguage =>
      Localizations.localeOf(context).languageCode;

  void _syncTicker(SitePhotoCycle cycle) {
    _ticker?.cancel();
    _ticker = null;
    _syncLock(cycle);
    if (cycle.status == 'analyzing') {
      _showVerifyOverlay();
      _ticker = Timer.periodic(const Duration(seconds: 2), (_) async {
        if (!mounted) return;
        try {
          final next = await ref
              .read(adminApiProvider)
              .sitePhotoCycle(widget.projectId);
          if (!mounted) return;
          setState(() => _cycle = next);
          _syncLock(next);
          if (next.status != 'analyzing') {
            _syncTicker(next);
          }
        } catch (_) {}
      });
      return;
    }
    if (cycle.status != 'waiting' || cycle.dueAt == null) {
      _remaining = Duration.zero;
      if (cycle.isReuploadLocked) {
        _startLockTicker(cycle);
      }
      return;
    }
    void tick() {
      final due = cycle.dueAt!.toUtc();
      final left = due.difference(DateTime.now().toUtc());
      if (!mounted) return;
      if (left <= Duration.zero) {
        _ticker?.cancel();
        _ticker = null;
        setState(() => _remaining = Duration.zero);
        _reload();
        return;
      }
      setState(() => _remaining = left);
    }

    tick();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      tick();
      _syncLock(cycle);
    });
  }

  void _syncLock(SitePhotoCycle cycle) {
    final until = cycle.reuploadLockedUntil?.toUtc();
    if (until == null) {
      _lockRemaining = Duration.zero;
      return;
    }
    final left = until.difference(DateTime.now().toUtc());
    _lockRemaining = left.isNegative ? Duration.zero : left;
  }

  void _startLockTicker(SitePhotoCycle cycle) {
    _ticker?.cancel();
    void tick() {
      if (!mounted) return;
      _syncLock(cycle);
      if (_lockRemaining <= Duration.zero) {
        _ticker?.cancel();
        _ticker = null;
        _reload();
        return;
      }
      setState(() {});
    }

    tick();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => tick());
  }

  Future<void> _showVerifyOverlay() async {
    if (_overlayOpen || !mounted) return;
    _overlayOpen = true;
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      pageBuilder: (ctx, _, _) {
        return SitePhotoVerifyOverlay(
          done: () async {
            while (mounted) {
              try {
                final next = await ref
                    .read(adminApiProvider)
                    .sitePhotoCycle(widget.projectId);
                if (!mounted) return;
                _cycle = next;
                if (next.status != 'analyzing') return;
              } catch (_) {}
              await Future<void>.delayed(const Duration(seconds: 2));
            }
          }(),
        );
      },
    );
    _overlayOpen = false;
    if (mounted) setState(() {});
  }

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final cycle = await ref
          .read(adminApiProvider)
          .sitePhotoCycle(widget.projectId);
      if (!mounted) return;
      setState(() => _cycle = cycle);
      _syncTicker(cycle);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  bool _isTooEarly(Object error) {
    if (error is! DioException) return false;
    final data = error.response?.data;
    if (data is Map) {
      final code = data['error'] is Map ? data['error']['code'] : data['code'];
      return code == 'TOO_EARLY';
    }
    return false;
  }

  Future<void> _uploadA() async {
    final picked = await showSitePhotoLibraryPicker(context, ref);
    if (picked == null || !mounted) return;
    final takenAt = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2018),
      lastDate: DateTime.now(),
    );
    if (takenAt == null || !mounted) return;
    await _applyLibraryPick(slot: 'a', pick: picked, takenAt: takenAt);
  }

  Future<void> _openUploadB() async {
    final cycle = _cycle;
    if (cycle?.photoA == null) return;
    final picked = await showSitePhotoLibraryPicker(
      context,
      ref,
      referencePhoto: cycle!.photoA,
    );
    if (picked == null || !mounted) return;
    final takenAt = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2018),
      lastDate: DateTime.now(),
    );
    if (takenAt == null || !mounted) return;
    await _applyLibraryPick(slot: 'b', pick: picked, takenAt: takenAt);
  }

  Future<void> _applyLibraryPick({
    required String slot,
    required SitePhotoLibraryPick pick,
    required DateTime takenAt,
  }) async {
    if (DemoSession.isActive &&
        pick.demoSampleFile != null &&
        pick.entry.kind == SitePhotoLibraryKind.builtin) {
      await _attachDemo(slot, sampleFile: pick.demoSampleFile);
      return;
    }
    final bytes = pick.bytes;
    final filename = pick.filename;
    if (bytes == null || filename == null) return;
    await _send(
      slot: slot,
      bytes: bytes,
      filename: filename,
      takenAt: takenAt,
    );
  }

  Future<void> _attachDemo(String slot, {String? sampleFile}) async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _uploading = true;
      _uploadProgress = 0;
    });
    try {
      final cycle = await ref.read(adminApiProvider).attachDemoSitePhotoSlot(
        widget.projectId,
        slot: slot,
        userLanguage: _uiLanguage,
        sampleFile: sampleFile,
      );
      if (!mounted) return;
      setState(() => _cycle = cycle);
      _syncTicker(cycle);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.siteCycleUploadError('$e'))),
      );
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _send({
    required String slot,
    required Uint8List bytes,
    required String filename,
    required DateTime takenAt,
  }) async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _uploading = true;
      _uploadProgress = 0;
    });
    try {
      final cycle = await ref
          .read(adminApiProvider)
          .uploadSitePhotoCycleSlot(
            widget.projectId,
            slot: slot,
            bytes: bytes,
            filename: filename,
            takenAt: takenAt,
            userLanguage: _uiLanguage,
            onSendProgress: (sent, total) {
              if (!mounted || total <= 0) return;
              setState(() => _uploadProgress = sent / total);
            },
          );
      if (!mounted) return;
      setState(() => _cycle = cycle);
      _syncTicker(cycle);
    } catch (e) {
      if (!mounted) return;
      if (_isTooEarly(e)) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.siteCycleTooEarly)));
        await _reload();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.siteCycleUploadError('$e'))),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  String _statusLabel(AppLocalizations l10n, String status) => switch (status) {
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

  String _hint(AppLocalizations l10n, SitePhotoCycle cycle) {
    switch (cycle.status) {
      case 'waiting':
        if (_remaining > Duration.zero) {
          return l10n.siteCycleCountdown(_formatRemaining(_remaining));
        }
        final due = cycle.dueAt;
        if (due != null) {
          return l10n.siteCycleLockedUntil(DateFormat.yMMMd().format(due.toLocal()));
        }
        return l10n.siteCycleTooEarly;
      case 'awaiting_b':
        return l10n.siteCycleWindowOpen;
      case 'analyzing':
        return l10n.siteCycleAnalyzingHint;
      case 'inspector':
        return l10n.siteCycleHintInspector;
      case 'missed':
        return l10n.siteCycleMissedHint;
      case 'confirmed':
        return l10n.siteCycleHintConfirmed;
      case 'rejected':
        return l10n.siteCycleHintRejected;
      default:
        return l10n.siteCycleAwaitingA;
    }
  }

  String _formatRemaining(Duration d) {
    final days = d.inDays;
    final hours = d.inHours % 24;
    final mins = d.inMinutes % 60;
    final secs = d.inSeconds % 60;
    if (days > 0) return '${days}d ${hours}h';
    if (hours > 0) return '${hours}h ${mins}m';
    if (mins > 0) return '${mins}m ${secs.toString().padLeft(2, '0')}s';
    return '${secs}s';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final cycle = _cycle;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showIntro) ...[
          SectionHeader(title: l10n.siteCycleTitle),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.siteCycleSubtitle,
            style: textTheme.bodySmall?.copyWith(color: colors.inkMuted),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        if (_loading)
          const LinearProgressIndicator()
        else if (_error != null)
          Text(_error!, style: textTheme.bodySmall)
        else if (cycle != null) ...[
          SitePhotoProjectHeader(
            title: cycle.projectName?.trim().isNotEmpty == true
                ? cycle.projectName!
                : l10n.siteCycleTitle,
            subtitle: [
              if (cycle.developerName?.trim().isNotEmpty == true)
                cycle.developerName!.trim(),
            ].join(' · '),
            statusLabel: _statusLabel(l10n, cycle.status),
            status: cycle.status,
          ),
          const SizedBox(height: AppSpacing.lg),
          SitePhotoVerifyPipeline(
            active: sitePhotoPipeStepForStatus(cycle.status),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(_hint(l10n, cycle), style: textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SitePhotoSlotTile(
                  badge: l10n.siteCycleSlotA,
                  caption: sitePhotoSlotCaption(
                    l10n,
                    cycle.photoA,
                    emptyWaiting: false,
                  ),
                  photo: cycle.photoA,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: SitePhotoSlotTile(
                  badge: l10n.siteCycleSlotB,
                  caption: sitePhotoSlotCaption(
                    l10n,
                    cycle.photoB,
                    emptyWaiting: cycle.status == 'waiting' ||
                        cycle.status == 'awaiting_a',
                  ),
                  photo: cycle.photoB,
                  dimmed: cycle.status == 'waiting',
                ),
              ),
            ],
          ),
          if (cycle.status == 'analyzing') ...[
            const SizedBox(height: AppSpacing.lg),
            const SitePhotoAnalyzeCard(),
          ] else if (cycle.status == 'inspector' ||
              cycle.status == 'confirmed' ||
              cycle.status == 'rejected') ...[
            const SizedBox(height: AppSpacing.lg),
            SitePhotoInspectResultCard(
              status: cycle.status,
              result: cycle.result,
              verifyExport: cycle.verifyExport,
            ),
          ],
          if (_uploading) ...[
            const SizedBox(height: AppSpacing.md),
            LinearProgressIndicator(value: _uploadProgress),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.siteCycleUploading((_uploadProgress * 100).round()),
              style: textTheme.bodySmall?.copyWith(color: colors.inkMuted),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          if (cycle.isReuploadLocked &&
              (cycle.status == 'awaiting_a' || cycle.status == 'missed'))
            PillButton(
              label: l10n.siteCycleReuploadLocked(
                _formatRemaining(_lockRemaining),
              ),
              icon: Icons.lock_clock_outlined,
              variant: PillButtonVariant.outline,
              expand: true,
              onPressed: null,
            )
          else if (cycle.canUploadA)
            PillButton(
              label: cycle.status == 'missed'
                  ? l10n.siteCycleMissedRestart
                  : l10n.siteCycleUploadA,
              icon: Icons.add_a_photo_outlined,
              expand: true,
              loading: _uploading,
              onPressed: _uploading ? null : _uploadA,
            )
          else if (cycle.canUploadB)
            PillButton(
              label: l10n.siteCycleUploadB,
              icon: Icons.add_a_photo_outlined,
              expand: true,
              loading: _uploading,
              onPressed: _uploading ? null : _openUploadB,
            )
          else if (cycle.status == 'waiting')
            PillButton(
              label: l10n.siteCycleTooEarly,
              icon: Icons.lock_clock_outlined,
              variant: PillButtonVariant.outline,
              expand: true,
              onPressed: null,
            )
          else if (cycle.status == 'analyzing')
            const SizedBox.shrink(),
        ],
      ],
    );
  }
}
