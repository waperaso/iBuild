import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../api.dart';
import '../l10n.dart';
import '../models.dart';
import '../money.dart';
import '../session_scope.dart';
import '../theme.dart';
import '../widgets.dart';
import 'project_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  var _waiting = 0;

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
      if (mounted) setState(() => _waiting = items.length);
    } on ApiException {
      if (mounted) setState(() => _waiting = 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = SessionScope.of(context);
    final copy = LocaleScope.copy(context);
    final projects = session.projects;
    final bank = session.user?.memberships.every((item) => item.role == AppRole.observer) == true;
    return ScreenScroll(
      children: [
        if (session.user?.isDirector == true)
          Align(
            alignment: Alignment.centerRight,
            child: PrimaryButton(
              key: const Key('create-project'),
              label: copy.createProject,
              onPressed: () => context.go('/projects'),
            ),
          ),
        _Hub(
          bank: bank,
          name: session.user?.name ?? 'iBuild',
          remainder: moneyUzs(moneySum(projects.map((item) => item.available))),
          reserved: moneyUzs(moneySum(projects.map((item) => item.reserved))),
          paid: moneyUzs(moneySum(projects.map((item) => item.paid))),
          waiting: '$_waiting',
          projects: projects,
          empty: projects.isEmpty,
        ),
      ],
    );
  }
}

class QueueScreen extends StatefulWidget {
  const QueueScreen({super.key});

  @override
  State<QueueScreen> createState() => _QueueScreenState();
}

class _QueueScreenState extends State<QueueScreen> {
  List<NoticeItem> _items = const [];
  var _loading = true;

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
      if (mounted) {
        setState(() {
          _items = items;
          _loading = false;
        });
      }
    } on ApiException {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final copy = LocaleScope.copy(context);
    return ScreenScroll(
      children: [
        Text(copy.queue, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: AppSpacing.sm),
        Text(
          copy.queueSubtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: context.colors.inkMuted),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (_loading)
          const SizedBox.shrink()
        else if (_items.isEmpty)
          EmptyState(
            key: const Key('empty-queue'),
            title: copy.queueEmptyTitle,
            body: copy.queueEmptyBody,
          )
        else
          for (final item in _items) ...[
            IBuildCard(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: GestureDetector(
                onTap: item.id.isEmpty ? null : () => context.go('/requests/${item.id}'),
                behavior: HitTestBehavior.opaque,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.line.isEmpty ? item.project : item.line, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.xs),
                    Text('${copy.place(item.project)} · ${copy.requestStatus(item.status)}'),
                    if (item.amount.isNotEmpty) Text(moneyUzs(item.amount)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
      ],
    );
  }
}

class _Hub extends StatefulWidget {
  const _Hub({
    required this.bank,
    required this.name,
    required this.remainder,
    required this.reserved,
    required this.paid,
    required this.waiting,
    required this.projects,
    required this.empty,
  });

  final bool bank;
  final String name;
  final String remainder;
  final String reserved;
  final String paid;
  final String waiting;
  final List<ProjectSummary> projects;
  final bool empty;

  @override
  State<_Hub> createState() => _HubState();
}

class _HubState extends State<_Hub> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool _hit(String text) {
    final query = _search.text.trim().toLowerCase();
    if (query.isEmpty) return true;
    return text.toLowerCase().contains(query);
  }

  @override
  Widget build(BuildContext context) {
    final copy = LocaleScope.copy(context);
    final shortcuts = [
      _Shortcut(copy.askTranche, 'assets/tiles/tile_tranche.png', () => context.go(widget.bank ? '/requests' : '/requests/new')),
      _Shortcut(copy.budget, 'assets/tiles/tile_plan.png', () => context.go('/budget')),
      _Shortcut(copy.projects, 'assets/tiles/tile_object.png', () => context.go('/projects')),
      _Shortcut(copy.inspections, 'assets/tiles/tile_inspection.png', () => context.go('/inspections')),
      _Shortcut(copy.documents, 'assets/tiles/tile_documents.png', () => context.go('/documents')),
      _Shortcut(copy.queue, 'assets/tiles/tile_queue.png', () => context.go('/queue')),
    ].where((item) => _hit(item.title)).toList();
    final ask = widget.bank ? '/requests' : '/requests/new';
    final spheres = [
      _Sphere(
        copy.requests,
        Icons.receipt_long_outlined,
        '/requests',
        [
          _SphereLink(copy.askTranche, ask),
          _SphereLink(copy.queue, '/queue'),
        ],
      ),
      _Sphere(
        copy.projectsCardTitle,
        Icons.apartment_outlined,
        '/projects',
        [
          for (final project in widget.projects.take(3))
            _SphereLink(copy.place(project.name), '/projects/${project.id}'),
          if (widget.projects.isEmpty) _SphereLink(copy.noProjects, '/projects'),
        ],
      ),
      _Sphere(
        copy.budget,
        Icons.account_balance_outlined,
        '/budget',
        [
          _SphereLink(copy.available, '/budget'),
          _SphereLink(copy.people, '/people'),
        ],
      ),
      _Sphere(
        copy.inspections,
        Icons.fact_check_outlined,
        '/inspections',
        [
          _SphereLink(copy.inspections, '/inspections'),
          _SphereLink(copy.documents, '/documents'),
        ],
      ),
    ].where((item) => _hit(item.title) || item.links.any((link) => _hit(link.label))).toList();
    return Column(
      key: const Key('hub-services'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.md),
        Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.lg),
            gradient: const LinearGradient(
              colors: [Color(0xFF1B6CA8), Color(0xFF0E3E68)],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${widget.name},',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white),
              ),
              Text(
                copy.welcome,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                controller: _search,
                onChanged: (_) => setState(() {}),
                style: const TextStyle(color: Color(0xFF101820)),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  hintText: copy.searchHint,
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        SizedBox(
          height: 132,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: shortcuts.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
            itemBuilder: (context, index) {
              final item = shortcuts[index];
              return SizedBox(width: 148, child: _ShortcutCard(item: item));
            },
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        LayoutBuilder(
          key: const Key('dashboard-tiles'),
          builder: (context, constraints) {
            final columns = constraints.maxWidth < 860 ? 2 : 4;
            final gap = AppSpacing.md;
            final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
            final figures = [
              _Figure(label: copy.available, value: widget.remainder),
              _Figure(label: copy.reserved, value: widget.reserved),
              _Figure(label: copy.paid, value: widget.paid),
              _Figure(label: copy.queue, value: widget.waiting),
            ];
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final figure in figures)
                  SizedBox(width: width, child: figure),
              ],
            );
          },
        ),
        const SizedBox(height: AppSpacing.xl),
        Row(
          children: [
            Text(copy.spheres, style: Theme.of(context).textTheme.titleLarge),
            const Spacer(),
            TextButton(
              onPressed: () => context.go('/projects'),
              child: Text(copy.allServices),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (widget.empty)
          EmptyState(
            key: const Key('empty-projects'),
            title: copy.noProjects,
            body: copy.noProjectsBody,
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth < 560
                  ? 1
                  : constraints.maxWidth < 860
                      ? 2
                      : 4;
              final gap = AppSpacing.md;
              final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final sphere in spheres)
                    SizedBox(width: width, child: _SphereCard(sphere: sphere)),
                ],
              );
            },
          ),
      ],
    );
  }
}

