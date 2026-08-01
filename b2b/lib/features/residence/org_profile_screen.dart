import 'dart:math' as math;

import 'package:file_picker/file_picker.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/localization/status_labels.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_theme_ext.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/documents_upload_card.dart';
import '../../core/widgets/pill_button.dart';
import '../../l10n/gen/app_localizations.dart';
import '../admin/admin_api.dart';

final _myOrgProvider = FutureProvider((ref) {
  return ref.watch(adminApiProvider).myDeveloper();
});

final _subscriptionPlansProvider = FutureProvider((ref) {
  return ref.watch(adminApiProvider).subscriptionPlans();
});

final _myDocumentsProvider = FutureProvider((ref) {
  return ref.watch(adminApiProvider).myDocuments();
});

/// Post-approval org / residence public profile + subscription gate.
class OrgProfileScreen extends ConsumerStatefulWidget {
  const OrgProfileScreen({super.key});

  @override
  ConsumerState<OrgProfileScreen> createState() => _OrgProfileScreenState();
}

class _PlanCard extends StatefulWidget {
  const _PlanCard({
    required this.plan,
    required this.isActive,
    required this.loading,
    required this.onSubscribe,
  });

  final Map<String, dynamic> plan;
  final bool isActive;
  final bool loading;
  final VoidCallback onSubscribe;

  @override
  State<_PlanCard> createState() => _PlanCardState();
}

class _PlanCardState extends State<_PlanCard> {
  bool _expanded = false;

