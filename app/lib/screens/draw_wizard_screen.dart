import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../api.dart';
import '../l10n.dart';
import '../models.dart';
import '../session_scope.dart';
import '../theme.dart';
import '../widgets.dart';

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
    if (_loading) return const SizedBox.expand();
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
        ],
        if ((_draw?.requirements ?? const <DrawRequirementView>[]).isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          IBuildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(copy.documents, style: Theme.of(context).textTheme.titleMedium),
                for (final item in _draw!.requirements) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(copy.documentTitle(item.code, item.title)),
                  DropdownButton<String>(
                    key: Key('requirement-${item.code}'),
                    isExpanded: true,
                    value: _requirementStatus[item.itemId] ?? item.status,
                    items: [
                      DropdownMenuItem(value: 'missing', child: Text(copy.docMissing)),
                      DropdownMenuItem(value: 'attached', child: Text(copy.docAttached)),
                      DropdownMenuItem(value: 'na', child: Text(copy.docNotNeeded)),
                    ],
                    onChanged: draft
                        ? (value) => setState(() => _requirementStatus[item.itemId] = value ?? 'missing')
                        : null,
                  ),
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
