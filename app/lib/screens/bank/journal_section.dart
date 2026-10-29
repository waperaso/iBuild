import 'package:flutter/material.dart';

import '../../api.dart';
import '../../session_scope.dart';
import '../../theme.dart';
import '../../widgets.dart';
import 'bank_models.dart';
import 'bank_ui.dart';

/// The journal of one tranche: who, what, when. Folded by default and loaded
/// only when the person opens it.
class BankJournal extends StatefulWidget {
  const BankJournal({super.key, required this.trancheId, required this.version});

  final String trancheId;

  /// Changes whenever the card changes, so an open journal follows the card.
  final Object version;

  @override
  State<BankJournal> createState() => _BankJournalState();
}

class _BankJournalState extends State<BankJournal> {
  bool _open = false;
  bool _failed = false;
  List<BankJournalEntry>? _entries;
  int _generation = 0;

  @override
  void didUpdateWidget(BankJournal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.trancheId != widget.trancheId) {
      _entries = null;
      if (_open) _load();
    } else if (oldWidget.version != widget.version && _open) {
      _load();
    }
  }

  Future<void> _load() async {
    final generation = ++_generation;
    final api = SessionScope.of(context).api;
    try {
      final entries = await api.bankJournal(widget.trancheId);
      if (!mounted || generation != _generation) return;
      setState(() {
        _entries = entries;
        _failed = false;
      });
    } on ApiException {
      if (!mounted || generation != _generation) return;
      setState(() => _failed = true);
    }
  }

  void _toggle() {
    setState(() => _open = !_open);
    if (_open && _entries == null) _load();
  }

  String _when(DateTime at) {
    final local = at.toLocal();
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(local.day)}.${two(local.month)}.${local.year} ${two(local.hour)}:${two(local.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final strings = BankStrings.of(context);
    final theme = Theme.of(context);
    final colors = context.colors;
    final entries = _entries;
    return IBuildCard(
      padding: EdgeInsets.zero,
      child: Column(
        key: const Key('bank-journal'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            key: const Key('bank-journal-toggle'),
            onTap: _toggle,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  Expanded(child: Text(strings.journalTitle, style: theme.textTheme.titleLarge)),
                  Text(
                    _open ? strings.journalHide : strings.journalShow,
                    style: theme.textTheme.bodySmall?.copyWith(color: colors.inkMuted),
                  ),
                  Icon(_open ? Icons.expand_less : Icons.expand_more, size: 18, color: colors.inkMuted),
                ],
              ),
            ),
          ),
          if (_open) ...[
            Divider(height: 1, color: colors.outline),
            if (_failed)
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: ErrorNote(message: strings.journalFailed),
              )
            else if (entries == null)
              const Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (entries.isEmpty)
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Text(
                  strings.journalEmpty,
                  key: const Key('bank-journal-empty'),
                  style: theme.textTheme.bodyMedium?.copyWith(color: colors.inkMuted),
                ),
              )
            else
              for (final entry in entries) ...[
                Padding(
                  key: Key('bank-journal-${entry.id}'),
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 120,
                        child: Text(
                          _when(entry.at),
                          style: theme.textTheme.bodySmall?.copyWith(color: colors.inkMuted),
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(strings.journalLine(entry), style: theme.textTheme.bodyMedium),
                            if (entry.actor.isNotEmpty)
                              Text(
                                entry.actor,
                                style: theme.textTheme.bodySmall?.copyWith(color: colors.inkMuted),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: colors.outline),
              ],
          ],
        ],
      ),
    );
  }
}