  String _limit(AppLocalizations l10n, dynamic value) =>
      value == -1 ? l10n.orgPlanUnlimited : '$value';

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    final plan = widget.plan;
    return AppCard(
      border: widget.isActive,
      color: widget.isActive ? colors.accent.withValues(alpha: 0.08) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          plan['name']?.toString() ?? '',
                          style: textTheme.titleMedium,
                        ),
                        if (widget.isActive) ...[
                          const SizedBox(width: AppSpacing.sm),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: colors.success.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(
                                AppRadii.pill,
                              ),
                            ),
                            child: Text(
                              l10n.orgPlanActive,
                              style: textTheme.labelSmall,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      l10n.orgPlanSummary(
                        '${plan['priceUsd']}',
                        _limit(l10n, plan['maxProjects']),
                        _limit(l10n, plan['maxUnits']),
                        '${plan['includedLeadsPerMonth']}',
                        '${plan['payPerLeadUsd']}',
                      ),
                      style: textTheme.bodySmall?.copyWith(
                        color: colors.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              PillButton(
                label: widget.isActive
                    ? l10n.orgPlanCurrentPlan
                    : l10n.orgPlanSubscribe,
                variant: widget.isActive
                    ? PillButtonVariant.outline
                    : PillButtonVariant.accent,
                loading: widget.loading,
                onPressed: widget.isActive || widget.loading
                    ? null
                    : widget.onSubscribe,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => setState(() => _expanded = !_expanded),
              icon: Icon(
                _expanded ? Icons.expand_less : Icons.expand_more,
                size: 18,
              ),
              label: Text(
                _expanded ? l10n.orgPlanDetailsHide : l10n.orgPlanDetailsShow,
              ),
            ),
          ),
          AnimatedSize(
            duration: AppDurations.medium,
            curve: Curves.easeOutCubic,
            child: _expanded
                ? Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.sm),
                    child: _AlwaysOnTopDetail(),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

/// Expandable "Always on Top" explainer: an fl_chart line showing how the
/// visibility boost coefficient decays from 0.4 (while the subscription is
/// active) down to 0.04 over the two weeks after it expires. Mock data.
class _AlwaysOnTopDetail extends StatelessWidget {
  /// Boost while active and after full decay (see [_decaySpots]).
  static const double _activeCoefficient = 0.4;
  static const double _floorCoefficient = 0.04;

  /// Weeks 0..2 map the two-week decay window; the leading -1..0 segment is the
  /// flat "still active" period before expiry.
  static List<FlSpot> _decaySpots() {
    final spots = <FlSpot>[
      const FlSpot(-1, _activeCoefficient),
      const FlSpot(0, _activeCoefficient),
    ];
    for (var i = 1; i <= 8; i++) {
      final w = i / 4; // 0.25 .. 2.0
      final coeff =
          _floorCoefficient +
          (_activeCoefficient - _floorCoefficient) * math.exp(-2 * w);
      spots.add(FlSpot(w, double.parse(coeff.toStringAsFixed(3))));
    }
    return spots;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    final spots = _decaySpots();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: AppSpacing.lg),
        Text(l10n.orgPlanAlwaysOnTopTitle, style: textTheme.titleSmall),
        const SizedBox(height: AppSpacing.xs),
        Text(
          l10n.orgPlanAlwaysOnTopSubtitle,
          style: textTheme.bodySmall?.copyWith(color: colors.inkMuted),
        ),
        const SizedBox(height: AppSpacing.lg),
        SizedBox(
          height: 180,
          child: LineChart(
            LineChartData(
              minX: -1,
              maxX: 2,
              minY: 0,
              maxY: 0.45,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 0.1,
                getDrawingHorizontalLine: (_) =>
                    FlLine(color: colors.outline, strokeWidth: 1),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                leftTitles: AxisTitles(
                  axisNameWidget: Text(
                    l10n.orgPlanDecayCoefficientAxis,
                    style: textTheme.labelSmall?.copyWith(
                      color: colors.inkMuted,
                    ),
                  ),
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 0.1,
                    reservedSize: 36,
                    getTitlesWidget: (value, meta) => Text(
                      value.toStringAsFixed(1),
                      style: textTheme.labelSmall?.copyWith(
                        color: colors.inkMuted,
                      ),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  axisNameWidget: Text(
                    l10n.orgPlanDecayWeeksAxis,
                    style: textTheme.labelSmall?.copyWith(
                      color: colors.inkMuted,
                    ),
                  ),
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 1,
                    reservedSize: 24,
                    getTitlesWidget: (value, meta) => Text(
                      value.toStringAsFixed(0),
                      style: textTheme.labelSmall?.copyWith(
                        color: colors.inkMuted,
                      ),
                    ),
                  ),
                ),
              ),
              extraLinesData: ExtraLinesData(
                verticalLines: [
                  VerticalLine(
                    x: 0,
                    color: colors.danger.withValues(alpha: 0.5),
                    strokeWidth: 1,
                    dashArray: [4, 4],
                  ),
                ],
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  preventCurveOverShooting: true,
                  color: colors.accentSecondary,
                  barWidth: 3,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: colors.accentSecondary.withValues(alpha: 0.12),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.lg,
          runSpacing: AppSpacing.xs,
          children: [
            _LegendDot(
              color: colors.accentSecondary,
              label: l10n.orgPlanDecayActiveLegend,
            ),
            _LegendDot(
              color: colors.danger.withValues(alpha: 0.6),
              label: l10n.orgPlanDecayExpiredLegend,
            ),
          ],
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = context.colors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          label,
          style: textTheme.labelSmall?.copyWith(color: colors.inkMuted),
        ),
      ],
    );
  }
}

class _OrgProfileScreenState extends ConsumerState<OrgProfileScreen> {
  final _description = TextEditingController();
  final _office = TextEditingController();
  final _website = TextEditingController();
  final _brandColor = TextEditingController();
  final _coverUrl = TextEditingController();
  final _logoUrl = TextEditingController();
  final _aiWebsite = TextEditingController();
  final _aiInstagram = TextEditingController();
  final _aiResult = TextEditingController();
  bool _hydrated = false;
  bool _saving = false;
  bool _aiGenerating = false;
  String? _aiPdfName;
  String? _checkingOutPlanId;
  String? _message;
  String? _uploadingDocType;
  double _docUploadProgress = 0;

  @override
  void dispose() {
    _description.dispose();
    _office.dispose();
    _website.dispose();
    _brandColor.dispose();
    _coverUrl.dispose();
    _logoUrl.dispose();
    _aiWebsite.dispose();
    _aiInstagram.dispose();
    _aiResult.dispose();
    super.dispose();
  }

  void _hydrate(Map<String, dynamic> org) {
    if (_hydrated) return;
    _description.text = org['description']?.toString() ?? '';
    _office.text = org['officeAddress']?.toString() ?? '';
    _website.text = org['website']?.toString() ?? '';
    _brandColor.text = org['brandColor']?.toString() ?? '';
    _coverUrl.text = org['coverImageUrl']?.toString() ?? '';
    _logoUrl.text = org['logoUrl']?.toString() ?? '';
    _aiWebsite.text = org['website']?.toString() ?? '';
    _hydrated = true;
  }

