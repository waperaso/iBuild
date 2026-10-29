import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../api.dart';
import '../../money.dart';
import '../../session_scope.dart';
import '../../theme.dart';
import '../../widgets.dart';
import 'bank_dialogs.dart';
import 'bank_models.dart';
import 'bank_ui.dart';
import 'journal_section.dart';
import 'line_detail.dart';

const _wideBreakpoint = 760.0;

class BankTrancheScreen extends StatefulWidget {
  const BankTrancheScreen({super.key, required this.id});

  final String id;

  @override
  State<BankTrancheScreen> createState() => _BankTrancheScreenState();
}

class _BankTrancheScreenState extends State<BankTrancheScreen> {
  BankTranche? _tranche;
  String? _error;
  bool _missing = false;
  bool _showPassed = false;
  bool _started = false;
  int _generation = 0;
  final _expanded = <String>{};
  bool _busy = false;
  String? _actionError;

  // One key per decision: sending the same decision again after a lost answer is harmless.
  String? _decisionKey;
  String? _decisionKind;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _load();
  }

  @override
  void didUpdateWidget(BankTrancheScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.id != widget.id) {
      _tranche = null;
      _showPassed = false;
      _expanded.clear();
      _actionError = null;
      _load();
    }
  }

  Future<void> _load({bool keepError = false}) async {
    final generation = ++_generation;
    final api = SessionScope.of(context).api;
    setState(() {
      _error = null;
      _missing = false;
      if (!keepError) _actionError = null;
    });
    try {
      final tranche = await api.bankTranche(widget.id);
      if (!mounted || generation != _generation) return;
      setState(() => _tranche = tranche);
    } on ApiException catch (failure) {
      if (!mounted || generation != _generation) return;
      setState(() {
        if (failure.status == 404) {
          _missing = true;
        } else {
          _error = failure.message;
        }
      });
    }
  }

  /// Runs one change. The answer is the whole card as the server counted it,
  /// so the screen never shows a number the server did not give.
  Future<bool> _apply(Future<BankTranche> Function(Api api) change) async {
    if (_busy) return false;
    final api = SessionScope.of(context).api;
    final strings = BankStrings.of(context);
    setState(() {
      _busy = true;
      _actionError = null;
    });
    try {
      final next = await change(api);
      if (!mounted) return true;
      setState(() {
        _tranche = next;
        _busy = false;
      });
      return true;
    } on ApiException catch (failure) {
      if (!mounted) return false;
      setState(() {
        _busy = false;
        _actionError = failure.status == 0 ? strings.saveFailed : failure.message;
      });
      // A refusal usually means the card is out of date: show the current one.
      if (failure.status == 409 || failure.status == 403) await _load(keepError: true);
      return false;
    }
  }

  Future<void> _choose(BankLine line, String choice) {
    return _apply((api) => api.bankChoose(trancheId: widget.id, lineId: line.id, choice: choice));
  }

  Future<void> _act(BankCheck check, String action) async {
    if (action == 'waive') {
      final answer = await showBankWaiveDialog(context, check);
      if (answer == null || !mounted) return;
      await _apply((api) => api.bankWaive(
        trancheId: widget.id,
        checkId: check.id,
        reason: answer.reason,
        comment: answer.comment,
      ));
      return;
    }
    await _apply((api) => api.bankRequest(trancheId: widget.id, checkId: check.id));
  }

  String _freshKey() {
    final random = Random.secure();
    return List.generate(
      16,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
  }

  Future<void> _decide(String kind) async {
    final tranche = _tranche;
    if (tranche == null) return;
    final strings = BankStrings.of(context);
    final issue = '${bankAmount(context, tranche.totals.issue)} ${bankUnit(context)}';
    final returned = '${bankAmount(context, tranche.totals.returned)} ${bankUnit(context)}';
    final (title, body, confirm, ask) = switch (kind) {
      'return_all' => (strings.returnAllTitle, strings.returnAllBody, strings.returnAll, true),
      'control_measure' => (strings.measureTitle, strings.measureBody, strings.orderInspection, true),
      'suspend' => (strings.suspendTitle, strings.suspendBody, strings.suspend, true),
      _ => (
        strings.partialConfirmTitle,
        strings.partialConfirmBody(issue, returned),
        strings.send,
        false,
      ),
    };
    final note = await showBankConfirmDialog(
      context,
      title: title,
      body: body,
      confirmLabel: confirm,
      askReason: ask,
      reasonLabel: strings.reasonLabel,
      requiredMessage: strings.reasonRequired,
    );
    if (note == null || !mounted) return;
    // The same decision keeps its key until it succeeds.
    if (_decisionKind != kind) {
      _decisionKind = kind;
      _decisionKey = _freshKey();
    }
    final key = _decisionKey ?? _freshKey();
    final done = await _apply((api) => api.bankDecide(
      trancheId: widget.id,
      kind: kind,
      note: note,
      idempotencyKey: key,
    ));
    if (done) {
      _decisionKind = null;
      _decisionKey = null;
    }
  }

  Future<void> _resume() => _apply((api) => api.bankResume(widget.id));

  @override
  Widget build(BuildContext context) {
    final strings = BankStrings.of(context);
    final tranche = _tranche;
    return ScreenScroll(
      key: const Key('bank-tranche-frame'),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            key: const Key('bank-back'),
            style: backLinkStyle,
            onPressed: () => context.go('/bank/queue'),
            icon: const Icon(Icons.arrow_back, size: 18),
            label: Text(strings.backToQueue),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (_missing)
          EmptyState(title: strings.notFound, body: '')
        else if (_error != null)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ErrorNote(message: strings.loadFailed),
              const SizedBox(height: AppSpacing.md),
              OutlinedButton(
                key: const Key('bank-retry'),
                onPressed: _load,
                child: Text(strings.retry),
              ),
            ],
          )
        else if (tranche == null)
          const Padding(
            padding: EdgeInsets.all(AppSpacing.xxl),
            child: Center(child: CircularProgressIndicator(key: Key('bank-tranche-loading'))),
          )
        else ...[
          _Header(tranche: tranche),
          const SizedBox(height: AppSpacing.lg),
          BankStageStrip(stages: tranche.stages),
          const SizedBox(height: AppSpacing.lg),
          _Totals(totals: tranche.totals),
          const SizedBox(height: AppSpacing.lg),
          if (_actionError != null) ...[
            ErrorNote(message: _actionError!),
            const SizedBox(height: AppSpacing.lg),
          ],
          _Checks(
            tranche: tranche,
            showPassed: _showPassed,
            busy: _busy,
            onToggle: () => setState(() => _showPassed = !_showPassed),
            onAction: _act,
          ),
          const SizedBox(height: AppSpacing.lg),
          _Lines(
            tranche: tranche,
            expanded: _expanded,
            busy: _busy,
            onToggle: (id) => setState(() {
              if (!_expanded.remove(id)) _expanded.add(id);
            }),
            onChoose: _choose,
          ),
          const SizedBox(height: AppSpacing.lg),
          _DecisionBar(
            tranche: tranche,
            busy: _busy,
            onDecide: _decide,
            onResume: _resume,
          ),
          const SizedBox(height: AppSpacing.lg),
          BankJournal(
            trancheId: tranche.id,
            version: '${tranche.totals.issue}|${tranche.stage}|${tranche.waitingDeveloper}|${tranche.openChecks.length}',
          ),
        ],
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.tranche});

  final BankTranche tranche;

  @override
  Widget build(BuildContext context) {
    final strings = BankStrings.of(context);
    final theme = Theme.of(context);
    final colors = context.colors;
    final meta = [
      strings.submitted(tranche.submittedDate, tranche.submittedTime),
      if (tranche.techConfirmed != null) strings.techConfirmed(tranche.techConfirmed!),
      strings.elapsedLabel(
        waitingDeveloper: tranche.waitingDeveloper,
        days: tranche.elapsedDays,
        hours: tranche.elapsedHours,
        sla: tranche.slaDays,
      ),
      strings.rules(tranche.rulesVersion),
    ];
    final limit = Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          strings.limitIssued,
          style: theme.textTheme.bodySmall?.copyWith(color: colors.inkMuted),
        ),
        Text(
          '${bankAmount(context, tranche.creditLimit)} / ${bankAmount(context, tranche.issuedTotal)} ${bankUnit(context)}',
          key: const Key('bank-limit'),
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
    final title = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tranche.projectName,
          key: const Key('bank-tranche-object'),
          style: theme.textTheme.headlineMedium,
        ),
        Text(
          '${tranche.projectAddress} · ${tranche.developerName}',
          style: theme.textTheme.bodyMedium?.copyWith(color: colors.inkMuted),
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              strings.tranche(tranche.trancheNo),
              key: const Key('bank-tranche-title'),
              style: theme.textTheme.titleLarge,
            ),
            BankPill(label: tranche.stageLabel),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          meta.join(' · '),
          key: const Key('bank-tranche-meta'),
          style: theme.textTheme.bodySmall?.copyWith(
            color: tranche.overdue ? colors.danger : colors.inkMuted,
          ),
        ),
      ],
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < _wideBreakpoint) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [title, const SizedBox(height: AppSpacing.lg), limit],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [Expanded(child: title), limit],
        );
      },
    );
  }
}

