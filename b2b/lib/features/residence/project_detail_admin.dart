import 'dart:async';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:latlong2/latlong.dart';

import '../../core/constants/districts.dart';
import '../../core/env.dart';
import '../../core/localization/status_labels.dart';
import '../../core/network/ws_client.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_theme_ext.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/lead_kanban_board.dart';
import '../../core/widgets/map_location_picker.dart';
import '../../core/widgets/pill_button.dart';
import '../../core/widgets/section_header.dart';
import '../../l10n/gen/app_localizations.dart';
import '../admin/admin_api.dart';
import '../auth/auth.dart';
import '../crm/crm_shared.dart';

// The residence project-detail admin screen was a ~1500-line "god file". Its
// self-contained sub-widgets and dialogs are split into feature-scoped part
// files below; they stay in the same library so no imports change and private
// (`_`) types remain shared across the split.
part 'project_detail_analytics.dart';
part 'project_detail_chessboard.dart';
part 'project_detail_dialogs.dart';
part 'project_detail_photo_reports.dart';

class ProjectDetailAdmin extends ConsumerStatefulWidget {
  const ProjectDetailAdmin({super.key, required this.projectId});

  final String projectId;

  @override
  ConsumerState<ProjectDetailAdmin> createState() => _ProjectDetailAdminState();
}

class _ProjectDetailAdminState extends ConsumerState<ProjectDetailAdmin> {
  Map<String, dynamic>? _project;
  List<Map<String, dynamic>> _leads = [];
  String _leadOwnerFilter = 'all';
  List<Map<String, dynamic>> _offers = [];
  List<Map<String, dynamic>> _photoReports = [];
  Map<String, dynamic>? _analytics;
  String? _error;
  bool _loading = true;
  bool _savingOffers = false;
  bool _savingLocation = false;
  bool _submittingForReview = false;
  bool _publishing = false;
  bool _deleting = false;
  bool _gridView = true;
  String? _kindFilter;
  bool _uploadingPhotoReport = false;
  double _photoReportProgress = 0;
  late final TextEditingController _addressController;
  late final TextEditingController _otherDistrictController;
  String _district = kTashkentDistricts.first;
  LatLng? _location;
  StreamSubscription<WsEvent>? _wsSub;
  WsClient? _wsClient;

  @override
  void initState() {
    super.initState();
    _addressController = TextEditingController();
    _otherDistrictController = TextEditingController();
    _load();
    _subscribeWs();
  }

  @override
  void dispose() {
    _wsSub?.cancel();
    // Use the client captured in `_subscribeWs`, not `ref.read`: by the time
    // `dispose` runs the widget may already be unmounted, and Riverpod
    // throws a StateError on any `ref` access past that point.
    _wsClient?.unsubscribeProject(widget.projectId);
    _addressController.dispose();
    _otherDistrictController.dispose();
    super.dispose();
  }

  /// Track B.1: subscribes to this project's live-update channel so unit
  /// status changes and lead activity patch the screen in place instead of
  /// requiring a manual reload.
  void _subscribeWs() {
    final client = ref.read(wsClientProvider);
    _wsClient = client;
    client.subscribeProject(widget.projectId);
    _wsSub = client.connect().listen(_onWsEvent);
  }

  void _onWsEvent(WsEvent event) {
    final payload = event.payload;
    if (payload['projectId']?.toString() != widget.projectId) return;
    switch (event.type) {
      case WsEventType.unitStatusChanged:
        _patchUnitStatus(
          payload['unitId'] as String?,
          payload['status'] as String?,
        );
      case WsEventType.leadCreated:
        _upsertLead(payload);
      case WsEventType.leadStatusChanged:
        _patchLeadStatus(
          payload['leadId'] as String?,
          payload['status'] as String?,
        );
      case WsEventType.leadOwnerChanged:
        _patchLeadOwner(
          payload['leadId'] as String?,
          ownerUserId: payload['ownerUserId'] as String?,
          assignedManager: payload['assignedManager'] as String?,
        );
      default:
        break;
    }
  }

  void _patchUnitStatus(String? unitId, String? status) {
    if (!mounted || unitId == null || status == null) return;
    final project = _project;
    if (project == null) return;
    final buildings = (project['buildings'] as List? ?? [])
        .cast<Map<String, dynamic>>();
    for (final building in buildings) {
      final units = (building['units'] as List? ?? [])
          .cast<Map<String, dynamic>>();
      for (final unit in units) {
        if (unit['id'] == unitId) {
          setState(() => unit['status'] = status);
          return;
        }
      }
    }
  }

