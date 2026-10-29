import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../api.dart';
import '../l10n.dart';
import '../models.dart';
import '../object_passport.dart';
import '../money.dart';
import '../session_scope.dart';
import '../theme.dart';
import '../widgets.dart';
import 'loan_panels.dart';

class ProjectReady {
  const ProjectReady({
    required this.project,
    required this.budget,
    required this.members,
    required this.firms,
  });

  final ProjectSummary project;
  final BudgetSnapshot budget;
  final List<ProjectMember> members;
  final List<ContractorFirm> firms;
}

Future<void> openProject(BuildContext context, String id) async {
  final session = SessionScope.of(context);
  try {
    final project = await session.api.project(id);
    final budget = await session.api.budget(id);
    final members = await session.api.members(id);
    final firms = project.myRole == AppRole.director ||
            project.myRole == AppRole.developer ||
            project.myRole == AppRole.observer
        ? await session.api.firms()
        : const <ContractorFirm>[];
    if (!context.mounted) return;
    session.rememberProject(project);
    context.go(
      '/projects/$id',
      extra: ProjectReady(
        project: project,
        budget: budget,
        members: members,
        firms: firms,
      ),
    );
  } on ApiException {
    if (!context.mounted) return;
    context.go('/projects/$id');
  }
}

class ProjectScreen extends StatefulWidget {
  const ProjectScreen({super.key, required this.id, this.initial});

  final String id;
  final ProjectReady? initial;

  @override
  State<ProjectScreen> createState() => _ProjectScreenState();
}

