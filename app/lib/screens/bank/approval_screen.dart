import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../api.dart';
import '../../session_scope.dart';
import '../../theme.dart';
import '../../widgets.dart';
import 'bank_dialogs.dart';
import 'bank_models.dart';
import 'bank_ui.dart';

const _wideBreakpoint = 900.0;

class BankApprovalScreen extends StatefulWidget {
  const BankApprovalScreen({super.key, required this.id});

  final String id;

  @override
  State<BankApprovalScreen> createState() => _BankApprovalScreenState();
}

class _BankApprovalScreenState extends State<BankApprovalScreen> {
  BankApproval? _approval;
  String? _error;
  String? _actionError;
  bool _missing = false;
  bool _busy = false;
  bool _started = false;
  int _generation = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _load();
  }

  @override
  void didUpdateWidget(BankApprovalScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.id != widget.id) {
      _approval = null;
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
      final approval = await api.bankApproval(widget.id);
      if (!mounted || generation != _generation) return;
      setState(() => _approval = approval);
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

  Future<void> _vote(String vote) async {
    if (_busy) return;
    final strings = BankStrings.of(context);
    var comment = '';
    if (vote != 'approve') {
      final answer = await showBankConfirmDialog(
        context,
        title: vote == 'reject' ? strings.rejectTitle : strings.returnToSpecialist,
        body: '',
        confirmLabel: vote == 'reject' ? strings.reject : strings.returnToSpecialist,
        askReason: true,
        reasonLabel: strings.reasonLabel,
        requiredMessage: strings.reasonRequired,
      );
      if (answer == null || !mounted) return;
      comment = answer;
    }
    final api = SessionScope.of(context).api;
    setState(() {
      _busy = true;
      _actionError = null;
    });
    try {
      final next = await api.bankVote(trancheId: widget.id, vote: vote, comment: comment);
      if (!mounted) return;
      setState(() {
        _approval = next;
        _busy = false;
      });
    } on ApiException catch (failure) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _actionError = failure.status == 0 ? strings.saveFailed : failure.message;
      });
      if (failure.status == 409 || failure.status == 403) await _load(keepError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = BankStrings.of(context);
    final approval = _approval;
    return ScreenScroll(
      key: const Key('bank-approval-frame'),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            key: const Key('bank-approval-back'),
            style: backLinkStyle,
            onPressed: () => context.go('/bank/tranches/${widget.id}'),
            icon: const Icon(Icons.arrow_back, size: 18),
            label: Text(strings.toCheck),
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
        else if (approval == null)
          const Padding(
            padding: EdgeInsets.all(AppSpacing.xxl),
            child: Center(child: CircularProgressIndicator(key: Key('bank-approval-loading'))),
          )
        else ...[
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                strings.approvalTitle(approval.trancheNo),
                key: const Key('bank-approval-title'),
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              BankPill(label: approval.stageLabel),
            ],
          ),
          Text(
            approval.projectName,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: context.colors.inkMuted),
          ),
          const SizedBox(height: AppSpacing.lg),
          BankStageStrip(stages: approval.stages),
          const SizedBox(height: AppSpacing.lg),
          if (_actionError != null) ...[
            ErrorNote(message: _actionError!),
            const SizedBox(height: AppSpacing.lg),
          ],
          LayoutBuilder(
            builder: (context, constraints) {
              final route = _Route(approval: approval);
              final side = _Side(approval: approval, busy: _busy, onVote: _vote);
              if (constraints.maxWidth < _wideBreakpoint) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [route, const SizedBox(height: AppSpacing.lg), side],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: route),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(flex: 2, child: side),
                ],
              );
            },
          ),
        ],
      ],
    );
  }
}

class _Route extends StatelessWidget {
  const _Route({required this.approval});

  final BankApproval approval;

  @override
  Widget build(BuildContext context) {
    final strings = BankStrings.of(context);
    final colors = context.colors;
    return IBuildCard(
      padding: EdgeInsets.zero,
      child: Column(
        key: const Key('bank-route'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(strings.routeTitle, style: Theme.of(context).textTheme.titleLarge),
          ),
          for (final step in approval.steps) ...[
            Divider(height: 1, color: colors.outline),
            _StepTile(approval: approval, step: step),
          ],
        ],
      ),
    );
  }
}

class _StepTile extends StatelessWidget {
  const _StepTile({required this.approval, required this.step});

  final BankApproval approval;
  final BankApprovalStep step;

