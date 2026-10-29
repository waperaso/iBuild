import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../api.dart';
import '../l10n.dart';
import '../models.dart';
import '../money.dart';
import '../session_scope.dart';
import '../theme.dart';
import '../widgets.dart';

class SourcesUsesTable extends StatelessWidget {
  const SourcesUsesTable({super.key, required this.desk});

  final LoanDesk desk;

  @override
  Widget build(BuildContext context) {
    final uses = desk.lines.where((line) => line.side == 'use').toList();
    final sources = desk.sources;
    if (uses.isEmpty && sources.isEmpty) return const SizedBox.shrink();
    final copy = LocaleScope.copy(context);
    return IBuildCard(
      key: const Key('sources-uses'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(copy.moneyPlan, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.lg),
          if (sources.isNotEmpty) ...[
            Text(copy.sources, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            for (final source in sources) ...[
              _GridLine(
                code: source.kind,
                title: source.name,
                kind: '',
                original: moneyUzs(source.amount),
                adjusted: moneyUzs('0.00'),
                revised: moneyUzs(source.amount),
                funded: moneyUzs('0.00'),
                remaining: moneyUzs(source.amount),
                extra: '',
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ],
          if (uses.isNotEmpty)
            Text(copy.uses, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          for (final line in uses) ...[
            _GridLine(
              code: line.code,
              title: line.title,
              kind: line.kind,
              original: moneyUzs(line.shownOriginal),
              adjusted: moneyUzs(line.adjusted),
              revised: moneyUzs(line.shownRevised),
              funded: moneyUzs(line.funded),
              remaining: moneyUzs(line.shownRemaining),
              extra: copy.holdback(line.retainagePercent, line.percentComplete.isEmpty ? '—' : line.percentComplete),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ],
      ),
    );
  }
}

class BudgetTools extends StatefulWidget {
  const BudgetTools({super.key, required this.project, required this.firms, required this.onChanged});

  final ProjectSummary project;
  final List<ContractorFirm> firms;
  final Future<void> Function() onChanged;

  @override
  State<BudgetTools> createState() => _BudgetToolsState();
}

class _BudgetToolsState extends State<BudgetTools> {
  final _csv = TextEditingController();
  final _template = TextEditingController();
  String? _fromProject;
  String? _firmId;
  String? _error;
  var _open = false;

  @override
  void dispose() {
    _csv.dispose();
    _template.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final role = widget.project.myRole;
    if (role != AppRole.director && role != AppRole.developer) {
      return const SizedBox.shrink();
    }
    _firmId ??= widget.firms.isEmpty ? null : widget.firms.first.id;
    final copy = LocaleScope.copy(context);
    return IBuildCard(
      key: const Key('budget-tools'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextButton(
            key: const Key('open-budget-tools'),
            onPressed: () => setState(() => _open = !_open),
            child: Text(copy.importBudget),
          ),
          if (!_open) const SizedBox.shrink() else ...[
          const SizedBox(height: AppSpacing.sm),
          Text(copy.importFormat),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            key: const Key('budget-csv'),
            controller: _csv,
            minLines: 2,
            maxLines: 4,
            decoration: InputDecoration(labelText: copy.importText),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            key: const Key('template-name'),
            controller: _template,
            decoration: InputDecoration(labelText: copy.templateName),
          ),
          const SizedBox(height: AppSpacing.sm),
          DropdownButtonFormField<String>(
            key: const Key('copy-from-project'),
            initialValue: _fromProject,
            decoration: InputDecoration(labelText: copy.copyFromProject),
            items: [
              for (final other in SessionScope.of(context).projects)
                if (other.id != widget.project.id)
                  DropdownMenuItem(value: other.id, child: Text(copy.place(other.name))),
            ],
            onChanged: (value) => setState(() => _fromProject = value),
          ),
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(copy.known(_error!)),
          ],
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              PrimaryButton(
                key: const Key('import-budget'),
                label: copy.doImport,
                onPressed: _firmId == null ? null : () { _import(); },
              ),
              PrimaryButton(
                key: const Key('save-template'),
                label: copy.saveTemplate,
                onPressed: () { _saveTemplate(); },
              ),
              PrimaryButton(
                key: const Key('copy-budget'),
                label: copy.doCopy,
                onPressed: _fromProject == null ? null : () { _copy(); },
              ),
            ],
          ),
          ],
        ],
      ),
    );
  }

  Future<void> _import() async {
    try {
      await SessionScope.of(context).api.importBudget(
        projectId: widget.project.id,
        contractorFirmId: _firmId!,
        csv: _csv.text,
      );
      _error = null;
      await widget.onChanged();
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    }
  }

  Future<void> _copy() async {
    try {
      await SessionScope.of(context).api.copyBudget(
        projectId: widget.project.id,
        fromProjectId: _fromProject!,
      );
      _error = null;
      await widget.onChanged();
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    }
  }

  Future<void> _saveTemplate() async {
    try {
      await SessionScope.of(context).api.saveBudgetTemplate(
        projectId: widget.project.id,
        name: _template.text.trim(),
      );
      if (mounted) setState(() => _error = null);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    }
  }
}

