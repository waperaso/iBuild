import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../api.dart';
import '../download.dart';
import '../l10n.dart';
import '../registration_models.dart';
import '../registration_spec.dart';
import '../session_scope.dart';
import '../theme.dart';
import '../widgets.dart';
import 'register_screen.dart' show CopyTextButton;

String _day(DateTime value) {
  final local = value.toLocal();
  return '${local.day.toString().padLeft(2, '0')}.${local.month.toString().padLeft(2, '0')}.${local.year}';
}

String _dayTime(DateTime value) {
  final local = value.toLocal();
  return '${_day(value)} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
}

String _isoDay(String iso) {
  final parts = iso.split('-');
  if (parts.length != 3) return iso;
  return '${parts[2]}.${parts[1]}.${parts[0]}';
}

String _groupDigits(String value) {
  final parts = value.split('.');
  final digits = parts.first;
  final out = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) out.write(' ');
    out.write(digits[i]);
  }
  return parts.length > 1 ? '$out.${parts[1]}' : out.toString();
}

String _phone(String value) {
  if (value.length != 13 || !value.startsWith('+998')) return value;
  return '${value.substring(0, 4)} ${value.substring(4, 6)} ${value.substring(6, 9)} '
      '${value.substring(9, 11)} ${value.substring(11)}';
}

StatusTone _tone(String status) => switch (status) {
  'approved' => StatusTone.good,
  'rejected' => StatusTone.bad,
  'docs_requested' || 'calling' => StatusTone.wait,
  _ => StatusTone.neutral,
};

// ── The list ─────────────────────────────────────────────────────────────

class ApplicationsScreen extends StatefulWidget {
  const ApplicationsScreen({super.key});

  @override
  State<ApplicationsScreen> createState() => _ApplicationsScreenState();
}

class _ApplicationsScreenState extends State<ApplicationsScreen> {
  ApplicationBoard? _board;
  String _kind = '';
  String _status = '';
  String? _error;
  var _started = false;
  Timer? _debounce;
  final _search = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final session = SessionScope.of(context);
    if (session.user?.platformAdmin != true) return;
    try {
      final board = await session.api.applications(
        kind: _kind,
        status: _status,
        query: _search.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _board = board;
        _error = null;
      });
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = SessionScope.of(context);
    final admin = session.user?.platformAdmin == true;
    final copy = LocaleScope.copy(context);
    final theme = Theme.of(context);
    final colors = context.colors;
    final board = _board;
    return ScreenScroll(
      children: [
        Text(copy.applications, style: theme.textTheme.headlineMedium),
        const SizedBox(height: AppSpacing.sm),
        Text(
          copy.applicationsSubtitle,
          style: theme.textTheme.bodyMedium?.copyWith(color: colors.inkMuted),
        ),
        const SizedBox(height: AppSpacing.xl),
        if (!admin)
          Text(copy.applicationsAdminOnly)
        else ...[
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final status in const ['', 'new', 'calling', 'docs_requested', 'in_review', 'approved', 'rejected'])
                ChoiceChip(
                  key: Key('pipe-${status.isEmpty ? 'all' : status}'),
                  label: Text(
                    status.isEmpty
                        ? '${copy.kindAll}${board == null ? '' : ' · ${board.counts.values.fold<int>(0, (a, b) => a + b)}'}'
                        : '${copy.say(statusLabels[status]!)}${board == null ? '' : ' · ${board.counts[status] ?? 0}'}',
                  ),
                  selected: _status == status,
                  onSelected: (_) {
                    setState(() => _status = status);
                    _load();
                  },
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.md,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SegmentedButton<String>(
                key: const Key('apps-kind'),
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(value: '', label: Text(copy.kindAll)),
                  ButtonSegment(value: 'developer', label: Text(copy.kindDevelopers)),
                  ButtonSegment(value: 'bank', label: Text(copy.kindBanks)),
                ],
                selected: {_kind},
                onSelectionChanged: (selection) {
                  setState(() => _kind = selection.first);
                  _load();
                },
              ),
              SizedBox(
                width: 340,
                child: TextField(
                  key: const Key('apps-search'),
                  controller: _search,
                  onChanged: (_) {
                    _debounce?.cancel();
                    _debounce = Timer(const Duration(milliseconds: 300), _load);
                  },
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search, size: 20),
                    hintText: copy.searchApplications,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          if (_error != null) ErrorNote(message: copy.known(_error!)),
          if (board != null && board.items.isEmpty)
            EmptyState(
              key: const Key('empty-applications'),
              title: copy.noApplications,
              body: copy.noApplicationsBody,
            )
          else if (board != null)
            for (final item in board.items) ...[
              _ApplicationRow(item: item),
              const SizedBox(height: AppSpacing.md),
            ],
        ],
      ],
    );
  }
}

