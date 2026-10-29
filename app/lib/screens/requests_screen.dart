import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../api.dart';
import '../download.dart';
import '../l10n.dart';
import '../models.dart';
import '../money.dart';
import '../session_scope.dart';
import 'request_form_screen.dart';
import '../theme.dart';
import '../widgets.dart';

class RequestsScreen extends StatefulWidget {
  const RequestsScreen({super.key, this.projectId});

  final String? projectId;

  @override
  State<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends State<RequestsScreen> {
  String? _filter;
  String? _projectId;
  var _started = false;
  var _ready = false;
  List<FundingRequest> _requests = const [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _projectId = widget.projectId;
    _filter = _queueFor(SessionScope.of(context).user);
    _load();
  }

  String? _queueFor(UserProfile? user) {
    if (user == null || user.isDeveloper) return null;
    if (user.memberships.any((item) => item.role == AppRole.director)) {
      return 'tech_approved';
    }
    if (user.memberships.any((item) => item.role == AppRole.tech)) {
      return 'submitted';
    }
    return null;
  }

  Future<void> _open(FundingRequest item) async {
    try {
      final full = await SessionScope.of(context).api.request(item.id);
      if (!mounted) return;
      context.go('/requests/${item.id}', extra: full);
    } on ApiException {
      if (!mounted) return;
      context.go('/requests/${item.id}');
    }
  }

  Future<void> _load() async {
    try {
      final rows = await SessionScope.of(context).api.requests();
      if (!mounted) return;
      setState(() {
        _requests = rows;
        _ready = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _ready = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = SessionScope.of(context);
    final copy = LocaleScope.copy(context);
    if (!_ready) return const SizedBox.expand();
    final projects = <String, String>{
      for (final project in session.projects) project.id: project.name,
      for (final item in _requests) item.projectId: item.projectName,
    };
    final visible = [
      for (final item in _requests)
        if ((_filter == null ||
                item.status == _filter ||
                (_filter == 'tech_approved' &&
                    item.mine &&
                    (item.status == 'draft' || item.status == 'submitted'))) &&
            (_projectId == null || item.projectId == _projectId))
          item,
    ];
    final showProjects =
        visible.isEmpty && _projectId == null && (_filter == null || _filter == 'draft');
    return ScreenScroll(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                copy.requests,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            Flexible(
              flex: 2,
              child: Wrap(
                alignment: WrapAlignment.end,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  TextButton(
                    key: const Key('download-registry'),
                    onPressed: () => downloadRegistry(projectId: _projectId, status: _filter),
                    child: Text(copy.downloadRegistry),
                  ),
                  if (session.user?.isContractor == true || session.user?.isDirector == true)
                    PrimaryButton(
                      key: const Key('new-request'),
                      label: copy.newRequest,
                      onPressed: () => openRequestForm(context),
                    ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (_filter == 'submitted' &&
            session.user?.memberships.any((item) => item.role == AppRole.tech) == true)
          Text(
            copy.techQueue,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: context.colors.inkMuted,
            ),
          )
        else if (_filter == 'tech_approved' &&
            session.user?.memberships.any(
                  (item) => item.role == AppRole.observer || item.role == AppRole.developer,
                ) ==
                true)
          Text(
            copy.bankQueueNote,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: context.colors.inkMuted,
            ),
          )
        else
          Text(
            copy.requestsSubtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: context.colors.inkMuted,
            ),
          ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            _Filter(
              label: copy.all,
              selected: _filter == null,
              onTap: () => setState(() => _filter = null),
            ),
            for (final code in AppCopy.statusCodes)
              _Filter(
                label: copy.requestStatus(code),
                selected: _filter == code,
                onTap: () => setState(() => _filter = code),
              ),
          ],
        ),
        if (projects.length > 1) ...[
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<String>(
            key: const Key('request-project-filter'),
            initialValue: projects.containsKey(_projectId) ? _projectId! : '',
            decoration: InputDecoration(labelText: copy.projects),
            items: [
              DropdownMenuItem(value: '', child: Text(copy.allProjects)),
              for (final entry in projects.entries)
                DropdownMenuItem(value: entry.key, child: Text(entry.value)),
            ],
            onChanged: (value) => setState(() {
              _projectId = value == null || value.isEmpty ? null : value;
            }),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        for (final item in visible) ...[
          IBuildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (projects.length > 1) ...[
                  Text(
                    item.projectName,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: context.colors.inkMuted,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                ],
                Text(
                  item.lineTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (item.description.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    item.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: context.colors.inkMuted,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(child: Text(moneyUzs(item.amount))),
                    StatusText(
                      label: copy.requestStatus(item.status),
                      tone: switch (item.status) {
                        'paid' || 'approved' || 'tech_approved' => StatusTone.good,
                        'rejected' || 'cancelled' => StatusTone.bad,
                        _ => StatusTone.wait,
                      },
                    ),
                  ],
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    key: Key('open-request-${item.id}'),
                    style: backLinkStyle,
                    onPressed: () => _open(item),
                    child: Text(copy.openRequest),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        if (visible.isEmpty && !showProjects)
          EmptyState(
            key: const Key('empty-requests'),
            title: copy.noRequestsForStatus,
            body: copy.noRequestsForStatusBody,
          )
        else if (visible.isEmpty) ...[
          for (final project in session.projects) ...[
            IBuildCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    project.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(project.address),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    '${copy.available} ${moneyUzs(project.available)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    copy.projectRequestsEmpty,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: context.colors.inkMuted,
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      style: backLinkStyle,
                      onPressed: () => context.go('/projects/${project.id}'),
                      child: Text(copy.openProject),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          if (session.projects.isEmpty)
            EmptyState(title: copy.noRequests, body: copy.noRequestsBody),
        ],
      ],
    );
  }
}

class _Filter extends StatelessWidget {
  const _Filter({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: selected ? colors.accent : colors.surface,
      borderRadius: BorderRadius.circular(AppRadii.pill),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: selected ? colors.onAccent : colors.ink,
            ),
          ),
        ),
      ),
    );
  }
}