class DrawsPanel extends StatelessWidget {
  const DrawsPanel({super.key, required this.project, required this.desk});

  final ProjectSummary project;
  final LoanDesk desk;

  @override
  Widget build(BuildContext context) {
    final canFile = project.myRole == AppRole.director ||
        project.myRole == AppRole.contractor ||
        project.myRole == AppRole.developer;
    final copy = LocaleScope.copy(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (canFile)
          PrimaryButton(
            key: const Key('new-draw'),
            label: copy.newRequest,
            onPressed: () => context.go('/projects/${project.id}/draw'),
          ),
        const SizedBox(height: AppSpacing.md),
        if (desk.draws.isEmpty)
          EmptyState(title: copy.noRequests, body: copy.drawsEmptyBody)
        else
          for (final draw in desk.draws) ...[
            IBuildCard(
              key: draw == desk.draws.first ? const Key('draw-amounts') : null,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextButton(
                    style: backLinkStyle,
                    onPressed: () => context.go('/projects/${project.id}/draw?id=${draw.id}'),
                    child: Text(
                      draw.name.isEmpty ? draw.id : draw.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final figures = [
                        _Figure(label: copy.drawRequested, value: moneyUzs(draw.requested)),
                        _Figure(label: copy.drawRecommended, value: moneyUzs(draw.recommended)),
                        _Figure(label: copy.drawApproved, value: moneyUzs(draw.confirmed), emphasize: true),
                      ];
                      if (constraints.maxWidth < 640) {
                        return Column(
                          children: [
                            for (final figure in figures) ...[
                              figure,
                              if (figure != figures.last) const SizedBox(height: AppSpacing.sm),
                            ],
                          ],
                        );
                      }
                      return Row(
                        children: [
                          for (final figure in figures) ...[
                            Expanded(child: figure),
                            if (figure != figures.last) const SizedBox(width: AppSpacing.md),
                          ],
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
      ],
    );
  }
}

class InspectionsPanel extends StatefulWidget {
  const InspectionsPanel({
    super.key,
    required this.project,
    required this.desk,
    required this.onChanged,
  });

  final ProjectSummary project;
  final LoanDesk desk;
  final Future<void> Function() onChanged;

  @override
  State<InspectionsPanel> createState() => _InspectionsPanelState();
}

class _InspectionsPanelState extends State<InspectionsPanel> {
  final _gate = TextEditingController();
  final _note = TextEditingController();
  final _percents = <String, TextEditingController>{};
  final _recommends = <String, TextEditingController>{};
  final _comments = <String, TextEditingController>{};
  final _risks = <String, String>{};
  String? _requestId;
  String? _error;

  @override
  void dispose() {
    _gate.dispose();
    _note.dispose();
    for (final controller in _percents.values) {
      controller.dispose();
    }
    for (final controller in _recommends.values) {
      controller.dispose();
    }
    for (final controller in _comments.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uses = widget.desk.lines.where((line) => line.side == 'use').toList();
    final canReport = widget.project.myRole == AppRole.tech || widget.project.myRole == AppRole.developer;
    _requestId ??= widget.desk.draws.isEmpty ? null : widget.desk.draws.first.id;
    final copy = LocaleScope.copy(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final report in widget.desk.inspections) ...[
          IBuildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(report.scheduledOn, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: AppSpacing.xs),
                Text(copy.gateCodeIs(report.gateCode)),
                if (report.note.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(report.note),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        if (canReport && uses.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          IBuildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
          TextField(
            key: const Key('gate-code'),
            controller: _gate,
            decoration: InputDecoration(labelText: copy.gateCode),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _note,
            decoration: InputDecoration(labelText: copy.noteToInspector),
          ),
          for (final line in uses) ...[
            const SizedBox(height: AppSpacing.lg),
            Text(line.title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              key: Key('percent-${line.id}'),
              controller: _percents.putIfAbsent(line.id, TextEditingController.new),
              decoration: InputDecoration(labelText: copy.percentDone),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              key: Key('recommend-${line.id}'),
              controller: _recommends.putIfAbsent(line.id, TextEditingController.new),
              decoration: InputDecoration(labelText: copy.recommendAmount),
            ),
            const SizedBox(height: AppSpacing.sm),
            DropdownButton<String>(
              key: Key('risk-${line.id}'),
              isExpanded: true,
              value: _risks[line.id] ?? '',
              items: [
                DropdownMenuItem(value: '', child: Text(copy.riskNone)),
                DropdownMenuItem(value: 'ok', child: Text(copy.riskOk)),
                DropdownMenuItem(value: 'watch', child: Text(copy.riskWatch)),
                DropdownMenuItem(value: 'high', child: Text(copy.riskHigh)),
              ],
              onChanged: (value) => setState(() => _risks[line.id] = value ?? ''),
            ),
            TextField(
              controller: _comments.putIfAbsent(line.id, TextEditingController.new),
              decoration: InputDecoration(labelText: copy.inspectorComment),
            ),
          ],
              ],
            ),
          ),
          if (_error != null) Text(copy.known(_error!)),
          const SizedBox(height: AppSpacing.md),
          PrimaryButton(
            key: const Key('send-inspection'),
            label: copy.sendInspection,
            onPressed: _requestId == null ? null : () { _send(); },
          ),
        ],
      ],
    );
  }

  Future<void> _send() async {
    final uses = widget.desk.lines.where((line) => line.side == 'use');
    try {
      await SessionScope.of(context).api.inspect(
        projectId: widget.project.id,
        requestId: _requestId!,
        scheduledOn: DateTime.now().toIso8601String().substring(0, 10),
        gateCode: _gate.text.trim(),
        note: _note.text.trim(),
        lines: [
          for (final line in uses)
            {
              'budgetItemId': line.id,
              'percent': _percents[line.id]?.text.trim() ?? '0.00',
              'recommend': _recommends[line.id]?.text.trim() ?? '0.00',
              'comment': _comments[line.id]?.text.trim() ?? '',
              'risk': _risks[line.id] ?? '',
            },
        ],
      );
      await widget.onChanged();
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    }
  }
}

class DocumentsPanel extends StatefulWidget {
  const DocumentsPanel({super.key, required this.project, required this.desk, required this.onChanged});

  final ProjectSummary project;
  final LoanDesk desk;
  final Future<void> Function() onChanged;

  @override
  State<DocumentsPanel> createState() => _DocumentsPanelState();
}

class _DocumentsPanelState extends State<DocumentsPanel> {
  final _insurance = TextEditingController();
  final _license = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _insurance.dispose();
    _license.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final admin = widget.project.myRole == AppRole.director || widget.project.myRole == AppRole.developer;
    final copy = LocaleScope.copy(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IBuildCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(copy.documentsBank, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.md),
              for (final item in widget.desk.checklist) ...[
                Row(
                  children: [
                    Expanded(child: Text(copy.documentTitle(item.code, item.title))),
                    Text(
                      item.required ? copy.requiredYes : copy.requiredNo,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: context.colors.inkMuted,
                      ),
                    ),
                  ],
                ),
                if (item != widget.desk.checklist.last)
                  Divider(height: AppSpacing.lg, color: context.colors.outline),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        for (final firm in widget.desk.firms) ...[
          IBuildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(firm.name, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: AppSpacing.sm),
                Text(copy.insuranceUntilIs(firm.insuranceUntil.isEmpty ? '—' : firm.insuranceUntil)),
                Text(copy.licenseUntilIs(firm.licenseUntil.isEmpty ? '—' : firm.licenseUntil)),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        if (admin && widget.desk.firms.isNotEmpty)
          IBuildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(copy.contractorDates, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  key: const Key('insurance-until'),
                  controller: _insurance,
                  decoration: InputDecoration(labelText: copy.insuranceUntilLabel),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  key: const Key('license-until'),
                  controller: _license,
                  decoration: InputDecoration(labelText: copy.licenseUntilLabel),
                ),
                if (_error != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(copy.known(_error!)),
                ],
                const SizedBox(height: AppSpacing.md),
                PrimaryButton(
                  key: const Key('save-compliance'),
                  label: copy.saveDates,
                  onPressed: () { _save(); },
                ),
              ],
            ),
          ),
      ],
    );
  }

  Future<void> _save() async {
    try {
      await SessionScope.of(context).api.updateCompliance(
        firmId: widget.desk.firms.first.id,
        insuranceUntil: _insurance.text.trim(),
        licenseUntil: _license.text.trim(),
      );
      await widget.onChanged();
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    }
  }
}