  Future<void> _pickPdf() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
      withData: false,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() => _aiPdfName = result.files.single.name);
    }
  }

  /// Track B.3: real file upload (replacing the previous mock-only PDF
  /// picker) — multipart to `POST /developers/me/documents`, tagged with
  /// [type] per the Documents API frozen contract.
  Future<void> _uploadDocument(String type) async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png'],
      withData: true,
    );
    if (result == null || result.files.isEmpty || !mounted) return;
    final picked = result.files.single;
    final bytes = picked.bytes;
    if (bytes == null) return;

    final l10n = AppLocalizations.of(context);
    // Documents are never sent the instant a file is picked — the user
    // reviews a preview (name, size, thumbnail) and must explicitly confirm.
    final confirmed = await confirmDocumentUpload(
      context,
      documentTypeLabel: documentTypeLabel(l10n, type),
      filename: picked.name,
      bytes: bytes,
    );
    if (!confirmed || !mounted) return;

    setState(() {
      _uploadingDocType = type;
      _docUploadProgress = 0;
      _message = null;
    });
    try {
      await ref
          .read(adminApiProvider)
          .uploadDeveloperDocument(
            type: type,
            bytes: bytes,
            filename: picked.name,
            onSendProgress: (sent, total) {
              if (total <= 0 || !mounted) return;
              setState(() => _docUploadProgress = sent / total);
            },
          );
      ref.invalidate(_myDocumentsProvider);
      if (mounted) setState(() => _message = l10n.orgDocumentUploaded);
    } catch (e) {
      if (mounted) {
        setState(() => _message = l10n.orgDocumentUploadError('$e'));
      }
    } finally {
      if (mounted) setState(() => _uploadingDocType = null);
    }
  }

  bool get _hasAiInputs =>
      _aiWebsite.text.trim().isNotEmpty ||
      _aiInstagram.text.trim().isNotEmpty ||
      _aiPdfName != null;

  /// Frontend-only mock: composes a deterministic, persona-aware draft from the
  /// org's details and the provided links/PDF. No network calls.
  Future<void> _generateAi(Map<String, dynamic> org) async {
    setState(() {
      _aiGenerating = true;
      _message = null;
    });
    // A short, fixed delay to convey "work happening" without any randomness.
    await Future<void>.delayed(AppDurations.slow);
    if (!mounted) return;
    setState(() {
      _aiResult.text = _composeMockDescription(org);
      _aiGenerating = false;
    });
  }

  String _composeMockDescription(Map<String, dynamic> org) {
    final name = (org['name']?.toString().trim().isNotEmpty ?? false)
        ? org['name'].toString().trim()
        : 'Our company';
    final isConstruction = org['accountKind']?.toString() == 'construction_company';
    final web = _aiWebsite.text.trim();
    final insta = _aiInstagram.text.trim();
    final hasPdf = _aiPdfName != null;

    final lead = isConstruction
        ? '$name is a construction partner delivering residential projects across Uzbekistan with a focus on reliable timelines, transparent budgets, and quality on-site execution.'
        : '$name is a property developer creating modern residential complexes in Uzbekistan, pairing thoughtful design with dependable delivery for homebuyers and investors.';

    final middle = isConstruction
        ? 'From groundwork to handover, the team coordinates inventory, sub-contractors, and site access so developer partners can plan with confidence.'
        : 'Each project balances location, layout, and long-term value, backed by a sales team that guides buyers from first viewing to keys in hand.';

    final sources = <String>[];
    if (web.isNotEmpty) sources.add('website ($web)');
    if (insta.isNotEmpty) sources.add('Instagram ($insta)');
    if (hasPdf) sources.add('company profile "$_aiPdfName"');
    final closing = sources.isEmpty
        ? 'Get in touch to learn more about current and upcoming developments.'
        : 'Highlights drawn from the ${_joinNaturally(sources)} round out a profile buyers can trust.';

    return '$lead\n\n$middle $closing';
  }

  String _joinNaturally(List<String> parts) {
    if (parts.length == 1) return parts.first;
    if (parts.length == 2) return '${parts[0]} and ${parts[1]}';
    return '${parts.sublist(0, parts.length - 1).join(', ')}, and ${parts.last}';
  }

  void _applyAiResult() {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _description.text = _aiResult.text;
      _message = l10n.orgAiApplied;
    });
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _saving = true;
      _message = null;
    });
    try {
      await ref.read(adminApiProvider).updateMyDeveloper({
        'description': _description.text.trim(),
        'officeAddress': _office.text.trim(),
        'website': _website.text.trim(),
        'brandColor': _brandColor.text.trim().isEmpty
            ? null
            : _brandColor.text.trim(),
        'coverImageUrl': _coverUrl.text.trim().isEmpty
            ? null
            : _coverUrl.text.trim(),
        'logoUrl': _logoUrl.text.trim().isEmpty ? null : _logoUrl.text.trim(),
      });
      ref.invalidate(_myOrgProvider);
      if (!mounted) return;
      setState(() => _message = l10n.orgSavedMessage);
    } catch (e) {
      if (!mounted) return;
      setState(() => _message = l10n.orgError('$e'));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _checkout(String planId) async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _checkingOutPlanId = planId;
      _message = null;
    });
    try {
      final res = await ref
          .read(adminApiProvider)
          .checkoutSubscription(planId: planId);
      ref.invalidate(_myOrgProvider);
      if (!mounted) return;
      setState(
        () => _message = res['message']?.toString() ?? l10n.orgSavedMessage,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _message = l10n.orgError('$e'));
    } finally {
      if (mounted) setState(() => _checkingOutPlanId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    final orgAsync = ref.watch(_myOrgProvider);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      children: [
        Text(l10n.orgTitle, style: textTheme.headlineMedium),
        const SizedBox(height: AppSpacing.sm),
        Text(
          l10n.orgSubtitle,
          style: textTheme.bodyMedium?.copyWith(color: colors.inkMuted),
        ),
        const SizedBox(height: AppSpacing.xl),
        orgAsync.when(
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => Text(l10n.orgError('$e')),
          data: (org) {
            if (org == null) {
              return Text(l10n.orgNoProfile);
            }
            _hydrate(org);
            final payment = org['paymentStatus']?.toString() ?? 'none';
            final canPublish = org['canPublish'] == true;
            final activePlanId = (org['subscription'] as Map?)?['planId']
                ?.toString();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        org['name']?.toString() ?? '',
                        style: textTheme.titleLarge,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        l10n.orgLegalLine(
                          '${org['legalName'] ?? ''}',
                          '${org['inn'] ?? '—'}',
                        ),
                        style: textTheme.bodySmall?.copyWith(
                          color: colors.inkMuted,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        l10n.orgPaymentLabel(payment) +
                            (canPublish
                                ? l10n.orgPublishingUnlocked
                                : l10n.orgPublishingLocked),
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                DocumentsUploadCard(
                  documentsAsync: ref.watch(_myDocumentsProvider),
                  uploadingType: _uploadingDocType,
                  uploadProgress: _docUploadProgress,
                  onUpload: _uploadDocument,
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  l10n.orgSubscriptionPlansTitle,
                  style: textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  l10n.orgSubscriptionPlansSubtitle,
                  style: textTheme.bodySmall?.copyWith(color: colors.inkMuted),
                ),
                const SizedBox(height: AppSpacing.md),
                Consumer(
                  builder: (context, ref, _) {
                    final plansAsync = ref.watch(_subscriptionPlansProvider);
                    return plansAsync.when(
                      loading: () => const LinearProgressIndicator(),
                      error: (e, _) => Text(l10n.orgPlansError('$e')),
                      data: (plans) => Column(
                        children: [
                          for (final plan in plans)
                            Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppSpacing.md,
                              ),
                              child: _PlanCard(
                                plan: plan,
                                isActive:
                                    plan['id'] == activePlanId && canPublish,
                                loading: _checkingOutPlanId == plan['id'],
                                onSubscribe: () =>
                                    _checkout(plan['id'] as String),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.xl),
                _AiGeneratorCard(
                  websiteController: _aiWebsite,
                  instagramController: _aiInstagram,
                  resultController: _aiResult,
                  pdfName: _aiPdfName,
                  generating: _aiGenerating,
                  hasInputs: _hasAiInputs,
                  onPickPdf: _pickPdf,
                  onGenerate: () => _generateAi(org),
                  onApply: _applyAiResult,
                ),
                const SizedBox(height: AppSpacing.xl),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l10n.orgPublicPresenceTitle,
                        style: textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextField(
                        controller: _description,
                        maxLines: 4,
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(2000),
                        ],
                        decoration: InputDecoration(
                          hintText: l10n.orgAboutHint,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextField(
                        controller: _office,
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(240),
                        ],
                        decoration: InputDecoration(
                          hintText: l10n.orgOfficeHint,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextField(
                        controller: _website,
                        keyboardType: TextInputType.url,
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(200),
                        ],
                        decoration: InputDecoration(
                          hintText: l10n.orgWebsiteHint,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextField(
                        controller: _logoUrl,
                        keyboardType: TextInputType.url,
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(500),
                        ],
                        decoration: InputDecoration(hintText: l10n.orgLogoHint),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextField(
                        controller: _coverUrl,
                        keyboardType: TextInputType.url,
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(500),
                        ],
                        decoration: InputDecoration(
                          hintText: l10n.orgCoverHint,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextField(
                        controller: _brandColor,
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(9),
                        ],
                        decoration: InputDecoration(
                          hintText: l10n.orgBrandColorHint,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      PillButton(
                        label: l10n.orgSaveProfile,
                        expand: true,
                        loading: _saving,
                        onPressed: _saving ? null : _save,
                      ),
                    ],
                  ),
                ),
                if (_message != null) ...[
                  const SizedBox(height: AppSpacing.lg),
                  Text(_message!, style: textTheme.bodyMedium),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

/// Frontend-only draft-description template: collects a website / Instagram
/// link and an optional company PDF, then composes a deterministic template
/// description (no AI/network call — the label and copy make this explicit)
/// that the user can edit and push into the profile's `description` field.
class _AiGeneratorCard extends StatelessWidget {
  const _AiGeneratorCard({
    required this.websiteController,
    required this.instagramController,
    required this.resultController,
    required this.pdfName,
    required this.generating,
    required this.hasInputs,
    required this.onPickPdf,
    required this.onGenerate,
    required this.onApply,
  });

  final TextEditingController websiteController;
  final TextEditingController instagramController;
  final TextEditingController resultController;
  final String? pdfName;
  final bool generating;
  final bool hasInputs;
  final VoidCallback onPickPdf;
  final VoidCallback onGenerate;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    final hasResult = resultController.text.trim().isNotEmpty;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.text_snippet_outlined, color: colors.accentSecondary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  l10n.orgAiSectionTitle,
                  style: textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.orgAiSectionSubtitle,
            style: textTheme.bodySmall?.copyWith(color: colors.inkMuted),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: websiteController,
            keyboardType: TextInputType.url,
            inputFormatters: [LengthLimitingTextInputFormatter(200)],
            decoration: InputDecoration(
              hintText: l10n.orgAiWebsiteHint,
              prefixIcon: const Icon(Icons.link_outlined),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: instagramController,
            keyboardType: TextInputType.url,
            inputFormatters: [LengthLimitingTextInputFormatter(200)],
            decoration: InputDecoration(
              hintText: l10n.orgAiInstagramHint,
              prefixIcon: const Icon(Icons.photo_camera_outlined),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: onPickPdf,
                icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                label: Text(l10n.orgAiPickPdf),
              ),
              if (pdfName != null) ...[
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    l10n.orgAiPdfSelected(pdfName!),
                    style: textTheme.bodySmall?.copyWith(
                      color: colors.inkMuted,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          PillButton(
            label: generating ? l10n.orgAiGenerating : l10n.orgAiGenerate,
            icon: Icons.edit_note_outlined,
            expand: true,
            variant: PillButtonVariant.ink,
            loading: generating,
            onPressed: hasInputs && !generating ? onGenerate : null,
          ),
          if (!hasInputs) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.orgAiNoInputs,
              style: textTheme.labelSmall?.copyWith(color: colors.inkMuted),
            ),
          ],
          if (hasResult) ...[
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: resultController,
              maxLines: 6,
              inputFormatters: [LengthLimitingTextInputFormatter(2000)],
              decoration: InputDecoration(
                labelText: l10n.orgAiResultHint,
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            PillButton(
              label: l10n.orgAiApply,
              icon: Icons.check,
              expand: true,
              variant: PillButtonVariant.outline,
              onPressed: onApply,
            ),
          ],
        ],
      ),
    );
  }
}