class _ApplicationRow extends StatelessWidget {
  const _ApplicationRow({required this.item});

  final ApplicationItem item;

  @override
  Widget build(BuildContext context) {
    final copy = LocaleScope.copy(context);
    final theme = Theme.of(context);
    final colors = context.colors;
    final age = DateTime.now().difference(item.createdAt).inDays;
    final muted = theme.textTheme.bodySmall?.copyWith(color: colors.inkMuted);
    return Material(
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.card),
        side: BorderSide(color: colors.outline),
      ),
      child: InkWell(
        key: Key('application-${item.id}'),
        borderRadius: BorderRadius.circular(AppRadii.card),
        onTap: () => context.go('/applications/${item.id}'),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Wrap(
            spacing: AppSpacing.xl,
            runSpacing: AppSpacing.md,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 320,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.orgName, style: theme.textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        Icon(
                          item.kind == 'bank' ? Icons.account_balance_outlined : Icons.apartment_outlined,
                          size: 14,
                          color: colors.inkMuted,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text('${item.code} · ${copy.say(('ИНН', 'TIN', 'STIR'))} ${item.inn}', style: muted),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 200,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.contactName, style: theme.textTheme.bodyMedium),
                    Text(_phone(item.phone), style: muted),
                  ],
                ),
              ),
              SizedBox(
                width: 200,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StatusText(label: copy.say(statusLabels[item.status]!), tone: _tone(item.status)),
                    const SizedBox(height: AppSpacing.xs),
                    Text(copy.waitingDays(age), style: muted),
                  ],
                ),
              ),
              SizedBox(
                width: 200,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (item.isOpen && item.nextCallOn != null)
                      Text(copy.callOn(_isoDay(item.nextCallOn!)), style: theme.textTheme.bodySmall),
                    Text(
                      item.missingDocs == 0 ? copy.docsComplete : copy.docsMissing(item.missingDocs),
                      style: muted?.copyWith(
                        color: item.missingDocs == 0 ? colors.success : colors.warning,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── One application ──────────────────────────────────────────────────────

class ApplicationScreen extends StatefulWidget {
  const ApplicationScreen({super.key, required this.id});

  final String id;

  @override
  State<ApplicationScreen> createState() => _ApplicationScreenState();
}

class _ApplicationScreenState extends State<ApplicationScreen> {
  ApplicationDetail? _detail;
  String? _error;
  var _started = false;
  var _busy = false;
  final _note = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _load();
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final session = SessionScope.of(context);
    if (session.user?.platformAdmin != true) return;
    await _run(() => session.api.applicationDetail(widget.id));
  }

  Future<void> _run(Future<ApplicationDetail> Function() action) async {
    setState(() => _busy = true);
    try {
      final detail = await action();
      if (!mounted) return;
      setState(() {
        _detail = detail;
        _error = null;
      });
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Api get _api => SessionScope.of(context).api;

  Future<void> _logCall() async {
    final result = await showPlainDialog<_CallResult>(
      context: context,
      builder: (context) => const _CallDialog(),
    );
    if (result == null || !mounted) return;
    await _run(
      () => _api.logApplicationCall(
        id: widget.id,
        outcome: result.outcome,
        note: result.note,
        nextCallOn: result.nextCallOn,
      ),
    );
  }

  Future<void> _askText({
    required String title,
    required String label,
    String? hint,
    required String button,
    required String key,
    required Future<ApplicationDetail> Function(String note) action,
  }) async {
    final note = await showPlainDialog<String>(
      context: context,
      builder: (context) => _TextDialog(title: title, label: label, hint: hint, button: button, fieldKey: key),
    );
    if (note == null || !mounted) return;
    await _run(() => action(note));
  }

  Future<void> _approve(ApplicationDetail detail) async {
    final copy = LocaleScope.copy(context);
    final ok = await showPlainDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(copy.approveTitle),
        content: Text(detail.kind == 'bank' ? copy.approveBankBody : copy.approveDeveloperBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(copy.cancel)),
          PrimaryButton(
            key: const Key('approve-confirm'),
            label: copy.approveApplication,
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    try {
      final result = await _api.approveApplication(widget.id);
      if (!mounted) return;
      setState(() {
        _detail = result.application;
        _error = null;
        _busy = false;
      });
      final account = result.account;
      if (account != null) {
        await showPlainDialog<void>(
          context: context,
          builder: (context) => _AccountDialog(account: account),
        );
      }
    } on ApiException catch (error) {
      if (mounted) {
        setState(() {
          _error = error.message;
          _busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = SessionScope.of(context);
    final copy = LocaleScope.copy(context);
    final theme = Theme.of(context);
    final colors = context.colors;
    final detail = _detail;
    if (session.user?.platformAdmin != true) {
      return ScreenScroll(children: [Text(copy.applicationsAdminOnly)]);
    }
    return ScreenScroll(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            key: const Key('back-to-applications'),
            style: backLinkStyle,
            onPressed: () => context.go('/applications'),
            icon: const Icon(Icons.arrow_back, size: 18),
            label: Text(copy.backToApplications),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (_error != null) ...[
          ErrorNote(message: copy.known(_error!)),
          const SizedBox(height: AppSpacing.md),
        ],
        if (detail != null) ...[
          _header(context, copy, detail),
          const SizedBox(height: AppSpacing.lg),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 980;
              final desk = _desk(context, copy, detail);
              final info = _info(context, copy, detail);
              if (!wide) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [desk, const SizedBox(height: AppSpacing.lg), info],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 5, child: info),
                  const SizedBox(width: AppSpacing.lg),
                  SizedBox(width: 400, child: desk),
                ],
              );
            },
          ),
        ] else
          Text('', style: theme.textTheme.bodySmall?.copyWith(color: colors.inkMuted)),
      ],
    );
  }

  Widget _header(BuildContext context, AppCopy copy, ApplicationDetail detail) {
    final theme = Theme.of(context);
    final colors = context.colors;
    return IBuildCard(
      child: Wrap(
        spacing: AppSpacing.xxl,
        runSpacing: AppSpacing.lg,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(detail.orgName, style: theme.textTheme.headlineSmall),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '${detail.code} · ${detail.kind == 'bank' ? copy.kindBanks : copy.kindDevelopers} · '
                '${copy.say(('ИНН', 'TIN', 'STIR'))} ${detail.inn}',
                style: theme.textTheme.bodyMedium?.copyWith(color: colors.inkMuted),
              ),
              const SizedBox(height: AppSpacing.md),
              StatusText(
                key: const Key('application-status'),
                label: copy.say(statusLabels[detail.status]!),
                tone: _tone(detail.status),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(detail.contactName, style: theme.textTheme.titleMedium),
              const SizedBox(height: AppSpacing.xs),
              SelectableText(_phone(detail.phone), key: const Key('application-phone')),
              SelectableText(detail.email),
              const SizedBox(height: AppSpacing.sm),
              CopyTextButton(text: detail.phone),
            ],
          ),
        ],
      ),
    );
  }

  // The working side: what to do, checks, notes, history.
  Widget _desk(BuildContext context, AppCopy copy, ApplicationDetail detail) {
    final theme = Theme.of(context);
    final colors = context.colors;
    final canApprove = detail.allChecked && detail.missing.isEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        IBuildCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(copy.crmActions, style: theme.textTheme.titleLarge),
              const SizedBox(height: AppSpacing.md),
              if (detail.isOpen) ...[
                if (detail.nextCallOn != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: Text(copy.callOn(_isoDay(detail.nextCallOn!)), style: theme.textTheme.bodyMedium),
                  ),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    OutlinedButton.icon(
                      key: const Key('app-log-call'),
                      onPressed: _busy ? null : _logCall,
                      icon: const Icon(Icons.phone_outlined, size: 18),
                      label: Text(copy.logCall),
                    ),
                    OutlinedButton.icon(
                      key: const Key('app-request-docs'),
                      onPressed: _busy
                          ? null
                          : () => _askText(
                              title: copy.requestDocs,
                              label: copy.docsNeededLabel,
                              button: copy.sendRequest,
                              key: 'request-note-field',
                              action: (note) => _api.setApplicationStatus(
                                id: widget.id,
                                status: 'docs_requested',
                                note: note,
                              ),
                            ),
                      icon: const Icon(Icons.description_outlined, size: 18),
                      label: Text(copy.requestDocs),
                    ),
                    if (detail.status != 'in_review')
                      OutlinedButton.icon(
                        key: const Key('app-review'),
                        onPressed: _busy
                            ? null
                            : () => _run(
                                () => _api.setApplicationStatus(id: widget.id, status: 'in_review'),
                              ),
                        icon: const Icon(Icons.fact_check_outlined, size: 18),
                        label: Text(copy.takeToReview),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    PrimaryButton(
                      key: const Key('app-approve'),
                      label: copy.approveApplication,
                      busy: _busy,
                      onPressed: canApprove ? () => _approve(detail) : null,
                    ),
                    TextButton(
                      key: const Key('app-reject'),
                      onPressed: _busy
                          ? null
                          : () => _askText(
                              title: copy.rejectApplicationTitle,
                              label: copy.reasonLabel,
                              hint: copy.rejectApplicationHint,
                              button: copy.rejectApplication,
                              key: 'reject-note-field',
                              action: (note) => _api.setApplicationStatus(
                                id: widget.id,
                                status: 'rejected',
                                note: note,
                              ),
                            ),
                      child: Text(copy.rejectApplication),
                    ),
                  ],
                ),
                if (!canApprove) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    detail.missing.isNotEmpty ? copy.docsMissing(detail.missing.length) : copy.checklistHint,
                    key: const Key('approve-blocker'),
                    style: theme.textTheme.bodySmall?.copyWith(color: colors.warning),
                  ),
                ],
              ] else ...[
                Text(copy.say(statusLabels[detail.status]!), style: theme.textTheme.titleMedium),
                if (detail.decisionNote.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(detail.decisionNote),
                ],
              ],
              if (detail.status == 'docs_requested' && detail.requestNote.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                Text(copy.adminAsks, style: theme.textTheme.titleSmall),
                Text(detail.requestNote),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        IBuildCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(copy.checklistTitle, style: theme.textTheme.titleLarge),
              const SizedBox(height: AppSpacing.xs),
              Text(
                copy.checklistHint,
                style: theme.textTheme.bodySmall?.copyWith(color: colors.inkMuted),
              ),
              const SizedBox(height: AppSpacing.sm),
              for (final key in detail.checkKeys)
                CheckboxListTile(
                  key: Key('check-$key'),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  value: detail.checks[key] == true,
                  onChanged: detail.isOpen && !_busy
                      ? (value) => _run(
                          () => _api.setApplicationCheck(
                            id: widget.id,
                            key: key,
                            done: value ?? false,
                          ),
                        )
                      : null,
                  title: Text(
                    copy.say(checkLabels[key] ?? (key, key, key)),
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        IBuildCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(copy.noteLabel, style: theme.textTheme.titleLarge),
              const SizedBox(height: AppSpacing.md),
              TextField(
                key: const Key('app-note'),
                controller: _note,
                minLines: 2,
                maxLines: 5,
                maxLength: 2000,
                decoration: InputDecoration(labelText: copy.noteLabel, counterText: ''),
              ),
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton(
                key: const Key('app-add-note'),
                onPressed: _busy
                    ? null
                    : () async {
                        final text = _note.text.trim();
                        if (text.isEmpty) return;
                        await _run(() => _api.addApplicationNote(id: widget.id, body: text));
                        if (mounted && _error == null) _note.clear();
                      },
                child: Text(copy.addNote),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        IBuildCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(copy.historyTitle, style: theme.textTheme.titleLarge),
              const SizedBox(height: AppSpacing.md),
              for (final event in detail.events) _eventTile(context, copy, event),
            ],
          ),
        ),
      ],
    );
  }

  Widget _eventTile(BuildContext context, AppCopy copy, ApplicationEvent event) {
    final theme = Theme.of(context);
    final colors = context.colors;
    var title = copy.eventText(event.kind, event.outcome, event.body);
    var detail = event.body;
    switch (event.kind) {
      case 'status':
        title = '${copy.eventText('status', '', '')}: ${copy.say(statusLabels[event.outcome] ?? (event.outcome, event.outcome, event.outcome))}';
      case 'call':
        title = '${copy.eventText('call', '', '')}: ${copy.say(callOutcomes[event.outcome] ?? (event.outcome, event.outcome, event.outcome))}';
      case 'check':
        title = '${copy.eventText('check', event.outcome, '')}: ${copy.say(checkLabels[event.body] ?? (event.body, event.body, event.body))}';
        detail = '';
      case 'document':
        title = '${copy.eventText('document', '', '')}: ${copy.docName(event.body)}';
        detail = '';
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.bodyMedium),
          if (detail.isNotEmpty) Text(detail, style: theme.textTheme.bodyMedium),
          Text(
            [_dayTime(event.createdAt), if (event.author.isNotEmpty) event.author].join(' · '),
            style: theme.textTheme.bodySmall?.copyWith(color: colors.inkMuted),
          ),
        ],
      ),
    );
  }

  // The reading side: what the company wrote and which papers it sent.
  Widget _info(BuildContext context, AppCopy copy, ApplicationDetail detail) {
    final theme = Theme.of(context);
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        IBuildCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(copy.documentsTitle, style: theme.textTheme.titleLarge),
              const SizedBox(height: AppSpacing.md),
              for (final doc in docsFor(detail.kind))
                _docLine(context, copy, detail, doc),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        IBuildCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(copy.applicationData, style: theme.textTheme.titleLarge),
              if (detail.consentAt != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  copy.consentRecorded(_dayTime(detail.consentAt!), detail.consentVersion),
                  style: theme.textTheme.bodySmall?.copyWith(color: colors.inkMuted),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              for (final section in sectionsFor(detail.kind)) ..._dataSection(context, copy, detail, section),
            ],
          ),
        ),
      ],
    );
  }

  Widget _docLine(BuildContext context, AppCopy copy, ApplicationDetail detail, RegDoc doc) {
    final theme = Theme.of(context);
    final colors = context.colors;
    final files = detail.documents.where((file) => file.type == doc.type).toList();
    final missing = doc.required && files.isEmpty;
    return Padding(
      key: Key('docline-${doc.type}'),
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            files.isNotEmpty
                ? Icons.check_circle_outline
                : (missing ? Icons.error_outline : Icons.radio_button_unchecked),
            size: 20,
            color: files.isNotEmpty ? colors.success : (missing ? colors.warning : colors.inkMuted),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(copy.say(doc.title), style: theme.textTheme.bodyMedium),
                if (files.isEmpty)
                  Text(
                    doc.required ? copy.docRequired : copy.fileMissing,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: missing ? colors.warning : colors.inkMuted,
                    ),
                  ),
                for (final file in files)
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          file.name,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(color: colors.inkMuted),
                        ),
                      ),
                      TextButton(
                        key: Key('open-file-${file.id}'),
                        onPressed: () => openApplicationDocument(detail.id, file.id),
                        child: Text(copy.openFile),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _dataSection(
    BuildContext context,
    AppCopy copy,
    ApplicationDetail detail,
    RegSection section,
  ) {
    final theme = Theme.of(context);
    final rows = <Widget>[];
    for (final field in section.fields) {
      final raw = detail.data[field.key];
      if (raw == null || '$raw'.isEmpty) continue;
      rows.add(_kv(context, copy.say(field.label), _show(copy, field, '$raw')));
    }
    if (section.extra == RegExtra.owners) {
      final owners = detail.data['owners'] as List<dynamic>? ?? const [];
      rows.insert(
        0,
        _kv(context, copy.ownersLabel, [
          for (final owner in owners)
            '${(owner as Map<String, dynamic>)['name']} · ${owner['tax_id']} · ${owner['share']}% '
                '(${owner['kind'] == 'company' ? copy.ownerCompany : copy.ownerPerson})',
        ].join('\n')),
      );
    }
    if (section.extra == RegExtra.licenses) {
      final licenses = detail.data['licenses'] as List<dynamic>? ?? const [];
      if (licenses.isNotEmpty) {
        rows.add(
          _kv(context, copy.licensesLabel, [
            for (final license in licenses)
              '${(license as Map<String, dynamic>)['activity']} · ${license['number']} · '
                  '${_isoDay('${license['issued_on']}')}'
                  '${license['valid_until'] == null ? '' : ' → ${_isoDay('${license['valid_until']}')}'}',
          ].join('\n')),
        );
      }
    }
    if (section.extra == RegExtra.interests) {
      final interests = detail.data['interests'] as List<dynamic>? ?? const [];
      rows.insert(
        0,
        _kv(context, copy.interestsLabel, [
          for (final code in interests)
            copy.say(
              bankInterestChoices
                  .firstWhere((choice) => choice.code == code, orElse: () => RegChoice('$code', ('$code', '$code', '$code')))
                  .label,
            ),
        ].join('\n')),
      );
    }
    if (rows.isEmpty) return const [];
    return [
      Padding(
        padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.xs),
        child: Text(copy.say(section.title), style: theme.textTheme.titleSmall),
      ),
      ...rows,
    ];
  }

  String _show(AppCopy copy, RegField field, String raw) {
    switch (field.kind) {
      case RegKind.choice:
      case RegKind.yesNo:
        for (final choice in field.choices) {
          if (choice.code == raw) return copy.say(choice.label);
        }
        return raw;
      case RegKind.date:
        return _isoDay(raw);
      case RegKind.phone:
        return _phone(raw);
      case RegKind.money:
        return '${_groupDigits(raw)}${field.suffix == null ? '' : ' ${copy.say(field.suffix!)}'}';
      case RegKind.percent:
        return '$raw%';
      case RegKind.number:
        return '$raw${field.suffix == null ? '' : ' ${copy.say(field.suffix!)}'}';
      default:
        return raw;
    }
  }

  Widget _kv(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final labelWidget = Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(color: colors.inkMuted),
          );
          final valueWidget = SelectableText(value, style: theme.textTheme.bodyMedium);
          if (constraints.maxWidth < 520) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [labelWidget, valueWidget],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 240, child: labelWidget),
              Expanded(child: valueWidget),
            ],
          );
        },
      ),
    );
  }
}

