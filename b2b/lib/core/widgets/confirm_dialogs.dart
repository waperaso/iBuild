import 'package:flutter/material.dart';

import '../../l10n/gen/app_localizations.dart';

/// Sign-out confirmation dialog.
Future<bool> confirmSignOut(BuildContext context) async {
  final l10n = AppLocalizations.of(context);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l10n.logoutConfirmTitle),
      content: Text(l10n.logoutConfirmMessage),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(l10n.commonSignOut),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