class _Shortcut {
  const _Shortcut(this.title, this.asset, this.onTap);
  final String title;
  final String asset;
  final VoidCallback onTap;
}

class _ShortcutCard extends StatelessWidget {
  const _ShortcutCard({required this.item});

  final _Shortcut item;

  @override
  Widget build(BuildContext context) {
    return IBuildCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: GestureDetector(
        onTap: item.onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Align(
                alignment: Alignment.center,
                child: Image.asset(item.asset, height: 56, fit: BoxFit.contain),
              ),
            ),
            Text(item.title, maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

class _SphereLink {
  const _SphereLink(this.label, this.location);
  final String label;
  final String location;
}

class _Sphere {
  const _Sphere(this.title, this.icon, this.location, this.links);
  final String title;
  final IconData icon;
  final String location;
  final List<_SphereLink> links;
}

class _SphereCard extends StatelessWidget {
  const _SphereCard({required this.sphere});

  final _Sphere sphere;

  void _open(BuildContext context, String location) {
    final id = RegExp(r'^/projects/(.+)$').firstMatch(location)?.group(1);
    if (id != null && id != '') {
      openProject(context, id);
      return;
    }
    context.go(location);
  }

  @override
  Widget build(BuildContext context) {
    final copy = LocaleScope.copy(context);
    final colors = context.colors;
    final linkStyle = TextButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      minimumSize: const Size(0, 36),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      alignment: Alignment.centerLeft,
      foregroundColor: colors.accent,
    );
    return IBuildCard(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(sphere.title, style: Theme.of(context).textTheme.titleMedium),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.surfaceAlt,
                  shape: BoxShape.circle,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: Icon(sphere.icon, size: 18, color: colors.inkMuted),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final link in sphere.links)
            TextButton(
              style: linkStyle,
              onPressed: () => _open(context, link.location),
              child: Text(link.label, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              style: linkStyle,
              onPressed: () => _open(context, sphere.location),
              child: Text('${copy.seeAll}  ›'),
            ),
          ),
        ],
      ),
    );
  }
}

class _Figure extends StatelessWidget {
  const _Figure({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return IBuildCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: context.colors.inkMuted)),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            height: 28,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(value, style: Theme.of(context).textTheme.titleMedium),
            ),
          ),
        ],
      ),
    );
  }
}