class _ProjectScreenState extends State<ProjectScreen> {
  ProjectSummary? _project;
  BudgetSnapshot? _budget;
  List<ProjectMember> _members = const [];
  List<ContractorFirm> _firms = const [];
  List<ProjectDocument> _documents = const [];
  LoanDesk _desk = LoanDesk.empty;
  var _tab = 0;
  String? _error;
  var _loading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final cached = SessionScope.of(context).findProject(widget.id);
    if (cached != null && _project == null) {
      _project = cached;
      _loading = false;
    }
    final requested = int.tryParse(
      GoRouterState.of(context).uri.queryParameters['tab'] ?? '',
    );
    if (requested != null && requested >= 0 && requested <= 4 && requested != _tab) {
      _tab = requested;
    }
    if (_started) return;
    _started = true;
    _load();
  }

  var _started = false;

  @override
  void initState() {
    super.initState();
    final ready = widget.initial;
    if (ready != null && ready.project.id == widget.id) {
      _project = ready.project;
      _budget = ready.budget;
      _members = ready.members;
      _firms = ready.firms;
      _loading = false;
    }
  }

  Future<void> _load() async {
    final session = SessionScope.of(context);
    try {
      final fresh = await session.api.project(widget.id);
      final budget = await session.api.budget(widget.id);
      final members = await session.api.members(widget.id);
      final documents = await session.api.projectDocuments(widget.id);
      final firms = fresh.myRole == AppRole.director || fresh.myRole == AppRole.developer
          ? await session.api.firms()
          : const <ContractorFirm>[];
      LoanDesk desk = LoanDesk.empty;
      try {
        desk = await session.api.loan(widget.id);
      } on ApiException {
        desk = LoanDesk.empty;
      }
      if (!mounted) return;
      session.rememberProject(fresh);
      setState(() {
        _project = fresh;
        _budget = budget;
        _members = members;
        _firms = firms;
        _documents = documents;
        _desk = desk;
        _loading = false;
        _error = null;
      });
    } on ApiException catch (failure) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        if (_project == null) _error = failure.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final copy = LocaleScope.copy(context);
    if (_loading && _project == null) {
      return const SizedBox.expand();
    }
    if (_project == null) {
      return ScreenScroll(
        children: [
          EmptyState(
            title: copy.projectUnavailable,
            body: _error == null
                ? copy.projectNotAssigned
                : copy.known(_error!),
          ),
        ],
      );
    }
    final project = _project!;
    return ScreenScroll(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            style: backLinkStyle,
            onPressed: () => context.go('/projects'),
            child: Text(copy.backToProjects),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        IBuildCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(project.name, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: AppSpacing.sm),
              Text(
                project.address,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.inkMuted),
              ),
              const SizedBox(height: AppSpacing.lg),
              ObjectPassport(project: project, documents: _documents),
              const SizedBox(height: AppSpacing.lg),
              Wrap(
                spacing: AppSpacing.lg,
                runSpacing: AppSpacing.sm,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text('${copy.yourRole} ${copy.roleName(project.myRole)}'),
                  StatusText(
                    label: copy.projectStatus(project.active),
                    tone: project.active ? StatusTone.good : StatusTone.neutral,
                  ),
                  TextButton(
                    key: const Key('project-requests'),
                    style: backLinkStyle,
                    onPressed: () => context.go('/requests?project=${project.id}'),
                    child: Text(copy.requestsForProject),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        IBuildCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          LayoutBuilder(
          builder: (context, constraints) {
            final narrow = constraints.maxWidth < 900;
            final tiles = [
              _Metric(label: copy.plan, value: project.plan),
              _Metric(label: copy.reserved, value: project.reserved),
              _Metric(label: copy.paid, value: project.paid),
              _Metric(
                label: copy.available,
                value: project.available,
                emphasize: true,
              ),
            ];
            if (narrow) {
              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: tiles[0]),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(child: tiles[1]),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(child: tiles[2]),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(child: tiles[3]),
                    ],
                  ),
                ],
              );
            }
            return Row(
              children: [
                for (final tile in tiles) ...[
                  Expanded(child: tile),
                  if (tile != tiles.last) const SizedBox(width: AppSpacing.md),
                ],
              ],
            );
          },
        ),
              const SizedBox(height: AppSpacing.md),
              Text(
                copy.formula,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.inkMuted),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final (index, label) in [
              (0, copy.budget),
              (1, copy.requests),
              (2, copy.inspections),
              (3, copy.documents),
              (4, copy.people),
            ])
              _SectionTab(
                key: Key('project-tab-$index'),
                label: label,
                selected: _tab == index,
                onPressed: () {
                  setState(() => _tab = index);
                  context.go('/projects/${project.id}?tab=$index');
                },
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        if (_tab == 0) ...[
          SourcesUsesTable(desk: _desk),
          const SizedBox(height: AppSpacing.xl),
          BudgetTools(project: project, firms: _firms, onChanged: _load),
          const SizedBox(height: AppSpacing.xl),
          BudgetSection(
            project: project,
            budget: _budget,
            firms: _firms,
            onChanged: _load,
          ),
        ],
        if (_tab == 1) DrawsPanel(project: project, desk: _desk),
        if (_tab == 2)
          InspectionsPanel(project: project, desk: _desk, onChanged: _load),
        if (_tab == 3)
          DocumentsPanel(project: project, desk: _desk, onChanged: _load),
        if (_tab == 4)
          MembersSection(
            project: project,
            members: _members,
            firms: _firms,
            onChanged: _load,
          ),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value, this.emphasize = false});

  final String label;
  final String? value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final ink = emphasize ? colors.accent : colors.ink;
    final muted = colors.inkMuted;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: muted),
          ),
          const SizedBox(height: AppSpacing.sm),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              moneyUzs(value),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: ink,
                letterSpacing: -0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTab extends StatelessWidget {
  const _SectionTab({
    super.key,
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: selected ? colors.accent : colors.inkMuted,
        backgroundColor: Colors.transparent,
        minimumSize: const Size(0, 44),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        shape: const RoundedRectangleBorder(),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected ? colors.accent : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Text(label),
        ),
      ),
    );
  }
}

class BudgetSection extends StatelessWidget {
  const BudgetSection({super.key,
    required this.project,
    required this.budget,
    required this.firms,
    required this.onChanged,
  });

  final ProjectSummary project;
  final BudgetSnapshot? budget;
  final List<ContractorFirm> firms;
  final Future<void> Function() onChanged;

