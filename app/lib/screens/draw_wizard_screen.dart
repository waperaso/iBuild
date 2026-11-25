import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../api.dart';
import '../download.dart';
import '../file_pick.dart';
import '../l10n.dart';
import '../models.dart';
import '../photo_meta_card.dart';
import '../session_scope.dart';
import '../theme.dart';
import '../widgets.dart';

String _noSourcesText(BuildContext context, AppCopy copy, String projectId) {
  final project = SessionScope.of(context).findProject(projectId);
  final director = project?.myRole == AppRole.director || project?.myRole == AppRole.developer;
  return director ? copy.noSourcesDirector : copy.noSourcesOther;
}

class DrawWizardScreen extends StatefulWidget {
  const DrawWizardScreen({super.key, required this.projectId, this.drawId});

  final String projectId;
  final String? drawId;

  @override
  State<DrawWizardScreen> createState() => _DrawWizardScreenState();
}

class _DrawWizardScreenState extends State<DrawWizardScreen> {
  LoanDesk? _desk;
  DrawDetail? _draw;
  bool _busyPaper = false;
  final _name = TextEditingController();
  final _signature = TextEditingController();
  final _comment = TextEditingController();
  final _payableNumber = TextEditingController();
  final _payableAmount = TextEditingController();
  final _requested = <String, TextEditingController>{};
  final _withheld = <String, TextEditingController>{};
  final _released = <String, TextEditingController>{};
  final _stored = <String, TextEditingController>{};
  final _adjustment = <String, TextEditingController>{};
  final _approved = <String, TextEditingController>{};
  final _sourceAmounts = <String, TextEditingController>{};
  final _requirementStatus = <String, String>{};
  var _finalDraw = false;
  var _loading = true;
  String? _error;
  String? _package;