class _GridLine extends StatelessWidget {
  const _GridLine({
    required this.code,
    required this.title,
    required this.kind,
    required this.original,
    required this.adjusted,
    required this.revised,
    required this.funded,
    required this.remaining,
    required this.extra,
  });

  final String code;
  final String title;
  final String kind;
  final String original;
  final String adjusted;
  final String revised;
  final String funded;
  final String remaining;
  final String extra;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).textTheme.bodySmall?.copyWith(color: context.colors.inkMuted);
    final copy = LocaleScope.copy(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (code.isNotEmpty) Text(code, style: muted),
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        if (kind.isNotEmpty) Text(kind, style: muted),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.lg,
          runSpacing: AppSpacing.sm,
          children: [
            _Cell(copy.gridOriginal, original, muted),
            _Cell(copy.gridChanges, adjusted, muted),
            _Cell(copy.gridNow, revised, muted),
            _Cell(copy.gridPaid, funded, muted),
            _Cell(copy.gridLeft, remaining, muted),
          ],
        ),
        if (extra.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(extra, style: muted),
        ],
      ],
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell(this.label, this.value, this.muted);
  final String label;
  final String value;
  final TextStyle? muted;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: muted),
        Text(value),
      ],
    );
  }
}

class _Figure extends StatelessWidget {
  const _Figure({required this.label, required this.value, this.emphasize = false});

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: emphasize ? colors.accent : colors.surfaceAlt,
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: emphasize ? colors.onHeroSurface : colors.inkMuted,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              value.isEmpty ? '—' : value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: emphasize ? colors.onAccent : colors.ink,
                letterSpacing: -0.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