  @override
  Widget build(BuildContext context) {
    final copy = LocaleScope.copy(context);
    final items = budget?.items ?? const <BudgetLine>[];
    final director = project.myRole == AppRole.director || project.myRole == AppRole.developer;
    final bank = project.myRole == AppRole.observer;
    final locked = budget?.locked ?? project.budgetLocked;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(copy.budget, style: Theme.of(context).textTheme.headlineSmall),
            ),
            if ((director || bank) && !locked)
              PrimaryButton(
                key: const Key('add-budget-line'),
                label: bank ? copy.setLimit : copy.addLine,
                onPressed: () => _addLine(context),
              ),
          ],
        ),
        if (director)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              key: const Key('add-firm'),
              style: backLinkStyle,
              onPressed: () async {
                if (await _addFirm(context) && context.mounted) {
                  await onChanged();
                }
              },
              child: Text(copy.newFirm),
            ),
          ),
        const SizedBox(height: AppSpacing.sm),
        if (locked)
          Text(
            copy.budgetLocked,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: context.colors.inkMuted),
          ),
        const SizedBox(height: AppSpacing.md),
        LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 560;
            VoidCallback? edit(BudgetLine item) =>
                (director || (bank && !item.planSet)) && !locked
                    ? () => _editLine(context, item)
                    : null;
            VoidCallback? remove(BudgetLine item) =>
                director && !locked ? () => _removeLine(context, item) : null;
            if (compact) {
              return Column(
                key: const Key('budget-cards'),
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (items.isEmpty)
                    EmptyState(title: copy.noLines, body: copy.noLinesBody)
                  else
                    for (final item in items) ...[
                      _LineCard(line: item, onEdit: edit(item), onRemove: remove(item)),
                      const SizedBox(height: AppSpacing.md),
                    ],
                ],
              );
            }
            if (items.isEmpty) {
              return EmptyState(
                key: const Key('budget-table'),
                title: copy.noLines,
                body: copy.noLinesBody,
              );
            }
            return IBuildCard(
              key: const Key('budget-table'),
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  const _LineHeader(),
                  for (final item in items) ...[
                    Divider(height: 1, color: context.colors.outline),
                    _LineRow(line: item, onEdit: edit(item), onRemove: remove(item)),
                  ],
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Future<bool> _addFirm(BuildContext context) async {
    final name = TextEditingController();
    final inn = TextEditingController();
    final contact = TextEditingController();
    String? error;
    var saved = false;
    await showPlainDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            final copy = LocaleScope.copy(context);
            return AlertDialog(
              title: Text(copy.contractor),
              content: SizedBox(
                width: dialogFieldWidth(context),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: name,
                      decoration: InputDecoration(labelText: copy.name),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      controller: inn,
                      decoration: InputDecoration(labelText: copy.inn),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      controller: contact,
                      decoration: InputDecoration(labelText: copy.contact),
                    ),
                    if (error != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        copy.known(error!),
                        style: TextStyle(color: context.colors.danger),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(copy.cancel),
                ),
                TextButton(
                  onPressed: () async {
                    try {
                      await SessionScope.of(context).api.createFirm(
                        name: name.text.trim(),
                        inn: inn.text.trim(),
                        contact: contact.text.trim(),
                      );
                      saved = true;
                      if (dialogContext.mounted) {
                        Navigator.of(dialogContext).pop();
                      }
                    } on ApiException catch (failure) {
                      setState(() => error = failure.message);
                    }
                  },
                  child: Text(copy.save),
                ),
              ],
            );
          },
        );
      },
    );
    name.dispose();
    inn.dispose();
    contact.dispose();
    return saved;
  }

  Future<bool> _addLine(BuildContext context) async {
    var currentFirms = firms;
    var createdFirm = false;
    if (currentFirms.isEmpty) {
      createdFirm = await _addFirm(context);
      if (!createdFirm || !context.mounted) return false;
      currentFirms = await SessionScope.of(context).api.firms();
      if (currentFirms.isEmpty || !context.mounted) return false;
    }
    final saved = await _lineDialog(context, firms: currentFirms);
    if (createdFirm && !saved && context.mounted) await onChanged();
    return saved;
  }

  Future<bool> _editLine(BuildContext context, BudgetLine line) {
    return _lineDialog(context, firms: firms, line: line);
  }

  Future<void> _removeLine(BuildContext context, BudgetLine line) async {
    final copy = LocaleScope.copy(context);
    final confirmed = await _confirm(
      context,
      copy.removeLineTitle,
      copy.removeLineBody,
    );
    if (!confirmed || !context.mounted) return;
    try {
      await SessionScope.of(
        context,
      ).api.deleteBudgetLine(projectId: project.id, itemId: line.id);
      await onChanged();
    } on ApiException catch (failure) {
      if (!context.mounted) return;
      await _note(
        context,
        copy.removeLineTitle,
        LocaleScope.copy(context).known(failure.message),
      );
    }
  }

  Future<bool> _lineDialog(
    BuildContext context, {
    required List<ContractorFirm> firms,
    BudgetLine? line,
  }) async {
    final title = TextEditingController(text: line?.title ?? '');
    final amount = TextEditingController(text: line?.amount ?? '');
    var firmId = line?.contractorFirmId ?? firms.first.id;
    String? error;
    var saved = false;
    await showPlainDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            final copy = LocaleScope.copy(context);
            return AlertDialog(
              title: Text(copy.lineTitle),
              content: SizedBox(
                width: dialogFieldWidth(context),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      key: const Key('budget-title'),
                      controller: title,
                      decoration: InputDecoration(labelText: copy.workName),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      key: const Key('budget-amount'),
                      controller: amount,
                      decoration: InputDecoration(
                        labelText: copy.amountUzs,
                        hintText: '12500000.00',
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    DropdownButtonFormField<String>(
                      initialValue: firmId,
                      decoration: InputDecoration(labelText: copy.contractor),
                      items: [
                        for (final firm in firms)
                          DropdownMenuItem(
                            value: firm.id,
                            child: Text(firm.name),
                          ),
                      ],
                      onChanged: (value) {
                        if (value != null) setState(() => firmId = value);
                      },
                    ),
                    if (error != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        copy.known(error!),
                        style: TextStyle(color: context.colors.danger),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(copy.cancel),
                ),
                TextButton(
                  key: const Key('budget-save'),
                  onPressed: () async {
                    try {
                      final api = SessionScope.of(context).api;
                      final nextTitle = title.text.trim();
                      final nextAmount = amount.text.trim();
                      if (line == null) {
                        await api.createBudgetLine(
                          projectId: project.id,
                          title: nextTitle,
                          amount: nextAmount,
                          contractorFirmId: firmId,
                        );
                      } else {
                        await api.updateBudgetLine(
                          projectId: project.id,
                          itemId: line.id,
                          title: nextTitle,
                          amount: nextAmount,
                          contractorFirmId: firmId,
                        );
                      }
                      saved = true;
                      if (dialogContext.mounted) {
                        Navigator.of(dialogContext).pop();
                      }
                    } on ApiException catch (failure) {
                      setState(() => error = failure.message);
                    }
                  },
                  child: Text(copy.save),
                ),
              ],
            );
          },
        );
      },
    );
    title.dispose();
    amount.dispose();
    if (saved && context.mounted) await onChanged();
    return saved;
  }
}

