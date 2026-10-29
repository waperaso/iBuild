import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../api.dart';
import '../file_pick.dart';
import '../l10n.dart';
import '../models.dart';
import '../money.dart';
import '../picked_file.dart';
import '../session_scope.dart';
import '../theme.dart';
import '../widgets.dart';

class RequestFormData {
  const RequestFormData({
    required this.projects,
    required this.projectId,
    required this.lines,
  });

  final List<ProjectSummary> projects;
  final String? projectId;
  final List<BudgetLine> lines;
}

Future<void> openRequestForm(BuildContext context) async {
  final session = SessionScope.of(context);
  final mine = [
    for (final project in session.projects)
      if (project.myRole == AppRole.contractor ||
          project.myRole == AppRole.director ||
          project.myRole == AppRole.developer)
        project,
  ];
  final projectId = mine.isEmpty ? null : mine.first.id;
  var lines = const <BudgetLine>[];
  if (projectId != null) {
    try {
      lines = (await session.api.budget(projectId)).items;
    } on ApiException {
      lines = const [];
    }
  }
  if (!context.mounted) return;
  context.go(
    '/requests/new',
    extra: RequestFormData(projects: mine, projectId: projectId, lines: lines),
  );
}

class RequestFormScreen extends StatefulWidget {
  const RequestFormScreen({super.key, this.initial});

  final RequestFormData? initial;

  @override
  State<RequestFormScreen> createState() => _RequestFormScreenState();
}

class _RequestFormScreenState extends State<RequestFormScreen> {
  final _amount = TextEditingController();
  final _why = TextEditingController();
  final _type = TextEditingController();
  PickedFile? _photo;
  bool _saving = false;
  String? _error;
  List<ProjectSummary> _projects = const [];
  List<BudgetLine> _lines = const [];
  String? _projectId;
  String? _lineId;
  var _started = false;
  var _loading = true;

  @override
  void initState() {
    super.initState();
    final ready = widget.initial;
    if (ready == null) return;
    _projects = ready.projects;
    _projectId = ready.projectId;
    _lines = ready.lines;
    _lineId = ready.lines.isEmpty ? null : ready.lines.first.id;
    _loading = false;
    _started = true;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _load();
  }

  Future<void> _load() async {
    final mine = [
      for (final project in SessionScope.of(context).projects)
        if (project.myRole == AppRole.contractor ||
          project.myRole == AppRole.director ||
          project.myRole == AppRole.developer)
        project,
    ];
    if (!mounted) return;
    setState(() {
      _projects = mine;
      _projectId = mine.isEmpty ? null : mine.first.id;
    });
    await _loadLines();
  }

  Future<void> _loadLines() async {
    final projectId = _projectId;
    if (projectId == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      final budget = await SessionScope.of(context).api.budget(projectId);
      if (!mounted) return;
      setState(() {
        _lines = budget.items;
        _lineId = _lines.isEmpty ? null : _lines.first.id;
        _loading = false;
      });
    } on ApiException {
      if (!mounted) return;
      setState(() {
        _lines = const [];
        _lineId = null;
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    final projectId = _projectId;
    final lineId = _lineId;
    final custom = _type.text.trim();
    if (projectId == null || _saving) return;
    if (custom.isEmpty && lineId == null) return;
    final copy = LocaleScope.copy(context);
    setState(() {
      _saving = true;
      _error = null;
    });
    final api = SessionScope.of(context).api;
    try {
      final created = await api.createRequest(
        projectId: projectId,
        budgetItemId: lineId ?? '',
        amount: _amount.text.trim(),
        description: _why.text.trim(),
        customTitle: custom.isEmpty ? null : custom,
      );
      final photo = _photo;
      if (photo != null) {
        await api.uploadRequestFile(
          requestId: created.id,
          bytes: photo.bytes,
        );
      }
      if (!mounted) return;
      context.go('/requests/${created.id}', extra: created);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = copy.known(error.message);
      });
    }
  }

  BudgetLine? get _line {
    for (final line in _lines) {
      if (line.id == _lineId) return line;
    }
    return null;
  }

  @override
  void dispose() {
    _amount.dispose();
    _why.dispose();
    _type.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = SessionScope.of(context).user;
    final contractor = user?.isContractor == true || user?.isDirector == true;
    final copy = LocaleScope.copy(context);
    final colors = context.colors;
    final line = _line;
    return ScreenScroll(
      children: [
        TextButton(
          style: backLinkStyle,
          onPressed: () => context.go('/requests'),
          child: Text(copy.backToRequests),
        ),
        Text(
          copy.newRequest,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: AppSpacing.md),
        if (!contractor)
          EmptyState(
            title: copy.formForContractor,
            body: copy.formForContractorBody,
          )
        else
          IBuildCard(
            key: const Key('request-form'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_projects.length > 1) ...[
                  DropdownButtonFormField<String>(
                    initialValue: _projectId,
                    decoration: InputDecoration(labelText: copy.projects),
                    items: [
                      for (final project in _projects)
                        DropdownMenuItem(
                          value: project.id,
                          child: Text(copy.place(project.name)),
                        ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _projectId = value;
                        _loading = true;
                      });
                      _loadLines();
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                if (_loading)
                  const SizedBox(height: 48)
                else if (_lines.isEmpty)
                  InputDecorator(
                    decoration: InputDecoration(labelText: copy.whatFor),
                    child: Text(copy.noPlanYet),
                  )
                else
                  DropdownButtonFormField<String>(
                    key: const Key('request-line'),
                    initialValue: _lineId,
                    decoration: InputDecoration(labelText: copy.whatFor),
                    items: [
                      for (final item in _lines)
                        DropdownMenuItem(
                          value: item.id,
                          child: Text(
                            '${item.title} · ${moneyUzs(item.amount)}',
                          ),
                        ),
                    ],
                    onChanged: (value) => setState(() => _lineId = value),
                  ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  key: const Key('custom-type'),
                  controller: _type,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: copy.customType,
                    hintText: copy.customTypeHint,
                  ),
                ),
                if (_type.text.trim().isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    copy.customTypeNote,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.inkMuted),
                  ),
                ],
                if (line != null && _type.text.trim().isEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    '${copy.lineAvailable}: ${moneyUzs(line.available)}',
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${copy.linePlan}: ${moneyUzs(line.amount)} · ${line.contractorFirmName}',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: colors.inkMuted),
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                TextField(
                  key: const Key('request-price'),
                  controller: _amount,
                  keyboardType: TextInputType.text,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: copy.price,
                    hintText: '0.00',
                    helperText: copy.amountHelper,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  key: const Key('request-why'),
                  controller: _why,
                  minLines: 3,
                  maxLines: 5,
                  decoration: InputDecoration(labelText: copy.description),
                ),
                const SizedBox(height: AppSpacing.md),
                OutlinedButton(
                  key: const Key('request-photo'),
                  onPressed: () async {
                    final file = await pickRequestFile();
                    if (file != null && mounted) setState(() => _photo = file);
                  },
                  child: Text(_photo == null ? copy.photoEvidence : _photo!.name),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  copy.photoEvidenceNote,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: colors.inkMuted),
                ),
                const SizedBox(height: AppSpacing.lg),
                if (_error != null) ...[
                  Text(
                    _error!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.danger,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                PrimaryButton(
                  key: const Key('save-draft'),
                  label: copy.saveDraft,
                  busy: _saving,
                  onPressed: _amount.text.trim().isEmpty ||
                          (_type.text.trim().isEmpty && _lineId == null)
                      ? null
                      : _save,
                ),
              ],
            ),
          ),
      ],
    );
  }
}
