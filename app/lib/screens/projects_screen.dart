import 'package:flutter/material.dart';

import '../api.dart';
import '../l10n.dart';
import '../models.dart';
import '../money.dart';
import '../session_scope.dart';
import 'project_screen.dart';
import '../theme.dart';
import '../widgets.dart';

class ProjectsScreen extends StatelessWidget {
  const ProjectsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = SessionScope.of(context);
    final copy = LocaleScope.copy(context);
    final projects = session.projects;
    final bankOnly = session.user != null &&
        session.user!.memberships.isNotEmpty &&
        session.user!.memberships.every((item) => item.role == AppRole.observer);
    return ScreenScroll(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                bankOnly ? copy.portfolio : copy.projects,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            if (session.user?.isDirector == true)
              PrimaryButton(
                key: const Key('create-project'),
                label: copy.createProject,
                onPressed: () => _create(context),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          copy.projectsSubtitle,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: context.colors.inkMuted),
        ),
        const SizedBox(height: AppSpacing.lg),
        const _NoticeList(),
        const SizedBox(height: AppSpacing.lg),
        if (projects.isEmpty)
          EmptyState(
            key: const Key('empty-projects'),
            title: copy.noProjects,
            body: copy.noProjectsBody,
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 560) {
                return Column(
                  key: const Key('project-cards'),
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final project in projects) ...[
                      _ProjectCard(project: project),
                      const SizedBox(height: AppSpacing.xl),
                    ],
                  ],
                );
              }
              return IBuildCard(
                key: const Key('project-table'),
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    const _TableHead(),
                    for (final project in projects) ...[
                      Divider(height: 1, color: context.colors.outline),
                      _TableRow(project: project),
                    ],
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  Future<void> _create(BuildContext context) async {
    final name = TextEditingController();
    final address = TextEditingController();
    String? error;
    await showPlainDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            final copy = LocaleScope.copy(context);
            return AlertDialog(
              title: Text(copy.newProject),
              content: SizedBox(
                width: dialogFieldWidth(context),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      key: const Key('project-name'),
                      controller: name,
                      decoration: InputDecoration(labelText: copy.name),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      key: const Key('project-address'),
                      controller: address,
                      decoration: InputDecoration(labelText: copy.address),
                    ),
                    if (error != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          copy.known(error!),
                          style: TextStyle(color: context.colors.danger),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(copy.cancel),
                ),
                TextButton(
                  key: const Key('project-save'),
                  onPressed: () async {
                    final title = name.text.trim();
                    final place = address.text.trim();
                    if (title.isEmpty || place.isEmpty) {
                      setState(() => error = copy.needNameAddress);
                      return;
                    }
                    final failure = await SessionScope.of(
                      context,
                    ).createProject(name: title, address: place);
                    if (!dialogContext.mounted) return;
                    if (failure != null) {
                      setState(() => error = failure);
                      return;
                    }
                    Navigator.of(dialogContext).pop();
                  },
                  child: Text(copy.save),
                ),
              ],
            );
          },
        );
      },
    );
    name.dispose();
    address.dispose();
  }
}

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({required this.project});

  final ProjectSummary project;

  @override
  Widget build(BuildContext context) {
    final copy = LocaleScope.copy(context);
    final colors = context.colors;
    return IBuildCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: InkWell(
        onTap: () => openProject(context, project.id),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    copy.place(project.name),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                StatusText(
                  label: copy.projectStatus(project.active),
                  tone: project.active ? StatusTone.good : StatusTone.neutral,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              project.address,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.inkMuted),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              copy.roleName(project.myRole),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.inkMuted),
            ),
            const SizedBox(height: AppSpacing.xs),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                moneyUzs(project.available),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 28),
              ),
            ),
            Text(
              copy.available,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.inkMuted),
            ),
          ],
        ),
      ),
    );
  }
}

const double _columnGap = 16;

class _ProjectColumns extends StatelessWidget {
  const _ProjectColumns({
    required this.name,
    required this.role,
    required this.available,
    required this.status,
  });

  final Widget name;
  final Widget role;
  final Widget available;
  final Widget status;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 5, child: name),
        const SizedBox(width: _columnGap),
        Expanded(flex: 2, child: role),
        const SizedBox(width: _columnGap),
        Expanded(flex: 3, child: available),
        const SizedBox(width: _columnGap),
        Expanded(flex: 2, child: status),
      ],
    );
  }
}

class _TableHead extends StatelessWidget {
  const _TableHead();

  @override
  Widget build(BuildContext context) {
    final copy = LocaleScope.copy(context);
    final style = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(color: context.colors.inkMuted);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.sm,
      ),
      child: _ProjectColumns(
        name: Text(copy.name, style: style, maxLines: 1, overflow: TextOverflow.ellipsis),
        role: Text(copy.role, style: style, maxLines: 1, overflow: TextOverflow.ellipsis),
        available: Text(
          copy.available,
          style: style,
          textAlign: TextAlign.right,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        status: Text(copy.status, style: style, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}

class _NoticeList extends StatefulWidget {
  const _NoticeList();

  @override
  State<_NoticeList> createState() => _NoticeListState();
}

class _NoticeListState extends State<_NoticeList> {
  List<NoticeItem> _items = const [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _load();
  }

  var _started = false;

  Future<void> _load() async {
    try {
      final items = await SessionScope.of(context).api.notices();
      if (mounted) setState(() => _items = items);
    } on ApiException {
      if (mounted) setState(() => _items = const []);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty) return const SizedBox.shrink();
    final copy = LocaleScope.copy(context);
    return IBuildCard(
      key: const Key('notice-queue'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(copy.needsAction, style: Theme.of(context).textTheme.titleMedium),
          for (final item in _items)
            Text('${copy.place(item.project)} · ${item.line} · ${copy.requestStatus(item.status)}'),
        ],
      ),
    );
  }
}

class _TableRow extends StatelessWidget {
  const _TableRow({required this.project});

  final ProjectSummary project;

  @override
  Widget build(BuildContext context) {
    final copy = LocaleScope.copy(context);
    return InkWell(
      onTap: () => openProject(context, project.id),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.lg,
        ),
        child: _ProjectColumns(
          name: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                copy.place(project.name),
                style: Theme.of(context).textTheme.titleMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                project.address,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: context.colors.inkMuted,
                ),
              ),
            ],
          ),
          role: Text(
            copy.roleName(project.myRole),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          available: Text(
            moneyUzs(project.available),
            textAlign: TextAlign.right,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          status: StatusText(
            label: copy.projectStatus(project.active),
            tone: project.active ? StatusTone.good : StatusTone.neutral,
          ),
        ),
      ),
    );
  }
}
