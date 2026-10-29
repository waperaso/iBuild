import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../api.dart';
import '../../l10n.dart';
import '../../session_scope.dart';
import '../../theme.dart';
import '../../widgets.dart';
import 'bank_models.dart';
import 'bank_ui.dart';

/// Where the table turns into cards.
const _tableBreakpoint = 820.0;

class BankQueueScreen extends StatefulWidget {
  const BankQueueScreen({super.key});

  @override
  State<BankQueueScreen> createState() => _BankQueueScreenState();
}

class _BankQueueScreenState extends State<BankQueueScreen> {
  String _tab = 'mine';
  BankQueue? _queue;
  String? _error;
  bool _loading = true;
  bool _started = false;
  int _generation = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _load();
  }

  Future<void> _load() async {
    final generation = ++_generation;
    final api = SessionScope.of(context).api;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final queue = await api.bankQueue(_tab);
      if (!mounted || generation != _generation) return;
      setState(() {
        _queue = queue;
        _loading = false;
      });
    } on ApiException catch (failure) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _error = failure.message;
        _loading = false;
      });
    }
  }

  void _select(String tab) {
    if (tab == _tab) return;
    setState(() => _tab = tab);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final strings = BankStrings.of(context);
    final theme = Theme.of(context);
    final queue = _queue;
    return ScreenScroll(
      key: const Key('bank-queue-frame'),
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.end,
          spacing: AppSpacing.lg,
          runSpacing: AppSpacing.sm,
          children: [
            Text(LocaleScope.copy(context).queue, style: theme.textTheme.headlineMedium),
            Text(
              '${strings.amountsIn} ${bankUnit(context)}',
              key: const Key('bank-queue-unit'),
              style: theme.textTheme.bodyMedium?.copyWith(color: context.colors.inkMuted),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final code in bankQueueTabs)
              _TabChip(
                code: code,
                label: strings.tab(code),
                count: queue?.counts.forTab(code),
                selected: code == _tab,
                onTap: () => _select(code),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        if (_error != null)
          _LoadFailed(message: _error!, onRetry: _load)
        else if (_loading && queue == null)
          const Padding(
            padding: EdgeInsets.all(AppSpacing.xxl),
            child: Center(child: CircularProgressIndicator(key: Key('bank-queue-loading'))),
          )
        else if (queue != null)
          Opacity(
            opacity: _loading ? 0.5 : 1,
            child: _QueueList(tab: _tab, items: queue.items),
          ),
        const SizedBox(height: AppSpacing.lg),
        const _Legend(),
      ],
    );
  }
}

class _TabChip extends StatelessWidget {
  const _TabChip({
    required this.code,
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String code;
  final String label;
  final int? count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textColor = selected ? colors.onAccent : colors.ink;
    return Material(
      color: selected ? colors.accent : colors.surface,
      shape: StadiumBorder(side: BorderSide(color: selected ? colors.accent : colors.outline)),
      child: InkWell(
        key: Key('bank-tab-$code'),
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (count != null) ...[
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '$count',
                  key: Key('bank-tab-$code-count'),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: textColor.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadFailed extends StatelessWidget {
  const _LoadFailed({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final strings = BankStrings.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ErrorNote(message: strings.loadFailed),
        const SizedBox(height: AppSpacing.md),
        OutlinedButton(
          key: const Key('bank-retry'),
          onPressed: onRetry,
          child: Text(strings.retry),
        ),
      ],
    );
  }
}

class _QueueList extends StatelessWidget {
  const _QueueList({required this.tab, required this.items});

  final String tab;
  final List<BankQueueItem> items;

  @override
  Widget build(BuildContext context) {
    final strings = BankStrings.of(context);
    if (items.isEmpty) {
      return EmptyState(title: strings.emptyTitle(tab), body: strings.emptyBody(tab));
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final table = constraints.maxWidth >= _tableBreakpoint;
        return IBuildCard(
          padding: EdgeInsets.zero,
          child: Column(
            key: Key('bank-queue-list-$tab'),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (table) const _TableHeader(),
              for (var i = 0; i < items.length; i++) ...[
                if (table || i > 0) Divider(height: 1, color: context.colors.outline),
                table ? _TableRow(item: items[i]) : _CardRow(item: items[i]),
              ],
            ],
          ),
        );
      },
    );
  }
}

const _columnFlex = [30, 8, 12, 17, 15, 20, 15, 11];

class _TableHeader extends StatelessWidget {
  const _TableHeader();

  @override
  Widget build(BuildContext context) {
    final strings = BankStrings.of(context);
    final style = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: context.colors.inkMuted,
      fontWeight: FontWeight.w600,
    );
    final labels = [
      strings.colObject,
      strings.colTranche,
      strings.colAmount,
      strings.colStage,
      strings.colTime,
      strings.colProblems,
      strings.colHolder,
      '',
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(flex: _columnFlex[i], child: Text(labels[i], style: style)),
        ],
      ),
    );
  }
}