class _Totals extends StatelessWidget {
  const _Totals({required this.totals});

  final BankTotals totals;

  @override
  Widget build(BuildContext context) {
    final strings = BankStrings.of(context);
    final colors = context.colors;
    final cards = [
      _SumCard(
        keyName: 'requested',
        label: strings.sumRequested,
        value: bankAmount(context, totals.requested),
      ),
      _SumCard(
        keyName: 'confirmed',
        label: strings.sumConfirmed,
        value: bankAmount(context, totals.confirmed),
      ),
      _SumCard(
        keyName: 'blocked',
        label: strings.sumBlocked,
        value: bankAmount(context, totals.blocked),
        valueColor: bankPositive(totals.blocked) ? colors.danger : null,
      ),
      _SumCard(
        keyName: 'issue',
        label: strings.sumIssue,
        value: bankAmount(context, totals.issue),
        valueColor: colors.success,
        outlined: true,
      ),
      _SumCard(
        keyName: 'remaining',
        label: strings.sumRemaining,
        value: bankAmount(context, totals.remaining),
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < _wideBreakpoint) {
          final width = (constraints.maxWidth - AppSpacing.md) / 2;
          return Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: [
              for (final card in cards) SizedBox(width: width, child: card),
            ],
          );
        }
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < cards.length; i++) ...[
                if (i > 0) const SizedBox(width: AppSpacing.md),
                Expanded(child: cards[i]),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _SumCard extends StatelessWidget {
  const _SumCard({
    required this.keyName,
    required this.label,
    required this.value,
    this.valueColor,
    this.outlined = false,
  });

  final String keyName;
  final String label;
  final String value;
  final Color? valueColor;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;
    return Container(
      key: Key('bank-sum-$keyName'),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: outlined ? colors.success : colors.outline, width: outlined ? 1.5 : 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.bodySmall?.copyWith(color: colors.inkMuted)),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            key: Key('bank-sum-$keyName-value'),
            style: theme.textTheme.headlineSmall?.copyWith(
              color: valueColor ?? colors.ink,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            bankUnit(context),
            style: theme.textTheme.bodySmall?.copyWith(color: colors.inkMuted),
          ),
        ],
      ),
    );
  }
}

