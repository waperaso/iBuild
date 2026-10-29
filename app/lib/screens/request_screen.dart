import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../api.dart';
import '../file_pick.dart';
import '../l10n.dart';
import '../models.dart';
import '../money.dart';
import '../session_scope.dart';
import '../theme.dart';
import '../widgets.dart';

class RequestScreen extends StatefulWidget {
  const RequestScreen({super.key, required this.id, this.initial});

  final String id;
  final Object? initial;

  @override
  State<RequestScreen> createState() => _RequestScreenState();
}

class _RequestScreenState extends State<RequestScreen> {
  final _amount = TextEditingController();
  final _description = TextEditingController();
  var _started = false;
  var _useSeed = true;
  var _ready = false;
  var _saving = false;
  var _uploading = false;
  String? _error;
  String? _actionKey;
  final _reason = TextEditingController();
  final _paidOn = TextEditingController();
  final _paymentNumber = TextEditingController();
  final _withdrawReason = TextEditingController();
  FundingRequest? _request;
  List<BudgetLine> _lines = const [];
  String? _lineId;
  Map<String, Uint8List> _photos = const {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _load();
  }

  @override
  void dispose() {
    _amount.dispose();
    _description.dispose();
    _reason.dispose();
    _paidOn.dispose();
    _paymentNumber.dispose();
    _withdrawReason.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final api = SessionScope.of(context).api;
    try {
      final seeded = widget.initial;
      final request = _useSeed && seeded is FundingRequest && seeded.id == widget.id
          ? seeded
          : await api.request(widget.id);
      _useSeed = false;
      final budget = request.status == 'draft'
          ? await api.budget(request.projectId)
          : null;
      final photos = <String, Uint8List>{};
      for (final file in request.files) {
        if (!file.isPhoto) continue;
        photos[file.id] = await api.requestFile(
          requestId: request.id,
          fileId: file.id,
        );
      }
      if (!mounted) return;
      _amount.text = request.amount;
      _description.text = request.description;
      setState(() {
        _request = request;
        _lines = budget?.items ?? const [];
        _lineId = request.budgetItemId;
        _photos = photos;
        _ready = true;
        _error = null;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _ready = true;
        _error = error.message;
        _request = null;
      });
    }
  }