void _openTranche(BuildContext context, BankQueueItem item) {
  context.go('/bank/tranches/${item.id}');
}

class _TableRow extends StatelessWidget {
  const _TableRow({required this.item});

  final BankQueueItem item;

  @override
  Widget build(BuildContext context) {
    final strings = BankStrings.of(context);
    final theme = Theme.of(context);
    final colors = context.colors;
    final dot = bankSignalColor(context, signal: item.signal, overdue: item.overdue);
    return InkWell(
      key: Key('bank-row-${item.id}'),
      onTap: () => _openTranche(context, item),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              flex: _columnFlex[0],
              child: Row(
                children: [
                  BankDot(key: Key('bank-dot-${item.id}'), color: dot),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.projectName,
                          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          item.developerName,
                          style: theme.textTheme.bodySmall?.copyWith(color: colors.inkMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(flex: _columnFlex[1], child: Text(strings.trancheNo(item.trancheNo))),
            Expanded(
              flex: _columnFlex[2],
              child: Text(
                bankAmount(context, item.requestedAmount),
                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            Expanded(
              flex: _columnFlex[3],
              child: Align(alignment: Alignment.centerLeft, child: BankPill(label: item.stageLabel)),
            ),
            Expanded(
              flex: _columnFlex[4],
              child: Text(
                strings.elapsed(item),
                key: Key('bank-elapsed-${item.id}'),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: item.overdue ? colors.danger : (item.waitingDeveloper ? colors.inkMuted : colors.ink),
                  fontWeight: item.overdue ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
            ),
            Expanded(
              flex: _columnFlex[5],
              child: Text(
                item.problemsLabel.isEmpty ? '—' : item.problemsLabel,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: item.problemsLabel.isEmpty ? colors.inkMuted : colors.ink,
                ),
              ),
            ),
            Expanded(flex: _columnFlex[6], child: Text(item.holderLabel)),
            Expanded(
              flex: _columnFlex[7],
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  key: Key('bank-open-${item.id}'),
                  onPressed: () => _openTranche(context, item),
                  child: Text(strings.open),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardRow extends StatelessWidget {
  const _CardRow({required this.item});

  final BankQueueItem item;

  @override
  Widget build(BuildContext context) {
    final strings = BankStrings.of(context);
    final theme = Theme.of(context);
    final colors = context.colors;
    final dot = bankSignalColor(context, signal: item.signal, overdue: item.overdue);
    return InkWell(
      key: Key('bank-row-${item.id}'),
      onTap: () => _openTranche(context, item),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                BankDot(key: Key('bank-dot-${item.id}'), color: dot),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    item.projectName,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                Text(
                  bankAmount(context, item.requestedAmount),
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              '${item.developerName} · ${strings.tranche(item.trancheNo)}',
              style: theme.textTheme.bodySmall?.copyWith(color: colors.inkMuted),
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.sm,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                BankPill(label: item.stageLabel),
                Text(
                  strings.elapsed(item),
                  key: Key('bank-elapsed-${item.id}'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: item.overdue ? colors.danger : colors.inkMuted,
                    fontWeight: item.overdue ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              ],
            ),
            if (item.problemsLabel.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(item.problemsLabel, style: theme.textTheme.bodyMedium),
            ],
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.holderLabel,
                    style: theme.textTheme.bodySmall?.copyWith(color: colors.inkMuted),
                  ),
                ),
                TextButton(
                  key: Key('bank-open-${item.id}'),
                  onPressed: () => _openTranche(context, item),
                  child: Text(strings.open),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    final strings = BankStrings.of(context);
    final colors = context.colors;
    final entries = [
      (colors.danger, strings.legendOverdue),
      (colors.warning, strings.legendProblem),
      (bankBlue(context), strings.legendInspection),
      (colors.inkMuted.withValues(alpha: 0.55), strings.legendDeveloper),
    ];
    return Wrap(
      key: const Key('bank-legend'),
      spacing: AppSpacing.xl,
      runSpacing: AppSpacing.sm,
      children: [
        for (final entry in entries)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              BankDot(color: entry.$1, size: 8),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Text(
                  entry.$2,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.inkMuted),
                ),
              ),
            ],
          ),
      ],
    );
  }
}