class _Checks extends StatelessWidget {
  const _Checks({
    required this.tranche,
    required this.showPassed,
    required this.busy,
    required this.onToggle,
    required this.onAction,
  });

  final BankTranche tranche;
  final bool showPassed;
  final bool busy;
  final VoidCallback onToggle;
  final void Function(BankCheck check, String action) onAction;

  @override
  Widget build(BuildContext context) {
    final strings = BankStrings.of(context);
    final theme = Theme.of(context);
    final colors = context.colors;
    return IBuildCard(
      padding: EdgeInsets.zero,
      child: Column(
        key: const Key('bank-checks'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: AppSpacing.lg,
              runSpacing: AppSpacing.xs,
              children: [
                Text(strings.checksTitle, style: theme.textTheme.titleLarge),
                Text(
                  '${strings.checksSubtitle} · ${strings.rules(tranche.rulesVersion)}',
                  style: theme.textTheme.bodySmall?.copyWith(color: colors.inkMuted),
                ),
              ],
            ),
          ),
          if (tranche.openChecks.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
              child: Text(
                strings.noOpenChecks,
                key: const Key('bank-no-open-checks'),
                style: theme.textTheme.bodyMedium?.copyWith(color: colors.inkMuted),
              ),
            ),
          for (final check in tranche.openChecks) ...[
            Divider(height: 1, color: colors.outline),
            _OpenCheck(
              check: check,
              permissions: tranche.permissions,
              busy: busy,
              onAction: onAction,
            ),
          ],
          if (tranche.passedChecks.isNotEmpty) ...[
            Divider(height: 1, color: colors.outline),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                key: const Key('bank-passed-toggle'),
                onPressed: onToggle,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                  child: Text(
                    showPassed
                        ? strings.hidePassed
                        : strings.showPassed(tranche.passedChecks.length),
                  ),
                ),
              ),
            ),
          ],
          if (showPassed)
            Column(
              key: const Key('bank-passed-list'),
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final check in tranche.passedChecks) _PassedCheck(check: check),
                const SizedBox(height: AppSpacing.sm),
              ],
            ),
        ],
      ),
    );
  }
}