// ── Dialogs ──────────────────────────────────────────────────────────────

class _CallResult {
  const _CallResult(this.outcome, this.note, this.nextCallOn);

  final String outcome;
  final String note;
  final String nextCallOn;
}

class _CallDialog extends StatefulWidget {
  const _CallDialog();

  @override
  State<_CallDialog> createState() => _CallDialogState();
}

class _CallDialogState extends State<_CallDialog> {
  String _outcome = 'reached';
  final _note = TextEditingController();
  final _next = TextEditingController();
  String _nextIso = '';

  @override
  void dispose() {
    _note.dispose();
    _next.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked == null) return;
    setState(() {
      _nextIso =
          '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      _next.text = _isoDay(_nextIso);
    });
  }

  @override
  Widget build(BuildContext context) {
    final copy = LocaleScope.copy(context);
    return AlertDialog(
      title: Text(copy.logCall),
      content: SizedBox(
        width: dialogFieldWidth(context),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                key: const Key('call-outcome'),
                initialValue: _outcome,
                isExpanded: true,
                decoration: InputDecoration(labelText: copy.callOutcome),
                items: [
                  for (final entry in callOutcomes.entries)
                    DropdownMenuItem(value: entry.key, child: Text(copy.say(entry.value))),
                ],
                onChanged: (value) => setState(() => _outcome = value ?? _outcome),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                key: const Key('call-note'),
                controller: _note,
                minLines: 2,
                maxLines: 4,
                maxLength: 1000,
                decoration: InputDecoration(labelText: copy.callNote, counterText: ''),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                key: const Key('call-next'),
                controller: _next,
                readOnly: true,
                onTap: _pick,
                decoration: InputDecoration(
                  labelText: copy.nextCallOn,
                  suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(copy.cancel)),
        PrimaryButton(
          key: const Key('call-save'),
          label: copy.save,
          onPressed: () => Navigator.pop(
            context,
            _CallResult(_outcome, _note.text.trim(), _nextIso),
          ),
        ),
      ],
    );
  }
}