  String _notes(BuildContext context, BankStrings strings) {
    final issue = '${bankAmount(context, approval.issue)} ${bankUnit(context)}';
    final threshold = '${bankAmount(context, approval.threshold)} ${bankUnit(context)}';
    final group = step.group;
    switch (step.code) {
      case 'expert':
        final date = approval.expertSignedOn;
        return step.status == 'done' && date != null ? strings.expertSigned(date) : '';
      case 'specialist':
        return step.status == 'done' ? strings.specialistPrepared(issue, approval.waivedCount) : '';
      case 'head':
        return [
          if (group != null) strings.groupNeeds(group.size, step.required),
          if (step.status == 'current') strings.preparerCannot,
        ].join('\n');
      case 'committee':
        if (step.status == 'skipped') return strings.committeeSkipped(issue, threshold);
        return [
          strings.committeeWhy(step.reason, threshold),
          if (group != null) strings.groupNeeds(group.size, step.required),
          if (group != null && group.onLeave.isNotEmpty)
            strings.committeeLeave(group.available, group.onLeave),
        ].where((line) => line.isNotEmpty).join('\n');
      case 'sign':
        return strings.signLocked;
      case 'payment':
        return strings.paymentNote;
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final strings = BankStrings.of(context);
    final theme = Theme.of(context);
    final colors = context.colors;
    final notes = _notes(context, strings);
    final done = step.status == 'done';
    final current = step.status == 'current';
    final muted = step.status == 'skipped' || step.status == 'waiting';
    final icon = done
        ? Icon(Icons.check_circle, size: 20, color: colors.success)
        : current
            ? Icon(Icons.radio_button_checked, size: 20, color: bankBlue(context))
            : Icon(
                step.kind == 'external' ? Icons.lock_outline : Icons.radio_button_unchecked,
                size: 20,
                color: colors.inkMuted,
              );
    return Padding(
      key: Key('bank-step-${step.code}'),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          icon,
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: AppSpacing.md,
                  runSpacing: 2,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      strings.stepTitle(step.code),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: muted ? colors.inkMuted : null,
                      ),
                    ),
                    if (step.by.isNotEmpty && done)
                      Text(step.by, style: theme.textTheme.bodySmall?.copyWith(color: colors.inkMuted)),
                  ],
                ),
                if (notes.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      notes,
                      key: Key('bank-step-${step.code}-note'),
                      style: theme.textTheme.bodySmall?.copyWith(color: colors.inkMuted),
                    ),
                  ),
                if (step.kind == 'group' && (current || step.status == 'pending') && step.approved > 0)
                  Text(
                    strings.votesCount(step.approved, step.required),
                    key: Key('bank-step-${step.code}-count'),
                    style: theme.textTheme.bodySmall,
                  ),
                for (final vote in step.votes)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      '${vote.by} · ${strings.voteLabel(vote.vote)}, ${vote.at}'
                      '${vote.comment.isEmpty ? '' : ': ${vote.comment}'}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(
            strings.stepStatus(step.status),
            key: Key('bank-step-${step.code}-status'),
            style: theme.textTheme.bodySmall?.copyWith(
              color: done
                  ? colors.success
                  : current
                      ? bankBlue(context)
                      : colors.inkMuted,
              fontWeight: current ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

class _Side extends StatelessWidget {
  const _Side({required this.approval, required this.busy, required this.onVote});

  final BankApproval approval;
  final bool busy;
  final ValueChanged<String> onVote;

  @override
  Widget build(BuildContext context) {
    final strings = BankStrings.of(context);
    final theme = Theme.of(context);
    final colors = context.colors;
    final unit = bankUnit(context);

    Widget figure(String keyName, String label, String value, {Color? color}) {
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Row(
          children: [
            Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
            Text(
              value,
              key: Key(keyName),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      );
    }

    final enabled = approval.canAct && !busy;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        IBuildCard(
          child: Column(
            key: const Key('bank-decision-card'),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(strings.cardTitle, style: theme.textTheme.titleLarge),
              const SizedBox(height: AppSpacing.md),
              figure(
                'bank-card-issue',
                '${strings.cardIssue}, $unit',
                bankAmount(context, approval.issue),
                color: colors.success,
              ),
              figure(
                'bank-card-returned',
                '${strings.cardReturned}, $unit',
                bankAmount(context, approval.returned),
              ),
              figure('bank-card-waived', strings.cardWaived, '${approval.waivedCount}'),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        IBuildCard(
          child: Column(
            key: const Key('bank-return-lines'),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(strings.returnLinesTitle, style: theme.textTheme.titleMedium),
              Text(
                strings.returnDeadline(approval.returnDays),
                style: theme.textTheme.bodySmall?.copyWith(color: colors.inkMuted),
              ),
              const SizedBox(height: AppSpacing.md),
              if (approval.returnLines.isEmpty)
                Text(strings.noReturnLines, style: theme.textTheme.bodyMedium),
              for (final line in approval.returnLines)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              line.title,
                              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                          Text(bankAmount(context, line.amount)),
                        ],
                      ),
                      Text(
                        line.reason,
                        style: theme.textTheme.bodySmall?.copyWith(color: colors.inkMuted),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (approval.outcome == 'rejected')
          Text(
            strings.rejectedBanner,
            key: const Key('bank-approval-rejected'),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.danger,
              fontWeight: FontWeight.w600,
            ),
          )
        else ...[
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: [
              PrimaryButton(
                key: const Key('bank-vote-approve'),
                label: strings.approve,
                onPressed: enabled ? () => onVote('approve') : null,
              ),
              OutlinedButton(
                key: const Key('bank-vote-return'),
                onPressed: enabled ? () => onVote('return') : null,
                child: Text(strings.returnToSpecialist),
              ),
              OutlinedButton(
                key: const Key('bank-vote-reject'),
                onPressed: enabled ? () => onVote('reject') : null,
                child: Text(strings.reject),
              ),
            ],
          ),
          if (!approval.canAct && approval.blocker != null)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.md),
              child: Text(
                strings.blocker(approval.blocker!),
                key: const Key('bank-approval-blocker'),
                style: theme.textTheme.bodySmall?.copyWith(color: colors.inkMuted),
              ),
            ),
        ],
      ],
    );
  }
}
