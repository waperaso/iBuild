import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../api.dart';
import '../l10n.dart';
import '../models.dart';
import '../session_scope.dart';
import '../theme.dart';
import '../widgets.dart';
import 'kit.dart';

/// Site visits, as the technical supervisor and the developer see them: the
/// same page frame the bank cabinet uses — a title, the counts, a filter and
/// one bordered list — so a visit reads at a glance on a wide screen.
class InspectionsScreen extends StatefulWidget {
  const InspectionsScreen({super.key});

  @override
  State<InspectionsScreen> createState() => _InspectionsScreenState();
}

class _InspectionsScreenState extends State<InspectionsScreen> {
  List<InspectionOrder> _items = const [];
  var _loading = true;
  final _note = TextEditingController();
  final _when = TextEditingController();
  String? _projectId;
  String? _error;
  var _filter = 'all';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _load();
  }

  var _started = false;

  @override
  void dispose() {
    _note.dispose();
    _when.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final items = await SessionScope.of(context).api.inspections();
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
        _projectId ??= SessionScope.of(context).projects.isEmpty
            ? null
            : SessionScope.of(context).projects.first.id;
      });
    } on ApiException catch (error) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = error.message;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = SessionScope.of(context);
    final t = Tx.of(context);
    final bank = session.projects.any((item) => item.myRole == AppRole.observer) ||
        session.user?.memberships.any((item) => item.role == AppRole.observer) == true;
    final builder = session.user?.isDirector == true;
    // The engineer who goes out to the site writes the report on the project
    // page; the list sends them there instead of leaving a dead row.
    final inspector = session.user?.memberships.any((item) => item.role == AppRole.tech) == true ||
        session.user?.isDeveloper == true;
    final copy = LocaleScope.copy(context);
    final scheduled = _items.where((item) => item.status == 'requested').length;
    final reported = _items.length - scheduled;
    final visible = [
      for (final item in _items)
        if (_filter == 'all' ||
            (_filter == 'requested' && item.status == 'requested') ||
            (_filter == 'reported' && item.status != 'requested'))
          item,
    ];
    return ScreenScroll(
      key: const Key('inspections-frame'),
      children: [
        PageTitle(title: copy.inspections, subtitle: copy.inspectionsSubtitle),
        if (!_loading) ...[
          KpiRow(children: [
            Kpi(label: copy.inspectionOrdered, value: '$scheduled'),
            Kpi(label: copy.inspectionReported, value: '$reported'),
          ]),
          const SizedBox(height: AppSpacing.lg),
        ],
        if (bank) ...[
          _orderForm(),
          const SizedBox(height: AppSpacing.lg),
        ],
        if (_error != null) ...[
          ErrorNote(message: _error!),
          const SizedBox(height: AppSpacing.md),
        ],
        if (_loading)
          const PageWait()
        else if (_items.isEmpty)
          EmptyState(
            key: const Key('empty-inspections'),
            title: copy.inspectionsEmpty,
            body: copy.inspectionsEmptyBody,
          )
        else ...[
          FilterChips(
            keyPrefix: 'visits-filter',
            value: _filter,
            onChanged: (value) => setState(() => _filter = value),
            options: [
              ('all', t('Все', 'All', 'Hammasi')),
              ('requested', copy.inspectionOrdered),
              ('reported', copy.inspectionReported),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          if (visible.isEmpty)
            EmptyState(
              key: const Key('empty-visit-filter'),
              title: t('Здесь пусто', 'Nothing here', 'Bu yerda hech narsa yo‘q'),
              body: t(
                'Осмотров с таким статусом нет.',
                'No inspections with this status.',
                'Bunday holatdagi ko‘riklar yo‘q.',
              ),
            )
          else
            IBuildCard(
              padding: EdgeInsets.zero,
              child: Column(
                key: const Key('visits-list'),
                children: [
                  for (final item in visible)
                    _VisitRow(
                      order: item,
                      canReport: builder && item.status == 'requested',
                      canVisit: inspector && item.status == 'requested',
                      onDone: _load,
                    ),
                ],
              ),
            ),
        ],
      ],
    );
  }

  Widget _orderForm() {
    final projects = SessionScope.of(context).projects;
    final copy = LocaleScope.copy(context);
    if (projects.isEmpty) {
      return Text(copy.openProjectWithLimit);
    }
    return FormCard(
      key: const Key('inspection-order'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(copy.orderInspection, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.md),
          FieldGrid(children: [
            DropdownButtonFormField<String>(
              initialValue: _projectId,
              isExpanded: true,
              decoration: InputDecoration(labelText: copy.project),
              items: [
                for (final project in projects)
                  menuLine(project.id, copy.place(project.name)),
              ],
              onChanged: (value) => setState(() => _projectId = value),
            ),
            TextField(
              key: const Key('inspection-date'),
              controller: _when,
              decoration: InputDecoration(labelText: copy.dateLabel, hintText: copy.dateHint),
            ),
          ]),
          const SizedBox(height: AppSpacing.md),
          TextField(
            key: const Key('inspection-note'),
            controller: _note,
            minLines: 2,
            maxLines: 4,
            decoration: InputDecoration(labelText: copy.whatToCheck),
          ),
          const SizedBox(height: AppSpacing.md),
          Align(
            alignment: Alignment.centerLeft,
            child: PrimaryButton(
              key: const Key('request-inspection'),
              label: copy.orderIt,
              onPressed: _projectId == null
                  ? null
                  : () {
                      _order();
                    },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _order() async {
    try {
      await SessionScope.of(context).api.requestInspection(
        projectId: _projectId!,
        scheduledOn: _when.text.trim(),
        note: _note.text.trim(),
      );
      _note.clear();
      await _load();
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    }
  }
}

const _dayColumn = 132.0;

/// One visit: the day on the left, what to check in the middle, the state and
/// the way on at the right — the row the bank cabinet uses for its own visits.
class _VisitRow extends StatefulWidget {
  const _VisitRow({
    required this.order,
    required this.canReport,
    required this.canVisit,
    required this.onDone,
  });

  final InspectionOrder order;
  final bool canReport;
  final bool canVisit;
  final Future<void> Function() onDone;

  @override
  State<_VisitRow> createState() => _VisitRowState();
}

class _VisitRowState extends State<_VisitRow> {
  var _open = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;
    final copy = LocaleScope.copy(context);
    final t = Tx.of(context);
    final order = widget.order;
    final scheduled = order.status == 'requested';
    final tag = Tag(
      label: scheduled ? copy.inspectionOrdered : copy.inspectionReported,
      color: scheduled ? colors.warning : colors.success,
    );
    final day = Text(
      order.scheduledOn.isEmpty ? '—' : fmtDay(order.scheduledOn),
      style: theme.textTheme.titleSmall,
    );
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => context.go('/projects/${order.projectId}?tab=2'),
          child: Text(copy.place(order.projectName), style: theme.textTheme.titleSmall),
        ),
        if (order.requestLine.isNotEmpty)
          Text(
            copy.forTranche(order.requestLine),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(color: colors.inkMuted),
          ),
        if (order.note.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Text(
              order.note,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall,
            ),
          ),
      ],
    );
    final actions = <Widget>[
      if (widget.canVisit)
        OutlinedButton(
          key: Key('visit-${order.id}'),
          onPressed: () => context.go('/projects/${order.projectId}?tab=2'),
          child: Text(t('Открыть осмотр', 'Open the visit', 'Ko‘rikni ochish')),
        ),
      if (widget.canReport)
        OutlinedButton(
          key: Key('report-${order.id}'),
          onPressed: () => setState(() => _open = !_open),
          child: Text(copy.submitReport),
        ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        // The buttons carry a full phrase in every language, so below this the
        // row becomes a stack instead of squeezing the text out of the middle.
        final wide = constraints.maxWidth >= 640;
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: wide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: _dayColumn,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              day,
                              const SizedBox(height: AppSpacing.xs),
                              Align(alignment: Alignment.centerLeft, child: tag),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(child: body),
                        for (final action in actions)
                          Padding(
                            padding: const EdgeInsets.only(left: AppSpacing.md),
                            child: action,
                          ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Wrap(
                          spacing: AppSpacing.md,
                          runSpacing: AppSpacing.xs,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [day, tag],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        body,
                        for (final action in actions) ...[
                          const SizedBox(height: AppSpacing.sm),
                          Align(alignment: Alignment.centerLeft, child: action),
                        ],
                      ],
                    ),
            ),
            if (widget.canReport && _open)
              Padding(
                padding: EdgeInsets.fromLTRB(
                  wide ? AppSpacing.md * 2 + _dayColumn : AppSpacing.md,
                  0,
                  AppSpacing.md,
                  AppSpacing.md,
                ),
                child: _ReportBox(order: order, onDone: widget.onDone),
              ),
            Divider(height: 1, color: colors.outline),
          ],
        );
      },
    );
  }
}