class _OpenCheck extends StatelessWidget {
  const _OpenCheck({
    required this.check,
    required this.permissions,
    required this.busy,
    required this.onAction,
  });

  final BankCheck check;
  final BankPermissions permissions;
  final bool busy;
  final void Function(BankCheck check, String action) onAction;

  bool _allowed(String action) {
    return action == 'waive' ? permissions.canDecide : permissions.canRequest;
  }

  @override
  Widget build(BuildContext context) {
    final strings = BankStrings.of(context);
    final theme = Theme.of(context);
    final colors = context.colors;
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: 2,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(check.title, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
            if (check.basis.isNotEmpty) BankPill(label: check.basis),
          ],
        ),
        if (check.detail.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(check.detail, style: theme.textTheme.bodySmall?.copyWith(color: colors.inkMuted)),
        ],
        if (check.requested != null) ...[
          const SizedBox(height: 4),
          Text(
            strings.requestedStamp(check.requested!.kind, check.requested!.at),
            key: Key('bank-check-${check.code}-requested'),
            style: theme.textTheme.bodySmall?.copyWith(color: bankBlue(context)),
          ),
        ],
        if (check.waiver != null) ...[
          const SizedBox(height: 4),
          Text(
            strings.waivedStamp(
              check.waiver!.by,
              check.waiver!.at,
              strings.waiveReason(check.waiver!.reason),
            ),
            key: Key('bank-check-${check.code}-waiver'),
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.success,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            check.waiver!.comment,
            key: Key('bank-check-${check.code}-waiver-comment'),
            style: theme.textTheme.bodySmall?.copyWith(color: colors.inkMuted),
          ),
        ],
      ],
    );
    final actions = Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final action in check.actions)
          OutlinedButton(
            key: Key('bank-action-${check.code}-$action'),
            onPressed: !busy && _allowed(action) ? () => onAction(check, action) : null,
            child: Text(strings.action(action)),
          ),
      ],
    );
    return Padding(
      key: Key('bank-check-${check.code}'),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final dot = Padding(
            padding: const EdgeInsets.only(top: 5, right: AppSpacing.md),
            child: BankDot(
              key: Key('bank-check-dot-${check.code}'),
              color: bankLevelColor(context, check.level),
            ),
          );
          if (constraints.maxWidth < _wideBreakpoint) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                dot,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      body,
                      if (check.actions.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.md),
                        actions,
                      ],
                    ],
                  ),
                ),
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              dot,
              Expanded(child: body),
              if (check.actions.isNotEmpty) ...[
                const SizedBox(width: AppSpacing.lg),
                actions,
              ],
            ],
          );
        },
      ),
    );
  }
}