  void _upsertLead(Map<String, dynamic> lead) {
    if (!mounted) return;
    setState(() {
      final index = _leads.indexWhere((l) => l['id'] == lead['id']);
      if (index >= 0) {
        _leads[index] = lead;
      } else {
        _leads = [lead, ..._leads];
      }
    });
  }

  void _patchLeadStatus(String? leadId, String? status) {
    if (!mounted || leadId == null || status == null) return;
    final index = _leads.indexWhere((l) => l['id'] == leadId);
    if (index < 0) return;
    setState(() => _leads[index] = {..._leads[index], 'status': status});
  }

  void _patchLeadOwner(
    String? leadId, {
    String? ownerUserId,
    String? assignedManager,
  }) {
    if (!mounted || leadId == null) return;
    final index = _leads.indexWhere((l) => l['id'] == leadId);
    if (index < 0) return;
    setState(() {
      _leads[index] = {
        ..._leads[index],
        'ownerUserId': ownerUserId,
        'assignedManager': assignedManager,
      };
    });
  }

  void _syncLocationFromProject(Map<String, dynamic> project) {
    final lat = (project['lat'] as num?)?.toDouble();
    final lng = (project['lng'] as num?)?.toDouble();
    _location = lat != null && lng != null
        ? LatLng(lat, lng)
        : kDefaultMapCenter;
    _addressController.text = project['address']?.toString() ?? '';
    final district = project['district']?.toString() ?? '';
    if (district.isNotEmpty && kTashkentDistricts.contains(district)) {
      _district = district;
      _otherDistrictController.text = '';
    } else if (district.isNotEmpty) {
      _district = kOtherDistrictOption;
      _otherDistrictController.text = district;
    }
  }

  String get _effectiveDistrict => _district == kOtherDistrictOption
      ? _otherDistrictController.text.trim()
      : _district;