Future<void> _note(BuildContext context, String title, String body) {
  final copy = LocaleScope.copy(context);
  return showPlainDialog<void>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(copy.cancel),
          ),
        ],
      );
    },
  );
}

Future<bool> _confirm(BuildContext context, String title, String body) async {
  final copy = LocaleScope.copy(context);
  final result = await showPlainDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(copy.cancel),
          ),
          TextButton(
            key: const Key('confirm-remove'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(copy.remove),
          ),
        ],
      );
    },
  );
  return result == true;
}

class _LineHeader extends StatelessWidget {
  const _LineHeader();

  @override
  Widget build(BuildContext context) {
    final copy = LocaleScope.copy(context);
    final style = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(color: context.colors.inkMuted);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(copy.work, style: style)),
          Expanded(flex: 3, child: Text(copy.contractor, style: style)),
          Expanded(
            flex: 2,
            child: Text(copy.plan, style: style, textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }
}

class _LineRow extends StatelessWidget {
  const _LineRow({required this.line, this.onEdit, this.onRemove});

  final BudgetLine line;
  final VoidCallback? onEdit;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final copy = LocaleScope.copy(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(line.title, maxLines: 2, overflow: TextOverflow.ellipsis),
                if (!line.planSet)
                  Text(
                    copy.limitMissing,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: context.colors.inkMuted),
                  ),
              ],
            ),
          ),
          Expanded(flex: 3, child: Text(line.contractorFirmName, maxLines: 2, overflow: TextOverflow.ellipsis)),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  moneyUzs(line.amount),
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                _LineRemainder(line: line),
                _LineActions(line: line, onEdit: onEdit, onRemove: onRemove),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LineCard extends StatelessWidget {
  const _LineCard({required this.line, this.onEdit, this.onRemove});

  final BudgetLine line;
  final VoidCallback? onEdit;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final copy = LocaleScope.copy(context);
    return IBuildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!line.planSet)
                      Text(
                        copy.limitMissing,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: context.colors.inkMuted),
                      ),
                    Text(
                      line.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      line.contractorFirmName,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: context.colors.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    moneyUzs(line.amount),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  _LineRemainder(line: line),
                ],
              ),
            ],
          ),
          if (onEdit != null || onRemove != null) ...[
            const SizedBox(height: AppSpacing.sm),
            _LineActions(line: line, onEdit: onEdit, onRemove: onRemove),
          ],
        ],
      ),
    );
  }
}

