import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/gen/app_localizations.dart';

/// Runs a platform admin action and shows success/error snackbar.
Future<bool> runPlatformAction(
  BuildContext context,
  WidgetRef ref, {
  required Future<void> Function() action,
  void Function()? onSuccess,
}) async {
  final l10n = AppLocalizations.of(context);
  try {
    await action();
    onSuccess?.call();
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.platformActionSuccess)));
    }
    return true;
  } on DioException catch (error) {
    final body = error.response?.data;
    String? serverMessage;
    if (body is Map) {
      final err = body['error'];
      if (err is Map) {
        serverMessage = err['message']?.toString();
      }
    }
    final message = serverMessage ?? error.message ?? error.toString();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.platformActionError(message))),
      );
    }
    return false;
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.platformActionError('$error'))),
      );
    }
    return false;
  }
}

/// Single free-text prompt (reject reason, warning note, ticket reply, ...).
class NoteDialog extends StatefulWidget {
  const NoteDialog({
    super.key,
    required this.title,
    required this.hint,
    required this.confirmLabel,
  });

  final String title;
  final String hint;
  final String confirmLabel;

  @override
  State<NoteDialog> createState() => _NoteDialogState();
}

class _NoteDialogState extends State<NoteDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return StatefulBuilder(
      builder: (context, setState) {
        return AlertDialog(
          title: Text(widget.title),
          content: TextField(
            controller: _controller,
            autofocus: true,
            maxLines: 3,
            decoration: InputDecoration(hintText: widget.hint),
            onChanged: (_) => setState(() {}),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.commonCancel),
            ),
            FilledButton(
              onPressed: _controller.text.trim().isEmpty
                  ? null
                  : () => Navigator.pop(context, _controller.text.trim()),
              child: Text(widget.confirmLabel),
            ),
          ],
        );
      },
    );
  }
}
