import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/gen/app_localizations.dart';

/// Wraps a dialog so Enter confirms and Escape cancels.
Widget bindDialogKeyboardActions({
  required VoidCallback onConfirm,
  required VoidCallback onCancel,
  required Widget child,
}) {
  return CallbackShortcuts(
    bindings: {
      const SingleActivator(LogicalKeyboardKey.enter): onConfirm,
      const SingleActivator(LogicalKeyboardKey.escape): onCancel,
    },
    child: Focus(autofocus: true, child: child),
  );
}

/// Simple yes/no dialog with keyboard shortcuts (Enter = confirm).
Future<bool?> showConfirmDialog({
  required BuildContext context,
  required Widget title,
  required Widget content,
  required String cancelLabel,
  required String confirmLabel,
}) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) {
      void cancel() => Navigator.pop(ctx, false);
      void confirm() => Navigator.pop(ctx, true);

      return bindDialogKeyboardActions(
        onConfirm: confirm,
        onCancel: cancel,
        child: AlertDialog(
          title: title,
          content: content,
          actions: [
            TextButton(onPressed: cancel, child: Text(cancelLabel)),
            FilledButton(
              autofocus: true,
              onPressed: confirm,
              child: Text(confirmLabel),
            ),
          ],
        ),
      );
    },
  );
}

/// Sign-out confirmation dialog.
Future<bool> confirmSignOut(BuildContext context) async {
  final l10n = AppLocalizations.of(context);
  final confirmed = await showConfirmDialog(
    context: context,
    title: Text(l10n.logoutConfirmTitle),
    content: Text(l10n.logoutConfirmMessage),
    cancelLabel: l10n.commonCancel,
    confirmLabel: l10n.commonSignOut,
  );
  return confirmed ?? false;
}