class _PassedCheck extends StatelessWidget {
  const _PassedCheck({required this.check});

  final BankCheck check;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;
    return Padding(
      key: Key('bank-passed-${check.code}'),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 6),
      child: Row(
        children: [
          BankDot(color: colors.success, size: 8),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Text(check.title, style: theme.textTheme.bodyMedium)),
          if (check.basis.isNotEmpty)
            Text(check.basis, style: theme.textTheme.bodySmall?.copyWith(color: colors.inkMuted)),
        ],
      ),
    );
  }
}

const _lineFlex = [32, 13, 13, 17, 13, 12];

class _Lines extends StatelessWidget {
  const _Lines({
    required this.tranche,
    required this.expanded,
    required this.busy,
    required this.onToggle,
    required this.onChoose,
  });

  final BankTranche tranche;
  final Set<String> expanded;
  final bool busy;
  final ValueChanged<String> onToggle;
  final void Function(BankLine line, String choice) onChoose;

  @override
  Widget build(BuildContext context) {
    final strings = BankStrings.of(context);
    final theme = Theme.of(context);
    final colors = context.colors;
    return IBuildCard(
      padding: EdgeInsets.zero,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final table = constraints.maxWidth >= _wideBreakpoint;
          return Column(
            key: const Key('bank-lines'),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  spacing: AppSpacing.lg,
                  runSpacing: AppSpacing.xs,
                  children: [
                    Text(strings.linesTitle, style: theme.textTheme.titleLarge),
                    Text(
                      bankUnit(context),
                      style: theme.textTheme.bodySmall?.copyWith(color: colors.inkMuted),
                    ),
                  ],
                ),
              ),
              if (table) _lineHeader(context, strings),
              for (final line in tranche.lines) ...[
                Divider(height: 1, color: colors.outline),
                InkWell(
                  key: Key('bank-line-toggle-${line.id}'),
                  onTap: () => onToggle(line.id),
                  child: table
                      ? _LineRow(line: line, open: expanded.contains(line.id))
                      : _LineCard(line: line, open: expanded.contains(line.id)),
                ),
                if (expanded.contains(line.id))
                  BankLineDetail(
                    line: line,
                    canChoose: tranche.permissions.canDecide,
                    busy: busy,
                    onChoose: (choice) => onChoose(line, choice),
                  ),
              ],
              Divider(height: 1, color: colors.outline),
              _LineTotal(totals: tranche.totals, table: table),
            ],
          );
        },
      ),
    );
  }

  Widget _lineHeader(BuildContext context, BankStrings strings) {
    final style = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: context.colors.inkMuted,
      fontWeight: FontWeight.w600,
    );
    final labels = [
      strings.colLine,
      strings.colIssuedBefore,
      strings.colRequested,
      strings.colReadiness,
      strings.colConfirmed,
      strings.colToIssue,
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.sm),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              flex: _lineFlex[i],
              child: Text(
                labels[i],
                style: style,
                textAlign: i == 0 ? TextAlign.start : TextAlign.end,
              ),
            ),
        ],
      ),
    );
  }
}

String _readiness(BankLine line) {
  final percent = line.readinessPercent;
  if (percent == null || percent.isEmpty) return line.readinessNote;
  return '$percent%';
}

class _LineRow extends StatelessWidget {
  const _LineRow({required this.line, required this.open});

