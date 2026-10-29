import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../api.dart';
import '../l10n.dart';
import '../models.dart';
import '../session_scope.dart';
import '../theme.dart';
import '../widgets.dart';

class ModerationScreen extends StatefulWidget {
  const ModerationScreen({super.key});

  @override
  State<ModerationScreen> createState() => _ModerationScreenState();
}

class _ModerationScreenState extends State<ModerationScreen> {
  List<ProjectChange> _items = const [];
  var _loading = true;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _load();
  }

  var _started = false;

  Future<void> _load() async {
    final session = SessionScope.of(context);
    if (session.user?.platformAdmin != true) {
      setState(() => _loading = false);
      return;
    }
    try {
      final items = await session.api.moderationQueue();
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
        _error = null;
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

  Future<void> _approve(ProjectChange change) async {
    try {
      await SessionScope.of(context).api.approveProjectChange(change.id);
      await _load();
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    }
  }

  Future<void> _reject(ProjectChange change) async {
    final note = await showPlainDialog<String>(
      context: context,
      builder: (context) => _RejectDialog(name: change.currentName),
    );
    if (note == null || !mounted) return;
    try {
      await SessionScope.of(context).api.rejectProjectChange(id: change.id, note: note);
      await _load();
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final admin = SessionScope.of(context).user?.platformAdmin == true;
    final copy = LocaleScope.copy(context);
    return ScreenScroll(
      children: [
        Text(copy.moderation, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: AppSpacing.sm),
        Text(
          copy.moderationSubtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: context.colors.inkMuted),
        ),
        const SizedBox(height: AppSpacing.xl),
        if (!admin)
          Text(copy.moderationAdminOnly)
        else if (_loading)
          const SizedBox.shrink()
        else if (_items.isEmpty)
          Column(
            key: const Key('empty-moderation'),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(copy.moderationEmpty, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.xs),
              Text(
                copy.moderationEmptyBody,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: context.colors.inkMuted),
              ),
            ],
          )
        else
          for (final change in _items) ...[
            _ChangeCard(
              change: change,
              onApprove: () => _approve(change),
              onReject: () => _reject(change),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        if (_error != null) ...[
          const SizedBox(height: AppSpacing.md),
          Text(copy.known(_error!)),
        ],
      ],
    );
  }
}

class _ChangeCard extends StatelessWidget {
  const _ChangeCard({
    required this.change,
    required this.onApprove,
    required this.onReject,
  });

  final ProjectChange change;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final copy = LocaleScope.copy(context);
    return IBuildCard(
      key: Key('moderation-${change.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(copy.place(change.currentName), style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          Text(copy.currentNameIs(copy.place(change.currentName))),
          Text(change.currentAddress),
          const SizedBox(height: AppSpacing.md),
          Text(copy.proposedNameIs(copy.place(change.name)), style: Theme.of(context).textTheme.titleMedium),
          Text(change.address),
          if (change.hasPhoto) ...[
            const SizedBox(height: AppSpacing.md),
            _BytesPhoto(load: () => SessionScope.of(context).api.changePhoto(change.id)),
          ],
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              PrimaryButton(label: copy.accept, onPressed: onApprove),
              TextButton(onPressed: onReject, child: Text(copy.rejectWork)),
            ],
          ),
        ],
      ),
    );
  }
}

class _BytesPhoto extends StatelessWidget {
  const _BytesPhoto({required this.load});

  final Future<Uint8List?> Function() load;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: load(),
      builder: (context, snapshot) {
        final bytes = snapshot.data;
        if (bytes == null || bytes.isEmpty) return const SizedBox.shrink();
        return ClipRRect(
          borderRadius: BorderRadius.circular(AppRadii.input),
          child: Image.memory(bytes, height: 140, width: double.infinity, fit: BoxFit.cover),
        );
      },
    );
  }
}

class _RejectDialog extends StatefulWidget {
  const _RejectDialog({required this.name});

  final String name;

  @override
  State<_RejectDialog> createState() => _RejectDialogState();
}

class _RejectDialogState extends State<_RejectDialog> {
  final _note = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final copy = LocaleScope.copy(context);
    return AlertDialog(
      title: Text(copy.rejectChangeTitle(copy.place(widget.name))),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            key: const Key('reject-note'),
            controller: _note,
            decoration: InputDecoration(labelText: copy.reasonLabel),
          ),
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(_error!),
          ],
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(copy.cancel)),
        PrimaryButton(
          label: copy.rejectWork,
          onPressed: () {
            final note = _note.text.trim();
            if (note.isEmpty) {
              setState(() => _error = copy.needRejectReason);
              return;
            }
            Navigator.pop(context, note);
          },
        ),
      ],
    );
  }
}