class _TextDialog extends StatefulWidget {
  const _TextDialog({
    required this.title,
    required this.label,
    required this.button,
    required this.fieldKey,
    this.hint,
  });

  final String title;
  final String label;
  final String? hint;
  final String button;
  final String fieldKey;

  @override
  State<_TextDialog> createState() => _TextDialogState();
}

class _TextDialogState extends State<_TextDialog> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final copy = LocaleScope.copy(context);
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: dialogFieldWidth(context),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.hint != null) ...[
              Text(widget.hint!),
              const SizedBox(height: AppSpacing.md),
            ],
            TextField(
              key: Key(widget.fieldKey),
              controller: _controller,
              minLines: 3,
              maxLines: 6,
              maxLength: 1000,
              decoration: InputDecoration(labelText: widget.label, counterText: '', errorText: _error),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(copy.cancel)),
        PrimaryButton(
          key: const Key('text-dialog-save'),
          label: widget.button,
          onPressed: () {
            final text = _controller.text.trim();
            if (text.isEmpty) {
              setState(() => _error = copy.fieldRequired);
              return;
            }
            Navigator.pop(context, text);
          },
        ),
      ],
    );
  }
}

class _AccountDialog extends StatelessWidget {
  const _AccountDialog({required this.account});

  final ApprovedAccount account;

  @override
  Widget build(BuildContext context) {
    final copy = LocaleScope.copy(context);
    final theme = Theme.of(context);
    Widget line(String label, String value, Key key) => Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.bodySmall),
          SelectableText(value, key: key, style: theme.textTheme.titleMedium),
        ],
      ),
    );
    return AlertDialog(
      key: const Key('account-dialog'),
      title: Text(copy.accountReady),
      content: SizedBox(
        width: dialogFieldWidth(context),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(copy.accountBody),
            const SizedBox(height: AppSpacing.lg),
            line(copy.companyLabel, account.company, const Key('account-company')),
            line(copy.loginLabel, account.login, const Key('account-login')),
            line(copy.passwordLabel, account.password, const Key('account-password')),
            CopyTextButton(text: 'iBuild\n${copy.loginLabel}: ${account.login}\n${copy.passwordLabel}: ${account.password}'),
          ],
        ),
      ),
      actions: [
        PrimaryButton(
          key: const Key('account-close'),
          label: copy.closeText,
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }
}