  final BankLine line;
  final bool open;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;
    final bold = theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700);
    final belowRequest = moneyCents(line.confirmed) < moneyCents(line.requested);
    final stopped = line.level == 'block';
    final note = line.readinessPercent == null || line.readinessPercent!.isEmpty
        ? ''
        : line.readinessNote;
    return Padding(
      key: Key('bank-line-${line.id}'),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: _lineFlex[0],
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 5, right: AppSpacing.md),
                  child: BankDot(
                    key: Key('bank-line-dot-${line.id}'),
                    color: bankLevelColor(context, line.level),
                  ),
                ),
                Expanded(child: Text(line.title, style: bold)),
                Icon(open ? Icons.expand_less : Icons.expand_more, size: 18, color: colors.inkMuted),
              ],
            ),
          ),
          Expanded(
            flex: _lineFlex[1],
            child: Text(bankAmount(context, line.issuedBefore), textAlign: TextAlign.end),
          ),
          Expanded(
            flex: _lineFlex[2],
            child: Text(bankAmount(context, line.requested), textAlign: TextAlign.end),
          ),
          Expanded(
            flex: _lineFlex[3],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(_readiness(line), textAlign: TextAlign.end),
                if (note.isNotEmpty)
                  Text(
                    note,
                    textAlign: TextAlign.end,
                    style: theme.textTheme.bodySmall?.copyWith(color: colors.inkMuted),
                  ),
              ],
            ),
          ),
          Expanded(
            flex: _lineFlex[4],
            child: Text(
              bankAmount(context, line.confirmed),
              key: Key('bank-line-${line.id}-confirmed'),
              textAlign: TextAlign.end,
              style: belowRequest ? bold?.copyWith(color: colors.warning) : null,
            ),
          ),
          Expanded(
            flex: _lineFlex[5],
            child: Text(
              bankAmount(context, line.toIssue),
              key: Key('bank-line-${line.id}-issue'),
              textAlign: TextAlign.end,
              style: bold?.copyWith(color: stopped ? colors.danger : null),
            ),
          ),
        ],
      ),
    );
  }
}

class _LineCard extends StatelessWidget {
  const _LineCard({required this.line, required this.open});

  final BankLine line;
  final bool open;

