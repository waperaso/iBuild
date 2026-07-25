import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/localization/status_labels.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_theme_ext.dart';
import '../../core/widgets/pill_button.dart';
import '../../l10n/gen/app_localizations.dart';
import '../admin/admin_api.dart';
import '../auth/auth.dart';

final crmAssigneesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(adminApiProvider).crmAssignees();
});

/// Owner line for kanban cards — shows assignee name or "Unassigned".
class LeadOwnerLine extends StatelessWidget {
  const LeadOwnerLine({super.key, required this.lead});

  final Map<String, dynamic> lead;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    final label =
        (lead['assignedManager'] as String?)?.trim() ??
        lead['ownerUserId']?.toString();

    return Row(
      children: [
        CircleAvatar(
          radius: 10,
          backgroundColor: label == null
              ? colors.outline
              : colors.accentSecondary,
          child: Icon(
            label == null ? Icons.person_off_outlined : Icons.person_outline,
            size: 12,
            color: colors.surface,
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            label == null || label.isEmpty
                ? l10n.crmOwnerUnassigned
                : l10n.crmAssignedTo(label),
            style: textTheme.labelSmall?.copyWith(color: colors.inkMuted),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// All / Mine / Unassigned filter chips for CRM boards.
class CrmOwnerFilterChips extends StatelessWidget {
  const CrmOwnerFilterChips({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Wrap(
      spacing: AppSpacing.sm,
      children: [
        ChoiceChip(
          label: Text(l10n.crmOwnerFilterAll),
          selected: selected == 'all',
          onSelected: (_) => onChanged('all'),
        ),
        ChoiceChip(
          label: Text(l10n.crmOwnerFilterMine),
          selected: selected == 'me',
          onSelected: (_) => onChanged('me'),
        ),
        ChoiceChip(
          label: Text(l10n.crmOwnerFilterUnassigned),
          selected: selected == 'unassigned',
          onSelected: (_) => onChanged('unassigned'),
        ),
      ],
    );
  }
}

/// Result from the shared CRM lead editor dialog.
class CrmLeadEditResult {
  const CrmLeadEditResult({
    this.status,
    this.score,
    this.ownerUserId,
    this.clearOwner = false,
    this.notes,
    this.tags,
    this.transferToUserId,
    this.transferNote,
  });

  final String? status;
  final String? score;
  final String? ownerUserId;
  final bool clearOwner;
  final String? notes;
  final List<String>? tags;
  final String? transferToUserId;
  final String? transferNote;
}

/// Full CRM editor: status, score, owner picker, notes, transfer, event feed.
class CrmLeadEditorDialog extends ConsumerStatefulWidget {
  const CrmLeadEditorDialog({
    super.key,
    required this.lead,
    required this.statuses,
    this.showTags = false,
    this.initialTags = const [],
  });

  final Map<String, dynamic> lead;
  final List<String> statuses;
  final bool showTags;
  final List<String> initialTags;

  @override
  ConsumerState<CrmLeadEditorDialog> createState() =>
      _CrmLeadEditorDialogState();
}

class _CrmLeadEditorDialogState extends ConsumerState<CrmLeadEditorDialog> {
  String? _status;
  String? _score;
  String? _ownerUserId;
  late final TextEditingController _notes;
  late final TextEditingController _tags;
  late final TextEditingController _transferNote;
  String? _transferToUserId;
  List<Map<String, dynamic>> _events = const [];
  bool _loadingEvents = true;

  @override
  void initState() {
    super.initState();
    _status = widget.lead['status'] as String?;
    _score = widget.lead['score'] as String?;
    _ownerUserId = widget.lead['ownerUserId'] as String?;
    _notes = TextEditingController(text: widget.lead['notes']?.toString() ?? '');
    _tags = TextEditingController(
      text: widget.initialTags.join(', '),
    );
    _transferNote = TextEditingController();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    try {
      final items = await ref
          .read(adminApiProvider)
          .leadEvents(widget.lead['id'] as String);
      if (mounted) {
        setState(() {
          _events = items;
          _loadingEvents = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingEvents = false);
    }
  }

  @override
  void dispose() {
    _notes.dispose();
    _tags.dispose();
    _transferNote.dispose();
    super.dispose();
  }

  String _eventLabel(AppLocalizations l10n, Map<String, dynamic> event) {
    final type = event['type']?.toString() ?? '';
    return switch (type) {
      'assigned' => l10n.crmEventAssigned,
      'transferred' => l10n.crmEventTransferred,
      'unassigned' => l10n.crmEventUnassigned,
      'status_changed' => l10n.crmEventStatusChanged(
        event['detail']?.toString() ?? '',
      ),
      'note' => l10n.crmEventNote,
      _ => type,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final assignees = ref.watch(crmAssigneesProvider);
    final me = ref.watch(authControllerProvider).value;

    return AlertDialog(
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
      title: Text(l10n.crmLeadEditorTitle),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.crmStatusLabel),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                children: [
                  for (final option in widget.statuses)
                    ChoiceChip(
                      label: Text(leadStatusLabel(l10n, option)),
                      selected: _status == option,
                      onSelected: (selected) =>
                          setState(() => _status = selected ? option : null),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(l10n.crmScoreLabel),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                children: [
                  for (final option in const ['hot', 'warm', 'cold'])
                    ChoiceChip(
                      label: Text(leadScoreLabel(l10n, option)),
                      selected: _score == option,
                      onSelected: (selected) =>
                          setState(() => _score = selected ? option : null),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(l10n.crmOwnerLabel),
              const SizedBox(height: AppSpacing.sm),
              assignees.when(
                data: (people) => DropdownButtonFormField<String?>(
                  initialValue: _ownerUserId,
                  decoration: InputDecoration(
                    hintText: l10n.crmOwnerUnassigned,
                  ),
                  items: [
                    DropdownMenuItem<String?>(
                      value: null,
                      child: Text(l10n.crmOwnerUnassigned),
                    ),
                    for (final p in people)
                      DropdownMenuItem<String?>(
                        value: p['id'] as String,
                        child: Text(p['displayLabel']?.toString() ?? ''),
                      ),
                  ],
                  onChanged: (v) => setState(() => _ownerUserId = v),
                ),
                loading: () => const LinearProgressIndicator(),
                error: (_, _) => Text(l10n.crmAssigneesLoadError),
              ),
              if (me != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () => setState(() => _ownerUserId = me.id),
                    child: Text(l10n.crmAssignToMe),
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              Text(l10n.crmTransferLabel),
              const SizedBox(height: AppSpacing.sm),
              assignees.when(
                data: (people) => DropdownButtonFormField<String?>(
                  initialValue: _transferToUserId,
                  decoration: InputDecoration(
                    hintText: l10n.crmTransferHint,
                  ),
                  items: [
                    DropdownMenuItem<String?>(
                      value: null,
                      child: Text(l10n.crmTransferNone),
                    ),
                    for (final p in people)
                      DropdownMenuItem<String?>(
                        value: p['id'] as String,
                        child: Text(p['displayLabel']?.toString() ?? ''),
                      ),
                  ],
                  onChanged: (v) => setState(() => _transferToUserId = v),
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
              ),
              if (_transferToUserId != null) ...[
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: _transferNote,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: l10n.crmTransferNoteLabel,
                  ),
                ),
              ],
              if (widget.showTags) ...[
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _tags,
                  decoration: InputDecoration(labelText: l10n.crmTagsLabel),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _notes,
                maxLines: 3,
                decoration: InputDecoration(labelText: l10n.crmNotesLabel),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(l10n.crmEventHistoryTitle, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: AppSpacing.sm),
              if (_loadingEvents)
                const Padding(
                  padding: EdgeInsets.all(AppSpacing.md),
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                )
              else if (_events.isEmpty)
                Text(
                  l10n.crmEventHistoryEmpty,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.inkMuted,
                  ),
                )
              else
                ..._events.take(8).map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: Text(
                      '${_formatWhen(e['createdAt'])} · ${_eventLabel(l10n, e)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.commonCancel),
        ),
        PillButton(
          label: l10n.commonSave,
          onPressed: () {
            final tags = widget.showTags
                ? _tags.text
                      .split(',')
                      .map((t) => t.trim())
                      .where((t) => t.isNotEmpty)
                      .toList()
                : null;
            final initialOwner = widget.lead['ownerUserId'] as String?;
            final clearOwner = _ownerUserId == null && initialOwner != null;
            Navigator.pop(
              context,
              CrmLeadEditResult(
                status: _status,
                score: _score,
                ownerUserId: _transferToUserId ?? _ownerUserId,
                clearOwner: clearOwner && _transferToUserId == null,
                notes: _notes.text.trim(),
                tags: tags,
                transferToUserId: _transferToUserId,
                transferNote: _transferNote.text.trim().isEmpty
                    ? null
                    : _transferNote.text.trim(),
              ),
            );
          },
        ),
      ],
    );
  }

  String _formatWhen(Object? raw) {
    if (raw == null) return '';
    final parsed = DateTime.tryParse(raw.toString());
    if (parsed == null) return raw.toString();
    return '${parsed.day.toString().padLeft(2, '0')}.'
        '${parsed.month.toString().padLeft(2, '0')} '
        '${parsed.hour.toString().padLeft(2, '0')}:'
        '${parsed.minute.toString().padLeft(2, '0')}';
  }
}

/// Applies [result] via AdminApi (assign / transfer / patch).
Future<void> applyCrmLeadEdit(
  WidgetRef ref, {
  required String leadId,
  required CrmLeadEditResult result,
}) async {
  final api = ref.read(adminApiProvider);
  if (result.transferToUserId != null) {
    await api.transferLead(
      leadId,
      toUserId: result.transferToUserId!,
      note: result.transferNote,
    );
    if (result.status != null ||
        result.score != null ||
        (result.notes?.isNotEmpty ?? false) ||
        result.tags != null) {
      await api.updateLead(
        leadId,
        status: result.status,
        score: result.score,
        notes: result.notes,
        tags: result.tags,
      );
    }
    return;
  }

  await api.updateLead(
    leadId,
    status: result.status,
    score: result.score,
    ownerUserId: result.clearOwner ? null : result.ownerUserId,
    clearOwner: result.clearOwner,
    notes: result.notes,
    tags: result.tags,
  );
}
