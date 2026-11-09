import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../api.dart';
import '../l10n.dart';
import '../models.dart';
import '../money.dart';
import '../session_scope.dart';
import '../theme.dart';
import '../widgets.dart';
import 'kit.dart';
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
    final t = Tx.of(context);
    final theme = Theme.of(context);
    final colors = context.colors;
    return ScreenScroll(
      key: const Key('queue-frame'),
      children: [
        PageTitle(title: copy.queue, subtitle: copy.queueSubtitle),
        if (_loading)
          const PageWait()
        else if (_items.isEmpty)
          EmptyState(
            key: const Key('empty-queue'),
            title: copy.queueEmptyTitle,
            body: copy.queueEmptyBody,
          )
        else ...[
          KpiRow(children: [
            Kpi(
              label: t('Ждут вашей проверки', 'Waiting for your check', 'Tekshiruvingizni kutmoqda'),
              value: '${_items.length}',
              tone: _items.isEmpty ? null : colors.warning,
            ),
            Kpi(
              label: t('На сумму', 'Worth', 'Summasi'),
              value: moneyUzs(moneySum(_items.map((item) => item.amount))),
            ),
          ]),
          const SizedBox(height: AppSpacing.lg),
          IBuildCard(
            padding: EdgeInsets.zero,
            child: Column(
              key: const Key('queue-list'),
              children: [
                for (final item in _items)
                  Column(
                    children: [
                      InkWell(
                        key: Key('queue-open-${item.id}'),
                        onTap: item.id.isEmpty ? null : () => context.go('/requests/${item.id}'),
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.line.isEmpty ? item.project : item.line,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.titleSmall,
                                    ),
                                    const SizedBox(height: AppSpacing.xs),
                                    // The page is the queue, so every row waits
                                    // for this person: the count above says so
                                    // once instead of a label on each line.
                                    Text(
                                      copy.place(item.project),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(color: colors.inkMuted),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: AppSpacing.lg),
                              Text(
                                item.amount.isEmpty ? '' : moneyUzs(item.amount),
                                textAlign: TextAlign.right,
                                style: theme.textTheme.titleSmall,
                              ),
                              Padding(
                                padding: const EdgeInsets.only(left: AppSpacing.md),
                                child: Icon(
                                  Icons.chevron_right,
                                  size: 20,
                                  color: colors.inkMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Divider(height: 1, color: colors.outline),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _Hub extends StatefulWidget {
  const _Hub({
    required this.name,
    required this.remainder,
    required this.reserved,
    required this.paid,
    required this.waiting,
    required this.projects,
    required this.empty,
  });

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
    final user = SessionScope.of(context).user;
    final canCreate = user?.isDirector == true || user?.isContractor == true;
    final shortcuts = [
      if (canCreate)
        _Shortcut(
          copy.askTranche,
          'assets/tiles/tile_tranche.png',
          () => context.go('/requests/new'),
          key: const Key('home-ask-shortcut'),
        )
      else
        _Shortcut(
          copy.requests,
          'assets/tiles/tile_tranche.png',
          () => context.go('/requests'),
          key: const Key('home-tranche-shortcut'),
        ),
      _Shortcut(copy.budget, 'assets/tiles/tile_plan.png', () => context.go('/budget')),
      _Shortcut(copy.projects, 'assets/tiles/tile_object.png', () => context.go('/projects')),
      _Shortcut(copy.inspections, 'assets/tiles/tile_inspection.png', () => context.go('/inspections')),
      _Shortcut(copy.documents, 'assets/tiles/tile_documents.png', () => context.go('/documents')),
      _Shortcut(copy.queue, 'assets/tiles/tile_queue.png', () => context.go('/queue')),
    ].where((item) => _hit(item.title)).toList();
    final spheres = [
      _Sphere(
        copy.requests,
        Icons.receipt_long_outlined,
        '/requests',
        [
          if (canCreate)
            _SphereLink(copy.askTranche, '/requests/new', key: const Key('home-ask-link'))
          else
            _SphereLink(copy.requests, '/requests', key: const Key('home-tranche-link')),
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
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 560) {
              const gap = AppSpacing.md;
              final width = (constraints.maxWidth - gap) / 2;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final item in shortcuts)
                    SizedBox(width: width, height: 112, child: _ShortcutCard(item: item)),
                ],
              );
            }
            return SizedBox(
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
            );
          },
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
  const _Shortcut(this.title, this.asset, this.onTap, {this.key});
  final String title;
  final String asset;
  final VoidCallback onTap;
  final Key? key;
}

class _ShortcutCard extends StatelessWidget {
  const _ShortcutCard({required this.item});

  final _Shortcut item;

  @override
  Widget build(BuildContext context) {
    return IBuildCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: GestureDetector(
        key: item.key,
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
  const _SphereLink(this.label, this.location, {this.key});
  final String label;
  final String location;
  final Key? key;
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
              key: link.key,
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
