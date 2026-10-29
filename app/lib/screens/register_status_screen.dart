import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../api.dart';
import '../file_pick.dart';
import '../l10n.dart';
import '../registration_models.dart';
import '../registration_spec.dart';
import '../session_scope.dart';
import '../theme.dart';
import '../widgets.dart';
import 'register_screen.dart';

/// The applicant's own page: where the application stands, what is missing,
/// and a place to add papers. The link carries a private token.
class RegisterStatusScreen extends StatefulWidget {
  const RegisterStatusScreen({super.key, required this.token});

  final String token;

  @override
  State<RegisterStatusScreen> createState() => _RegisterStatusScreenState();
}

class _RegisterStatusScreenState extends State<RegisterStatusScreen> {
  ApplicationStatusView? _view;
  String? _error;
  var _loading = true;
  var _started = false;
  String? _uploading;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _load();
  }

  Future<void> _load() async {
    final api = SessionScope.of(context).api;
    try {
      final view = await api.applicationStatus(widget.token);
      if (!mounted) return;
      setState(() {
        _view = view;
        _error = null;
        _loading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _loading = false;
      });
    }
  }

  Future<void> _add(ApplicationStatusView view, String type) async {
    final api = SessionScope.of(context).api;
    final picked = await pickRequestFile();
    if (picked == null || !mounted) return;
    setState(() => _uploading = type);
    try {
      await api.uploadApplicationDocument(
        id: view.id,
        token: widget.token,
        type: type,
        fileName: picked.name,
        bytes: picked.bytes,
      );
      await _load();
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _uploading = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final copy = LocaleScope.copy(context);
    final theme = Theme.of(context);
    final colors = context.colors;
    final view = _view;
    return PublicFrame(
      child: Column(
        key: const Key('register-status'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(copy.statusTitle, style: theme.textTheme.headlineMedium),
          const SizedBox(height: AppSpacing.lg),
          if (_loading)
            const SizedBox.shrink()
          else if (view == null)
            ErrorNote(message: copy.known(_error ?? copy.statusNotFound))
          else ...[
            IBuildCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(view.orgName, style: theme.textTheme.titleLarge),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${copy.applicationNumber}: ${view.code}',
                    style: theme.textTheme.bodyMedium?.copyWith(color: colors.inkMuted),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  StatusText(
                    key: const Key('applicant-status'),
                    label: copy.say(applicantStatusLabels[view.status] ?? applicantStatusLabels['new']!),
                    tone: switch (view.status) {
                      'approved' => StatusTone.good,
                      'rejected' => StatusTone.bad,
                      'docs_requested' => StatusTone.wait,
                      _ => StatusTone.neutral,
                    },
                  ),
                  if (view.status == 'docs_requested' && view.requestNote.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.lg),
                    Text(copy.adminAsks, style: theme.textTheme.titleSmall),
                    const SizedBox(height: AppSpacing.xs),
                    Text(view.requestNote, key: const Key('request-note')),
                  ],
                  if (view.status == 'rejected' && view.decisionNote.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.lg),
                    Text(copy.declineReason, style: theme.textTheme.titleSmall),
                    const SizedBox(height: AppSpacing.xs),
                    Text(view.decisionNote),
                  ],
                  if (view.status == 'approved') ...[
                    const SizedBox(height: AppSpacing.lg),
                    Text(copy.approvedNote),
                  ],
                ],
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.md),
              ErrorNote(message: copy.known(_error!)),
            ],
            const SizedBox(height: AppSpacing.lg),
            _documents(context, copy, view),
            const SizedBox(height: AppSpacing.lg),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: () {
                  setState(() => _loading = true);
                  _load();
                },
                icon: const Icon(Icons.refresh, size: 18),
                label: Text(copy.refresh),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => context.go('/login'),
              child: Text(copy.backToSignIn),
            ),
          ),
        ],
      ),
    );
  }

  Widget _documents(BuildContext context, AppCopy copy, ApplicationStatusView view) {
    final theme = Theme.of(context);
    final colors = context.colors;
    final rules = docsFor(view.kind);
    return IBuildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(copy.documentsTitle, style: theme.textTheme.titleLarge),
          const SizedBox(height: AppSpacing.xs),
          Text(
            view.missing.isEmpty ? copy.nothingMissing : copy.stillMissing,
            style: theme.textTheme.bodyMedium?.copyWith(color: colors.inkMuted),
          ),
          const SizedBox(height: AppSpacing.md),
          for (final doc in rules) ...[
            Builder(
              builder: (context) {
                final have = view.documents.where((file) => file.type == doc.type).toList();
                final missing = view.missing.contains(doc.type);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: Row(
                    key: Key('status-doc-${doc.type}'),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        have.isNotEmpty
                            ? Icons.check_circle_outline
                            : (missing ? Icons.error_outline : Icons.radio_button_unchecked),
                        size: 20,
                        color: have.isNotEmpty
                            ? colors.success
                            : (missing ? colors.warning : colors.inkMuted),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(copy.say(doc.title), style: theme.textTheme.bodyMedium),
                            for (final file in have)
                              Text(
                                file.name,
                                style: theme.textTheme.bodySmall?.copyWith(color: colors.inkMuted),
                              ),
                          ],
                        ),
                      ),
                      if (view.canUpload)
                        TextButton(
                          key: Key('status-add-${doc.type}'),
                          onPressed: _uploading == null ? () => _add(view, doc.type) : null,
                          child: Text(copy.addFile),
                        ),
                    ],
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}