  Future<void> _submitForReview() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _submittingForReview = true);
    try {
      final updated =
          await ref.read(adminApiProvider).submitProjectForReview(widget.projectId);
      setState(() => _project = updated);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.projectSubmitForReviewSuccess)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.residenceLoadError('$e'))),
        );
      }
    } finally {
      if (mounted) setState(() => _submittingForReview = false);
    }
  }

  Future<void> _unpublish() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.projectUnpublish),
        content: Text(l10n.projectUnpublishConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.projectUnpublish),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _publishing = true);
    try {
      final updated =
          await ref.read(adminApiProvider).unpublishAdminProject(widget.projectId);
      setState(() => _project = updated);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.projectUnpublishSuccess)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.residenceLoadError('$e'))),
        );
      }
    } finally {
      if (mounted) setState(() => _publishing = false);
    }
  }

  Future<void> _publish() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _publishing = true);
    try {
      final updated =
          await ref.read(adminApiProvider).publishAdminProject(widget.projectId);
      setState(() => _project = updated);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.projectPublishSuccess)),
        );
      }
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final message = status == 402
          ? l10n.projectPublishNeedsSubscription
          : status == 409
          ? l10n.projectPublishNeedsReview
          : l10n.residenceLoadError('$e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.residenceLoadError('$e'))),
        );
      }
    } finally {
      if (mounted) setState(() => _publishing = false);
    }
  }

  Future<void> _deleteProject() async {
    final l10n = AppLocalizations.of(context);
    final name = _project?['name']?.toString() ?? '';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.projectDeleteConfirmTitle(name)),
        content: Text(l10n.projectDeleteConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.projectDelete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _deleting = true);
    try {
      await ref.read(adminApiProvider).deleteAdminProject(widget.projectId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.projectDeleteSuccess)),
      );
      final isSystemAdmin =
          ref.read(authControllerProvider).value?.isSystemAdmin == true;
      context.go(isSystemAdmin ? '/platform/projects' : '/residence');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.residenceLoadError('$e'))),
        );
      }
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = ref.read(adminApiProvider);
      final project = await api.getAdminProject(widget.projectId);
      final results = await Future.wait([
        api.projectLeads(
          widget.projectId,
          owner: _leadOwnerFilter == 'all' ? null : _leadOwnerFilter,
        ),
        api.projectOffers(widget.projectId),
        api.projectAnalytics(widget.projectId),
        api.projectPhotoReports(widget.projectId),
      ]);
      setState(() {
        _project = project;
        _syncLocationFromProject(project);
        _leads = results[0] as List<Map<String, dynamic>>;
        _offers = results[1] as List<Map<String, dynamic>>;
        _analytics = results[2] as Map<String, dynamic>;
        _photoReports = results[3] as List<Map<String, dynamic>>;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveLocation() async {
    final location = _location;
    if (location == null) return;
    setState(() => _savingLocation = true);
    try {
      await ref.read(adminApiProvider).updateAdminProject(widget.projectId, {
        'district': _effectiveDistrict,
        'address': _addressController.text.trim(),
        'lat': location.latitude,
        'lng': location.longitude,
      });
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).projectLocationSaved),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _savingLocation = false);
    }
  }

  Future<void> _addOffer() async {
    final offer = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => const _OfferEditorDialog(),
    );
    if (offer == null) return;
    setState(() => _savingOffers = true);
    try {
      final next = [..._offers, offer];
      await ref.read(adminApiProvider).setProjectOffers(widget.projectId, next);
      await _load();
    } finally {
      if (mounted) setState(() => _savingOffers = false);
    }
  }

  Future<void> _removeOffer(String id) async {
    setState(() => _savingOffers = true);
    try {
      final next = _offers.where((o) => o['id'] != id).toList();
      await ref.read(adminApiProvider).setProjectOffers(widget.projectId, next);
      await _load();
    } finally {
      if (mounted) setState(() => _savingOffers = false);
    }
  }

  Future<void> _editLead(Map<String, dynamic> lead) async {
    final tags = (lead['tags'] as List?)?.cast<String>() ?? const <String>[];
    final result = await showDialog<CrmLeadEditResult>(
      context: context,
      builder: (ctx) => CrmLeadEditorDialog(
        lead: lead,
        statuses: const [
          'new',
          'contacted',
          'scheduled',
          'visited',
          'qualified',
          'won',
          'lost',
        ],
        showTags: true,
        initialTags: tags,
      ),
    );
    if (result == null) return;
    await applyCrmLeadEdit(
      ref,
      leadId: lead['id'] as String,
      result: result,
    );
    await _load();
  }

  Future<void> _setUnitStatus(String unitId, String status) async {
    final l10n = AppLocalizations.of(context);
    int? expectedVersion;
    final project = _project;
    if (project != null) {
      for (final building in (project['buildings'] as List? ?? [])) {
        for (final unit in ((building as Map)['units'] as List? ?? [])) {
          final u = unit as Map;
          if (u['id'] == unitId) {
            expectedVersion = (u['version'] as num?)?.toInt() ?? 1;
            break;
          }
        }
      }
    }
    try {
      await ref.read(adminApiProvider).patchUnit(unitId, {
        'status': status,
        'expectedVersion': ?expectedVersion,
      });
      await _load();
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.residenceLoadError('Unit was modified elsewhere — reloading'))),
          );
        }
        await _load();
        return;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.residenceLoadError('$e'))),
        );
      }
    }
  }

  /// Kanban drop handler (Track B.2): optimistically patches the card into
  /// its new column, then calls the existing `PATCH admin/leads/:id`.
  Future<void> _updateLeadStatus(
    Map<String, dynamic> lead,
    String status,
  ) async {
    final previous = lead['status'];
    setState(() {
      final index = _leads.indexWhere((l) => l['id'] == lead['id']);
      if (index >= 0) _leads[index] = {..._leads[index], 'status': status};
    });
    try {
      await ref
          .read(adminApiProvider)
          .updateLeadStatus(lead['id'] as String, status);
    } catch (e) {
      // Roll back the optimistic move and surface the failure.
      setState(() {
        final index = _leads.indexWhere((l) => l['id'] == lead['id']);
        if (index >= 0) {
          _leads[index] = {..._leads[index], 'status': previous};
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).residenceLoadError('$e')),
          ),
        );
      }
    }
  }

  /// Photo report upload (Track B.4): multipart upload with a live
  /// send-progress percent, mirroring the Documents API's file-handling
  /// pattern. [spec] carries the date and optional construction-progress
  /// percent collected by [_PhotoReportDetailsDialog].
  Future<void> _addPhotoReport() async {
    final result = await FilePicker.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final picked = result.files.single;
    final bytes = picked.bytes;
    if (bytes == null || !mounted) return;

    final spec = await showDialog<_PhotoReportSpec>(
      context: context,
      builder: (_) => const _PhotoReportDetailsDialog(),
    );
    if (spec == null || !mounted) return;

    setState(() {
      _uploadingPhotoReport = true;
      _photoReportProgress = 0;
    });
    try {
      await ref
          .read(adminApiProvider)
          .uploadPhotoReport(
            widget.projectId,
            bytes: bytes,
            filename: picked.name,
            takenAt: spec.takenAt,
            progressPercent: spec.progressPercent,
            onSendProgress: (sent, total) {
              if (total <= 0 || !mounted) return;
              setState(() => _photoReportProgress = sent / total);
            },
          );
      final reports = await ref
          .read(adminApiProvider)
          .projectPhotoReports(widget.projectId);
      if (mounted) setState(() => _photoReports = reports);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).projectPhotoReportUploadError('$e'),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingPhotoReport = false);
    }
  }

  Future<void> _deletePhotoReport(String id) async {
    await ref.read(adminApiProvider).deletePhotoReport(id);
    if (mounted) {
      setState(() => _photoReports = _photoReports.where((r) => r['id'] != id).toList());
    }
  }

  /// Units of building [b], filtered by [_kindFilter] (unit type split —
  /// plan section 5). `null` filter means "all types".
  List<Map> _filteredUnits(Map<String, dynamic> b) {
    final units = (b['units'] as List? ?? []).cast<Map>();
    if (_kindFilter == null) return units;
    return units.where((u) => u['kind']?.toString() == _kindFilter).toList();
  }

  Future<void> _openUnitSheet(Map<String, dynamic> unit) async {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadii.card),
        ),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.projectUnitLabel('${unit['number']}'),
                style: Theme.of(ctx).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                l10n.projectUnitMetaLine(
                  unitKindLabel(l10n, '${unit['kind']}'),
                  dealTypeLabel(l10n, '${unit['dealType']}'),
                  unitStatusLabel(l10n, '${unit['status']}'),
                  '${(unit['media'] as List?)?.length ?? 0}',
                ),
                style: Theme.of(
                  ctx,
                ).textTheme.bodySmall?.copyWith(color: colors.inkMuted),
              ),
              const SizedBox(height: AppSpacing.lg),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final status in const [
                    'available',
                    'reserved',
                    'sold',
                    'rented',
                    'blocked',
                  ])
                    ChoiceChip(
                      label: Text(unitStatusLabel(l10n, status)),
                      selected: unit['status'] == status,
                      onSelected: (_) async {
                        Navigator.pop(ctx);
                        await _setUnitStatus(unit['id'] as String, status);
                      },
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              PillButton(
                label: l10n.projectAddMediaUrl,
                expand: true,
                variant: PillButtonVariant.outline,
                onPressed: () {
                  Navigator.pop(ctx);
                  _addMedia(unit['id'] as String);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addBuildingDialog() async {
    final l10n = AppLocalizations.of(context);
    final name = TextEditingController();
    final floors = TextEditingController(text: '9');
    final colors = context.colors;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.card),
        ),
        title: Text(l10n.projectNewBuildingDialogTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              inputFormatters: [LengthLimitingTextInputFormatter(80)],
              decoration: InputDecoration(
                labelText: l10n.projectBuildingNameLabel,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: floors,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(3),
              ],
              decoration: InputDecoration(labelText: l10n.projectFloorsLabel),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.commonCancel),
          ),
          PillButton(
            label: l10n.commonAdd,
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );
    if (ok != true || name.text.trim().isEmpty) return;
    await ref.read(adminApiProvider).addBuilding(widget.projectId, {
      'name': name.text.trim(),
      'floors': int.tryParse(floors.text.trim()) ?? 1,
    });
    await _load();
  }

  Future<void> _bulkAddUnitsDialog(List<Map<String, dynamic>> buildings) async {
    final l10n = AppLocalizations.of(context);
    if (buildings.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.projectAddBuildingFirstSnackbar)),
      );
      return;
    }
    final result = await showDialog<_BulkUnitsSpec>(
      context: context,
      builder: (ctx) => _BulkUnitsDialog(buildings: buildings),
    );
    if (result == null) return;
    final api = ref.read(adminApiProvider);
    var number = result.startingNumber;
    for (var floor = result.floorFrom; floor <= result.floorTo; floor++) {
      for (var i = 0; i < result.unitsPerFloor; i++) {
        await api.addUnit(widget.projectId, {
          'buildingId': result.buildingId,
          'number': '$number',
          'floor': floor,
          'kind': result.kind,
          'dealType': result.dealType,
          'areaTotal': result.areaTotal,
          'rooms': result.rooms,
          if (result.dealType == 'sale') 'price': result.price,
          if (result.dealType == 'rent') 'rentMonthly': result.price,
        });
        number++;
      }
    }
    await _load();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.projectUnitsAddedSnackbar('${number - result.startingNumber}'),
          ),
        ),
      );
    }
  }

  Future<void> _addMedia(String unitId) async {
    final l10n = AppLocalizations.of(context);
    final url = TextEditingController();
    final colors = context.colors;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.card),
        ),
        title: Text(l10n.projectAddMediaUrl),
        content: TextField(
          controller: url,
          keyboardType: TextInputType.url,
          inputFormatters: [LengthLimitingTextInputFormatter(500)],
          decoration: InputDecoration(
            hintText: l10n.projectMediaUrlHint,
            prefixIcon: const Icon(Icons.image_outlined),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.commonCancel),
          ),
          PillButton(
            label: l10n.commonAdd,
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );
    if (ok != true || url.text.trim().isEmpty) return;
    await ref.read(adminApiProvider).addUnitMediaUrl(unitId, url.text.trim());
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    final isWide = !context.isMobile;

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: EmptyState(
          icon: Icons.error_outline,
          title: l10n.projectLoadError,
          subtitle: _error,
          actionLabel: l10n.projectBack,
          onAction: () => context.go('/residence'),
        ),
      );
    }

    final project = _project!;
    final buildings = (project['buildings'] as List? ?? [])
        .cast<Map<String, dynamic>>();
    final moderationStatus =
        project['moderationStatus']?.toString() ?? 'approved';
    final canSubmitForReview =
        moderationStatus == 'draft' || moderationStatus == 'rejected';
    final isPublished =
        project['isPublished'] == true ||
        project['isPublished']?.toString() == 'true';
    final canTogglePublish = moderationStatus == 'approved';

    final body = ListView(
      padding: EdgeInsets.fromLTRB(
        isWide ? AppSpacing.xl : AppSpacing.lg,
        isWide ? AppSpacing.xl : AppSpacing.lg,
        isWide ? AppSpacing.xl : AppSpacing.lg,
        AppSpacing.xxxl,
      ),
      children: [
        Text(
          project['name']?.toString() ?? '',
          style: textTheme.headlineMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            _MetaChip(
              label: l10n.projectModerationLabel(
                projectModerationStatusLabel(l10n, moderationStatus),
              ),
            ),
            _MetaChip(
              label: l10n.projectPublishedLabel(
                publishedStatusLabel(l10n, isPublished),
              ),
            ),
            if ((project['developer'] as Map?)?['name']
                    ?.toString()
                    .isNotEmpty ==
                true)
              _MetaChip(
                label: l10n.platformProjectDeveloper(
                  (project['developer'] as Map)['name'].toString(),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            if (canTogglePublish)
              PillButton(
                label: isPublished
                    ? l10n.projectUnpublish
                    : l10n.projectRepublish,
                variant: PillButtonVariant.outline,
                loading: _publishing,
                onPressed: _publishing
                    ? null
                    : (isPublished ? _unpublish : _publish),
              ),
            PillButton(
              label: l10n.projectDelete,
              variant: PillButtonVariant.outline,
              loading: _deleting,
              onPressed: _deleting ? null : _deleteProject,
            ),
          ],
        ),
        if (canSubmitForReview) ...[
          const SizedBox(height: AppSpacing.lg),
          AppCard(
            color: moderationStatus == 'rejected'
                ? colors.danger.withValues(alpha: 0.08)
                : colors.warning.withValues(alpha: 0.1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  moderationStatus == 'rejected'
                      ? l10n.projectRejectedBanner
                      : l10n.projectDraftBanner,
                  style: textTheme.bodyMedium,
                ),
                if (project['moderationNote'] != null &&
                    '${project['moderationNote']}'.trim().isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    '${project['moderationNote']}',
                    style: textTheme.bodySmall?.copyWith(color: colors.inkMuted),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                Align(
                  alignment: Alignment.centerRight,
                  child: PillButton(
                    label: l10n.projectSubmitForReview,
                    loading: _submittingForReview,
                    onPressed:
                        _submittingForReview ? null : _submitForReview,
                  ),
                ),
              ],
            ),
          ),
        ] else if (_platformWarningNote(project) != null) ...[
          const SizedBox(height: AppSpacing.lg),
          _PlatformWarningBanner(note: _platformWarningNote(project)!),
        ],
        const SizedBox(height: AppSpacing.xxl),
        SectionHeader(title: l10n.projectLocationSectionTitle),
        const SizedBox(height: AppSpacing.md),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _district,
                decoration: InputDecoration(
                  labelText: l10n.residenceDistrictHint,
                ),
                items: [
                  for (final d in kTashkentDistricts)
                    DropdownMenuItem(value: d, child: Text(d)),
                  DropdownMenuItem(
                    value: kOtherDistrictOption,
                    child: Text(l10n.residenceDistrictOther),
                  ),
                ],
                onChanged: (value) =>
                    setState(() => _district = value ?? _district),
              ),
              if (_district == kOtherDistrictOption) ...[
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _otherDistrictController,
                  inputFormatters: [LengthLimitingTextInputFormatter(80)],
                  decoration: InputDecoration(
                    hintText: l10n.residenceDistrictOtherHint,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _addressController,
                inputFormatters: [LengthLimitingTextInputFormatter(200)],
                decoration: InputDecoration(hintText: l10n.residenceAddressHint),
              ),
              const SizedBox(height: AppSpacing.lg),
              if (_location != null)
                MapLocationPicker(
                  location: _location!,
                  height: 260,
                  onLocationChanged: (point) => setState(() => _location = point),
                ),
              const SizedBox(height: AppSpacing.lg),
              Align(
                alignment: Alignment.centerRight,
                child: PillButton(
                  label: l10n.projectLocationSave,
                  loading: _savingLocation,
                  onPressed: _savingLocation ? null : _saveLocation,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        SectionHeader(title: l10n.projectAnalyticsTitle),
        const SizedBox(height: AppSpacing.md),
        if (_analytics != null) _AnalyticsPanel(analytics: _analytics!),
        const SizedBox(height: AppSpacing.xxl),
        Row(
          children: [
            Expanded(child: SectionHeader(title: l10n.projectOffersTitle)),
            PillButton(
              label: l10n.projectAddOffer,
              variant: PillButtonVariant.outline,
              loading: _savingOffers,
              onPressed: _savingOffers ? null : _addOffer,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (_offers.isEmpty)
          EmptyState(
            compact: true,
            icon: Icons.local_offer_outlined,
            title: l10n.projectNoOffers,
            subtitle: l10n.projectNoOffersSubtitle,
          )
        else
          for (final offer in _offers)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: AppCard(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${offer['title']} · '
                            '${offerTypeLabel(l10n, '${offer['type']}')}',
                            style: textTheme.titleSmall,
                          ),
                          if (offer['description'] != null) ...[
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              offer['description'].toString(),
                              style: textTheme.bodySmall?.copyWith(
                                color: colors.inkMuted,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: l10n.projectRemoveOfferTooltip,
                      onPressed: _savingOffers
                          ? null
                          : () => _removeOffer(offer['id'] as String),
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ],
                ),
              ),
            ),
        const SizedBox(height: AppSpacing.xxl),
        Row(
          children: [
            Expanded(child: SectionHeader(title: l10n.projectUnitsTitle)),
            PillButton(
              label: l10n.projectAddBuilding,
              variant: PillButtonVariant.outline,
              onPressed: _addBuildingDialog,
            ),
            const SizedBox(width: AppSpacing.sm),
            PillButton(
              label: l10n.projectBulkAddUnits,
              variant: PillButtonVariant.outline,
              onPressed: () => _bulkAddUnitsDialog(buildings),
            ),
            const SizedBox(width: AppSpacing.sm),
            IconButton(
              tooltip: _gridView
                  ? l10n.projectViewToggleList
                  : l10n.projectViewToggleChessboard,
              onPressed: () => setState(() => _gridView = !_gridView),
              icon: Icon(
                _gridView ? Icons.view_list_outlined : Icons.grid_view_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        _UnitKindFilterBar(
          value: _kindFilter,
          onChanged: (kind) => setState(() => _kindFilter = kind),
        ),
        const SizedBox(height: AppSpacing.md),
        if (_gridView) const _ChessboardLegend(),
        if (_gridView) const SizedBox(height: AppSpacing.sm),
        if (_gridView) const _ChessboardRoomLegend(),
        if (_gridView) const SizedBox(height: AppSpacing.md),
        for (final b in buildings) ...[
          if (_filteredUnits(b).isNotEmpty) ...[
            Text(
              b['name']?.toString() ?? l10n.projectBuildingFallback,
              style: textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          if (_gridView)
            _BuildingChessboard(
              units: _filteredUnits(b),
              onTapUnit: (u) => _openUnitSheet(u.cast<String, dynamic>()),
            ),
          if (!_gridView)
            for (final u in _filteredUnits(b))
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: AppCard(
                  child: isWide
                      ? Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.projectUnitLabel('${u['number']}'),
                                    style: textTheme.titleSmall,
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    l10n.projectUnitMetaLine(
                                      unitKindLabel(l10n, '${u['kind']}'),
                                      dealTypeLabel(l10n, '${u['dealType']}'),
                                      unitStatusLabel(l10n, '${u['status']}'),
                                      '${(u['media'] as List?)?.length ?? 0}',
                                    ),
                                    style: textTheme.bodySmall?.copyWith(
                                      color: colors.inkMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            PopupMenuButton<String>(
                              onSelected: (s) =>
                                  _setUnitStatus(u['id'] as String, s),
                              itemBuilder: (_) => [
                                for (final s in const [
                                  'available',
                                  'reserved',
                                  'sold',
                                  'rented',
                                  'blocked',
                                ])
                                  PopupMenuItem(
                                    value: s,
                                    child: Text(unitStatusLabel(l10n, s)),
                                  ),
                              ],
                              child: PillButton(
                                label: l10n.projectStatusButton,
                                variant: PillButtonVariant.outline,
                                onPressed: null,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            IconButton(
                              tooltip: l10n.projectAddMediaUrl,
                              onPressed: () => _addMedia(u['id'] as String),
                              icon: const Icon(Icons.image_outlined),
                            ),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.projectUnitLabelWithStatus(
                                '${u['number']}',
                                unitStatusLabel(l10n, '${u['status']}'),
                              ),
                              style: textTheme.titleSmall,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              l10n.projectUnitMetaLineNoStatus(
                                unitKindLabel(l10n, '${u['kind']}'),
                                dealTypeLabel(l10n, '${u['dealType']}'),
                                '${(u['media'] as List?)?.length ?? 0}',
                              ),
                              style: textTheme.bodySmall?.copyWith(
                                color: colors.inkMuted,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Row(
                              children: [
                                Expanded(
                                  child: PopupMenuButton<String>(
                                    onSelected: (s) =>
                                        _setUnitStatus(u['id'] as String, s),
                                    itemBuilder: (_) => [
                                      for (final s in const [
                                        'available',
                                        'reserved',
                                        'sold',
                                        'rented',
                                        'blocked',
                                      ])
                                        PopupMenuItem(
                                          value: s,
                                          child: Text(unitStatusLabel(l10n, s)),
                                        ),
                                    ],
                                    child: PillButton(
                                      label: l10n.projectChangeStatusButton,
                                      variant: PillButtonVariant.outline,
                                      expand: true,
                                      onPressed: null,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => _addMedia(u['id'] as String),
                                  icon: const Icon(Icons.image_outlined),
                                ),
                              ],
                            ),
                          ],
                        ),
                ),
              ),
          const SizedBox(height: AppSpacing.lg),
        ],
        SectionHeader(title: l10n.projectLeadCrmTitle),
        const SizedBox(height: AppSpacing.xs),
        Text(
          l10n.projectKanbanHint,
          style: textTheme.bodySmall?.copyWith(color: colors.inkMuted),
        ),
        const SizedBox(height: AppSpacing.md),
        CrmOwnerFilterChips(
          selected: _leadOwnerFilter,
          onChanged: (v) async {
            setState(() => _leadOwnerFilter = v);
            await _load();
          },
        ),
        const SizedBox(height: AppSpacing.md),
        if (_leads.isEmpty)
          EmptyState(
            compact: true,
            icon: Icons.inbox_outlined,
            title: l10n.projectNoLeads,
          )
        else
          LeadKanbanBoard(
            leads: _leads,
            statuses: const [
              'new',
              'contacted',
              'scheduled',
              'visited',
              'qualified',
              'won',
              'lost',
            ],
            statusLabel: (status) => leadStatusLabel(l10n, status),
            onStatusChanged: _updateLeadStatus,
            cardBuilder: (context, lead) => _LeadKanbanCard(
              lead: lead,
              onEdit: () => _editLead(lead),
            ),
          ),
        const SizedBox(height: AppSpacing.xxl),
        SectionHeader(title: l10n.projectPhotoReportsTitle),
        const SizedBox(height: AppSpacing.xs),
        Text(
          l10n.projectPhotoReportsSubtitle,
          style: textTheme.bodySmall?.copyWith(color: colors.inkMuted),
        ),
        const SizedBox(height: AppSpacing.md),
        Align(
          alignment: Alignment.centerLeft,
          child: PillButton(
            label: l10n.projectAddPhotoReport,
            icon: Icons.add_photo_alternate_outlined,
            variant: PillButtonVariant.outline,
            loading: _uploadingPhotoReport,
            onPressed: _uploadingPhotoReport ? null : _addPhotoReport,
          ),
        ),
        if (_uploadingPhotoReport) ...[
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.pill),
            child: LinearProgressIndicator(value: _photoReportProgress),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.projectPhotoReportUploading(
              (_photoReportProgress * 100).round(),
            ),
            style: textTheme.bodySmall?.copyWith(color: colors.inkMuted),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        if (_photoReports.isEmpty)
          EmptyState(
            compact: true,
            icon: Icons.photo_library_outlined,
            title: l10n.projectPhotoReportsEmpty,
          )
        else
          _PhotoReportsByMonth(
            reports: _photoReports,
            onDelete: _deletePhotoReport,
          ),
      ],
    );

    return body;
  }
}

/// Single lead card shown inside a [LeadKanbanBoard] column on the
/// per-project CRM. Drag handle is the whole card (see [LeadKanbanBoard]);
/// [onEdit] opens the existing tags/score editor.
class _LeadKanbanCard extends StatelessWidget {
  const _LeadKanbanCard({required this.lead, required this.onEdit});

  final Map<String, dynamic> lead;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${lead['number'] ?? ''} · ${lead['intent'] ?? ''}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleSmall,
                ),
              ),
              IconButton(
                tooltip: l10n.projectTagsScoreTooltip,
                iconSize: 18,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                onPressed: onEdit,
                icon: const Icon(Icons.label_outline),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.projectLeadContactLine(
              '${lead['contactPhone'] ?? ''}',
              '${lead['message'] ?? ''}',
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodySmall?.copyWith(color: colors.inkMuted),
          ),
          if (lead['score'] != null || (lead['tags'] as List?)?.isNotEmpty == true) ...[
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                if (lead['score'] != null)
                  _ScoreChip(score: lead['score'].toString()),
                for (final tag in (lead['tags'] as List? ?? []))
                  _MetaChip(label: tag.toString()),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.xs),
          LeadOwnerLine(lead: lead),
        ],
      ),
    );
  }
}

String? _platformWarningNote(Map<String, dynamic> project) {
  final note = project['moderationNote']?.toString().trim() ?? '';
  if (note.isEmpty) return null;
  // Warn keeps status approved + published; draft/rejected banners own the note.
  final status = project['moderationStatus']?.toString() ?? 'approved';
  if (status == 'draft' || status == 'rejected' || status == 'pending') {
    return null;
  }
  return note;
}

/// Red alert shown to the residence admin after platform moderation `warn`.
class _PlatformWarningBanner extends StatelessWidget {
  const _PlatformWarningBanner({required this.note});

  final String note;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);

    return AppCard(
      color: colors.danger.withValues(alpha: 0.12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, color: colors.danger, size: 28),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.projectWarningBanner,
                  style: textTheme.titleMedium?.copyWith(color: colors.danger),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.projectWarningBannerSubtitle,
                  style: textTheme.bodySmall?.copyWith(color: colors.inkMuted),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  note,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colors.danger,
                    fontWeight: FontWeight.w600,
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