class _LineRemainder extends StatelessWidget {
  const _LineRemainder({required this.line});

  final BudgetLine line;

  @override
  Widget build(BuildContext context) {
    final copy = LocaleScope.copy(context);
    final style = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(color: context.colors.inkMuted);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (line.reserved != '0.00')
          Text('${copy.reserved} ${moneyUzs(line.reserved)}', style: style, textAlign: TextAlign.right),
        if (line.paid != '0.00')
          Text('${copy.paid} ${moneyUzs(line.paid)}', style: style, textAlign: TextAlign.right),
        Text('${copy.available} ${moneyUzs(line.available)}', style: style, textAlign: TextAlign.right),
      ],
    );
  }
}

class _LineActions extends StatelessWidget {
  const _LineActions({required this.line, this.onEdit, this.onRemove});

  final BudgetLine line;
  final VoidCallback? onEdit;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    if (onEdit == null && onRemove == null) return const SizedBox.shrink();
    final copy = LocaleScope.copy(context);
    return Wrap(
      alignment: WrapAlignment.end,
      children: [
        if (onEdit != null)
          TextButton(
            key: Key('edit-line-${line.id}'),
            style: backLinkStyle,
            onPressed: onEdit,
            child: Text(copy.edit),
          ),
        if (onRemove != null)
          TextButton(
            key: Key('remove-line-${line.id}'),
            style: backLinkStyle,
            onPressed: onRemove,
            child: Text(copy.remove),
          ),
      ],
    );
  }
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({
    required this.member,
    required this.roleLabel,
    required this.removeLabel,
    this.onRemove,
  });

  final ProjectMember member;
  final String roleLabel;
  final String removeLabel;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(member.name, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  member.contractorFirmName == null
                      ? roleLabel
                      : '$roleLabel · ${member.contractorFirmName}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.inkMuted,
                  ),
                ),
              ],
            ),
          ),
          if (onRemove != null)
            TextButton(
              key: Key('remove-member-${member.id}'),
              style: backLinkStyle,
              onPressed: onRemove,
              child: Text(removeLabel),
            ),
        ],
      ),
    );
  }
}

class MembersSection extends StatelessWidget {
  const MembersSection({super.key,
    required this.project,
    required this.members,
    required this.firms,
    required this.onChanged,
  });

  final ProjectSummary project;
  final List<ProjectMember> members;
  final List<ContractorFirm> firms;
  final Future<void> Function() onChanged;

