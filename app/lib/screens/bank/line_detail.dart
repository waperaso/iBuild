import 'package:flutter/material.dart';

import '../../theme.dart';
import 'bank_models.dart';
import 'bank_ui.dart';

const _choices = ['confirmed', 'requested', 'withhold'];

/// What lies under an opened budget line: the conclusion of the expert, how
/// the confirmed sum was counted, the evidence, and the choice of the amount.
class BankLineDetail extends StatelessWidget {
  const BankLineDetail({
    super.key,
    required this.line,
    required this.canChoose,
    required this.busy,
    required this.onChoose,
  });

  final BankLine line;
  final bool canChoose;
  final bool busy;
  final ValueChanged<String> onChoose;

  @override
  Widget build(BuildContext context) {
    final strings = BankStrings.of(context);
    final theme = Theme.of(context);
    final colors = context.colors;
    final expert = line.expert;
    final formula = line.formula;
    final muted = theme.textTheme.bodySmall?.copyWith(color: colors.inkMuted);
    final label = theme.textTheme.bodySmall?.copyWith(
      color: colors.inkMuted,
      fontWeight: FontWeight.w600,
    );

    Widget section(String title, List<Widget> children) {
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: label),
            const SizedBox(height: AppSpacing.xs),
            ...children,
          ],
        ),
      );
    }

    final evidence = <Widget>[
      if (expert == null)
        Text(strings.noExpertEvidence, key: Key('bank-line-${line.id}-no-expert'), style: muted)
      else
        section(strings.expertInspection(expert.name, expert.signedOn), [
          if (expert.note.isNotEmpty) Text(expert.note, style: theme.textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xl,
            runSpacing: AppSpacing.xs,
            children: [
              if (expert.readinessPercent != null)
                Text(
                  expert.previousPercent == null
                      ? '${expert.readinessPercent}%'
                      : strings.readinessWas(expert.readinessPercent!, expert.previousPercent!),
                  key: Key('bank-line-${line.id}-readiness'),
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              if (expert.remaining != null)
                Text('${strings.remainingToBuild}: ${bankAmount(context, expert.remaining)}'),
              if (expert.recommended != null)
                Text(
                  '${strings.recommends}: ${bankAmount(context, expert.recommended)}',
                  key: Key('bank-line-${line.id}-recommended'),
                ),
              Text(
                '${strings.riskFlag}: ${expert.riskFlag ? strings.yes : strings.no}',
                key: Key('bank-line-${line.id}-risk'),
                style: TextStyle(color: expert.riskFlag ? colors.warning : null),
              ),
            ],
          ),
        ]),
      if (line.photos.isNotEmpty)
        section(strings.photosTitle, [
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: [
              for (final photo in line.photos)
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.surfaceAlt,
                    borderRadius: BorderRadius.circular(AppRadii.card),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.photo_outlined, size: 16, color: colors.inkMuted),
                            const SizedBox(width: AppSpacing.xs),
                            Text(photo.caption, style: theme.textTheme.bodyMedium),
                          ],
                        ),
                        if (photo.meta.isNotEmpty) Text(photo.meta, style: muted),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ]),
      if (formula != null)
        section(strings.howCounted, [
          Text(
            strings.formula(
              percent: formula.percent,
              plan: bankAmount(context, formula.plan),
              gross: bankAmount(context, formula.gross),
              before: bankAmount(context, formula.issuedBefore),
              result: bankAmount(context, formula.result),
            ),
            key: Key('bank-line-${line.id}-formula'),
            style: theme.textTheme.bodyMedium,
          ),
        ]),
      if (line.documents.isNotEmpty)
        section(strings.documentsTitle, [
          for (final document in line.documents)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Icon(
                    document.ok ? Icons.check_circle_outline : Icons.error_outline,
                    size: 16,
                    color: document.ok ? colors.success : colors.danger,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      document.ok ? document.title : '${document.title} · ${strings.documentMissing}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: document.ok ? null : colors.danger,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ]),
      if (line.payments.isNotEmpty)
        section(strings.paymentsTitle, [
          for (final payment in line.payments)
            Text(
              '${payment.label}, ${payment.paidOn}: ${bankAmount(context, payment.amount)} ${bankUnit(context)}',
              style: theme.textTheme.bodyMedium,
            ),
        ]),
    ];

    return DecoratedBox(
      key: Key('bank-line-${line.id}-detail'),
      decoration: BoxDecoration(color: colors.surfaceAlt.withValues(alpha: 0.5)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg + 22,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...evidence,
            Text(strings.choiceTitle, style: label),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final choice in _choices)
                  _ChoiceButton(
                    line: line,
                    choice: choice,
                    enabled: canChoose && !busy && _allowed(choice),
                    onChoose: onChoose,
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            if (line.blocked)
              Text(strings.lineBlockedNote, key: Key('bank-line-${line.id}-blocked'), style: muted)
            else if (!line.canChooseRequested)
              Text(strings.choiceAboveConfirmed, key: Key('bank-line-${line.id}-above'), style: muted),
          ],
        ),
      ),
    );
  }

  bool _allowed(String choice) {
    if (line.blocked) return choice == 'withhold';
    if (choice == 'requested') return line.canChooseRequested;
    return true;
  }
}

class _ChoiceButton extends StatelessWidget {
  const _ChoiceButton({
    required this.line,
    required this.choice,
    required this.enabled,
    required this.onChoose,
  });

  final BankLine line;
  final String choice;
  final bool enabled;
  final ValueChanged<String> onChoose;

  @override
  Widget build(BuildContext context) {
    final strings = BankStrings.of(context);
    // A blocked line pays nothing, whatever was chosen before the block.
    final selected = (line.blocked ? 'withhold' : line.choice) == choice;
    final label = Text(strings.choiceLabel(choice));
    final key = Key('bank-choice-${line.id}-$choice');
    final action = enabled && !selected ? () => onChoose(choice) : null;
    if (selected) {
      // The chosen one stays filled even when nothing can be changed.
      return FilledButton(key: key, onPressed: action ?? () {}, child: label);
    }
    return OutlinedButton(key: key, onPressed: action, child: label);
  }
}