  Future<void> _save() async {
    final request = _request;
    final lineId = _lineId;
    if (request == null || lineId == null || _saving) return;
    final copy = LocaleScope.copy(context);
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final updated = await SessionScope.of(context).api.updateRequest(
        id: request.id,
        budgetItemId: lineId,
        amount: _amount.text.trim(),
        description: _description.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _request = updated;
        _lineId = updated.budgetItemId;
        _saving = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = copy.known(error.message);
      });
    }
  }

  Future<void> _addFile() async {
    final request = _request;
    if (request == null || _uploading) return;
    final picked = await pickRequestFile();
    if (picked == null || !mounted) return;
    final copy = LocaleScope.copy(context);
    setState(() {
      _uploading = true;
      _error = null;
    });
    try {
      await SessionScope.of(context).api.uploadRequestFile(
        requestId: request.id,
        bytes: picked.bytes,
      );
      if (!mounted) return;
      setState(() => _uploading = false);
      await _load();
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _uploading = false;
        _error = copy.known(error.message);
      });
    }
  }

  Future<void> _removeFile(String fileId) async {
    final request = _request;
    if (request == null) return;
    final copy = LocaleScope.copy(context);
    try {
      await SessionScope.of(context).api.deleteRequestFile(
        requestId: request.id,
        fileId: fileId,
      );
      if (!mounted) return;
      await _load();
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _error = copy.known(error.message));
    }
  }

  AppRole? get _role {
    final request = _request;
    final user = SessionScope.of(context).user;
    if (request == null || user == null) return null;
    for (final membership in user.memberships) {
      if (membership.projectId == request.projectId) return membership.role;
    }
    return null;
  }

  String _freshKey() {
    final random = Random.secure();
    return List.generate(
      16,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
  }

  Future<void> _act(Future<FundingRequest> Function(String key) send) async {
    final request = _request;
    if (request == null || _saving) return;
    final copy = LocaleScope.copy(context);
    final key = _actionKey ??= _freshKey();
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final updated = await send(key);
      if (!mounted) return;
      _actionKey = null;
      _show(updated);
    } on ApiException catch (error) {
      if (!mounted) return;
      // A definite answer from the server (not a lost connection): ask with a fresh key next time.
      final retry = error.status >= 400 && error.status < 500;
      if (retry) _actionKey = null;
      setState(() {
        _saving = false;
        _error = copy.known(error.message);
      });
      if (error.status == 409) {
        _useSeed = false;
        await _load();
      }
    }
  }

  void _show(FundingRequest updated) {
    _amount.text = updated.amount;
    _description.text = updated.description;
    setState(() {
      _request = updated;
      _lineId = updated.budgetItemId;
      _saving = false;
      _error = null;
    });
  }

  Future<void> _submit() {
    final request = _request!;
    return _act(
      (key) => SessionScope.of(context).api.submitRequest(
        id: request.id,
        version: request.version,
        idempotencyKey: key,
      ),
    );
  }

  bool get _isBank => _role == AppRole.observer || _role == AppRole.developer;

  BudgetLine? get _selectedLine {
    for (final line in _lines) {
      if (line.id == _lineId) return line;
    }
    return null;
  }

  Future<void> _cancel() async {
    final copy = LocaleScope.copy(context);
    final confirmed = await showPlainDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(copy.cancelRequestTitle),
        content: Text(copy.cancelRequestBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(copy.keepRequest),
          ),
          TextButton(
            key: const Key('confirm-cancel'),
            onPressed: () => Navigator.pop(context, true),
            child: Text(copy.cancelRequest),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final request = _request!;
    await _act(
      (key) => SessionScope.of(context).api.cancelRequest(
        id: request.id,
        version: request.version,
        idempotencyKey: key,
      ),
    );
  }

  Future<void> _decide(String decision) {
    final request = _request!;
    return _act(
      (key) => SessionScope.of(context).api.techDecision(
        id: request.id,
        version: request.version,
        decision: decision,
        reason: _reason.text.trim(),
        idempotencyKey: key,
      ),
    );
  }

  Future<void> _approve() {
    final request = _request!;
    return _act(
      (key) => SessionScope.of(context).api.approveRequest(
        id: request.id,
        version: request.version,
        idempotencyKey: key,
      ),
    );
  }

  Future<void> _rejectByDirector() {
    final request = _request!;
    return _act(
      (key) => SessionScope.of(context).api.rejectRequest(
        id: request.id,
        version: request.version,
        reason: _reason.text.trim(),
        idempotencyKey: key,
      ),
    );
  }

  Future<void> _recordPayment() {
    final request = _request!;
    final copy = LocaleScope.copy(context);
    final paidOn = _isoDate(_paidOn.text);
    if (paidOn == null || _paymentNumber.text.trim().isEmpty) {
      setState(() => _error = copy.known('Укажите дату и номер платежа.'));
      return Future.value();
    }
    return _act(
      (key) => SessionScope.of(context).api.recordPayment(
        id: request.id,
        version: request.version,
        paidOn: paidOn,
        paymentNumber: _paymentNumber.text.trim(),
        idempotencyKey: key,
      ),
    );
  }

  Future<void> _withdraw() async {
    final copy = LocaleScope.copy(context);
    final confirmed = await showPlainDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(copy.withdrawTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(copy.withdrawBody),
            const SizedBox(height: AppSpacing.md),
            TextField(
              key: const Key('withdraw-reason'),
              controller: _withdrawReason,
              minLines: 2,
              maxLines: 4,
              decoration: InputDecoration(labelText: copy.reasonLabel),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(copy.keepRequest),
          ),
          TextButton(
            key: const Key('confirm-withdraw'),
            onPressed: () => Navigator.pop(context, true),
            child: Text(copy.withdrawApproval),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final request = _request!;
    await _act(
      (key) => SessionScope.of(context).api.withdrawApproval(
        id: request.id,
        version: request.version,
        reason: _withdrawReason.text.trim(),
        idempotencyKey: key,
      ),
    );
  }

  Future<void> _copyRejected() async {
    final request = _request!;
    final created = await _actResult(
      (key) => SessionScope.of(context).api.copyRejected(
        id: request.id,
        version: request.version,
        idempotencyKey: key,
      ),
    );
    if (created == null || !mounted) return;
    context.go('/requests/${created.id}');
  }

  Future<FundingRequest?> _actResult(
    Future<FundingRequest> Function(String key) send,
  ) async {
    final request = _request;
    if (request == null || _saving) return null;
    final copy = LocaleScope.copy(context);
    final key = _actionKey ??= _freshKey();
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final updated = await send(key);
      if (!mounted) return null;
      _actionKey = null;
      _show(updated);
      return updated;
    } on ApiException catch (error) {
      if (!mounted) return null;
      final retry = error.status >= 400 && error.status < 500;
      if (retry) _actionKey = null;
      setState(() {
        _saving = false;
        _error = copy.known(error.message);
      });
      return null;
    }
  }

  Future<void> _removePaymentFile(String fileId) async {
    final request = _request;
    if (request == null) return;
    final copy = LocaleScope.copy(context);
    try {
      await SessionScope.of(context).api.deletePaymentFile(
        requestId: request.id,
        fileId: fileId,
      );
      if (!mounted) return;
      await _load();
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _error = copy.known(error.message));
    }
  }

  Future<void> _addPaymentFile() async {
    final request = _request;
    if (request == null || _uploading) return;
    final picked = await pickRequestFile();
    if (picked == null || !mounted) return;
    final copy = LocaleScope.copy(context);
    setState(() {
      _uploading = true;
      _error = null;
    });
    try {
      await SessionScope.of(context).api.uploadPaymentFile(
        requestId: request.id,
        bytes: picked.bytes,
      );
      if (!mounted) return;
      setState(() => _uploading = false);
      await _load();
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _uploading = false;
        _error = copy.known(error.message);
      });
    }
  }

  String? _isoDate(String raw) {
    final text = raw.trim();
    final dotted = RegExp(r'^(\d{2})\.(\d{2})\.(\d{4})$').firstMatch(text);
    if (dotted != null) {
      return '${dotted.group(3)}-${dotted.group(2)}-${dotted.group(1)}';
    }
    if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(text)) return text;
    return null;
  }

  String _shownDate(String? iso) {
    if (iso == null || iso.length < 10) return '';
    final parts = iso.substring(0, 10).split('-');
    if (parts.length != 3) return iso;
    return '${parts[2]}.${parts[1]}.${parts[0]}';
  }

  String _tashkent(String iso) {
    if (iso.isEmpty) return '';
    final local = DateTime.parse(iso).toUtc().add(const Duration(hours: 5));
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(local.day)}.${two(local.month)}.${local.year} ${two(local.hour)}:${two(local.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready || _request == null && _error == null) {
      return const SizedBox.expand();
    }
    final copy = LocaleScope.copy(context);
    final request = _request;
    if (request == null) {
      return ScreenScroll(
        children: [
          _back(copy),
          EmptyState(title: copy.requestMissing, body: copy.requestMissingBody),
        ],
      );
    }
    final colors = context.colors;
    final editable =
        request.status == 'draft' && (request.mine || _role == AppRole.developer);
    return ScreenScroll(
      children: [
        _back(copy),
        Text(
          request.lineTitle,
          key: const Key('request-card'),
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          request.projectName,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.inkMuted),
        ),
        const SizedBox(height: AppSpacing.lg),
        IBuildCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              StatusText(
                label: copy.requestStatus(request.status),
                tone: _tone(request.status),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(request.lineTitle, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              Text(
                moneyUzs(request.amount),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                request.planSet
                    ? copy.lineLeft(moneyUzs(request.lineAvailable))
                    : copy.planNotSet,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.inkMuted),
              ),
              if (request.description.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  copy.whatWasDone(request.description),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.inkMuted,
                  ),
                ),
              ],
              if ((request.addresseeName ?? '').isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '${copy.sendTo}: ${copy.recipientLine(request.addresseeRole ?? '', request.addresseeName!)}',
                ),
              ],
              if (request.forBank && !request.bankSent) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  copy.addressedToBank,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.inkMuted),
                ),
              ],
              if (request.bankSent) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(copy.sentToBank),
              ],
              if (request.status == 'paid' && (request.paymentNumber ?? '').isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  copy.paymentOn(request.paymentNumber!, _shownDate(request.paidOn)),
                ),
              ],
              if (editable) ...[
                const SizedBox(height: AppSpacing.lg),
                if (_lines.isNotEmpty)
                  DropdownButtonFormField<String>(
                    key: ValueKey('draft-line-$_lineId'),
                    initialValue: _lineId,
                    decoration: InputDecoration(labelText: copy.lineTitle),
                    items: [
                      for (final line in _lines)
                        DropdownMenuItem(
                          value: line.id,
                          child: Text('${line.title} · ${moneyUzs(line.amount)}'),
                        ),
                    ],
                    onChanged: (value) => setState(() => _lineId = value),
                  ),
                if (_selectedLine != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    '${copy.lineAvailable}: ${moneyUzs(_selectedLine!.available)}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.inkMuted),
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _amount,
                  decoration: InputDecoration(labelText: copy.amount),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _description,
                  minLines: 3,
                  maxLines: 5,
                  decoration: InputDecoration(labelText: copy.description),
                ),
                const SizedBox(height: AppSpacing.md),
                PrimaryButton(
                  key: const Key('save-draft-edit'),
                  label: copy.saveChanges,
                  busy: _saving,
                  onPressed: _amount.text.trim().isEmpty ? null : _save,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        IBuildCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(copy.filesTitle, style: Theme.of(context).textTheme.titleMedium),
              if (editable) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  copy.fileRules,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.inkMuted,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              if (request.files.where((file) => !file.isPayment).isEmpty)
                Text(
                  copy.photoNote,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.inkMuted,
                  ),
                )
              else
                Wrap(
                  spacing: AppSpacing.md,
                  runSpacing: AppSpacing.md,
                  children: [
                    for (final file in request.files.where((file) => !file.isPayment))
                      _FileTile(
                        file: file,
                        bytes: _photos[file.id],
                        canRemove: editable,
                        removeLabel: copy.removeFile,
                        onRemove: () => _removeFile(file.id),
                      ),
                  ],
                ),
              if (editable) ...[
                const SizedBox(height: AppSpacing.md),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: AppSpacing.md,
                    children: [
                      TextButton(
                        key: const Key('add-file'),
                        onPressed: _uploading ? null : () => _addFile(),
                        child: Text(_uploading ? copy.save : copy.addFile),
                      ),
                    ],
                  ),
                ),
              ],
              if (editable && !request.files.any((file) => file.isPhoto)) ...[
                const SizedBox(height: AppSpacing.md),
                Text(copy.photoRequired),
              ],
              if (editable && request.files.any((file) => file.isPhoto)) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  copy.sendHint,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.inkMuted),
                ),
                const SizedBox(height: AppSpacing.md),
                if (!request.planSet)
                  Text(copy.planNotSetBody),
                if (!request.planSet) const SizedBox(height: AppSpacing.md),
                PrimaryButton(
                  key: const Key('send-request'),
                  label: copy.sendToTech,
                  busy: _saving,
                  onPressed: request.planSet ? _submit : null,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        IBuildCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(copy.checkTitle, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.md),
              _MoneyRow(label: copy.requestedAmount, amount: request.amount),
              _MoneyRow(label: copy.linePlan, amount: request.linePlan),
              _MoneyRow(label: copy.lineReserved, amount: request.lineReserved),
              _MoneyRow(label: copy.linePaid, amount: request.linePaid),
              _MoneyRow(label: copy.lineAvailable, amount: request.lineAvailable),
            ],
          ),
        ),
        if ((request.mine || _role == AppRole.developer) &&
            request.status == 'submitted') ...[
          const SizedBox(height: AppSpacing.md),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              key: const Key('cancel-request'),
              onPressed: _saving ? null : _cancel,
              child: Text(copy.cancelRequest),
            ),
          ),
        ],
        if ((_role == AppRole.tech || _role == AppRole.developer) &&
            request.status == 'submitted') ...[
          const SizedBox(height: AppSpacing.lg),
          PrimaryButton(
            key: const Key('tech-approve'),
            label: copy.approveWork,
            busy: _saving,
            onPressed: () => _decide('approve'),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            key: const Key('decision-reason'),
            controller: _reason,
            minLines: 1,
            maxLines: 3,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(labelText: copy.reasonLabel),
          ),
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              key: const Key('tech-reject'),
              onPressed: _saving || _reason.text.trim().isEmpty ? null : () => _decide('reject'),
              child: Text(copy.rejectWork),
            ),
          ),
        ],
        if (_isBank && request.status != 'draft') ...[
          const SizedBox(height: AppSpacing.lg),
          _ContactCard(requestId: request.id),
          const SizedBox(height: AppSpacing.md),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () async {
                try {
                  await SessionScope.of(context).api.requestInspection(
                    projectId: request.projectId,
                    scheduledOn: '',
                    note: copy.inspectionNote(request.lineTitle),
                    requestId: request.id,
                  );
                  if (context.mounted) context.go('/inspections');
                } on ApiException catch (error) {
                  if (mounted) setState(() => _error = error.message);
                }
              },
              child: Text(copy.orderInspection),
            ),
          ),
        ],
        if (_isBank && (request.status == 'submitted' || request.status == 'tech_approved')) ...[
          const SizedBox(height: AppSpacing.lg),
          if (_techNote(request) != null) ...[
            Text(copy.eventAction('tech_approved')),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${_techNote(request)!.authorName}'
              '${_techNote(request)!.reason.isEmpty ? '' : ' · ${_techNote(request)!.reason}'}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.inkMuted),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          PrimaryButton(
            key: const Key('director-approve'),
            label: copy.agreeRequest,
            busy: _saving,
            onPressed: _approve,
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            key: const Key('director-reason'),
            controller: _reason,
            minLines: 1,
            maxLines: 3,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(labelText: copy.reasonLabel),
          ),
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              key: const Key('director-reject'),
              onPressed: _saving || _reason.text.trim().isEmpty ? null : _rejectByDirector,
              child: Text(copy.rejectWork),
            ),
          ),
        ],
        if (_isBank && request.status == 'approved') ...[
          const SizedBox(height: AppSpacing.lg),
          IBuildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(copy.paymentTitle, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  copy.paymentHint,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.inkMuted),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  key: const Key('payment-date'),
                  controller: _paidOn,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(labelText: copy.paymentDate, hintText: '15.10.2026'),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  key: const Key('payment-number'),
                  controller: _paymentNumber,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(labelText: copy.paymentNumber),
                ),
                const SizedBox(height: AppSpacing.md),
                if (request.files.any((file) => file.isPayment))
                  Wrap(
                    spacing: AppSpacing.md,
                    runSpacing: AppSpacing.md,
                    children: [
                      for (final file in request.files.where((file) => file.isPayment))
                        _FileTile(
                          file: file,
                          bytes: _photos[file.id],
                          canRemove: true,
                          removeLabel: copy.removeFile,
                          onRemove: () => _removePaymentFile(file.id),
                        ),
                    ],
                  )
                else
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      key: const Key('payment-file'),
                      onPressed: _uploading ? null : _addPaymentFile,
                      child: Text(_uploading ? copy.save : copy.attachProof),
                    ),
                  ),
                const SizedBox(height: AppSpacing.md),
                PrimaryButton(
                  key: const Key('record-payment'),
                  label: copy.recordPayment,
                  busy: _saving,
                  onPressed: _isoDate(_paidOn.text) == null ||
                          _paymentNumber.text.trim().isEmpty ||
                          !request.files.any((file) => file.isPayment)
                      ? null
                      : _recordPayment,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              key: const Key('withdraw-approval'),
              onPressed: _saving ? null : _withdraw,
              child: Text(copy.withdrawApproval),
            ),
          ),
        ],
        if (!_isBank && request.status == 'tech_approved') ...[
          const SizedBox(height: AppSpacing.lg),
          Text(copy.waitingForBank),
        ],
        if (!_isBank && request.status == 'approved') ...[
          const SizedBox(height: AppSpacing.lg),
          Text(copy.waitingForRelease),
        ],
        if ((request.mine || _role == AppRole.developer) &&
            request.status == 'rejected') ...[
          const SizedBox(height: AppSpacing.md),
          PrimaryButton(
            key: const Key('new-from-rejection'),
            label: copy.newFromRejection,
            busy: _saving,
            onPressed: _copyRejected,
          ),
        ],
        if (request.events.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          IBuildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(copy.history, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: AppSpacing.md),
                for (var i = 0; i < request.events.length; i++) ...[
                  if (i > 0) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Divider(height: 1, color: colors.outline),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                  Text(
                    copy.eventAction(request.events[i].action),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${_tashkent(request.events[i].at)} · ${request.events[i].authorName}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.inkMuted,
                    ),
                  ),
                  if (request.events[i].reason.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(request.events[i].reason),
                  ],
                ],
              ],
            ),
          ),
        ],
        if (_error != null) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            copy.known(_error!),
            key: const Key('file-error'),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.danger),
          ),
        ],
      ],
    );
  }

  RequestEvent? _techNote(FundingRequest request) {
    RequestEvent? note;
    for (final event in request.events) {
      if (event.action == 'tech_approved') note = event;
    }
    return note;
  }

  StatusTone _tone(String status) {
    return switch (status) {
      'paid' || 'approved' || 'tech_approved' => StatusTone.good,
      'rejected' || 'cancelled' => StatusTone.bad,
      _ => StatusTone.wait,
    };
  }

  Widget _back(AppCopy copy) {
    return TextButton(
      style: backLinkStyle,
      onPressed: () => context.go('/requests'),
      child: Text(copy.backToRequests),
    );
  }
}

