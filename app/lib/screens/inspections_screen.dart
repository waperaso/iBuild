import 'package:flutter/material.dart';

import '../api.dart';
import '../l10n.dart';
import '../models.dart';
import '../session_scope.dart';
import '../theme.dart';
import '../widgets.dart';

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
    final bank = session.projects.any((item) => item.myRole == AppRole.observer) ||
        session.user?.memberships.any((item) => item.role == AppRole.observer) == true;
    final builder = session.user?.isDirector == true;
    final copy = LocaleScope.copy(context);
    return ScreenScroll(
      children: [
        Text(copy.inspections, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: AppSpacing.sm),
        Text(
          copy.inspectionsSubtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: context.colors.inkMuted),
        ),
        const SizedBox(height: AppSpacing.xl),
        if (bank) _orderForm(),
        if (_error != null) Text(copy.known(_error!)),
        if (_loading)
          const SizedBox.shrink()
        else if (_items.isEmpty)
          EmptyState(
            key: const Key('empty-inspections'),
            title: copy.inspectionsEmpty,
            body: copy.inspectionsEmptyBody,
          )
        else
          for (final item in _items) ...[
            IBuildCard(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(copy.place(item.projectName), style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: AppSpacing.xs),
                  Text(item.status == 'requested' ? copy.inspectionOrdered : copy.inspectionReported),
                  if (item.scheduledOn.isNotEmpty) Text(item.scheduledOn),
                  if (item.requestLine.isNotEmpty) Text(copy.forTranche(item.requestLine)),
                  if (item.note.isNotEmpty) Text(item.note),
                  if (builder && item.status == 'requested') ...[
                    const SizedBox(height: AppSpacing.md),
                    _ReportBox(order: item, onDone: _load),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
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
    return IBuildCard(
      key: const Key('inspection-order'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(copy.orderInspection, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<String>(
            initialValue: _projectId,
            decoration: InputDecoration(labelText: copy.project),
            items: [
              for (final project in projects)
                DropdownMenuItem(value: project.id, child: Text(copy.place(project.name))),
            ],
            onChanged: (value) => setState(() => _projectId = value),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            key: const Key('inspection-date'),
            controller: _when,
            decoration: InputDecoration(labelText: copy.dateLabel, hintText: copy.dateHint),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            key: const Key('inspection-note'),
            controller: _note,
            minLines: 2,
            maxLines: 4,
            decoration: InputDecoration(labelText: copy.whatToCheck),
          ),
          const SizedBox(height: AppSpacing.md),
          PrimaryButton(
            key: const Key('request-inspection'),
            label: copy.orderIt,
            onPressed: _projectId == null
                ? null
                : () {
                    _order();
                  },
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _percent,
          decoration: InputDecoration(labelText: copy.readyPercent),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: _recommend,
          decoration: InputDecoration(labelText: copy.recommendAmount),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: _note,
          decoration: InputDecoration(labelText: copy.commentAndPhoto),
        ),
        if (_error != null) Text(copy.known(_error!)),
        const SizedBox(height: AppSpacing.sm),
        PrimaryButton(
          label: copy.submitReport,
          onPressed: () {
            _send();
          },
        ),
      ],
    );
  }
}