  var _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _load();
  }

  @override
  void dispose() {
    _name.dispose();
    _signature.dispose();
    _comment.dispose();
    _payableNumber.dispose();
    _payableAmount.dispose();
    for (final group in [_requested, _withheld, _released, _stored, _adjustment, _approved, _sourceAmounts]) {
      for (final controller in group.values) {
        controller.dispose();
      }
    }
    super.dispose();
  }

  Future<void> _load() async {
    final api = SessionScope.of(context).api;
    final copy = LocaleScope.copy(context);
    try {
      final desk = await api.loan(widget.projectId);
      DrawDetail? draw;
      if (widget.drawId != null) draw = await api.draw(widget.drawId!);
      if (!mounted) return;
      _fill(desk, draw);
      if (draw == null) _name.text = copy.drawDefaultName;
      setState(() {
        _desk = desk;
        _draw = draw;
        _loading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.message;
      });
    }
  }

  void _fill(LoanDesk desk, DrawDetail? draw) {
    if (draw != null) {
      _name.text = draw.name;
      _signature.text = draw.signedName;
      _finalDraw = draw.finalDraw;
      for (final line in draw.lines) {
        _requested[line.budgetItemId] = TextEditingController(text: line.requested);
        _withheld[line.budgetItemId] = TextEditingController(text: line.retainageWithheld);
        _released[line.budgetItemId] = TextEditingController(text: line.retainageReleased);
        _stored[line.budgetItemId] = TextEditingController(text: line.storedMaterials);
        _adjustment[line.budgetItemId] = TextEditingController(text: line.adjustment);
        _approved[line.budgetItemId] = TextEditingController(text: line.approved);
      }
      for (final item in draw.requirements) {
        _requirementStatus[item.itemId] = item.status;
      }
    }
  }

  TextEditingController _field(Map<String, TextEditingController> group, String id) {
    return group.putIfAbsent(id, TextEditingController.new);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const ScreenScroll(children: [PageWait()]);
    final desk = _desk;
    final copy = LocaleScope.copy(context);
    if (desk == null) {
      return ScreenScroll(children: [Text(copy.known(_error ?? copy.requestMissing))]);
    }
    final uses = desk.lines.where((line) => line.side == 'use').toList();
    final draft = _draw == null || _draw!.status == 'draft';
    final bank = _draw?.status == 'tech_approved';
    final colors = context.colors;
    return ScreenScroll(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            style: backLinkStyle,
            onPressed: () => context.go('/projects/${widget.projectId}'),
            child: Text(copy.toProject),
          ),
        ),
        Text(copy.drawWizardTitle, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: AppSpacing.lg),
        IBuildCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                key: const Key('draw-name'),
                controller: _name,
                decoration: InputDecoration(labelText: copy.drawName),
              ),
              CheckboxListTile(
                key: const Key('final-draw'),
                contentPadding: EdgeInsets.zero,
                value: _finalDraw,
                onChanged: draft ? (value) => setState(() => _finalDraw = value ?? false) : null,
                title: Text(copy.finalDraw),
              ),
            ],
          ),
        ),
        for (final line in uses) ...[
          const SizedBox(height: AppSpacing.md),
          IBuildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${line.code}  ${line.title}', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: AppSpacing.md),
                _gap(TextField(
                  key: Key('requested-${line.id}'),
                  controller: _field(_requested, line.id),
                  decoration: InputDecoration(labelText: copy.drawRequested),
                )),
                _gap(TextField(
                  controller: _field(_withheld, line.id),
                  decoration: InputDecoration(labelText: copy.drawHoldback),
                )),
                _gap(TextField(
                  controller: _field(_released, line.id),
                  decoration: InputDecoration(labelText: copy.drawHoldbackRelease),
                )),
                _gap(TextField(
                  controller: _field(_stored, line.id),
                  decoration: InputDecoration(labelText: copy.drawStored),
                )),
                _gap(TextField(
                  controller: _field(_adjustment, line.id),
                  decoration: InputDecoration(labelText: copy.drawShift),
                )),
                Text(
                  copy.inspectorSays(_draw?.lines.where((item) => item.budgetItemId == line.id).map((item) => item.inspectorRecommend).join() ?? '—'),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.inkMuted),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  key: Key('approved-${line.id}'),
                  controller: _field(_approved, line.id),
                  decoration: InputDecoration(labelText: copy.drawApprovedField),
                ),
              ],
            ),
          ),
        ],
        if (desk.sources.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          IBuildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(copy.sources, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: AppSpacing.md),
                for (final source in desk.sources)
                  _gap(TextField(
                    controller: _field(_sourceAmounts, source.id),
                    decoration: InputDecoration(labelText: source.name),
                  )),
              ],
            ),
          ),
        ] else ...[
          const SizedBox(height: AppSpacing.md),
          IBuildCard(
            key: const Key('draw-no-sources'),
            child: Text(_noSourcesText(context, copy, widget.projectId)),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        _sitePhotosCard(context, copy, draft),
        if (_draw == null && draft) ...[
          const SizedBox(height: AppSpacing.md),
          IBuildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(copy.documents, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: AppSpacing.sm),
                Text(copy.docSaveFirst, key: const Key('documents-save-first')),
              ],
            ),
          ),
        ],
        if ((_draw?.requirements ?? const <DrawRequirementView>[]).isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          IBuildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(copy.documents, style: Theme.of(context).textTheme.titleMedium),
                if (draft) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(copy.docFilesHint, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.inkMuted)),
                ],
                for (final item in _draw!.requirements) ...[
                  const SizedBox(height: AppSpacing.md),
                  _paper(context, copy, item, draft),
                ],
              ],
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        IBuildCard(
          child: TextField(
            key: const Key('draw-signature'),
            controller: _signature,
            decoration: InputDecoration(labelText: copy.signature),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: AppSpacing.md),
          ErrorNote(message: copy.known(_error!)),
        ],
        const SizedBox(height: AppSpacing.lg),
        if (draft)
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              PrimaryButton(key: const Key('save-draw'), label: copy.saveDraft, onPressed: () { _save(); }),
              PrimaryButton(key: const Key('submit-draw'), label: copy.send, onPressed: () { _submit(); }),
            ],
          ),
        if (bank)
          PrimaryButton(key: const Key('decide-draw'), label: copy.trimDraw, onPressed: () { _decide(); }),
        if (_draw != null) ...[
          const SizedBox(height: AppSpacing.lg),
          IBuildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(copy.afterSending, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: AppSpacing.md),
                if (_draw!.comments.where((c) => c.isNotEmpty).isNotEmpty) ...[
                  Text(copy.pick('Комментарии и решения', 'Comments and decisions', 'Izohlar va qarorlar'),
                      key: const Key('draw-comments'),
                      style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: AppSpacing.sm),
                  for (final c in _draw!.comments.where((c) => c.isNotEmpty)) ...[
                    Text('• $c'),
                    const SizedBox(height: AppSpacing.xs),
                  ],
                  const SizedBox(height: AppSpacing.md),
                ],
                TextField(controller: _comment, decoration: InputDecoration(labelText: copy.commentLabel)),
                const SizedBox(height: AppSpacing.md),
                PrimaryButton(key: const Key('send-comment'), label: copy.sendComment, onPressed: () { _sendComment(); }),
                const SizedBox(height: AppSpacing.lg),
                TextField(
                  key: const Key('payable-number'),
                  controller: _payableNumber,
                  decoration: InputDecoration(labelText: copy.contractorInvoice),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(controller: _payableAmount, decoration: InputDecoration(labelText: copy.invoiceAmount)),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    PrimaryButton(key: const Key('save-payable'), label: copy.saveInvoice, onPressed: () { _payable(); }),
                    PrimaryButton(key: const Key('download-package'), label: copy.downloadPackage, onPressed: () { _download(); }),
                  ],
                ),
                if (_package != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: colors.surfaceAlt,
                      borderRadius: BorderRadius.circular(AppRadii.md),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: SelectableText(_package!),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _gap(Widget child) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: child,
    );
  }

  List<DrawLineInput> _lines(List<LoanLine> uses) {
    return [
      for (final line in uses)
        DrawLineInput(
          budgetItemId: line.id,
          requested: _field(_requested, line.id).text.trim(),
          adjustment: _field(_adjustment, line.id).text.trim(),
          retainageWithheld: _field(_withheld, line.id).text.trim(),
          retainageReleased: _field(_released, line.id).text.trim(),
          storedMaterials: _field(_stored, line.id).text.trim(),
        ),
    ];
  }

  Widget _paper(BuildContext context, AppCopy copy, DrawRequirementView item, bool draft) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final notNeeded = !item.present && (_requirementStatus[item.itemId] ?? item.status) == 'na';
    final state = item.present ? copy.docAttached : (notNeeded ? copy.docNotNeeded : copy.docMissing);
    final tone = item.present ? colors.success : (notNeeded ? colors.inkMuted : (item.required ? colors.warning : colors.inkMuted));
    final drawId = _draw!.id;
    return Column(
      key: Key('requirement-${item.code}'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                item.required
                    ? '${copy.documentTitle(item.code, item.title)} · ${copy.docRequiredMark}'
                    : copy.documentTitle(item.code, item.title),
              ),
            ),
            Text(state, key: Key('requirement-state-${item.code}'), style: theme.textTheme.bodySmall?.copyWith(color: tone)),
          ],
        ),
        if (item.beforeFiles && item.files.isEmpty)
          Text(copy.docMarkedBeforeFiles, style: theme.textTheme.bodySmall?.copyWith(color: colors.inkMuted)),
        for (final file in item.files)
          Row(
            children: [
              const Icon(Icons.description_outlined, size: 18),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Text(file.name, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall)),
              TextButton(
                key: Key('open-paper-${file.id}'),
                onPressed: () => openBankFile('/api/draws/$drawId/documents/${item.itemId}/${file.id}'),
                child: Text(copy.docOpen),
              ),
              if (draft)
                TextButton(
                  key: Key('remove-paper-${file.id}'),
                  onPressed: _busyPaper ? null : () { _removePaper(item, file); },
                  child: Text(copy.docRemove),
                ),
            ],
          ),
        if (draft)
          Wrap(
            spacing: AppSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              OutlinedButton.icon(
                key: Key('attach-${item.code}'),
                onPressed: _busyPaper ? null : () { _attachPaper(item); },
                icon: const Icon(Icons.attach_file, size: 18),
                label: Text(copy.docAttachFile),
              ),
              if (!item.required && !item.present)
                FilterChip(
                  key: Key('not-needed-${item.code}'),
                  label: Text(copy.docNotNeeded),
                  selected: notNeeded,
                  onSelected: (value) => setState(() => _requirementStatus[item.itemId] = value ? 'na' : 'missing'),
                ),
            ],
          ),
      ],
    );
  }

  Future<void> _reloadDraw() async {
    final draw = _draw;
    if (draw == null) return;
    final next = await SessionScope.of(context).api.draw(draw.id);
    if (!mounted) return;
    setState(() {
      _draw = next;
      for (final item in next.requirements) {
        if (item.present) _requirementStatus[item.itemId] = 'attached';
      }
    });
  }

  Widget _sitePhotosCard(BuildContext context, AppCopy copy, bool draft) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final photos = _draw?.photos ?? const <RequestFile>[];
    final drawId = _draw?.id;
    return IBuildCard(
      key: const Key('draw-site-photos'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  copy.pick(
                    'Фото с объекта · обязательно',
                    'Site photos · required',
                    'Obyektdan foto · majburiy',
                  ),
                  style: theme.textTheme.titleMedium,
                ),
              ),
              Text(
                photos.isEmpty
                    ? copy.pick('Не приложено', 'Missing', 'Yuklanmagan')
                    : '${photos.length} ${copy.pick('фото', 'photo(s)', 'foto')}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: photos.isEmpty ? colors.warning : colors.success,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            copy.pick(
              'На время теста достаточно загрузить фото файлом. Если в файле есть EXIF и геометки, они сохраняются.',
              'For the test, uploading a photo file is enough. EXIF and geotags are kept when the file has them.',
              'Test davrida foto faylini yuklash yetarli. Faylda EXIF va geoteglar bo‘lsa, ular saqlanadi.',
            ),
            style: theme.textTheme.bodySmall?.copyWith(color: colors.inkMuted),
          ),
          if (photos.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            for (final photo in photos) ...[
              Row(
                children: [
                  const Icon(Icons.photo_outlined, size: 18),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      '${copy.photoTile} · ${(photo.sizeBytes / 1024).toStringAsFixed(0)} KB',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                  if (drawId != null)
                    TextButton(
                      key: Key('open-draw-photo-${photo.id}'),
                      onPressed: () => openBankFile('/api/requests/$drawId/files/${photo.id}'),
                      child: Text(copy.docOpen),
                    ),
                  if (draft)
                    TextButton(
                      key: Key('remove-draw-photo-${photo.id}'),
                      onPressed: _busyPaper ? null : () => _removeSitePhoto(photo.id),
                      child: Text(copy.docRemove),
                    ),
                ],
              ),
              PhotoMetaPanel(file: photo),
              const SizedBox(height: AppSpacing.sm),
            ],
          ],
          if (draft) ...[
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                FilledButton.tonalIcon(
                  key: const Key('draw-photo-upload'),
                  onPressed: _busyPaper ? null : () => _addSitePhoto(camera: false),
                  icon: const Icon(Icons.upload_file_outlined, size: 18),
                  label: Text(copy.pick('Загрузить фото', 'Upload photo', 'Foto yuklash')),
                ),
                OutlinedButton.icon(
                  key: const Key('draw-photo-camera'),
                  onPressed: _busyPaper ? null : () => _addSitePhoto(camera: true),
                  icon: const Icon(Icons.photo_camera_outlined, size: 18),
                  label: Text(copy.pick('Сделать фото', 'Take photo', 'Suratga olish')),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _addSitePhoto({required bool camera}) async {
    final picked = await pickTranchePhoto(camera: camera);
    if (picked == null || !mounted) return;
    final api = SessionScope.of(context).api;
    final copy = LocaleScope.copy(context);
    setState(() {
      _busyPaper = true;
      _error = null;
    });
    try {
      final id = await _ensureId();
      await api.uploadRequestFile(
        requestId: id,
        bytes: picked.bytes,
        meta: picked.meta,
      );
      await _reloadDraw();
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = copy.known(error.message));
    } finally {
      if (mounted) setState(() => _busyPaper = false);
    }
  }

  Future<void> _removeSitePhoto(String fileId) async {
    final draw = _draw;
    if (draw == null) return;
    final api = SessionScope.of(context).api;
    final copy = LocaleScope.copy(context);
    setState(() => _busyPaper = true);
    try {
      await api.deleteRequestFile(requestId: draw.id, fileId: fileId);
      await _reloadDraw();
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = copy.known(error.message));
    } finally {
      if (mounted) setState(() => _busyPaper = false);
    }
  }

  Future<void> _attachPaper(DrawRequirementView item) async {
    final draw = _draw;
    if (draw == null) return;
    final picked = await pickRequestFile();
    if (picked == null || !mounted) return;
    final api = SessionScope.of(context).api;
    final copy = LocaleScope.copy(context);
    setState(() {
      _busyPaper = true;
      _error = null;
    });
    try {
      await api.uploadDrawDocument(
        drawId: draw.id,
        itemId: item.itemId,
        name: picked.name,
        bytes: picked.bytes,
        meta: picked.meta,
      );
      await _reloadDraw();
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = copy.known(error.message));
    } finally {
      if (mounted) setState(() => _busyPaper = false);
    }
  }

  Future<void> _removePaper(DrawRequirementView item, DrawDocumentFile file) async {
    final draw = _draw;
    if (draw == null) return;
    final api = SessionScope.of(context).api;
    final copy = LocaleScope.copy(context);
    setState(() => _busyPaper = true);
    try {
      await api.deleteDrawDocument(drawId: draw.id, itemId: item.itemId, fileId: file.id);
      _requirementStatus.remove(item.itemId);
      await _reloadDraw();
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = copy.known(error.message));
    } finally {
      if (mounted) setState(() => _busyPaper = false);
    }
  }

  Future<String> _ensureId() async {
    final existing = widget.drawId ?? _draw?.id;
    if (existing != null) return existing;
    final api = SessionScope.of(context).api;
    final id = await api.createDraw(
      projectId: widget.projectId,
      name: _name.text.trim(),
    );
    _draw = await api.draw(id);
    for (final item in _draw!.requirements) {
      _requirementStatus.putIfAbsent(item.itemId, () => item.status);
    }
    return id;
  }

  Future<void> _save() async {
    await _persist(submit: false);
  }

  Future<void> _submit() async {
    await _persist(submit: true);
  }

  Future<void> _persist({required bool submit}) async {
    final api = SessionScope.of(context).api;
    final desk = _desk;
    if (desk == null) return;
    try {
      final id = await _ensureId();
      final saved = await api.saveDraw(
        id: id,
        name: _name.text.trim(),
        finalDraw: _finalDraw,
        signedName: _signature.text.trim(),
        lines: _lines(desk.lines.where((line) => line.side == 'use').toList()),
        sources: [
          for (final source in desk.sources)
            {'sourceId': source.id, 'amount': _field(_sourceAmounts, source.id).text.trim()},
        ],
        requirements: [
          for (final item in _draw?.requirements ?? const <DrawRequirementView>[])
            {'itemId': item.itemId, 'status': _requirementStatus[item.itemId] ?? item.status, 'note': ''},
        ],
      );
      final next = submit ? await api.submitDraw(id) : saved;
      if (!mounted) return;
      setState(() {
        _draw = next;
        _error = null;
      });
      if (submit) context.go('/projects/${widget.projectId}');
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    }
  }

  Future<void> _decide() async {
    final draw = _draw;
    final desk = _desk;
    if (draw == null || desk == null) return;
    try {
      final next = await SessionScope.of(context).api.decideDraw(
        id: draw.id,
        lines: [
          for (final line in desk.lines.where((line) => line.side == 'use'))
            {'budgetItemId': line.id, 'approved': _field(_approved, line.id).text.trim()},
        ],
      );
      if (mounted) setState(() => _draw = next);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    }
  }

  Future<void> _sendComment() async {
    final draw = _draw;
    if (draw == null) return;
    try {
      await SessionScope.of(context).api.commentDraw(id: draw.id, body: _comment.text.trim());
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    }
  }

  Future<void> _payable() async {
    final draw = _draw;
    final desk = _desk;
    if (draw == null || desk == null || desk.firms.isEmpty || desk.lines.isEmpty) return;
    try {
      await SessionScope.of(context).api.addPayable(
        id: draw.id,
        budgetItemId: desk.lines.first.id,
        firmId: desk.firms.first.id,
        number: _payableNumber.text.trim(),
        amount: _payableAmount.text.trim(),
        waiver: 'signed',
      );
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    }
  }

  Future<void> _download() async {
    final draw = _draw;
    if (draw == null) return;
    try {
      final text = await SessionScope.of(context).api.drawPackage(draw.id);
      if (mounted) setState(() => _package = text);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    }
  }
}