  @override
  Widget build(BuildContext context) {
    final copy = LocaleScope.copy(context);
    final director = project.myRole == AppRole.director || project.myRole == AppRole.developer;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              copy.members,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const Spacer(),
            if (director)
              PrimaryButton(
                key: const Key('add-member'),
                label: copy.assign,
                onPressed: () => _assign(context),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (members.isEmpty)
          EmptyState(title: copy.noMembers, body: copy.noMembersBody)
        else
          IBuildCard(
            key: const Key('member-list'),
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var i = 0; i < members.length; i++) ...[
                  if (i > 0) Divider(height: 1, color: context.colors.outline),
                  _MemberRow(
                    member: members[i],
                    roleLabel: copy.memberRole(members[i].role),
                    removeLabel: copy.remove,
                    onRemove: director && _canRemove(members[i], members)
                        ? () => _remove(context, members[i])
                        : null,
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }

  bool _canRemove(ProjectMember member, List<ProjectMember> members) {
    if (member.role != 'director') return true;
    final directors = members.where((item) => item.role == 'director').length;
    return directors > 1;
  }

  Future<void> _remove(BuildContext context, ProjectMember member) async {
    final copy = LocaleScope.copy(context);
    final confirmed = await _confirm(
      context,
      copy.removeMemberTitle,
      copy.removeMemberBody,
    );
    if (!confirmed || !context.mounted) return;
    try {
      await SessionScope.of(
        context,
      ).api.removeMember(projectId: project.id, memberId: member.id);
      await onChanged();
    } on ApiException catch (failure) {
      if (!context.mounted) return;
      await _note(
        context,
        copy.removeMemberTitle,
        LocaleScope.copy(context).known(failure.message),
      );
    }
  }

  Future<void> _assign(BuildContext context) async {
    List<CompanyUser> users;
    try {
      users = await SessionScope.of(context).api.companyUsers();
    } on ApiException catch (failure) {
      if (!context.mounted) return;
      await _note(
        context,
        LocaleScope.copy(context).assignment,
        LocaleScope.copy(context).known(failure.message),
      );
      return;
    }
    if (!context.mounted) return;
    final available = [
      for (final user in users)
        if (user.active && !members.any((member) => member.userId == user.id))
          user,
    ];
    if (available.isEmpty) {
      await _note(
        context,
        LocaleScope.copy(context).assignment,
        LocaleScope.copy(context).everyoneAssigned,
      );
      return;
    }
    var userId = available.first.id;
    var role = 'director';
    String? firmId = firms.isEmpty ? null : firms.first.id;
    String? error;
    var saved = false;
    await showPlainDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            final copy = LocaleScope.copy(context);
            return AlertDialog(
              title: Text(copy.assignment),
              content: SizedBox(
                width: dialogFieldWidth(context),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: userId,
                      decoration: InputDecoration(labelText: copy.employee),
                      items: [
                        for (final user in available)
                          DropdownMenuItem(
                            value: user.id,
                            child: Text(user.name),
                          ),
                      ],
                      onChanged: (value) {
                        if (value != null) setState(() => userId = value);
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    DropdownButtonFormField<String>(
                      initialValue: role,
                      decoration: InputDecoration(labelText: copy.role),
                      items: [
                        DropdownMenuItem(
                          value: 'director',
                          child: Text(copy.roleName(AppRole.director)),
                        ),
                        DropdownMenuItem(
                          value: 'observer',
                          child: Text(copy.roleName(AppRole.observer)),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) setState(() => role = value);
                      },
                    ),
                    if (error != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        copy.known(error!),
                        style: TextStyle(color: context.colors.danger),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(copy.cancel),
                ),
                TextButton(
                  onPressed: () async {
                    try {
                      await SessionScope.of(context).api.addMember(
                        projectId: project.id,
                        userId: userId,
                        role: role,
                        contractorFirmId: role == 'contractor' ? firmId : null,
                      );
                      saved = true;
                      if (dialogContext.mounted) {
                        Navigator.of(dialogContext).pop();
                      }
                    } on ApiException catch (failure) {
                      setState(() => error = failure.message);
                    }
                  },
                  child: Text(copy.assign),
                ),
              ],
            );
          },
        );
      },
    );
    if (saved) await onChanged();
  }
}