class _ReportBox extends StatefulWidget {
  const _ReportBox({required this.order, required this.onDone});

  final InspectionOrder order;
  final Future<void> Function() onDone;

  @override
  State<_ReportBox> createState() => _ReportBoxState();
}

class _ReportBoxState extends State<_ReportBox> {
  final _note = TextEditingController();
  final _percent = TextEditingController();
  final _recommend = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _note.dispose();
    _percent.dispose();
    _recommend.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final api = SessionScope.of(context).api;
    try {
      final desk = await api.loan(widget.order.projectId);
      final uses = desk.lines.where((line) => line.side == 'use');
      await api.reportInspection(
        id: widget.order.id,
        note: _note.text.trim(),
        lines: [
          for (final line in uses)
            {
              'budgetItemId': line.id,
              'percent': _percent.text.trim().isEmpty ? '0.00' : _percent.text.trim(),
              'recommend': _recommend.text.trim().isEmpty ? '0.00' : _recommend.text.trim(),
              'comment': _note.text.trim(),
            },
        ],
      );
      await widget.onDone();
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final copy = LocaleScope.copy(context);
    return FormCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FieldGrid(children: [
            TextField(
              controller: _percent,
              decoration: InputDecoration(labelText: copy.readyPercent),
            ),
            TextField(
              controller: _recommend,
              decoration: InputDecoration(labelText: copy.recommendAmount),
            ),
          ]),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _note,
            minLines: 2,
            maxLines: 4,
            decoration: InputDecoration(labelText: copy.commentAndPhoto),
          ),
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.md),
            ErrorNote(message: _error!),
          ],
          const SizedBox(height: AppSpacing.md),
          Align(
            alignment: Alignment.centerLeft,
            child: PrimaryButton(
              label: copy.submitReport,
              onPressed: () {
                _send();
              },
            ),
          ),
        ],
      ),
    );
  }
}