class _MoneyRow extends StatelessWidget {
  const _MoneyRow({required this.label, required this.amount});

  final String label;
  final Object? amount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: context.colors.inkMuted,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(moneyUzs(amount)),
        ],
      ),
    );
  }
}

class _FileTile extends StatefulWidget {
  const _FileTile({
    required this.file,
    required this.bytes,
    required this.canRemove,
    required this.removeLabel,
    required this.onRemove,
  });

  final RequestFile file;
  final Uint8List? bytes;
  final bool canRemove;
  final String removeLabel;
  final VoidCallback onRemove;

  @override
  State<_FileTile> createState() => _FileTileState();
}

class _FileTileState extends State<_FileTile> {
  bool _photo = false;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  @override
  void didUpdateWidget(covariant _FileTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bytes != widget.bytes || oldWidget.file.id != widget.file.id) {
      _photo = false;
      _resolve();
    }
  }

  Future<void> _resolve() async {
    final bytes = widget.bytes;
    if (!widget.file.isPhoto || bytes == null || bytes.length < 64) return;
    try {
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;
      final readable = image.width >= 24 && image.height >= 24;
      image.dispose();
      codec.dispose();
      if (readable && mounted) setState(() => _photo = true);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final bytes = widget.bytes;
    return SizedBox(
      width: 180,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_photo && bytes != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadii.sm),
              child: Image.memory(
                bytes,
                key: Key('request-photo-${widget.file.id}'),
                height: 120,
                width: 180,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _frame(context, widget.file.isPhoto),
              ),
            )
          else
            _frame(context, widget.file.isPhoto),
          if (widget.canRemove)
            TextButton(
              key: Key('remove-file-${widget.file.id}'),
              style: backLinkStyle,
              onPressed: widget.onRemove,
              child: Text(widget.removeLabel),
            ),
        ],
      ),
    );
  }

  Widget _frame(BuildContext context, bool photo) {
    final colors = context.colors;
    return Container(
      key: Key('request-file-${widget.file.id}'),
      height: 120,
      width: 180,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(AppRadii.sm),
        border: Border.all(color: colors.outline),
      ),
      child: Text(
        photo
            ? LocaleScope.copy(context).photoTile
            : LocaleScope.copy(context).pdfTile,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.inkMuted),
      ),
    );
  }
}