  @override
  Widget build(BuildContext context) {
    final strings = BankStrings.of(context);
    final theme = Theme.of(context);
    final colors = context.colors;
    final stopped = line.level == 'block';
    Widget pair(String label, String value, {Color? color, Key? valueKey}) {
      return Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: theme.textTheme.bodySmall?.copyWith(color: colors.inkMuted)),
            Text(
              value,
              key: valueKey,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      key: Key('bank-line-${line.id}'),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              BankDot(
                key: Key('bank-line-dot-${line.id}'),
                color: bankLevelColor(context, line.level),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  line.title,
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              Icon(open ? Icons.expand_less : Icons.expand_more, size: 18, color: colors.inkMuted),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${strings.colReadiness}: ${_readiness(line)}',
            style: theme.textTheme.bodySmall?.copyWith(color: colors.inkMuted),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              pair(strings.colRequested, bankAmount(context, line.requested)),
              pair(strings.colConfirmed, bankAmount(context, line.confirmed)),
              pair(
                strings.colToIssue,
                bankAmount(context, line.toIssue),
                color: stopped ? colors.danger : null,
                valueKey: Key('bank-line-${line.id}-issue'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LineTotal extends StatelessWidget {
  const _LineTotal({required this.totals, required this.table});

  final BankTotals totals;
  final bool table;

  @override
  Widget build(BuildContext context) {
    final strings = BankStrings.of(context);
    final bold = Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700);
    final requested = bankAmount(context, totals.requested);
    final confirmed = bankAmount(context, totals.confirmed);
    final issue = bankAmount(context, totals.issue);
    return Padding(
      key: const Key('bank-lines-total'),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: table
          ? Row(
              children: [
                Expanded(flex: _lineFlex[0], child: Text(strings.total, style: bold)),
                const Expanded(flex: 13, child: SizedBox()),
                Expanded(flex: _lineFlex[2], child: Text(requested, style: bold, textAlign: TextAlign.end)),
                const Expanded(flex: 17, child: SizedBox()),
                Expanded(flex: _lineFlex[4], child: Text(confirmed, style: bold, textAlign: TextAlign.end)),
                Expanded(flex: _lineFlex[5], child: Text(issue, style: bold, textAlign: TextAlign.end)),
              ],
            )
          : Wrap(
              spacing: AppSpacing.lg,
              runSpacing: AppSpacing.xs,
              children: [
                Text(strings.total, style: bold),
                Text(requested, style: bold),
                Text(confirmed, style: bold),
                Text(issue, style: bold),
              ],
            ),
    );
  }
}

class _DecisionBar extends StatelessWidget {
  const _DecisionBar({
    required this.tranche,
    required this.busy,
    required this.onDecide,
    required this.onResume,
  });

  final BankTranche tranche;
  final bool busy;
  final ValueChanged<String> onDecide;
  final VoidCallback onResume;

  @override
  Widget build(BuildContext context) {
    final strings = BankStrings.of(context);
    final theme = Theme.of(context);
    final colors = context.colors;
    final totals = tranche.totals;
    final permissions = tranche.permissions;
    final issue = '${bankAmount(context, totals.issue)} ${bankUnit(context)}';
    final returned = '${bankAmount(context, totals.returned)} ${bankUnit(context)}';
    final approve = bankPositive(totals.returned)
        ? strings.approveAndReturn(issue, returned)
        : strings.approveOnly(issue);
    final enabled = permissions.canDecide && !busy;

    Widget banner(String keyName, String text, {Color? color, Widget? action}) {
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              text,
              key: Key(keyName),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
            ?action,
          ],
        ),
      );
    }

    final moved = tranche.stage == 'approval' || tranche.stage == 'payout';
    return IBuildCard(
      child: Column(
        key: const Key('bank-decision-bar'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (tranche.outcome == 'rejected')
            banner('bank-banner-rejected', strings.rejectedBanner, color: colors.danger)
          else if (moved)
            banner(
              'bank-banner-sent',
              strings.decisionSent,
              color: colors.success,
              action: TextButton(
                key: const Key('bank-open-approval'),
                onPressed: () => context.go('/bank/tranches/${tranche.id}/approval'),
                child: Text(strings.openApproval),
              ),
            )
          else if (tranche.fundingPaused)
            banner('bank-banner-paused', strings.pausedBanner, color: colors.danger)
          else if (tranche.waitingDeveloper)
            banner('bank-banner-waiting', strings.waitingBanner, color: colors.inkMuted),
          if (permissions.canResume)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: OutlinedButton(
                key: const Key('bank-resume'),
                onPressed: busy ? null : onResume,
                child: Text(strings.resume),
              ),
            ),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: [
              PrimaryButton(
                key: const Key('bank-decide-approve'),
                label: approve,
                onPressed: enabled && bankPositive(totals.issue) ? () => onDecide('partial') : null,
              ),
              OutlinedButton(
                key: const Key('bank-decide-return'),
                onPressed: enabled ? () => onDecide('return_all') : null,
                child: Text(strings.returnAll),
              ),
              OutlinedButton(
                key: const Key('bank-decide-measure'),
                onPressed: enabled ? () => onDecide('control_measure') : null,
                child: Text(strings.orderInspection),
              ),
              OutlinedButton(
                key: const Key('bank-decide-suspend'),
                onPressed: enabled && permissions.canSuspend ? () => onDecide('suspend') : null,
                child: Text(strings.suspend),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            permissions.canDecide ? strings.decisionNote : strings.decisionClosed,
            key: const Key('bank-decision-note'),
            style: theme.textTheme.bodySmall?.copyWith(color: colors.inkMuted),
          ),
        ],
      ),
    );
  }
}
