import 'package:flutter/material.dart';

import '../../l10n/gen/app_localizations.dart';

/// Asks "Are you sure you want to sign out?" before actually signing out —
/// every explicit sign-out affordance in the app (settings, shell nav, the
/// apply wizard's app-bar action) routes through this so a stray tap can't
/// end the session by accident.
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