class _ContactCard extends StatefulWidget {
  const _ContactCard({required this.requestId});

  final String requestId;

  @override
  State<_ContactCard> createState() => _ContactCardState();
}

class _ContactCardState extends State<_ContactCard> {
  final _message = TextEditingController();
  String? _sent;
  String? _error;

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _message.text.trim();
    if (text.isEmpty) return;
    try {
      await SessionScope.of(context).api.contactRequest(
        id: widget.requestId,
        message: text,
      );
      if (!mounted) return;
      setState(() {
        _sent = LocaleScope.copy(context).contactSent;
        _error = null;
      });
      _message.clear();
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final copy = LocaleScope.copy(context);
    return IBuildCard(
      key: const Key('bank-contact'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(copy.contactTitle, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.md),
          TextField(
            key: const Key('contact-message'),
            controller: _message,
            minLines: 2,
            maxLines: 4,
            decoration: InputDecoration(labelText: copy.contactMessage),
          ),
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(copy.known(_error!)),
          ],
          if (_sent != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(_sent!),
          ],
          const SizedBox(height: AppSpacing.md),
          PrimaryButton(
            key: const Key('send-contact'),
            label: copy.contactSend,
            onPressed: () {
              _send();
            },
          ),
        ],
      ),
    );
  }
}
