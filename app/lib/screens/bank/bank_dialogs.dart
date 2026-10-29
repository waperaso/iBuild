import 'package:flutter/material.dart';

import '../../theme.dart';
import 'bank_models.dart';
import 'bank_ui.dart';

const bankWaiveReasons = ['outside_system', 'fixed_elsewhere', 'approved_exception', 'other'];

class BankWaiveAnswer {
  const BankWaiveAnswer({required this.reason, required this.comment});

  final String reason;
  final String comment;
}

/// "Accept the check with a reason". The reason and the comment are both required.
Future<BankWaiveAnswer?> showBankWaiveDialog(BuildContext context, BankCheck check) {
  return showDialog<BankWaiveAnswer>(
    context: context,
    builder: (context) => _WaiveDialog(check: check),
  );
}

class _WaiveDialog extends StatefulWidget {
  const _WaiveDialog({required this.check});

  final BankCheck check;

  @override
  State<_WaiveDialog> createState() => _WaiveDialogState();
}

class _WaiveDialogState extends State<_WaiveDialog> {
  final _comment = TextEditingController();
  String _reason = bankWaiveReasons.first;
  bool _missing = false;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _comment.text.trim();
    if (text.isEmpty) {
      setState(() => _missing = true);
      return;
    }
    Navigator.of(context).pop(BankWaiveAnswer(reason: _reason, comment: text));
  }

  @override
  Widget build(BuildContext context) {
    final strings = BankStrings.of(context);
    final theme = Theme.of(context);
    final colors = context.colors;
    final check = widget.check;
    return AlertDialog(
      key: const Key('bank-waive-dialog'),
      title: Text(strings.waiveTitle),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                        children: [
                          BankDot(color: bankLevelColor(context, check.level)),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Text(
                              check.title,
                              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        strings.waiveKept,
                        style: theme.textTheme.bodySmall?.copyWith(color: colors.inkMuted),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(strings.waiveReasonLabel, style: theme.textTheme.labelLarge),
              RadioGroup<String>(
                groupValue: _reason,
                onChanged: (value) => setState(() => _reason = value ?? _reason),
                child: Column(
                  children: [
                    for (final reason in bankWaiveReasons)
                      RadioListTile<String>(
                        key: Key('bank-waive-reason-$reason'),
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        value: reason,
                        title: Text(strings.waiveReason(reason)),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                key: const Key('bank-waive-comment'),
                controller: _comment,
                minLines: 3,
                maxLines: 5,
                maxLength: 1000,
                onChanged: (_) {
                  if (_missing) setState(() => _missing = false);
                },
                decoration: InputDecoration(
                  labelText: strings.waiveCommentLabel,
                  hintText: strings.waiveCommentHint,
                  errorText: _missing ? strings.waiveCommentRequired : null,
                  border: const OutlineInputBorder(),
                ),
              ),
              if (check.level == 'block') ...[
                const SizedBox(height: AppSpacing.md),
                DecoratedBox(
                  key: const Key('bank-waive-block-warning'),
                  decoration: BoxDecoration(
                    color: colors.warning.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(AppRadii.card),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Text(strings.waiveBlockWarning, style: theme.textTheme.bodySmall),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          key: const Key('bank-waive-cancel'),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(strings.cancel),
        ),
        FilledButton(
          key: const Key('bank-waive-submit'),
          onPressed: _submit,
          child: Text(strings.waiveSubmit),
        ),
      ],
    );
  }
}

/// A short confirmation, with an optional required comment. Returns the comment
/// (empty when none was asked for) or null when the person cancelled.
Future<String?> showBankConfirmDialog(
  BuildContext context, {
  required String title,
  required String body,
  required String confirmLabel,
  bool askReason = false,
  String? reasonLabel,
  String? requiredMessage,
}) {
  return showDialog<String>(
    context: context,
    builder: (context) => _ConfirmDialog(
      title: title,
      body: body,
      confirmLabel: confirmLabel,
      askReason: askReason,
      reasonLabel: reasonLabel,
      requiredMessage: requiredMessage,
    ),
  );
}

class _ConfirmDialog extends StatefulWidget {
  const _ConfirmDialog({
    required this.title,
    required this.body,
    required this.confirmLabel,
    required this.askReason,
    this.reasonLabel,
    this.requiredMessage,
  });

  final String title;
  final String body;
  final String confirmLabel;
  final bool askReason;
  final String? reasonLabel;
  final String? requiredMessage;

  @override
  State<_ConfirmDialog> createState() => _ConfirmDialogState();
}

class _ConfirmDialogState extends State<_ConfirmDialog> {
  final _reason = TextEditingController();
  bool _missing = false;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _reason.text.trim();
    if (widget.askReason && text.isEmpty) {
      setState(() => _missing = true);
      return;
    }
    Navigator.of(context).pop(text);
  }

  @override
  Widget build(BuildContext context) {
    final strings = BankStrings.of(context);
    return AlertDialog(
      key: const Key('bank-confirm-dialog'),
      title: Text(widget.title),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.body),
              if (widget.askReason) ...[
                const SizedBox(height: AppSpacing.lg),
                TextField(
                  key: const Key('bank-confirm-reason'),
                  controller: _reason,
                  minLines: 3,
                  maxLines: 5,
                  maxLength: 1000,
                  onChanged: (_) {
                    if (_missing) setState(() => _missing = false);
                  },
                  decoration: InputDecoration(
                    labelText: widget.reasonLabel,
                    errorText: _missing ? widget.requiredMessage : null,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          key: const Key('bank-confirm-cancel'),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(strings.cancel),
        ),
        FilledButton(
          key: const Key('bank-confirm-submit'),
          onPressed: _submit,
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}
